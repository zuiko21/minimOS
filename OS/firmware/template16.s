; more-or-less generic firmware for minimOS·16
; v0.6a6
; (c)2015-2018 Carlos J. Santisteban
; last modified 20180122-1031

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
	.asc "65816 0.6a6 firmware for "	; machine description as comment
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
	.asc	"0.6a6 FW @ "
fw_mname:
	.asc	MACHINE_NAME, 0		; store the name at least
#endif

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
;#include "firmware/modules/rominram.s"

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


; ********************************
; ********************************
; *** administrative functions ***
; ********************************
; ********************************

; *** generic functions ***

; *********************************
; GESTALT, get system info, API TBD
; *********************************
#include "firmware/modules/gestalt16.s"

; ***********************
; SET_ISR, set IRQ vector
; ***********************
#include "firmware/modules/set_isr16.s"

; ********************************
; SET_NMI, set NMI handler routine
; ********************************
#include "firmware/modules/set_nmi16.s"

; ********************************
; SET_DBG, set BRK handler routine
; ********************************
#include "firmware/modules/set_dbg16.s"


; -------------------- old code ----------------------
; *** administrative functions ***
; A0, install jump table
; kerntab <- address of supplied jump table
fw_install:
	LDY #0				; reset index (2)
	_ENTER_CS			; disable interrupts! (5)
	.al: REP #$20		; ** 16-bit memory ** (3)
fwi_loop:
		LDA (kerntab), Y	; get word from table as supplied (6)
		STA fw_table, Y		; copy where the firmware expects it (5)
		INY					; advance two bytes (2+2)
		INY
		BNE fwi_loop		; until whole page is done (3/2)
	_EXIT_CS			; restore interrupts if needed, will restore size too (4)
	_DR_OK				; all done (8)





; A6, patch single function
; kerntab <- address of code
; Y <- function to be patched
fw_patch:
#ifdef		LOWRAM
	_DR_ERR(UNAVAIL)		; no way to patch on 128-byte systems
#else
; worth going 16-bit as status was saved, 10b/21c , was 13b/23c
	_ENTER_CS				; disable interrupts and save sizes! (5)
	.al: REP #$20			; ** 16-bit memory ** (3)
	LDA kerntab				; get full pointer (4)
	STA fw_table, Y			; store into firmware (5)
	_EXIT_CS				; restore interrupts and sizes (4)
	_DR_OK					; done (8)
#endif


; A10, poweroff etc
; Y <- mode (0 = poweroff, 2 = suspend, 4 = coldboot, 6 = warm?)
; C -> not implemented
fw_power:
	TYX					; get subfunction offset as index
	JMP (fwp_func, X)	; select from jump table

fwp_off:	; ******** CONTINUE HERE ********* CONTINUE HERE *********
#include "firmware/modules/poweroff.s"

fwp_susp:
#include "firmware/modules/suspend.s"

fwp_cold:
	JMP ($FFFC)			; call 6502 vector, as firmware start will initialize as needed

; sub-function jump table
fwp_func:
	.word	fwp_off		; poweroff	+FW_OFF
	.word	fwp_susp	; suspend	+FW_STAT
	.word	fwp_cold	; coldboot	+FW_COLD
	.word	kernel		; shouldn't use this, just in case

; *********************************
; *** administrative jump table *** changing
; *********************************
fw_admin:
; generic functions, esp. interrupt related
	.word	gestalt		; GESTALT get system info (renumbered)
	.word	set_isr		; SET_ISR set IRQ vector
	.word	set_nmi		; SET_NMI set (magic preceded) NMI routine
	.word	set_dbg		; SET_DBG set debugger, new 20170517

	.word	fw_jiffy	; *** JIFFY set jiffy IRQ speed, ** TBD **
	.word	fw_i_src	; *** IRQ_SOURCE get interrupt source in X for total ISR independence

; pretty hardware specific
	.word	fw_power	; POWEROFF power-off, suspend or cold boot
	.word	fw_fgen		; *** FREQ_GEN frequency generator hardware interface, TBD

; not for LOWRAM systems
	.word	fw_install	; INSTALL copy jump table
	.word	fw_patch	; PATCH patch single function (renumbered)
	.word	fw_ctx		; *** CONTEXT context bankswitching

; these already OK for 65816!
; *** minimOS·16 BRK handler *** might go elsewhere
brk_hndl:		; label from vector list
; much like the ISR start
	.al: .xl: REP #$38	; status already saved, but save register contents in full, decimal off just in case (3)
	PHA					; save registers (3x4)
	PHX
	PHY
	PHB					; eeeeeeeeeek (3)
; make sure we work on bank zero eeeeeeeeek
	PHK					; stack a 0...
	PLB					; ...for data bank
; in case an unaware 6502 app installs a handler ending in RTS,
; stack imbalance will happen, best keep SP and compare afterwards
#ifdef	SUPPORT
	.xs: SEP #$10		; *** back to 8-bit indexes ***
	TSX					; get stack pointer LSB
	STX sys_sp			; best place as will not switch
	.as: SEP #$20		; now all in 8-bit
#else
	.as: .xs: SEP #$30	; all 8-bit
#endif
; must use some new indirect jump, as set by new SET_BRK
; arrives in 8-bit, DBR=0 (no need to save it)
	JSR @brk_call		; JSL new indirect
; 6502 handlers will end in RTS causing stack imbalance
; must reset SP to previous value
#ifdef	SUPPORT
	.as: SEP #$20		; ** 8-bit memory for a moment **
	TSC					; the whole stack pointer, will not mess with B
	LDA sys_sp			; will replace the LSB with the stored value
	TCS					; all set!
#endif
; restore full status and exit
	.al: .xl: REP #$30	; just in case (3)
	PLB					; eeeeeeeeeeeek (4)
	PLY					; restore status and return (3x5)
	PLX
	PLA
	RTI
; as no long-indirect call is available, long-call here and return to handler
brk_call:
	JMP [fw_brk]		; will return

.as:.xs:				; otherwise might prevent code after ROM!

; *** minimOS·16 kernel call interface (COP) ***
cop_hndl:		; label from vector list
	.as: .xs: SEP #$30	; standard sizes
	JMP (fw_table, X)	; the old fashioned way (this takes 5 bytes)

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	kernel_call-*, $FF
#endif

; ******************************************************************
; ****** the following will come ALWAYS at standard addresses ****** last 64 bytes
; ******************************************************************

; *** minimOS·65 function call WRAPPER ($FFC0) ***
* = kerncall
	CLC			; pre-clear carry
	COP $7F		; wrapper on 816 firmware!
	RTS			; return to caller (this takes 4 bytes)
; *** no longer a wrapper outside bank zero for minimOS·65 ***
; alternative multikernel FW may use an indirect jump...
; ...will point to either the above wrapper (16-bit kernel)...
; ...or the usual indirect-indexed jump (8-bit)...
; ...without pre-CLC or size setting!

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	adm_call-*, $FF
#endif

; *** administrative meta-kernel call primitive ($FFD0) ***
* = adm_call
	JMP (fw_admin, X)		; takes 5 clocks and 3 bytes, kernel/drivers only!


; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	adm_call-*, $FF
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
;#ifdef	ROM
;	.dsb	lock-*, $FF
;#endif

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
