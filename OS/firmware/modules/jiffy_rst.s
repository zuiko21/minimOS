; firmware module for minimOS·65
; (c) 2017-2018 Carlos J. Santisteban
; last modified 20171222-2322

; reset jiffy count
; no interface needed

.(
	LDX #3				; max offset in uptime (assume contiguous)
res_sec:
		_STZA ticks, X		; reset byte
		DEX					; next byte backwards
		BPL res_sec			; zero is included
.)
