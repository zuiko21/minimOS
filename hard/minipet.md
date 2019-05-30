# miniPET

This is an _accurate *recreation*_ of a **Commodore PET 8032**, albeit
with more modern components. Performance is expected to be the same, save for
somewhat _reduced power consumption_ (and noticeably lower component count).

## Monitor compatibility

Since the original PET range include a CRT monitor, adequate compatibility with
current external monitors must be provided. The internal monitor on the 4000/8000
series worked at an unusual **20 kHz** horizontal rate. For compatibility with
current standards, two options are considered:

1) Tweaking the CRTC registers to achieve **~15.7 kHz** horizontal scan, essentialy
by _enlarging porchs_.
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

One doubt remains, however: it is said that, when switching between "text" and "graphic"
modes, some extra _blank_ scanlines are configured. This means the CRTC registers are
tweaked upon mode change, which will definitely throw VGA compatibility. Original
code must be patched in order to disable this "feature". However, after inspecting the
[Basic 4.0 & Kernal source code](http://www.zimmers.net/anonftp/pub/cbm/src/pet/pet_rom4_disassembly.txt),
it seems that all CRTC initialisation is done thru two register tables at `$E72A` and
`$E73C`, so here we are the tables to be patched.

## Static RAM

Gone are the days when **static RAM** was _prohibitively expensive_ -- at least, within such
_moderate_ (32 kiB) amounts of memory on a hobby-made level. The original 32K configuration included:

- 16x _power hungry_ **4116 DRAM** chips, including _-5 and +12v lines_.
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
the 40-column versions, and twice that for the 80-column machines). This was provided by two (or four)
_2114 SRAM chips_ (1 K * 4-bit). A relatively complex arrangement was needed and, in the 80-column machines,
_even and odd addresses were stored in separate chips_ for **bandwidth** reasons -- 2114s have never been
_speed kings_! In any case, _the CRTC supplied 40 columns_, even in the 80-column models. On these, the
hardware multiplexed _latched outputs_ from both VRAM banks, to be supplied to the _character ROM_ on
every `Phi-2` transition.

The most logical implementation nowadays would be the use of a **single 6116 SRAM** (2 K * 8-bit), able
to hold the whole 80-column screen; but needed **bandwidth** will rise, as latches can no longer be fed in
parallel. This calls for a _fastish_ 6116 (~120 nS) which is no big deal today. A different `VIDEO LATCH`
signal generation circuit must be designed, as both latches will be loaded _sequentially_. This might be
as simple as _decoding the 1 & 2 MHz clocks_ to get the **two first fourths** of the cycle, as the 2 MHz clock
will be sent to VRAM's `A0` _during `Phi 2` low state_, allowing timely latch loading during _display access_.

Speaking of multiplexing VRAM addresses, the real machines included a _bank of jumpers_ for a hardwired
selection between 40- and 80-column versions, the latter removing the CPU's `A0` from the addresses
multiplexed with the CRTC lines, as it will be used for switching between _odd and even VRAM banks_. On
the _recreated machine_, though, CPU address lines match those on the VRAM chip; but the CRTC `TA0-TA9`
lines will be shifted in 80-column mode to make room for the 2 MHz clock as LSB.

## ROMs

Present-day integration allows the use of a **single EPROM** (up to 27C256) on this
machine, instead of the battery of 2-4 kiB ROMs originally supplied. This single EPROM
will be disabled when accessing to the _I/O area_ or the VRAM. On the other hand, I'm
considering the use of a **daughter board** for that, perhaps with two or more sockets,
in order to put my _many_ **27C128s** to good use.

## Further circuit simplifying

Some of the original circuitry may be simplified, or even completely deleted. For a start,
instead of _bipolar TTL_ login I'll be using **CMOS logic**, which places little to no load
into the buses and signals -- that means **no buffering** is usually needed. Some other signals
may be generated in a different way, especially when using the _most abundant ICs_ in my stock,
like the **74HC245** (for both buffering and _multiplexing_), **74HC139** (for 1-to-4 decoding
plus some _3-input logic_ functions) and **74HC688** (for up to 8-bit active-low functions).
Of course, as previously mentioned, the use of **static RAM** greatly reduces the component count,
as does the **ROM bank**.

Based on the [CBM8032 schematics](http://www.zimmers.net/anonftp/pub/cbm/schematics/computers/pet/4000_Series_4016-4032_Technical_Reference.pdf)
(despite the manual stating the **4032** model, _both motherboards are the same
with different jumper configuration_) starting on page 26, these are the most notable changes.

- **Sheet 1:** buffers `UB9-10`, `UD13-14` removed. `UE11` & `UD15` gates removed, the latter may be replaced
by a 74HCT11 for simulating _open-collector_ interrupt lines. **`UE14` replaced by a' 688 looking for `$E8`,
combined with `I/O`**. `UE12` replaced by a '138, as only `/SEL 8` will be actually used.
- **Sheet 2:** _The IEEE-488 interface is optional and comes in an external board_. VIA's `CS1`
is no longer generated (with the new `I/O` just becomes `A6`, and `CS0` on both PIAs is **1**).
- **Sheet 3:** _Cassette interface on a separate daughterboard_, although the remaining
PIA & VIA stay. The cassette interface might be **integrated** in the IEEE-488 board. _Note simplified
selection as stated above_.
- **Sheet 4:** a 74HC20 generates just two 16kiB ROM selects. The combined `I/O` instead of
the 7425 _et al_ goes to a NAND together with `/NO ROM`, generating the new `/ROM OE` signal.
- **Sheet 5:** merely becomes the **62256** alone -- as simple as they come :-) `/CS` from `/RAM ON`
(created via a `Phi2` NAND inverted `A15`).
- **Sheet 6:** `UE1-3, UE6-7, UD1, UD5` all disappear as SRAM needs no extra signals nor refresh addresses.
`UD4` may become a 74HCT11 (now _active high_) and must use some form of _multiplexing_ for the
40/80-column modes (74**ACT**244). `UD3` may be a 74HCT93, as no more than 4 bits are needed.
- **Sheet 7:** becomes 3x '245 as multiplexers, one for the **40/80-column switch**. Will need a couple of '153
for the remaining bits (total 11). A _non-switchable_ version will be much simpler: 2x '245, 1x '157.
_MSB (`SA10`) should be muxed via the '153_ in order to avoid VRAM mirroring on the 40-column mode.
- **Sheet 8:** '74 Flip-flops replaced by '109s (perhaps one of them could use a '174, or use a _bipolar 74**F**74_). 
2114s replaced by a single **6116**. `UC3` likely to be replaced by a '139. Needs new `/VIDEO LATCH` generation,
separately for both '373s (maybe half a '139 will do). `UB4-7` replaced by a _single_ '245.
- **Sheet 9:** See above. Only the `UB8` latch remains.
- **Sheet 10:** `UD1` becomes an inverter and may substitute `UD2, UE13` by half a '139.

### List of materials

org. sheet|Qty.|type|replaces
----------|----|----|--------
1|1|**CPU 65C02**|UB14
1|1|**74HC138**|UE12 (some `/SELx` decoding)
1|1|**74HC688**|UE14 (_combined_ `I/O` and `x8xx` signal)
1|1|**74HCT11**|UD15 (simulate open-collector for `/RES`, `/IRQ` and `/NMI`,
connected to external slots and built-in switches)
3|1|**VIA 6522**|UB15
3|1|**PIA 68B21**|UB12 (6520)
3|1\*|NAND gate|UD5 (speaker output)
3|1|**74HC154**|UC11 (may use a _74LS145_ like the original)
4|1|**74HC20**|both `/ROM CS` lines
4|1\*|NAND gate|UE14/5 (new `/ROM OE`)
5|1|**SRAM 62256**|all memory!
6|1|**74HCT93**|UD3 (clock divider)
6|1|**74HCT11**|UD4 (_active high_ `LOAD SR`, two gates to be muxed for 40/80 modes)
6|1|**74ACT244**|- (muxer for the above signal, _if 40/80 switchable_)
6|3\*|fast inverter|UE4/UD2
6|1\*|NAND gate|UD1/4 (generates `/RAM ON`)
6|1\*|inverter|UE11 from sheet 1 (puts `/A15` on the above gate)
7|3|**74HC245**|UC8,9 (VRAM address muxer, just _two_ if not switchable)
7|2|**74HC153**|UC10 (VRAM MSB address muxer, just **one 74HC157** if not switchable)
8|2|**74HC109**|UB1,2
8|1|**_74F74_**|UC1 (might use a **74HC174** instead, if speed allows it)
8|1|**74HC86**|UC2 (shared with CRTC section)
8|1|**74HC166**|UA2
8|1\*|3-input _AND_|UD4 (remaining 74HC11 gate from _UD4@sh.6_)
8|1|**74HC139**|UC3 (VRAM access decoder)

_Last modified: 20190530-1049_
