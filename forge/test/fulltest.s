; Durango-X and peripherals FULL test suite
; (c) 2022-2023 Carlos J. Santisteban, parts from Emilio López Berenguer
; last modified 20230319-2228

; assemble from forge/test
#define	MULTIBOOT

	*	= $F000				; 4K is enough!

task	= $FA

; *** standard header ***
rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"fulltest", 0	; C-string with filename @ [8], max 238 chars
;	.asc	"(comment)"		; optional C-string with comment after filename, filename+comment up to 238 chars
	.byt	0				; second terminator for optional comment, just in case

; advance to end of header
	.dsb	rom_start + $F8 - *, $FF

; date & time in MS-DOS format at byte 248 ($F8)
	.word	$B380			; time, 22.28
	.word	$5673			; date, 2023/3/19
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start			; filesize (rom_end is actually $10000)
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number

; *** standard hardware test ***
hwtest:
.(
#include "durango-test.s"
.)

; *** joypad test (based on Emilio's work)***
joypad:
.(
#include "padtest.s"
.)

; *** Assembly version of Emilio's 5x8 keyboard test ***
keyboard:
.(
#include "kbtest.s"
.)

; *** delay test screen, colour mode ***
delay_c:
.(
#include "delay.s"
.)

; *** delay test screen, HIRES mode ***
delay_hr:
.(
#include "hrdelay.s"
.)

; *** NMI task switcher ***
switcher:
	LDX task				; current task, 0=test, 2=pads, 4=kbd, 6=colour chart, 8=hires chart
	INX
	INX
	CPX #ex_end-ex_ptr		; over 8, all tests done
	BNE next
		LDX #0				; start over
next:
	STX task
;	JMP (ex_ptr, X)			; otherwise, execute new task, CMOS only!
	LDA ex_ptr+1, X
	PHA
	LDA ex_ptr, X
	PHA
	PHP
	RTI						; indexed jump emulation!

; addresses list
ex_ptr:
	.word	hwtest
	.word	joypad
	.word	keyboard
	.word	delay_c
	.word	delay_hr
ex_end:

; standard interrupt handlers
irq_handler:
	JMP ($0200)
nmi_handler:
	JMP ($0202)

; *** standard ROM end ***
	.dsb	$FFD6-*, $FF	; ROM padding
	.asc	"DmOS"		; standard Durango cartridge signature
; end of ROM
	.dsb	$FFE1-*, $FF	; devCart support
	JMP ($FFFC)

	.dsb	$FFFA-*, $FF	; more padding until hardware vectors

	.word	nmi_handler
	.word	hwtest
	.word	irq_handler
