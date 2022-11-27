; Durango-X and peripherals FULL test suite
; (c) 2022 Carlos J. Santisteban, parts from Emilio López Berenguer
; last modified 20221127-1228

; assemble from forge/test
#define	MULTIBOOT

	*	= $F000				; 4K is enough!

task	= $FA

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

; *** standard ROM end ***
	.dsb	$FFD6-*, $FF	; ROM padding
	.asc	"DmOS"			; standard Durango cartridge signature
	.dsb	$FFE0-*, $FF	; more padding, including checksum values at $FFDE-FFDF

; standard interrupt handlers
irq_handler:
	JMP ($0200)
nmi_handler:
	JMP ($0202)

; end of ROM
	.dsb	$FFFA-*, $FF	; more padding until hardware vectors

	.word	nmi_handler
	.word	hwtest
	.word	irq_handler
