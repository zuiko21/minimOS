; *** alternate netboot Lboot module for minimOS ***
; (c) 2015-2020 Carlos J. Santisteban Salinas
; last modified 20150304-0945
; revised 20160115 for commit *** perhaps obsolete ***

	LDX #>nb_lboot		; Lboot string MSB (2)
	LDY #<nb_lboot		; Lboot string LSB (2)
	JSR nb_sout			; send login ID string (6...)
	LDX #>nb_buf		; buffer MSB (2)
	LDY #<nb_buf		; buffer LSB (2)
	JSR nb_sin			; get size (and pos) hex string (6...)
	LDA nb_buf			; get first char in buffer (3)
	CMP #'$'			; is it 16-bit size? (2)
		BEQ nb_16s			; supported size (3/2)
	CMP #'@'			; has start address? (0/2)
		BEQ nb_16a			; supported format (0/3/2)
		JMP nb_end			; 32-bit not supported yet, or wrong answer (3)
nb_16a:
	LDX #5				; point to hex address (2)
	JSR nb_h2b			; convert to binary (16-bit) (6...)
	LDA nb_conv			; get address LSB (3)
	STA nb_ptr			; store pointer (3)
	LDA nb_conv+1		; same for MSB (3+3)
	STA nb_ptr+1
	_BRA nb_size		; get size and go for it (3)
nb_16s:
	LDA #<sysvars		; free RAM start LSB (2)
	STA nb_ptr			; store in pointer (3)
	LDA #>sysvars		; same for MSB (2+3)
	STA nb_ptr+1
	LDX #1				; set index from start (2)
nb_size:
	JSR nb_h2b			; convert size into nb_conv (6...)
; get things ready to load ~/boot
; ...
	LDA #'A'		; send acknowledge
	JSR nb_out
nb_bloop:
; *********modified loop....

; @ does +29 instead of +28 clocks
; $ does +18 instead of +21 clocks
; saves 3 bytes anyway
