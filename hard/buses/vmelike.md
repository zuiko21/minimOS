## VME-like bus for 65816

_re CPU_ | VME | 65816 | 65C02 | 6800 | 6802 | 6809 | 6809E
------ | --- | ----- | ----- | ---- | ---- | ---- | -----
O | `SYSCLK` | Phi2 IN | _Phi2 OUT_ | Phi2 | E | E | E
oc | `SYSRESET` | /RES | /RES | /RESET | /RESET | /RESET | /RESET
3s | `/WRITE` | R/W | R/W | R/W | R/W | R/W | R/W
oc | `/DTACK` | _RDY_ | RDY | /HALT | MR | /HALT | /HALT
oc | `/IRQ7` | /NMI | /NMI | /NMI | /NMI | /NMI | /NMI
oc | `/IRQ6` | /IRQ | /IRQ | /IRQ | /IRQ | /IRQ | /FIRQ
oc | `/IRQ5` | /IRQ | /IRQ | /IRQ | /IRQ | /IRQ | /FIRQ
oc | `/IRQ4` | /IRQ | /IRQ | /IRQ | /IRQ | /IRQ | /FIRQ
oc | `/IRQ3` | /IRQ | /IRQ | /IRQ | /IRQ | /IRQ | /IRQ
oc | `/IRQ2` | /IRQ | /IRQ | /IRQ | /IRQ | /IRQ | /IRQ
oc | `/IRQ1` | /IRQ | /IRQ | /IRQ | /IRQ | /IRQ | /IRQ
oc | `/BBSY` | BE | **?** | DBE, _/TSC_ | **1** | /DMA-BREQ | _/TSC_
tp | `/BCLR` | /ML | **?** | **1** | **1** | **1** | _/BUSY_
oc | `/BERR` | /ABORT | **1** | **1** | **1** | **1** | **1** (AVMA?)
3s | `/DS1` | VDA | **1** | VMA | VMA | BS | BS
3s | `/DS0` | VPA | SYNC | **0** | **0** | BA | BA
3s | `/LWORD` | M/X | **1** | **1** | **1** | **1** | **1**
3s | `AM0` | **0** | **1** | **1** | **1** | **1** | **1** _(65816 sense)_
3s | `AM1` | Emul. | **1** | **1** | **1** | **1** | **1**
3s | `AM2` | /CE10 | **1** | **1** | **1** | **1** | **1**
3s | `AM3` | /CE11 | /SO | **1** | **1** | **1** | **1**
3s | `AM5` | /VP | **?** | **1** | **1** | **1** | **1**
3s | `/AS` | ? | ? | ? | Phi1 | Q | Q _(16-bit bus?)_
3s | `D0-D7` | D0-D7 | D0-D7 | D0-D7 | DO-D7 | D0-D7 | D0-D7
3s | `D8-D15` | _NC, reserved_
3s | `A1-A7` | A0-A6 | A0-A6 | A0-A6 | A0-A6 | A0-A6 | A0-A6
3s | `AM4` | A7 | A7 | A7 | A7 | A7 | A7
3s | `A8-A15` | A8-A15 | A8-A15 | A8-A15 | A8-A15 | A8-A15 | A8-A15
3s | `A16-A23` | BA0-BA7 | **0** | **0** | **0** | **0** | **0**

Notes:

- `RDY` on 65816 systems (or W65C02**S**) may be used as a **clock stretching** input.
- `/DS1` will stay **high** on '02 systems, letting `SYNC` into `/DS0`, allowing common circuitry in most cases.
- Some 65C02's have `/ML`, `/VP` and `BE` lines, otherwise they should use adequate _pull-ups_ on bus.
- Values in _italics_ are not generated/taken by the CPU itself, but modified on board for bus compatibility among platforms.
- **Fixed values must be set thru _pull-up_ (or _pull-down_) resistors.**
- Most IRQ lines are tied together _on the CPU side_. Peripheral cards should put their requests on **one** line according to a reasonable priority.
- **SIXtation** allows for external decoding of the _ninth_ RAM megabyte, if fitted, thru `/CE10` and `/CE11`, open-collector lines **pulled-up** in any case.

`SERCLK` may be used as DOTCLK.

_Last modified 20191204-1920_
