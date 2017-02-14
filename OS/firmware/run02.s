; firmware for minimOS on run65816 BBC simulator
; 65c02 version for testing 8-bit kernels
; v0.9b1
; (c)2017 Carlos J. Santisteban
; last modified 20170214-1908

#define		FIRMWARE	_FIRMWARE

; in case of standalone assembly
#include "usual.h"

; *** first some ROM identification *** new 20150612
; this is expected to be loaded at an aligned address anyway
#ifndef	NOHEAD
fw_start:
	.asc	0, "mV****", CR			; standard system file wrapper, new 20160309
	.asc	"boot", 0				; mandatory filename for firmware
fw_splash:
	.asc	"0.9b1 firmware for "
#else
fw_splash:
#endif

; at least, put machine name as needed by firmware!
; this cannot be waived by the NOHEAD option
fw_mname:
	.asc	MACHINE_NAME, 0

#ifndef	NOHEAD
; advance to end of header
	.dsb	fw_start + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$6000			; time, 12.00
	.word	$4A37			; date, 2017/1/23

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

; as this firmware should be 65816-only, check for its presence or nothing!
; derived from the work of David Empson, Oct. '94
#ifdef	SAFE
	SED					; decimal mode
	LDA #$99			; load highest BCD number (sets N too)
	CLC					; prepare to add
	ADC #$02			; will wrap around in Decimal mode (should clear N)
	CLD					; back to binary
		BMI cpu_bad			; NMOS, N flag not affected by decimal add
	TAY					; let us preload Y with 1 from above
	LDX #$00			; sets Z temporarily
	TYX					; TYX, 65802 instruction will clear Z, NOP on all 65C02s will not
	BNE fw_cpuOK		; Branch only on 65802/816
cpu_bad:
		LDA #'?'	; *** some debug code for run65816, just in case ***
		JSR $c0c2	; *** direct print via run65816 ********************
		JMP lock			; cannot handle BRK, alas
fw_cpuOK:
#endif

; it can be assumed 65816 from this point on
	CLC					; set NATIVE mode eeeeeeeeeeek
	XCE					; still with 8-bit registers

; *** optional firmware modules ***
post:

; might check ROM integrity here
;#include "firmware/modules/romcheck.s"

; SRAM test
;#include "firmware/modules/ramtest.s"

; *** set default CPU type ***
	LDA #'V'			; 65816 installed (2)
	STA fw_cpu			; store variable (4)
; *** preset kernel start address (standard label from ROM file) ***
	.al: REP #$20		; ** 16-bit memory ** (3)
	LDA #kernel			; get full address (3)
	STA fw_warm			; store in sysvars (5)

	LDA #IRQ_FREQ	; interrupts per second
	STA irq_freq	; store speed... 

	LDX #4				; max WORD offset in uptime seconds AND ticks, assume contiguous (2)
res_sec:
		STZ ticks, X		; reset word (5)
		DEX					; next word backwards (2+2)
		DEX
		BPL res_sec			; zero is included
;	LDX #$C0			; enable T1 (jiffy) interrupt only, this in 8-bit (2+4)
;	STX VIA_J + IER

	.as: .xs: SEP #$30	; all back to 8-bit, just in case, might be removed if no remote boot is used (3)

; ******* debug code, direct print some string *******
	LDX #0				; reset index
fws_loop:
		LDA fw_splash, X	; get char
			BEQ fws_cr			; no more to print
		PHX					; keep reg (not really needed)
		JSR $c0c2			; Eh output
		PLX
		INX					; next char
		BRA fws_loop
fws_cr:
	LDA #LF				; trailing CR, needed by console!
	JSR $c0c2			; direct print
; ******* end of debug code **************************

; *** firmware ends, jump into the kernel ***
start_kernel:
	SEC					; emulation mode, should stay (2+2)
	XCE
	JMP (fw_warm)		; (5)

; *** vectored NMI handler with magic number ***
nmi:
; save registers AND system pointers
;	.al: .xl: REP #$30	; ** whole register size, just in case **emulation
	PHA					; save registers
	PHX
	PHY
; make NMI reentrant
	LDY sysptr			; get original word 
	LDX sysptr+1
	LDA systmp			; this byte only
	PHY					; store them in similar order
	PHX
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
	JSR (fw_nmi, X)		; call actual code, ending in RTS (6)
; *** here goes the former nmi_end routine ***
nmi_end:
	PLA					; retrieve saved vars
	PLX
	PLY
	STA systmp			; only this byte
	STX sysptr+1
	STY sysptr
	PLY					; restore regular registers (3x5)
	PLX
	PLA
	RTI					; resume normal execution and register size, hopefully

fw_magic:
	.asc	"*jNU"		; reversed magic string

; *** execute standard NMI handler ***
rst_nmi:
	PEA nmi_end-1		; prepare return address
; ...will continue thru subsequent standard handler, its RTS will get back to ISR exit

; *** default code for NMI handler, if not installed or invalid, should end in RTS ***
std_nmi:
#include "firmware/modules/std_nmi.s"


; *** administrative functions ***
; A0, install jump table
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


; A2, set IRQ vector
; kerntab <- address of ISR
fw_s_isr:
	_ENTER_CS				; disable interrupts and save sizes! (5)
	LDY kerntab				; get pointer
	LDA kerntab+1
	STY fw_isr				; store for firmware
	STA fw_isr+1
	_EXIT_CS				; restore interrupts if needed
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

; A6, patch single function
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


; A8, get system info, API TBD
; zpar -> available pages of (kernel) SRAM
; zpar+2.W -> available BANKS of RAM
; zpar2.B -> speedcode
; zpar2+2.B -> CPU type
; zpar3.W/L -> points to a string with machine name
; *** WILL change ABI/API ***REVISE
fw_gestalt:
	LDA himem		; get pages of kernel SRAM (4)
	STA zpar		; store output (3)
	PHP				; keep sizes (3)
	STZ zpar+2		; no bankswitched RAM yet (4)
	STZ zpar3+2		; same for string address (4)
	LDA #fw_mname	; get string pointer (3)
	STA zpar3		; put it outside (4)
	PLP				; restore sizes (4)
	LDA #SPEED_CODE	; speed code as determined in options.h (2+3)
	STA zpar2
	LDA fw_cpu		; get kind of CPU (previoulsy stored or determined) (4+3)
	STA zpar2+2
	_DR_OK			; done (8)

; A10, poweroff etc
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

; sub-function jump table (eeeek)
fwp_func:
	.word	fwp_susp	; suspend	+FW_STAT
	.word	kernel		; shouldn't use this, just in case
	.word	fwp_cold	; coldboot	+FW_COLD
	.word	fwp_off		; poweroff	+FW_OFF

; *** administrative jump table ***
; PLEASE CHANGE ORDER ASAP
fw_admin:
	.word	fw_install
	.word	fw_s_isr
	.word	fw_s_nmi
	.word	fw_patch	; new order 20150409
	.word	fw_gestalt
	.word	fw_power

; these already OK for 65816!
; *** minimOS·16 BRK handler *** might go elsewhere
brk_hndl:		; label from vector list
; much like the ISR start
	PHA						; save registers
	PHX
	PHY
;	JSR brk_handler			; standard label from IRQ
	PLY						; restore status and return
	PLX
	PLA
	RTI

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	kernel_call-*, $FF
#endif

; *** minimOS·65 function call WRAPPER ($FFC0) ***
* = kernel_call
cop_hndl:		; label from vector list
	JMP (fw_table, X)		; the old fashioned way

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	admin_call-*, $FF
#endif

; *** administrative meta-kernel call primitive ($FFD0) ***
* = admin_call
	JMP (fw_admin, X)		; takes 5 clocks


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
