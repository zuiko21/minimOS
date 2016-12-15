; software multitasking module for minimOS
; v0.5.1a6
; (c) 2015-2016 Carlos J. Santisteban
; last modified 20161215-0956


; ********************************
; *** multitasking driver code ***
; ********************************

; *** set some reasonable number of braids ***
-MAX_BRAIDS		= 4		; reasonable number without too much overhead
; *** set delay counter for reasonable overhead ***
QUANTUM_COUNT	= 8		; specific delay, number of quantums to wait for before switching

#ifndef		HEADERS
#include "usual.h"
; specific header
.bss
#include "drivers/multitask.h"
.text
#endif

; *** begins with sub-function addresses table *** REVISE
	.byt	TASK_DEV	; physical driver number D_ID (TBD)
	.byt	A_POLL+A_COUT	; polling scheduler this far, new architecture needs to enable output!
	.word	mm_init		; initialize device and appropiate sysvars, called by POST only
	.word	mm_sched	; periodic scheduler
	.word	mm_eexit	; D_REQ does nothing
	.word	mm_abort	; no input
	.word	mm_cmd		; output will process all subfunctions!
	.word	mm_rts		; no need for 1-second interrupt
	.word	mm_abort	; no block input
	.word	mm_abort	; no block output
	.word	mm_bye		; shutdown procedure
	.word	mm_info		; NEW, points to descriptor string
	.byt	0			; reserved, D_MEM

; *** driver description, NEW 20150323 ***
mm_info:
	.asc	MAX_BRAIDS+'0', "-task Software Scheduler v0.5.1a6", 0	; works as long as no more than 9 braids!

; *** initialisation code ***
mm_init:
#ifdef	SAFE
; might check for bankswitching hardware and cause error, in order NOT to install BOTH schedulers!...
; ...or just ignore as only the first driver will install?
; hardware-assisted scheduler init code should do the opposite!
; remaining code assumes software scheduler only
	_KERNEL(TS_INFO)	; just checking availability, will actually be used by B_EXEC
	BCC mm_cont			; skip if no error eeeeeeeeeek
		_DR_ERR(UNAVAIL)	; error if not available
mm_cont:
#endif
; initialise 6502-only delay counter
	LDA #QUANTUM_COUNT
	STA mm_qcnt			; init quantum counter
; initialise stack pointers and flags table
; *** SP possibly needs NOT to be intialised, neither sysptr set here... just flags? ***
;	LDA #>mm_context	; MSB of storage area
;	CLC					; hope isn't needed anymore in the loop!
;	ADC #MAX_BRAIDS		; prepare backwards pointer! temporarily outside range...
;	STA sysptr+1		; store in pointer, will be increased
;	LDA #<mm_context	; same for LSB, will not bother adding sys_sp
;	STA sysptr
;	LDY #sys_sp			; offset for sys_sp, just in case
	LDA #BR_FREE		; adequate value in two highest bits, if sys_sp does NOT get inited!
;	LDY #0				; for safer STZ, in case SP is NOT inited! but not if mm_treq is integrated with mm_flags!
	LDX #MAX_BRAIDS		; set counter (much safer this way)
mm_rsp:
;		DEC sysptr+1		; move pointer to next storage area
;		LDA #$FF			; original SP value, no need to skim on that *** really needed?
;		STA (sysptr), Y		; store "register" in proper area *** really needed?
;		LDA #BR_FREE		; adequate value in two highest bits *** could be otside loop if sys_sp does NOT get inited!
		STA mm_flags-1, X	; set braid to FREE, please note X counts from 1 but table expects indexes from 0 *** also resets integrated mm_treq
;		STY mm_treq-1, X	; set SIGTERM request flags to zero, use this way in case SP does NOT get inited! but not if mm_treq is integrated with mm_flags!
;		_STZA mm_treq-1, X	; set SIGTERM request flags to zero, new 20150611, poorly optimized for NMOS macro
		DEX					; one braid less (much safer this way)
		BNE mm_rsp			; finish all braids (much safer this way)
	INX					; the first PID is 1
	STX mm_pid			; set index as current PID
; do NOT set current SP as initialisation will crash! startup via scheduler will do anyway
; *** shutdown code placeholder *** does not do much
mm_bye:
	_DR_OK				; new interface for both 6502 and 816

; switch to next braid
mm_yield:
	CLC					; for safety in case RTS is found (when no other braid is active)
	_ENTER_CS			; eeeeeeek, scheduler is expected to run with interrupts OFF!
	JSR mm_oksch		; ...then will CALL the scheduler! At once!
	_EXIT_CS			; restore interrupt status, could be off anyway
	_DR_OK				; eeeeeeeeeeeeeek, stack imbalance otherwise!

; in case of non-XIP code (loaded file) FINISH must free its previously assigned block, taking address from stack!
mm_oblit:
	PLA					; take LSB from stack!
	STA ma_pt			; parameter for FREE
	PLA					; same for MSB
	STA ma_pt+1
	SEI					; certainly needs interrupts off!
	_KERNEL(FREE)		; generic access
; ...and get into mm_suicide

; kill itself!!! simple way to terminate after FINISH
mm_suicide:
	LDY mm_pid			; special entry point for task ending EEEEEEEEEEEK
	SEI					; this needs to be run with interrupts OFF, do not care current status
	_STZA z_used		; *** optimise for faster switch!
	LDX #$FE			; Do not let EMPTY! eeeeeeeeeek
	TXS					; *** optimise for faster switch!
	JSR mms_kill		; complete KILL procedure and return here (ignoring errors)
	CLC					; for safety in case RTS is found (when no other braid is active)
	_BRA mm_oksch		; ...then into scheduler code, current context is irrelevant as will no longer be executable

; *** the scheduler code ***
mm_sched:
; check whether it's time to switch or not
	DEC mm_qcnt			; decrease remaining quantum count (6)
	BEQ mm_do			; change task if expired (2/3)
		RTS					; go away ASAP otherwise, no need for macro (6/0)
mm_do:
; execute scheduler itself
	LDA #QUANTUM_COUNT	; get number of quantums to wait (2)
	STA mm_qcnt			; restore counter for next time (4)
mm_oksch:
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
		LDX #MAX_BRAIDS		; go to end instead, valid as last PID (2)
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
; *** save current context! ***
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
#ifdef	C64
		CPY #z_used			; 6510 must skip built-in port! (2)
#endif
		BNE mm_save			; until first byte, but NOT included (3/2)
; after that loop, -1+z*14 (make it z*16 for 6510) worse case +3373 (+3823 for C64)
; copy missing byte (+9)
		LDA 0, Y			; get byte from zeropage (4) Y could be 2 in C64, otherwise LDA 0 will do (one cycle less)
		STA (sysptr), Y		; store it (5)
; save kernel local context also (+385)
#ifdef	C64
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
; *** now let's retrieve new task's context ***
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
#ifdef	C64
		CPY #z_used			; 6510 must skip built-in port!
#endif
		BNE mm_load			; until first byte, but NOT included (3/2)
; copy missing byte (9)
		LDA (sysptr), Y		; get it (5)
		STA 0, Y			; get byte from zeropage (4)
; load kernel local context also (+385)
#ifdef	C64
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
; now it's time to check whether SIGTERM was sent! new 20150611
	LDX mm_pid			; get current PID again (4)
;	LDA mm_treq-1, X	; had it a SIGTERM request? (4)
	LDA mm_flags-1, X	; had it a SIGTERM request? (4) in case of integrated mm_treq
	LSR					; easier check of bit 0! (2)
	BCS mm_sigterm		; process it now! (2/3)
mm_rts:
		RTS					; all done, continue ISR

; *** the actual SIGTERM routine execution, new 20150611 ***
mm_sigterm:
;	_STZA mm_treq-1, X	; EEEEEEEK! Clear received TERM signal
	ASL					; ...and restore value with clear flag!
	STA mm_flags-1, X	; EEEEEEEK! clear received TERM signal, new format 20161117
	LDA #>mm_rts		; compute return address for RTI!
	PHA					; into stack
	LDA #<mm_rts		; same for LSB
	PHA
	PHP					; sigterm ends in RTI!
	_JMPX(mm_term-2)	; indexed indirect jump, will return to RTS

; *** subfunction processing section ***
mm_cmd:
#ifdef	SAFE
	CPX #MM_PRIOR+2		; check limits, put last subfunction as appropriate (2)
		BCS mm_bad			; go away otherwise! (2/3) eeeeeek
#endif
	_JMPX(mm_funct)		; jump to appropriate routine (6)

#ifdef	SAFE
; check PID within limits (21 clocks optimized 150514, was 23 clocks including JSR)
mm_chkpid:
	TYA					; eeeeeeeek^2! the place to do it (3)
		BEQ mm_pidz			; system-reserved PID???? don't know what to do here... (2/3)
	CPY #MAX_BRAIDS+1	; check whether it's a valid PID (2) eeeeeek!
		BCS mm_piderr		; way too much (2/3) eeeeeeek
	RTS					; back to business (6)
mm_pidz:				; placeholder
mm_piderr:
	PLA					; discard return address, since called from a subroutine (4+4)
	PLA
mm_bad:
	_DR_ERR(INVALID)		; not a valid PID or subfunction code, worth checking
#endif

; reserve a free braid
; Y -> PID
mm_fork:
	LDY #MAX_BRAIDS		; scan backwards is usually faster (2)
	_ENTER_CS			; this is delicate (5)
mmf_loop:
		LDA mm_flags-1, Y	; get that braid's status (4)
		AND #BR_MASK		; mandatory now, ignore TERM (2)
		CMP #BR_FREE		; check whether available (2)
			BEQ mmf_found		; got it (2/3)
		DEY					; try next (2)
		BNE mmf_loop		; until the bottom of the list (3/2)
	CLI					; nothing was found (2)
	_DR_ERR(FULL)			; no available braids!
mmf_found:
	LDA #BR_STOP		; *** is this OK? somewhat dangerous *** (2)
	STA mm_flags-1, Y	; reserve braid (4)
	_EXIT_CS			; end of risk (4)
	_DR_OK

; get code at some address running into a paused (?) braid
; Y <- PID, ex_pt <- addr, def_io <- sys_in & sysout ** no need for architecture
; *** should need some flag to indicate XIP or not! stack frame is different
mm_exec:
#ifdef	SAFE
	JSR mm_chkpid		; check for a valid PID first (21)
#endif
	TYA					; new PID passing
	BNE mmx_br			; go for another braid
		_DR_ERR(INVALID)	; rejects system PID, or execute within this braid??? *** REVISE
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
; first goes KILL handler, as braids are expected to end via RTS *** could be different for rendez-vous mode calls!
; this was only for XIP code, otherwise shoud push a different handler address AND below that the pointer to the assigned block (handler will take it for FREE)
; ** check flag for XIP/non-XIP code and jump to mmx_nonxip if needed
; ** XIP handler **
	LDA #>mm_suicide-1	; compute end-of-task MSB (will arrive via RTS, thus one byte before)
	STA (exec_p), Y		; these could be replaced by PHA...
	DEY
	LDA #<mm_suicide-1	; same for LSB
	STA (exec_p), Y		; these could be replaced by PHA...
	DEY
;		_BRA mmx_frame		; continue creating stack frame!
; ** non-XIP handler **
;mmx_nonxip:
;	LDA ex_pt+1			; get MSB
;	PHA					; push it
;	LDA ex_pt			; same for LSB
;	PHA
;	LDA #>mm_oblit-1	; compute end-of-task MSB for non-XIP (will arrive via RTS, thus one byte before)
;	STA (exec_p), Y		; these could be replaced by PHA...
;	DEY
;	LDA #<mm_oblit-1	; same for LSB
;	STA (exec_p), Y		; these could be replaced by PHA...
;	DEY
; ** could jump to mmx_frame in case of optimisation **
; now the start address, no offset is needed if ending on RTI
mmx_frame:
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
	DEY					; irrelevant values for X, Y
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
;	_EXIT_CS			; no longer needs critical section as hardware stack remains intact
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


; pre-execution routine for faster task-switching first time!
mm_pre_exec:
	STA z_used		; store maximum available zero-page bytes from A, for safety EEEEEEK
	RTI				; 'return' to start of task! Much simpler, as long as a dummy PHP is done

; send some signal to a braid
mm_signal:

#ifdef	SAFE
	JSR mm_chkpid		; check for a valid PID first (21)
#endif

; new code 20150611, needs new ABI but 21 bytes (or 13 if not SAFE) and 13 clocks at most
	LDX b_sig			; get signal code (3)

#ifdef	SAFE
	CPX #SIGCONT+1		; compare against last (2)
	BMI mms_jmp			; abort if wrong signal
		_DR_ERR(INVALID)		; unrecognized signal!
#endif

mms_jmp:
	_JMPX(mms_table)	; jump to actual code

; kill braid!
mms_kill:
	LDA #BR_FREE		; will be no longer executable (2)
	STA mm_flags-1, Y	; store new status AND clear unattended TERM (5)
;	LDA #0				; STZ is not worth
;	STA mm_treq-1, Y	; Clear unattended TERM signal, 20150617
; should probably free up all MEMORY & windows belonging to this PID...
	LDY mm_pid			; get current task number
	_KERNEL(RELEASE)	; free up ALL memory belonging to this PID, new 20161115
; window release *** TO DO *** TO DO *** TO DO ***
	_DR_OK

; ask braid to terminate
mms_term:
	LDA mm_flags-1, Y	; get original flags, now integrated! (4)
	ORA #1				; set request (2)
	STA mm_flags-1, Y	; set SIGTERM request for that braid (4)
	_DR_OK

; resume execution
mms_cont:
	_ENTER_CS			; this is delicate (2)
	LDA mm_flags-1, Y	; first check current state (5)
	AND #BR_MASK		; mandatory as per integrated mm_treq (2)
	CMP #BR_STOP		; is it paused? (2)
		BNE mms_kerr		; no way to resume it! (2/3)
	LDA #BR_RUN			; resume (2)
	STA mm_flags-1, Y	; store new status (5) again, TERM is lost
	_EXIT_CS			; were off for ...
	_DR_OK

; pause execution
mms_stop:
	LDA mm_flags-1, Y	; first check current state (5)
	AND #BR_MASK		; mandatory as mm_treq is integrated! *** note that a previous TERM signal is lost!
	CMP #BR_RUN			; is it running? (2)
		BNE mms_kerr		; no way to stop it! (2/3)
	LDA #BR_STOP		; pause it (2)
	STA mm_flags-1, Y	; store new status (5) *** would like to restore somehow any previous TERM!
	_DR_OK
mms_kerr:
mm_abort:				; a bit of a placeholder...
	_DR_ERR(INVALID)	; not a valid PID

; get execution flags for a braid
mm_status:

#ifdef	SAFE
	JSR mm_chkpid		; check for a valid PID first (21)
#endif

	LDA mm_flags-1, Y	; parameter as index (4) eeeeek!
	TAY					; return value (2) *** might want to write it somewhere for faster BIT
	_DR_OK

; get current PID
mm_getpid:
	LDY mm_pid			; get PID (4)
	_DR_OK

; set SIGTERM handler
mm_hndl:

#ifdef	SAFE
	JSR mm_chkpid		; check for a valid PID first (21)
#endif

	LDA ex_pt			; get pointer LSB (3)
	_ENTER_CS			; this is delicate... (5)
	STA mm_term, Y		; store in table (4)
	LDA ex_pt+1			; now for MSB (3+4)
	STA mm_term+1, Y
	_EXIT_CS			; were off for 13 clocks (4)
; priorize braid, jump to it at once, really needed? *** placeholder ***
mm_prior:
	_DR_OK

; emergency exit, should never arrive here!
mm_eexit:
	_NEXT_ISR			; just in case

; *** subfuction addresses table ***
mm_funct:
	.word	mm_fork		; reserve a free braid (will go BR_STOP for a moment)
	.word	mm_exec		; get code at some address running into a paused braid (will go BR_RUN)
	.word	mm_yield	; switch to next braid, likely to be ignored if lacking hardware-assisted multitasking
	.word	mm_signal	; send some signal to a braid
	.word	mm_status	; get execution flags for a braid
	.word	mm_getpid	; get current PID
	.word	mm_hndl		; set SIGTERM handler
	.word	mm_prior	; priorize braid, jump to it at once, really needed?

; *** signal routines addresses table ***
mms_table:
	.word	mms_kill
	.word	mms_term
	.word	mms_cont
	.word	mms_stop

