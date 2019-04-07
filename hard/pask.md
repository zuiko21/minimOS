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
>> `+` is **`SHIFT`**
>> `^` is **`CONTROL`**
>> `*` is **`ALT`**
> Modifyer keys are doubled for convenience, but there is no distinction between them.

### Shifted codes

Key|normal|`SHIFT`|`CTRL`|`CTRL`+`SHIFT`|`ALT`|`ALT`+`SHIFT`|`ALT`+`CTRL`|`ALT`+`CTRL`+`SHIFT`
---|------|-------|------|--------------|-----|-------------|------------|--------------------
**1**|$31 `1`|$21 `!`|$2B `+`|$1B `ESC`|$ ``|$ ``|$ ``|$ ``
**2**|$32 `2`|$22 `"`|$2C `,`|$1C `FS`|$ ``|$ ``|$ ``|$ ``
**3**|$33 `3`|$23 `#`|$2D `-`|$1D `GS`|$ ``|$ ``|$ ``|$ ``
**4**|$34 `4`|$24 `$`|$2E `.`|$1E `RS`|$ ``|$ ``|$ ``|$ ``
**5**|$35 `5`|$25 `%`|$2F `/`|$1F `US`|$ ``|$ ``|$ ``|$ ``
**6**|$36 `6`|$26 `&`|$3A `:`|$5B `[`|$ ``|$ ``|$ ``|$ ``
**7**|$37 `7`|$27 `'`|$3B `;`|$5C `\`|$ ``|$ ``|$ ``|$ ``
**8**|$38 `8`|$28 `(`|$3C `<`|$5D `]`|$ ``|$ ``|$ ``|$ ``
**9**|$39 `9`|$29 `)`|$3D `=`|$5E `^`|$ ``|$ ``|$ ``|$ ``
**0**|$30 `0`|$2A `*`|$3E `>`|$5F `_`|$ ``|$ ``|$ ``|$ ``
**Q**|$71 `q`|$51 `Q`|$11 `XON`|$ ``|$ ``|$ ``|$ ``|$ ``
W|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
E|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
R|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
T|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
Y|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
U|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
I|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
O|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
P|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
A|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
S|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
D|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
F|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
G|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
H|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
1|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
J|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
K|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
L|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
Z|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
X|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
C|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
V|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
B|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
N|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``|$ ``
**M**|$6D `m`|$4D `M`|$0D `NEWL`|$3F `?`|$ ``|$ ``|$ ``|$ ``
`SPACE`|$20 ` `|$60 `` `|$40 `@`|$ ``|$ ``|$ ``|$ ``|$ ``

_Last update: 20190407-1058_
