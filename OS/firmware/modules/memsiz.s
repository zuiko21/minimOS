; minimOS•16 firmware module
; memory size estimation (needs mirroring, undecoded areas not allowed)
; 20-bit Jalapa version
; v0.6a3
; (c) 2017 Carlos J. Santisteban
; last modified 20170724-2116

	LDA #$FF		; initial MSB
	STA uz			; set pointer LSB
	LSR			; will point inside the lower 32k of each bank
	STA uz+1		; set pointer MSB
	LDA #$07		; base bank for high RAM
	STA uz+2		; pointer is complete
rs_hiram:
		STA [uz]		; store current bank
		LSR			; shift to half size...
		STA uz+2		; ...and update pointer
		BNE rs_hiram		; repeat until bank 0
	STZ $7FFF		; in case 64K or less
	LDA @$77FFF		; *** number of RAM banks ***


	LDA #$5A		; initial value (will swap with $A5)
rs_shft:
			STA [uz]		; store current value
			CMP [uz]		; is correct?
				BNE rs_not		; not, it must be ROM
			EOR #$FF		; otherwise switch value...
			BMI rs_shft		; ...until both done
		LSR uz+2		; shift bank
		BNE rs_shft		; try half size
; *** size detected, or no more than 64K ***
;
; *** no longer in RAM, but check whether decoded? ***
rs_not:
#ifdef	SAFE
#endif
	SEC
	ROR uz+1		; recover lost bit
;******************continue...
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
