# miniCoCo

A recreation of Tandy's [**TRS-80 _Color Computer_**](https://en.wikipedia.org/wiki/TRS-80_Color_Computer)
(version 1) with updated components. This may perform just like the _highly compatible_
[**Dragon 32/64**](https://en.wikipedia.org/wiki/Dragon_32/64) with a simple jumper setting.

## Proposed changes

- Use of **static RAM** instead of DRAM.
- Keep using _standard_ components (unlike later versions).
- **Dragon 32** (and _optionally_ **64**) compatibility via a jumper setting.
- Alternative **8x12 character matrix** for the 6847.
- **RGB video** output, preferably suited to European standards
(15625 kHz/50 Hz, although _60 Hz_ would be acceptable)

## Differences between CoCo and Dragon models

Based on the same [Motorola datasheet](http://www.colorcomputerarchive.com/coco/Documents/Datasheets/MC6883%20Synchronous%20Address%20Multiplexer%20(Motorola).pdf),
both computers are fairly similar (and thus **highly compatible**). Stated differences are:

- Keyboard matrix layout (some rows are swapped)
- Serial and parallel ports (see table below)
- ROM contents (and _size_, in case of the **Dragon 64**)
- PAL vs. NTSC video output

About the first issue, a couple of _'245s_ will easily turn keyboard rows 0-1-2-3-4-5 (CoCo)
into a **4-5-**0-1-2-3 order (Dragon); no big deal here. The next two items, however, ask for
further consideration as there are differences between both Dragon models:

Machine->     | CoCo     | Dragon 32 | Dragon 64
-------       | ----     | --------- | ---------
Serial port   | emulated | _n/a_     | **6551-based**
Parallel port | _n/a_    | Yes       | Yes
ROM size      | 16K      | 16K       | **2x**16K

### Serial and parallel ports

The original CoCo used a few VIA-1 pins (`PA1`, `CA1` and `PB0`) as the serial lines `TX`, `CD` and `RX`,
respectively. But on the Dragon these pins become `/STROBE`, `ACK` and `/BUSY` for the Centronics parallel
interface. While this seems no issue _as long as no more than one interface is populated_, the input lines
for parallel will collide with the _level shifter_ outputs, even if no device is connected to the (emulated)
serial port. This can be solved by _tri-stating_ input signals from the level shifter, **easily achieved**
as there are two free buffers on one of the '245s for _keyboard layout switching_.

> By the way, the aforementioned _level shifter_ circuit won't be discretely implemented any longer, as an IC like
**MAX232** seems a much better option nowadays. _One_ comparator is still needed for cassette input, though.

### ROM contents (and size)

The simplest option for a fully switchable machine would be the use of a **27C256** (32 kiB EPROM) with `A14` tied
to the _CoCo/Dragon_ option jumper. Another jumper at that **pin 27** (`A14` or `/PGM`) may leave a _pull-up_ on it
in case a 16 kiB, _non-switchable_ EPROM is used. However, the **Dragon 64** is supplied with _two_ 16 kiB ROMs
which are switched between _32 and 64 modes_ (never simultaneously!) thru PIA-1's `PB2` (`ROMSEL`). Thus, for a
_fully-compliant Coco/D32/D64_ computer, a whopping **64 kiB 27C512 EPROM** is needed. The aforementioned `ROMSEL`
line may go into `A15` but, once again, swapped for a _pull-up_ in case a smaller chip is used. Assuming the switch
line is **1** for _CoCo mode_ (convenient choice as it saves one inverter!) and `ROMSEL` is 1 for _64 mode_,
the ROM contents order may be  _D32_, _CoCo_, then  _D64_ and finally _CoCo_ again.

#### 32K-only version

An intermediate option, however, would be keeping the _Coco/Dragon **32**_ compatibility but losing the _Dragon 64_
option, as this will save the **ACIA** (and associated _level switcher_, independent from that on CoCo's _emulated_
serial) plus the **extra RAM**, which would mean _another_ 62256 chip. **ROM size** would be reduced to a reasonable
**32 kiB** _without mirroring_. `PB2` on VIA1 is no longer the `ROMSEL` outbut, but back an _input_ tied to ground
(or +5v in some boards). Decoding circuitry must be modified anyway in order to use a **single 16 kiB EPROM**
(or 32K for CoCo compatibility) instead of the _two 8 kiB ROMs_ on the original.

In any case, putting a _pulled-down_ `ROMSEL` into EPROM's **pin 1** will allow the use
of the alternative "64" ROM, while the missing 32K RAM could be added on the **expansion port**.
This way, a 27C512 EPROM is a must for Dragon 64 compatibility, even if no CoCo support is desired.
Since pin 1 is `Vpp` on any EPROM of 32 kiB or less, a _pulled-up_ (or pulled _down_?)
jumper is provided if Dragon 64 support is not needed.

### PAL vs NTSC video output

The 6847 VDG is designed around an NTSC display, with outputs in **YUV format**. This is pretty well matched to the
**MC1372 _encoder_** on both CoCo and Dragon computers but, in any case, a _composite video_ (if not RF-modulated)
output is supplied, which is not the best by any means, plus the **3.58 MHz NTSC** encoding could be hardly supported
in Europe. _There was a PAL version of the CoCo_, but since it uses **non-standard** ICs (TCC1000/HD61J204P)
is completely out of the question.

On the other hand, the Dragon (based on the very same datasheet for the CoCo) uses the same 6847 too, swapping the
MC1372 encoder for the similar **LM1889**; but a _rather complex_ circuit (although enterely based on 74-series
**standard** parts) does the whole **NTSC/PAL conversion**. This includes not only inverting the `øA` chrominance
component on alternate lines, but also _**switching off** the 6847's clock for nearly 100 lines while **generating**
its own `/HS` sync pulses_, actually turning the 60 Hz fields into 50 Hz ones. Alas, no RGB signal is supplied.

Latest CoCo's (3) provide RGB output (where neither NTSC or PAL encoding is used) but, once again, the use of a
**_non-standard_ TCC1014** IC makes this way unfeasible. Note that the 60 Hz frame rate should _not_ be an issue
on most monitors nowadays, as long as the signal is **RGB**.

But there is some hope: the French [Matra Alice](https://en.wikipedia.org/wiki/Matra_Alice), itself a clone of the
_simpler, CoCo-related_ [TRS-80 MC-10](https://en.wikipedia.org/wiki/TRS-80_MC-10), does use the 6847 too; but the
ubiquous MC1372 is replaced by a **mostly-discrete** circuit supplying **RGB output** for the already mandatory _Péritel_
connector, aka [SCART](https://en.wikipedia.org/wiki/SCART); but there is still an _unfathomable_ IC (`Z20` as seen on
the awful quality [schematics](https://system-cfg.com/photosforum/alice4k_schema_video.png)). Since this IC _seems_ to
intercept the VDG clock (much like the Dragon did), perhaps its only task is converting from 60 to 50Hz; this _conjecture_
is somewhat supported from the fact that it takes both sync signals and sort-of-mixes an obscure output to the `Y` signal,
most likely in order to **generate sync pulses** while the 6847 is stopped. _If this assumption is correct_, this part
of the circuit could be just deleted, getting an acceptable **60-Hz RGB video output**.

## Specs

* * * * * * TO BE DONE * * * * * *

Still within design phase, here is an outline of its basic specs:

- CPU: **65C02**
- Clock speed: **1.536 MHz** (although **1.5734375 MHz** might be preferred)
- VIA: single **65C22**, with the typical **piezo-buzzer** at `PB7-CB2`
- RAM: **32 kiB** (static) plus 1 kiB *shadow* RAM for attributes. 
- (E)EPROM: **32 kiB**
- Built-in video: **6445** based, 6845 may be used with extra multiplexing.

## Video output

The main feature of the otherwise simple **Acapulco** computer is the VGA-compatible
**colour video output**. But since a complete _4 bpp full VGA_ display would need
at least _128 kiB of VRAM_, some measures must be taken in order to reduce the memory
and bandwith requirememts so they fit into the 6502's capabilities:

1) **Halving the resolution**, both H & V, down to those on the _home computers_
of old times, via **line doubling**.
1) The use of an **attribute area**, allowing the whole image to be stored like a
_bitmap_, limited to **two available colours _each 8x8 pixels_**.

These restrictions allow the whole VRAM area to fit into a mere **9 kiB** (1 for the
_attribute area_), subtracted from the regular SRAM as _vampire-video_. Supplied with
32 kiB of static RAM, this seems a reasonable approach.

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

_Firmware_ may provide a module for **quick video mode selection** during startup.

6x45's _raster addresses_ are wired as the most significant bits. This allows fast
**hardware-assisted scrolling** (Amstrad-like). It also sets a _constant distance_
(`$400`) between the _colour RAM_ and the upper raster of each displayed character,
greatly simplifying the driver.


## Memory map

Within the usual 6502 restriction to 64 kiB address space, this machine is simply
defined as **32 kiB SRAM + 32 kiB EPROM**. From the latter, a full page (`$DFxx`)
is assigned to I/O devices -- although with quite a bit of mirroring.

Because of the _built-in video_ feature, some of the RAM is used as _VRAM_. **Colour
RAM** is, by the way, in a _separate **6116** chip_, but will be read by the CRTC only;
_writes on that area will be made **simultaneously on the 62256** too_, allowing
further reading by the CPU.

The standard memory map goes as follows:

- `$0000-$5BFF`: _62256_ **SRAM** (general purpose)
- `$5C00-$5FFF`: **Colour RAM** (**1K used** from a separate _6116_)
- `$6000-$7FFF`: **Video RAM** (stored in the _62256_)
- `$8000-$DEFF`: EPROM (**kernel & firmware**, plus any desired apps)
- `$DF00-$DFFF`: built-in **I/O** (NON selectable, but maybe _switchable_?)
- `$E000-$FFFF`: EPROM (continued kernel & firmware, including _hardware vectors_)



_Last modified: 20200131-1005_
