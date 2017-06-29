* Jalapa-II

The **Jalapa** project, originally intended to be a 65C02 machine with a *coarse*
bankswitching feature (loewr 16K, including *zeropage* & *stack*) for reasonable
**multitasking** performance, gave way to the current design, around the interesting
**65C816** with a simple architecture, but still powerful enough for future *minimOS*
versions.

** Specs

Still within design phase, here's an outline of its basic specs:

- CPU: **65C816**
- Clock speed: likely **2.304 MHz**, although might be increased in the future
- VIA: *single* **65C22**, with the typical **piezo-buzzer** at PB7/CB2
- RAM: 128/512 KB (static 32-pin)
- (E)EPROM: up to 512 KB
- Serial: single **65C51**

The most interesting *innovation* is remapping part of the ROM (up to 32K) into *bank 
zero*'s top, for convenient 65xx vector location.

*Last modified: 2017-06-29*
 
