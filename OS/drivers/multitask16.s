; software multitasking module for minimOS·16
; v0.5.1a9
; (c) 2016 Carlos J. Santisteban
; last modified 20161129-1035


; ********************************
; *** multitasking driver code ***
; ********************************

; *** set some reasonable number of braids ***
-MAX_BRAIDS		= 16	; takes 8 kiB -- hope it is OK to define here!

#ifndef		HEADERS
#include "usual.h"
; specific header
.bss
#include "drivers/multitask16.h"
.text
#endif

; *** begins with sub-function addresses table ***
	.byt	TASK_DEV	; physical driver number D_ID (TBD)
	.byt	A_POLL+A_COUT	; polling scheduler this far, new architecture needs to enable output!
	.word	mm_init		; initialize device and appropiate sysvars, called by POST only
	.word	mm_sched	; periodic scheduler
	.word	mm_nreq		; D_REQ does nothing
	.word	mm_abort	; no input
	.word	mm_cmd		; output will process all subfunctions!
	.word	mm_rts		; no need for 1-second interrupt
	.word	mm_abort	; no block input
	.word	mm_abort	; no block output
	.word	mm_bye		; shutdown procedure
	.word	mm_info		; points to descriptor string
	.byt	0			; reserved, D_MEM

; *** driver description ***
mm_info:
	.asc	"16-task 65816 Scheduler v0.5.1a9", 0	; fixed MAX_BRAIDS value!

; *** initialisation code ***
mm_init:
; if needed, check whether proper stack frame is available from kernel
#ifdef	SAFE
; might check for bankswitching hardware and cause error, in order NOT to install BOTH schedulers!...
; ...or just ignore as only the first driver will install?
; hardware-assisted scheduler init code should do the opposite!
;	LDY #0				; supposedly null PID
;	_ADMIN(SWITCH)		; future use of hardware multitasking
;	BCC mm_nohw			; no hardware detected, OK to proceed with soft
;		_DR_ERR(INVALID)	; otherwise will not install, hope there is a hardware driver!
;mm_nohw:
; remaining code assumes software scheduler only
	_KERNEL(TS_INFO)	; just checking availability, will actually be used by B_EXEC
	BCC mm_cont			; skip if no error eeeeeeeeeek
		_DR_ERR(UNAVAIL)	; error if not available
mm_cont:
#endif
; initialise flags table (and stack pointers?)
; at least, set direct page to current braid!
	LDA #>mm_context	; MSB of storage area
;	CLC
;	ADC #MAX_BRAIDS		; prepare backwards pointer! temporarily outside range...
	XBA					; will be the rest of the pointer
	LDA #<mm_context	; same for LSB... should be ZERO for performance reasons
	TCD					; direct-page set for FIRST context
	LDX #MAX_BRAIDS		; reset backwards index
;	LDY #$FF			; original SP value, no need to skim on that
	LDA #BR_FREE		; adequate value in two highest bits, outside loop b/c integrated mm_treq
mm_rsp:
;		XBA					; get accumulator MSB
;		DEC					; go for next context (contiguous)
;		XBA					; back to MSB
;		TCD					; set direct-page
;		STY sys_sp			; direct page storage of original SP
;		LDA #BR_FREE		; adequate value in two highest bits
		STA mm_flags-1, X	; set braid to FREE, please note X counts from 1 but table expects indexes from 0
;		STZ mm_treq-1, X	; set SIGTERM request flags to zero *** already integrated
;		LDA #<mm_context	; restore LSB... should be ZERO for performance reasons
		DEX					; go for next
		BNE mm_rsp			; continue until all done
	INX					; default task (will be 1)
	STX mm_pid			; set as current PID
; do NOT set current SP as initialisation will crash! startup via scheduler will do anyway
;	LDA #>mm_stacks		; contextual stack area base pointer *** assume page-aligned!!!
;	XBA					; that was MSB
;	LDA #$FF			; restored value, no need to skim on that (2)
;	TCS					; stack pointer updated!
; *** shutdown code placeholder *** does not do much
mm_bye:
	_DR_OK				; new interface for both 6502 and 816

; switch to next braid
mm_yield:
	CLC					; for safety in case RTS is found (when no other braid is active)
; 65816 calls already run with interrupts OFF!
	JSR mm_sched		; ...then will CALL the scheduler!
; interrupt status will be restored later
	_DR_OK				; eeeeeeeeeeeeeek, stack imbalance otherwise!

; kill itself!!! simple way to terminate after FINISH
mms_suicide:
	.as: .xs: SEP #$30	; ** standard size for app exit **
	LDY mm_pid			; special entry point for task ending EEEEEEEEEEEK
	SEI					; this needs to be run with interrupts OFF, do not care current status
	JSR mms_kill		; complete KILL procedure and return here (ignoring errors)
	CLC					; for safety in case RTS is found (when no other braid is active)
; ...then go into the scheduler as this will no longer be executable

; *** the scheduler code ***
mm_sched:
; get next available PID
	LDY #2				; to avoid deadlocks AND proper shutdown detection (2)
	LDX mm_pid			; actual PID as index (4)
mm_scan:
		DEX					; going backwards is faster (2)
			BEQ mm_wrap			; in case of wrap, remember first PID is 1 (2/3) faster implementation
mm_next:
		LDA mm_flags-1, X	; get status of entry (4)
		AND #BR_MASK		; if SIGTERM flag is integrated here, this is mandatory, does not harm (2)
		BNE mm_scan			; zero (now equal to BR_RUN) means executable braid (3/2)
; an executable braid is found
	CPX mm_pid			; is it the same as before? (4)
	BNE mm_switch		; if not, go and switch braids (3/2)
		RTS					; otherwise, nothing to do; no need for macro (0/3)

; PID expired, try to wrap or shutdown if no more live tasks!
mm_wrap:
		LDX #MAX_BRAIDS		; go to end instead, valid as last PID (2)
		DEY					; and check is not forever (2)
			BNE mm_next			; otherwise should only happen at shutdown time (3/2)
mm_lock:
		LDY #PW_CLEAN		; special code to do proper shutdown
		_KERNEL(SHUTDOWN)	; all tasks stopped, time for shutdown
		_PANIC("{TASK}")	; if ever arrives here, it was wrong at so many levels...

; arrived here in typically ? clocks, if all braids were executable
mm_switch:
; store previous status
	STX mm_pid			; will need to add that
; keep stack pointer!
	TSX					; get index MSB (2)
	STX sys_sp			; store as usual (3)
; go into new braid
	LDA #>mm_context-256	; get pointer to direct pages eeeeeeeeeeek
	CLC
	ADC mm_pid			; compute offset within stored direct-pages
	XBA					; that was MSB
	LDA #<mm_context	; should be zero
	TCD					; new direct page is set
; set stack pointer to new context
	LDA #>mm_stacks-256	; contextual stack area base pointer, assume page-aligned!!!
	CLC
	ADC mm_pid			; add offset for new braid
	XBA					; that was MSB
	LDA sys_sp			; restored value (3) *** should add LSB if not page-aligned?
	TCS					; stack pointer updated!
; now it's time to check whether SIGTERM was sent! new 20150611
	LDX mm_pid			; get current PID again (4)
	LDA mm_flags-1, X	; had it a SIGTERM request? (4)
	LSR					; easier check of bit 0! (2)
	BCS mm_sigterm		; process it now! (2/3)
mm_rts:
		RTS					; all done, continue ISR

; the actual SIGTERM routine execution, new interface 161024, always ending in RTI
mm_sigterm:
	ASL					; ...and restore value with clear flag!
	STA mm_flags-1, X	; EEEEEEEK! clear received TERM signal, new format 20161117
	PHK					; push program bank as required by RTI in 816
	PEA mm_rts			; correct return address after SIGTERM handler RTI
	PHP					; eeeeeeeeeeeeeeeeeek
; 24-bit indexed jump means the use of RTI
	LDA mm_stbnk-1, X	; now get bank address
	PHA					; needed for RTI at the end of the handler
	TXA					; addressed braid (2)
	ASL					; two times (2)
	TAX					; proper offset in handler table (2)
	LDA mm_term-1, X	; get MSB
	PHA					; and push it
	LDA mm_term-2, X	; same for LSB
	PHA
	PHP					; as needed by RTI
	RTI					; actual jump, will return to an RTS and continue ISR

; *** subfunction processing section ***
mm_cmd:
#ifdef	SAFE
	CPX #MM_PRIOR+2		; check limits, put last subfunction as appropriate (2)
		BCS mm_bad			; go away otherwise! (2/3) eeeeeeeeek
#endif
	JMP (mm_funct, X)	; jump to appropriate routine (6)

#ifdef	SAFE
; check PID within limits (20 including call)
mm_chkpid:
	TYA					; eeeeeeeek^2 the place to do it, new format (2)
		BEQ mm_pidz			; system-reserved PID???? don't know what to do here... (2/3)
	CPY #MAX_BRAIDS+1	; check whether it's a valid PID (2) eeeeeek!
		BCS mm_piderr		; way too much (2/3) eeeek
	RTS					; back to business (6)
mm_pidz:				; placeholder
mm_piderr:
	PLA					; discard return address, since called from a subroutine (4+4)
	PLA
mm_bad:
	_DR_ERR(INVALID)	; not a valid PID or subfunction code, worth checking
#endif

; reserve a free braid
; Y -> PID
mm_fork:
	LDY #MAX_BRAIDS	; scan backwards is usually faster (2)
; ** assume interrupts are off via COP **
mmf_loop:
		LDA mm_flags-1, Y	; get that braid's status (4)
		AND #BR_MASK		; mandatory now (2)
		CMP #BR_FREE		; check whether available (2)
			BEQ mmf_found		; got it (2/3)
		DEY					; try next (2)
		BNE mmf_loop		; until the bottom of the list (3/2)
	_DR_ERR(FULL)		; no available braids! *** it is a kernel I/O call...
mmf_found:
	LDA #BR_STOP		; *** is this OK? somewhat dangerous *** (2)
	STA mm_flags-1, Y	; reserve braid (4)
	_DR_OK				; this OK? it is a kernel I/O call...

; get code at some address running into a paused (?) braid ****** REVISE ****** REVISE ******
; Y <- PID, ex_pt <- addr, cpu_ll <- architecture, def_io <- sys_in & sysout
mm_exec:
#ifdef	SAFE
	JSR mm_chkpid		; check for a valid PID first ()
#endif
	TYA					; new PID passing
	BNE mmx_br			; go for another braid
		_DR_ERR(INVALID)	; rejects system PID, or execute within this braid??? *** REVISE
mmx_br:
; while still in 8-bit mode, compute new stack address
	CLC					; eeeeeeeeeeek
	ADC #>mm_stacks-256	; compute MSB, note offset as first PID is 1
	XBA					; will be MSB
	LDA #$FF			; always assume page-aligned stacks
; ...will switch to future stack space a bit later!
; create stack frame
	.al: REP #$20		; *** 16-bit memory ***
	LDA def_io			; get sys_in & sysout from parameter, revise ABI
	PHA					; into stack, but BEFORE PID
	PHY					; keep PID for later!
	TSX					; store older stack pointer!
	STX sys_sp			; ** 816 ABI is OK for CS **
; switch to future stack frame for easier creation
	TCS					; future stack pointer for easier frame construction
	LDX #0				; canary and bank address of SIG_KILL handler, taken by FINISH
	PHX					; bottom of stack!
	PEA mms_suicide-1	; corrected 'return' address for definitive SIG_KILL handler
	LDX ex_pt+2			; get bank address of starting point
	PHX					; place in on stack
	LDA ex_pt			; get full (minus bank) program address
	PHA					; RTI-savvy address placed
	LDX #$30			; as status means 8-bit size, interrupts enabled!
	PHX					; push fake status register!
	_KERNEL(TS_INFO)	; get ISR-dependent stack frame, Y holds size
	DEY					; correct index as will NEVER be empty!
	.as: SEP #$20		; *** back to 8-bit for a moment ***
mmx_sfp:
		LDA (ex_pt), Y		; get proposed stack frame byte
		PHA					; push it
		DEY					; go for next
		BPL mmx_sfp			; will work for shorter-than-128 byte frames!
	TSX					; keep destination stack pointer!
; back to regular stack
	LDA mm_pid			; get current PID as MSB offset
	CLC
	ADC #>mm_stacks-256	; first valid PID is 1
	XBA					; that was MSB
	LDA sys_sp			; saved value
	TCS					; stack is restored
; now prepare future task context, including the previously saved SP (in X), and PID pushed into stack
	.al: REP #$20		; *** 16-bit memory ***
	PLY					; get desired PID, 8-bit size
	TYA					; also here, B get zeroes
	XBA					; that will be MSB!
	CLC					; eeeeeeeek
	ADC #mm_context-256	; point to at that direct page
	TCD					; switch to future direct page
	STX sys_sp			; this is the computed stack pointer for the new braid
	LDX #ZP_AVAIL		; standard available space
	STX z_used			; as required
; now should poke std_in & stdout from stack
	PLA					; this was sysout & sys_in, little endian
	STA std_in			; assume sys_in is the LSB!!!
	.as: SEP #$20		; *** back to 8-bit ***
	LDA #BR_RUN			; will enable task
	STA mm_flags-1, Y	; Y holds desired PID
; switch back to original context!!! eeeeeeeeeek
	TYA					; current PID
	CLC
	ADC #>mm_context-256	; first PID is 1, context MSB is ready
	XBA					; now for LSB
	LDA #<mm_context	; should be zero for optimum performance
	TCD					; back to current direct page
	_DR_OK				; done

; send some signal to a braid
mm_signal:

#ifdef	SAFE
	JSR mm_chkpid		; check for a valid PID first ()
#endif

; new code 20150611, needs new ABI but 21 bytes (or 13 if not SAFE) and 13 clocks at most
	LDX b_sig			; get signal code (3)

#ifdef	SAFE
	CPX #SIGCONT+1		; compare against last (2)
		BCC mms_kerr		; abort if wrong signal
#endif

	JMP (mms_table, X)	; jump to actual code

; ask braid to terminate
mms_term:
	LDA mm_flags-1, Y	; get original flags, now integrated! (4)
	ORA #1				; set request (2)
	STA mm_flags-1, Y	; set SIGTERM request for that braid (4)
	_DR_OK

; kill braid!
mms_kill:
	LDA #BR_FREE		; will be no longer executable (2)
	STA mm_flags-1, Y	; store new status AND clear unattended TERM (5)
;	LDA #0				; no STZ abs,Y
;	STA mm_treq-1, Y	; clear unattended TERM signal, 20150617
; should probably free up all MEMORY & windows belonging to this PID...
	LDY mm_pid			; get current task number
	_KERNEL(RELEASE)	; free up ALL memory belonging to this PID, new 20161115
; window release *** TO DO *** TO DO *** TO DO ***
	_DR_OK				; return as appropriate

; resume execution
mms_cont:
; CS not needed as per 816 ABI
	LDA mm_flags-1, Y	; first check current state (5)
	LSR					; keep integrated mm_treq in C! (2)
	CMP #BR_STOP/2		; is it paused? note it was shifted (2)
		BNE mms_kerr		; no way to resume it! (2/3)
	LDA #BR_RUN/2		; resume, note shift (2)
	ROL					; reinsert TERM flag from C! (2)
	STA mm_flags-1, Y	; store new status (5) again, TERM is lost
; here ends CS
	_DR_OK

; pause execution
mms_stop:
	LDA mm_flags-1, Y	; first check current state (5)
	LSR					; keep integrated mm_treq in C! (2)
	CMP #BR_RUN/2		; is it running? note shift (2)
		BNE mms_kerr		; no way to stop it! (2/3)
	LDA #BR_STOP/2		; pause it, note shift (2)
	ROL					; reinsert TERM flag from C! (2)
	STA mm_flags-1, Y	; store new status (5) *** would like to restore somehow any previous TERM!
	_DR_OK
mms_kerr:
	_DR_ERR(INVALID)	; not a running PID

; get execution flags for a braid
mm_status:

#ifdef	SAFE
	JSR mm_chkpid		; check for a valid PID first ()
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

; CS not needed in 65816 ABI
; needs 24-bit addressing!!!
	LDA ex_pt+2			; bank address
	STA mm_stbnk-1, Y	; store into new array
; put rest of address in array!
	TYA					; get index
	ASL					; double as pointer eeeeeeeeeeeek
	TAX					; any better this way?
	LDA ex_pt			; get pointer LSB (3)
	STA mm_term-2, X	; store in table (4)
	LDA ex_pt+1			; now for MSB (3+4)
	STA mm_term-1, X
; end of CS
; ** priorize braid, jump to it at once, really needed? **
mm_prior:				; this is just a placeholder
	_DR_OK

; emergency exit, should never arrive here!
mm_nreq:
	_NEXT_ISR			; just in case

; placeholder for unimplemented features
mm_abort:
	_DR_ERR(EMPTY)

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
