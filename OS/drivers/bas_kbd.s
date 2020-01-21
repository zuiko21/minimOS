; 64-key ASCII keyboard for minimOS, simple version
; v0.6a2
; (c) 2018-2020 Carlos J. Santisteban
; last modified 20200121-1333

; *** caveats ***
; alt not recognised
; no repeat or deadkeys
; single-byte buffer

; VIA bit functions
; PA0...3	= input from selected column
; PA4...7	= output (selected column)
; PB3		= caps lock LED (hopefully respected!)

; new VIA-connected device ID is $A5/AD, $25/2D with PB7 off (%x010x101)

; ** driver variables description **
; ak_ddra, old port config
; ak_rmod, last detected raw modifier combo
;	d0 = caps lock
;	d1 = alt
;	d2 = control
;	d3 = shift
; ak_cmod, modifier status (like ak_rmod with toggling caps lock)
; ak_tof, table offset
; ak_scod, last detected scancode
; ak_get, decoded character

; ***********************
; *** minimOS headers ***
; ***********************
#ifndef		HEADERS
#ifdef			TESTING
; ** special include set to be assembled via... **
; xa drivers/bas_kbd.s -I drivers/ -DTESTING=1
#include "options.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
#else
; ** regular assembly **
#include "../usual.h"
#endif
; specific header for this driver
.bss
#include "bas_kbd.h"
.text
#endif

.(
; ******************************
; *** standard minimOS stuff ***
; ******************************

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
	.asc	"Base ASCII keyboard 0.6", 0

; *** some constant definitions ***
PA_MASK		= %11110000	; PA0-3 as input, PA4-7 as output
PB_KEEP		= %10000000	; keep PB7
PB_MASK		= %00100101	; VIAport address

; ****************************************
; *** read from buffer to output block *** usual mandatory loop
; ****************************************
ak_read:
	LDA bl_ptr+1			; save pointer MSB
	PHA
	LDY #0				; reset index
ak_rloop:
		LDA bl_siz			; check remaining
		ORA bl_siz+1
			BEQ blck_end			; nothing to do
		LDA ak_get			; *** get single byte ***
			BEQ blck_err		; not available, ends transfer!
		STA (bl_ptr),Y			; ...goes into buffer
		_STZA ak_get			; eeeeeek
		CLC
		INY					; next byte, check wrap
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
		_BRA blck_end			; cannot get another one
blck_err:
	SEC					; set error before exit
	LDY #EMPTY
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
; clear previous scancodes
	_STZA ak_rmod
	_STZA ak_cmod
	_STZA ak_scod
	_STZA ak_get
; all done
ak_exit:				; placeholder
	_DR_OK				; succeeded

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
	CMP ak_rmod		; any change on these?
	BNE ap_eqm		; no, just scan the rest
		STA ak_rmod		; update raw modifier combo
		LSR				; pressing caps lock?
		BCC ap_selt		; no, just check other modifiers
; toggle caps lock status bit...
			LSR ak_cmod		; get older caps lock status
			BCC ap_cup		; was off, turn it on...
				CLC				; ...or was on, turn off
				BCC ap_cok
ap_cup:
			SEC			; will turn caps on
ap_cok:
			ROL			; reinsert new caps status with other mod bits
			STA ak_cmod		; update all bits
			AND #1			; this is current caps lock status
			TAY				; check for presence
; ...and update status of caps lock LED!
			LDA VIA_U+IORB
			AND #%11110111	; clear PB3, thus caps lock LED
			CPY #0			; is caps lock on?
			BEQ ap_ncl		; no, let LED off
				ORA #%00001000	; set bit otherwise
ap_ncl:
			STA VIA_U+IORB	; update PB3 LED
; get table address for this modifier combo, much simpler
ap_selt:
		LDX ak_cmod
		LDA ak_mods, X	; offset wothin tables
		STA ak_tof		; will be added later
ap_eqm:
	LDX #14			; last regular column
ap_sloop:
		JSR ap_scol		; scan this one
			BNE ap_kpr		; some key pressed
		DEX				; next column
		BPL ap_sloop
	_STZA ak_scod		; clear previous scancode! eeeeeeeek
	_STZA ak_get
ap_end:
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
		BEQ ap_end		; do nothing as repeat is not implemented
ap_char:
	STA ak_scod		; save last detected! eeeeeeeeek
; get ASCII from compound scancode
ap_dorp:
	CLC
	ADC ak_tof		; add offset for modifier table
	TAX				; use full scancode as index
	LDA ak_tabs, X		; this is the ASCII code
; put char into single byte buffer, but if not read looks more reasonable to lose the LAST key
	LDY ak_get		; already clear?
	BNE ap_err		; no! just lose this character
; if the very last key is to be recorded, just store it (delete above)
		STA ak_get		; clear to go, put into single-byte buffer
	_DR_OK
ap_err:
	_DR_ERR(FULL)		; notify error if possible

; **************************
; *** auxiliary routines ***
; **************************

; *** get rows in A as selected in column X ***
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

; offsets to tables depending on modifiers
ak_mods:
	.byt	0,	60,	0,	60,	180,	180,	180,	180
	.byt	120,	120,	120,	120,	180,	180,	180,	180

; *******************************
; *** scancode to ASCII tables***
; *******************************
; cols 0...14, and inside rows 0...3

ak_tabs:
; unshifted
	.byt	$20, $3C, $09, $BA,  $7A, $61, $71, $31,  $78, $73, $77, $32
	.byt	$63, $64, $65, $33,  $76, $66, $72, $34,  $62, $67, $74, $35
	.byt	$6E, $68, $79, $36,  $6D, $6A, $75, $37,  $2C, $6B, $69, $38
	.byt	$2E, $6C, $6F, $39,  $2D, $F1, $70, $30,  $0 , $B4, $60, $27
	.byt	$0 , $E7, $2B, $A1,  $0A, $0B, $0D, $08,  $0C, $0 , $7F, $1B

; caps lock (+60)
	.byt	$20, $3C, $09, $BA,  $5A, $41, $51, $31,  $58, $53, $57, $32
	.byt	$43, $44, $45, $33,  $56, $46, $52, $34,  $42, $47, $54, $35
	.byt	$4E, $48, $59, $36,  $4D, $4A, $55, $37,  $2C, $4B, $49, $38
	.byt	$2E, $4C, $4F, $39,  $2D, $D1, $50, $30,  $0 , $B4, $60, $27
	.byt	$0 , $C7, $2B, $A1,  $0A, $0B, $0D, $08,  $0C, $0 , $7F, $1B

; shift (with or without caps lock, +120)
	.byt	$0 , $3E, $0 , $AA,  $5A, $41, $51, $21,  $58, $53, $57, $22
	.byt	$43, $44, $45, $B7,  $56, $46, $52, $24,  $42, $47, $54, $25
	.byt	$4E, $48, $59, $26,  $4D, $4A, $55, $2F,  $2C, $4B, $49, $28
	.byt	$2E, $4C, $4F, $29,  $2D, $D1, $50, $3D,  $0 , $A8, $5E, $3F
	.byt	$0 , $C7, $2A, $BF,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0

; control (with or without caps lock or shift, +180)
	.byt	$00, $00, $00, $00,  $1A, $01, $11, $00,  $18, $13, $17, $00
	.byt	$03, $04, $05, $00,  $16, $06, $12, $00,  $02, $07, $14, $00
	.byt	$0E, $08, $19, $00,  $0D, $0A, $15, $00,  $00, $0B, $09, $00
	.byt	$00, $0C, $0F, $00,  $00, $00, $10, $00,  $0 , $00, $00, $00
	.byt	$0 , $00, $00, $00,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
.)
