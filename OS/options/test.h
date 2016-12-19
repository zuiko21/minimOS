; default options for minimOS and other modules
; empty file for testing purposes
; copy or link as options.h in root dir
; (c) 2016 Carlos J. Santisteban
; last modified 20161219-1229

; *** set conditional assembly ***

; comment for optimized code without optional checks
;#define		SAFE	_SAFE
;#define		NMOS	_NMOS
#define		LOWRAM	_LOWRAM

; some strange options for testing purposes
;#define		MULTITASK	_MULTITASK
;#define	C816		_C816

; *** machine specific info ***
; select type as on executable headers, B=generic 65C02, V=C816, N=NMOS 6502, R=Rockwell 65C02
; this one will select according to previous setting!
#ifdef	C816
#define		CPU_TYPE	'V'
#else
#define		CPU_TYPE	'B'
#endif

; *** machine hardware definitions ***
; Machine-specific ID strings, new 20150122, renamed 20150128, 20160120, 20160308

#define		MACHINE_NAME	"TESTING"
#define		MACHINE_ID		"test"

; Firmware selection, new 20160310, will pick up suitable template from firmware/
#define		ARCH			test

; Suitable driver package (add .h or .s as needed) in drivers/config/ folder, new 20160308
; may suit different configurations on a machine
#define		DRIVER_PACK		test

; *** Default files ***
; default shell from folder
#define		SHELL		monitor.s

; default NMI, BRK etc TBD ***********

; ***** some typical values as placeholders *****
; ** start of ROM **
ROM_BASE	=	$C000	; enough space for testing

; ** position of firmware, usually skipping I/O area **
FW_BASE		=	$F000	; enough for testing


; ** I/O definitions **

; I/O base address, usually one page, new 20160308
IO_BASE		=	$8000	; basic placeholder

; missing hardware declarations...
; * VIA 65(C)22 Base address, machine dependent *
VIA1	=	IO_BASE			; fake VIA address
VIA		=	VIA1			; for compatibility with older code

; ** new separate VIAs in some machines **
; VIA_J is the one which does the jiffy IRQ, most likely the main one
; VIA_FG is the one for audio generation (/PB7 & CB2)
; VIA_SS is the one for SS-22 interface

VIA_J	=	VIA1
VIA_FG	=	VIA1
VIA_SS	=	VIA1


; *** set standard device *** new 20160331 
DEVICE	=	255			; possibly not valid, just a placeholder

; *** memory size ***
; * some pointers and addresses * renamed 20150220

; SRAM pages, just in case of mirroring/bus error * NOT YET USED
#ifndef	LOWRAM
SRAM =	128		; 32 KiB available

SPTR		=	$FF		; general case stack pointer, new name 20160308
SYSRAM		=	$0200	; generic case system RAM after zeropage and stack, most systems with at least 1 kiB RAM
ZP_AVAIL	=	$E1		; as long as locals start at $E4, not counting used_zp
#else
; rare lowram version for testing purposes
SRAM		=	0
SPTR		=	$63		; (previously $75) MTE and other 128-byte RAM systems!
SYSRAM		=	$28		; for 128-byte systems, reduced value 20150210
ZP_AVAIL	=	$25
#endif

; *** speed definitions ***
; ***** meaningless because there are no hardware interrupts! *****

; ** master Phi-2 clock speed, used to compute remaining values! **
PHI2	=	1000000		; clock speed in Hz, PLACEHOLDER

; ** jiffy interrupt frequency **
IRQ_FREQ =	200			; general case
; T1_DIV no longer specified, should be computed elsewhere
; could be PHI2/IRQ_FREQ-2

; ** initial speed for SS-22 link, begin no faster than 15625 bps **
SS_SPEED =	30		; 15625 bps @ 1 MHz
; could be PHI2/31250-2

; ** speed code in fixed-point format, new 20150129 **
SPEED_CODE =	$10		; 1 MHz system
; could be computed as PHI2*16/1000000
