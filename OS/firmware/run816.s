; firmware for minimOS on run65816 BBC simulator
; v0.9.6rc13
; (c) 2017-2019 Carlos J. Santisteban
; last modified 20190206-0855

#define		FIRMWARE	_FIRMWARE

; in case of standalone assembly
#include "../usual.h"

; already set at FW_BASE via rom.s

.(
#ifndef	NOHEAD
; *** first some ROM identification *** new 20150612
; this is expected to be loaded at an aligned address anyway
fw_start:
	.asc	0, "mV****", CR		; standard system file wrapper, new 20160309, flags TBD
	.asc	"boot", 0			; mandatory filename for firmware
fw_splash:
	.asc	"0.9.6 firmware for "
; at least, put machine name as needed by firmware!
fw_mname:
	.asc	MACHINE_NAME, 0

; advance to end of header
	.dsb	fw_start + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$45A0				; time, 8.45
	.word	$4E45				; date, 2019/2/5

fwSize	=	$10000 - fw_start - 256	; compute BLOCK size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	fwSize				; filesize
	.word	0					; 64K space does not use upper 16-bit
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
#include "modules/basic_init16.s"

; ******************************
; *** minimal hardware setup ***
; ******************************

; check for VIA presence and disable all interrupts
;#include "modules/viacheck_irq.s"
; simulated 65816 has no real hardware to initialise...

; *** specific 65816 code ***
; as this firmware should be 65816-only, go back to native mode!
#include "modules/816_check.s"
; it can be assumed 65816 from this point on *** NATIVE ***

; *********************************
; *** optional firmware modules ***
; *********************************

; bootoff seems of little use here...


; might check ROM integrity here
;#include "modules/romcheck16.s"

; supposedly no ROM-in-RAM feature


; no beep so far on simulation...


; SRAM test
;#include "modules/memsiz.s"

; ********************************
; *** hardware interrupt setup ***
; ********************************

; nothing to do here...


; ***********************************
; *** firmware parameter settings ***
; ***********************************

; *** set default CPU type ***
#include "modules/default_816.s"
; as this is the only valid CPU for this firmware, no further checking necessary
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

; network booting makes no sense here


; *** direct print splash string ***
#include "modules/splash.s"

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
cop_hndl:				; label from vector list
#include "modules/cop_hndl.s"


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

; 65816 systems have plenty of RAM
	.word	install		; INSTALL copy jump table
	.word	patch		; PATCH patch single function (renumbered)
	.word	reloc		; RELOCate code and data (TBD)
	.word	conio		; CONIO, basic console when available
#endif

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
; *************************** Note specific module as does not make much sense
jiffy:
#include "modules/jiffy_run816.s"

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

; *** other functions for higher specced systems ***

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
	CLC					; pre-clear carry
	COP #$7F			; wrapper on 816 firmware!
	RTS					; return to caller
; *** no longer a wrapper outside bank zero for minimOS·65 ***

; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	adm_appc-*, $FF	; eeeeeeeeeeeeeeeeeeeek
#endif

; *** administrative meta-kernel call primitive for apps ($FFD0) ***
* = adm_appc
real_admappc:
	PHB					; could came from any bank
	PHK					; zero is...
	PLB					; ...current bank
	JSR (fw_admin, X)	; return here (DR_OK form)
	PLB					; restore bank...
	RTL					; ...and return from long address!

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	adm_call-*, $FF
#endif

; *** administrative meta-kernel call primitive ($FFDA) ***
* = adm_call
real_admcall:
	JMP (fw_admin, X)	; takes 5 cycles

; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	lock-*, $FF
#endif

; *** panic routine, locks at very obvious address ($FFE2-$FFE3) ***
* = lock
	.byt	$42			; WDM opcode will trigger an error on run/lib65816
	SEI					; actually a signature byte
panic_loop:
	BRA panic_loop		; OK as this is 65816 only

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
