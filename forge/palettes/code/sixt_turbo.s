; SIXtation TURBO splash screen
; (c) 2020-2022 Carlos J. Santisteban
; last modified 20200411-1733

; must horizontally scroll a 1152x32 image, 32px (2 words) per frame!
; ...or perhaps just 1024?
; from the 1152x896 screen, this is located at y=864...879 (rows 53 & 54)
; ...for 1360x768, that would be y=736...751 (rows 45 & 46)
; base offset is $1DD0 for the first half and $1E60 for the second
; ...make that $1DF7 and $1EA1 for CENTERED 1K non-TURBO, or somewhat more?
; ...rightmost 1024px on 1152 screen adds $10 ($1DE0 and $1E70)
; ...within 1360 that is $1E07 and $1EB1
; increase address by $2000 each of the 16 scanlines
; example for top half:
; $1DD0,3DD0,5DD0,7DD0,9DD0,BDD0,DDD0,FDD0,11DD0,13DD0,15DD0,17DD0,19DD0,1BDD0,1DDD0,1FDD0
; ...note new offsets above
; by using 16-bit indexes seems worth doing 4 stores, waiving bank changes (abs.long)
; original image might be stored similarly, but puting scanlines separated by $200 instead
; whereas both halves start at 0 and $90, respectively, thus each scanline takes:
; $0-8F,200,400,600,800,A00,C00,E00,1000,1200,1400,1600,1800,1A00,1C00,1E00-1E8F
; $90-11F,290-31F...1E90-1F1F for a 7968 total bytes (instead of the minimum 4608)
; ...but since the image is being scrolled into the screen, is this waste necessary?

; ********************************************
; *** original version, full 1152px scroll ***
; ********************************************
	SEP #$10:REP #$20	; 16-bit memory, 8-bit indexes
	.al:.xs
; indexes may be 16-bit if X handling is so improved
	LDX #32			; scrolls counter?
; zeropage pointers setting
	LDA #$1DD0		; set two 24-bit pointers at s_ptu and s_ptl
	STA s_ptu
	LDA #$60B0		; $B0 means multiplane
	STA s_ptu+2
	LDA #$B01E
	STA s_ptl+1
	LDA #$1DD4		; ditto 4 bytes ahead at s_du and s_dl!
	STA s_du
	LDA #$64A0		; $A0 means plane 0
	STA s_du+2
	LDA #$A01E
	STA s_dl+1
	LDA #s_pic		; bitmap address
	STA s_im		; bankless pointer
	PHK
	PLB				; switch to current bank
; begin stuff
	CLC				; will do some adds with no carry
sl_scan:
		LDY #0				; reset index
sl_loop:
			LDA [s_du], Y		; scroll upper section
			STA [s_ptu], Y
			LDA [s_dl], Y		; scroll lower section
			STA [s_ptl], Y
			INY				; next word
			INY
			CPY #140		; whole 1152px done?
			BNE sl_loop
; must print here the new two words for those two scanlines ** TO DO
; go for next scanline
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
		CMP #$1200		; end of image file?
		BNE sl_scan
	RTL
