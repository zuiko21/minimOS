; 64-key ASCII keyboard for minimOS-16!
; v0.6a3
; (c) 2012-2022 Carlos J. Santisteban
; last modified 20200306-1001

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
#ifndef		HEADERS
#ifdef			TESTING
; ** special include set to be assembled via... **
; xa -w drivers/asc_kbd16.s -I drivers/ -DTESTING=1
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
#include "asc_kbd.h"
.text
#endif

.(
; ***************
; *** options ***
; ***************

; uncomment for repeat (except for deadkeys)
#define	REPEAT	_REPEAT

; uncomment for deadkey support (Spanish only this far)
#define	DEADKEY	_DEADKEY

; ******************************
; *** standard minimOS stuff ***
; ******************************

; *** begins with sub-function addresses table ***
	.byt	145			; physical driver number D_ID (TBD)
	.byt	A_BLIN|A_POLL	; input driver, periodic interrupt-driven
	.word	ak_read		; read from input buffer
	.word	ak_err		; no output
	.word	ak_init		; initialise 'device', called by POST only
	.word	ak_poll		; periodic interrupt...
	.word	4			; 20ms scan seems fast enough
	.word	ak_nreq		; D_ASYN does nothing
	.word	ak_err		; no config
	.word	ak_err		; no status
	.word	ak_exit		; shutdown procedure, leave VIA as it was...
	.word	ak_info		; points to descriptor string
	.word	0			; non-relocatable, D_MEM

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
	.xl: REP #$10			; 16-bit index for loops!
	LDY #0				; reset index (3)
	LDX bl_siz			; check remaining
	BEQ blck_end			; nothing to do
ak_rloop:
		PHY					; must keep this
		PHP
		.as: .xs: SEP #$30	; make sure all 8-bit
		JSR ak_get			; *** get one byte from buffer*** respect Y
			BCS blck_end		; any error ends transfer!
		PLP: .xl				; restore sizes AND counter
		PLY
		STA [bl_ptr], Y			; ...goes into buffer
		INY					; next byte, check carry
		LDX bl_siz			; bytes to go
		DEX					; one less
		STX bl_siz			; update
		BNE ak_rloop			; continue with remaining, or end
blck_end:
	RTS					; respect whatever error code

; ************************
; *** initialise stuff *** could optimise in 16-bit amounts
; ************************
ak_init:
; reset FIFO
	STZ ak_fi
	STZ ak_fo
; clear previous scancodes
	STZ ak_rmod
	STZ ak_cmod
	STZ ak_scod
#ifdef	DEADKEY
; clear deadkey mode
	STZ ak_dead
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
		LSR				; pressing caps lock?
		BCC ap_selt		; no, just check other modifiers
; toggle caps lock status bit (A holds shifted modifiers)
			LSR ak_cmod		; get older cpaps state
			BCC ap_cup		; was off, turn it on...
				CLC				; ...or turn off if was on
				BCC ap_cok
ap_cup:
			SEC				; this turns caps on
ap_cok:
			ROL				; reinsert new status together with other bits
			STA ak_cmod		; update all bits
			AND #1			; current caps lock status
			TAY				; keep for later
; and update status of caps lock LED
			LDA VIA_U+IORB	; clear PB3, thus caps lock LED
			AND #%11110111
			CPY #0			; is caps lock on?
			BEQ ap_updc		; nope...
				ORA #%00001000	; ...or yes
ap_updc:
			STA VIA_U+IORB	; update LED status
; get table address for this modifier combo
ap_selt:
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
	STZ ak_scod		; clear previous scancode! eeeeeeeek
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
	_NO_CRIT		; zeropage is free
#ifdef	DEADKEY
	LDX ak_dead		; check whether an actual deadkey-generated char
		BNE ap_live		; yes, no further checking
	CMP #$B4		; acute?
	BNE apd_b4
		LDA #2			; first half table of dead keys
		BNE ap_dead
apd_b4:
	CMP #$A8		; umlaut? last to be checked
	BNE ap_live
		LDA #6			; last of half-tables for deadkeys
ap_dead:
		STA ak_dead		; set deadkey mode and exit!
		RTS
ap_live:
	STZ ak_dead		; no repeat for deadkeys, this far
#endif
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
		DEC ak_fi			; yes, simply discard THIS byte
		SEC					; notify error
		LDY #FULL
	BPL ak_room			; did not wrap, all done
		LDA #AF_SIZ-1			; or just place it at the end
		STA ak_fi
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
ak_err:
	_DR_ERR(NO_RSRC)		; cannot do this

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

; *** keyboard layout definition, use previous labels! ***
#include "drivers/keys/akbd_lay.s"
.)
