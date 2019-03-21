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
both ports, plus the former 4+2 _pin header_ for **SS-22** interface, now
placed between both ports, which may be used separately thru **IDC-14**
connectors. These are wired in a way inspired, but not directly compatible,
with those used by [Daryl Rictor's SBC-2 computer](http://sbc.rictor.org/info2.html)
but with **symmetrical power pins** as per
[Garth Wilson's design](http://wilsonminesco.com/6502primer/potpourri.html),
so in case of accidental _backwards fitting_ no harm will be made.

### _single-port_ VIAport2 pinout

outside | inside
------- | ------
**+5 v** | **GND**
`Px0` | `Px5`
`Px1` | `Px6`
`Px2` | `Px7`
`Px3` | `Cx1`
`Px4` | `Cx2` 
**GND** | **+5 v**

### SS-22 connector

1) **GND**\*
1) `CB1` (CLK)
1) `CB2` (DAT)
1) `CA2` (/STB)
1) _Key_
1) **+5 v**

## The whole _VIAport2_ connector

_Inside_ means closer to the VIA (on a computer).

Outside | Inside
=== | ===
**+5 v** | **GND**
`PA0` | `PA5`
`PA1` | `PA6`
`PA2` | `PA7`
`PA3` | `CA1`
`PA4` | `CA2` 
**GND** | **+5 v**
**GND**\* | _NC_
`CB1` | _NC_ 
`CB2` | **_Key_** (IDC-40 standard)
`CA2` | _NC_ 
_NC_ | _NC_
**+5 v** | _NC_
**+5 v** | **GND**
`PB0` | `PB5`
`PB1` | `PB6`
`PB2` | `PB7`
`PB3` | `CB1`
`PB4` | `CB2` 
**GND** | **+5 v**

\*) These GND pins should be slightly _longer_, trying to avoid damage
in case of **hot-plugging**.

_Last modified 20190321-0901_
