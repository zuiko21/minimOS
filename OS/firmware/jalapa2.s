; firmware for minimOS on Jalapa-II
; v0.9.6a19
; (c)2017-2018 Carlos J. Santisteban
; last modified 20180119-1045

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
	.asc	"0.9.6a19 firmware for "
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
#else
; if case of no headers, at least keep machine name somewhere
fw_splash:
	.asc	"0.9.6a19 firmware for "
fw_mname:
	.asc	MACHINE_NAME, 0
#endif

; **************************
; **************************
; ****** cold restart ******
; **************************
; **************************

	.as:.xs				; to be sure!

reset:
; *** basic init ***
#include "firmware/modules/basic_init16.s"

; ******************************
; *** minimal hardware setup ***
; ******************************

; check for VIA presence and disable all interrupts
#include "firmware/modules/viacheck_irq.s"

; *** specific 65816 code ***
; as this firmware should be 65816-only, go back to native mode!
#include "firmware/modules/816_check.s"
; it can be assumed 65816 from this point on

; *********************************
; *** optional firmware modules ***
; *********************************

; optional boot selector
;#include "firmware/modules/bootoff.s"

; might check ROM integrity here
;#include "firmware/modules/romcheck16.s"

; Jalapa is intended NOT to have ROM-in-RAM feature


; startup beep, droplet style
#include "firmware/modules/droplet.s"	; specific Jalapa sound, not sure if I will be able to run it asynchronously

; SRAM test, MUST probe for RAM size, anyway... and skip the ROM
#include "firmware/modules/memsiz.s"

; ********************************
; *** hardware interrupt setup ***
; ********************************

; VIA initialisation (and stop beeping)
#include "firmware/modules/via_init.s"

; ***********************************
; *** firmware parameter settings ***
; ***********************************

; *** set default CPU type *** (not worth a separate file?)
	LDA #'V'			; 65816 only (2)
	STA fw_cpu			; store variable (4)

; as this is the only valid CPU for this firmware, no further checking necessary

; perhaps could wait until here to look for an actual 65816...

; *** continue parameter setting, worth switching to 16-bit memory while setting pointers ***
	.al: REP #$20

; preset kernel start address
#include "firmware/modules/kern_addr16.s"

; preset default BRK handler
#include "firmware/modules/brk_addr16.s"

; no need to set NMI as it will be validated


; preset jiffy irq frequency
#include "firmware/modules/jiffy_hz16.s"

; reset jiffy count
#include "firmware/modules/jiffy_rst16.s"

; reset last installed kernel (new)
#include "firmware/modules/rst_lastk16.s"

; *** back to 8-bit memory ***
	.as: SEP #$20

; *** optional network booting ***
; might modify the contents of fw_warm
;#include "firmware/modules/netboot.s"

; *** NO direct print splash string ***

; ************************
; *** start the kernel ***
; ************************
start_kernel:
#include "firmware/modules/start16.s"

; ********************************
; ********************************
; ****** interrupt handlers ******
; ********************************
; ********************************

; **********************************************
; *** vectored NMI handler with magic number ***
; **********************************************
nmi:
#include "firmware/modules/nmi_hndl16.s"


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
	.al: REP #$20		; *** 16-bit memory ***
	.xs: SEP #$10		; *** 8-bit indexes ***
	LDY fw_cpu			; get kind of CPU (previoulsy stored or determined) (4)
	LDA #SPD_CODE		; speed code as determined in options.h (3)
	STY cpu_ll			; set outputs (3+4)
	STA c_speed
	LDY himem			; get pages of kernel SRAM (4) ????
	STY k_ram			; store output (3)
	STZ b_ram			; no "high" RAM??? (4) *** TO DO ***
	LDA #fw_mname		; get string pointer
	STA str_pt			; put it outside
	LDA #fw_map			; pointer to standard map TBD ????
	STA ex_pt			; set output
; some separate map for high RAM???
	PLP					; restore sizes eeeek
	_DR_OK				; done

; SET_ISR, set IRQ vector
;		INPUT
; kerntab	= 24b address of ISR (will take care of all necessary registers)
;		zero means RETURN actual value! new 20170820
fw_s_isr:
	_CRITIC				; disable interrupts and save sizes! (5)
#ifdef	SUPPORT
	.xs: SEP #$10		; ** 8-bit indexes **
	LDY run_arch		; called from unaware 6502 code?
	BEQ fw_si24		; no, all set...
		STZ kerntab+2		; ...or clear bank
fw_si24:
#endif
	.al: REP #$20		; ** 16-bit memory ** (3)
	LDA kerntab+1			; get pointer highest... (4)
; no ISRs on PAGE zero... BIT is not suitablex
		BEQ fw_r_isr			; read instead! (2/3)
	STA @fw_isr+1			; store for firmware, note long addressing (6)
	LDA kerntab		; copy lowest too (4+6)
	STA @fw_isr		; will recopy middle byte, no long STX...
fwsi_end:
	_NO_CRIT			; restore interrupts if needed, sizes too (4)
	_DR_OK				; done (8)
fw_r_isr:
	LDA @fw_isr		; get previous value... (6)
	STA kerntab		; ...and store it (4)
	LDA @fw_isr+2		; get bank and garbage! (6)
	STA kerntab+2		; will not hurt anyway (4)
	BRA fwsi_end

; SET_NMI, set NMI vector
;		INPUT
; kerntab	= 24b address of NMI code (including magic string, ends in RTS)
;		zero means RETURN actual value! new 20170820

; might check whether the pointed code starts with the magic string
; no need to disable interrupts as a partially set pointer would be rejected...
; ...unless SAFE mode is NOT selected (will not check upon NMI)

fw_s_nmi:
	_CRITIC				; save sizes, just in case CS is needed...
#ifdef	SUPPORT
	.xs: SEP #$10			; *** standard index size ***
	LDY run_arch		; called from unaware 6502 code?
	BEQ fw_sn24		; no, all set...
		STZ kerntab+2		; ...or clear bank
fw_sn24:
#endif
	.al: REP #$20			; *** 16-bit memory ***
; first check whether read or set
	LDA kerntab+1			; get pointer highest... (4)
; no ISRs on zeropage!
		BEQ fw_r_nmi			; read instead! (2/3)
#ifdef	SAFE
	LDA [kerntab]		; get pointed handler string word
	CMP #'U'+256*'N'	; valid?
		BNE fw_snerr		; error!
	LDY #2				; point to next word
	LDA [kerntab], Y	; get pointed handler string word
	CMP #'k'+256*'*'	; valid?
		BNE fw_snerr		; error!
#endif
; transfer supplied pointer to firmware vector
	LDA kerntab+1			; get pointer highest again (4)
	STA @fw_nmi+1			; store for firmware, note long addressing (6)
	LDA kerntab		; copy lowest too (4+6)
	STA @fw_nmi		; will recopy middle byte, no long STX...
fwsn_end:
	_NO_CRIT			; restore sizes!
	_DR_OK				; done (8)
fw_snerr:
	LDY #CORRUPT			; preload error code
	_NO_CRIT			; restore sizes...
	SEC					; ...but mark error
	RTS					; firmware exit
fw_r_nmi:
	LDA @fw_nmi		; get previous value... (6)
	STA kerntab		; ...and store it (4)
	LDA @fw_nmi+2		; get bank and garbage! (6)
	STA kerntab+2		; will not hurt anyway (4)
	BRA fwsn_end

	.as: .xs			; just in case...

; SET_DBG, set BRK handler
;		INPUT
; kerntab	= 24b address of BRK routine (ending in RTS)
;		zero means RETURN actual value! new 20170820

fw_s_brk:
	PHP					; save sizes! (3)
#ifdef	SUPPORT
	.xs: SEP #$10			; *** standard index size ***
	LDY run_arch		; called from unaware 6502 code?
	BEQ fw_sb24		; no, all set...
		STZ kerntab+2		; ...or clear bank
fw_sb24:
#endif
	.al: REP #$20		; ** 16-bit memory ** (3)
; first check whether read or set
	LDA kerntab+1			; get pointer highest... (4)
; no ISRs on page zero!
		BEQ fw_r_brk			; read instead! (2/3)
	STA @fw_brk+1			; store for firmware, note long addressing (6)
	LDA kerntab			; get pointer lowest (4)
	STA @fw_brk			; sets middle byte too, no problem (6)
fwb_end:
	PLP					; restore sizes (4)
	_DR_OK				; done
fw_r_brk:
	LDA @fw_brk		; get previous value... (6)
	STA kerntab		; ...and store it (4)
	LDA @fw_brk+2		; get bank and garbage! (6)
	STA kerntab+2		; will not hurt anyway (4)
	BRA fwb_end

	.as: .xs			; just in case...

; JIFFY, set jiffy IRQ period
;		INPUT
; irq_hz	= PERIOD in uS (0 means READ current)
;		OUTPUT
; irq_hz	= actually set period (in case of error or no change)
; C			= could not set

fw_jiffy:
; if could not change, then just set return parameter and C
	_CRITIC				; disable interrupts and save sizes! (5)
	.al: REP #$20		; ** 16-bit memory ** (3)
	LDA irq_hz			; get input value
	BNE fj_set			; not just checking
		LDA @irq_freq		; get current frequency
		STA irq_hz			; set return values
fj_end:
		LDA irq_hz			; get asked value
		STA @irq_freq		; set current frequency
		_NO_CRIT			; eeeeeeeeek
		_DR_OK
fj_set:
; *** compute and set VIA counters accordingly!!!!! ***
;	LDA #IRQ_PER*PHI2/1000000-2	; compute value***placeholder
; multiply irq_hz (already in C) by SPD_CODE/4096
	STA local1		; this copy will shift left...
	STZ local1+2		; ...thus clear MSBs
	LDA #SPD_CODE		; hardware speed (might take from FW var)
	STA local2		; this shifts right until clear
	STZ local3		; clear 32-bit result
	STZ local3+2
fj_mul:
		LSR local2		; get 2nd factor lsb
		BCC fj_next		; if was 0, do not add
			CLC
			LDA local1		; otherwise take 1st factor...
			ADC local3		; ...and add to result (C was clear!)
			STA local3		; update!
			LDA local1+2		; same for MSW
			ADC local3+2
			STA local3+2
fj_next:
;			BCS fw_over		; if C is set... error! is it possible?
		ASL local1		; shift 1st factor left
		ROL local1+2
		LDA local2		; check next factor...
		BNE fj_mul		; ...until no more bits
; now local3 holds the full result, must be shifted right 12 bits
; just discard the LSB, shift 4 bits and simply keep the middle two!
	LDX #4			; bits to shift
fj_shft:
		LSR local3+2		; shift amount RIGHT eeeeek
		ROR local3
		DEX			; until done
		BNE fj_shft
; should subtract 2 for proper VIA T1 value, but only 1 if C!
	LDA local3+1		; note offset
; do not preset carry...
	SBC #1			; ...minus 2 if C was clear
; MSB must be zero, otherwise overflow!
	LDY local3+3		; is MSB zero?
	BNE fj_over		; no, outside range
; accumulator has the proper 16-bit value for VIA T1
		STA VIA_J+T1CL			; start running!
		BRA fj_end			; successful
fj_over:
	_NO_CRIT			; eeeeeeeek
	_DR_ERR(INVALID)

	.as: .xs			; just in case...

; IRQ_SRC, investigate source of interrupt
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
	RTS				; return ASAP, all OK

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
; include here shutdown code
	.byt	$DB			; STP in case a WDC CPU is used
	_PANIC("{OFF}")		; just in case is handled
fwp_susp:
; might use a SEI/WAI in case a WDC CPU is used...
fwp_end:
	PLP					; restore sizes
	_DR_OK				; just continue execution
fwp_nmi:
	PHK				; always in bank 0
	PEA fwp_end			; push correct return
	PHP				; will end in RTI
	JMP nmi				; handle as usual
fwp_brk:
	PHK				; always in bank 0
	PEA fwp_end			; push correct return
	PHP				; will end in RTI
	JMP brk_hndl			; handle as usual

; FREQ_GEN, frequency generator hardware interface, TBD
fw_fgen:
; ****** TO BE DONE ******
	_DR_ERR(UNAVAIL)	; not yet implemented

; *** for higher-specced systems ***

; INSTALL, copy jump table
;		INPUT
; kerntab	= address of supplied pointer table

fw_install:
	_CRITIC				; disable interrupts! (5)
	.al: REP #$20		; ** 16-bit memory ** (3)
	.xs: SEP #$10		; ** just in case, 8-bit indexes ** (3)
	LDY #0				; reset index (2)
fwi_loop:
		LDA (kerntab), Y	; get word from table as supplied (6)
		STA @fw_table, Y	; copy where the firmware expects it (6) ***faster if switching DBR but heavier
		INY					; advance two bytes (2+2)
		INY
		BNE fwi_loop		; until whole page is done (3/2)
	_NO_CRIT			; restore interrupts if needed, will restore size too (4)
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
; ****** TO BE DONE ****** not on unexpanded Jalapa
	_DR_ERR(UNAVAIL)	; not yet implemented, Jalapa does not use it


; ****************************
; *** some firmware tables ***
; ****************************

; sub-function jump table (eeeek)
fwp_func:
	.word	fwp_susp	; suspend	+FW_STAT
	.word	kernel		; should not use this, just in case
	.word	reset		; coldboot	+FW_COLD
	.word	fwp_off		; poweroff	+FW_OFF
; might include here the BRK/NMI invocation codes
	.word	fwp_nmi		; PW_CLEAN not allowed here!
	.word	fwp_nmi		; simulate NMI
	.word	fwp_brk		; execute BRK, not sure if needed


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
	.word	fw_s_brk	; *** SET_DBG set debugger, new 20170517
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
	.al: .xl: REP #$38	; status already saved, but save register contents in full, decimal off just in case (3)
	PHA					; save registers (3x4)
	PHX
	PHY
	PHB					; eeeeeeeeeek (3)
; make sure we work on bank zero eeeeeeeeek
	PHK					; stack a 0...
	PLB					; ...for data bank
; in case an unaware 6502 app installs a handler ending in RTS,
; stack imbalance will happen, best keep SP and compare afterwards
#ifdef	SUPPORT
	.xs: SEP #$10		; *** back to 8-bit indexes ***
	TSX					; get stack pointer LSB
	STX sys_sp			; best place as will not switch
	.as: SEP #$20		; now all in 8-bit
#else
	.as: .xs: SEP #$30	; all 8-bit
#endif
; must use some new indirect jump, as set by new SET_BRK
; arrives in 8-bit, DBR=0 (no need to save it)
	JSR @brk_call		; JSL new indirect
; 6502 handlers will end in RTS causing stack imbalance
; must reset SP to previous value
#ifdef	SUPPORT
	.as: SEP #$20		; ** 8-bit memory for a moment **
	TSC					; the whole stack pointer, will not mess with B
	LDA sys_sp			; will replace the LSB with the stored value
	TCS					; all set!
#endif
; restore full status and exit
	.al: .xl: REP #$30	; just in case (3)
	PLB					; eeeeeeeeeeeek (4)
	PLY					; restore status and return (3x5)
	PLX
	PLA
	RTI
brk_call:
	JMP [fw_brk]		; will return

.as:.xs:				; otherwise might prevent code after ROM!


; *** minimOS·16 kernel call interface (COP) ***
cop_hndl:		; label from vector list
	.as: .xs: SEP #$30		; default sizes!
	JMP (fw_table, X)		; the old fashioned way

; *************************************
; new lock routine blinking E-mode LED!
; *************************************
led_lock:
	CLC			; ensure native mode...
	XCE			; ...for a moment
	SEC			; will start in Emulation with C clear
led_switch:
		XCE			; switch between native and emulation mode
		LDA #4			; suitable delay
led_loop:
					INX
					BNE led_loop
				INY
				BNE led_loop
			DEC
			BNE led_loop
		BRA led_switch


; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	kerncall-*, $FF
#endif

; ******************************************************************
; ****** the following will come ALWAYS at standard addresses ****** last 64 bytes
; ******************************************************************

; *** minimOS-65 function call WRAPPER ($FFC0) ***
* = kerncall
	CLC				; must be here!
	COP #$7F			; wrapper on 816 firmware, will do CLC!
	RTS					; return to caller
; *** no longer a wrapper outside bank zero for minimOS·65 ***
; alternative multikernel FW may use an indirect jump...
; ...will point to either the above wrapper (16-bit kernel)...
; ...or the usual indirect-indexed jump (8-bit)...
; ...without pre-CLC or size setting!

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	adm_call-*, $FF
#endif

; *** administrative meta-kernel call primitive ($FFD0) ***
* = adm_call
	JMP (fw_admin, X)		; takes 5 clocks

; *** vectored IRQ handler ***
; could be elsewhere
irq:
	JMP [fw_isr]	; long vectored ISR (6)

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	adm_call-*, $FF
#endif

; *** administrative meta-kernel call primitive for apps ($FFD8) ***
* = adm_appc
	PHB						; could came from any bank
	PHK						; zero is...
	PLB						; ...current bank
	JSR (fw_admin, X)		; return here (DR_OK form)
	PLB						; restore bank...
	RTL						; ...and return from long address!

; *** above code takes -8- bytes, thus no room for padding! ***
; filling for ready-to-blow ROM
;#ifdef	ROM
;	.dsb	lock-*, $FF
;#endif

; *** panic routine, locks at very obvious address ($FFE1-$FFE2) ***
* = lock
	SEI					; same address as 6502
panic_loop:
	BRA led_lock		; OK as this is 65816 only
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
	.word	$FFFF		; reserved			@ $FFF6
	.word	nmi			; emulated ABORT 	@ $FFF8
; *** 65(C)02 ROM vectors ***
* = $FFFA				; just in case
	.word	nmi			; (emulated) NMI	@ $FFFA
	.word	reset		; (emulated) RST	@ $FFFC
	.word	irq			; (emulated) IRQ	@ $FFFE
