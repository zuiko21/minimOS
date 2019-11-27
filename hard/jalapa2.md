# Jalapa-II

The **Jalapa** project, originally intended to be a 65C02 machine with a _coarse_
bankswitching feature (lower 16K, including _zeropage_ & _stack_) for reasonable
**multitasking** performance, gave way to the current design, around the interesting
**65C816** with a simple architecture, but still powerful enough for future _minimOS_
versions.

As this machine will take the _experimental_ aim of the aborted **SDx** project,
some _configuration options_ like **Kernel size** and **I/O page** selection might
be selected via _jumpers_.

## Specs

Still within design phase, here is an outline of its basic specs:

- CPU: **65C816**
- Clock speed: **2.304 MHz**, with **1.8432** and **3.072 *turbo*** options
- VIA: (one or two?) **65C22**, with the typical **piezo-buzzer** at PB7/CB2
- RAM: 128 or **512 kiB** (static 32-pin DIP)
- (E)EPROM: up to **512 kiB** (plus separate _Kernel_ ROM up to 32 kiB)
- Serial: single **65C51**, just for the sake of completeness
- **Expansion bus:** _VME-like_, essentially a breakout of the 65816 pins

Although its most interesting feature was **remapping** part of the ROM (up to 32K) 
into _bank zero_'s top for convenient 65xx vector location, once again this was
discarded and went instead for the use of **_two_ separate ROM** sockets
(for `sys` and `lib` _implicit_ volumes, namely the
_Kernel and application/**library**_ EPROMs).

For debugging purposes, LEDs will indicate the state of **E** (emulation mode)
and **M/X** (register sizes) lines of the 65816. These will be available on the
[_VME-like_ bus](buses/vmelike.md), too.

### Not provided on this machine

- ROM-in-RAM copy (it's slow enough for most EPROMs)
- Real Time Clock (of little use lacking a _filesystem_, although **might be included**)
- Hardware _zeropage/stack_ **bankswitching** (65816 allows easy multitasking)
- 6845-based video output (suitable video cards available thru the _expansion bus_)

The newest redesign, however, allows easy implementation of the _ROM-in-RAM_
feature, by adding an extra _comparison bit_ to the `ROM /CS` signal generation.
But, being a **single VIA** machine, such switching signal should be generated
_manually via a jumper_, as there is hardly a spare bit for that. _This is a good
reason to use **two VIAs** instead_, with the added benefit of having a
_frequency generator_ completely independent from the **jiffy interrupt** timer.
 
### Clock generation

According to the usual way of selecting my _most abundant_ components in stock,
the clock signal is generated from a **18.432 MHz oscillator** can. Together with
a **74HC(T)390**, one half divides this frequency _by ten_, obtaining the
_standard 1.8432 MHz_ for the **ACIA**. The other half of the '390 is however
cofigured as **divide-by-eight**, thus obtaining the nominal **2.304 MHz** as
the _main system clock_.

For the _turbo_ option, this second half of the '390 could be configured as
_divide-by-six_ for a **3.072 MHz** Phi2. In this case, the first _divide-by-5_
counter must be reset upon reaching 3, via an AND gate. Note that taking the clock
from the _divide-by-5_ section of the ACIA divider, getting **3.6864 MHz**, is **not**
a good idea, as the _duty cycle_ would be far from the desired 50%.

## Memory map

This machine fomerly was designed around a  **20-bit** address bus _(1 MiB)_,
enough to allow **up to 512 kiB RAM & 512 kiB ROM** (plus up to _32 kiB Kernel ROM_
for a grand total of **544 kiB**), which is the biggest size available in
_hobbyist-friendly_, 5 volt DIP packages. However, the need for an appropriate
**expansion bus** calls for a reasonably complete address decoding.

The usual need in 65816 systems of some ROM in _bank zero_ is no longer satisfied
by _remapping_ the upper 32k of the first bank of ROM into bank zero, but by using a
**separate EPROM** instead.

About the RAM, no provision is made to avoid mirroring _within the first
megabyte_ thus suitable firmware should take that into account. Decoding RAM
for _twice_ the required amount allows for **getting full access to the
_ROM-shadowed_ RAM**, although this makes little sense if the _ROM-in-RAM_ option
is implemented. But for the required specs, that mirroring won't hurt either.

A typically configured machine goes as follows:

- $000000-$007FFF: RAM (all configs)
- $008000-$00DEFF: EPROM with **kernel** & **firmware** (may start later, up to $00F800, with RAM before that)
- $00DF00-$00DFFF: built-in I/O (selectable)
- $00E000-$00FFFF: EPROM (continued kernel & firmware, including _hardware vectors_) (see above)
- $010000-$01FFFF: RAM (both 128 & 512K models)
- $020000-$07FFFF: RAM (512K model only, or _mirror_ images of RAM if 128K are fitted)
- $080000-$0FFFFF: more RAM images ($0x8000-$0xFFFF allows _shadow RAM_ access for some *x* values: **8** for all, plus **2, 4, 6, $A, $C** & **$E** for the *128K model*)
- $100000-$EFFFFF: **free** for _VME-like_ expansion bus
- $F00000-$FFFFFF: "high" ROM (no longer includes _kernel_ ROM)

As this is a development machine, _jumpers_ select the **I/O page**,
_freely located anywhere within bank zero, no longer restricted to the
EPROM area_. This is enabled by switching off both the _kernel ROM_
and RAM outputs (just in case) for peripheral access.

Decoded via a '139, the **I/O page** supports just **four** internal devices,
two of them already assigned, **VIA** and **ACIA** (or _three_ if a second VIA is used).
As per _minimOS_ recommendations, each device owns **32 bytes** from this page,
thus the 128-byte decoded I/O gets _mirrored_. Any _external card_ decoding extra devices
on this standard area will thus have just another _four_ available slots (or three),
as VIA & ACIA appear _twice_ on the page.

Since a complete _expansion bus_ is fitted, the **high ROM** must be decoded at the
_uppermost banks_ (`BA4-BA7` = **1**) limiting mirroring.
Also, _RAM should be properly decoded_ too, but within the **lowest MiB**.
That would render `/lib` ROM at $F80000-$FFFFFF, leaving all addresses
$100000-$EFFFFF, a whole **14 MiB free** for expansion.
 
## Glue-logic implementation

As usual in my designs, some component choices were determined by my stock... This may
lead to somewhat _sub-optimal_ designs, although at such "pedestrian" speeds shouldn't
be an issue. In any case, replacing the 74HCxx ICs by faster **74ACT/FCT** logic will
allow significantly faster clock rates. Since HC logic seems good in this design for
**up to ~2.5 MHz**, the initial goal is attained. At the _nominal 2.304 MHz_,
**250 ns memories** will suffice.

Most of the ICs for decoding are **74HC688** and **74HC139**, as I own plenty of them.

As usual in 65816 talk, `D0-D7` and `A0-A15` are the **direct** data and address 
lines (pinout shared with the _6502_) while `BA0-BA7` are the outputs from the
_transparent **latch**_ as usually done. _These lines may be called `A16-A23`_.

### RDY implementation

Still under research is the fact **whether an `RDY`-halted 65816 *multiplexes* bank
addresses on the data bus or not**. Should this assumption be _true_, this perhaps will
**not** be an issue, because:

- While _reading_, the selected address will remain valid, and the recommended **74HC245**
will just isolate the CPU data bus from the outside, while the addressed device is
(slowly) _building_ the data bits. As long as it reaches a stable configuration prior
to the _setup time_ on the **last** Phi-2 cycle, all will be fine.
- During _writes_, the output data from CPU will arrive **intermittently** to the slow
device; it seems that _most RAMs actually **latch** the current data just upon `/WE` going
**up**_ and, unless its _setup time_ is longer than half the clock cycle, this should work fine.
- Even if the previous SRAM assumption is **false**, the _data bus capacitance_ is most
likely to **keep the output data stable** when the 74xx245 shuts off during Phi-1 with
its outputs in _high-Z_ state. _Weak pull-downs_ are even allowed, but with all the
mirroring on this machine there seems to be little use for such a **BRK-generating
device** which will disable execution on _undecoded_ areas.

Otherwise (the bank address does **not** get multiplexed during `RDY` pauses) the
WDC-suggested circuit **must** be modified in order to avoid _latching **invalid** bank
addresses_. Another option would be the use of **clock-stretching** and leaving `RDY`
_gently_ pulled up.

Note that this machine _does **not** negate `RDY`_ by itself, although this capability
should be provided for **expansion bus** use, perhaps by means of _clock-stretching_.

### Chip Selection

While the moderate clock speed does not ask for an extremely efficient _address
decoding_, keeping circuitry **as simple as possible** will reduce the build effort...
Extra care has been taken to reduce _power consumption_ as much as possible, although
the slowest bits (esp. for ROM enabling) are generated ASAP.

_Unless noted otherwise, all '688s and '139s are **enabled** when any of `VDA` or `VPA`
are in **high** state._

- **`/BZ`** (bank zero) is, of course, a '688 expecting `BA0-BA7` to be zero, most likely enabled thru `VPA` NOR `VDA` (aka `/OK`).
- **`LIB /CS`** (enabling the _high_ ROM) is another '688 looking for `BA4-BA7` high, and maybe R/W too in case of _bus contention_. In that case, you can keep `LIB /OE` tied to ground. (`BA3` not really necessary).
- **`RAM /CS`** expects `BA4-BA7` low on a '688 (the lowest MiB). _Note that RAM (or its outputs) is disabled when overlapping with (Kernel) EPROM or I/O_. The `/WE` signal will _no longer be validated_, as with a fast RAM it is best to **validate `RAM /CS` with Phi2**, together with several `BA` bits and perhaps `/IO` and `KERNEL /CS` for **lower power consumption**, as SRAMs are usually fast enough for this.
- **`RAM /OE`** can be **just tied to ground**, just like `LIB /OE` -- or perhaps disabled during I/O or Kernel accesses, if _ROM-in-RAM_ is implemented.
- **`/IO`** uses `/BZ` to _enable_ a '688, then `A8-A15` as configured. _Note that this is no longer restricted to EPROM space_, as long as it shuts off RAM output too.
- **`KERNEL /CS`** uses `/BZ` to _enable_ a '688, then `A8-A15` as configured, but as it _must_ take the uppermost bits, `A15` is expected to be **always high**, while `A14-A11` might be _sequentially compared to ones_ for **reduced kernel sizes** (from **32 kiB** down to **2 kiB**). Some jumpers will disconnect _ignored_ address lines, letting their inputs pulled up. In this scheme, _ROM will stay enabled during I/O_ but with outputs disabled.
- **`KERNEL /OE`** takes `/IO` negated (high) and `R/W` high to avoid _bus contention_.  If done thru a 74HC139's `/Y3` output, there is another output signalling _contention states_ (`/Y2` if `R/W` is set to the decoder's `A0`), but that '139 _must_ be enabled via `/BZ`. _Should this feature not be needed, the decoder could be permanently active_. Plus, swapping ROM's `/CS` and `/OE` inputs allows for higher performance at the cost of increased power consumption. On the other hand, moving the `R/W` signal to the `KERNEL /CS` '688 (with corresponding '139 input set high) would further reduce power consumption.

_Last modified: 20191127-0914_
