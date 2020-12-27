; sound test (speaker on A14)
; *** downloadable version ***
; (c) 2020 Carlos J. Santisteban
; last modified 20201226-1554

	.text

; *** addresses configuation ***
	*	= $0400				; most firmware savvy

alt		= $5FC0				; needs 32 kiB RAM! change and use another address line if needed (A14...A6)

start:
; *** copy delay loop in alternate location ***
	LDX #end-d_st-1			; bytes to copy
copy:
		LDA d_st, X			; get source
		STA alt, X			; put on alternate location
		DEX
		BPL copy			; until all code is copied
; *** modify alternate copy for return to original ***
	LDX #>d_st				; pick original return address
	LDY #<d_st
	STX alt+cont+2-d_st		; set on alternate copy
	STY alt+cont+1-d_st
; *** sound execution ***
init:
	LDY #170				; initial value for lower freq (1=max)
; *** delay loop for both locations ***
d_st:
		TYA
		TAX					; set initial X
d_loop:
			DEX
			BNE d_loop		; initial delay, depending on initial X
d_last:
			DEX
			BNE d_last		; last, fixed delay (as X is 0)
		DEY					; now a bit higher freq
		BNE cont
lock:
			JMP init		; *** repeat forever ***
cont:
	JMP alt					; execute alternate copy *** this will change on copy ***
end:
