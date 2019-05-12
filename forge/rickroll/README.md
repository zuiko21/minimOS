# Rickrolling on a 6502

We are, perhaps, facing the most difficult execution of this well-known prank:
playing [Rick Astley's famous video clip](https://youtu.be/dQw4w9WgXcQ) on a
sultry **6502** device!

## Hardware choice

Video playing is understandably well beyond the capabilities of a 6502, or any
other 8-bit CPU. The use of _specifically-designed auxiliary hardware_ is, thus,
essential. Some reasonable _display capabilities_ are desired, too. The choice
of the [Acapulco computer](../hard/acapulco.md) makes sense as it is able to display
up to 16 colours (which may be enhanced with some trickery, read later). Plus, it
makes use of an _attribute area_ which allows for a **much reduced bandwidth** --
at the cost of _reduced resolution_, of course. The standard audio configuration
allows the _VIA's shift register_ to act like a **PWM** output, allowing a 9-level
output, which is **a bit better than 3-bit PCM**, acceptable for the intended purpose.

### Auxiliary board

27C256
29EE020

_Last modified 20190512-1201_
