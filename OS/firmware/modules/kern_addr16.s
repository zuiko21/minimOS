; firmware module for minimOS·16
; (c) 2018 Carlos J. Santisteban
; last modified 20180511-1050

; *** preset kernel start address ***
; expects kernel label, possibly from ROM file
; 65816 only, MUST enter in 16-bit memory!
.al:
	LDA #kernel			; get address (3)
	STA fw_warm			; store in sysvars (5)
