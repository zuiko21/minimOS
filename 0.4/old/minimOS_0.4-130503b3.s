; minimOS 0.4b3 - SDd, 6502
; (c) 2012-2013 Carlos J. Santisteban
; last modified 2013.05.03

; first allocatable SRAM page, architecture dependant!
#define _lomem	3

; conditional assembly, select machine from SDd, SDx, MTE, Baja, Veracruz...
#define SDd 0

; conditional assembly, indicate NMOS for macros replacing new opcodes
;#define NMOS 0

; *** include files ***
; generic definitions
#include "macros_0.4.h"
#include "api_0.4.h"

; label definitions
.zero
#include "zeropage_0.4.h"

; system variables
.bss
#include "sysvars_0.4.h"

; driver-specific system variables
#include "drivers/drv_led.h"
;#include "drivers/drv_acia.h"
;#include "drivers/drv_ss22.h"

.text

; ***** the kernel contents *****
* = $F800		; *** 27C16 savvy address ***
k_vec:			; kernel's entry points
	.word cout	; output a character
	.word cin	; get a character
	.word malloc	; reserve memory (kludge!)
	.word free	; release memory (kludgest!)
	.word open_w	; get I/O port or window
	.word close_w	; close window
	.word free_w	; will be closed by kernel
	.word hid_push	; insert into input queue (deprecated)
	.word b_fork	; get available PID
	.word b_exec	; launch new process
	.word load_link	; get addr. once in RAM/ROM
	.word su_poke	; write protected addresses
	.word su_peek	; read protected addresses
	.word string	; prints a C-string
	.word dis_int	; disable interrupts
	.word en_int	; enable interrupts (not needed for 65xx)
	.word set_fg	; enable frequency generator (VIA T1@PB7)

; ***** I/O device drivers *****
; begin with address table for sub-functions
drv_ss22:			; SS-22 link
;#include "drivers/drv_ss22.s"
drv_acia:			; serial port
;#include "drivers/drv_acia.s"
drv_lcd:			; Hitachi LCD
;#include "drivers/drv_lcd.s"

; dummy driver, eight fake addresses
dummy_drv:
	.word void_routine	; +_d_init, device reset
	.word void_routine	; +_d_poll, device poll, called periodically
	.word void_routine	; +_d_req, asynchronous interrupt request by device (should verify source)
	.word void_routine	; +_d_in, device input, get character from device or buffer
	.word void_routine	; +_d_out, device output, buffered or not
	.word void_routine	; +_d_1sec, one second periodic interrupt
	.word void_routine	; +_d_bli, device input, block transfer
	.word void_routine	; +_d_blo, device output, block transfer
	.word void_routine	; +_d_bye, shutdown procedure
	.byt 	0		; +_d_auth, feature authorization code (new), dummy driver does nothing
	.byt	0		; +_d_num, reserved for alignment (device number!)
void_routine:
	_EXIT_OK		; essentially RTS

drv_led:			; should be default device, currently
#include "drivers/drv_led.s"

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
	CPY #ss22_dev		; SS-22?
	BNE k0_no_ss22
	JMP (drv_ss22+_d_out)	; may call its label on driver code
k0_no_ss22:
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
	CPY #ss22_dev		; SS-22?
	BNE k2_no_ss22
	JMP (drv_ss22+_d_in)	; may call its label on driver code
k2_no_ss22:
	CPY #acia_dev		; serial port?
	BNE k2_no_acia
	JMP (drv_acia+_d_in)	; @device drivers area
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
	LDA z2+2
	ORA z2+3	; asking over 16 K?
	BEQ k4_no_bank	; no bank switching...
	_ERR(_full)	; ...available so far
k4_no_bank:
	CLC		; for adding
	LDA z2+1	; number of pages
	LDX z2		; round size?
	BEQ k4_aligned	; no need for extra page
	SEC		; else increase result
k4_aligned:
	ADC ptr_page	; next free page
	CMP himem	; it's beyond the limit?
	BMI k4_enough	; OK, then
	_ERR(_full)	; else no room
k4_enough:
	LDX ptr_page	; start address
	STX z6+1	; store at output parameter
	_STZX z6	; aligned page, using X for NMOS
	STA ptr_page	; update pointer for next req...
	_EXIT_OK

; *** K6, release memory (kludgest!) ***
free:			; z6L <- addr
	LDA z6+1	; get start page
	STA ptr_page	; it's now the first free page!
	_EXIT_OK

; *** K8, get I/O port or window ***
open_w:				; Y -> dev, z2W -> size, z10W -> pos
				; z6L -> pointer to window title?
	LDA z2			; asking for some size?
	ORA z2+1
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
	LDA z10		; get LSB
	ADC #248	; offset to actual code!
	STA z2		; store address LSB
	LDA z10+1	; get MSB so far
	ADC #0		; propagate carry!
	STA z2+1	; store address MSB
	LDA #0		; NMOS only
	STA z2+2	; STZ, invalidate bank...
	STA z2+3	; ...just in case
	BCS k20_wrap	; really unexpected error
	_EXIT_OK
k20_wrap:
	_ERR(_invalid)	; something was wrong

; *** K22, write to protected addresses ***
su_poke:		; Y <- value, z2L <- addr
	TYA		; transfer value
	_STAX(z2)	; store value, macro for NMOS
	_EXIT_OK

; *** K24, read from protected addresses ***
su_peek:		; Y -> value, z2L <- addr
	_LDAX(z2)	; store value, macro for NMOS
	TAY		; transfer value
	_EXIT_OK

; *** K26, prints a C-string ***
string:			; Y <- dev, z10L <- *string
	_LDAX(z10)	; get current character, NMOS too
	BEQ k26_end	; NUL = end-of-string
	STA z2		; ready to go out
	STY z6		; save Y in case cout destroys it
	_KERNEL(_cout)	; call cout
	LDY z6		; restore Y
	INC z10		; next character
	BNE string
	INC z10+1	; cross page boundary
	BNE string	; ...or BRA
k26_end:
	_EXIT_OK

; *** K28, disable interrupts ***
dis_int:		; C -> not authorized (?)
	SEI		; disable interrupts
	CLC		; no error so far
	RTS

; *** K30, enable interrupts ***
en_int:			; not needed for 65xx, even with protection hardware
	CLI		; enable interrupts
	CLC		; no error
	RTS

; *** K32, enable/disable frequency generator (Phi2/n) on VIA ***
set_fg:			; z2 <- dividing factor (times two?)
	LDA z2
	ORA z2+1
	BEQ k32_dis	; if zero, disable output
	LDA _VIA+_acr	; get current configuration
	BMI k32_busy	; already in use
	LDX _VIA+_t1ll	; get older T1 latch values
	STX old_t1	; save them
	LDX _VIA+_t1lh
	STX old_t1+1
	LDX z2		; get new division factor
	STX _VIA+_t1ll	; store it
	LDX z2+1
	STX _VIA+_t1lh
	STX _VIA+_t1ch	; get it running!
	ORA #$C0	; enable free-run PB7 output
	STA _VIA+_acr	; update config
k32_none:
	_EXIT_OK	; finish anyway
k32_dis:
	LDA _VIA+_acr	; get current configuration
	BPL k32_none	; it wasn't playing!
	AND #$7F	; disable PB7 only
	STA _VIA+_acr	; update config
	LDA old_t1	; older T1L_L
	STA _VIA+_t1ll	; restore old value
	LDA old_t1+1
	STA _VIA+_t1lh	; it's supposed to be running already
	_BRA k32_none
k32_busy:
	_ERR(_busy)	; couldn't set

; ***** micro-kernel begins *****
; ***** power-on self-test *****
post:
	SEI			; just in case, but already in boot code?
	CLD			; in case of warm reset, even for CMOS
; should check out here for the 65xx version...
; *** initial beep (500Hz/MHz) during SRAM test ***
	LDA #%11100010		; CB2 *high*, Cx1 negative edge, CA2 indep. neg.	
	STA _VIA+_pcr		; sound output is enabled
	LDA #%11000000		; T1 cont, PB7 squarewave, no SR, no latch (so far)
	STA _VIA+_acr
	LDA #$7F		; disable all interrupts
	STA _VIA+_ier
	LDA #$A8		; $61A8 = 500 Hz beep @ 1 MHz
	STA _VIA+_t1ll		; put value into latch
	LDA #$61
	STA _VIA+_t1lh
	STA _VIA+_t1ch		; start counting!	
; *** SRAM test ***
	_STZA user		; safe (this far) zeropage vector
	LDA #_SRAM		; highest SRAM page number, architecture dependant!
	STA user+1		; safe (this far) zeropage vector
	STA user+2		; accessible pages (may be mirrored)
raminit:
	LDY #0
ramtest:
	LDA #$AA		; test pattern
rampatt:
	STA (user), Y		; store pattern
	CMP (user), Y		; reads OK?
	BNE dec_page
	EOR #$FF		; alternate pattern
	BPL rampatt		; same check
	LDA user+1		; get current number page
ramfill:
	STA (user), Y		; store page number anywhere
	CMP (user), Y		; reads OK?
	BEQ page_ok
dec_page:
	DEC user+1		; non-mirrored, try one page less
	LDA user+1
	STA user+2		; DEC would fail in case of a randomish error
	BNE raminit
	BEQ badram		; just zeropage? no way...
page_ok:
	INY
	BNE ramfill		; fill each page
	DEC user+1		; previous page
	BNE ramtest
	LDX #2			; special test for zeropage (6510 savvy)
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
	LDA user+2		; active pages (could be mirrored)
	STA user+1		; safe (this far) zeropage vector
	LDA (user)		; last non-mirrored page number, anywhere in the page
	_INC			; before storing at himem
	STA himem		; number of SRAM pages
	LDA #_lomem		; first free page so far
	STA ptr_page

; *** device initialisation ***
	JSR init_via		; standard initialisation
; initialise I/O drivers
	JSR init_led		; preliminary reset, should be from table
;	JSR init_ss22
;	JSR init_acia
;	JSR init_lcd

; *** set default I/O device ***
	LDA #led_dev	; much better than just zero
	STA default_out	; should check some devices, now defaults to LED keypad
	STA default_in

; *** final startup! ***
	LDA #<isr		; get ISR address
	STA irqvec		; put it on vector
	LDA #>isr
	STA irqvec+1
	CLI			; enable interrupts
; say hello!
	LDA #<hello		; LSB of the string
	STA z10
	LDA #>hello		; MSB
	STA z10+1
	LDY #0			; default device, currently LED
	_KERNEL(_string)	; print the message
; do something useful...
	JMP shell		; launch monitor/shell
hello:
	.asc "Hola", 0		; startup text
shell:				; so far, a post-POST task only!
	LDY default_out	; default device, should be LED keypad
	_KERNEL(_cin)		; get character
	BCS shell		; no key was pressed
	_KERNEL(_cout)		; output it
	_BRA shell		; repeat forever!

init_via:
	LDA #%11000010		; CB2 low, Cx1 negative edge, CA2 indep. neg.	
	STA _VIA+_pcr
	LDA #%01000000		; T1 cont, no PB7, no SR, no latch (so far)
	STA _VIA+_acr
	LDA #$7F		; disable all interrupts (for a moment)
	STA _VIA+_ier
	LDA #$88		; $1388 = 200 Hz interrupt @ 2 MHz
	STA _VIA+_t1ll		; put value into latch
	LDA #$13
	STA _VIA+_t1lh
	STA _VIA+_t1ch		; start counting!
	LDA #$C0		; enable T1 interrupt only
	STA _VIA+_ier
	RTS

init_led:
	JMP (drv_led+_d_init)	; do whatever is needed
init_ss22:
	JMP (drv_ss22+_d_init)	; do whatever is needed
init_acia:
	JMP (drv_acia+_d_init)	; will return to POST
init_lcd:
	JMP (drv_lcd+_d_init)	; will return to POST

; ***** non-maskable interrupt (debugger) *****
nmi:
	PHA		; save registers
	_PHX
	_PHY
	LDA #<nmi_txt	; string address load
	STA sysvec
	LDA #>nmi_txt
	STA sysvec+1
debug:			; entry point for BRK
	LDA z2		; save possible kernel function in progress
	PHA
	LDY default_out	; default device
deb_str:
	_LDAX(sysvec)	; get character
	BEQ deb_wait	; NUL at end of string
	STA z2		; put parameter
	_KERNEL(_cout)	; character output, shouldn't use regular kernel, but...
	INC sysvec	; next character
	BNE deb_str
	INC sysvec+1	; boundary crossing
	_BRA deb_str

; ***** simulate interrupts calling led_poll!
deb_wait:
	LDX #4		; about 195 Hz @ 1 MHz, no need to set the LSB
deb_dly:
	DEY
	BNE deb_dly	; delay loop, 1280 clocks
	DEX		; one iteration less
	BNE deb_dly
	JSR led_get	; simulate interrupt!

; ***** read key and wait until OK is pressed
	JSR led_cin	; read keypad buffer
	BCS deb_wait	; nothing pressed
	LDA z2		; the ASCII code
	CMP #_cr	; is it OK?
	BNE deb_wait	; keep waiting otherwise
	
	PLA		; retrieve old parameter
	STA z2		; nothing has changed!

; return to process
	_PLY		; restore registers
	_PLX
	PLA
	RTI
nmi_txt:		; splash text string
	.asc "NMI ", 0

; ***** interrupt request handler *****
irq:
	JMP (irqvec)	; vectored ISR

; ***** interrupt service routine *****
isr:
	PHA	; save registers
	_PHX
	_PHY
; check whether from VIA, BRK...
	BIT _VIA+_ifr		; much better than LDA + ASL + BPL!
	BVC async_irq		; not from T1
; execute driver poll routines, since it's periodic (VIA T1)
; there must be some better ways for doing this...
	LDA _VIA+_t1cl		; acknowledge interrupt!!!!!!!!!!!!!!!!!!!!!
	JSR led_poll		; very important, muxes display and keypad
isr_done:
	_PLY	; restore registers
	_PLX
	PLA
	RTI
led_poll:
	JMP (drv_led+_d_poll)	; should be from table
; in case of non-periodic interrupt, let the drivers ask their devices
async_irq:
	JSR ss22_req		; service routine, may be direct label
;	BCC isr_done		; IRQ serviced by a driver -> go away!
	JSR acia_req		; increase a_irqs if detected! (???)
;	BCC isr_done		; IRQ serviced by a driver -> go away!
; check for BRK
	TSX			; get stack pointer
	LDA $0104, X		; get saved PSR
	AND #$10		; mask out B bit
	BNE break		; it was BRK
	BEQ isr_done		; spurious interrupt!
ss22_req:
	JMP (drv_ss22+_d_req)	; manage generated interrupt
acia_req:
	JMP (drv_acia+_d_req)	; this one will get the job done
; *** do something to tell the debugger it's from BRK, not NMI...
break:
	LDA #<brk_txt	; string address load
	STA sysvec
	LDA #>brk_txt
	STA sysvec+1
	JMP debug		; debug somehow
brk_txt:
	.asc "BRK ", 0		; splash text string

; ***** boot code *****
; choose boot address depending on PA0-PA3
reset:
	SEI		; in case of warm reset
	CLD		; just in case, a must for NMOS
	LDA #$10	; bit 4 high
	STA _VIA+_ddra	; only PA4 as output
	STA _VIA+_iora	; set PA4 high
	LDX #_SP	; initial stack pointer
	TXS		; initialise stack
	LDA #$0F	; mask 4 lower bits
	AND _VIA+_iora	; read PA0-PA3 for startup ID
	ASL		; multiply by 2
	TAX		; table index
	_JMPX(table)	; macro for NMOS, but revise it for 6510!

; help for manual linking...
	.asc	" minimOS 0.4b3, SDd CMOS ", 0
	
* = $FFC0		; 'kernel call' primitive, NEW ADDRESS
k_call:			; X <- function code
;	TXA		; preliminary check for odd codes
;	LSR		; check bit 0
;	BCS bad_call	; disaster
	_JMPX(k_vec)	; macro for NMOS, not 6510-savvy!

; error handler for system call primitive, currently unused
bad_call:
/*	_ERR(_unavail)	; in case of odd function number */

; boot addresses table, may contain future primitives
* = $FFD0
table:
	.word post	; default startup address
	.dsb 30, $FF	; empty vectors

; 6502 vectors
* = $FFFA
	.word	nmi
	.word	reset
	.word	irq
