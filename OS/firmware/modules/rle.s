; RLE decoder for minimOS
; (c) 2021 Carlos J. Santisteban
; last modified 20211227-2332

; *************************
; RLE_DEC, RLE decompressor v0.9.6b1
; *************************
;		INPUT
; rle_src.w	= compressed data pointer
; rle_ptr.w	= destination pointer
;		OUTPUT
; C <- some error (usually beyond RAM)

.(
; *** zeropage variables ***
src		= rle_src			; pointer to compressed source
ptr		= rle_ptr			; pointer to screen output

; *** actual code ***
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
; * common code for destination advance, either from compressed or un compressed
rle_next:
		TYA					; once again, these were the transferred/repeated bytes
		CLC
		ADC ptr				; advance destination pointer accordingly
		STA ptr
		BCC rle_loop		; check possible carry
			INC ptr+1
#ifdef	SAFE
#ifndef	DOWNLOAD
			LDA ptr+1		; which is the new page?
			CMP #>ROM_BASE	; is it beyond available RAM?
			BCC rle_loop	; not yet, keep on
#else
			BPL rle_loop	; includes VRAM
#endif
		_DR_ERR(FULL)		; yes, no room for it!
#else
		BPL rle_loop		; no need for BRA
#endif
; *** end of code ***
rle_exit:
	_DR_OK					; all OK
.)
