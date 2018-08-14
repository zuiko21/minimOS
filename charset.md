# minimOS Character Set

*last modified 2018-08-14*

Focused on limited resource platforms, the standard **character set** for minimOS
had to satisfy the following:

- Single-byte sequences (for easier/faster parsing).
- Reasonably adhesion to actual standards for convenient compatibility.
- Support for Spanish characters... plus some other personal interests of mine.

Currently, it is *loosely* based on **ISO 8859-1**. It does however include the
Euro sign from 8859-15.

On the other hand, as *C1 control codes* were not defined on that standard, those
were filled with the following characters from other architectures:

- 128-143 ($80-$8F) are the **Sinclair ZX Spectrum *semi-graphic*** characters.
- 144-159 ($90-$9F) come from $E0-$EF of **code page 437** (*selected Greek for Maths*)
but with some substitutions for equal or similar characters (vgr. Beta vs *Eszett*).

Up to 190 ($BE) there are some differences from ISO 8859-1. Beyond that, they are jurt
the same. For inatance, the diacritical marks alone were judged kind of nonsense, thus
replaced by some other missing chars (four of them were taken from CP 437 $F0-$FF).

Another consideration was trying to match the text-LCD modules charset as much as
possible.


