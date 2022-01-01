; RLE decoder DEMO for minimOS
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20211031-1931

; *** zeropage variables ***
.zero

*	= 3

src		.word	0			; pointer to compressed source
ptr		.word	0			; pointer to screen output

.text

* = $400					; room enough

; *** parameter definitions ***
dest	= $6000				; Durango-X screen address

; *** actual code ***
	LDA #$38
	STA $DF80				; set videoflags
; preload pointers as required
	LDA #>source			; compressed data origin
	LDY #<source
	STY src
	STA src+1
	LDA #>dest				; destination address
	LDY #<dest				; may assume page-aligned?
	STY ptr					; must be zero
	STA ptr+1
rle_loop:
rle_u:
			LDA (src), Y	; read immediate value to be sent, just once
			STA (ptr), Y	; store it just once
			INY				; next byte in chunk, will never wrap as <= 127
			BNE rle_u
				INC src+1
				INC ptr+1
			BPL rle_loop

; ** test code ahead **
rle_exit:
	BRA rle_exit			; just hang after decoding!
; ** UNcompressed 'file' ahead **
source:
	.bin	0, 8192, "../../other/data/maze4.sv"
