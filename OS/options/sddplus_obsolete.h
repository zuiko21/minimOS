; default options for minimOS and other modules
; set for CMOS SDd+
; copy or link as options.h in root dir
; (c) 2015 Carlos J. Santisteban
; last modified 20150123-1429

; conditional assembly, indicate NMOS for macros replacing new opcodes
;#define	NMOS	NMOS

; Machine-specific ID string, new 20150122
#define		MACHINE_NAME	"SDd PLUS", 0

;ROM_BASE =	$F000		; 4 kiB ROM SDd/Chihuahua
ROM_BASE =	$8000		; SDd+/Chihuahua PLUS only, maybe MTE too
;ROM_BASE =	$C000		; generic case

; VIA 65(C)22 Base address, machine dependent
VIA		=	$6FF0		; SDd, Chihuahua, Chihuahua PLUS, maybe SDd+ too
;VIA	=	$DFF0		; most other machines?

; PROJECT: put an ACIA on it, decide address!!!

; ***check these!***
; first allocatable SRAM page, architecture dependent!
; _lomem	3

; *** highest SRAM page, just in case of mirroring/bus error ***
; MTE needs mirroring for the stack, but it has just 128 bytes!
; SDd has 2 kiB max
; 63 pages (16 kiB) is the general case, OK for SDx too, even without hAck14!
; uncomment this for MTE (128-byte RAM)
;#define		_SRAM	1		
; uncomment this for SDd/CHICHUAHUA (2 KiB RAM)
;#define		_SRAM	7
; general case for 8-16 kiB RAM
#define		_SRAM	63

; *** initial stack pointer, MTE has 128-byte RAM! ***
; uncomment this for MTE (previously $75)
;#define	_SP		$60
; general case
#define		_SP		$FF

; *** panic routine address in ROM ***
; OK with 128-byte size, no longer $EEEE
#define	_PANIC		$FFEE
