; minimOS 0.5 load_link function ***stub***
; (c) 2015-2020 Carlos J. Santisteban
; last modified 20150107-1005

; originally written on 20141107
; gets path string on zpar (aka z2)
; returns address on zpar2 (aka z6)
; sys_vol points to the first record on a SAm format mounted volume!
; can't include volume name in path, this far (assume relative naming)

	LDA sys_vol	; get LSB (not worth doing a loop, 20150107) 
	STA zpar2, X	; copy into parameter area
	LDA sys_vol+1	; get MSB
	STA zpar2+1, X	; copy into parameter area
kx_check
	LDY #4		; offset to name string on filesystem
	JSR kx_comp	; check names
	BCC kx_go	; ?
	LDY #$FF	; increase ponter MSB?
	LDA (zpar2), Y
	BNE kn_no	; end of volume?
	DEY
	LDA (zpar2), Y
	CLC
	ADC zpar2+1	; next record
	BRA kx_check
kx_go
	LDY #1		; offset for filetype
	LDA (zpar2), Y	; get for that record
	CMP #'m'	; check whether executable
	BNE kx_err
	INX		; offset for CPU-type
	LDA (zpar2), Y	; get again
	CMP #'B'	; check whether 65C02 (might check other types too)
	BNE kx_incomp	; wrong CPU
kx_go
	CLC		; otherwise, all OK
	RTS
kx_err
kx_incomp		; anyway
	LDY #not_found	; not executable
	SEC
	RTS


kx_comp
	LDX #0		; ?
kx_name
		LDA (zpar2), Y	; get name on file record
		BEQ kx_eot	; end of string
		CMP zpar, X	; compare with supplied path *** WRONG, probably CMP (zpar, Y)
		BNE kx_dif	; difference found
		INX		; next character ***WRONG
		INY
		BRA kx_name
kx_eot
	LDA (zpar), Y	; ...and not absolute indexed with X
	BNE kx_dif	; not longer
	CLC		; filenames coincide
	RTS
kx_dif
	SEC		; difference found
	RTS

