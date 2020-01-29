# miniCoCo

A recreation of Tandy's [**TRS-80 _Color Computer_**](https://en.wikipedia.org/wiki/TRS-80_Color_Computer)
(version 1) with updated components. This may perform just like the _highly compatible_
[**Dragon 32/64**](https://en.wikipedia.org/wiki/Dragon_32/64) with a simple jumper setting.

## Proposed changes

- Use of **static RAM** instead of DRAM.
- Keep using _standard_ components (unlike later versions).
- **RGB video** output, preferably suited to European standards
(15625 kHz/50 Hz, although _60 Hz_ would be acceptable)
- **Dragon 32/64** compatibility via a jumper setting.
- Alternative 8x12 **character matrix** for the 6847.

### Differences between CoCo and Dragon models

Based on the same [Motorola datasheet](http://www.colorcomputerarchive.com/coco/Documents/Datasheets/MC6883%20Synchronous%20Address%20Multiplexer%20(Motorola).pdf),
both computers are fairly similar (and thus **highly compatible**). Stated differences are:

- Keyboard matrix layout (some rows are swapped)
- Serial and parallel ports
- ROM contents (and size in case of the Dragon **64**)
- PAL vs. NTSC video output

For the first issue, a couple of _'245s_ will easily turn keyboard rows 012345 (CoCo)
into a 450123 order (Dragon); no big deal here. The following two items, however, ask for further
consideration as there are differences between both Dragon models:

Machine:      | CoCo     | Dragon 32 | Dragon 64
========      | ====     | ========= | =========
Serial port   | emulated | _n/a_     | **6551-based**
Parallel port | _n/a_    | Yes       | Yes
ROM size      | 16K      | 16K       | **2x**16K

The original CoCo used a few VIA-1 pins (`PA1`, `CA1` and `PB0`) as the serial lines `TX`, `CD` and `RX`, respectively.
But on the Dragon these pins become `/STROBE`, `ACK` and `/BUSY` for the Centronics parallel interface.
While this seems no issue _as long as no more than one interface is populated_, the input lines for parallel will collide with
the _level shifter_ outputs, even if no device is connected to the (emulated) serial port. This can be solved by _tri-stating_
input signals from the level shifter, **easily achieved** as there are two free buffers on one of the '245s for _keyboard layout switching_.

> By the way, the aforementioned _level shifter_ circuit won't be discretely implemented any longer, as an IC like **MAX232**
seems a much better option nowadays. _One_ comparator is still needed for cassette input, though.

As per the ROM contents, the simplest option would be the use of a **27C256** (32 kiB EPROM) with `A14` tied to the _CoCo/Dragon_
switching option. Another jumper at `A14` may leave a _pull-up_ on it in case a 16 kiB, non-switchable EPROM is used. However,
the **Dragon 64** is supplied with _two_ 16 kiB ROMs which are switched between _32 and 64 modes_ (never simultaneously!) thru
PIA-1's `PB2` (`ROMSEL`). Thus, for a _fully-compliant Coco/D32/D64_ computer, a whopping **64 kiB 27C512 EPROM** is needed.
The aforementioned `ROMSEL` line may go into `A15` but, once again, swapped for a _pull-up_ in case a smaller chip is used.
Assuming the switch line is 0 for _CoCo mode_ and `ROMSEL` is 1 for _64 mode_, the ROM contents order may be
_CoCo_, _D32_, _CoCo_ again and finally _D64_.

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



_Last modified: 20200129-1013_
