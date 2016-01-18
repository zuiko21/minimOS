; firmware module for most minimOS machines
; bootoff code 0.9
; as originally supplied with minimOS 0.4b4LK4
; (c) Carlos J. Santisteban 2013-2016
; last modified 20150223-1057
; revised 20160115 for commit with new filenames

#ifndef		FIRMWARE
#include "options.h"
#include "macros.h"
#include "abi.h"	; new filename
post = ROM_BASE		; placeholders
.text
#endif

; *** choose boot address depending on PA0-PA3 ***
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
