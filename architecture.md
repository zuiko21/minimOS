# minimOS architecture

*Last update: 2017-05-07*

## Rationale

**minimOS** (or *mOS* for short) is intended as a **development platform** for computers 
with *modest resources*. Its main goals are **modularity** (you choose whatever set of 
features you need) and **portability**: originally targeted to computers based on 6502 
CPU and derivatives, either commercial or home-made by retrocomputing enthusiasts, might 
be equally ported for almost any CPU out there including, but not limited to, Motorola 
**6800**, **6809** & **680x0**, Intel **8080**/8085/Zilog **Z80** and the popular **x86**, 
plus the ubiquitous **ARM**.

These goals will define most of its design features.

## Architecture

### Inspiration from CP/M

The *portability* goal takes some inspiration from the once popular **CP/M**, the then 
*de facto* standard OS for microcomputers. While the original target (65xx) is 
contemporary with those systems, present-day computing expectations lead to several 
differences.

Perhaps this achieved goal was the key to CP/M's success. This OS had three main components:

- **BIOS** (Basic I/O system, *hardware dependent*)
- **BDOS** (Basic Disk OS)
- **CCP** (Console Command Processor)

Please note that unlike the BIOS, which was provided *customised* by the computer's maker, 
all the remaining components were **generic**, as supplied by Digital Research. Of course, 
other commands or the *application software* was run by temporarily replacing the CCP, as this 
was a single task, single user OS.

Alas, this scheme is not complete: usally, these components were provided on some kind of mass-storage
media (often *diskettes*) that had to be *loaded* into RAM somehow, as no CPU has any means to execute code
*directly* from **secondary memory**. Thus, a small piece of **ROM** or any other *non-volatile **primary** memory* 
was needed in order to load and run the Operating System. This was often a **bootloader** (generically known as 
**firmware**) whose main purpose, besides perhaps some initial setup and hardware tests (*POST, Power-On Self Test*)
was merely copying those three files in RAM and ordering the CPU to jump at their code.

Back in the day, the **I/O** capabilites of computers were rather limited: assume a *keyboard*, an *output device*
(could be a text CRT screen, but a *teletype* would do) and/or a *printer*, plus some *mass-storage* devices, 
and you were set. Thus, the concept of modular device **drivers** as separate pieces of software was not relevant,
and adapting your system to different peripherals meant the aforementioned **BIOS customisation** -- it wasn't
*that* hard, anyway.

*more in a few minutes*

