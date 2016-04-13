; MINIMAL support for minimOS components
; on Kowalski's 6502 simulator
; v0.9.1b2
; (c)2016 Carlos J. Santisteban
; last modified 20160413-1050

#define		ROM		_ROM
#define		KERNEL	_KERNEL

#include "options/kowalski.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
.bss
user_sram = SYSRAM
.text

* = $E000			; just a placeholder, no standardised address

reset:
; *** basic init ***
	SEI				; cold boot (2)
	CLD				; just in case, a must for NMOS, maybe for emulating '816 (2)
	LDX #SPTR		; initial stack pointer, machine-dependent, must be done in emulation for '816 (2)
	TXS				; initialise stack (2)
; *** prepare execution ***
	LDA #$E1		; standard available space on zeropage
	STA z_used		; notify
	JSR module		; execute code!
	BRK				; end execution
;************************ module under testing **********************************
module:
#include "shell/monitor.s"		; here goes the code
;********************************************************************************
	RTS				; just in case

; *** minimal kernel support ***
; *** output ***
kow_cout:
	CPY #0			; default device?
		BNE kow_err		; abort I/O otherwise
	LDA io_c		; get char in case is control
kco_dir:
	CMP #13			; carriage return?
	BNE kow_ncr		; if so, should generate CR+LF
		LDA #10			; LF first
		STA IO_BASE+1	; print it
		LDA #13			; back to original CR
kow_ncr:
	STA IO_BASE+1	; print it
kow_rts:
	_EXIT_OK

kow_err:
	_ERR(NO_RSRC);	; unsupported device

; *** input ***
kow_cin:
	CPY #0			; default device?
		BNE kow_err		; abort I/O otherwise
	LDA IO_BASE+4	; get input from I/O window
	BEQ kow_empty	; nothing available
		STA io_c		; store result otherwise
		_EXIT_OK
kow_empty:
	_ERR(EMPTY)		; nothing yet

; ** open window ***
open_w:
	LDA w_rect			; asking for some size?
	ORA w_rect+1
	BEQ k8_no_window	; wouldn't do it
		_ERR(NO_RSRC)
k8_no_window:
	LDA #'['			; new window title
	JSR kco_dir			; print it
	JSR string			; print title
	LDA #']'			; new window title
	JSR kco_dir			; print it
	LDA #13				; new line
	JSR kco_dir
	LDY #0				; constant default device
	_EXIT_OK

; *** string ***
; interface for internal use
str_pre:
	STY str_pt			; set parameter
	STA str_pt + 1
; *** official entry point ***
string:
	LDY #0				; offset
str_loop:
		LDA (str_pt), Y		; get char
			BEQ str_end			; terminated
		JSR kco_dir			; direct call!
		INY					; next
		BNE str_loop		; no BRA!
			INC str_pt+1		; page crossing!
		BNE str_loop		; continue
str_end:
	_EXIT_OK

; *** shutdown ***
shutdn:
	LDY #<off			; get shutdown message
	LDA #>off
	JSR str_pre			; print the string
	BRK					; stop emulation!

; *** unimplemented function ***
unimpl:
	LDY #<invalid		; get unimplemented message
	LDA #>invalid
	JMP str_pre			; print the string and return

; *** minimal interrupt support ***
nmi:
	PHA					; store regs
	_PHX
	_PHY
	JSR do_nmi			; execute!
	_PLY				; restore regs
	_PLX
	PLA
	RTI

do_nmi:
; *** place adequate NMI routine here ***
	LDY #<nmint			; get NMI message
	LDA #>nmint
	JMP str_pre			; print the string and return

irq:
	PHA					; store regs
	_PHX
	_PHY
	JSR isr				; execute!
	_PLY				; restore regs
	_PLX
	PLA
	RTI

isr:
; *** place adequate IRQ routine here ***
	LDY #<intack		; get IRQ message
	LDA #>intack
	JMP str_pre			; print the string and return

; *** data and tables ***
off:
	.asc 13, "{SHUTDOWN}", 0
invalid:
	.asc " {UNIMPLEMENTED} ", 0
nmint:
	.asc " {NMI} ", 0
intack:
	.asc " {IRQ} ", 0

; check against abi.h!!!!
fw_kern:
	.word	kow_cout	; COUT 0
	.word	kow_cin		; CIN 2
	.word	unimpl		; 4
	.word	unimpl		; 6
	.word	open_w		; OPENW 8
	.word	unimpl		; 10
	.word	unimpl		; 12
	.word	unimpl		; 14
	.word	unimpl		; 16
	.word	unimpl		; 18
	.word	unimpl		; 20
	.word	unimpl		; 22
	.word	unimpl		; 24
	.word	string		; STRING 26
	.word	unimpl		; 28
	.word	unimpl		; 30
	.word	unimpl		; 32
	.word	unimpl		; 34
	.word	shutdn		; SHUTDOWN 36

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	kernel_call-*, $FF
#endif

; *** minimOS function call primitive ($FFC0) ***
* = kernel_call
	CPX #37				; check against limits
	BCC call_ok			; no overflow
		JMP unimpl			; error otherwise
call_ok:
	_JMPX(fw_kern)		; macro for NMOS compatibility (6)

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	admin_call-*, $FF
#endif

; *** administrative meta-kernel call primitive ($FFD0) ***
* = admin_call
	CPX #10				; only SHUTDOWN supported!
	BEQ do_shut
		JMP unimpl			; error otherwise
do_shut:
	JMP shutdn			; valid so far

; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	panic-*, $FF
#endif

; *** panic routine, locks at very obvious address ($FFE1-$FFE2) ***
* = panic
	SEC					; unified procedure 20150410, was CLV
panic_loop:
	BCS panic_loop		; no problem if /SO is used, new 20150410, was BVC
	NOP					; padding for reserved C816 vectors

; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	$FFFA-*, $FF
#endif

; *** 65(C)02 ROM vectors ***
* = $FFFA				; just in case
	.word	nmi			; (emulated) NMI	@ $FFFA
	.word	reset		; (emulated) RST	@ $FFFC
	.word	irq			; (emulated) IRQ	@ $FFFE
