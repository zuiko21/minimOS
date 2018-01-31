; extensive RAMtest for minimOS
; v0.5a1
; (c) 2015-2018 Carlos J. Santisteban
; last modified 20150622-1019
; revised 20160115 for commit with new filenames

; in case of stand alone assembly
#ifndef		FIRMWARE
#include "options.h"
#include "macros.h"
#include "abi.h"		; new filename
.zero
#include "zeropage.h"
.bss
#include "firmware/firmware.h"
.text
#endif

; extensive RAMtest, based on an idea from Tony Gonzalez @ 6502.org
ptr = z_used		; points at $2, 6510-savvy

	LDX #2			; downwards pointer limit
	LDA #$0F		; initial value to be stored
	LDY #$40		; begin testing A14
	STY ptr+1		; set pointer MSB
	LDY #0			; will be proper offset for a while
	STY ptr			; reset pointer LSB
adrt_write:
		STA (ptr), Y	; store pattern
		_DEC			; decrease value
		LSR ptr+1		; shift pointer MSB
		ROR ptr			; insert carry (if any) into LSB
		CPX ptr			; compare against limit
		BNE adrt_write	; loop otherwise
	ROL ptr			; restore pointer
	INY				; reverse offset for testing A0 @ 5
adrt_wlow:
		STA (ptr), Y
		INY			; reverse offset for testing A1 @ 6
		_DEC		; next unique value
		BNE adrt_wlow	; loop otherwise
adrt_tlow:
		DEY				; go back offset
		_INC			; restore value
		CMP (ptr), Y	; check stored value
			BNE adtr_bad	; found bad line as indicated by A-1
		CPY #0			; clumsy check...
		BNE adrt_tlow
	LDX #$80		; new upwards limit
	ROL ptr			; go for next
adrt_test:
		CMP (ptr), Y	; check stored value
			BNE adtr_bad	; found bad line as indicated by A-1
		_INC			; otherwise try next
		ROL ptr			; rotate value
		ROL ptr+1
		CPX ptr+1		; compare against value
		BNE adrt_test1	; loop otherwise
		BEQ adrt_end	; finished OK!
adrt_bad:
	_PANIC			; ????
adrt_end:
