## VME-like bus for 65816

VME | 65816 | 65C02
--- | ----- | -----
SYSCLK | Phi2 IN | *Phi2 OUT*
SYSRESET | /RST | /RST
/WRITE | R/W | R/W
/DTACK | RDY | RDY
IRQ7 | /NMI | /NMI
IRQ6 | /IRQ | /IRQ
/BBSY | BE | *1?*
/BCLR | /ML | *1?*
/BERR | /ABORT | **1**
/DS1 | VDA | **0**
/DS0 | VPA | **0**
/LWORD | M/X | **1**
AM0 | E | **1**
AM1 | /VP | *1?*
AM2 | see text | SYNC
AM3 | **1** | /SO
AM5 | **0** | **1** *(16-bit sense)*
/AS | */WE* | */WE*
D0-D7 | DO-D7 | D0-D7
D8-D15 | *NC*
A1-A7 | A0-A6 | A0-A6
AM4 | A7 | A7
A8-A15 | A8-A15 | A8-A15
A16-A23 | BA0-BA7 | **0**

`AM2`, normally carrying `SYNC` on 65C02 systems, *may* simulate that on 65816 machines
the usual way (`VDA` and `VPA`).
