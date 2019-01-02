; firmware module for minimOS·65
; (c) 2013-2019 Carlos J. Santisteban
; last modified 20180404-1404

; *** bootoff code *** v0.9.1
; NMOS and 65816 savvy
; no interface needed ('post' label is now generated here!)

#include "../../usual.h"

.(
; choose boot address depending on PA0-PA3
; ...when PA4-7 is $1
	LDA #$F0		; PA4...7 as output
	STA VIA+DDRA
	LDA #$10		; bit 4 high, 5-7 low
	STA VIA+IORA	; set PA4 high
	LDA #$0F		; mask 4 lower bits
	AND VIA+IORA	; read PA0-PA3 for startup ID
	ASL				; multiply by 2
	TAX				; table index
	_JMPX(fw_boot)	; macro for NMOS

; address table
fw_boot:
	.word	post		; default startup address
	.dsb	28, $FF		; 14 empty vectors
	.word	post		; in case the pull-ups put $FF on PA

-post:
; normal boot expected to continue after bootoff code
.)
