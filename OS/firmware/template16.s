; more-or-less generic firmware for minimOS·16
; v0.6b15
; (c) 2015-2020 Carlos J. Santisteban
; last modified 20200805-1138

#define		FIRMWARE	_FIRMWARE
#include "../usual.h"
; already set at FW_BASE via rom.s

.(
#ifndef	NOHEAD
; *************************************
; *** first some ROM identification *** new 20150612
; *************************************
; this is expected to be loaded at an aligned address anyway
fw_start:
	.asc 0, "mV"				; standard system file wrapper, new 20161010, experimental type
	.asc "****", CR				; flags TBD eeeeeeeeeeeeeeeeeeeeeeeeeek
	.asc "boot", 0				; standard filename
fw_splash:
	.asc "65816 v0.6 firmware for "	; machine description as comment
fw_mname:
	.asc	MACHINE_NAME, 0
; advance to end of header (may need extra fields for relocation)
	.dsb	fw_start + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$6800				; time, 13.00
	.word	$4E44				; date, 2019/2/4

fwSize	=	fw_end - fw_start - 256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	fwSize				; filesize
	.word	0					; 64K space does not use upper 16-bit
; *** end of standard header ***
#else
; if no headers, put identifying strings somewhere
fw_splash:
	.asc	"0.6 FW @ "
fw_mname:
	.asc	MACHINE_NAME, 0		; store the name at least
#endif

; *** new, make a cold proper reboot if executed ***
	LDY #PW_COLD		; select cold reboot
	_KERNEL(SHUTDOWN)
fw_boot:
	CLI					; make sure iterrupts are enabled...
	BRA fw_boot			; ...and keep waiting for whole system shutdown

; *********************************
; *********************************
; *** administrative jump table *** changing
; *********************************
; *********************************
fw_admin:
#ifndef		FAST_FW
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
	.word	reloc		; RELOCate code and data (TBD)
	.word	conio		; CONIO, basic console when available
#endif


; some room for unimplemented functions
#ifdef	SAFE
missing:
		_DR_ERR(UNAVAIL)	; return some error while trying to install or patch!
#endif

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
; specific 65816 code *** as this firmware should be 65816-only, this will go back to native mode!
#include "modules/816_check.s"
; check for VIA presence and disable all interrupts
#include "modules/viacheck_irq.s"

; *********************************
; *** optional firmware modules ***
; *********************************

; optional boot selector
;#include "modules/bootoff.s"

; might check ROM integrity here
;#include "modules/romcheck16.s"

; some systems might copy ROM-in-RAM and continue at faster speed!
;#include "modules/rominram16.s"

; startup beep
#include "modules/beep16.s"	; typical 816 standard beep

; SRAM test
#include "modules/memsiz.s"	; *** must support 24-bit addressing!!!

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

; as this is the only valid CPU for this firmware, no actual checking necessary




; *** *** continue parameter setting, worth switching to 16-bit memory while setting pointers *** ***
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

; *** *** back to 8-bit memory *** ***
	.as: SEP #$20

; *** direct print splash string code comes here, when available ***

; *** optional network booting ***
; might modify the contents of fw_warm
;#include "modules/netboot.s"

; *** possible kernel RELOCation should be done here ***

; ************************
; *** start the kernel ***
; ************************
start_kernel:
; start16 will switch to emulation mode just before launching kernel!
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
cop_hndl:				; label from vector list
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

; **********************
; POWEROFF, shutdown etc *** TBD
; **********************
poweroff:
#include "modules/poweroff16.s"

; ***********************************
; FREQ_GEN, generate frequency at PB7 *** TBD
; ***********************************
freq_gen:
#include "modules/set_fg16.s"

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

; *******************************
; RELOC, data and code relocation *** TBD
; *******************************
reloc:
;#include "modules/reloc16.s"

; ***********************************
; CONIO, basic console when available *** TBD
; ***********************************
conio:
;#include "modules/conio16.s"
	_DR_ERR(UNAVAIL)	; not implemented unless specific device

; ***********************************
; ***********************************
; *** some firmware odds and ends ***
; ***********************************
; ***********************************

; *** memory map, as used by gestalt, not sure what to do with it ***
fw_map:					; TO BE DONE

; ************************************************************************
; ************************************************************************
; ************************************************************************

; no NMOS option here, thus ADMIN & U_ADM handlers have room enough!


; ------------ only fixed addresses block remain ------------
; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	kerncall-*, $FF
#endif

; ******************************************************************
; ****** the following will come ALWAYS at standard addresses ****** last 64 bytes
; ******************************************************************

; *** minimOS·65 function call WRAPPER ($FFC0) ***
* = kerncall
	CLC					; pre-clear carry
	COP #$7F			; wrapper on 816 firmware!
	RTS					; return to caller (this takes 4 bytes)
; *** no longer a wrapper outside bank zero for minimOS·65 ***
; alternative multikernel FW may use an indirect jump...
; ...will point to either the above wrapper (16-bit kernel)...
; ...or the usual indirect-indexed jump (8-bit)...
; ...without pre-CLC or size setting!

; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	adm_appc-*, $FF	; eeeeeeeeeeeeeeeeeeeek
#endif

; *** administrative meta-kernel call primitive for apps ($FFD0) ***
; really needed on 65816 systems, for the sake of binary compatibility
; does not jump to $FFDA, not worth more overhead than it already does
* = adm_appc
#ifndef	FAST_FW
	PHB						; could came from any bank
	PHK						; zero is...
	PLB						; ...current bank
	JSR (fw_admin, X)		; return here (DR_OK form)
	PLB						; restore bank...
	RTL						; ...and return from long address!
#endif

; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	adm_call-*, $FF
#endif

; *** administrative meta-kernel call primitive ($FFDA) ***
* = adm_call
#ifndef	FAST_FW
	JMP (fw_admin, X)		; takes 5 clocks and 3 bytes, kernel/drivers only!
#endif




; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	lock-*, $FF
#endif

; *** panic routine, locks at very obvious address ($FFE2-$FFE3) ***
; may be changed for a particular machine after disabling interrupts
* = lock
	SEI					; reunified procedure 20181101
; *** jump to specific lock routine from here ***
	SEC
panic_loop:
	BCS panic_loop		; no problem if /SO is used, new 20150410, was BVC

; *** 65C816 ROM vectors ***
* = $FFE4				; should be already at it
	.word	cop_hndl	; native COP		@ $FFE4
	.word	brk_hndl	; native BRK		@ $FFE6, call standard label from IRQ
	.word	aborted		; native ABORT		@ $FFE8, not yet supported
	.word	nmi			; native NMI		@ $FFEA, unified?
aborted:
	.word	$FF40		; reserved (*)		@ $FFEC holds RTI!
	.word	irq			; native IRQ		@ $FFEE
	.word	$FFFF		; reserved			@ $FFF0
	.word	$FFFF		; reserved			@ $FFF2
	.word	aborted		; emulated COP		@ $FFF4, not compatible
	.word	$FFFF		; reserved			@ $FFF6, no emulated BRK here
	.word	aborted		; emulated ABORT 	@ $FFF8, not supported
; *** 65(C)02 ROM vectors ***
* = $FFFA				; just in case
	.word	aborted		; (emulated) NMI	@ $FFFA, perhaps not unified
	.word	reset		; standard RST		@ $FFFC
	.word	aborted		; (emulated) IRQ	@ $FFFE, not available

fw_end:					; for size computation
.)
