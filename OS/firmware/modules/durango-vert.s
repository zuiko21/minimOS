; Durango-X vertical line routine
; (c) 2022 Carlos J. Santisteban
; last modified 20220921-0958

; *** INPUT ***
; px_col.b	= colour in II format (17*index, HIRES reads d7 only)
; X		= x coordinate (fixed)
; Y		= initial (top) Y coordinate
; y_cnt	= number of vertical pixels (line height)

v_line:
.(
	_STZA cio_pt			; clear LSB
	TYA						; get Y coordinate... (2)
	LSR
	ROR cio_pt
	LSR
	ROR cio_pt				; divide by 4 instead of times 64, already OK for colour (2+5+2+5)
	BIT IO8attr				; check screen mode (4)
	BPL col_vl				; * HIRES V line below * (3/2 for COLOUR/HIRES)

col_vl:
	STA cio_pt+1			; LSB ready, temporary MSB (3)
	LDA IO8attr				; get flags... (4)
	AND #$30				; ...for the selected screen... (2)
	ASL						; ...and shift them to final position (2)
	ORA cio_pt+1			; add to MSB (3+3)
	STA cio_pt+1
	TXA						; get X coordinate (2)
	LSR						; in half (C is set for odd pixels) (2)
	TAY						; this is actual indexing offset (2)
	LDA #$F0				; active mask for even pixel (2)
	LDX #$0F				; and bits to be preserved
	BCC evpix
		TXA					; otherwise is odd (3/2+2+2 for even/odd)
		LDX #$F0
evpix:
	AND px_col				; compute desired colour pattern
	STA tmp_col				; store as mask
v_loop:
		TXA						; get preservation mask
		AND (cio_pt), Y			; extract relevant bits
		ORA tmp_col				; and add constant new ones!
		STA (cio_pt), Y
		; add 64 to cio_pt
		DEC y_cnt			; one line less
		BNE v_loop
	RTS
	
