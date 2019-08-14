# SIXtation

A powerful **_65816_ graphic workstation**
inspired by the _3M-compliant_ (1 MByte,
1 MegaPixel, 1 MIPS) computers of the early 80s
(Sun-1, SGI IRIS...)

## Specifications

- CPU: 65816 @ **9 MHz**
- FPU: 68882 @ **36 MHz** (overclocked)
- VDU: 6445 based, **1360x768**, up to 8 bpp
- RAM: **1 MiB** on board, two _Garth_ slots
(up to **8 MiB**, 5 MiB possible)
- ROM: 32 kiB _Kernel_, up to 4 MiB _library_
- Storage: CF & SD (possibly _bit-banged_) interfaces
- Usual 65xx ports, including **PS/2**

## Memory

In order to be fully _3 M compliant_, the main board is provided with **1 MiB RAM** as
standard. Then, two pin-header slots for _Garth Wilson's RAM 4 MiB cards_ are provided.
Since every 512 kiB `Chip Select` line is individually accesible, three RAM configurations
are supported:

- **1 MiB** (standard on-board RAM)
- **5 MiB** (add one Garth module, plus the supplied megabyte)
- **8 MiB** (needs two Garth modules, although two chips on the second one will remain unused)

Mwmory addresses above `$800000` will be reserved for special I/O, whereas above `$C00000`
are intended for _library_ ROM.

## Graphic card & clock

Perhaps on a separate PCB, but otherwise **higly integrated** on the system. Trying to
match the 1366/1360 x 768 resolution of my cheap Acer widescreen, which just fits the
_megapixel_ rating, the standard 85.5 MHz (85.86 MHz according to other sources) _dot clock_
is almost impossible to find from standard oscillator cans, whereas a **72 MHz** one seems
quite popular. There is a **reduced blanking** timing standard for that resolution, thus
seems quite suitable.

Divided by 8 it will generate the **9 MHz CPU clock** (instead of the previously specced
_10.7 MHz_), and further halved will fit the _4.5 MHz **HD6445** CRTC_ clock. On the other
hand, half the dot clock (36 MHz) might work for a _slightly overclocked_ FPU.

### VRAM

Being **6445-based** (improved 6845), VRAM is organized in an _Amstrad-like_ fashion, but
with **16 scanlines per row**. While a _bitmapped_ display is optimum for performance,
colour is certainly desired. **Planar** layout is chosen for scalability.

Assuming a colour depth of **8 bits per pixel** (up to 256 colours), this needs a whopping
**1 MiB VRAM**, somewhat above the capabilities of a 65816, even at a mighty **9 MHz**.
Please note that the original _3 M_ workstations, while bearing slower CPUs (a 10 MHz
_MC 68000_ is about **2.5 times slower** than a **9 MHz 65816**), had _graphic coprocessors_
for much improved screen handling (_RasterOp_ on Sun, _Geometry Engine_ on SGI IRIS...).

Despite this handicap, there is one trick from Sun graphic cards that is _easily
implemented_ and will noticeably speed-up a few operations: the ability to _write on more
of a bit plane **simultaneously**_.

## Storage

**IDE/CF** and **SD/MMC** interfaces will be provided. The latter might be implemented on
_bit-banging_, unless the **65SPI** hardware is used. 

_last modified 20190814-2204_
