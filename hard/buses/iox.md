# (B)IOX: (Bus) Input/Output eXpansion

## Specs

This is a _simple, direct connection_ for peripherals, particularly useful for VIA-less systems (like the [Durango](../computers/durango.md) computer).
Provides a qualified `/SEL`ect line, four address bits and the whole 8-bit bus, together with the `R/W` signal (qualified as well).

Since this link allows for easy connection of simple, dumb devices, but it is **not** suitable for a VIA or any other 65xx peripheral chip, an
**optional extension** is specified -- adding an **unqualified `/USEL`** plus the usual direct `R/W` and `Phi2` lines for custom qualification.

## Pinout (standard version)

function|pin|pin|function
--------|---|---|--------
+5 V	|1	|9	|D0
A0		|2	|10	|D1
A1		|3	|11	|D2
A2		|4	|12	|D3
A3		|5	|13	|D4
/SEL	|6	|14	|D5
/WE		|7	|15	|D6
GND		|8	|16	|D7

## Pinout (EXTENDED version)

function|pin|pin|function
--------|---|---|--------
/USEL	|1	|11	|Phi2
**KEY**	|2	|12	|R/W
+5 V	|3	|13	|D0
A0		|4	|14	|D1
A1		|5	|15	|D2
A2		|6	|16	|D3
A3		|7	|17	|D4
/SEL	|8	|18	|D5
/WE		|9	|19	|D6
GND		|10	|20	|D7

_Last modified 20210422-1343_


