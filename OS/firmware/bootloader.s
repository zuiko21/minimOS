; breadboard nanoBoot-loader ROM
; minimal support for minimOS·65
; v0.6b20
; (c)2015-2021 Carlos J. Santisteban
; last modified 20210218-1054

#include "../usual.h"

.(
	.text
	* = $FC00					; minimal 1 KB ROM

#ifndef	NOHEAD
; *************************************
; *** first some ROM identification *** new 20150612
; *************************************
fw_start:
	.asc 0, "m", CPU_TYPE		; standard system file wrapper, new format 20161010, experimental type
	.asc "****", CR				; flags TBD
	.asc "nanoBoot", 0			; standard filename
fw_splash:
	.asc "0.6 nanoBoot loader for "	; machine description as comment
fw_mname:
	.asc	MACHINE_NAME, 0
; advance to end of header (may need extra fields for relocation)
	.dsb	fw_start + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$4BC0				; time, 09.30
	.word	$5251				; date, 2021/2/17

fwSize	=	fw_end - fw_start - 256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	fwSize				; filesize
	.word	0					; 64K space does not use upper 16-bit
; *** end of standard header ***
#endif

; ********************
; ********************
; *** cold restart *** launch nanoBoot, then execute a test counter
; ********************
; ********************

reset:
; place nanoBoot code here:

; **********************************************************
; *** if unsuccessful, how a demo counter on LTC display ***
; **********************************************************
	_STZA nb_ptr+1			; use page pointer as counter
	LDA #244				; actual frequency
	STA nb_ptr				; also interrupt counter
; set up new IRQ handler
	LDY #<cnt_isr			; get pointer
	LDX #>cnt_isr
	STY fw_isr				; store at vector
	STX fw_isr+1
	STX $AFF1				; enable periodic interrupt (irrelevant value as long as the ADDRESS is ODD)
	CLI						; interrupts are on!
count:
		JSR show_pg			; create bitmaps from value
		JSR ltc_up			; quickly update display
		JMP count			; forever

; *************************************
; *** interrupt handler for counter ***
; *************************************
cnt_isr:
	PHA						; take some time, just in case
	DEC nb_ptr				; count number of interrupts
	BNE ci_end				; second not yet complete, exit
; *** will in this case last enough for the IRQ pulse to have ended?
		LDA #244			; reload counter
		STA nb_ptr
		INC nb_ptr+1		; count up a new second
		LDA nb_ptr+1		; check LSN
		AND #15
		CMP #10				; decimal overflow?
		BNE ci_end			; no, finish
			LDA nb_ptr+1	; retrieve full value otherwise
			ADC #5			; yes, advance decade (C was set)
			CMP #$A0		; already at 100?
			BNE ci_upd		; no, just update value
				LDA #0		; yes, reset counter... but change dots?
ci_upd:
			STA nb_ptr+1	; update decade too
ci_end:
	PLA						; restore status
	RTI

; *******************************
; *******************************
; *** *** minimOS support *** ***
; *******************************
; *******************************
panic_loop:
; lock here in case of severe error, displaying 'Er.'
;	.byt	%01110000		; E
	LDA #%01110010
	STA $FFF0				; first digit, first anode
	BNE del1				; slight delay, not using stack!
ret1:
	LDA #%00000001
	STA $FFF0				; first digit, second anode
	BNE del2
ret2:
;	.byt	%01101010		; r.
	LDA #%01101000
	STA $FFF0				; second digit, first anode
	BNE del3
ret3:
	LDA #%10100100
	STA $FFF0				; second digit, second anode
	BNE del4
del4:
	BNE panic_loop
del3:
	BNE ret3
del2:
	BNE ret2
del1:
	BNE ret1

; *** NMOS version needs large ADMIN call back here! ***
#ifndef	FAST_FW
#ifdef	NMOS
nmos_adc:
	_JMPX(fw_admin)		; takes a lot of clocks
#endif
#endif
; ------------ only fixed addresses block remain ------------
; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	kerncall-*, $FF
#endif

; ******************************************************************
; ****** the following will come ALWAYS at standard addresses ****** last 64 bytes
; ******************************************************************

; *** minimOS function call primitive ($FFC0) ***
* = kerncall
#ifndef	FAST_API
	_JMPX(fw_table)		; macro for NMOS compatibility (6) this will be a wrapper on 816 firmware!
#endif






; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	adm_appc-*, $FF	; eeeeeeeeeeeeeeeeeeeek
#endif

; *** administrative meta-kernel call primitive for apps ($FFD0) ***
; not really needed on 6502 systems, but kept for the sake of binary compatibility
; pretty much the same code at $FFDA, not worth more overhead
* = adm_appc
#ifndef	FAST_FW
#ifndef	NMOS
	_JMPX(fw_admin)		; takes 6 clocks with CMOS
#else
	JMP nmos_adc		; needed overhead as takes 10 bytes!
#endif
#endif
; 65816 need to do some extra stuff, but this must check anyway NMOS option, as may not have room enough!

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	adm_call-*, $FF
#endif

; *** administrative meta-kernel call primitive ($FFDA) ***
* = adm_call
#ifndef	FAST_FW
#ifndef	NMOS
	_JMPX(fw_admin)		; takes 6 clocks with CMOS
#else
	JMP nmos_adc		; needed overhead as takes 10 bytes!
#endif
#endif
; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	lock-*, $FF
#endif

; *** panic routine, locks at very obvious address ($FFE2-$FFE3) ***
; may be suited to any particular machine after disabling interrupts
* = lock
	SEI					; reunified procedure 20181101
; *** jump to a suitable lock routine if needed ***
	JMP panic_loop		; will display 'Er' on LTC

* = $FFE4				; should be already at it
#ifdef	SAFE
; *** 65C816 ROM vectors, just in case ***
	.word	nmi			; native COP		@ $FFE4, will debug
	.word	nmi			; native BRK		@ $FFE6, will debug
	.word	aborted		; native ABORT		@ $FFE8
	.word	aborted		; native NMI		@ $FFEA
aborted:
	.word	$FF40		; reserved (nRST)	@ $FFEC holds RTI!
	.word	aborted		; native IRQ		@ $FFEE
	.word	$FFFF		; reserved			@ $FFF0
	.word	$FFFF		; reserved			@ $FFF2
	.word	nmi			; emulated COP		@ $FFF4, not compatible
; must store the BRK handler address!
	.word	brk_hndl	; reserved (eBRK)	@ $FFF6, 65x02 BRK handler entry
	.word	aborted		; emulated ABORT 	@ $FFF8, not supported
#else
#ifdef	ROM
	.dsb	$FFF6-*, $FF
	.word	brk_hndl	; new eBRK			@ $FFF6
	.word	nmi			; emulated ABORT 	@ $FFF8
#endif
#endif
; *** 65(C)02 ROM vectors ***
* = $FFFA				; just in case
	.word	nmi			; NMI	@ $FFFA
	.word	reset		; RST	@ $FFFC
	.word	irq			; IRQ	@ $FFFE
fw_end:					; for size computation
.)
