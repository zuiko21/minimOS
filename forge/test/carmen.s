; test of Durango-X video output (colour mode)
; (c) 2021 Carlos J. Santisteban 

* = $6000					; VRAM start

IO8lh	= $8000				; will change to $DF80

	LDA #$30				; colour, non-inverted, 24K
	STA IO8lh
	BRA $6000				; must lock here as will be exectuted!

; binary data from file, offset 7 as it's a raw binary
	.bin	*-$6000, 8185, "../../other/data/cra.sv"
