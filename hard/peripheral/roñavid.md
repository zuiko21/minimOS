# RoñaVid

### A simple, CRTC-less graphic card for the VME-like bus

## Video output

Intended for the **Jalapa (2)** 65816-based development computer, this card
will generate a somewhat **VGA-compatible** signal, albeit with *slightly faster*
timings, due to my lack of 25.175 MHz oscillators. Originally intended as a
**bitmapped high resolution** display, the complete version can generate a lower
resolution image with **4-bpp**, either *greyscale* or *GRgB* colour.

- Dot clock: **24.576 MHz**  
- VRAM: static **32 kiB** (62256)
- Resolution: **576x448** or 512x480 pixels (*lo-res:* **288x224** or 256x240)
- Colour depth: **1 bpp** (*lo-res:* chunky **4 bpp**, either greyscale
or *non-indexed* colour)
- Scan rates: **32 kHz** horizontal and nearly **61 Hz** vertical

While a *planar* hi-res version with 3 or 4 bitplanes was considered, the required
amount of wiring and soldering is not worth the effort, and without the *hardware
scrolling* feature of a **6845**, handling of 96-128 kiB of VRAM would be
unacceptably slow.

## Access arbitration

Speaking about *speed*, arbitration between CPU and video circuitry accesses yields
priority to the latter thru *negating the RDY line* during the enabled display times.
When fitted to a **2.304 MHz *Jalapa*** machine, this will get VRAM access of
**18 clock cycles each scanline**, plus an additional **5544 accessible cycles between
frames**. For heavy VRAM access rates, this will reduce the computer's *effective
speed* to about 830 kHz. *These figures will vary somewhat if using a different
CPU speed, or the alternate 512x480 or 256x240 resolutions.* In this last case,
there will be 24 free clock cycles each scanline, plus 3240 cycles between frames,
resulting in a worst case 666 kHz effective speed, albeit with somewhat reduced
latency and **much simpler software** routines.

For maximum performance, however, the RDY-generating circuit might be disabled, at the
cost of the typical *snow* showing up during CPU accesses.

## Addresses and sync generation

Instead of a *CRTC* (which needs a lot of supporting circuitry) or a *custom logic*
design from off-the-shelf compoments (unsurprisingly complex), the device gets
inspiration from
[this thread on 6502.org](http://forum.6502.org/viewtopic.php?f=4&t=4986)
but the ROM will generate not just sync and control signals, but also *video
addresses*. Two ROM chips are thus needed but since I own lots of suitable EPROMs,
this is no big deal. Advantages of this approach:

- *Tristating* the ROM ouputs via `/OE` will avoid the need of multiplexers (or bus
transceivers) for the video addresses.
- The video addresses are generated in a nice **contiguous, linear** fashion.

The uppermost bits of the "high" ROM carry the `/HS`, `/VS` and `/DE` (display enable)
signals. Since we are addressing a 32 kiB VRAM, we need another 15 bits but,
as we have used up 3 out of all 16 ROM output bits, the *two least-significant bits*
which are missing will come **direct from the counters** (would need to be
*tristated*, though).

On second thought... the control signals `/HS`, `/VS` and `/DE` **cannot** be
*tristated* like the remaining bits of the high ROM, otherwise loss of sync will
happen. Two workarounds are in mind:

- Not using `/OE` on the high ROM, using a 4-bit tristate line driver (74HC244). The
last bit must be multiplexed externally, but this is anyway needed for switching
between *bitmap* and *colour* modes (see below).
- Adding a **third ROM** just for control signals. As I own *plenty* of them, this is
the preferred solution (makes wiring simpler, too). Despite having extra room in the
high ROM, the lowermost bits will stay being generated from the counters
because of *bandwidth* reasons.

If we address each byte (8 pixels) of the VRAM as *positions*, the ROM addresses would
need not just the 32256 bytes of the VRAM, but also the *retrace* time (when the
blanking and sync pulses are generated). This will need **50400 *positions***, asking
for a couple of 27C512s. But since I own *plenty* of slowish **27C128**s, a less
precise addressing is used. *This prevents the use of a standard 25.175 Mhz
oscillator for a more standard resolution (**640x400** or 320x200/4bpp), as the tighter
sync requirements will need **at least** a 32 kiB EPROM bank with 26250 positions*.

In case of the *hi-res* mode, by removing the two (fastest changing) least
significant bits from the EPROMs address bus, each *position* becomes a
**32-pixel strip** (about 1.3 microseconds), so every scanline takes *24 positions*, 18 
of them *active*. The lower resolution compared to the industry-standard VGA allows
for **wider front and back porchs**, thus these coarse *positions* still render a
**properly sized and centered *HSync* pulse**, as all timings become multiples of the
1.3 uS *quantum*. *The alternative resolutions have 16 active positions*.

Between frames, a total of **77 lines** must be generated for blanking and *VSync*,
adding 1848 *positions*. Including **448 active lines** of 24 positions, the grand
total is **12600 positions**, well within the 27128 capacity. The 14-bit counter
(several **cascading 74HC161**s, as they **must** be synchronous) will be reset
upon reaching 12600, detected via a multi-input NAND gate. *Alternate resolutions
have 480 active lines and 45 blank lines*.

## Video signal generation

No big deal here... for the bitmapped version, just a **74HC165 shift register** at
the VRAM output. However, the *chunky* 4bpp version may use **multiplexing** instead
for transferring each half of the stored byte.

Back to the bitmap, the shift register will be clocked directly from the 24.576 MHz
dot clock, while the 14-bit EPROM addresses are taken from `Q2B` (384 kHz) and beyond.
`Q1D` & `Q2A` are however fed directly to the VRAM's `A0` & `A1` lines, as previoulsy
described (thru *tristate* gates). All these division factors may come from more
74HC161s, as *synchronous* counter are needed.

*Note:* the outputs from the **first** '161 are called `Q1A` (LSB) to `Q1D` (MSB),
the **second** '161 uses `Q2A` to `Q2D`, and so on.

## Colour/greyscale option

By *halving* both horizontal and vertical resolution, the same 32 kiB VRAM allows
up to **4 bits per pixel**. The resulting **288x224** resolution is feasible on
old-fasioned *PAL/NTSC TV* sets; however, it is best to standardise on **VGA output**
using *line duplication*. Now the dot-clock is actually one half of the master
frequency, however the *multiplexing* must be done at half of that, `Q1B` at
**6.144 MHz**. But each VRAM address gives two pixels only (vs. eight)
although at half the rate, thus the VRAM LSB comes from `Q1C` instead.
In order to *simplify* a **dual-mode circuit**, that LSB will go to `A14` on VRAM,
but will be muxed with `A0` from the CPU bus, shifting the remaining CPU address lines
to `A0...A13` on the VRAM.

The EPROM address bits are always hardwired to `Q2B-Q5A`.
Its contents, however, are different: **each scanline's addresses are sent twice** for
line duplication, which is logical as VRAM addresses are shifted left by one bit. Note
that the *direct bit for address LSB* goes from `Q1C` to `A14` *on the VRAM* but is
mapped to `A0` on the *CPU bus* side! Other than that, the addresses generating circuits
remain pretty much the same, including resetting at *position* 12600. Of course,
every *position* here accounts for a **16-pixel strip** (instead of 32).  

## Main Component List

Qty. | Ref.    | pins | comments
---- | ----    | ---- | --------
5    | 74HC161 |  80  | counters
3    | 27C128  |  84  | address & sync generator
1    | oscil.  |   4  | main clock
1    | 74HC30  |  14  | reset device
1    | 62256   |  28  | VRAM
9    | 74HC245 | 180  | CPU-bus and video output "multiplexers" (\*)
2    | 74HC139 |  16  | internal signal decoding
1    | 74HC165 |  16  | video shift register (bitmap)
1    | 74HC157 |  16  | pixel multiplexer (lo-res)
1    | 74HC688 |  20  | CPU-bus decoder
1    | 'HC4316 |  16  | greyscale analog switch

\*) May use **3 less** of them if single-resolution. *Further pin savings by replacing
a few of them for 74HC**244**s*.

*last modified: 20180930-1224*
