; firmware for minimOS on Kowalski simulator
; v0.9a1
; (c)2015-2016 Carlos J. Santisteban
; last modified 20160330-1627

#define		FIRMWARE	_FIRMWARE

; in case of stand alone assembly from 'xa firmware/template.s'
#ifndef		KERNEL
#include "options.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
.bss
#include "firmware/ARCH.h"
#include "sysvars.h"
.text
kernel		= remote_boot	; in case no kernel is provided with firmware, try to download one forever
* = ROM_BASE				; sample address
#endif

; *** first some ROM identification *** new 20150612
fw_start:
	.asc 0, "aS****", 13	; standard system file wrapper, new 20160309
	.asc "0.9a1 firmware for "
fw_mname:
	.asc	MACHINE_NAME, 0

	.dsb	fw_start + $FC - *, $FF	; generate padding to link
	.asc	$FF,$FF,$FF,$FF			; undefined ending???

; *** cold restart ***
; basic init
reset:
	SEI				; cold boot. Do not use macro, maybe no OS installed this far (2)
	CLD				; just in case, a must for NMOS, maybe for emulating '816 (2)
	LDX #SPTR		; initial stack pointer, machine-dependent, must be done in emulation for '816 (2)
	TXS				; initialise stack (2)
; disable all interrupt sources
	LDA #$7F		; disable all interrupts (2+4)
	STA VIA1 + IER

; and optionally check for VIA presence
#ifdef	SAFE
	LDA VIA1 + IER	; check VIA presence, NEW 20150118 (4)
	CMP #$80		; should read $80 (2)
	BEQ via_ok		; panic otherwise! (slight modification 20150121 and 0220) (3/2)
		_PANIC			; no other way to tell the world... (3)
#endif

#ifndef	FINAL
	_BRA via_ok			; skip the markup
	.asc	"<mods>"	; easier debugging
#endif

via_ok:

; *** optional firmware modules ***
; optional boot selector
#include "firmware/modules/bootoff.s"

; ***continue power-on self-test***
post:

; might check ROM integrity here
;#include "firmware/modules/romcheck.s"

; some systems might copy ROM-in-RAM and continue at faster speed!
;#include "firmware/modules/rominram.s"

; startup beep
#include "firmware/modules/beep.s"

; SRAM test
#include "firmware/modules/ramtest.s"

; *** VIA initialisation (and stop beeping) ***
	LDA #%11000010	; CB2 low, Cx1 negative edge, CA2 indep. neg. (2+4)
	STA VIA1 + PCR
	LDA #%01000000	; T1 cont, no PB7, no SR, no latch (so far) (2+4)
	STA VIA1 + ACR
; *** preset kernel start address (standard label from ROM file) ***
	LDA #<kernel	; get LSB (2)
	STA fw_warm		; store in sysvars (4)
	LDA #>kernel	; same for MSB (2+4)
	STA fw_warm+1
; *** set default CPU type ***
	LDA #CPU_TYPE	; constant from options.h (2)
	STA fw_cpu		; store variable (4)

; might check out here for the actual CPU type...
#include "firmware/modules/cpu_check.s"

; *** maybe this is the place for final interrupt setup *** 20150605
	LDA	#<T1_DIV	; set IRQ frequency divisor LSB ** revised 20150220 (2)
	STA VIA + T1CL	; put value into latch (write to counter) (4)
	LDA #>T1_DIV	; same for MSB (2)
	STA VIA + T1CH	; start counting! (4)
	LDA #<IRQ_FREQ	; interrupts per second, LSB ** revised 20150225 (2)
	STA irq_freq	; store speed... (4)
	STA ticks		; and counter value (4)
	LDA #>IRQ_FREQ	; same for MSB (2+4+4)
	STA irq_freq+1
	STA ticks+1
	LDX #3			; number of bytes in uptime seconds
res_sec:
		_STZA ticks+1, X	; reset byte, note special offset
		DEX					; next byte backwards
		BNE res_sec
	LDA #$C0		; enable T1 interrupt only (2+4)
	STA VIA + IER

#ifndef	FINAL
	_BRA remote_boot	; skip the markup
	.asc	"<boot>"	; easier debugging
#endif

; *** optional network booting ***
; might modify the contents of fw_warm
remote_boot:
;#include "firmware/modules/netboot.s"

; *** firmware ends, jump into the kernel ***
start_kernel:
	JMP (fw_warm)		; (6)

#ifndef	FINAL
	.asc	"<nmi>"		; easier debugging
#endif

; *** vectored NMI handler with magic number ***
nmi:

#ifdef	NMOS
	CLD					; eeeeeeeeek! 20150316
#endif

; save registers AND system pointers
	PHA					; save registers (3x3)
	_PHX
	_PHY
	LDX #0				; have to save systmp and sysptr, new 20150326 (2)
nmi_save:
		LDA sysptr, X		; get original byte (3)
		PHA					; put it on stack (3)
		INX					; go forward (2)
		CPX #3				; number of bytes to save, makes retrieving simpler (2)
		BNE nmi_save		; until the end (3/2, total loop is 38 clocks)
; check whether user NMI pointer is valid
	LDY #0				; offset for NMI code pointer (2)
;	LDX #3				; offset for (reversed) magic string (2) ** already loaded from earlier step
	LDA fw_nmi			; copy vector to zeropage (corrected 20150118) (4+3+4+3)
	STA sysptr
	LDA fw_nmi+1
	STA sysptr+1
nmi_chkmag:
		LDA (sysptr), Y		; get code byte (5)
		CMP fw_magic, X		; compare with string (4)
			BNE rst_nmi			; not a valid routine (2/3)
		INY					; another byte (2)
		DEX					; internal string is read backwards (2)
		BPL nmi_chkmag		; down to zero (3/2)
do_nmi:
	JSR go_nmi			; call actual code (6)
; *** here goes the former nmi_end routine ***
nmi_end:
	LDX #2				; have to retrieve systmp and sysptr, new 20150326 (2)
nmi_restore:
		PLA					; get byte from stack (4)
		STA sysptr, X		; restore it (3)
		DEX					; go backwards (2)
		BPL nmi_restore		; offset zero included (3/2, total loop is 35 clocks)
	_PLY				; restore regular registers
	_PLX
	PLA
	RTI					; resume normal execution, hopefully

go_nmi:
	JMP (fw_nmi)		; jump to code (and inocuous header) (6)

; *** execute standard NMI handler ***
rst_nmi:
	JSR std_nmi			; call standard handler
	_BRA nmi_end		; and finish as usual

; *** default code for NMI handler, if not installed or invalid ***
std_nmi:
#include "firmware/modules/std_nmi.s"
;	JMP (fw_warm)		; a much simpler way?

fw_magic:
	.asc	"*jNU"		; reversed magic string

#ifndef	FINAL
	.asc	"<admin>"	; easier debugging
#endif

; *** administrative functions ***
; A0, install jump table
; zpar.W <- address of supplied jump table
fw_install:
	LDY #0				; reset index (2)
	_ENTER_CS			; disable interrupts! (5)
fwi_loop:
		LDA (zpar), Y		; get from table as supplied (5)
		STA fw_table, Y		; copy where the firmware expects it (4+2)
		INY
		BNE fwi_loop		; until whole page is done (3/2)
	_EXIT_CS			; restore interrupts if needed (4)
	_EXIT_OK			; all done (8)


; A2, set IRQ vector
; zpar.W <- address of ISR
fw_s_isr:
	_ENTER_CS				; disable interrupts! (5)
	LDA zpar				; get LSB (3)
	STA fw_isr				; store for firmware (4)
	LDA zpar+1				; get MSB (3+4)
	STA fw_isr+1
	_EXIT_CS				; restore interrupts if needed (4)
	_EXIT_OK				; done (8)


; A4, set NMI vector
; zpar.W <- address of NMI code (including magic string)
; might check whether the pointed code starts with the magic string
; no need to disable interrupts as a partially set pointer would be rejected
fw_s_nmi:
	LDA zpar				; get LSB (3)
	STA fw_nmi				; store for firmware (4)
	LDA zpar+1				; get MSB (3+4)
	STA fw_nmi+1
	_EXIT_OK				; done (8)


; A6, patch single function
; zpar.W <- address of code
; Y <- function to be patched
fw_patch:
#ifdef		LOWRAM
	_ERR(UNAVAIL)			; no way to patch on 128-byte systems
#else
	LDA zpar				; get LSB (3)
	_ENTER_CS				; disable interrupts! (5)
	STA fw_table, Y			; store where the firmware expects it (4)
	LDA zpar+1				; same for MSB (3+4)
	STA fw_table+1, Y
	_EXIT_CS				; restore interrupts if needed (4)
	_EXIT_OK				; done (8)
#endif


; A8, get system info, API TBD
; zpar -> available pages of (kernel) SRAM (0 means 128-byte system)
; zpar+2.W -> available BANKS of RAM
; zpar2.B -> speedcode
; zpar2+2.B -> CPU type
; zpar3.W/L -> points to a string with machine name
; *** might change ABI/API ***
fw_gestalt:
	LDA himem		; get pages of kernel SRAM (4)
	STA zpar		; store output (3)
	_STZA zpar+2	; no bankswitched RAM yet (3+3)
	_STZA zpar+3
	_STZA zpar3+2	; same for string address (3+3)
	_STZA zpar3+3
	LDA #SPEED_CODE	; speed code as determined in options.h (2+3)
	STA zpar2
	LDA fw_cpu		; get kind of CPU (previoulsy stored or determined) (4+3)
	STA zpar2+2
	LDA #<fw_mname	; get string LSB (2+3)
	STA zpar3
	LDA #>fw_mname	; same for MSB (2+3)
	STA zpar3+1
	_EXIT_OK		; done (8)

; *************************** CONTINUE UP FROM HERE *****************************+

; A10, poweroff etc
; Y <- mode (0 = poweroff, 2 = suspend, 4 = coldboot, 6 = warm?)
; C -> not implemented
fw_power:
	TYA					; get subfunction offset
	TAX					; use as index
	_JMPX(fwp_func)		; select from jump table

fwp_off:
	BRK					; stop simulation!
	.asc	"{OFF}", 0	; just in case is handled

fwp_susp:
	RTS					; just continue execution

fwp_cold:
	JMP ($FFFC)			; call 6502 vector, not really needed here but...

; sub-function jump table
fwp_func:
	.word	fwp_off		; poweroff	+FW_OFF
	.word	fwp_susp	; suspend	+FW_STAT
	.word	fwp_cold	; coldboot	+FW_COLD
	.word	kernel		; shouldn't use this, just in case

; *** administrative jump table ***
; PLEASE CHANGE ORDER ASAP
fw_admin:
	.word	fw_install
	.word	fw_s_isr
	.word	fw_s_nmi
	.word	fw_patch	; new order 20150409
	.word	fw_gestalt
	.word	fw_power

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	kernel_call-*, $FF
#endif

; *** minimOS function call primitive ($FFC0) ***
* = kernel_call
	_JMPX(fw_table)	; macro for NMOS compatibility (6)

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	admin_call-*, $FF
#endif

; *** administrative meta-kernel call primitive ($FFD0) ***
* = admin_call
	_JMPX(fw_admin)		; takes 6 clocks with CMOS

; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	panic-*, $FF
#endif

; *** panic routine, locks at very obvious address ($FFE1-$FFE2) ***
* = panic
	SEC					; unified procedure 20150410, was CLV
panic_loop:
	BCS panic_loop		; no problem if /SO is used, new 20150410, was BVC

; no 65816 vectors on simulator!

; *** vectored IRQ handler ***
irq:
	JMP (fw_isr)	; vectored ISR (6)

; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	$FFFA-*, $FF
#endif

; *** 65(C)02 ROM vectors ***
* = $FFFA				; just in case
	.word	nmi			; (emulated) NMI	@ $FFFA
	.word	reset		; (emulated) RST	@ $FFFC
	.word	irq			; (emulated) IRQ	@ $FFFE
