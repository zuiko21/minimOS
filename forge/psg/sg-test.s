; Test for Interrupt-driven SN76489 PSG controller for Durango-X
; (c) 2024 Carlos J. Santisteban
; last modified 20240903-1309

; *** firmware definitions ***
	irq_ptr	= $0200
	nmi_ptr	= $0202
	ticks	= $0206

; *** I/O definitions ***
	IO8attr	= $DF80
	IOAie	= $DFA0
	IO_PSG	= $DFDB

; *** library definitions ***
	psg_if		= 0
	sg_local	= $10

	sysptr		= $FC

; *** load address ***
#ifdef	POCKET
	* = $0800				; standard pocket address
#else
	* = $C000
#endif

; ***********************
; *** standard header ***
; ***********************
rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
#ifdef	POCKET
	.asc	"pX"			; pocket executable
	.word	rom_start		; load address
	.word	reset			; execution address
#else
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
#endif
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"PSG-daemon test", 0		; C-string with filename @ [8], max 238 chars
	.asc	0				; optional comment

; advance to end of header
	.dsb	rom_start + $E6 - *, $FF

; NEW library commit (user field 2)
	.asc	"$$$$$$$$"
; NEW main commit (user field 1)
	.asc	"$$$$$$$$"
; NEW coded version number
	.word	$1042			; 1.0b2		%vvvvrrrr sshhbbbb, where revision = %hhrrrr, ss = %00 (alpha), %01 (beta), %10 (RC), %11 (final)
; date & time in MS-DOS format at byte 248 ($F8)
	.word	$6400			; time, 12.32		0110 0-100 000-0 0000
	.word	$5923			; date, 2024/9/03	0101 100-1 001-0 0011
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	file_end-rom_start			; actual executable size
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number

; *********************************
; *** interrupt service routine ***
; *********************************
isr:
	PHA
	PHX
	PHY						; save full status
	INC ticks				; increment jiffy counter (typically at $0206)
	BNE jiffies				; usually will use more bytes, but not needed for this
		INC ticks+1
;;	BNE jiffies
;;		INC ticks+2
;;	BNE jiffies
;;	INC ticks+3
jiffies:

#include "task.s"

	PLY
	PLX
	PLA
int_exit:
	RTI


; *************************
; *** generic functions ***
; *************************
delay24:
	JSR delay
delay:
	RTS

; *****************
; *** init code ***
; *****************
reset:
	SEI						; usual 6502 init
	CLD
	LDX #$FF
	TXS
; Durango-X specifics
	STX IOAie				; enable interrupts, as X is an odd value
	LDA #$38				; colour mode, screen 3, RGB
	STA IO8attr				; set video mode
; mute PSG, if available
	LDA #$FF				; max. attenuation for noise channel
psg_mute:
		STA IO_PSG			; send command to PSG (4)
		SEC					; used for subtraction (2)
		SBC #32				; next channel (2)
		JSR delay24			; wait for next PSG command (24)
		BMI psg_mute		; until all four channels done (3)
; clear screen for good measure
	LDA #$BB				; lavender pink
	LDX #$60				; screen 3 page
	LDY #0
	STY sysptr				; clear LSB
cl_page:
		STX sysptr+1		; update page
cl_loop:
			STA (sysptr), Y	; store byte
			INY
			BNE cl_loop		; until page is complete
		INX
		BPL cl_page			; until the last page of RAM
; interrupt setup
	LDY #<isr
	LDX #>isr				; ISR address
	STY irq_ptr
	STX irq_ptr+1			; stored into standard vector
	LDY #<reset
	LDX #>reset				; warm reset...
	STY nmi_ptr
	STX nmi_ptr+1			; ...installed for NMI button, as usual
	STZ ticks
	STZ ticks+1				; reset interrupt counter for good measure
; init player *** TBD
	STZ sg_c1l
	STZ sg_c2l
	STZ sg_c3l
	STZ sg_nc
	STZ psg_ec
	STZ psg_ec2
	STZ psg_ec3
	STZ psg_nec
	LDA #16
	STA sg_envsp			; set envelope speed
; setup
	LDA #%00010111			; max vol, slow decay
	STA sg_nve
	LDA #%01000100			; rnd, fast
	STA sg_nc
; *** enable interrupts and launch player ***
	CLI
lock:
	BRA lock				; infinite loop as end

; ---------------------------
#ifdef	POCKET
file_end:					; for pocket format
#else
; ***************************
; *** ROM padding and end ***
; ***************************
	.dsb	$FFD6-*, $FF	; ROM fill
; standard ROM tail
	.asc	"DmOS"			; minimOS-compliant signature
; interrupt handlers fit here
irq_hndl:
	JMP (irq_ptr)			; standard IRQ handler @ $FFDA
nmi_hndl:
	JMP (nmi_ptr)			; standard NMI handler @ $FFDD
	.byt	$FF				; some padding
switch:
	JMP ($FFFC)				; devCart switching support $FFE1

	.dsb	$FFFA-*, $FF	; ROM fill, not using checksum
; 6502 hardware vectors
	.word	nmi_hndl		; NMI as warm reset
	.word	reset
	.word	irq_hndl
file_end:					; should be $10000 for ROM images
#endif
