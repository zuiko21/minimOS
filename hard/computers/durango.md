# The Durango project

## System range

This is a development project, from an _experimental_ breadboard to a **fully-featured computer** on a PCB. Can be split
into **five** different machines:

- **Durango PROTO**, the experimental 1 MHz system with **128x128 bitmap** display.
- **Durango·SV**, a **4 bpp** version of the above, intender for **Super VGA** monitors.
- **Durango·S**, similar to the above but **synchronous** 1.536 MHz clock and for a SCART TV interface.
- **Durango·R**, composite **256x256 bitmap** video output, otherwise as above.
- **Durango·X**, the _definitive_ version, combining `S` and `R` versions (software-switchable).

From the above, only the PROTO version is limited to a 2 kiB VRAM, thus suitable for [**IOX interface**](../buses/iox.md)
and supplied separately as **picoVDU**.

## Specs

### The computer board

The basic specs were as follows:

- 65C02 @ **1 MHz**
- **32 kiB RAM**
- **16 kiB (EP)ROM**
- Hardware interrupt timer at **~244 Hz** (1000000/4096, hardware disabled)

Originaly intended as a _6502 test board_, I/O capabilites were way limited. Notably _lacking a 6522 VIA_, devices included on breadboard are:

- A multiplexed **_LTC 4622_ 2-digit 7-segment display**, implemented thru an _8-bit latch_ (otherwise useable as a **general-purpose 8-bit output port**)
- A non-handshake, _polled_ **8-bit input port** intended for keyboard/joystick
- A single-bit port mimicking the `A0` line, dedicated for **hardware interrupt disable**
- A single-bit port mimicking the `D0` line, connected to a **buzzer**
- _Open Collector_ (inverting) drivers for both interrupt lines, intended for a **nanoLink** interface.

The aforementioned _nanoLink_ interface, together with a small (<256 bytes_) **bootloader EPROM**, greatly eases development.
But since it uses both interrupt lines, it is necessary to completely disable hardware (periodic) interrupt.

_to be continued_
