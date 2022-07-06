; joypad format conversion for NES
; (c) 2022 Carlos J. Santisteban

;	LDA orig				; get NES-format data (ABetUDLR, where t=START & e=SELECT)
	STA temp				; store original value (for d7)
	LSR						; discard d0 but save it in C
	AND #%00111111			; ignore previous d7 for a 64-byte table
	LDA table, X			; get shuffled bits (x0tBeULD)
	ROL						; reinsert stored d0
	BIT temp				; if d7 was originally set, goes Negative
	BPL ok
		ORA #%10000000		; A was pushed
;	STA joypad				; save in our standard format (AtBeULDR)
;	RTS						; done (may be inlined)

; *** 64-byte table for bit-shuffling (ABetUDLR => AtBeULDR) ***
; note they're 6-bit entries 00tBeULD, as A & R coincide with NES format
table:
	
