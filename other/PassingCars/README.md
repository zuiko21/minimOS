# PassingCars

### An exercise from [Codility](https://app.codility.com/programmers/lessons/5-prefix_sums/passing_cars)

From an [inspiring talk](https://www.twitch.tv/videos/616019288) by [pinchitoCoder](https://www.twitch.tv/pinchitocoder) I was tempted
to submit an improvement on [his **JavaScript**-based solution](https://twitter.com/pinchito/status/1259189318893084672?s=20).
This is the code I wrote:

```javascript
function solution(array) {
  let total   = 0
  let partial = 0
  for (let i = array.length - 1; i >= 0; i--) {
    if (array[i] == 1) {
      partial++
    } else {
      total += partial
      if (total > 1000000000) return -1
    }
  }
  return total
}
```

Now the ordeal was, obviously, rewrite [this JS code](passing.js) as **6502 assembly**.

## 6502 version

Being a _pure_ 8-bit CPU, the original 6502 is a somewhat _ill-fitted_ choice for working on large data sets. A _quick and dirty_
approach was [like this](6502-128.s):

```assembly
LDX #length-1   ; start from the LAST element, going backwards
LDY #0          ; reset partial counter (Y)
STY total       ; reset total too
loop:
  LDA array, X  ; get element from array (zero or otherwise)
  BEQ zero      ; if not zero...
    INY         ; ...increment partial counter...
    BNE next    ; CMOS could use BRA as well
zero:
    TYA         ; ...else add partial counter...
    CLC
    ADC total   ; ...to current total
    STA total
next:
  DEX           ; go for next element
  BPL loop
```

Which, while being valid as a _proof-of-concept_, it's far below the original specs: this code is all **8-bit arithmetic** and values
up to 255, whereas the original excercise was expected to count up to **one thousand million cars** and running against a
**100,000-element array**. To make things worse, the `BPL` trick in the loop allows the array to **start at index _zero_** without
any _page-boundary crossing_ penalty, but limits the array size to **128 elements**, as anything above will be evaluated as
_negative_, stopping the loop right after the first iteration...

A [simple (but still incomplete) workaround](6502-256.s) would be replacing the aforementioned `BPL` by the following code:

```assembly
  CPX #$FF
  BNE loop
```

Which allows for a "full"-sized **256-element array**... albeit with a _2-cycle speed penalty_ per iteration.

[A much better approach](6502-255.s), at least for this reduced-size version, is to make _array indexes starting from 1_, using an
appropriate offset on the indexed read and removing the time-consuming `CPX` atop the `BNE`.
This sacrifices a single array element **(maximum 255 bytes) without impacting performance**
compared to the 128-element version. _If care is exerted on **not** placing the array at the
very start of a page_ (address `$xx00`), no boundary-crossing penalty is to be expected.

For performance estimation, this code is **23 bytes** long (assuming its only variable
`total` resides in _zeropage_). Execution time depends on whether the array element holds
an `1` or a `0`, with each iteration taking **17 or 23 clock cycles**, respectively.
  
### Going bigger: the 64 KB (not KiB) version

Even if still below [the original specs](https://app.codility.com/programmers/lessons/5-prefix_sums/passing_cars), some more
elaborated code will allow a **nearly 64K-element array** -- theoretically up to 65536 elements, but some space must be allowed for
variables and the code itself, not mentioning a _minimal I/O_ environment, interrupt vectors, stack, etc. Including some
cumbersome **16- and 32-bit arithmetic**, this [much bigger chunk of code](6502-64k.s)
is shown as reference (_critical_ instruction timings shown between parentheses):

```assembly
LDX #0          ; reset LOW byte of partial counter (X)
LDA #>(array+size-1)
LDY #<(array+size-1)
STA ptr+1       ; make zeropage pointer (+Y) to LAST array element
STX ptr
STX total       ; reset 32-bit total counter
STX total+1
STX total+2
STX total+3
STX partial.h   ; reset HIGH byte of partial counter (in zeropage as will change much less frequently)
loop:
 LDA (ptr), Y   ; (5) get array element
 BEQ zero       ; (2/3) if not zero... [timing shown for (then/else) sections]
  INX           ; (2/0) ...increment partial counter
  BNE next      ; (3-10/0) check for possible carry! extra cycles only 0.4% of the time
   INC partial.h
  BNE next
zero:
  TXA           ; (0/2) ...else take partial counter...
  CLC           ; (0/2)
  ADC total     ; (0/3) ...and add it to current total
  STA total     ; (0/3)
  LDA total+1   ; (0/3) ditto for 2nd byte
  ADC partial.h ; (0/3) note partial MSB origin
  STA total+1   ; (0/3)
  LDA total+2   ; (0/3)
  ADC #0        ; (0/2) partial is 16-bit, but carry may propagate
  STA total+2   ; (0/3)
  LDA total+3   ; (0/3)
  ADC #0        ; (0/2) ditto for last byte, but...
  CMP #60       ; (0/2) ...have we reached the limit?
   BEQ over     ; (0/2) yes? no more iterations! if this jump executes, no more iterations
  STA total+3   ; (0/3) no? just update value
next:
 DEY            ; (2) go for next byte
 CPY #$FF       ; (2) wraparound?
 BNE loop       ; (3-15) if not, just iterate; extra cycles only ~0.4% of the time
  DEC ptr+1     ; otherwise, modify pointer MSB...
  LDA ptr+1
  CMP #>array   ; ...until we went below array start address
 BCS loop
BCC end         ; array is done, just exit
over:
 LDA #$FF       ; in case of overflow, set total to -1
 STA total
 STA total+1
 STA total+2
 STA total+3
end:
```

This sample is **84 bytes** long and takes **19 or 54 clock cycles** per iteration.
It also uses **7 bytes of RAM** space (`ptr` is mandatorily in **zeropage**). Note
that the array must be _page-aligned_.
   
### TO DO: even bigger

Whilst being able to access a whopping 64 K of data, it's still below the specified
_100,000-element array_. A more **efficient array storage** is thus needed, using
just _one bit_ per element instead of a whole byte.

## 65C816: the 6502's Big Brother

With **full 16-bit registers and arithmetic**, [this interesting CPU](https://en.wikipedia.org/wiki/WDC_65C816)
seems way more suited to these large tasks. Discarding a previous [dirty attempt](816-t16.s),
here is the [**16-bit version**](816-t32.s) of the [6502 code](6502-64k.s) above:

```assembly
REP #$10         ; use 16-bit indexes...
SEP #$20         ; ...but 8-bit memory/accumlator
LDX #length      ; backwards loop, as usual
LDY #0           ; reset partial (16-bit)...
STY total        ; ...and total (32-bit) counters
STY total+2
loop:
 LDA @array-1, X ; (5)   get array element
 BEQ zero        ; (2/3) if it's 1... [timing as above]
  INY            ; (2/0) ...increment partial
  BRA next       ; (3/0)
zero:
  REP #$20       ; (0/3) ...else use 16-bit memory for a moment
  TYA            ; (0/2) add partial...
  CLC            ; (0/2) ...for the first time...
  ADC total      ; (0/4) ...to current total
  STA total      ; (0/4)
  LDA total+2    ; (0/4) ditto for high order word...
  ADC #0         ; (0/3) ...as carry may propagate
  STA total+2    ; (0/4)
  SEP #$20       ; (0/3) back to 8-bit accesses
next:
 DEX             ; (2)   go for next element
 BNE loop        ; (3)
```

But there's still much room for [improvement](816-t32o.s):

- No execution limit
- `Carry` flag (usually reset by a `CLC` before adding) can be cleared thru the previous `REP`
- The array fits a single _bank_ so, assuming all variables are in _zeropage_, could use
the classic **absolute indexed** (not _long_) addressing, saving one byte, as long
as the `Data Bank` is selected beforehand.
 
The last one is easily implemented, as is the second one, saving another byte &
2 clock cycles... just replace the `REP/TYA/CLC` sequence by:

```assembly
  REP #$21       ; (0/3) use 16-bit memory AND clear Carry flag
  TYA            ; (0/2) add partial...
```

The execution limit, thanks to the 16-bit arithmetic, is nowhere as cumbersome as on the 6502.
After `ADC #0` use the following code chunk instead:

```assembly
  CMP #15259     ; (0/3) already at the limit?
   BEQ over      ; (0/2) return -1 if so, executes at most ONCE 
  STA total+2    ; (as before)
  SEP #$20
next:
 DEX
 BNE loop
BRA end          ; (add from here)
over:
 LDX #$FFFF      ; load value as -1
 STX total       ; set total counter
 STX total+2
end:
```

Performance-wise, this takes **56 bytes** and **17 or 45 cycles** per iteration, thus
expected to run about **20% faster** than the 6502 version. Variables need **4 bytes
of RAM**, preferably in _zeropage_.  

### The (almost) final version

In order to reach the specified _array size_ (100,000 elements), regular 16-bit indexing
is no longer an option; but the 65C816's **indirect postindexed _long_** addressing mode
comes to the rescue! [This way](816-16m.s) the array may span several banks, waiving
the 64K limit.

```assembly
REP #$10                ; 16-bit indexes
SEP #$20                ; 8-bit memory & accumulator
LDX #0                  ; reset partial, also for clearing words
STX partial_h           ; needs 32-bit clean, although uses only 24
LDA #(array+size-1)>>16 ; last BANK used by the array
LDY #!(array+size-1)    ; last low word used by the array
STA ptr+2               ; create LONG indirect pointer
STX ptr
STX total               ; reset total counter
STZ total+2
loop:
 LDA [ptr], Y    ;(6)   get array data
 BEQ zero        ;(2/3) if not zero...
  INX            ;(2/0) ...increment partial
  BNE next       ;(3/0) VERY rarely over 3 cycles
   INC partial_h ;(5*/0) don't care about fourth byte
  BRA next       ;(3*/0) VERY rarely done
zero:
  REP #$21       ;(0/3) else clear C and set 16-bit memory
  TXA            ;(0/2) add partial...
  ADC total      ;(0/4) ...to current total
  STA total      ;(0/4)
  LDA total+2    ;(0/4) ditto with high word...
  ADC partial_h  ;(0/4) ...not just carry
  CMP #15259     ;(0/3) are we at the limit?
   BEQ over      ;(0/2) return -1 if so, executes at most ONCE
  STA total+2    ;(0/4) total is updated
  SEP #$20       ;(0/3) back to 8-bit memory & accumulator
next:
 DEY             ;(2)   next element
 CPY #$FFFF      ;(3)   are we switching bank?
 BNE loop        ;(3)   VERY rarely beyond this point
  DEC ptr+2      ;(5*) switch to previous bank
  LDA ptr+2      ;(3*) could be waived if starting at bank 1
  CMP #array>>16 ;(2*) could be waived if starting at bank 1
 BCS loop        ;(3*) use BNE if waived
BRA end
over:
 LDX #$FFFF      ; -1 to be set in case of overflow
 STX total
 STX total+2
end:

; *) Very rarely (~0.0015%) executed
```

This code is **76 bytes** long and typically takes **21 or 50 cycles** per iteration. _Array must be
**bank-aligned**_. Some 4 bytes can be saved if we assume the array to start at `$010000`, but with
**negligible improvement on performance**, though.

Further speedup may be done by using the classic _indirect postindexed_ addressing,
as the array is **sequentially** scanned and bank switching is rare. But code is likely
to become much more cumbersome, for a _single cycle saving_ per iteration, which
doesn't seem to be worth the hassle. 

### Compact array

Even if it's intereseting to store a prominently **boolean** array as bytes for the sake
of _performance_, properly storing every element as a **single bit** will allow the use
of 16-bit indexing _while keeping a reasonable 512K-element array_.

```assembly
REP #$30        ; 16-bit all the way!
LDX #size/8     ; offset in bytes to last element+2
STZ partial     ; clear counters
STZ partial+2
STZ total
STZ total+2
loop:
 LDY #16        ; (3*)  number of bits to be shifted from a word
 LDA array-2, X ; (6*)  get word, or 16 array entries
bit:
  ASL           ; (2)   shift word, MSB is the last element of the chunk
  BCC zero      ; (2/3) if not zero...
  INC partial   ; (7/0) ...increment partial...
  BNE next      ; (3-13/0) ...checking possible carry (rare)
   INC partial+2
  BRA next
zero:
  STA tmp       ; (0/4) save accumulator as it has unshifted bits
  CLC           ; (0/2) prepare for adding
  LDA total     ; (0/4) add to total...
  ADC partial   ; (0/4) ...current partial
  STA total     ; (0/4)
  LDA total+2   ; (0/4) ditto for high word
  ADC partial+2 ; (0/4)
  CMP #15259    ; (0/3) are we at the limit?
   BEQ over     ; (0/2) if so, abort (just ONCE executed)
  STA total+2   ; (0/4) updated total
  LDA tmp       ; (0/4) retrieve accumulator
next:
  DEY           ; (2)   another bit in the word
  BNE bit       ; (3)   after the last bit is done, this is one cycle faster
 DEX            ; (2*)  word is empty, go for next one
 DEX            ; (2*)  pointer arithmetic!
 BNE loop       ; (3*)  until array is done
BRA end
over:
 LDA #$FFFF     ; load -1...
 STA total      ; ...into total counter
 STA total+2
end:

;*) executed once every 16 iterations
```

At **71 bytes**, this is [surprinsingly compact code](816-c512k). Performance is nice too,
even including the **15-cycle overhead _every 16 iterations_**. Depending on stored
value and including the overhead, each one will take around **20 or 50 cycles**,
actually improving the performance of the _24-bit version_. **6 RAM bytes** are used,
not necessarily in zeropage.

Note that _the array can be located anywhere_, as long as the `Data Bank` register is
pointing to it; but **its size must be a multiple of 16** 

## 6502 revisited: 512K elements in compact form

The compact array approach is particularly interesting for the "bare" 6502, as is
**the only way to suit the original specs**. Taking **104 bytes**,
[this is the largest chunk of code](6502-c512k.s) for this task:

```assembly
LDX #0            ; 65C02 may delete this, using STZ instead of STX below
LDA #>(array+size/8-1)
LDY #<(array+size/8-1)
STA ptr+1         ; create indirect pointer, LSB is only at Y
STX ptr
STX partial       ; clear all counters
STX partial+1
STX partial+2
STX total
STX total+1
STX total+2
STX total+3
loop:
 LDX #8           ; (2^)  number of bits to be shifted each load
 LDA (ptr), Y     ; (5^)  get 8-element pack
bit:
  ASL             ; (2)   MSB is the last element of the pack
  BCC zero        ; (2/3) if not zero...
   INC partial    ; (5/0) ...count into partial
   BNE next       ; (3/0) check possible carry
    INC partial+1 ; (*5/0) this is done 0.4% of time
   BNE next       ; (*3/0) VERY seldom (~0.0015%) beyond this point
    INC partial+2
   BNE next
zero:
   STA tmp        ; (0/3) store accumulator as it has unshifted bits
   CLC            ; (0/2) prepare for addition
   LDA total      ; (0/3) take total...
   ADC partial    ; (0/3) ...plus partial...
   STA total      ; (0/3) ...and store result
   LDA total+1    ; (0/3) ditto for following bytes
   ADC partial+1  ; (0/3)
   STA total+1    ; (0/3)
   LDA total+2    ; (0/3)
   ADC partial+2  ; (0/3)
   STA total+2    ; (0/3)
   LDA total+3    ; (0/3)
   ADC #0         ; (0/2) possible carry
   CMP #60        ; (0/2) are we over the limit?
    BEQ over      ; (0/2) will take 3 cycles ONCE at most
   STA total+1    ; (0/3) updated counter
   LDA tmp        ; (0/3) retrieve remaining bytes
next:
  DEX             ; (2)  next bit
  BNE bit         ; (3)  will take one less cycle the last bit
 DEY              ; (2^)   next byte
 CPY #$FF         ; (2^)   wraparound?
 BNE loop         ; (3^)   another iteration, rarely beyond this point
  DEC ptr+1       ; decrement MSB and check limits
  LDA ptr+1
  CMP #>array
 BCS loop
BCC end           ; array is done, keep total result
over:
 LDY #$FF         ; set -1 on total in case of overflow
 STY total
 STY total+1
 STY total+2
 STY total+3
end:

; ^) executed once each 8 iterations
; *) executed 0.4% of the time
```

A ~13-cycle overhead _every 8 iterations_ accounts for a bit less than 2 clock cycles, thus
total iteration time is **~18.6 or ~58.6 cycles**. Code size is again **104 bytes**, with
2 bytes less for the CMOS version.

_last modified: 20200514-1538_
