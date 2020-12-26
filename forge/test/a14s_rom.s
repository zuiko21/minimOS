; sound test (speaker on *A13*)
; *** ROMmable version ***
; (c) 2020 Carlos J. Santisteban
; last modified 20201226-1607

	.text

; *** addresses configuation ***
	*	= $C000				; 27C128 savvy

alt		= $FFC0				; needs 16 kiB ROM! change and use another address line if needed (A13...A6)

; since * is %1100000000000000
; and alt is $1111111111000000
; A13 to A6 will do

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
			JMP lock		; lock here
cont:
	JMP alt					; execute alternate copy *** this will change on copy ***

; ****************************************************************
	.dsb	alt-*, $FF		; *** padding until alternate copy ***
; ****************************************************************

		TYA
		TAX					; set initial X
a_loop:
			DEX
			BNE a_loop		; initial delay, depending on initial X
a_last:
			DEX
			BNE a_last		; last, fixed delay (as X is 0)
		DEY					; now a bit higher freq
		BNE back
lock2:
			JMP lock2		; lock here
back:
	JMP d_st				; return to original

; *************************************************************
	.dsb	$FFFA-*, $FF	; *** ROM padding until vectors ***
; *************************************************************

	.word	lock
	.word	init			; interrupts will lock at different addresses
	.word	lock2
