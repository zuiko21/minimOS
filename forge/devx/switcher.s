; split-screen resolution switcher for devX development suite
; (c) 2022 Carlos J. Santisteban
; last modified 20220620-1549


; *** I/O addresses ***
	IO8attr	= $DF80			; resolution settings as always (D7=HIRES, D6=INVERT, D5-4=SCREEN, D3=RGB)
	IO8sync = $DF88			; blanking signals (D7=LINE, D6=FRAME)

; *** parameters needed ***
;	oldat	= address of original gameplay screen mode (usually stores $38)
	newat	= $B0			; debugger screen mode
	raster	= 127			; number of rasters displayed in original mode... minus one?

; routine for switching resolution on the top half of the screen
switch:
		BIT IO8sync			; check current position
		BVC switch			; frame has not ended yet, so busy wait :-(
; we're in vertical blanking here (perhaps was called during blank)
	LDA oldat				; set original mode, usually colour mode ($38)
	STA IO8attr
wait:
		BIT IO8sync			; wait until the end of vertical blank in order to count lines
		BVS wait
; a new frame is about to be displayed, thus count 128 raster lines (half the screen height)
; *** not sure if the BMI/BPL sequence below does lose one raster, but will switch faster
	LDX #raster				; number of lines to be displayed in original mode***
blank:
			BIT IO8sync		; wait for the end of H-blanking, if still on it
			BMI blank
line:
			BIT IO8sync		; wait until the end of this line
			BPL line
		DEX					; one less line to go
		BNE blank
; switch ASAP to HIRES for the debugger
	LDA #newat				; set debugger screen mode
	STA IO8attr				; hope to return on time (<11.7 ms)
	RTS
