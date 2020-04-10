; SIXtation TURBO splash screen
; (c) 2020 Carlos J. Santisteban
; last modified 20200410-2351

; must horizontally scroll a 1152x32 image, 32px (2 words) per frame!
; from the 1152x896 picture, this is located at y=864...879 (rows 53 & 54)
; base offset is $1DD0 for the first half and $1E60 for the second
; increase address by $2000 each of the 16 scanlines
; example for top half:
; $1DD0,3DD0,5DD0,7DD0,9DD0,BDD0,DDD0,FDD0,11DD0,13DD0,15DD0,17DD0,19DD0,1BDD0,1DDD0,1FDD0
; by using 16-bit indexes seems worth doing 4 stores, waiving bank changes (abs.long)
; original image might be stored similarly, but puting scanlines separated by $200 instead
; whereas both halves start at 0 and $90, respectively, thus each scanline takes:
; $0-8F,200,400,600,800,A00,C00,E00,1000,1200,1400,1600,1800,1A00,1C00,1E00-1E8F
; $90-11F,290-31F...1E90-1F1F for a 7968 total bytes (instead of the minimum 4608)
; ...but since the image is being scrolled into the screen, is this waste necessary?

	SEP #$10:REP #$20	; 16-bit memory, 8-bit indexes
	.al:.xs
; indexes may be 16-bit if X handling is so improved
;	LDX #32			; scrolls counter?

	LDA #$1DD0		; set two 24-bit pointers at s_ptu and s_ptl
	STA s_ptu
	LDA #$60A0
	STA s_ptu+2
	LDA #$B01E
	STA s_ptl+1
	LDA #$1DD4		; ditto 4 bytes ahead at s_du and s_dl!
	STA s_du
	LDA #$64A0
	STA s_du+2
	LDA #$B01E
	STA s_dl+1
	CLC
sl_scan:
		LDY #0
sl_loop:
			LDA [s_du], Y		; scroll upper section
			STA [s_ptu], Y
			LDA [s_dl], Y		; scroll lower section
			STA [s_ptl], Y
			INY
			INY
			CPY #140
			BNE sl_loop
; must print here the new two words for those two scanlines ** TO DO
		LDA s_ptu+1		; advance 8K
		ADC #$20
		STA s_ptu+1
		LDA s_ptl+1		; advance 8K
		ADC #$20
		STA s_ptl+1
		LDA s_du+1		; advance 8K, not same as ptu/ptl because those write to multiplane area, which cannot be read
		ADC #$20
		STA s_du+1
		LDA s_dl+1		; advance 8K
		ADC #$20
		STA s_dl+1
; the image source pointer will increase much less, perhaps $120 for no waste at all!
		LDA s_im
		ADC #$120
		STA s_im
		CMP #$2200		; end of image file?
		BNE sl_scan
	RTL
