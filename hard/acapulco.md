# Acapulco

The **Acapulco** project, formerly called *Tampico*, is a simple 65C02 computer with
**built-in *VGA-compatible* video output**. Despite this output fitting a
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
presence of a *VGA-compatible* option suggests the industry-standard **25.175 MHz**
frequency; but some tinkering with the 6845/6345/6445 registers may achieve the
required compatibility. *Half* of this frequency is used as **dot clock**, as it
will use *half the resolution*, both horizontal and vertical, of the VGA standard.

Further divided by 16, this signal will provide the main **`Phi-2`** clock.
This way, CPU accesses will be **interleaved** with CRTC accesses for
**optimum performance**.

## Video output

The main feature of the otherwise simple **Acapulco** computer is the VGA-compatible
**colour video output**. But since a complete *4 bpp full VGA* signal would need
at least *128 kiB of VRAM*, some measures must be taken in order to reduce the memory
and bandwith requirememts so they fit into the 6502's capabilities:

1) **Halving the resolution**, both H & V, giving a resolution similar to the usual
*home computers* of old, via **line doubling**.
1) The use of an **attribute area**, allowing the whole image to be stored like a
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

- _for the non-standard 24.576 MHz:_
3) **320x200** (40x25 char.) shorter *back porch & sync pulses* (likely compatible)
3) **320x200** (40x25 char.) **much shorter sync** pulse (likely compatible)
3) **288x224** (36x28 char.) most likely compatible with *slightly* faster timing
3) **256x240** (32x30 char.) ditto, allowing a simpler driver
3) **320x200** (40x25 char.) **much shorter back porch** (*perhaps* compatible)

*Firmware* may provide a module for **quick video mode selection** during startup.

6x45's *raster addresses* are wired as the most significant bits. This allows fast
**hardware-assisted scrolling**. It also sets a *constant distance* (`$0400`) between
the *colour RAM* and the first raster of each displayed character, greatly simplifying
the driver.

### VGA compatibility and the 6845

As previously metioned, fully VGA compatibility can only be achieved thru the use of
a standard 25.175 MHz oscillator. The project is to be made using a 6445 CRTC and no
further issues should occur; however, in case a classic 6845 is used, another problem
can arise: it produces a **fixed length** (16 lines) *vertical sync* pulse, which
may throw off the vertical position of the image a bit. *This might be an issue on the
256x240 mode*, as the whole 480 image lines are used, and some monitors may not have
room enough for top or bottom lines under such displaced `VSYNC` pulse.

On the other hand, the 6345/6445 can fine-adjust the `VSYNC` pulse length
*and* position, thus highly recommended in any case. To keep the desired 6845
compatibility, this setting (together with those 6345/6445-specific ones)
**must be done by the Firmware** during *cold boot*, so the
OS *driver* does not have to check for other than the generic 6845 registers.

### Palette for the *Colour RAM*

For moderate bandwith and attractive presentation, a **GRgB palette** is used -- the
*green* channel sporting **4 levels**, as the human eye is most sensitive to this one.
The colour codes *for each character* (or the corresponding **8x8 pixel** area) are
recorded in a *chunky* fashion, the most significant nibble representing the
**background** one.

You can see the **GRgB palette** (among several discarded other ones)
[here](../other/grgb.html)

## Memory map

Within the usual 6502 restriction to 64 kiB address space, this machine is simply
defined as **32 kiB SRAM + 32 kiB EPROM**. From the latter, a full page (`$DFxx`)
is assigned to I/O devices -- although with quite a bit of mirroring.

Because of the *built-in video* feature, some of the RAM is used as *VRAM*. **Colour
RAM** is, by the way, in a *separate 6116 chip*, but will be read by the CRTC only;
*writes on that area will be made **simultaneously on the 62256** too*, allowing
further reading by the CPU.

The standard memory map goes as follows:

- `$0000-$5BFF`: *62256* **RAM** (general purpose)
- `$5C00-$5FFF`: **Colour RAM** (**1K used** from a separate *6116*)
- `$6000-$7FFF`: **Video RAM** (stored in the *62256*)
- `$8000-$DEFF`: EPROM (**kernel & firmware**, plus any desired apps)
- `$DF00-$DFFF`: built-in **I/O** (NON selectable, buy maybe *switchable*)
- `$E000-$FFFF`: EPROM (continued kernel & firmware, including *hardware vectors*)

Decoded via a '139, the **I/O page** supports just **four** internal devices
with a 32-byte area each (decoding address lines `A5-A6`), mirrored on the
lower half of the I/O page. Only two devices are included:

- **VIA** at `$DFFx` (actually $DFE0-$DFFF, also at $DF60-$DF7F)
- **CRTC** at `$DFCC-$DFCD` ($DFC0-$DFDF and $DF40-$DF5F)

Some mirroring could be reduced by taking `A4` to the VIA's `CS1` *active-high*
signal, limiting its appearances at the **nominal $DFFx** and $DF7x. The other
second half of the '139 may be used (taking A7) leaving undecoded the *lower half*
of the I/O page, but at the cost of increasing delays. **This is particularly critical
with the 6522 VIA** as 1 MHz parts may violate its `tACR` and `tACW` requirements.
*Using 2 MHz parts should provide adequate speed*, though.

Anyway, since a complete *expansion bus* is not fitted, there is a chance to
**disable internal decoding** thru the *CPU socket*. Pin 1 (`VSS` or `/VP`)
may be connected via a jumper to the decoding `/EN` enable input (active low).
A *pull-down* resistor will allow normal operation in case a W65C02S part is
used (which takes pin 1 as `/VP` output), but will not prevent a suitable
socket-installed card **disabling the built-in decoding** whenever an *external
I/O address* is issued. This method allows a *65816 card* to supply some
**extra memory** outside bank zero.

## Glue-logic implementation

Most of the ICs for decoding are **74HC688** and **74HC139**, as I own plenty of them.
As per **multiplexing the address lines** in order to share RAM access between the CPU
and the CRTC, the use of a 6445 waives the need for actual multiplexers. From the CPU
side, though, a couple of **74HC245** isolate this part of the address bus whenever the
CRTC ouputs are not tristated (during *Phi1*).

Please note that *the 6445 does NOT tristate its outputs* until it is so configured.
Thus, the Firmware MUST do that as soon as possible, and make certain that **no RAM is
accessed until its _tristate_ configuration**, in order to avoid *bus contention*.
The hardware will make sure that the CPU-side '245s are enabled when `Phi2` is high
AND `A15` is low, so ROM accesses during the first cycles will not cause bus contention.

Special consideration needs the 6116 **Colour RAM**. Wired (mostly) in parallel
with the regular 62256 RAM, it is *write-only* for the CPU (it will read from the
62256, which is always written with the same contents) thru another '245 (a '244 may
be used as well) and *read-only* for the CRTC (thru a suitable '374/'574 latch).

### RDY implementation

Note that this machine _does **not** negate RDY_ by itself, thus a *gentle* pull-up
is connected to this pin on the CPU. Thus, *WDC parts* should not worry about the
execution of `WAI/STP` opcodes, as long as the jumper is NOT set to provide `VSS` there.

### Chip Selection

_Unless noted otherwise, all '688s and '139s are *enabled* as long as **`/EN`**
(perhaps available at CPU socket pin 1) is held **low**._

- **`/IO`** (peripheral page): a '688 compares `A8-A15` to `$DF`
- **`/RD`** (read enable): a '139 takes `Phi2 (nA1)` and `R/W (nA0)`, output on `n/Y3`
- **`/WR`** (write enable): the same '139 for `/RD`, output on `n/Y2`
- **`ROM /CS`**: inverted `A15` for optimum speed
- **`ROM /OE`**: a '139 takes `/RD (nA1)` and `/IO (nA0)`, output on `n/Y1`
- **`RAM /CS`**: a *permanently enabled* '139 takes `Phi2 (nA1)` and `A15 (nA0)`,
output is **negated** `n/Y3`
- **`/MUX`** (enable CPU RAM access): the same '139 as above, output on `n/Y2`
- **`RAM /OE`**: a '139 *enabled by `A15`* takes `Phi2 (nA1)` and `/EN (nA0)`,
output is **negated** `n/Y3`
- **`VIA /CS2`**: a '139 enabled by `/IO`\*, takes `A6 (nA1)` and `A5 (nA0)`, output
on `n/Y3`
- **`CRTC /CS`**: the same '139 as above, output on `n/Y2`
- **`VIA CS1`**: direct to `A4` as previously stated
- **`/CRAM`** (colour RAM write): a '688 comparing `A10-A15` to the upper bits of `$5C`

*) Another '139 half may be used for enabling this one, taking `A7` and
`/IO` as *enable*, for **reduced mirroring** at some speed penalty. 

*Last modified: 20190310-1843*
