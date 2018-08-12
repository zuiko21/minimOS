# minimOS Character Set

*last modified 2018-08-12*

Currently, it is *loosely* based on **ISO 8859-1**. It does however include the
Euro sign from 8859-15.

On the other hand, as *C1 control codes* were not defined on that standard, those
were filled with the following characters from other architectures:

- 128-143 ($80-$8F) are the **Sinclair ZX Spectrum *semi-graphic*** characters.
- 144-159 ($90-$9F) come from $E0-$EF of **code page 437** (*selected Greek for Maths*)
but with some substitutions for equal or similar characters (vgr. Beta vs *Eszett*).

Up to 190 ($BE) there are some differences from ISO 8859-1. Beyond that, they are jusrt
the same.


