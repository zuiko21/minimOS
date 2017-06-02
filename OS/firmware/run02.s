; firmware for minimOS on run65816 BBC simulator
; 65c02 version for testing 8-bit kernels
; *** use as sort-of template ***
; v0.9.6a2
; (c)2017 Carlos J. Santisteban
; last modified 20170602-0904

#define		FIRMWARE	_FIRMWARE

; in case of standalone assembly
#include "usual.h"

; *** first some ROM identification *** new 20150612
; this is expected to be loaded at an aligned address anyway
#ifndef	NOHEAD
fw_start:
	.asc	0, "m", CPU_TYPE	; special system wrapper
	.asc	"****", CR			; flags TBD
	.asc	"boot", 0			; mandatory filename for firmware
fw_splash:
	.asc	"0.9.6 firmware for "
fw_mname:
	.asc	MACHINE_NAME, 0

; advance to end of header
	.dsb	fw_start + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$4800			; time, 9.00
	.word	$4AC2			; date, 2017/6/2

fwSize	=	$10000 - fw_start - 256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	fwSize			; filesize
	.word	0				; 64K space does not use upper 16-bit
; *** end of standard header ***
#endif

; ********************
; *** cold restart ***
; ********************
; basic init
reset:
	SEI				; cold boot (2) not needed for simulator?
	CLD				; just in case, a must for NMOS (2)
; * this is in case a 65816 is being used, but still compatible with all *
	SEC				; would set back emulation mode on C816
	.byt	$FB		; XCE on 816, NOP on C02, but illegal 'ISC $0005, Y' on NMOS!
	ORA $0			; the above would increment some random address in zeropage (NMOS) but this one is inocuous on all CMOS
; * end of 65816 specific code *
	LDX #SPTR		; initial stack pointer, machine-dependent, must be done in emulation for '816 (2)
	TXS				; initialise stack (2)

; *** optional firmware modules ***
post:

; might check ROM integrity here
;#include "firmware/modules/romcheck.s"

; SRAM test
;#include "firmware/modules/ramtest.s"

; *** set default CPU type ***
	LDA #'V'			; 65816 installed (2)
	STA fw_cpu			; store variable (4)
; ...but check it for real afterwards
#include	"firmware/modules/cpu_check.s"

; *** preset kernel start address (standard label from ROM file) ***
	LDA #>kernel			; get full address
	LDY #<kernel
	STA fw_warm+1			; store in sysvars
	STY fw_warm

; *** preset jiffy irq *** this should be done by installed kernel!
	LDA #>IRQ_FREQ	; interrupts per second
	LDY #<IRQ_FREQ
	STA irq_freq+1	; store speed...
	STY irq_freq

; *** preset default BRK & NMI handlers ***
	LDA #>brk_handler	; standard label from IRQ file
	LDY #<brk_handler
	STY fw_brk			; store default handler
	STA fw_brk+1
; since the NMI handler is validated, no need to install a default

	LDX #4				; max WORD offset in uptime seconds AND ticks, assume contiguous (2)
res_sec:
		_STZA ticks, X		; reset word (5)
		DEX					; next backwards
		BPL res_sec			; zero is included
;	LDX #$C0			; enable T1 (jiffy) interrupt only, this in 8-bit (2+4)
;	STX VIA_J + IER


; ******* debug code, direct print some string *******
	LDX #0				; reset index
fws_loop:
		LDA fw_splash, X	; get char
			BEQ fws_cr			; no more to print
		_PHX				; keep reg (not really needed)
#ifdef	NMOS
		LDA fw_splash, X	; get char AGAIN
#endif
		JSR $c0c2			; Eh output
		_PLX
		INX					; next char
		BNE fws_loop		; no need for BRA
fws_cr:
	LDA #LF				; trailing CR, needed by console!
	JSR $c0c2			; direct print
; ******* end of debug code **************************

; *** firmware ends, jump into the kernel ***
start_kernel:
	JMP (fw_warm)		; (5)

; *** vectored NMI handler with magic number ***
nmi:
; save registers AND system pointers
	PHA					; save registers
	_PHX
	_PHY
; make NMI reentrant
	LDY sysptr			; get original word 
	LDX sysptr+1
	LDA systmp			; this byte only
	_PHY					; store them in similar order
	_PHX
	PHA
; prepare for next routine
	LDA fw_nmi			; copy vector to zeropage
	LDY fw_nmi+1
	STA sysptr
	STY sysptr+1
; check whether user NMI pointer is valid
	LDX #3				; offset for (reversed) magic string, no longer preloaded (2)
	LDY #0				; offset for NMI code pointer (2)
nmi_chkmag:
		LDA (sysptr), Y		; get code byte (5)
		CMP fw_magic, X		; compare with string (4)
			BNE rst_nmi			; not a valid routine (2/3)
		INY					; another byte (2)
		DEX					; internal string is read backwards (2)
		BPL nmi_chkmag		; down to zero (3/2)
do_nmi:
	LDX #0				; null offset
	JSR nmi_call		; in case no 816 is used!
; *** here goes the former nmi_end routine ***
nmi_end:
	PLA					; retrieve saved vars
	_PLX
	_PLY
	STA systmp			; only this byte
	STX sysptr+1
	STY sysptr
	_PLY				; restore regular registers (3x5)
	_PLX
	PLA
	RTI					; resume normal execution and register size, hopefully

nmi_call:
	_JMPX(fw_nmi)		; call actual code, ending in RTS (6)

fw_magic:
	.asc	"*jNU"		; reversed magic string

; *** execute standard NMI handler ***
rst_nmi:
	LDA #>nmi_end-1		; prepare return address
	PHA
	LDA #<nmi_end-1		; now LSB (safer than PEA)
	PHA
; ...will continue thru subsequent standard handler, its RTS will get back to ISR exit

; *** default code for NMI handler, if not installed or invalid, should end in RTS ***
std_nmi:
#include "firmware/modules/std_nmi.s"


; ********************************
; *** administrative functions ***
; ********************************

; *** generic functions ***

; GESTALT, get system info, API TBD
; zpar -> available pages of (kernel) SRAM
; zpar+2.W -> available BANKS of RAM
; zpar2.B -> speedcode
; zpar2+2.B -> CPU type
; zpar3.W/L -> points to a string with machine name
; *** WILL change ABI/API ***REVISE
fw_gestalt:
	LDA himem		; get pages of kernel SRAM (4)
	STA zpar		; store output (3)
	_STZX zpar+2	; no bankswitched RAM yet (4)
	_STZX zpar3+2	; same for string address (4)
	LDA #>fw_mname	; get string pointer
	LDY #<fw_mname
	STA zpar3+1		; put it outside
	STY zpar3
	LDA #SPEED_CODE	; speed code as determined in options.h (2+3)
	STA zpar2
	LDA fw_cpu		; get kind of CPU (previoulsy stored or determined) (4+3)
	STA zpar2+2
	_DR_OK			; done (8)

; SET_ISR, set IRQ vector
; kerntab <- address of ISR
fw_s_isr:
	_ENTER_CS				; disable interrupts and save sizes! (5)
	LDY kerntab				; get pointer
	LDA kerntab+1
	STY fw_isr				; store for firmware
	STA fw_isr+1
	_EXIT_CS				; restore interrupts if needed
	_DR_OK					; done (8)

; SET_NMI, set NMI vector
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
fw_sn_ok:
		INY						; try next one
		DEX
		BPL fw_sn_chk			; until all done
#endif
; transfer supplied pointer to firmware vector
	LDY kerntab				; get LSB (3)
	LDA kerntab+1			; get MSB (3)
	STY fw_nmi				; store for firmware (4+4)
	STA fw_nmi+1
	_DR_OK					; done (8)

; SET_BRK, set BRK handler
fw_s_brk:
; ****** TO BE DONE ******

; JIFFY, set jiffy IRQ frequency
fw_jiffy:
; ****** TO BE DONE ******

; IRQ_SOURCE, set jiffy IRQ frequency
fw_i_src:
; ****** TO BE DONE ******
	_DR_ERR(UNAVAIL)	; not yet implemented

; *** hardware specific ***

; POWEROFF, poweroff etc
; Y <- mode (0 = suspend, 2 = warmboot, 4 = coldboot, 6 = poweroff)
; C -> not implemented
fw_power:
	TYA					; get subfunction offset
	TAX					; use as index
	_JMPX(fwp_func)		; select from jump table

fwp_off:
	_PANIC("{OFF}")		; just in case is handled
	.byt	$42			; WDM will show up on BBC emulator... and cold boot!

fwp_cold:
	JMP ($FFFC)			; call 6502 vector, not really needed here but...

fwp_susp:
	_DR_OK				; just continue execution

; FREQ_GEN, frequency generator hardware interface, TBD
fw_fgen:
; ****** TO BE DONE ******
	_DR_ERR(UNAVAIL)	; not yet implemented

; *** for higher-specced systems ***

#ifndef	LOWRAM
; INSTALL, copy jump table
; kerntab <- address of supplied jump table
fw_install:
	_ENTER_CS			; disable interrupts! (5)
	LDY #0				; reset index (2)
fwi_loop:
		LDA (kerntab), Y	; get word from table as supplied (5)
		STA fw_table, Y		; copy where the firmware expects it (4)
		INY					; advance one byte
		BNE fwi_loop		; until whole page is done (3/2)
	_EXIT_CS			; restore interrupts if needed, will restore size too (4)
	_DR_OK				; all done (8)

; PATCH, patch single function
; kerntab <- address of code
; Y <- function to be patched
fw_patch:
#ifdef		LOWRAM
	_DR_ERR(UNAVAIL)		; no way to patch on 128-byte systems
#else
	_ENTER_CS				; disable interrupts and save sizes! (5)
	LDA kerntab				; get full pointer
	LDX kerntab+1
	STA fw_table, Y			; store into firmware
	TXA
	STA fw_table+1, Y
	_EXIT_CS				; restore interrupts and sizes (4)
	_DR_OK					; done (8)
#endif

; CONTEXT, zeropage & stack bankswitching
fw_ctx:
; ****** TO BE DONE ******
	_DR_ERR(UNAVAIL)	; not yet implemented

#endif

; *** end of temporary labels ***

; sub-function jump table (eeeek)
fwp_func:
	.word	fwp_susp	; suspend	+FW_STAT
	.word	kernel		; shouldn't use this, just in case
	.word	fwp_cold	; coldboot	+FW_COLD
	.word	fwp_off		; poweroff	+FW_OFF

; *********************************
; *** administrative jump table *** changing
; *********************************
fw_admin:
; generic functions, esp. interrupt related
	.word	fw_gestalt	; GESTALT get system info (renumbered)
	.word	fw_s_isr	; SET_ISR set IRQ vector
	.word	fw_s_nmi	; SET_NMI set (magic preceded) NMI routine
	.word	fw_s_brk	; *** SET_BRK set debugger, new 20170517
	.word	fw_jiffy	; *** JIFFY set jiffy IRQ speed, ** TBD **
	.word	fw_i_src	; *** IRQ_SOURCE get interrupt source in X for total ISR independence

; pretty hardware specific
	.word	fw_power	; POWEROFF power-off, suspend or cold boot
	.word	fw_fgen		; *** FREQ_GEN frequency generator hardware interface, TBD

; not for LOWRAM systems
	.word	fw_install	; INSTALL copy jump table
	.word	fw_patch	; PATCH patch single function (renumbered)
	.word	fw_ctx		; *** CONTEXT context bankswitching

; *** minimOS BRK handler *** might go elsewhere
brk_hndl:		; label from vector list
; much like the ISR start
	PHA						; save registers
	_PHX
	_PHY
;	JSR brk_handler			; standard label from IRQ
	JSR brk_call			; indirect call
	_PLY					; restore status and return
	_PLX
	PLA
	RTI
brk_call:
	JMP (fw_brk)			; vectored handler

; if case of no headers, at least keep machine name somewhere
#ifdef	NOHEAD
fw_splash:
	.asc	"0.9.6 firmware for "
fw_mname:
	.asc	MACHINE_NAME, 0
#endif

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	kernel_call-*, $FF
#endif

; *** minimOS·65 function call interface ($FFC0) ***
* = kernel_call
cop_hndl:		; label from vector list
	_JMPX(fw_table)		; the old fashioned way

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	admin_call-*, $FF
#endif

; *** administrative meta-kernel call primitive ($FFD0) ***
* = admin_call
	_JMPX(fw_admin)		; takes 5 clocks


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
	.word	cop_hndl	; native COP		@ $FFE4
	.word	brk_hndl	; native BRK		@ $FFE6, call standard label from IRQ
	.word	nmi			; native ABORT		@ $FFE8, not yet supported
	.word	nmi			; native NMI		@ $FFEA, unified this far
	.word	$FFFF		; reserved			@ $FFEC
	.word	irq			; native IRQ		@ $FFEE, unified this far
	.word	$FFFF		; reserved			@ $FFF0
	.word	$FFFF		; reserved			@ $FFF2
	.word	nmi			; emulated COP		@ $FFF4
	.word	$3412		; reserved			@ $FFF6
	.word	nmi			; emulated ABORT 	@ $FFF8
; *** 65(C)02 ROM vectors ***
* = $FFFA				; just in case
	.word	nmi			; (emulated) NMI	@ $FFFA
	.word	reset		; (emulated) RST	@ $FFFC
	.word	irq			; (emulated) IRQ	@ $FFFE
