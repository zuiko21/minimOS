; ***      A5 blinking LED mini-test      ***
; *** ***      RAM-less version!      *** ***
; *** (c) 2020-2021 Carlos J. Santisteban ***
; ***    last modified 20201204-2358      ***

		.text

; ****************************************
; *** delay loop, first issue (A5 low) ***
; ****************************************

		* = $FFC0			; whole code fits into the last 64-byte chunk

start:
		SEI					; really needed, as any interrupt will crash!
blink1:
			NOP				; cannot call subroutines! adjusted delay for ~1 sec @ 1 MHz
			NOP
			NOP
			NOP
			NOP
			INX
			BNE blink1
				INY
			BNE blink1
		JMP blink2			; that will turn A5 on! 15 bytes this chunk

; ********************************************
; *** filling until the next 32-byte chunk ***
; ********************************************

		blink2 = $FFE0

		.dsb	blink2-*, $FF

; ***********************************
; *** second delay loop (A5 high) ***
; ***********************************

		* = blink2			; A5 is now on

			NOP				; cannot call subroutines! adjusted delay for ~1 sec @ 1 MHz
			NOP
			NOP
			NOP
			NOP
			INX
			BNE blink2
				INY
			BNE blink2
		JMP blink1			; and turn A5 off again, this chunk is 17 bytes plus 6 for the vectors

; *************************
; *** auxiliary opcodes ***
; *************************

lock:	JMP lock			; *** unexpected interrupts will definitely crash when RAMless! ***

; *************************************
; *** filling until the ROM vectors ***
; *************************************

		vectors = $FFFA

		.dsb	vectors-*, $FF

; *************************************
; *** *** 6502 hardware vectors *** ***
; *************************************

		* = vectors

		.word	start		; *** NMI will work like RESET, hopefully no bus contention is done ***
		.word	start		; *** only functionality of this device ***
		.word	lock		; *** will crash upon unexpected IRQs or BRKs ***
