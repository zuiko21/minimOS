; software multitasking module for minimOS
; v0.5a6
; (c) 2015-2016 Carlos J. Santisteban
; last modified 20150928-1045

; *** this makes sense for 02 only, but check newer interface ASAP *************************
; in case of standalone assembly from 'xa drivers/multitask.s'
#ifndef		DRIVERS
#include "options.h"
#include "macros.h"
#include "abi.h"		; new filename
.zero
#include "zeropage.h"
.bss
#include "firmware/firmware.h"
#include "sysvars.h"
; specific header
#include "drivers/multitask.h"
.text
#endif

; *** begins with sub-function addresses table, new format 20150323 ***
	.byt	TASK_DEV	; physical driver number D_ID (TBD)
	.byt	A_POLL		; polling scheduler this far, might get some I/O for API
	.word	mm_init		; initialize device and appropiate sysvars, called by POST only
	.word	mm_sched	; periodic scheduler
	.word	mm_rts		; D_REQ does nothing
	.word	mm_rts		; no input
	.word	mm_cmd		; output will process all subfunctions!
	.word	mm_rts		; no need for 1-second interrupt
	.word	mm_rts		; no block input
	.word	mm_rts		; no block output
	.word	mm_bye		; shutdown procedure
	.word	mm_info		; NEW, points to descriptor string
	.byt	0			; reserved, D_MEM

; *** driver description, NEW 20150323 ***
mm_info:
	.asc	MAX_BRAIDS+'0', "-task Software Scheduler v0.5a4", 0

; *** initialisation code ***
mm_init:
; might check for bankswitching hardware and cause error, in order NOT to install BOTH schedulers!...
; hardware-assisted scheduler init code should do the opposite!
; remaining code assumes software scheduler only
	LDA #QUANTUM_COUNT
	STA mm_qcnt			; init quantum counter
; initialise stack pointers
	LDA #>mm_context	; MSB of storage area
	STA sysptr+1		; store in pointer, will be increased
	LDA #<mm_context	; same for LSB
	STA sysptr
	LDY #sys_sp			; offset for sys_sp, just in case
	CLC					; hope isn't needed anymore in the loop!
	LDA #0				; reset index
	LDX #MAX_BRAIDS		; set counter (much safer this way)
mm_rsp:
		ADC #256/MAX_BRAIDS-1	; compute initial SP value for that braid (will be 63 for 4 braids)
		STA (sysptr), Y		; store "register" in proper area
		INC sysptr+1		; move pointer to next storage area
		_INC				; increase pointer to next braid space
		DEX					; one braid less (much safer this way)
		BNE mm_rsp			; finish all braids (much safer this way)
; initialise flags table
	LDA #BR_FREE		; adequate value in two highest bits
	LDX #MAX_BRAIDS		; last index of status array IF counting from 0
mm_xsl:						; should take 35 clocks
		STA mm_flags-1, X	; set braid to FREE, please note X counts from 1 but table expects indexes from 0
		_STZY mm_treq-1, X	; set SIGTERM request flags to zero, new 20150611, poorly optimized for NMOS macro
		DEX					; backwards is faster, or at least saves a CPX
		BNE mm_xsl			; all braids, including the first one
	INX					; the first PID is 1
	STX mm_pid			; set index as current PID
; prepare first running task
	LDA #<mms_kill-1	; get default TERM handler LSB (will arrive via RTS, thus one byte before)
	STA mm_term			; store in table
	LDA #>mms_kill-1	; same for MSB
	STA mm_term+1
	LDA #BR_RUN			; will start "current" task
	STA mm_flags		; no need for index, first entry anyway
; get proper stack frame from kernel, new 20150507
	_KERNEL(TS_INFO)	; get taskswitching info for needed stack frame

#ifdef	SAFE
		_DR_ERR(UNAVAIL)	; error if not available
#endif

	STY mm_sfsiz		; store stack frame size! new 20150521
mm_tscp:
		LDA zpar-1, Y		; get output value (note offset)
		STA mm_stack-1, Y	; store into private vars
		DEY					; go for next byte
		BNE mm_tscp
	_DR_OK				; new interface for both 6502 and 816

; *** the scheduler code ***
mm_sched:
; check whether it's time to switch or not
	DEC mm_qcnt			; decrease remaining quantum count (6)
	BEQ mm_do			; change task if expired (2/3)
		RTS					; go away ASAP otherwise (6/0)
mm_do:
; execute scheduler itself
	LDA #QUANTUM_COUNT	; get number of quantums to wait (2)
	STA mm_qcnt			; restore counter for next time (4)
; get next available PID

#ifdef	SAFE
	LDY #2				; to avoid deadlocks (2)
#endif

	LDX mm_pid			; actual PID as index (4)
mm_scan:
		DEX					; going backwards is faster (2)
		BNE mm_next			; no wrap, remember first PID is 1 (3/2)
			LDX #MAX_BRAIDS		; go to end instead, valid as last PID (2)

#ifdef	SAFE
			DEY					; and check is not forever (2)
				BEQ mm_lock			; shouldn't happen ever! (2/3)
#endif

mm_next:
		LDA mm_flags-1, X		; get status of entry, seems OK for first PID=1 (4)
		BNE mm_scan				; zero means executable braid (3/2)
; an executable braid is found
	CPX mm_pid			; is it the same as before? (4)
		BNE mm_switch		; if not, go and switch braids (3/2)
		BEQ mm_rts			; otherwise, nothing to do; no need for BRA (0/3)

#ifdef	SAFE
mm_lock:
	_KERNEL(GO_SHELL)	; severe error! restart the shell
#endif

; arrived here in typically 39 clocks, if all braids were executable
mm_switch:
; go into new braid, saving previous context
; this will be MUCH faster (9 clocks) with hardware-assisted context bankswitching...
	STX systmp			; store new PID (3)
	LDA mm_pid			; compute older PID's storage address (4+2)
	CLC
	ADC #>mm_context	; PID as MSB (full page for each context) (2)
	STA sysptr+1		; store pointer MSB (3)
	LDA #<mm_context	; fixed LSB (2+3)
	STA sysptr
; store previous status
; keep stack pointer!
	TSX					; get index (2)
	STX sys_sp			; store as usual (3)
; then user-zeropage
	LDA z_used			; actual bytes used on zeropage (3, 27 up to here)
	_STAY(sysptr)		; store value
		BEQ mm_saved		; skip if nothing to save (+2/3)
	TAY					; use as index
mm_save:
		LDA z_used, Y		; get byte from zeropage (4*)
		STA (sysptr), Y		; store it, although two bytes earlier (5)
		DEY					; previous byte (2)
		BNE mm_save			; until z_used, but NOT copied itself (3/2, used*14, max 3150) eeek!
mm_saved:
; finally the kernel context
	LDY #locals			; beginning of variables (2)
mm_kern:
		LDA 0, Y			; get byte from locals and parameters (4*)
		STA (sysptr), Y		; store in context area (5)
		INY					; next byte (2)
		BNE mm_kern			; up to $FF (3/2, total 391)
; now let's retrieve new task's context
; compute storage address
	LDA systmp			; retrieve new PID (3)
	STA mm_pid			; set new value, in the meanwhile (4+2)
	CLC
	ADC #>mm_context	; PID as MSB (full page for each context) (2)
	STA sysptr+1		; store pointer MSB, LSB is still valid (3)
; restore kernel context
	LDY #locals			; beginning of variables (2, 16 up here)
mm_rest:
		LDA (sysptr), Y		; get from context area (5)
		STA 0, Y			; store byte from locals and parameters (4*)
		INY					; next byte (2)
		BNE mm_rest			; up to $FF (3/2, total 391)
; then user-zeropage
	_LDAY(sysptr)		; stored z_used (5)
	STA z_used			; restore in zero page
		BEQ mm_loaded		; skip if possible
	TAY					; actual bytes used on zeropage (2)
mm_load:
		LDA (sysptr), Y		; get it, although two bytes earlier (5)
		STA z_used, Y		; store byte in zeropage (4*)
		DEY					; previous byte (2)
		BNE mm_load			; until z_used but NOT copied itself (3/2, used*14+13, max 3163)
mm_loaded:
; finally get current stack pointer!
	LDX sys_sp			; restored value (3)
	TXS					; stack pointer updated! (2)
; now it's time to check whether SIGTERM was sent! new 20150611
	LDX mm_pid			; get current PID again (4)
	LDA mm_treq-1, X	; had it a SIGTERM request? (4)
		BNE mm_sigterm		; process it now! (2/3)
mm_rts:
	_DR_OK				; everything done, continue with ISR, will RTS do?

; the actual SIGTERM routine execution, new 20150611
mm_sigterm:
	_STZA mm_treq-1, X	; EEEEEEEK! Clear received TERM signal
	JSR mms_tj			; should call handler and let it finish at some point (6+32)
	_BRA mm_rts			; term handler will return here

mms_tj:
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
	_SEI				; *** critical section begins ***
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
	CLI					; *** end of critical section ***
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
	_SEI				; this is delicate (2)
	LDA mm_flags-1, Y	; first check current state (5)
	CMP #BR_STOP		; is it paused? (2)
		BNE mms_kerr		; no way to resume it! (2/3)
	LDA #BR_RUN			; resume (2)
	STA mm_flags-1, Y	; store new status (5)
	CLI					; were off for ...
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
	_DR_OK			; placeholder

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
