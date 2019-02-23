; firmware for minimOS on run65816 BBC simulator
; 65c02 version for testing 8-bit kernels
; v0.9.6rc19
; (c) 2017-2019 Carlos J. Santisteban
; last modified 20190223-2244

#define		FIRMWARE	_FIRMWARE

; in case of standalone assembly
#ifndef	HEADERS
#include "../usual.h"
#endif

; already set at FW_BASE via rom.s

#ifndef	NOHEAD
; *** first some ROM identification *** new 20150612
; this is expected to be loaded at an aligned address anyway
fw_start:
	.asc	0, "m", CPU_TYPE	; special system wrapper
	.asc	"****", CR			; flags TBD
	.asc	"boot", 0			; mandatory filename for firmware
fw_splash:
	.asc	"0.9.6 firmware for "
fw_mname:
	.asc	MACHINE_NAME, 0

; advance to end of header
	.dsb	fw_start + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$4DA0				; time, 09.45
	.word	$4E45				; date, 2019/2/5

fwSize	=	$10000 - fw_start - 256	; compute size NOT including header!

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

; basic init
reset:
#include "modules/basic_init.s"

; simulated 65816 has no real hardware to initialise...

; *********************************
; *** optional firmware modules ***
; *********************************

; bootoff seems of little use here...

; might check ROM integrity here
;#include "modules/romcheck.s"

; no beep so far on simulation...

; SRAM test
;#include "modules/ramtest.s"

; ********************************
; *** hardware interrupt setup ***
; ********************************

; no VIA to initialise...

; ***********************************
; *** firmware parameter settings ***
; ***********************************

; set default CPU type
; just set expected default type as defined in options.h...
;#include "modules/default_cpu.s"
; ...or actually check for it!
#include "modules/cpu_check.s"
; do NOT include both files at once!

; *** simulator simply cannot issue an NMOS CPU! ***

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

; *** could download a kernel here, updating fw_warm accordingly ***


; **********************************
; *** direct print splash string *** now with generic CONIO
; **********************************
#include "modules/splash.s"

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

; ***************************
; *** minimOS BRK handler ***
; ***************************
brk_hndl:				; this is now pointed from a reserved vector
#include "modules/brk_hndl.s"


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
	.word	missing		; these three functions not implemented on such systems
	.word	missing
	.word	missing
#endif
	.word	conio		; CONIO, basic console when available (TBD) *** should NOT depend on LOWRAM option!
#ifdef	LOWRAM
missing:
		_DR_ERR(UNAVAIL)	; return some error while trying to install or patch!
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
; *** TWEAKED version for VIA-less emulators, always ASYNC! ***
irq_src:
#include "modules/irq_src_emu.s"

; *** hardware specific ***

; **********************
; POWEROFF, shutdown etc
; **********************
poweroff:
#include "modules/poweroff.s"

; ***********************************
; FREQ_GEN, generate frequency at PB7 *** TBD
; ***********************************
freq_gen:
#include "modules/set_fg.s"

; *** other functions with RAM enough ***
#ifndef		LOWRAM
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
#endif

; ***********************************
; CONIO, basic console when available
; ***********************************
conio:					; simple I/O routines for run816 and run02
#include "modules/conio-run816.s"


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

; *** minimOS·65 function call interface ($FFC0) ***
* = kerncall
#ifndef	FAST_API
	_JMPX(fw_table)		; the old fashioned way, suitable for NMOS builds
#endif

; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	adm_appc-*, $FF	; eeeeeeeeeeeeeeeeeeeek
#endif

; *** administrative meta-kernel call primitive for apps ($FFD0) ***
; not really needed on 6502 systems, but kept for the sake of binary compatibility
; pretty much the same code at $FFD8, not worth more overhead (but check NMOS size!)
* = adm_appc
#ifndef	FAST_FW
#ifndef	NMOS
	_JMPX(fw_admin)		; takes 6 clocks with CMOS
#else
	JMP nmos_adc		; needed overhead as takes 10 bytes!
#endif
#endif

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
* = lock
	.byt	$42			; WDM opcode will trigger an error on run/lib65816
	SEI					; actually a signature byte
panic_loop:
	BRA panic_loop		; OK as this is 65816 only

; **********************************
; ****** hardware ROM vectors ******
; **********************************

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
