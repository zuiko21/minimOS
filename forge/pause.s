; Skeumorphic pause for Durango-X
; (c) 2023 Carlos J. Santisteban
; last modified 20230627-1315

; *** zeropage ***
ptr			= $FA		; will affect $FB only!

; *** other addresses ***
ROM_BASE	= $E000		; randomish ROM contents start address
RASTER_CNT	= 112		; noise band start raster
MAX_ITER	= 20		; average ~32 rasters

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
cycle:
	LDA #$E0			; randomish pointer MSB
	STA ptr+1
frame:
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
	LDY #MAX_ITER		; 20 toggles should take around 32 rasters, make it even and will restore initial status
; go for the streaks
streak:
		LDA IO8attr
  		EOR #%10000000	; toggle between HIRES and colour
		ORA #%00001000	; enable RGB, just in case
		STA IO8attr		; switch mode
		LDA (ptr), Y	; get randomish content
		LSR
		LSR				; max. 63, or 315t ~3.2 rasters
  		TAX				; for the counter
dropout:
			DEX
   			BPL dropout	; delay, 5*X t
		DEY
		BNE streak
	INC ptr+1			; some randomness
 	BNE frame
	BEQ cycle 
exit:
; pause is over, wait until START is released again
		LDA gamepad0	; assume these are ready and masked by the ISR
		ORA gamepad1
		AND #START		; check button
		BNE exit
	RTS
	
