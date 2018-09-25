# RoñaVid

### A simple, CRTC-less graphic card for the VME-like bus

## Video output

Will generate a *somewhat **VGA-compatible*** signal, albeit with slightly faster
timings -- due to my lack of 25.175 MHz oscillators. Originally intended as a
**bitmapped high resolution** display, an alternative version may generate a lower
resolution image with **4-bpp**, either *greyscale* or *GRgB* colour.

- Dot clock: **24.576 MHz**  
- VRAM: static **32 kiB** (62256)
- Resolution: **576x448** pixels *(alternative: 288x224)*
- Colour depth: **1 bpp** (alternative: *chunky* 4 bpp, either greyscale
or *non-indexed* colour)
- Scan rates: about 32 kHz horizontal, 61 Hz vertical

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
speed* to about 830 kHz.

For maximum performance, however, the RDY-generating circuit might be disabled, at the
cost of the typical *snow* during CPU accesses.

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

The uppermost bits of the "high" ROM carry the /HS, /VS and /DE (display enable)
signals. Since we are addressing a 32 kiB VRAM, we need the remaining 15 bits but,
as we have used up 3 out of all 16 ROM output bits, the *two least-significant bits*
which are missing will come **direct from the counters** (would need to be
*tristated*, though).

If we address each byte (8 pixels) of the VRAM as *positions*, the ROM addresses would
need not just the 32256 bytes of the VRAM, but also the *retrace* time (when the
blanking and sync pulses are generated). This will need **50400 *positions***, asking
for a couple of 27C512s. But since I own *plenty* of slowish **27C128**s, a less
precise addressing is used. By removing the two (fastest changing) least
significant bits from the EPROMs address bus, each *position* becomes a
**32-pixel strip** (about 1.3 microseconds), so every scanline takes *24 positions*, 18 
of them *active*. The lower resolution compared to the industry-standard VGA allows
for **wider front and back porchs**, thus these longer *positions* still render a
**properly timed and centered *HSync* pulse**, as all timings become multiples of the
1.3 uS *quantum*.

Between frames, a total of **77 lines** must be generated for blanking and *VSync*,
adding 1848 *positions*. Including **448 active lines** of 24 positions, the grand
total is **12600 *positions***, well within the 27C256 capacity. The 14-bit counter
(a **couple of 74HC4024**s) must be reset upon reaching 12600, detected via an AND gate.

## Video signal generation

No big deal here... for the bitmapped version, just a **74HC165 *shift register*** at
the VRAM output. However, the *chunky* 4bpp version may use a **74HC157 *multiplexer***
for transferring each half of the stored byte.

Back to the bitmap, the shift register will be clocked directly from the 24.576 MHz
dot clock, while the 14-bit counter is fed from 1/32 of that (768 kHz). 1/16 and 1/8
division factors are however fed directly to the VRAM's A0 & A1 lines, as previoulsy
described (thru *tristate* gates). All these division factors may come from a
**74HC393** (not sure if a *synchronous* counter is needed, though). 

*last modified: 20180925-2211*
