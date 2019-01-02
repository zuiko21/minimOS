; firmware module for minimOS·65
; (c) 2017-2019 Carlos J. Santisteban
; last modified 20171222-2314

; VIA initialisation (and stop beeping)
; no interface needed

	LDA #%11000010	; CB2 low, Cx1 negative edge, CA2 indep. neg. (2+4)
	STA VIA_J + PCR
	LDA #%01000000	; T1 cont, no PB7, no SR, no latch (so far) (2+4)
	STA VIA_J + ACR
; supposedly will not start counting until writing to counters!
	LDA #$C0			; enable T1 (jiffy) interrupt only (2+4)
	STA VIA_J + IER
