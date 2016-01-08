; minimOS 0.4a3 - SDd, 6502
; (c) 2012 Carlos J. Santisteban
; last modified 2012.12.26

; conditional assembly, check is SDd and/or NMOS
#define SDd

; include files
.zero
#include "zeropage_0.4.h"
.bss
#include "sysvars_0.4.h"
.text
#include "api_0.4.h"
#include "macros_0.4.h"

; ***** the kernel contents *****
* = $F800		; *** SDd savvy address ***
k_vec:			; kernel's entry points
	.word cout	; output a character
	.word cin	; get a character
	.word malloc	; reserve memory (kludge!)
	.word free	; release memory (kludgest!)
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

	.dsb 114, unimplemented	; missing functions, will that work?

; ***** I/O device drivers *****	
drv_acia:			; serial port
;#include "drv_acia.s"		; begins with address table for sub-functions
drv_lcd:			; Hitachi LCD
;#include "drv_lcd.s"
; dummy driver, five fake addresses
dummy_drv:
	.word void_routine	; +_d_init, device reset
	.word void_routine	; +_d_poll, device poll, called periodically
	.word void_routine	; +_d_req, asynchronous interrupt request by device (should verify source)
	.word void_routine	; +_d_in, device input, get character from device or buffer
	.word void_routine	; +_d_out, device output, buffered or not
void_routine:
	_EXIT_OK		; essentially RTS

drv_led:			; should be default device
#include "drv_led.s"

; ***** kernel generic routines *****
; *** dummy function, non implemented
unimplemented:			; placeholder here
	_ERR(_unavail)		; go away!

; *** K0, output a character ***
cout:				; Y <- dev, z2 <- char
	CPY #0			; default device?
	BNE k0_port		; check actual port
	LDY default_out	; default output device
k0_port:
	CPY #acia_dev		; serial port?
	BNE k0_no_acia
	JMP (drv_acia+_d_out)	; @device drivers area
k0_no_acia:
	CPY #lcd_dev		; LCD & I/O keypad?
	BNE k0_no_lcd
	JMP (drv_lcd+_d_out)	; @device drivers area
k0_no_lcd:
	CPY #led_dev		; LED & VIA keypad?
	BNE k0_no_led
	JMP (drv_led+_d_out)	; @device drivers area
k0_no_led:			; no supported device found
	_ERR(_not_found)	; unknown device

; *** K2, get a character ***
cin:				; Y <- dev, z2 -> char
	CPY #0			; default device?
	BNE k2_port		; check actual port
	LDY default_in		; default input device
k2_port:
	CPY #acia_dev		; serial port?
	BNE k2_no_acia
	JMPX(drv_acia+_d_in)	; @device drivers area
k2_no_acia:
	CPY #lcd_dev		; LCD & I/O keypad?
	BNE k2_no_lcd
	JMP (drv_lcd+_d_in)	; @device drivers area
k2_no_lcd:
	CPY #led_dev	; LED & VIA keypad?
	BNE k2_no_led
	JMP (drv_led+_d_in)	; @device drivers area
k2_no_led:			; no supported device found
	_ERR(_not_found)	; unknown device

; *** K4, reserve memory (kludge!) ***
malloc:			; z2L <- size, z6L -> addr
	LDA z2L+2
	ORA z2L+3	; asking over 16 K?
	BEQ k4_no_bank	; no bank switching...
	_ERR(_full)	; ...available so far
k4_no_bank:
	CLC		; for adding
	LDA z2L+1	; number of pages
	LDX z2L		; round size?
	BEQ k4_aligned	; no need for extra page
	SEC		; else increase result
k4_aligned:
	ADC ptr_page	; next free page
	CMP himem	; it's beyond the limit?
	BMI k4_enough	; OK, then
	_ERR(_full)	; else no room
k4_enough:
	LDX ptr_page	; start address
	STX z6L+1	; store at output parameter
	LDX #0		; NMOS only
	STX z6L		; aligned page, STZ for CMOS
	STA ptr_page	; update pointer for next req...
	_EXIT_OK

; *** K6, release memory (kludgest!) ***
free:			; z6L <- addr
	LDA z6L+1	; get start page
	STA ptr_page	; it's now the first free page!
	_EXIT_OK

; *** K8, get I/O port or window ***
open_w:				; Y -> dev, z2W -> size, z10W -> pos
	LDA z2W			; asking for some size?
	ORA z2W+1
	BEQ k8_no_window	; can't do it
	_ERR(_no_rsrc)
k8_no_window:
	LDY #0			; constant device?
	_EXIT_OK

; *** K10, close window ***
close_w:		; Y <- dev
; *** K12, will be closed by kernel ***
free_w:			; Y <- dev
; *** K14, insert into input queue. DEPRECATE NOW??? ***
hid_push:		; Y <- char
			; all the same, so far...
	_EXIT_OK	; doesn't do much, either

; *** K16, get available PID ***
b_fork:			; Y -> PID
	LDY #0		; no multitasking, so far...
	_EXIT_OK

; *** K18, launch new process ***
b_exec:				; Y <- PID, z2L <- addr
	CPY #0			; no multitasking yet
	BNE k18_multi
	LDX zp_used		; how many bytes to save
	INX			; including that
k18_save:
	LDA zp_used-1, X	; get used byte
	PHA			; save it
	DEX			; countdown
	BNE k18_save		; another one
	STX zp_used		; reset variable for the new process!
	LDX #5			; now for the environment variables
k18_sys_sv:
	LDA sys_sp-1, X		; get a system byte
	PHA			; save it
	DEX			; countdown
	BNE k18_sys_sv		; and another one
	LDA #<k18_return-1	; LSB return address
	PHA			; pseudo-return for the RTS
	LDA #>k18_return-1	; MSB return address
	PHA
	JMP (z2)		; start code execution
k18_return:
	LDX #0			; reset index
k18_sys_rs:
	PLA			; retrieve system byte
	STA sysvec, X		; restore it
	INX			; count it
	CPX #8			; until it's done
	BNE k18_sys_rs
	PLA			; get number of user bytes
	STA zp_used		; restore it
	LDX #1			; reset index
k18_restore:
	PLA			; retrieve user byte
	STA user, X		; restore it
	INX			; count it
	DEY			; one less to go
	BNE k18_restore		; until it's done
	_EXIT_OK
k18_multi:
	_ERR(_no_rsrc)

; *** K20, get address once in RAM/ROM (kludge!) ***
load_link:		; z2L -> addr, z10L <- *path
; *** assume path points to filename in header, code begins +248
	CLC		; ready to add
	LDA z10L	; get LSB
	ADC #248	; offset to actual code!
	STA z2L		; store address LSB
	LDA z10L+1	; get MSB so far
	ADC #0		; propagate carry!
	STA z2L+1	; store address MSB
	LDA #0		; NMOS only
	STA z2L+2	; STZ, invalidate bank...
	STA z2L+3	; ...just in case
	BCS k20_wrap	; really unexpected error
	_EXIT_OK
k20_wrap:
	_ERR(_invalid)	; something was wrong

; *** K22, write to protected addresses ***
s_poke:			; Y <- value, z2L <- addr
	TYA		; transfer value
	_STAX(z2L)	; store value, macro for NMOS
	_EXIT_OK

; *** K24, read from protected addresses ***
s_peek:			; Y -> value, z2L <- addr
	_LDAX(z2L)	; store value, macro for NMOS
	TAY		; transfer value
	_EXIT_OK

; *** K26, prints a C-string ***
string:			; Y <- dev, z10L <- *string
	LDX #0		; NMOS only
	_LDAX(z10L)	; get current character, NMOS too
	BEQ k26_end	; NUL = end-of-string
	STA z2		; ready to go out
	STY z6		; save Y in case cout destroys it
	_KERNEL(_cout)	; call cout
	LDY z6		; restore Y
	INC z10L	; next character
	BNE string
	INC z10L+1	; cross page boundary
	BNE string
	_EXIT_OK

; ***** power-on self-test *****
post:
; *** SRAM test ***
	LDA #0			; NMOS only
	STA 2			; STZ, safe (this far) zeropage vector
	LDA #63			; up to 16 KiB SRAM
	STA 3			; safe (this far) zeropage vector
	STA 4			; accessible pages (may be mirrored)
raminit:
	LDY #0
ramtest:
	LDA #$AA		; test pattern
rampatt:
	STA (2), Y		; store pattern
	CMP (2), Y		; reads OK?
	BNE dec_page
	EOR #$FF		; alternate pattern
	BPL rampatt		; same check
	LDA 3			; get current number page
ramfill:
	STA (2), Y		; store page number anywhere
	CMP (2), Y		; reads OK?
	BEQ page_ok
dec_page:
	DEC 3			; non-mirrored, try one page less
	LDA 3
	STA 4			; DEC 4 would fail in case of a randomish error
	BNE raminit
	BEQ badram		; just zeropage? no way...
page_ok:
	INY
	BNE ramfill		; fill each page
	DEC 3			; previous page
	BNE ramtest
	LDX #2			; special test for zeropage
	LDA #$AA		; test pattern
zerotest:
	STA 0, X		; store it
	CMP 0, X		; reads OK?
	BNE badram
	EOR #$FF		; alternate pattern
	BPL zerotest		; same check
	INX			; next byte
	BNE zerotest		; until we're done
	BEQ measure		; compute SRAM size
badram:
	BRK			; complain???????
measure:
	LDA 4			; active pages (could be mirrored)
	STA 3			; safe (this far) zeropage vector
	LDA (2)			; last non-mirrored page number, anywhere in the page
	CLC			; NMOS only
	ADC #1			; increase before storing at himem
	STA himem		; number of SRAM pages
	LDA #3			; first free page so far
	STA ptr_page

; *** device initialisation ***
	JSR init_via		; standard initialisation
; initialise I/O drivers
	JSR init_led		; preliminary reset, should be from table
	JSR init_acia
	JSR init_lcd

; *** final startup! ***
	LDA #<isr		; get ISR address
	STA irqvec		; put it on vector
	LDA #>isr
	STA irqvec+1
	CLI			; enable interrupts
; do something useful...
	JSR shell		; launch monitor/shell
	BRK			; shouldn't arrive here, ever

init_via:
	LDA #$C2		; CB2 low, Cx1 negative edge, CA2 indep. neg.	
	STA pcr
	LDA #$40		; T1 cont, no PB7, no SR, no latch (so far)
	STA acr
	LDA #$7F		; disable all interrupts (for a moment)
	STA ier
	LDA #$35		; $C35 = 200 Hz interrupt @ 1.25 MHz
	STA t1l_l		; put value into latch
	LDA #$0C
	STA t1h_l
	STA t1c_h		; start counting!
	LDA #$C0		; enable T1 interrupt only
	STA ier
	RTS

init_led:
	JMP (drv_led+_d_init)	; do whatever is needed
init_acia:
	JMP (drv_acia+_d_init)	; will return to POST
init_lcd:
	JMP (drv_lcd+_d_init)	; will return to POST

; ***** non-maskable interrupt (debugger) *****
nmi:
	PHA		; save registers
	_PHX
	_PHY

debug:			; entry point for BRK
	; *****
	_PLY		; restore registers
	_PLX
	PLA
	RTI

; ***** interrupt request handler *****
irq:
	JMP (irqvec)	; vectored ISR

; ***** interrupt service routine *****
isr:
	PHA	; save registers
	_PHX
	_PHY
; check whether from VIA, BRK...
	LDA ifr
	ASL			; shift interrupt flags
	BPL async_irq		; not from T1
; execute driver poll routines, since it's periodic (VIA T1)
; there must be some better ways for doing this...
	JSR led_poll		; very important, muxes display and keypad
;	JSR acia_poll		; not really needed
;	JSR lcd_poll
	JMP isr_done		; finish up
led_poll:
	JMP (drv_led+_d_poll)	; should be from table
acia_poll:
	JMP (drv_acia+_d_poll)	; this should point to RTS (no polling)
lcd_poll:
	JMP (drv_lcd+_d_poll)	; does it get info?
; in case of non-periodic interrupt, let the drivers ask their devices
async_irq:
;	JSR led_req		; does nothing
	JSR acia_req		; increase a_irqs if detected!
;	JSR lcd_req
	JMP chk_brk		; finish up, unless it's a BRK
led_req:
	JMP (drv_led+_d_req)	; should be from table, but this will point to RTS (can't generate IRQs)
acia_req:
	JMP (drv_acia+_d_req)	; this one will get the job done
lcd_req:
	JMP (drv_lcd+_d_req)
; check for BRK
chk_brk:
	TSX			; get stack pointer
	LDA $0104, X		; get saved PSR
	AND #$10		; mask out B bit
	BNE break		; it was BRK
isr_done:
	_PLY	; restore registers
	_PLX
	PLA
	RTI
; *** do something to tell the debugger it's from BRK, not NMI...
break:
	JMP debug		; debug somehow

; ***** boot code *****
; choose boot address depending on PA0-PA3
reset:
	SEI		; in case of warm reset
	CLD		; just in case, a must for NMOS
	LDA #$10	; bit 4 high
	STA ddra	; only PA4 as output
	STA iora	; set PA4 high
	LDX #$FF	; initial stack pointer
	TXS		; initialise stack
	LDA #$0F	; mask 4 lower bits
	AND iora	; read PA0-PA3 for startup ID
	ASL		; multiply by 2
	TAX		; table index
	_JMPX(table)	; macro for NMOS, but revise it for 6510!

; error handler for system call primitive
bad_call:
	_ERR(_unavail)	; in case of odd function number

* = $FFC0		; 'kernel call' primitive, NEW ADDRESS
k_call:			; X <- function code
;	TXA		; preliminary check for odd codes
;	LSR		; check bit 0
;	BCS bad_call	; disaster
	_JMPX(k_vec)	; macro for NMOS, but revise it for 6510!

; boot addresses table
* = $FFD0
	.word post	; default startup address
	.dsb 30, $FF	; empty vectors

; 6502 vectors
* = $FFFA
	.word	nmi
	.word	reset
	.word	irq
