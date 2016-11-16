; software multitasking module for minimOS
; v0.5.1a2
; (c) 2015-2016 Carlos J. Santisteban
; last modified 20161116-1231

; will install only if no other multitasking driver is already present!
#ifndef	MULTITASK
#define		MULTITASK	_MULTITASK

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
	.asc	MAX_BRAIDS+'0', "-task Software Scheduler v0.5.1a2", 0	; works as long as no more than 9 braids!

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
	LDA #>mm_context	; MSB of storage area
	CLC					; hope isn't needed anymore in the loop!
	ADC #MAX_BRAIDS		; prepare backwards pointer! temporarily outside range...
	STA sysptr+1		; store in pointer, will be increased
	LDA #<mm_context	; same for LSB, will not bother adding sys_sp
	STA sysptr
	LDY #sys_sp			; offset for sys_sp, just in case
	LDX #MAX_BRAIDS		; set counter (much safer this way)
mm_rsp:
		LDA #$FF			; original SP value, no need to skim on that
		DEC sysptr+1		; move pointer to next storage area
		STA (sysptr), Y		; store "register" in proper area
		LDA #BR_FREE		; adequate value in two highest bits
		STA mm_flags-1, X	; set braid to FREE, please note X counts from 1 but table expects indexes from 0
		_STZA mm_treq-1, X	; set SIGTERM request flags to zero, new 20150611, poorly optimized for NMOS macro
		DEX					; one braid less (much safer this way)
		BNE mm_rsp			; finish all braids (much safer this way)
	INX					; the first PID is 1
	STX mm_pid			; set index as current PID
; do NOT set current SP as initialisation will crash! startup via scheduler will do anyway
mm_bye:
	_DR_OK				; new interface for both 6502 and 816

; kill itself!!! simple way to terminate after FINISH
mms_suicide:
	LDY mm_pid			; special entry point for task ending EEEEEEEEEEEK
	JSR mms_kill		; complete KILL procedure and return here (ignoring errors)
; ...then go into B_YIELD as this will no longer be executable

; switch to next braid
mm_yield:
	CLC					; for safety in case RTS is found (when no other braid is active)
; ...then will go into the scheduler afterwards!

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
		_KERNEL(SHUTDOWN)	; all tasks stopped, time for shutdown

; arrived here in typically 39 clocks, if all braids were executable
mm_switch:
; store previous status
	STX systmp			; store new PID (3)
; *** save current context! ***
; first save both zeropage & stack from context as stated in mm_pid
	LDA #<mm_context	; possibly zero
	STA sysptr			; set LSB
	LDA #>mm_context-256	; get pointer to direct pages eeeeeeeeeeek
	ADC mm_pid			; compute offset within stored direct-pages
	STA sysptr+1		; indirect pointer is ready
; save zeropage
	LDY z_used			; actual bytes used on zeropage (3, 27 up to here)
#ifndef	C64
	INY					; take standard devices also!
	INY
#else
		BEQ mm_saved		; if nothing to save
#endif
mm_save:
#ifdef	C64
		LDA z_used, Y		; 6510 will skip port, but store it two bytes easlier
#else
		LDA 0, Y			; get byte from zeropage (4*)
#endif
		STA (sysptr), Y		; store it (5)
		DEY					; previous byte (2)
		BNE mm_save			; until first byte, but NOT included (3/2)
mm_saved:
; copy missing byte
#ifdef	C64
		LDA z_used			; 6510 will skip port, but store it two bytes earlier
#else
		LDA 0				; get byte from zeropage (4*)
#endif
		STA (sysptr), Y		; store it (5)
; save kernel local context also
#ifdef	C64
	LDY #std_in			; first byte of system context
#else
	LDY #locals			; system context
#endif
mm_kern:
		LDA 0, Y			; get byte from locals and parameters (4*)
		STA (sysptr), Y		; store in context area (5)
		INY					; next byte (2)
		CPY #sysptr			; this will not get copied (first byte of reserved arrea)
		BNE mm_kern			; up to $FF (3/2, total 391)
; keep stack pointer!
	LDY #sys_sp			; will point to last 
	TSX					; get index MSB (2)
	TXA					; cannot indirect-index from X
	STA (sysptr), Y		; store as usual (3)
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
mm_stsav:
		LDA $0100, Y		; get stack contents
		STA (sysptr), Y		; storage area
		INY					; go for next
		BNE mm_stsav		; until the end
; *** now let's retrieve new task's context ***
; compute storage address
	LDA systmp			; retrieve new PID (3)
	STA mm_pid			; set new value, in the meanwhile (4+2)
	CLC
	ADC #>mm_context	; PID as MSB (full page for each context) (2)
	STA sysptr+1		; store pointer MSB (3)
	LDA #<mm_context	; might be zero
	STA sysptr			; indirect pointer ready!
; retrieve zeropage
	LDY #z_used			; offset to parameter
	LDA (sysptr), Y		; actual bytes used on zeropage
	TAY					; use as index!
#ifndef	C64
	INY					; take standard devices also!
	INY
#else
		BEQ mm_loaded		; if nothing to retrieve
#endif
mm_load:
		LDA (sysptr), Y		; store it (5)
#ifdef	C64
		STA z_used, Y		; 6510 will skip port, but store it two bytes easlier
#else
		STA 0, Y			; get byte from zeropage (4*)
#endif
		DEY					; previous byte (2)
		BNE mm_save			; until first byte, but NOT included (3/2)
mm_saved:
; copy missing byte
		LDA (sysptr), Y		; store it (5)
#ifdef	C64
		STA z_used, Y		; 6510 will skip port, but store it two bytes easlier
#else
		STA 0, Y			; get byte from zeropage (4*)
#endif
; save kernel local context also
#ifdef	C64
	LDY #std_in			; first byte of system context
#else
	LDY #locals			; system context
#endif
mm_lkern:
		LDA (sysptr), Y		; get from context area (5)
		STA 0, Y			; get byte from locals and parameters (4*)
		INY					; next byte (2)
		CPY #sysptr			; this will not get copied (first byte of reserved arrea)
		BNE mm_lkern		; until sysptr not included
; retrieve stack pointer!
	LDY #sys_sp			; will point to last 
	LDA (sysptr), Y		; retrieve
	TAX					; cannot set SP from A
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



; **********************OLD CODE****************
; now it's time to check whether SIGTERM was sent! new 20150611
	LDX mm_pid			; get current PID again (4)
	LDA mm_treq-1, X	; had it a SIGTERM request? (4)
		BNE mm_sigterm		; process it now! (2/3)
	RTS					; all done, continue ISR

; the actual SIGTERM routine execution, new 20150611
mm_sigterm:
	_STZA mm_treq-1, X	; EEEEEEEK! Clear received TERM signal
	JSR mms_tj			; should call handler and let it finish at some point (6+32)
	_FINISH				; term handler will return here, is this OK?

mms_tj:
; ********* revise this for 816 ***********
	TXA					; addressed braid (2)
	ASL					; two times (2)
	TAX					; proper offset in handler table, plus 2 (2)
	LDA mm_term-1, X	; get MSB from table (4)
	PHA					; put it on stack (3)
	LDA mm_term-2, X	; now get the LSB, I can save both DEXs (4)
	PHA					; address complete (3)
	PHP					; ready for RTI (3)
	RTI					; do jump to handler (6)

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

	_JMPX(mm_funct)		; jump to appropriate routine (6)

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
	PLA					; discard return address, since called from a subroutine (4+4)
	PLA
mm_bad:
	_DR_ERR(INVALID)		; not a valid PID or subfunction code, worth checking
#endif

; reserve a free braid
mm_fork:
	LDY #MAX_BRAIDS-1	; scan backwards is usually faster (2)
	_SEI				; this is delicate (2)
mmf_loop:
		LDA mm_flags, Y		; get that braid's status (4)
		CMP #BR_FREE		; check whether available (2)
			BEQ mmf_found		; got it (2/3)
		DEY					; try next (2)
		BPL mmf_loop		; until the bottom of the list (3/2)
	CLI					; nothing was found (2)
	_DR_ERR(FULL)			; no available braids!
mmf_found:
	LDA #BR_STOP		; *** is this OK? somewhat dangerous *** (2)
	STA mm_flags, Y		; reserve braid (4)
	CLI					; end of risk (2)
	INY					; first PID is 1 (2)
	_DR_OK

; get code at some address running into a paused (?) braid
mm_exec:

#ifdef	SAFE
	JSR mm_chkpid		; check for a valid PID first (21)
	TYA					; use PID as MSB offset *** optimized 20150616
#else
	LDA locals			; supposedly valid PID! *** optimized 20150616
#endif

; prepare storage pointer for later
	_DEC
	CLC					; put after DEC, otherwise NMOS emulation might fail! 20150616
	ADC #>mm_context	; compute final MSB, note first stored PID is 1!
	STA sysptr+1		; store it
	LDA #<mm_context	; LSB needs no offset
	STA sysptr			; store it
; compute shared stack address
	LDA #0				; reset values
	CLC
mme_sp:
		ADC #256/MAX_BRAIDS		; go for next stack space
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
mm_pre_exec:
	STA z_used		; store maximum available zero-page bytes from A, for safety EEEEEEK
	RTI				; 'return' to start of task! Much simpler, as long as a dummy PHP is done

; switch to next braid
mm_yield:
	_DR_OK			; if no multitasking assisting hardware is present, just ignore and stay, will RTS do?

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
	_JMPX(mms_table)	; jump to actual code

mms_table:
	.word	mms_kill
	.word	mms_term
	.word	mms_cont
	.word	mms_stop

; kill braid!
mms_kill:
	LDA #BR_FREE		; will be no longer executable (2)
	STA mm_flags-1, Y	; store new status (5)
	LDA #0				; STZ is not worth
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
	_ENTER_CS			; this is delicate (2)
	LDA mm_flags-1, Y	; first check current state (5)
	CMP #BR_STOP		; is it paused? (2)
		BNE mms_kerr		; no way to resume it! (2/3)
	LDA #BR_RUN			; resume (2)
	STA mm_flags-1, Y	; store new status (5)
	_EXIT_CS			; were off for ...
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
	_ENTER_CS			; this is delicate... (2)
	STA mm_term, Y		; store in table (4)
	LDA zpar2+1			; now for MSB (3+4)
	STA mm_term+1, Y
	_EXIT_CS			; were off for 13 clocks (2)
	_DR_OK

; priorize braid, jump to it at once, really needed?
mm_prior:
	_DR_OK				; placeholder

; emergency exit, should never arruive here!
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

#endif
