; test of Durango-X video output (colour mode)
; (c) 2021 Carlos J. Santisteban 

* = $6000					; VRAM start

	BRA $6000				; must lock here as will be exectuted!

; binary data from file, offset 2 as it's a raw binary
	.bin	*-$6000, 8190, "../../other/data/cra.sv"
