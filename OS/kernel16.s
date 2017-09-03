; minimOS·16 generic Kernel
; v0.6a12
; (c) 2012-2017 Carlos J. Santisteban
; last modified 20170903-1055

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
	.asc	"minimOS•16 0.6a12", 0	; version in comment
	.dsb	kern_head + $F8 - *, $FF	; padding

	.word	$4800	; time, 0900
	.word	$4AB7	; date, 2017/5/23

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

; *** 1) initialise stuff ***
	LDX #0				; reset driver index (2)
; clear some bytes
	STZ queue_mx		; reset all indexes, 16-bit already set
	STX run_arch		; assume native 65816
	STX run_pid			; new 170222, set default running PID *** this must be done BEFORE initing drivers as multitasking should place appropriate temporary value via SET_CURR!

; init all I/O pointers and flags
	LDA #dr_error		; make unused entries point to a standard error routine (3)
dr_clear:
		STZ cio_lock, X		; clear I/O locks and interleaved binary flags! (5)
		STA drv_opt, X		; set full pointer for output (5)
		STA drv_ipt, X		; and for input (5)
		INX					; go for next entry (2+2)
		INX
; might compare against a max-ID and save some RAM, perhaps for 8-bit systems
		BNE dr_clear		; finish page (3/2)

; TASKDEV is no longer a thing...

; *** 2) prepare access to each driver header ***
dr_loop:
		PHX					; keep current value (3)
; first create a pointer to it
		LDA drvrs_ad, X		; get full address (5)
		BNE dr_inst			; cannot be zero, in case is too far for BEQ dr_ok (3/2)
			JMP dr_ok			; all done otherwise (0/4)
dr_inst:
		STA da_ptr			; store full pointer (4)
; *** here will begin the future DRV_INST function ***
; da_ptr will be a kernel parameter

; get some info from header
		.as: SEP #$20		; *** back to 8-bit memory for a while ***
; assuming D_ID is zero, just use non-indexed indirect to get ID (not much used anyway)
;		LDY #D_ID			; offset for ID (2)
;		LDA (da_ptr), Y		; get ID code (5)
;		STA dr_id			; keep in local variable as will be often used (3)
#ifdef	SAFE
		LDA (da_ptr)			; check ID if no longer stored above
		BMI dr_phys			; only physical devices (3/2)
; logical devices cannot be installed this way, function should return INVALID error
			JMP dr_abort8		; reject logical devices, from 8-bit code (3)
dr_phys:
#endif

; *** 3) before registering, check whether the driver COULD be successfully installed ***
; that means 1.the ID is not already in use eeeeeeeek
; 2.there must be room enough on the interrupt queues for its tasks, if provided
; and 3.the D_INIT routine succeeded as usual
; otherwise, skip the installing procedure altogether for that driver

; *** 3.1) first check whether this ID was not in use ***
; since I/O pointers are always set, pseudo-drivers are detected too!
		LDA (da_ptr)			; get ID, not worth a variable (5)
		ASL					; convert to index (2+2)
		TAX
		STX dr_id			; keep this eeeeeeeek
; new 170523, TASK_DEV is nothing to be checked
		.al: REP #$20		; *** 16-bit memory *** (3)
		LDA #dr_error		; will look for this address (3)
		CMP drv_opt, X		; check whether in use (5)
			BNE dr_busy			; pointer was not empty (2/3)
		CMP drv_ipt, X		; now check input, just in case (5)
		BEQ dr_empty		; it is OK to set (3/2)
dr_busy:
; already in use, function should return FULL error code
			JMP dr_abort		; already in use (3)
dr_empty:

; 3.2) check room in queues, where needed
		.as: SEP #$20			; *** 8-bit memory again *** (3)
		LDY #D_AUTH			; let us get the provided features (2)
		LDA (da_ptr), Y			; will be checked in a non-destructive way (5)
		STA dr_aut			; also saved for later (3)
		LDX #1				; last queue (2)
dr_chk:
			ASL				; extract MSB (will be A_POLL first, then A_REQ) best done in 8-bit! (2)
			BCC dr_ntsk			; skip verification if task not enabled (3/2)
				LDY queue_mx, X		; get current tasks in queue, no offset (4)
				CPY #MX_QUEUE		; room for another? (2)
				BCC dr_ntsk			; there is (3/2)
; again, no room for driver, return FULL error code
					JMP dr_abort8		; or no way OK (3)
dr_ntsk:
			DEX					; check next feature (2)
			BPL dr_chk			; zero included (3/2)
; 3.3) if arrived here, it is possible to install, but run init code to confirm
		.al: REP #$20		; *** 16-bit memory as required by dr_icall *** (3)
		JSR dr_icall		; call routine (6+...)
		.xs: SEP #$10		; *** 8-bit indexes, again just in case *** (3)
; as 816 function exit does not care about *memory* size, just return some error here...
		.al: REP #$20		; *** 16-bit memory again, just in case *** (3)
			BCS dr_abort		; no way, forget about this (2/3) see above for function implementation

; if arrived here, it is OK to install the driver!

; *** 4) Set I/O pointers ***
; no longer checks I/O availability as any driver must provide at least dummy pointers!
; thus not worth a loop...
		LDX dr_id		; retrieve this eeeeeeeeek
		LDY #D_BLIN			; offset for input routine (2)
		LDA (da_ptr), Y		; get full address (6)
		STA drv_ipt, X		; store full pointer in table (5)
		LDY #D_BOUT			; offset for output routine (2)
		LDA (da_ptr), Y		; get full address (6)
		STA drv_opt, X		; store full pointer in table (5)

; *** 5) register interrupt routines *** new, much cleaner approach
; dr_aut is now kept intact...
; time to get a pointer to the-block-of-pointers (source)

; pfa_ptr moved to locals, ready to become a kernel function!
;pfa_ptr	= sysptr		; *** temporary, should move to locals
		LDY #D_POLL			; should be the FIRST of the three words (D_POLL, D_FREQ, D_ASYN)
		LDA (da_ptr), Y		; get full address (6)
		STA pfa_ptr		; get the pointer
; also a temporary pointer to the particular queue
		LDA #drv_poll		; must be the first one!
		STA dq_ptr			; store temporarily
; new functionality 170519, pointer to (interleaved) task enabling queues
		LDA #drv_p_en		; this is the second one, will be decremented for async
		STA dte_ptr			; yet another temporary pointer...
; all set now, now easier to use a loop
		LDX #1				; index for periodic queue (2)
; *** suspicious code follows ***
dr_iqloop:
			.as: SEP #$20		; *** 8-bit shift *** eeeeeeeeeeeeeeek
			ASL dr_aut		; extract MSB (will be A_POLL first, then A_REQ) eeeeeeeeeeeeeeeeeeeeeeeeeeeeek
			BCC dr_noten		; skip installation if task not enabled
; prepare another entry into queue
				LDY queue_mx, X		; get index of free entry!
;				STY dq_off			; worth saving on a local variable
				INC queue_mx, X		; add another task in queue
				INC queue_mx, X		; pointer takes two bytes
; install entry into queue
; read pointer from header (inline version of dr_itask)
				al: REP #$20		; *** 16-bit memory ***
				LDA (pfa_ptr)		; get pointer
; write pointer into queue
;				LDY dq_off			; get index of free entry!
				STA (dq_ptr), Y		; store into reserved place!
; save for frequency queue, flags must be enabled for this task!
;				LDY dq_off			; get index of free entry!
				.as: SEP #$20		; *** needs to go into 8-bit mode for a moment ***
				LDA (da_ptr)			; use ID as flags, simplifies search and bit 7 hi (as per physical device) means enabled by default
				STA (dte_ptr), Y	; set default flags
; let us see if we are doing periodic task, in case frequency must be set also
				.al: REP #$20		; *** back to 16-bit, flags unaffected *** eeeeeeeeeeeeeeek
				TXA					; doing periodic?
					BEQ dr_next			; if zero, is doing async queue, thus skip frequencies (in fact, already ended)
; future DEV_INST should just return successfully if BEQ above gets executed...
				JSR dr_nextq		; advance to next queue (frequencies)
; read frequency value from header (inline version of dr_itask)
				LDA (pfa_ptr)		; non-indexed indirect
; write unmodified value into its queue
;				LDY dq_off			; get index of free entry!
				STA (dq_ptr), Y		; store into reserved place!
; *** and copy A into drv_count, unmodified! ***
				STA drv_cnt, Y		; simply!
				BRA dr_doreq		; nothing to skip, go for async queue
dr_noten:
			.al: REP #$20		; needed for subsequent routine
			JSR dr_nextq		; if periodic was not enabled, this will skip frequencies queue
dr_doreq:
; as this will get into async, switch enabling queue
			DEC dte_ptr			; one before as it is interleaved
; continue into async queue
			JSR dr_nextq		; go for next queue
			DEX					; now 0, index for async queue (2)
			BPL dr_iqloop
; *** end of suspicious code ***
		BRA dr_next			; if arrived here, did not fail initialisation
; function arriving here will simply exit successfully

; *****************************************
; *** some driver installation routines ***
; *****************************************

; * routine for advancing to next queue *
; both pointers in dq_ptr (destination queue) and pfa_ptr (pointer to header)
; A in 16-bit mode

dr_nextq:
	LDA dq_ptr			; get original queue pointer
	CLC
	ADC #MX_QUEUE		; go to next queue
	STA dq_ptr
	INC pfa_ptr			; increment the origin pointer!
	INC pfa_ptr			; not worth the old way
	RTS

; dr_itask is now inlined, and has dq_off already in Y!

; ******************************************
; *** other driver installation routines ***
; ******************************************
dr_error:
	_DR_ERR(N_FOUND)	; standard exit for non-existing drivers!

dr_icall:
	LDY #D_INIT			; original pointer offset (2)
; *** generic driver call, pointer set at da_ptr, Y holds table offset
; *** assume 16-bit memory and 8-bit indexes ***
; takes 7 bytes (could be 2 less) 21 clocks, was 10 bytes, 29 clocks
; make certain about DBR in calls... but should be for kernel/API only
dr_call:
	LDA (da_ptr), Y		; destination pointer (6)
	DEC					; one less for RTS (2)
	PHA					; push it (4)
	.as: .xs: SEP #$30	; make sure driver is called in 8-bit size (3)
	RTS					; actual CORRECTED jump (6)

; **********************
; *** error handling ***
; **********************
; something went wrong, 8-bit mode entry point
dr_abort8:
		.al: REP #$20		; *** 16-bit memory in most of the code ***
; something went wrong, here in 16-bit Memory
dr_abort:
; no longer a difference between dr_abort and dr_next? no LOWRAM option here...

; *******************************
; *** prepare for next driver ***
; *******************************
; this will remain in kernel loop when DRV_INST is used
dr_next:
; in order to keep drivers_ad in ROM, can't just forget unsuccessfully registered drivers...
; in case drivers_ad is *created* in RAM, dr_abort could just be here, is this OK with new separate pointer tables?
		PLX					; retrieve saved index (4)
		INX					; update ADDRESS index, even if unsuccessful (2)
		INX					; eeeeeeeek! pointer arithmetic! (2)
		JMP dr_loop			; go for next (3)

; *********************************************************************
; *** drivers already installed, clean up things and finish booting ***
; *********************************************************************
dr_ok:					; *** all drivers inited ***
	PLX					; discard stored X, beware of 16-bit memory!

; **********************************
; ********* startup code ***********
; **********************************

; *** set default I/O device *** still in 16-bit memory
	LDA #DEVICE*257		; as defined in options.h **** revise as it might be different for I and O
	STA deflt_in		; should check some devices, this assumes _in is LSB

; *** interrupt setup no longer here, firmware did it! *** 20150605

; new, show a splash message ever the kernel is restarted!
; assume 16-bit memory

	JSR ks_cr			; leading newline
	LDA #kern_splash	; get pointer to string
	STA str_pt			; set parameter
	STZ str_pt+2		; clear bank!
	LDY #DEVICE			; eeeeeek
	_KERNEL(STRING)		; print it!
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
	.asc	"minimOS•16 0.6a12", 0	; version in comment
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
