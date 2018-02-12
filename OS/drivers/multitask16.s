; software multitasking module for minimOS·16
; v0.6a1
; (c) 2016-2018 Carlos J. Santisteban
; last modified 20180212-0936

; ***************************
; *** multitasking driver ***
; ***************************

; *** set some reasonable number of braids ***
MAX_BRAIDS		= 16	; takes 8 kiB -- hope it is OK to define here!

#ifndef		HEADERS
#include "usual.h"
; specific header
.bss
#include "drivers/multitask16.h"
.text
#endif

.(
; *** begins with sub-function addresses table ***
	.byt	TASK_DEV	; physical driver number D_ID (TBD)
	.byt	A_POLL+A_COUT	; polling scheduler for new 0.6 architecture
	.word	mm_abort	; no input
	.word	mm_abort	; no output
	.word	mm_init		; initialize device and appropiate sysvars, MUST patch relevant task-handling functions!
	.word	mm_sched	; periodic scheduler
	.word	1			; scheduler frequency, quantum is as fast as jiffy!
	.word	mm_nreq		; D_ASYN does nothing
	.word	mm_abort	; no config?
	.word	mm_abort	; no status?
	.word	mm_bye		; shutdown procedure
	.word	mm_info		; points to descriptor string
	.word	0			; reserved, D_MEM (word just in case)

; *** driver description ***
mm_info:
	.asc	"16-task 65816 Scheduler v0.6a1", 0	; fixed MAX_BRAIDS value!

; ***************************
; ***************************
; *** initialisation code ***
; ***************************
; ***************************
mm_init:
; if needed, check whether proper stack frame is available from kernel
#ifdef	SAFE
; no longer hardware support from firmware!
; remaining code assumes software scheduler only
	_KERNEL(TS_INFO)	; just checking availability, will actually be used by B_EXEC
	BCC mm_cont			; skip if no error eeeeeeeeeek
		_DR_ERR(UNAVAIL)	; error if not available
mm_cont:
#endif
; first, set direct page to current braid!
	.al: REP #$20		; *** 16-bit memory, index are 8-bit by default DR_INST method ***
	LDA #mm_context		; storage area full pointer
	TCD					; direct-page set for FIRST context
; initialise flags table (but not stack pointers?)
	LDY #MAX_BRAIDS		; reset backwards index *** MAX_BRAIDS must be even!
	LDA #BR_FREE*257	; TWICE the 8-bit required pattern
#if MAX_BRAIDS % 2
; *** in case of odd MAX_BRAIDS value, add the following code ***
	DEY					; now it is even
	STA mm_flags-1, Y	; will set an extra previous byte without ill effect
#endif
mm_rsp:
		STA mm_flags-2, Y	; set a couple of braids to FREE, please note table expects indexes from 0
		DEY					; go for next (remember 16-bit)
		DEY
		BNE mm_rsp			; continue until all done (MAX_BRAIDS must be EVEN!!!)
	INY					; default task (will be 1)
	STY mm_pid			; set as current temporary PID
; do NOT set current SP as initialisation will crash! startup via scheduler will do anyway
	STZ cpu_ll			; native 65816, of course ***does extra byte, no problem
	_KERNEL(SET_CURR)	; avoids possible crash upon shell startup
; as everything is set now, patch all task-handling API entries (M16)
	LDY #B_FORK			; first function to be patched
mm_ptl:
		LDA mm_patch, Y		; get from table...
		STA kerntab			; ...and use as parameter
;		PHY					; preserve this! is likely to be respected
		_ADMIN(PATCH)		; install new function
			BCS mm_restore		; somethiong went wrong, undo everything and exit!
;		PLY					; otherwise retrieve loop var, if was saved
		INY					; go for next
		INY
		CPY #GET_PID		; first NON-patched function...
		BNE mm_ptl			; ...means we are done
; *** shutdown code placeholder *** does not do much
mm_bye:
	_DR_OK				; new interface for both 6502 and 816

; *** discard all patches and return an error code! ***
; Y hold currently failed function code... if not on top of stack! (M16,X8)
mm_restore:
; 	PLY					; if it had to be saved!
mm_rslp:
		DEY					; go for previous function
		DEY
		CPY #B_FORK-2		; just before FIRST multitasking function
			BEQ mm_abort		; all done
		STZ kerntab			; otherwise set NULL parameter for unpatch feature!
;		PHY					; for safe operation
		_ADMIN(PATCH)		; restore original kernel function
;		PLY					; restore too, if saved
		BRA mm_rslp			; continue until done
; *** placeholder for unimplemented features ***
mm_abort:
	_DR_ERR(UNAVAIL)

; *******************************
; *** task special exit point ***
; *******************************
mm_suicide:
	.as: .xs: SEP #$30	; ** standard size for app exit ** just in case
	LDY mm_pid			; special entry point for task ending EEEEEEEEEEEK
	SEI					; this needs to be run with interrupts OFF, do not care current status
	JSR mms_kill		; complete KILL procedure and return here (ignoring errors) ***check stack among calls
; *** now switch to another braid as this one is dead! ***
; forget this context as will never be executed again!
; no need to clear z_used as 65816 do not need to manually copy zeropage contents, stack is already empty!
	CLC					; for safety in case RTS is found (when no other braid is active)
; ...then go into the scheduler as this will no longer be executable

; **************************
; **************************
; *** the scheduler code *** usually called from ISR
; **************************
; **************************
mm_sched:
; get next available PID
	LDY #2				; to avoid deadlocks AND proper shutdown detection (2)
	LDX mm_pid			; current PID as index (4)
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

; PID count expired, try to wrap or shutdown if no more live tasks!
mm_wrap:
		LDX #MAX_BRAIDS		; go to end instead, valid as last PID (2)
		DEY					; and check is not forever (2)
		BNE mm_next			; otherwise should only happen at shutdown time (3/2)
mm_lock:
	LDY #PW_CLEAN		; special code to do proper shutdown
	_KERNEL(SHUTDOWN)	; all tasks stopped, time to complete shutdown (as specified by default action)
	_PANIC("{TASK}")	; if ever arrives here, it was wrong at so many levels...

; arrived here in typically ? clocks, if all braids were executable
mm_switch:
; store previous status
	STX mm_pid			; update PID, will need to add that
; keep stack pointer!
	TSX					; get index LSB (2)
	STX sys_sp			; store as usual (3)
; *** this could be the generic context switching ***
; go into new braid
	LDA #>mm_context-256	; get pointer MSB to direct pages eeeeeeeeeeek
	CLC
	ADC mm_pid			; compute offset within stored direct-pages
	XBA					; that was MSB
	LDA #<mm_context	; should be zero
	TCD					; new direct page is set
; set stack pointer to new context
	LDA #>mm_stacks-256	; contextual stack area base pointer MSB, assume page-aligned!!!
	CLC
	ADC mm_pid			; add offset for new braid
	XBA					; that was MSB
	LDA sys_sp			; restored value (3) *** should add LSB if not page-aligned?
	TCS					; stack pointer updated!
; *** end of context switching ***
; now it's time to check whether SIGTERM was sent! new 20150611
	LDY mm_pid			; get new PID again (4)
	LDA mm_flags-1, Y	; had it a SIGTERM request? (4)
; ...but first set running arch & PID!
	PHA					; keep it for arch bits! (2)
	AND #%00000110		; mask for CPU-type bits (2)
	STA cpu_ll			; proper CPU code (3)
;	PHY					; in case is not kept...
	_KERNEL(SET_CURR)	; update system variables, should keep Y which already had the PID
;	PLY					; must retrive if not kept...
	PLA					; but first restore full flags (4)
; continue SIGTERM checking
	LSR					; MUST be shifted for later, easier check of bit 0! (2)
	BCS mm_sigterm		; process it now! (2/3)
mm_rts:
		RTS					; all done, continue ISR... on another braid

; **********************************
; *** the actual SIGTERM routine ***
; **********************************
; no longer ending in RTI!
; needs older SHIFTED flags in A, PID in Y!!!
mm_sigterm:
	ASL					; ...and restore value with clear flag!
	STA mm_flags-1, Y	; EEEEEEEK! clear received TERM signal, new format 20161117
; stack return address upon end of SIGTERM handler
	PHK					; push program bank as 816 code will end in RTL... as mm_stend cannot be $xx0000
	PEA mm_stend-1		; correct return address after SIGTERM handler RTL/RTS
#ifdef	SUPPORT
	TSX					; keep current SP...
	STX sys_sp			; ...in case bank address remains
#endif
; 24-bit indexed jump means the use of RTI as indirect long jump
; original approach, 15b, 27t
	LDA mm_stbnk-1, Y	; now get bank address (4)
	PHA					; push bank address for the simulated 24-bit call (3)
	TYA					; addressed braid (2)
	ASL					; two times for use as index (2)
	TAX					; proper offset in handler table (2)
	LDA mm_term-1, X	; get MSB (4)
	PHA					; and push it (3)
	LDA mm_term-2, X	; same for LSB (4+3)
	PHA
; in case a table of 24-bit pointers is used
; sample 24-bit array code is 20b, 35t
;	TYA					; operate with PID (2)
;	STA systmp			; keep original (3)
;	ASL					; x2 (2)
;	CLC
;	ADC systmp			; x3 (2+3)
;	TAY					; use as new index (2)
;	LDA mm_term-1, Y	; get one byte (4)
;	PHA					; push it (3)
;	LDA mm_term-2, Y	; get one byte (4)
;	PHA					; push it (3)
;	LDA mm_term-3, Y	; get one byte (4)
;	PHA					; push it (3)
	PHP					; as needed by RTI
	RTI					; actual jump, will return to an RTS or RTL just here!
mm_stend:
#ifdef	SUPPORT
; 6502 handlers will end in RTS causing stack imbalance
; must reset SP to previous value
	.as: SEP #$20		; needs 8-bit memory, just in case (3)
	TSC					; the whole stack pointer, will not mess with B (2)
	LDA sys_sp			; will replace the LSB with the stored value (3)
	TCS					; all set! (2)
#endif
	RTS					; back to ISR in new context, might be called from 

; ****************************
; ****************************
; *** supporting functions ***
; ****************************
; ****************************
#ifdef	SAFE
; check PID within limits (20 including call)
mm_chkpid:
	TYA					; eeeeeeeek^2 the place to do it, new format (2)
		BEQ mm_pidz			; system-reserved PID???? don't know what to do here... (2/3)
	CPY #MAX_BRAIDS+1	; check whether it's a valid PID (2) eeeeeek!
		BCS mm_piderr		; way too much (2/3) eeeek
	RTS					; back to business (6)
mm_pidz:				; placeholder
; should check whether X means a 0-compatible subfunction (B_EXEC for this, B_SIGNAL for all)
mm_piderr:
	PLA					; discard return address, since called from a subroutine (4+4)
	PLA
mm_bad:
	_DR_ERR(INVALID)	; not a valid PID or subfunction code, worth checking
#endif

; ************************************
; *** replacement Kernel functions ***
; ************************************

; *** switch to next braid ***
mm_yield:
; 65816 calls already run with interrupts OFF!
	JSR mm_sched		; ...then will CALL the scheduler!
; interrupt status will be restored later
	_EXIT_OK			; I hope it is OK...

; *** reserve a free braid ***
; Y -> PID
mm_fork:
	LDY #MAX_BRAIDS		; scan backwards is usually faster (2)
; ** assume interrupts are off via COP **
mmf_loop:
		LDA mm_flags-1, Y	; get that braid's status (4)
		AND #BR_MASK		; mandatory now (2)
		CMP #BR_FREE		; check whether available (2)
			BEQ mmf_found		; got it (2/3)
		DEY					; try next (2)
		BNE mmf_loop		; until the bottom of the list (3/2)
	BEQ mmf_nfound		; nothing was found, just return 0 as system-reserved braid ID
; otherwise there are some flags to initialise
		LDA #BR_RISE		; new value, currently set as BR_STOP (2)
		STA mm_flags-1, Y	; reserve braid (4)
mmf_nfound:
	_EXIT_OK				; return set PID

; -------------------------------OLD----------------------

; get code at some address running into a paused (?) braid ****** REVISE ****** REVISE ******
; Y <- PID, ex_pt <- addr, cpu_ll <- architecture, def_io <- sys_in & sysout
; no longer should need some flag to indicate XIP or not! code start address always at stack bottom
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
; *****should place at the very bottom the (full) starting address, in case of non-XIP
	.al: REP #$20		; *** 16-bit memory ***
	LDA def_io			; get sys_in & sysout from parameter, revise ABI
	PHA					; into stack, but BEFORE PID
	PHY					; keep PID for later!
	TSX					; store older stack pointer!
	STX sys_sp			; ** 816 ABI is OK for CS **
; switch to future stack frame for easier creation
	TCS					; future stack pointer for easier frame construction
; this was only for XIP code, otherwise shoud push a different handler address AND below that the pointer to the assigned block (handler will take it for FREE)
; ** check flag for XIP/non-XIP code and jump to mmx_nonxip if needed
; ** XIP handler **
	LDX #0				; canary and bank address of SIG_KILL handler, taken by FINISH
	PHX					; bottom of stack!
	PEA mm_suicide-1	; corrected 'return' address for definitive SIG_KILL handler
;		BRA mmx_frame		; continue creating stack frame!
; ** non-XIP handler **
;mmx_nonxip:
;	LDX ex_pt+2			; get bank
;	PĤX					; push it
;	LDA ex_pt			; get address (16-bit)
;	PHA					; push it
;	LDX #0				; bank address of mm_oblit handler, taken by FINISH
;	PHX					; just above starting pointer
;	PEA mm_oblit-1		; compute end-of-task MSB for non-XIP (will arrive via RTL, thus one byte before)
; ** could jump to mmx_frame in case of optimisation **
; now the start address, no offset is needed if ending on RTI
mmx_frame:
	LDX ex_pt+2			; get bank address of starting point
	PHX					; place in on stack
	LDA ex_pt			; get full (minus bank) program address
	PHA					; RTI-savvy address placed
	LDX #$30			; as status means 8-bit size, interrupts enabled!
	PHX					; push fake status register!
; *****please put actual register contents as per future interface
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
; set architecture into flags!
	LDX #0				; reset index
arch_loop:
		CMP arch_tab, X		; compare with list item
			BEQ arch_ok			; detected!
		INX					; next
		CPX #4				; supported limit?
		BNE arch_loop		; still to go
	_DR_ERR(INVALID)	; cannot execute this! should be a mere error
arch_ok:
	TXA					; make equivalent code from index!
	ASL					; two times to make it SIGterm flag savvy!
	ORA #BR_RUN			; will enable task
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
	PHY					; keep targeted PID for a moment
; free up all MEMORY & windows belonging to this PID...
; Y currently set to desired PID
	_KERNEL(RELEASE)	; free up ALL memory belonging to this PID, new 20161115
; now it is time to release memory assigned for non-XIP executable!
	PLA					; retrieve desired PID... as LSB
	CLC
	ADC #>mm_stacks-256	; contextual stack area base pointer, assume page-aligned!!!
; this version for pointer copying takes 18b/29t until call
;	STA mk_nxpt+1			; this is MSB, stored in local pointer
;	LDA #$FD			; make it point at stored address, LSB only *** assume page-aligned!!!
;	STA mk_nxpt		; store local pointer to bottom of stack
;	LDA (mk_nxpt) 	; get first pointer byte from stack
;	STA ma_pt		; store as zp parameter
;	REP #$20		; *** 16-bit memory ***
;	LDY #1			; move index, not worth a loop
;	LDA (mk_nxpt), Y 	; get last pointer word from stack
;	STA ma_pt+1		; store as zp parameter
; alternative code is 16b/30t until call and saves local
	XBA				; that was MSB
	LDA #$FD			; make it point at stored address, LSB only *** assume page-aligned!!!
	.xl: .al: REP #$30	; *** all 16-bit ***
	TAX				; offset is full address
	LDA $0, X			; get base word
	STA ma_pt			; store as zp parameter
	LDY $2, X			; 6800-like indexing! gets extra byte
	.xs: .as: SEP #$30	; *** back to 8-bit ***
	STY ma_pt+2			; store bank byte eeeeeeek
; another version is 16b/33t eeeeeeeek
;	XBA					; that was MSB
;	LDA #0				; make it point at whole stack space *** assume page-aligned!!!
;	PHD					; keep direct pointer!
;	TCD					; temporarily at stack space!
;	REP #$20			; *** 16-bit memory ***
;	LDA $FD				; get word, note offset eeeeeeek
;	LDY $FF				; get bank
;	PLD					; restore direct page
;	STA ma_pt			; store word as zp parameter
;	STY ma_pt+2			; store bank as zp parameter
; will take address anyhow, FREE will quietly fail if no block was assigned to that pointer
	_KERNEL(FREE)		; try to release the executable block
; do not care if FREE succeeded or not...
; window release *** TO DO *** TO DO *** TO DO ***
	_DR_OK				; return as appropriate

	.as					; remaining routines are called in 8-bit mode

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

; get current PID **might be deprecated as directly handled in API
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
; staying in 8-bit mode takes 10b, 14t
;	LDA ex_pt			; get pointer LSB (3)
;	STA mm_term-2, X	; store in table (4)
;	LDA ex_pt+1			; now for MSB (3+4)
;	STA mm_term-1, X
; going 16-bit takes 7b, 12t (9b, 15t if actually needed to go back into 8-bit)
	.al: REP #$20		; *** 16-bit memory *** (3)
	LDA ex_pt			; get pointer (4)
	STA mm_term-2, X	; store in table (5)
; end of CS
; ** priorize braid, jump to it at once, really needed? **
mm_prior:				; this is just a placeholder
	_DR_OK

; emergency exit, should never arrive here!
mm_nreq:
	_NEXT_ISR			; just in case


; *********************************
; *** diverse data and pointers ***
; *********************************

; *** array of patch addresses ***
mm_patch:
	.word	mm_fork
	.word	mm_exec
	.word	mm_signal
	.word	mm_flags
	.word	mm_seth
; B_YIELD is not patched as will use standtard SET_CURR interface


; ------- OLD -------------
; *** signal routines addresses table ***
mms_table:
	.word	mms_kill
	.word	mms_term
	.word	mms_cont
	.word	mms_stop
.)
