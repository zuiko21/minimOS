; Durango firmware
; based on generic firmware template for minimOS·65
; v0.6.1b7
; (c)2015-2022 Carlos J. Santisteban
; last modified 20220723-0031

#define		ROM			_ROM
#define		HEADERS		_HEADERS
#define		FIRMWARE	_FIRMWARE
#define		SAFE		_SAFE
;#define		DOWNLOAD	_DOWNLOAD
; setting 
; already set at FW_BASE via rom.s

.(
#ifdef	DOWNLOAD
#include "options/durango.h"
#include "macros.h"
#include "abi.h"
#include "zeropage.h"
* = $200
#include "firmware/durango.h"
.text
	* = FW_BASE					; 32 KiB ROM at $8000, otherwise at $2000-$5FFF

; *** since nanoBoot will start executing from first loaded address, an empty page with a JMP is mandatory ***
	JMP dreset					; skip up to two pages
; could put here some routines, or tables, really disposable once booted into minimOS...
#else
; these are temporarily included here
#include "options/durango.h"
#include "macros.h"
#include "abi.h"
#include "zeropage.h"
* = $200
#include "firmware/durango.h"
;#include "../../forge/eh_basic/drv_ehbasic.h"
;#include "../usual.h"
-user_ram = *
.text
	* = ROM_BASE					; 32 KiB ROM at $8000, otherwise at $2000-$5FFF
; *** kludge app software and kernel included here ***
#include "../kernel.s"
; kernel includes suitable shell (options.h)
#include "../drivers/config/durango_std.s"	; EEEEEEK
#include "../apps/ls.s"
#include "../apps/flags.s"
#include "../shell/miniMoDA.s"
#include "../../forge/eh_basic/ehbasic.s"
#endif


; *********************************
; *********************************
; *** administrative jump table *** this has been safely moved backwards, thanks to the mandatory jump instruction
; *********************************
; *********************************

-fw_admin:
#ifndef		FAST_FW
; generic functions, esp. interrupt related
	.word	gestalt				; GESTALT get system info (renumbered)
	.word	set_isr				; SET_ISR set IRQ vector
	.word	set_nmi				; SET_NMI set (magic preceded) NMI routine
	.word	set_dbg				; SET_DBG set debugger, new 20170517
	.word	chk_sum				; CHK_SUM *** new *** Fletcher-16 checksum
; pretty hardware specific
	.word	jiffy				; JIFFY set jiffy IRQ speed (enable hard int here)
	.word	irq_src				; IRQ_SOURCE get interrupt source in X for total ISR independence (check for enabled irq generator)
	.word	poweroff			; POWEROFF power-off, suspend or cold boot
	.word	freq_gen			; *** FREQ_GEN frequency generator hardware interface, TBD
; not for LOWRAM systems
	.word	install				; INSTALL copy jump table
	.word	patch				; PATCH patch single function (renumbered)
	.word	reloc				; RELOCate code and data (TBD)
	.word	nanolnk				; NANOLNK loader *** new
	.word	rle_dec				; RLE_DEC *** new *** RLE decoder
; basic I/O
	.word	conio				; CONIO, basic console with built-in video
#endif

; *** there's still some room for routines! ***
; ID strings unless residing on header
#ifdef	NOHEAD
fw_splash:
	.asc	"DURANGO FW 0.6.1", 0
#endif

; *** firmware code follows ***
#ifndef	NOHEAD
; header is expected to be page-aligned
	.dsb	FW_BASE+256-*, $FF

; *************************************
; *** first some ROM identification *** new 20150612 *** might go first with a proper bootloader BRK handler
; *************************************
fw_start:
	.asc 0, "m", CPU_TYPE		; standard system file wrapper, new format 20161010, experimental type
	.asc "****", CR				; flags TBD
	.asc "boot", 0				; standard filename
fw_splash:
#ifdef	DOWNLOAD
	.asc " *DOWNLOADABLE* "
#endif
	.asc "0.6.1b6 firmware for "	; machine description as comment
fw_mname:
	.asc	MACHINE_NAME, 0
; advance to end of header (may need extra fields for relocation)
	.dsb	fw_start + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$6DA0				; time, 13.45
	.word	$5422				; date, 2022/1/2

fwSize	=	boot_end - fw_start - 256	; compute size NOT including header!

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

; perhaps make certain that hardware interrupt AND beeper are disabled
#include "modules/durango-irqb.s"

; *********************************
; *** optional firmware modules ***
; *********************************

; optional boot selector *** makes little sense with downloaded kernel
;#include "modules/bootoff.s"

; might check ROM integrity here *** now built-in FW feature, but set parameter appropriately
#include "modules/romcheck-dx.s"

; some systems might copy ROM-in-RAM and continue at faster speed!
;#include "modules/rominram.s"

; startup beep *** will do after successful FW boot

; SRAM test *** new code from test suite, may include other hardware check... and finally some nice beep
#include "modules/durango-POST.s"
#include "modules/durango-beep.s"

; *******************************
; *** general hardware setup ***
; *******************************

; actually will set up CONIO, as interrupts are set by POST
#include "modules/durango-init.s"

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

; preset default BRK _SERVICE_, may set NMI too
#include "modules/brk_addr.s"

; NMI is NOT validated, and 6502 systems should set a minimal IRQ handler in order to enable PANIC (BRK) handling!
; perhaps mini_nmi should include the standard nmi_end?
#include "modules/mini_irq.s"

; preset jiffy irq frequency *** this hardware is fixed-freq, so much with 0.5.x compatibility! might just preset that 250 Hz
;#include "modules/jiffy_hz.s"

; reset jiffy count
#include "modules/jiffy_rst.s"

; reset last installed kernel (new)
#include "modules/rst_lastk.s"

; *** direct print splash string code comes here, when available ***
#include "modules/durango-splash.s"

; *** optional network booting *** makes no sense with nanoBoot, but will when not downloaded
#ifndef	DOWNLOAD
#include "modules/fw-nanoboot.s"
#else
; testing, just the timeout in order to inspect the screen messages first!
#include "modules/fw-nanoboot.s"
#endif
; *** possible kernel RELOCation and/or decompression should be done here ***

; ************************
; *** start the kernel ***
; ************************
start_kernel:

#include "modules/start.s"
;JMP nanomon	; test

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

; ********************************
; CHK_SUM, verify with Fletcher-16
; ********************************
chk_sum:
#include "modules/chk_sum.s"

; *** interrupt related ***

; ***************************
; JIFFY, set jiffy IRQ period
; ***************************
jiffy:							; special module, cannot set speed but at least enable 250 Hz interrupt source!
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
	_DR_ERR(UNAVAIL)	; this system lacks power management

; ***********************************
; FREQ_GEN, generate frequency at PB7 *** TBD
; ***********************************
freq_gen:
	_DR_ERR(UNAVAIL)	; this system lacks hardware oscillator

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
	_DR_ERR(UNAVAIL)	; not yet implemented

; ****************************
; NANOLNK, nanoLink loader *** NEW
; ****************************
nanolnk:
#include "modules/nanolink-fw.s"

; ****************************
; RLE_DEC, RLE decoder *** NEW
; ****************************
rle_dec:
#include "modules/rle.s"

; ***********************************
; CONIO, basic console when available
; ***********************************
conio:
#include "modules/conio-durango-fast.s"

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
	_JMPXA(fw_admin)	; takes a lot of clocks, no need to preserve A
#endif
#endif

; *** Durango-X special panic handler ****
dx_lock:
#include "modules/durango-panic.s"

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
boot_end:
; ****************************************************************
; ****************************************************************
; ****** firmware end, here comes the kernel and some apps *******
; ****************************************************************
; ****************************************************************
#ifdef	DOWNLOAD

#include "../kernel.s"
; kernel includes suitable shell (options.h)
#include "../apps/ls.s"
#include "../apps/flags.s"
#include "../shell/miniMoDA.s"

; ****************************************************
; ****** skip rest of unused ROM until firmware ******
; ****************************************************
; ##### empty header #####
#ifndef	NOHEAD
	.dsb	$100*((* & $FF) <> 0) - (* & $FF), $FF	; page alignment!!! eeeeek
free_head:
	BRK							; don't enter here! NUL marks beginning of header
	.asc	"aS****", CR		; just reserved SYSTEM space
	.asc	"[pseudoR", "OM]", 0, 0	; file name (mandatory) and empty comment *** note macro savvy
; advance to end of header
	.dsb	free_head + $F8 - *, $FF	; for ready-to-blow ROM, advance to time

	.word	$45A0				; time, 8.45
	.word	$4E4D				; date, 2019/02/13

freeSize	=	fw_end - free_head -256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	freeSize			; filesize
	.word	0					; 64K space does not use upper 16-bit
#endif
; ##### end of minimOS header #####
#endif
; ------------ only fixed addresses block remain ------------
; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	kerncall-*, $FF
#endif

; ******************************************************************
; ****** the following will come ALWAYS at standard addresses ****** last 64 bytes
; ******************************************************************

; *** minimOS function call primitive ($FFC0) *** or $5FC0 if DOWNLOADed
* = kerncall
#ifndef	FAST_API
	_JMPXA(fw_table)	; macro for NMOS compatibility (6) this will be a wrapper on 816 firmware!
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
	.dsb	rom_id-*, $FF
#endif
* = rom_id
	.asc	"DmOS"		; Durango-type cartridge at $FFD6

; *** administrative meta-kernel call primitive ($FFDA) ***
* = adm_call
#ifndef	FAST_FW
#ifndef	NMOS
	_JMPXA(fw_admin)	; takes 6 clocks with CMOS
#else
	JMP nmos_adc		; needed overhead as takes 10 bytes!
#endif
#endif
; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	lock-*, $FF
#endif
; note ROM signature is at $FFDE-$FFDF, but no need for a label

; *** panic routine, locks at very obvious address ($FFE2-$FFE3) ***
; may be suited to any particular machine after disabling interrupts
* = lock
	SEI					; reunified procedure 20181101
; *** jump to a suitable lock routine if needed ***
	JMP dx_lock

#ifndef	DOWNLOAD
vectors	= $FFF6
#else
vectors	= $5FF6
#endif

	.dsb	vectors-*, $FF

* = vectors
	.word	brk_hndl	; new eBRK			@ $FFF6
	.word	nmi			; emulated ABORT 	@ $FFF8
; *** 65(C)02 ROM vectors ***
	.word	nmi			; NMI	@ $FFFA
	.word	reset		; RST	@ $FFFC
	.word	irq			; IRQ	@ $FFFE
fw_end:					; for size computation
.)
