; 64-key ASCII keyboard for minimOS!
; v0.6a1
; (c) 2012-2018 Carlos J. Santisteban
; last modified 20180804-1856

; VIA bit functions
; PA0...3	= input from selected column
; PA4...7	= output (selected column)
; PB3		= caps lock LED (hopefully respected!)

; new VIA-connected device ID is $A5/AD, $25/2D with PB7 off (%x010x101)

; ** driver variables description **
; ak_fi, first free element in FIFO
; ak_fo, element ready for exit in FIFO
; ak_ddra, old port config
; ak_iorb, old command **needed?**
; ak_rmod, last detected raw modifier combo
;	d0 = caps lock
;	d1 = alt
;	d2 = control
;	d3 = shift
; ak_cmod, modifier status (like ak_rmod with toggling caps lock)
; ak_scod, last detected scancode
; ak_del, delay counter before repeat
; ak_rep, repeat rate counter
; ak_dead, deadkey mode flag

; ***********************
; *** minimOS headers ***
; ***********************
#include "../usual.h"

.(
; *** begins with sub-function addresses table ***
	.byt	145		; physical driver number D_ID (TBD)
	.byt	A_BLIN|A_POLL	; input driver, periodic interrupt-driven
	.word	ak_read		; read from input buffer
	.word	ak_err		; no output
	.word	ak_init		; initialise 'device', called by POST only
	.word	ak_poll		; periodic interrupt...
	.word	4		; 20ms scan seems fast enough
	.word	ak_nreq		; D_ASYN does nothing
	.word	ak_err		; no config
	.word	ak_err		; no status
	.word	ak_exit		; shutdown procedure, leave VIA as it was...
	.word	ak_info		; points to descriptor string
	.word	0		; non-relocatable, D_MEM

; *** driver description ***
ak_info:
	.asc	"ASCII keyboard v0.6", 0

; *** some definitions ***
AF_SIZ		= 16		; buffer size (only 15 useable) no need to be power of two
AR_DEL		= 140		; 140×5 ms (0.7s) fixed delay
AR_RATE		= 20		; 20×5 ms (1/10s) fixed repeat rate
PA_MASK		= %11110000	; PA0-3 as input, PA4-7 as output
PB_KEEP		= %10000000	; keep PB7
PB_MASK		= %00100101	; VIAport address

ak_mk		= sysptr	; *** needed zeropage pointer ***

; ****************************************
; *** read from buffer to output block ***
; ****************************************
ak_read:
	LDA bl_ptr+1			; save pointer MSB
	PHA
	LDY #0				; reset index
ak_rloop:
		LDA bl_siz			; check remaining
		ORA bl_siz+1
			BEQ blck_end			; nothing to do
		JSR ak_get			; *** get one byte from buffer***
			BCS blck_end		; any error ends transfer!
		STA (bl_ptr),Y			; ...goes into buffer
		INY					; next byte, check carry
		BNE ak_nw
			INC bl_ptr+1
ak_nw:
		DEC bl_siz			; one less to go
		LDA bl_siz			; check whether wrapped
		CMP #$FF
		BNE blck_end			; no wrap, all done
			LDA bl_siz+1			; any page remaining?
		BEQ blck_end			; no, exit
			DEC bl_siz+1			; ...or one page less
		_BRA ak_rloop
blck_end:
	PLA					; restore MSB
	STA bl_ptr+1
	RTS					; respect whatever error code

ak_err:
	_DR_ERR(NO_RSRC)		; cannot do this

; ************************
; *** initialise stuff ***
; ************************
ak_init:
; reset FIFO
	_STZA ak_fi
	_STZA ak_fo
; clear previous scancodes
	_STZA ak_rmod
	_STZA ak_cmod
	_STZA ak_scod
; clear deadkey
	_STZA ak_dead
; preset repeat counters
	LDA #AR_DEL
	STA ak_del
	LDA #AR_RATE
	STA ak_rep

	_DR_OK				; succeeded


; *******************************
; *** read one byte from FIFO *** A -> char, C = empty, uses X
; *******************************
ak_get:
	LDX ak_fo			; get output position
	CPX ak_fi			; is it empty?
	BNE ak_some			; no, do extract
		_DR_ERR(EMPTY)			; yes, do nothing
ak_some:
	LDA ak_buff, X		; extract char
	INX					; this is no more
	CPX #AF_SIZ			; wrapped?
	BNE ak_rnw				; no
		LDX #0					; or yes, back to zero
ak_rnw:
	STX ak_fo			; eeeeeeeeeek
	_DR_OK

; *******************************
; *** push one byte into FIFO *** A <- char, uses X
; *******************************
ak_push:
	LDX ak_fi			; get input position
	STA ak_buff, X		; insert char
	INX					; go for first free position
	CPX #AF_SIZ			; wrapped?
	BNE ak_wnw				; no
		LDX #0					; or yes, back to zero
ak_wnw:
	STX ak_fi			; update pointer
	CPX ak_fo			; is it full?
	BNE ak_room			; no, all OK
		INC ak_fo			; yes, simply discard oldest byte
		LDA ak_fo			; but check for wrap, too
		CMP #AF_SIZ
	BNE ak_room			; did not, all done
		_STZA ak_fo			; or go back to zero
ak_room:
	RTS					; no errors here

; ******************************************************
; *** scan matrix and put char on FIFO, if available *** D_POLL task
; ******************************************************
ak_poll:
; must setup VIA first!!
	LDA VIA_U+IORB		; set control port
	AND #PB_KEEP		; keep desired bits
	ORA #PB_MASK		; set accordingly
	STA VIA_U+IORB
	LDA VIA_U+DDRA		; save older port config
	STA ak_ddra
	LDA #PA_MASK		; prepare for this device
	STA VIA_U+DDRA
; scan modifier column
	LDX #15			; maximum column index (modifiers)
	JSR ap_scol		; scan this column
	_CRITIC			; will use zeropage interrupt space!
	CMP ak_rmod		; any change on these?
	BNE ap_eqm		; no, just scan the rest
		STA ak_rmod		; update modifier combo
; update status of caps lock LED...
		AND #1			; caps lock=bit 0
		TAY			; keep for status
		ASL
		ASL
		ASL			; now is bit 3, ready for PB3
		EOR VIA_U+IORB		; TOGGLE PB3, thus caps lock LED
		STA VIA_U+IORB
; ...and toggle caps lock status bit
		LSR ak_cmod		; clear caps lock bit...
		TYA			; is caps lock on?
		BEQ ap_updc		; nope...
			SEC			; ...or yes...
ap_updc:
		ROL ak_cmod		; ...update this bit
; get table address for this modifier combo
		LDA ak_cmod		; retrieve modifier status
		ASL				; table offsets need 9 bits!
		TAX				; index for modifier combos
		LDY ak_mods, X	; get pointer on main table for these modifiers
		LDA ak_mods+1, X
		STY ak_mk		; save for later!
		STA ak_mk+1
ap_eqm:
	LDX #14			; last regular column
ap_sloop:
		JSR ap_scol		; scan this one
			BNE ap_kpr		; some key pressed
		DEX				; next column
		BPL ap_sloop
	_STZA ak_scod		; clear previous scancode! eeeeeeeek
ap_end:
	_NO_CRIT		; eeeeeeeeek
	RTS				; none pressed, all done
; we have a raw, incomplete scancode, must convert it
ap_kpr:
	LDY #0			; clear row number (hopefully will stop)
ap_bshf:
		LSR				; shift until A is clear
	BEQ ap_scok		; Y is the highest row pressed!
		INY				; next row
		BNE ap_bshf		; will finish eventually
ap_scok:
	TYA				; base row index
	ORA col4, X		; include column index!
; must check whether scancode is different from last poll
	CMP ak_scod		; any changes?
	BNE ap_char		; yes, get ASCII and put into buffer
; *** no changes, but could implement repeat here ***
;		BEQ ap_end		; do nothing if repeat is not implemented
		LDY ak_del		; already repeating?
		BEQ ak_rpt		; go check its counter
			DEC ak_del		; decrement delay counter...
			BNE ap_end		; ...but do not repeat yet
; delay counter has expired, start repeating at its rate
ak_rpt:
		DEC ak_rep		; rate counter...
		BNE ap_end		; ...abort if not expired...
	LDY #AR_RATE		; ...or reload rate counter...
	STY ak_rep
	BNE ap_dorp		; ...and send repeated char!
; finish repeat (if active) and get ready for new char
ap_char:
	LDY #AR_DEL		; preset repeat counters
	STY ak_del
	LDY #AR_RATE
	STY ak_rep
; ** end of repeat code **
	STA ak_scod		; save last detected! eeeeeeeeek
; get ASCII from compound scancode
ap_dorp:
	TAY				; use scancode as post-index
; *** should manage dead key(s) here ***
	CPY #$2E		; acute accent/umlaut scancode?
	BNE ap_ndk		; do not set
		LDX #2			; or enter deadkey mode 1 (acute)
		LDA ak_cmod		; check modifiers
		AND #8			; only shift bit supported
		BEQ ap_numl		; not shifed...
			LDX #6			; ...or set deadkey mode 2 (uml)
ap_uml:
		STX ak_dead		; set deadkey mode...
		BNE ap_end		; ...and exit without key
ap_ndk:
	LDX ak_dead		; are we in deadkey mode?
	BEQ ak_live		; no, decode as usual
		LDA ak_cmod		; or yes, check modifiers
		AND #%1001		; only shift & capslock supported
		BEQ adk_ns		; will use unshifted dead table
			LDX ak_dead		; or get original deadkey mode...
			INX			; ...and advance to next table
			INX
adk_ns:
		LDA ak_dkpt, X		; get base pointer for accented chars
		STA ak_mk		; and set for indirect mode
		LDA ak_dkpt+1, X
		STA ak_mk+1
;		LDA (ak_mk), Y		; take ASCII
;		BNE ak_got		; if related, print adecuate char
; otherwise is unrelated to dead key
; ** end of deadkey code **
ak_live:
	_STZA ak_dead		; ** is this OK? **
	LDA (ak_mk), Y		; this is the ASCII code
ak_got:
	_NO_CRIT		; zeropage is free
	JMP ak_push		; goes into FIFO... and return to ISR

; **************************
; *** auxiliary routines ***
; **************************

; get rows in A as selected in column X
ap_scol:
	LDA col4, X		; column times 4
	ASL				; make it times 16 for port
	ASL
	STA VIA_U+IORA		; place output bits (select column)
; fastest machines may need some delay here
	LDA VIA_U+IORA		; get row values back
	AND #$0F		; just the low nibble
	RTS

; *** misc ***
ak_nreq:
	_NXT_ISR		; in case gets called, exit ASAP

; *******************************
; *** diverse data and tables ***
; *******************************

; column index times 4 for compound scancodes
col4:
	.byt	 0,  4,  8, 12, 16, 20, 24, 28
	.byt	32, 36, 40, 44, 48, 52, 56

; pointers to tables depending on modifiers
ak_mods:
	.word	ak_traw, ak_tu,   ak_ta,   ak_tua,  ak_tc,   ak_tuc,  ak_tac,  ak_tuac
	.word	ak_ts,   ak_tsu,  ak_tsa,  ak_tsua, ak_tsc,  ak_tsuc, ak_tsac, ak_tsuac

; *** scancode to ASCII tables***
; cols 0...14, and inside rows 0...3

; unshifted
ak_traw:
	.byt	$20, $3C, $09, $BA,  $7A, $61, $71, $31,  $78, $73, $77, $32
	.byt	$63, $64, $65, $33,  $76, $66, $72, $34,  $62, $67, $74, $35
	.byt	$6E, $68, $79, $36,  $6D, $6A, $75, $37,  $2C, $6B, $69, $38
	.byt	$2E, $6C, $6F, $39,  $2D, $F1, $70, $30,  $0 , $0 , $60, $27
	.byt	$0 , $E7, $2B, $A1,  $0A, $0B, $0D, $08,  $0C, $0 , $7F, $1B

; caps lock (with or without control)
ak_tu:
ak_tuc:
	.byt	$20, $3C, $09, $BA,  $5A, $41, $51, $31,  $58, $53, $57, $32
	.byt	$43, $44, $45, $33,  $56, $46, $52, $34,  $42, $47, $54, $35
	.byt	$4E, $48, $59, $36,  $4D, $4A, $55, $37,  $2C, $4B, $49, $38
	.byt	$2E, $4C, $4F, $39,  $2D, $D1, $50, $30,  $0 , $0 , $60, $27
	.byt	$0 , $C7, $2B, $A1,  $0A, $0B, $0D, $08,  $0C, $0 , $7F, $1B

; alt
ak_ta:
	.byt	$0 , $AB, $0 , $5C,  $0 , $E0, $0 , $7C,  $0 , $A7, $0 , $40
	.byt	$A9, $F0, $A4, $23,  $0 , $0 , $E8, $A2,  $DF, $0 , $FE, $0
	.byt	$0 , $0 , $A5, $AC,  $B5, $0 , $F9, $0 ,  $0 , $0 , $EC, $0
	.byt	$0 , $0 , $F2, $0 ,  $0 , $7E, $F8, $0 ,  $0 , $7B, $5B, $0
	.byt	$0 , $7D, $5D, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0

; caps lock & alt
ak_tua:
	.byt	$0 , $AB, $0 , $5C,  $0 , $C0, $0 , $7C,  $0 , $A7, $0 , $40
	.byt	$A9, $D0, $A4, $23,  $0 , $0 , $C8, $A2,  $DF, $0 , $DE, $0
	.byt	$0 , $0 , $A5, $AC,  $B5, $0 , $D9, $0 ,  $0 , $0 , $CC, $0
	.byt	$0 , $0 , $D2, $0 ,  $0 , $B6, $D8, $0 ,  $0 , $7B, $5B, $0
	.byt	$0 , $7D, $5D, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0

; control
ak_tc:
	.byt	$00, $00, $00, $00,  $1A, $01, $11, $00,  $18, $13, $17, $00
	.byt	$03, $04, $05, $00,  $16, $06, $12, $00,  $02, $07, $14, $00
	.byt	$0E, $08, $19, $00,  $0D, $0A, $15, $00,  $00, $0B, $09, $00
	.byt	$00, $0C, $0F, $00,  $00, $00, $10, $00,  $0 , $00, $00, $00
	.byt	$0 , $00, $00, $00,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0

; alt & control
ak_tac:
	.byt	$0 , $0 , $0 , $0 ,  $B8, $E2, $0 , $0 ,  $0 , $A8, $0 , $0
	.byt	$0 , $0 , $EA, $0 ,  $0 , $0 , $AE, $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $0 , $0 ,  $0 , $0 , $FB, $0 ,  $0 , $0 , $EE, $0
	.byt	$0 , $0 , $F4, $0 ,  $0 , $E3, $F5, $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0

; caps & alt & control
ak_tuac:
; shift & alt & control (same as above, this far)
ak_tsac:
; shift & caps & alt & control (same as above, this far)
ak_tsuac:
	.byt	$0 , $0 , $0 , $0 ,  $B4, $C2, $0 , $0 ,  $0 , $A6, $0 , $0
	.byt	$0 , $0 , $CA, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $0 , $0 ,  $0 , $0 , $DB, $0 ,  $0 , $0 , $CE, $0
	.byt	$0 , $0 , $D4, $0 ,  $0 , $C3, $D5, $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0

; shift (with or without caps lock)
ak_ts:
ak_tsu:
	.byt	$A0, $3E, $0 , $AA,  $5A, $41, $51, $21,  $58, $53, $57, $22
	.byt	$43, $44, $45, $B7,  $56, $46, $52, $24,  $42, $47, $54, $25
	.byt	$4E, $48, $59, $26,  $4D, $4A, $55, $2F,  $2C, $4B, $49, $28
	.byt	$2E, $4C, $4F, $29,  $2D, $D1, $50, $3D,  $0 , $0 , $5E, $3F
	.byt	$0 , $C7, $2A, $BF,  $0A, $0B, $0D, $08,  $0C, $0 , $7F, $1B

; shift & alt (with or without caps lock)
ak_tsa:
ak_tsua:
	.byt	$0 , $BB, $0 , $0 ,  $0 , $C0, $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $D0, $0 , $0 ,  $0 , $0 , $C8, $A3,  $0 , $0 , $DE, $0
	.byt	$0 , $0 , $0 , $AF,  $0 , $0 , $D9, $0 ,  $0 , $0 , $CC, $0
	.byt	$0 , $0 , $D2, $0 ,  $0 , $B6, $D8, $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $B1, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0

; shift & control (with or without caps lock) TBD
ak_tsc:
ak_tsuc:
	.byt	$0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0

; ** tables for deadkey(s), just one in Spanish **
; unshifted
ak_draw:
	.byt	$0, $0, $0, $0,  $0, $0, $0, $0,  $0, $0, $0, $0
	.byt	$0, $0, $0, $0,  $0, $0, $0, $0,  $0, $0, $0, $0
	.byt	$0, $0, $0, $0,  $0, $0, $0, $0,  $0, $0, $0, $0
	.byt	$0, $0, $0, $0,  $0, $0, $0, $0,  $0, $0, $0, $0
	.byt	$0, $0, $0, $0,  $0, $0, $0, $0,  $0, $0, $0, $0

; shift and/or caps lock
ak_dsu:

	.byt	$0, $0, $0, $0,  $0, $0, $0, $0,  $0, $0, $0, $0
	.byt	$0, $0, $0, $0,  $0, $0, $0, $0,  $0, $0, $0, $0
	.byt	$0, $0, $0, $0,  $0, $0, $0, $0,  $0, $0, $0, $0
	.byt	$0, $0, $0, $0,  $0, $0, $0, $0,  $0, $0, $0, $0
	.byt	$0, $0, $0, $0,  $0, $0, $0, $0,  $0, $0, $0, $0

.)
