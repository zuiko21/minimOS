# mu-VDU

Minimal **288x224 bitmap _VGA-compatible_** VDU, to be installed into **any 6502 socket**.
Includes 8 kiB of _write-only_ VRAM (CPU must keep a copy into its own RAM for reads).

If the recommended standard oscillator is used, other resolutions between 320x200 and
256x240 are possible.

## Addressing

The VRAM address range is selectable:

1) `$0000-$1FFF` (**not** recommended as will include _zeropage & stack_)
1) `$2000-$3FFF` (preferred for 16K systems)
1) `$4000-$5FFF`
1) `$6000-$7FFF` (preferred for 32K systems)

The last two bytes of the selected block (`$1FFE-$1FFF`, `$3FFE-3FFF$`, `$5FFE-$5FFF` or
`$7FFE-$7FFF`) are reserved for the **CRTC registers**. As most of them are **write-only**
anyway, _no reads are allowed_, just like with VRAM. _The circuit does **not** make any
use of the `R/W` line_, thus any read attempt will actually _write_ into VRAM (or CRTC
registers) **the same value** as read from the computer's regular RAM. 

While this issue does not prevent proper operation, it however makes unneeded VRAM
accesses -- which will increase _snow_ generation or, in case of using the _optional RDY
generator_, impair CPU performance because of the extra wait states (see below). Thus,
it seems worth disabling the circuit during reads, something easily achived with some
OR gates.

## Circuit description

**VRAM select** (1/2 74HC139):

- `A15` to `/G` (or could use `R/W` instead, see below)
- `A13-A14` to inputs
- `/SEL` output comes from one of its `/Yn` outputs (`/Y0` **not** recommended)

The second '139 decoder may be used as an _inverter_ for the select signal **or** as an
RDY-generating device in order to avoid _snow_ during CPU accesses:

Original **RDY generation** (1/2 74HC139, _optional_):

- previous `/SEL` to `A0` input
- `DEN` from CRTC to `A1` input
- `RDY` output from `/Y2`
- valid `/SEL` from `/Y0`

In case _quick and dirty_ operation is desired, a jumper disconnecting the received
`DEN` signal is to be used (with pulldown for `A1` input). **Note that RDY generation is
_useless_ on NMOS 6502 systems!**

But, as previously stated, it pays to **disable _read_ operations**. One simple (and
fast!) way is using a 74HC32 quad-OR gate as follows:

- `A15` + **`R/W`**, output goes to `/G` on VRAM select '139 (instead of `A15` alone)
- `/SEL` + `DEN`, output creates _valid_ `/SEL` (in case of RDY generation)
- `/SEL` + `/DEN` (use an inverter), output is `RDY`

A fourth gate may be used for _qualifying writes_, as recommended.

Just like the original design, a pulled-down jumper on `DEN` (before the inverter!)
allows _quick-and-dirty_ operation if desired.

Alrernatively, if _arbitration_ (id est, the _RDY generation_ circuit) is not needed,
the **read-disable** feature may be implemented by using a 74HC13**8** instead of a
'139, applying `R/W` to the extra address input. _This will save the 74HC32_ and one
of the inverters.

_**Preferred option:**_

Then, another option arises, implementing both **read disable** and **RDY generation**
features thru the use of a _single 74HC139_. It will be wired as initially, but using
`R/W` instead `A15` for gating. _This will mirror acceses on the top 32 kiB_ but, since
this is usually ROM and reads are anyway disabled, no ill effects are expected.

**CRTC select** (74HC133):

- one input is the _inverted_ VRAM select (needs an inverter)
- `A1-A12` as required-high inputs
- output goes to CRTC `/CS`

**address multiplexers** (2x 74HC245):

- `A` inputs go to CPU address lines
- `B` outputs go to VRAM address lines (`A13-A15` not used)
- `DIR` is kept high (_A to B_ transfer)
- `/OE` comes from `/SEL`

**data buffer** (74HC245):

- same as above, but for _data_ lines instead

**clock divider** (74HC93):

- `/CP0` from the 25.175 MHz oscillator (24.576 MHz may be used with some tweaking)
- `Q0` to `/CP1`, as usual
- `Q3` (possibly inverted, see below) to CRTC `CLK`

**register load** (1/2 74HC21 _or_ 1/3 74HC11):

- takes `Q1`, `Q2` and (possibly inverted) `Q3` from the above
- gate output goes to `SH/LD` input of shift register

**CRTC** (6845):

- `MA0-MA9` go to VRAM address lines **thru 1 K resistors**
- `RA1-RA3` go to VRAM `A10-A12`, respectively, again with **resistors** (note offset)
- CPU interface (`Dx, RS, E`) as usual, `/CS` as previously described
- sync outputs and `CUR` go to the output stage
- `DEN` goes to blanking gate (and optionally to RDY generator)
- `CLK` as described, from clock divider

This _Amstrad-like_ layout is the same as the one used on the
[Acapulco computer](acapulco.md) but, since this board maps the CRTC I/O _into_
VRAM address range, **no _hardware scrolling_** will be available. Thus, a **C64-like**
layout might be preferred, as that will simplify the software somewhat -- at least for
text rendering. In this case, address lines are mapped as follows, the remaining
connections being the same:

- `RA1-RA3` to VRAM `A0-A2` (note offset)
- `MA0-MA9` to VRAM `A3-A12`

Always **thru 1 K resistors**.
 
**VRAM** (6264):

- address lines as described
- data lines go to shift register, in parallel with the data buffer
- `/CS` kept low (and `CS` high), permanently enabled
- `/WE` is the `/SEL` signal\*
- `/OE` can be the _inverted_ select (or just kept low)

\*) Note that writes **should be qualified** thru _Phi2_ as usual, for reliable operation.
In such case, a **74HC11** may be used (together with a few inverters) instead of the
74HC21 used in several places, as no more than a three-input NAND is needed.

**shift register** (74HC165):

- parallel inputs to VRAM data lines (or data buffer output)
- `CLK` from clock divider `Q0` (perhaps inverted)
- `Qh` (or `/Qh`) to output stage
- `SH/LD` from register load gate

**output stage** (1/2 74HC21 or 1/3 74HC11):

- only two inputs used, `Qh` from shift register and `DEN` from CRTC
- might take `/Qh` in case an **inverse video** output is desired
- gate output fed with a suitable emitter-follower transistor to VGA **green** line
- `CUR` similarly buffered to VGA **red** line
- inverters should be used for `HS` and `VS` outputs (direct to VGA)

Some _capacitors_ might be needed in order to introduce suitable **delays**. However,
it seems that (most) Hitachi 6845 clones include a **skew** option, suitably delaying
both `DEN` and `CUR` signals.

### Component layout

One of the design goals was fitting this into a **7 x 9 cm perfboard**. This is the reason
behind some "ugly" decisions. Plus, the use of the most abundant components in my stock is
preferred.

Since this circuit is **_universally_ fitted in parallel with the CPU**, another problem
arises: _probing_ sockets seem almost impossible to find, thus _the original CPU must be
**removed** from the original board, to be fitted into the VDU itself_. This takes
valuable _real estate_ from the VDU board.

The only way to achieve this is by putting some ICs _under_ some other big ones. The
current layout puts the 74HC245 _data buffer_ under the CRTC, the 74HC165 _shift register_
under the VRAM, and both the 74HC139 and 74HC133 for _chip selection_ under the removed CPU!

_last modified 20190721-1436_
