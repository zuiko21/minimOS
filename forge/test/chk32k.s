; Durango-X ROM download test
; (c) 2024 Carlos J. Santisteban
; last modified 20241001-2257

#define	CHKVALUE	0
#define	SUMVALUE	0
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
	strip	= $6F00
	display	= $705F
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
	LDY #$81				; page index

	JMP $8180				; first standard test!
	.dsb	$8180-*, $FF
; *** test code ***
c818:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $6021				; indicate on screen otherwise
	INY						; this was odd half-page
	JMP $8200				; next test
t818:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c820:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $6060				; indicate on screen otherwise
	NOP
	JMP $8280				; next test
t820:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c828:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $60A1				; indicate on screen otherwise
	INY						; this was odd half-page
	JMP $8300				; next test
t828:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c830:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $60E0				; indicate on screen otherwise
	NOP
	JMP $8380				; next test
t830:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c838:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $6121				; indicate on screen otherwise
	INY						; this was odd half-page
	JMP $8400				; next test
t838:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c840:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $6160				; indicate on screen otherwise
	NOP
	JMP $8480				; next test
t840:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c848:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $6160				; indicate on screen otherwise
	INY						; this was odd half-page
	JMP $8500				; next test
t848:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c850:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $61A1				; indicate on screen otherwise
	NOP
	JMP $8580				; next test
t850:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c858:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $61E0				; indicate on screen otherwise
	INY						; this was odd half-page
	JMP $8600				; next test
t858:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c860:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $6221				; indicate on screen otherwise
	NOP
	JMP $8680				; next test
t860:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c868:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $6260				; indicate on screen otherwise
	INY						; this was odd half-page
	JMP $8700				; next test
t868:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c870:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $62A1				; indicate on screen otherwise
	NOP
	JMP $8780				; next test
t870:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c878:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $62E0				; indicate on screen otherwise
	INY						; this was odd half-page
	JMP $8800				; next test
t878:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c880:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $6321				; indicate on screen otherwise
	NOP
	JMP $8880				; next test
t880:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c888:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $6360				; indicate on screen otherwise
	INY						; this was odd half-page
	JMP $8900				; next test
t888:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c890:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $63A1				; indicate on screen otherwise
	NOP
	JMP $8980				; next test
t890:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c898:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $63E0				; indicate on screen otherwise
	INY						; this was odd half-page
	JMP $8A00				; next test
t898:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c8A0:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $6421				; indicate on screen otherwise
	NOP
	JMP $8A80				; next test
t8A0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c8A8:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $6460				; indicate on screen otherwise
	INY						; this was odd half-page
	JMP $8B00				; next test
t8A8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c8B0:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $64A1				; indicate on screen otherwise
	NOP
	JMP $8B80				; next test
t8B0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c8B8:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $6460				; indicate on screen otherwise
	INY						; this was odd half-page
	JMP $8C00				; next test
t8B8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c8C0:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $64A1				; indicate on screen otherwise
	NOP
	JMP $8C80				; next test
t8C0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c8C8:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $64E0				; indicate on screen otherwise
	INY						; this was odd half-page
	JMP $8D00				; next test
t8C8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c8D0:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $6521				; indicate on screen otherwise
	NOP
	JMP $8D80				; next test
t8D0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c8D8:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $6560				; indicate on screen otherwise
	INY						; this was odd half-page
	JMP $8E00				; next test
t8D8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c8E0:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $65A1				; indicate on screen otherwise
	NOP
	JMP $8E80				; next test
t8E0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c8E8:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $65E0				; indicate on screen otherwise
	INY						; this was odd half-page
	JMP $8F00				; next test
t8E8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c8F0:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $6621				; indicate on screen otherwise
	NOP
	JMP $8F80				; next test
t8F0:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87
; *** test code ***
c8F8:
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
		BNE *				; lock if bad
	LDA sum
	CMP #SUMVALUE			; compare simple sum
		BNE *				; lock if bad
	STY $6660				; indicate on screen otherwise
	INY						; this was odd half-page
	JMP $9000				; next test
t8F8:
	.byt	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
	.byt	21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37
	.byt	38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54
	.byt	55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71
	.byt	72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87


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
