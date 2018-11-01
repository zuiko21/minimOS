; firmware for minimOS on Jalapa-II
; v0.9.6a24
; (c)2017-2018 Carlos J. Santisteban
; last modified 20181101-1832

#define		FIRMWARE	_FIRMWARE

; in case of standalone assembly
#include "../usual.h"

; *** first some ROM identification *** new 20150612
; this is expected to be loaded at an aligned address anyway
#ifndef	NOHEAD
fw_start:
	.asc	0, "mV****", CR		; standard system file wrapper, new 20160309
	.asc	"boot", 0			; mandatory filename for firmware
fw_splash:
	.asc	"0.9.6a24 firmware for "
; at least, put machine name as needed by firmware!
fw_mname:
	.asc	MACHINE_NAME, 0

; advance to end of header
	.dsb	fw_start + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$4DA0				; time, 09.45
	.word	$4C45				; date, 2018/2/5

fwSize	=	$10000 - fw_start - 256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	fwSize				; filesize
	.word	0					; 64K space does not use upper 16-bit
; *** end of standard header ***
#else
; if case of no headers, at least keep machine name somewhere
fw_splash:
	.asc	"0.9.6a24 FW @ "
fw_mname:
	.asc	MACHINE_NAME, 0
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

; not for LOWRAM systems
	.word	install		; INSTALL copy jump table
	.word	patch		; PATCH patch single function (renumbered)


; **************************
; **************************
; ****** cold restart ******
; **************************
; **************************

	.as:.xs				; to be sure!

reset:
; *** basic init ***
#include "modules/basic_init16.s"

; ******************************
; *** minimal hardware setup ***
; ******************************

; check for VIA presence and disable all interrupts
#include "modules/viacheck_irq.s"

; *** specific 65816 code ***
; as this firmware should be 65816-only, go back to native mode!
#include "modules/816_check.s"
; it can be assumed 65816 from this point on

; *********************************
; *** optional firmware modules ***
; *********************************

; optional boot selector
;#include "modules/bootoff.s"

; might check ROM integrity here
;#include "modules/romcheck16.s"

; Jalapa is intended NOT to have ROM-in-RAM feature


; startup beep, droplet style
#include "modules/droplet.s"	; specific Jalapa sound, not sure if I will be able to run it asynchronously

; SRAM test, MUST probe for RAM size, anyway... and skip the ROM
#include "modules/memsiz.s"

; ********************************
; *** hardware interrupt setup ***
; ********************************

; VIA initialisation (and stop beeping)
#include "modules/via_init.s"

; ***********************************
; *** firmware parameter settings ***
; ***********************************

; *** set default CPU type ***
#include "modules/default_816.s"
; as this is the only valid CPU for this firmware, no further checking necessary

; perhaps could wait until here to look for an actual 65816...

; *** continue parameter setting, worth switching to 16-bit memory while setting pointers ***
	.al: REP #$20

; preset kernel start address
#include "modules/kern_addr16.s"

; preset default BRK handler
#include "modules/brk_addr16.s"

; no need to set NMI as it will be validated


; preset jiffy irq frequency
#include "modules/jiffy_hz16.s"

; reset jiffy count
#include "modules/jiffy_rst16.s"

; reset last installed kernel (new)
#include "modules/rst_lastk16.s"

; *** back to 8-bit memory ***
	.as: SEP #$20

; *** optional network booting ***
; might modify the contents of fw_warm
;#include "modules/netboot.s"

; *** NO direct print splash string ***

; ************************
; *** start the kernel ***
; ************************
start_kernel:
#include "modules/start16.s"

; ********************************
; ********************************
; ****** interrupt handlers ******
; ********************************
; ********************************

; **********************************************
; *** vectored NMI handler with magic number ***
; **********************************************
nmi:
#include "modules/nmi_hndl16.s"

; ****************************
; *** vectored IRQ handler ***
; ****************************
; nice to be here, but might go elsewhere in order to save space, like between FW interface calls
irq:
#include "modules/irq_hndl16.s"

; ****************************
; *** vectored BRK handler ***
; ****************************
brk_hndl:
#include "modules/brk_hndl16.s"

; ******************************************************
; *** minimOS·16 kernel call interface (COP handler) ***
; ******************************************************
cop_hndl:		; label from vector list
#include "modules/cop_hndl.s"


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
#include "modules/gestalt16.s"

; ***********************
; SET_ISR, set IRQ vector
; ***********************
set_isr:
#include "modules/set_isr16.s"

; ********************************
; SET_NMI, set NMI handler routine
; ********************************
set_nmi:
#include "modules/set_nmi16.s"

; ********************************
; SET_DBG, set BRK handler routine
; ********************************
set_dbg:
#include "modules/set_dbg16.s"

; *** interrupt related ***

; ***************************
; JIFFY, set jiffy IRQ period
; ***************************
jiffy:
#include "modules/jiffy16.s"

; ****************************************
; IRQ_SRC, investigate source of interrupt
; ****************************************
; notice non-standard ABI, same module as 6502 version!
irq_src:
#include "modules/irq_src.s"

; *** hardware specific ***

; *****************************************
; POWEROFF, resets and interrupt invocation
; *****************************************
poweroff:
#include "modules/poweroff16.s"

; ***********************************
; FREQ_GEN, generate frequency at PB7 *** TBD
; ***********************************
freq_gen:
;#include "modules/freq_gen16.s"
	_DR_ERR(UNAVAIL)	; not yet implemented

; *** other functions with RAM enough ***

; **************************
; INSTALL, supply jump table
; **************************
install:
#include "modules/install16.s"

; ****************************
; PATCH, patch single function
; ****************************
patch:
#include "modules/patch16.s"


; ***********************************
; ***********************************
; *** some firmware odds and ends ***
; ***********************************
; ***********************************

; *** memory map, as used by gestalt, not sure what to do with it ***
fw_map:					; TO BE DONE

; *************************************
; new lock routine blinking E-mode LED!
; *************************************
led_lock:
	CLC					; ensure native mode...
	XCE					; ...for a moment
	SEC					; will start in Emulation with C clear
led_switch:
		XCE					; switch between native and emulation mode
		LDA #4				; suitable delay
led_loop:
					INX
					BNE led_loop
				INY
				BNE led_loop
			DEC
			BNE led_loop
		BRA led_switch


; ------------ only fixed addresses block remain ------------
; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	kerncall-*, $FF
#endif

; ******************************************************************
; ****** the following will come ALWAYS at standard addresses ****** last 64 bytes
; ******************************************************************

; *** minimOS-65 function call WRAPPER ($FFC0) ***
* = kerncall
	CLC					; must be here!
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

; *** administrative meta-kernel call primitive for apps ($FFD0) ***
* = adm_appc
	PHB					; could came from any bank
	PHK					; zero is...
	PLB					; ...current bank
	JSR (fw_admin, X)	; return here (DR_OK form)
	PLB					; restore bank...
	RTL					; ...and return from long address!
; *** above code takes -8- bytes, thus no room for padding! ***
; filling for ready-to-blow ROM
;#ifdef		ROM
;	.dsb	adm_call-*, $FF
;#endif

; *** administrative meta-kernel call primitive ($FFD8) ***
* = adm_call
	JMP (fw_admin, X)	; takes 5 cycles

; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	lock-*, $FF
#endif

; *** panic routine, this one will make Emulation LED blink ***
* = lock
	JMP led_lock		; specific call, may be far away
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
