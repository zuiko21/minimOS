; firmware for minimOS on run65816 BBC simulator
; v0.9.6rc3
; (c)2017-2018 Carlos J. Santisteban
; last modified 20180123-1002

#define		FIRMWARE	_FIRMWARE

; in case of standalone assembly
#include "usual.h"

; already set at FW_BASE via rom.s

.(
#ifndef	NOHEAD
; *** first some ROM identification *** new 20150612
; this is expected to be loaded at an aligned address anyway
fw_start:
	.asc	0, "mV****", CR			; standard system file wrapper, new 20160309, flags TBD
	.asc	"boot", 0				; mandatory filename for firmware
fw_splash:
	.asc	"0.9.6 firmware for "
; at least, put machine name as needed by firmware!
fw_mname:
	.asc	MACHINE_NAME, 0

; advance to end of header
	.dsb	fw_start + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$7000	; time, 13.00
	.word	$4AC2	; date, 2017/6/2

fwSize	=	$10000 - fw_start - 256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	fwSize			; filesize
	.word	0				; 64K space does not use upper 16-bit
; *** end of standard header ***
#else
; if no headers, put identifying strings somewhere
fw_splash:
	.asc	"0.9.6 FW @ "
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

; ******************************
; *** minimal hardware setup ***
; ******************************

; check for VIA presence and disable all interrupts
;#include "firmware/modules/viacheck_irq.s"
; simulated 65816 has no real hardware to initialise...

; *** specific 65816 code ***
; as this firmware should be 65816-only, go back to native mode!
#include "firmware/modules/816_check.s"
; it can be assumed 65816 from this point on

; *********************************
; *** optional firmware modules ***
; *********************************

; bootoff seems of little use here...


; might check ROM integrity here
;#include "firmware/modules/romcheck16.s"

; supposedly no ROM-in-RAM feature


; no beep so far on simulation...


; SRAM test
;#include "firmware/modules/memsiz.s"

; ********************************
; *** hardware interrupt setup ***
; ********************************

; nothing to do here...


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

; network booting makes no sense here


; *** direct print splash string ***
#include "firmware/modules/splash.s"

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
; *** administrative functions ***
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

; ***************************
; JIFFY, set jiffy IRQ period
; ***************************
#include "firmware/modules/jiffy_run816.s"

; ****************************************
; IRQ_SRC, investigate source of interrupt
; ****************************************
; notice non-standard ABI, same module as 6502 version!
#include "firmware/modules/irq_src.s"

; *** hardware specific ***

; POWEROFF, poweroff etc
; Y <- mode (0 = suspend, 2 = warmboot, 4 = coldboot, 6 = poweroff)
; C -> not implemented

fw_power:
	PHP					; save sizes eeeeeeeeek
	.as: .xs: SEP #$30	; *** all 8-bit ***
	TYX					; get subfunction offset as index
	JMP (fwp_func, X)	; select from jump table

fwp_off:
	_PANIC("{OFF}")		; just in case is handled
	.byt	$42			; WDM will show up on BBC emulator... and cold boot!

fwp_susp:
	PLP					; restore sizes
	_DR_OK				; just continue execution

; FREQ_GEN, frequency generator hardware interface, TBD
fw_fgen:
; ****** TO BE DONE ******
	_DR_ERR(UNAVAIL)	; not yet implemented

; *** for higher-specced systems ***

; INSTALL, copy jump table
;		INPUT
; kerntab	= address of supplied pointer table

fw_install:
	_CRITIC			; disable interrupts! (5)
	.al: REP #$20		; ** 16-bit memory ** (3)
	.xs: SEP #$10		; ** just in case, 8-bit indexes ** (3)
	LDY #0				; reset index (2)
fwi_loop:
		LDA (kerntab), Y	; get word from table as supplied (6)
		STA @fw_table, Y	; copy where the firmware expects it (6) ***faster if switching DBR but heavier
		INY					; advance two bytes (2+2)
		INY
		CPY #LAST_API		; EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEK
		BCC fwi_loop		; until whole TABLE is done (3/2)***might corrupt fw vars!
; perhaps could do up to LAST_API && %11111110, then check whether extra byte or not outside the loop
	_NO_CRIT			; restore interrupts if needed, will restore size too (4)
	_DR_OK				; all done (8)

; PATCH, patch single function
; kerntab <- address of code
; Y <- function to be patched

fw_patch:
; worth going 16-bit as status was saved, 10b/21c , was 13b/23c
	_CRITIC				; disable interrupts and save sizes! (5)
	.al: REP #$20		; ** 16-bit memory ** (3)
	.xs: SEP #$20		; ** 8-bit indexes, no ABI to set that! **
	LDA kerntab			; get full pointer (4)
	TYX					; no Y-indexed long addressing! (2)
	STA @fw_table, X	; store into firmware, note long addressing (6)
	_NO_CRIT			; restore interrupts and sizes (4)
	_DR_OK				; done (8)

	.as: .xs			; just in case...

; CONTEXT, zeropage & stack bankswitching
fw_ctx:
; ****** TO BE DONE ******
	_DR_ERR(UNAVAIL)	; not yet implemented


; ****************************
; *** some firmware tables ***
; ****************************

; sub-function jump table (eeeek)
fwp_func:
	.word	fwp_susp	; suspend	+FW_STAT
	.word	kernel		; should not use this, just in case
	.word	reset		; coldboot	+FW_COLD
	.word	fwp_off		; poweroff	+FW_OFF

fw_map:
; *** do not know what to do here ***

; *********************************
; *** administrative jump table *** changing
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
	.al: .xl: REP #$30	; status already saved, but save register contents in full (3)
	PHA					; save registers (3x4)
	PHX
	PHY
	PHB					; eeeeeeeeeek (3)
; must use some new indirect jump, as set by new SET_BRK
;	JSR brk_handler		; standard label from IRQ
; ************************************ CONTINUE HERE ***************************
	.al: .xl: REP #$30	; just in case (3)
	PLB					; eeeeeeeeeeeek (4)
	PLY					; restore status and return (3x5)
	PLX
	PLA
	RTI

.as:.xs:				; otherwise might prevent code after ROM!

; *** minimOS·16 kernel call interface (COP) ***
cop_hndl:		; label from vector list
	.as:.xs: SEP #$30	; eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeek
	JMP (fw_table, X)	; the old fashioned way

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	kerncall-*, $FF
#endif

; *** minimOS-65 function call WRAPPER ($FFC0) ***
* = kerncall
	CLC					; pre-clear carry
	COP #$FF			; wrapper on 816 firmware!
	RTS					; return to caller
; *** no longer a wrapper outside bank zero for minimOS·65 ***

; ****** idea for 65816 admin-call interface from apps! ******
; ** could be at $00FFC8 **
;	JSR adm_call		; get into firmware interface (returns via RTS)
;	RTL					; get back into original task (called via JSL $00FFC8)
; ****** likely to end at $00FFCD ******

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	adm_call-*, $FF
#endif

; *** administrative meta-kernel call primitive ($FFD0) ***
* = adm_call
	JMP (fw_admin, X)	; takes 5 clocks

; this could be a good place for the IRQ handler...

; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	lock-*, $FF
#endif


; *** panic routine, locks at very obvious address ($FFE1-$FFE2) ***
* = lock
	NOP					; same address as 6502
panic_loop:
	BRA panic_loop		; OK as this is 65816 only
	NOP					; padding for reserved C816 vectors

.as:.xs

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
	.word	$3412		; reserved			@ $FFF6
	.word	nmi			; emulated ABORT 	@ $FFF8
; *** 65(C)02 ROM vectors ***
* = $FFFA				; just in case
	.word	nmi			; (emulated) NMI	@ $FFFA
	.word	reset		; (emulated) RST	@ $FFFC
	.word	irq			; (emulated) IRQ	@ $FFFE

fw_end:					; for size computation
.)
