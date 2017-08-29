; ROM header listing for minimOS!
; v0.5rc1
; last modified 20170515-1313
; (c) 2016-2017 Carlos J. Santisteban

#include "usual.h"
.(
; *** declare zeropage variables ***
; ##### uz is first available zeropage byte #####
	rompt		= uz			; scans ROM

; ...some stuff goes here, update final label!!!
	__last	= rompt+3	; ##### just for easier size check ##### could be +2 for 65c02

; ##### include minimOS headers and some other stuff #####
#ifndef	NOHEAD
	.dsb	$100*((* & $FF) <> 0) - (* & $FF), $FF	; page alignment!!! eeeeek
lsHead:
; *** header identification ***
	BRK						; do not enter here! NUL marks beginning of header
	.asc	"m", CPU_TYPE	; minimOS app! it is 816 savvy
	.asc	"****", 13		; some flags TBD

; *** filename and optional comment ***
	.asc	"ls", 0			; file name (mandatory)
	.asc	"Lists ROM contents, v0.5", 0		; comment

; advance to end of header
	.dsb	lsHead + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$6800			; time, 13.00
	.word	$4AAF			; date, 2017/5/15

lsSize	=	lsEnd - lsHead -$100	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	lsSize			; filesize
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
	BCC go_ls			; enough space
	BEQ go_ls			; just enough!
		_ABORT(FULL)		; not enough memory otherwise (rare) new interface
go_ls:
#endif
	STA z_used			; set needed ZP space as required by minimOS
; will not use iodev as will work on default device
; ##### end of minimOS specific stuff #####
	LDA #>banner		; address of banner message (column header)
	LDY #<banner
	JSR prnStr			; print the string!

; ********************
; *** begin things ***
; ********************

; get initial address
	LDY #<ROM_BASE		; begin of ROM contents LSB
	LDA #>ROM_BASE		; same for MSB, will read volume header (zero size!)
	STY rompt			; set local pointer
	STA rompt+1			; internal pointer set
#ifdef	C816
	STZ rompt+2			; make it 816-savvy
#endif

ls_geth:
; ** check whether we are on a valid header!!! **
#ifndef	C816
		_LDAY(rompt)		; get first byte in header, should be NUL
#else
		LDA [rompt]
#endif
		BEQ ls_nul			; eeeeeeeeeeeeeeeeeeeeeeeeeek
			JMP ls_nfound		; link was lost, no more to scan
ls_nul:
		LDY #7				; after type and size, a CR is expected
#ifndef	C816
		LDA (rompt), Y		; get eigth byte in header!
#else
		LDA [rompt], Y
#endif
		CMP #13				; was it a CR?
		BEQ ls_hok			; eeeeeeeeeeeeeeeeeeeeeeeeek
			JMP ls_nfound		; if not, go away
ls_hok:
; * print address in hex *
		LDA #'$'			; print hex radix
		JSR prnChar
#ifdef	C816
		LDA rompt+2			; retrieve current BANK address
		JSR byte2hex		; print BANK
#endif
		LDA rompt+1			; retrieve current address MSB
		JSR byte2hex		; print MSB
		LDY #<lst_lsb		; string for trailing zeroes
		LDA #>lst_lsb
		JSR prnStr

; * print up to 10 chars from name *
		LDY #8				; initial offset for name
ls_name:
			_PHY				; store for later
#ifndef	C816
			LDA (rompt), Y		; get one char
#else
			LDA [rompt], Y
#endif
				BEQ ls_pad			; shorter, put padding spaces
			JSR prnChar			; print it
			_PLY				; restore index
			INY					; next char
			CPY #18				; room for it?
			BNE ls_name			; continue
		LDA #'~'			; otherwise print substituting character
		JSR prnChar
		_BRA ls_type		; go for next column
ls_loop:
			_PHY				; keep index
ls_pad:
			LDA #' '			; print trailing space
			JSR prnChar
			_PLY				; retrieve index
			INY					; another char
			CPY #19				; room for it?
			BNE ls_loop			; continue

; * now print CPU type on executable blobs *
ls_type:
		LDY #1				; offset for file type
#ifndef	C816
		LDA (rompt), Y		; check it
#else
		LDA [rompt], Y
#endif
		CMP #'m'			; minimOS executable?
			BEQ ls_exec			; do print CPU type
		CMP #'s'			; system file? new option
			BEQ ls_exec			; also CPU bound
		LDY #<ls_file		; print CPU-less label
		LDA #>ls_file
		JSR prnStr
		_BRA ls_size		; end line with file size
ls_exec:
		INY					; advance to CPU type (was 1)
#ifndef	C816
		LDA (rompt), Y		; get it
#else
		LDA [rompt], Y
#endif
		LDX #20				; default type offset is like generic file
		CMP #'N'			; NMOS?
		BNE ls_nnmos
			LDX #0				; offset for NMOS string
			BEQ ls_cprn			; no need for BRA
ls_nnmos:
		CMP #'B'			; plain 65C02?
		BNE ls_ncmos
			LDX #5				; offset for it
			BNE ls_cprn
ls_ncmos:
		CMP #'R'			; Rockwell?
		BNE ls_nrock
			LDX #10
			BNE ls_cprn
ls_nrock:
		CMP #'V'			; 65816?
		BNE ls_cprn			; if neither, unrecognised CPU
			LDX #15				; offset for 65816
ls_cprn:
		TXA					; prepare to add offset
		CLC
		ADC #<ls_cpus		; base offset
		TAY					; will be LSB
		LDA #>ls_cpus		; base page
		ADC #0				; propagate carry
		JSR prnStr			; and print selected label

; * print size, pages or KB *
ls_size:
		LDA #' '			; print leading space
		JSR prnChar
; compute size
		LDY #253			; offset for size in pages (max 64k!)
#ifndef	C816
		LDA (rompt), Y
#else
		LDA [rompt], Y
#endif
; print pages/KB in decimal
		CMP #4				; check whether below 1k
		BCS ls_kb
			_INC				; round up pages!
			JSR b2h_num			; will not be over 4
			LDA #'p'			; page suffix
			BNE ls_next			; print suffix, CR and go for next, no need for BRA
ls_kb:
		LSR					; divide by 4
		LSR
		BCC ls_nround		; if C, round up!
			_INC
ls_nround:
; print A in decimal and continue! never more than 64k!!!
		LDX #0				; decade counter
lsb_div10:
			CMP #10				; something to count?
				BCC lsb_unit		; less than 10
			SBC #10				; otherwise subtract 10 (carry was set)
			INX					; and increase decade
			BNE lsb_div10		; until exit above, no need for BRA
lsb_unit:
		PHA					; save units
		TXA					; decades will not be over 6
		JSR b2h_num			; print ASCII
		PLA					; retrieve units
		JSR b2h_ascii		; convert & print
		LDA #'K'
; ...and end line printing suffix

; * print suffix in A and a new line *
ls_next:
		JSR prnChar			; print suffix
ls_cr:
		LDA #CR				; new line
		JSR prnChar

; * scan for next header *
		LDY #253			; relative offset to number of pages
#ifndef	C816
		LDA (rompt), Y		; get it now
#else
		LDA [rompt], Y
#endif
		TAX					; save for a while
		DEY					; relative offset to FILE SIZE eeeeek
#ifndef	C816
		LDA (rompt), Y		; check whether crosses boundary
#else
		LDA [rompt], Y
#endif
		BEQ ls_bound		; if it does not, do not advance page
			INX					; otherwise goes into next page
ls_bound:
		TXA					; retrieve number of pages to skip...
		SEC					; ...plus header itself! eeeeeeek
		ADC rompt+1			; add to previous value
		STA rompt+1			; update pointer
			BCS ls_carry			; inspect new header (if no 16bit overflow!)
		JMP ls_geth
ls_carry:
#ifdef	C816
		INC rompt+2			; next bank for 24-bit addressing eeeeeeek
			BEQ ls_nfound		; abort if full wraparound
		JMP ls_geth			; or continue otherwise
#endif
ls_nfound:
	_FINISH

; *** useful routines ***

; ** these should go into a pseudolibrary, ifdef to be included once, with + on entry labels **
; * print binary in A as two hex ciphers *
byte2hex:
	PHA					; keep whole value
	LSR					; shift right four times (just the MSn)
	LSR
	LSR
	LSR
	JSR b2h_ascii		; convert and print this cipher
	PLA					; retrieve full value
	AND #$0F			; keep just the LSB... and repeat procedure
b2h_ascii:
	CMP #10				; will be a letter?
	BCC b2h_num			; just a number
		ADC #6				; convert to letter (plus carry)
b2h_num:
	ADC #'0'			; convert to ASCII (carry is clear)
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
#ifdef	C816
	PHK					; get current bank eeeeeeeek
	PLA					; retreive
	STA str_pt+2		; and set accordingly
#endif
	LDY #0				; standard device
	_KERNEL(STRING)		; print it! ##### minimOS #####
; currently ignoring any errors...
	RTS
; ** end of usual pseudolibrary **

; *** strings and other data ***
banner:
#ifdef	C816
	.asc	"  "		; two extra spaces for bank address
#endif
	.asc	"Addr. Name       CPU  Size", CR, 0		; header

; format as follows
; 0123456789012345-789012345 (16 & 20 char)
; Addr. Name       CPU  Size
; $1200 pmap       'C02 3p
; $5600 abcdefghij~NMOS 2K
; $8000 8085emu16  '816 3K
; $0400 kernel     R65C 13K
; $F800 picture     --  1K

ls_cpus:
	.asc	"N", "MOS", 0	; macro alert!!!
	.asc	"'C02", 0
	.asc	"R65C", 0
	.asc	"'816", 0

ls_file:
	.asc	" -- ", 0

lst_lsb:
	.asc	"00 ", 0

; ***** end of stuff *****
lsEnd:				; ### for easy size computation ###
.)
