; firmware module for most minimOS machines
; startup beep code 0.9.2b1
; 0.9 originally supplied with minimOS 0.4rc
; (c) 2013-2022 Carlos J. Santisteban
; last modified 20180404-1404
; revised 20160115 for commit with new filenames

; in case of standalone assembly
#ifndef		FIRMWARE
#include "../../usual.h"
#endif

; *** initial beep (500Hz/MHz) during test ***
	LDA #%11100010	; CB2 *high*, Cx1 negative edge, CA2 indep. neg.
	STA VIA+PCR		; sound output is enabled
	LDA #%11000000	; T1 cont, PB7 squarewave, no SR, no latch (so far)
	STA VIA+ACR
	LDA #$F2		; $1F2 = 1kHz beep @ 1 MHz, obviously NOT $61A8 for 500...
	STA VIA+T1CL	; put value into latch
	LDA #$01
	STA VIA+T1CH	; start counting!
