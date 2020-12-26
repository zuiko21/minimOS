; sound test (speaker on A14-A6)
; *** RAM-copied version ***
; (c) 2020 Carlos J. Santisteban
; last modified 20201226-1653

	.text

; *** addresses configuation ***
orig	= $0400				; most firmware savvy

alt		= $5FC0				; needs 32 kiB RAM! change and use another address line if needed (A14...A6)

; ****************
; *** ROM code ***
; ****************
	*	= $FF00				; last 256-byte is more than enough

reset:
; ****************************************************
; *** copy the whole SMC into RAM, then jump to it ***
; ****************************************************
	LDX #end-start-1		; number of bytes
c_loop:
		LDA start, X		; get original
		STA orig, X			; put copy
		DEX
		BPL c_loop
; *** modify absolute addresses accordingly ***
	JMP orig				; run in RAM!

; *****************************************
; *** code that will be copied into RAM ***
; *****************************************
start:
; *** copy delay loop in alternate location *** CHECK
	LDX #end-d_st-1			; bytes to copy
copy:
		LDA d_st, X			; get source (could read from ROM!)
		STA alt, X			; put on alternate location
		DEX
		BPL copy			; until all code is copied
; *** modify alternate copy for return to original ***
	LDX #>orig+d_st-start	; pick original return address (corrected)
	LDY #<orig+d_st-start
	STX alt+cont+2-d_st		; set on alternate copy (seems OK, as alt is abosulte and the other references are relative)
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
			JMP lock		; lock here (this is OK in ROM)
cont:
	JMP alt					; execute alternate copy *** this will change on copy ***
end:

; *******************
; *** ROM padding ***
; *******************

	.dsb	$FFFA-*, $FF

; *** hardware vectors ***

	.word	lock
	.word	reset			; interrupts will lock
	.word	lock
