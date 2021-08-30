; test of Durango-X video output (hires mode)
; (c) 2021 Carlos J. Santisteban 

* = $6000					; VRAM start

	BRA $6000				; must lock here as will be exectuted!

off = * - $6000
; binary data from file, offset 11+2 as it's a PBM
	.bin	11+off, 8190, "../../other/data/cra-hires.pbm"

	.byt	$80				; set hires, non-inverted mode!
