; firmware module for minimOS
; Durango-X ROMcheck interface
; (c) 2021 Carlos J. Santisteban
; last modified 20211226-1640

.(
	JSR chk_sum				; direct firmware call, of course
	BCC f16ok				; ROM checked out OK...
		LDA #1				; or turn LED off once, cyclically
		JMP lock			; low-level panic routine
f16ok:
.)
