; memory map for minimOS! KLUDGE
; v0.5.1rc1
; last modified 20170511-1351
; (c) 2016-2018 Carlos J. Santisteban

#include "usual.h"
.(
; *** declare zeropage variables ***
; ##### uz is first available zeropage byte #####
	page	= uz			; start of current block
	current	= page+1	; index storage

; ...some stuff goes here, update final label!!!
	__last	= current+1	; ##### just for easier size check #####

; ##### include minimOS headers and some other stuff #####
#ifndef	NOHEAD
	.dsb	$100*((* & $FF)<> 0) - (* & $FF), $FF	; page aligned
pmapHead:
; *** header identification ***
	BRK						; do not enter here! NUL marks beginning of header
	.asc	"mB"			; minimOS 65C02 app!
	.asc	"****", 13		; some flags TBD

; *** filename and optional comment ***
	.asc	"pmap", 0	; file name (mandatory)

	.asc	"Display memory map", CR				; comment
	.asc	"8-bit minimOS 0.5.1 only!!!", 0

; advance to end of header
	.dsb	pmapHead + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$6E60			; time, 1351
	.word	$4AAB			; date, 2017/5/11

pmapSize	=	pmapEnd - pmapHead -256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	pmapSize		; filesize
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

	LDA #>splash		; address of splash message (plus column header)
	LDY #<splash
	JSR prnStr			; print the string!

; ********************
; *** begin things ***
; ********************

	_STZY current	; reset index
pmap_loop:
		LDA #'$'		; print hex radix
		JSR prnChar
		LDY current		; retrieve index
		LDA ram_pos, Y	; get this block address
		STA page			; store for further size computation
		JSR hex2char		; print MSB
		LDY #<pmt_lsb	; string for trailing zeroes
		LDA #>pmt_lsb
		JSR prnStr
		LDY current		; index again
		LDX ram_stat, Y	; check status of this, use as index
		_JMPX(pmap_tab)	; process as appropriate

; * print suffix in A, new line and complete loop *
pmap_next:
		JSR prnChar	; print suffix
pmap_cr:
		LDA #CR			; new line
		JSR prnChar
		_BRA pmap_loop	; and go for next entry

; manage used block
pmap_used:
	LDY #<pmt_pid	; string for PID prefix
	LDA #>pmt_pid
	JSR prnStr
	LDY current	; restore index
	LDA ram_pid, Y	; get corresponding PID
	JSR hex2char		; print it
; ...and finish line with block size

; * common ending with printed size, pages or KB *
pmap_size:
	LDA #' '		; print leading space
	JSR prnChar
	INC current	; check next block!
	LDY current	; set index
	LDA ram_pos, Y	; get next block position
	SEC
	SBC page		; subtract start of block
	CMP #4		; check whether below 1k
	BCS pmap_kb
		JSR h2c_num	; will not be over 3
		LDA #'p'	; page suffix
		_BRA pmap_next	; print suffix, CR and go for next
pmap_kb:
	LSR			; divide by 4
	LSR
		BCC pm_nround	; if C, round up!
			_INC
pm_nround:
; print A in decimal and continue! no more than 64!
	LDX #0		; decade counter
pkb_div10:
		CMP #10		; something to count?
			BCC pkb_unit	; less than 10
		SBC #10		; otherwise subtract 10 (carry was set)
		INX		; and increase decade
		_BRA pkb_div10	; until exit above
pkb_unit:
	PHA			; save units
	TXA			; decades will not be over 6
	JSR h2c_num	; print ASCII
	PLA			; retrieve units
	JSR h2c_ascii	; convert & print
	LDA #'K'
	_BRA pmap_next	; print suffix, CR and go for next

; manage locked list
pmap_lock:
	LDY #<pmt_lock	; string for locked label
	LDA #>pmt_lock
	JSR prnStr
	_BRA pmap_size	; tell block size too

; manage free block
pmap_free:
	LDY #<pmt_free	; string for free label
	LDA #>pmt_free
	JSR prnStr
	_BRA pmap_size	; finish line with block size

; manage end of list
pmap_end:
	LDY #<pmt_end	; string for end label
	LDA #>pmt_end
	JSR prnStr
	_FINISH		; *** all done ***


; *** table for routine pounters, as defined in abi.h ***
pmap_tab:
	.word	pmap_free
	.word	pmap_used
	.word	pmap_end
	.word	pmap_lock

; *** useful routines ***

; ** these will go into a pseudolibrary **
; * print binary in A as two hex ciphers *
hex2char:
	PHA			; keep whole value
	LSR			; shift right four times (just the MSB)
	LSR
	LSR
	LSR
	JSR h2c_ascii	; convert and print this cipher
	PLA			; retrieve full value
	AND #$0F	; keep just the LSB... and repeat procedure
h2c_ascii:
	CMP #10		; will be a letter?
	BCC h2c_num	; just a number
		ADC #6			; convert to letter (plus carry)
h2c_num:
	ADC #'0'	; convert to ASCII (carry is clear)
; ...and print it (will return somewhere)

; * print a character in A *
prnChar:
	STA io_c			; store character
	LDY #0				; use default device
	_KERNEL(COUT)		; output it ##### minimOS #####
; ignoring possible I/O errors
	RTS

; * print a NULL-terminated string pointed by $AAYY *
prnStr:
	STA str_pt+1		; store MSB
	STY str_pt			; LSB
	LDY #0				; standard device
	_KERNEL(STRING)		; print it! ##### minimOS #####
; currently ignoring any errors...
	RTS


; *** strings and other data ***
splash:
	.asc	"pmap 0.5.1", CR
	.asc	"(c) 2016-2017 Carlos J. Santisteban", CR
	.asc	"Addr. PID  Size", CR, 0		; header

; format as follows
; 0123456789012345-789 (16 & 20 char)
; Addr. PID  Size
; $1200 #$07 3p
; $5600 Free 15K
; $8000 [  END  ]
; $0400 LOCK 31K

pmt_free:
	.asc	"Free", 0

pmt_lock:
	.asc	"LOCK", 0

pmt_end:
	.asc	"[  END  ]", CR, 0

pmt_lsb:
	.asc	"00 ", 0

pmt_pid:
	.asc	"$#", 0

; ***** end of stuff *****
pmapEnd:				; ### for easy size computation ###
.)
