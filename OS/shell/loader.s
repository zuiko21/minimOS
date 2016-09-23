; Basic loader for minimOS (simple version)
; v0.5rc8
; last modified 20160923-0928
; (c) 2016 Carlos J. Santisteban

#include "usual.h"

; *** zeropage variables ***
	l_io	=	uz		; default device
	__last2	=	l_io+1	; END

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
		_ABORT(NO_RSRC)		; abort otherwise! proper error code
open_loader:
	STY l_io			; store device!!!
; ##### end of minimOS specific stuff #####

	LDY #<optxt		; get LSB
	LDA #>optxt		; and MSB
	STY str_pt		; as parameter
	STA str_pt+1
	LDY l_io		; set device
	_KERNEL(STRING)	; print entry
menu_exit:
	LDY l_io		; device just in case
	_KERNEL(CIN)	; get key
		BCS menu_exit	; wait for key
	LDY l_io		; just in case
	_KERNEL(COUT)	; hope is kept!
; should probably close/free device
	LDA io_c		; get key
	PHA				; save it!!!
	LDY l_io		; make some room
	LDA #13			; newline
	STA io_c		; as parameter
	_KERNEL(COUT)	; better looking
	PLA				; retrieve selection!!!
	AND #$0F		; filter number
	CMP #10			; only 9 entries supported
		BCS loader_init	; beyond available options!
	ASL				; twice
	TAX				; use as index
	JSR l_call		; execute option
	_BRA loader_init	; forever!

; *** basic routines ***
; call chosen program
l_call:
	LDA #ZP_AVAIL	; reset available space!
	STA z_used		; eeeeeek
	_JMPX(codeptr)	; choose from compiled table

; reject invalid option
invalid_option:
	PLA				; discard return
	PLA
	JMP loader_init	; and restart

; exit
l_shut:
	_KERNEL(SHUTDOWN)	; end

; *** pointer array ***
codeptr:
	.word	l_shut	; common exit routine
	.word	label1	; these are the addresses of the chunks of code
	.word	label2
	.word	label3
	.word	label4
	.word	label5
	.word	label6
	.word	label7
	.word	label8
	.word	label9

; *** on-screen texts ***
; these are content-dependent
optxt:
	.asc	"1) Monitor + disassembler", 13
	.asc	"2) Line editor", 13
	.asc	"3) miniMoDA (debug)", 13
; these are always present
	.asc	13, "0) SHUTDOWN", 13, "?", 0
l_title:
	.asc	"LOADER", 0
	
; *** available programs ***
label1:
.(
#define	KERNEL
#include "shell/disasm.s"
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

label4:
.(
#define	KERNEL
;#include "shell/miniMoDA.s"
.)

label5:
.(
#define	KERNEL
;#include "shell/miniMoDA.s"
.)

label6:
.(
#define	KERNEL
;#include "shell/miniMoDA.s"
.)

label7:
.(
#define	KERNEL
;#include "shell/miniMoDA.s"
.)

label8:
.(
#define	KERNEL
;#include "shell/miniMoDA.s"
.)

label9:
.(
#define	KERNEL
;#include "shell/miniMoDA.s"
.)

; wrong option arrives here
	RTS
