## VME-like bus for 65816

VME | 65816 | 65C02
--- | ----- | -----
/BBSY | BE | *
/BCLR | /ML | *
IRQ7 | /NMI 
IRQ6 | /IRQ
/BERR | /ABORT | -
/DS1 | VDA | -
/DS0 | VPA | -
/WRITE | R/W
AM0 | VP | *
AM1 | E | -
/LWORD | M/X | -
/DTACK | RDY
/AS | - | SYNC
AM5 | - | /SO
D8-D15 | [Card ID]
