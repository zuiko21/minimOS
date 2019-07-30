# Hardware for minimOS

## Supported architectures

With great embarrassment I have to admit never having owned a 65xx computer...
but suport for these classic machines shouldn't be difficult to add -- for
instance, I have declared as 'reserved' the two first zero-page bytes in case
the utterly popular Commodore-64 (using a 6510) is targeted.

Back to my **own-designed** machines, here's the current history & roadmap:

### Computers


**MTE _("Medidor de Tiempos de Exposición", Exposure Time Meter)_**

Status: finishing design.

Form-factor: soldered PCB.

Specs: 1 MHz 6503 (28 pin, 4 kiB addressing space), 128-byte RAM,
3 kiB-EPROM (addressed range from a 2732), VIA 6522

Intefaces: four (very large) 7-segment LED digits, light sensor, a couple of keys...




[**SDd _("Sistema de Desarrollo didáctico", Learning Development 
System)_**](https://flic.kr/s/aHsjCMszTY)

Status: [WORKING!](https://twitter.com/zuiko21/status/936654607014653952?s=19)

Form-factor: solderless breadboard.

Specs: 1 MHz 65SC02, 2 kiB RAM, 2-4 kIB (E)EPROM, VIA 65C22.

Interfaces: Amplified piezo buzzer between PB7-CB2,
currently with a VIA-attached 4-digit **LED-keypad**.




[**CHIHUAHUA**](https://flic.kr/s/aHsjEn5ntM)

Status: Finished and _sort-of_ working, but with some strange bug with VIA,
not solved yet. _Likely to be discarded_.

Form-factor: Soldered, compact version of SDd. Perfboard with point-to-point soldering.

Interfaces: Piezo buzzer between PB7-CB2, SS-22 and old _VIAport_ connectors.




[**CHIHUAHA PLUS**](https://flic.kr/s/aHsjEGuCH3)

Status: under construction (recently redesigned).

Form-factor: Perfboard with point-to-point soldering.

Specs: 1 MHz (socketed) 65C02, 16 kiB RAM, 32 kiB EPROM, VIA 65C22.
_Might be configured for 32 kiB RAM + 16 kiB EPROM if desired_.

Interfaces: Amplified piezo buzzer between PB7-CB2, SS-22 and old _VIAport_ connectors.




[**SDx _("Sistema de Desarrollo eXpandible", Expansible Develpment 
System)_**](https://flic.kr/s/aHsjDAwJBR)

Status: aborted during construction :-(

Form-factor: Perfboard with point-to-point soldering.

Specs: 1.25 / 2 MHz 65C02/102, 8-16 kIB RAM, 32 kiB EPROM, VIA 65C22, ACIA 65SC51,
RTC 146818.

Interfaces: Amplified piezo buzzer between PB7-CB2, Hitachi LCD, TTL-level RS-232,
SS-22 and old _VIAport_ connectors. Several diagnostic LEDs.




**Baja**

Status: never started :-(

Specs: intended to be a _fully bankswitching*_65C02 **SBC**,
but pluggable into a backplane, too.




[**Jalapa (formerly _SDm_)**](jalapa2.md)

Status: almost finished design, heavily _revamped_ as of Oct-2018.

Form-factor: Perfboard with point-to-point soldering.

Specs: 1.8432 / 2.304 MHz **65C816**, 128 kiB RAM (or 512K),
up to 32 kiB _Kernel_ EPROM plus up to 512 kiB _library_ EPROM,
VIA 65C22, ACIA 65SC51.

Intefaces: Amplified piezo buzzer between PB7-CB2, SS-22, new _VIAport**2**_
(_SBC-2_ style but with "mirrored" power pins), TTL-level RS-232,
_VME-like_ slot (65816 direct expansion)




[**Acapulco**](acapulco.md)

Status: almost finished design.

Form-factor: Perfboard with point-to-point soldering.

Specs: 1.536 MHz 65C02, 32 kiB SRAM (plus 1 kiB in parallel as _attribute area_, 
32 kiB EPROM, VIA 65C22, CRTC HD6445. _Intended to be a colour & graphics capable SBC._

Interfaces: Piezo buzzer, SS-22, new VIA connector, VGA-compatible video output
(~320x200 @ 16 colours in GRgB mode, only 2 of them each 8x8 pixels)




[**miniPET**](minipet.md)

Status: **essentially finished** design.

Form-factor: Perfboard with point-to-point soldering.

Specs: 1.57 MHz 65(C)02, 32 kiB SRAM (plus 2 kiB _VRAM_, 
up to 32 kiB EPROM, VIA 65(C)22, PIA 6521/6821,
CRTC HD6845, with _optional second PIA_.

_This is a recreation of the `Commodore PET 8032` **switchable between 40 and 80 columns**_,
with updated components (e.g. SRAM) and **VGA-compatible** output.

Interfaces: **same as the original PET**; cassette and
IEEE-488 on separate _optional_ boards.




**Tijuana**

Status: finishing design.

Form-factor: Single layer PCB?

Specs: 6.144 MHz 65C816, 16 kiB SRAM (plus 16 more for _ROM-in-RAM_), 3x32 kiB VRAM,
16 kiB EPROM, VIA 65C22, CRTC HD6845, ACIA 6551A.
_Intended to be a colour & graphics capable VT-52 based terminal._

Interfaces: Piezo buzzer, TTL-level async., SS-22, parallel input,
VGA-compatible video output (~576x448 @ 1 bpp, 3-bit RGB or 3-bit greyscale),
_VME-like_ slot (65816 direct expansion) 




**Veracruz**

Status: in design stage _(might be merged with **Jalapa**)_

Form-factor: thru-hole PCB?

Specs: 4 MHz (at least) 65816, 512 kiB RAM, 32 kiB _Kernel_ EPROM, 512 kiB _lib_ EPROM,
2 x VIA 65C22, UART 16C550, RTC MC146818.

Interfaces: Piezo buzzer, new VIA and SS-22 connectors, TTL-level async,
**65SIB**, Hitachi LCD thru VIA, **PS/2**, _VME-like_ slot (65816 direct expansion)




**Jalisco** _(might be merged with **SIXtation**)_

Status: in design stage

Form-factor: 4-layer PCB, SMD components.

Specs: 12 MHz (I hope!) 65816, up to **8 MiB RAM** (2 x Garth's modules),
32 kiB Kernel + 2 MiB _lib_ EPROM, 2 x VIA 65C22, (2x) UART 16C552, _ROM-in-RAM_.

Interfaces: most likely those of Veracruz, possibly plus SD-card,
text console (or graphic) output...




**SIXtation**

Status: in _early_ design stage

Form-factor: 4-layer PCB, SMD components.

Specs: **9 MHz 65816**, _overclocked_ (?) **_36 MHz_ 68882 FPU**,
up to **8 MiB RAM** (2x Garth's modules), 32 kiB Kernel + 4 MiB *lib* EPROM,
2x VIA 65C22, (2x) 16C552 UART, MC146818 RTC, _ROM-in-RAM_.

Video output: 6445-based, _planar_ 1 MiB VRAM, up to **8 bpp**, typically **1360x768**.

Other interfaces: most likely those of _Jalisco_, adding CF & SD-card. Will _definitely_
include PS/2 keyboard/mouse ports.


### Peripherals (TBD)

**LED-Keypad**




**ASCII Keyboard**




**[PASK (_Port A Simple Keyboard_)](pask.md)**




**Roñavid**




**mu-VDU**

Simple, _CPU-socket installed_ **graphic display** (VGA-compatible) with
**288x224 bitmap**. _An extended **planar** version might provide **8 colours**_.


_...more to come!_

_last modified: 20190730-1606_
