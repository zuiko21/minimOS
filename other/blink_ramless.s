; ***   A5 blinking LED mini-test    ***
; *** ***   RAM-less version!    *** ***   
; *** (c) 2020 Carlos J. Santisteban ***
; *** last modified 20201204-2337    ***

		.text

; ****************************************
; *** delay loop, first issue (A5 low) ***
; ****************************************

		* = $FFC0			; whole code fits into the last 64-byte chunk

start:
		SEI					; just in case
		CLD
blink1:
			JSR ex_rts		; just some suitable delay
			INX
			BNE blink1
				INY
			BNE blink1
		JMP blink2			; that will turn A5 on! 14 bytes this chunk

; ********************************************
; *** filling until the next 32-byte chunk ***
; ********************************************

		blink2 = $FFE0

		.dsb	blink2-*, $FF

; ***********************************
; *** second delay loop (A5 high) ***
; ***********************************

		* = blink2			; A5 is now on

			JSR ex_rts		; just some suitable delay
			INX
			BNE blink2
				INY
			BNE blink2
		JMP blink1			; and turn A5 off again, this chunk is 14 bytes plus 6 for the vectors

; *************************
; *** auxiliary opcodes ***
; *************************

ex_rts:	RTS					; *** label for delay via JSR/RTS  ***
ex_rti:	RTI					; *** label for unexpected IRQ/BRK ***

; *************************************
; *** filling until the ROM vectors ***
; *************************************

		vectors = $FFFA

		.dsb	vectors-*, $FF

; *************************************
; *** *** 6502 hardware vectors *** ***
; *************************************

		* = vectors

		.word	start		; *** without monitor or any IO, will just acknowledge NMI as cycle restart ***
		.word	start		; *** only functionality of this device ***
		.word	ex_rti		; *** will ignore unexpected IRQs or BRKs ***
