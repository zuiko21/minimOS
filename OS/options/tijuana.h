; default options for minimOS and other modules
; suitable for Tijuana with built-in VGA-compatible output
; copy or link as options.h in root dir
; (c) 2015-2019 Carlos J. Santisteban
; last modified 20180801-2042

; *** set conditional assembly ***

; comment for optimized code without optional checks
;#define		SAFE	_SAFE

; uncomment to enable (software) multitasking
;#define		MULTITASK	_MULTITASK

; *** machine specific info ***
; select type as on executable headers, B=generic 65C02, V=C816, N=NMOS 6502, R=Rockwell 65C02
#define		CPU_TYPE	'R'

; *** machine hardware definitions ***
; Machine-specific ID strings, new 20150122, renamed 20150128, 20160120, 20160308

#define		MACHINE_NAME	"Tijuana"
#define		MACHINE_ID		"tvga"

; Firmware selection, new 20160310, will pick up suitable template from firmware/
#define		ARCH			firmware/tijuana

; Suitable driver package (add .h or .s as needed) in drivers/config/ folder, new 20160308
; may suit different configurations on a machine
#define		DRIVER_PACK		drivers/config/tijuana_std

; *** Default files ***
; default shell from folder
#define		SHELL		shell/monitor.s

; default NMI, BRK etc TBD ***********

; ** start of ROM **
ROM_BASE	=	$C000		; 16 kiB only

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
; VIA_SP is the one for SPI interface (TBD)
; VIA_U is the one for user interface (VIAport)

VIA_J	=	VIA1
VIA_FG	=	VIA1
VIA_SS	=	VIA1
VIA_SP	=	VIA1
VIA_U	=	VIA1

; * ACIA/UART address *
ACIA1	=	IO_BASE + $D0	; ACIA address on SDm and most other (no longer $DFE0 for easier decoding 688+138)
ACIA	=	ACIA1			; for increased compatibility

; *** set standard device *** new 20160331 
DEVICE	=	DEV_VGA		; standard I/O device

; *** memory size ***
; * some pointers and addresses * renamed 20150220

; SRAM pages, just in case of mirroring/bus error * NOT YET USED
SRAM		=	64		; up to 16 kiB for general use, despite having much more memory!

SPTR		=	$FF		; general case stack pointer, new name 20160308
SYSRAM		=	$0200	; generic case system RAM after zeropage and stack, most systems with at least 1 kiB RAM
ZP_AVAIL	=	$E1		; as long as locals start at $E4, not counting used_zp


; *** speed definitions ***

; ** master Phi-2 clock speed, used to compute remaining values! **
PHI2	=	3072000		; clock speed in Hz
;PHI2	=	3146875		; if proper VGA dot clock is used

; ** jiffy interrupt frequency **
IRQ_FREQ =	200			; general case
; T1_DIV no longer specified, should be computed elsewhere
; could be PHI2/IRQ_FREQ-2
;T1_DIV		=	15358	; (15360-2) 200Hz ints @ 3.072 MHz (5 ms quantum)
;T1_DIV		=	15732	; (15734-2) ~200Hz ints @ 3.146875 MHz with proper VGA dot clock, otherwise 2 sec/day faster!

; ** initial speed for SS-22 link, begin no faster than 15625 bps **
SS_SPEED	=	97		; 15625 bps @ 3.072 MHz
;SS_SPEED	=	99		; in case of proper VGA dot clock (3.146875 MHz) but might be fine otherwise
; could be PHI2/31250-2

; speed code in fixed-point format, new 20150129
SPEED_CODE	=	$31		; 3.072 MHz system
;SPEED_CODE	=	$32		; 3.146875 MHz system
; could be computed as PHI2*16/1000000
