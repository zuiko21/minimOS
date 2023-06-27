; Skeumorphic pause for Durango-X
; (c) 2023 Carlos J. Santisteban
; last modified 20230627-1109

; *** zeropage definitions ***
sptr	= 
base	= sptr + 2
total	= base + 2		; from this point on, no need for zeropage

ROM_BASE	= $E000		; ransomish ROM contents start address
RASTER_CNT	= 112		; noise band start raster
BAND_ADR	= $6E00		; noise band start address

; ************************************************************************************************************************
; *** code itself, main program must check START button and, if pressed, JSR pause and then somehow restore the screen ***
; ************************************************************************************************************************
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
;	LDY #0					; fixed LSB
	LDA #>BAND_ADR			; pointer for randomish content
	STY sptr
	STA sptr+1
; first wait for VBLANK
vb_in:
		BIT IO8blnk
  		BVC vb_in		; wait until within VBLANK
vb_out:
		BIT IO8blnk
  		BVS vb_out		; wait until the end of VBLANK
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


exit:
; pause is over, wait until START is released again... but screen must be restored?
		LDA gamepad0	; assume these are ready and masked by the ISR
		ORA gamepad1
 		AND #START		; check button
		BNE exit
  RTS
	
