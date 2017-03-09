; code for minimOS testing purposes

; assemble from OS/ as usual
#include "usual.h"

.(
* = $10000	; go to bank 1

#ifndef	NOHEAD
	.dsb	$100*((* & $FF) <> 0) - (* & $FF), $FF	; page alignment!!! eeeeek
testHead:
; *** header identification ***
	BRK						; do not enter here! NUL marks beginning of header
	.asc	"mV"			; minimOS app! 65c816 only
	.asc	"****", CR		; some flags TBD

; *** filename and optional comment ***
	.asc	"TEST", 0		; file name (mandatory) will never coexist with pmap8
	.asc	"Just testing...", 0	; comment

; advance to end of header
	.dsb	testHead + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$5000			; time, 10.00
	.word	$4A69			; date, 2017/3/09

testSize	=	testEnd - testHead - 256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	testSize		; filesize
	.word	0				; 64K space does not use upper 16-bit
#endif

; *** real code here ***
	NOP
	JMP `!testTable
	JMP !testTable
	JMP testTable
	JMP @testTable			; this should be the only JML
	JMP testTable & $FFFF	; OK
	JSR !testEnd
	JSR testEnd
	JSR @testEnd			; this should be the only JSL
	JSR testEnd & $FFFF		; OK
testTable:
	.word	testHead
	.word	testEnd

testEnd:				; compute size!
.)

.as: .xs:				; just in case
