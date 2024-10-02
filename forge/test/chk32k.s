; Durango-X ROM download test
; (c) 2024 Carlos J. Santisteban
; last modified 20241003-0002

#define	CHKVALUE	156
#define	SUMVALUE	244
#define	SIZE		87

*	= $8000
; *** *** standard header *** ***
rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"Download integrity test", 0		; C-string with filename @ [8], max 238 chars
	.asc	"for Durango·X + devCart and DurangoPLUS"		; comment with IMPORTANT attribution
	.byt	0				; second terminator for optional comment, just in case

; advance to end of header *** NEW format
	.dsb	rom_start + $E6 - *, $FF

; NEW library commit (user field 2)
	.asc	"$$$$$$$$"
; NEW main commit (user field 1)
	.asc	"$$$$$$$$"
; NEW coded version number
	.word	$0101			; 0.1a1		%vvvvrrrrsshhbbbb, where revision = %hhrrrr, ss = %00 (alpha), %01 (beta), %10 (RC), %11 (final)
; date & time in MS-DOS format at byte 248 ($F8)
	.word	$B800			; time, 23.00		%1011 1-000 000-0 0000
	.word	$5941			; date, 2024/10/1	%0101 100-1 010-0 0001
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start			; filesize (rom_end is actually $10000)
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number

; *** hardware definitions ***
	screen3	= $6000
	IO8attr	= $DF80
	IOAie	= $DFA0
	IOCart	= $DFC0

; *** memory allocation ***
	sum		= $FA
	chk		= $FB
	ptr		= $FC

; *****************
; *** init code ***
; *****************
reset:
	SEI
	CLD
	LDX #$FF
	TXS						; basic 6502 init
	STX IOAie				; turn LED off
	LDA #$38				; screen 3, colour mode, RGB
	STA IO8attr
; clear screen for good measure
	LDX #>screen3
	LDY #<screen3			; expected 0
	TYA						; will set screen black as well
	STY ptr
p_cls:
		STX ptr+1
l_cls:
			STA (ptr), Y
			INY
			BNE l_cls		; clear full page
		INX					; next page
		BPL p_cls			; valid until the end of mux-RAM
; prepare for testing
	LDY #>p_cls				; page index

	JMP $8180				; first standard test!
	.dsb	$8180-*, $FF

; $8xxx, minus header and init

; *** test code ***
s818:
	STZ sum
	STZ chk
	LDX #0
l818:
		LDA sum
		CLC
		ADC t818, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l818
	CMP #CHKVALUE			; compare sum of sums
		BNE x818			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x818			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x818:
	INY						; this was odd half-page
	JMP $8200				; next test
t818:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s820:
	STZ sum
	STZ chk
	LDX #0
l820:
		LDA sum
		CLC
		ADC t820, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l820
	CMP #CHKVALUE			; compare sum of sums
		BNE x820			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x820			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x820:
	NOP
	JMP $8280				; next test
t820:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s828:
	STZ sum
	STZ chk
	LDX #0
l828:
		LDA sum
		CLC
		ADC t828, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l828
	CMP #CHKVALUE			; compare sum of sums
		BNE x828			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x828			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x828:
	INY						; this was odd half-page
	JMP $8300				; next test
t828:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s830:
	STZ sum
	STZ chk
	LDX #0
l830:
		LDA sum
		CLC
		ADC t830, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l830
	CMP #CHKVALUE			; compare sum of sums
		BNE x830			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x830			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x830:
	NOP
	JMP $8380				; next test
t830:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s838:
	STZ sum
	STZ chk
	LDX #0
l838:
		LDA sum
		CLC
		ADC t838, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l838
	CMP #CHKVALUE			; compare sum of sums
		BNE x838			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x838			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x838:
	INY						; this was odd half-page
	JMP $8400				; next test
t838:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s840:
	STZ sum
	STZ chk
	LDX #0
l840:
		LDA sum
		CLC
		ADC t840, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l840
	CMP #CHKVALUE			; compare sum of sums
		BNE x840			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x840			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x840:
	NOP
	JMP $8480				; next test
t840:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s848:
	STZ sum
	STZ chk
	LDX #0
l848:
		LDA sum
		CLC
		ADC t848, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l848
	CMP #CHKVALUE			; compare sum of sums
		BNE x848			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x848			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x848:
	INY						; this was odd half-page
	JMP $8500				; next test
t848:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s850:
	STZ sum
	STZ chk
	LDX #0
l850:
		LDA sum
		CLC
		ADC t850, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l850
	CMP #CHKVALUE			; compare sum of sums
		BNE x850			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x850			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x850:
	NOP
	JMP $8580				; next test
t850:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s858:
	STZ sum
	STZ chk
	LDX #0
l858:
		LDA sum
		CLC
		ADC t858, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l858
	CMP #CHKVALUE			; compare sum of sums
		BNE x858			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x858			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x858:
	INY						; this was odd half-page
	JMP $8600				; next test
t858:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s860:
	STZ sum
	STZ chk
	LDX #0
l860:
		LDA sum
		CLC
		ADC t860, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l860
	CMP #CHKVALUE			; compare sum of sums
		BNE x860			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x860			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x860:
	NOP
	JMP $8680				; next test
t860:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s868:
	STZ sum
	STZ chk
	LDX #0
l868:
		LDA sum
		CLC
		ADC t868, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l868
	CMP #CHKVALUE			; compare sum of sums
		BNE x868			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x868			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x868:
	INY						; this was odd half-page
	JMP $8700				; next test
t868:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s870:
	STZ sum
	STZ chk
	LDX #0
l870:
		LDA sum
		CLC
		ADC t870, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l870
	CMP #CHKVALUE			; compare sum of sums
		BNE x870			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x870			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x870:
	NOP
	JMP $8780				; next test
t870:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s878:
	STZ sum
	STZ chk
	LDX #0
l878:
		LDA sum
		CLC
		ADC t878, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l878
	CMP #CHKVALUE			; compare sum of sums
		BNE x878			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x878			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x878:
	INY						; this was odd half-page
	JMP $8800				; next test
t878:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s880:
	STZ sum
	STZ chk
	LDX #0
l880:
		LDA sum
		CLC
		ADC t880, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l880
	CMP #CHKVALUE			; compare sum of sums
		BNE x880			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x880			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x880:
	NOP
	JMP $8880				; next test
t880:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s888:
	STZ sum
	STZ chk
	LDX #0
l888:
		LDA sum
		CLC
		ADC t888, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l888
	CMP #CHKVALUE			; compare sum of sums
		BNE x888			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x888			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x888:
	INY						; this was odd half-page
	JMP $8900				; next test
t888:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s890:
	STZ sum
	STZ chk
	LDX #0
l890:
		LDA sum
		CLC
		ADC t890, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l890
	CMP #CHKVALUE			; compare sum of sums
		BNE x890			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x890			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x890:
	NOP
	JMP $8980				; next test
t890:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s898:
	STZ sum
	STZ chk
	LDX #0
l898:
		LDA sum
		CLC
		ADC t898, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l898
	CMP #CHKVALUE			; compare sum of sums
		BNE x898			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x898			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x898:
	INY						; this was odd half-page
	JMP $8A00				; next test
t898:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s8A0:
	STZ sum
	STZ chk
	LDX #0
l8A0:
		LDA sum
		CLC
		ADC t8A0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l8A0
	CMP #CHKVALUE			; compare sum of sums
		BNE x8A0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x8A0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x8A0:
	NOP
	JMP $8A80				; next test
t8A0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s8A8:
	STZ sum
	STZ chk
	LDX #0
l8A8:
		LDA sum
		CLC
		ADC t8A8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l8A8
	CMP #CHKVALUE			; compare sum of sums
		BNE x8A8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x8A8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x8A8:
	INY						; this was odd half-page
	JMP $8B00				; next test
t8A8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s8B0:
	STZ sum
	STZ chk
	LDX #0
l8B0:
		LDA sum
		CLC
		ADC t8B0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l8B0
	CMP #CHKVALUE			; compare sum of sums
		BNE x8B0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x8B0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x8B0:
	NOP
	JMP $8B80				; next test
t8B0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s8B8:
	STZ sum
	STZ chk
	LDX #0
l8B8:
		LDA sum
		CLC
		ADC t8B8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l8B8
	CMP #CHKVALUE			; compare sum of sums
		BNE x8B8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x8B8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x8B8:
	INY						; this was odd half-page
	JMP $8C00				; next test
t8B8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s8C0:
	STZ sum
	STZ chk
	LDX #0
l8C0:
		LDA sum
		CLC
		ADC t8C0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l8C0
	CMP #CHKVALUE			; compare sum of sums
		BNE x8C0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x8C0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x8C0:
	NOP
	JMP $8C80				; next test
t8C0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s8C8:
	STZ sum
	STZ chk
	LDX #0
l8C8:
		LDA sum
		CLC
		ADC t8C8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l8C8
	CMP #CHKVALUE			; compare sum of sums
		BNE x8C8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x8C8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x8C8:
	INY						; this was odd half-page
	JMP $8D00				; next test
t8C8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s8D0:
	STZ sum
	STZ chk
	LDX #0
l8D0:
		LDA sum
		CLC
		ADC t8D0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l8D0
	CMP #CHKVALUE			; compare sum of sums
		BNE x8D0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x8D0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x8D0:
	NOP
	JMP $8D80				; next test
t8D0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s8D8:
	STZ sum
	STZ chk
	LDX #0
l8D8:
		LDA sum
		CLC
		ADC t8D8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l8D8
	CMP #CHKVALUE			; compare sum of sums
		BNE x8D8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x8D8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x8D8:
	INY						; this was odd half-page
	JMP $8E00				; next test
t8D8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s8E0:
	STZ sum
	STZ chk
	LDX #0
l8E0:
		LDA sum
		CLC
		ADC t8E0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l8E0
	CMP #CHKVALUE			; compare sum of sums
		BNE x8E0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x8E0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x8E0:
	NOP
	JMP $8E80				; next test
t8E0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s8E8:
	STZ sum
	STZ chk
	LDX #0
l8E8:
		LDA sum
		CLC
		ADC t8E8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l8E8
	CMP #CHKVALUE			; compare sum of sums
		BNE x8E8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x8E8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x8E8:
	INY						; this was odd half-page
	JMP $8F00				; next test
t8E8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s8F0:
	STZ sum
	STZ chk
	LDX #0
l8F0:
		LDA sum
		CLC
		ADC t8F0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l8F0
	CMP #CHKVALUE			; compare sum of sums
		BNE x8F0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x8F0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x8F0:
	NOP
	JMP $8F80				; next test
t8F0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s8F8:
	STZ sum
	STZ chk
	LDX #0
l8F8:
		LDA sum
		CLC
		ADC t8F8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l8F8
	CMP #CHKVALUE			; compare sum of sums
		BNE x8F8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x8F8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x8F8:
	INY						; this was odd half-page
	JMP $9000				; next test
t8F8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87

; $9xxx

; *** test code ***
s900:
	STZ sum
	STZ chk
	LDX #0
l900:
		LDA sum
		CLC
		ADC t900, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l900
	CMP #CHKVALUE			; compare sum of sums
		BNE x900			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x900			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x900:
	NOP
	JMP $9280				; next test
t900:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s908:
	STZ sum
	STZ chk
	LDX #0
l908:
		LDA sum
		CLC
		ADC t908, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l908
	CMP #CHKVALUE			; compare sum of sums
		BNE x908			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x908			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x908:
	INY						; this was odd half-page
	JMP $9300				; next test
t908:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s910:
	STZ sum
	STZ chk
	LDX #0
l910:
		LDA sum
		CLC
		ADC t910, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l910
	CMP #CHKVALUE			; compare sum of sums
		BNE x910			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x910			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x910:
	NOP
	JMP $9380				; next test
t910:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s918:
	STZ sum
	STZ chk
	LDX #0
l918:
		LDA sum
		CLC
		ADC t918, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l918
	CMP #CHKVALUE			; compare sum of sums
		BNE x918			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x918			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x918:
	INY						; this was odd half-page
	JMP $9200				; next test
t918:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s920:
	STZ sum
	STZ chk
	LDX #0
l920:
		LDA sum
		CLC
		ADC t920, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l920
	CMP #CHKVALUE			; compare sum of sums
		BNE x920			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x920			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x920:
	NOP
	JMP $9280				; next test
t920:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s928:
	STZ sum
	STZ chk
	LDX #0
l928:
		LDA sum
		CLC
		ADC t928, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l928
	CMP #CHKVALUE			; compare sum of sums
		BNE x928			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x928			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x928:
	INY						; this was odd half-page
	JMP $9300				; next test
t928:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s930:
	STZ sum
	STZ chk
	LDX #0
l930:
		LDA sum
		CLC
		ADC t930, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l930
	CMP #CHKVALUE			; compare sum of sums
		BNE x930			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x930			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x930:
	NOP
	JMP $9380				; next test
t930:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s938:
	STZ sum
	STZ chk
	LDX #0
l938:
		LDA sum
		CLC
		ADC t938, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l938
	CMP #CHKVALUE			; compare sum of sums
		BNE x938			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x938			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x938:
	INY						; this was odd half-page
	JMP $9400				; next test
t938:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s940:
	STZ sum
	STZ chk
	LDX #0
l940:
		LDA sum
		CLC
		ADC t940, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l940
	CMP #CHKVALUE			; compare sum of sums
		BNE x940			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x940			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x940:
	NOP
	JMP $9480				; next test
t940:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s948:
	STZ sum
	STZ chk
	LDX #0
l948:
		LDA sum
		CLC
		ADC t948, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l948
	CMP #CHKVALUE			; compare sum of sums
		BNE x948			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x948			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x948:
	INY						; this was odd half-page
	JMP $9500				; next test
t948:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s950:
	STZ sum
	STZ chk
	LDX #0
l950:
		LDA sum
		CLC
		ADC t950, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l950
	CMP #CHKVALUE			; compare sum of sums
		BNE x950			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x950			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x950:
	NOP
	JMP $9580				; next test
t950:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s958:
	STZ sum
	STZ chk
	LDX #0
l958:
		LDA sum
		CLC
		ADC t958, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l958
	CMP #CHKVALUE			; compare sum of sums
		BNE x958			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x958			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x958:
	INY						; this was odd half-page
	JMP $9600				; next test
t958:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s960:
	STZ sum
	STZ chk
	LDX #0
l960:
		LDA sum
		CLC
		ADC t960, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l960
	CMP #CHKVALUE			; compare sum of sums
		BNE x960			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x960			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x960:
	NOP
	JMP $9680				; next test
t960:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s968:
	STZ sum
	STZ chk
	LDX #0
l968:
		LDA sum
		CLC
		ADC t968, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l968
	CMP #CHKVALUE			; compare sum of sums
		BNE x968			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x968			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x968:
	INY						; this was odd half-page
	JMP $9700				; next test
t968:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s970:
	STZ sum
	STZ chk
	LDX #0
l970:
		LDA sum
		CLC
		ADC t970, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l970
	CMP #CHKVALUE			; compare sum of sums
		BNE x970			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x970			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x970:
	NOP
	JMP $9780				; next test
t970:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s978:
	STZ sum
	STZ chk
	LDX #0
l978:
		LDA sum
		CLC
		ADC t978, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l978
	CMP #CHKVALUE			; compare sum of sums
		BNE x978			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x978			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x978:
	INY						; this was odd half-page
	JMP $9800				; next test
t978:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s980:
	STZ sum
	STZ chk
	LDX #0
l980:
		LDA sum
		CLC
		ADC t980, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l980
	CMP #CHKVALUE			; compare sum of sums
		BNE x980			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x980			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x980:
	NOP
	JMP $9880				; next test
t980:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s988:
	STZ sum
	STZ chk
	LDX #0
l988:
		LDA sum
		CLC
		ADC t988, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l988
	CMP #CHKVALUE			; compare sum of sums
		BNE x988			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x988			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x988:
	INY						; this was odd half-page
	JMP $9900				; next test
t988:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s990:
	STZ sum
	STZ chk
	LDX #0
l990:
		LDA sum
		CLC
		ADC t990, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l990
	CMP #CHKVALUE			; compare sum of sums
		BNE x990			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x990			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x990:
	NOP
	JMP $9980				; next test
t990:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s998:
	STZ sum
	STZ chk
	LDX #0
l998:
		LDA sum
		CLC
		ADC t998, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l998
	CMP #CHKVALUE			; compare sum of sums
		BNE x998			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x998			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x998:
	INY						; this was odd half-page
	JMP $9A00				; next test
t998:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s9A0:
	STZ sum
	STZ chk
	LDX #0
l9A0:
		LDA sum
		CLC
		ADC t9A0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l9A0
	CMP #CHKVALUE			; compare sum of sums
		BNE x9A0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x9A0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x9A0:
	NOP
	JMP $9A80				; next test
t9A0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s9A8:
	STZ sum
	STZ chk
	LDX #0
l9A8:
		LDA sum
		CLC
		ADC t9A8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l9A8
	CMP #CHKVALUE			; compare sum of sums
		BNE x9A8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x9A8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x9A8:
	INY						; this was odd half-page
	JMP $9B00				; next test
t9A8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s9B0:
	STZ sum
	STZ chk
	LDX #0
l9B0:
		LDA sum
		CLC
		ADC t9B0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l9B0
	CMP #CHKVALUE			; compare sum of sums
		BNE x9B0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x9B0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x9B0:
	NOP
	JMP $9B80				; next test
t9B0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s9B8:
	STZ sum
	STZ chk
	LDX #0
l9B8:
		LDA sum
		CLC
		ADC t9B8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l9B8
	CMP #CHKVALUE			; compare sum of sums
		BNE x9B8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x9B8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x9B8:
	INY						; this was odd half-page
	JMP $9C00				; next test
t9B8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s9C0:
	STZ sum
	STZ chk
	LDX #0
l9C0:
		LDA sum
		CLC
		ADC t9C0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l9C0
	CMP #CHKVALUE			; compare sum of sums
		BNE x9C0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x9C0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x9C0:
	NOP
	JMP $9C80				; next test
t9C0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s9C8:
	STZ sum
	STZ chk
	LDX #0
l9C8:
		LDA sum
		CLC
		ADC t9C8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l9C8
	CMP #CHKVALUE			; compare sum of sums
		BNE x9C8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x9C8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x9C8:
	INY						; this was odd half-page
	JMP $9D00				; next test
t9C8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s9D0:
	STZ sum
	STZ chk
	LDX #0
l9D0:
		LDA sum
		CLC
		ADC t9D0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l9D0
	CMP #CHKVALUE			; compare sum of sums
		BNE x9D0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x9D0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x9D0:
	NOP
	JMP $9D80				; next test
t9D0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s9D8:
	STZ sum
	STZ chk
	LDX #0
l9D8:
		LDA sum
		CLC
		ADC t9D8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l9D8
	CMP #CHKVALUE			; compare sum of sums
		BNE x9D8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x9D8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x9D8:
	INY						; this was odd half-page
	JMP $9E00				; next test
t9D8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s9E0:
	STZ sum
	STZ chk
	LDX #0
l9E0:
		LDA sum
		CLC
		ADC t9E0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l9E0
	CMP #CHKVALUE			; compare sum of sums
		BNE x9E0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x9E0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x9E0:
	NOP
	JMP $9E80				; next test
t9E0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s9E8:
	STZ sum
	STZ chk
	LDX #0
l9E8:
		LDA sum
		CLC
		ADC t9E8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l9E8
	CMP #CHKVALUE			; compare sum of sums
		BNE x9E8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x9E8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x9E8:
	INY						; this was odd half-page
	JMP $9F00				; next test
t9E8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s9F0:
	STZ sum
	STZ chk
	LDX #0
l9F0:
		LDA sum
		CLC
		ADC t9F0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l9F0
	CMP #CHKVALUE			; compare sum of sums
		BNE x9F0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x9F0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
x9F0:
	NOP
	JMP $9F80				; next test
t9F0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
s9F8:
	STZ sum
	STZ chk
	LDX #0
l9F8:
		LDA sum
		CLC
		ADC t9F8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE l9F8
	CMP #CHKVALUE			; compare sum of sums
		BNE x9F8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE x9F8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
x9F8:
	INY						; this was odd half-page
	JMP $A000				; next test
t9F8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87

; $Axxx

; *** test code ***
sA00:
	STZ sum
	STZ chk
	LDX #0
lA00:
		LDA sum
		CLC
		ADC tA00, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lA00
	CMP #CHKVALUE			; compare sum of sums
		BNE xA00			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xA00			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xA00:
	NOP
	JMP $A280				; next test
tA00:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sA08:
	STZ sum
	STZ chk
	LDX #0
lA08:
		LDA sum
		CLC
		ADC tA08, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lA08
	CMP #CHKVALUE			; compare sum of sums
		BNE xA08			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xA08			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xA08:
	INY						; this was odd half-page
	JMP $A300				; next test
tA08:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sA10:
	STZ sum
	STZ chk
	LDX #0
lA10:
		LDA sum
		CLC
		ADC tA10, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lA10
	CMP #CHKVALUE			; compare sum of sums
		BNE xA10			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xA10			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xA10:
	NOP
	JMP $A380				; next test
tA10:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sA18:
	STZ sum
	STZ chk
	LDX #0
lA18:
		LDA sum
		CLC
		ADC tA18, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lA18
	CMP #CHKVALUE			; compare sum of sums
		BNE xA18			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xA18			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xA18:
	INY						; this was odd half-page
	JMP $A200				; next test
tA18:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sA20:
	STZ sum
	STZ chk
	LDX #0
lA20:
		LDA sum
		CLC
		ADC tA20, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lA20
	CMP #CHKVALUE			; compare sum of sums
		BNE xA20			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xA20			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xA20:
	NOP
	JMP $A280				; next test
tA20:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sA28:
	STZ sum
	STZ chk
	LDX #0
lA28:
		LDA sum
		CLC
		ADC tA28, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lA28
	CMP #CHKVALUE			; compare sum of sums
		BNE xA28			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xA28			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xA28:
	INY						; this was odd half-page
	JMP $A300				; next test
tA28:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sA30:
	STZ sum
	STZ chk
	LDX #0
lA30:
		LDA sum
		CLC
		ADC tA30, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lA30
	CMP #CHKVALUE			; compare sum of sums
		BNE xA30			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xA30			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xA30:
	NOP
	JMP $A380				; next test
tA30:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sA38:
	STZ sum
	STZ chk
	LDX #0
lA38:
		LDA sum
		CLC
		ADC tA38, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lA38
	CMP #CHKVALUE			; compare sum of sums
		BNE xA38			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xA38			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xA38:
	INY						; this was odd half-page
	JMP $A400				; next test
tA38:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sA40:
	STZ sum
	STZ chk
	LDX #0
lA40:
		LDA sum
		CLC
		ADC tA40, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lA40
	CMP #CHKVALUE			; compare sum of sums
		BNE xA40			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xA40			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xA40:
	NOP
	JMP $A480				; next test
tA40:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sA48:
	STZ sum
	STZ chk
	LDX #0
lA48:
		LDA sum
		CLC
		ADC tA48, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lA48
	CMP #CHKVALUE			; compare sum of sums
		BNE xA48			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xA48			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xA48:
	INY						; this was odd half-page
	JMP $A500				; next test
tA48:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sA50:
	STZ sum
	STZ chk
	LDX #0
lA50:
		LDA sum
		CLC
		ADC tA50, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lA50
	CMP #CHKVALUE			; compare sum of sums
		BNE xA50			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xA50			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xA50:
	NOP
	JMP $A580				; next test
tA50:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sA58:
	STZ sum
	STZ chk
	LDX #0
lA58:
		LDA sum
		CLC
		ADC tA58, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lA58
	CMP #CHKVALUE			; compare sum of sums
		BNE xA58			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xA58			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xA58:
	INY						; this was odd half-page
	JMP $A600				; next test
tA58:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sA60:
	STZ sum
	STZ chk
	LDX #0
lA60:
		LDA sum
		CLC
		ADC tA60, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lA60
	CMP #CHKVALUE			; compare sum of sums
		BNE xA60			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xA60			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xA60:
	NOP
	JMP $A680				; next test
tA60:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sA68:
	STZ sum
	STZ chk
	LDX #0
lA68:
		LDA sum
		CLC
		ADC tA68, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lA68
	CMP #CHKVALUE			; compare sum of sums
		BNE xA68			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xA68			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xA68:
	INY						; this was odd half-page
	JMP $A700				; next test
tA68:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sA70:
	STZ sum
	STZ chk
	LDX #0
lA70:
		LDA sum
		CLC
		ADC tA70, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lA70
	CMP #CHKVALUE			; compare sum of sums
		BNE xA70			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xA70			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xA70:
	NOP
	JMP $A780				; next test
tA70:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sA78:
	STZ sum
	STZ chk
	LDX #0
lA78:
		LDA sum
		CLC
		ADC tA78, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lA78
	CMP #CHKVALUE			; compare sum of sums
		BNE xA78			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xA78			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xA78:
	INY						; this was odd half-page
	JMP $A800				; next test
tA78:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sA80:
	STZ sum
	STZ chk
	LDX #0
lA80:
		LDA sum
		CLC
		ADC tA80, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lA80
	CMP #CHKVALUE			; compare sum of sums
		BNE xA80			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xA80			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xA80:
	NOP
	JMP $A880				; next test
tA80:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sA88:
	STZ sum
	STZ chk
	LDX #0
lA88:
		LDA sum
		CLC
		ADC tA88, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lA88
	CMP #CHKVALUE			; compare sum of sums
		BNE xA88			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xA88			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xA88:
	INY						; this was odd half-page
	JMP $A900				; next test
tA88:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sA90:
	STZ sum
	STZ chk
	LDX #0
lA90:
		LDA sum
		CLC
		ADC tA90, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lA90
	CMP #CHKVALUE			; compare sum of sums
		BNE xA90			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xA90			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xA90:
	NOP
	JMP $A980				; next test
tA90:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sA98:
	STZ sum
	STZ chk
	LDX #0
lA98:
		LDA sum
		CLC
		ADC tA98, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lA98
	CMP #CHKVALUE			; compare sum of sums
		BNE xA98			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xA98			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xA98:
	INY						; this was odd half-page
	JMP $AA00				; next test
tA98:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sAA0:
	STZ sum
	STZ chk
	LDX #0
lAA0:
		LDA sum
		CLC
		ADC tAA0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lAA0
	CMP #CHKVALUE			; compare sum of sums
		BNE xAA0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xAA0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xAA0:
	NOP
	JMP $AA80				; next test
tAA0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sAA8:
	STZ sum
	STZ chk
	LDX #0
lAA8:
		LDA sum
		CLC
		ADC tAA8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lAA8
	CMP #CHKVALUE			; compare sum of sums
		BNE xAA8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xAA8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xAA8:
	INY						; this was odd half-page
	JMP $AB00				; next test
tAA8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sAB0:
	STZ sum
	STZ chk
	LDX #0
lAB0:
		LDA sum
		CLC
		ADC tAB0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lAB0
	CMP #CHKVALUE			; compare sum of sums
		BNE xAB0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xAB0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xAB0:
	NOP
	JMP $AB80				; next test
tAB0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sAB8:
	STZ sum
	STZ chk
	LDX #0
lAB8:
		LDA sum
		CLC
		ADC tAB8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lAB8
	CMP #CHKVALUE			; compare sum of sums
		BNE xAB8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xAB8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xAB8:
	INY						; this was odd half-page
	JMP $AC00				; next test
tAB8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sAC0:
	STZ sum
	STZ chk
	LDX #0
lAC0:
		LDA sum
		CLC
		ADC tAC0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lAC0
	CMP #CHKVALUE			; compare sum of sums
		BNE xAC0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xAC0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xAC0:
	NOP
	JMP $AC80				; next test
tAC0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sAC8:
	STZ sum
	STZ chk
	LDX #0
lAC8:
		LDA sum
		CLC
		ADC tAC8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lAC8
	CMP #CHKVALUE			; compare sum of sums
		BNE xAC8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xAC8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xAC8:
	INY						; this was odd half-page
	JMP $AD00				; next test
tAC8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sAD0:
	STZ sum
	STZ chk
	LDX #0
lAD0:
		LDA sum
		CLC
		ADC tAD0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lAD0
	CMP #CHKVALUE			; compare sum of sums
		BNE xAD0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xAD0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xAD0:
	NOP
	JMP $AD80				; next test
tAD0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sAD8:
	STZ sum
	STZ chk
	LDX #0
lAD8:
		LDA sum
		CLC
		ADC tAD8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lAD8
	CMP #CHKVALUE			; compare sum of sums
		BNE xAD8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xAD8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xAD8:
	INY						; this was odd half-page
	JMP $AE00				; next test
tAD8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sAE0:
	STZ sum
	STZ chk
	LDX #0
lAE0:
		LDA sum
		CLC
		ADC tAE0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lAE0
	CMP #CHKVALUE			; compare sum of sums
		BNE xAE0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xAE0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xAE0:
	NOP
	JMP $AE80				; next test
tAE0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sAE8:
	STZ sum
	STZ chk
	LDX #0
lAE8:
		LDA sum
		CLC
		ADC tAE8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lAE8
	CMP #CHKVALUE			; compare sum of sums
		BNE xAE8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xAE8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xAE8:
	INY						; this was odd half-page
	JMP $AF00				; next test
tAE8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sAF0:
	STZ sum
	STZ chk
	LDX #0
lAF0:
		LDA sum
		CLC
		ADC tAF0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lAF0
	CMP #CHKVALUE			; compare sum of sums
		BNE xAF0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xAF0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xAF0:
	NOP
	JMP $AF80				; next test
tAF0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sAF8:
	STZ sum
	STZ chk
	LDX #0
lAF8:
		LDA sum
		CLC
		ADC tAF8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of table
		BNE lAF8
	CMP #CHKVALUE			; compare sum of sums
		BNE xAF8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xAF8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xAF8:
	INY						; this was odd half-page
	JMP $B000				; next test
tAF8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87

; $Bxxx

; *** test code ***
sB00:
	STZ sum
	STZ chk
	LDX #0
lB00:
		LDA sum
		CLC
		ADC tB00, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lB00
	CMP #CHKVALUE			; compare sum of sums
		BNE xB00			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xB00			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xB00:
	NOP
	JMP $B280				; next test
tB00:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sB08:
	STZ sum
	STZ chk
	LDX #0
lB08:
		LDA sum
		CLC
		ADC tB08, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lB08
	CMP #CHKVALUE			; compare sum of sums
		BNE xB08			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xB08			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xB08:
	INY						; this was odd half-page
	JMP $B300				; next test
tB08:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sB10:
	STZ sum
	STZ chk
	LDX #0
lB10:
		LDA sum
		CLC
		ADC tB10, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lB10
	CMP #CHKVALUE			; compare sum of sums
		BNE xB10			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xB10			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xB10:
	NOP
	JMP $B380				; next test
tB10:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sB18:
	STZ sum
	STZ chk
	LDX #0
lB18:
		LDA sum
		CLC
		ADC tB18, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lB18
	CMP #CHKVALUE			; compare sum of sums
		BNE xB18			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xB18			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xB18:
	INY						; this was odd half-page
	JMP $B200				; next test
tB18:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sB20:
	STZ sum
	STZ chk
	LDX #0
lB20:
		LDA sum
		CLC
		ADC tB20, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lB20
	CMP #CHKVALUE			; compare sum of sums
		BNE xB20			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xB20			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xB20:
	NOP
	JMP $B280				; next test
tB20:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sB28:
	STZ sum
	STZ chk
	LDX #0
lB28:
		LDA sum
		CLC
		ADC tB28, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lB28
	CMP #CHKVALUE			; compare sum of sums
		BNE xB28			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xB28			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xB28:
	INY						; this was odd half-page
	JMP $B300				; next test
tB28:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sB30:
	STZ sum
	STZ chk
	LDX #0
lB30:
		LDA sum
		CLC
		ADC tB30, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lB30
	CMP #CHKVALUE			; compare sum of sums
		BNE xB30			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xB30			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xB30:
	NOP
	JMP $B380				; next test
tB30:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sB38:
	STZ sum
	STZ chk
	LDX #0
lB38:
		LDA sum
		CLC
		ADC tB38, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lB38
	CMP #CHKVALUE			; compare sum of sums
		BNE xB38			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xB38			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xB38:
	INY						; this was odd half-page
	JMP $B400				; next test
tB38:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sB40:
	STZ sum
	STZ chk
	LDX #0
lB40:
		LDA sum
		CLC
		ADC tB40, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lB40
	CMP #CHKVALUE			; compare sum of sums
		BNE xB40			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xB40			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xB40:
	NOP
	JMP $B480				; next test
tB40:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sB48:
	STZ sum
	STZ chk
	LDX #0
lB48:
		LDA sum
		CLC
		ADC tB48, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lB48
	CMP #CHKVALUE			; compare sum of sums
		BNE xB48			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xB48			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xB48:
	INY						; this was odd half-page
	JMP $B500				; next test
tB48:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sB50:
	STZ sum
	STZ chk
	LDX #0
lB50:
		LDA sum
		CLC
		ADC tB50, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lB50
	CMP #CHKVALUE			; compare sum of sums
		BNE xB50			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xB50			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xB50:
	NOP
	JMP $B580				; next test
tB50:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sB58:
	STZ sum
	STZ chk
	LDX #0
lB58:
		LDA sum
		CLC
		ADC tB58, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lB58
	CMP #CHKVALUE			; compare sum of sums
		BNE xB58			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xB58			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xB58:
	INY						; this was odd half-page
	JMP $B600				; next test
tB58:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sB60:
	STZ sum
	STZ chk
	LDX #0
lB60:
		LDA sum
		CLC
		ADC tB60, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lB60
	CMP #CHKVALUE			; compare sum of sums
		BNE xB60			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xB60			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xB60:
	NOP
	JMP $B680				; next test
tB60:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sB68:
	STZ sum
	STZ chk
	LDX #0
lB68:
		LDA sum
		CLC
		ADC tB68, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lB68
	CMP #CHKVALUE			; compare sum of sums
		BNE xB68			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xB68			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xB68:
	INY						; this was odd half-page
	JMP $B700				; next test
tB68:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sB70:
	STZ sum
	STZ chk
	LDX #0
lB70:
		LDA sum
		CLC
		ADC tB70, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lB70
	CMP #CHKVALUE			; compare sum of sums
		BNE xB70			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xB70			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xB70:
	NOP
	JMP $B780				; next test
tB70:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sB78:
	STZ sum
	STZ chk
	LDX #0
lB78:
		LDA sum
		CLC
		ADC tB78, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lB78
	CMP #CHKVALUE			; compare sum of sums
		BNE xB78			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xB78			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xB78:
	INY						; this was odd half-page
	JMP $B800				; next test
tB78:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sB80:
	STZ sum
	STZ chk
	LDX #0
lB80:
		LDA sum
		CLC
		ADC tB80, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lB80
	CMP #CHKVALUE			; compare sum of sums
		BNE xB80			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xB80			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xB80:
	NOP
	JMP $B880				; next test
tB80:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sB88:
	STZ sum
	STZ chk
	LDX #0
lB88:
		LDA sum
		CLC
		ADC tB88, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lB88
	CMP #CHKVALUE			; compare sum of sums
		BNE xB88			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xB88			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xB88:
	INY						; this was odd half-page
	JMP $B900				; next test
tB88:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sB90:
	STZ sum
	STZ chk
	LDX #0
lB90:
		LDA sum
		CLC
		ADC tB90, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lB90
	CMP #CHKVALUE			; compare sum of sums
		BNE xB90			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xB90			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xB90:
	NOP
	JMP $B980				; next test
tB90:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sB98:
	STZ sum
	STZ chk
	LDX #0
lB98:
		LDA sum
		CLC
		ADC tB98, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lB98
	CMP #CHKVALUE			; compare sum of sums
		BNE xB98			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xB98			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xB98:
	INY						; this was odd half-page
	JMP $BA00				; next test
tB98:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sBA0:
	STZ sum
	STZ chk
	LDX #0
lBA0:
		LDA sum
		CLC
		ADC tBA0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lBA0
	CMP #CHKVALUE			; compare sum of sums
		BNE xBA0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xBA0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xBA0:
	NOP
	JMP $BA80				; next test
tBA0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sBA8:
	STZ sum
	STZ chk
	LDX #0
lBA8:
		LDA sum
		CLC
		ADC tBA8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lBA8
	CMP #CHKVALUE			; compare sum of sums
		BNE xBA8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xBA8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xBA8:
	INY						; this was odd half-page
	JMP $BB00				; next test
tBA8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sBB0:
	STZ sum
	STZ chk
	LDX #0
lBB0:
		LDA sum
		CLC
		ADC tBB0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lBB0
	CMP #CHKVALUE			; compare sum of sums
		BNE xBB0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xBB0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xBB0:
	NOP
	JMP $BB80				; next test
tBB0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sBB8:
	STZ sum
	STZ chk
	LDX #0
lBB8:
		LDA sum
		CLC
		ADC tBB8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lBB8
	CMP #CHKVALUE			; compare sum of sums
		BNE xBB8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xBB8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xBB8:
	INY						; this was odd half-page
	JMP $BC00				; next test
tBB8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sBC0:
	STZ sum
	STZ chk
	LDX #0
lBC0:
		LDA sum
		CLC
		ADC tBC0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lBC0
	CMP #CHKVALUE			; compare sum of sums
		BNE xBC0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xBC0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xBC0:
	NOP
	JMP $BC80				; next test
tBC0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sBC8:
	STZ sum
	STZ chk
	LDX #0
lBC8:
		LDA sum
		CLC
		ADC tBC8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lBC8
	CMP #CHKVALUE			; compare sum of sums
		BNE xBC8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xBC8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xBC8:
	INY						; this was odd half-page
	JMP $BD00				; next test
tBC8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sBD0:
	STZ sum
	STZ chk
	LDX #0
lBD0:
		LDA sum
		CLC
		ADC tBD0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lBD0
	CMP #CHKVALUE			; compare sum of sums
		BNE xBD0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xBD0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xBD0:
	NOP
	JMP $BD80				; next test
tBD0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sBD8:
	STZ sum
	STZ chk
	LDX #0
lBD8:
		LDA sum
		CLC
		ADC tBD8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lBD8
	CMP #CHKVALUE			; compare sum of sums
		BNE xBD8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xBD8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xBD8:
	INY						; this was odd half-page
	JMP $BE00				; next test
tBD8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sBE0:
	STZ sum
	STZ chk
	LDX #0
lBE0:
		LDA sum
		CLC
		ADC tBE0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lBE0
	CMP #CHKVALUE			; compare sum of sums
		BNE xBE0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xBE0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xBE0:
	NOP
	JMP $BE80				; next test
tBE0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sBE8:
	STZ sum
	STZ chk
	LDX #0
lBE8:
		LDA sum
		CLC
		ADC tBE8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lBE8
	CMP #CHKVALUE			; compare sum of sums
		BNE xBE8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xBE8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xBE8:
	INY						; this was odd half-page
	JMP $BF00				; next test
tBE8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sBF0:
	STZ sum
	STZ chk
	LDX #0
lBF0:
		LDA sum
		CLC
		ADC tBF0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lBF0
	CMP #CHKVALUE			; compare sum of sums
		BNE xBF0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xBF0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xBF0:
	NOP
	JMP $BF80				; next test
tBF0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sBF8:
	STZ sum
	STZ chk
	LDX #0
lBF8:
		LDA sum
		CLC
		ADC tBF8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tBble
		BNE lBF8
	CMP #CHKVALUE			; compare sum of sums
		BNE xBF8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xBF8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xBF8:
	INY						; this was odd half-page
	JMP $C000				; next test
tBF8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87

; $Cxxx

; *** test code ***
sC00:
	STZ sum
	STZ chk
	LDX #0
lC00:
		LDA sum
		CLC
		ADC tC00, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lC00
	CMP #CHKVALUE			; compare sum of sums
		BNE xC00			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xC00			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xC00:
	NOP
	JMP $C280				; next test
tC00:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sC08:
	STZ sum
	STZ chk
	LDX #0
lC08:
		LDA sum
		CLC
		ADC tC08, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lC08
	CMP #CHKVALUE			; compare sum of sums
		BNE xC08			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xC08			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xC08:
	INY						; this was odd half-page
	JMP $C300				; next test
tC08:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sC10:
	STZ sum
	STZ chk
	LDX #0
lC10:
		LDA sum
		CLC
		ADC tC10, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lC10
	CMP #CHKVALUE			; compare sum of sums
		BNE xC10			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xC10			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xC10:
	NOP
	JMP $C380				; next test
tC10:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sC18:
	STZ sum
	STZ chk
	LDX #0
lC18:
		LDA sum
		CLC
		ADC tC18, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lC18
	CMP #CHKVALUE			; compare sum of sums
		BNE xC18			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xC18			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xC18:
	INY						; this was odd half-page
	JMP $C200				; next test
tC18:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sC20:
	STZ sum
	STZ chk
	LDX #0
lC20:
		LDA sum
		CLC
		ADC tC20, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lC20
	CMP #CHKVALUE			; compare sum of sums
		BNE xC20			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xC20			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xC20:
	NOP
	JMP $C280				; next test
tC20:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sC28:
	STZ sum
	STZ chk
	LDX #0
lC28:
		LDA sum
		CLC
		ADC tC28, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lC28
	CMP #CHKVALUE			; compare sum of sums
		BNE xC28			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xC28			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xC28:
	INY						; this was odd half-page
	JMP $C300				; next test
tC28:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sC30:
	STZ sum
	STZ chk
	LDX #0
lC30:
		LDA sum
		CLC
		ADC tC30, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lC30
	CMP #CHKVALUE			; compare sum of sums
		BNE xC30			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xC30			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xC30:
	NOP
	JMP $C380				; next test
tC30:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sC38:
	STZ sum
	STZ chk
	LDX #0
lC38:
		LDA sum
		CLC
		ADC tC38, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lC38
	CMP #CHKVALUE			; compare sum of sums
		BNE xC38			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xC38			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xC38:
	INY						; this was odd half-page
	JMP $C400				; next test
tC38:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sC40:
	STZ sum
	STZ chk
	LDX #0
lC40:
		LDA sum
		CLC
		ADC tC40, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lC40
	CMP #CHKVALUE			; compare sum of sums
		BNE xC40			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xC40			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xC40:
	NOP
	JMP $C480				; next test
tC40:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sC48:
	STZ sum
	STZ chk
	LDX #0
lC48:
		LDA sum
		CLC
		ADC tC48, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lC48
	CMP #CHKVALUE			; compare sum of sums
		BNE xC48			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xC48			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xC48:
	INY						; this was odd half-page
	JMP $C500				; next test
tC48:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sC50:
	STZ sum
	STZ chk
	LDX #0
lC50:
		LDA sum
		CLC
		ADC tC50, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lC50
	CMP #CHKVALUE			; compare sum of sums
		BNE xC50			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xC50			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xC50:
	NOP
	JMP $C580				; next test
tC50:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sC58:
	STZ sum
	STZ chk
	LDX #0
lC58:
		LDA sum
		CLC
		ADC tC58, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lC58
	CMP #CHKVALUE			; compare sum of sums
		BNE xC58			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xC58			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xC58:
	INY						; this was odd half-page
	JMP $C600				; next test
tC58:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sC60:
	STZ sum
	STZ chk
	LDX #0
lC60:
		LDA sum
		CLC
		ADC tC60, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lC60
	CMP #CHKVALUE			; compare sum of sums
		BNE xC60			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xC60			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xC60:
	NOP
	JMP $C680				; next test
tC60:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sC68:
	STZ sum
	STZ chk
	LDX #0
lC68:
		LDA sum
		CLC
		ADC tC68, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lC68
	CMP #CHKVALUE			; compare sum of sums
		BNE xC68			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xC68			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xC68:
	INY						; this was odd half-page
	JMP $C700				; next test
tC68:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sC70:
	STZ sum
	STZ chk
	LDX #0
lC70:
		LDA sum
		CLC
		ADC tC70, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lC70
	CMP #CHKVALUE			; compare sum of sums
		BNE xC70			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xC70			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xC70:
	NOP
	JMP $C780				; next test
tC70:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sC78:
	STZ sum
	STZ chk
	LDX #0
lC78:
		LDA sum
		CLC
		ADC tC78, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lC78
	CMP #CHKVALUE			; compare sum of sums
		BNE xC78			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xC78			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xC78:
	INY						; this was odd half-page
	JMP $C800				; next test
tC78:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sC80:
	STZ sum
	STZ chk
	LDX #0
lC80:
		LDA sum
		CLC
		ADC tC80, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lC80
	CMP #CHKVALUE			; compare sum of sums
		BNE xC80			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xC80			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xC80:
	NOP
	JMP $C880				; next test
tC80:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sC88:
	STZ sum
	STZ chk
	LDX #0
lC88:
		LDA sum
		CLC
		ADC tC88, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lC88
	CMP #CHKVALUE			; compare sum of sums
		BNE xC88			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xC88			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xC88:
	INY						; this was odd half-page
	JMP $C900				; next test
tC88:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sC90:
	STZ sum
	STZ chk
	LDX #0
lC90:
		LDA sum
		CLC
		ADC tC90, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lC90
	CMP #CHKVALUE			; compare sum of sums
		BNE xC90			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xC90			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xC90:
	NOP
	JMP $C980				; next test
tC90:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sC98:
	STZ sum
	STZ chk
	LDX #0
lC98:
		LDA sum
		CLC
		ADC tC98, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lC98
	CMP #CHKVALUE			; compare sum of sums
		BNE xC98			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xC98			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xC98:
	INY						; this was odd half-page
	JMP $CA00				; next test
tC98:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sCA0:
	STZ sum
	STZ chk
	LDX #0
lCA0:
		LDA sum
		CLC
		ADC tCA0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lCA0
	CMP #CHKVALUE			; compare sum of sums
		BNE xCA0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xCA0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xCA0:
	NOP
	JMP $CA80				; next test
tCA0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sCA8:
	STZ sum
	STZ chk
	LDX #0
lCA8:
		LDA sum
		CLC
		ADC tCA8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lCA8
	CMP #CHKVALUE			; compare sum of sums
		BNE xCA8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xCA8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xCA8:
	INY						; this was odd half-page
	JMP $CB00				; next test
tCA8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sCB0:
	STZ sum
	STZ chk
	LDX #0
lCB0:
		LDA sum
		CLC
		ADC tCB0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lCB0
	CMP #CHKVALUE			; compare sum of sums
		BNE xCB0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xCB0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xCB0:
	NOP
	JMP $CB80				; next test
tCB0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sCB8:
	STZ sum
	STZ chk
	LDX #0
lCB8:
		LDA sum
		CLC
		ADC tCB8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lCB8
	CMP #CHKVALUE			; compare sum of sums
		BNE xCB8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xCB8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xCB8:
	INY						; this was odd half-page
	JMP $CC00				; next test
tCB8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sCC0:
	STZ sum
	STZ chk
	LDX #0
lCC0:
		LDA sum
		CLC
		ADC tCC0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lCC0
	CMP #CHKVALUE			; compare sum of sums
		BNE xCC0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xCC0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xCC0:
	NOP
	JMP $CC80				; next test
tCC0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sCC8:
	STZ sum
	STZ chk
	LDX #0
lCC8:
		LDA sum
		CLC
		ADC tCC8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lCC8
	CMP #CHKVALUE			; compare sum of sums
		BNE xCC8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xCC8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xCC8:
	INY						; this was odd half-page
	JMP $CD00				; next test
tCC8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sCD0:
	STZ sum
	STZ chk
	LDX #0
lCD0:
		LDA sum
		CLC
		ADC tCD0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lCD0
	CMP #CHKVALUE			; compare sum of sums
		BNE xCD0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xCD0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xCD0:
	NOP
	JMP $CD80				; next test
tCD0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sCD8:
	STZ sum
	STZ chk
	LDX #0
lCD8:
		LDA sum
		CLC
		ADC tCD8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lCD8
	CMP #CHKVALUE			; compare sum of sums
		BNE xCD8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xCD8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xCD8:
	INY						; this was odd half-page
	JMP $CE00				; next test
tCD8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sCE0:
	STZ sum
	STZ chk
	LDX #0
lCE0:
		LDA sum
		CLC
		ADC tCE0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lCE0
	CMP #CHKVALUE			; compare sum of sums
		BNE xCE0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xCE0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xCE0:
	NOP
	JMP $CE80				; next test
tCE0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sCE8:
	STZ sum
	STZ chk
	LDX #0
lCE8:
		LDA sum
		CLC
		ADC tCE8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lCE8
	CMP #CHKVALUE			; compare sum of sums
		BNE xCE8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xCE8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xCE8:
	INY						; this was odd half-page
	JMP $CF00				; next test
tCE8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sCF0:
	STZ sum
	STZ chk
	LDX #0
lCF0:
		LDA sum
		CLC
		ADC tCF0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lCF0
	CMP #CHKVALUE			; compare sum of sums
		BNE xCF0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xCF0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xCF0:
	NOP
	JMP $CF80				; next test
tCF0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sCF8:
	STZ sum
	STZ chk
	LDX #0
lCF8:
		LDA sum
		CLC
		ADC tCF8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tCble
		BNE lCF8
	CMP #CHKVALUE			; compare sum of sums
		BNE xCF8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xCF8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xCF8:
	INY						; this was odd half-page
	JMP $D000				; next test
tCF8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87

; Dxxx

; *** test code ***
sD00:
	STZ sum
	STZ chk
	LDX #0
lD00:
		LDA sum
		CLC
		ADC tD00, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lD00
	CMP #CHKVALUE			; compare sum of sums
		BNE xD00			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xD00			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xD00:
	NOP
	JMP $D280				; next test
tD00:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sD08:
	STZ sum
	STZ chk
	LDX #0
lD08:
		LDA sum
		CLC
		ADC tD08, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lD08
	CMP #CHKVALUE			; compare sum of sums
		BNE xD08			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xD08			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xD08:
	INY						; this was odd half-page
	JMP $D300				; next test
tD08:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sD10:
	STZ sum
	STZ chk
	LDX #0
lD10:
		LDA sum
		CLC
		ADC tD10, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lD10
	CMP #CHKVALUE			; compare sum of sums
		BNE xD10			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xD10			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xD10:
	NOP
	JMP $D380				; next test
tD10:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sD18:
	STZ sum
	STZ chk
	LDX #0
lD18:
		LDA sum
		CLC
		ADC tD18, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lD18
	CMP #CHKVALUE			; compare sum of sums
		BNE xD18			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xD18			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xD18:
	INY						; this was odd half-page
	JMP $D200				; next test
tD18:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sD20:
	STZ sum
	STZ chk
	LDX #0
lD20:
		LDA sum
		CLC
		ADC tD20, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lD20
	CMP #CHKVALUE			; compare sum of sums
		BNE xD20			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xD20			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xD20:
	NOP
	JMP $D280				; next test
tD20:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sD28:
	STZ sum
	STZ chk
	LDX #0
lD28:
		LDA sum
		CLC
		ADC tD28, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lD28
	CMP #CHKVALUE			; compare sum of sums
		BNE xD28			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xD28			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xD28:
	INY						; this was odd half-page
	JMP $D300				; next test
tD28:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sD30:
	STZ sum
	STZ chk
	LDX #0
lD30:
		LDA sum
		CLC
		ADC tD30, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lD30
	CMP #CHKVALUE			; compare sum of sums
		BNE xD30			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xD30			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xD30:
	NOP
	JMP $D380				; next test
tD30:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sD38:
	STZ sum
	STZ chk
	LDX #0
lD38:
		LDA sum
		CLC
		ADC tD38, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lD38
	CMP #CHKVALUE			; compare sum of sums
		BNE xD38			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xD38			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xD38:
	INY						; this was odd half-page
	JMP $D400				; next test
tD38:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sD40:
	STZ sum
	STZ chk
	LDX #0
lD40:
		LDA sum
		CLC
		ADC tD40, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lD40
	CMP #CHKVALUE			; compare sum of sums
		BNE xD40			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xD40			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xD40:
	NOP
	JMP $D480				; next test
tD40:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sD48:
	STZ sum
	STZ chk
	LDX #0
lD48:
		LDA sum
		CLC
		ADC tD48, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lD48
	CMP #CHKVALUE			; compare sum of sums
		BNE xD48			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xD48			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xD48:
	INY						; this was odd half-page
	JMP $D500				; next test
tD48:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sD50:
	STZ sum
	STZ chk
	LDX #0
lD50:
		LDA sum
		CLC
		ADC tD50, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lD50
	CMP #CHKVALUE			; compare sum of sums
		BNE xD50			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xD50			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xD50:
	NOP
	JMP $D580				; next test
tD50:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sD58:
	STZ sum
	STZ chk
	LDX #0
lD58:
		LDA sum
		CLC
		ADC tD58, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lD58
	CMP #CHKVALUE			; compare sum of sums
		BNE xD58			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xD58			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xD58:
	INY						; this was odd half-page
	JMP $D600				; next test
tD58:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sD60:
	STZ sum
	STZ chk
	LDX #0
lD60:
		LDA sum
		CLC
		ADC tD60, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lD60
	CMP #CHKVALUE			; compare sum of sums
		BNE xD60			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xD60			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xD60:
	NOP
	JMP $D680				; next test
tD60:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sD68:
	STZ sum
	STZ chk
	LDX #0
lD68:
		LDA sum
		CLC
		ADC tD68, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lD68
	CMP #CHKVALUE			; compare sum of sums
		BNE xD68			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xD68			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xD68:
	INY						; this was odd half-page
	JMP $D700				; next test
tD68:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sD70:
	STZ sum
	STZ chk
	LDX #0
lD70:
		LDA sum
		CLC
		ADC tD70, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lD70
	CMP #CHKVALUE			; compare sum of sums
		BNE xD70			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xD70			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xD70:
	NOP
	JMP $D780				; next test
tD70:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sD78:
	STZ sum
	STZ chk
	LDX #0
lD78:
		LDA sum
		CLC
		ADC tD78, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lD78
	CMP #CHKVALUE			; compare sum of sums
		BNE xD78			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xD78			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xD78:
	INY						; this was odd half-page
	JMP $D800				; next test
tD78:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sD80:
	STZ sum
	STZ chk
	LDX #0
lD80:
		LDA sum
		CLC
		ADC tD80, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lD80
	CMP #CHKVALUE			; compare sum of sums
		BNE xD80			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xD80			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xD80:
	NOP
	JMP $D880				; next test
tD80:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sD88:
	STZ sum
	STZ chk
	LDX #0
lD88:
		LDA sum
		CLC
		ADC tD88, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lD88
	CMP #CHKVALUE			; compare sum of sums
		BNE xD88			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xD88			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xD88:
	INY						; this was odd half-page
	JMP $D900				; next test
tD88:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sD90:
	STZ sum
	STZ chk
	LDX #0
lD90:
		LDA sum
		CLC
		ADC tD90, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lD90
	CMP #CHKVALUE			; compare sum of sums
		BNE xD90			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xD90			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xD90:
	NOP
	JMP $D980				; next test
tD90:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sD98:
	STZ sum
	STZ chk
	LDX #0
lD98:
		LDA sum
		CLC
		ADC tD98, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lD98
	CMP #CHKVALUE			; compare sum of sums
		BNE xD98			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xD98			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xD98:
	INY						; this was odd half-page
	JMP $DA00				; next test
tD98:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sDA0:
	STZ sum
	STZ chk
	LDX #0
lDA0:
		LDA sum
		CLC
		ADC tDA0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lDA0
	CMP #CHKVALUE			; compare sum of sums
		BNE xDA0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xDA0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xDA0:
	NOP
	JMP $DA80				; next test
tDA0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sDA8:
	STZ sum
	STZ chk
	LDX #0
lDA8:
		LDA sum
		CLC
		ADC tDA8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lDA8
	CMP #CHKVALUE			; compare sum of sums
		BNE xDA8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xDA8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xDA8:
	INY						; this was odd half-page
	JMP $DB00				; next test
tDA8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sDB0:
	STZ sum
	STZ chk
	LDX #0
lDB0:
		LDA sum
		CLC
		ADC tDB0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lDB0
	CMP #CHKVALUE			; compare sum of sums
		BNE xDB0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xDB0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xDB0:
	NOP
	JMP $DB80				; next test
tDB0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sDB8:
	STZ sum
	STZ chk
	LDX #0
lDB8:
		LDA sum
		CLC
		ADC tDB8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lDB8
	CMP #CHKVALUE			; compare sum of sums
		BNE xDB8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xDB8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xDB8:
	INY						; this was odd half-page
	JMP $DC00				; next test
tDB8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sDC0:
	STZ sum
	STZ chk
	LDX #0
lDC0:
		LDA sum
		CLC
		ADC tDC0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lDC0
	CMP #CHKVALUE			; compare sum of sums
		BNE xDC0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xDC0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xDC0:
	NOP
	JMP $DC80				; next test
tDC0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sDC8:
	STZ sum
	STZ chk
	LDX #0
lDC8:
		LDA sum
		CLC
		ADC tDC8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lDC8
	CMP #CHKVALUE			; compare sum of sums
		BNE xDC8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xDC8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xDC8:
	INY						; this was odd half-page
	JMP $DD00				; next test
tDC8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sDD0:
	STZ sum
	STZ chk
	LDX #0
lDD0:
		LDA sum
		CLC
		ADC tDD0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lDD0
	CMP #CHKVALUE			; compare sum of sums
		BNE xDD0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xDD0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xDD0:
	NOP
	JMP $DD80				; next test
tDD0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sDD8:
	STZ sum
	STZ chk
	LDX #0
lDD8:
		LDA sum
		CLC
		ADC tDD8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lDD8
	CMP #CHKVALUE			; compare sum of sums
		BNE xDD8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xDD8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xDD8:
	INY						; this was odd half-page
	JMP $DE00				; next test
tDD8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sDE0:
	STZ sum
	STZ chk
	LDX #0
lDE0:
		LDA sum
		CLC
		ADC tDE0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lDE0
	CMP #CHKVALUE			; compare sum of sums
		BNE xDE0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xDE0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xDE0:
	NOP
	JMP $DE80				; next test
tDE0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sDE8:
	STZ sum
	STZ chk
	LDX #0
lDE8:
		LDA sum
		CLC
		ADC tDE8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lDE8
	CMP #CHKVALUE			; compare sum of sums
		BNE xDE8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xDE8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xDE8:
	INY						; this was odd half-page
	JMP $DF00				; next test
tDE8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sDF0:
	STZ sum
	STZ chk
	LDX #0
lDF0:
		LDA sum
		CLC
		ADC tDF0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tDble
		BNE lDF0
	CMP #CHKVALUE			; compare sum of sums
		BNE xDF0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xDF0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xDF0:
	INY						; note this
	JMP $E000				; next test *** MUST skip I/O ***
tDF0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** must skip I/O ***
sDF8:
	.dsb	$E000-*, $FF	; padding until next test

; Exxx

; *** test code ***
sE00:
	STZ sum
	STZ chk
	LDX #0
lE00:
		LDA sum
		CLC
		ADC tE00, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lE00
	CMP #CHKVALUE			; compare sum of sums
		BNE xE00			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xE00			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xE00:
	NOP
	JMP $E280				; next test
tE00:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sE08:
	STZ sum
	STZ chk
	LDX #0
lE08:
		LDA sum
		CLC
		ADC tE08, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lE08
	CMP #CHKVALUE			; compare sum of sums
		BNE xE08			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xE08			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xE08:
	INY						; this was odd half-page
	JMP $E300				; next test
tE08:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sE10:
	STZ sum
	STZ chk
	LDX #0
lE10:
		LDA sum
		CLC
		ADC tE10, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lE10
	CMP #CHKVALUE			; compare sum of sums
		BNE xE10			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xE10			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xE10:
	NOP
	JMP $E380				; next test
tE10:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sE18:
	STZ sum
	STZ chk
	LDX #0
lE18:
		LDA sum
		CLC
		ADC tE18, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lE18
	CMP #CHKVALUE			; compare sum of sums
		BNE xE18			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xE18			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xE18:
	INY						; this was odd half-page
	JMP $E200				; next test
tE18:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sE20:
	STZ sum
	STZ chk
	LDX #0
lE20:
		LDA sum
		CLC
		ADC tE20, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lE20
	CMP #CHKVALUE			; compare sum of sums
		BNE xE20			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xE20			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xE20:
	NOP
	JMP $E280				; next test
tE20:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sE28:
	STZ sum
	STZ chk
	LDX #0
lE28:
		LDA sum
		CLC
		ADC tE28, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lE28
	CMP #CHKVALUE			; compare sum of sums
		BNE xE28			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xE28			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xE28:
	INY						; this was odd half-page
	JMP $E300				; next test
tE28:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sE30:
	STZ sum
	STZ chk
	LDX #0
lE30:
		LDA sum
		CLC
		ADC tE30, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lE30
	CMP #CHKVALUE			; compare sum of sums
		BNE xE30			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xE30			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xE30:
	NOP
	JMP $E380				; next test
tE30:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sE38:
	STZ sum
	STZ chk
	LDX #0
lE38:
		LDA sum
		CLC
		ADC tE38, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lE38
	CMP #CHKVALUE			; compare sum of sums
		BNE xE38			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xE38			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xE38:
	INY						; this was odd half-page
	JMP $E400				; next test
tE38:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sE40:
	STZ sum
	STZ chk
	LDX #0
lE40:
		LDA sum
		CLC
		ADC tE40, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lE40
	CMP #CHKVALUE			; compare sum of sums
		BNE xE40			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xE40			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xE40:
	NOP
	JMP $E480				; next test
tE40:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sE48:
	STZ sum
	STZ chk
	LDX #0
lE48:
		LDA sum
		CLC
		ADC tE48, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lE48
	CMP #CHKVALUE			; compare sum of sums
		BNE xE48			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xE48			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xE48:
	INY						; this was odd half-page
	JMP $E500				; next test
tE48:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sE50:
	STZ sum
	STZ chk
	LDX #0
lE50:
		LDA sum
		CLC
		ADC tE50, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lE50
	CMP #CHKVALUE			; compare sum of sums
		BNE xE50			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xE50			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xE50:
	NOP
	JMP $E580				; next test
tE50:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sE58:
	STZ sum
	STZ chk
	LDX #0
lE58:
		LDA sum
		CLC
		ADC tE58, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lE58
	CMP #CHKVALUE			; compare sum of sums
		BNE xE58			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xE58			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xE58:
	INY						; this was odd half-page
	JMP $E600				; next test
tE58:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sE60:
	STZ sum
	STZ chk
	LDX #0
lE60:
		LDA sum
		CLC
		ADC tE60, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lE60
	CMP #CHKVALUE			; compare sum of sums
		BNE xE60			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xE60			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xE60:
	NOP
	JMP $E680				; next test
tE60:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sE68:
	STZ sum
	STZ chk
	LDX #0
lE68:
		LDA sum
		CLC
		ADC tE68, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lE68
	CMP #CHKVALUE			; compare sum of sums
		BNE xE68			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xE68			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xE68:
	INY						; this was odd half-page
	JMP $E700				; next test
tE68:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sE70:
	STZ sum
	STZ chk
	LDX #0
lE70:
		LDA sum
		CLC
		ADC tE70, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lE70
	CMP #CHKVALUE			; compare sum of sums
		BNE xE70			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xE70			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xE70:
	NOP
	JMP $E780				; next test
tE70:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sE78:
	STZ sum
	STZ chk
	LDX #0
lE78:
		LDA sum
		CLC
		ADC tE78, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lE78
	CMP #CHKVALUE			; compare sum of sums
		BNE xE78			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xE78			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xE78:
	INY						; this was odd half-page
	JMP $E800				; next test
tE78:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sE80:
	STZ sum
	STZ chk
	LDX #0
lE80:
		LDA sum
		CLC
		ADC tE80, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lE80
	CMP #CHKVALUE			; compare sum of sums
		BNE xE80			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xE80			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xE80:
	NOP
	JMP $E880				; next test
tE80:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sE88:
	STZ sum
	STZ chk
	LDX #0
lE88:
		LDA sum
		CLC
		ADC tE88, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lE88
	CMP #CHKVALUE			; compare sum of sums
		BNE xE88			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xE88			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xE88:
	INY						; this was odd half-page
	JMP $E900				; next test
tE88:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sE90:
	STZ sum
	STZ chk
	LDX #0
lE90:
		LDA sum
		CLC
		ADC tE90, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lE90
	CMP #CHKVALUE			; compare sum of sums
		BNE xE90			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xE90			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xE90:
	NOP
	JMP $E980				; next test
tE90:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sE98:
	STZ sum
	STZ chk
	LDX #0
lE98:
		LDA sum
		CLC
		ADC tE98, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lE98
	CMP #CHKVALUE			; compare sum of sums
		BNE xE98			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xE98			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xE98:
	INY						; this was odd half-page
	JMP $EA00				; next test
tE98:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sEA0:
	STZ sum
	STZ chk
	LDX #0
lEA0:
		LDA sum
		CLC
		ADC tEA0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lEA0
	CMP #CHKVALUE			; compare sum of sums
		BNE xEA0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xEA0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xEA0:
	NOP
	JMP $EA80				; next test
tEA0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sEA8:
	STZ sum
	STZ chk
	LDX #0
lEA8:
		LDA sum
		CLC
		ADC tEA8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lEA8
	CMP #CHKVALUE			; compare sum of sums
		BNE xEA8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xEA8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xEA8:
	INY						; this was odd half-page
	JMP $EB00				; next test
tEA8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sEB0:
	STZ sum
	STZ chk
	LDX #0
lEB0:
		LDA sum
		CLC
		ADC tEB0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lEB0
	CMP #CHKVALUE			; compare sum of sums
		BNE xEB0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xEB0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xEB0:
	NOP
	JMP $EB80				; next test
tEB0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sEB8:
	STZ sum
	STZ chk
	LDX #0
lEB8:
		LDA sum
		CLC
		ADC tEB8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lEB8
	CMP #CHKVALUE			; compare sum of sums
		BNE xEB8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xEB8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xEB8:
	INY						; this was odd half-page
	JMP $EC00				; next test
tEB8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sEC0:
	STZ sum
	STZ chk
	LDX #0
lEC0:
		LDA sum
		CLC
		ADC tEC0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lEC0
	CMP #CHKVALUE			; compare sum of sums
		BNE xEC0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xEC0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xEC0:
	NOP
	JMP $EC80				; next test
tEC0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sEC8:
	STZ sum
	STZ chk
	LDX #0
lEC8:
		LDA sum
		CLC
		ADC tEC8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lEC8
	CMP #CHKVALUE			; compare sum of sums
		BNE xEC8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xEC8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xEC8:
	INY						; this was odd half-page
	JMP $ED00				; next test
tEC8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sED0:
	STZ sum
	STZ chk
	LDX #0
lED0:
		LDA sum
		CLC
		ADC tED0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lED0
	CMP #CHKVALUE			; compare sum of sums
		BNE xED0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xED0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xED0:
	NOP
	JMP $ED80				; next test
tED0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sED8:
	STZ sum
	STZ chk
	LDX #0
lED8:
		LDA sum
		CLC
		ADC tED8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lED8
	CMP #CHKVALUE			; compare sum of sums
		BNE xED8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xED8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xED8:
	INY						; this was odd half-page
	JMP $EE00				; next test
tED8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sEE0:
	STZ sum
	STZ chk
	LDX #0
lEE0:
		LDA sum
		CLC
		ADC tEE0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lEE0
	CMP #CHKVALUE			; compare sum of sums
		BNE xEE0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xEE0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xEE0:
	NOP
	JMP $EE80				; next test
tEE0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sEE8:
	STZ sum
	STZ chk
	LDX #0
lEE8:
		LDA sum
		CLC
		ADC tEE8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lEE8
	CMP #CHKVALUE			; compare sum of sums
		BNE xEE8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xEE8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xEE8:
	INY						; this was odd half-page
	JMP $EF00				; next test
tEE8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sEF0:
	STZ sum
	STZ chk
	LDX #0
lEF0:
		LDA sum
		CLC
		ADC tEF0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lEF0
	CMP #CHKVALUE			; compare sum of sums
		BNE xEF0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xEF0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xEF0:
	NOP
	JMP $EF80				; next test
tEF0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sEF8:
	STZ sum
	STZ chk
	LDX #0
lEF8:
		LDA sum
		CLC
		ADC tEF8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tEble
		BNE lEF8
	CMP #CHKVALUE			; compare sum of sums
		BNE xEF8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xEF8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xEF8:
	INY						; this was odd half-page
	JMP $F000				; next test
tEF8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87

; $Fxxx

; *** test code ***
sF00:
	STZ sum
	STZ chk
	LDX #0
lF00:
		LDA sum
		CLC
		ADC tF00, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lF00
	CMP #CHKVALUE			; compare sum of sums
		BNE xF00			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xF00			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xF00:
	NOP
	JMP $F280				; next test
tF00:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sF08:
	STZ sum
	STZ chk
	LDX #0
lF08:
		LDA sum
		CLC
		ADC tF08, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lF08
	CMP #CHKVALUE			; compare sum of sums
		BNE xF08			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xF08			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xF08:
	INY						; this was odd half-page
	JMP $F300				; next test
tF08:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sF10:
	STZ sum
	STZ chk
	LDX #0
lF10:
		LDA sum
		CLC
		ADC tF10, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lF10
	CMP #CHKVALUE			; compare sum of sums
		BNE xF10			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xF10			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xF10:
	NOP
	JMP $F380				; next test
tF10:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sF18:
	STZ sum
	STZ chk
	LDX #0
lF18:
		LDA sum
		CLC
		ADC tF18, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lF18
	CMP #CHKVALUE			; compare sum of sums
		BNE xF18			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xF18			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xF18:
	INY						; this was odd half-page
	JMP $F200				; next test
tF18:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sF20:
	STZ sum
	STZ chk
	LDX #0
lF20:
		LDA sum
		CLC
		ADC tF20, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lF20
	CMP #CHKVALUE			; compare sum of sums
		BNE xF20			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xF20			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xF20:
	NOP
	JMP $F280				; next test
tF20:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sF28:
	STZ sum
	STZ chk
	LDX #0
lF28:
		LDA sum
		CLC
		ADC tF28, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lF28
	CMP #CHKVALUE			; compare sum of sums
		BNE xF28			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xF28			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xF28:
	INY						; this was odd half-page
	JMP $F300				; next test
tF28:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sF30:
	STZ sum
	STZ chk
	LDX #0
lF30:
		LDA sum
		CLC
		ADC tF30, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lF30
	CMP #CHKVALUE			; compare sum of sums
		BNE xF30			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xF30			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xF30:
	NOP
	JMP $F380				; next test
tF30:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sF38:
	STZ sum
	STZ chk
	LDX #0
lF38:
		LDA sum
		CLC
		ADC tF38, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lF38
	CMP #CHKVALUE			; compare sum of sums
		BNE xF38			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xF38			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xF38:
	INY						; this was odd half-page
	JMP $F400				; next test
tF38:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sF40:
	STZ sum
	STZ chk
	LDX #0
lF40:
		LDA sum
		CLC
		ADC tF40, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lF40
	CMP #CHKVALUE			; compare sum of sums
		BNE xF40			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xF40			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xF40:
	NOP
	JMP $F480				; next test
tF40:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sF48:
	STZ sum
	STZ chk
	LDX #0
lF48:
		LDA sum
		CLC
		ADC tF48, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lF48
	CMP #CHKVALUE			; compare sum of sums
		BNE xF48			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xF48			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xF48:
	INY						; this was odd half-page
	JMP $F500				; next test
tF48:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sF50:
	STZ sum
	STZ chk
	LDX #0
lF50:
		LDA sum
		CLC
		ADC tF50, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lF50
	CMP #CHKVALUE			; compare sum of sums
		BNE xF50			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xF50			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xF50:
	NOP
	JMP $F580				; next test
tF50:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sF58:
	STZ sum
	STZ chk
	LDX #0
lF58:
		LDA sum
		CLC
		ADC tF58, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lF58
	CMP #CHKVALUE			; compare sum of sums
		BNE xF58			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xF58			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xF58:
	INY						; this was odd half-page
	JMP $F600				; next test
tF58:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sF60:
	STZ sum
	STZ chk
	LDX #0
lF60:
		LDA sum
		CLC
		ADC tF60, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lF60
	CMP #CHKVALUE			; compare sum of sums
		BNE xF60			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xF60			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xF60:
	NOP
	JMP $F680				; next test
tF60:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sF68:
	STZ sum
	STZ chk
	LDX #0
lF68:
		LDA sum
		CLC
		ADC tF68, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lF68
	CMP #CHKVALUE			; compare sum of sums
		BNE xF68			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xF68			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xF68:
	INY						; this was odd half-page
	JMP $F700				; next test
tF68:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sF70:
	STZ sum
	STZ chk
	LDX #0
lF70:
		LDA sum
		CLC
		ADC tF70, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lF70
	CMP #CHKVALUE			; compare sum of sums
		BNE xF70			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xF70			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xF70:
	NOP
	JMP $F780				; next test
tF70:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sF78:
	STZ sum
	STZ chk
	LDX #0
lF78:
		LDA sum
		CLC
		ADC tF78, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lF78
	CMP #CHKVALUE			; compare sum of sums
		BNE xF78			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xF78			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xF78:
	INY						; this was odd half-page
	JMP $F800				; next test
tF78:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sF80:
	STZ sum
	STZ chk
	LDX #0
lF80:
		LDA sum
		CLC
		ADC tF80, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lF80
	CMP #CHKVALUE			; compare sum of sums
		BNE xF80			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xF80			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xF80:
	NOP
	JMP $F880				; next test
tF80:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sF88:
	STZ sum
	STZ chk
	LDX #0
lF88:
		LDA sum
		CLC
		ADC tF88, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lF88
	CMP #CHKVALUE			; compare sum of sums
		BNE xF88			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xF88			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xF88:
	INY						; this was odd half-page
	JMP $F900				; next test
tF88:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sF90:
	STZ sum
	STZ chk
	LDX #0
lF90:
		LDA sum
		CLC
		ADC tF90, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lF90
	CMP #CHKVALUE			; compare sum of sums
		BNE xF90			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xF90			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xF90:
	NOP
	JMP $F980				; next test
tF90:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sF98:
	STZ sum
	STZ chk
	LDX #0
lF98:
		LDA sum
		CLC
		ADC tF98, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lF98
	CMP #CHKVALUE			; compare sum of sums
		BNE xF98			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xF98			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xF98:
	INY						; this was odd half-page
	JMP $FA00				; next test
tF98:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sFA0:
	STZ sum
	STZ chk
	LDX #0
lFA0:
		LDA sum
		CLC
		ADC tFA0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lFA0
	CMP #CHKVALUE			; compare sum of sums
		BNE xFA0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xFA0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xFA0:
	NOP
	JMP $FA80				; next test
tFA0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sFA8:
	STZ sum
	STZ chk
	LDX #0
lFA8:
		LDA sum
		CLC
		ADC tFA8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lFA8
	CMP #CHKVALUE			; compare sum of sums
		BNE xFA8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xFA8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xFA8:
	INY						; this was odd half-page
	JMP $FB00				; next test
tFA8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sFB0:
	STZ sum
	STZ chk
	LDX #0
lFB0:
		LDA sum
		CLC
		ADC tFB0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lFB0
	CMP #CHKVALUE			; compare sum of sums
		BNE xFB0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xFB0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xFB0:
	NOP
	JMP $FB80				; next test
tFB0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sFB8:
	STZ sum
	STZ chk
	LDX #0
lFB8:
		LDA sum
		CLC
		ADC tFB8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lFB8
	CMP #CHKVALUE			; compare sum of sums
		BNE xFB8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xFB8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xFB8:
	INY						; this was odd half-page
	JMP $FC00				; next test
tFB8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sFC0:
	STZ sum
	STZ chk
	LDX #0
lFC0:
		LDA sum
		CLC
		ADC tFC0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lFC0
	CMP #CHKVALUE			; compare sum of sums
		BNE xFC0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xFC0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xFC0:
	NOP
	JMP $FC80				; next test
tFC0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sFC8:
	STZ sum
	STZ chk
	LDX #0
lFC8:
		LDA sum
		CLC
		ADC tFC8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lFC8
	CMP #CHKVALUE			; compare sum of sums
		BNE xFC8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xFC8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xFC8:
	INY						; this was odd half-page
	JMP $FD00				; next test
tFC8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sFD0:
	STZ sum
	STZ chk
	LDX #0
lFD0:
		LDA sum
		CLC
		ADC tFD0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lFD0
	CMP #CHKVALUE			; compare sum of sums
		BNE xFD0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xFD0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xFD0:
	NOP
	JMP $FD80				; next test
tFD0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sFD8:
	STZ sum
	STZ chk
	LDX #0
lFD8:
		LDA sum
		CLC
		ADC tFD8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lFD8
	CMP #CHKVALUE			; compare sum of sums
		BNE xFD8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xFD8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xFD8:
	INY						; this was odd half-page
	JMP $FE00				; next test
tFD8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sFE0:
	STZ sum
	STZ chk
	LDX #0
lFE0:
		LDA sum
		CLC
		ADC tFE0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lFE0
	CMP #CHKVALUE			; compare sum of sums
		BNE xFE0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xFE0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xFE0:
	NOP
	JMP $FE80				; next test
tFE0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sFE8:
	STZ sum
	STZ chk
	LDX #0
lFE8:
		LDA sum
		CLC
		ADC tFE8, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lFE8
	CMP #CHKVALUE			; compare sum of sums
		BNE xFE8			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xFE8			; lock if bad
	STA $7000, Y			; indicate on screen otherwise
xFE8:
	INY						; this was odd half-page
	JMP $FF00				; next test
tFE8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
sFF0:
	STZ sum
	STZ chk
	LDX #0
lFF0:
		LDA sum
		CLC
		ADC tFF0, X			; compute sum
		STA sum
		CLC
		ADC chk				; compute sum of sums
		STA chk
		INX
		CPX #SIZE			; until end of tFble
		BNE lFF0
	CMP #CHKVALUE			; compare sum of sums
		BNE xFF0			; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE xFF0			; lock if bad
	STA $6F00, Y			; indicate on screen otherwise
xFF0:
	NOP
	JMP $FF80				; next test
tFF0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87

; *** all tests finished ***
	LDA #$BB				; lavender pink
	LDX #0
streak:
		STA $7100, X
		INX
		BNE streak

; *****************************
; *** alignment and ROM end ***
; *****************************
lock:
				INX
				BNE lock
			INY
			BNE lock
		INC
		STA IOAie
		BRA lock			; do some blinking
	.dsb	$FFD6-*, $FF	; padding

	.asc	"DmOS"			; standard minimOS signature
void:
	RTI						; dummy ISR
	.dsb	$FFE1-*, $FF
; * = $FFE1
autoreset:
	JMP ($FFFC)				; RESET on loaded image *** mandatory instruction on any ROM image ***
 
; *****************************
; *** standard 6502 vectors ***
; *****************************
	.dsb	$FFFA-*, $FF

; * = $FFFA
	.word	reset			; NMI as warm reset
	.word	reset
	.word	void
