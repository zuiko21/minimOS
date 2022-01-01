; 64-key ASCII keyboard for minimOS!
; v0.6.1a2
; (c) 2012-2022 Carlos J. Santisteban
; last modified 20201009-1011
; new VIAport interface version

; VIA bit functions
; PA0...3	= input from selected column
; PA4...7	= output (selected column)
; PB0		= caps lock status, will be latched for LED
; *** in case an LCD is integrated, PA3 might be temprorarily _output_ as RS line, while PB0 will create the E pulse ***

; new VIA-connected device ID (at PB) is $AC when caps lock is on, and $AD otherwise
; could jumper-enable the use of $2C/$2D, in case PB7 output is being used
; might reserve $AE & $AF (perhaps with $2E/$2F) for optional LCD module

; ** driver variables description **
; ak_fi, first free element in FIFO
; ak_fo, element ready for exit in FIFO
;  *** CHECK
; ak_ddra, old port config
; ak_iorb, old command
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
; xa drivers/asc_kbd.s -I drivers/ -DTESTING=1
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

; uncomment for non-PB7 savvy
#define	PB7KEEP	_PB7KEEP

; uncomment for optional LCD module support
#define	LCDCHAR	_LCDCHAR
; ******************************
; *** standard minimOS stuff ***
; ******************************

; *** begins with sub-function addresses table *** note options
	.byt	145			; physical driver number D_ID (TBD)
#ifndef	LCDCHAR
	.byt	A_BLIN|A_POLL	; input driver, periodic interrupt-driven
	.word	ak_read		; read from input buffer
	.word	ak_err		; no output
#else
	.byt	A_BLIN|A_BOUT|A_POLL	; I/O driver, periodic interrupt-driven
	.word	ak_read		; read from input buffer
	.word	ak_out		; output to LCD
#endif
	.word	ak_init		; initialise 'device', called by POST only
	.word	ak_poll		; periodic interrupt...
	.word	5			; 20ms scan seems fast enough
	.word	ak_nreq		; D_ASYN does nothing
	.word	ak_err		; no config
	.word	ak_err		; no status
	.word	ak_exit		; shutdown procedure, leave VIA as it was...
	.word	ak_info		; points to descriptor string
	.word	0			; non-relocatable, D_MEM

; *** driver description ***
ak_info:
#ifndef	LCDCHAR
	.asc	"ASCII keyboard v0.6.1", 0
#else
	.asc	"ASCII keyboard + LCD module v0.6.1", 0
#endif

; *** some constant definitions ***
AF_SIZ		= 16		; buffer size (only 15 useable) no need to be power of two
AR_DEL		= 35		; 35×20 ms (0.7s) original delay
AR_RATE		= 5			; 5×20 ms (1/10s) original repeat rate
PA_MASK		= %11110000	; PA0-3 as input, PA4-7 as output, PA3 only output for optional LCD module
PB_CAPS		= %00000001	; PB0 indicates caps lock status (0=on!)
#ifdef	PB7KEEP
PB_CMD		= $2C		; VIAport address (caps lock on, add PB_CAPS for caps lock off) not disturbing with PB7
PB_LCD		= $2F		; just in case (E is HIGH, will DEC later)
PB_KEEP		= %10000000	; PB7 must be kept undisturbed
#else
PB_CMD		= $AC		; VIAport address (caps lock on, add PB_CAPS for caps lock off) but cannot use PB7
PB_LCD		= $AF		; just for convenience (E is HIGH, will DEC later)
#endif
#ifdef	LCDCHAR
PA_RS		= %00001000	; RS is PA3 for optional LCD
#endif
ak_mk		= sysptr	; *** required zeropage pointer ***

; ****************************************
; *** read from buffer to output block *** usual mandatory loop
; ****************************************
ak_read:
	LDA bl_ptr+1		; save pointer MSB
	PHA
	LDY #0				; reset index
ak_rloop:
		LDA bl_siz			; check remaining
		ORA bl_siz+1
			BEQ blck_end		; nothing to do
		JSR ak_get			; *** get one byte from buffer***
			BCS blck_end		; any error ends transfer!
		STA (bl_ptr),Y		; ...goes into buffer
		INY					; next byte, check carry
		BNE ak_nw
			INC bl_ptr+1
ak_nw:
		DEC bl_siz			; one less to go
		LDA bl_siz			; check whether wrapped
		CMP #$FF
		BNE blck_end		; no wrap, all done
			LDA bl_siz+1		; any page remaining?
		BEQ blck_end		; no, exit
			DEC bl_siz+1		; ...or one page less
		_BRA ak_rloop
blck_end:
	PLA					; restore MSB
	STA bl_ptr+1
	RTS					; respect whatever error code

ak_err:
	_DR_ERR(NO_RSRC)	; cannot do this

; *****************************
; *** write to optional LCD *** 
; *****************************
ak_out:
	LDA bl_ptr+1		; get pointer MSB
	PHA					; in case gets modified...
	LDY #0				; reset index
lp_l:
		_PHY				; keep this
		LDA (bl_ptr), Y		; buffer contents...
		STA io_c			; ...will be sent
		JSR lcd_char		; *** print one byte ***
			BCS lcd_exit		; any error ends transfer!
		_PLY				; restore index
		INY					; go for next
		DEC bl_siz			; one less to go
			BNE lp_l			; no wrap, continue
		LDA bl_siz+1		; check MSB otherwise
			BEQ lcd_end			; no more!
		DEC bl_siz+1		; ...or one page less
		_BRA lp_l
lcd_exit:
	PLA					; discard saved index
lcd_end:
	PLA					; get saved MSB...
	STA bl_ptr+1		; ...and restore it
lcd_rts:
	RTS					; exit, perhaps with an error code

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
; caps lock status is reset, as bit 0 from ak_comd will be inverted towards PB0
	_STZA ak_scod
; optional stuff
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
; *** in case LCD is installed, reset it too ***
#ifdef	LCDCHAR
; * * * T O   D O * * *
#endif
; all done
ak_exit:				; placeholder
	_DR_OK				; succeeded

#ifdef	LCDCHAR
; *************************************
; *** optional LCD character output ***
; *************************************
lcd_char:				; placeholder
; *** *** really OUGHT to make a generic routine for this, with a variable RS *** ***
	TAX					; keep character
	AND #PA_MASK		; filter MSN first
	ORA #PA_RS			; set RS=1
	STA VIA_U+IORA		; put data on VIAport
	LDA VIA_U+DDRA		; make sure PA3 is output for RS
	ORA #PA_RS			; enable RS
	STA VIA_U+DDRA		; all data is ready
#ifdef	PB7KEEP
	LDA VIA_U+IORB		; original command
	AND #PB_KEEP		; keep PB7 status from it
	ORA #PB_LCD			; select LCD with E high
#else
	LDA #PB_LCD			; just select LCD with E high
#endif
	STA VIA_U+IORB		; issue LCD command (sets E)
	DEC VIA_U+IORB		; ...and E goes down for a moment
	TXA					; retrieve original char
	ASL					; will keep LSN (might use SEC & ROL instead but not worth)
	ASL
	ASL
	ASL
	ORA #PA_RS			; enable RS as this is a char
	STA VIA_U+IORA		; put data on VIAport
	INC VIA_U+IORB		; and pulse E again
	DEC VIA_U+IORB		; *** this may suffice, instead of issuing a NULL PB command ***
; *** *** end of LCD transfer "routine" *** ***
	_DR_OK				; should succeed...
#endif

; ******************************************************
; *** scan matrix and put char on FIFO, if available *** D_POLL task
; ******************************************************
ak_poll:
; must setup VIA first!!
; note stacking order, DDRA-(IORA)-DDRB
	LDA VIA_U+DDRA		; save older port config
	PHA
	LDA #PA_MASK		; prepare for this device
	STA VIA_U+DDRA
#ifdef	SAFE
	LDA VIA_U+IORA		; save this too, just in case
	PHA
#endif
	LDA VIA_U+DDRB		; previous PB config?
	PHA					; don't forget!
; create command with caps lock status, perhaps saving PB7
#ifdef	PB7KEEP
	LDA VIA_U+IORB		; get control port
	AND #PB_KEEP		; keep desired bits
	ORA ak_cmod			; and look for the status (won't mess with PB4...7 anyway)
	AND #PB_CAPS|PB_KEEP	; only PB7 and caps lock
#else
	LDA ak_cmod			; get whole status
	AND #PB_CAPS		; just for caps lock
#endif
	EOR #PB_CAPS		; LED goes inverted!
	ORA #PB_CMD			; set single command
#endif
	STA VIA_U+IORB		; issue VIAport command!
#ifdef	SAFE
	LDY #$FF			; useful?
	STY VIA_U+DDRB		; PB must be all output
#endif
; scan modifier column
	LDX #15				; maximum column index (modifiers)
	JSR ap_scol			; scan this column
	_CRITIC				; will use zeropage interrupt space!
	CMP ak_rmod			; any change on these?
	BNE ap_eqm			; no, just scan the rest
		STA ak_rmod			; update raw modifier combo...
		LSR					; pressing caps lock?
		BCC ap_selt			; no, just check other modifiers
; toggle caps lock status bit (A holds shifted modifiers) *** *** REVISE *** ***
			LDA ak_cmod			; get older caps state
			EOR #PB_CAPS		; just FUCKING toggle it...
			STA ak_cmod			; update all bits, will update caps lock LED on next read!
; get table address for this modifier combo
ap_selt:
		LDA ak_cmod			; retrieve modifier status EEEEEEEK
#ifdef	DEADKEY
; *** check whether in deadkey mode for simplified modifier handling ***
		LDX ak_dead			; will be modified by previous deadkey?
			BNE ap_dset			; yeah
#endif
; standard table select
		ASL					; table offsets need 9 bits!
		TAX					; index for modifier combos
		LDY ak_mods, X		; get pointer on main table for these modifiers
		LDA ak_mods+1, X
#ifdef	DEADKEY
; *** deadkey table handling ***
		BNE ap_pset			; set this pointer (BRA)
ap_dset:
			AND #%1001			; detect shift or caps ONLY
			BEQ ap_dns			; unshifted...
				INX					; ...or point to next table
				INX
ap_dns:
			LDY ak_dktb, X		; get pointer for deadkey-modified
			LDA ak_dktb+1, X
ap_pset:
#endif
		STY ak_mk			; save for later!
		STA ak_mk+1
ap_eqm:
	LDX #14				; last regular column
ap_sloop:
		JSR ap_scol			; scan this one
			BNE ap_kpr			; some key pressed
		DEX					; next column
		BPL ap_sloop
	_STZA ak_scod		; clear previous scancode! eeeeeeeek
ap_end:
	_NO_CRIT			; eeeeeeeeek
	RTS					; none pressed, all done
; we have a raw, incomplete scancode, must convert it
ap_kpr:
	LDY #0				; clear row number (hopefully will stop)
ap_bshf:
		LSR					; shift until A is clear
	BEQ ap_scok			; Y is the highest row pressed!
		INY					; next row
		BNE ap_bshf			; will finish eventually
ap_scok:
	TYA					; base row index
	ORA col4, X			; include column index!
; must check whether scancode is different from last poll
	CMP ak_scod			; any changes?
	BNE ap_char			; yes, get ASCII and put into buffer
#ifndef	REPEAT
		BEQ ap_end			; do nothing if repeat is not implemented
ap_char:
#else
		LDY ak_del			; already repeating?
		BEQ ak_rpt			; go check its counter
			DEC ak_del			; decrement delay counter...
			BNE ap_end			; ...but do not repeat yet
; delay counter has expired, start repeating at its rate
ak_rpt:
		DEC ak_rep			; rate counter...
		BNE ap_end			; ...abort if not expired...
	LDY ak_vrep			; ...or reload rate counter...
	STY ak_rep
	BNE ap_dorp			; ...and send repeated char!
; finish repeat (if active) and get ready for new char
ap_char:
	LDY ak_vdel			; preset repeat counters
	STY ak_del
	LDY ak_vrep
	STY ak_rep
#endif
	STA ak_scod			; save last detected! eeeeeeeeek
; get ASCII from compound scancode
ap_dorp:
	TAY					; use scancode as post-index
	LDA (ak_mk), Y		; this is the ASCII code
	_NO_CRIT			; zeropage is free
#ifdef	DEADKEY
	LDX ak_dead			; check whether an actual deadkey-generated char
		BNE ap_live			; yes, no further checking
	CMP #$B4			; acute?
	BNE apd_b4
		LDA #2				; first half table of dead keys
		BNE ap_dead
apd_b4:
	CMP #$A8			; umlaut? last to be checked
	BNE ap_live
		LDA #6				; last of half-tables for deadkeys
ap_dead:
		STA ak_dead			; set deadkey mode and exit!
		RTS
ap_live:
	_STZA ak_dead			; no repeat for deadkeys, this far
#endif
;	JMP ak_push			; goes into FIFO... and return to ISR
; no need for the above if ak_push code follows! it's the only use!

; **************************
; *** auxiliary routines ***
; **************************

; *** push one byte into FIFO *** A <- char, uses X
; actually inlined as only used by interrupt task
ak_push:
	LDX ak_fi			; get input position
	STA ak_buff, X		; insert char
	INX					; go for first free position
	CPX #AF_SIZ			; wrapped?
	BNE ak_wnw			; no
		LDX #0				; or yes, back to zero
ak_wnw:
	STX ak_fi			; update pointer
	CPX ak_fo			; is it full?
	BNE ak_room			; no, all OK
		DEC ak_fi			; yes, simply discard THIS byte
		SEC					; notify error
		LDY #FULL
	BPL ak_room			; did not wrap, all done
		LDA #AF_SIZ-1		; or just place it at the end
		STA ak_fi
ak_room:
; *** as this is the interrupt task exit, must restore VIA config ***
#ifdef	SAFE
	PLA
	STA VIA_U+DDRB		; restore previous PB status
#endif
#ifdef	PB7KEEP
	LDA #PB_KEEP^$FF	; disable selection, but respect PB7
	ORA VIA_U+IORB		; current status for PB7
	STA VIA_U+IORB
#else
	STY VIA_U+IORB		; null device selected, end of operation
#endif
	PLA
	STA VIA_U+DDRA		; restore older PA config
	RTS					; no errors here

; *** read one byte from FIFO *** A -> char, C = empty, uses X
; perhaps worth inlining, but take care of error code (Y and P.C)
ak_get:
	LDX ak_fo			; get output position
	CPX ak_fi			; is it empty?
	BNE ak_some			; no, do extract
		_DR_ERR(EMPTY)		; yes, do nothing
ak_some:
	LDA ak_buff, X		; extract char
	INX					; this is no more
	CPX #AF_SIZ			; wrapped?
	BNE ak_rnw			; no
		LDX #0				; or yes, back to zero
ak_rnw:
	STX ak_fo			; eeeeeeeeeek
	_DR_OK

; *** get rows in A as selected in column X ***
; cannot be inlined...
ap_scol:
	LDA col4, X			; column times 4
	ASL					; make it times 16 for port
	ASL
	STA VIA_U+IORA		; place output bits (select column)
; fastest machines may need some delay here
	LDA VIA_U+IORA		; get row values back
	AND #$0F			; just the low nibble
	RTS

; *** misc ***
ak_nreq:
	_NXT_ISR			; in case gets called, exit ASAP

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
