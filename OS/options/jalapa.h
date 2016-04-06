; default options for minimOS and other modules
; suitable for Jalapa and its strange memory architecture!
; copy or link as options.h in root dir
; (c) 2015-2016 Carlos J. Santisteban
; last modified 20160406-0844

; *** set conditional assembly ***

; comment for optimized code without optional checks
;#define		SAFE	_SAFE

; hardware-capable multitasking machine!
#define		MULTITASK	_MULTITASK

; *** machine specific info ***
; select type as on executable headers, B=generic 65C02, V=C816, N=NMOS 6502, R=Rockwell 65C02
#define		CPU_TYPE	'B'

; *** machine hardware definitions ***
; Machine-specific ID strings, new 20150122, renamed 20150128, 20160120, 20160308

#define		MACHINE_NAME	"Jalapa"
#define		MACHINE_ID		"sdm"

; Firmware selection, new 20160310, will pick up suitable template from firmware/
#define		ARCH			jalapa

; Suitable driver package (add .h or .s as needed) in drivers/config/ folder, new 20160308
; may suit different configurations on a machine
#define		DRIVER_PACK		jalapa_std

; *** Default files ***
; default shell from folder
#define		SHELL		monitor.s

; default NMI, BRK etc TBD ***********

; ** start of ROM **
ROM_BASE	=	$8000		; SDm/Jalapa, might become the generic case

; ** position of firmware, usually skipping I/O area **
FW_BASE		=	$E000		; standard value


; ** I/O definitions **

; I/O base address, usually one page, new 20160308
IO_BASE		=	$DF00		; generic case

; * VIA 65(C)22 Base address, machine dependent *
VIA1	=	IO_BASE + $F0	; for most machines
VIA2	=	VIA1			; Jalapa is a single-VIA machine, others may change
VIA		=	VIA1			; for compatibility with older code

; ** new separate VIAs in some machines **
; VIA_J is the one which does the jiffy IRQ, most likely the main one
; VIA_FG is the one for audio generation (/PB7 & CB2)
; VIA_SS is the one for SS-22 interface

VIA_J	=	VIA1
VIA_FG	=	VIA1
VIA_SS	=	VIA1

; * ACIA/UART address *
ACIA1	=	IO_BASE + $D0	; ACIA address on SDm and most other (no longer $DFE0 for easier decoding 688+138)
ACIA	=	ACIA1			; for increased compatibility

; * will it include RTC? *

; *** set standard device *** new 20160331 
DEVICE	=	DEV_ACIA		; standard I/O device

; *** memory size ***
; * some pointers and addresses * renamed 20150220

; SRAM pages, just in case of mirroring/bus error * NOT YET USED
; 128 pages (32 kiB) is the new generic case, no longer the highest page number!
SRAM =	128
; note special memory architecture, upper 16K fixed and lower 16K bankswitched!

SPTR		=	$FF		; general case stack pointer, new name 20160308
SYSRAM		=	$4000	; *** special case for bankswitched SDm/Jalapa ***
ZP_AVAIL	=	$E1		; as long as locals start at $E4, not counting used_zp


; *** speed definitions ***

; ** master Phi-2 clock speed, used to compute remaining values! **
PHI2	=	2000000		; clock speed in Hz

; ** jiffy interrupt frequency **
IRQ_FREQ =	200			; general case
; T1_DIV no longer specified, should be computed elsewhere
; could be PHI2/IRQ_FREQ-2

; ** initial speed for SS-22 link, begin no faster than 15625 bps **
SS_SPEED	=	62		; 15625 bps @ 2 MHz
; could be PHI2/31250-2

; speed code in fixed-point format, new 20150129
SPEED_CODE	=	$20		; 2 MHz system
; could be computed as PHI2*16/1000000
