; firmware for minimOS on Jalapa-II
; v0.9.6a21
; (c)2017-2018 Carlos J. Santisteban
; last modified 20180124-0837

#define		FIRMWARE	_FIRMWARE

; in case of standalone assembly
#include "usual.h"

; *** first some ROM identification *** new 20150612
; this is expected to be loaded at an aligned address anyway
#ifndef	NOHEAD
fw_start:
	.asc	0, "mV****", CR			; standard system file wrapper, new 20160309
	.asc	"boot", 0				; mandatory filename for firmware
fw_splash:
	.asc	"0.9.6a21 firmware for "
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
; if case of no headers, at least keep machine name somewhere
fw_splash:
	.asc	"0.9.6a21 FW @ "
fw_mname:
	.asc	MACHINE_NAME, 0
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

; Jalapa is intended NOT to have ROM-in-RAM feature


; startup beep, droplet style
#include "firmware/modules/droplet.s"	; specific Jalapa sound, not sure if I will be able to run it asynchronously

; SRAM test, MUST probe for RAM size, anyway... and skip the ROM
#include "firmware/modules/memsiz.s"

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

; *** NO direct print splash string ***

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
; POWEROFF, poweroff etc
; **********************
;	INPUT
; Y <- mode (0 = suspend, 2 = warmboot, 4 = coldboot, 6 = poweroff, 8 = NMI, 10 = BRK)
;	OUTPUT
; C -> not implemented
; this must be further modularised

poweroff:
	_CRITIC				; save sizes eeeeeeeeek
	.as: .xs: SEP #$30	; *** all 8-bit ***
	TYX					; get subfunction offset as index
	JMP (fwp_func, X)	; select from jump table
fwp_off:
; include here shutdown code
	STP					; $DB in case a WDC CPU is used
	_PANIC("{OFF}")		; just in case is handled
fwp_susp:
; first shut off interrupts!
	LDA VIA_J + IER		; get current interrupt sources
	PHA					; save for later (with bit 7 high)
	AND #$7F			; turn bit 7 low
	STA VIA_J + IER		; this will disable every enabled interrupt source
; in case a WDC CPU is used, apply SEI/WAI sequence (SEI already done)
	WAI					; $CB, wait for some interrupt
; *** system expected to be suspended here ***
; after waking up, reenable interrupt sources!
	PLA					; get saved config (with bit 7 high)
	STA VIA_J + IER		; this will enable every previously set interrupt source
; this is also the exit for software interrupt simulation
fwp_end:
	_NO_CRIT			; restore sizes
	_DR_OK				; just continue execution
; software interrupt calls
fwp_nmi:
	PHK					; always in bank 0
	PEA fwp_end			; push correct return
	PHP					; will end in RTI
	JMP nmi				; handle as usual
fwp_brk:
	PHK					; always in bank 0
	PEA fwp_end			; push correct return
	PHP					; will end in RTI
	JMP brk_hndl		; handle as usual

; sub-function jump table (eeeek)
fwp_func:
	.word	fwp_susp	; suspend	+FW_STAT
	.word	kernel		; should not use this, just in case
	.word	reset		; coldboot	+FW_COLD
	.word	fwp_off		; poweroff	+FW_OFF
; might include here the BRK/NMI invocation codes
	.word	fwp_nmi		; PW_CLEAN not allowed here!
	.word	fwp_nmi		; simulate NMI
	.word	fwp_brk		; execute BRK, not sure if needed


; FREQ_GEN, frequency generator hardware interface, TBD
freq_gen:
; ****** TO BE DONE ******
	_DR_ERR(UNAVAIL)	; not yet implemented

; *** for higher-specced systems ***

; INSTALL, copy jump table
;		INPUT
; kerntab	= address of supplied pointer table

install:
	_CRITIC				; disable interrupts! (5)
	.al: REP #$20		; ** 16-bit memory ** (3)
	.xs: SEP #$10		; ** just in case, 8-bit indexes ** (3)
	LDY #0				; reset index (2)
fwi_loop:
		LDA (kerntab), Y	; get word from table as supplied (6)
		STA @fw_table, Y	; copy where the firmware expects it (6) ***faster if switching DBR but heavier
		INY					; advance two bytes (2+2)
		INY
		BNE fwi_loop		; until whole page is done (3/2)
	_NO_CRIT			; restore interrupts if needed, will restore size too (4)
	_DR_OK				; all done (8)

; PATCH, patch single function
; kerntab <- address of code
; Y <- function to be patched

patch:
; worth going 16-bit as status was saved, 10b/21c , was 13b/23c
	_ENTER_CS				; disable interrupts and save sizes! (5)
	.al: REP #$20			; ** 16-bit memory ** (3)
	.xs: SEP #$20			; ** 8-bit indexes, no ABI to set that! **
	LDA kerntab				; get full pointer (4)
	TYX						; no Y-indexed long addressing! (2)
	STA @fw_table, X		; store into firmware, note long addressing (6)
	_EXIT_CS				; restore interrupts and sizes (4)
	_DR_OK					; done (8)

	.as: .xs				; just in case...

; CONTEXT, zeropage & stack bankswitching
context:
; ****** TO BE DONE ****** not on unexpanded Jalapa
	_DR_ERR(UNAVAIL)	; not yet implemented, Jalapa does not use it


; ****************************
; *** some firmware tables ***
; ****************************



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
	.word	poweroff	; POWEROFF power-off, suspend or cold boot
	.word	freq_gen	; *** FREQ_GEN frequency generator hardware interface, TBD

; not for LOWRAM systems
	.word	install		; INSTALL copy jump table
	.word	patch		; PATCH patch single function (renumbered)
	.word	context		; *** CONTEXT context bankswitching

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
brk_call:
	JMP [fw_brk]		; will return

.as:.xs:				; otherwise might prevent code after ROM!


; *** minimOS·16 kernel call interface (COP) ***
cop_hndl:		; label from vector list
	.as: .xs: SEP #$30		; default sizes!
	JMP (fw_table, X)		; the old fashioned way

; *************************************
; new lock routine blinking E-mode LED!
; *************************************
led_lock:
	CLC			; ensure native mode...
	XCE			; ...for a moment
	SEC			; will start in Emulation with C clear
led_switch:
		XCE			; switch between native and emulation mode
		LDA #4			; suitable delay
led_loop:
					INX
					BNE led_loop
				INY
				BNE led_loop
			DEC
			BNE led_loop
		BRA led_switch


; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	kerncall-*, $FF
#endif

; ******************************************************************
; ****** the following will come ALWAYS at standard addresses ****** last 64 bytes
; ******************************************************************

; *** minimOS-65 function call WRAPPER ($FFC0) ***
* = kerncall
	CLC				; must be here!
	COP #$7F			; wrapper on 816 firmware, will do CLC!
	RTS					; return to caller
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
	JMP (fw_admin, X)		; takes 5 clocks

; this could be a good place for the IRQ handler...

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
	SEI					; same address as 6502
panic_loop:
	BRA led_lock		; OK as this is 65816 only
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
