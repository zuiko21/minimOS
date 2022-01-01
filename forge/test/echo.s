; CONIO echo server for Durango-X
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20211226-1134
; assemble from ~forge/nanoboot via:
; xa echo.s -I ../../OS/firmware/modules/ -I ../../OS -l labels

#include "../../macros.h"
#include "../../abi.h"
#include "../../zeropage.h"

; *** zeropage variables ***
.zero
*	= 3

;cio_src	.word	0		; (pointer to glyph definitions)
;cio_pt		.word	0		; (screen pointer)

; *** other variables, perhaps in ZP ***
.bss
*	= $240

fw_ctmp
fw_cbyt		.byt	0		; (temporary glyph storage) other tmp $240
fw_ccnt		.byt	0		; (bytes per raster counter, no longer X) other tmp $241
fw_chalf	.byt	0		; (remaining pages to write) $242
fw_sind		.dsb	3, 0	; $243-245

; *** firmware variables to be reset upon FF ***
fw_ccol		.dsb	4, 0	; (no longer SPARSE array of two-pixel combos, will store ink & paper) $246-249
;  * now reduced to simple 00.01.10.11 array
fw_ciop		.word	0		; (upper scan of cursor position) $24A-B
fw_fnt		.word	0		; (new, pointer to relocatable 2KB font file) $24C-D
fw_mask		.byt	0		; (for inverse/emphasis mode) $24E
;fw_hires	.byt	0		; (0=colour, 128=hires, may contain other flags like 64=inverse)
;fw_hires	= $DF80			; directly from video flags
fw_cbin		.byt	0		; (binary or multibyte mode) $24F
fw_io9		.byt	0		; input buffer $250

; *** firmware variables to be reset upon FF ***
; fw_ccol.p (SPARSE array of two-pixel combos, will store ink & paper)
;  above will use offsets 0, 1, 2, 3; 4, 8, 12; 16, 32, 48; 64, 128, 192
;  set patterns will be  00,01,10,11,01,10, 11, 01, 10, 11, 01,  10,  11 (0=paper, 1=ink)
;  * now reduced to simple 00.01.10.11 array
; fw_ciop.w (upper scan of cursor position)
; fw_fnt.w (new, pointer to relocatable 2KB font file)
; fw_mask (for inverse/emphasis mode)
; OK but HERE also fw_cbin (binary or multibyte mode, essential for the first FF)

; *** test code ***
.text
*	= $400					; safe download address

; usual stuff
	SEI
	CLD
	LDX #$FF
	TXS
; minimal hardware init
	LDA #$b8				; lo res, true video, screen 3, colour enabled
repeat:
	STA $DF80				; now directly on hardware register!
	_STZA fw_cbin			; eeeeeeeeeeeeeek
	LDY #12					; reset screen
	JSR conio
; printing loop
loop:
			LDY #0			; input mode
			JSR conio
			BCS loop		; wait for something available
		CPY #255			; ÿ for mode switch
			BEQ switch
		JSR conio			; otherwise, print it right now!
		BCC loop			; no need for BRA, hopefully
switch:
	LDA $DF80
	EOR #$80				; switch resolution
	JMP repeat

; *** firmware module ***
conio:
#include "../../OS/firmware/modules/conio-durango-fast.s"
after:
