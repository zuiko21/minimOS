; minimOS generic Kernel
; v0.6a1
; (c) 2012-2017 Carlos J. Santisteban
; last modified 20170518-1445

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
	.asc	"minimOS 0.6a1", 0	; version in comment

	.dsb	kern_head + $F8 - *, $FF	; padding

	.word	$5000	; time, 10.00
	.word	$4AB2	; date, 2017/5/18

kern_siz = kern_end - kern_head - $FF

	.word	kern_siz, 0	; kernel size excluding header 
#endif

; **************************************************
; *** kernel begins here, much like a warm reset ***
; **************************************************

-kernel:
warm:
	SEI				; interrupts off, just in case (2)
	CLD				; just in case, a must for NMOS (2)
#ifdef	SAFE
; * this is in case a 65816 is being used, but still compatible with all * EXCEPT Kowlaski
#ifdef	C816
	SEC				; would set back emulation mode on C816
	.byt	$FB		; XCE on 816, NOP on C02, but illegal 'ISC $0005, Y' on NMOS!
	ORA $0			; the above would increment some random address in zeropage (NMOS) but this one is inocuous on all CMOS
#endif
; * end of 65816 specific code *
#endif
; assume interrupts off, binary mode and 65C816 in emulation mode!
; install kernel jump table if not previously loaded, NOT for 128-byte systems
#ifndef	LOWRAM
; ++++++
#ifndef		DOWNLOAD
	LDY #<k_vec			; get table address, nicer way (2+2)
	LDA #>k_vec
	STY ex_pt			; store parameter (3+3)
	STA ex_pt+1
	_ADMIN(INSTALL)		; copy jump table (14...)
#endif
; ++++++
#endif

; install ISR code (as defined in "isr/irq.s" below)
	LDY #<k_isr			; get address, nicer way (2+2)
	LDA #>k_isr
	STY ex_pt			; no need to know about actual vector location (3)
	STA ex_pt+1
	_ADMIN(SET_ISR)		; install routine (14...)

; Kernel no longer supplies default NMI, but could install it otherwise

; *****************************
; *** memory initialisation ***
; *****************************

#ifndef		LOWRAM
; ++++++
	LDY #FREE_RAM		; get status of whole RAM
	STY ram_stat		; as it is the first entry, no index needed
	LDY #END_RAM		; also for end-of-memory marker
	STY ram_stat+1		; second entry in array
	LDX #>user_sram		; beginning of available ram, as defined... in rom.s
	LDY #<user_sram		; LSB misaligned?
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
; sometime will create API entries for these, but new format is urgent!
; * will also initialise I/O lock arrays! * 20161129

; *** 1) initialise stuff ***
; driver full install is new 20150208
	LDX #0				; reset driver index (2)
	STX queues_mx		; reset all indexes, NMOS-savvy (4+4+4)
	STX queues_mx+1
; clear some other bytes
; runarch not used here as no API/ABI differences
	STX sd_flag			; this is important to be clear (PW_STAT) or set as proper error handler

#ifdef LOWRAM
; ------ low-RAM systems have no direct tables to reset ------
; ** maybe look for fast tables in ROM **
	STX drv_num			; single index of, not necessarily SUCCESSFULLY, detected drivers, updated 20150318 (4)
; ------
#else
; ++++++ new direct I/O tables for much faster access 20160406 ++++++
	STX run_pid			; new 170222, set default running PID *** this must be done BEFORE initing drivers as multitasking should place appropriate temporary value via SET_CURR!
dr_clear:
		_STZA cio_lock, X	; clear I/O locks! (4)
		_STZA cin_mode, X	; and binary flags, actually next address (4)
		LDA #<dr_error		; make unused entries point to a standard error routine, new 20160406 (2)
		STA drv_opt, X		; set LSB for output (4)
		STA drv_ipt, X		; and for input (4)
		INX					; go for MSB (2)
		LDA #>dr_error		; had to keep it inside because no STY abs,X!!!
		STA drv_opt, X		; set MSB for output (4)
		STA drv_ipt, X		; and for input (4)
		INX					; next entry (2)
		BNE dr_clear		; finish page (3/2)
; TASKDEV is no longer a thing...
; ++++++
#endif

; *** 2) prepare access to each driver header ***
; first get the pointer to each driver table
dr_loop:
		_PHX				; keep current value, no longer drv_aix (3)
		LDA drivers_ad+1, X	; get address MSB (4)
		BNE dr_inst			; cannot be in zeropage, in case is too far for BEQ dr_ok (3/2)
			JMP dr_ok			; all done otherwise (0/4)
dr_inst:
		STA da_ptr+1		; store pointer MSB (3)
		LDA drivers_ad, X	; same for LSB (4+3)
		STA da_ptr
; create entry on IDs table ** new 20150219
		LDY #D_ID			; offset for ID (2)
		LDA (da_ptr), Y		; get ID code (5)
		STA dr_id			; keep in local variable as will be often used
#ifdef	SAFE
		BMI dr_phys			; only physical devices (3/2)
			JMP dr_abort		; reject logical devices (3)
dr_phys:
#endif
		LDY #D_AUTH			; let us get the provided features
		LDA (da_ptr), Y
		STA dr_feat			; another commonly used value
		STA dr_aut			; also into temporary variable for checking

; *** before registering, check whether the driver COULD be successfully installed ***
; that means 1) there must be room enough on the interrupt queues for its tasks, if provided
; and 2) the D_INIT routine succeeded as usual
; otherwise, skip the installing procedure altogether for that driver
		LDX #2				; number of queues
dr_chk:
			ASL dr_aut			; extract MSB (will be A_POLL first, then A_REQ)
			BCC dr_ntsk			; skip verification if task not enabled
				LDY queues_mx-1, X	; get current tasks in queue
				CPY #MAX_QUEUE		; room for another?
					BCS dr_abort			; did not checked OK
dr_ntsk:
			DEX					; let us check next feature
			BNE dr_chk
; if arrived here, there is room for interrupt tasks, but check init code
		JSR dr_icall		; call routine (6+...)
			BCS dr_abort		; now way, forget about this
; *** 3) driver is OK to install, just check whether this ID was not in use ***
		LDA dr_id			: retrieve saved ID

#ifndef	LOWRAM
; ++++++ new faster driver list 20151014, revamped 20160406 ++++++
		ASL					; use retrieved ID as index (2+2)
		TAX					; was Y
; new 170518, TASK_DEV is nothing to be checked
		LDA #<dr_error		; pre-installed LSB (2)
		CMP drv_opt, X		; check whether in use (4)
			BNE dr_busy			; pointer was not empty (2/3)
		CMP drv_ipt, X		; now check input, just in case (4)
			BNE dr_busy			; pointer was not empty (2/3)
		LDA #>dr_error		; now look for pre-installed MSB (2)
		CMP drv_opt+1, X	; check whether in use (4)
			BNE dr_busy			; pointer was not empty (2/3)
		CMP drv_ipt+1, X	; now check input, just in case (4)
		BEQ dr_empty		; it is OK to set (3/2)
dr_busy:
			JMP dr_abort		; already in use (3)
dr_empty:
; might check here whether I/O are provided!
;		ASL dr_aut			; look for CIN (5)
;		BCC dr_seto			; no input for this!
			LDY #D_CIN			; same for input routine (2)
			JSR dr_gind			; get indirect address
			LDA sysptr			; get driver table LSB (3)
			STA drv_ipt, X		; store in table (4)
			LDA sysptr+1		; same for MSB (3+4)
			STA drv_ipt+1, X
dr_seto:
;		ASL dr_aut			; look for COUT (5)
;		BCC dr_nout			; no output for this!
			LDY #D_COUT			; offset for output routine (2)
			JSR dr_gind			; get indirect address
			LDA sysptr			; get driver table LSB (3)
			STA drv_opt, X		; store in table (4)
			LDA sysptr+1		; same for MSB (3+4)
			STA drv_opt+1, X
dr_nout:
; ++++++
#else
; ------ IDs table filling for low-RAM systems ------
#ifdef	SAFE
; check whether the ID is already in use
		LDY #0				; reset index (2)
		BEQ dr_limit		; check whether has something to check, no need for BRA (3)
dr_scan:
			CMP drivers_id, Y	; compare with list entry (4)
				BEQ dr_abort		; already in use, don't register! (2/3)
			INY					; go for next (2)
dr_limit:	CPY drv_num			; all done? (4)
			BNE dr_scan			; go for next (3/2)
#endif
		LDX drv_num			; retrieve single offset (4)
		STA drivers_id, X	; store in list, now in RAM (4)
; ------
#endif

; *** 4) register interrupt routines *** new, much simpler approach
		LDA dr_feat			; get original auth code (3)
		STA dr_aut			; and keep for later! (3)
; time to get a pointer to the-block-of-pointers (source)
		LDY #D_POLL			; should be the FIRST of the three words (D_POLL, D_FREQ, D_REQ)
		JSR dr_gind			; get the pointer into sysptr (move to locals?)
; also a temporary pointer to the particular queue
		LDA #<drv_poll		; must be the first one!
		STA dq_ptr			; store temporarily
		LDA #>drv_poll		; MSB too
		STA dq_ptr+1
		LDX #2				; index is number of queues (2)
dr_task:
			ASL dr_aut			; extract MSB (will be A_POLL first, then A_REQ)
			BCC dr_noten		; skip installation if task not enabled
; prepare another entry into queue
				INC queues_mx, X	; add another task in queue
				INC queues_mx, X	; pointer takes two bytes
; read pointer from header
dr_copyq:
				LDY #1				; reset offset (note order)
				LDA (sysptr), Y		; get MSB from header
				PHA					; stack it!
				_LDAY(sysptr)		; non-indexed indirect, get LSB in A
; write pointer into queue
				LDY queues_mx, X	; get index of free entry!
				STA (dq_ptr), Y		; store into reserved place!
				INY					; go for MSB
				PLA					; was stacked!
				STA (dq_ptr), Y
; do not know if it was periodic, should skip the ASL as is related queue
				JSR dr_nextq		; switch to next queue
				LDA dq_ptr			; check current feature for a moment
				CMP #<drv_freq		; just did the periodic?
					BEQ dr_copyq		; simply copy the frquency, then
					BNE dr_nxque		; or go for last one!
dr_noten:
			JSR dr_nextq		; switch to next queue
			LDA dq_ptr			; check current feature for a moment
			CMP #<drv_freq		; periodic was not enabled?
				BEQ dr_noten		; then skip frequency queue ***clumsy way, saves some bytes***
dr_nxque:
			DEX					; let us check next feature
			BPL dr_task
				
; * routine for advancing to next queue *		
dr_nextq:
	LDA dq_ptr			; get original queue pointer
	CLC
	ADC #MAX_QUEUE		; go to next queue
	STA dq_ptr
	BCC dnq_nw			; no carry...
		INC dq_ptr+1		; ...or update MSB
dnq_nw:
	LDA sysptr			; increment the origin pointer!
	CLC
	ADC #2				; next pointer in header
	BCC dnq_snw			; no carry...
		INC sysptr+1		; ...or update MSB
	RTS









; continue initing drivers
		BCC dr_next			; did not fail initialisation
; *** if arrived here, driver initialisation failed in some way! ***
			PLA					; discard saved ID...
#ifdef	LOWRAM
; ------ low-RAM systems keep count of installed drivers ------
dr_abort:
dr_ab_p:	; placeholder labels!!! REVISE
dr_abpr:
			LDY drv_num			; get failed driver index (4)
			LDA #DEV_NULL		; make it unreachable, any positive value (logic device) will do (2)
			STA drivers_id, Y	; delete older value (4)
; ------
#else
; ++++++



dr_abort:
			LDY #D_ID			; offset for ID (2)
			LDA (da_ptr), Y		; get ID code (5)
				BPL dr_next			; nothing to delete (2/3)
			ASL					; use retrieved ID as index (2+2)
			TAX					; was TAY
; ++++++
#endif
dr_next:
#ifdef	LOWRAM
; ------ low-RAM systems keep count of installed drivers ------
		INC drv_num			; update SINGLE index (6)
; ------
#endif
; in order to keep drivers_ad in ROM, can't just forget unsuccessfully registered drivers...
; in case drivers_ad is *created* in RAM, dr_abort could just be here, is this OK with new separate pointer tables?
		_PLX				; retrieve saved index (4)
		INX					; update ADDRESS index, even if unsuccessful (2)
		INX					; eeeeeeeek! pointer arithmetic! (2)
		JMP dr_loop			; go for next (3)

; get indirect address from driver pointer table, 13 bytes, 33 clocks
dr_gind:
	LDA (da_ptr), Y		; get address LSB (5)
	STA sysptr			; store temporarily (3)
	INY					; same for MSB (2)
	LDA (da_ptr), Y		; get MSB (5)
	STA sysptr+1		; store temporarily (3)
	RTS					; come back!!! (6)

dr_error:
	_DR_ERR(N_FOUND)	; standard exit for non-existing drivers!

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

dr_ok:					; *** all drivers inited ***
	PLA					; discard stored X, no hassle for NMOS
#ifdef	LOWRAM
; ------ terminate ID list ------
	LDX drv_num			; retrieve single index (4)
	_STZA drivers_id, X	; terminate list, and we are done! (4)
; ------
#endif

; **********************************
; ********* startup code ***********
; **********************************

#ifndef		MULTITASK
; in case no I/O lock arrays were initialised...
	_STZA cin_mode		; single flag for non-multitasking systems
; *** set default SIGTERM handler for single-task systems, new 20150514 ***
; **** since shell will be launched via proper B_FORK & B_EXEC, do not think is needed any longer!
; could be done always, will not harm anyway
	LDY #<sig_kill		; get default routine address LSB
	LDA #>sig_kill		; same for MSB
	STY mm_sterm		; store in new system variable
	STA mm_sterm+1
#endif

; startup code, revise ASAP
; *** set default I/O device ***
	LDA #DEVICE			; as defined in options.h
	STA default_out		; should check some devices
	STA default_in

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
	LDY #<shell			; get pointer to built-in shell
	LDA #>shell			; as per mandatory label, no header to skip!
	STY ex_pt			; set execution address
	STA ex_pt+1
	LDA #DEVICE			; *** revise
	STA def_io			; default local I/O
	STA def_io+1
	JSR b_fork			; reserve first execution braid
;	CLI					; enable interrupts *** this is dangerous!
	JSR b_exec			; go for it! EXEC should enable interrupts from launched process anyway
	JSR yield			; run ASAP
here:
	_BRA here			; ...as the scheduler will detour execution

; a quick way to print a newline on standard device
ks_cr:
	LDA #CR				; leading newline
	STA io_c
	LDY #DEVICE
	_KERNEL(COUT)		; print it
	RTS

; *** generic kernel routines, now in separate file 20150924 *** new filenames
#ifndef		LOWRAM
	.asc	"<API>"		; debug only
#include "api.s"
#else
#include "api_lowram.s"
#endif

; *** pseudo-driver for non-multitasking systems! ***
; only to be installed if no proper multitasking driver is present! 20161115
#ifndef	LOWRAM
st_taskdev:
	_JMPX(st_tdlist)	; call appropriate code, will return to original caller

; pointer list for single-task management routines
st_tdlist:
	.word	st_fork		; reserve a free braid (will go BR_STOP for a moment)
	.word	st_exec		; get code at some address running into a paused braid (will go BR_RUN)
	.word	st_yield	; switch to next braid, likely to be ignored if lacking hardware-assisted multitasking
	.word	st_signal	; send some signal to a braid
	.word	st_status	; get execution flags for a braid
	.word	st_getpid	; get current PID
	.word	st_hndl		; set SIGTERM handler
	.word	st_prior	; priorize braid, jump to it at once, really needed?

; ** single-task management routines **

; B_FORK for non-multitasking systems
; GET_PID for non-multitasking systems
st_fork:
st_getpid:
	LDY #0				; no multitasking, system reserved PID anytime
; B_YIELD for non-multitasking systems
st_yield:
	_DR_OK				; YIELD has no other task to give CPU time to!

; B_EXEC for non-multitasking systems
st_exec:
st_prior:
#ifdef	SAFE
	TYA					; should be system reserved PID, best way
	BEQ exec_st			; OK for single-task system
		_DR_ERR(NO_RSRC)	; no way without multitasking
exec_st:
#endif
; initialise stack EEEEEEK
	LDX #SPTR
	TXS					; eeeeeeeeeek
; push return address towards KILL routine
	LDA #>sig_kill-1	; get routine MSB, corrected for RTS eeeeeeek
	PHA
	LDA #<sig_kill-1	; same for LSB
	PHA
; set context space!
	LDA #ZP_AVAIL		; eeeeeeek!
	STA z_used			; otherwise SAFE will not work!
; jump to code!
	CLI					; the place to do it???
	JMP (ex_pt)

; SET_HNDL for single-task systems
st_hndl:
	LDY ex_pt			; get pointer
	LDA ex_pt+1			; get pointer MSB
	STY mm_sterm		; store in single variable (from unused table)
	STA mm_sterm+1
	_DR_OK

; B_STATUS for single-task systems
st_status:
	LDY #BR_RUN			; single-task systems are always running, or should I make an error instead?
	_DR_OK

; B_SIGNAL for single-task systems
st_signal:
#ifdef	SAFE
	TYA					; check correct PID, really needed?
		BNE sig_pid			; strange error?
#endif
	LDY b_sig			; get the signal
	CPY #SIGTERM		; clean shutdown
		BEQ sig_term
	CPY #SIGKILL		; suicide, makes any sense?
		BEQ sig_kill		; release MEMORY, windows etc
sig_pid:
	_DR_ERR(INVALID)	; unrecognised signal
sig_term:
	LDA #>st_yield		; get routine MSB eeeeeeek
	PHA
	LDA #<st_yield		; same for LSB
	PHA
	PHP					; as required by RTI
	JMP (mm_sterm)		; execute handler, will return to sig_yield
sig_kill:
; first, free up all memory from previous task
;	LDY #0				; standard PID
;	JSR release			; free all memory eeeeeeeek
; new, check whether a shutdown command was issued
	LDA sd_flag			; some action pending?
	BEQ rst_shell		; if not, just restart shell
		LDY #PW_CLEAN		; otherwise, complete ordered shutdown
		_KERNEL(SHUTDOWN)	; *** could use direct call???
rst_shell:
; at last, restart shell!
	JMP sh_exec			; relaunch shell! eeeeek
#endif

; *** new, sorted out code 20150124 ***
; *** interrupt service routine ***
; will include BRK handler!

k_isr:
#include "isr/irq.s"
; default NMI-ISR is on firmware!
kern_end:		; for size computation
; ***********************************************
; ***** end of kernel file plus API and IRQ *****
; ***********************************************

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

; ****** Downloaded kernels add driver staff at the end ******
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
-user_sram = *			; the rest of available SRAM
#endif

; in headerless builds, keep at least the splash string
#ifdef	NOHEAD
kern_splash:
	.asc	"minimOS 0.6a1", 0
#endif
