## VME-like bus for 65816

VME | 65816 | 65C02
--- | ----- | -----
SYSCLK | Phi2 IN | Phi2 OUT
SYSRESET | /RST | /RST
/WRITE | R/W | R/W
/DTACK | RDY | RDY
IRQ7 | /NMI | /NMI
IRQ6 | /IRQ | /IRQ
/BBSY | BE | ?
/BCLR | /ML | ?
/BERR | /ABORT | **1**
/DS1 | VDA | **0**
/DS0 | VPA | **0**
/LWORD | M/X | **1**
AM0 | E | **1**
AM1 | VP | ?
AM4 | 1 | /SO
AM5 | 0 | **1** *(16-bit sense)*
/AS | 0 | SYNC
D8-D15 | *???*

