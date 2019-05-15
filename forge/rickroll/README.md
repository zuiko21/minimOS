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

Thus, the ISR for _audio stream_ (stored in a 64 kiB **27C256**) will just **pulse
`PB0`** (thru the usual `INC`-`DEC` sequence) to increment the audio counter and
_enable_ the audio ROM output, to keep interrupt overhead as low as possible.

For _video_ (stored in a 256 kiB **29EE020**) two approaches have been considered:

1) Keep the full address counter on the board, being pulsed by `PB1`
1) Take the lowest 6 bits from `PB1-PB6` (`PB7` expected _low_ at all times), while
`PB6` is used to pulse an in-board counter for the remaining bits.

But after writing stubs of code, the first option in no better than the second one,
and needs more hardware anyway, so we will provide the lowest video bits on PB.

In short, the **auxiliary board** will use the following components:

- One **27C512 EPROM** with the _audio_ samples
- One **29EE020 EEPROM** with the _video_ data
- Two **74HCT393** for the 16-bit _audio counter_
- One **74HCT4040** for the upper 12 bits of _video addresses_
- One **74HCT139** which selects audio or video ROM thru `PB0`, disabling
both if `PB7` is high.

And that's it! Both ROM's data busses are connected to `PA`, while their addresses
lines are connected to the respective counters (the lowest video bits to `PB`, as is
the selecting '139).

## Media format

Obviously, the format to be stored has to deal with two _normally antagonistic_ features:

- Low bandwidth
- Easy of processing

**Audio and Video quality** had to suffer as a consequence. To keep things reasonable,
the following parameters are chosen:

- Video resolution: **36x28 pixels** (matching the _attribute area_ blocks)
- Video depth: **4 bit fixed GRgB palette**, with _dithering_.
- Video framerate: **30 fps** (for reasonably smooth motion)
- Audio sampling: **8 kHz**, 9-level **PWM** patterns (8-bit, slightly better than
_3-bit PCM_)

### Audio playback

This is the most demanding part, as _jitter_ requirements claim for really _tight timing_.
While a precisely timed loop is frequently used on simple audio playback, interleaving that
with video playback would be really difficult and inefficient; thus, **interrupt-driven
audio playback** is implemented. The ISR is as slim as possible, combining clock drive with
audio ROM selection (see above) but at a mere 1.536 MHz, still creates a considerable
**24% overhead**. _All dithering and encoding is pre-recorded on the EPROM_, to make
playback as simple as putting the value on the VIA's serial register.

### Video playback

The VRAM acting as a buffer makes timing lest strict; however, this part takes about
**80% bandwith** and thus must be executed as fast as possible, especially taking into
account the noticeable _audio interrupt overhead_. For easier addressing, _the whole
1024 byte attribute area is transferred_ for each frame, even if some part of it is
not visible.

The currently used algorithm takes about _21 ms_ to transfer a frame which, having into
account the _audio overhead_, will reach nearly **28 ms**, which is _just_ right for 30fps
playback. But the VGA screen with be refreshed _twice_ during this time, thus some
refreshing artifacts are to be expected in the lower half of the picture.

Note that to keep video and audio synced, the code relies on a **6345/6445 CRTC** as
normally specced for the _Acapulco_ computer, since it provides a way to detect the
_vertical sync pulse_. In case a regular _6845_ is used, some extra hardware should make
the code able to detect the `VSYNC` pulse for proper synchronisation, and the software
conveniently adapted. Alternatively, an estimation of frame execution time (plus expected
audio interrupts) may be computed for a suitable _delay loop_, but it may require some
tweaking in order to achieve proper sync.

## Signal pre-processing

### Audio

As prevuiously stated, for optimum performance audio samples are stored in a _ready-to-use_
format. With an 8-bit PWM pattern, up to **9 levels** are available. Besides the extremes,
several patterns are feasible for each level, which may be ransomised for a somewhat
impoved listening experience.

_Dithering_ is the key here, because of the limited bit depth. Larger orginal samples should
be randomly approximated to the closest levels (alternating randomly selected patterns for
each one) so some **noise** is heard instead of a much annoying _quantisation distortion_.

### Video

Both resolution and bit depth are severily limited here. Plus, processing time is _just right_
for the aimed fps. Thus, all downscaling, quantising and dithering is previously done. The device
will just copy **1024-byte chunks** into the _attribute area_, then wait for the next `VSYNC` in
oreder to load the next frame. _The VGA standard having a **60 Hz** refresh rate, two `VSYNC`s
are expected during each frame_; but the first one will happen half-way in the 28 ms transfer,
thus the expected artifacts. In case a non-standard crystall is used, _it is worth tweaking the
`VSYNC` rate in order to be **as close as possible to the nominal 60 Hz**_ for perfect
audio/video sync.

About the **colour depth**, the _Acapulco_ harware is capable of _16 colours_ from its fixed
[GRgB palette](../../other/grgb_palette.png); but a simple form of **dithering** may be used,
giving a total of **63 different colours** with no performance penalty. The idea is to _fill
the screen with a **checkered** pattern_, allowing the mix of `INK` and `PAPER` colours. _If
both colours (nibbles) are set the same, a **solid, non-dithered colour** will show up_, as the
pattern will remain invisible. But if both nibbles differ, the mix of both colours will generate
an acceptable average on screen, at least for such reduced resolution. Not
[all the 256 possible combinations](dithered.html)
are feasible, as many of them will produce _the same effect on screen_ (if seen from
a distance, that is), thus the aforementioned 63-colour _effective_ figure.

## Circuit description

### Component list

Qty|reference|purpose
---|---------|-------
1  |27C512   |Audio EPROM
1  |29EE020  |Video EEPROM (could use a **27C2001** EPROM as well)
2  |74HCT393 |16-bit Audio counter
1  |74HCT4040|12-bit Video counter
1  |74HCT139 |chip selection
_1_|_74HC245_|_**optional:** keyboard input buffer_

### Theory of operation

The now standard [VIAbus port](../../hard/buses/viaport.md) takes both port A & B from
the VIA, although no control lines will be used. The signals are connected as follows:

- `PA` lines are connected to both ROM's data pins.
- `PB0` goes to the first **74HCT393** clock input, and also to one of the **74HCT139**'s
decoder `A`input (it is permanently _enabled_).
- `PB7` is connected to _all counters' `RESET`_ input, as well as the previous '139 decoder
`B` input.
- `PB1...PB6` go respectively to the _Video ROM's_ `A0...A5`. On the other hand, `A6...A17`
are connected to the **4040**'s outputs.
- The **74HCT393**s outputs go to `A0...A15` on the _Audio ROM_. Of course, every clock input
(minus the first one) is connected to `Q3` on the previous counter.
- The aforementioned **74HCT139** `/Y0` output goes to the _Video ROM_ `/CS` input. Also, its
`/Y1` output is connected to the _Audio ROM_ `/CS` input.
- `/OE` is **grounded** in both memories.

In case the _optional **PASK** (Port A Simple Keyboard)_ is connected, some cautions must be
taken in order to avoid **bus contention**. Thus:

- The `PA` extension for the keyboard is connected to the data bus thru the **74HC245** (connect
its `DIR` input as convenient).
- The remaining decoder on the **74HCT139** (permanently enabled, too) takes `PB7` on its `B`
input (just like the other), while its `A` input may be tied to **ground**.
- The decoder `/Y2` output goes to `/OE` on the '245.
- `CA1` from PASK goes directly to `CA1` on the **VIAport** interface.

This way, typing during video playback will be read by software as a random keypress (after playback)
but will never cause _bus contention_ neither disturb playback in any way.

In case this part is not deemed necessary, the unused decoder inputs must _not_ be left floating.

_Last modified 20190515-1041_
