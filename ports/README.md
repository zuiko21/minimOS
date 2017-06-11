# minimOS ports to other architectures

These are some planned ports of **minimOS·65** (or just **minimOS**, by default) for CPUs
other than the 65(C)02 series. *Please note that the 65C816 port is integrated within the
original branch*.

Planned so far are:

## [minimOS·65](../OS)
It's the standard, original version, available at the OS directory within this repository!
Will support **NMOS** 6502, generic CMOS **65C02** plus the **Rockwell/WDC** extensions
(R65C02/W65C02S). It now *integrates* the port previously known as
[**minimOS·16**](16.md) 
for the **65C816** CPU, which is able to execute 65(C)02 code *in native mode* (albeit
restricted to *bank zero*. The only 65xx apps unable to run on the '816 are those
specifically written for the R65C02 --- no RMB/SMB/BBR/BBS opcodes on the '816!

## [minimOS·63](63.md)
Originally for the Motorola **6800** and derivatives (6802, the 6801/6803 microcontrollers,
and the *Hitachi CMOS* versions **63**01/**63**03). The Motorola 68**HC11** is supported too.
Currently seems to implement only a *restricted API* (up to 85 system calls instead of 128).
*The 6809/6309 ISA is only partially compatible, thus will use a different port
(minimOS-**09**, see below) lacking the inter-operativity of the '816 version.*

## [minimOS·09](09.md)
For Motorola **6809** and the much improved **Hitachi 6309**.
*Details for this port are mostly TBD*, although it **won't** be compatible with *-63* code.

## [minimOS·05](05.md)
For Motorola's 68**05**/146805/68**HC05**/68**HC08** *medium performance* microcontrollers.
*This is going to be a rather **limited port** because of restricted performance on 
these MCUs*.

Please note that, as '05 family is considered *legacy* and they have *no external bus* 
connections (with the exception of the ROM-less 146805**E2**), only those models with
*EPROM* (68**7**05, 1468**7**05, 68HC**7**05) or *EEPROM* (68HC**8**05) instead of
*mask ROM* could be used.

I'm not sure if ordering a mask ROM based 68HC**08** is profitable or even feasible,
although the *Flash* based versions (68HC**9**08) seem suitable.   

## [minimOS·68](68.md)
For Motorola **680x0** series, long ago thought of.

## [minimOS·80](80.md)
For Intel **8080**/8085 and Zilog-**Z80**. Not sure if modern Z-80 derivatives
will be supported.

## [minimOS·86](86.md)
**This will be a very interesting port** allowing the use of regular PCs,
although my knowledge about these CPUs or the general PC architecture is close to nothing...

*...and hopefully many more to come (MIPS, ARM...)*

Most (if not all) of these ports may support several *compatible* CPUs, with increasing
features. In order to take advantage of them wherever possible, each **executable *file***
(or *ROMmable* binary blob, for that matter) codes the
[native CPU into the third byte](cpu_codes.md). Some parts of the code might use
*conditional assembly*, generating appropriate code for the target CPU (as defined in
the `options.h` file).

*Last modified 2017-06-11*
