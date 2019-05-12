# Rickrolling on a 6502

We are, perhaps, facing the most difficult execution of this well-known prank:
playing [Rick Astley's famous video clip](https://youtu.be/dQw4w9WgXcQ) on a
sultry **6502** device!

## Hardware choice

Video playing is understandably well beyond the capabilities of a 6502, or any
other 8-bit CPU. The use of _specifically-designed auxiliary hardware_ is, thus,
essential. Some reasonable _display capabilities_ are desired, too. The choice
of the [Acapulco computer](../../hard/acapulco.md) makes sense as it is able to display
up to 16 colours (which may be enhanced with some trickery, read later). Plus, it
makes use of an _attribute area_ which allows for a **much reduced bandwidth** --
at the cost of _reduced resolution_, of course. The standard audio configuration
allows the _VIA's shift register_ to act like a **PWM** output, allowing a 9-level
output, which is **a bit better than 3-bit PCM**, acceptable for the intended purpose.

### Auxiliary board

The sole purpose of this board is to feed the considerable amount of data on a **simple,
most efficient way**. Since Acapulco has no proper expansion slot, _VIAport2_ is the
only way to do that. As the transmission is expected to be **sequential**, _most of the
addressing is done on the board_ itself, freeing the CPU as much as possible.

Both streams (audio & video) are handled differently, as their requiremens vary
widely:

- **Audio** data must be feed at _extremely regular intervals_, as the stored values
are POKEd directly into the VIA's shift register. Reading procedure will be
_interrupt-driven_.
- **Video** data, on the other hand, takes most of the bandwidth but is nowhere as
demanding on timing accuracy, since the scanned VRAM acts as an effective buffer.

Thus, the ISR for _audio stream_ (stored in a **27C256**) will just **pulse `PB0`**
(thru the usual `INC`-`DEC` sequence) to increase the audio counter and enable the
audio ROM output, to keep interrupt overhead as low as possible.

For _video_ (stored in a **27EE020**) two approaches have been considered:

1) Keep the full address counter on the board, being pulsed by `PB1`
1) Take the lowest 6 bits from `PB1-PB6` (`PB7` expected _low_ at all times), while
`PB6` is used to pulse an in-board counter for the remaining bits.

_Last modified 20190512-1230_
