; default options for minimOS and other modules
; suitable for run816 BBC simulator
; for 8-bit kernel testing!
; copy or link as options.h in root dir
; (c) 2017-2022 Carlos J. Santisteban
; last modified 20200301-1008

; *** set conditional assembly ***

; comment for optimized code without optional checks
#define		SAFE	_SAFE

;#define		LOWRAM	_LOWRAM

; *** these optimisations need the CPP preprocessor! ***
;#define		FAST_API	_FAST_API
;#define		FAST_FW		_FAST_FW

; new option for mutable IDs, most likely mandatory!
#define		MUTABLE		_MUTABLE

; enable in order to remove headers, not LOADLINK savvy!
;#define		NOHEAD	_NOHEAD
; enable multitasking support... hopefully! *** might be defined upon multitasking driver
;#define		MULTITASK	_MULTITASK

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

#define		MACHINE_NAME	"BBC simulator '02"
#define		MACHINE_ID		"run6502"

; Firmware selection, new 20160310, will pick up suitable template from firmware/
#define		ARCH_s			"firmware/run02.s"
#define		ARCH_h			"firmware/run02.h"

; Suitable driver package (add .h or .s as needed) in drivers/config/ folder, new 20160308
; may suit different configurations on a machine
#define		DRIVER_PACK_s		"drivers/config/run02_std.s"
#define		DRIVER_PACK_h		"drivers/config/run02_std.h"

; *** Default files ***
; default shell from folder
#define		SHELL		"shell/minishell.s"
; default firmware NMI
#define		STD_NMI		"shell/nanomon.s"
; default NMI, BRK etc TBD ***********

; ** start of ROM **
ROM_BASE	=	$8000	; enough for package WITH EhBASIC

; ** position of firmware, usually skipping I/O area **
FW_BASE		=	$F800	; simple firmware expected on BBC simulator


; ** I/O definitions **

; I/O base address, usually one page, new 20160308
IO_BASE		=	$DF00	; as per EhBASIC I/O

; missing hardware declarations...
; * VIA 65(C)22 Base address, machine dependent *
VIA1	=	IO_BASE + $10	; fake VIA address, should not be checked!
VIA		=	VIA1			; for compatibility with older code

; ** new separate VIAs in some machines **
; VIA_J is the one which does the jiffy IRQ, most likely the main one
; VIA_FG is the one for audio generation (/PB7 & CB2)
; VIA_SS is the one for SS-22 interface

VIA_J	=	VIA1
VIA_FG	=	VIA1
VIA_SS	=	VIA1

; * ACIA/UART address *
ACIA1	=	IO_BASE + $20	; fake ACIA address, should not be checked!
ACIA	=	ACIA1			; for increased compatibility

; *** set standard device *** new 20160331 
DEVICE	=	DEV_CNIO		; standard I/O device

; *** memory size ***
; * some pointers and addresses * renamed 20150220

; SRAM pages, just in case of mirroring/bus error * NOT YET USED
#ifndef	LOWRAM
SRAM		=	128		; 32 KiB available as standard
SPTR		=	$FF		; general case stack pointer, new name 20160308
SYSRAM		=	$0200	; generic case system RAM after zeropage and stack, most systems with at least 1 kiB RAM
#ifndef	C64
ZP_AVAIL	=	$E1		; as long as locals start at $E4, not counting used_zp
#else
ZP_AVAIL	=	$DF		; two bytes less for the 6510
#endif
#else
; rare lowram version for testing purposes
SRAM		=	0
SPTR		=	$63		; (previously $75) MTE and other 128-byte RAM systems!
SYSRAM		=	$20		; for 128-byte systems, reduced value 20150210 (should be $28)
ZP_AVAIL	=	SYSRAM-3
#endif

; *** speed definitions ***
; ***** meaningless because there are no hardware interrupts! *****

; ** master Phi-2 clock speed, used to compute remaining values! **
PHI2	=	2000000		; clock speed in Hz, PLACEHOLDER

; ** jiffy interrupt frequency **
IRQ_FREQ =	200			; general case
; T1_DIV no longer specified, should be computed elsewhere
; could be PHI2/IRQ_FREQ-2

; ** initial speed for SS-22 link, begin no faster than 15625 bps **
SS_SPEED =	30		; 15625 bps @ 1 MHz
; could be PHI2/31250-2

; ** speed code in fixed-point format, new 20150129 **
SPD_CODE =	$20		; 1 MHz system
; could be computed as PHI2*16/1000000
