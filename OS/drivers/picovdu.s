; 2 kiB pico-VDU (direct bus version)
; v0.1a1
; (c) 2021 Carlos J. Santisteban
; last modified 20210125-1435

; *** stub with TONS of things to do ***

pv_pch:
; ** print char **
	_STZA pv_2c				; clear this flag
	_STZA io_c+1			; clear MSB
; compute glyph pointer
	LDA io_c				; get ASCII
	LSR						; two chars per byte!
	ROR pv_2c				; store C into high bit of flag
	ASL
	ASL						; takes 8 scanlines per COUPLE of chars
	ROL io_c+1
	ASL
	ROL io_c+1
	ASL
	ROL io_c+1
	CLC
	ADC font				; add font base (could be immediate)
	STA pv_fpt				; create read pointer
	LDA io_c+1				; ditto for MSB
	ADC font+1
	STA pv_fpt
; compute screen pointer
	_STZA pv_spt			; clear LSB!
	LDA pv_y				; get row (0...15)
	LSR						; 8 scanlines per row, but 16 bytes per scanline, shift one byte left and one bit right
	ROR pv_spt				; may create carry
; following code is valid for the $7800 fixed (and especially page-aligned) start address
;	CLC						; already clear thanks to ROR above!
	ADC #$78				; screen base address MSB
	STA pv_spt+1			; MSB is ready, but...
	LDA pv_x				; column (0...31)
	LSR						; two columns per byte
	ORA pv_spt				; LSB is only 0 or 128! D6-D4 will change each scanline!
	STA pv_spt				; ready
; put glyph data on screen

