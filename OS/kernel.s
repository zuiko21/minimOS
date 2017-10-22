; minimOS generic Kernel
; v0.6a15
; (c) 2012-2017 Carlos J. Santisteban
; last modified 20171022-2158

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
#include "drivers/config/DRIVER_PACK.s"
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
	.asc	"minimOS 0.6a14", 0	; version in comment

	.dsb	kern_head + $F8 - *, $FF	; padding

	.word	$6000	; time, 12.00
	.word	$4AD6	; date, 2017/6/22

kern_siz = kern_end - kern_head - $FF

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
	LDY #<k_vec			; get table address, nicer way (2+2)
	LDA #>k_vec
	STY ex_pt			; store parameter (3+3)
	STA ex_pt+1
	_ADMIN(INSTALL)		; copy jump table
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
	LDY #<supplied_brk		; get address, nicer way (2+2)
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
; separared LOWRAM & standard versions 20170902

#ifndef	LOWRAM
; ++++++ ++++++ standard version ++++++ ++++++

; *** initialise stuff ***
; clear some bytes
	LDX #0				; reset driver index (2)
	STX queue_mx		; reset all indexes, NMOS-savvy (4+4+4)
	STX queue_mx+1
; ++++++ new direct I/O tables for much faster access 20160406 ++++++
	STX run_pid			; new 170222, set default running PID *** this must be done BEFORE initing drivers as multitasking should place appropriate temporary value via SET_CURR!
dr_clear:
		_STZA cio_lock, X	; clear I/O locks! (4)
		_STZA cin_mode, X	; and binary flags, actually next address (4)
#ifdef	MUTABLE
		_STZA drv_ads, X	; ****** in case of mutable driver IDs, clear pointer array first (4+4)
		_STZA drv_ads+1, X	; ****** could just clear MSB...
#endif
		LDA #<dr_error		; make unused entries point to a standard error routine, new 20160406 (2)
		STA drv_opt, X		; set LSB for output (4)
		STA drv_ipt, X		; and for input (4)
		INX					; go for MSB (2)
		LDA #>dr_error		; had to keep it inside because no STY abs,X!!!
		STA drv_opt, X		; set MSB for output (4)
		STA drv_ipt, X		; and for input (4)
		INX					; next entry (2)
; might save RAM comparing against a limit of IDs...
		BNE dr_clear		; finish page (3/2)
; TASKDEV is no longer a thing...
;	LDX #0			; ...but reset X if using restricted ID array!!!

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
		_KERNEL(DRV_INST)	; try to install this driver

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

; ++++++ ++++++ end of standard version ++++++ ++++++

#else

; ------ ------ LOWRAM version ------ ------

; *** 1) initialise stuff ***
; clear some bytes
	LDX #0				; reset driver index (2)
	STX queue_mx		; reset all indexes, NMOS-savvy (4+4+4)
	STX queue_mx+1
; ------ low-RAM systems have no direct tables to reset ------
; ** maybe look for fast tables in ROM **
	STX drv_num			; single index of, not necessarily SUCCESSFULLY, detected drivers, updated 20150318 (4)

; *** 2) prepare access to each driver header ***
; first get the pointer to it
dr_loop:
		_PHX				; keep current value, no longer drv_aix (3)
		LDA drvrs_ad+1, X		; get address MSB (4)
		BNE dr_inst			; cannot be in zeropage, in case is too far for BEQ dr_ok (3/2)
			JMP dr_ok			; all done otherwise (0/4)
dr_inst:
		STA da_ptr+1		; store pointer MSB (3)
		LDA drvrs_ad, X		; same for LSB (4+3)
		STA da_ptr
; *** here comes the call to API function ***
;		KERNEL(DRV_INST)	; try to install this driver
; *** code for separate API function ***
; get some info from header
; as D_ID is zero, simply indirect will do without variable (not much used anyway)
#ifdef	SAFE
		_LDAY(da_ptr)			; get ID as not stored above
		BMI dr_phys			; only physical devices (3/2)
			JMP dr_iabort		; reject logical devices (3)
dr_phys:
#endif

; *** 3) before registering, check whether the driver COULD be successfully installed ***
; that means 1.the ID must not be in use eeeeeek
; 2.there must be room enough on the interrupt queues for its tasks, if provided
; and 3.the D_INIT routine succeeded as usual
; otherwise, skip the installing procedure altogether for that driver

; 3.1 is best done last...

; 3.2) check room in queues, if needed
; first get and store requested features
		LDY #D_AUTH			; let us get the provided features
		LDA (da_ptr), Y
		STA dr_aut			; a commonly used value
; check space in queues
		LDX #1				; max queue index
dr_chk:
			ASL				; extract MSB (will be A_POLL first, then A_REQ)
			BCC dr_ntsk			; skip verification if task not enabled
				LDY queue_mx, X		; get current tasks in queue
				CPY #MX_QUEUE		; room for another?
				BCC dr_ntsk			; yeah!
dr_nabort:
					JMP dr_fabort		; or did not checked OK
dr_ntsk:
			DEX					; let us check next feature
			BNE dr_chk

; 3.3) if arrived here, there is room for interrupt tasks, but check init code
		JSR dr_icall		; call routine (6+...)
			BCS dr_nabort		; no way, forget about this
; 4) LOWRAM kernel has no I/O pointers...
; finally add ID to list
		_LDAY (da_ptr)			; retrieve ID eeeeeek
#ifdef	SAFE
; 3.1) check whether this ID was not in use ***
		LDY #0				; reset index (2)
		BEQ dr_limit		; check whether has something to check, no need for BRA (3)
dr_scan:
			CMP id_list, Y		; compare with list entry (4)
				BEQ dr_babort		; already in use, do not register! (2/3)
			INY					; go for next (2)
dr_limit:	CPY drv_num			; all done? (4)
			BNE dr_scan			; go for next (3/2)
#endif
; if arrived here, succeeded, thus include ID in list
		_LDAY(da_ptr)		; get ID eeeeeeeeek
		LDX drv_num			; retrieve single offset (4)
		STA id_list, X		; store in list, now in RAM (4)

; *** 5) register interrupt routines *** new, much cleaner approach
; time to get a pointer to the-block-of-pointers (source)
		LDY #D_POLL			; should be the FIRST of the three words (D_POLL, D_FREQ, D_ASYN)
		JSR dr_gind			; get the pointer into pfa_ptr)
; also a temporary pointer to the particular queue
		LDA #<drv_poll		; must be the first one!
		STA dq_ptr			; store temporarily
		LDA #>drv_poll		; MSB too
		STA dq_ptr+1
; new functionality 170519, pointer to (interleaved) task enabling queues
		LDA #<drv_p_en		; this is the second one, will be decremented for async
		STA dte_ptr			; yet another temporary pointer...
		LDA #>drv_p_en		; same for MSB
		STA dte_ptr+1
; all set now, now easier to use a loop
		LDX #1				; index for periodic queue (2)
; *** suspicious code ***
dr_iqloop:
			ASL dr_aut			; extract MSB (will be A_POLL first, then A_REQ)
			BCC dr_noten		; skip installation if task not enabled
; prepare another entry into queue
				LDY queue_mx, X		; get index of free entry!
				STY dq_off			; worth saving on a local variable
				INC queue_mx, X		; add another task in queue
				INC queue_mx, X		; pointer takes two bytes
; install entry into queue
				JSR dr_itask		; install into queue
; save for frequency queue, flags must be enabled for this task!
				_LDAY(dr_id)			; use ID as flags, simplifies search and bit 7 hi (as per physical device) means enabled by default
				LDY dq_off			; get index of free entry!
				STA (dte_ptr), Y	; set default flags
; let us see if we are doing periodic task, in case frequency must be set also
				TXA					; doing periodic?
					BEQ dr_done			; if zero, is doing async queue, thus skip frequencies (in fact, already ended)
				JSR dr_nextq		; advance to next queue (frequencies)
				JSR dr_itask		; same for frequency queue
; *** must copy here original frequency (PLUS 256) into drv_cnt ***
				LDA (dq_ptr), Y		; get MSB
				_INC				; plus 1
				STA drv_cnt, Y		; store copy...
				STA (dq_ptr), Y		; ...and correct original value
				DEY					; go for LSB
				LDA (dq_ptr), Y		; get original...
				STA drv_count, Y	; ...and store unmodified
				_BRA dr_doreq		; nothing to skip, go for async queue
dr_noten:
			JSR dr_nextq		; if periodic was not enabled, this will skip frequencies queue
dr_doreq:
; as this will get into async, switch enabling queue
			LDA dte_ptr			; check previous LSB
			BNE dr_neqnw		; will wrap upon decrement?
				DEC dte_ptr+1		; if so, precorrect MSB
dr_neqnw:
			DEC dte_ptr			; one before as it is interleaved
; continue into async queue
			JSR dr_nextq		; go for next queue
			DEX					; now 0, index for async queue (2)
			BPL dr_iqloop		; eeeeek
; *** end of suspicious code ***

; *** 6) continue initing drivers ***
		_BRA dr_ended		; if arrived here, did not fail

; *****************************************
; *** some driver installation routines ***
; *****************************************
dr_icall:
	LDY #D_INIT			; original pointer offset (2)
; *** generic driver call, pointer set at da_ptr, Y holds table offset *** new 20150610, revised 20160412
; takes 10 bytes, 29 clocks
dr_call:
	INY					; get MSB first (2)
	LDA (da_ptr), Y		; destination pointer MSB (5)
	PHA					; push it (3)
	DEY					; go for LSB (2)
	LDA (da_ptr), Y		; repeat procedure (5)
	PHA					; push LSB (3)
	PHP					; 816 is expected to be in emulation mode anyway (3)
	RTI					; actual jump (6)

; * get indirect address from driver pointer table, 13 bytes, 33 clocks *
; da_ptr pointing to header, Y has the offset in table, returns pointer in sysptr
dr_gind:
	LDA (da_ptr), Y		; get address LSB (5)
	STA pfa_ptr			; store temporarily (3)
	INY					; same for MSB (2)
	LDA (da_ptr), Y		; get MSB (5)
	STA pfa_ptr+1		; store temporarily (3)
	RTS					; come back!!! (6)

; * routine for advancing to next queue *
; both pointers in dq_ptr (whole queue) and pfa_ptr (pointer in header)
dr_nextq:
	LDA dq_ptr			; get original queue pointer
	CLC
	ADC #MX_QUEUE		; go to next queue
	STA dq_ptr
	BCC dnq_nw			; no carry...
		INC dq_ptr+1		; ...or update MSB
dnq_nw:
	LDA pfa_ptr			; increment the origin pointer!
	CLC
	ADC #2				; next pointer in header
	STA pfa_ptr			; eeeeeeeeeeek
	BCC dnq_snw			; no carry...
		INC pfa_ptr+1		; ...or update MSB
dnq_snw:
	RTS

; * routine for copying a pointer from header into a table *
; X is 0 for async, 1 for periodic, pfa_ptr, dq_off & dq_ptr set as usual
dr_itask:
; read pointer from header
	LDY #1				; preset offset
	LDA (pfa_ptr), Y		; get MSB from header
	PHA					; stack it!
	_LDAY(pfa_ptr)		; non-indexed indirect, get LSB in A
; write pointer into queue
	LDY dq_off			; get index of free entry!
	STA (dq_ptr), Y		; store into reserved place!
	INY					; go for MSB
	PLA					; was stacked!
	STA (dq_ptr), Y
	RTS

; **********************
; *** error handling ***
; **********************
dr_iabort:
	LDY #INVALID
	_BRA dr_abort			; could use BNE instead of BRA
dr_babort:
	LDY #BUSY
	_BRA dr_abort
dr_fabort:
	LDY #FULL
	_BRA dr_abort
dr_uabort:
	LDY #UNAVAIL

; *** if arrived here, driver initialisation failed in anyway ***
; invalidate ID on list
dr_abort:
	LDX drv_num		; get failed driver index
	LDA #DEV_NULL		; positive value is unreachable
	STA id_list, X		; invalidate entry
;	SEC
;	RTS			; no macro needed as Carry was set
; *** function exits here if failed ***

dr_ended:
; LOWRAM system keep count of installed drivers
	INC drv_num		; update count
; success!
;	EXIT_OK
; ***** end of function *****

; in order to keep drivers_ad in ROM, can't just forget unsuccessfully registered drivers...
; in case drivers_ad is *created* in RAM, dr_abort could just be here, is this OK with new separate pointer tables?
		_PLX				; retrieve saved index (4)
		INX					; update ADDRESS index, even if unsuccessful (2)
		INX					; eeeeeeeek! pointer arithmetic! (2)
		JMP dr_loop			; go for next (3)

; ***************************************************************
; *** drivers already installed, clean up things and continue ***
; ***************************************************************
dr_ok:					; *** all drivers inited ***
	PLA					; discard stored X, no hassle for NMOS

; in case no I/O lock arrays were initialised... only for LOWRAM
	_STZA cin_mode		; single flag for non-multitasking systems

; ------ ------ end of LOWRAM version ------ ------

#endif

; **********************************
; ********* startup code ***********
; **********************************

; startup code, revise ASAP
; *** set default I/O device ***
	LDA #DEVICE			; as defined in options.h
	STA defltout		; should check some devices
	STA deflt_in

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
here:
	_BRA here			; ...as the scheduler will detour execution

; a quick way to print a newline on standard device
ks_cr:
	LDA #CR				; leading newline
	STA io_c
	LDY #DEVICE
	_KERNEL(COUT)		; print it
	RTS

; ***********************************************
; *** generic kernel routines, separate files ***
; ***********************************************
#ifndef		LOWRAM
	.asc	"<API>"		; debug only
#include "api.s"
#else
#include "api_lowram.s"
#endif

; *********************************
; *** interrupt service routine ***
; *********************************
; will include BRK handler!

k_isr:
#include "isr/irq.s"
; default NMI-ISR is on firmware!
; will include supplied BRK handler, although called by firmware

; in headerless builds, keep at least the splash string
#ifdef	NOHEAD
kern_splash:
	.asc	"minimOS 0.6a14", 0
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
shell:					; no header to skip
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
