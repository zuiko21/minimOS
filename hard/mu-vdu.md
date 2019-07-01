# mu-VDU

Minimal **288x224 bitmap _VGA-compatible_** VDU, to be installed into a 6502 socket.
Includes 8 kiB of _write-only_ VRAM (CPU must keep a copy into its own RAM for reads).

## Addressing

The VRAM address range is selectable:

1) `$0000-$1FEF` (**not** recommended as will include _zeropage & stack_)
1) `$2000-$3FEF`
1) `$4000-$5FEF`
1) `$6000-$7FEF` (preferred)

The last two bytes of selected block are reserved for the **CRTC registers**. As most
of them are **write-only**, _no reads are allowed_, just like VRAM.

## Circuit description

74HC139 (VRAM select):

- A15 to /E
- A13-14 to inputs
- main VRAM select comes from one of its /Y outputs (/Y0 not recommended)
- the second decoder may be used as an _inverter_ for the select signal

74HC133 (CRTC select):

- one input is the _inverted_ VRAM select
- A12-A1 as required-high inputs
- output goes to CRTC /CS

2x 74HC245 (address multiplexers):

- inputs (A) go to CPU address lines
- outputs (B) go to VRAM address lines (A13-A15 not used)
- DIR is kept high (A to B transfer)
- /OE comes from VRAM select

74HC245 (data buffer):

- same as above, but for data lines instead

74HC93 (clock divider):

CRTC 6845:

- MA0-MA9 go to VRAM address lines **thru 1 K resistors**
- RA1-RA3 go to VRAM A10-A12, respectively
- CPU interface (Dx, RS, E) as usual, /CS as previously described
- sync outputs and CUR go to the output stage
- DE goes to blanking gate
- CLK as described

VRAM 6264:

- address lines as described
- data lines go to the shift register, in parallel with the data buffer
- /CS kept low (and CS high)
- /WE is the VRAM SELECT signal
- /OE can be the _inverted_ select (or kept low)

_last modified 20190701-2350_
