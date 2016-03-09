; minimOS 0.5a9 shell code
; (c) 2015-2016 Carlos J. Santisteban
; last modified 20160309

; in case of standalone assembly
#ifndef		KERNEL
#include "options.h"
#include "macros.h"
#include "abi.h"		; new filename
#include "zeropage.h"
#include "sysvars.h"
.text
#endif

; ***** minimOS M/L monitor shell *****

; trying something like a stand-alone utility
; might be called by NMI and BRK handlers!


; *** constants definition ***
; number of characters in input buffer, check for 128-byte systems
; also set offset between last-access pointers, they'll be merged in 128-byte systems
; and required minimOS ZP bytes, 34 (13 vars + 16 buff + 5 stack) for LOWRAM devices, 65 (20 + 40 + 5) otherwise

#ifdef	LOWRAM
#define		SH_BUF	16
#define		LS_OF	0
#define		MIN_ZP	34
#else
#define		SH_BUF	40
#define		LS_OF	2
#define		MIN_ZP	65
#endif

; *** labels declaration ***
	endsp	=	z_used			; minimOS ZP use indicator doubles as internal stack pointer
	a_reg	=	endsp+1			; temporary A storage
	x_reg	=	a_reg+1			; temporary X storage
	y_reg	=	x_reg+1			; temporary Y storage
	p_reg	=	y_reg+1			; temporary status storage
	s_reg	=	p_reg+1			; stack pointer at invocation time, not to be modified?
	io_dev	=	s_reg+1			; I/O device ***minimOS only***
	com_dev	=	io_dev+1		; load/save port ***minimOS only***
	curs	=	com_dev+1		; current buffer pointer, really needed?
	mode	=	curs+1			; d7=ASCII instead of hex, d6=command select (+-), d0=SIGTERM
	temp	=	mode+1			; hex-to-bin conversion
	count	=	temp+1			; number of lines (minus 1) to dump, or bytes to load/save
	ptr		=	count+2			; converted values and addresses *** needs to be in zeropage ***
	last_f	=	ptr+LS_OF		; last fetch address *** should be in zeropage, may be merged with others
	last_p	=	last_f+LS_OF	; last put address *** should be in zeropage, may be merged with others
	last_d	=	last_p+LS_OF	; last dump address *** should be in zeropage, may be merged with others
	inbuff	=	last_d+2		; buffer for keyboard input
	stack	=	inbuff+SH_BUF	; internal stack

; *** code starts here ***
+monstart:			; ***this is global***
	STA a_reg		; store previous values
	STX x_reg
	STY y_reg
	PHP				; get flags
	PLA
	STA p_reg
	TSX				; get stack pointer
	STX s_reg
; init some stuff
	JSR mos_init	; initialise minimOS-specific stuff (worth the call for cleaner code)
	LDX #inbuff-com_dev+1	; number of bytes to be zeroed
mon_res:
		_STZA com_dev-1, X	; reset variable, non miminOS systems may use curs instead
		DEX					; go for previous
		BNE mon_res			; until start
	LDA #stack-2	; initial data stack pointer, or -z_used
	STA z_used		; reset data stack
; splash screen
	LDA #<splash	; string LSB
	STA ptr			; temporary pointer storage
	LDA #>splash	; same for MSB
	STA ptr+1
	JSR mon_string	; print string
; main loop, now much cleaner, worth the callings
mon_loop:
		JSR mon_getline		; get command line
		JSR mon_parse		; process it!
		LDA mode			; get flags
		ROR					; check for SIGTERM (LSB)
		BNE mon_loop		; wait until exit
; we're going out, restore status and exit?
mon_term:
	LDX s_reg		; get previous SP, really needed???
	TXS				; restore SP, really needed???
	LDA p_reg		; get previous status
	PHA				; push it for later
	LDA a_reg		; restore regular registers
	LDX x_reg
	LDY y_reg
	PLP				; lastly, restore status
	RTS				; all done -- NMI handler should wrap it accordingly
 
; get the command line
mon_getline:
	LDA #<prompt	; string LSB
	STA ptr			; temporary pointer storage
	LDA #>prompt	; same for MSB
	STA ptr+1
	JSR mon_string	; print string
	LDX #0			; reset cursor
	STX curs		; and store it, really needed?
mon_type:
		JSR mon_input	; get pressed key
		
		CMP #13			; last check, is it CR?
		BNE mon_nox		; don't execute yet
	RTS				; otherwise return to parse line
mon_nox:
		LDA mode		; check for SIGTERM
		ROR				; get LSB
		BEQ mon_getline	; continue if not asked to exit
	PLA				; otherwise, discard return address
	PLA
	_BRA mon_term	; and get out from here

; interpret the command line
; *** might be called by OSCLI, thus set appropriate interface ***
mon_parse:
	LDX #0			; reset cursor
mon_cli:
		LDA inbuff, X	; get character in line
		BEQ mc_end		; already terminated
			BIT mode		; binary mode?
			BPL mc_bin		; get full command set
;				LDY #NUM_ACMD	; reduced set otherwise
			BNE mc_scan		; continue checking command, no need for BRA
mc_bin:
;				LDY #NUM_FCMD	; the full set
mc_scan:
			CMP mon_cmd-1, Y	; compare against table
				BEQ mon_do			; found
			DEY					; go back
			BNE mc_scan			; until no more
		BIT mode		; check mode again
		BPL mc_hex		; in ASCII?
			JSR push			; already converted, just push the character
			_BRA mc_next		; go for next character
mc_hex:
				
mc_next:
			INX				; next character
			CPX #SH_BUF		; end of buffer?
			BCS mon_cli		; continue executing
mc_end:
		_BRA mon_loop		; continue forever
mon_do:
	; ******* TO DO TO DO TO DO TO DO TO DO TO DO TO DO TO DO TO DO TO DO ***
; *** useful routines ***
; print string pointed at ptr
; destroys A
mon_string:
	_PHY		; save reg
	LDY #0		; reset offset
ms_loop:
		LDA (ptr), Y	; get pointed character
			BEQ ms_end		; terminated C-string
		JSR mon_print	; print character
		INY				; next character
		BNE ms_loop		; maximum 256 characters
ms_end:
	_PLY		; restore reg
	RTS

push:
	RTS			; **** TO DO TO DO TO DO TO DO TO DO TO DO TO DO ****

; *** system-specific I/O stuff ***
; print character in A
mon_print:
	STA zpar		; store character
	PHA				; save regs
	_PHX
	_PHY
	LDY io_dev		; get default device
	_KERNEL(COUT)	; print char
	_PLY			; restore regs
	_PLX
	PLA
	RTS

; get input character in A, non locking, C set if no char available
mon_input:
	_PHX			; preserve regs
	_PHY
	LDY io_dev		; get default device
	_KERNEL(CIN)	; get character
	_PLY
	_PLX			; retrieve, C was set accordingly
	LDA zpar		; get output character in A, only valid if C clear
	RTS

; *** minimOS specific stuff ***
; initialise environment
; no interface, destroys all
mos_init:
; ------------------------------------------------
; ** discard this for minimOS 0.4 compatibility **
; check available memory
	LDA endsp			; really gets number of available ZP bytes
	CMP #MIN_ZP			; below minimum?
		BCC mos_abort	; not enough room
; set SIGTERM handler
	_KERNEL(GET_PID)	; first get current PID
	LDA #<mon_term		; handler LSB
	STA zaddr2			; store parameter
	LDA #>mon_term		; same for MSB
	STA zaddr2+1
	_KERNEL(SET_HNDL)	; establish handler
; ** end of discarded block **
; ----------------------------
	_STZA zpar			; no size required
	_STZA zpar+1		; same for MSB
	_KERNEL(OPEN_W)		; get window or device
		BCS mos_abort	; no way to open anything!
	STY io_dev			; set default device

	RTS					; all done?
; abort this routine in case of error
mos_abort:
	PLA					; discard routine return address
	PLA
	_ERR(FULL)			; not enough memory (or some other problem)

; *** data ***
splash	.asc	"minimOS 0.5a9", 13, "M/L monitor", 13, "(c) 2015 CJSS", 13, 0
prompt	.asc	13, ">", 0
mon_cmd	.asc	"!@,'*&"

; *** command set *** 20151029

; ! = store (daa--)
; @ = fetch (aa--d)
; comma = store next (d--)
; ' = fetch previous (--d)
; * = jump (aa--)
; & = call (aa--)
; _ = show regs (--)
; . = pop and show (d--)
; " = set ASCII mode (--)
; $ = set hex mode, default (--)
; # = set dump/disass lines (d--)
; % = dump (aa--)
; / = dump # more lines (--)
; [ = enter assembler (--)
; ( = disassemble (aa--)
; ) = disassemble # more lines (--)
; colon = warm reset??
; semicolon = shutdown??

; (extended set, only in hex mode)
; M = set accumulator (d--)
; X = set X (d--)
; Y = set Y (d--)
; P = set P??? (d--)
; S = set SP???????? (d--)


