; breadboard nanoBoot-loader ROM
; minimal support for minimOS·65
; v0.6b21
; (c)2015-2021 Carlos J. Santisteban
; last modified 20210225-1153

#define	TIMEBOOT	_TIMEBOOT
#define	DISPLAY		_DISPLAY
#define	NBEXTRA		_NBEXTRA
#define	ROM			_ROM

; headers intended to be assembled from /OS like the following line
; xa firmware/bootloader.s -I firmware

#include "../options.h"
#include "../macros.h"
#include "../abi.h"
#include "../../forge/nanoboot/nanoboot.h"
#include "../zeropage.h"

	.bss:
	* =	$200					; standard FW variables start

#include "template.h"
; takes standard FW variables, already nanoBoot-savvy

	-fw_admin=$4003				; *** new stardard address for downloadable FWs ***

.(
	.text
#ifdef	NOHEAD
	* = $FE00					; minimal 0.5K if NOHEAD option
#else
	* = $FC00					; minimal 1 KB ROM with headers
; *************************************
; *** first some ROM identification *** new 20150612
; *************************************
nl_start:
	.asc 0, "m", CPU_TYPE		; standard system file wrapper, new format 20161010, experimental type
	.asc "****", CR				; flags TBD
	.asc "nanoBoot", 0			; standard filename
nl_splash:
	.asc "0.6 nanoBoot loader for "	; machine description as comment
nl_mname:
	.asc	MACHINE_NAME, 0
; advance to end of header (may need extra fields for relocation)
	.dsb	nl_start + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$4BC0				; time, 09.30
	.word	$5251				; date, 2021/2/17


nlSize	=	nl_end - nl_start - 256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	nlSize				; filesize
	.word	0					; 64K space does not use upper 16-bit
; *** end of standard header ***
#endif

; *** auxiliary stuff for nanoBoot ***
#include "../../forge/nanoboot/nmi.s"
#include "../../forge/nanoboot/isr.s"

; ********************
; ********************
; *** cold restart *** launch nanoBoot, then execute a test counter
; ********************
; ********************

; *** actual RST entry point ***
reset:
	SEI						; basic 6502 init, worth it now
	CLD
	LDX #$FF				; theoretically not needed, but...
	TXS

; place nanoBoot init code here, then alternative:
#include "../../forge/nanoboot/init.s"

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
		LDA nb_disp+3		; get second digit...
		AND #%11101111		; ...and set decimal point
		STA nb_disp+3
		JSR ltc_up			; quickly update display
		JMP count			; forever

; *************************************
; *** interrupt handler for counter ***
; *************************************
cnt_isr:
	PHA						; take some time, just in case
	SED						; best done in decimal
	DEC nb_ptr				; count number of interrupts
	BNE ci_end				; second not yet complete, exit
; *** will in this case last enough for the IRQ pulse to have ended?
		LDA #244			; reload counter
		STA nb_ptr
		LDA nb_ptr+1		; will increment display counter
		CLC
		ADC #1				; one more second
		CMP #$60			; full minute?
		BNE ci_upd			; no, just update value
			LDA #0			; yes, reset counter... but change dots?
ci_upd:
		STA nb_ptr+1		; update decade too
ci_end:
	PLA						; restore status
	RTI

; ******************************************
; *** simple hardware interrupt handlers ***
; ******************************************
irq:
	JMP (fw_isr)
nmi:
	JMP (fw_nmi)			; unfortunately, no longer safe
brk_hndl:
	JSR brk_call			; indirect jump will return here
	RTI						; *** should jum to some end-of-handler
; as no indirect call is available, call here and return to handler
brk_call:
	JMP (fw_dbg)		; will return

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
	LDA #%00000001
	STA $FFF0				; first digit, second anode
;	.byt	%11101010		; r.
	LDA #%11101000
	STA $FFF0				; second digit, first anode
	LDA #%10100100
	STA $FFF0				; second digit, second anode
	BNE panic_loop			; no longer using delays, not worth it

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
	JMP panic_loop		; will display 'Er.' on LTC

;* = $FFE4				; should be already at it
#ifdef	ROM
	.dsb	$FFF6-*, $FF
	.word	brk_hndl	; new eBRK			@ $FFF6
	.word	nmi			; emulated ABORT 	@ $FFF8
#endif
; *** 65(C)02 ROM vectors ***
* = $FFFA				; just in case
	.word	nmi			; NMI	@ $FFFA
	.word	reset		; RST	@ $FFFC
	.word	irq			; IRQ	@ $FFFE
nl_end:					; for size computation
.)
