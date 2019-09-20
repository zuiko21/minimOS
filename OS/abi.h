; minimOS 0.6rc22 API/ABI
; *** not compatible with earlier versions ***
; (c) 2012-2019 Carlos J. Santisteban
; last modified 20190920-2248

; *************************************************
; *************************************************
; ***** kernel function codes for system call *****
; *************************************************
; *************************************************

; legacy basic I/O
COUT		= 0				; character output, interface for BOUT
CIN			= COUT + 2		; character input, interface for BLIN
STRING		= CIN + 2		; output a C-string
READLN		= STRING + 2	; read input into supplied buffer

; block-oriented I/O
BLOUT		= READLN + 2	; block output
BLIN		= BLOUT + 2		; block input
BL_CNFG		= BLIN + 2		; configuration settings, new TBD
BL_STAT		= BL_CNFG + 2	; device status report, new TBD

; basic windowing system
OPEN_W		= BL_STAT + 2	; open window or get I/O device
CLOSE_W		= OPEN_W + 2	; close a window or release device and its buffer
FREE_W		= CLOSE_W + 2	; release a window but let it on screen, keeping its buffer, may be closed by kernel
FLOAT_W		= FREE_W + 2	; put this window in foreground, interface similar to B_FORE
; perhaps could add some other window management functions

; other generic functions
UPTIME		= FLOAT_W + 2	; give uptime in ticks and seconds
; *** frequency generator DEPRECATED for firmware ***
SHUTDOWN	= UPTIME + 2	; proper shutdown, with or without power-off
LOADLINK	= SHUTDOWN + 2	; get an executable from its path, and get it loaded into primary memory, maybe relocated

; for multitask main use, but also with reduced single task management, will be patched by multitasking driver!
B_FORK		= LOADLINK + 2	; reserve a free braid
B_EXEC		= B_FORK + 2	; get code at some address running into a previously reserved braid
B_SIGNAL	= B_EXEC + 2	; send UNIX_like signal to a braid
B_FLAGS		= B_SIGNAL + 2	; get execution flags of a braid
SET_HNDL	= B_FLAGS + 2	; set SIGTERM handler
B_YIELD		= SET_HNDL + 2	; give away CPU time, not really needed but interesting anyway
B_FORE		= B_YIELD + 2	; set foreground task ***new 20181011***
GET_FG		= B_FORE + 2	; get previously set foreground task ***new20181022***
; unpatched functions...
B_EVENT		= GET_FG + 2	; identify event and send signal to foreground task ***new 20181011*** for drivers
GET_PID		= B_EVENT + 2	; get current braid PID *** 20171220 is last one as will not need to be patched

; some new driver functionalities, perhaps OK with LOWRAM systems
DR_INFO		= GET_PID + 2	; get header, new
DR_EXEC		= DR_INFO + 2	; execute driver routine, new 20190126
AQ_MNG		= DR_EXEC + 2	; get asyncronous task status, or enable/disable it!
PQ_MNG		= AQ_MNG + 2	; get periodic task status, enable/disable it or set frequency!

; drivers... perhaps in a reduced way for LOWRAM systems
DR_INST		= PQ_MNG + 2	; install driver
DR_SHUT		= DR_INST + 2	; shutdown driver

; ** not for LOWRAM systems **
; memory...
MALLOC		= DR_SHUT + 2	; allocate memory
FREE		= MALLOC + 2	; release memory block
MEMLOCK		= FREE + 2		; allocate memory at a certain address, new 20170524
RELEASE		= MEMLOCK + 2	; release ALL memory blocks belonging to some PID, new 20161115 *** worth it???
; multitasking...
TS_INFO		= RELEASE + 2	; get taskswitching info for multitasking driver
SET_CURR	= TS_INFO + 2	; set internal kernel info for running task (PID & architecture) new 20170222

; *** define the jump-table size for more efficient memory usage! ***
API_SIZE	= SET_CURR + 2	; *** set just after the LAST API call, renamed 20180124 ***

; ***********************
; ***********************
; ***** error codes *****
; ***********************
; ***********************
END_OK	=   0		; not needed on 65xx, CLC instead
UNAVAIL	=   1		; unavailable on this version
TIMEOUT	=   2		; try later
FULL	=   3		; not enough memory, try less
N_FOUND	=   4		; try another
NO_RSRC	=   5		; no resource, try a different way
EMPTY	=   6		; put some and retry
INVALID	=   7		; invalid argument
BUSY	=   8		; cannot use it now, free it or wait
CORRUPT	=   9		; data corruption

; ************************************
; ************************************
; ** firmware interface calls (TBD) **
; ************************************
; ************************************

; generic functions, esp. interrupt handler related
GESTALT		= 0				; supply hardware info
SET_ISR		= GESTALT+2		; set interrupt service routine
SET_NMI		= SET_ISR+2		; set NMI routine (internally handled)
SET_DBG		= SET_NMI+2		; set debugger (BRK) routine

; somewhat hardware specific, interrupt hardware related
JIFFY		= SET_DBG+2		; set periodic interrupt frequency
IRQ_SRC		= JIFFY+2		; determine interrupt line

; pretty hardware specific
POWEROFF	= IRQ_SRC+2		; shutdown, suspend etc.
FREQ_GEN	= POWEROFF+2	; generate square wave

; not for LOWRAM systems
INSTALL		= FREQ_GEN+2	; copy kernel jump table
PATCH		= INSTALL+2		; change one kernel function
; CONTEXT no longer used, as would be just called from a *specific* Multitasking driver
RELOC		= PATCH+2		; relocate code and/or variables ***TBD***
CONIO		= RELOC+2		; firmware basic console, when available

; **************************
; ** Driver table offsets **
; **************************
D_ID	=  0		; driver ID
D_AUTH	=  1		; authorization mask
D_BLIN	=  2		; BLOCK input code
D_BOUT	=  4		; BLOCK output code
D_INIT	=  6		; device reset procedure
D_POLL	=  8		; periodic interrupt task
D_FREQ	= 10		; frequency for periodic task, new 20170517
D_ASYN	= 12		; asynchronous interrupt task
D_CNFG	= 14		; device configuration, TBD
D_STAT	= 16		; device status, TBD
D_BYE	= 18		; shutdown procedure
D_INFO	= 20		; points to a C-string with driver info
D_MEM	= 22		; NEW, required variable space (if relocatable) (WORD)
D_DYN	= 24		; NEW, offset to relocation table (if the above is NOT zero)

; ** Driver feature mask values **
A_POLL	= %10000000	; D_POLL routine available
A_REQ	= %01000000	; D_REQ routine available
A_BLIN	= %00100000	; D_BLIN capability
A_BOUT	= %00010000	; D_BOUT capability
A_CNFG	= %00001000	; D_CNFG capability
A_STAT	= %00000100	; D_STAT capability
A_RSVD	= %00000010	; *** no longer available, RESERVED ***
A_MEM	= %00000001	; D_MEM dynamically linked, on-the-fly loadable driver

; ** VIA 65(C)22 registers, just for convenience **
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
VSR		= $A		; renamed 20170805
ACR		= $B
PCR		= $C
IFR		= $D
IER		= $E
NHRA	= $F		; IRA/ORA without handshake

; **********************************
; ** values for RAM chunck status **
; **********************************
; make certain FREE_RAM is zero for easier scan (BEQ)
; even numbers just in case indexed jump is used
FREE_RAM	=	0
USED_RAM	=	2
END_RAM		=	4	; new label 20161103
LOCK_RAM	=	6	; new label 20161117

; some kernel-related definitions *** renamed
#ifndef	LOWRAM
MX_QUEUE	=	16	; maximum interrupt task queue size
MX_DRVRS	=	16	; maximum number of drivers, independent as of 20170207
MAX_LIST	=	32	; number of available RAM blocks *** might increase this value in 65816 systems!
#else
MX_QUEUE	=	6	; much smaller queues in 128-byte systems, note unified jiffy & slow queues!
MX_DRVRS	=	4	; maximum number of drivers, independent as of 20170207
MAX_LIST	=	0	; no memory management for such systems
#endif

IQ_FREE	= 127		; empty entry in interrupt queues, new 20180320

; multitasking subfunctions no longer needed as will patch regular kernel!

; ** multitasking status values **
BR_FREE		= 192	; free slot, non-executable
BR_RUN		=   0	; active process, may get CPU time, should be zero for quick evaluation
BR_STOP		= 128	; paused process, will not get CPU until resumed
BR_END		=  64	; ended task, waiting for rendez-vous
BR_BORN		= 160	; added a fifth state for forked-but-not-yet-loaded braids (in order NOT to start them abnormally)
BR_MASK		= 224	; as it set highest 3 bits but NOT those for SIGTERM handler, new 20161117

; ** multitasking signals **
SIGKILL		=  0	; immediately kill braid, will go BR_FREE... maybe after BR_END if launched from rendez-vous mode
SIGTERM		=  2	; ask braid to terminate in an orderly fashion, default handler is SIGKILL
SIGSTOP		=  4	; pause braid, will go BR_STOP
SIGCONT		=  6	; resume a previously paused braid, will go BR_RUN

; MAX_BRAIDS should be system variable, as defined by firmware and/or multitasking driver
; default updateable value = 1 (no multitasking)
; if defined in firmware, think about a gestalt-like function for reading/setting it!
; QUANTUM_COUNT no longer defined here

; ********************************************************
; *** subfunction codes for task queues management TBD ***
; ********************************************************
TQ_STAT		=   0	; read status (and frequency)
TQ_EN		=   2	; enable task
TQ_DIS		=   4	; disable task
TQ_FREQ		=   6	; set task frequency (periodic tasks only)

; *********************************************************
; ** power control values, valid for kernel and firmware **
; *********************************************************
PW_STAT		=  0	; suspend (go static) if available, or no pending action, best if zero
PW_WARM		=  2	; warm reset (needs no firmware) renumbered 150603
PW_COLD		=  4	; cold reset (needed for compatibility with other architectures) renumbered 150603
PW_OFF		=  6	; power off
PW_CLEAN	=  8	; scheduler detected system is clean for poweroff! new 20160408
; invocation codes for NMI and IRQ
PW_NMI		= 10	; trigger max-priority interrupt (like NMI)
PW_IRQ		= 12	; trigger standard hardware interrupt (6502 has IRQ only)
; other architectures may use further codes for lesser-priority interrupts

; *******************************************
; ** optional windowing system values, TBD **
; *******************************************
W_OPEN		=   0	; active window in use
W_CLOSE		= 192	; closed, free window
W_FREE		= 128	; no longer in use, may be closed by kernel itself
W_REQ		=  64	; requested to close, will send SIGTERM to creator braid

; *****************************************
; ** device numbers and identifier names ** TBD
; *****************************************
; 128...135	lr0-7, low-RAM devices
; 136...143	ff0-7, fixed-function devices, e.g. multitask, windowing...
; 144...151	io0-7, combined I/O devices, e.g. terminal
; 152...159	
; 160...167	st0-7, storage devices (R/W)
; 168...175	ro0-7, massive read-only devices
; 176...183	nt0-7, network interfaces?
; 184...191	kb0-7, keyboards & keypads
; 192...199	td0-7, text displays
; 200...207	gd0-7, graphic (bitmapped) displays
; 208...215	pt0-7, pointing devices, e.g. mouse
; 216...223	pr0-7, printers?
; 224...232	gp0-7, general purpose I/O, e.g. VIAport
; 232...239	as0-7, asynchronous serial, e.g. RS-232
; 240...247	ss0-7, synchronous serial, e.g. SS-22
; 248...254	ud0-6, user defined
; 255		rdv, reserved

/*
; ****************************************************
; ** optional filesystem subfunctions 20150304, TBD **
; ****************************************************
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
FS_CREAT	=  34	; format filesystem

; optional filesystem limits, TBD
; again, this might be defined elsewhere

MAX_FILES	=	16
MAX_VOLS	=	8
*/

; ************************
; ** logic devices, TBD **
; ************************
DEV_RND		= 126	; get a random number
DEV_NULL	= 127	; ignore I/O

; ** physical device numbers, TBD **
; these are likely to become 'logical' port IDs like rs0, rs1, ss0... regardless of actual implementation
DEV_LED		= 252	; LED keypad on VIAport
DEV_LCD		= 210	; Hitachi LCD module, TO_DO
DEV_ACIA	= 236	; ACIA, currently 6551
DEV_SS22	= 250	; SS-22 port
DEV_ASC		= 241	; ASCII keyboard on VIAport, TO_DO
DEV_DBG		= 255	; Bus sniffer, NEW 20150323
DEV_CNIO	= 132	; for Kowalski & run816 simulator, NEW 20160308
DEV_VGA		= 192	; integrated VGA-compatible Tijuana, NEW 20160331
SOFT232		= 232	; VIA-bit banged serial

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

