; minimOS BRK handler
; v0.5a2
; (c) Carlos J. Santisteban
; based on 0.4rc
; last modified 20160310

#ifndef	KERNEL
#include "options.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
.bss
#include "firmware/ARCH.h"	; generic filename
#include "sysvars.h"
.text
* = ROM_BASE
#endif

; *** do something to tell the debugger it's from BRK, not NMI...
	LDA #<brk_txt		; string address load
	STA sysptr			; new label 20150124
	LDA #>brk_txt
	STA sysptr+1
;	JMP debug			; debug somehow...
	RTS					; standard ending 20160310
brk_txt:
	.asc "BRK ", 0		; splash text string
