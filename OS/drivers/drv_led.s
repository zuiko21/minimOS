; LED Keypad driver for minimOS
; as originally issued on 0.4rc1 20130521
; v0.9.2 corrected NMOS version 20160407
; (c) 2012-2016 Carlos J. Santisteban
; last modified 20160928-1053 for new interface

; in case of standalone assembly via 'xa drivers/drv_led.s'
#ifndef		DRIVERS
#include "options.h"
#include "macros.h"
#include "abi.h"		; new filename
.zero
#include "zeropage.h"
.bss
#include "firmware/firmware.h"
#include "sysvars.h"
; specific header for this driver
#include "drivers/drv_led.h"
.text
#endif

#define _led_digits	4

-drv_led:				; for compatibility with older NMI handler, added 20151015-1225

; *** begins with sub-function addresses table ***
	.byt	DEV_LED						; D_ID, new format 20150323, TBD
	.byt	A_POLL + A_CIN + A_COUT		; D_AUTH, this one does poll, no req., I/O, no 1-sec and neither block transfers, non relocatable (NEWEST HERE)
	.word	led_reset	; D_INIT, initialize device and appropiate sysptrs, called by POST only
	.word	led_get		; D_POLL, read keypad into buffer (called by ISR)
	.word	ledg_end	; D_REQ, this one can't generate IRQs, will be ignored anyway
	.word	led_cin		; D_CIN, input from buffer
	.word	led_cout	; D_COUT, output to display
	.word	ledg_end	; D_SEC, NEW, no need for 1-second interrupt
	.word	ledg_end	; D_SIN, NEW, no block input
	.word	ledg_end	; D_SOUT, NEW, no block output
	.word	ledg_end	; D_BYE, NEWER, no shutdown procedure
	.word	led_info	; D_INFO points to C-string
	.byt	0			; D_MEM, reserved bytes, relocatable drivers only, NEW 130512

; *** info string ***
led_info:
	.asc	"LED-keypad v0.9.1", 0

; *** output, rewritten 130507 ***
led_cout:
	LDA z2			; get char in case is control
	CMP #13			; carriage return? (won't just clear, but wait for next char instead)
	BNE led_ncr		; check other codes
		LDA #$FF		; -1 means next received character will clear the display
		STA led_pos		; update variable!
		_DR_OK
led_ncr:
	CMP #12			; FF clears too
		BEQ led_blank
	CMP #10			; LF clears too
	BNE led_noclear	; else, do print
led_blank:
		LDX led_len		; display size
led_clear:
		_STZA led_pos, X	; will clear LED buffer _and_ position, NMOS will *not* keep A corrected 20160407
		DEX
		BPL led_clear	; loops until all clear, zero will loop too
		_DR_OK
led_noclear:
	LDX led_pos		; check whether a new line was due
	BPL	led_nonl	; some other standard value
		JSR led_blank	; interesting in-function subroutine call, and then continue printing the new character
led_nonl:
	CMP #8			; backspace?
	BNE led_nobs
		LDX led_pos		; gets cursor position
		BEQ led_end		; nothing to delete
		DEX				; else, backs off one place
		_STZA led_buf, X	; clear position
		STX led_pos		; update cursor position
led_end:
		_DR_OK
led_nobs:
	CMP #'.'		; may add dot to previous char
		BNE led_nodot
	LDX led_pos		; gets cursor position
		BEQ led_nodot	; nothing before
	DEX				; go to previous character, but let variable as it was
	LDA led_buf, X	; previous char. bitmap
	LSR				; check LSB for decimal point
		BCS led_nodot	; already has dot, go away
	INC led_buf, X	; add decimal point
	_DR_OK
led_nodot:
	CMP #' '		; check whether is non-printable
	BPL led_print	; OK to print
		LDA #' '		; put a space instead (or another char?)
		STA z2			; modify parameter!
led_print:
	LDA led_pos		; cursor position
	CMP led_len		; is display full?
		BMI led_cur		; else, don't scroll
	LDX #0			; reset index
led_scroll:
		LDA led_buf+1, X	; get from second character
		STA led_buf, X	; copy it before
		INX				; get next character
		CPX led_len		; until screen ends
		BNE led_scroll	; will scroll some garbage for a moment, but maaaaaaah, anyway it's just 0 (blank) or 1 segment
	DEX				; back off one place
	_STZA led_buf, X	; get rid of the garbage
	STX led_pos		; cursor *after* last digit
led_cur:
	LDX z2			; get the ASCII code
	LDA lk_font-32, X	; get that character's bitmap (beware of NMOS page boundary!)
	LDX led_pos		; get cursor position
	STA led_buf, X	; store bitmap
	INC led_pos		; move cursor
	_DR_OK

; *** input, rewritten 130507 ***
; could use generic FIFO from 0.4.1, but a single-byte buffer will do
led_cin:
	LDX lkp_cont	; number of characters in buffer
	BEQ ledi_none	; no way if it's empty
		LDA lkp_buf		; gets the only char stored at buffer
		STA z2			; output value
		_STZA lkp_cont	; it's empty now! Could use DEC, but no advantage on CMOS
		_DR_OK
ledi_none:
	_DR_ERR(EMPTY)	; mild error otherwise

; *** poll, rewritten 130506, corrected 130512 ***
led_get:
	LDA VIA+IORA		; get current cathode mask
;	TAY					; save input bits
	AND #$F0			; only the output bits
	_STZX VIA+IORB	; disable digit as late as possible
	LDX led_mux			; currently displayed digit
	INX					; next digit???
	ASL					; shift to the next (left), or INC if decoded
	BCC led_nw			; should it wrap? BNE/BMI after a CMP, if decoded
		LDA #$10			; begin from the right
		LDX #0
led_nw:
	STA VIA+IORA		; update mask
	LDA led_buf, X		; get bitmap to display ASAP -- better *after* the new cathode is enabled
	STA VIA+IORB		; put it on PB to show the digit
	STX led_mux			; update displayed position
;	TYA					; restore input bits
	LDA VIA+IORA		; get input bits FROM NEW COLUMN!
	AND #$0F			; mask input bits, keep PA0...PA3 only
	STA lkp_mat, X		; store current column
	INX					; next column, not stored, now it's 1...4
	CPX #_led_digits	; four columns processed?
	BEQ ledg_go			; decode it!
ledg_end:
		_DR_OK
; decode depressed key
ledg_go:
	DEX					; now it's 3
ledg_col:
		LDA lkp_mat, X		; get stored column
		LDY #4				; number of rows per column
ledg_row:
			LSR					; shift right, get PA0...PA3
				BCS ledg_kpr		; abort if pressed
			DEY					; next row
			BNE ledg_row
		DEX					; next column
		BPL ledg_col		; does zero too!
ledg_kpr:
	BCS ledg_scan	; key was actually pressed?
		_STZA lkp_new	; no longer pressed, reset previous scancode
		RTS				; ...and go away, there was no error **** WATCH THIS
ledg_scan:
	STY systmp		; save row (1-4) number
	TXA				; column number
	ASL				; multiply by four
	ASL
	CLC				; ORA no longer possible with 1-4 row numbers!
	ADC systmp		; add row to 4*column, hope new var's OK!
	CMP lkp_new		; new scancode?
		BEQ ledg_end	; if the same, do nothing
	STA lkp_new		; update register
	TAX				; scancode (1-16) as index
		BEQ ledg_end	; scancode 0 means no key at all!!!
	DEX				; no 0-scancode in the table!
	LDA kptable, X	; get ASCII from scancode table
; could use generic FIFO from 0.4.1, but a single-byte buffer will do
	LDX lkp_cont	; number of characters in buffer
	BNE ledg_full	; has something already
		STA lkp_buf		; store char from A into buffer
		INC lkp_cont	; it's full now!
		_DR_OK
ledg_full:
	_DR_ERR(FULL)		; no room

; *** initialise, revised for new simplified keypad buffer 130507 ***
led_reset:
	LDY #%11110000		; bits PA4...7 for output
	STY VIA+DDRA		; easier with unprotected I/O, it's within kernel code anyway
	LDY #$FF			; PB is all output
	STY VIA+DDRB		; easier with unprotected I/O, it's within kernel code anyway

; clear display	and related variables
	LDA #_led_digits	; display size
	STA led_len			; first byte of the pack
	CLC					; let's make a counter for the bytes to be cleared
	ADC #2				; mux+pos (+ the buffer itself)
	TAX					; set counter as offset (won't reach first byte)
	LDA #0				; there's STZ on CMOS, but NMOS macros are worse here
led_dispcl:
		STA led_len, X		; clear variable
		DEX					; previous
		BNE led_dispcl		; won't reach offset 0, where the size is stored!
	LDA #_led_digits-1	; ***correct value, so first interrupt won't miss first column!
	STA led_mux			; ***fixed 130521

; clear keypad things
; could use generic FIFO from 0.4.1, but a single-byte buffer will do
	_STZA lkp_cont		; it's empty
	_STZA lkp_new		; no scancode detected so far

; enable display
	LDA VIA+PCR		; easier with unprotected I/O
	AND #%00011111		; keep other PCR bits
	ORA #%11000000		; CB2 low (display enable)
	STA VIA+PCR		; instead of the rest
	_DR_OK

; **** data tables ****
kptable:		; ascii values, reversed both column and row order 130512
	.asc "7410"			; leftmost column, top to bottom
	.asc "852."
	.asc "963?"
	.asc "+-", 27, 13	; rightmost column, top to bottom

; **** place bitmap here (minus non-printable chars)
lk_font:
	.byt $00, $61, $44, $7E, $B4, $4B, $3C, $04, $9C, $F0, $6C, $62, $08, $02, $01, $4A
	.byt $FC, $60, $DA, $F2, $66, $B6, $BE, $E0, $FE, $F6, $41, $50, $18, $12, $30, $CA
	.byt $F8, $EE, $3E, $9C, $7A, $9E, $8E, $BC, $6E, $0C, $78, $0E, $1C, $EC, $2A, $FC
	.byt $CE, $FD, $DA, $B6, $1E, $38, $4E, $7C, $92, $76, $D8, $9C, $26, $F0, $C0, $10
	.byt $40, $FA, $3E, $1A, $7A, $DE, $8E, $F6, $2E, $08, $70, $0E, $1C, $EC, $2A, $3A
	.byt $CE, $E6, $0A, $32, $1E, $38, $4D, $7C, $92, $76, $D8, $9C, $20, $F0, $80, $00
