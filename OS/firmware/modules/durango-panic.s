; firmware module for minimOS
; Durango-X panic handler!
; make IRQ LED flash according to pattern in A
; (c) 2021 Carlos J. Santisteban
; last modified 20211230-2207

.(
dx_p:
			INY
			BNE dx_p
		INX
		BNE dx_p			; total delay ~0.2s
	ROL						; keep rotating pattern
	STA IOAie				; LED is on only when A0=0, ~44% the time
	_BRA dx_p				; not sure...
.)
