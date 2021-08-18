# (B)IOX: (Bus) Input/Output eXpansion

## Specs

This is a _simple, direct connection_ for peripherals, particularly useful for VIA-less systems (like the [Durango](../computers/durango.md) computer).
Provides a `/SEL`ect line, four address bits and the whole 8-bit bus (_tristated_ unless `/SEL`), together with the `R/W` or `/WE` signal.

>>> Note: `/SEL` and/or `R/W` **must** be qualified

Since this link allows for easy connection of simple, dumb devices, but it is **not** suitable for a VIA or any other 65xx peripheral chip, an
**optional extension** is specified -- adding some unqualified pins plus the usual direct `R/W` and `Phi2` lines for custom qualification.
Intended for `/CS1` and `CS2` of a VIA, **both** must be decoded, although some computers may generate them in a limited way, precluding the use of
more than one VIA.

## Pinout (standard version)

function|pin|pin|function
--------|---|---|--------
+5 V	|1	|9	|D0
A0		|2	|10	|D1
A1		|3	|11	|D2
A2		|4	|12	|D3
A3		|5	|13	|D4
/WE		|6	|14	|D5
/SEL	|7	|15	|D6
GND		|8	|16	|D7

## Pinout (EXTENDED version)

function|pin|pin|function
--------|---|---|--------
_+5 V	|1	|13	|Phi2_
_**KEY**	|2	|14	|R/W_
+5 V	|3	|15	|D0
A0		|4	|16	|D1
A1		|5	|17	|D2
A2		|6	|18	|D3
A3		|7	|19	|D4
/WE		|8	|20	|D5
/SEL	|9	|21	|D6
GND		|10	|22	|D7
_**KEY**	|11	|23	|CS2_
_**KEY**	|12	|24	|/CS1_

Note the convenient pinout for a 6502: `Dx` and `R/W` match precisely those on the CPU, as do `Ax` and the lowest `+5 V`;
`Phi2` on the extended version isn't that far either.

_Last modified 20210819-0113_


