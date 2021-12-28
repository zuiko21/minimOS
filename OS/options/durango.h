; default options for minimOS and other modules
; suitable for Durango (al least in proto version)
; copy or link as options.h in root dir
; (c) 2021 Carlos J. Santisteban
; last modified 20211228-2334

; *** set conditional assembly ***

; comment for optimized code without optional checks
#define		SAFE	_SAFE

; uncomment to enable (software) multitasking
;#define		MULTITASK	_MULTITASK

; *** these optimisations need the CPP preprocessor! ***
;#define		FAST_API	_FAST_API
;#define		FAST_FW		_FAST_FW

; new option for mutable IDs, most likely mandatory!
#define		MUTABLE		_MUTABLE

; *** machine specific info ***
; select type as on executable headers, B=generic 65C02, V=C816, N=NMOS 6502, R=Rockwell 65C02
;#define		NMOS	_NMOS
#ifdef	NMOS
#define		CPU_TYPE	'N'
#else
#define		CPU_TYPE	'B'
#endif

; *** machine hardware definitions ***
; Machine-specific ID strings, new 20150122, renamed 20150128, 20160120, 20160308

#define		MACHINE_NAME	"Durango"
#define		MACHINE_ID		"DX"

; Firmware selection, new 20160310, will pick up suitable template from firmware/
#define		ARCH_h			"firmware/durango.h"
#define		ARCH_s			"firmware/durango.s"

; Suitable driver package (add .h or .s as needed) in drivers/config/ folder, new 20160308
; may suit different configurations on a machine
#define		DRIVER_PACK_h		"drivers/config/durango_std.h"
#define		DRIVER_PACK_s		"drivers/config/durango_std.s"

; *** Default files ***
; default shell
#define		SHELL		"shell/minishell.s"
; default Firmware NMI
#define		STD_NMI		"shell/nanomon.s"

; default NMI, BRK etc TBD ***********


#ifdef	DOWNLOAD
; ** start of ROM **
ROM_BASE	=	$2000	; ** placeholder **
; ** position of firmware, usually skipping I/O area **
FW_BASE		=	$2000	; just before VRAM, now 16 kiB
#else
ROM_BASE	=	$8000	; Durango 32 kiB ROM
FW_BASE		=	$E000	; new value
#endif

; ** I/O definitions **

; I/O base address, usually one page, new 20160308
IO_BASE	=	$DF80			; new Durango

; * VIA 65(C)22 Base address, machine dependent *
; generic address declaration
;VIA1	=	IO_BASE - $10	; no VIAs in Durango!
;VIA	=	VIA1			; for compatibility with older code
; ** new separate VIAs in some machines **
; VIA_J is the one which does the jiffy IRQ, most likely the main one
; VIA_FG is the one for audio generation (/PB7 & CB2)
; VIA_SS is the one for SS-22 interface
; VIA_U is the user interface (VIAport)

; *** hardware-dependent device addresses ***
pvdu	= $6000					; standard screen address
IO8attr	= $DF80					; video mode flags (R/W)
IO8blk	= $DF88					; video blanking signals (R only)
IO9di	= $DF9A					; data input (PASK-like)
IOAie	= $DFAF					; d0 enables hardware interrupt
IOBeep	= $DFBF					; d0 goes to beeper output

; *** set standard device *** new 20160331 
DEVICE	=	DX_VDU		; standard I/O device

; *** memory size ***
; * some pointers and addresses * renamed 20150220

; SRAM pages, just in case of mirroring/bus error * NOT YET USED
; 128 pages (32 kiB) is the new generic case, no longer the highest page number!
SRAM =	128

SPTR		=	$FF		; general case stack pointer, new name 20160308
SYSRAM		=	$0200	; generic case system RAM after zeropage and stack, most systems with at least 1 kiB RAM
ZP_AVAIL	=	$E1		; as long as locals start at $E4, not counting used_zp


; *** speed definitions ***

; ** master Phi-2 clock speed, used to compute remaining values! **
PHI2	=	1536000		; clock speed in Hz (may become 1536000 in definitive version)

; ** jiffy interrupt frequency **
IRQ_FREQ =	250			; approximate, may become 250 in definitive version
; T1_DIV no longer specified, should be computed elsewhere
; could be PHI2/IRQ_FREQ-2

; ** initial speed for SS-22 link, begin no faster than 15625 bps ** NO VIA in Durango!
;SS_SPEED =	30		; 15625 bps @ 1 MHz
; could be PHI2/31250-2

; speed code in fixed-point format, new 20150129
SPD_CODE =	$18		; 1.536 MHz system
; could be computed as PHI2*16/1000000
