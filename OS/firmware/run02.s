; firmware for minimOS on run65816 BBC simulator
; 65c02 version for testing 8-bit kernels
; v0.9.6rc8
; (c)2017-2018 Carlos J. Santisteban
; last modified 20180131-1424

#define		FIRMWARE	_FIRMWARE

; in case of standalone assembly
#include "usual.h"

; already set at FW_BASE via rom.s

.(
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
	.word	$7000			; time, 14.00
	.word	$4AC9			; date, 2017/6/9

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
	.word	jiffy		; JIFFY set jiffy IRQ speed, ** TBD **
	.word	irq_src		; IRQ_SOURCE get interrupt source in X for total ISR independence

; pretty hardware specific
	.word	poweroff	; POWEROFF power-off, suspend or cold boot
	.word	freq_gen	; *** FREQ_GEN frequency generator hardware interface, TBD

; not for LOWRAM systems
#ifndef	LOWRAM
	.word	install		; INSTALL copy jump table
	.word	patch		; PATCH patch single function (renumbered)
	.word	context		; *** CONTEXT context bankswitching
#else
#ifdef	SAFE
	.word	missing		; these three functions not implemented on such systems
	.word	missing
	.word	missing

missing:
		_DR_ERR(UNAVAIL)	; return some error while trying to install or patch!
#endif
#endif


; **************************
; **************************
; ****** cold restart ******
; **************************
; **************************

; basic init
reset:
#include "firmware/modules/basic_init.s"

; simulated 65816 has no real hardware to initialise...

; *********************************
; *** optional firmware modules ***
; *********************************

; bootoff seems of little use here...

; might check ROM integrity here
;#include "firmware/modules/romcheck.s"

; no beep so far on simulation...

; SRAM test
;#include "firmware/modules/ramtest.s"

; ********************************
; *** hardware interrupt setup ***
; ********************************

; no VIA to initialise...

; ***********************************
; *** firmware parameter settings ***
; ***********************************

; set default CPU type 
; just set expected default type as defined in options.h...
;#include "firmware/modules/default_cpu.s"
; ...or actually check for it!
#include "firmware/modules/cpu_check.s"
; do NOT include both files at once!

; *** simulator simply cannot issue an NMOS CPU! ***

; preset kernel start address
#include "firmware/modules/kern_addr.s"

; preset default BRK handler
#include "firmware/modules/brk_addr.s"

; no need to set NMI as it will be validated

; preset jiffy irq frequency
#include "firmware/modules/jiffy_hz.s"

; reset jiffy count
#include "firmware/modules/jiffy_rst.s"

; reset last installed kernel (new)
#include "firmware/modules/rst_lastk.s"

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
	JMP (fw_warm)		; (5/6)


; ********************************
; ********************************
; ****** interrupt handlers ******
; ********************************
; ********************************

; **********************************************
; *** vectored NMI handler with magic number ***
; **********************************************
nmi:
#include "firmware/modules/nmi_hndl.s"

; ****************************
; *** vectored IRQ handler ***
; ****************************
; nice to be here, but might go elsewhere in order to save space, like between FW interface calls
irq:
	JMP (fw_isr)		; vectored ISR (6)

; ***************************
; *** minimOS BRK handler ***
; ***************************
brk_hndl:				; label from vector list
#include "firmware/modules/brk_hndl.s"


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
#include "firmware/modules/gestalt.s"

; ***********************
; SET_ISR, set IRQ vector
; ***********************
set_isr:
#include "firmware/modules/set_isr.s"

; ********************************
; SET_NMI, set NMI handler routine
; ********************************
set_nmi:
#include "firmware/modules/set_nmi.s"

; ********************************
; SET_DBG, set BRK handler routine
; ********************************
set_dbg:
#include "firmware/modules/set_dbg.s"

; *** interrupt related ***

; ***************************
; JIFFY, set jiffy IRQ period
; ***************************
jiffy:
#include "firmware/modules/jiffy.s"

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
#include "firmware/modules/poweroff.s"

; ***********************************
; FREQ_GEN, generate frequency at PB7 *** TBD
; ***********************************
freq_gen:
;#include "firmware/modules/freq_gen16.s"
	_DR_ERR(UNAVAIL)	; not yet implemented

; *** other functions with RAM enough ***
#ifndef		LOWRAM
; **************************
; INSTALL, supply jump table
; **************************
install:
#include "firmware/modules/install.s"

; ****************************
; PATCH, patch single function
; ****************************
patch:
#include "firmware/modules/patch.s"

; *****************************************
; CONTEXT, hardware switch zeropage & stack
; *****************************************
context:
;#include "firmware/modules/context16.s"
	_DR_ERR(UNAVAIL)	; not yet implemented
#endif

; ----------------------- OLD CODE ---------------------------

; **************** make a specific one for no hardware??????????????????
; JIFFY, set jiffy IRQ frequency
;		INPUT
; irq_hz	= frequency in Hz (0 means no change)
;		OUTPUT
; irq_hz	= actually set frequency (in case of error or no change)
; C			= could not set (not here)

;jiffy:
; this is generic
; if could not change, then just set return parameter and C
	LDA irq_hz+1		; get input values
	LDY irq_hz
;		BNE fj_set			; not just checking
	CMP #0				; MSB also 0?
;		BNE fj_set			; not checking
	LDA irq_freq+1		; get current frequency
	LDY irq_freq
	STA irq_hz+1		; set return values
	STY irq_hz
;fj_end:
	_DR_OK
;fj_set:
	STA irq_freq+1		; store in sysvars
	STY irq_freq
;	BRA fj_end			; all done, no need to update as will be OK


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
	RTI
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
	_JMPX(fw_table)		; the old fashioned way

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	adm_call-*, $FF
#endif

; *** administrative meta-kernel call primitive ($FFD0) ***
* = adm_call
	_JMPX(fw_admin)		; takes 5/6 clocks

; ****** taking up some unused space ******
; this could be a good place for the IRQ handler...

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

; **********************************
; ****** hardware ROM vectors ******
; **********************************

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
