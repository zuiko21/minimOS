; minimOS 0.5.1a4 API/ABI
; (c) 2012-2016 Carlos J. Santisteban
; last modified 20161117-1337

; VIA 65(C)22 registers, just for convenience
; offsets from base address (add to base in options.h)
IORB	= $0
IORA	= $1
DDRB	= $2
DDRA	= $3
T1CL	= $4
T1CH	= $5
T1LL	= $6
T1LH	= $7
T2CL	= $8
T2CH	= $9
SR		= $A
ACR		= $B
PCR		= $C
IFR		= $D
IER		= $E
NHRA	= $F		; IRA/ORA without handshake

; ** Driver table offsets **
D_ID	=  0		; driver ID
D_AUTH	=  1		; authorization code
D_INIT	=  2		; device reset
D_POLL	=  4		; periodic interrupt task
D_REQ	=  6		; asynchronous interrupt request
D_CIN	=  8		; character input
D_COUT	= 10		; character output
D_SEC	= 12		; 1-second interrupt
D_BLIN	= 14		; block input, new names 20150304, also for control purposes
D_BLOUT	= 16		; block output, new names 20150304, also for control purposes
D_BYE	= 18		; shutdown procedure
D_INFO	= 20		; points to a C-string with driver info
D_MEM	= 22		; NEW, required variable space (if relocatable)

; ** Driver feature mask values **
A_POLL	= %10000000	; D_POLL routine available
A_REQ	= %01000000	; D_REQ routine available
A_CIN	= %00100000	; D_CIN capability
A_COUT	= %00010000	; D_COUT capability
A_SEC	= %00001000	; D_SEC routine available
A_BLIN	= %00000100	; D_BLIN capability
A_BLOUT	= %00000010	; D_BLOUT capability
A_MEM	= %00000001	; D_MEM dynamically linked, on-the-fly loadable driver

; ** firmware interface calls (TBD) **
INSTALL		=  0	; copy jump table
SET_ISR		=  2	; set IRQ vector
SET_NMI		=  4	; set (magic preceded) NMI routine
PATCH		=  6	; patch single function (renumbered)
GESTALT		=  8	; get system info (renumbered)
POWEROFF	= 10	; power-off, suspend or cold boot
CONTEXT		= 12	; context bankswitching
JIFFY		= 14	; set jiffy IRQ speed, ** TBD **

; ***** ***** kernel function codes for system call ***** *****
COUT		=   0	; character output
CIN			=   2	; character input
MALLOC		=   4	; allocate memory
FREE		=   6	; release memory
OPEN_W		=   8	; open window or get I/O devices
CLOSE_W		=  10	; close a window or release device and its buffer
FREE_W		=  12	; release a window but let it on screen, keeping its buffer, may be closed by kernel
UPTIME		=  14	; give uptime in ticks and seconds *** no longer_hid_push!
B_FORK		=  16	; reserve a free braid
B_EXEC		=  18	; get code at some address running into a previously reserved braid
LOAD_LINK	=  20	; get an executable from its path, and get it loaded into primary memory, maybe relocated
SU_POKE		=  22	; access protected memory or I/O
SU_PEEK		=  24	; access protected memory or I/O
STRING		=  26	; output a C-string via COUT
SU_SEI		=  28	; disable interrupts, really needed?
SU_CLI		=  30	; enable interrupts, really needed?
SET_FG		=  32	; set PB7 frequency generator
GO_SHELL	=  34	; launch default shell, probably needed
SHUTDOWN	=  36	; proper shutdown, with or without power-off
B_SIGNAL	=  38	; send UNIX_like signal to a braid
B_STATUS	=  40	; get execution flags of a braid
GET_PID		=  42	; get current braid PID
SET_HNDL	=  44	; set SIGTERM handler
B_YIELD		=  46	; give away CPU time, not really needed but interesting anyway
TS_INFO		=  48	; get taskswitching info for multitasking driver
RELEASE		=  50	; release ALL memory chuncks belonging to some PID, new 20161115

; ** optional multitasking subfunctions, TBD **
MM_FORK		=  0	; reserve a free braid (will go BR_STOP for a moment)
MM_EXEC		=  2	; get code at some address running into a paused braid (will go BR_RUN)
MM_YIELD	=  4	; switch to next braid, likely to be ignored if lacking hardware-assisted multitasking
MM_SIGNAL	=  6	; send some signal to a braid
MM_STATUS	=  8	; get execution flags for a braid, new 20150413
MM_PID		= 10	; get current PID, new 20150413
MM_HANDL	= 12	; set TERM handler, new 20150416
MM_PRIOR	= 14	; priorize braid, jump to it at once, really needed? new 20150413, renumbered 20150416

; ** multitasking status values **
BR_FREE		= 192	; free slot, non-executable
BR_RUN		=   0	; active process, may get CPU time, should be zero for quick evaluation
BR_STOP		= 128	; paused process, will not get CPU until resumed
BR_END		=  64	; ended task, waiting for rendez-vous
; might add a fifth state for forked-but-not-yet-loaded braids (in order NOT to start them abnormally)
BR_MASK		= 192	; as it set both bits but NOT those for SIGTERM handler, new 20161117

; ** multitasking signals **
SIGKILL		=  0	; immediately kill braid, will go BR_FREE
SIGTERM		=  2	; ask braid to terminate in an orderly fashion, default handler is SIGKILL
SIGSTOP		=  4	; pause braid, will go BR_STOP
SIGCONT		=  6	; resume a previously paused braid, will go BR_RUN

; ** power control values, valid for kernel and firmware **
PW_STAT		=  0	; suspend (go static) if available, or no pending action, best if zero
PW_WARM		=  2	; warm reset (needs no firmware) renumbered 150603
PW_COLD		=  4	; cold reset (needed for compatibility with other architectures) renumbered 150603
PW_OFF		=  6	; power off
PW_CLEAN	=  8	; scheduler detected system is clean for poweroff! new 20160408

; ** optional windowing system values, TBD **
W_OPEN		=   0	; active window in use
W_CLOSE		= 192	; closed, free window
W_FREE		= 128	; no longer in use, may be closed by kernel itself
W_REQ		=  64	; requested to close, will send SIGTERM to creator braid

; ** optional filesystem subfunctions 20150304, TBD **
FOPEN		=   0	; why not FS_OPEN, etc?
FSEEK		=   2
FTELL		=   4
FCLOSE		=   6
FFLUSH		=   8
; extra codes TBD
FS_MKDIR	=  10	; create directory
FS_CD		=  12	; set working directory
FS_PATH		=  14	; get working directory
FS_ENTRY	=  16	; get one file entry from current directory (masked?)
FS_REW		=  18	; return to first entry on directory
FS_DEL		=  20	; delete file or directory
FS_TOUCH	=  22	; set modification date
FS_STAT		=  24	; get info about file
FS_NAME		=  26	; rename file or directory
FS_FREE		=  28	; get free space on current volume
FS_MOUNT	=  30	; mount (all?) volumes on a device
FS_UNMNT	=  32	; unmount volume
FS_CREATE	=  34	; format filesystem

; ** values for RAM chunck status **
; make certain FREE_RAM is zero for easier scan (BEQ)
; even number just in case indexed jump is used
FREE_RAM	=	0
USED_RAM	=	2
END_RAM		=	4	; new label 20161103
LOCK_RAM	=	6	; new label 20161117

; ** logic devices, TBD **
DEV_RND		= 126	; get a random number
DEV_NULL	= 127	; ignore I/O

; ***** ***** error codes ***** *****
OK		=   0		; not needed on 65xx, CLC instead
UNAVAIL	=   1		; unavailable on this version
TIMEOUT	=   2		; try later
FULL	=   3		; not enough memory, try less
N_FOUND	=   4		; try another
NO_RSRC	=   5		; no resource, try a different way
EMPTY	=   6		; put some and retry
INVALID	=   7		; invalid argument
BUSY	=   8		; cannot use it now, free it or wait
CORRUPT	=   9		; data corruption

; some kernel-related definitions
; MAX_BRAIDS should be system variable, as defined by firmware and/or multitasking driver
; default updateable value = 1 (no multitasking)
; if defined in firmware, think about a gestalt-like function for reading/setting it!

-MAX_BRAIDS	=	1	; no multitasking

; QUANTUM_COUNT no longer defined here

#ifndef	LOWRAM
			MAX_QUEUE	=	16	; maximum number of drivers, and queue size (half the number of drivers)
			MAX_LIST	=	16	; number of available RAM blocks *** might increase this value in 65816 systems!
#else
			MAX_QUEUE	=	4	; much less available drivers in 128-byte systems
			MAX_LIST	=	0	; no memory management for such systems
#endif

; optional filesystem limits, TBD
; again, this might be defined elsewhere

MAX_FILES	=	16
MAX_VOLS	=	8

; ** physical device numbers, TBD **
; these are likely to become 'logical' port IDs like rs0, rs1, ss0... regardless of actual implementation
DEV_LED		= 252	; LED keypad on VIAport
DEV_LCD		= 210	; Hitachi LCD module, TO_DO
DEV_ACIA	= 236	; ACIA, currently 6551
DEV_SS22	= 250	; SS-22 port
DEV_ASCII	= 241	; ASCII keyboard on VIAport, TO_DO
DEV_DEBUG	= 255	; Bus sniffer, NEW 20150323
DEV_CONIO	= 132	; for Kowalski simulator, NEW 20160308
DEV_VGA		= 192	; integrated VGA-compatible Tijuana, NEW 20160331

; more temporary IDs

; lcd-4-bit @ascii = 240
; acia 2651 = 237
; VIA PA parallel port = 243
; VDU @ VIAport = 242
; (d)uart-16c550-1 = 232 hehehe
; duart-16c552-0 (or 2) = 224
; rtc 146818 (pseudo-driver?) = 208
; duart 2681-1 = 235 (or 227)
; duart 2681-2 = 227 (or 235)
