; firmware module for minimOS·16
; (c) 2018-2020 Carlos J. Santisteban
; last modified 20180110-1417

; reset jiffy count
; no interface needed
; 65816 only, MUST enter in 16-bit memory!

	STZ ticks			; reset word
	STZ ticks+2			; and the MSW

