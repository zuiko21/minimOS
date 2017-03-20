; minimOS·16 generic Kernel
; v0.5.1b17
; (c) 2012-2017 Carlos J. Santisteban
; last modified 20170320-0842

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
	.asc	"minimOS-16 0.5.1b16", 0	; version in comment
	.dsb	kern_head + $F8 - *, $FF	; padding

	.word	$9000	; time, 18.00
	.word	$4A70	; date, 2017/3/16

kern_siz = kern_end - kern_head - 256

	.word	kern_siz, 0	; kernel size excluding header 
#endif
; ##### end of minimOS header #####

; **************************************************
; *** kernel begins here, much like a warm reset ***
; **************************************************
-kernel:
warm:
	SEI					; interrupts off, just in case
	CLD					; do not assume anything
#ifdef	SAFE
	SEC
	XCE					; set emulation mode for a moment! will reset to 8-bit registers
	PHK					; this pushes a zero into stack
	PLB					; ...and resets data bank eeeeeeeeeek
#endif
; assume interrupts off, binary mode and 65C816 in emulation mode!
	CLC
	XCE					; enter native mode! still 8 bit regs, though
; worth going 16-bit for the install calls!
	.al: REP #$20		; *** 16-bit memory most of the time ***

; install kernel jump table if not previously loaded
#ifndef		DOWNLOAD
	LDA #k_vec			; get table address, nicer way (3)
	STA kerntab			; store parameter (4)
; as kernels must reside in bank 0, no need for 24-bit addressing
	_ADMIN(INSTALL)		; copy jump table, will respect register sizes
#endif

; install ISR code (as defined in "isr/irq.s" below)
	LDA #k_isr			; get address, nicer way (3)
	STA ex_pt			; no need to know about actual vector location (4)
; as kernels must reside in bank 0, no need for 24-bit addressing
	_ADMIN(SET_ISR)		; install routine, will respect sizes

; Kernel no longer supplies default NMI, but could install it otherwise

; *****************************
; *** memory initialisation ***
; *****************************
; THINK about making API entries for this!
	LDY #FREE_RAM	; dirty trick no longer allowed... should be zero
	STY ram_stat	; as it is the first entry, no index needed
	LDY #END_RAM	; also for end-of-memory marker
	STY ram_stat+2	; note offset for interleaved array!
	LDX #>user_sram	; beginning of available ram, as defined... in rom.s
	LDY #<user_sram	; LSB misaligned?
	BEQ ram_init	; nothing to align
		INX				; otherwise start at next page
ram_init:
	TXA				; will set MSB as zero
	STA ram_pos		; store it
	LDA #SRAM		; number of SRAM pages as defined in options.h *** revise
	STA ram_pos+2	; store second entry and we are done!

; ************************************************
; *** intialise drivers from their jump tables ***
; ************************************************
; THINK about making API entries for this!

; globally defined da_ptr is a pointer for indirect addressing, new CIN/COUT compatible 20150619, revised 20160413
; same with dr_aut, now independent kernel call savvy 20161103
; 16-bit revamp 20161013

	LDX #0				; reset driver index (2)
	STX dpoll_mx		; reset all indexes (4+4+4)
	STX dreq_mx
	STX dsec_mx
; clear some other bytes
	STX run_arch		; assume native 65816
	STX run_pid			; new 170222, set default running PID *** this must be done BEFORE initing drivers as multitasking should place appropriate temporary value via SET_CURR!
	STX sd_flag			; *** this is important to be clear (PW_STAT) or set as proper error handler

; already in 16-bit memory mode...
	LDA #dr_error		; make unused entries point to a standard error routine (3)
dr_clear:
		STZ cio_lock, X		; clear I/O locks and interleaved binary flags! (5)
		STA drv_opt, X		; set full pointer for output (5)
		STA drv_ipt, X		; and for input (5)
		INX					; go for next entry (2+2)
		INX
		BNE dr_clear		; finish page (3/2)

; install embedded single TASK_DEV driver anyway, a suitable driver would replace it
	LDA #st_taskdev		; pseudo-driver full address, would be in this file
	STA drv_opt			; *** assuming TASK_DEV = 128, index otherwise
; might do something similar for WIND_DEV = 129...

; first get the pointer to each driver table
dr_loop:
		PHX					; keep current value (3)
		LDA drivers_ad, X	; get full address (5)
		BNE dr_inst			; cannot be zero, in case is too far for BEQ dr_ok (3/2)
			JMP dr_ok			; all done otherwise (0/4)
dr_inst:
		STA da_ptr			; store full pointer (4)
; create entry on IDs table
		LDY #D_ID			; offset for ID (2)
		LDA (da_ptr), Y		; get ID code... plus extra byte (6)

#ifdef	SAFE
		TAX					; check sign, faster! (2)
		BMI dr_phys			; only physical devices (3/2)
			JMP dr_abort		; reject logical devices (3)
dr_phys:
#endif

		ASL					; convert to index, no matter the MSB (2+2)
		TAX
; new 161014, TASK_DEV (128 turns into 0 as index) does NOT get checked, allowing default installation
		BEQ dr_empty
; alternative in case of WIND_DEV managed similarly
;		CPX #4				; first index that will be managed normally
;		BCC dr_empty		; 0 & 2 (TASK_DEV & WIND_DEV) will NOT be checked from default installation
			LDA #dr_error		; will look for this address (3)
			CMP drv_opt, X		; check whether in use (5)
				BNE dr_busy			; pointer was not empty (2/3)
			CMP drv_ipt, X		; now check input, just in case (5)
			BEQ dr_empty		; it is OK to set (3/2)
dr_busy:
			JMP dr_abort		; already in use (3)
dr_empty:
		LDY #D_COUT			; offset for output routine (2)
		LDA (da_ptr), Y		; get full address (6)
		STA drv_opt, X		; store full pointer in table (5)
		LDY #D_CIN			; same for input routine (2)
		LDA (da_ptr), Y		; get full address (6)
		STA drv_ipt, X		; store full pointer in table (5)

; register interrupt routines (as usual)
		LDY #D_AUTH			; offset for feature code (2)
		LDA (da_ptr), Y		; get auth code... plus extra byte (6)
		STA dr_aut			; and keep for later! (4)
		BIT #A_POLL			; check whether D_POLL routine is avaliable (2)
		BEQ dr_nopoll		; no D_POLL installed (2/3)
			LDY #D_POLL			; get offset for periodic vector (2)
			LDX dpoll_mx		; get destination index (4)
			CPX #MAX_QUEUE		; compare against limit (2)
				BCS dr_abort		; error registering driver! (2/3) nothing was queued
			LDA (da_ptr), Y		; get full pointer bytes (6)
			STA drv_poll, X		; store word in list (5)
			INX					; increase index (2+2)
			INX
			STX dpoll_mx		; save updated index (4)
			LDA dr_aut			; get auth code... plus extra byte (4)
dr_nopoll:
		BIT #A_REQ			; check D_REQ presence (2)
		BEQ dr_noreq		; no D_REQ installed (2/3)
			LDY #D_REQ			; get offset for async vector (2)
			LDX dreq_mx			; get destination index (4)
			CPX #MAX_QUEUE		; compare against limit (2)
				BCS dr_ab_p			; error registering driver! (2/3) check poll!
			LDA (da_ptr), Y		; get full pointer (6)
			STA drv_async, X	; store word in list (5)
			INX					; increase index (2+2)
			INX
			STX dreq_mx			; save updated index  (4)
			LDA dr_aut			; get auth code... plus extra byte (4)
dr_noreq:
		BIT #A_SEC			; check D_SEC (2)
		BEQ dr_nosec		; no D_SEC installed (2/3)
			LDY #D_SEC			; get offset for 1-sec vector (2)
			LDX dsec_mx			; get destination index (4)
			CPX #MAX_QUEUE		; compare against limit (2)
				BCS dr_abpr		; error registering driver! (2/3) check poll & req!
			LDA (da_ptr), Y		; get full pointer (6)
			STA drv_sec, X		; store word in list (5)
			INX					; increase index (2+2)
			INX
			STX dsec_mx			; save updated index (4)
dr_nosec:
; continue initing drivers
; ***maybe best to do this BEFORE installing queues, aborted drivers will be easier to reset
		JSR dr_icall		; call routine (6+...)
		.al: REP #$20		; *** 16-bit memory again, just in case ***
		.xs: SEP #$10		; *** 8-bit indexes, again just in case ***
		BCC dr_next			; did not failed initialisation
			LDY #D_AUTH
			LDA (da_ptr), Y		; get auth code... plus extra byte (6)
			BIT #A_SEC			; any slow?
			BNE dr_abpr			; none to remove
				DEC dsec_mx			; otherwise remove from queue!
				DEC dsec_mx			; two-byte pointer
dr_abpr:
			BIT #A_REQ			; any async?
			BNE dr_ab_p			; none to remove
				DEC dreq_mx			; otherwise remove from queue!
				DEC dreq_mx			; two-byte pointer
dr_ab_p:
			BIT #A_POLL			; any jiffy?
			BNE dr_abort		; none to remove
				DEC dpoll_mx		; otherwise remove from queue!
				DEC dpoll_mx		; two-byte pointer
dr_abort:
			LDY #D_ID			; offset for ID (2)
			LDA (da_ptr), Y		; get ID code... plus extra (6)
#ifdef	SAFE
			BIT #$0080			; check whether it was a valid physical device, negative LSB (
				BEQ dr_next			; nothing to delete (2/3)
#endif
			ASL					; use retrieved ID as index (2+2)
			TAX					; will keep LSB only
			BEQ dr_abmm			; aborted multitasking will revert to supplied single-task driver!!!
				LDA #dr_error		; make deleted entries point to a standard error routine (3)
				BRA dr_abptr		; set standard pointer
dr_abmm:
			LDA #st_taskdev		; a multitasking effort was aborted
dr_abptr:
			STA drv_opt, X		; set full pointer for output (5)
			STA drv_ipt, X		; and for input (5)
dr_next:
; in order to keep drivers_ad in ROM, can't just forget unsuccessfully registered drivers...
; in case drivers_ad is *created* in RAM, dr_abort could just be here, is this OK with new separate pointer tables?
		PLX					; retrieve saved index (4)
		INX					; update ADDRESS index, even if unsuccessful (2)
		INX					; eeeeeeeek! pointer arithmetic! (2)
		JMP dr_loop			; go for next (3)

dr_error:
	_DR_ERR(N_FOUND)	; standard exit for non-existing drivers!

dr_icall:
	LDY #D_INIT			; original pointer offset (2)
; *** generic driver call, pointer set at da_ptr, Y holds table offset
; *** assume 16-bit memory and 8-bit indexes ***
; takes 7 bytes (could be 2 less) 21 clocks, was 10 bytes, 29 clocks
; make certain about DBR in calls...
dr_call:
	LDA (da_ptr), Y		; destination pointer MSB (6)
	DEC					; one less for RTS (2)
	PHA					; push it (4)
	.as: .xs: SEP #$30	; make sure driver is called in 8-bit size (3)
	RTS					; actual CORRECTED jump (6)

dr_ok:					; *** all drivers inited ***
	PLX					; discard stored X, beware of 16-bit memory!

; **********************************
; ********* startup code ***********
; **********************************

	.al					; as outside dr_call routine will be doing 16-bit memory!

; *** set default SIGTERM handler for single-task systems, new 20150514 ***
; **** since shell will be launched via proper B_FORK & B_EXEC, do not think is needed any longer!
; could be done always, will not harm anyway
	LDA #sig_kill		; get default routine full address, we are still in 16-bit memory
	STA mm_sterm		; store in new system variable
	LDX #0				; beware of 16-bit memory!
	STX mm_sterm+2		; clear default bank!!! just before pointer for easy 24-bit addressing

; startup code

; *** set default I/O device *** still in 16-bit memory
	LDA #DEVICE*257		; as defined in options.h **** revise as it might be different for I and O
	STA default_in		; should check some devices, this assumes _in is LSB
; do not forget setting local devices via B_EXEC

; *** interrupt setup no longer here, firmware did it! *** 20150605
; new, show a splash message ever the kernel is restarted!
; assume 16-bit memory
	JSR ks_cr			; leading newline
	LDA #kern_splash	; get pointer to string
	STA str_pt			; set parameter
	STZ str_pt+2		; clear bank!
	LDY #DEVICE			; eeeeeek
	_KERNEL(STRING)		; print it!
	_KERNEL(STRING)		; why do I have to print it twice??? It only appears once
	JSR ks_cr			; trailing newline

; ******************************
; **** launch monitor/shell ****
; ******************************
sh_exec:
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
	_KERNEL(B_FORK)		; reserve first execution braid, no direct deindexed call because of 16-bit memory!
	CLI					; should enable interrupts at some point... eeeeeeeek
	_KERNEL(B_EXEC)		; go for it! no direct deindexed call because of 16-bit memory!
	_KERNEL(B_YIELD)	; ** get into the working code ASAP! ** might be fine for 6502 too
here:
	BRA here			; ...as the scheduler will detour execution

; ***** debug code *****
; a quick way to print a newline (or a debugging '!') on standard device
ks_cr:
	LDY #CR				; leading newline, 8-bit
ksc_pry:
	STY io_c
	LDY #DEVICE
	_KERNEL(COUT)		; print it
	RTS
debug:
	LDY #'!'			; *** debug mark ****
	BRA ksc_pry			; *** go print it ***

; *** generic kernel routines, now in separate file 20150924 *** new filenames
#ifndef		C816
#include "api.s"
#else
#include "api16.s"
#endif

; in case of no headers, keep splash ID string
#ifdef	NOHEAD
kern_splash:
	.asc	"minimOS-16 0.5.1b16", 0	; version in comment
#endif

; *****************************************************
; *** default single-task driver, new here 20161109 ***
; *****************************************************
; only to be installed if no multitasking driver already present! 20161115
#ifndef	MULTITASK
st_taskdev:
	JMP (st_tdlist, X)	; call appropriate code, will return to original caller

; pointer list for single-task management routines
st_tdlist:
	.word	st_fork		; reserve a free braid (will go BR_STOP for a moment)
	.word	st_exec		; get code at some address running into a paused braid (will go BR_RUN)
	.word	st_yield	; switch to next braid, likely to be ignored if lacking hardware-assisted multitasking
	.word	st_signal	; send some signal to a braid
	.word	st_status	; get execution flags for a braid
	.word	st_getpid	; get current PID
	.word	st_hndl		; set SIGTERM handler
;	.word	st_prior	; priorize braid, jump to it at once, really needed? *** might deprecate for B_INFO or so

; diverse driver data
; this table could be suppressed via EOR on CPU-flagging code
;arch_tab:
;	.asc	"VRBN"		; 65xx codes are 65816, Rockwell, CMOS & NMOS (new order)

; ** single-task management routines **
; called from API, make certain about DBR or use long addressing!!!

.as:.xs					; all of these will be called from API!

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
;st_prior:
#ifdef	SAFE
	TYA					; should be system reserved PID, best way
	BEQ exec_st			; OK for single-task system
		_DR_ERR(NO_RSRC)	; no way without multitasking
exec_st:
#endif
; initialise stack EEEEEEK
	LDA #1				; standard stack page
	XBA					; use as MSB
	LDA #$FF			; initial stack pointer
	TCS					; eeeeeeeeeek
; this should now work for both 02 and 816 apps
	LDY ex_pt+2			; get bank first! keep it
; *** as this version has no non-XIP support, no real need for the following ***
; *** first push the 24-bit pointer, when non-XIP is available
;	PHY					; push it
;	PEI (ex_pt)			; push the rest of the pointer
; *** the above for non-XIP support ***
; check architecture, 6502 code currently on bank zero only!
	LDA cpu_ll			; check architecture
; set run_arch as per architecture!
; *** might just do EOR #'V' to detect 65816! ***
;	LDX #0				; reset index
;arch_loop:
;		CMP @arch_tab, X	; compare with list item
;			BEQ arch_ok			; detected!
;		INX					; next
;		CPX #4				; supported limit?
;		BNE arch_loop		; still to go
; No valid code found, should try to free non-XIP allocated RAM
;	DR_ERR(INVALID)	; cannot execute this! should be a mere error
;arch_ok:
;	TXA					; make equivalent code from index!
;	ASL					; two times to make it SIGterm flag savvy!
; ...and store at run_arch
; *** could just store the EOR result, see above ***
	EOR #'V'			; ** will be zero only for native **
	STA @run_arch		; set as current, note long addressing eeeeeeek
; new approach, reusing 816 code!
	TAX					; recheck architecture
		BEQ exec_long		; native 816 will always push standard return bank
; here is to manage 65xx02 code ***temporarily limited to bank zero
	TYX					; check bank for a moment
	BEQ exec_long		; already in bank zero means no need to install wrapper *** ***
; *** in case 6502 code is running beyond bank zero, setup wrapper here! ***
; after that, push alternative (wrapper) return address
;		PHY					; push target bank
; *** is the above needed for 02 code? should not harm anyway ***
;		PEA $FFC4			; sample return address, will point to a JML sig_kill
;		BRA exec_retset		; all done?
; *** in the meanwhile, just reject the request ***
; should deallocate resources, just like an invalid CPU!
		_DR_ERR(INVALID)	; 6502 code not yet supported on that address
; long indirect call, just push the proper return address, both RTS & RTL savvy
exec_long:
	PHK					; push return bank address, actually zero (3) no matter the architecture!
	PEA sig_kill-1		; push corrected return address (5)
; ** if an alternative return address (wrapper) was pushed, jump here
exec_retset:
; set context space!
	LDA #ZP_AVAIL		; eeeeeeek!
	STA z_used			; otherwise SAFE will not work!
; right now should set DBR as there is no scheduler to preload it! eeeeeeek
	PHY					; push bank into stack for a moment
	PLB					; ...and now properly set for the task
; somehow should set registers, API TBD...
; jump to code!
; already in full 8-bit mode as assumed
	JMP [ex_pt]			; forthcoming RTL (or RTS) will end via SIGKILL

; SET_HNDL for single-task systems
st_hndl:
	.al: REP #$20		; *** 16-bit memory size ***
	LDA ex_pt			; get pointer
; must check for 02 code in order to get bank from current DBR!
	LDY run_arch		; check current code
	BEQ st_sh16			; if native, bank is set
		PHB					; otherwise get current *** find another way for multitasking!
		PLX					; get it on reg
		BRA st_shset		; no need to load
st_sh16:
	LDX ex_pt+2			; please, take bank too
st_shset:
	STA @mm_sterm		; store in single variable, 24-bit addr!
	.as: SEP #$20		; *** back to 8-bit ***
	TXA					; no long STX...
	STA @mm_sterm+2		; bank stored just after regular pointer, 24-bit addr!
	_DR_OK
.as						; back to regular API call, just in case

; B_STATUS for single-task systems
; ***this one does not provide CPU-type flags!!!
st_status:
	LDY #BR_RUN			; single-task systems are always running, or should I make an error instead?
; ***might need to add CPU info inside
;	LDA #BR_RUN
;	ORA run_arch			; only if properly set, EOR hack is NOT allowed!
;	TAY
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
	PHK					; needed for new interface as will end in RTI!
	PEA st_yield		; correct return address
	PHP					; eeeeeeeeeeeek
	.as: .xs: SEP #$30	; *** make certain TERM handler is called in standard register size! ***
	JMP [mm_sterm]		; actual JUMP, will return to sig_yield
sig_kill:
; since it could arrive here from the end of a task, restore register sizes!
	.as: .xs: SEP #$30	; *** standard sizes ***
; then, free up all memory from previous task
	LDY #0				; standard PID
	_KERNEL(RELEASE)	; free all memory eeeeeeeek
; *** when non-XIP is available, try to free address from stack bottom
;	LDX #3				; number of bytes for pointer
;sk_loop:				; *** this code valid for singletask 816 ***
;		LDA @$01FC, X		; get byte from bottom of stack
;		STA ma_pt, X		; set pointer
;		DEX					; previous byte
;		BNE sk_loop			; until all done
;	KERNEL(FREE)		; try to release non-XIP code block! ***check out bank byte
; new, check whether a shutdown command was issued
	LDA @sd_flag		; some action pending? 24-bit!
	BEQ rst_shell		; if not, just restart shell
		LDY #PW_CLEAN		; otherwise, complete ordered shutdown
		_KERNEL(SHUTDOWN)
rst_shell:
; at last, restart shell!
	JMP sh_exec			; relaunch shell! eeeeek
#endif

; *** new, sorted out code 20150124 ***
; *** interrupt service routine ***
; will include BRK handler!

k_isr:
#ifndef	C816
#include "isr/irq.s"
#else
#include "isr/irq16.s"
#endif
; default NMI-ISR is on firmware!

kern_end:		; for size computation
; ***********************************************
; ***** end of kernel file plus API and IRQ *****
; ***********************************************

; *** place here the shell code, must end in FINISH macro, currently with header ***
; must NOT include external shell label!!!
shellcode:
; first determine actual shell address, no longer internally defined!
#ifdef	NOHEAD
shell	= shellcode			; no header to skip
#else
shell	= shellcode+256		; skip header
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
