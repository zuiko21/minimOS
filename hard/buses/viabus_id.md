# VIAbus

This is a **backplane** for [_VIAport2_](viaport.md)-connected
devices, thru some form of _addressing_ via `PBx` lines.
In some cases, a few control lines on the lowest bits (usually `PB0` for _clock_, as a
pulse can be easily sent thru a `INC IORB: DEC IORB` sequence) are used. `PB7` is
likely to be a _"don't care"_ line, in case the _user VIA_ is the same used
for the _frequency generator_ (toggling `PB7`).

### Alternative implementations

Though obviously designed for systems sporting a **65(C)22 VIA**, _any_ device with a couple of
8-bit ports (one of them could be _output only_) would suffice. Even with **one 8-bit bidirectional port**
and just **two output bits** controlling a '373/374/573/574 latch would do, which is interesting for using
a _6801/6803/6301/6303_ MCU.

## Device ID list

Device|PB7 high|PB7 low
------|--------|-------
ASCII keyboard (`CAPS LOCK` on)|$AC|$2C
ASCII keyboard (`CAPS LOCK` off)|$AD|$2D
LCD module (`E` low)|$AE|$2E
LCD module (`E` high\*)|$AF|$2F
2564 EPROM _blower_ (Vpp off)|$E8...$EB|$68...$6B \*\*
2564 EPROM _blower_ (Vpp **on**)|$EC...$EF|$6C...$6F \*\*\*

\*) Uses `PB0` for pulsing `E`
\*\*) Sub-commands are `IDLE` ($x8), `LATCH L` ($x9), `LATCH H` ($xA) and `READ` ($xB)
\*\*\*) _Official_ sub-commands are `IDLE` ($xC) and `WRITE` ($xF)

_more to come..._

_Last modified 20201030-1331_
