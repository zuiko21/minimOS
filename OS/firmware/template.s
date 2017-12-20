; more-or-less generic firmware for minimOS·65
; v0.6b1
; (c)2015-2017 Carlos J. Santisteban
; last modified 20171220-0828

#define		FIRMWARE	_FIRMWARE

#include "usual.h"

; already set at FW_BASE via rom.s

.(
#ifndef	NOHEAD
; *** first some ROM identification *** new 20150612
; this is expected to be loaded at an aligned address anyway
fw_start:
	.asc 0, "m", CPU_TYPE			; standard system file wrapper, new format 20161010, experimental type
	.asc "****", CR					; flags TBD
	.asc "boot", 0					; standard filename
fw_splash: 
	.asc "0.6b1 firmware for "	; machine description as comment
fw_mname:
	.asc	MACHINE_NAME, 0
; advance to end of header
	.dsb	fw_start + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$7000	; time, 13.00
	.word	$4AC2	; date, 2017/6/2

fwSize	=	fw_end - fw_start - 256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	fwSize			; filesize
	.word	0				; 64K space does not use upper 16-bit
; *** end of standard header ***
#else
; if no headers, put identifying strings somewhere
fw_splash:
	.asc	"0.6b1 firmware for "
fw_mname:
	.asc	MACHINE_NAME, 0		; store the name at least
#endif

; *** cold restart ***
; basic init
reset:
	SEI				; cold boot, best assume nothing (2)
	CLD				; just in case, a must for NMOS (2)
; * this is in case a 65816 is being used, but still compatible with all *
	SEC				; would set back emulation mode on C816
	.byt	$FB		; XCE on 816, NOP on C02, but illegal 'ISC $0005, Y' on NMOS!
	ORA $0			; the above would increment some random address in zeropage (NMOS) but this one is inocuous on all CMOS
; * end of 65816 specific code *
	LDX #SPTR		; initial stack pointer, machine-dependent, must be done in emulation for '816 (2)
	TXS				; initialise stack (2)

; ******************************
; *** minimal hardware setup ***
; ******************************
; disable all interrupt sources
	LDA #$7F		; disable all interrupts (2+4)
	STA VIA_J + IER	; *** this is for single VIA systems ***

; and optionally check for VIA presence
#ifdef	SAFE
	LDA VIA_J + IER	; check VIA presence, NEW 20150118 (4)
	CMP #$80		; should read $80 (2)
	BEQ via_ok		; panic otherwise! (slight modification 20150121 and 0220) (3/2)
		JMP lock		; no other way to tell the world... (3)
via_ok:
#endif

; *********************************
; *** optional firmware modules ***
; *********************************

; optional boot selector
;#include "firmware/modules/bootoff.s"

; ***continue power-on self-test***
post:
; might check ROM integrity here
;#include "firmware/modules/romcheck.s"

; *** some systems might copy ROM-in-RAM and continue at faster speed! ***
;#include "firmware/modules/rominram.s"

; startup beep
#include "firmware/modules/beep.s"	; basic standard beep

; SRAM test
#include "firmware/modules/ramtest.s"

; ***********************************
; *** firmware parameter settings ***
; ***********************************

; *** set default CPU type ***
;	LDA #CPU_TYPE			; REDUNDANT if actual test is done (2)
; ...but check it for real afterwards
#include	"firmware/modules/cpu_check.s"
; module will no longer store value
	STA fw_cpu			; store variable (4)

; *** in case an NMOS CPU is used, this code must be assembled for it!
; assume A holds CPU code as per above
#ifdef	SAFE
#ifndef	NMOS
	CMP #'N'		; is it NMOS? not supported!
	BNE fw_cpuOK	; otherwise continue
		JMP lock		; cannot handle BRK, alas
fw_cpuOK:
#endif
#endif

; *** preset kernel start address (standard label from ROM file) ***
	LDY #<kernel	; get LSB, nicer (2)
	LDA #>kernel	; same for MSB (2)
	STY fw_warm		; store in sysvars (4+4)
	STA fw_warm+1

; *** preset default BRK & NMI handlers ***
	LDY #<std_nmi			; default BRK like standard NMI
	LDA #>std_nmi
	STY fw_brk			; set vector
	STA fw_brk+1
; no need to set NMI as it will be validated

; *** preset jiffy irq frequency ***
; this should be done by installed kernel, but at least set to zero for 0.5.x compatibility!
	_STZA irq_freq		; store null speed... IRQ not set
	_STZA irq_freq+1

; *** reset jiffy count ***
	LDX #3				; max offset in uptime (assume contiguous)
res_sec:
		_STZA ticks, X		; reset byte
		DEX					; next byte backwards
		BPL res_sec			; zero is included

; ********************************
; *** hardware interrupt setup ***
; ********************************





; *** maybe this is the place for final interrupt setup *** 20150605
; *********************************************
; *** VIA initialisation (and stop beeping) ***
; *********************************************
	LDA #%11000010	; CB2 low, Cx1 negative edge, CA2 indep. neg. (2+4)
	STA VIA_J + PCR
	LDA #%01000000	; T1 cont, no PB7, no SR, no latch (so far) (2+4)
	STA VIA_J + ACR

; first of all, compute Timer 1 division factor, out from options.h 20160407
T1_DIV = PHI2/IRQ_FREQ-2

	LDY	#<T1_DIV		; set IRQ frequency divisor LSB ** revised 20150220 (2)
	LDA #>T1_DIV		; same for MSB, nicer (2)
	STY VIA_J + T1CL	; put value into latch (write to counter) (4)
	STA VIA_J + T1CH	; start counting! (4)
	LDX #5				; max offset in uptime seconds AND ticks (assume contiguous)
res_sec:
		_STZA ticks, X		; reset byte
		DEX					; next byte backwards
		BPL res_sec			; zero is included
	LDA #$C0			; enable T1 (jiffy) interrupt only (2+4)
	STA VIA_J + IER

; *** optional network booting ***
; might modify the contents of fw_warm
-remote_boot:
;#include "firmware/modules/netboot.s"

; *** firmware ends, jump into the kernel ***
start_kernel:
	JMP (fw_warm)		; (6)

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
;	LDX #3				; offset for (reversed) magic string (2) ** already loaded from earlier step
	LDY fw_nmi			; copy vector to zeropage (corrected 20150118) (4+4+3+3)
	LDA fw_nmi+1
	STY sysptr			; nicer way 20160407
	STA sysptr+1
	LDY #0				; offset for NMI code pointer (2)
nmi_chkmag:
		LDA (sysptr), Y		; get code byte (5)
		CMP fw_magic, X		; compare with string (4)
			BNE rst_nmi			; not a valid routine (2/3)
		INY					; another byte (2)
		DEX					; internal string is read backwards (2)
		BPL nmi_chkmag		; down to zero (3/2)
do_nmi:
	JSR go_nmi			; call actual code, ending in RTS (6)
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

; *** execute installed NMI handler ***
go_nmi:
	JMP (fw_nmi)		; jump to code (and inocuous header) (6)

; *** execute standard NMI handler ***
rst_nmi:
	JSR std_nmi			; call standard handler
	_BRA nmi_end		; and finish as usual

fw_magic:
	.asc	"*jNU"		; reversed magic string

; *** default code for NMI handler, if not installed or invalid, should end in RTS ***
std_nmi:
#include "firmware/modules/std_nmi.s"


; *** administrative functions ***
; A0, install jump table
; kerntab <- address of supplied jump table
fw_install:
	LDY #0				; reset index (2)
	_ENTER_CS			; disable interrupts! (5)
fwi_loop:
		LDA (kerntab), Y	; get from table as supplied (5)
		STA fw_table, Y		; copy where the firmware expects it (4+2)
		INY
		BNE fwi_loop		; until whole page is done (3/2)
	_EXIT_CS			; restore interrupts if needed (4)
	_DR_OK				; all done (8)


; A2, set IRQ vector
; kerntab <- address of ISR
fw_s_isr:
	LDY kerntab				; get LSB, nicer (3)
	LDA kerntab+1			; get MSB (3)
	_ENTER_CS				; disable interrupts! (5)
	STY fw_isr				; store for firmware (4+4)
	STA fw_isr+1
	_EXIT_CS				; restore interrupts if needed (4)
	_DR_OK					; done (8)


; A4, set NMI vector
; kerntab <- address of NMI code (including magic string)
; might check whether the pointed code starts with the magic string
; no need to disable interrupts as a partially set pointer would be rejected
fw_s_nmi:
#ifdef	SAFE
	LDX #3					; offset to reversed magic string
	LDY #0					; reset supplied pointer
fw_sn_chk:
		LDA (kerntab), Y		; get pointed handler string char
		CMP fw_magic, X			; compare against reversed string
		BEQ fw_sn_ok			; no problem this far...
			_DR_ERR(CORRUPT)		; ...or invalid NMI handler
		INY						; try next one
		DEX
		BPL fw_sn_chk			; until all done
#endif
	LDY kerntab				; get LSB (3)
	LDA kerntab+1			; get MSB (3)
	STY fw_nmi				; store for firmware (4+4)
	STA fw_nmi+1
	_DR_OK					; done (8)


; A6, patch single function
; kerntab <- address of code
; Y <- function to be patched
fw_patch:
#ifdef		LOWRAM
	_DR_ERR(UNAVAIL)		; no way to patch on 128-byte systems
#else
	LDY kerntab				; get LSB (3)
	LDA kerntab+1			; same for MSB (3)
	_ENTER_CS				; disable interrupts! (5)
	STA fw_table, Y			; store where the firmware expects it (4+4)
	STA fw_table+1, Y
	_EXIT_CS				; restore interrupts if needed (4)
	_DR_OK					; done (8)
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
	_DR_OK			; done (8)


; A10, poweroff etc
; Y <- mode (0 = poweroff, 2 = suspend, 4 = coldboot, 6 = warm?)
; C -> not implemented
fw_power:
	TYA					; get subfunction offset
	TAX					; use as index
	_JMPX(fwp_func)		; select from jump table

fwp_off:
#include "firmware/modules/poweroff.s"

fwp_susp:
#include "firmware/modules/suspend.s"

fwp_cold:
	JMP ($FFFC)			; call 6502 vector, as firmware start will initialize as needed

; sub-function jump table
fwp_func:
	.word	fwp_off		; poweroff	+FW_OFF
	.word	fwp_susp	; suspend	+FW_STAT
	.word	fwp_cold	; coldboot	+FW_COLD
	.word	kernel		; shouldn't use this, just in case

; *** administrative jump table ***
; might go elsewhere as it may grow, especially on NMOS
; WILL CHANGE ORDER
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
	_JMPX(fw_table)	; macro for NMOS compatibility (6) this will be a wrapper on 816 firmware!

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	admin_call-*, $FF
#endif

; *** administrative meta-kernel call primitive ($FFD0) ***
* = admin_call
	_JMPX(fw_admin)		; takes 6 clocks with CMOS


; *** vectored IRQ handler ***
; might go elsewhere, especially on NMOS systems
irq:
	JMP (fw_isr)	; vectored ISR (6)

; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	lock-*, $FF
#endif

; *** panic routine, locks at very obvious address ($FFE1-$FFE2) ***
* = lock
	SEC					; unified procedure 20150410, was CLV
panic_loop:
	BCS panic_loop		; no problem if /SO is used, new 20150410, was BVC
	NOP					; padding for reserved C816 vectors

; *** 65C816 ROM vectors ***
* = $FFE4				; should be already at it
	.word	fwp_cold	; native COP		@ $FFE4
	.word	fwp_cold	; native BRK		@ $FFE6
	.word	fwp_cold	; native ABORT		@ $FFE8
	.word	fwp_cold	; native NMI		@ $FFEA
	.word	$FFFF		; reserved			@ $FFEC
	.word	fwp_cold	; native IRQ		@ $FFEE
	.word	$FFFF		; reserved			@ $FFF0
	.word	$FFFF		; reserved			@ $FFF2
	.word	nmi			; emulated COP		@ $FFF4
	.word	$FFFF		; reserved			@ $FFF6
	.word	nmi			; emulated ABORT 	@ $FFF8
; *** 65(C)02 ROM vectors ***
* = $FFFA				; just in case
	.word	nmi			; (emulated) NMI	@ $FFFA
	.word	reset		; (emulated) RST	@ $FFFC
	.word	irq			; (emulated) IRQ	@ $FFFE

fw_end:					; for size computation
.)
