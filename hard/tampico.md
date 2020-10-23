# Tampico

The **Tampico** project is a simple 65C02 computer with
**built-in _VGA-compatible_ monochrome video output**. Despite this output fitting a
_quasi-VGA_ format, actual picture resolution is _SD TV-like_ but compatible with
more modern devices. This also works better within the limited power of a 65C02.

Displaying an SDTV image on a VGA display means _line-doubling_; but an extra feature
is a **double-res mode** which disables that doubling, reading actual new rasters from
video RAM (now 16 KiB out of 32). The easiest way to implement this is via `MA13` from
the CRTC: thus, if the screen base address is anywhere in the upper 8K (from the 16K
addressable by the 6x45), `VA13` (to SRAM) takes the otherwise ignored `RA0` from CRTC.

Another feasible feature would be a _chunky_ **2 bpp mode**, halving horizontal resolution.
Instead of getting (V)RAM data into a _shift register_, a **dual 4-to-1 mux** (e.g. 74HC253)
will supply the 4-colour bitstream to the RGB outputs. Perhaps the simplest palette would
be a kind of _semaphore plus black_ driving, say, LSB into `G` and MSB into `R`.
6x45 cursor output might go into the blue channel. Much like the aforementioned _double-res_
mode, this could be enabled by `MA12` on the CRTC, saving a dedicated register.

As this machine lacks the _experimental_ aim of the **Jalapa 2** project,
no _configuration options_ will be available, although pin 1 on the CPU socket may
be used for **internal decoding disabling**. This may allow _piggybacking_ peripheral
cards, but is really intended for a **65816 card**, also in the making.

## Specs

Still within design phase, here is an outline of its basic specs:

- CPU: **65C02**
- Clock speed: **1.536 MHz** (although **1.5734375 MHz** might be preferred)
- VIA: single **65C22**, with the typical **piezo-buzzer** at `PB7-CB2`
- RAM: **32 kiB** (static). 
- (E)EPROM: **32 kiB**
- Built-in video: **6445** based, 6845 may be used with extra multiplexing.

### Not provided on this machine

- Serial port
- Real Time Clock (of little use lacking a _filesystem_, although might be included)
- Hardware _zeropage/stack **bankswitching**_ (for multitasking, best to use the
_optional **65816 card**_)
- Expansion bus

## Clock generation

According to the usual way of selecting my _most abundant_ components in stock,
the clock signal is generated from a **24.576 MHz oscillator** can. However, the
specification of _VGA-compatible_ output suggests the industry-standard **25.175 MHz**
frequency; but some tinkering with the 6845/6345/6445 registers may achieve the
required compatibility. _Half_ of this frequency is used as **dot clock**, as it
will use _half the resolution_, both horizontal and vertical, of the VGA standard.

Further divided by 16 (via a **74HC161**), this signal will provide the main
**`Phi-2`** clock. This way, CPU accesses will be **interleaved** with
CRTC accesses for **optimum performance**.

## Video output

Even on monochrome, a complete _full VGA_ display would need the whole available RAM
on Tampico, and then some more, thus a **reduced resolution** around _320x200_ is set
(see below resolution options). As the number of lines is halved, _line doubling_ must
be used for VGA compliance.
These restrictions allow the whole VRAM area to fit into a mere **8 kiB**, subtracted
from the regular SRAM as _vampire-video_. On the other hand, if the _double-res_ feature
is enabled, **16 kiB** will be used. Supplied with 32 kiB of static RAM, either approach
seems reasonable.

On the other hand, the optional **colour mode** just takes 2 bits per pixel, halving
horizontal resolution but still fitting into the same VRAM size. _Note that this mode
could be combined with the **double-res** mode, but would definitely look horrible!_

The versatility of the **6x45 CRTCs** allow easy implementation of several video
modes. The choice of oscillator will affect compatibility, so some _timing tweaking_
should be used in case the _non-standard 24.576 MHz_ can is used. _Video driver_ may
thus provide several _configuration tables_, allowing these suggested modes:

- _for the **standard 25.175 MHz**:_
0) **320x200** (40x25 char.) **industry-standard** timing
0) **288x224** (36x28 char.) with elongated porchs (fully compatible)
0) **256x240** (32x30 char.) ditto, allowing a simpler driver

- _for the non-standard 24.576 MHz:_
3) **320x200** (40x25 char.) **much shorter back porch** (_perhaps_ compatible)
3) **320x200** (40x25 char.) **much shorter sync** pulse (likely compatible)
3) **288x224** (36x28 char.) most likely compatible with _slightly_ faster timing
3) **256x240** (32x30 char.) ditto, allowing a simpler driver
3) **320x200** (40x25 char.) shorter _back porch & sync pulses_ (most likely compatible)

Vertical resolution doubles up to 400/448/480 lines in case _double-res_ mode is enabled,
but timing will remain the same.

_Firmware_ may provide a module for **quick video mode selection** during startup.

On the other hand, some VGA monitors (like my Acer) allow the somewhat reduced
scan frequencies (58.5 Hz & 30.7 kHz) from a 24.576 MHz clock, thus taking the whole
320 x 200 without any weaking.   

6x45's _raster addresses_ are wired as the most significant bits. This allows fast
**hardware-assisted scrolling** (Amstrad-CPC-like). Interestingly, if _double-res mode_
is enabled, only the even-numbered rasters will be adjacent at the upper RAM, while the
odd-numbered rasters will show up before.

### VGA compatibility and the 6845

As previously metioned, fully VGA compatibility can only be achieved thru the use of
a standard 25.175 MHz oscillator. The project is to be made using a 6445 CRTC and no
further issues should occur; however, in case a classic 6845 is used, another problem
can arise: it produces a **fixed length** (16 lines) _vertical sync_ pulse, which
may throw off the vertical position of the image a bit. _This might be an issue on the
256x240 mode_, as the whole 480 image lines are used, and some monitors may not have
room enough for top or bottom lines under such displaced `VSYNC` pulse. A feasible
workaround could be limiting such mode to _28 rows_ (224 raster lines).

On the other hand, the 6345/6445 can fine-adjust the `VSYNC` pulse length
_and_ position, thus highly recommended in any case. To keep the desired 6845
compatibility, this setting (together with those 6345/6445-specific ones)
**must be done by the Firmware** during _cold boot_, so the
OS _driver_ does not have to check for other than the **generic 6845 registers**.

### Video signal generation

VRAM data is handled differently depending on the _double-res_ mode being enabled
or not. When on standard _line doubling_ mode, RAM data is
latched into a **'165 shift register** as usual. However, the colour mode takes
these bytes into a **'253 dual 4-to-1 mux**, switching pairs at half the usual
dot rate. A simple hardwired palette is expected.

_**Cursor** circuitry is TBD_, certainly with the assistance of the 6x45 hardware.
A simple approach would be putting the monochrome video output to, say, the green
channel and the cursor output to the red channel, switching the _vintage_ green-on-black
look to a yellow-on-red one -- could use jumpers for alternative colour schemes.
Ditto for the _colour_ mode, with two (fixed?) channels for display and the remaining
one for cursor -- might turn a semaphore-like palette into a CGA-like one!

About the **double-res mode**, it's just a matter of muxing into `VA13` either 1
(normal mode) or the normally ignored `/RA0` (note it is _negated_), depending on
the state of `MA13`, which can be easily selected from a spare '139. _But the **OS**
must take account of this, reserving the `$4000-$5FFF` RAM area for display_.

## Memory map

Within the usual 6502 restriction to 64 kiB address space, this machine is simply
defined as **32 kiB SRAM + 32 kiB EPROM**. From the latter, a full page (`$DFxx`)
is assigned to I/O devices -- although with quite a bit of mirroring.

Because of the _built-in video_ feature, some of the RAM is used as _VRAM_.

The standard memory map goes as follows:

- `$0000-$3FFF`: _62256_ **SRAM** (general purpose)
- `$4000-$5FFF`: **Video RAM** (odd rasters on _double-res_; could work as _general purpose_ RAM)
- `$6000-$7FFF`: **Video RAM** (even rasters, stored in the _62256_)
- `$8000-$DEFF`: EPROM (**kernel & firmware**, plus any desired apps)
- `$DF00-$DFFF`: built-in **I/O** (NON selectable, but maybe _switchable_?)
- `$E000-$FFFF`: EPROM (continued kernel & firmware, including _hardware vectors_)

Decoded via a '139, the **I/O page** supports just **four** internal devices
with a 32-byte area each (decoding address lines `A5-A6`), mirrored on the
lower half of the I/O page. Only two devices are included:

- **VIA** at `$DFFx` (actually $DFE0-$DFFF, also at $DF60-$DF7F)
- **CRTC** at `$DFCC-$DFCD` ($DFC0-$DFDF and $DF40-$DF5F)

Some mirroring could be reduced by taking `A4` to the VIA's `CS1` _active-high_
signal, limiting its appearances at the **nominal $DFFx** and $DF7x. The other
second half of the '139 may be used (taking A7) leaving undecoded the _lower half_
of the I/O page, but at the cost of increasing delays. **This is particularly critical
with the 6522 VIA** as 1 MHz parts may violate its `tACR` and `tACW` requirements.
_Using 2 MHz parts should provide adequate speed_, though.

Anyway, since a complete _expansion bus_ is not fitted, there is a chance to
**disable internal decoding** thru the _CPU socket_. Pin 1 (`VSS` or `/VP`)
may be connected via a jumper to the decoding `/EN` enable input (active low).
A _pull-down_ resistor will allow normal operation in case a W65C02S part is
used (which takes pin 1 as `/VP` output), but will not prevent a suitable
socket-installed card **disabling the built-in decoding** whenever an _external
I/O address_ is issued. This method allows a _65816 card_ to supply some
**extra memory** outside bank zero.

## Glue-logic implementation

Most of the ICs for decoding are **74HC688** and **74HC139**, as I own plenty of them.
As per **multiplexing the address lines** in order to share RAM access between the CPU
and the CRTC, the use of a 6445 waives the need for actual multiplexers. From the CPU
side, though, a couple of **74HC245** isolate this part of the address bus whenever the
CRTC ouputs are not tristated (during `Phi1`).

Please note that _the 6445 does NOT tristate its outputs_ until it is told so.
Thus, the Firmware MUST do that as soon as possible, and make certain that **no RAM is
accessed until its _tristate_ configuration**, in order to avoid _bus contention_.
The hardware will make sure that the CPU-side '245s are enabled when `Phi2` is high
AND `A15` is low, so ROM or I/O accesses during the very first cycles will not cause
any problems. **6502 does a (fake) stack access during RESET**, thus note the trick
on _Chip selection_ for a complete solution. _None of these solutions will be
actually needed if using a properly **multiplexed** 6845_.

### RDY implementation

Note that this machine _does **not** negate RDY_ by itself, thus a _gentle_ pull-up
is connected to this pin on the CPU. Thus, **WDC parts** should not worry about the
execution of `WAI/STP` opcodes, as long as the _internal decoding_ jumper is NOT set
to provide `VSS` there (as pin 1 is used for `/VP` on them).

### Chip Selection

_Unless noted otherwise, all '688s and '139s are enabled as long as **`/EN`**
(perhaps available at CPU socket pin 1) is held **low**._

- **`/IO`** (peripheral page): a '688 compares `A8-A15` to `$DF`
- **`/RD`** (read enable): a '139 takes `Phi2 (nA1)` and `R/W (nA0)`, output on `n/Y3`
- **`/WR`** (write enable): the same '139 for `/RD`, output on `n/Y2`
- **`ROM /CS`**: inverted `A15` for optimum speed
- **`ROM /OE`**: a '139 takes `/RD (nA1)` and `/IO (nA0)`, output on `n/Y1`
- **`RAM /CS`**: a _permanently\* enabled_ '139 takes `Phi2 (nA1)` and `A15 (nA0)`,
output is **negated** `n/Y3`
- **`/MUX`** (enable CPU RAM access): the same '139 as above, output on `n/Y2`
- **`RAM /OE`**: a '139 _enabled by `A15`_ takes `Phi2 (nA1)` and `/EN (nA0)`,
output is **negated** `n/Y3`
- **`VIA /CS2`**: a '139 enabled by `/IO`\*\*, takes `A6 (nA1)` and `A5 (nA0)`, output
on `n/Y3`
- **`CRTC /CS`**: the same '139 as above, output on `n/Y2`
- **`VIA CS1`**: direct to `A4` as previously stated

\*) The _enable_ signal should be the **inverted `/RES`** signal, but _delayed_ at least
_5 clock cycles_, skipping fake stack access during RESET. Although an _RC-delayed `RESET`
signal has been considered_, perhaps the most recommended method would be the use of a
**'165 shift register**, easily wired up for an _delayed-by-8-cycles_ enable signal.

\*\*) Another '139 half may be used for enabling this one, taking `A7` and
`/IO` as *enable*, for **reduced mirroring** at some speed penalty. 

### RAM multiplexing

Since there is **no separate VRAM** on this machine (even the _colour RAM_ values
are read by the CPU _from the standard RAM_, written in parallel), adequate
multiplexing between CPU and CRTC addresses must be provided. The use of a
6345/**6445** (instead of the classic 6845/HD46505) with **tristate** outputs
eases the need for a _real_ '157-based multiplexer, relying on a couple of my
abundant '245s bus transceivers (acting as mere line drivers) instead. Note that
the ROM and peripherals are _directly connected to the CPU address lines_ and
thus not multiplexed at all.

Enabling the CRTC's outputs is as simple as connecting `Phi2` to the `LPSTB/TSC`
input. On the other hand, _the CPU bus cannot be simply enabled by this signal_.
In order to allow safe operation without _bus contention_, as previously stated,
the CPU addresses are enabled by the aforementioned `/MUX` signal. For this trick
to work, it is ESSENTIAL that **no RAM is accessed** (including stack) **until
the tristate option is activated**. _Read above about ways to achieve this,
thru proper enabling of the `RAM /CS` signal_. 

_Last modified: 20201023-1010_
