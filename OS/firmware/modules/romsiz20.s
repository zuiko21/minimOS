; minimOS•16 firmware module
; ROM size estimation (allows mirroring)
; 20-bit Jalapa version
; v0.6a1
; (c) 2017 Carlos J. Santisteban
; last modified 20170703-1945

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
rs_small:
rs_end:
