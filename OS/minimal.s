; MINIMAL support for minimOS components
; on Kowalski's 6502 simulator
; v0.9a1
; (c)2016 Carlos J. Santisteban
; last modified 20160309-1420

#include "options.h"	; machine specific
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
.bss
#include "firmware/firmware.h"	; machine specific
#include "sysvars.h"
;#include "drivers.h"
user_sram = *
;#include "drivers.s"	; don't assemble actual code, just labels

* = ROM_BASE			; just a placeholder, no standardised address

;#define	ROM		_ROM

reset:
; *** basic init ***
	SEI				; cold boot (2)
	LDX #SPTR		; initial stack pointer, machine-dependent, must be done in emulation for '816 (2)
	TXS				; initialise stack (2)
; *** preset kernel start address (standard label from ROM file) ***
	LDA #<kernel	; get LSB (2)
	STA fw_warm		; store in sysvars (4)
	LDA #>kernel	; same for MSB (2+4)
	STA fw_warm+1
; *** set default CPU type ***
	LDA #CPU_TYPE	; constant from options.h (2)
	STA fw_cpu		; store variable (4)
kernel:
	CLD				; just in case, a must for NMOS, maybe for emulating '816 (2)
;********************************************************************************
;******************** module under testing **************************************
;#include "shell.s"		; here goes the code
;********************************************************************************
	BRK				; ????

; *** minimal kernel support ***
; *** output ***
kow_cout:
	LDA zpar		; get char in case is control
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

; *** input ***
kow_cin:
	LDA IO_BASE+4	; get input from I/O window
	BEQ kow_empty	; nothing available
		STA zpar		; store result otherwise
		_EXIT_OK
kow_empty:
	_ERR(EMPTY)		; nothing yet

; ** open window ***
open_w:
	LDA zpar			; asking for some size?
	ORA zpar+1
	BEQ k8_no_window	; wouldn't do it
		_ERR(NO_RSRC)
k8_no_window:
	LDY #0				; constant default device
	_EXIT_OK

; *** string ***
string:
	LDY #0				; offset
str_loop:
		LDA (zaddr3), Y		; get char
			BEQ str_end			; terminated
		JSR kco_dir			; direct call!
		INY					; next
		BNE str_loop		; no need for BRA
str_end:
	_EXIT_OK

; *** shutdown ***
shutdn:
	LDY #<off			; get shutdown message
	LDA #>off
	STY zaddr3			; set parameter
	STA zaddr3 + 1
	JSR string			; print the string
	JMP panic			; lock the system!

; *** data and tables ***
off:
	.asc 13, "[SHUTDOWN]", 0

fw_table:
	.word	kow_cout	; COUT 0
	.word	kow_cin		; CIN 2
	.word	unimpl		; MALLOC 4
	.word	unimpl		; FREE 6
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
fw_end:

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	kernel_call-*, $FF
#endif

; *** minimOS function call primitive ($FFC0) ***
* = kernel_call
	CPX #fw_end-fw_table	; check against limits
	BCC call_ok				; no overflow
		JMP unimpl				; error otherwise
call_ok:
	_JMPX(fw_table)	; macro for NMOS compatibility (6)

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	admin_call-*, $FF
#endif

; *** administrative meta-kernel call primitive ($FFD0) ***
* = admin_call
	_JMPX(fw_admin)		; takes 6 clocks with CMOS

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

; *** 65C816 ROM vectors ***
* = $FFE4				; should be already at it
	.word	fwp_cold	; native COP		@ $FFE4
	.word	fwp_cold	; native BRK		@ $FFE6
	.word	fwp_cold	; native ABORT		@ $FFE8
	.word	fwp_cold	; native NMI		@ $FFEA
	.word	$FFFF		; reserved			@ $FFEC
	.word	fwp_cold	; native IRQ		@ $FFEE
	.word	$FFFF		; reserved			@ $FFF0
	.word	$FFFF		; reserved			@ $FFF2
	.word	nmi			; emulated COP		@ $FFF4
	.word	$FFFF		; reserved			@ $FFF6
	.word	nmi			; emulated ABORT 	@ $FFF8
; *** 65(C)02 ROM vectors ***
* = $FFFA				; just in case
	.word	nmi			; (emulated) NMI	@ $FFFA
	.word	reset		; (emulated) RST	@ $FFFC
	.word	irq			; (emulated) IRQ	@ $FFFE
