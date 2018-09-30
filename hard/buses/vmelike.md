## VME-like bus for 65816

*re CPU* | VME | 65816 | 65C02 | 6800 | 6802
------ | --- | ----- | ----- | ---- | ----
O | SYSCLK | Phi2 IN | *Phi2 OUT* | Phi2 | E
oc | SYSRESET | /RES | /RES | /RESET | /RESET
3s | /WRITE | */WE* | */WE* | */WE* | */WE* | */WE*
oc | /DTACK | *RDY* | RDY | /HALT | MR
oc | /IRQ7 | /NMI | /NMI | /NMI | /NMI
oc | /IRQ6 | /IRQ | /IRQ | /IRQ | /IRQ
oc | /IRQ5 | /IRQ | /IRQ | /IRQ | /IRQ
oc | /IRQ4 | /IRQ | /IRQ | /IRQ | /IRQ
oc | /IRQ3 | /IRQ | /IRQ | /IRQ | /IRQ
oc | /IRQ2 | /IRQ | /IRQ | /IRQ | /IRQ
oc | /IRQ1 | /IRQ | /IRQ | /IRQ | /IRQ
oc | /BBSY | BE | **1?** | DBE, */TSC* | **1** 
tp | /BCLR | /ML | **1?** | **1** | **1**
oc | /BERR | /ABORT | **1** | **1** | **1**
3s | /DS1 | VDA | **1** | VMA | VMA
3s | /DS0 | VPA | SYNC | **0** | **0**
3s | /LWORD | M/X | **1** | **1** | **1**
3s | AM0 | **0** | **1** | **1** | **1** | **1** *(65816 sense)*
3s | AM1 | E | **1** | **1** | **1**
3s | AM2 | /VP | **1?** | **1** | **1**
3s | AM3 | **1** | /SO | **1** | **1** | **1**
3s | AM5 | **1** | **1** | **1** | **1** | **1** *(16-bit bus)*
3s | /AS | R/W | R/W | R/W | R/W
3s | D0-D7 | D0-D7 | D0-D7 | D0-D7 | DO-D7
3s | D8-D15 | *NC, reserved*
3s | A1-A7 | A0-A6 | A0-A6 | A0-A6 | A0-A6
3s | AM4 | A7 | A7 | A7 | A7
3s | A8-A15 | A8-A15 | A8-A15 | A8-A15 | A8-A15
3s | A16-A23 | BA0-BA7 | **0** | **0** | **0**

- `RDY` on 65816 systems (or W65C02**S**) may be used as a **clock stretching** input.
- `/DS1` will stay **high** on '02 systems, letting `SYNC` into `/DS0`, allowing common
circuitry in most cases.
- Some 65C02 have `/ML`, `/VP` and `BE` inputs, otherwise they should use
adequate pull-ups.
- Values in *italics* are not generated/taken by the CPU itself, but modified
on board for bus compatibility among platforms.
- **Fixed values must be set thru *pull-up* (or *pull-down*) resistors.**
