# minimOS architecture

*Last update: 2018-12-06*

## Rationale

**minimOS** (or *mOS* for short) is intended as a **development platform** for computers 
with *modest resources*. Its main goals are **modularity** (you choose whatever set of 
features you need) and **portability**: originally targeted to computers based on 
[**6502** CPU](https://en.wikipedia.org/wiki/MOS_Technology_6502) 
and derivatives, either commercial or home-made by retrocomputing enthusiasts, might 
be equally ported for almost any CPU out there including, but not limited to, Motorola 
[**6800**](https://en.wikipedia.org/wiki/Motorola_6800), 
[**6809**](https://en.wikipedia.org/wiki/Motorola_6809) & 
[**680x0**](https://en.wikipedia.org/wiki/Motorola_68000_series), 
Intel [**8080**](https://en.wikipedia.org/wiki/Intel_8080) /
[**8085**](https://en.wikipedia.org/wiki/Intel_8085) /
[Zilog **Z80**](https://en.wikipedia.org/wiki/Zilog_Z80) 
and the popular [**x86**](https://en.wikipedia.org/wiki/X86), 
plus the ubiquitous [**ARM**](https://en.wikipedia.org/wiki/ARM_architecture).

These goals will define most of its design features.

## Aesthetic

The *corporative* typeface is **Neuzeit Grotesk DIN 30640**.

# Background

## Inspiration from CP/M

The *portability* goal takes some inspiration from the once popular 
[**CP/M**](https://en.wikipedia.org/wiki/CP/M),
the then *de facto* standard OS for microcomputers. While the original target (65xx) is 
contemporary with those systems, present-day computing expectations lead to several 
differences.

Perhaps this achieved goal was the key to CP/M's success. This OS had three main components:

- **BIOS** (Basic I/O system, *hardware dependent*)
- **BDOS** (Basic Disk OS)
- **CCP** (Console Command Processor)

Unlike the [**BIOS**](https://en.wikipedia.org/wiki/BIOS), 
which was provided *customised* by the computer's maker, 
all the remaining components were **generic**, as supplied by 
[Digital Research](https://en.wikipedia.org/wiki/Digital_Research)
(which also supplied a BIOS *template* intended for the
[Intel MDS-800](http://www.computinghistory.org.uk/det/21821/Intel-Intellec-MDS-800-Development-System/) development system). 
Of course, other commands or the *application software* were run atop of this,
most likely *replacing the CCP* temporarily for increased available RAM, as this 
was a **single task**, single user OS. As soon as the task was completed,
the *shell* (CCP) was reloaded and the user was prompted for another command.

Alas, this scheme is not complete: usually, these components were provided
on some kind of mass-storage media (often
[*diskettes*](https://en.wikipedia.org/wiki/Floppy_disk)) 
that had to be *loaded* into RAM, as no CPU has any means to execute code *directly* from 
[**secondary memory**](https://en.wikipedia.org/wiki/Auxiliary_memory).
Thus, a small piece of **ROM** or any other *non-volatile 
[**primary** memory](https://en.wikipedia.org/wiki/Computer_memory)* 
was needed in order to load and run the Operating System. This was often a 
[**bootloader**](https://en.wikipedia.org/wiki/Bootstrapping#Computing) 
(generically known as 
[**firmware**](https://en.wikipedia.org/wiki/Firmware)) 
whose main purpose, besides the initial setup and perhaps some hardware tests 
([*POST, Power-On Self-Test*](https://en.wikipedia.org/wiki/Power-on_self-test))
was merely copying those three files in RAM and ordering the CPU to jump at their code.
Obviously, this firmware was part of the computer's hardware, and had nothing to do
with CP/M itself, save for being designed to boot from such system files. 

Apart from such firmware design, having an **Intel 8080** CPU or compatible (the only one 
initially supported by CP/M) and at least **16 KiB RAM** *starting at address $0* (plus some 
kind of **disk drive** for the DOS to work on) were the only requisites to any computer 
maker to have a **CP/M compatible** machine. With its notable software base, CP/M was *the* 
choice for many computer makers, at least in the office environment.

> A quick *hardware* note: since the i8080 CPU starts executing code *from address 0*, 
> some **non-volatile** ROM is expected to be accesible at that address.
> But CP/M *needs* RAM there, thus some means to *switch off* ROM access from
> the bottom of the address map (once the firmware has done its chore, of course)
> has to be provided to achieve CP/M compatibility... unless you want to *manually*
> program the initial RAM bytes via toggle-switches! Anyway, 
> such a simple [*bank-switching*](https://en.wikipedia.org/wiki/Bank_switching) 
> feature was easily implemented, as demonstrated by CP/M's sheer popularity.

Back in the day, the **I/O** capabilites of computers were rather limited: assume
a *keyboard*, an *output device* (could be a text CRT screen, but a
[*teletype*](https://en.wikipedia.org/wiki/Teleprinter) 
would do) and/or a *printer*, plus some *mass-storage* devices, 
and you were set. Thus, the concept of modular 
[device **drivers**](https://en.wikipedia.org/wiki/Device_driver) 
as separate pieces of software was not relevant, and adapting your system to different 
peripherals meant the aforementioned **BIOS customisation** -- it wasn't *that* hard, anyway.

After the hayday of CP/M came the *x86-based* 
[**IBM PC**](https://en.wikipedia.org/wiki/IBM_Personal_Computer) 
running [**MS-DOS**](https://en.wikipedia.org/wiki/MS-DOS), 
itself pretty much inspired by CP/M, although the BIOS was somehow integrated into the firmware,
at least in an OS-independent fashion. For compatibility reasons, a 
[**jump table**](https://en.wikipedia.org/wiki/Branch_table) 
was provided for easily calling BIOS routines, no matter their actual 
locations in ROM; for additional performance, some software *skipped* this jump table, 
leading to a 
[plethora of incompatibilities](https://en.wikipedia.org/wiki/Influence_of_the_IBM_PC_on_the_personal_computer_market) 
whenever a *different from IBM's (copyrighted) BIOS* was used, but this soon ceased 
to be a problem, thanks to the development of highly compatible BIOSes thru 
[*clean room* design](https://en.wikipedia.org/wiki/Clean_room_design) techiniques, 
running on highly standardised PC *clones* of widespread use. ***The rest is history...***

## The home-computer market

On the other hand, the late seventies witnessed the birth of an unexpected computer 
market: the [*home computer*](https://en.wikipedia.org/wiki/Home_computer) 
which, despite the performance impairment, made computing affordable for the masses.

But bereft of the portability/standardisation features of CP/M (and later MS-DOS) machines, 
these were **closed, incompatible systems**, each platform gathering its base of loyal 
users. Despite this diversity, many systems became quite popular indeed: in USA, the 
[**TRS-80**](https://en.wikipedia.org/wiki/TRS-80),
the [**Commodore PET**](https://en.wikipedia.org/wiki/Commodore_PET), 
the [**Atari 400/800**](https://en.wikipedia.org/wiki/Atari_8-bit_family), 
and the [**Apple \]\[**](https://en.wikipedia.org/wiki/Apple_II); 
at the other side of the pond, the 
[**ZX Spectrum**](https://en.wikipedia.org/wiki/ZX_Spectrum),
the *powerful* [**BBC Micro**](https://en.wikipedia.org/wiki/BBC_Micro) 
(especially in UK schools) and, a bit later, the 
[**Amstrad CPC**](https://en.wikipedia.org/wiki/Amstrad_CPC)... plus the 
[**Commodore 64**](https://en.wikipedia.org/wiki/Commodore_64) 
(and its predecessor [**VIC-20**](https://en.wikipedia.org/wiki/Commodore_VIC-20)
) **anywhere** in the world, to mention the most relevant.

Despite their alleged technological advantage, the *Japanese* were off from this 
fierce price war but anyway they tried to make an *standardised* platform for it: the ill-fated 
[**MSX**](https://en.wikipedia.org/wiki/MSX) 
systems had some popularity in Japan, but much less in Europe and almost *zero* in America.

Substituting home cassette players for (then expensive) disk drives, these systems had 
a relatively ample ROM with not only the essential firmware and *kernel/BIOS* (sort-of), 
but usually featured a 
[**BASIC language interpreter**](https://en.wikipedia.org/wiki/BASIC), 
thus after booting (in just *a couple of seconds!*) one could simply 
**start typing programs**. *Many of us were taught Computer Programming (leading to 
formal education in Computer Science) this way...*

A pretty odd exception to this rule (in the UK) was the 
[**Jupiter ACE**](https://en.wikipedia.org/wiki/Jupiter_Ace), 
somewhat related to 
[*Sinclair*](https://en.wikipedia.org/wiki/Sinclair_Research) 
computers, but meant to be programmed... in 
[**Forth**](https://en.wikipedia.org/wiki/Forth_(programming_language)). 
This rather limited (1 KiB RAM + 2 KiB *VRAM*) machine 
played little role into the troubled waters of home computers, but made a point on the 
**extreme efficiency** of the little known Forth language.

Eventually, these home computers evolved into 16 or even 32-bit processors, like the 
[Apple IIgs](https://en.wikipedia.org/wiki/Apple_IIGS), 
[Atari ST](https://en.wikipedia.org/wiki/Atari_ST) &
[Commodore Amiga](https://en.wikipedia.org/wiki/Amiga),
although they were somewhat less popular as regular x86 PCs became less and less expensive.

# Generic *minimOS* architecture

## Overview

At first glance, **minimOS** architecture might look similar to that of CP/M,
but there are significant differences. Have a look at this graph:

![minimOS architecture](mOS-arch.jpeg)

Apparently, the **firmware** looks like the generic term for CP/M's *BIOS* -- together with
the device **drivers**, which were implemented via *customisation*.

On the other hand, the **Kernel/API** seems certainly related to the *BDOS*, as is
hardware-independent and providing the only interface *application software* is supposed
to use... This component is probably the 
**closest one to CP/M's design**, in both form and function.

Unlike CP/M's *BIOS*, though, minimOS' firmware (as of 2018-05-29) has
**no I/O capabilities**, being restricted to **Kernel instalation/configuration** chores,
plus providing a **standard interface to some hardware-dependent features** (say,
*power management*). As this OS is intended to run on a **wide spectrum of machines**,
from a simple embedded system to a *quasi-full-featured* desktop computer,
**there is no guarantee of I/O device availability** at such low level.
You can think of this as a ***Hardware Abstraction Layer***

However, in case of a *Kernel and/or driver failure*, it would be nice to have 
an *emergency* I/O channel available for **debugging purposes**, provided the hardware 
allows it. For instance, a *Commodore 64* **has** a 40x25 text screen starting at $0400 
which could be easily used by debuggers, after a simple VIC-II initialisation. It does
have, of course, a **keyboard** for human input, too. Even if a 
particular computer lacks such convenient devices, a **suitable driver** provided by its 
*custom* kernel could "announce" its availability to the firmware, for its simple 
firmware I/O to work thru it. These won't be as reliable as the built-in devices in 
heavily crashed environments, but it's better than nothing. *The concept of separate 
**firmware drivers** has been considered*, but deemed too complicated. Actual 
implementation might just use a regular driver in firmware space, with its *unused*
header and I/O routines that will be directly called. *As long as the header address is
provided into the configuration list at `drvrs_ad`, it might be used by the regular
kernel too*.

## Firmware

The *firmware* term is actually a **misnomer** here, as most *minimOS* kernel
will usually reside together in some kind of (E)EPROM. As previously mentioned,
calling it BIOS would be inappropriate too, as no I/O is provided. On the other hand,
the firmware calling macro is `_ADMIN` from *Administrative Kernel*.

This is intended as the **device-dependent** part of minimOS (the kernel being
*device-independent*). Formerly consisted of several files, each one serving a
particular machine; however, the chore of copying every improvement on *each*
file was alleviated via a **fully-*modular* approach**: the `template` file (or any
particular machine's firmware, for that matter) will consist in just **a bunch of
`#include`s** for *small* code chunks on the `modules` folder. Different machines
may then use a different chunk for a particular feature, or just suppress it.

Please note that some of these chunks may be as short as two or three lines on code!
However, this make sense as ther might be implementation changes for some simple
operations, like e. g. the *jiffy counter* size.

A similar **modular**
approach has been used for **firmware variables**, *statically* assigned before kernel's
*sysvars*. After including the regular `template.h`, a particular machine may add
any other variables as needed. On the other hand, including these extra variables *before*
the template may facilitate computing the **first address of `sysvars`** in case of a
*dynamically linked* (loadable) kernel.

In any case, it is worth transferring the initial address of kernel variables,
allowing a *dynamic kernel* to **relocate itself (!)**. Since the kernel will
start with interrupts off, it is safe to store it into the `sysptr` zeropage
variable. As long as no variables are used before calling the relocation function,
all will be OK. This feature can be switched on and off via the `DYNKERN` option.

### The *Administrative Kernel*

This is the **firmware's API**, originally intended to be used by the Kernel only --
although a standard interface is provided for standard apps, even if it's not really
needed for the 65(C)02 version.

#### Kernel installing and patching

Main available functions are for `INSTALL`ing the Kernel's *jump table*, and setting the
IRQ, BRK and NMI routines -- usually will be called by the Kernel at startup time.
The mechanism for **kernel patching** is also supplied, and from 0.6 version on
it does provide a *recovery setting* -- just a NULL pointer as the supplied jump table
(for `INSTALL`) or routine address (for individual function `PATCH`). The firmware
will take care of a pointer to the last installed *kernel **jump table*** for this matter.

*(must clarify this)*

On the other hand, passing a NULL pointer to any interrupt-setting function will simply
return the original pointer, no matter that the standard interface for
*patching* kernel functions will also return the *previous* address, thus
allowing both **head and tail patching**, like this:

**Install routine** (6502 version)
```
    LDA #>patch           ; pointer to new code
    LDX #<patch
    STX kerntab           ; store parameter word
    STA kerntab+1
    LDY #function_id      ; kernel function to be patched
    _ADMIN(PATCH)         ; install my routine
    LDX kerntab           ; get old pointer
    LDA kerntab+1
    STX my_pointer        ; store it at a known address
    STA my_pointer+1
```

(65816 version)
```
    LDA #patch            ; pointer to new code
    STA kerntab           ; set as parameter
    LDY #function_id      ; kernel function to be patched
    _ADMIN(PATCH)         ; install my routine
    LDA kerntab           ; get old pointer
    STA my_pointer        ; store it in a known address
```

**Head and/or tail patch code** (6502 version)
```
patch:
; *** here comes the HEAD patching code ***
    JSR old_call          ; *** only for tail-patching code ***
; *** here comes the TAIL patching code ***
    _EXIT_OK              ; proper API exit *** only for tail-patching code ***
old_call:
    JMP (my_pointer)      ; call original routine (will return to tail-patch or caller) 
    
```

(65816 version)
```
patch:
; *** here comes the HEAD patching code ***
; *** the following code ONLY in case of tail-patching ***
    PHK                   ; will return to this bank *** tail-patching only ***
    PEA patch_code        ; proper return address for RTI *** tail-patching only ***
    PHP                   ; as requested by RTI *** tail-patching only ***
; *** the above code ONLY in case of tail-patching ***
    JMP (my_pointer)      ; call original routine (will return to tail-patch or caller) 
patch_code:
; *** here comes the TAIL patching code ***
    _EXIT_OK              ; proper API exit *** tail code only ***
```

The above code, apparently, does **not** allow *mixed* interrupt code -- i. e.,
patching a 16-bit kernel with 8-bit code. Maybe it's worth implementing a *filter*
for the `U_ADM` entry point.

Please note that, unlike the *generic* Kernel, this *administrative Kernel* is **not
patchable**. The firmware will keep a table in RAM for the kernel's vectors, sized as 
defined by `API_SIZE`. Also, the final 0.6 release API expects kernels to
*specify their **number of functions** upon calling `INSTALL`* (in bytes; 0 means a 
full 256-byte page is needed). This way, the firmware may check whether the kernel to
be installed fits its own data structures and report an error code otherwise; the
**generic** kernel being installed *will not need to now about those structures*.

## Device Drivers (0.6 version)

As an essential feature of such device-agnostic OS, minimOS **driver architecture** has 
been carefully crafted for **versatility**. The details may vary depending on the CPU 
in use, but in any case they'll bear a **header** (does not need to be *page-aligned*)
containing this package of information:

- A device **ID** (currently 128-255, as *logical* devices use up to 127)
- A **feature mask** indicating the availability of some of the following
- Pointers to **initialisation** and **shutdown** routines (mandatory)
- Pointers to ***block* Input** and **Output** routines (when available)
- Pointer to a **configuration** routine (when available)
- Pointer to a **status report** routine (when available)
- Pointer to an **Asynchronous Interrupt Handler** (called *by request*, if enabled)
- Pointer to a **Periodic Interrupt Handler** (called every "n" *jiffy* interrupts, if enabled)
- **Frequency** value for the *periodic* task described above (the *n* value for the above)
- Pointer to a **description *C-string*** in human-readable form
- Number (word) of ***dynamically allocated* bytes**, if loadable *on-the-fly*
- *Offset* (or *pointer*) to data relocation table (only if the above is **not zero**)

A last-minute change in 0.6 is the **block-oriented I/O**. This was foreseen on older
versions, but drivers were *character-oriented*. This also leaves room for separate
**configuration** and **status report** features, previously integrated within block I/O.
Note that, for compatibility reasons, *the Kernel still provides legacy **character**-
oriented I/O*, as mere interfaces setting a fixed single-byte *block size* prior to
calling the generic block routines.

Note that, while driver format for kernels *up to 0.5.1* (totally **incompatible**
with those for 0.6 and beyond) *might* provide some compatibility for **8-bit
drivers *on 16-bit kernels***, this is no longer the case. However, making them
16-bit-savvy should be pretty straightforward, as should be adapting older
*character-oriented* drivers with a suitable loop.

At boot time, the *initialisation* routine of each registered driver is **unconditionally** 
called -- if not needed, must point to an existing `ReTurn from Subroutine` instruction. 
Upon exit, this routine must return an **error flag** indicating whether the driver was 
succesfully initialised or not (e.g. device not present), the latter condition making it 
**unavailable** for further I/O operation. Similarly, at shutdown/reboot every *shutdown* 
routine will be called, although any error condition makes no sense, thus no error code
is required or evaluated anyway.

### Interrupt queues

Of special interest are the **interrupt routines**. The (now unified) **periodic** queue
handles those tasks at *multiples* of the **jiffy** IRQ period; while **4 ms** is
the *recommended* value, the actual timing **cannot be guaranteed**. Plus,
the ocassional *interrupt masking* when entering
[critical sections](https://en.wikipedia.org/wiki/Critical_section) may cause further
delays. This mechanism is particularly suited to replace the
[**daemons**](https://en.wikipedia.org/wiki/Daemon_(computing)) 
commonly seen on UNIX-like systems, perhaps with better responsiveness (quite an asset on 
low-spec machines) or even with no form of **multitasking** (which is, in any 
case, another *driver*) available! On the other hand, for those cases of obviously 
**infrequent** tasks (disk auto-mount, long-lasting timers), a suitably larger *frequency* 
parameter is to be used.

Older versions (before 0.6) had the **periodic tasks** separated into *jiffy* and *slow* 
interrupt tasks, with no *frequency* parameter whatsoever, being complete responsability of 
the task to count whatever *ticks* (jiffy interrupts) must wait in order to call the routine.
Within the current **unified periodic queue** (and assuming a *recommended* **4 ms** IRQ 
period) a *frequency* value of 250 would be equivalent to the older *slow* interrupt task
(4*250=1000 ms), while the standard **1** value will serve just like the old *jiffy* task.
In case a driver needs *both* the jiffy and slow interrupt tasks, code for the former
should handle an internal **counter** for the appropriate delay, *as was already 
being done for may interrupt tasks not requiring being executed at **every** single jiffy IRQ*. 
On such cases, the unified interrupt task may start (in 6502 fashion) like this:

```
    DEC delay          ; some internal counter
    BNE fast_task      ; not expired, just execute jiffy task
        LDA #max_delay ; number of jiffys to be executed before the slow task
        STA delay
        JSR slow_task  ; execute slow task...
fast_task:             ; ...and continue with the usual jiffy task
```

For instance, in a system with 4 ms jiffy IRQ, a driver executing a periodic task 
**every 20 ms** *and* a slow task every full second, would use `frequency = 5` and
`max_delay = 50`. A similar piece of code had to be used with "jiffy" tasks that
hadn't to be executed every periodic IRQ, as mentioned above.

Please note that while frequencies are stated as 16-bit integers, `LOWRAM` option will 
take the LSB *only*, setting it to **0** in case the MSB is not zero -- this will
provide the **slowest** operation (execute each 256 *jiffys*). For the full-fledged
version, a 16b *zero* frequency value implies the **slowest** operation again, this
time a whopping *65536 jiffys* (usually **over 4 minutes**).

Another improvement to the old method is the possibiliy of **temporarily disabling a certain 
interrupt task** when not needed, for better system performance (and, of course,
**re-enabling** it at any time, when needed). ***API functions** will be provided to
**enable/disable** a particular task, modify its **frequency** value or simply
**checking** its current settings*.

On the other hand, for **asynchronous interrupts** it's still worth keeping them in a 
*separate queue* for **lower interrupt latency**. *Frequency* is meaningless here, but
the idea of **enabling/disabling** them at will remains interesting. Such on-the-fly
check adds very little overhead, thus certainly worth it.

Please note that this system was designed with the (rather simple) interrupt system
of 65xx processors in mind. *Hardware with more sophisticated interrupt management
could use more queues to match their capabilities*. In any case, 
whenever the [ISR](https://en.wikipedia.org/wiki/Interrupt_handler) 
is called, if a **periodic interrupt** was the cause, the *periodic* queue will be
scanned, calling each entry sequentially. For the **asynchronous tasks**, a similar
procedure may be used, but each task **must** return an *error code* signaling whether
the IRQ was **acknowledged** by that handler or not. This code **may or may not**
be ignored by the ISR, depending on performance considerations or the estimated
chance of simultaneous interrupts. If *ignored*, the ISR should keep checking the
async queue until the end, which may avoid repeating the whole ISR cycle should
another IRQ be issued while serving the first one. 

### Interrupt performance: *latency* vs. *jitter* vs. *overhead*

In certain systems, **interrupt performance** may be a global performance defining
parameter. Especially on **65xx systems**, which bear *outstandingly low interrupt
latency*, although in the realm of a complex OS this is somewhat impaired.

But interrupt performance can be measured from different points of view. For a start,
in case of *asynchronous* interrupts, the goal is to achieve a very **low latency**, as
these interrupts may happen unexpectedly and should be serviced ASAP. While not as
efficient as specifically-tailored 6502 code, current implementation of the ISR is able
to execute the *most prioritary* asynchronous interrupt in as low as **40 clock cycles**,
still better than most other microprocessors can achieve. The *65816* version, with much
more context to save, takes longer (57 cycles) but as these will usually *faster clocked*
than 'classic' 6502s, this will hardly be an issue.

On the other hand, latency in itself becomes almost meaningless for synchronous,
*periodic* interrupts, which will happen at very precisely known time. As long as
the *periodicity* of executions is kept *reasonably* stable (*absolute* stability
is impossible to achieve!), they will do fine. The goal here is to keep **low jitter**
for predictable results. Since interrupt tasks may be temporarily interrupted, this
cannot be guaranteed, but code design should try to *equalize* execution times,
even if some *overhead* is added.

Being inspired by old-fashioned 8-bit systems, where *every cycle counts*, the ISR should
be as *succint* and efficient as possible, thus adding **minimal overhead**. This is always
desirable, but especially in minimOS, with its surprinsgly short *quantum* (**4 ms**
recommended, or **250 Hz**). Note that some critical systems may reduce jitter to almost
zero, by checking the VIA T1 value ASAP and then executing some equalizing *delay* code...
at the cost of **increased overhead**. *No free lunch, I'm afraid...*

Anyway, minimOS' firmware interface offers easy **ISR patching/replacing**, allowing
*optimum performance* when needed, although the firmware will always add some fixed
overhead.

### Static vs. *Dynamic* Drivers

As of 2018-05-29, drivers **cannot be loaded *on-the-fly*** (*dynamic*), 
being **assembled together** with the Kernel, firmware etc. 
The problem is in *driver variables*, which are **statically allocated**. 
*Future versions will allow loading drivers from mass storage, even on a 
running system **without rebooting***. For this to be achieved, *dynamic allocation* of 
variable space is needed, thus a parameter in driver header asks for a certain memory 
size. Details for passing the allocated space *pointer* to the asking driver are TBD,
however in 65xx architectures has been dismissed the idea of *pointing `sysptr`* to the 
beginning of allocated space, prior to any interrupt task execution, as this will 
**dramatically impair performance**, together with the use of *Indirect indexed 
addressing* instead of faster *absolute* addressing, indexed or not.
 
Alternatively, a *relocation* scheme (**not yet used**) will be used for *much*
better runtime performance; I no longer see any problem for the **65816**, as 
*Direct Page* does not need to be moved or even used, except for the
*globally system reserved* `sysptr` and `systmp`. 

Sample code for *driver variable **relocation*** could be as follows (wrote in
**16-bit** memory/indexes in 65816-fashion for simplicity).
*This will be done upon `DR_INST` call* and a similar scheme could be used for
*generic code relocation* as issued by `LOADLINK`.

We assume `da_ptr` points to the driver's header, as usual during install. *This
code may be generalized for data and code relocation*.

```
; *** let us allocate some memory for driver variables ***
; first let us set up some pointers
    LDY #D_MEM         ; how much dynamic memory is asked?
    LDA (da_ptr), Y
    BNE dd_end         ; static driver, nothing to do here
; if arrived here, it is a dynamic driver, must first allocate requested memory
        STA ma_rs          ; set parameters for MALLOC
        STZ ma_align       ; *** might revise API for non-page-aligned blocks ***
        _KERNEL(MALLOC)    ; successful allocation?
        BCC dyd_ok         ; yes, proceed
            _ERR(FULL)         ; no, abort driver installation 
dyd_ok:
        LDA ma_pt          ; get pointer from MALLOC
        STA dynmem         ; store as base for relocation
; space allocated, proceed to relocate references
; *** this section may be used for code relocation too ***
        LDY #D_DYN         ; get offset to relocation table
        LDA (da_ptr), Y
        CLC
        ADC da_ptr         ; get absolute pointer
        STA dyntab         ; use as local pointer
        LDY #0             ; reset counter
; all set, let us convert the variable references
dyd_rel:
            LDA (dyntab), Y    ; any more to convert?
                BEQ dd_end         ; no, all done
            CLC
            ADC da_ptr         ; yes, compute actual location of address
            STA tmptr          ; store temporary pointer
            LDA (tmptr)        ; this is the generic address to be converted
; generic data addresses may start at $4000 (up to 16K), while code relocation...
; ...may just start from zero, as skipping the header will provide addresses over $100
; in any case, 65xx jumps have no zeropage addressing anyway. 68xx may need...
; ...to make sure early jumps (or references) are assembled as full 16-bit.
; data relocation could start from $8000 as well, but $4000 gives it a chance to work...
; ...on unaware 32K RAM systems!
            EOR #$4000         ; *** assume generic addresses start @ $4000 and no more than 16k is used ***
            CLC
            ADC dynmem         ; the location of this driver's variables
            STA (tmptr)        ; address is corrected!
            INY                ; go for next offset (assume 16-bit indexes)
            INY
            BRA dyd_rel
dd_end:
```

Please note that, for this *and for any other relocation procedure*, should any
data structure be used via an indirect ZP⁻pointer, it **can no longer be set
via a couple of *immediate* loads**, but the *whole, uninterrupted pointer* must
be stored somewhere in order to allow its relocation. Typical code (no longer valid)
that would go as follows:

```
    LDY #<my_data    ; get LSB of data structure (statically allocated)
    LDA #>my_data    ; same for MSB
    STY pointer      ; store pointer in ZP
    STA pointer+1
    . . .
    LDA (pointer), Y ; (typical use example)
    . . .
```

In case of *dynamic* drivers, such kind of code should be written this way:

```
    LDY somewhere    ; must get LSB from the whole pointer
    LDA somewhere+1  ; same for MSB
; now follows identical code to above example
    STY pointer      ; store pointer in ZP
    STA pointer+1
    . . .
    LDA (pointer), Y ; (typical use example)
    . . .
somewhere:
    .word my_data    ; here lies the relocatable pointer to the dynamically allocated data
```

Thus the corresponding entry into the relocation table would precisely point
to `somewhere`, which contains the dynamic address.

On the other hand, *the above precautions may not be needed in 65816 code*,
as **16-bit immediate** allows easy copying of a *complete* pointer (within
**bank zero** at least, as expected for driver memory):

```
; 16-bit memory is assumed (or indexes in inconvenient, use LDX/STX or LDY/STY for copy instead)
    LDA #my_data     ; get WHOLE pointer of data structure (dynamically allocated)
    STA pointer      ; store pointer in ZP
    . . .
    LDA (pointer), Y ; (typical use example)
    . . .
```

65816 systems should also take care of **bank** addresses, thru a similar but
single-byte relocation code. Long references should be much rarer, though.

#### Relocation tables

*Not yet implemented*, but the most reasonable way of implementing relocatable
binaries would be an **offsets table** placed *after the code blurb*, which will
point to any location whenever an *absolute reference* is made -- the beginning
of this table (no need for any alignment) stored into `dyntab` ZP variable on the
code sample above. This list must be *double-null* terminated.

Actually, relocatable kernels and drivers would use **two** of these tables, pointed
from corresponding entries on the *minimOS header*. No particular order is thus
needed, although they could **not** be placed at the very beginning of the binary,
as that will prevent regular code execution.

### Input/Output

*I/O routines* need little explanation, now that **block** transfers are the
standard form. Old *character-oriented* code will now need to integrate a loop for
repeatedly executing the single byte transfer. Note that drivers lacking input and/or
output capabilities **must** provide anyway a pointer to a valid *error routine*, as
the MSB might be checked in some implementations. 

The primitive **event management** this far expected certain *control characters*
(^C for `SIGTERM`, ^Z for `SIGSTOP`, etc) to be received and processed via `CIN`.
However, this old approach would disable signal receiving by *CPU-intensive* tasks.
Thus, event management is the sole responsability of suitable **drivers**, simplified
by the newly provided `B_EVENT` kernel function. As this will send the appropriate
signal to the *foreground task* (and no longer to the calling PID), determining this
becomes a new problem. As a temporary workaround (still lacking *virtual windows*)
there are the **`B_FORE` and `GET_FG` new functions**, *in a similar fashion as
`SET_CURR` and `GET_PID` did for multitasking*.

#### Character set

In a way or another, no computing device is free from dealing with some text. And
because English is *not* my mother tongue, some **language support** had to be
included, at least in a minimalistic way.

*Multi-byte encodings** (like *Unicode*) are versatile and well supported anywhere,
they put *extra burden on limited devices* and thus not a very sensible choice for
this OS -- this is not *maximOS* by any stretch of imagination! However, **their use
is not ruled out** for bigger systems or when text I/O performance is not a concern;
it is simply an **optional feature**, just cannot be the *default, native* encoding.

The choice of character set is somewhere between **ISO 8859-1** and **ISO 8859-15**.

### Device IDs

IDs *were* chosen in a random fashion, but they're likely to be grouped into batches
of generic devices, like this:

- `lr0-lr7` = 128-135, **Low Resource** (for use within `LOWRAM` option)
- `rd0-rd7` = 136-143, **Reseved Drivers** (for multitasking, windowing, filesystem, etc.)
- *144-231 TBD*
- `as0-as7` = 232-239, *Asynchronous* Serial
- `ss0-ss7` = 240-247, *Synchronous* Serial (like **SS22**)
- `ud0-ud7` = 248-255, **User Devices** (255/`ud7` *might* be reserved)

Thus, drivers would include any ID in the generic range, and the
OS will try to find a place for him, perhaps with another suitable ID. Since
there could be up to 8 **asynchronous serial** devices `as0` to `as7`, corresponding
to IDs 232 to 239, **most** if not all of these drivers would be supplied with
a fixed ID of 232, no matter whether driving a 6551, 6850, 16C550 or *bit-banged* VIA;
upon install, the kernel would try to use the 232 entry. If busy, try everyone else up
to 239; if no free entry is found, complain as `BUSY`, otherwise install it. *Might try
first with the supplied ID first (232-239) just in case.*

Most likely, no auto-ID change should be available for reserved blocks (`lr` & `rd`).

As of 2017-10-23, a new `MUTABLE` option switches on this feature, which will take
(yet) another 256-byte array from `sysvars.h`, but may become implicit except for
`LOWRAM` systems.

About **logical** device IDs, as of 2018-05-29 only three are supported:

- **#0** as the (task-defined or global) **default** device (like UNIX's `stdin` & `stdout`)
- **#126** as **`DEV_RND`** (still under development)
- **#127** as **`DEV_NULL`** (more like UNIX's `/dev/zero`)

Device IDs in the range 1...63 are intended as **window** numbers, while 64 and up could
be assigned to open **file handlers**.

### Multitasking

An unconventional feature (for the sake of modularity) is that multitasking is
**implemented as a 'device' driver**. This driver will supply
the **scheduler** as a periodic `D_POLL` task (usually at *frequency* 1, although *soft*
6502 implementations may use a longer quantum) while the `D_INIT` routine will
**`PATCH` the existing *task-handling* functions**. `GET_PID` might not need to be
patched, as long as the scheduler makes use of the supplied `SET_CURR` function in
order to report the running PID (and architecture) to the OS. *Certainly, `GET_PID` is
intended for application use only, as the Kernel may just read its own variable.*

## Kernel/API

*to be done*

### Kernel patching

Kernel's API functions may be patched (except on the `LOWRAM` version). From 0.6, the
patching function (see *firmware* for details) provides the *previous* address,
thus allowing both **head and/or tail patching**. By passing a NULL pointer, any
*patched* function may be restored to the **originally supplied** one. You can also
unpatch the whole API, restoring it to the last installed full Kernel!  

## Access privileges

This is always a tough question, as there are some *psychological* reasons against
a robust, **highly protected** system -- it may lead to **buggier** user software
under the *fake security* impression that userland crashes won't affect the *rest*
of the system... but there are certain situations where adequate protection is
**a must**. Thus, by concept, minimOS *neither requires nor prevent protection
techniques*. Development is made with *cleanliness* and *functional separation*
in mind, but access privileges are just **recommended paths**, as 65xx CPUs have
no protection facilities whatsoever, and **may be skipped** altogether if *performance
concerns* require so. The aforementioned functional separation would allow other
CPUs with privilege support to strictly enforce such "correct" access procedures.

The arrows in the previous graphic tell the *expected* calls between components. In a nutshell:

- **User apps** should just call the *Kernel/API*
- **Kernel** will use *drivers* and *firmware* functions, but will **not** directly
access *hardware*
- **Drivers** will interact with *hardware*, either directly or thru *firmware*
- **Firmware** is of course *hardware-specific*, but may call some *Kernel* functions (?)

Eagle-eyed readers may have noticed the **yellow fringing** around the *apps-to-kernel*
arrow... while user apps are not *expected* to call the Firmware *directly*, there is
nothing preventing it. Actually, a "plain" 6502 may do it without effort, as the
firmware's [ABI](https://en.wikipedia.org/wiki/Application_binary_interface) is pretty
much the same as the Kernel's (call via `JSR` and ending in `RTS`). The 65816 makes it
more difficult, as the Kernel uses a different interface (call via `COP` which must end
in **`RTI`**) while the Firmware is expected to be called *from bank zero* (where the
Kernel & drivers must reside); but anyway, a **wrapper** is now provided for enabling
the user apps to **directly** call the firmware via `JSL` (from any bank)...
*if you know what you're doing* (register sizes, etc).

The desired *cleanliness* is responsible for the creation of some *apparently unneeded*
Kernel functions (`TS_INFO`, `RELEASE`, `SET_CURR`...) that will be discussed in due time,
particularly affecting **multitasking** implementation.

Note that some optimisation options will render kernel & firmware calls as **direct
`JSR` calls** (or some suitable 65816 replacement, including `PLP:RTL` instead of `RTI`)
removing the need for *jump tables* and the time-consuming interface that was needed
for **binary compatibility**.

### Task context

This is an architecture-dependent issue, but will usually include:

- Standard *per task* Input and Output device, allowing easy **redirection**
- Some available **space** for the user task, doesn't need to be allocated
- Probably an indication of available user space. *This could be updated with the
**actually** used bytes from that space*.
- **Local variables** for kernel functions (should *not* be touched by user code)
- **Kernel parameters** for function calling
- **System reserved variables** which, at least on 65xx machines, *may* be used
harmlessly but would certainly change upon interrupts or context switches.

Depending of the CPU used, this context can be totally or partially stored in
**zero-page** (for 65xx and 68xx families), **registers** (680x0) or some
appropriately pointed RAM area. Together with the 
[stack](https://en.wikipedia.org/wiki/Stack_\(abstract_data_type\)) area,
this will be saved upon **context switches** (typically under *multitasking*)
with probably the *system reserved variables* as a notable exception.
NMIs should preserve those too for total **transparency**

Some hardware may make this area **protected** from other processes. Even on
65xx architectures, ***bank-switching** the zero-page and stack* areas will yield
a similar effect, while greatly improving **multitasking** performance.

## Application format

To be done.

### Relocatable format

Although **not yes implemented** as of 2018-06-05, a *relocatable format* has been thought of.
In a similar way as already described for *dynamic drivers*, the most reasonable way could be
adding a **list of offsets** where the *generic* addresses are referenced, then upon load time
adding the base address to them. In order to avoid problems with *fake zero-page* references,
these generic addresses may start at **$8000**, similarly to dynamic driver generic accesses
to $4000 and beyond. The relocation algorithm has been already described there.

## The LOWRAM option

With an eye into **microcontrolers**, *minimOS* should be able to run on the most humble
devices. Most interestingly, application (source) code for these devices should run
**unmodified** on suitable bigger machines, for ease of development. With the
inspiration coming from an *exposure time meter* project (using a 650**3** and an
otherwise nearly-useless 6810 IC (**128-byte SRAM**), plus also from the attractive
**6301/6303** Hitachi MCUs, it is reasonable to design a *reduced feature set* with
particularly **low RAM usage**.

Initially devised as a *separate fork*, 0.5.x version gave birth to the `LOWRAM`
version. In order to reduce RAM usage, this option produces the following changes:

- Non-patchable kernel calls
- No memory management (besides zeropage/**context** area)
- Reduced number of available drivers
- Compact driver ID range (no *sparse* arrays)
- No multitasking option
- No windowing system option
- No filesystem

As there is no RAM to load programs (or drivers) on, there will not be any *relocation*
features.

Newer options for 0.6 include:

- replacing generic calls with direct JSRs (**DONE via the `FAST_API` and `FAST_FW` options**)**
- using I/O arrays in ROM (*should be a configuration file matter*)
- *adding* an array for driver enabling (whether `D_INIT` succeeded) (**in the making, bitwise**)

and many more *(to be completed)*

*more coming soon*
