; memory map for minimOS! KLUDGE
; v0.5.1b5
; last modified 20170210-1349
; (c) 2016-2017 Carlos J. Santisteban

#include "usual.h"
.(
; *** declare zeropage variables ***
; ##### uz is first available zeropage byte #####
	page	= uz		; start of current block
	current	= page+2	; index storage (now 16-bit)

; ...some stuff goes here, update final label!!!
	__last	= current+2	; ##### just for easier size check #####

; ##### include minimOS headers and some other stuff #####
#ifndef	NOHEAD
	.dsb	$100*((* & $FF) <> 0) - (* & $FF), $FF	; page alignment!!! eeeeek
pmapHead:
; *** header identification ***
	BRK						; do not enter here! NUL marks beginning of header
	.asc	"mV"			; minimOS app! 65c816 only
	.asc	"****", 13		; some flags TBD

; *** filename and optional comment ***
	.asc	"pmap16", 0		; file name (mandatory)
	.asc	"Display memory map", CR			; comment
	.asc	"16-bit minimOS 0.5.1 only!!!", 0

; advance to end of header
	.dsb	pmapHead + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$6000			; time, 12.00
	.word	$4A49			; date, 2017/2/09

pmap16Size	=	pmapEnd - pmapHead -256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	pmap16Size		; filesize
	.word	0				; 64K space does not use upper 16-bit
#endif
; ##### end of minimOS executable header #####

; ************************
; *** initialise stuff ***
; ************************

; ##### minimOS specific stuff #####
	LDA #__last-uz		; zeropage space needed
; check whether has enough zeropage space
#ifdef	SAFE
	CMP z_used			; check available zeropage space
	BCC go_pmap			; enough space
	BEQ go_pmap			; just enough!
		_ABORT(FULL)		; not enough memory otherwise (rare) new interface
go_pmap:
#endif
	STA z_used			; set needed ZP space as required by minimOS
; will not use iodev as will work on default device
; ##### end of minimOS specific stuff #####

	.al: .xl: REP #$30	; *** full 16-bit ***
	LDA #splash			; address of splash message (plus column header)
	JSR prnStrW			; print the string!

; ********************
; *** begin things ***
; ********************

	STZ current			; reset index, 16-bit anyway
pmap_loop:
		LDX #'$'			; print hex radix
		JSR prnCharW
		LDY current			; retrieve index
		LDA ram_stat, Y		; check status of this
		AND #$0006			; danger! it is a 16-bit number!
		PHA					; will use as index later
		LDA ram_pos, Y		; get this block address
		STA page			; store for further size computation
		XBA					; let us look the bank address before
		JSR byte2hexW		; print bank...
		LDA page			; ...and switch back to page address, was destroyed
		JSR byte2hexW
		LDA #pmt_lsb		; string for trailing zeroes
		JSR prnStrW
		PLX					; use as index
		JMP (pmap_tab, X)	; process as appropriate

; * print suffix in X, new line and complete loop *
pmap_next:
		JSR prnCharW		; print suffix
pmap_cr:
		LDX #CR				; new line
		JSR prnCharW
		BRA pmap_loop		; and go for next entry

; manage used block
pmap_used:
	LDA #pmt_pid		; string for PID prefix
	JSR prnStrW
	LDY current			; restore index
	LDA ram_pid, Y		; get corresponding PID
	JSR byte2hexW		; print it
; ...and finish line with block size

; * common ending with printed size, pages or KB *
pmap_size:
	LDX #' '			; print leading space
	JSR prnCharW
	LDY current			; get old index
	INY					; check next block!
	INY					; 16 bit entries!!!!
	STY current			; update byte
	LDA ram_pos, Y		; get next block position
	SEC
	SBC page			; subtract start of block
	CMP #4				; check whether below 1k
	BCS pmap_kb
		INC					; round up pages!
		JSR b2h_numW		; will not be over 4
		LDX #'p'			; page suffix
		BRA pmap_next		; print suffix, CR and go for next
pmap_kb:
	LSR					; divide by 4
	LSR
		BCC pm_nround	; if C, round up!
			INC
pm_nround:
; print A in decimal and continue! *******REVISE
/* have a look at this
unsigned divu10(unsigned n) {
    unsigned q, r;
    q = (n >> 1) + (n >> 2);
    q = q + (q >> 4);
    q = q + (q >> 8);
    q = q + (q >> 16);
    q = q >> 3;
    r = n - (((q << 2) + q) << 1);
    return q + (r > 9);
}
*/
	LDY #0				; this is the number of ciphers (2)
pkb_x10:
	LDX #0				; decade counter (2)
pkb_div10:
		CMP #10				; something to count? (3**)
			BCC pkb_unit		; less than 10 (2**+1)
		SBC #10				; otherwise subtract 10 (carry was set) (3**)
		INX					; and increase decade (2**)
		BRA pkb_div10		; until exit above (3**)
pkb_unit:
	PHA					; save units (4**)
	INY					; yet another cipher! (2*)
	CPX #10				; more than 10 decades? (3*)
	BCC pkb_prn			; if less, time to start printing (2*+1)
		TXA					; otherwise, these are the new units (3*)
		BRA pkb_x10			; ...to be divided by ten again (3*)
pkb_prn:
	CPX #0				; any decades?
	BEQ pkb_ltt			; less than ten, do not print X
		TXA 				; otherwise, this will be printed first
		PHA					; into stack, not PHX because 16-bit ciphers are expected...
		INY					; one more to print
pkb_ltt:
		PLA					; get cipher from stack
		PHY					; keep this again
		JSR b2h_asciiW		; filtered printing
		PLY
		DEY					; one less
		BNE pkb_ltt			; go for next until done
	LDX #'K'
	BRA pmap_next		; print suffix, CR and go for next

; manage locked list
pmap_lock:
	LDA #pmt_lock		; string for locked label
	JSR prnStrW
	BRA pmap_size		; finish line with block size

; manage free block
pmap_free:
	LDA #pmt_free		; string for free label
	JSR prnStrW
	BRA pmap_size		; finish line with block size

; manage end of list
pmap_end:
	LDA #pmt_end		; string for end label
	JSR prnStrW
	_FINISH				; *** all done ***


; *** table for routine pounters, as defined in abi.h ***
pmap_tab:
	.word	pmap_free
	.word	pmap_used
	.word	pmap_end
	.word	pmap_lock

; *** useful routines ***

;	.al: xl		; as these will be called in 16-bit mode

; ** these will go into a pseudolibrary **
; * print binary in A as two hex ciphers *
byte2hexW:
	PHA			; keep whole value
	LSR			; shift right four times (just the MSN)
	LSR
	LSR
	LSR
	JSR b2h_asciiW	; convert and print this cipher
	PLA			; retrieve full value
b2h_asciiW:
	AND #$000F	; keep just the LSN... and repeat procedure
	CMP #10		; will be a letter?
	BCC b2h_numW	; just a number
		ADC #6			; convert to letter (plus carry)
b2h_numW:
	ADC #'0'	; convert to ASCII (carry is clear)
; ...and print it (will return somewhere)
	TAX			; where the following function expects it

; * print a character in X *
prnCharW:
	STX io_c			; store character
	LDY #0				; use default device
	_KERNEL(COUT)		; output it ##### minimOS #####
; ignoring possible I/O errors
	RTS

; * print a NULL-terminated string pointed by A.w *
prnStrW:
	STA str_pt			; store full pointer
	LDY #0				; standard device
	_KERNEL(STRING)		; print it! ##### minimOS #####
; currently ignoring any errors...
	RTS


; *** strings and other data ***
splash:
	.asc	"pmap16 0.5.1", CR
	.asc	"(c) 2016-2017 Carlos J. Santisteban", CR
	.asc	" Addr.  PID  Size", CR, 0		; header

; format as follows
; 0123456789012345-789 (16 & 20 char)
;  Addr.  PID  Size
; $001200 #$07 3p
; $005600 FREE 15K
; $000400 LOCK 31K
; $008000 [  END  ]

pmt_free:
	.asc	"Free", 0

pmt_lock:
	.asc	"LOCK", 0

pmt_end:
	.asc	"[  END  ]", CR, 0

pmt_lsb:
	.asc	"00 ", 0

pmt_pid:
	.asc	"#$", 0

; ***** end of stuff *****
pmapEnd:				; ### for easy size computation ###
.)
.as: .xs:				; eeeeeeeeeeeeeek

