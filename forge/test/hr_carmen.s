; test of Durango-X video output (hires mode)
; (c) 2021 Carlos J. Santisteban 

* = $6000					; VRAM start

	LDA #$C0				; set hires, inverted mode!
	STA $DF80				; new FLAGS port
lock:
	BRA lock				; must lock here as will be exectuted!

off = * - $6000
; binary data from file, offset 11+2 as it's a PBM
	.bin	11+off, 8190, "../../other/data/cra-hires.pbm"

	.byt	$C0				; mode switching for the old FLAGS address ($8000)
