# PASK: _Port A_ Simple Keyboard

Intended as a simple keyboard capable of generating the **full range of characters**
(if not in the most convenient way) with **really simple software support**. This
device simply puts into the **user VIA's _port A_** (in _handshake_ input mode) the
desired ASCII code, to be directly read thru a trivial driver, allowing easy
interface _even in heaviliy crashed systems_.

## Hardware interface

The now standard **VIAport 2** in a simple port fashion will suffice. It is
expected to be connected to port A. Actually, only `CA1` is used besides the port
lines `PA0-PA7`.

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

Note: `+` is **`SHIFT`**, `^` is **`CONTROL`** and `*` is **`ALT`**

_Last update: 20190406-2306_
