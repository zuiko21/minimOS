; 64-key ASCII keyboard for minimOS!
; v0.6b2
; (c) 2012-2018 Carlos J. Santisteban
; last modified 20180825-1342

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
; ak_vdel, original delay value
; ak_rep, repeat rate counter
; ak_vrep, original rate value
; ak_dead, deadkey mode flag

; ***********************
; *** minimOS headers ***
; ***********************
//#include "usual.h"
#include "options/chihuahua_plus.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
* = $200
#include "drivers/asc_kbd.h"
.text

.(
; ***************
; *** options ***
; ***************

; uncomment for repeat (except for deadkeys)
;#define	REPEAT	_REPEAT

; uncomment for deadkey support (Spanish only this far)
;#define	DEADKEY	_DEADKEY

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
	.asc	"ASCII keyboard v0.6", 0

; *** some constant definitions ***
AF_SIZ		= 16		; buffer size (only 15 useable) no need to be power of two
AR_DEL		= 35		; 35×20 ms (0.7s) original delay
AR_RATE		= 5		; 5×20 ms (1/10s) original repeat rate
PA_MASK		= %11110000	; PA0-3 as input, PA4-7 as output
PB_KEEP		= %10000000	; keep PB7
PB_MASK		= %00100101	; VIAport address

ak_mk		= sysptr	; *** required zeropage pointer ***

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
#ifdef	DEADKEY
; clear deadkey mode
	_STZA ak_dead
#endif
#ifdef	REPEAT
; preset repeat variables & counters
	LDA #AR_DEL
	STA ak_vdel
	STA ak_del
	LDA #AR_RATE
	STA ak_vrep
	STA ak_rep
#endif
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
	_CRITIC			; will use zeropage interrupt space!
	CMP ak_rmod		; any change on these?
	BNE ap_eqm		; no, just scan the rest
		STA ak_rmod		; update raw modifier combo...
		STA ak_cmod		; and compound too, caps lock is wrong
; toggle caps lock status bit
		AND #1			; caps lock=bit 0
		EOR ak_cmod		; toggle caps lock
		STA ak_cmod		; update
		AND #1			; current status
		TAY			; keep for later
; and update status of caps lock LED
		LDA VIA_U+IORB		; clear PB3, thus caps lock LED
		AND #%11110111
		CPY #0			; is caps lock on?
		BEQ ap_updc		; nope...
			ORA #%00001000	; ...or yes...
ap_updc:
		STA VIA_U+IORB
; get table address for this modifier combo
		LDA ak_cmod		; retrieve modifier status
#ifdef	DEADKEY
; *** check whether in deadkey mode for simplified modifier handling ***
		LDX ak_dead		; will be modified by previous deadkey?
			BNE ap_dset		; yeah
#endif
; standard table select
		ASL				; table offsets need 9 bits!
		TAX				; index for modifier combos
		LDY ak_mods, X	; get pointer on main table for these modifiers
		LDA ak_mods+1, X
#ifdef	DEADKEY
; *** deadkey table handling ***
		BNE ap_pset		; set this pointer (BRA)
ap_dset:
			AND #%1001		; detect shift or caps ONLY
			BEQ ap_dns		; unshifted...
				INX				; ...or point to next table
				INX
ap_dns:
			LDY ak_dktb, X	; get pointer for deadkey-modified
			LDA ak_dktb+1, X
ap_pset:
#endif
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
#ifndef	REPEAT
		BEQ ap_end		; do nothing if repeat is not implemented
ap_char:
#else
		LDY ak_del		; already repeating?
		BEQ ak_rpt		; go check its counter
			DEC ak_del		; decrement delay counter...
			BNE ap_end		; ...but do not repeat yet
; delay counter has expired, start repeating at its rate
ak_rpt:
		DEC ak_rep		; rate counter...
		BNE ap_end		; ...abort if not expired...
	LDY ak_vrep		; ...or reload rate counter...
	STY ak_rep
	BNE ap_dorp		; ...and send repeated char!
; finish repeat (if active) and get ready for new char
ap_char:
	LDY ak_vdel		; preset repeat counters
	STY ak_del
	LDY ak_vrep
	STY ak_rep
#endif
	STA ak_scod		; save last detected! eeeeeeeeek
; get ASCII from compound scancode
ap_dorp:
	TAY				; use scancode as post-index
	LDA (ak_mk), Y		; this is the ASCII code
#ifdef	DEADKEY
	CMP #$B4		; acute?
		LDA #2			; first half table of dead keys
		BNE ap_dead
	CMP #$A8		; umlaut? last to be checked
		LDA #6			; last of half-tables for deadkeys
	BNE ap_live
ap_dead:
		STA ak_dead		; set deadkey mode
		BNE ap_end		; is BRA
ap_live:
	_STZA ak_dead		; no repeat for deadkeys, this far
#endif
	_NO_CRIT		; zeropage is free
;	JMP ak_push		; goes into FIFO... and return to ISR
; no need for the above if ak_push code follows!

; **************************
; *** auxiliary routines ***
; **************************

; *** push one byte into FIFO *** A <- char, uses X
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

; *** read one byte from FIFO *** A -> char, C = empty, uses X
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

; pointers to tables depending on modifiers
ak_mods:
	.word	ak_traw, ak_tu,   ak_ta,   ak_tua,  ak_tc,   ak_tuc,  ak_tac,  ak_tuac
	.word	ak_ts,   ak_tsu,  ak_tsa,  ak_tsua, ak_tsc,  ak_tsuc, ak_tsac, ak_tsuac

#ifdef	DEADKEY
; pointers to tables of characters altered by dead keys!
; this far, only shift and/or caps lock are detected
ak_dktb:
	.word	ak_acu,  ak_acs,  ak_umu,  ak_ums
#endif

; *******************************
; *** scancode to ASCII tables***
; *******************************
; cols 0...14, and inside rows 0...3

; unshifted
ak_traw:
	.byt	$20, $3C, $09, $BA,  $7A, $61, $71, $31,  $78, $73, $77, $32
	.byt	$63, $64, $65, $33,  $76, $66, $72, $34,  $62, $67, $74, $35
	.byt	$6E, $68, $79, $36,  $6D, $6A, $75, $37,  $2C, $6B, $69, $38
	.byt	$2E, $6C, $6F, $39,  $2D, $F1, $70, $30,  $0 , $B4, $60, $27
	.byt	$0 , $E7, $2B, $A1,  $0A, $0B, $0D, $08,  $0C, $0 , $7F, $1B

; caps lock
ak_tu:
	.byt	$20, $3C, $09, $BA,  $5A, $41, $51, $31,  $58, $53, $57, $32
	.byt	$43, $44, $45, $33,  $56, $46, $52, $34,  $42, $47, $54, $35
	.byt	$4E, $48, $59, $36,  $4D, $4A, $55, $37,  $2C, $4B, $49, $38
	.byt	$2E, $4C, $4F, $39,  $2D, $D1, $50, $30,  $0 , $B4, $60, $27
	.byt	$0 , $C7, $2B, $A1,  $0A, $0B, $0D, $08,  $0C, $0 , $7F, $1B

; shift (with or without caps lock)
ak_ts:
ak_tsu:
	.byt	$0 , $3E, $0 , $AA,  $5A, $41, $51, $21,  $58, $53, $57, $22
	.byt	$43, $44, $45, $B7,  $56, $46, $52, $24,  $42, $47, $54, $25
	.byt	$4E, $48, $59, $26,  $4D, $4A, $55, $2F,  $2C, $4B, $49, $28
	.byt	$2E, $4C, $4F, $29,  $2D, $D1, $50, $3D,  $0 , $A8, $5E, $3F
	.byt	$0 , $C7, $2A, $BF,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0

; alt
ak_ta:
	.byt	$A0, $96, $0 , $5C,  $99, $E5, $93, $7C,  $0 , $DF, $B8, $40
	.byt	$A2, $F0, $A4, $23,  $91, $0 , $B6, $A2,  $90, $BE, $97, $9C
	.byt	$0 , $0 , $A5, $AC,  $B5, $E6, $0 , $F7,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $F8, $0 ,  $AF, $7E, $FE, $AD,  $0 , $7B, $5B, $0
	.byt	$0 , $7D, $5D, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0

; caps lock & alt
ak_tua:
	.byt	$A0, $96, $0 , $5C,  $99, $C5, $93, $7C,  $0 , $DF, $9A, $40
	.byt	$A2, $D0, $A4, $23,  $91, $0 , $B6, $A2,  $90, $BE, $97, $9C
	.byt	$0 , $0 , $A5, $AC,  $B5, $C6, $0 , $F7,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $D8, $0 ,  $AF, $7E, $DE, $AD,  $0 , $7B, $5B, $0
	.byt	$0 , $7D, $5D, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0

; shift & alt (with or without caps lock)
ak_tsa:
ak_tsua:
	.byt	$0 , $98, $0 , $B0,  $9F, $C5, $9B, $A6,  $0 , $A7, $9A, $B2
	.byt	$A9, $D0, $9E, $BC,  $B9, $0 , $AE, $A3,  $95, $92, $0 , $0
	.byt	$0 , $0 , $0 , $B3,  $94, $C6, $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $D8, $0 ,  $0 , $0 , $DE, $9D,  $0 , $AB, $BD, $0
	.byt	$0 , $BB, $B1, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0

; control (with or without caps lock or shift)
ak_tc:
ak_tuc:
ak_tsc:
ak_tsuc:
	.byt	$00, $00, $00, $00,  $1A, $01, $11, $00,  $18, $13, $17, $00
	.byt	$03, $04, $05, $00,  $16, $06, $12, $00,  $02, $07, $14, $00
	.byt	$0E, $08, $19, $00,  $0D, $0A, $15, $00,  $00, $0B, $09, $00
	.byt	$00, $0C, $0F, $00,  $00, $00, $10, $00,  $0 , $00, $00, $00
	.byt	$0 , $00, $00, $00,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0

; alt & control (maybe & caps & shift) *** preliminary ***
ak_tac:
ak_tuac:
ak_tsac:
ak_tsuac:
	.byt	$00, $00, $00, $00,  $1A, $01, $11, $00,  $18, $13, $17, $00
	.byt	$03, $04, $05, $00,  $16, $06, $12, $00,  $02, $07, $14, $00
	.byt	$0E, $08, $19, $00,  $0D, $0A, $15, $00,  $00, $0B, $09, $00
	.byt	$00, $0C, $0F, $00,  $00, $00, $10, $00,  $0 , $00, $00, $00
	.byt	$0 , $00, $00, $00,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0

#ifdef	DEADKEY
; ** tables for deadkey(s), just one in Spanish **
; acute unshifted
ak_acu:
	.byt	$B4, $0 , $0 , $0 ,  $0 , $E1, $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $E9, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $FD, $0 ,  $0 , $0 , $FA, $0 ,  $0 , $0 , $ED, $0
	.byt	$0 , $0 , $F3, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0

; acute with shift and/or caps lock
ak_acs:
	.byt	$B4, $0 , $0 , $0 ,  $0 , $C1, $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $C9, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $DD, $0 ,  $0 , $0 , $DA, $0 ,  $0 , $0 , $CD, $0
	.byt	$0 , $0 , $D3, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0

; diaeresis unshifted
ak_umu:
	.byt	$A8, $0 , $0 , $0 ,  $0 , $E4, $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $EB, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $FF, $0 ,  $0 , $0 , $FC, $0 ,  $0 , $0 , $EF, $0
	.byt	$0 , $0 , $F6, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0

; diaeresis with shift and/or caps lock
ak_ums:
	.byt	$A8, $0 , $0 , $0 ,  $0 , $C4, $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $CB, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $BE, $0 ,  $0 , $0 , $DC, $0 ,  $0 , $0 , $CF, $0
	.byt	$0 , $0 , $B6, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
#endif
.)
