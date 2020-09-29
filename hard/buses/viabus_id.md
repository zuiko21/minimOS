# VIAbus

This is a **backplane** for [_VIAport2_](viaport.md)-connected
devices, thru some form of _addressing_ via `PBx` lines.
In some cases, a few control lines on the lowest bits (usually `PB0` for _clock_, as a
pulse can be easily sent thru a `INC IORB: DEC IORB` sequence) are used. `PB7` is
likely to be a _"don't care"_ line, in case the _user VIA_ is the same used
for the _frequency generator_ (toggling `PB7`).

## Device ID list

Device|PB7 high|PB7 low
------|--------|-------
ASCII keyboard (`CAPS LOCK` on)|$AC|$2C
ASCII keyboard (`CAPS LOCK` off)|$AD|$2D
LCD module (`E` low)|$AE|$2E
LCD module (`E` high\*)|$AF|$2F

\*) Uses `PB0` for pulsing `E`

_more to come..._

_Last modified 20200929-1318_
