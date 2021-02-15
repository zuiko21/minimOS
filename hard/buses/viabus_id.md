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
ASCII keyboard (`CAPS LOCK` on)|$AC, $A8\*\*\*\*|$2C, $28\*\*\*\*
ASCII keyboard (`CAPS LOCK` off)|$AD, $A9\*\*\*\*|$2D, $29\*\*\*\* 
LCD module (`E` low\*, `RS` low)|$AA|$2A
LCD module (`E` low\*, `RS` high)|$AE|$2E
CText VDU (CRTC control\*)|$C8...$CF|$48...$4F
CText VDU (VRAM access\*\*\*\*\*)|$D0...$D3|$50...$53
2564 EPROM _blower_ (Vpp off)|$E8...$EB|$68...$6B \*\*
2564 EPROM _blower_ (Vpp **on**)|$EC...$EF|$6C...$6F \*\*\*

\*) Uses `PB0` for pulsing `E`, adding 1 to values

\*\*) Sub-commands are `IDLE` ($x8), `LATCH L` ($x9), `LATCH H` ($xA) and `READ` ($xB)

\*\*\*) _Official_ sub-commands are `IDLE` ($xC) and `WRITE` ($xF)

\*\*\*\*) _Official_ entry is at $AC/AD, $A8/$A9 should be an alias, or simply reserved

\*\*\*\*\*) Sub-commands are `LATCH H` ($x0), `LATCH L` ($x1), `PRESELECT` ($x2) and `WRITE` ($x3),
which are indeed shared with other _VIAbus_-connected VDUs.

### Older devices adapted to VIAbus spec

Due to the versatility of the **VIAbus** interface, it makes sense to adapt
older peripherals in order to share the connection. Of particular is the
_LED-Keypad_ which in turn allows for quick boot selection, in a similar
way as the ASCII keyboard. A possible implementation would be:

- `$A0` = Select enabled display (`CB2` low, latches column from `PA4...PA7`)
- `$A4` = Disable display (`CB2` high _and latch column from `PA4...PA7`_)
- `$A8` = Latch display data from `PA` (like transferring via `PB` old-style)
- `$AC` = Read column on `PA0...PA3` (as selected from `PA4...PA7`)

Note that the `$AC` command is shared with the **ASCII keyboard**, thus
_able to read the boot selection just the same way_, by putting `%0001xxxx` on `PA`
and reading `PA0-3`, _while `PB` is $AC_. The unusual latching scheme
allows the use of a '374/574 for display data and a '174 for latching both the
active LED (from `PA4...PA7`) and the `CB2` status (from `PB2`, when `PB3` is low).
Device section just looks for `PB` as **%1010xx00**, which together with
_command decoding_ could be done with a couple of '139s.

_more to come..._

_Last modified 20210215-1340_
