; RLE-encoded video playback POC
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20211110-1334

; *** zeropage variables ***
.zero

*	= 3

src		.word	0			; pointer to compressed source
ptr		.word	0			; pointer to screen output
jiffy	.byt	0			; jiffy counter, if not provided by OS
next	.byt	0			; next frame decoding deadline

.text

* = $300					; needs TONS of space!

; *** parameter definitions ***
dest	= $6400				; Durango-X screen address (for 192-px height)
 
; *** actual code ***
    LDA #$B0                ; hires mode, screen 3 for testing
    STA $DF80               ; set video flags
; must install an interrupt handler, 10 fps = 25 jiffys
	LDY #<isr_rle
	LDA #>isr_rle
	STY $200				; fw_isr
	STA	$201
	STZ jiffy
	LDA #25					; next displayed frame
	STA next
	STA $DFA0				; d0 is on, enable interrupts
	CLI						; interrupt is on
	
; *** decompressing algorithm ***
; preload pointers as required
start:
	LDA #>source			; compressed data origin
	LDY #<source
	STY src
	STA src+1
reloop:
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
; skip end-of-file, wait for VSYNC and decode next frame
	INC src				    ; advance read pointer
	BNE rle_wait
		INC src+1
rle_wait:
    LDA (src)               ; CMOS, are we on a second consecutive NULL?
    BEQ rle_end             ; yep, playback is done (may repeat all)
; ...but make sure we are doing the right fps!
rle_fps:
	LDA jiffy
	CMP next				; wait until next displayable frame
	BNE rle_fps
; now set all for next frame
	CLC
	ADC #25					; for 10 fps
	STA next
; to avoid tearing, wait for vsync
rle_vsync:
        BIT $DF88           ; wait until VBlank (d6)
        BVC rle_vsync
    BVS reloop              ; then decode next frame
rle_end:
; *** all frames done, maybe loop again ***
    JMP start
; should page-align?

; *** interrupt handler (if not provided) ***
isr:
	INC jiffy
	RTI

; ** compressed 'file' ahead **
source:
	.bin	0, *, "../rle/test.rlm"
