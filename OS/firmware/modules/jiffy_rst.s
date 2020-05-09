; firmware module for minimOS·65
; (c) 2017-2020 Carlos J. Santisteban
; last modified 20200509-1658

; reset jiffy count
; no interface needed

.(
	LDX #3				; max offset in uptime (assume contiguous)
#ifdef	NMOS
	LDA #0
#endif
res_sec:
#ifdef	NMOS
		STA ticks, X			; reset byte
#else
		STZ ticks, X			; reset byte
#endif
		DEX					; next byte backwards
		BPL res_sec			; zero is included
.)
