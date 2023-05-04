; Durango-X 5x8 keyboard driver
; v1.0b5
; (c) 2022-2023 Carlos J. Santisteban
; last modified 20230504-1849

#echo 5x8 keyboard support

; usual definitions
#ifndef	KEYBDRV
#define	KEYBDRV
IO9pask	= $DF9A				; PASK port
IO9m5x8	= $DF9B				; matrix keyboard port
kb_asc	= $020A				; read key
kb_mod	= $020B				; modifier keys combo (d7=ALT, d6=SHIFT)
kb_ctl	= $020C				; control key flag (d7)
kb_scan	= $020D				; last scancode read
kb_rcnt	= $020E				; repeat counter
kb_type	= $020F				; type of keyboard (0=PASK, 2=5x8 matrix...)
#endif

; *** some other constants for repeat rate (in 4 ms units) ***
#define	DELAY	175
#define	RATE	25

; ***********************************************
; *** *** plug-and-play interrupt support *** ***
#ifdef	KBDISR
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
#endif
; *** *** ******************************* *** ***
; ***********************************************

; *** 5x8 matrix driver ***
drv_5x8:
	LDY #0
	STY kb_mod				; reset modifiers (no need for STZ)
	INY						; column 1 has CAPS SHIFT
	STY IO9m5x8				; select column
	LDA IO9m5x8				; get rows
	ASL						; extract ROW8 (SPACE)...
	ASL						; ...then ROW7 (ENTER)...
	ASL						; ...and finally ROW6 (SHIFT) into C (3b, 6t; was 6b, 7/8t)
	ROR kb_mod				; insert CAPS bit at left (will end at d6)
	INY						; second column
	STY IO9m5x8				; select it
	LDA IO9m5x8				; and read its rows
	ASL						; only d7 is interesting (ALT, aka SYMBOL SHIFT)
	ROR kb_mod				; insert ALT bit at d7
	LDY #5					; prepare to scan backwards (note indices are 1...5)
col_loop:
		LDA col_bit-1, Y	; get bit position for column, note offset
		STA IO9m5x8			; select column
		LDA IO9m5x8			; and read it
;		STZ IO9m5x8			; deselect all, not necessary but lower power (CMOS only)
		AND k_mask-1, Y		; discard modifier bits, note offset
		BEQ kb_skip			; no keys from this column
			LDX #7			; row loop (row indices are 0...7)
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
	LDA #0					; 0 means no (new) key was pressed
set_key:					; common ASCII code output, with or without actual key
	STA kb_asc				; return ASCII code (0 = no key)
	RTS
; otherwise, a key was detected
key_pr:
	TYA						; get column index (1...5)
	ASL
	ASL
	ASL						; times 8 (8...40)
	STX kb_asc				; TEMPORARY STORAGE of ·····XXX
	ORA kb_asc				; A = ··YYYXXX
	BIT kb_ctl				; is control-mode enabled?
	BMI ctl_key				; check different table (without checking any modifiers nor repeat)
		ORA kb_mod			; scancode is complete in A
; look for new or repeated key
		CMP kb_scan			; same as before?
		BNE diff_k			; nope, just generate new keystroke
			DEC kb_rcnt		; otherwise update repeat counter
				BNE no_key	; if not expired, just simulate released key for a while
			LDX #RATE		; I believe this goes here...
			STX kb_rcnt		; the counter is reset, repeat current keystroke
diff_k:
		STA kb_scan			; in any case, update last scancode as new keystroke
		TAX					; use scancode as index
		LDA kb_map-8, X		; get ASCII from layout, note offset
		CMP #$FF			; invalid ASCII, this will change into CTRL mode
		BNE set_key			; not the CONTROL combo, all done
			STA kb_ctl		; otherwise, $FF sets d7 for CTRL mode
			JMP no_key		; no ASCII for now
; if arrived here, a key was pressed while in CONTROL mode (will not repeat)
ctl_key:
	TAX						; use scancode (without modifiers) as index
	LDA ctl_map-8, X		; get ASCII from CONTROL-mode layout, note offset
		BEQ no_key			; invalid ASCII, this will stay into CTRL mode
	STA kb_ctl				; otherwise clear d7, no longer in CTRL mode (works as none of control codes is over 127)
;	STX kb_scan				; try this less dodgy alternative ***
rls_ctl:
		LDY IO9m5x8			; wait until column from detected key is clear *** KLUDGE, see alternative above
		BNE rls_ctl
	BEQ set_key				; and send that control code (no need for BRA)

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
; * filling after tables inside gap *
	.dsb	14, 0
kb_s_map:
; SHIFTed keys (d6=1)
	.asc	$1B, "QA", 8, 'P', 0, $D, 3		; column 1, note SHIFT disabled (scan = $48...$4F)
	.asc	9, "WS", $FF, "OZL", 0			; column 2, note ALT disabled and CTRL code switch (scan = $50...$57)
	.asc	$F, "ED", 6, "IXKM"				; column 3 (scan = $58...$5F)
	.asc	$E, "RF", $B, "UCJN"			; column 4 (scan = $60...$67)
	.asc	2, "TG", $A, "YVHB"				; column 5 (scan = $68...$6F)
; note 24-byte gap
	.dsb	24, 0
kb_a_map:
; ALTed keys (d7=1)
	.asc	'!', $A1,$E1, '_', $22,0,$F1, 0	; column 1, note SHIFT disabled (scan = $88...$8F)
	.asc	'@', $7E, ";)", $F3, ":=", 0	; column 2, note ALT disabled (scan = $90...$97)
	.asc	'#', $E9, "|(", $ED, $BF, "+."	; column 3 (scan = $98...$9F)
	.asc	"$<['", $FA, "?-,"				; column 4 (scan = $A0...$A7)
	.asc	"%>]&", $FC, '/', $5E, '*'		; column 5 (scan = $A8...$AF)
; note 24-byte gap
	.dsb	24, 0
kb_as_map:
; SHIFT+ALT (d7d6=11)
	.asc	0, $B0, $C1, 0, 0, 0, $D1, 0	; column 1, note SHIFT disabled (scan = $C8...$CF)
	.asc	$18, 0, 0, 0, $D3, 0, 0, 0		; column 2, note ALT disabled (scan = $D0...$D7)
	.asc	0, $C9, $5C, 5, $CD, $A4, 0, 0	; column 3 (scan = $D8...$DF)
	.asc	0, $96, '{', $19, $DA, 0, 0, 0	; column 4 (scan = $E0...$E7)
	.asc	1, $98, '}', $16, $DC, 0, 0, 0	; column 5 (scan = $E8...$EF)

; *** control mode keymap, first 8 bytes removed *** may split in 16-byte chunks between gaps
ctl_map:
	.asc	$1B, $11, 1, 0, $10, 0, 0, 0		; column 1, note SHIFT disabled (scan = 8...$F)
	.asc	$1C, $17, $13, 0, $F, $1A, $C, 0	; column 2, note ALT disabled (scan = $10...$17)
	.asc	$1D, 5, 4, 0, 9, $18, $B, $D		; column 3 (scan = $18...$1F)
	.asc	$1E, $12, 6, 0, $15, 3, $A, $E		; column 4 (scan = $20...$27)
	.asc	$1F, $14, 7, 0, $19, $16, 8, 2		; column 5 (scan = $28...$2F)
