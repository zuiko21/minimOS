; RLE decoder for minimOS
; (c) 2021 Carlos J. Santisteban
; last modified 20211031-1931

; *** zeropage variables ***
.zero

*	= 3

src		.word	0			; pointer to compressed source
ptr		.word	0			; pointer to screen output

.text

* = $4000					; room enough

; *** parameter definitions ***
dest	= $6000				; Durango-X screen address

; *** actual code ***
; preload pointers as required
	LDA #>source			; compressed data origin
	LDY #<source
	STY src
	STA src+1
	LDA #>dest				; destination address
	LDY #<dest				; may assume page-aligned?
	STY ptr
	STA ptr+1
rle_loop:
		LDY #0				; always needed as part of the loop
		LDA (src), Y		; get command
		INC src				; advance read pointer
		BNE rle_0
			INC src+1
rle_0:
		TAX					; command is just a counter
			BMI rle_u		; negative count means uncompressed string
; * compressed string decoding ahead *
		BEQ rle_exit		; 0 repetitions means end of 'file'
; multiply next byte according to count
		LDA (src), Y		; read immediate value to be repeated
rc_loop:
			STA (ptr), Y	; store one copy
			INY				; next copy, will never wrap as <= 127
			DEX				; one less to go
			BNE rc_loop
; burst generated, must advance to next command!
		INC src
		BNE rle_next		; usually will skip to common code
			INC src+1
			BNE rle_next	; no need for BRA
; alternate code, more compact but a bit slower
;		LDA #1
;		BNE rle_adv			; just advance source by 1 byte
; * uncompressed string decoding ahead *
rle_u:
			LDA (src), Y	; read immediate value to be sent, just once
			STA (ptr), Y	; store it just once
			INY				; next byte in chunk, will never wrap as <= 127
			INX				; one less to go
			BNE rle_u
		TYA					; how many were read?
rle_adv:
		CLC
		ADC src				; advance source pointer accordingly (will do the same with destination)
		STA src
		BCC rle_next		; check possible carry
			INC src+1
; * common code for destination advence, either from compressed or un compressed
rle_next:
		TYA					; once again, these were the transferred/repeated bytes
		CLC
		ADC ptr				; advance desetination pointer accordingly
		STA ptr
		BCC rle_loop		; check possible carry
			INC ptr+1
		BNE rle_loop		; no need for BRA
; *** end of code ***
rle_exit:

; ** test code ahead **
	BRA rle_exit			; just hang after decoding!
; ** compressed 'file' ahead **
source:
	.bin	0, 2908, "../rle/source.rle"
