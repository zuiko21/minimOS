; firmware for minimOS on run65816 BBC simulator
; v0.9b7
; (c)2017 Carlos J. Santisteban
; last modified 20170403-0925

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
	.asc	"0.9b5 firmware for "
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
	.word	$63C0	; time, 12.30
	.word	$4A70	; date, 2017/3/16

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
; ***** do I really need to (re)set DP and DBR??? *****
	PHK					; stacks a zero
	PLB					; reset this value
	PHK					; stack two zeroes
	PHK
	PLD					; simpler than TCD et al

; *** optional firmware modules ***
post:

; might check ROM integrity here
;#include "firmware/modules/romcheck.s"

; SRAM test
;#include "firmware/modules/ramtest.s"

; *** set default CPU type ***
	LDA #'V'			; 65816 only (2)
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
	SEC					; emulation mode for a moment (2+2)
	XCE
	JMP (fw_warm)		; (5)

; *** vectored NMI handler with magic number ***
nmi:
; save registers AND system pointers
	.al: .xl: REP #$30	; ** whole register size, just in case **
	PHA					; save registers (3x4)
	PHX
	PHY
	PHB					; eeeeeeeeeeeeeeeeeeeeeeeeek
; make NMI reentrant, new 65816 specific code
; assume all registers in 16-bit size, this is 6+2 bytes, 16+2 clocks! (was 10b, 38c)
	LDY sysptr			; get original word (4+4)
	LDA systmp			; this will get sys_sp also!
	PHY					; store them in similar order (4+4)
	PHA
; switch DBR to bank zero!!!!
	.xs: SEP #$10		; ** 8-bit indexes ** as I need to push a single byte
	LDX #0
	PHX					; push a zero...
	PLB					; ...as current data bank!
; prepare for next routine while memory is still 16-bit!
	LDA fw_nmi			; copy vector to zeropage (5+4)
	STA sysptr
	.as: SEP #$20		; ** back to 8-bit size all the way! **
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
	.al: .xl: REP #$30	; ** whole register size to restore **
	PLA					; retrieve saved vars (5+5)
	PLY
	STA systmp			; I suppose is safe to alter sys_sp too (4+4)
	STY sysptr
	PLB					; eeeeeeeeeeeeeeek
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
; * 8-bit savvy *

fw_install:
	_ENTER_CS			; disable interrupts! (5)
	.al: REP #$20		; ** 16-bit memory ** (3)
	.xs: SEP #$10		; ** just in case, 8-bit indexes ** (3)
	LDY #0				; reset index (2)
fwi_loop:
		LDA (kerntab), Y	; get word from table as supplied (6)
		STA @fw_table, Y	; copy where the firmware expects it (6) ***faster if switching DBR but heavier
		INY					; advance two bytes (2+2)
		INY
		BNE fwi_loop		; until whole page is done (3/2)
	_EXIT_CS			; restore interrupts if needed, will restore size too (4)
	_DR_OK				; all done (8)


; A2, set IRQ vector
; kerntab <- address of ISR
fw_s_isr:
	_ENTER_CS				; disable interrupts and save sizes! (5)
	.al: REP #$20			; ** 16-bit memory ** (3)
	.xs: SEP #$20			; ** 8-bit indexes, no ABI to set that! **
	LDA kerntab				; get pointer (4)
	STA @fw_isr				; store for firmware, note long addressing (6)
	_EXIT_CS				; restore interrupts if needed, sizes too (4)
	_DR_OK					; done (8)


; A4, set NMI vector
; kerntab <- address of NMI code (including magic string)
; might check whether the pointed code starts with the magic string
; no need to disable interrupts as a partially set pointer would be rejected
fw_s_nmi:
	PHP						; save sizes, just in case, CS not needed
	.as: .xs: SEP #$30		; *** standard size ***
#ifdef	SAFE
	LDX #3					; offset to reversed magic string
	LDY #0					; reset supplied pointer
fw_sn_chk:
		LDA (kerntab), Y		; get pointed handler string char
		CMP @fw_magic, X		; compare against reversed string, note long addressing
		BEQ fw_sn_ok			; no problem this far...
; ***** due to error handling cannot use DR_ERR macro *****
			LDY #CORRUPT			; error code (8-bit size)
			PLP						; *** restore sizes eeeeeeeeek ***
			SEC						; time to flag error!
			RTS
fw_sn_ok:
		.as: .xs				; just in case...
		INY						; try next one
		DEX
		BPL fw_sn_chk			; until all done
#endif
; transfer supplied pointer to firmware vector
; not worth going 16-bit as will by 9b/19c instead of 12b/16c
	LDY kerntab				; get LSB (3)
	LDA kerntab+1			; get MSB (3)
	STY @fw_nmi				; store for firmware, note long addressing (5+5)
	STA @fw_nmi+1
	PLP						; restore sizes!
	_DR_OK					; done (8)

; A6, patch single function
; kerntab <- address of code
; Y <- function to be patched
fw_patch:
#ifdef		LOWRAM
	_DR_ERR(UNAVAIL)		; no way to patch on 128-byte systems
#else
; worth going 16-bit as status was saved, 10b/21c , was 13b/23c
	_ENTER_CS				; disable interrupts and save sizes! (5)
	.al: REP #$20			; ** 16-bit memory ** (3)
	.xs: SEP #$20			; ** 8-bit indexes, no ABI to set that! **
	LDA kerntab				; get full pointer (4)
	TYX						; no Y-indexed long addressing! (2)
	STA @fw_table, X		; store into firmware, note long addressing (6)
	_EXIT_CS				; restore interrupts and sizes (4)
	_DR_OK					; done (8)
#endif


; A8, get system info, API TBD
; zpar -> available pages of (kernel) SRAM
; zpar+2.W -> available BANKS of RAM
; zpar2.B -> speedcode
; zpar2+2.B -> CPU type
; zpar3.W/L -> points to a string with machine name
; *** WILL change ABI/API ***
fw_gestalt:
	PHP				; keep sizes (3)
	REP #$20		; ** 16-bit memory **
	SEP #$10		; ** 8-bit indexes **
	LDX himem		; get pages of kernel SRAM (4)
	STX zpar		; store output (3)
	STZ zpar+2		; no bankswitched RAM yet (4) 16-bit
	STZ zpar3+2		; same for string address (4)
; must revise ABI as per new 24-bit pointers!!!
	LDA #fw_mname	; get string pointer (3)
	STA zpar3		; put it outside (4)
	LDX #SPEED_CODE	; speed code as determined in options.h (2+3)
	STX zpar2
	LDX fw_cpu		; get kind of CPU (previoulsy stored or determined) (4+3)
	STX zpar2+2
	PLP				; restore sizes (4)
	_DR_OK			; done (8)

	.as				; likely to be needed as previously set

; A10, poweroff etc
; Y <- mode (0 = suspend, 2 = warmboot, 4 = coldboot, 6 = poweroff)
; C -> not implemented
fw_power:
	TYX					; get subfunction offset as index
	JMP(fwp_func, X)	; select from jump table

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
	.word	kernel		; should not use this, just in case
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
	.al: .xl: REP #$30		; status already saved, but save register contents in full (3)
	PHA						; save registers (3x4)
	PHX
	PHY
	PHB						; eeeeeeeeeek (3)
;	JSR brk_handler			; standard label from IRQ
	.al: .xl: REP #$30		; just in case (3)
	PLB						; eeeeeeeeeeeek (4)
	PLY						; restore status and return (3x5)
	PLX
	PLA
	RTI

.as:.xs:					; otherwise might prevent code after ROM!

; *** minimOS·16 kernel call interface (COP) ***
cop_hndl:		; label from vector list
	JMP (fw_table, X)		; the old fashioned way

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	kernel_call-*, $FF
#endif

; *** minimOS-65 function call WRAPPER ($FFC0) ***
* = kernel_call
	CLC			; pre-clear carry
	COP #$FF	; wrapper on 816 firmware!
	RTS			; return to caller
; ****** sample for wrapper outside bank zero for minimOS-65 ******
; ** should be at $xxFFC4 **
;	JMP @sig_kill	; program end arrives here via RTS

; ****** idea for 65816 admin-call interface from apps! ******
; ** should be at $00FFC8 **
;	JSR admin_call		; get into firmware interface (returns via RTS)
;	RTL					; get back into original task (called via JSL $00FFC8)
; ****** likely to end at $00FFCD ******

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
