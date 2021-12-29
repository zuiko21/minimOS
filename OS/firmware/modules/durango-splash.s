; firmware module for minimOS
; Durango-X splash screen after POST
; (c) 2021 Carlos J. Santisteban
; last modified 20211230-0006

#ifdef	TESTING
fw_cpu=$222
conio=$1234
af_pg=$F8
st_pg=$F9
himem=$211
#define _PLX	PLX
#define	_PHX	PHX
#define	NEWL	13
#define	STD_INK	15
#define	STD_PPR 0
#endif
.(
; report CPU type
	LDX #0					; base index into multiple strings
	LDA fw_cpu
	CMP #'N'				; NMOS 6502
		BEQ pr_cpu
	LDX #cmos-base			; 65C02 offset
	CMP #'B'				; 65C02 code
		BEQ pr_cpu
	LDX #rock-base			; Rockwell 65C02
	CMP #'R'
		BEQ pr_cpu
	LDX #c816-base			; 65C816
	CMP #'V'
		BEQ pr_cpu
	LDX #unk-base			; unknown CPU type!
pr_cpu:
		LDA base, X			; get char
	BEQ end_cpu				; until string is done
		_PHX
		TAY					; char to be printed
		JSR conio			; direct firmware call
		_PLX				; restore index
		INX
		BNE pr_cpu			; no need for BRA
base:
	.asc	"NMOS 6502", 0
cmos:
	.asc	"65C02", 0
rock:
	.asc	"R65C02", 0
c816:
	.asc	18, 5, "65C816!", 18, STD_INK, 0
unk:
	.asc	18, 2, "CPU?", 18, STD_INK, 0
end_cpu:
	JSR newline
; report ROM size, from checksum!
	LDA af_pg				; end page of ROM
	SEC
	SBC st_pg				; start page of ROM
	LSR
	LSR						; was pages, now KiB
	JSR by10				; let's print two ciphers from A
	LDA #'O'				; will add 'K ROM'
	JSR memsiz_p
; report RAM size
	LDA himem				; RAM size
	JSR by10				; print in decimal
	LDA #'A'				; will add 'K RAM'
	JSR memsiz_p
; all done by now
	JMP continue
; *** some support routines ***
memsiz_p:					; *** display K R*M, replacing * by what's in A ***
	PHA
	LDY #'K'
	JSR conio
	LDY #' '
	JSR conio
	LDY #'R'
	JSR conio
	PLA
	TAY
	JSR conio
	LDY #'M'
	JSR conio
;	JMP newline
newline:					; *** quickly send NEWLINE ***
	LDY #NEWL				; newline
	JMP conio				; will return
by10:						; *** print A (<100) in decimal ***
	LDX #0					; reset tens!
div_loop:
	CMP #10					; divisible by 10?
	BCC modulo				; not any more
		INX					; otherwise, count ten more
		SBC #10				; and try again (C is set)
		BPL div_loop		; never goes negative, no need for BRA
modulo:						; A is remainder, X is quotient
	PHA						; save this for later
	TXA						; print tens first
	BEQ below10				; not if <10
		JSR dec_prn			; print cipher
below10:
	PLA						; back to units
	CLC						; is this needed?
;	JMP dec_prn				; print second
dec_prn:
	ADC #'0'				; convert to ASCII (C is clear)
	TAY
	JMP conio				; and print it as usual (will return)
continue:
.)
