; minimOS 0.4a2 - SDx, 6502
; (c) 2012 Carlos J. Santisteban
; last modified 2012.12.05

.zero
#include "zeropage_0.4.h"
.bss
#include "sysvars_0.4.h"
.text
#include "api_0.4.h"
#include "io_dev_0.4.h"
#include "macros_0.4.h"

k_vec:		; kernel's entry points
	.word cout		; output a character
	.word cin		; get a character
	.word malloc	; reserve memory (kludge!)
	.word free		; release memory (kludgest!)
	.word open_w	; get I/O port or window
	.word close_w	; close window
	.word free_w	; will be closed by kernel
	.word hid_push	; insert into input queue
	.word b_fork	; get available PID
	.word b_exec	; launch new process
	.word load_link	; get addr. once in RAM/ROM
	.word su_poke	; write protected addresses
	.word su_peek	; read protected addresses
	.word string	; prints a C-string

* = $DF00			; 'kernel call' primitive
; kernel calling primitive
k_call:			; X <- function code
		CPX #27		; first invalid code
		BMI implemented	; else, it's OK. BCS?
		_ERR(_unavail)
implemented:		; the (unpatched) call in itself
	_JMPX(k_vec)	; macro for NMOS
;	LDA k_vec, X	; boot address LSB
;	STA sysvec		; reserved zero-page vector ***NOT HERE 121211
;	LDA k_vec+1, X	; boot address MSB
;	STA sysvec+1	; two reserved bytes
;	JMP (sysvec)	; ...NMOS only
	
* = $E000			; kernel routines
; *** K0, output a character ***
cout:				; Y <- dev, z2 <- char
	CPY #acia_dev	; serial port?
	BNE k0_no_acia	
		_ERR(_not_found)	; temporary error
k0_no_acia:
	CPY #lcd_dev	; LCD & I/O keypad?
	BNE k0_no_lcd
		_ERR(_not_found)	; temporary error
k0_no_lcd:
	CPY #led_dev	; LED & VIA keypad?
	BEQ k0_led_ok
	_ERR(_not_found)	; unknown device
k0_led_ok:			; only supported device so far
	LDA z2		; get char in case is control
	CMP #_cr		; carriage return?
	BEQ k0_blank	; if so, clear LED display
	CMP #_lf		; LF clears too
	BEQ k0_blank
	CMP #_ff		; FF clears too
	BNE k0_no_clear	; else, do print
k0_blank:
	LDX led_len	; display size
	LDA #0		; NMOS only
k0_clear:
	STA led_buf-1, X	; STZ if CMOS
	DEX
	BNE k0_clear	; loops until all clear
	STA led_pos	; reset cursor
	_EXIT_OK
k0_no_clear:
	CMP #_bs		; backspace?
	BNE k0_no_bs
	LDX led_pos		; gets cursor position
	BEQ k0_end		; nothing to delete
	DEX			; else, backs off one place
	LDA #0		; NMOS only
	STA led_buf, X	; clear position, STZ for CMOS
	STX led_pos		; update cursor position
k0_end:
	_EXIT_OK
k0_no_bs:
	CMP #'.'		; may add dot to previous char
	BNE k0_no_dot
	LDX led_pos		; gets cursor position
	BEQ k0_no_dot	; nothing before
	DEX			; go to previous character
	LDA led_buf, X	; previous char. bitmap
	BMI k0_no_dot	; already has dot, go away
	ORA #$80		; add decimal point
	STA led_buf, X	; modified bitmap
	_EXIT_OK
k0_no_dot:
	LDA led_pos		; cursor position
	CMP led_len		; is display full?
	BMI k0_no_scroll	; else, don't scroll
	LDX #0		; reset index
k0_scroll:
	LDA led_buf+1, X	; get from second character
	STA led_buf, X	; copy it before
	INX			; get next character
	CPX led_len		; until screen ends
	BNE k0_scroll
	DEX			; back off one place
	STX led_pos		; cursor at last digit
k0_no_scroll:
	LDX z2		; get the ASCII code
	LDA font, X		; get that character's bitmap
	LDX led_pos		; get cursor position
	STA led_buf, X	; store bitmap
	INC led_pos		; move cursor
	_EXIT_OK

; *** K2, get a character ***
cin:				; Y <- dev, z2 -> char

	_EXIT_OK

; *** K4, reserve memory (kludge!) ***
malloc:			; z2L <- size, z6L -> addr
	LDA z2L+2
	ORA z2L+3		; asking over 64 K?
	BEQ k4_no_bank	; no bank switching...
	_ERR(_full)		; ...available so far
k4_no_bank:
	CLC			; for adding
	LDA z2L+1		; number of pages
	LDX z2L		; round size?
	BEQ k4_aligned	; no need for extra page
	SEC			; else increase result
k4_aligned:
	ADC ptr_page	; next free page
	CMP himem		; it's beyond the limit?
	BMI k4_enough	; OK, then
	_ERR(_full)		; else no room
k4_enough:
	LDX ptr_page	; start address
	STX z6L+1		; store at output parameter
	LDX #0		; NMOS only
	STX z6L		; aligned page, STZ for CMOS
	STA ptr_page	; update pointer for next req...
	_EXIT_OK

; *** K6, release memory (kludgest!) ***
free:				; z6L <- addr
	LDA z6L+1		; get start page
	STA ptr_page	; it's now the first free page!
	_EXIT_OK

; *** K8, get I/O port or window ***
open_w:		; Y -> dev, z2W -> size, z10W -> pos
	LDA z2W		; asking for some size?
	ORA z2W+1
	BEQ k8_no_window	; can't do it
	_ERR(_no_rsrc)
k8_no_window:
	LDY #0		; constant device?
	_EXIT_OK

; *** K10, close window ***
close_w:			; Y <- dev
; *** K12, will be closed by kernel ***
free_w:			; Y <- dev
; *** K14, insert into input queue ***
hid_push:			; Y <- char
				; all the same, so far...
	_EXIT_OK		; doesn't do much, either

; *** K16, get available PID ***
b_fork:			; Y -> PID
	LDY #0		; no multitasking, so far...
	_EXIT_OK

; *** K18, launch new process ***
b_exec:			; Y <- PID, z2L <- addr
	CPY #0		; no multitasking yet
	BNE k18_multi
	LDX zp_used		; how many bytes to save
	INX			; including that
k18_save:
	LDA zp_used-1, X	; get used byte
	PHA			; save it
	DEX			; countdown
	BNE k18_save	; another one
	LDX #8		; now for the system variables
k18_sys_sv:
	LDA sysvec-1, X	; get a system byte
	PHA			; save it
	DEX			; countdown
	BNE k18_sys_sv	; and another one
	LDA #<k18_return-1	; LSB return address
	PHA				; pseudo-return for the RTS
	LDA #>k18_return-1	; MSB return address
	PHA
	JMP (z2)		; start code execution
k18_return:
	LDX #0		; reset index
k18_sys_rs:
	PLA			; retrieve system byte
	STA sysvec, X	; restore it
	INX			; count it
	CPX #8		; until it's done
	BNE k18_sys_rs
	PLY			; get number of user bytes
	STY zp_used		; restore it
	LDX #1		; reset index
k18_restore:
	PLA			; retrieve user byte
	STA user, X		; restore it
	INX			; count it
	DEY			; one less to go
	BNE k18_restore	; until it's done
	_EXIT_OK
k18_multi:
	_ERR(_no_rsrc)

; *** K20, get address once in RAM/ROM ***
load_link:			; z2L -> addr, z10L <- *path

	_EXIT_OK

; *** K22, write to protected addresses ***
s_poke:			; Y <- value, z2L <- addr
	TYA			; transfer value
	_STAX(z2L)		; store value, macro for NMOS
	_EXIT_OK

; *** K24, read from protected addresses ***
s_peek:			; Y -> value, z2L <- addr
	_LDAX(z2L)		; store value, macro for NMOS
	TAY			; transfer value
	_EXIT_OK

; *** K26, prints a C-string ***
string:			; Y <- dev, z10L <- *string
	LDX #0		; NMOS only
	_LDAX(z10L)		; get current character, NMOS too
	BEQ k26_end		; NUL = end-of-string
	STA z2		; ready to go out
	_KERNEL(_cout)	; call cout
	INC z10L		; next character
	BNE string
	INC z10L+1		; cross page boundary
	BNE string
	_EXIT_OK

; ***********************************************
; power-on self-test
post:
	;...*****
	BRK			; abort execution?

; non-maskable interrupt (debugger)
nmi:
	;...*****
	RTI

; interrupt request handler
irq:
	JMP (irqvec)	; vectored ISR

; interrupt service routine
isr:
	;...*****
	RTI

; choose boot address depending on PA0-PA3
reset:
	SEI			; in case of warm reset
	CLD			; NMOS only
	LDA #$10		; bit 4 high
	STA ddra		; only PA4 as output
	STA iora		; set PA4 high
	LDX #$FF		; initial stack pointer
	TXS			; initialise stack
	LDA #$0F		; mask 4 lower bits
	AND iora		; read PA0-PA3 for startup ID
	ASL			; multiply by 2
	TAX			; table index
	_JMPX(table)	; macro for NMOS

; boot addresses table
* = $FFD0
	.word post		; main code startup address
	.dsb 30, $FF	; empty vectors

; 6502 vectors
* = $FFFA
	.word	nmi
	.word	reset
	.word irq