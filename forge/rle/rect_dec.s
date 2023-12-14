; RLE decoder for minimOS (arbitrary picture size)
; (c) 2021-2023 Carlos J. Santisteban
; last modified 20231214-1349

.(
; *** zeropage variables ***
*		= $80				; * placeholder

ptr		.word	0			; pointer to screen output (temp)
raster	.byt	0			; bytes per raster (temp)
src		.word	0			; pointer to compressed source (parameter)
dest	.word	0			; pointer to INITIAL screen output (parameter)
lines	.byt	0			; number of raster lines (parameter)

; *** hardware definitions ***
IO8attr	= $DF80				; Durango-X video mode
IOAen	= $DFA0				; interrupt control
screen	= $6810				; (32,32) coordinates

* = $800					; Pocket format ;-)
start:
; *** *************** ***
; *** standard header ***
; *** *************** ***
	.byt	0				; MAGIC #1
	.asc	"pX"			; Pocket executable
	.word	start			; load address
	.word	code			; execution address
	.byt	13				; MAGIC #2

	.asc	"Decompressor test", 0		; name
	.asc	"Arbitrary screen size", 0	; comment

	.dsb	start+$E6, $FF	; padding

	.asc	"$$$$$$$$"		; user2
	.asc	"$$$$$$$$"		; user1
	.word	$1041			; v1.0b1
	.word	0				; time (will be set by dxtouch)
	.word	0				; date (will be set by dxtouch)

	.word	end-start		; filesize

	.word	0				; MSB + MAGIC #3
; *** *************** ***

code:
; *** standard Durango init ***
	SEI						; just in case
	CLD
	LDA #$38				; colour mode
	STA IO8attr
	LDX #$FF
	TXS
	STX IOAen				; turn error LED off
; Pocket init
	LDY #<code
	LDA #>code
	STY $0202				; set NMI as warm reset
	STA $0203
; *** test code ***
; set parameters for testing
	LDA #64					; * * * replace as needed
	STA lines
	LDA #>source			; compressed data origin
	LDY #<source
	STY src
	STA src+1
; * preset bytes per raster according to video mode (or just set as expected) *
	LDA #64					; default is colour mode
	LDX IO8attr				; check video mode
	BPL col_ok				; already in colour mode
		LSR					; or turn into 32 for HIRES
col_ok:
; *******************
; *** actual code ***
; preload pointers as required
	LDA dest+1				; destination address
	LDY dest
raster_loop:
; *** *** decompress one raster line at AY, reading from current (src) *** ***
		STY ptr
		STA ptr+1
rle_loop:
			LDY #0			; always needed as part of the loop
			LDA (src), Y	; get command
			INC src			; advance read pointer
			BNE rle_0
				INC src+1
rle_0:
			TAX				; command is just a counter
				BMI rle_u	; negative count means uncompressed string
; * compressed string decoding ahead *
			BEQ rle_exit	; 0 repetitions means end of 'file'
; multiply next byte according to count
			LDA (src), Y	; read immediate value to be repeated
rc_loop:
				STA (ptr), Y	; store one copy
				INY				; next copy, will never wrap as <= 127
				DEX				; one less to go
				BNE rc_loop
; burst generated, must advance to next command!
			INC src
			BNE rle_next	; usually will skip to common code
				INC src+1
				BNE rle_next	; no need for BRA
; * uncompressed string decoding ahead *
rle_u:
				LDA (src), Y	; read immediate value to be sent, just once
				STA (ptr), Y	; store it just once
				INY				; next byte in chunk, will never wrap as <= 127
				INX				; one less to go
				BNE rle_u
			TYA				; how many were read?
rle_adv:
			CLC
			ADC src			; advance source pointer accordingly (will do the same with destination)
			STA src
			BCC rle_next	; check possible carry
				INC src+1
; * common code for destination advance, either from compressed or un compressed
rle_next:
			TYA				; once again, these were the transferred/repeated bytes
			CLC
			ADC ptr			; advance destination pointer accordingly
			STA ptr
			BCC rle_loop	; check possible carry
				INC ptr+1
			BNE rle_loop	; no need for BRA
; *** end of decompressor ***
rle_exit:
		CLC
		LDA dest
		ADC raster			; advance to next raster
		STA dest
		TAY					; and get ready for line decompressor
		LDA dest+1
		ADC #0				; add possible carry
		STA dest
		DEC lines			; one line less to go
		BNE raster_loop
; *** end of actual code ***
; **************************
	BRA rle_exit			; just hang after decoding!

; ** compressed 'file' ahead **
source:
;	.bin	0, 0, "image.rle"			; source file
end:
.)
