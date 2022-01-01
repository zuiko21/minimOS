; firmware module for minimOS·65
; (c) 2017-2022 Carlos J. Santisteban
; last modified 20171225-2134

; *** preset kernel start address ***
; expects kernel label, possibly from ROM file
; NMOS and 65816 savvy

	LDY #<kernel	; get LSB, nicer (2)
	LDA #>kernel	; same for MSB (2)
	STY fw_warm		; store in sysvars (4+4)
	STA fw_warm+1
