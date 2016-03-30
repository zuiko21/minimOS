; default options for minimOS and other modules
; suitable for Kowalski simulator
; copy or link as options.h in root dir
; (c) 2015-2016 Carlos J. Santisteban
; last modified 20160330-1240

; *** set conditional assembly ***

; comment for optimized code without optional checks
;#define		SAFE	_SAFE

; *** machine specific info ***
; select type as on executable headers, B=generic 65C02, V=C816, N=NMOS 6502, R=Rockwell 65C02
#define		CPU_TYPE	'B'

; *** machine hardware definitions ***
; Machine-specific ID strings, new 20150122, renamed 20150128, 20160120, 20160308

#define		MACHINE_NAME	"Kowalski simulator"
#define		MACHINE_ID		"kow"

; Firmware selection, new 20160310, will pick up suitable template from firmware/
#define		ARCH			kowalski

; Suitable driver package (add .h or .s as needed) in drivers/config/ folder, new 20160308
; may suit different configurations on a machine
#define		DRIVER_PACK		kowalski_std

; *** Default files ***
; default shell from folder
#define		SHELL		monitor.s

; default NMI, BRK etc TBD ***********

; ** start of ROM **
ROM_BASE	=	$E000	; safe for Kowalski if I/O area set to $DF00

; ** position of firmware, usually skipping I/O area **
FW_BASE		=	$F800	; simple firmware expected on Kowalski simulator


; ** I/O definitions **

; I/O base address, usually one page, new 20160308
;IO_BASE	=	$DF00	; set accordingly on simulator!

; missing hardware declarations...
; * VIA 65(C)22 Base address, machine dependent *
VIA1	=	IO_BASE + $10	; fake VIA address, should not be checked!
VIA		=	VIA1			; for compatibility with older code

; ** new separate VIAs in some machines **
; VIA_J is the one which does the jiffy IRQ, most likely the main one
; VIA_FG is the one for audio generation (/PB7 & CB2)
; VIA_SS is the one for SS-22 interface
; VIA_SP is the one for SPI interface (TBD)

VIA_J	=	VIA1
VIA_FG	=	VIA1
VIA_SS	=	VIA1
VIA_SP	=	VIA1

; * ACIA/UART address *
ACIA1	=	IO_BASE + $20	; fake ACIA address, should not be checked!
ACIA	=	ACIA1			; for increased compatibility


; *** memory size ***
; * some pointers and addresses * renamed 20150220

; highest SRAM page, just in case of mirroring/bus error * NOT YET USED
SRAM =	191		; 48 KiB (and more) available this far

SPTR		=	$FF		; general case stack pointer, new name 20160308
SYSRAM		=	$0200	; generic case system RAM after zeropage and stack, most systems with at least 1 kiB RAM
ZP_AVAIL	=	$E1		; as long as locals start at $E4, not counting used_zp


; *** speed definitions ***
; meaningless because no hardware interrupts!

; interrupt counter value
T1_DIV	=	4998		; (5000-2) 200Hz ints @ 1 MHz (5 ms quantum) general case
IRQ_FREQ =	200			; general case

; initial speed for SS-22 link
SS_SPEED =	30		; 15625 bps @ 1 MHz

; speed code in fixed-point format, new 20150129
SPEED_CODE =	$10		; 1 MHz system
