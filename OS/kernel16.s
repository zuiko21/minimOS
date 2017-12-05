; minimOS·16 generic Kernel
; v0.6b5
; (c) 2012-2017 Carlos J. Santisteban
; last modified 20171205-1035

; just in case
#define		C816	_C816

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
#ifdef	DOWNLOAD
* = $0400				; safe address for patchable 2 kiB systems, change if required
#else
; standalone kernels need to keep track of drivers_ad label!
.data
#include "drivers/config/DRIVER_PACK.s"
.text
#endif
#endif

; ##### standard header, at least for testing #####
#ifndef	NOHEAD
	.dsb	$100*((* & $FF) <> 0) - (* & $FF), $FF	; page alignment!!! eeeeek
kern_head:
	BRK
	.asc	"mV"			; executable for testing TBD
	.asc	"****", 13		; flags TBD
	.asc	"kernel", 0		; filename
kern_splash:
	.asc	"minimOS·16 0.6b5", 0	; version in comment
	.dsb	kern_head + $F8 - *, $FF	; padding

	.word	$5000	; time, 1000
	.word	$4B6E	; date, 2017/11/14

kern_siz = kern_end - kern_head - 256

	.word	kern_siz, 0	; kernel size excluding header
#endif
; ##### end of minimOS header #####

; **************************************************
; *** kernel begins here, much like a warm reset ***
; **************************************************
warm:
	SEI					; interrupts off, just in case
	CLD					; do not assume anything
#ifdef		SAFE
	SEC
	XCE					; set emulation mode for a moment! will reset to 8-bit registers
	PHK					; this pushes a zero into stack
	PLB					; ...and resets data bank eeeeeeeeeek
	PHK					; stack two zeroes to reset DP
	PHK					; worth it instead of TCD et al
	PLD					; even if it was done on firmware!
#endif
; assume interrupts off, binary mode and 65C816 in emulation mode!
	CLC
	XCE					; enter native mode! still 8 bit regs, though
; worth going 16-bit for the install calls!
	.al: REP #$20		; *** 16-bit memory most of the time ***

; install kernel jump table if not previously loaded
#ifndef		DOWNLOAD
	LDA #k_vec			; get table address (3)
	STA kerntab			; store parameter (4)
; as kernels must reside in bank 0, no need for 24-bit addressing
	_ADMIN(INSTALL)		; copy jump table, will respect register sizes
#endif

; install ISR code (as defined in "isr/irq16.s" below)
	LDA #k_isr			; get address (3)
	STA kerntab			; no need to know about actual vector location (4)
	STZ kerntab+2		; required 24b
	_ADMIN(SET_ISR)		; install routine, will respect sizes

; install BRK code (as defined in "isr/brk16.s", currently from IRQ, might move to rom.s)
	LDA #supplied_brk		; get address (3)
	STA kerntab			; no need to know about actual vector location (4)
	STZ kerntab+2		; required 24b
	_ADMIN(SET_DBG)		; install routine, will respect sizes

; Kernel no longer supplies default NMI, but could install it otherwise

; will not try to set jiffy, assumed by firmware

; what to do if scheduler run out if tasks? set here
	LDX #PW_STAT		; default cmd upon lack of tasks
	STX sd_flag		; must be done here as will no longer be done on driver init code!

; *****************************
; *** memory initialisation ***
; *****************************

; ***this should take a basic memory map from firmware, perhaps via the GESTALT function

	LDY #FREE_RAM	; dirty trick no longer allowed... should be zero
	STY ram_stat	; as it is the first entry, no index needed
	LDY #END_RAM	; also for end-of-memory marker
	STY ram_stat+2	; note offset for interleaved array!
	LDX #>user_ram	; beginning of available ram, as defined... in rom.s
	LDY #<user_ram	; LSB misaligned?
	BEQ ram_init	; nothing to align
		INX				; otherwise start at next page
ram_init:
	TXA				; will set MSB as zero
	STA ram_pos		; store it
	LDA #SRAM		; number of SRAM pages as defined in options.h
	STA ram_pos+2	; store second entry and we are done!

; ************************************************
; *** intialise drivers from their jump tables ***
; ************************************************
; sometime will create API entries for these, but new format is urgent!
; * will also initialise I/O lock arrays! * 20161129
; obviously enters in 16-bit memory size!

; *** initialise stuff ***
	LDX #0				; reset driver index (2)
; clear some bytes
	STZ queue_mx		; reset all indexes, 16-bit already set
	STX run_arch		; assume native 65816
	STX run_pid			; new 170222, set default running PID *** this must be done BEFORE initing drivers as multitasking should place appropriate temporary value via SET_CURR!

; init all I/O pointers and flags
	LDA #dr_error		; make unused entries point to a standard error routine (3)
dr_clear:
		STZ cio_lock, X		; clear I/O locks and interleaved binary flags! (5)
#ifdef	MUTABLE
		STZ drv_ads, X		; ****** clear array for mutable IDs (5)
		STZ drv_opt, X		; eeeeeeeeeeeek (5)
		STZ drv_ipt, X		; eeeeeeeeeeeek (5)
#else
		STA drv_opt, X		; set full pointer for output (5)
		STA drv_ipt, X		; and for input (5)
#endif
		INX					; go for next entry (2+2)
		INX
		CPX #MX_DRVRS*2		; all done? needed for sparse arrays (2) EEEEEEEEEK
		BNE dr_clear		; finish page (3/2)
; sparse arrays need their index inited... EEEEEEEEEEEK
	LDX #128				; initial offset (2)
	LDA #0					; ***** or 255, if needed ***** best to define a constant! *** A in 16-bit anyway
dr_spars:
		STA dr_ind-128, X		; clear entry
		INX
		INX						; 16-bit access
		BNE dr_spars
; TASKDEV is no longer a thing...
;	LDX #0					; ...reset X if using restricted set, but NOT needed with sparse ID array!!!
; *** prepare access to each driver header ***
dr_loop:
		PHX					; keep current value (3)
; first create a pointer to it
lda#'x':jsr$c0c2
txa:and#$ff:clc:adc#'0':jsr$c0c2
lda#10:jsr$c0c2
		LDA drvrs_ad, X		; get full address (5)
			BEQ dr_ok			; cannot be zero, all done otherwise
		STA da_ptr			; store full pointer (4)
; *** call new API function ***
		_KERNEL(DR_INST)	; try to install this driver
lda#'H':jsr$c0c2
lda#'e':jsr$c0c2
lda#'r':jsr$c0c2
lda#'e':jsr$c0c2
lda#10:jsr$c0c2
bcc drsucc
lda#'!':jsr$c0c2
newline:lda#10:jsr$c0c2
bra gonext
drsucc:lda#'$':jsr$c0c2:bra newline
gonext:

; *** prepare for next driver ***
; in order to keep drivers_ad in ROM, can't just forget unsuccessfully registered drivers...
; in case drivers_ad is *created* in RAM, dr_abort could just be here, is this OK with new separate pointer tables?
		PLX					; retrieve saved index (4)
		INX					; update ADDRESS index, even if unsuccessful (2)
		INX					; eeeeeeeek! pointer arithmetic! (2)
		BRA dr_loop			; go for next (3)

; ****************************************************************************
; *** default error routine, just for kernel init... but also for DRV_SHUT ***
; ****************************************************************************
dr_error:
	_DR_ERR(N_FOUND)	; standard exit for non-existing drivers!

; *********************************************************************
; *** drivers already installed, clean up things and finish booting ***
; *********************************************************************
dr_ok:					; *** all drivers inited ***
lda#'D':jsr$c0c2
lda#'u':jsr$c0c2
lda#'h':jsr$c0c2
lda#10:jsr$c0c2
	PLX					; discard stored X, beware of 16-bit memory!

; **********************************
; ********* startup code ***********
; **********************************

; *** set default I/O device *** still in 16-bit memory
	LDA #DEVICE*257		; as defined in options.h **** revise as it might be different for I and O
	STA dflt_in			; should check some devices, this assumes _in is LSB

; *** interrupt setup no longer here, firmware did it! *** 20150605

; new, show a splash message ever the kernel is restarted!
; assume 16-bit memory
	JSR ks_cr			; leading newline
	LDA #kern_splash	; get pointer to string
	STA str_pt			; set parameter
	STZ str_pt+2		; clear bank!
	LDY #DEVICE			; eeeeeek
;	KERNEL(STRING)		; print it!
	JSR ks_cr			; trailing newline

; ******************************
; **** launch monitor/shell ****
; ******************************
sh_exec:
; should use LOADLINK...
#ifdef	NOHEAD
	LDX #'V'			; assume shell code is 65816!!! ***** REVISE
#else
	LDX shell-254		; get ACTUAL CPU type from executable header!
#endif
	STX cpu_ll			; architecture parameter
	STZ ex_pt+2			; 24-bit addressing for forthcoming EXEC
	.al: REP #$20		; will be needed anyway upon restart
	LDA #shell			; pointer to integrated shell! eeeeeek
	STA ex_pt			; set execution full address
	LDA #DEVICE*257		; revise as above *****
	STA def_io			; default LOCAL I/O
	_KERNEL(B_FORK)		; reserve first execution braid, no direct call as could be PATCHED!
	_KERNEL(B_EXEC)		; go for it! no direct call as could be PATCHED!
; singletask systems will not arrive here, ever!
	_KERNEL(B_YIELD)	; ** get into the working code ASAP! ** no direct call as could be PATCHED!
here:
	BRA here			; ...as the scheduler will detour execution

; a quick way to print a newline on standard device
ks_cr:
	LDY #CR				; leading newline, 8-bit
	STY io_c
	LDY #DEVICE
	_KERNEL(COUT)		; print it
	RTS

; ***********************************************
; *** generic kernel routines, separate files ***
; ***********************************************
	.asc	"<API>"				; for debug only
#include "api16.s"

; *********************************
; *** interrupt service routine ***
; *********************************
; will include BRK handler!
k_isr:
#include "isr/irq16.s"
; default NMI-ISR is on firmware!


; in case of no headers, keep splash ID string
#ifdef	NOHEAD
kern_splash:
	.asc	"minimOS·16 0.6b5", 0	; version in comment
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
; but MUST make page alignment HERE, the bulit-in one into shell file will fo nothing as already algined

; first determine actual shell address, no longer internally defined!
#ifdef	NOHEAD
shell:			; no header to skip
#else
	.dsb	$100*((* & $FF) <> 0) - (* & $FF), $FF	; page alignment!!! eeeeek
shell	= * + 256		; skip header
#endif

#include "shell/SHELL"

; ************************************************************
; ****** Downloaded kernels add driver staff at the end ******
; ************************************************************
#ifdef	DOWNLOAD
#include "drivers/config/DRIVER_PACK.s"	; this package will be included with downloadable kernels
.data
; downloadable system have ALL system & driver variables AFTER the kernel/API
sysvars:
#include "sysvars.h"
; driver-specific system variables, located here 20170207
dr_vars:
#include "drivers/config/DRIVER_PACK.h"
.text					; eeeeeek
-user_ram = *			; the rest of available SRAM
#endif
