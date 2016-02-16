#minimOS·65 ABI
AKA *minimOS*, this is the **original** branch. While the forthcoming **minimOS·16** (for the 65C816) will remain inter-operative with this one, support for *all* variants of the 6502 is guaranteed by this one.

Depending on the targeted processor, code chunks (firmware, kernel, drivers, apps...) may be classified as:
* **NMOS:** only the original, **legal** opcodes are supported. *Some macros are provided in order to emulate the missing CMOS instructions*.
* **CMOS (*generic*):** usual, preferred deployment, includes basic CMOS upgrades but *not* the Rockwell/WDC extensions (RMB/SMB/BBR/BBS).
* **CMOS (Rockwell):** allows the use of RMB/SMB/BBR/BBS and maybe WAI/STP. *This is **not** compatible with 65C816 processors, due to their lack of Rockwell extensions (replaced by the new addressing modes).

Obviously, no 65(C)02 is able to execute '816 code, although the latter is capable of running NMOS and *generic* 65C02 code.

###Function call procedure
The *firmware* has a standardised address (`k_call = $FFC0`) for kernel entry. The usual way to call the API is:
```
LDX #function_number
JSR k_call
```
and will return via `RTS` with the **carry bit** *clear* if all was OK. In case of **error**, carry bit is *set* and **Y** register may contain an *error code*.

Since the firmware code at `k_call` is designed around a `JMP (fw_table, X)` instruction (or equivalent NMOS sequence, supplied as a *macro*), `function_number` is expected to be an **even** number, thus up to **128 system calls** are supported.

**Parameter passing and return values** are done via the **Y** register and/or some *zeropage* locations. There are **12 bytes** for parameters (three chunks of 32-bit words) known as:
```
zpar  = zaddr  = $F0
zpar2 = zaddr2 = $E8
zpar3 = zaddr3 = $E4
```
