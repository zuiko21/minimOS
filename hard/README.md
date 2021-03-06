# Hardware for minimOS

## Supported architectures

With great embarrassment I have to admit never having owned a 65xx computer...
but suport for these classic machines shouldn't be difficult to add -- for
instance, I have declared as 'reserved' the two first zero-page bytes in case
the utterly popular Commodore-64 (using a 6510) is targeted.

Back to my **own-designed** devices, here's the range (past, present and future):

## (Simple) Computers

### 65x02-based

[**MTE** _("Medidor de Tiempos de Exposición", Exposure Time Meter)_](computers/mte.md)

  * Status: finishing design.
  * Form-factor: soldered PCB.
  * Specs: 1 MHz **6503** (28 pin, 4 kiB addressing space), **128-byte RAM**,
3 kiB-EPROM (useable range from a 2732), VIA 6522
  * Peripherals: four (very large) **7-segment LED digits**, light sensor,
a couple of buttons...


[**SDd** _("Sistema de Desarrollo didáctico", Learning Development System)_](computers/sdd.md)

  * Status: [WORKING!](https://twitter.com/zuiko21/status/936654607014653952?s=19)
  * Form-factor: [solderless breadboard.](https://flic.kr/s/aHsjCMszTY)
  * Specs: 1 MHz 65SC02 (only 13 address bits used), **2 kiB RAM, 2-4 kIB (E)EPROM**,
VIA 65C22.
  * Peripherals: Amplified piezo buzzer between PB7-CB2,
currently with a VIA-attached 4-digit **LED-keypad**.


[**CHIHUAHUA**](computers/chihuahua.md)

  * Status: Finished and _sort-of_ working, but with some strange bug around VIA access,
not solved yet. _Likely to be discarded_.
  * Form-factor: [Perfboard with point-to-point soldering.](https://flic.kr/s/aHsjEn5ntM)
  * Peripherals: Piezo buzzer between PB7-CB2
  * Interfaces: **SS-22** and _old **VIAport**_ connectors.

> Soldered, compact version of [SDd](sdd.md).

[**CHIHUAHA PLUS**](computers/chihuahuaplus.md)

  * Status: [under construction (recently redesigned).](https://flic.kr/s/aHsjEGuCH3)
  * Form-factor: Perfboard with point-to-point soldering.
  * Specs: **1 MHz (socketed XTAL)** 65C02, **16 kiB RAM, 32 kiB EPROM**, VIA 65C22.
_Can be configured for **32 kiB RAM + 16 kiB EPROM** if desired_.
  * Peripherals: _Amplified_ piezo buzzer between PB7-CB2
  * Interfaces: **SS-22** and _old **VIAport**_ connectors.


[**miniKIM**](computers/minikim.md)

  * Status: finishing specs.
  * Form-factor: Perfboard with point-to-point soldering.
  * Specs: 1 MHz 6502, **32 kiB RAM (16 KiB available), 2x16 kiB EPROM**, 2xVIA 6522,
ready for _cheap video_ output. _May use 32K RAM and 16K EPROM_ instead.
  * Peripherals: original KIM keypad, **6x seven-segment displays** (muxed LTC4622).
  * Interfaces: original Application & Expansion slots, _upstream tap_ for **cheap video**.


[**DURANGO**](computers/durango.md)

  * Status: **working**.
  * Form-factor: several solderless breadboards.
  * Specs: 1 MHz 6502, **32 kiB RAM, 16 kiB EPROM**, includes **picoVDU**
TV video output (128x128 _bitmap_).
  * Peripherals: simple bit buzzer, **2x seven-segment displays** (muxed LTC4622).
  * Interfaces: 8-bit input (`IO9`), 8-bit output for _picoVDU_ (`IO8`)

> Originally intended as a **6502 CPU tester** with _no I/O_ whatsoever, it evolved
into a fully featured development platform with sort-of integrated **video output**.
_May become a definitive, improved version in perfboard_


[**miniPET**](computers/minipet.md)

  * Status: **essentially finished** design.
  * Form-factor: Perfboard with point-to-point soldering.
  * Specs: **1.57 MHz** 65(C)02, **32 kiB SRAM** (plus 2 kiB _VRAM_), up to
**32 kiB EPROM**, VIA 65(C)22, PIA 6521/6821, CRTC HD6845, with _optional second PIA_
for **IEEE-488** interface.
  * Interfaces: **same as the original PET**; cassette and IEEE-488 on separate
_optional_ board.

> _This is a recreation of the **Commodore PET/CBM 8032**, 
switchable between **40 and 80 columns**_, with updated components
(e.g. SRAM) and **VGA-compatible** output (thus about **57% faster**).


[**Tampico**](computers/tampico.md)

  * Status: finishing specs.
  * Form-factor: Perfboard with point-to-point soldering.
  * Specs: **1.536 MHz** 65C02, **32 kiB SRAM**, **32 kiB EPROM**, VIA 65C22, CRTC HD6845/6445.
  * Peripherals: Piezo buzzer, **VGA-compatible** video output
(**320x200/288x224 bitmap** with options of _**400/448 lines**_ and _**2 bpp colour**_)
  * Interfaces: SS-22, new VIA connector.

> A _black & white_ version of **Acapulco**, albeit with a 'high' resolution option.
_Might include a 6551-based TTL serial_.
> Optional **2 bpp colour mode** by halving horizontal resolution.


[**Acapulco**](computers/acapulco.md)

  * Status: almost finished design.
  * Form-factor: Perfboard with point-to-point soldering.
  * Specs: **1.536 MHz** 65C02, **32 kiB SRAM** (plus 1 kiB in parallel as
_attribute area_, **32 kiB EPROM**, VIA 65C22, CRTC HD6445.
_Intended to be a **colour & graphics** capable SBC._
  * Peripherals: Piezo buzzer, **VGA-compatible** video output
(**320x200/228x224 @ 16 colours** in gBRG mode, only 2 of them on any 8x8-pixel block)
  * Interfaces: SS-22, new VIA connector.

> _May use an **alternate attribute area**, as CRAM is really 2 kiB_.


### 65816-based

[**Jalapa** (formerly _SDm_)](computers/jalapa2.md)

  * Status: almost finished design, heavily _revamped_ as of Oct-2018.
  * Form-factor: Perfboard with point-to-point soldering.
  * Specs: 1.8432 / 2.304 MHz **65816**, **128-512 kiB RAM**,
up to **32 kiB _Kernel_ EPROM** plus **up to 512 kiB _library_ EPROM**,
VIA 65C22 (x2?), ACIA 65SC51, ROM-in-RAM, RTC 146818 (?).
  * Peripherals: Amplified piezo buzzer between PB7-CB2.
  * Interfaces: SS-22, new _VIAport**2**_ (_SBC-2_ style but with "mirrored" power pins),
TTL-level RS-232, **_VME-like_ slot** (65816 direct expansion).

> **Development system**, much like the former _SDx_ project.


[**Tijuana**](computers/tijuana.md)

  * Status: finishing design, _revamped as 20200413_
  * Form-factor: Single layer PCB?
  * Specs: **3.072 MHz 65816**, 128 kiB SRAM (expandable to **512 kB**),
(optional?) 32 kiB **ColourRAM**, 32 kiB EPROM, VIA 65C22, **CRTC HD6845**, ACIA 6551A.
  * Peripherals: Piezo buzzer, **VGA-compatible** video output (**640x400/576x448**
bitmap or up to **4bpp** on 8x1 _attribute area_, gBRG or greyscale?).
  * Interfaces: TTL-level async., SS-22, VIAport2.

> _Intended to be a **graphics** (and perhaps _colour_) capable **VT-52** based terminal_,
a bit like an '816-based **Tampico** computer. Might use a 16C550 instead of the 6551.


[**Tantoyuca**](computers/tantoyuca.md)

  * Status: creating specs
  * Form-factor: Single layer PCB?
  * Specs: **3.072 MHz 65816**, 128 kiB SRAM (expandable to **512 kB**),
32 kiB EPROM, VIA 65C22, **CRTC HD6845**, ACIA 6551A.
  * Peripherals: Piezo buzzer, **VGA-compatible** video output
  * Display resolution: **640x400/576x448**
bitmap, **320x400/288x448 2bpp** or **160x400/144x448 _gBRG_ 4bpp**.
Might reduce vertical resolution to 200/224 lines for reduced 16 kiB
_vampire video_ memory.
  * Interfaces: TTL-level async., SS-22, VIAport2.

> _Might become integrated with the Tijuana project_, a bit like an
'816-based **Tampico** computer. Might use a 16C550 instead of the 6551.
Might switch between high and low resolution (400/448 vs. 200/224 lines)
thru the `E` line, _remapping VRAM_ from $10000-$17FFF to just 16 kiB at
$4000-7FFF, more suitable for 6502 emulation mode.


##  Workstations (65816-based)

[**Veracruz**](computers/veracruz.md)

  * Status: in design stage.
  * Form-factor: thru-hole PCB?
  * Specs: **6.144 MHz 65816**, 512 kiB RAM, 32 kiB _Kernel_ EPROM, 512 kiB _lib_ EPROM,
2x VIA 65C22, UART 16C550, RTC MC146818 (?), ROM-in-RAM. 
  * Peripherals: Piezo buzzer, Hitachi LCD thru VIA (?).
  * Interfaces: new VIA and SS-22 connectors, TTL-level async, **65SIB** (?), **PS/2**,
_VME-like_ slot (65816 direct expansion).

> _Likely to include a **4bpp, 640x400/576x448 px** card (becoming the **SIXtation Lite**)_


[**Jalisco**](computers/jalisco.md) _(CPU card for **SIXtation**)_

  * Status: in design stage.
  * Form-factor: 4-layer PCB, SMD components.
  * Specs: **7.16-9 MHz 65816**, **68881/882 FPU**, **1 MiB RAM, expandable**
(2 x Garth's modules), 32 kiB Kernel + **4 MiB _lib_ EPROM**, 2x or 3x VIA 65C22,
UART 16C552, RTC MC146818, _ROM-in-RAM_.
  * Peripherals: most likely those of _Veracruz_, plus CF & SD-card.
  * Interfaces: most likely those of _Veracruz_, including **65SIB**, _VME-like slot_...

> The 7.16 MHz version is the CPU card for _SIXtation-P_ (**640x864 px**),
while the standard model uses a **9 MHz** clock (**1360x768 px**).


[**Tabasco**](computers/tabasco.md) _(CPU card for **SIXtation TURBO**)_

  * Status: in design stage.
  * Form-factor: 4-layer PCB, SMD components.
  * Specs: **13.5 MHz 65816**, **68881/882 FPU**, **1 MiB RAM, expandable**
(2 x Garth's modules), 32 kiB Kernel + **4 MiB _lib_ EPROM**, 2x or 3x VIA 65C22,
UART 16C552, RTC MC146818, _ROM-in-RAM_.
  * Peripherals: most likely those of _Jalisco_, plus CF & SD-card.
  * Interfaces: most likely those of _Jalisco_.


[**SIXtation**](computers/sixtation.md) _essentially a **Jalisco/Tabasco** CPU card with an 8-plane VDU_

  * Status: in design stage.
  * Form-factor: 4-layer PCB, SMD components.
  * Specs: **9 MHz 65816** (base model), **24.576 MHz 68881 FPU** (or faster), up to
**8-9 MiB RAM** using the _Jalisco_ (or _Tabasco_) CPU card.
  * Video output: VGA, 6445-based, _planar_ up to 8x128 kiB VRAM and **8 bpp**, typically
**1360x768 px**. 24-bit CLUT.
  * Other interfaces: those of _Jalisco/Tabasco_.

> Range include the P (portrait) version (**7.16 MHz, 640x864 px**) and _TURBO_ model
(**13.5 MHz, 1152x896 px**). Also the FPU-less, Veracruz-based _SIXtation Lite_
(**6.144 MHz, 576x448 px, 4 bpp**).


## Aborted projects (6502-based)

[**SDx _("Sistema de Desarrollo eXpandible", Expansible Develpment 
System)_**](https://flic.kr/s/aHsjDAwJBR)

  * Status: aborted during construction :-(
  * Form-factor: Perfboard with point-to-point soldering.
  * Specs: 1.25 / 2 MHz 65C02/102, 8-16 kIB RAM, 32 kiB EPROM, VIA 65C22,
ACIA 65SC51, RTC 146818.
  * Peripherals: Amplified piezo buzzer between PB7-CB2, several diagnostic LEDs.
  * Interfaces: Hitachi LCD, TTL-level RS-232, SS-22 and old _VIAport_ connectors.


**Baja**

  * Status: never started :-(

> Intended to be a **fully _bankswitching_ 65C02 SBC**, but pluggable into a backplane, too.


## Non-65xx architectures

### Motorola 6800 & 6809-based

[**KERAton**](https://flic.kr/p/dUEH5s)

  * Specs: 921.6 kHz **MC6800, 128-byte RAM**, up to 32 kiB EPROM,
PIA **CM602** (MC6820 clone), ACIA 2651.

> Made from **ceramic**-cased ICs only.


[**miniAlice**](computers/minialice.md)

  * Specs: 895 kHz **MC6803** _MCU_, **8 KiB** SRAM, **MC6847** video (with _RGB_ output).

> Recreation of Tandy's **TRS-80 _MC-10_**), perhaps switchable to mimic its French clone
**Matra & Hachette _Alice_** (AZERTY keyboard).


[**miniCoCo**](computers/minicoco.md)

  * Specs: 895 kHz **MC6809**, 32-64 KiB **S**RAM, 2x PIA 6821,
**MC6847 video** (with _RGB_ output).

> Recreation of Tandy's **TRS-80 _Color Computer_** (version 1), switchable to
mimic the highly compatible **Dragon 32/64**.


## Peripherals (TBD)

**LED-Keypad**

  * Status: [WORKING!](https://flic.kr/p/dL6Nec)
  * Form-factor: solderless breadboard.
  * Specs: four 7-segment LED displays, 16-key keypad.
  * Interface: old-style _VIAport_ connector.

> Intended as a basic I/O device, current driver allows hex input via a _shift_ key.


**ASCII Keyboard**

  * Status: [in design stage.](https://flic.kr/p/e7C1mS)
  * Form-factor: solderless breadboard.
  * Specs: **64 keys**, two sets of three modifier keys. _May include a 20x4 LCD_.
  * Interface: old-style _VIAport_ connector, thinking about using the new **VIAport2**.

> Conveniently laid out keyboard, the use of an **optional LCD** will make a
_self-contained simple terminal_.


**[PASK (_Port-'A' Simple Keyboard_)](peripheral/pask.md)**

  * Status: in design stage.
  * Specs: **40 keys** including the three usual _modifiers_: `Shift`, `Ctrl` and `Alt`.
  * Interface: single **VIAport2**, supposedly compatible with _Centronics_
printer interface.

> A self-contained keyboard, supported by a **minimal driver**.  Allows input of the
**full 8-bit** ASCII set.


**[Roñavid](peripheral/roñavid.md)**

  * Status: (almost) finished design.
  * Specs: **VGA-compatible** output, typically **640x400/576x448 _bitmap_** or
**320x200/288x224 @ 4bpp** _chunky_).
  * Interface: _VME-like bus_.
  
> _Somewhat cumbersome_ **video card**. No CRTC, just _suitably programmed EPROMs_
generating all needed addresses and signals.


**[mu-VDU](peripheral/mu-vdu.md)**

  * Status: (almost) finished design.
  * Specs: **VGA-compatible** output of **320x200/288x224px bitmap**.
  * Interface: **6502-CPU _socket_**

> Simple, universal **graphic display**. _An extended **planar** version might provide
**8 colours**_.


**[pico-VDU](peripheral/pico-vdu.md)**

  * Status: **working**.
  * Specs: PAL TV output of **128x128/256x256px bitmap**.
  * Interface: **6502-CPU _socket_**, also available as _IOchannel_ and **VIAbus**

> Simple, universal **graphic display**, also integrated in _DURANGO_.
---
_...and many more to come!_

_last modified: 20210312-1428_
