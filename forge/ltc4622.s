; *** LTC-4622 simple driver (2x 2 1/2 digits) ***
; *** call periodically for display (4 digits) ***
; *** 4-hex char string pointed from zeropage  ***
; *** takes ~10 ms, port is any write to $FFFx ***

	.zero

	* = $F4					; minimOS compatible string address

ptr	.dsb 2					; single parameter, pointer to hex-string (4 char)
an	.dsb 1					; index for selected anode
ch	.dsb 1					; index for read hex-char


	. text

	* = $FF00

	LDA #7					; max anode index
	STA an
	LSR						; now it's 3
	STA ch					; pointing to last character
cloop:
		LDY ch				; retrieve index
		LDA (ptr), Y		; read pointed character
		TAX					; use as bitmap index
		LDA bm, X			; get pattern
		AND #$F0			; keep MSN only
		JSR disdel			; enable anode and make delay
		LDA bm, X			; get pattern again
		
