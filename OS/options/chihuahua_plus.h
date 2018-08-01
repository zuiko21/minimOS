; default options for minimOS and other modules
; suitable for Chihuahua PLUS
; copy or link as options.h in root dir
; (c) 2015-2018 Carlos J. Santisteban
; last modified 20180801-2023

; *** set conditional assembly ***

; comment for optimized code without optional checks
#define		SAFE	_SAFE
;#define		NMOS	_NMOS
;#define		LOWRAM	_LOWRAM

; uncomment to enable (software) multitasking
#define		MULTITASK	_MULTITASK

; *** machine specific info ***
; select type as on executable headers, B=generic 65C02, V=C816, N=NMOS 6502, R=Rockwell 65C02
#define		CPU_TYPE	'B'

; *** machine hardware definitions ***
; Machine-specific ID strings, new 20150122, renamed 20150128, 20160120, 20160308

#define		MACHINE_NAME	"Chihuahua PLUS"
#define		MACHINE_ID		"sdd+"

; Firmware selection, new 20160310, will pick up suitable template from firmware/
#define		ARCH			chihuahua

; Suitable driver package (add .h or .s as needed) in drivers/config/ folder, new 20160308
; may suit different configurations on a machine
#define		DRIVER_PACK		chihuahua_plus_std

; *** Default files ***
; default shell from folder
#define		SHELL		miniMoDA.s

; default NMI, BRK etc TBD ***********

; ** start of ROM **
ROM_BASE	=	$C000	; new Chihuahua PLUS

; ** position of firmware, usually skipping I/O area **
FW_BASE		=	$F000	; standard value ***testing


; ** I/O definitions **

; I/O base address, usually one page, new 20160308
IO_BASE	=	$B000	; new Chihuahua PLUS, reserved for expansion at $Bxxx, undecoded area $8000-$9FFF

; * VIA 65(C)22 Base address, machine dependent *
; generic address declaration
VIA1	=	IO_BASE - $10	; new Chihuahua PLUS available at $Axxx, $AFFx makes it binary-compatible with SDd
VIA		=	VIA1			; for compatibility with older code

; ** new separate VIAs in some machines **
; VIA_J is the one which does the jiffy IRQ, most likely the main one
; VIA_FG is the one for audio generation (/PB7 & CB2)
; VIA_SS is the one for SS-22 interface
; VIA_U is the user interface (VIAport)

VIA_J	=	VIA1
VIA_FG	=	VIA1
VIA_SS	=	VIA1
VIA_U	=	VIA1

; * optional ACIA/UART address (in external board!) *
ACIA1	=	IO_BASE + $D0	; ACIA address on most (no longer $DFE0 for easier decoding 688+138)
ACIA	=	ACIA1			; for increased compatibility

; *** set standard device *** new 20160331 
DEVICE	=	DEV_LED		; standard I/O device

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
PHI2	=	1000000		; clock speed in Hz

; ** jiffy interrupt frequency **
IRQ_FREQ =	200			; general case
; T1_DIV no longer specified, should be computed elsewhere
; could be PHI2/IRQ_FREQ-2

; ** initial speed for SS-22 link, begin no faster than 15625 bps **
SS_SPEED =	30		; 15625 bps @ 1 MHz
; could be PHI2/31250-2

; speed code in fixed-point format, new 20150129
SPD_CODE =	$10		; 1 MHz system
; could be computed as PHI2*16/1000000
