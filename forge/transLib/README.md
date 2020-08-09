# transLib

## Code Translation services for _minimOS_

This is a generalisation of the previous emulators for [MC6800](../apps/6800emu/6800emu.s)
and [i8085](../apps/80emu/8085emu.s),
which were no more than _non-executable_ chunks of code.

The **Translation Library** is split around three components:

- **transFly:** direct foreign code execution (like a classic emulator)
- **transGen:** _compiler_ for the above, generating a **native** executable from a foreign one
- **transExt:** the _cross-compiler_ version, takes _native_ code and turns it into a **foreign executable**

Due to computing power and memory requirements, this is intended for the **16-bit** 65816 port only.
 
_Last modified: 2020-08-09, 19:08_
