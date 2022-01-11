; video flag settings for Durango-X
; v1.1b2
; last modified 20220111-1652
; (c) 2022 Carlos J. Santisteban

#include "../OS/usual.h"
.(
; *** declare zeropage variables ***
; ##### uz is first available zeropage byte #####
	rompt		= uz			; scans ROM

; ...some stuff goes here, update final label!!!
	__last	= rompt+3	; ##### just for easier size check ##### could be +2 for 65c02

; ##### include minimOS headers and some other stuff #####
#ifndef	NOHEAD
	.dsb	$100*((* & $FF) <> 0) - (* & $FF), $FF	; page alignment!!! eeeeek
vfHead:
; *** header identification ***
	BRK						; do not enter here! NUL marks beginning of header
	.asc	"m", CPU_TYPE	; minimOS app! it is 816 savvy
	.asc	"****", 13		; some flags TBD

; *** filename and optional comment ***
	.asc	"flags", 0			; file name (mandatory)
	.asc	"Sets Durango-X video flags, v1.1", 0		; comment

; advance to end of header
	.dsb	vfHead + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$0000			; time, 0.00
	.word	$5425			; date, 2022/1/5

vfSize	=	vfEnd - vfHead -$100	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	vfSize			; filesize
	.word	0				; 64K space does not use upper 16-bit
#endif
; ##### end of minimOS executable header #####

; ************************
; *** initialise stuff ***
; ************************
	col_en	= z_used+1	; variable for the unreadable C bit
	tmp		= col_en+1	; need this too
	set_sc	= tmp+1		; allow proper resolution switch in alternative screens

; ##### minimOS specific stuff #####
	LDA #4				; zeropage space needed
; check whether has enough zeropage space
#ifdef	SAFE
	CMP z_used			; check available zeropage space
	BCC go_vf			; enough space
	BEQ go_vf			; just enough!
		_ABORT(FULL)	; not enough memory otherwise (rare) new interface
go_vf:
#endif
	STA z_used			; set needed ZP space as required by minimOS
; will not use iodev as will work thru firmware
; ##### end of minimOS specific stuff #####

	LDA IO8attr
	AND #%00110000		; filter current screen
	STA set_sc
	LDA #>banner		; address of banner message (column header)
	LDY #<banner
	JSR prnStr			; print the string! ready for flags
vf_col:
	LDA #%1000			; originally enable colour (if in lowres)
	STA col_en
; *****************
; *** main loop ***
; *****************
vf_main:
	LDA IO8attr			; get video flags (D7-D3)
	AND #%11110000		; only active bits
vf_cbit:
	ORA col_en			; plus 'stablished' colour enable
	STA IO8attr			; easily update colour status
	LDX #5				; four visible bits+one computed here
vf_loop:
		LDY #' '		; space by default (off)
		ASL				; get leftmost bit
		BCC vf_clear
			LDY #$BC	; bullet char (on)
vf_clear:
		PHA
		_PHX
		_U_ADM(CONIO)	; direct firmware call!
		_PLX
		PLA
		DEX				; next bit
		BNE vf_loop
	LDY #1
	_U_ADM(CONIO)		; send CR for next
vf_wait:
		LDY #0			; get input char
		_U_ADM(CONIO)	; eeeeeek
		BCS vf_wait		; hopefully no errors!
	TYA
	ORA #32				; all lowercase
	CMP #'h'			; Hires toggle (will get back to selected screen)
	BNE no_hr
		LDA IO8attr
		AND #%11001111	; remove current screen, just in case
		ORA set_sc		; back to selected one
		EOR #%10000000	; toggle D7
		STA IO8attr
		JMP vf_clpr		; clear and print, like "s"
no_hr:
	CMP #'i'			; Inverse toggle
	BNE no_iv
		LDA IO8attr
		EOR #%01000000	; toggle D6
		STA IO8attr
		JMP vf_main		; update bit display
no_iv:
	CMP #'s'			; Set current screen
	BNE no_ss
vf_clpr:
		LDY #<clear		; clearing is all we need (reused by H)
		LDA #>clear
		JSR prnStr
		LDA IO8attr
		AND #%00110000	; selected screen
		STA set_sc		; take note
		JMP vf_main		; and update bits
no_ss:
	CMP #'c'			; Enable colour mode
		BEQ vf_col		; just reset this internal flag
no_cm:
	CMP #'g'			; Disable colour mode (greayscale)
	BNE no_gm
		_STZA col_en	; disable stored flag
		JMP vf_main		; and update all
no_gm:
	CMP #'0'			; getting a number 0...3
	BCC vf_nosn			; below 0
	CMP #'4'
	BCS vf_nosn			; over 3
		ASL
		ASL
		ASL
		ASL				; times 16
		STA tmp			; eeeek
		LDA IO8attr
		AND #%11000000	; filter valid bits EEEEEEK how could it EVER work?
		ORA tmp			; select new screen
		JMP vf_cbit		; and update the rest
vf_nosn:
; all done, check for exit
	CMP #59				; actually 27 (ESC)
	BEQ vf_exit			; will exit
		CMP #'q'		; and this one as well
		BNE vf_wait		; otherwise keep waiting
vf_exit:
	LDA #>down			; set a reasonable cursor
	LDY #<down
	JSR prnStr
	_FINISH

; *** useful routines ***

; * print a NULL-terminated string pointed by $AAYY *
prnStr:
	STA str_pt+1		; store MSB
	STY str_pt			; LSB
	LDY #0				; reset index
prn_loop:
		_PHY
		LDA (str_pt), Y	; get char
	BEQ prn_end			; unless terminator
		TAY				; FW parameter
		_U_ADM(CONIO)	; print char
		_PLY
		INY				; next char
		BNE prn_loop	; no need for BRA
prn_end:
	PLA					; discard saved index, for NMOS-savvyness
; currently ignoring any errors...
	RTS

; *** strings and other data ***
clear:
	.asc	12								; this point will clear screen before
banner:
	.asc	14, "Video flags", 15, NEWL		; inverse text label
	.asc	"HIssC---", NEWL				; flags header
	.asc	10, 14, "H", 15, "ires   "		; blank line for flags and help strings
	.asc	14, "I", 15, "nverse", NEWL
	.asc	14, "0-3", 15, "=see", 16, 6	; include right-pointing arrow
	.asc	14, "S", 15, "et", NEWL
	.asc	14, "C", 15, "olour  "
	.asc	14, "G", 15, "rey", NEWL
	.asc	14, "Esc/Q", 15, "=quit", 1		; help text, CR
	.asc	11, 11, 11, 11, 0				; 4xUPCU 

down:
	.asc	10, 10, 10, 10, 10, 0	; 8xLF
; ***** end of stuff *****
vfEnd:					; ### for easy size computation ###
.)
