; Test for Interrupt-driven SN76489 PSG controller for Durango-X
; (c) 2024 Carlos J. Santisteban
; last modified 20240904-1751

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
	sr_if		= $10
	sg_local	= $20		; EEEEEEEEK
#define	SCORE
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
	.word	$1044			; 1.0b4		%vvvvrrrr sshhbbbb, where revision = %hhrrrr, ss = %00 (alpha), %01 (beta), %10 (RC), %11 (final)
; date & time in MS-DOS format at byte 248 ($F8)
	.word	$BB00			; time, 23.24		1011 1-011 000-0 0000
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
	LDA IO8attr
	AND #$F0
	ORA #8
	EOR #64
	STA IO8attr

#include "task.s"

	LDA IO8attr
	AND #$F0
	ORA #8
	EOR #64
	STA IO8attr

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
; init player
	STZ sg_c1l
	STZ sg_c2l
	STZ sg_c3l
	STZ sg_nc
;	STZ psg_cv
;	STZ psg_cv2
;	STZ psg_cv3
;	STZ psg_nc
	STZ pr_dly
	STZ pr_cnt
	STZ pr_cnt2
	STZ pr_cnt3
	STZ pr_ncnt
	LDA #16
	STA sg_envsp			; set envelope speed
	STZ sr_turbo
	dec sr_turbo
	LDA #0					; 0 = 234 bpm, then half, third...
	STA sr_tempo
	STZ sr_ena
; setup
	LDY #<score1
	LDX #>score1			; score 1 pointer
	STY sr_c1
	STX sr_c1+1				; set pointer
	LDY #<score2
	LDX #>score2			; score 2 pointer
	STY sr_c2
	STX sr_c2+1				; set pointer
	LDY #<score3
	LDX #>score3			; score 3 pointer
	STY sr_c3
	STX sr_c3+1				; set pointer
	LDY #<nscore
	LDX #>nscore			; noise score pointer
	STY sr_nc
	STX sr_nc+1				; set pointer
; *** enable interrupts and launch player ***
	LDA #%10010000			; start noise channel only
	STA sr_rst
	CLI
lock:
	BRA lock				; infinite loop as end

; three-byte strings -> note, length, envelope/volume
; note 0 -> end, note $FF -> repeat
score1:
	.byt	20, 128, $FF
	.byt	20, 255, $0F
	.byt	20, 1, $0F
;	.byt	20, 128, $0F
	.byt	32, 128, $2F
	.byt	$ff				; end

score2:
	.byt	24, 128, 0
	.byt	24, 128, $FF
	.byt	24, 128, $0F
	.byt	36, 128, $2F
	.byt	$ff				; end

score3:
	.byt	27, 255, 0
	.byt	27, 1, 0
	.byt	27, 128, $FF
	.byt	39, 128, $2F
	.byt	$ff				; end

nscore:
	.byt $44, 64, $1F		; open hihat, black, slow decay, max vol
	.byt $44, 32, $2F		; open hihat, crochet, not so slow decay
	.byt $44, 32, $2F		; open hihat, crochet, not so slow decay
	.byt $45, 32, $2C		; closed lohat, crochet, fast decay, mid volume
	.byt $45, 96, 0			; rest, dotted black
	.byt $44, 128, $1F		; open hihat, white, slow decay, max vol
	.byt $45, 32, $2C		; closed lohat, crochet, fast decay, mid volume
	.byt $45, 96, 0			; rest, dotted black
	.byt $FF				; repeat this forever

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
