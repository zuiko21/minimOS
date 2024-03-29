; test code for picoVDU in DURANGO computer
; IO-channel 8 connection
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20210427-1723

	* = $400				; standard download address

; constants
	io_lh =	$8000
	io_ll =	$8001
	io_wr =	$8002			; *** new
	ltc_o =	$FFF0
; first block %01010101
	LDX #0
	STX ltc_o				; turn LED off
	STX io_lh
	LDY #0					; starting on first line
	LDA #%01010101
top:
		STY io_ll
		STA io_wr
#ifdef	SLOW
		JSR delay
#endif
		INY
		CPY #16				; until end of first line
		BNE top
lin:
; create lines %01010000...00000101, avoiding first pixel repetition
		TYA
		AND #15				; check lower offset
		BNE nz				; is it left?
			LDA #%01010000	; left pattern
			BNE do
nz:		CMP #15				; is it right?
		BNE ne
			LDA #%00000101	; right pattern
			BNE do
ne:		LDA #0				; otherwise clear
do:		STY io_ll
		STA io_wr
#ifdef	SLOW
		JSR delay
#endif
		INY
		BNE lin
	INX						; next page
	STX io_lh
	CPX #7					; near the end?
	BNE lin
; create lines %10100000...00000101, but last
lin2:
		TYA
		AND #15				; check lower offset
		BNE nz2				; is it left?
			LDA #%01010000	; left pattern
			BNE do2
nz2:	CMP #15				; is it right?
		BNE ne2
			LDA #%00000101	; right pattern
			BNE do2
ne2:	LDA #0				; otherwise clear
do2:	STY io_ll
		STA io_wr
#ifdef	SLOW
		JSR delay
#endif
		INY
		CPY #240			; all but last line
		BNE lin2
; draw last solid line
	LDA #%01010101			; same pattern
bot:
		STY io_ll
		STA io_wr
#ifdef	SLOW
		JSR delay
#endif
		INY
		BNE bot
; all done, show some feedback on LED
end:
	LDA #%11101001			; dot & slash (or the opposite)
	STA ltc_o
	JMP *					; lock here
delay:
	PHY
	INY
l_loop:
		PHX
		INX
d_loop:
		DEX
		BNE d_loop
		PLX
		DEY
		BNE l_loop
	PLY
	RTS
