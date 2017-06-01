# minimOS ports to other architectures

These are some planned ports of **minimOS·65** (or just **minimOS**, by default) for CPUs other than the 65(C)02 series. *Please note that the 65C816 port is integrated within the original branch.*

Planned so far are:

## minimOS·65
It's the standard version, available at the [OS directory](../OS) outside this one! Will support **NMOS** 6502, generic CMOS **65C02** plus the **Rockwell/WDC** extensions (R65C02/W65C02S).

## minimOS·16
For 65C816, will be able to execute 65(C)02 code *in native mode*, although NOT if it's specifically written for the R65C02 --- no RMB/SMB/BBR/BBS opcodes on the '816! *This is currently integrated within minimOS·65.*

## minimOS·63
Originally for the Motorola **6800** and derivatives (6802, the 6801/6803 microcontrollers, and the *Hitachi CMOS* versions **63**01/**63**03). Currently seems to support only a reduced API (up to 85 system calls instead of 128). *The 6809/6309 ISA is only partially compatible, thus will use a different port (minimOS-**09**) lacking the inter-operativity of the '816 version.*

## minimOS·09
For Motorola **6809** and the much improved **Hitachi 6309**. *Details for this port are mostly TBD*, although isn't likely to be compatible with -63 code.

## minimOS·68
For Motorola **680x0** series, long ago thought of.

## minimOS·80
For Intel **8080**/8085 and Zilog-**Z80**. Not sure if modern Z-80 derivatives will be supported.

## minimOS·86
**This will be a very interesting port** allowing the use of regular PCs, although my knowledge about these CPUs or the general PC architecture is close to nothing...

*...and hopefully many more to come (MIPS, ARM...)*

