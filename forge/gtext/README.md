# Arbitrary pixel position text printing

### Some thoughts:

AT command used to be followed by two bytes indicating row and column (ASCII >= 32).
They can be preceded by another byte (ASCII < 32) with the LSB in fixed point notation.
For instance:

- 640x400 pixel, 80x25 char screen (8x16 font)
- x=12, y=12 is actually row 1 (first), column 2 (second)
- 13th scanline within first row
- 5th pixel of second column
- transmitted values are CHR$(12), CHR$(32), CHR$(4), CHR$(1)
- fixed point notation: y=0.75, x=1.5

Note that non-graphic screens should ignore such LSBs **below CHR$(32)**
 
