; *** A15 blinking LED mini-test     ***
; *** (c) 2020 Carlos J. Santisteban ***
; *** last modified 20201204-1743    ***

		.bss

		* = $201			; not using zeropage, but avoid page-crossing penalty

; *** RAM data will hold a copy of the blinking routine ***
ram_blink:
		.dsb	10			; *** blinking routine should be copied here ***
ram_ret:
		.dsb	2			; *** actual ROM return address ***

; *******************************
; *** *** actual ROM code *** ***
; *******************************
		.text

		* = $FFC0			; at 37 bytes+vectors, the whole code fits easily into the last 64-byte chunk

start:
		SEI					; just in case
		CLD

; *** copy blinking routine in RAM ***
		LDX #ex_rts-rom_blink
loop:	LDA rom_blink-1,x
		STA ram_blink-1,x
		DEX
		BNE loop
; *** *** change jump address accordingly *** ***
		LDY #<rom_blink
		LDX #>rom_blink
		STY ram_ret
		STX ram_ret

; ***********************************************************
; *** blinking routine code will be copied after all data ***
rom_blink:
			JSR ex_rts		; just some suitable delay
			INX
			BNE rom_blink	; relative branches will generate the same binary
				INY
			BNE rom_blink	; relative branches will generate the same binary
		JMP ram_blink		; original jump, will be changed in RAM
; *** end of blinking routine *** needs 12 bytes! ***********
; ***********************************************************

ex_rts:	RTS					; *** label for delay via JSR/RTS   ***
ex_rti:	RTI					; *** label for unexpected IRQ/BRK  ***

; *********************************************
; *** *** filling until the ROM vectors *** ***
; *********************************************
		vectors = $FFFA

		.dsb	vectors-*, $FF

; *************************************
; *** *** 6502 hardware vectors *** ***
; *************************************
		* = vectors

		.word	start		; *** without monitor or any IO, will just acknowledge NMI as cycle restart ***
		.word	start		; *** only functionality of this device ***
		.word	ex_rti		; *** will ignore unexpected IRQs or BRKs ***
