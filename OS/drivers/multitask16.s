; software multitasking module for minimOS·16
; v0.5.1a1
; (c) 2016 Carlos J. Santisteban
; last modified 20161011-1105

; *** set some reasonable number of braids ***
	-MAX_BRAIDS	= 16	; takes 8 kiB -- hope it is OK to define here!

#ifndef		HEADERS
#include "usual.h"
; specific header
#include "drivers/multitask16.h"
#endif

; *** begins with sub-function addresses table, new format 20150323 ***
	.byt	TASK_DEV	; physical driver number D_ID (TBD)
	.byt	A_POLL		; polling scheduler this far, might get some I/O for API
	.word	mm_init		; initialize device and appropiate sysvars, called by POST only
	.word	mm_sched	; periodic scheduler
	.word	mm_exit		; D_REQ does nothing
	.word	mm_exit		; no input
	.word	mm_cmd		; output will process all subfunctions!
	.word	mm_rts		; no need for 1-second interrupt
	.word	mm_exit		; no block input
	.word	mm_exit		; no block output
	.word	mm_bye		; shutdown procedure
	.word	mm_info		; NEW, points to descriptor string
	.byt	0			; reserved, D_MEM

; *** driver description, NEW 20150323 ***
mm_info:
	.asc	MAX_BRAIDS+'0', "-task 65816 Scheduler v0.5a2", 0

; *** initialisation code ***
mm_init:
; might check for bankswitching hardware and cause error, in order NOT to install BOTH schedulers!...
; hardware-assisted scheduler init code should do the opposite!
; remaining code assumes software scheduler only

; initialise stack pointers and flags table
	LDA #>mm_context	; MSB of storage area
	CLC
	ADC #MAX_BRAIDS		; prepare backwards pointer! temporarily outside range...
	XBA					; will be the rest of the pointer
	LDA #<mm_context	; same for LSB... should be ZERO for performance reasons
	TCD					; direct-page set for just-over-last context
	LDX #MAX_BRAIDS		; reset backwards index
	LDY #$FF			; original SP value, no need to skim on that
mm_rsp:
		XBA					; get accumulator MSB
		DEC					; go for next context (contiguous)
		XBA					; back to MSB
		TCD					; set direct-page
		STY sys_sp			; direct page storage of original SP
		LDA #BR_FREE		; adequate value in two highest bits
		STA mm_flags-1, X	; set braid to FREE, please note X counts from 1 but table expects indexes from 0
		STZ mm_treq-1, X	; set SIGTERM request flags to zero
		LDA #<mm_context	; restore LSB... should be ZERO for performance reasons
		DEX					; go for next
		BNE mm_rsp			; continue until all done
	LDA #1				; default task
	STA mm_pid			; set as current PID
; set current SP
	LDA #>mm_stacks		; contextual stack area base pointer *** assume page-aligned!!!
	XBA					; that was MSB
	LDA sys_sp			; restored value (3)
	TCS					; stack pointer updated!
; prepare first running task, as no standard B_FORK will be used
	LDA #<mms_kill-1	; get default TERM handler LSB (will arrive via RTS, thus one byte before)
	STA mm_term			; store in table
	LDA #>mms_kill-1	; same for MSB
	STA mm_term+1
	LDA #BR_RUN			; will start "current" task
	STA mm_flags		; no need for index, first entry anyway
	
; get proper stack frame from kernel, new 20150507 *** REVISE THIS
	_KERNEL(TS_INFO)	; get taskswitching info for needed stack frame

#ifdef	SAFE
	BCC mmi_tsok		; skip if no error eeeeeeeeeek
		_DR_ERR(UNAVAIL)	; error if not available
mmi_tsok:
#endif

	STY mm_sfsiz		; store stack frame size! new 20150521
mm_tscp:
		LDA zpar-1, Y		; get output value (note offset)
		STA mm_stack-1, Y	; store into private vars
		DEY					; go for next byte
		BNE mm_tscp
mm_exit:
	_DR_OK				; new interface for both 6502 and 816
; ******************************* revise all of the above ***********************

; *** the scheduler code ***
mm_sched:
; execute scheduler itself
; get next available PID

	LDY #2				; to avoid deadlocks AND proper shutdown detection (2)
	LDX mm_pid			; actual PID as index (4)
mm_scan:
		DEX					; going backwards is faster (2)
		BNE mm_next			; no wrap, remember first PID is 1 (3/2)
			LDX #MAX_BRAIDS		; go to end instead, valid as last PID (2)
			DEY					; and check is not forever (2)
				BEQ mm_lock			; should only happen at shutdown time (2/3)
mm_next:
		LDA mm_flags-1, X		; get status of entry, seems OK for first PID=1 (4)
		BNE mm_scan				; zero means executable braid (3/2)
; an executable braid is found
	CPX mm_pid			; is it the same as before? (4)
	BNE mm_switch		; if not, go and switch braids (3/2)
		RTS					; otherwise, nothing to do; no need for BRA (0/3)

mm_lock:
		LDY #PW_CLEAN		; special code to do proper shutdown
		_KERNEL(SHUTDOWN)	; all tasks stopped, time for shutdown ****** revise interface

; arrived here in typically 39 clocks, if all braids were executable
mm_switch:
; store previous status
	STX mm_pid			; will need to add that
; keep stack pointer!
	TSX					; get index MSB (2)
	STX sys_sp			; store as usual (3)
; go into new braid
	TDC					; get current zeropage pointer
	XBA					; we will touch MSB only
	CLC
	ADC mm_pid			; compute offset within stored direct-pages
	DEC					; first valid PID is 1!!!
; set stack pointer to new context
	LDA #>mm_stacks-1	; contextual stack area base pointer, assume page-aligned!!!
	CLC
	ADC mm_pid			; add offset for new braid
	XBA					; that was MSB
	LDA sys_sp			; restored value (3) *** should add LSB if not page-aligned?
	TCS					; stack pointer updated!
; now it's time to check whether SIGTERM was sent! new 20150611
	LDX mm_pid			; get current PID again (4)
	LDA mm_treq-1, X	; had it a SIGTERM request? (4)
		BNE mm_sigterm		; process it now! (2/3) *** careful! it ends on FINISH instead of RTS
	RTS					; all done, continue ISR

; the actual SIGTERM routine execution, new 20150611
mm_sigterm:
	STZ mm_treq-1, X	; EEEEEEEK! Clear received TERM signal
	DEX					; correct offset
	TXA					; addressed braid (2)
	ASL					; two times (2)
	TAX					; proper offset in handler table (2)
	JSR (mm_term, X)	; indexed indirect call! note it MUST be in bank zero!!!
	_FINISH				; term handler will return here, is this OK? ******* revise

; *** shutdown code TO DO ***
mm_bye:
mm_rts:
	RTS

; *** subfunction processing section ***
mm_cmd:
	LDX zpar			; get subfunction as index (3)

#ifdef	SAFE
	CPX #MM_PRIOR+2		; check limits, put last subfunction as appropriate (2)
		BPL mm_bad			; go away otherwise! (2/3)
#endif

	JMP (mm_funct, X)	; jump to appropriate routine (6)

#ifdef	SAFE
; check PID within limits (21 clocks optimized 150514, was 23 clocks including JSR)
mm_chkpid:
	LDY locals			; eeeeeeeek! the place to do it (3)
		BEQ mm_pidz			; system-reserved PID???? don't know what to do here... (2/3)
	CPY #MAX_BRAIDS+1	; check whether it's a valid PID (2) eeeeeek!
		BPL mm_piderr		; way too much (2/3)
	RTS					; back to business (6)

mm_pidz:				; placeholder
mm_piderr:
	PLA					; discard return address, since called from a subroutine (4+4) **** check
	PLA
mm_bad:
	_DR_ERR(INVALID)		; not a valid PID or subfunction code, worth checking
#endif

; reserve a free braid
mm_fork:
	LDY #MAX_BRAIDS-1	; scan backwards is usually faster (2)
; ** assume interrupts are off via COP **
mmf_loop:
		LDA mm_flags, Y		; get that braid's status (4)
		CMP #BR_FREE		; check whether available (2)
			BEQ mmf_found		; got it (2/3)
		DEY					; try next (2)
		BPL mmf_loop		; until the bottom of the list (3/2)
	_DR_ERR(FULL)			; no available braids! *** it is a kernel I/O call...
mmf_found:
	LDA #BR_STOP		; *** is this OK? somewhat dangerous *** (2)
	STA mm_flags, Y		; reserve braid (4)
	INY					; first PID is 1 (2)
	_DR_OK			; this OK? it is a kernel I/O call...

; get code at some address running into a paused (?) braid ****** REVISE ****** REVISE ******
mm_exec:

#ifdef	SAFE
	JSR mm_chkpid		; check for a valid PID first (21)
	TYA					; use PID as MSB offset *** optimized 20150616
#else
	LDA locals			; supposedly valid PID! *** optimized 20150616
#endif

; prepare storage pointer for later
	DEC
	CLC					; put after DEC, otherwise NMOS emulation might fail! 20150616
	ADC #>mm_context	; compute final MSB, note first stored PID is 1!
	STA sysptr+1		; store it
	LDA #<mm_context	; LSB needs no offset
	STA sysptr			; store it
; compute shared stack address ****** SUPRESS THIS ********
	LDA #0				; reset values
	CLC
mme_sp:
;		ADC #256/MAX_BRAIDS		; go for next stack space
		DEY						; until desired PID
		BNE mme_sp
	TSX					; get current SP
	_ENTER_CS			; *** critical section begins ***
	STX systmp			; will hold original SP
	TAX					; computed value as destination SP
	DEX					; initial value is one less from next one's start
; *** CAUTION! will switch temporarily into destination stack space for easier creation of stack frame ***
	TXS					; now into destination stack space! EEEEEK
; *** create stack frame ***
; first goes KILL handler, as braids are expected to end via RTS *** could be different for rendez-vous mode calls!
	LDA #>mms_kill-1	; compute end-of-task MSB (will arrive via RTS, thus one byte before)
	PHA
	LDA #<mms_kill-1	; same for LSB
	PHA
; now the start address, no offset is needed if ending on RTI
	LDA zpar2+1			; braid's starting MSB goes first
	PHA
	LDA zpar2			; same for LSB
	PHA
	LDA #$20			; fake PHP value for RTI, start interrupts
	PHA
; ISR will 'return' to pre-execution routine
	LDA #>mm_pre_exec	; pre-execution routine's MSB goes first
	PHA
	LDA #<mm_pre_exec	; same for LSB
	PHA
	PHP					; don't care about interrupts here
; now the usual interrupt stack frame
	LDA #ZP_AVAIL		; value in A will be taken by pre-exec routine!
	PHA
	PHA					; irrelevant values for X, Y
	PHA
; the scheduler calling context! revamped 20150521, need _reversed_ stack frame at mm_stack
	LDY mm_sfsiz		; bytes to copy
mme_sf:
		LDA mm_stack-1, Y	; get stored frame
		PHA					; put it into stack
		DEY					; whatever number of bytes
		BNE mme_sf			; until done
; *** stack frame done, now let's tidy up the pointers! ***
	TSX					; this is the foreign stack pointer
	TXA					; temporary storage
	LDX systmp			; retrive original value
	TXS					; back to our own stack!
	_EXIT_CS			; *** end of critical section ***
	LDY #sys_sp			; get offset for stored SP
	STA (sysptr), Y		; store into context
	LDY #z_used			; offset for user zero-page bytes EEEEEK!
	LDA #0				; pre-execution has no context!
	STA (sysptr), Y		; set null context for much faster startup
	 
	LDY locals			; retrieve PID
	LDA #BR_RUN			; will enable task
	STA mm_flags-1, Y	; Y holds desired PID


; pre-execution routine for faster task-switching first time!
mm_pre_exec:	; ******** revise or delete altogether for 816 **********
	STA z_used		; store maximum available zero-page bytes from A, for safety EEEEEEK
	RTI				; 'return' to start of task! Much simpler, as long as a dummy PHP is done

; switch to next braid
mm_yield:
	_DR_OK			; if no multitasking assisting hardware is present, just ignore and stay

; send some signal to a braid
mm_signal:

#ifdef	SAFE
	JSR mm_chkpid		; check for a valid PID first (21)
#else
	LDY locals			; supposedly valid PID!
#endif

; new code 20150611, needs new ABI but 21 bytes (or 13 if not SAFE) and 13 clocks at most
	LDX zpar2			; get signal code (3)

#ifdef	SAFE
	CPX #SIGCONT+1		; compare against last (2)
	BMI mms_jmp			; abort if wrong signal
		_DR_ERR(INVALID)		; unrecognized signal!
#endif

mms_jmp:
	JMP (mms_table, X)	; jump to actual code

mms_table:
	.word	mms_kill
	.word	mms_term
	.word	mms_cont
	.word	mms_stop

; kill braid!
mms_kill:
	LDA #BR_FREE		; will be no longer executable (2)
	STA mm_flags-1, Y	; store new status (5)
	LDA #0				; no STZ abs,Y
	STA mm_treq-1, Y	; Clear unattended TERM signal, 20150617
; should probably free up all windows belonging to this PID...
	_DR_OK

; ask braid to terminate
mms_term:
	TXA					; should get something not zero!
	STA mm_treq-1, Y	; set SIGTERM request for that braid
	_DR_OK

; resume execution
mms_cont:
	_ENTER_CS			; this is delicate **** really needed?
	LDA mm_flags-1, Y	; first check current state (5)
	CMP #BR_STOP		; is it paused? (2)
		BNE mms_kerr		; no way to resume it! (2/3)
	LDA #BR_RUN			; resume (2)
	STA mm_flags-1, Y	; store new status (5)
	_EXIT_CS			; were off for ... ********** revise
	_DR_OK

; pause execution
mms_stop:
	LDA mm_flags-1, Y	; first check current state (5)
	CMP #BR_RUN			; is it running? (2)
		BNE mms_kerr		; no way to stop it! (2/3)
	LDA #BR_STOP		; pause it (2)
	STA mm_flags-1, Y	; store new status (5)
	_DR_OK
mms_kerr:
	_DR_ERR(INVALID)	; not a valid PID

; get execution flags for a braid
mm_status:

#ifdef	SAFE
	JSR mm_chkpid		; check for a valid PID first (21)
#else
	LDY locals			; supposedly valid PID!
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
#else
	LDY locals			; supposedly valid PID!
#endif

	LDA zpar2			; get pointer LSB (3)
	_SEI				; this is delicate... (2)
	STA mm_term, Y		; store in table (4)
	LDA zpar2+1			; now for MSB (3+4)
	STA mm_term+1, Y
	CLI					; were off for 13 clocks (2)
	_DR_OK

; priorize braid, jump to it at once, really needed?
mm_prior:
	_DR_OK				; placeholder

; emergency exit, should never arrive here!
;mm_emexit:
;	_NEXT_ISR			; just in case

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
