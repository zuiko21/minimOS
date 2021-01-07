# Arbitrary pixel position text printing

### Some thoughts:

`AT` command used to be followed by two bytes indicating row and column (ASCII >= 32).
They can be preceded by another byte (ASCII < 32) with the LSB in _fixed point_ notation.
Since the addressable character grid was up to 224x224, the maximum supported
resolution would be **7168x7168**, larger than the _Tektronix_-based 4096x4096
graphic support.

For instance:

- 640x400 pixel, 80x25 char screen (8x16 font)
- y=12 would be 13th scanline within first row
- x=12 would be 5th pixel of _second_ column
- transmitted values are `CHR$(12)`, `CHR$(32)`, `CHR$(4)`, `CHR$(33)`
- fixed point notation: y=0.75 (12/16), x=1.5 (12/8)

Note that non-graphic screens **should ignore** such LSBs _below CHR$(32)_ in order
to achieve backwards compatibility with non-graphic printing devices -- they will
round the coordinates to the character grid, ignoring the LSB (decimal part). This
is simply implemented via a **`BCC`** after the `SBC #32` of coordinate scaling.

## General principles



_Last modified: 20210107-1218_
