; CONIO test for Durango-X
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20211226-1224
; assemble from ~forge/nanoboot via:
; xa conio.s -I ../../OS/firmware/modules/ -I ../../OS -l labels

#include "../../macros.h"
#include "../../abi.h"
#include "../../zeropage.h"

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
fw_ciop		.word	0		; (upper scan of cursor position) $217-8
fw_fnt		.word	0		; (new, pointer to relocatable 2KB font file) $26A-B
fw_mask		.byt	0		; (for inverse/emphasis mode) $26C
;fw_hires	.byt	0		; (0=colour, 128=hires, may contain other flags like 64=inverse) $26D
fw_hires	= $DF80			; directly from video flags
fw_cbin		.byt	0		; (binary or multibyte mode) $21D
fw_io9		.byt	0

; *** firmware variables to be reset upon FF ***
; OK fw_ccol.p (SPARSE array of two-pixel combos, will store ink & paper)
;  above will use offsets 0, 1, 2, 3; 4, 8, 12; 16, 32, 48; 64, 128, 192
;  set patterns will be  00,01,10,11,01,10, 11, 01, 10, 11, 01,  10,  11 (0=paper, 1=ink)
;  * now reduced to simple 00.01.10.11 array
; OK fw_ciop.w (upper scan of cursor position)
; OK fw_fnt.w (new, pointer to relocatable 2KB font file)
; OK fw_mask (for inverse/emphasis mode)
; HERE fw_hires (0=colour, 128=hires, may contain other flags like 64=inverse)
; OK but HERE also fw_cbin (binary or multibyte mode)

; *** test code ***
.text
*	= $400					; safe download address

; usual stuff
	SEI
	CLD
	LDX #$FF
	TXS
; minimal hardware init
	LDA #$B8				; hi res, true video, screen 3, colour enabled
repeat:
	STA fw_hires			; now directly on hardware register!
	_STZA fw_cbin			; eeeeeeeeeeeeeek
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
	BIT $DF9F				; check joystick
	BPL exit
release:
	BIT $DF9F				; check joystick
	BMI release				; wait for keyup
	LDA fw_hires
	EOR #$80				; switch resolution
	JMP repeat

; *** text to print ***
texto:
	.asc	" Imprimo lo que   me sale del   ", 9, 7, 14		; TAB, BEL, EON
	.asc	$12, 2, 'C', $A, $12, 5, 'O', 7, $A					; INK, LF, BEL
	.asc	$12, $C, 'N', $A, $12, $E, 'I', $A, $12, 7, 'O', 15	; INK, EOFF (with LFs)

	.asc	13,13, "Hola, 1234"									; CR
	.asc	13,13,13,13,13,"uno",13,"dos",13,"tres",13,"cuatro"	; scroll
	.asc	13,13,13,13,13,"UNO",13,"DOS",13,"TRES",13,"CUATRO"
	.asc	13,13,13,13,13,"one",13,"two",13,"three",13,"four"
	.asc	13,13,13,13,13,"ONE",13,"TWO",13,"THREE",13,"FOUR"
	
	.asc	21,14,18,11,"Hom*******"	; home
	.asc	8,8,8,8,8,8,8,"e",15		; backspace
	.asc	10,16,10,2,6,16,6,2			; cursors & DLE
	.asc	11,16,11,2,2,16,2
	.asc	23,37,36,"@",1,14,"T",15	; ATYX, start-of-line
	.asc	17,7,17,7,17,7				; XON & BEL
	.byt	23,40,39,18,2,16,16,18,3,16,7,	0

; *** firmware module ***
conio:
#include "../../OS/firmware/modules/conio-durango-fast.s"
after:
