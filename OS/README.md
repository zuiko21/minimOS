#minimOS·65 ABI
AKA *minimOS*, this is the **original** branch. While the forthcoming **minimOS·16** (for the 65C816) will remain inter-operative with this one, support for *all* variants of the 6502 is guaranteed here.

Depending on the targeted processor, code *chunks* (firmware, kernel, drivers, apps...) may be classified as:
* **NMOS:** only the original, **legal** opcodes are supported. *Some macros are provided in order to emulate the missing CMOS instructions*.
* **CMOS (*generic*):** usual, preferred deployment, includes basic CMOS upgrades but *not* the Rockwell/WDC extensions (RMB/SMB/BBR/BBS).
* **CMOS (Rockwell):** allows the use of RMB/SMB/BBR/BBS and maybe WAI/STP. *This is NOT compatible with 65C816 processors, due to their lack of Rockwell extensions (replaced by the new addressing modes)*.

Obviously, no 65(C)02 is able to execute '816 code, although the latter is capable of running NMOS and *generic* 65C02 code.

###Function call procedure
The *firmware* has a standardised address (`k_call = $FFC0`) for kernel entry. The usual way to call the API is:
```
LDX #function_number
JSR k_call
```
For convenience, a *macro* for this is defined as `_KERNEL(function_number)`. Functions will return via `RTS` with the **carry bit** *clear* if all was OK. In case of **error**, carry bit is *set* and **Y** register may contain an *error code*. 

Since the firmware code at `k_call` is designed around a `JMP (fw_table, X)` instruction (or equivalent NMOS sequence, supplied as a *macro*), `function_number` is expected to be an **even** number, thus up to **128 system calls** are supported.

**Parameter passing and return values** are done via the **Y** register and/or some *zeropage* locations. There are **12 bytes** for parameters (three 32-bit words) known as:
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
Full featured systems will have (currently) **241 bytes** *between $03 and $E3* freely available, the first one pointed by the label `uz`. Due to the **software-implemented multitasking** on some 65(C)02 systems, user programmes are **encouraged** (but not *required*) to keep zeropage use from the bottom up, and **setting the system variable `z_used` with the currently used zeropage space**. It is OK (and recommended) to update this value dinamically, since *software-driven* context switching will **only** save `z_used` bytes from `uz` up. On the other hand, systems with *hardware-assisted multitasking* (or any 65C816 implementation) make no use whatsoever of this value, but should not be used because of compatibility reasons. Leaving `z_used`'s *default* value (currently **$E1** for full featured systems) is **safe** anyway  albeit performance might be impaired whenever software-multitasking is in use.

###Reserved zeropage space
Besides user space and locals/parameters area, there are some bytes usually reserved:

* `$00-$01: reserved` for compatibility with 6510 systems. *These will be free ONLY if the CPU is NOT a 6510 AND no software-multitasking is in use*.
* `$03: z_used` is expected to indicate how many zeropage bytes (from `uz`) are actually used, for a faster *software-based* multitasking. *Otherwise (hardware-assisted or NO multitasking) is free*.
* `$FC-$FD: sysptr` might be used by **interrupt tasks** anytime, which aren't expected to be reentrant anyway.
* `$FE: systmp` might be equally used by **interrupts**. Tinkering with these will do no harm, however values may change unexpectedly *if interrupts are enabled*.
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
###`api.s`
Here are the **kernel functions** providing services to the running apps. This will get included from the [kernel](kernel.s) for most systems.
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
