; more-or-less generic firmware for minimOS·16
; v0.6a7
; (c)2015-2018 Carlos J. Santisteban
; last modified 20180131-0837

#define		FIRMWARE	_FIRMWARE
#include "usual.h"
; already set at FW_BASE via rom.s

.(
#ifndef	NOHEAD
; *************************************
; *** first some ROM identification *** new 20150612
; *************************************
; this is expected to be loaded at an aligned address anyway
fw_start:
	.asc 0, "mV", 13					; standard system file wrapper, new 20161010, experimental type
	.asc "****", CR						; flags TBD eeeeeeeeeeeeeeeeeeeeeeeeeek
	.asc "boot", 0						; standard filename
fw_splash:
	.asc "65816 0.6a7 firmware for "	; machine description as comment
fw_mname:
	.asc	MACHINE_NAME, 0
; advance to end of header
	.dsb	fw_start + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$7000	; time, 13.00
	.word	$4AC2	; date, 2017/6/2

fwSize	=	fw_end - fw_start - 256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	fwSize			; filesize
	.word	0				; 64K space does not use upper 16-bit
; *** end of standard header ***
#else
; if no headers, put identifying strings somewhere
fw_splash:
	.asc	"0.6a7 FW @ "
fw_mname:
	.asc	MACHINE_NAME, 0		; store the name at least
#endif

; *********************************
; *********************************
; *** administrative jump table *** changing
; *********************************
; *********************************
fw_admin:
; generic functions, esp. interrupt related
	.word	gestalt		; GESTALT get system info (renumbered)
	.word	set_isr		; SET_ISR set IRQ vector
	.word	set_nmi		; SET_NMI set (magic preceded) NMI routine
	.word	set_dbg		; SET_DBG set debugger, new 20170517
	.word	jiffy		; JIFFY set jiffy IRQ speed
	.word	irq_src		; IRQ_SOURCE get interrupt source in X for total ISR independence

; pretty hardware specific
	.word	poweroff	; POWEROFF power-off, suspend or cold boot
	.word	freq_gen	; *** FREQ_GEN frequency generator hardware interface, TBD

; 65816 systems are always highly-specced...
	.word	install		; INSTALL copy jump table
	.word	patch		; PATCH patch single function (renumbered)
	.word	context		; *** CONTEXT context bankswitching


; **************************
; **************************
; ****** cold restart ******
; **************************
; **************************

	.as:.xs				; to be sure!

reset:
; *** basic init ***
#include "firmware/modules/basic_init16.s"

; ******************************
; *** minimal hardware setup ***
; ******************************

; check for VIA presence and disable all interrupts
#include "firmware/modules/viacheck_irq.s"

; *** specific 65816 code ***
; as this firmware should be 65816-only, go back to native mode!
#include "firmware/modules/816_check.s"
; it can be assumed 65816 from this point on

; *********************************
; *** optional firmware modules ***
; *********************************

; optional boot selector
;#include "firmware/modules/bootoff.s"

; might check ROM integrity here
;#include "firmware/modules/romcheck16.s"

; some systems might copy ROM-in-RAM and continue at faster speed!
;#include "firmware/modules/rominram16.s"

; startup beep
#include "firmware/modules/beep16.s"	; typical 816 standard beep

; SRAM test
#include "firmware/modules/memsiz.s"	; *** must support 24-bit addressing!!!

; ********************************
; *** hardware interrupt setup ***
; ********************************

; VIA initialisation (and stop beeping)
#include "firmware/modules/via_init.s"

; ***********************************
; *** firmware parameter settings ***
; ***********************************

; *** set default CPU type *** (not worth a separate file?)
	LDA #'V'			; 65816 only (2)
	STA fw_cpu			; store variable (4)

; as this is the only valid CPU for this firmware, no further checking necessary

; perhaps could wait until here to look for an actual 65816...

; *** continue parameter setting, worth switching to 16-bit memory while setting pointers ***
	.al: REP #$20

; preset kernel start address
#include "firmware/modules/kern_addr16.s"

; preset default BRK handler
#include "firmware/modules/brk_addr16.s"

; no need to set NMI as it will be validated


; preset jiffy irq frequency
#include "firmware/modules/jiffy_hz16.s"

; reset jiffy count
#include "firmware/modules/jiffy_rst16.s"

; reset last installed kernel (new)
#include "firmware/modules/rst_lastk16.s"

; *** back to 8-bit memory ***
	.as: SEP #$20

; *** optional network booting ***
; might modify the contents of fw_warm
;#include "firmware/modules/netboot.s"

; *** direct print splash string code comes here, when available ***

; ************************
; *** start the kernel ***
; ************************
start_kernel:
#include "firmware/modules/start16.s"


; ********************************
; ********************************
; ****** interrupt handlers ******
; ********************************
; ********************************

; **********************************************
; *** vectored NMI handler with magic number ***
; **********************************************
nmi:
#include "firmware/modules/nmi_hndl16.s"

; ****************************
; *** vectored IRQ handler ***
; ****************************
; nice to be here, but might go elsewhere in order to save space, like between FW interface calls
irq:
	JMP [fw_isr]	; 24-bit vectored ISR (6)

; ****************************
; *** vectored BRK handler ***
; ****************************
brk_hndl:
#include "firmware/modules/brk_hndl16.s"


; ********************************
; ********************************
; *** administrative functions ***
; ********************************
; ********************************

; *** generic functions ***

; *********************************
; GESTALT, get system info, API TBD
; *********************************
gestalt:
#include "firmware/modules/gestalt16.s"

; ***********************
; SET_ISR, set IRQ vector
; ***********************
set_isr:
#include "firmware/modules/set_isr16.s"

; ********************************
; SET_NMI, set NMI handler routine
; ********************************
set_nmi:
#include "firmware/modules/set_nmi16.s"

; ********************************
; SET_DBG, set BRK handler routine
; ********************************
set_dbg:
#include "firmware/modules/set_dbg16.s"

; ***************************
; JIFFY, set jiffy IRQ period
; ***************************
jiffy:
#include "firmware/modules/jiffy16.s"

; ****************************************
; IRQ_SRC, investigate source of interrupt
; ****************************************
; notice non-standard ABI, same module as 6502 version!
irq_src:
#include "firmware/modules/irq_src.s"

; *** hardware specific ***

; **********************
; POWEROFF, shutdown etc *** TBD
; **********************
poweroff:
#include "firmware/modules/poweroff16.s"

; ***********************************
; FREQ_GEN, generate frequency at PB7 *** TBD
; ***********************************
freq_gen:
;#include "firmware/modules/freq_gen16.s"
	_DR_ERR(UNAVAIL)	; not yet implemented

; *** other functions with RAM enough ***

; **************************
; INSTALL, supply jump table
; **************************
install:
#include "firmware/modules/install16.s"

; ****************************
; PATCH, patch single function
; ****************************
patch:
#include "firmware/modules/patch16.s"

; *****************************************
; CONTEXT, hardware switch zeropage & stack
; *****************************************
context:
;#include "firmware/modules/context16.s"
	_DR_ERR(UNAVAIL)	; not yet implemented


; ****************************
; *** some firmware tables ***
; ****************************

fw_map:
; *** do not know what to do here ***

; these already OK for 65816!

; *** minimOS·16 kernel call interface (COP) ***
cop_hndl:		; label from vector list
	.as: .xs: SEP #$30	; standard sizes
	JMP (fw_table, X)	; the old fashioned way (this takes 5 bytes)

; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	kerncall-*, $FF
#endif

; ******************************************************************
; ****** the following will come ALWAYS at standard addresses ****** last 64 bytes
; ******************************************************************

; *** minimOS·65 function call WRAPPER ($FFC0) ***
* = kerncall
	CLC			; pre-clear carry
	COP #$7F	; wrapper on 816 firmware!
	RTS			; return to caller (this takes 4 bytes)
; *** no longer a wrapper outside bank zero for minimOS·65 ***
; alternative multikernel FW may use an indirect jump...
; ...will point to either the above wrapper (16-bit kernel)...
; ...or the usual indirect-indexed jump (8-bit)...
; ...without pre-CLC or size setting!

; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	adm_call-*, $FF
#endif

; *** administrative meta-kernel call primitive ($FFD0) ***
* = adm_call
	JMP (fw_admin, X)		; takes 5 clocks and 3 bytes, kernel/drivers only!

; this could be a good place for the IRQ handler...

; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	adm_appc-*, $FF	; eeeeeeeeeeeeeeeeeeeek
#endif

; *** administrative meta-kernel call primitive for apps ($FFD8) ***
* = adm_appc
	PHB						; could came from any bank
	PHK						; zero is...
	PLB						; ...current bank
	JSR (fw_admin, X)		; return here (DR_OK form)
	PLB						; restore bank...
	RTL						; ...and return from long address!

; *** above code takes -8- bytes, thus no room for padding! ***
; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	lock-*, $FF
#endif

; *** panic routine, locks at very obvious address ($FFE1-$FFE2) ***
* = lock
	SEC					; unified procedure 20150410, was CLV
panic_loop:
	BCS panic_loop		; no problem if /SO is used, new 20150410, was BVC
	NOP					; padding for reserved C816 vectors

; *** 65C816 ROM vectors ***
* = $FFE4				; should be already at it
	.word	cop_hndl	; native COP		@ $FFE4
	.word	brk_hndl	; native BRK		@ $FFE6, call standard label from IRQ
	.word	nmi			; native ABORT		@ $FFE8, not yet supported
	.word	nmi			; native NMI		@ $FFEA, unified this far
	.word	$FFFF		; reserved			@ $FFEC
	.word	irq			; native IRQ		@ $FFEE, unified this far
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

fw_end:					; for size computation
.)
