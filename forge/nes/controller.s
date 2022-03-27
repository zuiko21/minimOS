; NES-type controller reader for Durango-X (and possibly other)
; (c) 2022 Carlos J. Santisteban
; last modified 20220327-1923

.(
; *** I/O addresses ***
	IO9clk	= $DF9C			; D0=clk, D1=stb
	IO9dat	= $DF9D			; D7=data in
; might use another pair for second controller, like $8/9
; could use Y-indexing for two (or mode) pads

; *** read routine, probably interrupt-based ***
NESread:
	LDX #16					; D0 will be clock signal 0<->1 (2)
	LDA #2					; strobe pulse (2)
	STA IO9clk				; send STROBE (4)
	LDA #0					; clear accumulator (2)
nc_loop:
		ASL IO9dat			; shift data in (void write afterwards) (6)
		ROL					; inject C bit into accumulator (2)
		DEX					; X.D0 goes 1... (2)
		STX IO9clk			; pulse on (4)
		DEX					; (2)
		STX IO9clk			; ...and 0 (4)
		BNE nc_loop			; repeat 8 times (3, total 23t per bit, slightly slower)
; *** A holds D7=A, D6=B, D5=Select, D4=Start, D3=Up, D2=Down, D1=Left, D0=Right ***
