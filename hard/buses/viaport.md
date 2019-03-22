# VIAport2

This is intended as a **general purpose** interface.

## Changes from old _VIAport_

The older _VIAport_ was designed around the
[LED keypad](../../OS/drivers/drv_led.s), it just offered `PA0-PA7` and
`PB0-PB7`, plus `CB2`, and it was anyway _inconveniently wired_ from the
computer VIA's perspective, thus has been replaced by this new alternative.

The new connector puts the VIA's **parallel ports** together with the
**SS-22** interface in a convenient way, **simplifying the computer's
wiring** as much as possible. Both ports are now **separately accesible**
thru **IDC-14** connectors, while the previous **SS-22** _4+1 pin header_
interface is now placed between those ports, allowing the whole connection
to be made with a _garden-variety_ **_ATA_ IDC-40 connector** for utmost
convenience.

## VIAbus

There is the posibility of making a **backplane** for _VIAport2_-connected
devices, although some form of _addressing_ must be provided. `PAx` might be
used for general **data** transfers, while `PBx` lines will **select device**
and some control lines on the lowest bits (usually `PB0` for _clock_, as a
pulse can be easily sent thru a `INC IORB: DEC IORB` sequence). `PB7` is
likely to be a _"don't care"_ line, in case the _user VIA_ is the same used
for the _frequency generator_ (toggling `PB7`).

The aforementioned backplanes may include an older _VIAport_ connector plus
separate _SS-22_ header for backwards compatibility.

## Pinouts

The pinout is inspired, but not directly compatible, with that on
[Daryl Rictor's SBC-2 computer](http://sbc.rictor.org/info2.html)
although with **symmetrical power pins** as per
[Garth Wilson's design](http://wilsonminesco.com/6502primer/potpourri.html)
suggestion, so in case of accidental _backwards fitting_ no harm will be made.
_One of the +5 V pins may be connected to a **LED** on peripheral devices and
left **unconnected** on computers_, thus conspicuously **alerting** about a
reversed connection. If a computer supplies +5 V on _both_ pins, everything
**will work fine**, although the warning LED will light up with no reason.

Computers are expected to supply power to the **+5 V** pins, while
_peripherals_ may take power from these pins (within reason). In **any**
case, they should supply their power **thru a _Shottky_ diode**. This is
particularly important in case of _self-powered peripherals_.

Note: in the following diagrams, _Inside_ means closer to the VIA
(on a computer).

### _single-port_ VIAport2 pinout

outside | inside
------- | ------
_+5 V_\*\* | GND
`Px0` | `Px5`
`Px1` | `Px6`
`Px2` | `Px7`
`Px3` | `Cx1`
`Px4` | `Cx2` 
GND | +5 V

### Integrated SS-22 connector

1) GND\*
1) `CB1` (CLK)
1) `CB2` (DAT)
1) `CA2` (/STB)
1) _Key_
1) +5 V

## The complete VIAport2 connector

Outside | Inside
------- | ------
_+5 V_\*\* | GND
`PA0` | `PA5`
`PA1` | `PA6`
`PA2` | `PA7`
`PA3` | `CA1`
`PA4` | `CA2` 
GND | +5 V
GND\* | _NC_
`CB1` | _NC_ 
`CB2` | **_Key_** (IDC-40 standard)
`CA2` | _NC_ 
_NC_ | _NC_
+5 V | _NC_
_+5 V_\*\* | GND
`PB0` | `PB5`
`PB1` | `PB6`
`PB2` | `PB7`
`PB3` | `CB1`
`PB4` | `CB2` 
GND | +5 V

\*) These GND pins should be slightly _taller_, trying to avoid damage
in case of **hot-plugging**.

\*\*) Might be left _NC_ on computers and connected to a **LED** on peripherals
for _backwards fitting_ detection.

_Last modified 20190322-0855_
