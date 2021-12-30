; firmware module for minimOS
; Durango-X panic handler!
; make IRQ LED flash according to pattern in A
; (c) 2021 Carlos J. Santisteban
; last modified 20211230-2138

.(
dx_p:
			INY
			BNE dx_p
		INX
		BNE dx_p			; total delay ~0.2s
	ROL						; keep rotating pattern
	STA IOAen				; LED is on only when A0=0, ~44% the time
	BNE dx_p				; A is NEVER zero (I hope), no need for BRA
.)
