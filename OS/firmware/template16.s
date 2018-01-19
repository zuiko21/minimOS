; more-or-less generic firmware for minimOS·16
; v0.6a5
; (c)2015-2018 Carlos J. Santisteban
; last modified 20180119-0847

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
	.asc "65816 0.6a5 firmware for "	; machine description as comment
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
	.asc	"0.6a5 firmware for "
fw_mname:
	.asc	MACHINE_NAME, 0		; store the name at least
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

; some systems might copy ROM-in-RAM and continue at faster speed!
;#include "firmware/modules/rominram.s"

; startup beep
#include "firmware/modules/beep16.s"	; typical 816 standard beep

; SRAM test
#include "firmware/modules/memsiz.s"	; *** must support 24-bit addressing!!!

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
	.al: .xl: REP #$30	; ** whole register size, just in case ** (3)
	PHA					; save registers (3x4)
	PHX
	PHY
	PHB					; eeeeeeeeeeeeeeeek (3)
; prepare for following code while memory is still 16-bit!
	.xs: SEP #$10		; *** back to 8-bit indexes *** (3)
; make NMI reentrant, new 65816 specific code
	LDA sysptr			; get original words (4+3)
	LDX systmp			; this will no longer get sys_sp too!
	PHA					; make sure 8-bit systmp is on top (3+4)
	PHX
; switch DBR to bank zero!!!!
	PHK					; push a zero... (3+3)
	PLB					; ...as current data bank!
; in case an unaware 6502 app installs a handler ending in RTS,
; stack imbalance will happen, best keep SP and reset afterwards
#ifdef	SUPPORT
	TSX					; get stack pointer LSB (2)
	STX sys_sp			; best place as will not switch (3)
#endif
; let us get ready for the return address
	PHK					; return bank is zero (3)
	PEA nmi_end-1		; prepare return address (5)

#ifdef	SAFE
; check whether user NMI pointer is valid
; first copy vector into zeropage, as per long-indirect requirement
	LDA fw_nmi			; copy vector to zeropage, now 24b (5)
	LDX fw_nmi+2		; bank too, new (4)
	STA sysptr			; store all (4+3)
	STX sysptr+2		; actually systmp
; look for the magic string
	LDA [sysptr]		; get first word (7)
	CMP #'U'+256*'N'	; correct? (3)
		BNE rst_nmi			; not a valid routine (2/3)
	LDY #2				; point to second word (2)
	LDA [sysptr], Y		; get that (7)
	CMP #'j'+256*'*'	; correct? (3)
		BNE rst_nmi			; not a valid routine (2/3)
#endif

	.as: SEP #$20		; *** code is executed in 8-bit sizes ***
; jump to user-supplied handler!
; return address already set, but DBR is 0! No need to save it as only DP is accessed afterwards
; MUST respect DP and sys_sp, though
	JMP [fw_nmi]		; will return upon RTL... or RTS (8)
nmi_end:
	.as: SEP #$20		; ** 8-bit memory for a moment ** (3)
#ifdef	SUPPORT
; 6502 handlers will end in RTS causing stack imbalance
; must reset SP to previous value
	TSC					; the whole stack pointer, will not mess with B (2)
	LDA sys_sp			; will replace the LSB with the stored value (3)
	TCS					; all set! (2)
#endif
; *** here goes the former nmi_end routine ***
	PLA					; restrieve systmp and restore it, no longer including sys_sp (4+3)
	STA systmp			; restore values (4+4)
	.al: .xl: REP #$30	; ** whole register size to restore the rest ** (3)
	PLA					; restore saved sysptr (5+5)
	STA sysptr
; as DBR was reset, time to restore it
	PLB					; eeeeeeeek (4)
	PLY					; restore regular registers (3x5)
	PLX
	PLA
	RTI					; resume normal execution and register sizes, hopefully

; *** execute standard NMI handler ***
rst_nmi:
	.xs:				; we came from 8-bit indexes
	.as: SEP #$20		; handler is executed in full 8-bit sizes (3)
; return address already set!
; ...will continue thru subsequent standard handler, its RTS/RTL will get back to ISR exit

; *** default code for NMI handler, enters in 8-bit sizes, if not installed or invalid, should end in RTS... or RTL ***
std_nmi:
#include "firmware/modules/std_nmi16.s"

.as: .xs

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
; kerntab	= pointer to ISR (24b)
;	OUTPUT
; kerntab	= currently set pointer (if was NULL at input)
; sizes irrelevant!

set_isr:
	_CRITIC
	.al: REP #$20		; *** 16-bit memory ***
	.xs: SEP #$10		; *** 8-bit indexes ***
#ifdef	SUPPORT
	LDX run_arch		; called from 8-bit code?
	BEQ si_16b			; no, bank address already provided
		STZ kerntab+2		; otherwise, set it to zero
si_16b:
#endif
	LDA kerntab+1		; check MSB and bank address
	BNE fw_s_isr		; set ISR as was not NULL
		LDA fw_isr			; get whole pointer otherwisw
		LDX fw_isr+2
		STA kerntab			; store result
		STX kerntab+2
; no need to skip next instruction as will be harmless
fw_s_isr:
	LDA kerntab			; get original pointer
	LDX kerntab+2
	STA fw_isr			; store for firmware
	STX fw_isr+2
	_NO_CRIT			; restore sizes and interrupt mask
	_DR_OK				; done


; ********************************
; SET_NMI, set NMI handler routine
; ********************************
; might check whether the pointed code starts with the magic string
; no need to disable interrupts as a partially set pointer would be rejected...
; ...unless SAFE is not selected (will not check upon NMI)
; will use CRITIC section as will save register sizes as well
;	INPUT
; ex_pt		= pointer to ISR (24b)
;	OUTPUT
; ex_pt		= currently set pointer (if was NULL at input)
; sizes irrelevant!
; routine ending in *RTL* (RTS is valid in bank zero, id est, 6502 code), regs already saved, but MUST respect sys_sp

set_nmi:
	LDA kerntab+1			; get MSB (3)
		BEQ fw_r_nmi				; read instead (2/3)
#ifdef	SAFE
	LDY #0				; offset for NMI code pointer (2)
	LDA (kerntab), Y		; get code byte (5)
	CMP #'U'			; match? (2)
		BNE fw_nerr			; not a valid routine (2/3)
	INY					; another byte (2)
	LDA (kerntab), Y		; get code byte (5)
	CMP #'N'			; match? (2)
		BNE fw_nerr			; not a valid routine (2/3)
	INY					; another byte (2)
	LDA (kerntab), Y		; get code byte (5)
	CMP #'j'			; match? (2)
		BNE fw_nerr			; not a valid routine (2/3)
	INY					; another byte (2)
	LDA (kerntab), Y		; get code byte (5)
	CMP #'*'			; match? (2)
		BNE fw_nerr			; not a valid routine (2/3)
#endif
	LDY kerntab				; get LSB (3)
	STY fw_nmi				; store for firmware (4+4)
	STA fw_nmi+1
	_DR_OK					; done (8)
fw_r_nmi:
	LDY fw_nmi				; get current if read (4+4)
	LDA fw_nmi+1
	STY kerntab				; store result (3+3)
	STA kerntab+1
	_DR_OK
fw_nerr:
	_DR_ERR(CORRUPT)		; invalid magic string!

; ***********************
; SET_DBG, set BRK vector
; ***********************
; kerntab	= pointer to ISR (16b)
;	OUTPUT
; kerntab	= currently set pointer (if was NULL at input)
; sizes irrelevant!
; routine ending in RTS, regs already saved, but MUST respect sys_sp

set_dbg:
	LDY kerntab				; get LSB, nicer (3)
	_CRITIC					; disable interrupts! (5)
	LDA kerntab+1			; get MSB (3)
		BEQ fw_r_brk				; read instead (2/3)
	STY fw_brk				; store for firmware (4+4)
	STA fw_brk+1
fwsb_end:
	_NO_CRIT				; restore interrupts if needed (4)
	_DR_OK					; done (8)
fw_r_brk:
	LDY fw_brk				; get current if read (4+4)
	LDA fw_brk+1
	STY kerntab				; store result (3+3)
	STA kerntab+1
	_BRA fwsb_end


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
	.word	set_nmi		; SET_NMI set (magic preceded) NMI routine
	.word	set_dbg		; SET_DBG set debugger, new 20170517

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
; as no long-indirect call is available, long-call here and return to handler
brk_call:
	JMP [fw_brk]		; will return

.as:.xs:				; otherwise might prevent code after ROM!

; *** minimOS·16 kernel call interface (COP) ***
cop_hndl:		; label from vector list
	.as: .xs: SEP #$30	; standard sizes
	JMP (fw_table, X)	; the old fashioned way (this takes 5 bytes)

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
	COP $7F		; wrapper on 816 firmware!
	RTS			; return to caller (this takes 4 bytes)
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
	JMP (fw_admin, X)		; takes 5 clocks and 3 bytes, kernel/drivers only!

; *** vectored IRQ handler ***
; might go elsewhere
irq:
	JMP [fw_isr]	; 24-bit vectored ISR, 4 byte instruction (6) total 7 bytes

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
