# PASK: _Port A_ Simple Keyboard

Intended as a simple keyboard capable of generating the **full range of characters**
(if not in the most convenient way) with **really simple software support**. This
device simply puts into the **user VIA's _port A_** (in _handshake_ input mode) the
desired ASCII code, to be directly read thru a trivial driver, allowing easy
interface _even in heaviliy crashed systems_.

## Hardware interface

The now standard **VIAport 2** in a simple port fashion will suffice. It must be
connected to port A, as port B does not support _read handshake_. Actually, only `CA1`
is used besides the port lines `PA0-PA7`.

## Keyboard

**40 keys** decoded in a 5x8 matrix. Actually, `SHIFT`, `CONTROL` and `ALT` are
outside the matrix and directly taken as address bits for the table EPROM. The
remaining keys are `A...Z`, the ten numbers and `SPACE`. _There is **no** `RETURN`
key_, neither `BACKSPACE`, `TAB` or cursors, as all of them may be generated via
`CONTROL`-key combos (e.g. `^M` for _newline_).

It is possible to use a 10x4 matrix, although the 5x8 scheme allows the use of
lower pin count components.

### Suggested layout
```
1 2 3 4 5 6 7 8 9 0
Q W E R T Y U I O P
 A S D F G H J K L
+  Z X C V B N M  +
^ *   [SPACE]   * ^ 
```

> Note:
> - `+` is **`SHIFT`**
> - `^` is **`CONTROL`**
> - `*` is **`ALT`**
>
> Modifier keys are doubled for convenience, but there is no distinction between them.

### Shifted codes

Key|normal|`SHIFT`|`CTRL`|`CTRL`+`SHIFT`|`ALT`|`ALT`+`SHIFT`|`ALT`+`CTRL`|`ALT`+`CTRL`+`SHIFT`
---|------|-------|------|--------------|-----|-------------|------------|--------------------
**1**|$31 `1`|$21 `!`|$2B `+`|$1B `ESC`|$BA `ord o`|$AA `ord a`|$A1 `¡`|$B1 `+-`
**2**|$32 `2`|$22 `"`|$2C `,`|$1C `FS`|$B2 `^2`|$B3 `^3`|$A2 `cent`|$ ` `
**3**|$33 `3`|$23 `#`|$2D `-`|$1D `GS`|$B7 `.`|$BC `•`|$A3 `£`|$F7 `÷`
**4**|$34 `4`|$24 `$`|$2E `.`|$1E `RS`|$85 ` `|$8A ` `|$A4 `€`|$83 ` `
**5**|$35 `5`|$25 `%`|$2F `/`|$1F `US`|$86 ` `|$89 ` `|$A5 `¥`|$8C ` `
**6**|$36 `6`|$26 `&`|$3A `:`|$5B `[` |$7B `{`|   -   |   -   |$AC `not`
**7**|$37 `7`|$27 `'`|$3B `;`|$5C `\` |$7C `pipe`|$A6 `bpipe`|   -   |   -
**8**|$38 `8`|$28 `(`|$3C `<`|$5D `]` |$7D `}`|$96 `<=`|$9C `inf`|$AB `《`
**9**|$39 `9`|$29 `)`|$3D `=`|$5E `^` |$7E `~`|$AD `not eq`|$9D `approx`|   -
**0**|$30 `0`|$2A `*`|$3E `>`|$5F `_` |$7F `DEL`|$98 `>=`|$AF `macron`|$BB `》`
**Q**|$71 `q`|$51 `Q`|$11 `XON` |$BD `œ`|$F8 `ø`|$D8 `Ø`|$F5 `õ`|$D5 `Õ`
**W**|$77 `w`|$57 `W`|$17 `ATYX`|   -   |$B8 `omega`|$9A `OMEGA`|   -   |   -
**E**|$65 `e`|$45 `E`|$0E `ENDL`|$EA `ê`|$E9 `é`|$C9 `É`|$EB `ë`|$CB `Ë`
**R**|$72 `r`|$52 `R`|$12 `INK` |   -   |$95 `rho`|$B0 `°`|$AE `(r)`|$92 `gamma`
**T**|$74 `t`|$54 `T`|$14 `PAPR`|   -   |$97 `tau`|   -   |   -   |   -
**Y**|$79 `y`|$59 `Y`|$19 `PGUP`|   -   |$FD `ý`|$DD `Ý`|$FF `y uml `|$A8 `uml`
**U**|$75 `u`|$55 `U`|$15 `CRTN`|$FB `û`|$FA `ú`|$DA `Ú`|$FC `ü`|$DC `Ü`
**I**|$69 `i`|$49 `I`|$09 `HTAB`|$EE `î`|$ED `í`|$CD `Í`|$EF `ï`|$CF `Ï`
**O**|$6F `o`|$4F `O`|$0F `EMOF`|$F4 `ô`|$F3 `ó`|$D3 `Ó`|$F6 `ö`|$D6 `Ö`
**P**|$70 `p`|$50 `P`|$10 `DLE` |   -   |$B6 `pg`|   -   |   -   |   -
**A**|$61 `a`|$41 `A`|$01 `HOME`|$E2 `â`|$E1 `á`|$C1 `Á`|$E4 `ä`|$C4 `Ä`
**S**|$73 `s`|$53 `S`|$13 `XOFF`|   -   |$A7 `§`|   -   |   -   |   -
**D**|$64 `d`|$44 `D`|$04 `ENDT`|   -   |$F0 `đ`|$D0 `Đ`|$9B `delta l`|$B9 `delta u`
**F**|$66 `f`|$46 `F`|$06 `RGHT`|$8F &#9608;|$81 &#9629;|$82 &#9624;|$84 &#9600;|
$88 &#9623;
**G**|$67 `g`|$47 `G`|$07 `BELL`|$C3 `Ã`|$E3 `ã`|$C2 `Â`|$E1 `à`|$E2 `À`
**H**|$68 `h`|$48 `H`|$08 `BKSP`|$C6 `Æ`|$E6 `æ`|$CA `Ê`|$E8 `è`|$EA `È`
**J**|$6A `j`|$4A `J`|$0A `DOWN`|   -   |   -   |$CE `Î`|$ED `ì`|$EE `Ì`
**K**|$6B `k`|$4B `K`|$0B `UPCU`|$D5 `Õ`|$F5 `õ`|$D4 `Ô`|$F2 `ò`|$F4 `Ò`
**L**|$6C `l`|$4C `L`|$0C `FORM`|$C5 `Å`|$E5 `å`|$DB `Û`|$F9 `ù`|$FB `Ù`
**Z**|$7A `z`|$5A `Z`|$1A `STOP`|$87 ` `|$FE `þ`|$DE `Þ`|   -   |   -
**X**|$78 `x`|$58 `X`|$18 `BKTB`|$8B ` `|$D7 `×`|   -   |$90 `alpha`|   -
**C**|$63 `c`|$43 `C`|$03 `TERM`|$8D ` `|$E7 `ç`|$C7 `Ç`|$A9 `(c)`|$9F `inters`
**V**|$76 `v`|$56 `V`|$16 `PGDN`|$8E ` `|$91 `tick`|   -   |   -   |   -
**B**|$62 `b`|$42 `B`|$02 `LEFT`|   -   |$DF `ß`|   -   |   -   |$99 `theta`
**N**|$6E `n`|$4E `N`|$0E `EMON`|   -   |$F1 `ñ`|$D1 `Ñ`|$BE `eng`|$93 `pi`
**M**|$6D `m`|$4D `M`|$0D `NEWL`|$3F `?`|$B5 `mu`|$BF `¿`|$9E `belong`|$94 `sigma`
**`SPACE`**|$20 `SPACE`|$60 `grave`|$40 `@`|$80 `NBSP`|$B4 `acute`|$A0 `□`|   -   |   -

Unused combos render `NULL` ($00)

_Last update: 20190407-1450_
