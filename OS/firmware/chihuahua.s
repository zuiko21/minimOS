; firmware for minimOS on Chichuahua PLUS (and maybe others)
; v0.9.6a1
; (c)2015-2017 Carlos J. Santisteban
; last modified 20170815-1242

#define		FIRMWARE 	_FIRMWARE

#include "usual.h"

* = FW_BASE			; this will be page-aligned!

; *** first some ROM identification *** new 20150612
fw_start:
	.asc 0, "mB", 13				; standard system file wrapper, new format 20161010, experimental type
	.asc "boot", 0					; standard filename
	.asc "0.9.6a1 firmware for "	; machine description as comment
fw_mname:
	.asc	MACHINE_NAME, 0

	.dsb	fw_start + $100 - *, $FF	; generate padding including end of linked list

; ********************
; ********************
; *** cold restart ***
; ********************
; ********************
; basic init
reset:
	SEI				; cold boot, best assume nothing (2)
	CLD				; just in case, a must for NMOS (2)
; chihuahua is unlikely to use a 65816...
	LDX #$FF		; initial stack pointer, no low ram here, must be done in emulation for '816 (2)
	TXS				; initialise stack (2)
; disable all interrupt sources
	LDA #$7F		; disable all interrupts (2+4)
	STA VIA_J + IER

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
#include "firmware/modules/bootoff.s"

; ***continue power-on self-test***
post:
; might check ROM integrity here
;#include "firmware/modules/romcheck.s"

; startup beep
#include "firmware/modules/beep.s"	; basic standard beep

; SRAM test
#include "firmware/modules/ramtest.s"

; ***********************************
; *** firmware parameter settings ***
; ***********************************
; *** preset kernel start address (standard label from ROM file) ***
	LDY #<kernel	; get LSB, nicer (2)
	LDA #>kernel	; same for MSB (2)
	STY fw_warm		; store in sysvars (4+4)
	STA fw_warm+1

; *** set default CPU type ***
;	LDA #CPU_TYPE	; constant from options.h, remove if tested (2)
; might check out here for the actual CPU type...
; should just get CPU type in A
#include "firmware/modules/cpu_check.s"
	STA fw_cpu		; store variable (4) redundant if stored from module

#ifdef	SAFE
#ifndef	NMOS
	CMP #'N'		; is it NMOS? not supported on this build!
	BNE fw_cpuOK	; otherwise continue
		JMP lock		; cannot handle BRK, alas
fw_cpuOK:
#endif
#endif

; *** preset jiffy IRQ frequency ***
; this must be done by kernel, but at least clear it for 0.5.x compatibility
	_STZA irq_freq			; null speed... IRQ not set
	_STZA irq_freq+1

; *** preset defaul BRK & NMI handlers ***
	LDY #<std_nmi			; defaul BRK like NMI
	LDA #>std_nmi
	STY fw_brk			; set vector
	STA fw_brk+1
; no need to set NMI as it's validated

; *** reset jiffy count ***
	LDX #5				; max offset in uptime seconds AND ticks (assume contiguous)
res_sec:
		_STZA ticks, X		; reset byte
		DEX					; next byte backwards
		BPL res_sec			; zero is included

; ********************************
; *** hardware interrupt setup ***
; ********************************
; *** VIA initialisation (and stop beeping) ***
	LDA #%11000010	; CB2 low, Cx1 negative edge, CA2 indep. neg. (2+4)
	STA VIA_J + PCR
	LDA #%01000000	; T1 cont, no PB7, no SR, no latch (so far) (2+4)
	STA VIA_J + ACR

	LDA #$C0			; enable T1 (jiffy) interrupt only (2+4)
	STA VIA_J + IER

; *** optional network booting ***
; might modify the contents of fw_warm
-remote_boot:
;#include "firmware/modules/netboot.s"

; *******************************************
; *** firmware ends, jump into the kernel ***
; *******************************************
start_kernel:
	JMP (fw_warm)		; (6)

; ********************************
; ********************************
; ****** interrupt handlers ******
; ********************************
; ********************************

; **********************************************
; *** vectored NMI handler with magic number ***
; **********************************************
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
#ifdef	SAFE
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
#endif
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

; *** default code for NMI handler, if not installed or invalid ***
std_nmi:
#include "firmware/modules/std_nmi.s"

; ********************************
; *** administrative functions ***
; ********************************

; *** generic functions ***

; GESTALT, get system info, API TBD
;		OUTPUT
; cpu_ll	= CPU type
; c_speed	= speed code
; str_pt	= *machine name
; ex_pt		= *memory map
; k_ram		= pages of RAM

fw_gestalt:
	LDA himem		; number of pages???
	LDX #SPEED_CODE		; CPU speed
	LDY fw_cpu		; CPU type
	STA k_ram		; set outputs
	STX c_speed
	STY cpu_ll
	LDY #<fw_mname		; get pointer to name
	LDA #>fw_mname
	STY str_pt		; set output
	STA str_pt+1
	LDY #<fw_map		; get pointer to map
	LDA #>fw_map
	STY ex_pt		; set output
	STA ex_pt+1
	_DR_OK

; SET_ISR, set IRQ vector
;	INPUT
; kerntab	= vector

fw_s_isr:
	LDY kerntab				; get LSB, nicer (3)
	LDA kerntab+1			; get MSB (3)
	_CRITIC					; disable interrupts! (5)
	STY fw_isr				; store for firmware (4+4)
	STA fw_isr+1
	_NO_CRIT				; restore interrupts if needed (4)
	_DR_OK					; done (8)

; SET_NMI, set NMI handler routine
; might check whether the pointed code starts with the magic string
; no need to disable interrupts as a partially set pointer would be rejected...
; ...unless SAFE is not selected (will not check upon NMI)
;	INPUT
; kerntab	= vector

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

; SET_DBG, set BRK vector
;	INPUT
; kerntab	= vector

fw_s_brk:
	LDY kerntab				; get LSB, nicer (3)
	LDA kerntab+1			; get MSB (3)
	_CRITIC					; disable interrupts! (5)
	STY fw_brk				; store for firmware (4+4)
	STA fw_brk+1
	_NO_CRIT				; restore interrupts if needed (4)
	_DR_OK					; done (8)

; JIFFY, set/check IRQ speed
;		INPUT
; irq_hz	= desired frequency in Hz (0 means no change)
;		OUTPUT
; irq_hz	= actually set freq (if error or no change)
; C		= error, did not set

fw_jiffy:
	_CRITIC		; this is serious
	LDA irq_hz	; check LSB
	TAY		; save for later
	ORA irq_hz+1	; any bit set?
	BNE fj_set	; will adjust new value
		LDY irq_freq	; otherwise get current
		LDA irq_freq+1
		STY irq_hz	; set output
		STA irq_hz+1
fj_end:
		_NO_CRIT	; all safe now
		_DR_OK		; will work always on this machine!
fj_set:
	STY irq_freq	; set value
	STA irq_freq+1
	_BRA fj_end	; all done, nothing to update

; IRQ_SRC, investigate source of interrupt
;		OUTPUT
; *** X = 0 (periodic), 2 (async IRQ @ 65XX) ***
; *** notice NON-standard output register for faster indexed jump! ***
; other even values will be hardware-dependent

fw_i_src:
	BIT VIA_J+IFR		; much better than LDA, ASL, BPL!
	BVS fis_per		; from T1
		LDX #2			; standard async otherwise
		RTS			; fastest!
fis_per:
	LDA VIA_J+T1CL		; acknowledge periodic interrupt
	LDX #0			; standard jiffy value
	_DR_OK

; *** hardware specific ***

; POWEROFF, shutdown etc
;		INPUT
; Y = mode (0=suspend, 2=warmboot, 4=coldboot, 6=power off)
fw_power:
	TYA					; get subfunction offset
	TAX					; use as index
	_JMPX(fwp_func)		; select from jump table

fwp_off:
	.byt $DB		; in case a WDC CPU is used
	_PANIC("{OFF}")		; stop execution! just in case is handled

fwp_susp:
	_DR_ERR(UNAVAIL)	; just continue execution
; could switch off VIA IRQ and use SEI/WAI for WDC use...

; sub-function jump table
fwp_func:
	.word	fwp_susp	; suspend	+FW_STAT
	.word	start_kernel	; shouldn't use this, just in case
	.word	reset		; coldboot	+FW_COLD
	.word	fwp_off		; poweroff	+FW_OFF
; must include BRK/NMI invocation codes




; A0, install jump table
; kerntab <- address of supplied jump table
fw_install:
	LDY #0				; reset index (2)
	_CRITIC				; disable interrupts! (5)
fwi_loop:
		LDA (kerntab), Y	; get from table as supplied (5)
		STA fw_table, Y		; copy where the firmware expects it (4+2)
		INY
		BNE fwi_loop		; until whole page is done (3/2)
	_NO_CRIT			; restore interrupts if needed (4)
	_DR_OK				; all done (8)



; A4, set NMI vector
; kerntab <- address of NMI code (including magic string)


; A6, patch single function
; kerntab <- address of code
; Y <- function to be patched
fw_patch:
	LDY kerntab				; get LSB (3)
	LDA kerntab+1			; same for MSB (3)
	_CRITIC					; disable interrupts! (5)
	STA fw_table, Y			; store where the firmware expects it (4+4)
	STA fw_table+1, Y
	_NO_CRIT				; restore interrupts if needed (4)
	_DR_OK					; done (8)



; A10, poweroff etc
; Y <- mode (0 = poweroff, 2 = suspend, 4 = coldboot, 6 = warm?)
; C -> not implemented

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
	.dsb	kerncall-*, $FF
#endif

; *** minimOS function call primitive ($FFC0) ***
* = kerncall
	_JMPX(fw_table)	; macro for NMOS compatibility (6)

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	adm_call-*, $FF
#endif

; *** administrative meta-kernel call primitive ($FFD0) ***
* = adm_call
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

; once again, CHIHUAHUA is very unlikely to use a 65816
; filling for ready-to-blow ROM
#ifdef	ROM
	.dsb	$FFFA-*, $FF
#endif

; *** 65(C)02 ROM vectors ***
* = $FFFA				; just in case
	.word	nmi			; NMI	@ $FFFA
	.word	reset		; RST	@ $FFFC
	.word	irq			; IRQ	@ $FFFE
