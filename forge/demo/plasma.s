; plasma effect for Durango-X
; based on code from Commodore 64 & 6510 retro-programming
; https://www.youtube.com/watch?v=w93AncybKaY
; (c) 2024 Carlos J. Santisteban
; last modified 20240707-1642

; **************************
; *** memory definitions ***
; **************************
; zeropage
	ptr		= $FC			; indirect pointer
	tmp		= $FE			; temporary value (no longer $10)
; standard RAM
	fw_irq	= $0200
	fw_nmi	= $0202
; Durango·X hardware
	screen3	= $6000
	IO8mode	= $DF80
	IO8lf	= $DF88			; EEEEEEEK
	IOAen	= $DFA0
	IOBeep	= $DFB0

	* = $800				; suitable for Pocket format
; *********************************
; *** pocket header (essential) ***
; *********************************
rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
	.asc	"pX"			; pocket format Durango-X executable
	.word	rom_start		; load address
	.word	exec			; execute address
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"Plasma effect"	; C-string with filename @ [8], max 220 chars
	.byt	0, 0			; second terminator for optional comment, just in case

; advance to end of header
	.dsb	rom_start + $E6 - *, $FF

; NEW library commit (user field 2)
	.asc	"$$$$$$$$"
; NEW main commit (user field 1)
	.asc	"$$$$$$$$"
; NEW coded version number
	.word	$1041			; 1.0b1		%vvvvrrrrsshhbbbb, where revision = %hhrrrr, ss = %00 (alpha), %01 (beta), %10 (RC), %11 (final)
; date & time in MS-DOS format at byte 248 ($F8)
	.word	$7A00			; time, 15.16		0111 1-010 000-0 0000
	.word	$58E7			; date, 2024/7/7	0101 100-0 111-0 0111
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	rom_end-rom_start			; filesize including header
	.word	0				; 64K space does not use upper 16 bits, [255]=NUL may be third magic number

; ******************
; *** init code ***
; ******************
exec:
	SEI						; usual 6502 stuff
	CLD
	LDX #$FF
	TXS
; Durango·X specific stuff
	LDA #$38				; flag init and interrupt disable
	STA IO8mode				; set colour mode
	STX IOAen				; enable hardware interrupt (LED turns off)
	LDX #>exec
	LDY #<exec
	STY fw_nmi
	STX fw_nmi+1			; use NMI as soft reset, don't care about IRQ
; black everywhere
	LDX #>screen3
	LDY #<screen3			; screen address
	STY ptr
	TYA						; actually 0
cl_page:
		STX ptr+1			; update page
clear:
			STA (ptr), Y	; clear this byte
			INY				; next in page
			BNE clear
		INX					; next page
		BPL cl_page			; until the end of screen

; ************************
; *** actual demo code ***
; ************************
start:
; first step is to create a table with sine + cosine values 
; The addition is performed on a proportionate basis
; the table is changed on every frame
	LDY #127				; actually 64 rows +64 additional values
loop:
		LDA sin, Y
addpart:
		ADC cos, Y
		STA sinecosine, Y	; new table
		DEY
		BPL loop
; values in sine + cos table are changed after each frame
	INC loop+1				; *** self-modifying code ***
	DEC addpart+1			; *** self-modifying code ***

; the first 40 succesive values represent a value
; for each of the 40 columns * * now 64 bytes per line
; The 25 following successive values represent the 25 rows * * now 64, skipping every other line
; Once the sine + cos table with the 65 values is created * * now 128
; The code adds and combines them giving 1,000 different values * * now 4096
; values 0-39 in the table / column * * now 0-63
; values 40-64 in the table / row * * now 64-127
; the routine deals each column, line by line 

	LDX #63					; no longer 39
plot:
		LDA sinecosine, X
;		LSR
		STA tmp				; will be used to store the value used for each column
; row 0
		ADC sinecosine+64	; value for row 0 (not +40)
		TAY
		LDA pattern, Y		; get colour in double nybble
		STA screen3, X		; and store it in the screen memory
; row 1
		LDA tmp
		ADC sinecosine+65	; value for row 1 (not +41)
		TAY
		LDA pattern, Y		; get colour in double nybble
		STA screen3+$0080, X; and store it in the screen memory (every 128 bytes)
; row 2
		LDA tmp
		ADC sinecosine+66
		TAY
		LDA pattern, Y
		STA screen3+$0100, X
; row 3
		LDA tmp
		ADC sinecosine+67
		TAY
		LDA pattern, Y
		STA screen3+$0180, X
; row 4
		LDA tmp
		ADC sinecosine+68
		TAY
		LDA pattern, Y
		STA screen3+$0200, X
; row 5
		LDA tmp
		ADC sinecosine+69
		TAY
		LDA pattern, Y
		STA screen3+$0280, X
; row 6
		LDA tmp
		ADC sinecosine+70
		TAY
		LDA pattern, Y
		STA screen3+$0300, X
; row 7
		LDA tmp
		ADC sinecosine+71
		TAY
		LDA pattern, Y
		STA screen3+$0380, X
; row 8
		LDA tmp
		ADC sinecosine+72
		TAY
		LDA pattern, Y
		STA screen3+$0400, X
; row 9
		LDA tmp
		ADC sinecosine+73
		TAY
		LDA pattern, Y
		STA screen3+$0480, X
; row 10
		LDA tmp
		ADC sinecosine+74
		TAY
		LDA pattern, Y
		STA screen3+$0500, X
; row 11
		LDA tmp
		ADC sinecosine+75
		TAY
		LDA pattern, Y
		STA screen3+$0580, X
; row 12
		LDA tmp
		ADC sinecosine+76
		TAY
		LDA pattern, Y
		STA screen3+$0600, X
; row 13
		LDA tmp
		ADC sinecosine+77
		TAY
		LDA pattern, Y
		STA screen3+$0680, X
; row 14
		LDA tmp
		ADC sinecosine+78
		TAY
		LDA pattern, Y
		STA screen3+$0700, X
; row 15
		LDA tmp
		ADC sinecosine+79
		TAY
		LDA pattern, Y
		STA screen3+$0780, X
; row 16
		LDA tmp
		ADC sinecosine+80
		TAY
		LDA pattern, Y
		STA screen3+$0800, X
; row 17
		LDA tmp
		ADC sinecosine+81
		TAY
		LDA pattern, Y
		STA screen3+$0880, X
; row 18
		LDA tmp
		ADC sinecosine+82
		TAY
		LDA pattern, Y
		STA screen3+$0900, X
; row 19
		LDA tmp
		ADC sinecosine+83
		TAY
		LDA pattern, Y
		STA screen3+$0980, X
; row 20
		LDA tmp
		ADC sinecosine+84
		TAY
		LDA pattern, Y
		STA screen3+$0A00, X
; row 21
		LDA tmp
		ADC sinecosine+85
		TAY
		LDA pattern, Y
		STA screen3+$0A80, X
; row 22
		LDA tmp
		ADC sinecosine+86
		TAY
		LDA pattern, Y
		STA screen3+$0B00, X
; row 23
		LDA tmp
		ADC sinecosine+87
		TAY
		LDA pattern, Y
		STA screen3+$0B80, X
; row 24
		LDA tmp
		ADC sinecosine+88
		TAY
		LDA pattern, Y
		STA screen3+$0C00, X
; row 25
		LDA tmp
		ADC sinecosine+89
		TAY
		LDA pattern, Y
		STA screen3+$0C80, X
; row 26
		LDA tmp
		ADC sinecosine+90
		TAY
		LDA pattern, Y
		STA screen3+$0D00, X
; row 27
		LDA tmp
		ADC sinecosine+91
		TAY
		LDA pattern, Y
		STA screen3+$0D80, X
; row 28
		LDA tmp
		ADC sinecosine+92
		TAY
		LDA pattern, Y
		STA screen3+$0E00, X
; row 29
		LDA tmp
		ADC sinecosine+93
		TAY
		LDA pattern, Y
		STA screen3+$0E80, X
; row 30
		LDA tmp
		ADC sinecosine+94
		TAY
		LDA pattern, Y
		STA screen3+$0F00, X
; row 31
		LDA tmp
		ADC sinecosine+95
		TAY
		LDA pattern, Y
		STA screen3+$0F80, X
; row 32
		LDA tmp
		ADC sinecosine+96
		TAY
		LDA pattern, Y
		STA screen3+$1000, X
; row 33
		LDA tmp
		ADC sinecosine+97
		TAY
		LDA pattern, Y
		STA screen3+$1080, X
; row 34
		LDA tmp
		ADC sinecosine+98
		TAY
		LDA pattern, Y
		STA screen3+$1100, X
; row 35
		LDA tmp
		ADC sinecosine+99
		TAY
		LDA pattern, Y
		STA screen3+$1180, X
; row 36
		LDA tmp
		ADC sinecosine+100
		TAY
		LDA pattern, Y
		STA screen3+$1200, X
; row 37
		LDA tmp
		ADC sinecosine+101
		TAY
		LDA pattern, Y
		STA screen3+$1280, X
; row 38
		LDA tmp
		ADC sinecosine+102
		TAY
		LDA pattern, Y
		STA screen3+$1300, X
; row 39
		LDA tmp
		ADC sinecosine+103
		TAY
		LDA pattern, Y
		STA screen3+$1380, X
; row 40
		LDA tmp
		ADC sinecosine+104
		TAY
		LDA pattern, Y
		STA screen3+$1400, X
; row 41
		LDA tmp
		ADC sinecosine+105
		TAY
		LDA pattern, Y
		STA screen3+$1480, X
; row 42
		LDA tmp
		ADC sinecosine+106
		TAY
		LDA pattern, Y
		STA screen3+$1500, X
; row 43
		LDA tmp
		ADC sinecosine+107
		TAY
		LDA pattern, Y
		STA screen3+$1580, X
; row 44
		LDA tmp
		ADC sinecosine+108
		TAY
		LDA pattern, Y
		STA screen3+$1600, X
; row 45
		LDA tmp
		ADC sinecosine+109
		TAY
		LDA pattern, Y
		STA screen3+$1680, X
; row 46
		LDA tmp
		ADC sinecosine+110
		TAY
		LDA pattern, Y
		STA screen3+$1700, X
; row 47
		LDA tmp
		ADC sinecosine+111
		TAY
		LDA pattern, Y
		STA screen3+$1780, X
; row 48
		LDA tmp
		ADC sinecosine+112
		TAY
		LDA pattern, Y
		STA screen3+$1800, X
; row 49
		LDA tmp
		ADC sinecosine+113
		TAY
		LDA pattern, Y
		STA screen3+$1880, X
; row 50
		LDA tmp
		ADC sinecosine+114
		TAY
		LDA pattern, Y
		STA screen3+$1900, X
; row 51
		LDA tmp
		ADC sinecosine+115
		TAY
		LDA pattern, Y
		STA screen3+$1980, X
; row 52
		LDA tmp
		ADC sinecosine+116
		TAY
		LDA pattern, Y
		STA screen3+$1A00, X
; row 53
		LDA tmp
		ADC sinecosine+117
		TAY
		LDA pattern, Y
		STA screen3+$1A80, X
; row 54
		LDA tmp
		ADC sinecosine+118
		TAY
		LDA pattern, Y
		STA screen3+$1B00, X
; row 55
		LDA tmp
		ADC sinecosine+119
		TAY
		LDA pattern, Y
		STA screen3+$1B80, X
; row 56
		LDA tmp
		ADC sinecosine+120
		TAY
		LDA pattern, Y
		STA screen3+$1C00, X
; row 57
		LDA tmp
		ADC sinecosine+121
		TAY
		LDA pattern, Y
		STA screen3+$1C80, X
; row 58
		LDA tmp
		ADC sinecosine+122
		TAY
		LDA pattern, Y
		STA screen3+$1D00, X
; row 59
		LDA tmp
		ADC sinecosine+123
		TAY
		LDA pattern, Y
		STA screen3+$1D80, X
; row 60
		LDA tmp
		ADC sinecosine+124
		TAY
		LDA pattern, Y
		STA screen3+$1E00, X
; row 61
		LDA tmp
		ADC sinecosine+125
		TAY
		LDA pattern, Y
		STA screen3+$1E80, X
; row 62
		LDA tmp
		ADC sinecosine+126
		TAY
		LDA pattern, Y
		STA screen3+$1F00, X
; row 63
		LDA tmp
		ADC sinecosine+127
		TAY
		LDA pattern, Y
		STA screen3+$1F80, X

		DEX
	BMI loop_exit
		JMP plot
loop_exit:
; might include some delay here
	JMP start

	.dsb	(* & $FF00) + $100 - *, $FF	; page-align

; ************
; *** data ***
; ************
pattern:
; Durango·X colours, sorted by luminance (approx)
	.dsb	8, %00000000	; black
	.dsb	8, %10001000	; blue
	.dsb	8, %01000100	; dark green
	.dsb	8, %11001100	; indigo
	.dsb	8, %00100010	; red
	.dsb	8, %10101010	; magenta
	.dsb	8, %01100110	; tile
	.dsb	8, %11101110	; fuchsia
	.dsb	8, %00010001	; green
	.dsb	8, %10011001	; sky blue
	.dsb	8, %01010101	; lime
	.dsb	8, %11011101	; cyan
	.dsb	8, %00110011	; orange
	.dsb	8, %10111011	; pink
	.dsb	8, %01110111	; yellow
	.dsb	8, %11111111	; white

	.dsb	8, %00000000	; black
	.dsb	8, %10001000	; blue
	.dsb	8, %01000100	; dark green
	.dsb	8, %11001100	; indigo
	.dsb	8, %00100010	; red
	.dsb	8, %10101010	; magenta
	.dsb	8, %01100110	; tile
	.dsb	8, %11101110	; fuchsia
	.dsb	8, %00010001	; green
	.dsb	8, %10011001	; sky blue
	.dsb	8, %01010101	; lime
	.dsb	8, %11011101	; cyan
	.dsb	8, %00110011	; orange
	.dsb	8, %10111011	; pink
	.dsb	8, %01110111	; yellow
	.dsb	8, %11111111	; white

; *** trigonometry tables ***
sin:
	.byt	32,	28,	24,	20,	16,	13,	10,	7,	5,	3,	1,	0,	0,	0,	0,	1
	.byt	2,	4,	6,	9,	11,	15,	18,	22,	26,	30,	33,	37,	41,	45,	48,	52
	.byt	54,	57,	59,	61,	62,	63,	63,	63,	63,	62,	60,	58,	56,	53,	50,	47
	.byt	43,	39,	35,	32,	28,	24,	20,	16,	13,	10,	7,	5,	3,	1,	0,	0
	.byt	0,	0,	1,	2,	4,	6,	9,	11,	15,	18,	22,	26,	30,	33,	37,	41
	.byt	45,	48,	52,	54,	57,	59,	61,	62,	63,	63,	63,	63,	62,	60,	58,	56
	.byt	53,	50,	47,	43,	39,	35,	32,	28,	24,	20,	16,	13,	10,	7,	5,	3
	.byt	1,	0,	0,	0,	0,	1,	2,	4,	6,	9,	11,	15,	18,	22,	26,	30
	.byt	33,	37,	41,	45,	48,	52,	54,	57,	59,	61,	62,	63,	63,	63,	63,	62
	.byt	60,	58,	56,	53,	50,	47,	43,	39,	35,	32,	28,	24,	20,	16,	13,	10
	.byt	7,	5,	3,	1,	0,	0,	0,	0,	1,	2,	4,	6,	9,	11,	15,	18
	.byt	22,	26,	30,	33,	37,	41,	45,	48,	52,	54,	57,	59,	61,	62,	63,	63
	.byt	63,	63,	62,	60,	58,	56,	53,	50,	47,	43,	39,	35,	32,	28,	24,	20
	.byt	16,	13,	10,	7,	5,	3,	1,	0,	0,	0,	0,	1,	2,	4,	6,	9
	.byt	11,	15,	18,	22,	26,	30,	33,	37,	41,	45,	48,	52,	54,	57,	59,	61
	.byt	62,	63,	63,	63,	63,	62,	60,	58,	56,	53,	50,	47,	43,	39,	35,	32

	.byt	32,	28,	24,	20,	16,	13,	10,	7,	5,	3,	1,	0,	0,	0,	0,	1
	.byt	2,	4,	6,	9,	11,	15,	18,	22,	26,	30,	33,	37,	41,	45,	48,	52
	.byt	54,	57,	59,	61,	62,	63,	63,	63,	63,	62,	60,	58,	56,	53,	50,	47
	.byt	43,	39,	35,	32,	28,	24,	20,	16,	13,	10,	7,	5,	3,	1,	0,	0
	.byt	0,	0,	1,	2,	4,	6,	9,	11,	15,	18,	22,	26,	30,	33,	37,	41
	.byt	45,	48,	52,	54,	57,	59,	61,	62,	63,	63,	63,	63,	62,	60,	58,	56
	.byt	53,	50,	47,	43,	39,	35,	32,	28,	24,	20,	16,	13,	10,	7,	5,	3
	.byt	1,	0,	0,	0,	0,	1,	2,	4,	6,	9,	11,	15,	18,	22,	26,	30
	.byt	33,	37,	41,	45,	48,	52,	54,	57,	59,	61,	62,	63,	63,	63,	63,	62
	.byt	60,	58,	56,	53,	50,	47,	43,	39,	35,	32,	28,	24,	20,	16,	13,	10
	.byt	7,	5,	3,	1,	0,	0,	0,	0,	1,	2,	4,	6,	9,	11,	15,	18
	.byt	22,	26,	30,	33,	37,	41,	45,	48,	52,	54,	57,	59,	61,	62,	63,	63
	.byt	63,	63,	62,	60,	58,	56,	53,	50,	47,	43,	39,	35,	32,	28,	24,	20
	.byt	16,	13,	10,	7,	5,	3,	1,	0,	0,	0,	0,	1,	2,	4,	6,	9
	.byt	11,	15,	18,	22,	26,	30,	33,	37,	41,	45,	48,	52,	54,	57,	59,	61
	.byt	62,	63,	63,	63,	63,	62,	60,	58,	56,	53,	50,	47,	43,	39,	35,	32

cos:
	.byt	0,	0,	1,	4,	7,	11,	15,	20,	25,	31,	36,	42,	47,	51,	55,	59
	.byt	61,	63,	63,	63,	62,	60,	57,	53,	49,	44,	39,	33,	28,	22,	17,	13
	.byt	8,	5,	2,	0,	0,	0,	1,	3,	5,	9,	13,	18,	23,	29,	34,	39
	.byt	45,	50,	54,	57,	60,	62,	63,	63,	63,	61,	58,	55,	51,	46,	41,	36
	.byt	30,	25,	19,	14,	10,	6,	3,	1,	0,	0,	0,	2,	4,	7,	11,	16
	.byt	21,	26,	32,	37,	43,	47,	52,	56,	59,	61,	63,	63,	63,	62,	60,	56
	.byt	53,	48,	43,	38,	32,	27,	22,	17,	12,	8,	5,	2,	0,	0,	0,	1
	.byt	3,	6,	10,	14,	19,	24,	29,	35,	40,	45,	50,	54,	58,	61,	62,	63
	.byt	63,	62,	61,	58,	54,	50,	45,	40,	35,	29,	24,	19,	14,	10,	6,	3
	.byt	1,	0,	0,	0,	2,	5,	8,	12,	17,	22,	27,	32,	38,	43,	48,	53
	.byt	56,	60,	62,	63,	63,	63,	61,	59,	56,	52,	48,	43,	37,	32,	26,	21
	.byt	16,	11,	7,	4,	2,	0,	0,	0,	1,	3,	6,	10,	14,	19,	25,	30
	.byt	36,	41,	46,	51,	55,	58,	61,	63,	63,	63,	62,	60,	57,	54,	50,	45
	.byt	39,	34,	29,	23,	18,	13,	9,	5,	3,	1,	0,	0,	0,	2,	5,	8
	.byt	13,	17,	22,	28,	33,	39,	44,	49,	53,	57,	60,	62,	63,	63,	63,	61
	.byt	59,	55,	51,	47,	42,	36,	31,	25,	20,	15,	11,	7,	4,	1,	0,	0

	.byt	0,	0,	1,	4,	7,	11,	15,	20,	25,	31,	36,	42,	47,	51,	55,	59
	.byt	61,	63,	63,	63,	62,	60,	57,	53,	49,	44,	39,	33,	28,	22,	17,	13
	.byt	8,	5,	2,	0,	0,	0,	1,	3,	5,	9,	13,	18,	23,	29,	34,	39
	.byt	45,	50,	54,	57,	60,	62,	63,	63,	63,	61,	58,	55,	51,	46,	41,	36
	.byt	30,	25,	19,	14,	10,	6,	3,	1,	0,	0,	0,	2,	4,	7,	11,	16
	.byt	21,	26,	32,	37,	43,	47,	52,	56,	59,	61,	63,	63,	63,	62,	60,	56
	.byt	53,	48,	43,	38,	32,	27,	22,	17,	12,	8,	5,	2,	0,	0,	0,	1
	.byt	3,	6,	10,	14,	19,	24,	29,	35,	40,	45,	50,	54,	58,	61,	62,	63
	.byt	63,	62,	61,	58,	54,	50,	45,	40,	35,	29,	24,	19,	14,	10,	6,	3
	.byt	1,	0,	0,	0,	2,	5,	8,	12,	17,	22,	27,	32,	38,	43,	48,	53
	.byt	56,	60,	62,	63,	63,	63,	61,	59,	56,	52,	48,	43,	37,	32,	26,	21
	.byt	16,	11,	7,	4,	2,	0,	0,	0,	1,	3,	6,	10,	14,	19,	25,	30
	.byt	36,	41,	46,	51,	55,	58,	61,	63,	63,	63,	62,	60,	57,	54,	50,	45
	.byt	39,	34,	29,	23,	18,	13,	9,	5,	3,	1,	0,	0,	0,	2,	5,	8
	.byt	13,	17,	22,	28,	33,	39,	44,	49,	53,	57,	60,	62,	63,	63,	63,	61
	.byt	59,	55,	51,	47,	42,	36,	31,	25,	20,	15,	11,	7,	4,	1,	0,	0

; workspace
sinecosine:
	.dsb	128, 0			; reserve some space for good measure
rom_end:
