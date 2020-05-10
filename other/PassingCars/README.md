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

Now the ordeal was, obviously, rewrite this JS code as **6502 assembly**.

## 6502 version

Being a _pure_ 8-bit CPU, the original 6502 is a somewhat ill-fitted choice for working on large data sets. A _quick and dirty_
approach was [like this](6502-128.s):

```assembly
LDX #length-1   ; start from the LAST element, going backwards
LDY #0          ; reset partial counter (Y)
STY total       ; reset total too
loop:
  LDA array, X  ; get element from array (zero or otherwise)
  BEQ zero      ; if not zero...
    INY         ; ...increment partial counter...
    BRA next
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
**100000-element array**. To make things worse, the `BPL` trick in the loop allows the array to **start at index _zero_** without
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
`total` on _zeropage_). Execution time depends on whether the array element holds an `1`
or a `0`, with each iteration taking **17 or 23 clock cycles**, respectively.
  
### Going bigger: the 64 KB (not KiB) version

Even if still below [the original specs](https://app.codility.com/programmers/lessons/5-prefix_sums/passing_cars), some more
elaborated code will allow a **nearly 64K-element array** -- theoretically up to 65536 elements, but some space must be allowed for
variables and the code itself, not mentioning a _minimal I/O_ environment, interrupt vectors, stack, etc. Including some
cumbersome **16- and 32-bit arithmetic**, this [much bigger chunk of code](6502-64k.s) is shown as reference:

```assembly
LDX #0          ; reset LOW byte of partial counter (X)
LDA #>(array+size-1)
LDY #<(array+size-1)
STA ptr+1       ; make zeropage pointer to LAST array element
STX ptr
STX total       ; reset 32-bit total counter
STX total+1
STX total+2
STX total+3
STX partial.h   ; reset HIGH byte of partial counter (on zeropage as will change much less frequently)
loop:
 LDA (ptr), Y   ; get array element (5)
 BEQ zero       ; if not zero... (2/3) [timing shown for (then/else) sections]
  INX           ; ...increment partial counter (2/0)
  BNE next      ; check for possible carry! (3-10/0) extra cycles only 0.4% of the time
  INC partial.h
  BNE next
zero:
  TXA           ; ...else take partial counter... (0/2)
  CLC           ; (0/2)
  ADC total     ; ...and add it to current total (0/3)
  STA total     ; (0/3)
  LDA total+1   ; ditto for 2nd byte (0/3)
  ADC partial.h ; note partial MSB origin (0/3)
  STA total+1   ; (0/3)
  LDA total+2   ; (0/3)
  ADC #0        ; partial is 16-bit, but carry may propagate (0/2)
  STA total+2   ; (0/3)
  LDA total+3   ; (0/3)
  ADC #0        ; ditto for last byte, but... (0/2)
  CMP #60       ; ...have we reached the limit? (0/2)
   BEQ over     ; if so, no more iterations! (0/2*) if this jump executes, no more iterations
  STA total+3   ; if not, just update value (0/3)
next:
 DEY            ; go for next byte (2)
 CPY #$FF       ; wraparound? (2)
 BNE loop       ; if not, just iterate (3-15) extra cycles only ~0.4% of the time
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
It also uses **7 bytes of zeropage** space (`ptr` is mandatory there).
   
### TO DO: even bigger

Whilst being able to access a whopping 64 K of data, it's still below the specified
_100000-element array_. A more **efficient array storage** is thus needed, using
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
 LDA @array-1, X ; get array element (5)
 BEQ zero        ; if it's 1... (2/3) [timing as above]
  INY            ; ...increment partial (2/0)
  BRA next       ; (3/0)
zero:
  REP #$20       ; ...else use 16-bit memory for a moment (0/3)
  TYA            ; add partial... (0/2)
  CLC            ; ...for the first time... (0/2)
  ADC total      ; ...to current total (0/4)
  STA total      ; (0/4)
  LDA total+2    ; ditto for high order word... (0/4)
  ADC #0         ; ...as carry may propagate (0/3)
  STA total+2    ; (0/4)
  SEP #$20       ; back to 8-bit accesses (0/3)
next:
 DEX             ; go for next element (2)
 BNE loop        ; (3)
```

But there's still much room for [improvement](816-t32o.s):

- No execution limit
- `Carry` flag (usually reset by a `CLC` before adding) can be cleared thru the previous `REP`
 
The last one is easily implemented, saving 1 byte & 2 clock cycles... just replace:

```assembly
  REP #$20       ; ...else use 16-bit memory for a moment (0/3)
  TYA            ; add partial... (0/2)
  CLC            ; ...for the first time... (0/2)
```

by:

```assembly
  REP #$21       ; use 16-bit memory AND clear Carry flag
  TYA            ; add partial...
```

The execution limit, thanks to the 16-bit arithmetic, is nowhere as cumbersome as on the 6502.
After `ADC #0` use the following code chunk instead:

```assembly
  CMP #15259     ; already at the limit? (0/3)
   BEQ over      ; return -1 if so (0/2*)
  STA total+2    ; (as before)
  SEP #$20
next:
 DEX
 BNE loop
BRA end          ; (add the following)
over:
 LDX #$FFFF      ; -1
 STX total       ; set total counter
 STX total+2
end:
```

Performance-wise, this takes **56 bytes** and **17 or 45 cycles** per iteration, thus
expected to run about **20% faster** than the 6502 version. Needs _4 bytes_ of RAM,
preferably on _zeropage_.  

### The (almost) final version

In order to reach the specified _array size_ (100000 elements), regular 16-bit indexing
is no longer an option; but the 65C816's _indirect postindexed **long**_ addressing mode
comes to the rescue! This way the array may span several banks, waiving the 64K limit.

TO DO
 
### Compact array

Even if it's intereseting to store a prominently **boolean** array as bytes for the sake
of _performance_, properly storing every element as a **single bit** will allow the use
of 16-bit indexing _while keeping a reasonable 512 Ki-element array_.

TO DO 

## 6502 revisited: 512K elements in compact form

_last modified: 20200510-1822_
