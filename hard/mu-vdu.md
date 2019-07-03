# mu-VDU

Minimal **288x224 bitmap _VGA-compatible_** VDU, to be installed into a 6502 socket.
Includes 8 kiB of _write-only_ VRAM (CPU must keep a copy into its own RAM for reads).

## Addressing

The VRAM address range is selectable:

1) `$0000-$1FFF` (**not** recommended as will include _zeropage & stack_)
1) `$2000-$3FFF`
1) `$4000-$5FFF`
1) `$6000-$7FFF` (preferred)

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

- `A15` to `/G`
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
`DEN` signal is to be used (with pulldown for `A1`).

But, as previously stated, it pays to **disable _read_ operations**. The simplest (and
fastest!) way is using a 74HC32 quad-OR gate as follows:

- `A15` + **`R/W`**, output goes to `/G` on VRAM select (instead of `A15` alone)
- `/SEL` + `DEN`, output creates _valid_ `/SEL` (in case of RDY generation)
- `/SEL` + `/DEN` (use an inverter), output is `RDY`

Just like the original design, a pulled-down jumper on `DEN` (before the inverter!)
allows _quick-and-dirty_ operation if desired.

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

**register load** (1/2 74HC21):

- takes `Q1`, `Q2` and (possibly inverted) `Q3` from the above
- gate output goes to `SH/LD` input of shift register

**CRTC** (6845):

- `MA0-MA9` go to VRAM address lines **thru 1 K resistors**
- `RA1-RA3` go to VRAM `A10-A12`, respectively (note offset)
- CPU interface (`Dx, RS, E`) as usual, `/CS` as previously described
- sync outputs and `CUR` go to the output stage
- `DEN` goes to blanking gate
- `CLK` as described, from clock divider

**VRAM** (6264):

- address lines as described
- data lines go to shift register, in parallel with the data buffer
- `/CS` kept low (and `CS` high), permanently enabled
- `/WE` is the `/SEL` signal
- `/OE` can be the _inverted_ select (or just kept low)

**shift register** (74HC165):

- parallel inputs to VRAM data lines
- `CLK` from clock divider `Q0`
- `Qh` (or `/Qh`) to output stage
- `SH/LD` from register load gate

**output stage** (1/2 74HC21):

- only two inputs used, `Qh` from shift register and `DEN` from CRTC
- might take `/Qh` in case an **inverse video** output is desired
- gate output fed with a suitable emitter-follower transistor to VGA **green** line
- `CUR` similarly buffered to VGA **red** line
- inverters should be used for `HS` and `VS` outputs (direct to VGA)

Some _capacitors_ might be needed in order to introduce suitable **delays**.

_last modified 20190703-0944_
