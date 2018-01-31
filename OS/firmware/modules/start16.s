; firmware module for minimOS·16
; (c) 2018 Carlos J. Santisteban
; last modified 20180119-0958

; *** start a 65816-based kernel ***
; no interface needed, uses fw_warm var

	SEC					; emulation mode for a moment (2+2)
	XCE
	JMP (fw_warm)		; any 16-bit kernel should get back into NATIVE mode (5)
