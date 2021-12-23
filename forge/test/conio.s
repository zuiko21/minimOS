; CONIO test for Durango-X
; (c) 2021 Carlos J. Santisteban
; last modified 20211223-2251
; assemble from ~forge/test via:
; xa conio.s -I ../../OS/firmware/modules/ -I ../../OS -l labels

; *** zeropage variables ***
.zero
*	= 3

;cio_src		.word	0		; (pointer to glyph definitions)
;cio_pt		.word	0		; (screen pointer)

; *** other variables, perhaps in ZP ***
.bss
*	= $260

fw_ctmp
fw_cbyt		.byt	0		; (temporary glyph storage) other tmp $260
fw_ccnt		.byt	0		; (bytes per raster counter, no longer X) other tmp $261
fw_chalf	.byt	0		; (remaining pages to write) $262
fw_sind		.dsb	3, 0	; $263-265

; *** firmware variables to be reset upon FF ***
fw_ccol		.dsb	4, 0	; (no longer SPARSE array of two-pixel combos, will store ink & paper) $266-269
;  * now reduced to simple 00.01.10.11 array
;fw_ciop		.word	0		; (upper scan of cursor position) $217-8
fw_fnt		.word	0		; (new, pointer to relocatable 2KB font file) $26A-B
fw_mask		.byt	0		; (for inverse/emphasis mode) $26C
fw_hires	.byt	0		; (0=colour, 128=hires, may contain other flags like 64=inverse) $26D
;fw_cbin		.byt	0		; (binary or multibyte mode) $21D

; *** test code ***
.text
*	= $400					; safe download address

; minimal hardware init
	LDA #$38				; low res, true video, screen 3, colour enabled
	STA $DF80
	LDY #12					; reset screen
	JSR conio
; printing loop
	LDX #0					; reset cursor
loop:
		PHX					; save cursor
		LDY texto, X		; get char to be printed!
			BEQ exit		; unless it's a terminator
		JSR conio
		PLX					; restore and advance cursor
		INX
		BNE loop
exit:
	BEQ loop				; final lock

; *** text to print ***
texto:
	.asc	" Imprimo lo que", 13, "  me sale del", 13, 9, 7, 14				; CR, CR, TAB, BEL, EON
	.asc	$12, 2, 'C', $A, $12, 5, 'O', $A, $12, $C, 'N', $A, $12, $E, 'I', $A, $12, 7, 'O', 15	; INK 2, INK 5, INK 12, INK 14, INK 7, EOFF (with LFs)
	.byt	0

; *** firmware module ***
conio:
#include "../../OS/firmware/modules/conio-durango-fast.s"
