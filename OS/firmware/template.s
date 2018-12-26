; more-or-less generic firmware template for minimOS·65
; v0.6b13
; (c)2015-2018 Carlos J. Santisteban
; last modified 20181226-1414

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
	.asc 0, "m", CPU_TYPE		; standard system file wrapper, new format 20161010, experimental type
	.asc "****", CR				; flags TBD
	.asc "boot", 0				; standard filename
fw_splash:
	.asc "0.6b12 firmware for "	; machine description as comment
fw_mname:
	.asc	MACHINE_NAME, 0
; advance to end of header (may need extra fields for relocation)
	.dsb	fw_start + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$53C0				; time, 10.30
	.word	$4D8D				; date, 2018/12/13

fwSize	=	fw_end - fw_start - 256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	fwSize				; filesize
	.word	0					; 64K space does not use upper 16-bit
; *** end of standard header ***
#else
; if no headers, put identifying strings somewhere
fw_splash:
	.asc	"0.6b12 FW@"
fw_mname:
	.asc	MACHINE_NAME, 0		; store the name at least
#endif

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
; not for LOWRAM systems
#ifndef	LOWRAM
	.word	install		; INSTALL copy jump table
	.word	patch		; PATCH patch single function (renumbered)
	.word	reloc		; RELOCate code and data (TBD)
#else
#ifdef	SAFE
	.word	missing		; these three functions not implemented on such systems
	.word	missing
	.word	missing
missing:
		_DR_ERR(UNAVAIL)	; return some error while trying to install or patch!
#endif
#endif
#endif

; ********************
; ********************
; *** cold restart ***
; ********************
; ********************

reset:
; *** basic init *** could save a few bytes if unlikely to use a 65816, use basic_init02.s instead
#include "modules/basic_init.s"

; ******************************
; *** minimal hardware setup ***
; ******************************
; 65x02 does not need to deal with native vs. emulation mode

; check for VIA presence and disable all interrupts
#include "modules/viacheck_irq.s"

; *********************************
; *** optional firmware modules ***
; *********************************

; optional boot selector
;#include "modules/bootoff.s"

; might check ROM integrity here
;#include "modules/romcheck.s"

; some systems might copy ROM-in-RAM and continue at faster speed!
;#include "modules/rominram.s"

; startup beep
#include "modules/beep.s"	; basic standard beep

; SRAM test
#include "modules/ramtest.s"

; ********************************
; *** hardware interrupt setup ***
; ********************************

; VIA initialisation (and stop beeping)
#include "modules/via_init.s"

; ***********************************
; *** firmware parameter settings ***
; ***********************************

; *** set default CPU type ***
; just set expected default type as defined in options.h...
;#include "modules/default_cpu.s"
; ...or actually check for it!
#include "modules/cpu_check.s"
; do NOT include both files at once!

; in case an NMOS CPU is used, make sure this was built for it
#include "modules/nmos_savvy.s"

; *** continue parameter setting ***
; preset kernel start address
#include "modules/kern_addr.s"

; preset default BRK handler
#include "modules/brk_addr.s"

; no need to set NMI as it will be validated

; preset jiffy irq frequency
#include "modules/jiffy_hz.s"

; reset jiffy count
#include "modules/jiffy_rst.s"

; reset last installed kernel (new)
#include "modules/rst_lastk.s"




; *** direct print splash string code comes here, when available ***

; *** optional network booting ***
; might modify the contents of fw_warm
;#include "modules/netboot.s"

; *** possible kernel RELOCation should be done here ***

; ************************
; *** start the kernel ***
; ************************
start_kernel:

#include "modules/start.s"


; ********************************
; ********************************
; ****** interrupt handlers ******
; ********************************
; ********************************

; **********************************************
; *** vectored NMI handler with magic number ***
; **********************************************
nmi:
#include "modules/nmi_hndl.s"

; ****************************
; *** vectored IRQ handler ***
; ****************************
; nice to be here, but might go elsewhere in order to save space, like between FW interface calls
irq:
#include "modules/irq_hndl.s"

; ****************************
; *** vectored BRK handler ***
; ****************************
brk_hndl:				; label from vector list
#include "modules/brk_hndl.s"

; *** *** 65x02 does have no use for a COP handler *** ***





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
#include "modules/gestalt.s"

; ***********************
; SET_ISR, set IRQ vector
; ***********************
set_isr:
#include "modules/set_isr.s"

; ********************************
; SET_NMI, set NMI handler routine
; ********************************
set_nmi:
#include "modules/set_nmi.s"

; ********************************
; SET_DBG, set BRK handler routine
; ********************************
set_dbg:
#include "modules/set_dbg.s"

; *** interrupt related ***

; ***************************
; JIFFY, set jiffy IRQ period
; ***************************
jiffy:
#include "modules/jiffy.s"

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
#include "modules/poweroff.s"

; ***********************************
; FREQ_GEN, generate frequency at PB7 *** TBD
; ***********************************
freq_gen:
;#include "modules/freq_gen16.s"
	_DR_ERR(UNAVAIL)	; not yet implemented

; *** other functions for systems with RAM enough ***
; **************************
; INSTALL, supply jump table
; **************************
install:
#include "modules/install.s"

; ****************************
; PATCH, patch single function
; ****************************
patch:
#include "modules/patch.s"

; *******************************
; RELOC, data and code relocation *** TBD
; *******************************
reloc:
;#include "modules/reloc.s"

; ***********************************
; ***********************************
; *** some firmware odds and ends ***
; ***********************************
; ***********************************

; *** memory map, as used by gestalt, not sure what to do with it ***
fw_map:					; TO BE DONE

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
	SEC
panic_loop:
	BCS panic_loop		; no problem if /SO is used, new 20150410, was BVC

* = $FFE4				; should be already at it
#ifdef	SAFE
; *** 65C816 ROM vectors, just in case ***
	.word	aborted		; native COP		@ $FFE4
	.word	aborted		; native BRK		@ $FFE6
	.word	aborted		; native ABORT		@ $FFE8
	.word	aborted		; native NMI		@ $FFEA
aborted:
	.word	$FF40		; reserved (nRST)	@ $FFEC holds RTI!
	.word	aborted		; native IRQ		@ $FFEE
	.word	$FFFF		; reserved			@ $FFF0
	.word	$FFFF		; reserved			@ $FFF2
	.word	nmi		; emulated COP		@ $FFF4
-brk_02:
	.word	brk_hndl	; reserved (eBRK)	@ $FFF6, 65x02 BRK handler entry
	.word	nmi		; emulated ABORT 	@ $FFF8
#else
#ifdef	ROM
	.dsb	$FFF6-*, $FF
	.word	brk_hndl	; reserved (eBRK)	@ $FFF6
	.word	nmi		; emulated ABORT 	@ $FFF8
#endif
#endif
; *** 65(C)02 ROM vectors ***
* = $FFFA				; just in case
	.word	nmi			; NMI	@ $FFFA
	.word	reset		; RST	@ $FFFC
	.word	irq			; IRQ	@ $FFFE

fw_end:					; for size computation
.)
