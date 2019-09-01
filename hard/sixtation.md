# SIXtation

A powerful **_65816_ graphic workstation** inspired by the _3M-compliant_ (1 MByte,
1 MegaPixel, 1 MIPS) computers of the early 80s (Sun-1, SGI IRIS 1000...)

## Specifications

- CPU: 65816 @ **9 MHz**
- FPU: 68882 @ **36 MHz** (overclocked)
- VDU: 6445 based, **1360x768**, up to 8 bpp
- RAM: **1 MiB** on board, two _Garth_ slots (up to **8 MiB**, 5 MiB possible)
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

Memory addresses above `$800000` will be reserved for I/O boards, and those above `$C00000`
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
hand, half the dot clock (36 MHz) might work for a _slightly overclocked_ FPU. Since
all timing is derived from the _dot clock_, the main CPU board **has no oscillator**, as
it will be located on the video board.

On the other hand, a somewhat reduced resolution of **880 x 864** should be compatible
with the _Apple Portrait Display_ (with non-square pixels, unfortunately), all
within software configuration. While this reduced resolution is compatible with the
Acer monitor, it is not recommended as sharpness will be sub-optimal.

### VRAM layout

Being **6445-based** (improved 6845), VRAM is organized in an _Amstrad-like_ fashion, but
with **16 scanlines per row**. While a _bitmapped_ display is optimum for performance,
colour is certainly desired. **Planar** layout is chosen for scalability.

Assuming a colour depth of **8 bits per pixel** (up to 256 colours), this needs a whopping
**1 MiB VRAM**, somewhat above the capabilities of a 65816, even at a mighty **9 MHz**.
Please note that the original _3 M_ workstations, while bearing slower CPUs (a 10 MHz
_MC 68000_ is about **2.5 times slower** than a **9 MHz 65816**), had _graphic coprocessors_
for much improved screen handling (_RasterOp_ on Sun, _Geometry Engine_ on SGI IRIS...).

### Performance improvements

Despite this handicap, there is one trick from Sun graphic cards that is _easily
implemented_ and will noticeably speed-up a few operations: the ability to _write on more
than one bit plane **simultaneously**_.

While this device is perfectly capable of displaying _graphic content_, most development
tasks are expected to be done on _text windows_. With more than one bit plane installed,
these are colour capable too; but then one _software trick_ (combined with the previous
**multi-plane writes**) may _improve drawing and **scrolling** speed noticeably_.

For the sake of simplicity, let us assume an example with 4 planes following the `GRgB` model:
```
    INK: 0010 (dark green)
  PAPER: 1110 (yellow)
```

Note that both planes 0 (light green) and 1 (red) will switch on every pixel depending
whether it is foreground (clear) or background (set). Since they take **identical values**
on both set or clear pixels, the whole byte can be set _on both planes_ at once, thanks
to the aforementioned hardware feature.

However, _neither planes 2 and 3 change_, no matter what gets printed! This means that
**these planes will remain constant** (one all set, the other one all clear), thus the
system _will not bother writing or **scrolling**_ them. All combined, **only one out of
4 planes** is actually accessed by the CPU.

In order to keep track of the actually used planed, an **enable mask** is to be used.
Upon `CLRS` this mask is reset as the _exclusive-OR_ of both INK and PAPER values. From
the above example, `0010 XOR 1110 =**1100**`, leaving planes 2 and 3 untouched (after
filling them appropriately).

However, further colours may appear on that window. Those should enable further planes,
and eventually all available planes would be in use, cancelling the performance
advantage -- until a new `CLRS` is issued. These new colours should be inclusive-ORed with
the current mask. If some _dark turuqoise_ (0011) text on white appears, we could compute
a new enable mask as follows:
```
    INK: 0011 (dark turquoise) _newly set_
  PAPER: 1110 (yellow)

         0011 XOR 1110 = 1101 (temporary mask)
old mask 1100  OR 1101 = 1101 (new _enable mask_ for this setting)

    INK: 0011 (dark turquoise)
  PAPER: 1111 (white) newly set

         0011 XOR 1111 = 1100 (temporary mask)
old mask 1101  OR 1100 = 1101 (definitive enable mask)
```

Printing logic operations are equally simple. _Disabled planes_ are of course ignored and,
thanks to the multiplane writes, easily done. A _temporary mask_ as per the previous examples must be computed,
and then ANDing that with both INK and PAPER codes results on which planes will take the
_normal_ pattern (INK) and the _inverse_ pattern (PAPER).
If more than a bit is set from those AND ops, the pattern may be set at once on all of them,
thanks to the multiplane write feature. However, unaffected planes must be checked for.

For instance:
```
    INK: 0011 (dark turquoise)
  PAPER: 1111 (white) newly set

         0011 XOR 1111 = 1100 (temporary mask)
           enable mask = 1101 (previously set)

         0011 AND 1100 = 0000 (ink AND temp, no "positive" planes to be set)
         1111 AND 1100 = 1100 (paper AND temp, planes 0 & 1 to be set with INVERTED pattern)

         1100 XOR 1101 = 0001 (temp XOR mask, plane 3 is NOT unaffected!)
         0001 AND 1101 = 0001 (...AND mask, plane 3 to be filled with 1s)
```
### Palette

The _planar_ video architecture allows easy **bit-depth configuration**, either at
build time or on-the-fly. While a single bit _bitmap_ (128 kiB) leads to simple
construction and high performance, it may be easily scaled by adding more RAM chips.
Several _fixed_ palettes (both colour and greyscale) have been considered depending on
bit depth (not limited to powers of two!), but the most versatile (and relatively simple)
option is the use of a suitable **RAMDAC**, preferibly of 24-bit type.

## Storage

**IDE/CF** and **SD/MMC** interfaces will be provided. The latter might be implemented on
_bit-banging_, unless the **65SPI** hardware is used. 

_last modified 20190901-1045_
