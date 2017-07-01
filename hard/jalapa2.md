# Jalapa-II

The **Jalapa** project, originally intended to be a 65C02 machine with a *coarse*
bankswitching feature (lower 16K, including *zeropage* & *stack*) for reasonable
**multitasking** performance, gave way to the current design, around the interesting
**65C816** with a simple architecture, but still powerful enough for future *minimOS*
versions.

As this machine will take the *experimental* aim of the aborted **SDx** project,
some **configuration options** (EPROM size, I/O page...) will be available via jumpers.

## Specs

Still within design phase, here's an outline of its basic specs:

- CPU: **65C816**
- Clock speed: likely **2.304 MHz**, although might be increased in the future
- VIA: *single* **65C22**, with the typical **piezo-buzzer** at PB7/CB2
- RAM: 128/512 KB (static 32-pin)
- (E)EPROM: up to 512 KB
- Serial: single **65C51**

The most interesting *innovation* is **remapping** part of the ROM (up to 32K) into *bank 
zero*'s top, for convenient 65xx vector location. For debugging purposes, LEDs will
indicate the state of **E** (emulation mode) and **M/X** (register sizes) lines of the 65816.

### Not provided on this machine

- ROM-in-RAM copy (it's slow enough for most EPROMs)
- Real Time Clock (of little use lacking a *filesystem*, although might be included)
- Hardware *zeropage/stack* **bankswitching** (65816 allows easy multitasking)

## Memory map

Despite the 65816 providing 24-bit addresses, this computer bears a **20-bit** address
bus *(1 MiB)*. Splitting this space in two allows **up to 512 kiB RAM & 512 kiB ROM**,
which is the maximum size available in *hobbyist-friendly*, 5v DIP packages.

The usual need in 65816 systems of some ROM in *bank zero* is waived by *remapping
the upper 32 or 16k (configurable) of the first bank of ROM into bank zero. As the upper
4 address bits are not connected, this map will *repeat* every 16 banks, note the `x` as
*don't care* in the indicated addresses.

A typically configured machine goes as follows:

- $x00000-$x07FFF: RAM (all configs)
- $x08000-$x0BFFF: EPROM (if set to 32K, RAM otherwise) *from $x88000-$x8BFFF*
- $xC0000-$x0DEFF: EPROM (if set to 32 or 16K, RAM otherwise) *from $x8C000-$x8DEFF*
- $x0DF00-$x0DFFF: I/O (not valid if 8K or less assigned to ROM)
- $x0E000-$x0FFFF: EPROM (on standard configs) *from $x8E000-x$8FFFF*
- $x10000-$x1FFFF: RAM (both 128 & 512K models)
- $x20000-$x7FFFF: RAM (512K model only)
- $x80000-$xFFFFF: "high" ROM (includes *kernel* ROM as mentioned)

Configuration jumpers select the ***kernel* ROM size** (usually 32 or 16K, but smaller sizes
down to 2kiB are possible) and the **I/O page** can be freely located anywhere within
*the upper 32K of bank zero*, although it **must overlap *kernel* ROM area**, otherwise
bad things may happen (unaccessible I/O, bus contention...) 

## Glue-logic implementation

As usual in my designs, some component choices were determined by my stock... This may
lead to somewhat sub-optimal designs, although at aimed speeds shouldn't be a problem.
In any case, replacing the 74HCxx ICs by *faster* 74ACT/FCT logic will improve performance
significantly.

*Last modified: 2017-07-01*
 
