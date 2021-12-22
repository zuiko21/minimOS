; HAM-like interlaced colour palette for Durango-X
; (c) 2021 Carlos J. Santisteban
; last modified 20211222-2347

	* = $400				; standard download

; zeropage
	ptr		= 3

; *** code ***
	SEI						; usual 6502 stuff
	CLD
	LDX #$FF
	TXS
; Durango stuff
	LDA #%00101000			; screen 2 at first, colour mode
	STA $DF80				; set video mode
; init pointer
	LDA #$40				; screen 2
	LDY #0					; will reset index too
	STA ptr+1
	STY ptr

; vertical stripes, 4 bytes of each
vpage:
	LDA #0					; black from the left
vline:
				LDX #4		; bytes of each colour
four:
					STA (ptr), Y
					INY
					DEX
					BNE four
				CLC
				ADC #$11	; next colour
				BCC vline
	cont:
			TYA				; A may be discarded as must be reset here
			BNE vpage
		INC ptr+1			; next page
		LDA ptr+1			; must check
		CMP #$60			; until end of screen 2
		BCC vpage

; *** just for fun, switch to screen 3 to see how it draws ***
	LDA #%00111000
	STA $DF80

; horizontal stripes, ptr already set
hpage:
	TXA						; A is now black (or saved colour)
hloop:
			STA (ptr), Y
			INY
			BNE hloop
		INC ptr+1			; next page
		TAX					; must keep current colour
		LDA ptr+1			; current page
		LSR					; half it! check d0
		BCS hpage			; going even to odd, same colour
			TXA				; otherwise retrieve colour...
			ADC #$11		; ...and advance to next (C was clear)
			TAX
		BCC hpage			; note it will stop upon C

; all drawn, now switch screens rapidly!
flickr:
			BIT $DF88		; check blanking
			BVS flickr		; if we still are in VBL
wait:
			BIT $DF88
			BVC wait		; wait for next VBL
		LDA $DF80			; actual flags
		EOR #%00010000		; toggle between screens 2 & 3
		ORA #$10			; allow colour, just in case
		STA $DF80			; switch screen
		BNE flickr			; forever as per ORA
