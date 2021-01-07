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

The use of a **shiftable mask** will allow proper integration of the glyph data into the
screen. Its size is expected to be _one more byte_ than the largest glyph data chunk --
that's two bytes for any 8-pixel (or less) wide font.

Transferring all scanlines of the character is highly dependent on screen memory layout.
An optimum balance between speed and memory use is achieved by means of an **offset table**
which is created every time a character is printed, avoiding complex calculations _per scanline_.

Another thing to consider is the **coordinate format**. While standard 16-bit quantities
seem reasonable, the aforementioned principle of operation makes _fixed-point notation_
particularly suited. The _base address_ might be computed the usual, text-oriented way
and, for the **horizontal** offset, the column "integer" value will be taken into account
as well, while the _pixel-precise_ offset is directly assigned from the "decimal" part.

### Proportionally spaced fonts

This engine is easily adapted to **variable-width fonts**; the mask is filled with a stream
of 1's depending on the particular character width. The stored font format is TBD, though.

## Screen layouts

Once again, the **offset table** previously created will easily adapt to any kind of VRAM
layouts. The most popular schemes include:

- **Linear scanbuffer**: the easiest one, perhaps not worth the offset table.
- **C64 style**, where the 8 bytes for each displayed character are consecutive.
- **Amstrad style**, where the first scanline of _all_ characters go first, and so on. _More suited to hardware scrolling_.



_Last modified: 20210107-1429_
