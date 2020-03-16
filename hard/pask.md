# PASK: _Port-"A"_ Simple Keyboard

Intended as a simple keyboard capable of generating the **full range of characters**
(if not in the most convenient way) with **really simple software support**. This
device simply puts into the **user VIA's _port A_** (in _handshake_ input mode) the
desired ASCII code, to be directly read thru a trivial driver, allowing easy
interface _even in heaviliy crashed systems_.

## Principle of operation

From the computer's point of view, PASK just sends an ASCII code whenever a key is
pressed. A simple _ripple counter_ scans the keyboard's rows and, together with the
detected column data, create an address for an **(EP)ROM** containing the corresponding
character codes. This allows the use with any character set by switching the EPROM contents.

Whenever the selected row detects some pressed key(s), the `/ROW` signal is generated --
which, in turn, emits the `/STROBE` pulse. But it also **stops the clock** for the counter,
in order to wait for the key to be released. Thus, **debouncing** becomes just a matter of
scanning the keyboard at a reasonable rate (~20 ms).

On the other hand, the _n-key rollover_ problem is not solved this way... the simpler workaround
I can think of is the use of a _second EPROM_ just taking the uncoded column bits, emitting
the `/ROW` signal when **one and only one key** is pressed. Another option could be the use of a
_priority encoder_ for the column inputs, but that was deemed inconvenient as will be discussed
later.

With the proposed 5x8 matrix, the EPROM takes 5 _uncoded_ columns, plus 3 row bits (8 coded rows)
and 3 modifier bits (shift, control & alt), for a total of **11 bits** (**2 kiB**). A 2716 will
suffice; anyway, larger EPROMs (up to 27C128, which I have many) are accepted, with a few jumpers
allowing _alternative charsets_.

## Hardware interface

The now standard **VIAport 2** in a simple port fashion will suffice. It must be
connected to port A, as port B does not support _read handshake_. Actually, only `CA1`
is used besides the data lines `PA0-PA7`.

Since the VIA interface is _sort-of-compatible_ with the well-known **Centronics**
connection, PASK might be connected to a classic printer with no computer in between!
But in order not to violate its timings, the data must be held for at least 0.5 us
after the `/STROBE` pulse ends (and the same amount _before_ it starts). Since the
ROM output usually stays tristated until a key code is sent (in case of interference
with unrelated port-A activity), a jumper may keep the ROM's `/OE` enabled for
direct print operation.

## Keyboard

**40 keys** decoded in a 5x8 matrix. Actually, `SHIFT`, `CONTROL` and `ALT` are
outside the matrix and directly taken as address bits for the table EPROM. The
remaining keys are `A...Z`, the ten numbers and `SPACE`. _There is **no** `RETURN`
key_, neither `BACKSPACE`, `TAB` or cursors, as all of them may be generated via
`CONTROL`-key combos (e.g. `^M` for _newline_).

It is possible to use a 10x4 matrix, although the 5x8 scheme allows the use of
lower pin count components. This latter arrangement is assumed in all the following
information.

### Suggested layouts
```
     Standard                Compact

1 2 3 4 5 6 7 8 9 0    1 2 3 4 5 6 7 8 9 0
Q W E R T Y U I O P    Q W E R T Y U I O P
 A S D F G H J K L     + A S D F G H J K L
+  Z X C V B N M  +    ^ * Z X C V B N M #
^ *   [SPACE]   * ^ 
```

> Note:
> - **`+`** is `SHIFT`
> - **`^`** is `CONTROL`
> - **`*`** is `ALT`
> - **`#`** is `SPACE` (on _compact_ layout)
>
> On the standard layout, modifier keys are _doubled_ for convenience,
but there is no distinction between them.

### Suggested 5x8 matrix decoding

Based on the previously shown layouts.

Format: _`row`.`column`_

```
               STANDARD                                    COMPACT

00  01  02  03  04  40  41  42  43  44      00  01  02  03  04  40  41  42  43  44
10  11  12  13  14  50  51  52  53  54      10  11  12  13  14  50  51  52  53  54
  20  21  22  23  24  60  61  62  63            21  22  23  24  60  61  62  63  64
      31  32  33  34  70  71  72                    32  33  34  70  71  72  73  74
                  74
```

Note: `SHIFT`, `CONTROL` and `ALT` are **outside** the matrix, thus the
matrix points `30`, `64` and `73` remain unused.

**Both** layouts suggest the use of decoding schemes designed to
simplify the wiring. On the _compact_ layout, the unused matrix points are
`20`, `30` and `31` (where the _modifier_ keys would be located).

### Keymap codes

I have tried to assign the whole character set in a reasonable way. Goals included:

- Easy access to **Spanish diacritics** (acute accent, `ñ` and diaeresis)
- Reasonable access for commonly used missing keys (_`CTRL` + number_ for most **punctuation symbols**)
- Reasonably consistent and intuitive symbol access.
- Scarce use of the rather awkward `CTRL` + `ALT` + `SHIFT` combo.


Key  |normal |`SHIFTed`|`CONTROL`|`CTRL`+`SHIFT`|`ALTERNATE` |`ALT`+`SHIFT`|`ALT`+`CTRL`|`ALT`+`CTRL`+`SHIFT`
-----|-------|---------|---------|--------------|------------|-------------|------------|--------------------
**1**|$31 `1`|$21 `!`  |$2B `+`  |$1B`ESC`      |$7C `\|`    |$A1 `¡`      |$2A `*`     |   -
**2**|$32 `2`|$22 `"`  |$27 `'`  |$1C`PLOT`     |$40 `@`     |   -         |$A2 `¢`     |$B2 `²`
**3**|$33 `3`|$B7 `·`  |$2E `.`  |$1D`DRAW`     |$23 `#`     |$BC `•`      |$B1 `±`     |$B3 `³`
**4**|$34 `4`|$24 `$`  |$2C `,`  |$1E`INCG`     |$A4 `€`     |$A3 `£`      |$A5 `¥`     |   -
**5**|$35 `5`|$25 `%`  |$3A `:`  |$1F`TXTM`     |$BA `º`     |$AA `ª`      |$F7 `÷`     |   -
**6**|$36 `6`|$26 `&`  |$3B `;`  |$5E `^`       |$AC `¬`     |$B4 `´`      |$60 `` ` `` |   -
**7**|$37 `7`|$2F `/`  |$2D `-`  |$3F `?`       |$A6 `¦`     |$5C `\`      |$BF `¿`     |   -
**8**|$38 `8`|$28 `(`  |$3C `<`  |$5B `[`       |$7B `{`     |$AB `«`      |$96 `≤`     |$9C `∞`
**9**|$39 `9`|$29 `)`  |$3E `>`  |$5D `]`       |$7D `}`     |$BB `»`      |$98 `≥`     |   -
**0**|$30 `0`|$3D `=`  |$5F `_`  |$7F`DEL`      |$7E `~`     |$9D `≈`      |$AD `≠`     |$AF `¯`
**Q**|$71 `q`|$51 `Q`  |$11`XON` |$BD `œ`       |$F8 `ø`     |$D8 `Ø`      |   -        |   -
**W**|$77 `w`|$57 `W`  |$17`ATYX`|$81 `▝`       |$B8 `ω`     |$9A `Ω`      |   -        |   -
**E**|$65 `e`|$45 `E`  |$05`ENDL`|$EA `ê`       |$E9 `é`     |$C9 `É`      |$EB `ë`     |$CB `Ë`
**R**|$72 `r`|$52 `R`  |$12`INK` |$86 `▚`       |$95 `σ`     |$B0 `°`      |$AE `®`     |   -
**T**|$74 `t`|$54 `T`  |$14`PAPR`|$89 `▞`       |$97 `τ`     |$A8 `¨`      |$92 `Γ`     |   -
**Y**|$79 `y`|$59 `Y`  |$19`PGUP`|$82 `▘`       |$FD `ý`     |$DD `Ý`      |$FF `ÿ`     |   -
**U**|$75 `u`|$55 `U`  |$15`HOME`|$FB `û`       |$FA `ú`     |$DA `Ú`      |$FC `ü`     |$DC `Ü`
**I**|$69 `i`|$49 `I`  |$09`HTAB`|$EE `î`       |$ED `í`     |$CD `Í`      |$EF `ï`     |$CF `Ï`
**O**|$6F `o`|$4F `O`  |$0F`EOFF`|$F4 `ô`       |$F3 `ó`     |$D3 `Ó`      |$F6 `ö`     |$D6 `Ö`
**P**|$70 `p`|$50 `P`  |$10`DLE` |$84 `▗`       |$B6 `¶`     |   -         |$93 `π`     |   -
**A**|$61 `a`|$41 `A`  |$01`CRTN`|$E2 `â`       |$E1 `á`     |$C1 `Á`      |$E4 `ä`     |$C4 `Ä`
**S**|$73 `s`|$53 `S`  |$13`XOFF`|$85 `▐`       |$A7 `§`     |$9F `∩`      |$94 `Σ`     |   -
**D**|$64 `d`|$44 `D`  |$04`ENDT`|$8A `▌`       |$F0 `đ`     |$D0 `Đ`      |$9B `δ`     |   -
**F**|$66 `f`|$46 `F`  |$06`RGHT`|$8F `█`       |   -        |   -         |   -        |   -
**G**|$67 `g`|$47 `G`  |$07`BELL`|$C3 `Ã`       |$E3 `ã`     |$C2 `Â`      |$E0 `à`     |$C0 `À`
**H**|$68 `h`|$48 `H`  |$08`BKSP`|$C6 `Æ`       |$E6 `æ`     |$CA `Ê`      |$E8 `è`     |$C8 `È`
**J**|$6A `j`|$4A `J`  |$0A`DOWN`|$88 `▖`       |   -        |$CE `Î`      |$EC `ì`     |$CC `Ì`
**K**|$6B `k`|$4B `K`  |$0B`UPCU`|$D5 `Õ`       |$F5 `õ`     |$D4 `Ô`      |$F2 `ò`     |$D2 `Ò`
**L**|$6C `l`|$4C `L`  |$0C`FORM`|$C5 `Å`       |$E5 `å`     |$DB `Û`      |$F9 `ù`     |$D9 `Ù`
**Z**|$7A `z`|$5A `Z`  |$1A`STOP`|$87 `▜`       |$FE `þ`     |$DE `Þ`      |$99 `ϴ`     |   -
**X**|$78 `x`|$58 `X`  |$18`BKTB`|$8B `▛`       |$D7 `×`     |   -         |$90 `α`     |   -
**C**|$63 `c`|$43 `C`  |$03`TERM`|$8D `▟`       |$E7 `ç`     |$C7 `Ç`      |$A9 `©`     |   -
**V**|$76 `v`|$56 `V`  |$16`PGDN`|$8E `▙`       |$91 `✓`     |   -         |$B9 `Δ`     |   -
**B**|$62 `b`|$42 `B`  |$02`LEFT`|$83 `▀`       |$DF `ß`     |   -         |   -        |   -
**N**|$6E `n`|$4E `N`  |$0E`EON` |$8C `▄`       |$F1 `ñ`     |$D1 `Ñ`      |$BE `ŋ`     |   -
**M**|$6D `m`|$4D `M`  |$0D`NEWL`|   -          |$B5 `µ`     |   -         |$9E `∈`     |   -
**`SPC`**|$20`SPC`|   -|$80`NBSP`|   -          |$A0 `□`     |   -        |**$00`SWTC`**|   -

Unused combos render `NUL/SWTC` ($00), although the recommended standard is **`CTRL`+`ALT`+`SPACE`**.

## Circuit design

As a **self-contained, CPU-less** device, _PASK_
must scan on its own the _keyboard matrix_
while trying to avoid the effects of bouncing
as much as possible. _Low pin count_ is a goal
for obvious reasons, and thus several matrices
have been considered.

The most obvious approach, a **4x10 matrix**,
would involve a 4 bit counter with a 4-to-16
decoder -- a 74HC154. But that would be a lot 
of pins and, being active-low its outputs,
will need the use of expensive _Shottky
diodes_ in order to prevent ghosting.

On the other hand, the **5x8 matrix** will
fit a **74HC238** decoder which, besides its
large availability (from my stock), has
_active-high_ outputs, allowing the use of
just eight unexpensive 1N4148 diodes.

Once the row is selected by the decoder,
each column line is received as _unencoded_
addresses lines; the use of a _priority
encoder_ (e.g. 74HC147) has been discarded
because of the aforementioned reason of its
active-low inputs.

The `/ROW` signal, indicating a key is pressed
on the selected row, might be generated thru a
'688 telling whether the all the column inputs
are 0, or with a '32 quad-OR gate for the same
purpose (these will generate an active-high `ROW`
signal). But neither will deal with several keys
pressed _in that row_, other than sending
unexpected `NULL`s. Thus, a second EPROM takes
the uncoded column lines and generates the `ROW`
and `/ROW` signals (both needed) whenever a
**single** key is pressed on the row.

For **better response and user experience** (plus
improved compatibility with the Centronics I/F)
the `/STROBE` signal is not just `/ROW`, but a
slightly delayed pulse or limited length, made
with the FFs of a '74, in sync with the original
_unswitched_ clock signal. Something like **400 Hz**
seems to be a suitable clock rate for _debouncing_,
although frequencies up to 1 MHz might work well
with the interface.

_Last update: 20200316-2257_
