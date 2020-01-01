; minimOS generic Kernel
; v0.6.1a1
; (c) 2012-2020 Carlos J. Santisteban
; last modified 20190215-0951

; avoid standalone definitions
#define		KERNEL	_KERNEL

; uncomment in case of separate, downloadable jump & boot files
; should assume standalone assembly!!! (will get drivers anyway)
; ROMable kernels cannot be downloaded, though
#ifndef	ROM
;#define		DOWNLOAD	_DOWNLOAD
#endif

; in case of standalone assembly
#ifndef	HEADERS
#include "usual.h"
#ifdef		DOWNLOAD
* = $0400				; safe address for patchable 2 kiB systems, change if required
#else
; standalone kernels need to keep track of drivers_ad label!
.data
#include DRIVER_PACK_s
.text
#endif
#endif

; *** standard header, at least for testing ***
#ifndef	NOHEAD
	.dsb	$100*((* & $FF) <> 0) - (* & $FF), $FF	; page alignment!!! eeeeek
kern_head:
	BRK
	.asc	"m", CPU_TYPE	; executable for testing TBD
	.asc	"****", 13		; flags TBD
	.asc	"kernel", 0		; filename
kern_splash:
	.asc	"minimOS 0.6.1", 0			; version in comment

	.dsb	kern_head + $F8 - *, $FF	; padding

	.word	$4800	; time, 9.00
	.word	$4E4D	; date, 2019/2/13

kern_siz = kern_end - kern_head - $100

	.word	kern_siz, 0	; kernel size excluding header
#endif

; **************************************************
; *** kernel begins here, much like a warm reset ***
; **************************************************

warm:
	SEI				; interrupts off, just in case (2)
	CLD				; just in case, a must for NMOS (2)
; * this is in case a 65816 is being used, but still compatible with all * EXCEPT Kowlaski
#ifdef	SAFE
	SEC				; would set back emulation mode on C816
	.byt	$FB		; XCE on 816, NOP on C02, but illegal 'ISC $0005, Y' on NMOS!
	ORA 0			; the above would increment some random address in zeropage (NMOS) but this one is inocuous on all CMOS
; should clear DBR & DP...
#endif
; * end of 65816 specific code *

; assume interrupts off, binary mode and 65816 in emulation mode!
; install kernel jump table if not previously loaded, NOT for 128-byte systems
#ifndef	LOWRAM
; ++++++
#ifndef		DOWNLOAD
#ifndef			FAST_API
	LDY #<k_vec			; get table address, nicer way (2+2)
	LDA #>k_vec
	STY kerntab			; store parameter (3+3)
	STA kerntab+1
	LDY #API_SIZE & $FF	; *** new API ***
	_ADMIN(INSTALL)		; copy jump table
#ifdef	SAFE
	BCC ki_ok		; no problems
		_PANIC("{FWSIZ}")	; not enough room, incompatible FW
ki_ok:
#endif
#endif
#endif
; ++++++
#endif
; install ISR code (as defined in "isr/irq.s" below)
	LDY #<k_isr			; get address, nicer way (2+2)
	LDA #>k_isr
	STY ex_pt			; no need to know about actual vector location (3)
	STA ex_pt+1
	_ADMIN(SET_ISR)		; install routine

; install BRK code (as defined in "isr/brk.s" loaded from IRQ)
	LDY #<supplied_brk	; get address, nicer way (2+2)
	LDA #>supplied_brk
	STY ex_pt			; no need to know about actual vector location (3)
	STA ex_pt+1
	_ADMIN(SET_DBG)		; install routine

; Kernel no longer supplies default NMI, but could install it otherwise
; jiffy already set by firmware

; *** default action in case the scheduler runs out of tasks ***
	LDA #PW_STAT		; default action upon complete task death
	STA sd_flag			; this is important to be clear (PW_STAT) or set as proper error handler

; *****************************
; *** memory initialisation ***
; *****************************

; ***this should take a basic memory map from firmware, perhaps via the GESTALT function

#ifndef		LOWRAM
; ++++++
	LDY #FREE_RAM		; get status of whole RAM
	STY ram_stat		; as it is the first entry, no index needed
	LDY #END_RAM		; also for end-of-memory marker
	STY ram_stat+1		; second entry in array
	LDX #>user_ram		; beginning of available ram, as defined... in rom.s
	LDY #<user_ram		; LSB misaligned?
	BEQ ram_init		; nothing to align
		INX					; otherwise start at next page
ram_init:
	STX ram_pos			; store it, this is PAGE number
	LDA #SRAM			; number of SRAM pages as defined in options.h *** revise
	STA ram_pos+1		; store second entry and we are done!
; ++++++
#endif

; ************************************************
; *** intialise drivers from their jump tables ***
; ************************************************
; ***** sometime will create API entries for these, but new format is urgent!
; * will also initialise I/O lock arrays! * 20161129
; separared LOWRAM & standard versions 20170902, revamped 20180308

; *** initialise stuff ***
; clear some bytes
	LDX #0				; reset driver index (2)

#ifndef	LOWRAM
; ++++++ ++++++ standard version adds this ++++++ ++++++
	STX queue_mx		; reset all indexes, NMOS-savvy (4+4+4)
	STX queue_mx+1
; ++++++ new direct I/O tables for much faster access 20160406 ++++++
	STX run_pid			; new 170222, set default running PID *** this must be done BEFORE initing drivers as multitasking should place appropriate temporary value via SET_CURR!
dr_clear:
		_STZA cio_lock, X	; clear I/O locks! (4)
;		STZA cin_mode, X	; and binary flags, actually next address (4)
; drv_ads is now mandatory
;		STZA drv_ads, X		; ****** in case of mutable driver IDs, clear pointer array first (4+4)
		_STZA drv_ads+1, X	; ****** could just clear MSB...
		INX					; next entry (2+2)
		INX
		CPX #MX_DRVRS*2+2	; all done? needed for sparse arrays (2)
		BNE dr_clear		; finish page (3/2)
; only dummy entry of I/O pointer arrays must be initialised
	LDY #<dr_error		; make unused entries point to a standard error routine, new 20160406 (2+2)
	LDA #>dr_error
	STY drv_opt			; set LSB for output (4)
	STY drv_ipt			; and for input (4)
	STA drv_opt+1		; set MSB for output (4)
	STA drv_ipt+1		; and for input (4)
; sparse arrays need their index inited...
	LDX #128			; initial offset (2)
dr_spars:
		_STZA dr_ind-128, X	; clear entry (best for CMOS)
		INX
		BNE dr_spars
; ++++++ ++++++ end of standard version extra code ++++++ ++++++
#else
; ------ ------ alternative code for LOWRAM systems ------ ------
;	STX cin_mode		; NLA, single flag for non-multitasking systems, X known to be 0
	STX drv_en			; eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeek
	LDY #MX_QUEUE
	LDA #IQ_FREE		; proper value
dr_qcl:
		STA drv_a_en-1, Y	; reset entry! eeeeeeeeeeek
		DEY
		BNE dr_qcl
#endif

; X know to be zero here
; *** prepare access to each driver header ***
; first get the pointer to it
dr_loop:
		_PHX				; keep current value, no longer drv_aix (3)
		LDA drvrs_ad+1, X		; get address MSB (4)
			BEQ dr_ok			; cannot be in zeropage, all done otherwise
		STA da_ptr+1		; store pointer MSB (3)
		LDA drvrs_ad, X		; same for LSB (4+3)
		STA da_ptr

; *** call new API install ***
		_KERNEL(DR_INST)	; try to install this driver

; *** continue initing drivers ***
; in case drivers_ad is *created* in RAM, dr_abort could just be here, is this OK with new separate pointer tables?
		_PLX				; retrieve saved index (4)
		INX					; update ADDRESS index, even if unsuccessful (2)
		INX					; eeeeeeeek! pointer arithmetic! (2)
		BNE dr_loop			; go for next, no need for BRA? (3)

; *** generic error routine ***
dr_error:
	_DR_ERR(UNAVAIL)		; uninstalled device

; ***************************************************************
; *** drivers already installed, clean up things and continue ***
; ***************************************************************
dr_ok:					; *** all drivers inited ***
	PLA					; discard stored X, no hassle for NMOS


; **********************************
; ********* startup code ***********
; **********************************
; startup code, revise ASAP
; *** set default I/O device ***
	LDA #DEVICE			; as defined in options.h
	STA dfltout			; should check some devices
	STA dflt_in

; *** interrupt setup no longer here, firmware did it! *** 20150605

; new, show a splash message ever the kernel is restarted!
	JSR ks_cr			; leading newline
	LDY #<kern_splash	; get pointer
	LDA #>kern_splash
	STY str_pt			; set parameter
	STA str_pt+1
	LDY #DEVICE			; eeeeeek
	_KERNEL(STRING)		; print it!
	JSR ks_cr			; trailing newline

; ******************************
; **** launch monitor/shell ****
; ******************************
sh_exec:
; should use LOADLINK instead, unless NOHEAD
	LDY #<shell			; get pointer to built-in shell
	LDA #>shell			; as per mandatory label, no header to skip!
	STY ex_pt			; set execution address
	STA ex_pt+1
	LDA #DEVICE			; *** revise
	STA def_io			; default local I/O
	STA def_io+1
	_KERNEL(B_FORK)		; reserve first execution braid, no direct call as could be PATCHED!
	_KERNEL(B_EXEC)		; go for it! no direct call as could be PATCHED!
; singletask systems will not arrive here, ever!
	_KERNEL(B_YIELD)	; ** get into the working code ASAP! ** no direct call as could be PATCHED!
	_PANIC("{yield}")	; ...as the scheduler will detour execution

; a quick way to print a newline on standard device
ks_cr:
	LDA #CR				; leading newline
	STA io_c
	LDY #DEVICE
	_KERNEL(COUT)		; print it
	RTS

; in headerless builds, keep at least the splash string
#ifdef	NOHEAD
kern_splash:
	.asc	"mOS 0.6.1", 0
#endif

; ***********************************************
; *** generic kernel routines, separate files ***
; ***********************************************
#ifndef	LOWRAM
#ifdef		SAFE
	.asc	"<API>"		; debug only
#endif
#include "api.s"
#else
#include "api_lowram.s"
#endif

; *********************************
; *** interrupt service routine ***
; *********************************
; will include BRK handler!
; new separate LOWRAM ISR 20180323

#ifdef		SAFE
	.asc	"<IRQ>"		; debug only
#endif

k_isr:
#ifndef		LOWRAM
#include "isr/irq.s"
#else
#include "isr/irq_lowram.s"
#endif

kern_end:		; for size computation
; ***********************************************
; ***** end of kernel file plus API and IRQ *****
; ***********************************************

; **********************************************************************************

; **********************************************************************************
; *** place here the shell code, must end in FINISH macro, currently with header ***
; **********************************************************************************
; must NOT include external shell label!!!
; but MUST make page alignment HERE, the bulit-in one into shell file will do nothing as already algined

; first determine actual shell address, no longer internally defined!
#ifdef	NOHEAD
shell:					; no header to skip
#else
	.dsb	$100*((* & $FF) <> 0) - (* & $FF), $FF	; page alignment!!! eeeeek
shell	= * + 256		; skip header
#endif

#include SHELL

; ************************************************************
; ****** Downloaded kernels add driver stuff at the end ******
; ************************************************************
#ifdef	DOWNLOAD
#include DRIVER_PACK_s	; this package will be included with downloadable kernels
.data
; downloadable system have ALL system & driver variables AFTER the kernel/API
sysvars:
#include "sysvars.h"
; driver-specific system variables, located here 20170207
dr_vars:
#include DRIVER_PACK_h
.text					; eeeeeek
-user_ram = *			; the rest of available SRAM
#endif
