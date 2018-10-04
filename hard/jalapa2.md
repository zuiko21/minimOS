# Jalapa-II

The **Jalapa** project, originally intended to be a 65C02 machine with a *coarse*
bankswitching feature (lower 16K, including *zeropage* & *stack*) for reasonable
**multitasking** performance, gave way to the current design, around the interesting
**65C816** with a simple architecture, but still powerful enough for future *minimOS*
versions.

As this machine will take the *experimental* aim of the aborted **SDx** project,
some **configuration options**  like *Kernel size* were to be available via
jumpers, but deemed too complicated. The **I/O page** selection will remain, though.

## Specs

Still within design phase, here is an outline of its basic specs:

- CPU: **65C816**
- Clock speed: **2.304 MHz**, with **1.8432** and **3.072 *turbo*** options
- VIA: *single* **65C22**, with the typical **piezo-buzzer** at PB7/CB2
- RAM: 128/**512 kiB** (static 32-pin)
- (E)EPROM: up to **512 kiB**
- Serial: single **65C51**, just for the sake of completeness
- **Expansion bus:** *VME-like*, essentialy the 65816 pins

Although its most interesting feature was **remapping** part of the ROM (up to 32K) 
into *bank zero*'s top for convenient 65xx vector location, once again this was
discarded and went instead for the use of ***two* separate ROM** sockets
(for `sys` and `lib` *implicit* volumes, namely the *Kernel and application* EPROMs).

For debugging purposes, LEDs will indicate the state of **E** (emulation mode)
and **M/X** (register sizes) lines of the 65816. These will be available on the
*VME-like* bus, too.

### Not provided on this machine

- ROM-in-RAM copy (it's slow enough for most EPROMs)
- Real Time Clock (of little use lacking a *filesystem*, although might be included)
- Hardware *zeropage/stack* **bankswitching** (65816 allows easy multitasking)
- 6845-based video output (cards available thru the *expansion bus*)

## Memory map

This machine fomerly was designed around a  **20-bit** address bus *(1 MiB)*,
enough to allow **up to 512 kiB RAM & 512 kiB ROM**, which is the maximum size
available in *hobbyist-friendly*, 5v DIP packages. However, the need for a suitable
**expansion bus** calls for a more complete address decoding.

The usual need in 65816 systems of some ROM in *bank zero* is no longer satisfied
by *remapping* the upper 32k of the first bank of ROM into bank zero, but using a
**separate EPROM** instead.

About the RAM, no provision is made to avoid mirroring *within the maximum
512 kiB area*, thus suitable firmware should take that into account.

A typically configured machine goes as follows:

- $000000-$007FFF: RAM (all configs)
- $080000-$00DEFF: EPROM (**kernel** & **firmware**)
- $00DF00-$00DFFF: built-in I/O (selectable)
- $00E000-$00FFFF: EPROM (continued kernel & firmware, including *hardware vectors*)
- $010000-$01FFFF: RAM (both 128 & 512K models)
- $020000-$07FFFF: RAM (512K model only, or *mirror* images of RAM if 128K are fitted)
- $080000-$F7FFFF: **free** for *VME-like* expansion bus
- $F80000-$FFFFFF: "high" ROM (no longer includes *kernel* ROM)

As this is a development machine, *jumpers* select the **I/O page**,
freely located anywhere within *bank zero, no longer restricted to the
EPROM area*. This is enabled by switching off both the *kernel ROM*
and RAM (just in case) for peripheral access.

Decoded via a '139, the **I/O page** supports just **four** internal devices,
two of them already assigned (**VIA** and **ACIA**). As per *minimOS* recommendations,
each device owns **32 bytes** from this page, thus the 128-byte decoded I/O gets
*mirrored*. Any *external card* decoding extra devices on this standard area will thus
have just another *four* available slots, as VIA & ACIA appear *twice* on the page.

Since a complete *expansion bus* is fitted, the *high* ROM must be decoded at the
**uppermost banks** (`BA3-BA7`=**1**) avoiding mirroring.
Also, *RAM should be properly decoded* too, at least within the **lowest 512 K**.
That would render `lib` ROM at $F80000-$FFFFFF, leaving all addresses
$080000-$F7FFFF (15 MiB) **free** for expansion.
 
## Glue-logic implementation

As usual in my designs, some component choices were determined by my stock... This may
lead to somewhat *sub-optimal* designs, although at such *pedestrian* speeds shouldn't
be a problem. In any case, replacing the 74HCxx ICs by faster **74ACT/FCT** logic will
allow significantly faster clock rates. Since HC logic seems good in this design for
**up to ~2.5 MHz**, the initial goal is attained. At the *nominal 2.304 MHz*,
**250 ns memories** are suitable.

Most of the ICs dor decoding are **74HC688** and **74HC139**, as I own plenty of them.

As usual in 65816 talk, `D0-D7` and `A0-A15` are the **direct** data and address 
lines (pinout shared with the *6502*) while `BA0-BA7` are the outputs from the
*transparent **latch*** as usually done. *These lines may be called `A16-A23`*.

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
should be provided for **expansion bus** use, perhaps by means of *clock-stretching*.

### Chip Selection

While the moderate clock speed does not ask for an extremely efficient *address
decoding*, keeping circuitry **as simple as possible** will reduce the build effort...
Extra care has been taken to reduce *power consumption* as much as possible, although
the slowest bits (esp. for ROM enabling) are generated ASAP.

*Unless noted otherwise, all '688s and '139s are **enabled** when any of `VDA` or `VPA`
are in **high** state.*

- **`/BZ`** (bank zero) is, of course, a '688 expecting `BA0-BA7` to be zero,
most likely enabled thru `VPA` NOR `VDA` (aka `/OK`).
- **`LIB /CS`** (enabling the *high* ROM) is another '688 looking for `BA5-BA7`
high, and maybe R/W too in case of *bus contention*. In that case, you can keep
`LIB /OE` tied to ground.
- **`RAM /CS`** expects `BA3-BA7` as *zero* on a '688 (the lowest 512 kiB).
*Note that RAM was **always** written*, although its *output* was disabled when
overlapping with (kernel) EPROM or I/O. An *alternative decoding* will shut it off
during I/O, though. *The `/WE` signal will no longer be generated*,
as with a fast RAM it is best to **validate `RAM /CS` with Phi2**, together with 
several `BA` bits. This reduces power consumption, too. *Further savings could be done
putting `/IO` and `KERNEL /CS` here too*, as RAMs are usually fast enough for this.
- **`RAM /OE`** stays low unless `/BZ` is low and `A15` high. *It is actually
the **negation** of `KERNEL /CS`*, but if this last signal affects `RAM /CS`
(see above) can be **just tied to ground**.
- **`/IO`** uses `/BZ` to *enable* a '688, then `A8-A15` as configured. *Note that
this is no longer restricted to EPROM space*, as long as it shuts off RAM output too.
- **`KERNEL /CS`** looks for `/BZ` low and `A15` high (first upper 32K), for lowest
power consumption (will stay on during I/O but with outputs disabled). *A few ns
cound be gained if **enabled** via `/BZ`*. 
- **`KERNEL /OE`** takes `/IO` negated (high) and `R/W` high to avoid
*bus contention*.

*Last modified: 20181004-1231*
