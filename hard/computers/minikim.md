# miniKIM

A recreation of the venerable [KIM-1 computer](https://en.m.wikipedia.org/wiki/KIM-1),
although with some modifications in order to use components from my stock.

Being a very simple 6502 computer, there are several keypoints that ask for
modification: the use of a couple of **6532 RRIOTs** (1K _ROM_, 64B RAM, I/O & Timer),
the **6-digit LED display** and the limited **1 kiB RAM**, plus the intended use of
Don Lancaster's **_cheap_ video display adapter**, which required some modifications
on the original KIM-1.

### Limitations

The KIM-1 was originally supplied with a couple of 6530 RRIOTs, one for the system,
one for the Application bus. While theoretically is possible to run a KIM without
this last RRIOT, its ROM contains the **tape routines**, thus becomes necessary even
if the Application bus isn't used. But after replacing the RRIOTs (either with
**6532 RIOTs** or even with **6522 VIAs**) the ROM is external anyway, and there is
_plenty_ of it, so this second _periheral bus set_ becomes optional.

**Casette** and **current loop** interfaces are somewhat obsolete nowadays, even
for a retro-enthusiast... plus, the cassette interface requires 12 V supply, so it
makes sense to keep that circuit in a _separate, optional board_.

## Component substitution

### 6530 RRIOT

Back in the day, these chips allowed building a cheap _two-chip computer_, just by
adding the CPU. But these ROM inside them means they must be **mask-programmed** at
the factory, thus must have the appropriate _suffix_ for the intended task; `6530-002`
(system) and `6530-003` (application) we the ones used by the original KIM, the latter
including some code for the **tape interface**. This means they are next to impossible
to find and, honestly, I think we must keep this scarce resource for the restoration of
existing KIM-1s.

On the other hand, MOS Technology introduced the alternative **653_2_ RIOT**. Compared
to the 6530, this one **has no ROM** (thus completely _generic_) and doubles the built-in
RAM (up to **128 bytes**). _The pin-out is completely different_ but software-wise is
fully compatible with the 6530. Of course, the lacking ROM must be provided externally
with some decoding logic, but this is no big deal anyway.

6532s can be sourced without too much trouble and reasonably priced but, being NMOS
devices, I'm not very keen on them, as I already got a few NMOS 6502 and 6522 (and
EPROMs) which I'd like to use anyway. The **6522 VIA** seems an adequate (if a bit
_overkill_) substitute for the 6532, having into account the following issues:

- `Port A` and `Port B` on the 6530/6532 are simple, without the `CAx/CBx` control
lines on the VIA. Software must be modified for proper configuration _at startup_, and
the port addresses are different anyway. **Swapping `RS0` and `RS1`** at least puts
the _Data Registers_ and _Data **Direction** Registers_ in the same order of a 6530.
_Note that `PA` and `PB` are swapped_ unless `RS0` is inverted. **In any case, the
VIA's registers get shuffled**, so the corresponding firmware must be designed
accordingly.   
- The **interval timer** on the 6532 can be sort-of-emulated with the VIA's
_single-shot T1_, although with quite different programming: the VIA can be set between
**1 and 65535 _T_** delay, while the 6530 uses an 8-bit register (thus up to 255 counts)
but with a choice of division factors (1, 8, 64 & 1024), allowing intervals up to
**261120 _T_**, although with much reduced precision. Anyway, the only use of it found
on KIM's software is in the _tape routines_, and no further than the 64:1 factor, thus
well within the capabilites of the VIA. The _PIA 6820/6520 seems unsuitable_ because of
this.
- The missing **RAM** is no problem as we now have plenty of them. Since the I/O addresses
will have to be fixed in software anyway, at least there is RAM enough for the
Application and system areas from the RRIOTs at `$1780-$17FF`.

_Last modified: 20200103-2213_
