# VIAport2

This is intended as a **general purpose** interface. The older _VIAport_
was designed around the [LED keypad](../../OS/drivers/drv_led.s), it just
offered `PA0-PA7` and `PB0-PB7`, plus `CB2`, and was anyway inconveniently
wired from the computer VIA's perspective.

## Changes from old _VIAport_

The main advantages of the new connector are _reuniting_ the VIA's **parallel
ports** together with the **SS-22** interface in a convenient way, plus
**simplifying the computer's wiring** as much as possible.
The new design sports the whole VIA interface in separate connectors, but
a _garden-variety_ **_IDE_ IDC-40 connector** may be used for connecting
both ports, plus the former 4+1 _pin header_ for **SS-22** interface, now
placed between both ports, which may be used separately thru **IDC-14**
connectors.

The pinout is inspired, but not directly compatible, with that used by
[Daryl Rictor's SBC-2 computer](http://sbc.rictor.org/info2.html)
although with **symmetrical power pins** as per
[Garth Wilson's design](http://wilsonminesco.com/6502primer/potpourri.html),
suggestion, so in case of accidental _backwards fitting_ no harm will be made.
_One of the +5 V pins may be connected to a **LED** on peripheral devices and
left **unconnected** on computers_, thus **alerting** about a reversed connection.

## VIAbus

There is the posibility of making a **backplane** for _VIAport2_-connected
devices, although some form of _addressing_ must be provided. `PAx` might be
used for general **data** transfers, while `PBx` lines will **select device**
and some control lines on the lowest bits (usually `PB0` for _clock_, as a
pulse can be esaily sent thru a `INC IORB: DEC IORB` sequence). `PB7` is
likely to be a _"don't care"_ line, in case the _user VIA_ is the same used
for the _frequency generator_ (toggling `PB7`).

The aforementioned backplanes may include an older _VIAport_ connector plus
separate _SS-22_ header for backwards compatibility.

## Pinouts

_Inside_ means closer to the VIA (on a computer).

Computers are expected to supply power to all **+5 V** pins, while
_peripherals_ may take power from these pins (within reason). In
case of _self-powered peripherals_, they should supply their power
**thru a _Shottky_ diode**.

### _single-port_ VIAport2 pinout

outside | inside
------- | ------
+5 V\*\* | GND
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
+5 V\*\* | GND
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
+5 V\*\* | GND
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

_Last modified 20190321-0947_
