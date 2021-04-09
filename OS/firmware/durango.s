; Durango firmware (at least for prototype version)
; based on generic firmware template for minimOS·65
; v0.6b20
; (c)2015-2021 Carlos J. Santisteban
; last modified 20210409-1406

#define		FIRMWARE	_FIRMWARE
#define		DOWNLOAD	_DOWNLOAD

#include "../usual.h"
; already set at FW_BASE via rom.s

.(
	* = $4000					; *** *** standard downloadable firmware address *** ***
	
; *** since nanoBoot will start executing from first loaded address, an empty page with a JMP is mandatory ***
	JMP dreset					; skip up to two pages
; could put here some routines, or tables, really disposable once booted into minimOS...

; *********************************
; *********************************
; *** administrative jump table *** this has been safely moved backwards, thanks to the mandatory jump instruction
; ********************************* note STANDARD $4003 location
; *********************************

-fw_admin:						; *** now at $4003 as standard for downloadable firmware ***
#ifndef		FAST_FW
; generic functions, esp. interrupt related
	.word	gestalt				; GESTALT get system info (renumbered)
	.word	set_isr				; SET_ISR set IRQ vector
	.word	set_nmi				; SET_NMI set (magic preceded) NMI routine
	.word	set_dbg				; SET_DBG set debugger, new 20170517
	.word	jiffy				; JIFFY set jiffy IRQ speed
	.word	irq_src				; IRQ_SOURCE get interrupt source in X for total ISR independence

; pretty hardware specific
	.word	poweroff			; POWEROFF power-off, suspend or cold boot
	.word	freq_gen			; *** FREQ_GEN frequency generator hardware interface, TBD
; not for LOWRAM systems
	.word	install				; INSTALL copy jump table
	.word	patch				; PATCH patch single function (renumbered)
	.word	reloc				; RELOCate code and data (TBD)
; basic I/O
	.word	conio				; CONIO, basic console when available (TBD)

; *** there's still some room for routines! ***
; ID strings unless residing on header
#ifdef	NOHEAD
fw_splash:
	.asc	"0.6 FW @ "
fw_mname:
	.asc	MACHINE_NAME, 0		; store the name at least
#endif


; *** firmware code follows ***
#ifndef	NOHEAD
; header is expected to be page-aligned
	.dsb	fw_start-*, $FF

; *************************************
; *** first some ROM identification *** new 20150612
; *************************************
fw_start:
	.asc 0, "m", CPU_TYPE		; standard system file wrapper, new format 20161010, experimental type
	.asc "****", CR				; flags TBD
	.asc "boot", 0				; standard filename
fw_splash:
	.asc "0.6 LOADABLE firmware for "	; machine description as comment
fw_mname:
	.asc	MACHINE_NAME, 0
; advance to end of header (may need extra fields for relocation)
	.dsb	fw_start + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$4BC0				; time, 09.30
	.word	$5251				; date, 2021/2/17

fwSize	=	fw_end - fw_start - 256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	fwSize				; filesize
	.word	0					; 64K space does not use upper 16-bit
; *** end of standard header ***
#endif

; *** cannot do proper shutdown as this will be executed first ***
; since this is the start point from nanoBoot, HERE starts the mOS firmware!

; ********************
; ********************
; *** cold restart ***
; ********************
; ********************

dreset:
; *** basic init *** could save a few bytes if unlikely to use a 65816, use basic_init02.s instead
#include "modules/basic_init02.s"

; ******************************
; *** minimal hardware setup ***
; ******************************
; 65x02 does not need to deal with native vs. emulation mode

; check for VIA presence and disable all interrupts *** currently no VIA!
; perhaps make certain that hardware interrupt is disabled?
;#include "modules/viacheck_irq.s"
	STA $AF00				; irrelevant data, as long as the ADDRESS is EVEN

; *********************************
; *** optional firmware modules ***
; *********************************

; optional boot selector *** makes little sense with downloaded kernel
;#include "modules/bootoff.s"

; might check ROM integrity here
;#include "modules/romcheck.s"

; some systems might copy ROM-in-RAM and continue at faster speed!
;#include "modules/rominram.s"

; startup beep *** not really using this
;#include "modules/beep.s" 

; SRAM test *** integrates new beep for breadboard loader
#include "modules/ramtestI0B.s"

; ********************************
; *** hardware interrupt setup ***
; ********************************

; VIA initialisation (and stop beeping) *** stop beeping integrated in RAMtest
; this will enable hardware periodic interrupt
	STA $AF01				; irrelevant data, as long as the ADDRESS is ODD

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

; NMI is NOT validated, and 6502 systems should set a minimal IRQ handler in order to enable PANIC (BRK) handling!
; perhaps mini_nmi should include the standard nmi_end?
;#include "modules/mini_nmi.s"
#include "modules/mini_irq.s"

; preset jiffy irq frequency *** this hardware is fixed-freq, so much with 0.5.x compatibility! might just preset that 244 Hz
;#include "modules/jiffy_hz.s"

; reset jiffy count
#include "modules/jiffy_rst.s"

; reset last installed kernel (new)
#include "modules/rst_lastk.s"

; *** direct print splash string code comes here, when available ***
; perhaps time to initialise picoVDU

; *** optional network booting *** makes no sense with nanoBoot

; *** possible kernel RELOCation should be done here ***

; ************************
; *** start the kernel ***
; ************************
start_kernel:

#include "modules/start.s"

; ********************************
; ****** interrupt handlers ****** no longer here, these go into bootloader firmware
; ********************************
; *** *** 65x02 does have no use for a COP handler *** ***


; ********************************
; ********************************
; *** administrative functions *** these take some custom modules
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
jiffy:							; special module, cannot set speed but at least enable 244 Hz interrupt source!
#include "modules/nv_jiffy.s"

; ****************************************
; IRQ_SRC, investigate source of interrupt
; ****************************************
; notice non-standard ABI
irq_src:						; special module for VIA-less system, just check whether jiffy is disabled in hardware!
#include "modules/nv_i_src.s"

; *** hardware specific ***

; **************************
; POWEROFF, shutdown etc *** TBD
; **************************
poweroff:
#include "modules/poweroff.s"

; ***********************************
; FREQ_GEN, generate frequency at PB7 *** TBD
; ***********************************
freq_gen:
	DR_ERR(UNAVAIL)	; this system lacks hardware oscillator

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
	DR_ERR(UNAVAIL)	; not yet implemented

; ***********************************
; CONIO, basic console when available
; ***********************************
conio:
#include "modules/conio-picovdu.s"

; base FW and minimOS support are...
; **************************************
; *** *** *** NO LONGER HERE *** *** ***
; **************************************
; see bootloader.s

fw_end:					; for size computation
.)
