# Jalapa-II

The **Jalapa** project, originally intended to be a 65C02 machine with a *coarse*
bankswitching feature (lower 16K, including *zeropage* & *stack*) for reasonable
**multitasking** performance, gave way to the current design, around the interesting
**65C816** with a simple architecture, but still powerful enough for future *minimOS*
versions.

As this machine will take the *experimental* aim of the aborted **SDx** project,
some **configuration options** (EPROM size, I/O page...) were to be available via
jumpers, but deemed too complicated.

## Specs

Still within design phase, here's an outline of its basic specs:

- CPU: **65C816**
- Clock speed: likely **2.304 MHz**, although might be increased in the future
- VIA: *single* **65C22**, with the typical **piezo-buzzer** at PB7/CB2
- RAM: 128/512 KB (static 32-pin)
- (E)EPROM: up to 512 KB
- Serial: single **65C51**, really needed?
- *VME-like* **expansion bus**, essentialy the 65816 pins

Although its most interesting feature was **remapping** part of the ROM (up to 32K) 
into *bank zero*'s top, for convenient 65xx vector location,
once again this was feature was discarded and went instead for
the use of ***two* separate ROM** sockets (for `sys` and `lib` *implicit* volumes,
namely the **Kernel** and **application** EPROMs).

For debugging purposes, 
LEDs will indicate the state of **E** (emulation mode) and **M/X** (register sizes) lines of the 65816.

### Not provided on this machine

- ROM-in-RAM copy (it's slow enough for most EPROMs)
- Real Time Clock (of little use lacking a *filesystem*, although might be included)
- Hardware *zeropage/stack* **bankswitching** (65816 allows easy multitasking)
- 6845-based video output (optional thru the *expansion bus*)

## Memory map

Despite the 65816 providing 24-bit addresses, this computer bears a **20-bit** address
bus *(1 MiB)*. Splitting this space in two allows **up to 512 kiB RAM & 512 kiB ROM**,
which is the maximum size available in *hobbyist-friendly*, 5v DIP packages.

The usual need in 65816 systems of some ROM in *bank zero* is no longer *remapping
the upper 32k of the first bank of ROM into bank zero, but using a separate ROM
instead.

As the upper 4 address bits are not used, note the `x` as
*don't care* in the indicated addresses. No provision is made to avoid *mirroring*,
thus suitable firmware should take that into account.

A typically configured machine goes as follows:

- $x00000-$x07FFF: RAM (all configs)
- $x80000-$x0DEFF: EPROM (**kernel** & **firmware**)
- $x0DF00-$x0DFFF: I/O
- $x0E000-$x0FFFF: EPROM (continued kernel & firmware, including *hardware vectors*)
- $x10000-$x1FFFF: RAM (both 128 & 512K models)
- $x20000-$x7FFFF: RAM (512K model only)
- $x80000-$xFFFFF: "high" ROM (no longer includes *kernel* ROM)

A reasonable feature would be *jumpers* to select the **I/O page**,
freely located anywhere within *the upper 32K of bank zero*, switching off the
*kernel ROM* for peripheral access.

Actually, *I/O space* is just **128 bytes**... as it is hardwired to the upper 32K,
the LSB on the '688 comparator goes to A7, thus being able to select *either
half* of the page. As the MSB goes with A14, A15 is kept as a non-selectable option
one the previous comparator, for *kernel-ROM* selection. **This method seems OK
*if an expansion bus provides means to disable internal decoding***, otherwise will
limit the expansion capabilities. On the other hand, "borrowing" the whole page for
I/O will need to disable the internal '139 for the unused half-page. 

Some workaround for its limited expansion capabilities would be decoding the
*high* ROM at the **uppermost banks** (`BA19`-`BA23`=**1**) avoiding mirroring.
That would render it at $F80000-$FFFFFF, leaving at least **fifteen 512 kiB blocks**
at the addresses $x80000-$xFFFFF free for expansion (where x is on the range $0-$E)
 
## Glue-logic implementation

As usual in my designs, some component choices were determined by my stock... This may
lead to somewhat *sub-optimal* designs, although at such *pedestrian* speeds shouldn't
be a problem. In any case, replacing the 74HCxx ICs by faster **74ACT/FCT** logic will
allow significantly faster clock rates. Since HC logic seems good in this design for
**up to ~2.5 MHz**, the initial goal is attained. At the *nominal 2.304 MHz*,
**250 ns memories** are suitable.

As usual in 65816 talk, `D0`...`D7` and `A0`...`A15` are the **direct** data and address 
lines (pinout shared with the *6502*) while `BA16`...`BA23` are the outputs from the
*transparent **latch*** as usually done (note `BA20` to `BA23` are **not** used,
except for decoding the high ROM (see above).

### RDY implementation

Still under research is the fact **whether an RDY-halted 65816 *multiplexes* bank
addresses on the data bus or not**. Should this assumption be *true*, this perhaps will
*not* be an issue, because:

- While *reading*, the selected address will remain valid, and the recommended **74HC245**
will just isolate the CPU data bus from the outside, while the addressed device is
(slowly) *building* the data bits. As long as it reaches a stable configuration prior
to the *setup time* on the **last** Phi-2 cycle, all will be fine.
- During *writes*, the output data from CPU will arrive *intermittently* to the slow
device; it seems that *most RAMs actually **latch** the current data just upon /WE going
**up*** and, unless its *setup time* is longer than half the clock cycle.
- Even if the previous SRAM assumption is *false*, the *data bus capacitance* is most
likely to **keep the output data stable** when the 74xx245 shuts off during Phi-1 with
its outputs in *high-Z* state. *Weak pull-downs* are even allowed, but with all the
mirroring on this machine there seems to be little use for such a **BRK-generating
device** which will disable execution on *undecoded* areas.

Otherwise (the bank address does *not* get multiplexed during RDY pauses) the
WDC-suggested circuit **must** be modified in order to avoid *latching **invalid** bank
addresses*. Another option would be the use of **clock-stretching** and leaving RDY
*gently* pulled up and indisturbed.

Note that this machine *does **not** negate RDY* by itself, although this capability
should be provided for **expansion bus** use.

### Chip Selection

While the moderate clock speed does not ask for an extremely efficient *address
decoding*, keeping circuitry **as simple as possible** will reduce the build effort...

- **`RAM /CS`** is as simple as **negated `BA19`** (the lowest 512K of each megabyte).
*Note that RAM is **always** written*, although its *output* will be disabled when
overlapping with (kernel) EPROM or I/O. *No clock is taken for this signal*, writes
will be Phi2-validated via `/WE`, as usual. *It is possible to obtain `RAM /CS`
putting `BA19` thru `BA23` on a '688 for non-mirrored decoding, enhancing the
expanasion capabilities*.

- **`ROM /CS`**, on the other hand, cannot just be the opposite, because it has to be
enabled whenever the ***kernel* area** is accessed (below $x10000, with `BA19` low).
A NAND gate is to be used for this signal, from both `BA19` and the (active *high*)
result of a '688 detecting the configured *kernel* area. This might be implemented
thru some *decoder*, like a spare 74HC139... which I have plenty of.

*Last modified: 2018-09-23*
