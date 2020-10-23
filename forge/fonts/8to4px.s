; *** convert raster in A into a 4px mask ***
; *** for Tampico's optional colour mode ***
; (c) 2020 Carlos J. Santisteban
; last modified 20201023-1307

; first approach, outside ZP takes 20b, 31t, otherwise saves 4 bytes and 4 cycles (16/27)
	PHA					; save whole raster (3)
	AND #%01010101		; keep rightish bits (2)
	STA temp			; will be ORed later (4)
	PLA					; retrieve original (4)
	LSR					; equalise position (2)
	AND #%01010101		; these were the leftish bits (2)
	ORA temp			; combine with rightish (4)
	STA temp			; result with even-numbered bits only (4)
	ASL					; now on odd-numbered positions (2)
	ORA temp			; full mask is ready in A! (4)
