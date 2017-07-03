; minimOS•16 firmware module
; ROM size estimation (allows mirroring)
; 20-bit Jalapa version
; v0.6a1
; (c) 2017 Carlos J. Santisteban
; last modified 20170703-2144

	LDA #$FA		; standard vector location LSB
	STA uz			; set pointer
	LDA #$FF		; standard vector location MSB
	STA uz+1		; set pointer
	LDA #$F8		; base bank ($80 for 24-bit)
	STA uz+2		; pointer is complete
	SEC			; insert 1 from left
rs_shft:
		ROR uz+2		; shift bank
			BCS rs_small		; tiny ROM!
		JSR rs_cmp		; check whether vectors are found there
		BCS rs_shft		; there is mirroring, try half size
; *** size detected ***
	LDA #1			; we will subtract to the end
	SBC uz+2		; subtract selected bank (C was clear)
	LDY #0			; no partial banks!
	STZ uz			; neither partial pages
	BRA rs_end		; store size and we're done

; *** check whether the vectors appear at pointed bank [uz] ***
rs_cmp:
	LDY #5			; from last vector, backwards
rs_loop:
		LDA [uz], Y		; get byte pointed at high ROM
		CMP $FFFA, Y		; compare with kernel-area vectors
			BNE rs_dif		; not the same
		DEY			; go for next byte
		BPL rs_loop		; zero is included
	SEC			; mark as repeat
	RTS
rs_dif:
	CLC			; otherwise is not the same
	RTS

; *** compute small ROM size ***
rs_small:
	STZ uz			; pointer now goes at start
	STZ uz+1
	LDA @$F80000		; this is the first byte in ROM (bank $80 for 24-bit)
rss_shft:
		SEC			; will insert 1 from left
		ROR uz+1		; shift page
; might check C, if set something must be corrupt!
		CMP [uz]		; coincides with what was inside?
		BEQ rss_shft		; no, more mirroring
; get size in pages
	LDA #0
	SEC
	SBC uz+1
	TAY
	LDA #0
rs_end:
	STA uz+2		; store size in banks
	STY uz+1		; just in case, store size in pages
