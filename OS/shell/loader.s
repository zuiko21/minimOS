; Basic loader for minimOS (simple version)
; v0.5rc4
; last modified 20160602-1054
; (c) 2016 Carlos J. Santisteban

#ifndef	KERNEL
#include "options.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
.bss
#include "firmware/ARCH.h"
#include "sysvars.h"
.text
#endif

; *** zeropage variables ***
	l_io	=	uz		; default device
	l_ptr	=	l_io+1	; generic pointer
	__last2	=	l_ptr+2	; END

; *** initialise the loader ***

loader_init:
; ##### minimOS specific stuff #####
	LDA #__last2-uz		; zeropage space needed
	STA z_used			; set needed ZP space as required by minimOS
	_STZA w_rect		; no screen size required
	_STZA w_rect+1		; neither MSB
	LDY #<l_title		; LSB of window title
	LDA #>l_title		; MSB of window title
	STY str_pt			; set parameter
	STA str_pt+1
	_KERNEL(OPEN_W)		; ask for a character I/O device
	BCC open_loader		; no errors
		_ERR(NO_RSRC)		; abort otherwise! proper error code
open_loader:
	STY l_io			; store device!!!
; ##### end of minimOS specific stuff #####

	LDX #<txtptr	; get LSB
	LDA #>txtptr	; and MSB
	STX l_ptr		; store pointer
	STA l_ptr+1
	LDY #0			; reset counter
menu_loop:
		LDA (l_ptr), Y	; get address LSB
		STA str_pt		; as parameter
		INY				; same for MSB
		LDA (l_ptr), Y
		STA str_pt+1
		ORA str_pt		; check for double NULL
			BEQ menu_exit	; finished
		INY				; ready for next
		_PHY			; save!
		LDY l_io		; set device
		_KERNEL(STRING)	; print entry
		_PLY			; restore
		_BRA menu_loop
menu_exit:
	LDY l_io		; device
	_KERNEL(CIN)	; get key
		BCS menu_exit	; wait for key
	LDY l_io		; just in case
	_KERNEL(COUT)	; hope is kept!
; should probably close/free device
	LDA io_c		; get key
	AND #$0F		; filter number
	CMP #3+1		; *** first incorrect option!!! ***
		BCS loader_init	; beyond available options!
	ASL				; twice
	TAX				; use as index
	JSR l_call		; execute option
	_BRA loader_init	; forever!

; *** basic routines ***
; call chosen program
l_call:
	LDY l_io		; make some room
	LDA #13			; newline
	STA io_c		; as parameter
	_KERNEL(COUT)	; better looking
	LDA #ZP_AVAIL	; reset available space!
	STA z_used		; eeeeeek
	_JMPX(codeptr)	; choose from compiled table

; exit
l_shut:
	_KERNEL(SHUTDOWN)	; end

; *** string pointer array ***
txtptr:
	.word	opt1	; as declared below
	.word	opt2
	.word	opt3
	.word	optx	; exit, always present, includes prompt
	.word	0		; last pointer is a double NUL

codeptr:
	.word	l_shut	; common exit routine
	.word	label1	; these are the addresses of the chunks of code
	.word	label2
	.word	label3

; *** on-screen texts ***
; these are content-dependent
opt1:
	.asc	"1) M/L Monitor", 13, 0
opt2:
	.asc	"2) Line editor", 13, 0
opt3:
	.asc	"3) miniMoDA (debug)", 13, 0
; these are always present
optx:
	.asc	13, "0) SHUTDOWN", 13, "?", 0
l_title:
	.asc	"LOADER", 0
	
; *** available programs ***
label1:
.(
#define	KERNEL
#include "shell/monitor.s"
.)

label2:
.(
#define	KERNEL
#include "../apps/lined.s"
.)

label3:
.(
#define	KERNEL
#include "shell/miniMoDA.s"
.)
