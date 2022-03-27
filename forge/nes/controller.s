; NES-type controller reader for Durango-X (and possibly other)
; (c) 2022 Carlos J. Santisteban
; last modified 20220327-2329

.(
; *** I/O addresses ***
	IO9clk	= $DF9C			; Write D0=clk, D1=stb to BOTH controllers ($DF9D does the same)
	IO9nes0	= $DF9C			; Read D7=data in
	IO9nes1	= $DF9D			; Read D7=data in

; *** zeropage (or elsewhere) variables ***
	nesdat0	= io_c			; standard I/O at $F4
	nesdat1	= io_c+1

; *** read routine, probably interrupt-based ***
NESread:
	LDA #2					; strobe pulse (2)
	STA IO9clk				; send STROBE (4)
	LDX #0					; D0 will be clock signal 0<->1 (2)
	LDY #8					; bit counter (2)
	STX IO9clk				; end of strobe, still very short (8 vs ~18t) (4)
nc_loop:
		LDA IO9nes0			; get controller MSB (can't do void writes!) (4)
		ASL					; shift MSB into C (2)
		ROL nesdat0			; inject C bit into zeropage, don't care initial value (5)
		LDA IO9nes1			; same for second controller (4+2+5)
		ASL
		ROL nesdat1
		INX					; X.D0 goes 1... (2)
		STX IO9clk			; pulse on CLK (4)
		DEX					; (2)
		DEY					; I think it's best to do this now, as STW won't affect flags and makes pulse closer to original length (2)
		STX IO9clk			; ...and return to 0 (4)
		BNE nc_loop			; repeat 8 times (3, total 39t per bit, about half speed)
; *** nesdatX holds D7=A, D6=B, D5=Select, D4=Start, D3=Up, D2=Down, D1=Left, D0=Right ***
