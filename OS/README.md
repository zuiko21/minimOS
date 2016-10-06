#minimOS·65 *and minimOS·16* ABI
AKA *minimOS*, this is the **original** branch. The originally planed **minimOS·16** port (for the 65C816) is **integrated here**, thus support for *all* variants of the 6502 is guaranteed, while docs will explain appliable differences.

Depending on the targeted processor, code *chunks* (firmware, kernel, drivers, apps...) may be classified as:
* `n`, **NMOS:** only the original, **legal** opcodes are supported. *Some macros are provided in order to emulate the missing CMOS instructions*.
* `b`, **CMOS (*generic*):** usual, preferred deployment, includes basic CMOS upgrades but *not* the Rockwell/WDC extensions (RMB/SMB/BBR/BBS).
* `r`, **CMOS (Rockwell):** allows the use of RMB/SMB/BBR/BBS and maybe WAI/STP. *This is NOT compatible with 65C816 processors, due to their lack of Rockwell extensions (replaced by the new addressing modes)*.
* `v`, **65C816:** besides the proper CPU, requires the use of a suitable '816 firmware and specific kernel API, capable of executing all of the above **except** the Rockwell variant.

Obviously, no 65(C)02 is able to execute '816 code, although the latter is capable of running NMOS and *generic* 65C02 code.

###Function call procedure
The *firmware* has a standardised address (`k_call = $FFC0`) for kernel entry. The usual way to call the API is:
```
LDX #function_number
JSR k_call
```
For convenience, a *macro* for this is defined as `_KERNEL(function_number)`. Functions will return via `RTS` with the **carry bit** *clear* if all was OK. In case of **error**, carry bit is *set* and **Y** register may contain an *error code*. There are the `_EXIT_OK` and `_ERR(error_code)` macros for convenience. 

Since the firmware code at `k_call` is designed around a `JMP (fw_table, X)` instruction (or equivalent NMOS sequence, supplied as a *macro*), `function_number` is expected to be an **even** number, thus up to **128 system calls** are supported.

**65C816 variant** redefines the **same** set of macros: `_KERNEL` is actually implemented as a `CLC: COP $FF` sequence. Suitable '816 firmware would then implement a compatible 8-bit wrapper at $FFC0 around a `COP $FF: RTS` sequence. The '816 API functions would obviously end on `RTI` instead of `RTS`, and since **carry is *precleared* on call**, `_EXIT_OK` becomes a **mere RTI**, while `_ERR` updates the *already saved* carry flag via a (somewhat cumbersome) `PLP: SEC: PHP: RTI` sequence.

Although older versions (up to 0.5, *without* '816 support) used the `_EXIT_OK` and `_ERR` macros everywhere (**all** routines ending in `RTS`), proper compatibility of 8-bit software is only achieved from the use of the proper set of macros; for *driver code* and other generic routines (which are **expected to be in bank zero** anyway) they're replaced by the new `_DR_OK` and `_DR_ERR` which otherwise are the same as the old 8-bit generic macros. **Application** and other executable binary blobs were expected to end in `RTS`; but '816 will use** `RTL` **instead, thus a new `_FINISH` and `_ABORT()` macro set *must* be used instead.

*As of 0.5.1*, 6502-code is only able to run within the lowest 64 KB (bank zero) but **future plans** include a 64-byte *wrapper* at the end of any available bank for '02 *bank-agnostic* code to run.

###Parameter passing and return values
These are done via the **Y** register and/or some *zeropage* locations. There are **12 bytes** for parameters (three 32-bit words) known as:
```
zpar  = zaddr  = $F0
zpar2 = zaddr2 = $F4
zpar3 = zaddr3 = $F8
```
These may work either as *data* (`zpar`) or *addresses* (`zaddr`), thus the naming convention. Since both in each pair point to the *same* address, only **three** 32-bit parameters could be used at a time --- although individual bytes on each parameter might be addressed. The rationale behind this is to ease porting to other architectures (e.g. [680x0](../ports/68/)) using *dedicated* registers for data and pointers.

Together with these, there are another 12 bytes for **local variables**, saved together with the above when *switching context*, thus guaranteeing **reentrancy** *in a different context* on multitasking systems. On the other hand, *recursion* is only explicitally suported by the calling function by pushing into the stack whatever context is to be kept. Due to limited stack space in 65(C)02 architectures, *recursive procedures are discouraged*, though.

Local variables follow a similar naming convention as the aforementioned parameters:
```
local1 = locpt1 = $E4 = locals
local2 = locpt2 = $E8
local3 = locpt3 = $EC
```
where the `localX` labels are used for *data*, and `locptX` for *pointers*. The generic label `locals` gives access to the beginning of this area. Hopefully, **all these addresses $E4-$FB would remain unchanged** in future versions, although at such an early stage (as of 0.5 version) *this cannot be guaranteed*. In case of change, built binaries won't be compatible any longer, and reassembly/recompiling would be necessary, source code unchanged.

###User zeropage space
Full featured systems will have (currently) **241 bytes** *between $03 and $E3* freely available, the first one pointed by the label `uz`. Due to the **software-implemented multitasking** on some 65(C)02 systems, user programmes are **encouraged** (but not *required*) to keep zeropage use from the bottom up, and **setting the system variable `z_used` with the currently used zeropage space**. It is OK (and recommended) to update this value dinamically, since *software-driven* context switching will **only** save `z_used` bytes from `uz` up. On the other hand, systems with *hardware-assisted multitasking* (or any 65C816 implementation) make no use whatsoever of this value, but should not be altered because of compatibility reasons. Leaving `z_used`'s *default* value (currently **$E1** for full featured systems) is **safe** anyway  albeit performance might be impaired whenever software-multitasking is in use.

###Reserved zeropage space
Besides user space and locals/parameters area, there are some bytes usually reserved:

* `$00: sys_in` is the defult input device for the current task. *This is `res6510` on 6510 systems, and obviously **not** available here.*
* `$01: sysout` is the defult output device for the current task.* **Not** available here for 6510 systems.*
* `$02: z_used` is expected to indicate how many zeropage bytes (from `uz`) are actually used, for a faster *software-based* multitasking. *Otherwise (hardware-assisted or NO multitasking at all) is free*.
* `$03: uz`is the first byte of the user's free zeropage space. Tasks start with the currently available bytes set on `z_used`.
* `$E2-$E3` will be the usual location of `sysout` and `sys_in` of 6510 systems, otherwise free for user.
* `$E4` will (hopefully) stay as the beginning of local variables and kernel parameters (from `$F0`).
* `$FC-$FD: sysptr` might be used by **interrupt tasks** anytime. Tinkering with these will do no harm, however values may change unexpectedly *if interrupts are enabled*.
* `$FE: systmp` might be equally used by **interrupts**, which aren't expected to be reentrant anyway.
* `$FF: sys_sp` holds the SP register between context switches. Like the above, if *any* form of multitasking is in use, this **will** change unexpectedly whenever context is switched.

##File description
###`options.h`
Contains definitions for most hardware, especially the **memory map**. This will mainly affect the [firmware](firmware) and [drivers](drivers) since the *kernel* is expected to be as generic as possible! Must reside into the `OS` directory, but may be linked or copied from a suitable template inside the [options](options/) folder.
###`macros.h`
Many useful `#define` declarations, **shorthands** for common code *snippets* (function calls, etc) and NMOS missing opcodes simulations. Currently, the **standard addresses** (`k_call`, ...) are defined here as *labels*, but might be moved into `abi.h`.
###`abi.h`
Formerly `api.h`, defines numeric constants like **function numbers**, error codes, driver table offsets etc. Also the VIA register addresses for convenience, as most 65xx will have at least one (though not required). 
###`zeropage.h`
Defines zeropage use, including the essential `used_zp` and `uz` variables. Also kernel **function parameters** and local variables.
###`sysvars.h`
Global system variables, as used by the kernel. *Will usually go after [firmware variables](firmware/firmware.h)*
###`rom.s`
**This is the main file to be assembled** making reference to all other OS files. Thanks to the current file structure, generating custom ROMs for different machines will be as simple as choosing the appropriate `options.h` file from the [template folder](options/) and assembling `rom.s`.
###`kernel.s`
Surprisingly bereft of *API's functions*, this is a **mostly generic** piece of code. However, the [Interrupt Service Routine](isr/irq.s) is dependant of the kernel, as is the (implicitally related in 6502/65C02) [BRK handler](isr/brk.s).
###`kernel16.s`
*Same as above for the 65C816 processor.*
###`api.s`
Here are the **kernel functions** providing services to the running apps. This will get included from the [kernel](kernel.s) for most systems.
###`api16.s`
*Same as above for the 65C816 processor.* Functions must end in **`RTI`** instead of `RTS`.
###`api_lowram.s`
An alternative for the [above file](api.s) with redesigned functions for **128-byte systems**. Many features are crippled, however.
###`shell.s`
OBSOLETE file to be included from the kernel after all the initialisation is done. *Will be replaced by specific templates on the [shell](shell/)s folder*.
###`drivers.h`
OBSOLETE file with statically allocated variables for drivers. *Replaced by [templates](drivers/config/) as indicated in `options.h`*.
###`drivers.s`
OBSOLETE file with the actual code for drivers. *Replaced by [templates](drivers/config/) as indicated in `options.h`*.

##Folder description
###`drivers`
Code and headers for **drivers**. Also contains a [template folder](drivers/config/) with combinations of `.h` and appropriate `.s` files of drivers to be inculuded on any particular configuration.
###`firmware`
Machine-dependent code, including POST. Also **highly modular**, makes reference to several files on the [modules](firmware/modules/) folder. *Will also contain a [machines](firmware/machines/) folder with templates for particular architectures*.
###`isr`
The **Interrupt Service Routines**, namely `irq.s`, `brk.s` and `nmi.s`, usually *kernel-dependent*. Notice that there is a [default NMI handler](firmware/modules/std_nmi.s) supplied by the *firmware*, in case the (dynamically) installed one gets corrupted.
###`options`
Templates for the `options.h` file to be copied or linked at the `OS` directory as appropriate.
