; more-or-less generic firmware for minimOS·16
; v0.5.1a1
; (c)2015-2016 Carlos J. Santisteban
; last modified 20161010-1106

#define		FIRMWARE	_FIRMWARE

#include "usual.h"

	.align	256

; *** first some ROM identification *** new 20150612
fw_start:
	.asc 0, "mV", 13					; standard system file wrapper, new 20161010, experimental type
	.asc "boot", 0						; standard filename
	.asc "65816 0.5.1a1 firmware for "	; machine description as comment
fw_mname:
	.asc	MACHINE_NAME, 0

	.dsb	fw_start + $100 - *, $FF	; generate padding including end of linked list

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
		JMP lock			; cannot handle BRK, alas
fw_cpuOK:
#endif

; it can be assumed 65816 from this point on

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
#include "firmware/modules/beep16.s"	; typical 816 standard beep

; SRAM test
#include "firmware/modules/ramtest.s"

; *** VIA initialisation (and stop beeping) ***
	LDA #%11000010		; CB2 low, Cx1 negative edge, CA2 indep. neg. (2+4)
	STA VIA_J + PCR
	LDA #%01000000		; T1 cont, no PB7, no SR, no latch (so far) (2+4)
	STA VIA_J + ACR
; *** set default CPU type ***
	LDA #'V'			; 65816 only (2)
	STA fw_cpu			; store variable (4)
; *** preset kernel start address (standard label from ROM file) ***
	.al: REP $20		; ** 16-bit memory ** (3)
	LDA #kernel			; get full address (3)
	STA fw_warm			; store in sysvars (5)

; *** maybe this is the place for final interrupt setup *** 20150605
; first of all, compute Timer 1 division factor, out from options.h 20160407
T1_DIV = PHI2/IRQ_FREQ-2

	LDA	#T1_DIV			; set IRQ frequency divisor LSB, still in 16-bit (3)
	STA VIA_J + T1CL	; put value into latches (will start counting!) (5)
	LDX #4				; max WORD offset in uptime seconds AND ticks, assume contiguous (2)
res_sec:
		STZ ticks, X		; reset word (5)
		DEX					; next word backwards (2+2)
		DEX
		BPL res_sec			; zero is included
	LDX #$C0			; enable T1 (jiffy) interrupt only, this in 8-bit (2+4)
	STX VIA_J + IER

	.as: .xs: SEP $30	; all back to 8-bit, just in case, might be removed if no remote boot is used (3)

; *** optional network booting ***
; might modify the contents of fw_warm
remote_boot:
;#include "firmware/modules/netboot.s"

; *** firmware ends, jump into the kernel ***
start_kernel:
	SEC					; emulation mode for a moment (2+2)
	XCE
	JMP (fw_warm)		; (5)

; *** vectored NMI handler with magic number ***
nmi:
; save registers AND system pointers
	.al: .xl: REP $30	; ** whole register size, just in case **
	PHA					; save registers (3x4)
	PHX
	PHY
; make NMI reentrant, new 65816 specific code
; assume all registers in 16-bit size, this is 6+2 bytes, 16+2 clocks! (was 10b, 38c)
	LDA sysptr			; get original word (4+4)
	LDY systmp			; this will get sys_sp also!
	PHA					; store them in similar order (4+4)
	PHY
; prepare for next routine while regs are still 16-bit!
	LDA fw_nmi			; copy vector to zeropage (5+4)
	STA sysptr
	.as: .xs: SEP $30	; ** back to 8-bit size! **
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
	JSR go_nmi			; call actual code, ending in RTS (6)
; *** here goes the former nmi_end routine ***
nmi_end:
	.al: .xl: REP $30	; ** whole register size to restore **
	PLY					; retrieve saved vars (5+5)
	PLA
	STY systmp			; I suppose is safe to alter sys_sp too (4+4)
	STA sysptr
	PLY					; restore regular registers (3x5)
	PLX
	PLA
	RTI					; resume normal execution and register size, hopefully

; *** execute installed NMI handler ***
go_nmi:
	JMP (fw_nmi)		; jump to code (and inocuous header) (5)

; *** execute standard NMI handler ***
rst_nmi:
	JSR std_nmi			; call standard handler
	BRA nmi_end			; and finish as usual

fw_magic:
	.asc	"*jNU"		; reversed magic string

; *** default code for NMI handler, if not installed or invalid, should end in RTS ***
std_nmi:
#include "firmware/modules/std_nmi.s"


; *** administrative functions *** CONTINUE REVAMP HERE ***** CONTINUE REVAMP HERE *****
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
	.dsb	panic-*, $FF
#endif

; *** panic routine, locks at very obvious address ($FFE1-$FFE2) ***
* = panic
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
