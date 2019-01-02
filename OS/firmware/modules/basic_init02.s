; firmware module for minimOS·65
; (c) 2017-2019 Carlos J. Santisteban
; last modified 20180131-0855

; *** basic initialisation ***
; assumed to start at 'reset' label (in template file)
; NMOS savvy, save a few bytes if a 65816 cannot be used!
; no interface needed

-reset:
	SEI				; cold boot, best assume nothing (2)
	CLD				; just in case, a must for NMOS (2)
	LDX #SPTR		; initial stack pointer, machine-dependent, must be done in emulation for '816 (2)
	TXS				; initialise stack (2)
