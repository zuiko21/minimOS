; firmware module for minimOS·16
; (c) 2018 Carlos J. Santisteban
; last modified 20180116-1057

; reset last installed kernel pointer!
; no interface needed, affects FW vars
; 65816 only, MUST enter in 16-bit memory!

	STZ fw_lastk		; 816 code expected to check the whole word!
