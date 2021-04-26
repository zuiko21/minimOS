# The Durango project

## System range

This is a development project, from an _experimental_ breadboard to a **fully-featured computer** on a PCB. Can be split
into **five** different machines:

- **Durango PROTO**, the experimental 1 MHz system with **128x128 bitmap** display.
- **Durango·SV**, a **4 bpp** version of the above, intended for **Super VGA** monitors.
- **Durango·S**, similar to the above but **synchronous** 1.536 MHz clock and for a SCART TV interface.
- **Durango·R**, composite **256x256 bitmap** video output, otherwise as above.
- **Durango·X**, the _definitive_ version, combining `S` and `R` versions (software-switchable).

From the above, only the PROTO version is limited to a 2 kiB VRAM, thus suitable for [**IOX interface**](../buses/iox.md)
and supplied separately as **picoVDU**.

## The computer board

### Main devices

The basic specs were as follows:

- 65C02 @ **1 MHz**
- **32 kiB RAM**
- **16 kiB (EP)ROM**
- Hardware interrupt timer at **~244 Hz** (1000000/4096, hardware disabled)

### Peripheral devices and interfaces

Originaly intended as a _6502 test board_, I/O capabilites were way limited. Notably _lacking a 6522 VIA_, devices included on breadboard are:

- A multiplexed **_LTC 4622_ 2-digit 7-segment display**, implemented thru an _8-bit latch_ (otherwise useable as a **general-purpose 8-bit output port**)
- A non-handshake, _polled_ **8-bit input port** intended for keyboard/joystick
- A single-bit port mimicking the `A0` line, dedicated for **hardware interrupt disable**
- A single-bit port mimicking the `D0` line, connected to a **buzzer**
- _Open Collector_ (inverting) drivers for both interrupt lines, intended for a **nanoLink** interface.

The aforementioned _nanoLink_ interface, together with a small (<256 bytes_) **bootloader EPROM**, greatly eases development.
But since it uses both interrupt lines, it is necessary to completely disable hardware (periodic) interrupt.

### Memory Map

Please note that this differs depending of the particular version:

- `$0000-$5FFF`: 24 kiB **SRAM** (all versions)
- `$6000-$7FFF`: 8 kiB **display** area (_SV_ and _X_ versions, regular RAM otherwise)
- `$8000-$8FFF`: **IO8 port** (nominally `$8000-$8003`, typically unused in _SV_ and _X_)
- `$9000-$9FFF`: **IO9 port** (keyboard _input_, any address in the range should do)
- `$A000-$AFFF`: **interrupt control**, _any_ access on an **even** address will _disable_ the hardware interrupt timer, on **odd** addresses will enable it, although _canonnical_ addresses `$A000` & `$A001` work best.
- `$B000-$BFFF`: **beeper**, will be set as `D0` on any address in range.
- `$C000-$FFFF` _read_: 16 kiB **EPROM**
- `$C000-$FFFF` _write_: 8-bit latch for the **LTC display** (may be used as GP _output_ port as well)

### Display options

Once again, most I/O on this computer is an afterthought... while experimenting with the generation of **video signals & sync**
(PAL/CCIR standard) I had the idea of connecting the video board to the computer via a simple 8-bit interface, what would become
the [**IOX port**](../buses/iox.md). Original display was a mere **128x128 bitmap** on a mere 2 kiB of _separate VRAM_, accessed
thru 3 I/O addresses:

- `$8000`: latch high address
- `$8001`: latch low address
- `$8003`: write data at latched address (_this may change to `$8002` in the future_)

The limited bandwith was suitable for such a small screen. The reduced resolutions was achived thru **line-doubling**,
actually sending 256 lines to the TV screen, which is within PAL/CCIR capabilities. On the other hand, this approach
is **not** valid for NTSC/EIA sets as the maximum visible _non-interlaced_ lines is 240, and any _reasonable_ screen shrinking
will no longer be a convenient power of two.

Pretty much the same problem arises for a **VGA monitor**, as the industry-standard _640x480 mode_ is actually a
doubled, non-interlaced version of the NTSC broadcast system. Assuming **line quadrupling** for these higher resolution devices,
the simplest solution was using the **800x600 _Super VGA_** mode, allowing easy display of 512 lines (4 times 128). Together
with a revised/simplified sync generation, this became into the **Durango·SV** board. This also sports a _chunky_ **4 bpp** mode
using the usual **GRgB palette** (hardwired). Whilst a _direct mapped_ screen was tried, access was still **asynchronous**
(and thus generating _snow_ on accesses, much like the _PROTO_ version). 

Thanks to the availability of **RGB inputs** thru SCART connections, this approach goes back to using a regular TV set for display.
The 8 kiB display area definitely asks for higher bandwidth, achieved via _direct mapped_ memory; but this time the CPU runs
**synchronously at 1.536 MHz** derived from the usual 24.576 MHz master clock.

_to be continued_
