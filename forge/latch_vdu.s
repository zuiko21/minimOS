; stub for VDU access via VIA latched interface
; 32K 4-bit version
; (c)2017-2019 Carlos J. Santisteban
; last modified 20170415

; *** direct access 6502 version *** ~0.82s @ 1 MHz
clear_screen:
	LDX #>SCREEN_BASE	; likely to be $4000-$BFFF?
	LDY #<SCREEN_BASE	; should be zero...
	LDA #LATCH_H		; first issued command
	STA VIA1+IORB		; select it for first op
	LDA #color		; standard value (two nibbles) or STZ
cs_wrap:
	STX VIA1+IORA		; set new page
	INC VIA1+IORB		; latch MSB, continue with LATCH_L
cs_loop:
		STY VIA1+IORA		; LSB to be latched
		INC VIA1+IORB		; command LATCH_L > WRITE
		STA VIA1+IORA		; color to be written, or STZ
		DEC VIA1+IORB		; command WRITE > LATCH_L
		INY				; next
		BNE cs_loop		; ~25×256t (each page +23)
	DEC VIA1+IORB		; relatch L, now LATCH_H
	INX				; next page
	CPX #>SCREEN_TOP	; likely $C0
		BNE cs_wrap		; until all done (could be cs_loop if STZ)
	RTS

; *** 256-byte window version ***
clear_screen:
	LDY #<WINDOW_BASE	; LSB should be zero
	LDX #>SCREEN_BASE	; preset page counter
cs_wrap:
; select page from X
	LDA #LATCH_H		; first issued command
	STA VIA1+IORB		; select it for first op
	LDA #>VDU_BASE+PGSEL	; MSB of paging register
	STA VIA1+IORA		; set pointer page
	INC VIA1+IORB		; latch MSB, continue with LATCH_L
	LDA #<VDU_BASE+PGSEL	; same with LSB
	STA VIA1+IORA		; set pointer offet
	INC VIA1+IORB		; command LATCH_L > WRITE
	STX VIA1+IORA		; set current page
	DEC VIA1+IORA		; latch and back...
	DEC VIA1+IORA		; ...to initial command
; select window
	LDA #>WINDOW_BASE	; likely $7F00
	STA VIA1+IORA		; set window page
	INC VIA1+IORB		; latch MSB, continue with LATCH_L
; fill page
	LDA #color ; standard value (two nibbles) or STZ
cs_loop:
		STY VIA1+IORA		; LSB to be latched
		INC VIA1+IORB		; command LATCH_L > WRITE
		STA VIA1+IORA		; color to be written, or STZ
		DEC VIA1+IORB		; command WRITE > LATCH_L
		INY				; next
		BNE cs_loop		; ~25×256t
	INX page			; next page
	CPX #>SCREEN_TOP	; likely $C0
		BNE cs_wrap
	RTS
