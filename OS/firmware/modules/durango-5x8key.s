; Durango-X 5x8 keyboard driver
; v0.1a1
; (c) 2022 Carlos J. Santisteban
; last modified 20221028-1957

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
	JMP (kbd_drv, X)

; *** drivers pointer list ***
kdb_drv:
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
	LDY #4					; prepare to scan backwards
col_loop:
		LDX #7				; row loop
		LDA col_bit, Y		; get bit position for column
		STA IO9m5x8			; select column
		LDA IO9m5x8			; and read it
;			STZ IO9m5x8		; deselect all, not necessary but lower power
		AND k_mask, Y		; discard modifier bits
		BEQ kb_skip			; no keys from this column
row_loop:
			ASL				; d7 goes first
			BCS key_pr		; detected keypress!
			DEX
			BPL row_loop	; all 8 rows
		DEY					; next column
		BPL col_loop
; if arrived here, no keys (beside SHIFT) were pressed
	LDA #$FF				; invalid scancode
	STA kb_scan
	LDA #DELAY				; reset key repeat
	STA kb_rcnt
no_key:
	STZ kb_asc				; no key pressed
	RTS
; otherwise, a key was detected
key_pr:
	TYA						; get column index
	ASL
	ASL
	ASL						; times 8
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
		LDX #rpt			; I believe this goes here...
		STX kb_rcnt
diff_k:
	STA kb_scan				; in any case, update last scancode as new keystroke
	TAX						; use scancode as index
	LDA kb_map, X			; get ASCII from layout
	CMP #$FF				; invalid ASCII, this will change into CONTROL mode
	BNE no_ctl
		STA kb_ctl			; set d7
		LDA #0				; no ASCII for now
no_ctl:
	STA kb_asc				; store detected ASCII
	RTS
; if arrived here, a key was pressed while in CONTROL mode (will not repeat)
ctl_key:
	TAX						; use scancode as index
	LDA ctl_map, X			; get ASCII from CONTROL-mode layout
	CMP #$FF				; invalid ASCII, this will change into CONTROL mode
	BNE no_ctl
		STA kb_ctl			; keep d7 set
		LDA #0				; no ASCII for now
	BEQ no_ctl				; send it and exit (no need for BRA)

; *******************
; *** data tables ***
; *******************

; bit positions for every column
col_bit:
	.byt	1, 2, 4, 8, 16

; valid row bits minus shift keys
k_mask:
	.byt	%11011111, %01111111, %11111111, %11111111, %11111111

; standard keymap *** TBD
kb_map:

; control mode keymap *** TBD
ctl_map:
