; Skeumorphic pause for Durango-X
; (c) 2023 Carlos J. Santisteban
; last modified 20230627-1220

; *** zeropage definitions ***
total		= 			; from this point on, no need for zeropage

ROM_BASE	= $E000		; randomish ROM contents start address
RASTER_CNT	= 112		; noise band start raster
MAX_ITER	= $500		; average ~32 rasters

; *******************
; *** code itself ***
; *******************
pause:
; should wait for START button release
		LDA gamepad0	; assume these are ready and masked by the ISR
		ORA gamepad1
		AND #START		; check button
		BNE pause
; *** now generate the noise band until START is pressed again ***
; init some stuff
	LDY #0					; fixed LSB
	LDA #>ROM_BASE			; pointer for randomish content
	STY base
	STA base+1
frame:
	LDY #0					; fixed LSB
	STY total				; no need for STZ
	STY total+1
; first wait for VBLANK
vb_in:
		BIT IO8blnk
		BVC vb_in		; wait until within VBLANK
vb_out:
		BIT IO8blnk
		BVS vb_out		; wait until the end of VBLANK
; now wait until desired raster
	LDY #RASTER_CNT		; raster counter
hb_in:
		BIT IO8blnk
		BPL hb_in		; wait until next HBLANK
hb_out:
		BIT IO8blnk
		BMI hb_in		; wait until the end of HBLANK
		DEY
		BNE vb_in		; exit upon reaching the desired raster
; go for the streaks
streak:
		LDA IO8attr
  		EOR #%10000000	; toggle between HIRES and colour
		ORA #%00001000	; enable RGB, just in case
		STA IO8attr		; switch mode
		LDA (base), Y	; get randomish content
		INY
		LSR
		LSR				; max. 63, or 315t ~3.2 rasters
  		TAX				; for the counter
dropout:
			DEX
   			BPL dropout	; delay, 5*X t
		ADC total
		STA total
		LDA total+1
		ADC #0			; propagate carry
		CMP #5
  		BCC streak

	JMP frame
exit:
; pause is over, wait until START is released again
		LDA gamepad0	; assume these are ready and masked by the ISR
		ORA gamepad1
		AND #START		; check button
		BNE exit
	RTS
	
