# miniPET

This is an _accurate *recreation*_ of a **Commodore PET 8032**, albeit
with more modern components. Performance was expected to be the same, save for
somewhat _reduced power consumption_ (and noticeably lower component count).
However, the VGA mod (read later) will provide a **57% speed boost** as a bonus.

## Monitor compatibility

Since the original PET range include a CRT monitor, adequate compatibility with
current external monitors must be provided. The internal monitor on the 4000/8000
series worked at an unusual **20 kHz** horizontal rate. For compatibility with
current standards, two options are considered:

1) Tweaking the CRTC registers to achieve **~15.7 kHz** horizontal scan, essentialy
by _extending porchs_.
2) Speed things up for **VGA** compatibility (at **31.5 kHz** scan rate).

The later option adds much more complexity, but seems quite interesting. That would mean:

- **Duplicate scanlines** per char (another CRTC tweak). _This means a different arranging
of CRTC raster address lines_.
- Optionally, redesigning PETSCII font in an **8x16 pixel** fashion, thus waiving
the previous issue.
- Speeding up CPU up to **~1.57 MHz**, in order to match the VGA's _25.175 MHz dot clock_.

In case _analog-TV compatibility_ is needed, first option is to be implemented, at the standard
clock rate, with somewhat compressed characters. _In any case would the regular ROM contents
be compatible with the external monitor_, but tweaking the CRTC's register list is an easy task.

It is known that, when switching between "text" and "graphic"
modes, some extra _blank_ scanlines are configured. This means the CRTC registers are
set upon every mode change. However, after inspecting the
[Basic 4.0 & Kernal source code](http://www.zimmers.net/anonftp/pub/cbm/src/pet/pet_rom4_disassembly.txt),
it seems that all CRTC initialisation is done thru two register tables at `$E72A` and
`$E73C`, so here we are the tables to be patched.

## Static RAM

Gone are the days when **static RAM** was _prohibitively expensive_ -- at least, within such
_moderate_ (32 kiB) amounts of memory on a hobby-made level. The original 32K configuration included:

- 16x _power hungry_ **4116 DRAM** chips, demanding _-5 and +12v lines_ besides the usual +5.
- **Address multiplexers** for the DRAM chips, as usual.
- Several _flip-flops_ and gates for generating the _precisely timed_ **`/CAS` and `/RAS` signals**.
- A **shift register** decomposing the clock cycle into _eight phases_ for the above.
- A **7-bit counter** to generate the _refresh addresses_ to be periodically fed to the DRAM chips.

But back then, all this complexity was worth it, as the cost of a so-called _maximum integration SRAM_
would be rather unaffordable.

A simple **62256 SRAM** chip is all that is needed for the task -- no multiplexed addresses, no refresh,
no weird voltages, no `/CAS-/RAS` hassle... The only care to be taken is to select the SRAM `/CS` taking
into account both A15 (which needs to be _low_ for RAM access) **and** `/R/W`, as RAM writes must be
validated as usual.

### Video RAM

The original design was already using SRAM for this, as the _size_ requirements were much lower (1 K for
the 40-column machines, and twice that for the 80-column ones). This was provided by two (or four)
_2114 SRAM chips_ (1 K * 4-bit). A relatively complex arrangement was needed and, in the 80-column machines,
_even and odd addresses were stored in separate chips_ for **bandwidth** reasons -- 2114s have never been
_speed kings_! In any case, _the CRTC supplied 40 column addressess_, even in the 80-column models. On this, the
hardware multiplexed _latched outputs_ from both VRAM banks, to be supplied to the _character ROM_ on
every `Phi-2` transition.

The most logical implementation nowadays would be the use of a **single 6116 SRAM** (2 K * 8-bit), able
to hold the whole 80-column screen; but needed **bandwidth** will rise, as latches can no longer be fed in
parallel. This calls for a _fastish_ 6116 (~120 nS) which is no big deal today. A different `VIDEO LATCH`
signal generation circuit must be designed, as both latches will be loaded _sequentially_. This might be
as simple as _decoding the 1 & 2 MHz clocks_ to get the **first two quarters** of the cycle, as the 2 MHz clock
will be sent to VRAM's `A0` _during `Phi 2` low state_, allowing timely latch loading during _display access_.

Speaking of multiplexing VRAM addresses, the real machines included a _bank of jumpers_ for a hardwired
selection between 40- and 80-column versions, the latter removing the CPU's `A0` from the addresses
multiplexed with the CRTC lines, as it will be used for switching between _odd and even VRAM banks_. On
the _recreated machine_, though, CPU address lines match those on the VRAM chip; but the CRTC `TA0-TA9`
lines will be shifted in 80-column mode to make room for the 2 MHz clock as LSB.

## ROMs

Present-day integration allows the use of a **single EPROM** (up to 27C256) on this
machine, instead of the battery of 2-4 kiB ROMs originally supplied. This single EPROM
output will be disabled when accessing to the _I/O area_ or the VRAM. On the other hand, I'm
considering the use of a **daughter board** for that, perhaps with two or more sockets,
in order to put my _many_ **27C128s** to good use.

The current design (27C128-based) puts the `/SELx` outputs from the '138 into the inputs of a '20
(one gate for `/SEL9` to `/SEL B`, the other for `/SEL C` to `/SEL F`). This way $8xxx 
addresses do not select any ROM, as they will be used by VRAM. The I/O page accesses
just turn off the `/OE` input on ROMs, as does the `/NO ROM` line thru a NAND,
something easier to do than if half a '139 was used for selecting -- but the NAND itself is
to be replaced by one '139 decoder, though.

## Expansion bus(es)

In order to keep things simple, there is **no IEEE-488** functionality on board, as it
would require a second PIA and associated circuitry. Ditto for the **cassette
interface** which, despite having all _logic_ signals available, lacks _buffered_
motor control. Note that both interfaces are suitable for Commodore hardware _only_,
which I do not own.

The lacking circuits are to be provided on an **expansion board**, fitted thru a
**DIN 41612** connector. This slot will provide _all signals on the original
connectors_, albeit with a few exceptions. For easier _breakout_, the original
pins are grouped following the original connectors as close as possible.

### Expansion connector pinout

- C1-C12 & B1-B12: **User port** (J2, PAx on B row)
- C17-C20: reserved (`/SEL4` to `/SEL7` from J4, _currently **not** implemented_)
- C21-C26: **Cassette port 2** (J6, _non-buffered_ motor control)
- C27-C32: **Cassette port 1** (J3, ditto)
- B15-B23: upper part of **Memory expansion** (J4, data bus)
- B24-B32: lower part of **Memory expansion** (J4, `/SEL8` and further down)
- A9-A32: right side of **Memory expansion** (J9)

Some signals are currently lacking, though: `/PEN STROBE`\*, `/BRW` and the
aforementioned `/SEL` lines, thus will remain _not connected_. On the other hand,
the newly generated `/IOP` signal (access to `$E8` I/O page) is provided for
convenience on pin A32, which was unused anyway.

\*) This signal may be worth implementing, especially if a spare inverter is
available -- or a transistor is used. The remaining ones, on the other hand,
are easily implemented on auxiliary boards should them be needed.

Besides the originally included supply contacts, some extra **power pins** are provided,
even taking some otherwise unused locations.

- C13-C14 & B13-B14: +5 V supply
- C15-C16: ground
- A9 & B15: ground (added to J4 & J9)

### IEEE-488 support

The full IEEE-488 interface is only provided on an auxiliary board; however, some
signals are actually generated on the standard VIA & PIA, thus must be sent to the
second PIA and associated circuitry. _The 8 remaining pins on the DIN connector are
set for this_, although only pins A3-4 are determined as of May 2019. Suggested
pinout is:

- A1: `/DAV IN` _TBD_
- A2: `/NDAC IN` _TBD_
- **A3: `/SRQ IN` (goes also on C3)**
- **A4: `/EOI IN` (goes also on C4)**
- A5: `/NRFD IN` _TBD_
- A6: `/NRFD OUT` _TBD_
- A7: `/EOI OUT` _TBD_
- A8: `/ATN OUT` _TBD_

Note that `/SRQ IN` is **not** generated on the main board, but must be _returned_
from the auxiliary board to be supplied on the **user port**.

## Further circuit simplifying

Some of the original circuitry may be simplified, or even completely deleted. For a start,
instead of _bipolar TTL_ login I'll be using **CMOS logic**, which places little to no load
into the buses and signals -- that means **no buffering** is usually needed. Some other signals
may be generated in a different way, especially when using the _most abundant ICs_ in my stock,
like the **74HC245** (for both buffering and _multiplexing_), **74HC139** (for 1-to-4 decoding
plus some _3-input logic_ functions) and **74HC688** (for up to 8-bit active-low functions).
Of course, as previously mentioned, the use of **static RAM** greatly reduces the component count,
as does the **ROM bank**.

Based on the
[CBM8032 schematics](http://www.zimmers.net/anonftp/pub/cbm/schematics/computers/pet/4000_Series_4016-4032_Technical_Reference.pdf)
(despite the manual stating the **4032** model, _both motherboards are the same
with different jumper configuration_) starting on page 26, these are the most notable changes.

- **Sheet 1:** buffers `UB9-10`, `UD13-14` removed. `UE11` & `UD15` gates removed, the latter may be replaced
by a 74HCT11 for simulating _open-collector_ interrupt lines. **`UE14` replaced by a' 688 looking for `$E8`,
combined with `I/O`**. `UE12` replaced by a '138, as only `/SEL 8` will be actually used.
- **Sheet 2:** _The IEEE-488 interface is optional and comes in an external board_. VIA's `CS1`
is no longer generated (with the new `/IOP` just becomes `A6`, and `CS0` on both PIAs is **1**).
- **Sheet 3:** _Cassette interface on a separate daughterboard_, although the remaining
PIA & VIA stay. The cassette interface might be **integrated** in the IEEE-488 board. _Note simplified
chip selection as stated above_.
- **Sheet 4:** a 74HC20 generates just two 16 kiB ROM selects. Instead of the 7425 _et al_, newly combined
`/IOP` goes to a NAND together with `/NO ROM`, generating the new `/ROM OE` signal.
_A '138 might be used instead of a gate._
- **Sheet 5:** merely becomes the **62256** alone -- as simple as they come :-) `/CS` from `/RAM ON`
(created via `Phi2` NAND inverted `A15`.). _The use of a '138 instead of a NAND saves one inverter_.
- **Sheet 6:** `UE1-3, UE6-7, UD1, UD5` all disappear as SRAM needs no extra signals nor refresh addresses.
`UD4` may become a 74HCT11 (now _active high_) and must use some form of _multiplexing_ for the
40/80-column modes; for instance, a 74**AC**258 switching (and inverting) all signal pairs, including the
output from _both_ 74HCT11 gates. `UD3` may be a 74HCT93, as no more than 4 bits are needed.
- **Sheet 7:** becomes 3x '245 as multiplexers, one of them for the **40/80-column switch**. Will need a couple
of '153s for the most significant bits, plus half a '139 for selection. A _non-switchable_ version will be
much simpler: 2x '245, 1x '157. _MSB (`SA10`) should be muxed via the '153_ in order to _create_ VRAM mirroring
on the 40-column mode.
- **Sheet 8:** '74 Flip-flops replaced by '109s (perhaps one of them could use a '174, or use a _bipolar 74**F**74_). 
2114s replaced by a single **6116**. `UC3` likely to be replaced by a '139. Needs new `/VIDEO LATCH` generation,
separately for both '373s (maybe half a '139 will do). `UB4-7` replaced by a _single_ '245.
- **Sheet 9:** See above. Only the `UB8` latch remains.
- **Sheet 10:** `UD1` becomes an inverter and may substitute `UD2, UE13` by half a '139. In case `/PEN STROBE`
is needed, a transistor (acting as an inverter) is needed.

### List of materials

ref.|type|replaces
----|----|--------
IC1|**65C02**|UB14 CPU
IC2|**74HCT11**|UD15 (simulate open-collector `/RES`, `/IRQ` and `/NMI` lines, connected to expansion slots and buttons)
IC3|**74HC138**|UE12 (some `/SELx` decoding)
IC4|**74HC688**|UE14 (new `/IOP`, _combined_ `I/O` and `x8xx` signal)
IC5|**6522 A**|UB15 VIA
IC6|**68A21**|UB12 PIA (originally a 6520)
IC7|**74HC154**|UC11 (keyboard decoder, may use a _74LS145_ like the original)
IC8a|**74HC139**|UD1,4 (generates `/RAM ON`)
IC8b||UD5 (speaker output)
IC9|**74HC20**|both `/ROM CS` lines
IC10,11|**27C128**|EPROMs
IC12a|**74HC139**|UE14,5 (new `/ROM OE`)
IC12b||new (enable lines for video addresses multiplexer)
IC13|**62256**|UA4-19, UE8-10 (Static RAM!)
IC14|**74HCT93**|UD3 (clock divider)
IC15a|**74HCT11**|UD4 (_active high_ `LOAD SR`, two gates to be muxed for 40/80 modes)
IC15b||UD4 (_active high_ `LOAD SR`, only if _40/80 switchable_)
IC15c||UD4 (video gate, now _active high_ for non-inverted output)
_IC16a,b_|**74 _AC_ 258**|new muxer for `LOAD SR` & `DOT` signals, only if 40/80 switchable
_IC16c,d_||_not used, or could just switch off latch outputs_
IC17a,b|**74 _AC_ 14**|UE4,UD2 fast inverters for clock signals, `CLK1B` no longer generated?
IC17c||UD2 inverter for `/LOAD SR`
IC17d||UD16 Schmitt trigger for `/RESET`
IC17e,f||fast inverters for IC29a outputs
IC18,19|**74HC245**|UC8,9 (VRAM address muxer)
_IC20_|**74HC245**|UC8,9 (VRAM address muxer, _only if switchable_)
IC21|**74HC153**|UC10 (VRAM _MSB_ address muxer, use a **74HC157** _if **non**-switchable_)
_IC22_|**74HC153**|UC10 (VRAM _MSB_ address muxer, _only if switchable_)
IC23,24|**74HC74**|UB1,2 (video signals delay, less pins than '109s)
IC25|**_74F74_**|UC1 (might use a _74HC174_ instead, should speed allows it; ideally a **74AC74**)
IC26|**74HC86**|UC2 (video & H-sync inverter, `/NO ROW` generation)
IC27|**74HC166**|UA2 (video shifter)
IC28|**74HC139**|UC3 (VRAM access decoder)
IC29a|**74HC139**|UD1 (_revamped_ latch enabling; could use different wiring for **40-col**, see IC32)
IC29b||UE8/UD2 chip select for CRTC
IC30|**6116**|UC4/5/6/7 VRAM (single SRAM chip, ~120 ns or faster)
IC31|**74HC573**|UB3 even latch
_IC32_|**74HC573**|UB8 odd latch _(might be **supressed** if full use of '258 on **40-col** mode)_
IC33|**HD6845**|UB13 CRTC
Q1|**BC557**|UD2 in case `/PEN STROBE` is available
Q2|**BC547**|UD1, _V-sync_ inverter (plus diode)
Q3|**BC547**|new, VGA _green_ channel output (plus 390 ohm emitter resistor)

## 7 or 8-bit charset?

The original PET used a _7-bit charset_ (known as PETSCII) whereas the eigth bit was
hardwired to the `INVERT` signal. Thus, any character with bit 7 set will be displayed
in **inverse video**. A similar, global effect will be achieved by setting the CRTC's
`TA12` line on. Also, the `TA13` line selects the alternative `CHR OPTION` when
available -- or just shuts off the character ROM when not. On the other hand, the
`GRAPHIC` signal (generated from VIA's `CA2`) is used as a high address line for the
character ROM, which fits a **2 kiB ROM** (8 scanlines x 128 glyphs x 2 modes)
or, if the `CHR OPTION` is to be used, _twice_ that amount.

But **minimOS** is intended to use a **8-bit charset** for adequate international
support. Thus, **miniPET** has its VRAM's `D7` connected as an address line for the
charset ROM, besides the usual _inverse video_ switch. Because of the mandatory
**original PET _compatibility_**, it will not be able to use **both** the full 8-bit
charset _and_ inverse video on selected chars. _The original PET cannot display 8-bit
chars by any means_, but the `GRAPHIC` signal might be used on the **miniPET** to
switch between two display modes:

1) **7-bit** charset **with** inverse video
1) **full 8-bit** charset _without_ inverse video

The first mode will need the whole glyph set _repeated_, as VRAM's `D7` is used as an
address line. But in the second option, _the "bit-7 high" glyphs should be stored
**inverted**, as these will be reinverted by the display hardware.

All these options may be provided by an **8 kiB** character ROM (16 scanlines x
256 glyphs x 2 modes) but, if the `CHR OPTION` is available, a **27C128** (16 kiB) is
to be used -- no big deal as I own plenty of them.

In any case, the independent `INVERT` signal (from CRTC's `TA12`) may be set via _user_
software with the otherwise unused `INK` and `PAPER` commands -- setting the _ink as
pure black_ (zero) will activate the **global inverse mode**, whereas setting the _paper
as pure black_ will revert to standard mode. _Any other colour setting will be ignored_,
as will be (in 8-bit mode) the `EON` and `EOFF` _emphasis_ control codes. As of
20190624, _no control codes are provided for switching between 7 and 8 bit modes_,
as a suitable utility will be provided for that.

Back to the _global inverse mode_, the XOR gate for this, originally placed at the
very end of the video signal path, should be relocated as will definitely throw off
_black level_ on most (if not all) standard monitors. Thus, the XOR gate must go next
to the other gate taking **bit 7** as inverse video signal. That way, the white "paper"
typical of global inverse will be disabled outside the visible area, keeping black
borders and guaranteeing proper black level setting.

_Last modified: 20190630-1027_
