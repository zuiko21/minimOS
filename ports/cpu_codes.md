# minimOS CPU codes

Executable headers on **minimOS** apps bear a byte indicating the *suitable CPU* for it. This may change in the future, as
many of these CPUs are used in ports to-be-made.

Some CPUs are binary-compatible, thus they've been grouped on their particular ports.
`LOAD_LINK` function will determine, according to the reported installed CPU (via the `GESTALT` *firmware* function),
whether a particular code chunk is able to be executed on that particular machine.

## [minimOS·65](https://github.com/zuiko21/minimOS)
- **N**: plain *NMOS* **6502** (illegal opcodes **not** supported)
- **B**: generic 65**C**02 (no `RMB/SMB/BBR/BBS` opcodes)
- **R**: *Rockwell* **R**65C02 (includes `RMB/SMB/BBR/BBS`, WDC's `STP/WAI` not guaranteed)
- **V**: 65C**816** (also *65C802*, they will execute `N` and `B` code, but not `R`)

## [minimOS·63](https://github.com/zuiko21/minimOS-63)
- **M**: standard ***Motorola* 6800** (6802/6808 are the same, software-wise)
- **U**: MC 68**01**/68**03** *Microcontrollers*
- **K**: *Hitachi* **63**01/6303 **CMOS** versions of the above (with `XGDX, SLP, TIM, AIM, OIM, EIM`) 
- **H**: *Motorola* 68**HC11** (will execute `M` and `U` code, but not `K`)

## [minimOS·09]()
- **D**: *Motorola* 68**09** (NMOS)
- **E**: *Hitachi* **63**09 (enhanced CMOS version)

## [minimOS·05]()
*This is going to be a pretty limited port, due to restricted performance on these MCU family
- **J**: *Motorola* 6805 microcontroller
- **C**: *CMOS* 68**HC**05, includes `SLP`
- **O**: 68HC**08**, notably improved version of the above

## [minimOS·80]()
- **I**: *Intel* **8080**/8085
- **Z**: *Zilog* **Z80**

## [minimOS·68]()
- **S**: *Motorola* **68000**/68008
- **T**: MC 680**20**
- **X**: MC 680**30**
- **Q**: MC 680**40**

## [minimOS·86]()
- **P**: *Intel* 80**86**/8088
- **A**: 80**286**

...

*Last modified: 2017-06-09*


