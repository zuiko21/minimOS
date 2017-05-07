# minimOS architecture

*Last update: 2017-05-07*

## Rationale

**minimOS** (or *mOS* for short) is intended as a **development platform** for computers 
with *modest resources*. Its main goals are **modularity** (you choose whatever set of 
features you need) and **portability**: originally targeted to computers based on 
[**6502** CPU](https://en.wikipedia.org/wiki/) 
and derivatives, either commercial or home-made by retrocomputing enthusiasts, might 
be equally ported for almost any CPU out there including, but not limited to, Motorola 
[**6800**](), 
[**6809**]() & 
[**680x0**](), 
Intel [**8080**]()/
[8085]()/
[Zilog **Z80**]() 
and the popular [**x86**](), 
plus the ubiquitous [**ARM**]().

These goals will define most of its design features.

## Architecture

### Inspiration from CP/M and *home* computers

The *portability* goal takes some inspiration from the once popular 
[**CP/M**](), 
the then *de facto* standard OS for microcomputers. While the original target (65xx) is 
contemporary with those systems, present-day computing expectations lead to several 
differences.

Perhaps this achieved goal was the key to CP/M's success. This OS had three main components:

- **BIOS** (Basic I/O system, *hardware dependent*)
- **BDOS** (Basic Disk OS)
- **CCP** (Console Command Processor)

Unlike the 
[BIOS](), 
which was provided *customised* by the computer's maker, 
all the remaining components were **generic**, as supplied by 
[Digital Research](). 
Of course, other commands or the *application software* were run atop of this, probably by 
temporarily *replacing the CCP* for increased available RAM, as this 
was a **single task**, single user OS. As soon as the task was completed, the *shell* (CCP) 
was reloaded and the user was prompted for another command.

Alas, this scheme is not complete: usually, these components were provided on some kind of mass-storage
media (often 
[*diskettes*]()) 
that had to be *loaded* into RAM somehow, as no CPU has any means to execute code *directly* from 
[**secondary memory**](). 
Thus, a small piece of **ROM** or any other *non-volatile 
[**primary** memory]()* 
was needed in order to load and run the Operating System. This was often a 
[**bootloader**](https://en.wikipedia.org/wiki/Booting) 
(generically known as 
[**firmware**](https://en.wikipedia.org/wiki/Firmware)) 
whose main purpose, besides perhaps some initial setup and hardware tests 
([*POST, Power-On Self-Test*](https://en.wikipedia.org/wiki/Power-on_self-test))
was merely copying those three files in RAM and ordering the CPU to jump at their code. Obviously, 
this firmware was part of the computer maker's package, and had nothing to do with CP/M, save 
for being designed to boot from such system files. 

Apart from such firmware design, having an **Intel 8080** CPU or compatible (the only one 
initially supported by CP/M) and at least **16 KiB RAM** *starting at address $0*\* (plus some 
kind of **disk drive** for the DOS to work on) were the only requisites to any computer 
maker to have a **CP/M compatible** machine. With its notable software base, CP/M was *the* 
choice for many computer makers, at least in the office environment.

\*) A quick *hardware* note: since the i8080 CPU starts executing code *from address 0* 
also, some **non-volatile** ROM is expected to be accesible there. But CP/M *needs* RAM there, 
thus some means to *switch off* ROM access from the bottom of the address map (once 
the firmware has done its task, of course) has to be provided to achieve CP/M compatibility... 
unless you want to *manually* program the initial RAM bytes via toggle-switches! Anyway, 
that simple 
[*bank-switching*](https://en.wikipedia.org/wiki/Bank_switching) 
feature was easily implemented, as demonstrated by CP/M's popularity.

Back in the day, the **I/O** capabilites of computers were rather limited: assume a *keyboard*, an *output device*
(could be a text CRT screen, but a 
[*teletype*](https://en.wikipedia.org/wiki/Teleprinter) 
would do) and/or a *printer*, plus some *mass-storage* devices, 
and you were set. Thus, the concept of modular 
[device **drivers**](https://en.wikipedia.org/wiki/Device_driver) 
as separate pieces of software was not relevant, and adapting your system to different 
peripherals meant the aforementioned **BIOS customisation** -- it wasn't *that* hard, anyway.

After the hayday of CP/M came the *x86-based* 
[**IBM PC**](https://en.wikipedia.org/wiki/IBM_Personal_Computer) 
running [**MS-DOS**](https://en.wikipedia.org/wiki/MS-DOS), 
itself pretty much inspired by CP/M, although the BIOS was somehow integrated into the firmware, as 
was definitely part of the (heaviliy standardised) machine. For compatibility, a 
[**jump table**](https://en.wikipedia.org/wiki/Branch_table) 
was provided for easily calling BIOS routines, no matter their actual 
locations in ROM; for additional performance, some software *skipped* this jump table, 
leading to a 
[plethora of incompatibilities](https://en.wikipedia.org/wiki/Influence_of_the_IBM_PC_on_the_personal_computer_market) 
whenever a *different from IBM's (copyrighted) BIOS* was used, but this soon ceased 
to be a problem. *The rest is history...*

## The home-computer market

On the other hand, the late seventies witnessed the birth of an unexpected computer 
market: the 
[*home computer*](https://en.wikipedia.org/wiki/Home_computer) 
which, despite the performance impairment, made computing affordable for the masses.

But bereft of the portability/standardisation features of CP/M (and later MS-DOS) machines, 
these were **closed, incompatible systems**, each platform gathering its base of loyal 
users. Despite this diversity, many systems became quite popular indeed: the 
[**TRS-80**](https://en.wikipedia.org/wiki/TRS-80),
the [**Commodore PET**](https://en.wikipedia.org/wiki/Commodore_PET) 
and the [**Apple \]\[**](https://en.wikipedia.org/wiki/Apple_II) 
in USA; 
the [**ZX Spectrum**](https://en.wikipedia.org/wiki/ZX_Spectrum),
the powerful [**BBC Micro**](https://en.wikipedia.org/wiki/BBC_Micro) 
(especially in UK schools) and, a bit later, the 
[**Amstrad CPC**](https://en.wikipedia.org/wiki/Amstrad_CPC) 
at the other side of the pond... plus the 
[**Commodore 64**](https://en.wikipedia.org/wiki/Commodore_64) 
(and its predecessor [**VIC-20**](https://en.wikipedia.org/wiki/Commodore_VIC-20)
) anywhere in the world, to mention the most relevant.

Despite their alleged technological advantage, the *Japanese* were off from this 
fierce price war (essential parameter of the targeted market) but they tried to make 
an *standardised* platform for it: the ill-fated 
[**MSX**](https://en.wikipedia.org/wiki/MSX) 
systems had some popularity in 
Japan, but much less in Europe and almost zero in America.

Substituting home cassette players for (then expensive) disk drives, these systems had 
a relatively ample ROM with not only the essential firmware and *kernel/BIOS* (sort-of), 
but usually a 
[**BASIC language interpreter**](https://en.wikipedia.org/wiki/BASIC) 
was built-in, thus after booting (in just *a couple of seconds!*) one could simply 
start typing programs. *Many of us were taught Computer Programming (leading to later 
Computer Science formal education) this way...*

A pretty odd exception to this rule (in the UK) was the 
[**Jupiter ACE**](https://en.wikipedia.org/wiki/Jupiter_Ace), 
somewhat related to 
[*Sinclair*](https://en.wikipedia.org/wiki/Sinclair_Research) 
computers, but meant to be programmed... in 
[**Forth**](https://en.wikipedia.org/wiki/Forth_(programming_language)). 
This limited machine 
played little role into the troubled waters of home computers, but made a point on the 
**extreme efficiency** of the little known Forth language.

*more in a few minutes*

