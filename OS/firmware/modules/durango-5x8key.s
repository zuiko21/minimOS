; Durango-X 5x8 keyboard driver
; v0.1a2
; (c) 2022 Carlos J. Santisteban
; last modified 20221128-0811

; usual definitions
#ifndef	KEYBDRV
#define	KEYBDRV
IO9pask	= $DF9A				; PASK port
IO9m5x8	= $DF9B				; matrix keyboard port
kb_asc	= $020A				; read key
kb_type	= $020B				; type of keyboard (0=PASK, 2=5x8 matrix...)
kb_mod	= $020C				; modifier keys combo (d7=SYMBOL, d6=CAPS)
kb_ctl	= $020D				; control key mode (d7 only)
kb_scan	= $020E				; last scancode read (for repeat)
kb_rcnt	= $020F				; repeat counter
#endif

; *** some other constants for repeat rate (in 4 ms units) ***
#define	DELAY	175
#define	RATE	25

; *** ISR to be called via JSR (will return)
kbd_isr:
	LDX kb_type
	JMP (kbd_drv, X)		; CMOS only

; *** drivers pointer list ***
kbd_drv:
	.word	drv_pask
	.word	drv_5x8

; *** generic PASK driver ***
drv_pask:
	LDA IO9pask				; PASK peripheral address
	STA kb_asc				; store for software
	RTS

; *** 5x8 matrix driver ***
drv_5x8:
	LDY #0					; first column contains CAPS SHIFT
	STY kb_mod				; reset modifiers (no need for STZ)
	INY						; get bit pattern for this column (d0 is actually 1)
	STY IO9m5x8				; select column
	LDA IO9m5x8				; get column
	AND #32					; select CAPS SHIFT row
	BEQ no_cs				; if CAPS SHIFT is pressed...
		SEC					; ...will set bit
no_cs:
	ROR kb_mod				; insert CAPS bit (will end at d6)
	INY						; second column
	STY IO9m5x8				; select it
	LDA IO9m5x8				; and read it
	ASL						; only d7 is interesting (SYMBOL SHIFT)
	ROR kb_mod				; insert SYMBOL bit at d7
	LDY #5					; prepare to scan backwards (note indices are 1...5)
col_loop:
		LDA col_bit-1, Y	; get bit position for column, note offset
		STA IO9m5x8			; select column
		LDA IO9m5x8			; and read it
;			STZ IO9m5x8		; deselect all, not necessary but lower power
		AND k_mask-1, Y		; discard modifier bits, note offset
		BEQ kb_skip			; no keys from this column
		LDX #7				; row loop
row_loop:
			ASL				; d7 goes first
			BCS key_pr		; detected keypress!
			DEX
			BPL row_loop	; all 8 rows
kb_skip:
		DEY					; next column
		BNE col_loop
; if arrived here, no keys (beside modifiers) were pressed
	STY kb_scan				; Y is zero, which is now an invalid scancode
	LDA #DELAY				; reset key repeat
	STA kb_rcnt
no_key:
	STZ kb_asc				; no key pressed, CMOS only
	RTS
; otherwise, a key was detected
key_pr:
	TYA						; get column index (1...5)
	ASL
	ASL
	ASL						; times 8 (8...40)
	STX kb_asc				; TEMPORARY STORAGE
	ORA kb_asc				; ··YYYXXX
	BIT kb_ctl				; is control-mode enabled?
		BMI ctl_key			; check different table
	ORA kb_mod				; scancode is complete
; otherwise look for new or repeated key
	CMP kb_scan				; same as before?
	BNE diff_k				; nope, just generate new keystroke
		DEC kb_rcnt			; otherwise update repeat counter
			BNE no_key		; if not expired, just simulate released key for a while
		LDX #RATE			; I believe this goes here...
		STX kb_rcnt
diff_k:
	STA kb_scan				; in any case, update last scancode as new keystroke
	TAX						; use scancode as index
	LDA kb_map-8, X			; get ASCII from layout, note offset
	CMP #$FF				; invalid ASCII, this will change into CONTROL mode *** check
	BNE no_ctl
		STA kb_ctl			; set d7 *** beware of above
		LDA #0				; no ASCII for now
no_ctl:
	STA kb_asc				; store detected ASCII
	RTS
; if arrived here, a key was pressed while in CONTROL mode (will not repeat)
ctl_key:
	TAX						; use scancode as index
	LDA ctl_map-8, X		; get ASCII from CONTROL-mode layout, note offset
	CMP #$FF				; invalid ASCII, this will stay into CONTROL mode *** check
	BNE no_ctl
		STA kb_ctl			; keep d7 set
		LDA #0				; no ASCII for now
	BEQ no_ctl				; send it and exit (no need for BRA)

; *******************
; *** data tables ***
; *******************

; *** standard keymap, first 8 bytes removed ***
kb_map:
; unshifted keys (d7d6=00)
	.asc	"1qa0p", 0, $D, ' '		; column 1, note SHIFT disabled (scan = 8...$F)
	.asc	"2ws9ozl", 0			; column 2, note ALT disabled (scan = $10...$17)
	.asc	"3ed8ixkm"				; column 3 (scan = $18...$1F)
	.asc	"4rf7ucjn"				; column 4 (scan = $20...$27)
	.asc	"5tg6yvhb"				; column 5 (scan = $28...$2F)
; * note 24-byte gap *
; bit positions for every column (may place in gaps)
col_bit:
	.byt	1, 2, 4, 8, 16
; valid row bits minus shift keys
k_mask:
	.byt	%11011111, %01111111, %11111111, %11111111, %11111111
; * filling after gap *
	.dsb	14, 0
; SHIFTed keys (d6=1)
	.asc	$1B, "QA", 8, 'P', 3, $D, ' '	; column 1, note SHIFT disabled (scan = $48...$4F)
	.asc	9, "WS", $FF, "OZL", 0			; column 2, note ALT disabled (scan = $50...$57)
	.asc	$F, "ED", 6, "IXKM"				; column 3 (scan = $58...$5F)
	.asc	$E, "RF", $B, "UCJN"			; column 4 (scan = $60...$67)
	.asc	2, "TG", $A, "YVHB"				; column 5 (scan = $68...$6F)
; note 24-byte gap
	.dsb	24, 0
; ALTed keys (d7=1)********** TBD
	.asc	"!qá_", $22, 0, 'ñ', 0	; column 1, note SHIFT disabled (scan = $88...$8F)
	.asc	"@w;)ó:=", 0			; column 2, note ALT disabled (scan = $90...$97)
	.asc	"#é|(í¿+."				; column 3 (scan = $98...$9F)
	.asc	"$r['ú?-,"				; column 4 (scan = $A0...$A7)
	.asc	"%t]&ü/^*"				; column 5 (scan = $A8...$AF)
; note 24-byte gap
	.dsb	24, 0
; SHIFT+ALT (d7d6=11)
	.asc	0, "ºÁ", 0, 0, 0, 'Ñ', 0	; column 1, note SHIFT disabled (scan = $C8...$CF)
	.asc	$18, 0, 0, 0, 'Ó', 0, 'l', 0; column 2, note ALT disabled (scan = $D0...$D7)
	.asc	0, "É\", 5, "Í€", 0, 0		; column 3 (scan = $D8...$DF)
	.asc	0, "≤{", $19, 'Ú', 0, 0, 0	; column 4 (scan = $E0...$E7)
	.asc	1, "≥}", $16, 'Ü', 0, 0, 0	; column 5 (scan = $E8...$EF)

; *** control mode keymap, first 8 bytes removed *** TBD
ctl_map:
