# Acapulco

The **Acapulco** project, formerly called *Tampico*, is a simple 65C02 computer with
**built-in *VGA-compatible* video output*. Despite this output fitting a
*quasi-VGA* format, actual picture resolution is *SD TV-like* but compatible with
more modern devices. This also stays better within the limited power of a 65C02.

Another feature for both a more attractive display *and* resource saving is the
ability to **display up to 16 colours** from a *fixed GRgB palette*, although
limited to *two of them over each 8x8 pixel region*, by means of an
**attribute area** (much like the one on the **ZX Spectrum**, although with no
`BRIGHT` or `FLASH` attributes.

As this machine lacks the *experimental* aim of the **Jalapa 2** project,
no *configuration options* will be available, although pin 1 on the CPU socket may
be used for **internal decoding disabling**. This may allow *piggybacking* peripheral
cards, but is really intended for a **65816 card**, also in the making.

## Specs

Still within design phase, here is an outline of its basic specs:

- CPU: **65C02**
- Clock speed: **1.536 MHz** (although **1.5734375** might be preferred)
- VIA: *single* **65C22**, with the typical **piezo-buzzer** at `PB7-CB2`
- RAM: **32 kiB** (static) plus 1 kiB *shadow* RAM for attributes. 
- (E)EPROM: **32 kiB**
- Built-in video: **6445** based, 6845 may be used with extra multiplexing.

### Not provided on this machine

- Serial port
- Real Time Clock (of little use lacking a *filesystem*, although might be included)
- Hardware *zeropage/stack* **bankswitching** (for multitasking, best to use the
_optional **65816 card**_)
- Expansion bus

### Clock generation

According to the usual way of selecting my *most abundant* components in stock,
the clock signal is generated from a **24.576 MHz oscillator** can. However, the
presence of a *VGA-compatible* option suggests the industry-standard **25.175** MHz
frequency; but some tinkering with the 6845/6345/6445 registers may achieve the
required compatibility. *Half* of this frequency is used as **dot clock**, as it
will use *half the resolution*, both horizontal and vertical, of the VGA standard.

Further divided by 16, this signal will provide the main **`Phi-2`** clock.

## Video output

The main feature of the otherwise simple **Acapulco** computer is the VGA-compatible
**colour video output**. But since a complete *4 bpp full VGA* signal would need
at least *128 kiB of VRAM*, some measures must be taken in order to reduce the memory
and bandwith requirememts so they fit into the 6502 capabilities:

- **Halving the resolution**, both H & V, giving a resolution similar to the usual
*home computers* of old, via **line doubling**.
- The use of an **attribute area**, allowing the whole image to be stored like a
*bitmap*, limited to **two available colours _each 8x8 pixels_**.

These restrictions allow the whole VRAM area to fit into a mere **9 kiB** (1 for the
*attribute area*), subtracted from the regular SRAM as *vampire-video*. Supplied with
32 kiB of static RAM, this seems a reasonable approach.

The versatility of the **6x45 CRTCs** allow easy implementation of several video
modes. The choice of oscillator will affect compatibility, so some *timing tweaking*
should be used in case the *non-standard 24.576 MHz* can is used. *Video driver* may
thus provide several *configuration tables*, allowing these suggested modes:

- _for the **standard 25.175 MHz**:_
0) **320x200** (40x25 char.) **industry-standard** timing
0) **288x224** (36x28 char.) with elongated porchs (fully compatible)
0) **256x240** (32x30 char.) ditto, allowing a simpler driver

- *for the non-standard 24.576 MHz:*
3) **320x200** (40x25 char.) shorter back porch & sync pulses (likely compatible)
3) **320x200** (40x25 char.) much shorter sync pulse (likely compatible)
3) **288x224** (36x28 char.) most likely compatible (*slightly* faster timing)
3) **256x240** (32x30 char.) ditto, allowing a simpler driver
3) **320x200** (40x25 char.) much shorter back porch (*perhaps* compatible)


*- - - - - - - - - - - - - - - Jalapa specs below, as template - - - - - - - - - - -*

## Memory map

This machine fomerly was designed around a  **20-bit** address bus *(1 MiB)*,
enough to allow **up to 512 kiB RAM & 512 kiB ROM**, which is the maximum size
available in *hobbyist-friendly*, 5v DIP packages. However, the need for a suitable
**expansion bus** calls for a more complete address decoding.

The usual need in 65816 systems of some ROM in *bank zero* is no longer satisfied
by *remapping* the upper 32k of the first bank of ROM into bank zero, but using a
**separate EPROM** instead.

About the RAM, no provision is made to avoid mirroring *within the first
megabyte* thus suitable firmware should take that into account. Decoding RAM
for *twice* the required amount allows for **getting full access to the
*ROM-shadowed* RAM**.

A typically configured machine goes as follows:

- $000000-$007FFF: RAM (all configs)
- $080000-$00DEFF: EPROM (**kernel** & **firmware**)
- $00DF00-$00DFFF: built-in I/O (selectable)
- $00E000-$00FFFF: EPROM (continued kernel & firmware, including *hardware vectors*)
- $010000-$01FFFF: RAM (both 128 & 512K models)
- $020000-$07FFFF: RAM (512K model only, or *mirror* images of RAM if 128K are fitted)
- $080000-$0FFFFF: more RAM images ($0x8000-$0xFFFF allows *shadow RAM* access for some
*x* values: **8** for all, plus **2, 4, 6, $A, $C** & **$E** for the *128K model*)
- $100000-$F7FFFF: **free** for *VME-like* expansion bus
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
Also, *RAM should be properly decoded* too, but within the **lowest MiB**.
That would render `lib` ROM at $F80000-$FFFFFF, leaving all addresses
$100000-$F7FFFF, a whole **14 MiB free** for expansion.
 
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
- **`RAM /CS`** expects `BA4-BA7` as *zero* on a '688 (the lowest MiB).
*Note that RAM is disabled when overlapping with (kernel) EPROM or I/O*.
*The `/WE` signal will no longer be generated*,m as with a fast RAM it is best
to **validate `RAM /CS` with Phi2**, together with several `BA` bits, `/IO` and
`KERNEL /CS` for lower power consumption*, as RAMs are usually fast enough for this.
- **`RAM /OE`** can be **just tied to ground**, just like `LIB /OE`.
- **`/IO`** uses `/BZ` to *enable* a '688, then `A8-A15` as configured. *Note that
this is no longer restricted to EPROM space*, as long as it shuts off RAM output too.
- **`KERNEL /CS`** uses `/BZ` to *enable* a '688, then `A8-A15` as configured, but
as it *must* take the uppermost bits, `A15` is expected to be **always 1**, while
`A14-A11` might be *sequentially* compared to ones for **reduced kernel sizes**
(from **32 kiB** down to **2 kiB**). Some jumpers will disconnect *ignored* address
lines. In this scheme, ROM will stay enabled during I/O but with outputs disabled.
- **`KERNEL /OE`** takes `/IO` negated (high) and `R/W` high to avoid
*bus contention*.  If done thru a 74HC139's `/Y3` output, there is another output
signalling *contention states* (`/Y2` if `R/W` is set to the decoder's `A0`), but
that '139 *must* be enabled via `/BZ`. *Should this feature not be needed, the
decoder could be permanently active*. Plus, swapping ROM's `/CS` and `/OE` inputs allows
for higher performance at the cost of increased power consumption. On the other hand,
moving the `R/W`signal to the `KERNEL /CS` '688 (with corresponding '139 input set
high) would further reduce power consumption.

*Last modified: 20181018-1204*
