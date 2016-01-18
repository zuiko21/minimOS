; default options for minimOS and other modules
; set for CMOS SDm
; copy or link as options.h in root dir
; (c) 2015 Carlos J. Santisteban
; last modified 20151015-1228

; *** set conditional assembly ***
; uncomment to remove debugging markup
;#define	FINAL	_FINAL

; comment for optimized code without optional checks
#define		SAFE	_SAFE

; uncomment for macros replacing new opcodes
;#define	NMOS	_NMOS
;#define	C816	_C816

; select type as on executable headers, B=generic 65C02, V=C816, N=NMOS 6502, R=Rockwell 65C02???
#define		_CPU_TYPE	'B'

; allows for 128-byte systems!
#define		LOWRAM		_LOWRAM

; enables filesystem feature
;#define		FILESYSTEM		_FILESYSTEM

; enables multitasking kernel, as long as there is enough memory
#ifndef	LOWRAM
#define		MULTITASK	_MULTITASK
#endif

; enables hardware-assisted bankswitching, esp. the autobank feature ***DEPRECATE???
;#define		AUTOBANK	_AUTOBANK

; *** machine hardware definitions ***
; Machine-specific ID strings, new 20150122, renamed 20150128
#define		_MACHINE_NAME	"SDm"
#define		_MACHINE_ID		"sdm"

;ROM_BASE	=	$F000	; 4 kiB ROM SDd/Chihuahua
ROM_BASE	=	$8000	; SDx, SDm, SDd+/Chihuahua PLUS only, maybe MTE too
;ROM_BASE	=	$C000	; generic case

; VIA 65(C)22 Base address, machine dependent
;VIA	=	$6FF0		; SDd, Chihuahua, Chihuahua PLUS, maybe SDd+ too
VIA	=	$DFF0		; most other machines? including SDm

; PROJECT, put an ACIA on it, decide address!!!
;ACIA	=	$6FE0		; SDd+, maybe
ACIA	=	$DFE0		; ACIA address on SDx and most other, including SDm

; *** RAM size ***
; uncomment this for 128-byte systems!
;#define	LOWRAM		_LOWRAM

; * some pointers and addresses * renamed 20150220

; * highest SRAM page, just in case of mirroring/bus error * NOT YET USED
; uncomment for MTE, needs mirroring for the stack, but it has just 128 bytes!
; SRAM =	1

; uncomment this for SDd/CHIHUAHUA (2 KiB RAM)
;SRAM =	7

; page 63 (16 kiB) is the general case, OK for SDx too, even without hAck14!
;SRAM =	63

; page 127 (32 kiB) works for newly designed SDm 20150615
SRAM =	127

#ifdef	LOWRAM
; initial stack pointer, renamed as label 20150603
SP		=	$63		; (previously $75) MTE and other 128-byte RAM systems!

; system RAM location, where firmware and system variables start, renamed as label 20150603
SYSRAM	=	$28		; for 128-byte systems, reduced value 20150210

; user-zp available space, new 20150128, updated 20150210, renamed as label 20150603
; in 128-byte systems leave 37(+3+1) bytes for user ($03-$27) assuming 60-byte stack AND sysvars space ($28-$63)
; unless a 6510 is used, the two first bytes are available
; without multitasking, $02 (z_used) is free, and so is $FF/$7F (sys_sp)
ZP_AVAIL	=	$25

#else
SP			=	$FF		; general case stack pointer
SYSRAM		=	$0200	; after zeropage and stack, most systems with at least 1 kiB RAM
ZP_AVAIL	=	$E2		; as long as locals start at $E4

#endif

; *** speed definitions ***
; interrupt counter value
;T1_DIV	=	198			; (200-2) 5 kHz @ 1 MHz (200µs quantum) for MTE!
T1_DIV	=	4998		; (5000-2) 200Hz ints @ 1 MHz (5 ms quantum) general case
;IRQ_FREQ =	5000		; for MTE
IRQ_FREQ =	200			; general case

; initial speed for SS-22 link
SS_SPEED =	30		; 15625 bps @ 1 MHz
;SS_SPEED = 62		; 15625 bps @ 2 MHz
;SS_SPEED =	126		; 15625 bps @ 4 MHz
;SS_SPEED =	254		; 15625 bps @ 8 MHz

; speed code in fixed-point format, new 20150129
SPEED_CODE =	$10		; 1 MHz system
;SPEED_CODE =	$20		; 2 MHz system (SDx)
