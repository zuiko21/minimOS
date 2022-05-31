; NES-type controller reader for Durango-X (and possibly other)
; (c) 2022 Carlos J. Santisteban
; last modified 20220601-0005

; ***************************************************
; *** original version, simple but wrong hardware *** '139, '08 & '125
; ***************************************************

; *** I/O addresses ***
	IO9clk	= $DF9C			; Write D0=clk, D1=stb to BOTH controllers ($DF9D does the same)
	IO9nes0	= $DF9C			; Read D7=data in
	IO9nes1	= $DF9D			; Read D7=data in

; *** zeropage (or elsewhere) variables ***
	nesdat0	= io_c			; standard I/O at $F4
	nesdat1	= io_c+1

; *** read routine, probably interrupt-based *** 35b, 325t (212µs or ~3.3 lines) and takes two ZP bytes
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

; *******************************************
; *** corrected version, simpler hardware *** '138, '174 & '245
; *******************************************

; *** I/O addresses ***
	IO9nclk	= $DF9C			; Write D0=clk, D1=stb to BOTH controllers
	IO9ndat	= $DF9D			; Read D7=data from controller 0, D6=data from controller 1

; *** zeropage (or elsewhere) variables ***
	nesdat0	= io_c			; standard I/O at $F4
	nesdat1	= io_c+1

; *** read routine, probably interrupt-based *** 32b, 293t (191µs or 3 lines), same two ZP bytes
NESread:
	LDA #2					; strobe pulse (2)
	STA IO9nclk				; send STROBE (4)
	LDX #0					; D0 will be clock signal 0<->1 (2)
	LDY #8					; bit counter (2)
	STX IO9nclk				; end of strobe, still very short (8 vs ~18t) (4)
nc_loop:
		LDA IO9ndat			; get controller MSB (can't do void writes!) (4)
		ASL					; shift MSB into C (2)
		ROL nesdat0			; inject C bit into zeropage, don't care initial value (5)
;		LDA IO9ndat			; second controller goes into next bit
		ASL					; now C is pad1 data, inject into its variable (2+5)
		ROL nesdat1
		INX					; X.D0 goes 1... (2)
		STX IO9nclk			; pulse on CLK (4)
		DEX					; (2)
		DEY					; I think it's best to do this now, as STX won't affect flags and makes pulse closer to original length (2)
		STX IO9nclk			; ...and return to 0 (4)
		BNE nc_loop			; repeat 8 times (3, total 35t per bit, about half speed)
; *** nesdatX holds D7=A, D6=B, D5=Select, D4=Start, D3=Up, D2=Down, D1=Left, D0=Right ***

; *********************************************
; *** alternative version, complex hardware *** '138, 2x '595 & a couple of inverters
; *********************************************

; *** I/O addresses ***
	IO9nlat	= $DF9C			; any Write sends STROBE to BOTH controllers
	IO9nclk	= $DF9D			; any Write sends CLOCK to BOTH controllers
	IO9nd0	= $DF9C			; Read WHOLE data from controller 0
	IO9nd1	= $DF9D			; Read WHOLE data from controller 1

; *** NO zeropage usage! *** 11b, 77t (50µs or ~0.78 lines)
NESread:
	STA IO9nlat				; irrelevant value, latch data (4)
	LDX #8					; number of bits (2)
ns_loop:
		STX IO9nclk			; irrelevant value, clock pulse (4)
		DEX
		BNE ns_loop			; until all bits shifted (2+3, total loop is 71t)
; *** IO9nd0 and IO9nd1 now read values in nesdatX format until new latch pulse! ***
