# minimOS

Minimalistic, portable, scalable Operating System for everything from embedded devices to (quasi) full-featured desktop computers!

Initial target is the venerable 65(C)02 and its big brother, the 16-bit enabled 65816 (minimOS·16) which will keep compatibility with existing '02 code. But ports to many other CPU architectures are in mind, like the Motorola 68xx / Hitachi 63xx series (minimOS·63, with the interesting 6809/6309 branch as minimOS·69), 680x0 (minimOS·68), 8080/8085/Z80 (minimOS·80), even (God forbid! :-) the common x86 (minimOS·86). I really have little-to-no knowledge about this CPU family, nor about the usual household PC architecture, but if someone more knowledgable than me about these is able to port minimOS (hopefully not too much of a chore), would make a very interesting 'breath' to (otherwise useless) older PCs.

Currently in a VERY early development stage, hopefully will become (to me) a common reference platform for deployment of computer-related appliances -- think about embedded systems, like the original intent: an Actual Exposure Time Meter for classic photographic cameras. But by virtue of its modularity and scalability would equally serve to a whole breed of home-made, retro-inspided computers.

With great embarrassment I have to admit never have owned a 65xx computer... but suport for these classic machines shouldn't be difficult to add -- for instance, I have declared as 'reserved' the two first zero-page bytes in case the utterly popular Commodore-64 (using a 6510) is targeted. Back to my own-designed machines, here's the current history & roadmap:

MTE ("Medidor de Tiempos de Exposición", Exposure Time Meter)
Status: planned, finishing design.
Specs: 1 MHz 6503 (28 pin, 4 kiB space), 128-byte RAM, 3 kiB-EPROM, VIA 6522, four (very large) 7-segment LED digits.

SDd ("Sistema de Desarrollo didáctico", Development System)
Status: WORKING!
Specs: 1 MHz 65SC02, 2 kiB RAM, 2-4 kIB (E)EPROM, VIA 65C22. Currently interfaced to a 4-digit LED-keypad.

CHIHUAHUA
Status: debugging hardware :-(
Specs: Soldered, compact version of SDd. Strange bug with VIA, not solved yet. Probably abandoned.

CHIHUAHA PLUS
Status: under construction.
Specs: 1 MHz (socketed) 65C02, 16 kiB RAM, 32 kiB EPROM, VIA 65C22. SS-22 and obsolete "VIAport" connections, in a similar form-factor as CHIHUAHUA

SDx ("Sistema de Desarrollo eXpandible", Expansible Develpment System)
Status: abandoned :-(
Specs: 2 MHz 65C02/102, 8-16 kIB RAM, 32 kiB EPROM, VIA 65C22, ACIA 65SC51, RTC 146815.

Baja
Status: aborted :-(
Specs: intended to be a fully bankswitching 65C02 SBC, but also pluggable into a backplane.

SDm ("Sistema de Desarrollo mejorado", Improved Development System)
Status: in design stage
Specs: 2 MHz 65C02, 128 kiB RAM (16K + 7*16K banks), 32 kiB EPROM, VIA 65C22, ACIA 65SC51 in breadboard.

Veracruz
Status: in design stage
Specs: 2 MHz (at least) 65816, 512 kiB RAM, 32 kiB EPROM, 2 x VIA 65C22, ACIA/UART (16C550/2?), RTC(?)

Jalisco
Status: in design stage
Specs: 12 MHz (hope!) 65816, up to 8 MiB RAM (2 x Garth's modules), 2 x VIA 65C22, UART, 65SIB (with SD-card slot) and SS-22 ports. To be buit on real PCB with PLCC components, likely with PLD decoding.

...more to come!
