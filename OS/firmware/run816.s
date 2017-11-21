; firmware for minimOS on run65816 BBC simulator
; v0.9.6b1
; (c)2017 Carlos J. Santisteban
; last modified 20171121-1034

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
	.asc	"0.9.6 firmware for "
; at least, put machine name as needed by firmware!
fw_mname:
	.asc	MACHINE_NAME, 0

; advance to end of header
	.dsb	fw_start + $F8 - *, $FF	; for ready-to-blow ROM, advance to time/date field

; *** date & time in MS-DOS format at byte 248 ($F8) ***
	.word	$7000	; time, 13.00
	.word	$4AC2	; date, 2017/6/2

fwSize	=	$10000 - fw_start - 256	; compute size NOT including header!

; filesize in top 32 bits NOT including header, new 20161216
	.word	fwSize			; filesize
	.word	0				; 64K space does not use upper 16-bit
; *** end of standard header ***
#endif

; **************************
; **************************
; ****** cold restart ******
; **************************
; **************************
; basic init
reset:
	SEI					; cold boot (2) not needed for simulator?
	CLD					; just in case, a must for NMOS (2)
; reset the 65816 to emulation mode, just in case
	SEC					; would set back emulation mode on C816
	XCE					; XCE on 816, NOP on C02, but illegal 'ISC $0005, Y' on NMOS!
	ORA $0				; the above would increment some random address in zeropage (NMOS) but this one is inocuous on all CMOS
	LDX #SPTR			; initial stack pointer, machine-dependent, must be done in emulation for '816 (2)
	TXS					; initialise stack (2)

; ***************************
; *** specific 65816 code ***
; ***************************

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
		LDA #'?'			; *** some debug code for run65816, just in case ***
		JSR $c0c2			; *** direct print via run65816 ********************
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

; *********************************
; *** optional firmware modules ***
; *********************************
post:
; might check ROM integrity here
;#include "firmware/modules/romcheck.s"

; SRAM test
;#include "firmware/modules/ramtest.s"

; ***********************************
; *** firmware parameter settings ***
; ***********************************

; *** set default CPU type ***
	LDA #'V'			; 65816 only (2)
	STA fw_cpu			; store variable (4)
; as this is the only valid CPU for this firmware, no further checking necessary

; *** preset kernel start address (standard label from ROM file, unless downloaded) ***
	.al: REP #$20		; ** 16-bit memory ** (3)
	LDA #kernel			; get full address (3)
	STA fw_warm			; store in sysvars (5)

; *** preset jiffy irq frequency ***
; this should be done by installed kernel, but at least set to zero for 0.5.x compatibility!
	STZ irq_freq		; store null speed... IRQ not set

; *** preset default BRK & NMI handlers ***
	LDA #std_nmi		; default like the standard NMI
	STA fw_brk			; store default handler
; since the NMI handler is validated, no need to install a default

; *** reset jiffy count ***
	LDX #4				; max WORD offset in uptime seconds AND ticks, assume contiguous (2)
res_sec:
		STZ ticks, X		; reset word (5)
		DEX					; next word backwards (2+2)
		DEX
		BPL res_sec			; zero is included

; ********************************
; *** hardware interrupt setup ***
; ********************************
;	LDX #$C0			; enable T1 (jiffy) interrupt only, this in 8-bit (2+4)
;	STX VIA_J + IER

	.as: .xs: SEP #$30	; *** all back to 8-bit, just in case, might be removed if no remote boot is used (3) ***

; **********************************
; *** direct print splash string ***
; **********************************
	LDX #0				; reset index
fws_loop:
		LDA fw_splash, X	; get char
			BEQ fws_cr			; no more to print
; as direct print uses no regs, nothing to save and reload
		JSR $c0c2			; *** EhBASIC output ***
		INX					; next char
		BRA fws_loop
fws_cr:
	LDA #LF				; trailing CR, needed by console!
	JSR $c0c2			; direct print

; *** could download a kernel here, updating fw_warm accordingly ***

; ************************
; *** start the kernel ***
; ************************
start_kernel:
	SEC					; emulation mode for a moment (2+2)
	XCE
	JMP (fw_warm)		; any 16-bit kernel should get back into NATIVE mode (5)

; ********************************
; ********************************
; ****** interrupt handlers ******
; ********************************
; ********************************

; **********************************************
; *** vectored NMI handler with magic number ***
; **********************************************
nmi:
; save registers AND system pointers
	.al: .xl: REP #$30	; ** whole register size, just in case **
	PHA					; save registers (3x4)
	PHX
	PHY
	PHB					; eeeeeeeeeeeeeeeeeeeeeeeeek
; should I save and reset DP???
; make NMI reentrant, new 65816 specific code
; assume all registers in 16-bit size
	LDY sysptr			; get original word (4+4)
	LDA systmp			; this will get sys_sp also!
	PHA					; store them in similar order (4+4)
	PHY
; switch DBR to bank zero!!!!
	PHK					; push a zero...
	PLB					; ...as current data bank!
; prepare for next routine while memory is still 16-bit!
	LDA fw_nmi			; copy vector to zeropage (5+4)
	STA sysptr
	.as: SEP #$20		; *** back to 8-bit size all the way! ***
#ifdef	SAFE
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
#endif
	LDX #0				; null offset (2)
	JSR (fw_nmi, X)		; call actual code, ending in RTS (8) enters in 8-bit sizes
; *** here goes the former nmi_end routine ***
nmi_end:
	.al: .xl: REP #$30	; ** whole register size to restore **
	PLY					; retrieve saved vars (5+5)
	PLA
	STY sysptr			; restore values (4+4)
	STA systmp			; I suppose is safe to alter sys_sp too
; if DP was reset, time to restore it
	PLB					; eeeeeeeeeeeeeeek
	PLY					; restore regular registers (3x5)
	PLX
	PLA
	RTI					; resume normal execution and register sizes, hopefully

; *** execute standard NMI handler ***
rst_nmi:
	PEA nmi_end-1		; prepare return address
; ...will continue thru subsequent standard handler, its RTS will get back to ISR exit

; *** default code for NMI handler, 8-bit sizes, if not installed or invalid, should end in RTS ***
std_nmi:
#include "firmware/modules/std_nmi.s"


; ********************************
; *** administrative functions ***
; ********************************

; *** generic functions ***

; GESTALT, get system info, API TBR
;		OUTPUT
; cpu_ll	= CPU type
; c_speed	= speed code
; str_pt	= points to a string with machine name
; ex_pt		= points to a map of default memory conf ???
; k_ram		= available pages of (kernel) SRAM
; b_ram		= available BANKS of "high" RAM

fw_gestalt:
	PHP					; save sizes!
;	PHB					; in case is called outside bank 0?
;	PHK					; use bank zero...
;	PLB					; ...for data
	.al: REP #$20		; *** 16-bit memory ***
	.xs: SEP #$10		; *** 8-bit indexes ***
	LDY fw_cpu			; get kind of CPU (previoulsy stored or determined) (4+3)
	LDX #SPEED_CODE		; speed code as determined in options.h (2+3)
	STY cpu_ll			; set outputs
	STX c_speed
	LDY himem			; get pages of kernel SRAM (4) ????
	STY k_ram			; store output (3)
	STZ b_ram			; no "high" RAM??? (4) *** TO DO ***
	LDA #fw_mname		; get string pointer
	STA str_pt			; put it outside
	LDA #fw_map			; pointer to standard map TBD ????
	STA ex_pt			; set output
; some separate map for high RAM???
;	PLB					; restore data bank?
	_DR_OK				; done

; SET_ISR, set IRQ vector
;		INPUT
; kerntab	= address of ISR (will take care of all necessary registers)

fw_s_isr:
	_ENTER_CS			; disable interrupts and save sizes! (5)
	.al: REP #$20		; ** 16-bit memory ** (3)
	.xs: SEP #$20		; ** 8-bit indexes, no ABI to set that! **
	LDA kerntab			; get pointer (4)
	STA @fw_isr			; store for firmware, note long addressing (6)
	_EXIT_CS			; restore interrupts if needed, sizes too (4)
	_DR_OK				; done (8)

; SET_NMI, set NMI vector
;		INPUT
; kerntab	= address of NMI code (including magic string, ends in RTS)

; might check whether the pointed code starts with the magic string
; no need to disable interrupts as a partially set pointer would be rejected...
; ...unless SAFE mode is NOT selected (will not check upon NMI)

fw_s_nmi:
	_ENTER_CS			; save sizes, just in case CS is needed...
	.as: .xs: SEP #$30	; *** standard sizes ***
#ifdef	SAFE
	LDX #3				; offset to reversed magic string
	LDY #0				; reset supplied pointer
fw_sn_chk:
		LDA (kerntab), Y	; get pointed handler string char
		CMP @fw_magic, X	; compare against reversed string, note long addressing
		BEQ fw_sn_ok		; no problem this far...
; ***** due to error handling cannot use DR_ERR macro *****
			LDY #CORRUPT		; error code (8-bit size)
			PLP					; *** restore sizes eeeeeeeeek ***
			SEC					; time to flag error!
			RTS
fw_sn_ok:
		INY					; try next one
		DEX
		BPL fw_sn_chk		; until all done
#endif
; transfer supplied pointer to firmware vector
	.al: REP #$20		; *** 16-bit memory ***
	LDA kerntab			; get pointer (4)
	STA @fw_nmi			; store for firmware, note long addressing (6)
	_EXIT_CS			; restore sizes!
	_DR_OK				; done (8)

	.as: .xs			; just in case...

; SET_BRK, set BRK handler
;		INPUT
; kerntab	= address of BRK routine (ending in RTS)

fw_s_brk:
	_ENTER_CS			; disable interrupts and save sizes! (5)
	.al: REP #$20		; ** 16-bit memory ** (3)
	LDA kerntab			; get pointer (4)
	STA @fw_brk			; store for firmware, note long addressing (6)
	_EXIT_CS			; restore interrupts if needed, sizes too (4)
	_DR_OK				; done

	.as: .xs			; just in case...

; JIFFY, set jiffy IRQ frequency
;		INPUT
; irq_hz	= frequency in Hz (0 means no change)
;		OUTPUT
; irq_hz	= actually set frequency (in case of error or no change)
; C			= could not set (not here)

fw_jiffy:
; this is generic
; if could not change, then just set return parameter and C
	_ENTER_CS			; disable interrupts and save sizes! (5)
	.al: REP #$20		; ** 16-bit memory ** (3)
	LDA irq_hz			; get input value
	BNE fj_set			; not just checking
		LDA @irq_freq		; get current frequency
		STA irq_hz			; set return values
fj_end:
		_EXIT_CS			; eeeeeeeeek
		_DR_OK
fj_set:
	STA @irq_freq		; store in sysvars
	BRA fj_end			; all done, no need to update as will be OK

	.as: .xs			; just in case...

; IRQ_SOURCE, investigate source of interrupt
;		OUTPUT
; *** X	= 0 (periodic), 2 (async IRQ @ 65xx) ***
; *** notice NON-standard output register for faster indexed jump! ***
; other even values hardware dependent
; MUST be called on 8-bit sizes!

fw_i_src:
	BIT VIA_J+IFR		; much better than LDA + ASL + BPL! (4)
	BVS fis_per			; from T1 (3/2)
		LDX #2				; standard async otherwise (2)
		RTS					; no error handling for speed! (6)
fis_per:
	LDA VIA+T1CL		; acknowledge periodic interrupt!!! (4)
	LDX #0				; standard value for jiffy IRQ (2)
	_DR_OK

; *** hardware specific ***

; POWEROFF, poweroff etc
; Y <- mode (0 = suspend, 2 = warmboot, 4 = coldboot, 6 = poweroff)
; C -> not implemented

fw_power:
	PHP					; save sizes eeeeeeeeek
	.as: .xs: SEP #$30	; *** all 8-bit ***
	TYX					; get subfunction offset as index
	JMP (fwp_func, X)	; select from jump table

fwp_off:
	_PANIC("{OFF}")		; just in case is handled
	.byt	$42			; WDM will show up on BBC emulator... and cold boot!

fwp_susp:
	PLP					; restore sizes
	_DR_OK				; just continue execution

; FREQ_GEN, frequency generator hardware interface, TBD
fw_fgen:
; ****** TO BE DONE ******
	_DR_ERR(UNAVAIL)	; not yet implemented

; *** for higher-specced systems ***

; INSTALL, copy jump table
;		INPUT
; kerntab	= address of supplied pointer table

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
		CPY #LAST_API		; EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEK
		BCC fwi_loop		; until whole TABLE is done (3/2)***might corrupt fw vars!
	_EXIT_CS			; restore interrupts if needed, will restore size too (4)
	_DR_OK				; all done (8)

; PATCH, patch single function
; kerntab <- address of code
; Y <- function to be patched

fw_patch:
; worth going 16-bit as status was saved, 10b/21c , was 13b/23c
	_ENTER_CS				; disable interrupts and save sizes! (5)
	.al: REP #$20			; ** 16-bit memory ** (3)
	.xs: SEP #$20			; ** 8-bit indexes, no ABI to set that! **
	LDA kerntab				; get full pointer (4)
	TYX						; no Y-indexed long addressing! (2)
	STA @fw_table, X		; store into firmware, note long addressing (6)
	_EXIT_CS				; restore interrupts and sizes (4)
	_DR_OK					; done (8)

	.as: .xs				; just in case...

; CONTEXT, zeropage & stack bankswitching
fw_ctx:
; ****** TO BE DONE ******
	_DR_ERR(UNAVAIL)	; not yet implemented


; ****************************
; *** some firmware tables ***
; ****************************

; magic string for NMI handler
fw_magic:
	.asc	"*jNU"		; REVERSED magic string

; sub-function jump table (eeeek)
fwp_func:
	.word	fwp_susp	; suspend	+FW_STAT
	.word	kernel		; should not use this, just in case
	.word	reset		; coldboot	+FW_COLD
	.word	fwp_off		; poweroff	+FW_OFF

fw_map:
; *** do not know what to do here ***

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

; these already OK for 65816!
; *** minimOS·16 BRK handler *** might go elsewhere
brk_hndl:		; label from vector list
; much like the ISR start
	.al: .xl: REP #$30		; status already saved, but save register contents in full (3)
	PHA						; save registers (3x4)
	PHX
	PHY
	PHB						; eeeeeeeeeek (3)
; must use some new indirect jump, as set by new SET_BRK
;	JSR brk_handler			; standard label from IRQ
; ************************************ CONTINUE HERE ***************************
	.al: .xl: REP #$30		; just in case (3)
	PLB						; eeeeeeeeeeeek (4)
	PLY						; restore status and return (3x5)
	PLX
	PLA
	RTI

.as:.xs:					; otherwise might prevent code after ROM!

; if case of no headers, at least keep machine name somewhere
#ifdef	NOHEAD
fw_splash:
	.asc	"0.9.6 firmware for "
fw_mname:
	.asc	MACHINE_NAME, 0
#endif

; *** minimOS·16 kernel call interface (COP) ***
cop_hndl:		; label from vector list
	JMP (fw_table, X)		; the old fashioned way

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	kernel_call-*, $FF
#endif

; *** minimOS-65 function call WRAPPER ($FFC0) ***
* = kernel_call
	CLC					; pre-clear carry
	COP #$FF			; wrapper on 816 firmware!
	RTS					; return to caller
; *** no longer a wrapper outside bank zero for minimOS·65 ***

; ****** idea for 65816 admin-call interface from apps! ******
; ** could be at $00FFC8 **
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
	NOP					; same address as 6502
panic_loop:
	BRA panic_loop		; OK as this is 65816 only
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
