; firmware module for minimOS·65
; (c) 2017-2019 Carlos J. Santisteban
; last modified 20171221-1330

; *** NMOS-savvyness check ***
; assume A holds CPU code!

.(
#ifdef	SAFE
#ifndef	NMOS
;	LDA fw_cpu		; ...in case A was not preserved after CPU check
	CMP #'N'		; is it NMOS? not supported!
	BNE fw_cpuOK	; otherwise continue
		JMP lock		; cannot handle BRK, alas
fw_cpuOK:
#endif
#endif
.)
