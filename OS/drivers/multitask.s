; software multitasking module for minimOS
; v0.6b1
; (c) 2015-2022 Carlos J. Santisteban
; last modified 20200121-1431
; *** UNDER REVISION ***

#ifndef		HEADERS
#ifdef			TESTING
; ** special include set to be assembled via... **
; xa drivers/multitask.s -I drivers/ -DTESTING=1
#include "options.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
#else
; ** regular assembly **
#include "../usual.h"
#endif
; specific header for this driver
.bss
#include "multitask.h"
.text
#endif

; ********************************
; *** multitasking driver code ***
; ********************************

; *** MX_BRAID defined in .h for some reasonable number of braids ***
; *** delay counter for reasonable overhead will be set in header ***

.(
; *** begins with sub-function addresses table *** REVISE
	.byt	TASK_DEV	; physical driver number D_ID (currently ft0, 136)
	.byt	A_POLL		; polling scheduler this far
	.word	mm_abort	; no input
	.word	mm_abort	; no output
	.word	mm_init		; initialize device and appropiate sysvars, called by POST only *** HEAVILY REVISED
	.word	mm_sched	; periodic scheduler
	.word	10			; slowish 40ms quantum for acceptable overhead
	.word	mm_eexit	; D_ASYN does nothing
	.word	mm_eexit	; no config
	.word	mm_eexit	; no status
	.word	mm_bye		; shutdown procedure
	.word	mm_info		; points to descriptor string
	.word	0			; reserved, D_MEM

; *** driver description, NEW 20150323 ***
mm_info:
	.asc	MX_BRAID+'0', "-task Software Scheduler v0.6", 0	; works as long as no more than 9 braids!

mm_abort:
		_DR_ERR(UNAVAIL)	; error for not available features

; *** initialisation code ***
mm_init:
#ifdef	SAFE
; might check for bankswitching hardware and cause error, in order NOT to install BOTH schedulers!...
; ...or just ignore as only the first driver will install?
; hardware-assisted scheduler init code should do the opposite!
; remaining code assumes software scheduler only
	_KERNEL(TS_INFO)	; just checking availability, will actually be used by B_EXEC
		BCS mm_abort		; skip if no error eeeeeeeeeek
#endif
; initialise stack pointers and flags table, no need to initialise SP yet!
	LDA #BR_FREE		; adequate value in two highest bits, if sys_sp does NOT get inited!
	LDX #MX_BRAID		; set counter (much safer this way)
mm_rsp:
		STA mm_flags-1, X	; set braid to FREE, please note X counts from 1 but table expects indexes from 0 *** also resets integrated mm_treq
		DEX					; one braid less (much safer this way)
		BNE mm_rsp			; finish all braids (much safer this way)
	INX					; the first PID is 1
	STX mm_pid			; set index as current PID
; install procedure means now PATCHING all relevant kernel functions!
	LDY #GET_FG			; _last_ function to be patched ***new
mm_patch:
		LDA mm_funct-B_FORK, Y	; get LSB, note special offset from _first_ function saving the use of X
		STA kerntab			; set FW parameter
		LDA mm_funct-B_FORK+1, Y	; get MSB, note offset trick
		STA kerntab+1		; set FW parameter eeeeeek
		_PHY
		_ADMIN(PATCH)		; patch this function
		_PLY
		DEY
		DEY
		CPY #B_FORK-2		; until the first function is patched last
		BNE mm_patch
; *** shutdown code placeholder *** does not do much
mm_bye:
	_DR_OK				; new interface for both 6502 and 816

; *************************************************
; *** end-of-task routine, where FINISH returns ***
; *************************************************
; in case of non-XIP code (loaded file) FINISH must free its previously assigned block, taking address from stack!
mm_oblit:
;	PLA					; take LSB from stack!
;	STA ma_pt			; parameter for FREE
;	PLA					; same for MSB
;	STA ma_pt+1
;	SEI					; certainly needs interrupts off!
;	KERNEL(FREE)		; generic access
; ...and get into mm_suicide (label no longer needed)
;mm_suicide:
	LDY mm_pid			; special entry point for task ending EEEEEEEEEEEK
	SEI					; this needs to be run with interrupts OFF, do not care current status
	_STZA z_used		; *** optimise for faster switch!
	LDX #$FE			; Do not let EMPTY! eeeeeeeeeek
	TXS					; *** optimise for faster switch!
	JSR mms_kill		; complete KILL procedure and return here (ignoring errors) OK for 6502, Y set as PID
	CLC					; for safety in case RTS is found (when no other braid is active)
;	BRA mm_sched		; ...then into scheduler code, current context is irrelevant as will no longer be executable

; *** the scheduler code ***
mm_sched:
; get next available PID
	LDY #2				; to avoid deadlocks AND proper shutdown detection (2)
	LDX mm_pid			; actual PID as index (4)
mm_scan:
		DEX					; going backwards is faster (2)
			BEQ mm_wrap			; in case of wrap, remember first PID is 1 (2/3) faster implementation
mm_next:
		LDA mm_flags-1, X	; get status of entry, seems OK for first PID=1 (4)
		AND #BR_MASK		; if SIGTERM flag is integrated here, this is mandatory, does not harm (2)
;		CMP #BR_RUN			; in case is not zero as recommended
		BNE mm_scan			; zero (now equal to BR_RUN) means executable braid (3/2)
; an executable braid is found
	CPX mm_pid			; is it the same as before? (4)
	BNE mm_switch		; if not, go and switch braids (3/2)
		RTS					; otherwise, nothing to do; no need for macro (0/3)

; PID count ended, try to wrap or shutdown if no more alive tasks!
mm_wrap:
		LDX #MX_BRAID		; go to end instead, valid as last PID (2)
		DEY					; and check is not forever (2)
			BNE mm_next			; otherwise should only happen at shutdown time (3/2)
mm_lock:
		LDY #PW_CLEAN		; special code to do proper shutdown
		_KERNEL(SHUTDOWN)	; all tasks stopped, time for shutdown
		_PANIC("{TASK}")	; if ever arrives here, it was wrong at so many levels...

; arrived here in typically 40 clocks, if all braids were executable
mm_switch:
; store previous status
	STX systmp			; store temporarily new PID (3)

; *****************************
; *** save current context! ***
; *****************************
; first save both zeropage & stack from context as stated in mm_pid
	LDA #<mm_context	; possibly zero (2)
	STA sysptr			; set LSB (3)
	LDA #>mm_context-256	; get pointer to direct pages eeeeeeeeeeek (2)
	CLC					; eeeeeeeeeeek (2)
	ADC mm_pid			; compute current offset within stored direct-pages (4)
	STA sysptr+1		; indirect pointer is ready (3)
; save zeropage
	LDY z_used			; actual bytes used on zeropage (3)
	INY					; placed two bytes after, anyway (2+2)
	INY
; before loop, +26 fixed clock cycles
mm_save:
		LDA 0, Y			; get byte from zeropage (4)
		STA (sysptr), Y		; store it (5)
		DEY					; previous byte (2)

#ifdef	CBM64
		CPY #z_used			; 6510 must skip built-in port! (2)
#endif

		BNE mm_save			; until first byte, but NOT included (3/2)
; after that loop, -1+z*14 (make it z*16 for 6510) worse case +3373 (+3823 for C64)
; copy missing byte (+9)
		LDA 0, Y			; get byte from zeropage (4) Y could be 2 in C64, otherwise LDA 0 will do (one cycle less)
		STA (sysptr), Y		; store it (5)
; save kernel local context also (+385)
#ifdef	CBM64
	LDY #std_in			; first byte of system context (2)
#else
	LDY #locals			; system context (2)
#endif

mm_kern:
		LDA 0, Y			; get byte from locals and parameters (4)
		STA (sysptr), Y		; store in context area (5)
		INY					; next byte (2)
		CPY #sysptr			; this will not get copied (first byte of reserved area)
		BNE mm_kern			; up to $FF (3/2)
; keep stack pointer! (+11)
	LDY #sys_sp			; will point to last (2)
	TSX					; get index MSB (2)
	TXA					; cannot do indirect-indexed from X (2)
	STA (sysptr), Y		; store as usual (5)
; *** now do the same with stack ***
; A & X hold actual SP! before loop, +20
	TAY					; common index (2)
	LDA #<mm_stacks		; get LSB first (2)
	STA sysptr			; prepare indirect pointer (3)
	LDA #>mm_stacks-256	; prepare new pointer (2+2)
	CLC
	ADC mm_pid			; add page offset for this stack area (4)
	STA sysptr+1		; indirect pointer is ready! (3)
	INY					; point to top of stack, not first free byte (2)
; no need to check for zero as stack would not be empty! loop is -1+s*14, worse +3583, typical +349
mm_stsav:
		LDA $0100, Y		; get stack contents (4)
		STA (sysptr), Y		; storage area (5)
		INY					; go for next (2)
		BNE mm_stsav		; until the end (3/2)

; *********************************************
; *** now let's retrieve new task's context ***
; *********************************************
; compute storage address (+31 before the loop)
	LDA systmp			; retrieve new PID (3)
	STA mm_pid			; set new value, in the meanwhile (4+2)
	CLC
	ADC #>mm_context	; PID as MSB (full page for each context) (2)
	STA sysptr+1		; store pointer MSB (3)
	LDA #<mm_context	; might be zero (2)
	STA sysptr			; indirect pointer ready! (3)
; retrieve zeropage
	LDY #z_used			; offset to parameter (2)
	LDA (sysptr), Y		; actual bytes used on zeropage (5)
	TAY					; use as index! (2)
	INY					; take standard devices anyway! (2+2)
	INY
; loop takes -1+14*z (16*z in 6510) worse case +3373 (+3823 for C64)
mm_load:
		LDA (sysptr), Y		; get it (5)
		STA 0, Y			; get byte from zeropage (4)
		DEY					; previous byte (2)

#ifdef	CBM64
		CPY #z_used			; 6510 must skip built-in port!
#endif

		BNE mm_load			; until first byte, but NOT included (3/2)
; copy missing byte (9)
		LDA (sysptr), Y		; get it (5)
		STA 0, Y			; get byte from zeropage (4)
; load kernel local context also (+385)
#ifdef	CBM64
	LDY #std_in			; first byte of system context
#else
	LDY #locals			; system context
#endif

mm_lkern:
		LDA (sysptr), Y		; get from context area (5)
		STA 0, Y			; get byte from locals and parameters (4)
		INY					; next byte (2)
		CPY #sysptr			; this will not get copied (first byte of reserved area)
		BNE mm_lkern		; until sysptr not included (3/2)
; retrieve stack pointer! (+11)
	LDY #sys_sp			; will point to last (2)
	LDA (sysptr), Y		; retrieve (5)
	TAX					; cannot set SP from A (2+2)
	TXS					; new stack pointer
; *** now do the same with stack ***
; A & X hold actual SP!
	TAY					; common index
	LDA #<mm_stacks		; get LSB first
	STA sysptr			; prepare indirect pointer
	LDA #>mm_stacks-256	; prepare new pointer
	CLC
	ADC mm_pid			; add page offset for this stack area
	STA sysptr+1		; indirect pointer is ready!
	INY					; point to top of stack (not first free byte)
; no need to check for zero as stack would not be empty!
mm_stload:
		LDA (sysptr), Y		; from storage area
		STA $0100, Y		; put stack contents
		INY					; go for next
		BNE mm_stload		; until the end

; **************************************
; *** pending SIGTERM execution code ***
; **************************************
; now it's time to check whether SIGTERM was sent! new 20150611
	LDX mm_pid			; get current PID again (4)
	LDA mm_flags-1, X	; had it a SIGTERM request? (4) in case of integrated mm_treq
	LSR					; easier check of bit 0! (2)
	BCS mm_sigterm		; process it now! (2/3)
mm_rts:
		RTS					; all done, continue ISR with C clear
; *** the actual SIGTERM routine execution, new 20150611, fixed 20181029  ***
mm_sigterm:
	ASL					; ...and restore value with clear flag!
	STA mm_flags-1, X	; EEEEEEEK! clear received TERM signal, new format 20161117
; no longer pushing a fake return address to a mere RTS!
	_JMPX(mm_term-2)	; indexed indirect jump, will return to ISR (hopefully with clear C!)

; ******************************************************
; *** replacement for kernel functions *****************
; *** these end in EXIT_OK as will patch regular API ***
; ******************************************************

; *** B_FORK, reserve a free braid ***
; Y -> PID (0 = no more available braids)
mm_fork:
	LDY #MX_BRAID		; scan backwards is usually faster (2)
	_CRITIC			; this is delicate (5)
mmf_loop:
		LDA mm_flags-1, Y	; get that braid's status (4)
		AND #BR_MASK		; mandatory now, ignore TERM (2)
		CMP #BR_FREE		; check whether available (2)
			BEQ mmf_found		; got it (2/3)
		DEY					; try next (2)
		BNE mmf_loop		; until the bottom of the list (3/2)
		BEQ mmf_nfound		; ***if not found, just return PID=0
;	NO_CRIT				; nothing was found ***using a BEQ above instead...
;	ERR(FULL)			; no available braids!
mmf_found:
	LDA #BR_STOP		; *** is this OK? somewhat dangerous *** (2)
	STA mm_flags-1, Y	; reserve braid (4)
; ***could just jump here if no available slot was found...
mmf_nfound:
	_NO_CRIT			; end of risk (4)
	_EXIT_OK

; *** B_EXEC, get code at some address running into a paused (?) braid ***
; Y <- PID, ex_pt <- addr, def_io <- sys_in & sysout ** no need for architecture
; no longer should need some flag to indicate XIP or not! code start address always at stack bottom
mm_exec:
#ifdef	SAFE
	JSR mm_chkpid		; check for a valid PID first (21)
#endif
	TYA					; new PID passing
	BNE mmx_br			; go for another braid
		_ERR(INVALID)	; rejects system PID, or execute within this braid??? *** REVISE
mmx_br:
	PHA					; save desired PID for later!
; now should point to future stack space, no longer will switch regular stack!
	CLC
	ADC #>mm_stacks-256	; compute final MSB, note first stored PID is 1!
	STA exec_p+1		; store it
	LDA #<mm_stacks		; LSB needs no offset
	STA exec_p			; store it
	LDY #$FF			; standard stack bottom!
; *** create stack frame *** maybe try to switch again to regular stack?
; *****place starting address at the very bottom of stack, even in XIP code
; first goes KILL handler, as braids are expected to end via RTS *** could be different for rendez-vous mode calls!
; this was only for XIP code, otherwise shoud push a different handler address AND below that the pointer to the assigned block (handler will take it for FREE)
; ** non-XIP extra code, will not harm anyway **
;	LDA ex_pt+1			; get MSB
;	PHA					; push it
;	LDA ex_pt			; same for LSB
;	PHA
; continue with standard XIP code
	LDA #>mm_oblit-1	; compute end-of-task MSB for non-XIP (will arrive via RTS, thus one byte before)
	STA (exec_p), Y		; these could be replaced by PHA...
	DEY
	LDA #<mm_oblit-1	; same for LSB
	STA (exec_p), Y		; these could be replaced by PHA...
	DEY
; now the start address, no offset is needed if ending on RTI
	LDA ex_pt+1			; braid's starting MSB goes first
	STA (exec_p), Y		; these could be replaced by PHA...
	DEY
	LDA ex_pt			; same for LSB
	STA (exec_p), Y		; these could be replaced by PHA...
	DEY
	LDA #$20			; fake PHP value for RTI, start interrupts
	STA (exec_p), Y		; these could be replaced by PHA...
	DEY
; ISR will 'return' to pre-execution routine
	LDA #>mm_pre_exec	; pre-execution routine's MSB goes first
	STA (exec_p), Y		; these could be replaced by PHA...
	DEY
	LDA #<mm_pre_exec	; same for LSB
	STA (exec_p), Y		; these could be replaced by PHA...
	DEY
	DEY					; irrelevant P (could be PHP)
; now the usual interrupt stack frame
	LDA #ZP_AVAIL		; value in A will be taken by pre-exec routine!
	STA (exec_p), Y		; these could be replaced by PHA...
	DEY
	DEY					; irrelevant values for X, Y*****or taken as per future interface
	DEY
	STY exe_sp			; save this for a moment
; the scheduler calling context! new version 20161118, revise anyway
	_KERNEL(TS_INFO)	; get standard stack frame (Y->bytes, ex_pt->addr)
	DEY					; correct bytes as will never be empty!
	STY exe_sp+1		; number of bytes in another local...
mmx_sfp:
		LDA (ex_pt), Y		; get proposed stack frame byte
		DEY					; point to next
		STY exe_sp+1		; keep index
		LDY exe_sp			; get SP instead
		STA (exec_p), Y		; push into virtual stack
		DEY					; update SP
		STY exe_sp
		LDY exe_sp+1		; get index again
		CPY #$FF			; upon real end!
		BNE mmx_sfp			; will work always!
; *** stack frame done, now let us set the initial environment ***
;	NO_CRIT			; no longer needs critical section as hardware stack remains intact
; prepare storage pointer for new context
	PLA					; recover PID
	TAX					; stay saved
	CLC
	ADC #>mm_context-256	; compute final MSB, note first stored PID is 1!
	STA sysptr+1		; store it *** could use one local for shorter critical section!
	LDA #<mm_context	; LSB needs no offset
	STA sysptr			; store it
	_PHY				; keep definitive stack pointer!!!
; while we are on it, set standard I/O
	LDA def_io			; get std_in
	LDY #std_in			; offset for variable
	STA (exec_p), Y		; store into context
	LDA def_io+1		; this should be stdout
	INY					; advance offset to stdout
	STA (exec_p), Y		; context complete
	LDY #sys_sp			; get offset for stored SP
	PLA					; retrieve that saved SP
	STA (exec_p), Y		; store into context
	LDY #z_used			; offset for user zero-page bytes EEEEEK!
	LDA #0				; pre-execution has no context!
	STA (exec_p), Y		; set null context for much faster startup
	LDA #BR_RUN			; will enable task, no pending TERM!
	STA mm_flags-1, X	; X holds desired PID

; *** B_YIELD, yield CPU time ***
; no interface needed
mm_yield:
	CLC					; for safety in case RTS is found (when no other braid is active)
	_CRITIC				; eeeeeeek, scheduler is expected to run with interrupts OFF!
	JSR mm_sched		; ...then will CALL the scheduler! At once!
	_NO_CRIT			; restore interrupt status, could be off anyway
	_EXIT_OK			; eeeeeeeeeeeeeek, stack imbalance otherwise!

; *** GET_FG, get foreground PID from reserved variable ***
; Y -> PID
mm_getfg:
	LDY mm_fg			; get foreground PID
	_EXIT_OK

; *** B_FORE, get foreground PID from reserved variable *** STUB
; Y -> PID
mm_fore:
	STY mm_fg			; set foreground PID
	_EXIT_OK

; *** B_SIGNAL, send some signal to a braid ***
; b_sig <- signal code, Y <- PID (0 means TO ALL)
mm_signal:
#ifdef	SAFE
	JSR mm_chkpidz		; check for a valid PID first (21)
#endif
; new code 20150611, needs new ABI but 21 bytes (or 13 if not SAFE) and 13 clocks at most
	LDX b_sig			; get signal code (3)

#ifdef	SAFE
	CPX #SIGCONT+1		; compare against last (2)
	BCS mms_call		; abort if wrong signal eeeeeeek
		_ERR(INVALID)		; unrecognized signal!
#endif
mms_call:
; must accept PID=0 as send to all!
	TYA				; check whether broadcasting
	BNE mms_cjmp		; no, just send signal once
		LDY #MX_BRAID		; yes, prepare loop for all braids
mms_loop:
			_PHY				; just in case
			JSR mms_cjmp		; send signal to this braid and return here
			_PLY
			DEY				; next braid, backwards
			BNE mms_loop
		_EXIT_OK
mms_cjmp:
	_JMPX(mms_table)	; jump to actual code... and return (6502 ABI is the same for routines and API functions)

; *** B_FLAGS, get execution flags for a braid ***
; Y <- PID, Y -> flags
mm_status:
#ifdef	SAFE
	JSR mm_chkpid		; check for a valid PID first (21)
#endif

	LDA mm_flags-1, Y	; parameter as index (4) eeeeek!
	TAY					; return value (2) *** might want to write it somewhere for faster BIT
	_EXIT_OK

; *** SET_HNDL, set SIGTERM handler ***
; mm_term <- handler pointer, Y <- PID
mm_hndl:
#ifdef	SAFE
	JSR mm_chkpid		; check for a valid PID first (21)
#endif
	TYA					; eeeeeeeeeeek
	ASL					; pointers are TWICE the size of flags!
	TAY					; back to index
	LDA ex_pt			; get pointer LSB (3)
	_CRITIC				; this is delicate... (5)
	STA mm_term, Y		; store in table (4)
	LDA ex_pt+1			; now for MSB (3+4)
	STA mm_term+1, Y
	_NO_CRIT			; were off for 13 clocks (4)
	_EXIT_OK


; ****************************
; *** supporting functions ***
; ****************************

#ifdef	SAFE
; check PID within limits, with or without 0 (two entry points)
mm_chkpidz:
	TYA					; eeeeeeeek^2! the place to do it (2)
		BEQ mm_piderr		; error unless explicitally accepted (2/3)
mm_chkpid:
	CPY #MX_BRAID+1	; check whether it's a valid PID (2) eeeeeek!
		BCS mm_piderr		; way too much (2/3) eeeeeeek
	RTS					; back to business (6)
mm_piderr:
	PLA					; discard return address, since called from a subroutine (4+4)
	PLA
mm_bad:
	_ERR(INVALID)		; not a valid PID or subfunction code, worth checking, is this OK?
#endif

; pre-execution routine for faster task-switching first time!
mm_pre_exec:
	STA z_used		; store maximum available zero-page bytes from A, for safety EEEEEEK
	RTI				; 'return' to start of task! Much simpler, as long as a dummy PHP is done

; emergency exit, should never arrive here!
mm_eexit:
	_NEXT_ISR			; just in case

; ************************************
; *** signals ************************
; *** required interface, Y <- PID ***
; ************************************

; SIGKILL, kill braid immediately! perhaps called via ^D?
mms_kill:
	LDA #BR_FREE		; will be no longer executable (2)
	STA mm_flags-1, Y	; store new status AND clear unattended TERM (5)
; should probably free up all MEMORY & windows belonging to this PID...
;	_KERNEL(RELEASE)	; free up ALL memory belonging to this PID, new 20161115
; window release *** TO DO *** TO DO *** TO DO ***
	_DR_OK

; SIGTERM, ask braid to terminate, usually called via ^C
mms_term:
	LDA mm_flags-1, Y	; get original flags, now integrated! (4)
	ORA #1				; set request (2)
	STA mm_flags-1, Y	; set SIGTERM request for that braid (4)
	_EXIT_OK			; as direct jump from patched B_SIGNAL

; SIGCONT, resume execution
mms_cont:
	_CRITIC			; this is delicate (2)
	LDA mm_flags-1, Y	; first check current state (5)
	AND #BR_MASK		; mandatory as per integrated mm_treq (2)
	CMP #BR_STOP		; is it paused? (2)
		BNE mms_kerr		; no way to resume it! (2/3)
	LDA #BR_RUN			; resume (2)
	STA mm_flags-1, Y	; store new status (5) again, TERM is lost
	_NO_CRIT			; were off for ...
	_EXIT_OK			; as direct jump from patched B_SIGNAL

; SIGSTOP, pause execution, usually called via ^Z
mms_stop:
	LDA mm_flags-1, Y	; first check current state (5)
	AND #BR_MASK		; mandatory as mm_treq is integrated! *** note that a previous TERM signal is lost!
	CMP #BR_RUN			; is it running? (2)
		BNE mms_kerr		; no way to stop it! (2/3)
	LDA #BR_STOP		; pause it (2)
	STA mm_flags-1, Y	; store new status (5) *** would like to restore somehow any previous TERM!
	_EXIT_OK			; as direct jump from patched B_SIGNAL
mms_kerr:
	_DR_ERR(INVALID)	; not a valid PID

; **********************
; *** pointer tables ***
; **********************

; *** subfuction addresses table ***
mm_funct:
	.word	mm_fork		; reserve a free braid (will go BR_STOP for a moment)
	.word	mm_exec		; get code at some address running into a paused braid (will go BR_RUN)
	.word	mm_signal	; send some signal to a braid
	.word	mm_status	; get execution flags for a braid
	.word	mm_hndl		; set SIGTERM handler
	.word	mm_yield	; switch to next braid, likely to be ignored if lacking hardware-assisted multitasking
	.word	mm_fore		; ***new, set foreground task
	.word	mm_getfg	; ***new, get foreground PID

; *** signal routines addresses table ***
mms_table:
	.word	mms_kill
	.word	mms_term
	.word	mms_cont
	.word	mms_stop
.)
