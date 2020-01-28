# Hardware for minimOS

## Supported architectures

With great embarrassment I have to admit never having owned a 65xx computer...
but suport for these classic machines shouldn't be difficult to add -- for
instance, I have declared as 'reserved' the two first zero-page bytes in case
the utterly popular Commodore-64 (using a 6510) is targeted.

Back to my **own-designed** machines, here's the current history & roadmap:

## Computers

**MTE _("Medidor de Tiempos de Exposición", Exposure Time Meter)_**

  * Status: finishing design.
  * Form-factor: soldered PCB.
  * Specs: 1 MHz 6503 (28 pin, 4 kiB addressing space), **128-byte RAM**,
3 kiB-EPROM (useable range from a 2732), VIA 6522
  * Interfaces: four (very large) **7-segment LED digits**, light sensor,
a couple of buttons...


[**SDd _("Sistema de Desarrollo didáctico", Learning Development 
System)_**](https://flic.kr/s/aHsjCMszTY)

  * Status: [WORKING!](https://twitter.com/zuiko21/status/936654607014653952?s=19)
  * Form-factor: solderless breadboard.
  * Specs: 1 MHz 65SC02, **2 kiB RAM, 2-4 kIB (E)EPROM**, VIA 65C22.
  * Interfaces: Amplified piezo buzzer between PB7-CB2,
currently with a VIA-attached 4-digit **LED-keypad**.


[**CHIHUAHUA**](https://flic.kr/s/aHsjEn5ntM)

  * Status: Finished and _sort-of_ working, but with some strange bug with VIA,
not solved yet. _Likely to be discarded_.
  * Form-factor: Soldered, compact version of SDd. Perfboard with point-to-point soldering.
  * Interfaces: Piezo buzzer between PB7-CB2, SS-22 and old _VIAport_ connectors.


[**CHIHUAHA PLUS**](https://flic.kr/s/aHsjEGuCH3)

  * Status: under construction (recently redesigned).
  * Form-factor: Perfboard with point-to-point soldering.
  * Specs: **1 MHz (socketed)** 65C02, **16 kiB RAM, 32 kiB EPROM**, VIA 65C22.
_Can be configured for **32 kiB RAM + 16 kiB EPROM** if desired_.
  * Interfaces: Amplified piezo buzzer between PB7-CB2, SS-22 and old _VIAport_ connectors.


[**SDx _("Sistema de Desarrollo eXpandible", Expansible Develpment 
System)_**](https://flic.kr/s/aHsjDAwJBR)

  * Status: aborted during construction :-(
  * Form-factor: Perfboard with point-to-point soldering.
  * Specs: 1.25 / 2 MHz 65C02/102, 8-16 kIB RAM, 32 kiB EPROM, VIA 65C22,
ACIA 65SC51, RTC 146818.
  * Interfaces: Amplified piezo buzzer between PB7-CB2, Hitachi LCD, TTL-level RS-232,
SS-22 and old _VIAport_ connectors. Several diagnostic LEDs.


**Baja**

  * Status: never started :-(

> Intended to be a _fully bankswitching_ **65C02 SBC**, but pluggable into a backplane, too.


[**Jalapa (formerly _SDm_)**](jalapa2.md)

  * Status: almost finished design, heavily _revamped_ as of Oct-2018.
  * Form-factor: Perfboard with point-to-point soldering.
  * Specs: 1.8432 / 2.304 MHz **65816**, **128/512 kiB RAM**,
up to **32 kiB _Kernel_ EPROM** plus **up to 512 kiB _library_ EPROM**,
VIA 65C22 (x2?), ACIA 65SC51.
  * Interfaces: Amplified piezo buzzer between PB7-CB2, SS-22, new _VIAport**2**_
(_SBC-2_ style but with "mirrored" power pins), TTL-level RS-232,
_VME-like_ slot (65816 direct expansion)


[**Acapulco**](acapulco.md)

  * Status: almost finished design.
  * Form-factor: Perfboard with point-to-point soldering.
  * Specs: **1.536 MHz** 65C02, **32 kiB SRAM** (plus 1 kiB in parallel as _attribute area_, 
**32 kiB EPROM**, VIA 65C22, CRTC HD6445. _Intended to be a **colour & graphics** capable SBC._
  * Interfaces: Piezo buzzer, SS-22, new VIA connector, **VGA-compatible** video output
(~320x200 @ 16 colours in gBRG mode, only 2 of them on any 8x8-pixel block)


[**miniKIM**](minikim.md)

  * Status: finishing specs.
  * Form-factor: Perfboard with point-to-point soldering.
  * Specs: 1 MHz 6502, **32 kiB RAM (16 KiB available), 2x16 kiB EPROM**, 2xVIA 6522,
ready for _cheap video_ output. _May use 32K RAM and 16K EPROM_ instead.
  * Interfaces: original KIM keypad, **6x seven-segment displays** (muxed LTC4622),
original Application & Expansion slots.


[**miniPET**](minipet.md)

  * Status: **essentially finished** design.
  * Form-factor: Perfboard with point-to-point soldering.
  * Specs: **1.57 MHz** 65(C)02, **32 kiB SRAM** (plus 2 kiB _VRAM_), up to **32 kiB EPROM**,
VIA 65(C)22, PIA 6521/6821, CRTC HD6845, with _optional second PIA_ for **IEEE-488** interface.
  * Interfaces: **same as the original PET**; cassette and IEEE-488 on
separate _optional_ board.

> _This is a recreation of the **Commodore PET/CBM 8032**, 
switchable between **40 and 80 columns**_, with updated components
(e.g. SRAM) and **VGA-compatible** output (thus about **57% faster**).


**Tijuana**

  * Status: finishing design.
  * Form-factor: Single layer PCB?
  * Specs: **6.144 MHz 65816**, 16 kiB SRAM (plus 16 more for _ROM-in-RAM_),
**3x32 kiB VRAM**, 16 kiB EPROM, VIA 65C22, **CRTC HD6845**, ACIA 6551A.
  * Interfaces: Piezo buzzer, TTL-level async., SS-22, parallel input,
**VGA-compatible** video output (**~576x448** @ up to **4bpp**, gBRG or greyscale),
_VME-like_ slot (65816 direct expansion) 

> Intended to be a **colour & graphics** capable **VT-52** based terminal.


**Veracruz** _(might become the **SIXtation Lite**)_

  * Status: in design stage _(might become a lower-spec **SIXtation**)_.
  * Form-factor: thru-hole PCB?
  * Specs: **3.072 MHz 65816, 512 kiB RAM, 32 kiB _Kernel_ EPROM, 512 kiB _lib_ EPROM**,
2x VIA 65C22, UART 16C550 (?), RTC MC146818 (?).
  * Interfaces: Piezo buzzer, new VIA and SS-22 connectors, TTL-level async,
**65SIB** (?), Hitachi LCD thru VIA (?), **PS/2**, _VME-like_ slot (65816 direct expansion)

> _Likely to include a **4bpp, ~640x400px** card._


**Jalisco** _(might be merged with **SIXtation**)_

  * Status: in design stage.
  * Form-factor: 4-layer PCB, SMD components.
  * Specs: up to **13.5 MHz 65816**, optional **68881/882 FPU @ 24 MHz** or faster,
up to **8 MiB RAM** (2 x Garth's modules), 32 kiB Kernel + **4 MiB _lib_ EPROM**,
2x or 3x VIA 65C22, UART 16C552, RTC MC146818, _ROM-in-RAM_.
  * Interfaces: most likely those of _Veracruz_, plus CF & SD-card (via **65SIB**),
_VME-like slot_...


[**SIXtation**](sixtation.md)

  * Status: in design stage.
  * Form-factor: 4-layer PCB, SMD components.
  * Specs: **9 MHz 65816**, **_24.576 MHz_ 68881/882 FPU** (or faster),
up to **8 MiB RAM** (2x Garth's modules), **32 kiB Kernel + 4 MiB _lib_ EPROM**,
2x VIA 65C22, (2x) 16C552 UART, MC146818 RTC, _ROM-in-RAM_.
  * Video output: 6445-based, _planar_ up to 8x128 kiB VRAM and **8 bpp**, typically **1360x768**.
  * Other interfaces: most likely those of _Jalisco_. Will _definitely_ include **PS/2**
keyboard/mouse ports and **flash-memory** via 65SIB.

> Base design allows an alternate **SIXtation Turbo @ 13.5 MHz** and **1152x896px**.


### Non-65xx architectures

[**KERAton**](https://flic.kr/p/dUEH5s)

  * Specs: 921.6 kHz **MC6800, 128-byte RAM**, up to 32 kiB EPROM,
PIA **CM602** (6820 clone), ACIA 2651.

> Made from **ceramic**-cased ICs only.


[**miniCoCo**](minicoco.md)

  * Specs: 895 kHz **MC6809**, 32-64 KiB **S**RAM, 2x PIA 6821,
**MC6847 video** (with _RGB_ output).

> Recreation of Tandy's **TRS-80 _Color Computer_** (version 1), switchable to
mimic the highly compatible **Dragon 32/64**.


[**miniMC10**](minimc10.md)

  * Specs: 895 kHz **MC 6803** _MCU_, **8 KiB** SRAM, **MC6847** video (with _RGB_ output).

> Recreation of Tandy's **TRS-80 _MC-10_**), perhaps switchable to mimic its french clone **Matra Alice**.


## Peripherals (TBD)

**LED-Keypad**

  * Status: [WORKING!](https://flic.kr/p/dL6Nec)
  * Form-factor: solderless breadboard.
  * Specs: four 7-segment LED displays, 16-key keypad.
  * Interface: old-style _VIAport_ connector.

Intended as a basic I/O device, current driver allows hex input via a _shift_ key.


**ASCII Keyboard**

  * Status: [in design stage.](https://flic.kr/p/e7C1mS)
  * Form-factor: solderless breadboard.
  * Specs: **64 keys**, two sets of three modifier keys. _May include a 20x4 LCD_.
  * Interface: old-style _VIAport_ connector, thinking about using the new **VIAport2**.

Conveniently laid out keyboard, the use of an **optional LCD** will make a _self-contained
simple terminal_.


**[PASK (_Port-'A' Simple Keyboard_)](pask.md)**

  * Status: in design stage.
  * Specs: **40 keys** including the three usual _modifiers_ `Shift`, `Ctrl` and `Alt`.
  * Interface: single **VIAport2**, supposedly compatible with _Centronics_ printer interface.

A self-contained keyboard, supported by a **minimal driver**.  Allows input of the **full 8-bit** ASCII set.


**Roñavid**

  * Status: (almost) finished design.
  * Specs: **VGA-compatible** output, typically **576x448 _bitmap_** or **288x224 @ 4bpp** _chunky_).
  * Interface: _VME-like bus_.
  
_Somewhat cumbersome_ **video card**. No CRTC, just _suitably programmed EPROMs_
generating all needed addresses and signals.


**mu-VDU**

  * Status: (almost) finished design.
  * Specs: **VGA-compatible** output of **288x224px bitmap**.
  * Interface: **6502-CPU _socket_**

Simple, universal **graphic display**. _An extended **planar** version might provide **8 colours**_.
---
_...and many more to come!_

_last modified: 20200128-1437_
