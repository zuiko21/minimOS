; minimOS software multitasking
; (c) 2014-2020 Carlos J. Santisteban
; last modified: 20141010-1109

; local definitions
; reduce taskswitching overhead by taking several quantums
; for 4 braids @ 200Hz, global latency stays below 160ms (5x32)
#DEFINE	QUANTUM_COUNT	8
#DEFINE	MAX_BRAID		3

; *** data section at scheduler.h ***
;mm_sq		.byt	; quantums to waste before switching braid
;mm_pid		.byt	; current braid
;mm_flags	.ds	4	; execution state for each braid, array-like

; *** init code ***
	LDA #QUANTUM_COUNT
	STA mm_sq
	LDX #0	; pointer to stack "registers"
	CLC		; hope isn't needed anymore in the loop!
mm_rsp			; this loop will take 51 clocks
		TXA
		ADC #63			; create initial SP value for that braid (for 4)
		STA $0100, X	; store "register" in proper area
		TAX				; increase pointer to next braid space
		INX				; probably faster than adding 64 both ways
		BNE mm_rsp		; finish all four braids
	LDA #IDLE_BRAID	; adequate value in two highest bits -TBD
	LDX #MAX_BRAIDS	; last index of state array
mm_xsl						; should take 35 clocks
		STA mm_flags, X		; set braid to IDLE
		DEX					; backwards
		BNE mm_xsl			; all braids except 0
	LDA #ACTIVE_BRAID	; will start "current" task, tbd
	STA mm_flags		; no need for index
;	RTS					; init done?

; *** _hardwired_ interrupt task ***
	DEC mm_sq	; decrease quantum count (6 clocks?)
	BEQ mm_expired
	RTS			; not yet
mm_expired			; +9 clocks
	LDA #QUANTUM_COUNT
	STA mm_sq	; restore counter for next interrupt
	LDX mm_pid	; get current PID
	TXA			; keep current PID for later
	LDY #2		; in order to avoid deadlocks
mm_scan				; +36 clocks
		DEX				; switching backwards...
		BPL mm_next		; ...is faster most of the time
			DEY			; do it twice and will become zero
			BEQ mm_lock	; shouldn't happen ever!
			LDX #MAX_BRAID	; reset loop
	mm_next					; +5 (+10 if wraps)
		BIT mm_flags, X	; check braid status (?)
		BNE mm_scan		; look for zero => executable	(+7 for loop ending, minus the last iteration)
	CPX mm_pid		; the only task running?
	BEQ mm_nocs		; skip context switch!	(+6 if context switch, +7 otherwise)
		CLC
		ROR
		ROR
		ROR			; rotate to get two bits at the highest positions!
		TAY			; keep offset
		TSX			; get current SP
		TXA
		STA $0100, Y		; store in proper register
		STX mm_pid			; switch braid
		TAY					; get (still current) PID
		LDA #EXECUTABLE_BRAID
		STA mm_flags, Y		; put former task to sleep, should be zero for BNE in the loop to work
		LDA #ACTIVE_BRAID
		STA mm_flags, X		; wakeup new task
		TYA					; get older PID for saving context
		CLC
		ADC #>mm_ctx		; base _page_ for context area
		STA	z_some+1		; pointer for zero-page copy area
		LDA #<mm_ctx		; base pointer LSB, or should be zero?
		STA	z_some			; NMOS savvy in case of STZ
		LDX z_count			; get number of actually used ZP bytes
	mm_save					; +53 clocks
			LDA $0, X			; get older context
			STA (z_some), X		; save into proper area
			DEX
			BNE mm_save		; from 1, careful with C=64!	(+13 each, I hope)
		LDY mm_pid			; new PID to read context from
		TYA					; save for later
		CLC
		ADC #>mm_ctx		; base pointer MSB for context area
		STA	z_some+1		; ponter for zero-page copy area
		LDA #<mm_ctx		; base pointer LSB, or should be zero?
		STA	z_some			; NMOS savvy in case of STZ
		LDX #z_count		; get offset of actually used ZP bytes
		LDA (z_some), X		; pick number of actually used ZP bytes
		TAX
	mm_reca				; +23?
			LDA (z_some), X		; get older context
			STA $0, X			; save into proper area
			DEX
			BNE mm_reca		; from 1, careful with C=64!	(+13 each)
		TYA					; get back new PID
		CLC
		ROR
		ROR
		ROR					; rotate to get two bits at the highest positions!
		TAY					; keep offset
		LDA $0100, X		; get saved SP
		TAX
		TXS					; restore SP
mm_nocs

;***********************************
;***** context save for exec() *****
;***********************************
	LDA	mm_pid			; get current PID 
	CLC
	ADC #>mm_ctx		; base _page_ for context area
	STA	z_some+1		; pointer for zero-page copy area
	LDA #<mm_ctx		; base pointer LSB, or should be zero?
	STA	z_some			; NMOS savvy in case of STZ
	LDX z_count			; get number of actually used ZP bytes
exec_save					; 
		LDA $0, X			; get older context
		STA (z_some), X		; save into proper area
		DEX
		BNE exec_save		; from 1, careful with C=64!	(+13 each, I hope)
	LDA #ACTIVE
	STA mm_flags, Y	; set executable new task
	STY mm_pid			; set new PID
	STZ z_used			; this far?

;************************************
;************ fork() ****************
;************************************
; *** K16, get available PID ***
b_fork:				; Y -> PID
	LDX #2			; avoiding deadlocks
	LDY mm_pid		; get current PID for a starting point
	_SEI			; ***CRITICAL SECTION***
k16_snb:
		INY			; check next braid
		CPY #MAX_BRAID+1
		BNE k16_nbw	; no need to wrap
			LDY #0
			DEX		; no more than two cycles
			BEQ k16_noav	; no available braid found
	k16_nbw:
		LDA mm_flags, Y		; get state of a braid
		CMP #IDLE_BRAID		; check whether free
		BNE k16_snb			; go for another
	LDA #HOLD_BRAID		; stay paused
	STA mm_flags, Y
	CLI					; exit critical section, 65xx need no Kernel call
	_EXIT_OK
k16_noav:
	CLI					; another exit point
	_ERR(FULL)			; no free braid
