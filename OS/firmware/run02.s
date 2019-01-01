; firmware for minimOS on run65816 BBC simulator
; 65c02 version for testing 8-bit kernels
; v0.9.6rc13
; (c) 2017-2019 Carlos J. Santisteban
; last modified 20181227-1758

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
	.word	$4C45				; date, 2018/2/5

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
; *** direct print splash string ***
; **********************************
	LDX #0				; reset index (2)
fws_loop:
		LDA fw_splash, X	; get char (4)
			BEQ fws_cr			; no more to print (2/3)
; as direct print uses no regs, nothing to save and reload
		JSR $c0c2			; *** EhBASIC output ***
		INX					; next char (2)
		BNE fws_loop		; no need for BRA, as long as no more tha 255 chars (3/2)
fws_cr:
	LDA #LF				; trailing CR, needed by console! (2)
	JSR $c0c2			; direct print

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
#ifndef	FAST_FW
; generic functions, esp. interrupt related
	.word	gestalt		; GESTALT get system info (renumbered)
	.word	set_isr		; SET_ISR set IRQ vector
	.word	set_nmi		; SET_NMI set (magic preceded) NMI routine
	.word	set_dbg		; SET_DBG set debugger, new 20170517
	.word	jiffy		; JIFFY set jiffy IRQ speed, ** TBD **
	.word	irq_src		; IRQ_SOURCE get interrupt source in X for total ISR independence

; pretty hardware specific
	.word	poweroff	; POWEROFF power-off, suspend or cold boot
	.word	freq_gen	; *** FREQ_GEN frequency generator hardware interface, TBD

; not for LOWRAM systems
#ifndef	LOWRAM
	.word	install		; INSTALL copy jump table
	.word	patch		; PATCH patch single function (renumbered)
#else
#ifdef	SAFE
	.word	missing		; these three functions not implemented on such systems
	.word	missing

missing:
		_DR_ERR(UNAVAIL)	; return some error while trying to install or patch!
#endif
#endif
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
+freq_gen:
	_DR_ERR(UNAVAIL)	; not yet implemented

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

#endif


; ***********************************
; ***********************************
; *** some firmware odds and ends ***
; ***********************************
; ***********************************

; *** memory map, as used by gestalt, not sure what to do with it ***
fw_map:					; TO BE DONE

; *** wrapper in case 816-enabled code calls 8-bit kernel??? ***
cop_hndl:				; label from vector list
#ifdef	C816
	.as: .xs: SEP #$30	; *** standard sizes, just in case ***
	JSR (fw_table, X)	; the old fashioned way, 8-bit functions end in RTS
; ...but this does NOT affect the pushed status!
	RTI
#endif

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
	SEI					; REunified procedure 20181101
	SEC
panic_loop:
	BCS panic_loop		; no problem if /SO is used, new 20150410, was BVC

; **********************************
; ****** hardware ROM vectors ******
; **********************************

; *** 65C816 ROM vectors ***
;* = $FFE4				; should be already at it
	.word	cop_hndl	; native COP		@ $FFE4***revise
	.word	brk_hndl	; native BRK		@ $FFE6, call standard label from IRQ***revise
	.word	nmi			; native ABORT		@ $FFE8, not yet supported
	.word	nmi			; native NMI		@ $FFEA, unified this far
	.word	$FFFF		; reserved			@ $FFEC
	.word	irq			; native IRQ		@ $FFEE, unified this far***revise
	.word	$FFFF		; reserved			@ $FFF0
	.word	$FFFF		; reserved			@ $FFF2
	.word	nmi			; emulated COP		@ $FFF4***revise
	.word	brk_hndl		; reserved (eBRK)	@ $FFF6
	.word	nmi			; emulated ABORT 	@ $FFF8
; *** 65(C)02 ROM vectors ***
* = $FFFA				; just in case
	.word	nmi			; (emulated) NMI	@ $FFFA
	.word	reset		; (emulated) RST	@ $FFFC
	.word	irq			; (emulated) IRQ	@ $FFFE

fw_end:					; for size computation
