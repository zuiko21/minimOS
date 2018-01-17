; more-or-less generic firmware for minimOS·16
; v0.6a4
; (c)2015-2018 Carlos J. Santisteban
; last modified 20180117-1243

#define		FIRMWARE	_FIRMWARE
#include "usual.h"
; already set at FW_BASE via rom.s

.(
#ifndef	NOHEAD
; *************************************
; *** first some ROM identification *** new 20150612
; *************************************
; this is expected to be loaded at an aligned address anyway
fw_start:
	.asc 0, "mV", 13					; standard system file wrapper, new 20161010, experimental type
	.asc "****", CR						; flags TBD eeeeeeeeeeeeeeeeeeeeeeeeeek
	.asc "boot", 0						; standard filename
fw_splash:
	.asc "65816 0.6a4 firmware for "	; machine description as comment
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
	.asc	"0.6a4 firmware for "
fw_mname:
	.asc	MACHINE_NAME, 0		; store the name at least
#endif

; ********************
; *** cold restart ***
; ********************

reset:
; *** basic init ***
#include "firmware/modules/basic_init.s"

; ******************************
; *** minimal hardware setup ***
; ******************************

; check for VIA presence and disable all interrupts
#include "firmware/modules/viacheck_irq.s"

; as this firmware should be 65816-only, check for its presence or nothing!
#include "firmware/modules/816_check.s"
; it can be assumed 65816 from this point on

; *********************************
; *** optional firmware modules ***
; *********************************

; optional boot selector
;#include "firmware/modules/bootoff.s"

; ***continue power-on self-test***
;post:					; this is no longer needed
; might check ROM integrity here
;#include "firmware/modules/romcheck.s"

; some systems might copy ROM-in-RAM and continue at faster speed!
;#include "firmware/modules/rominram.s"

; startup beep
#include "firmware/modules/beep16.s"	; typical 816 standard beep

; SRAM test
#include "firmware/modules/ramtest.s"	; *** must support 24-bit addressing!!!

; ********************************
; *** hardware interrupt setup ***
; ********************************

; VIA initialisation (and stop beeping)
#include "firmware/modules/via_init.s"

; ***********************************
; *** firmware parameter settings ***
; ***********************************

; set default CPU type
	LDA #'V'			; 65816 only (2)
	STA fw_cpu			; store variable (4)

; no way to be assembled for NMOS

; *** worth switching to 16-bit memory while setting pointers ***
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
-remote_boot:
;#include "firmware/modules/netboot.s"

; *******************************************
; *** firmware ends, jump into the kernel ***
; *******************************************
start_kernel:
	SEC					; emulation mode for a moment (2+2)
	XCE
	JMP (fw_warm)		; (5)


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
	PHA					; save registers (4x4)
	PHX
	PHY
	PHB					; eeeeeeeeeeeeeeeek
; make NMI reentrant, new 65816 specific code
; assume all registers in 16-bit size, this is 6+2 bytes, 16+2 clocks! (was 10b, 38c)
	LDY sysptr			; get original word (4+4)
	LDA systmp			; this will get sys_sp also!
	PHY					; store them in similar order (4+4)
	PHA
; switch DBR to bank zero!!!!
	PHK					; push a zero...
	PLB					; ...as current data bank!
; prepare for next routine while regs are still 16-bit!
	LDA fw_nmi			; copy vector to zeropage (5+4)
	STA sysptr

#ifdef	SAFE
; check whether user NMI pointer is valid
	LDA (sysptr)		; get magic word, still on 16-bit (6)
	CMP #'NU'			; valid? (3)
		BNE rst_nmi			; not a valid routine (2/3)
	LDY #2				; point to next word (3)
	LDA (sysptr), Y		; get next magic word, still on 16-bit (6)
	CMP #'*j'			; valid? (3)
		BNE rst_nmi			; not a valid routine (2/3)
; OK to proceed with supplied routine
#endif

	.as: .xs: SEP #$30	; ** back to 8-bit size! **
	LDX #0				; null offset
	JSR (fw_nmi, X)		; call actual code, ending in RTS (6)
; *** here goes the former nmi_end routine ***
nmi_end:
	.al: .xl: REP #$30	; ** whole register size to restore **
	PLA					; retrieve saved vars (5+5)
	PLY
	STA systmp			; I suppose is safe to alter sys_sp too (4+4)
	STY sysptr
	PLB					; eeeeeeeek
	PLY					; restore regular registers (3x5)
	PLX
	PLA
	RTI					; resume normal execution and register size, hopefully


; *** execute standard NMI handler ***
rst_nmi:
	.as: .xs: SEP #$30	; ** back to 8-bit size! **
; should I PHK for 24b pointers???
	PEA nmi_end-1		; prepare return address
; ...will continue thru subsequent standard handler, its RTS (RTL???) will get back to ISR exit

; *** default code for NMI handler, if not installed or invalid, should end in RTS (RTL???) ***
std_nmi:
#include "firmware/modules/std_nmi.s"

; ********************************
; *** administrative functions ***
; ********************************

; *** generic functions ***

; *********************************
; GESTALT, get system info, API TBD
; *********************************
;		OUTPUT
; cpu_ll	= CPU type
; c_speed	= speed code (now 16b)
; str_pt	= *machine name
; ex_pt		= *memory map
; k_ram		= pages of RAM
; sizes irrelevant

gestalt:
	PHP					; keep sizes (3)
	.al: REP #$20		; ** 16-bit memory **
	LDA #SPEED_CODE		; speed code as determined in options.h (2+3)
	LDX fw_cpu			; get kind of CPU (previoulsy stored or determined) (4+3)
	STA c_speed			; store values
	STX cpu_ll
	LDX himem			; get pages of kernel SRAM (4)
	STX k_ram			; store output (3)
	LDA #fw_mname		; get pointer to name
	STA str_pt			; set value
	LDA #fw_map			; get pointer to map
	STA ex_pt			; set output
	PLP					; restore sizes (4)
	_DR_OK				; done (8)


; ***********************
; SET_ISR, set IRQ vector
; ***********************
;	INPUT
; kerntab	= pointer to ISR (16b)
;	OUTPUT
; kerntab	= currently set pointer (if was NULL at input)
; sizes irrelevant!

set_isr:
	_CRITIC
	.al: REP #$20		; *** 16-bit memory ***
	.xs: SEP #$10		; *** 8-bit indexes ***
	LDA kerntab			; get original pointer
	BNE fw_s_isr		; set ISR as was not NULL
		LDA fw_isr			; get whole pointer otherwisw
		STA kerntab			; store result
; no need to skip next instruction as will be harmless, saving 3 bytes although wasting 5 cycles
fw_s_isr:
	STA fw_isr			; store for firmware
	_NO_CRIT			; restore sizes and interrupt mask
	_DR_OK				; done




; -------------------- old code ----------------------
; *** administrative functions ***
; A0, install jump table
; kerntab <- address of supplied jump table
fw_install:
	LDY #0				; reset index (2)
	_ENTER_CS			; disable interrupts! (5)
	.al: REP #$20		; ** 16-bit memory ** (3)
fwi_loop:
		LDA (kerntab), Y	; get word from table as supplied (6)
		STA fw_table, Y		; copy where the firmware expects it (5)
		INY					; advance two bytes (2+2)
		INY
		BNE fwi_loop		; until whole page is done (3/2)
	_EXIT_CS			; restore interrupts if needed, will restore size too (4)
	_DR_OK				; all done (8)




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
; not worth going 16-bit as will by 9b/19c instead of 10b/14c
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
; worth going 16-bit as status was saved, 10b/21c , was 13b/23c
	_ENTER_CS				; disable interrupts and save sizes! (5)
	.al: REP #$20			; ** 16-bit memory ** (3)
	LDA kerntab				; get full pointer (4)
	STA fw_table, Y			; store into firmware (5)
	_EXIT_CS				; restore interrupts and sizes (4)
	_DR_OK					; done (8)
#endif


; A10, poweroff etc
; Y <- mode (0 = poweroff, 2 = suspend, 4 = coldboot, 6 = warm?)
; C -> not implemented
fw_power:
	TYX					; get subfunction offset as index
	JMP (fwp_func, X)	; select from jump table

fwp_off:	; ******** CONTINUE HERE ********* CONTINUE HERE *********
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

; *********************************
; *** administrative jump table *** changing
; *********************************
fw_admin:
; generic functions, esp. interrupt related
	.word	gestalt		; GESTALT get system info (renumbered)
	.word	set_isr		; SET_ISR set IRQ vector
	
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
	PHB						; eeeeeeeeeek
; will this work outside bank zero???
;	JSR brk_handler			; standard label from IRQ****
	.al: .xl: REP #$30		; just in case (3)
	PLB						; eeeeek
	PLY						; restore status and return
	PLX
	PLA
	RTI

; *** minimOS·16 kernel call interface (COP) ***
cop_hndl:		; label from vector list
	.as: .xs: SEP #$30
	JMP (fw_table, X)		; the old fashioned way

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	kernel_call-*, $FF
#endif

; ******************************************************************
; ****** the following will come ALWAYS at standard addresses ****** last 64 bytes
; ******************************************************************

; *** minimOS·65 function call WRAPPER ($FFC0) ***
* = kerncall
	CLC			; pre-clear carry
	COP $FF		; wrapper on 816 firmware!
	RTS			; return to caller

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	admin_call-*, $FF
#endif

; *** administrative meta-kernel call primitive ($FFD0) ***
* = adm_call
	JMP (fw_admin, X)		; takes 5 clocks

; *** vectored IRQ handler ***
; might go elsewhere
irq:
	JMP (fw_isr)	; vectored ISR (5)

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
	.word	$FFFF		; reserved			@ $FFF6
	.word	nmi			; emulated ABORT 	@ $FFF8
; *** 65(C)02 ROM vectors ***
* = $FFFA				; just in case
	.word	nmi			; (emulated) NMI	@ $FFFA
	.word	reset		; (emulated) RST	@ $FFFC
	.word	irq			; (emulated) IRQ	@ $FFFE

fw_end:					; for size computation
.)
