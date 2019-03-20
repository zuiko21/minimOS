# VIAport

**IDC-14** for each port, plus former 4+2 pin header for **SS-22**

### single VIAport

outside|inside
===|===
+5 v|GND
`Px0`|`Px5`
`Px1`|`Px6`
`Px2`|`Px7`
`Px3`|`Cx1`
`Px4`|`Cx2` 
GND|+5 v

### SS-22

- **GND**
- `CB1` (CLK)
- `CB2` (DAT)
- `CA2` (/STB)
- _empty_
- **+5 v** (self-powered peripherals MUST use a _Schottky_ diode)

## The whole _VIAport_ connector

outside|inside
===|===
+5 v|`GND`
`PA0`|`PA5`
`PA1`|`PA6`
`PA2`|`PA7`
`PA3`|`CA1`
`PA4`|`CA2` 
GND|+5 v
GND|
`CB1`|
`CB2`|
`CA2`|
_empty_|
+5 v|
+5 v|GND
`Px0`|`Px5`
`Px1`|`Px6`
`Px2`|`Px7`
`Px3`|`Cx1`
`Px4`|`Cx2` 
GND|+5 v
