; test of Durango-X video output (hires mode)
; (c) 2021-2022 Carlos J. Santisteban 

* = $6000					; VRAM start

	LDA #$F8				; set hires, inverted mode! should ignore RGB enable
	STA $DF80				; new FLAGS port
lock:
	BNE lock				; must lock here as will be exectuted!

off = * - $6000
; binary data from file, offset 11+2 as it's a PBM
	.bin	11+off, 8185, "../../other/data/cra-hires.pbm"

	.byt	$F0				; mode switching for the old FLAGS address ($8000)
