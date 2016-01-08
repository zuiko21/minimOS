; minimOS 0.5??? signal handling
; (c) 2014 Carlos J. Santisteban
; last modified 20141210-1015

; *** KILL process indicated on Y (1...) ***
kill
	TYA
		BEQ err_sysproc		; can't kill reserved system braid
	DEY					; if tables won't hold PID=0
	LDA #_FREE_BR		; non-existant braid (TBD)
	STA mm_flags, Y		; won't get CPU any longer
	; *** may want to _free_ up all windows belonging to this PID ***
	CLC
	RTS					; all OK
err_sysproc
		LDY #_VIOLATION		; not allowed (TBD)
		SEC					; notify error
		RTS

; *** SIGSTOP emulation, pauses process indicated on Y (1...) ***
sigstop
	TYA
		BEQ err_sysproc		; can reuse former code
	DEY					; if tables won't hold PID=0
	LDA #_PAUSED_BR		; could be resumed
	STA mm_flags, Y		; skipped by scheduler (TBD)
	CLC
	RTS					; all OK

; *** SIGTERM emulation, same ABI as before ***
; *** try this if any window goes into REQUEST status ***
sigterm
	TYA
		BEQ err_sysproc		; can reuse former code
	DEC					; if tables won't hold PID=0
	ASL					; access to 2-byte vectors
	TAX					; index to pointer table
		; *** in case of bankswitching, check whether on kernel or user space ***
		LDA term_ptr + 1, X		; get pointer's MSB
		BCS term_jump			; x1 means kernel (DISCARD 01 databank)
		BPL term_jump			; 00 is kernel too (low RAM)
			; do bankswitching in userspace here...
		; *** end of bankswitching procedure ***
term_jump
	JMP (term_ptr, X)	; CMOS, jump to TERM handler for that PID
