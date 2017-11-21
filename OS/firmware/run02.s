; firmware for minimOS on run65816 BBC simulator
; 65c02 version for testing 8-bit kernels
; *** use as sort-of template ***
; v0.9.6b2
; (c)2017 Carlos J. Santisteban
; last modified 20171121-1016

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
	.word	$7000			; time, 14.00
	.word	$4AC9			; date, 2017/6/9

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
	SEI					; cold boot (2)
	CLD					; just in case, a must for NMOS (2)
; * this is in case a 65816 is being used, but still compatible with all *
	SEC					; would set back emulation mode on C816 (2)
	.byt	$FB			; XCE on 816 (2), NOP on C02, but illegal 'ISC $0005, Y' on NMOS!
	ORA $0				; the above would increment some random address in zeropage (NMOS) but this one is inocuous on all CMOS (3)
; * end of 65816 specific code *
	LDX #SPTR			; initial stack pointer, machine-dependent, must be done in emulation for '816 (2)
	TXS					; initialise stack (2)

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
;	LDA #'V'			; 65816 installed (2) REDUNDANT if actual test is done
; ...but check it for real afterwards
#include	"firmware/modules/cpu_check.s"
; module will no longer store value
	STA fw_cpu			; store variable (4)

; *** preset kernel start address (standard label from ROM file, unless downloaded) ***
	LDA #>kernel		; get full address (2+2)
	LDY #<kernel
	STA fw_warm+1		; store in sysvars (4+4)
	STY fw_warm

; *** preset default BRK & NMI handlers ***
	LDA #>std_nmi		; default like the standard NMI (2+2)
	LDY #<std_nmi
	STY fw_brk			; store default handler (4+4)
	STA fw_brk+1
; since the NMI handler is validated, no need to install a default

; *** preset jiffy irq frequency ***
; this should be done by installed kernel, but at least set to zero for 0.5.x compatibility!
	_STZA irq_freq		; store null speed... IRQ not set (4+4)
	_STZA irq_freq+1

; *** reset jiffy count ***
	LDX #5				; max offset in uptime seconds AND ticks, assume contiguous (2) eeeeek
res_sec:
		_STZA ticks, X		; reset BYTE (5)
		DEX					; next backwards (2)
		BPL res_sec			; zero is included (3/2)

; ********************************
; *** hardware interrupt setup ***
; ********************************
;	LDX #$C0			; enable T1 (jiffy) interrupt only, this in 8-bit (2+4)
;	STX VIA_J + IER
; should also get the counter running etc

; **********************************
; *** direct print splash string ***
; **********************************
	LDX #0				; reset index (2)
fws_loop:
		LDA fw_splash, X	; get char (4)
			BEQ fws_cr			; no more to print (2/3)
; as direct print uses no regs, nothing to save and reload
		JSR $c0c2			; *** EhBASIC output ***
		INX					; next char (2)
		BNE fws_loop		; no need for BRA, as long as no more tha 255 chars (3/2)
fws_cr:
	LDA #LF				; trailing CR, needed by console! (2)
	JSR $c0c2			; direct print

; *** could download a kernel here, updating fw_warm accordingly ***

; ************************
; *** start the kernel ***
; ************************
start_kernel:
	JMP (fw_warm)		; (5/6)

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
	PHA					; save registers (3x3)
	_PHX
	_PHY
; make NMI reentrant
	LDX sysptr			; get original word  (3+3)
	LDY sysptr+1
	_PHY				; store them in similar order (3+3)
	_PHX
	LDA systmp			; this byte too (3+3)
	PHA
; prepare for routine checking
	LDY fw_nmi			; copy vector... (4+4)
	LDA fw_nmi+1
	STY sysptr			; ...on zeropage (3+3)
	STA sysptr+1
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
	JSR nmi_call		; will do indirect call (6...)
; *** here goes the former nmi_end routine, restore and exit ***
nmi_end:
	PLA					; retrieve saved vars (4+3)
	STA systmp			; only this byte
	_PLX				; sysptr... (4+4)
	_PLY
	STX sysptr			; ...is also restored (3+3)
	STY sysptr+1
	_PLY				; restore regular registers (3x4)
	_PLX
	PLA
	RTI					; resume normal execution, hopefully (6)

nmi_call:
	JMP (fw_nmi)		; call actual code, ending in RTS, DUH (5/6...)

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

; GESTALT, get system info, API TBR
;		OUTPUT
; cpu_ll	= CPU type
; c_speed	= speed code
; str_pt	= points to a string with machine name
; ex_pt		= points to a map of default memory conf ???
; k_ram		= available pages of (kernel) SRAM
; b_ram		= available BANKS of "high" RAM

fw_gestalt:
	LDY fw_cpu			; get kind of CPU (previoulsy stored or determined) (4)
	LDA #SPD_CODE		; speed code as determined in options.h (2)
	STY cpu_ll			; set outputs (3+3)
	STA c_speed
	LDA himem			; get pages of kernel SRAM (4) ????
	STA k_ram			; store output (3)
	_STZA b_ram			; no "high" RAM (4)
	LDA #>fw_mname		; get string pointer (2+2)
	LDY #<fw_mname
	STA str_pt+1		; put it outside (3+3)
	STY str_pt
	LDA #>fw_map		; pointer to standard map TBD (2+2) ????
	LDY #<fw_map
	STY ex_pt			; set output (3+3)
	STA ex_pt+1
	_DR_OK				; done

; SET_ISR, set IRQ vector
;		INPUT
; kerntab	= address of ISR (will take care of all necessary registers)

fw_s_isr:
	LDY kerntab			; get pointer (3+3)
	LDA kerntab+1
	_CRITIC			; disable interrupts! (5)
	STY fw_isr			; store for firmware (4+4)
	STA fw_isr+1
	_NO_CRIT			; restore interrupts if needed (4)
	_DR_OK				; done (8)

; SET_NMI, set NMI vector
;		INPUT
; kerntab	= address of NMI code (including magic string, ends in RTS)

; might check whether the pointed code starts with the magic string
; no need to disable interrupts as a partially set pointer would be rejected...
; ...unless SAFE mode is NOT selected (will not check upon NMI)

fw_s_nmi:
#ifdef	SAFE
	LDX #3				; offset to reversed magic string
	LDY #0				; reset supplied pointer
fw_sn_chk:
		LDA (kerntab), Y	; get pointed handler string char
		CMP fw_magic, X		; compare against reversed string
		BEQ fw_sn_ok		; no problem this far...
			_DR_ERR(CORRUPT)	; ...or invalid NMI handler
fw_sn_ok:
		INY					; try next one
		DEX
		BPL fw_sn_chk		; until all done
#else
	_CRITIC			; as will NOT check upon NMI, do not let partial settings
#endif
; transfer supplied pointer to firmware vector
	LDY kerntab			; get LSB (3)
	LDA kerntab+1		; get MSB (3)
	STY fw_nmi			; store for firmware (4+4)
	STA fw_nmi+1
#ifndef	SAFE
	_NO_CRIT			; had to shut off interrupts in case of no further checking!
#endif
	_DR_OK				; done (8)

; SET_BRK, set BRK handler
;		INPUT
; kerntab	= address of BRK routine (ending in RTS)

fw_s_brk:
	_CRITIC			; disable interrupts! (5)
	LDY kerntab			; get pointer
	LDA kerntab+1
	STY fw_brk			; store for firmware
	STA fw_brk+1
	_NO_CRIT			; restore interrupts if needed
	_DR_OK				; done

; JIFFY, set jiffy IRQ frequency
;		INPUT
; irq_hz	= frequency in Hz (0 means no change)
;		OUTPUT
; irq_hz	= actually set frequency (in case of error or no change)
; C			= could not set (not here)

fw_jiffy:
; this is generic
; if could not change, then just set return parameter and C
	LDA irq_hz+1		; get input values
	LDY irq_hz
		BNE fj_set			; not just checking
	CMP #0				; MSB also 0?
		BNE fj_set			; not checking
	LDA irq_freq+1		; get current frequency
	LDY irq_freq
	STA irq_hz+1		; set return values
	STY irq_hz
fj_end:
	_DR_OK
fj_set:
	STA irq_freq+1		; store in sysvars
	STY irq_freq
	_BRA fj_end			; all done, no need to update as will be OK

; IRQ_SOURCE, investigate source of interrupt
;		OUTPUT
; *** X	= 0 (periodic), 2 (async IRQ @ 65xx) ***
; *** notice NON-standard output register for faster indexed jump! ***
; other even values hardware dependent

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
	TYA					; get subfunction offset
	TAX					; use as index
	_JMPX(fwp_func)		; select from jump table

fwp_off:
	_PANIC("{OFF}")		; just in case is handled
	.byt	$42			; WDM will show up on BBC emulator... and cold boot!

fwp_susp:
	_DR_OK				; just continue execution

; FREQ_GEN, frequency generator hardware interface, TBD
fw_fgen:
; ****** TO BE DONE ******
	_DR_ERR(UNAVAIL)	; not yet implemented

; *** for higher-specced systems ***
#ifndef	LOWRAM

; INSTALL, copy jump table
;		INPUT
; kerntab	= address of supplied pointer table

fw_install:
	_CRITIC			; disable interrupts! (5)
	LDY #0				; reset index (2)
fwi_loop:
		LDA (kerntab), Y	; get word from table as supplied (5)
		STA fw_table, Y		; copy where the firmware expects it (4)
		INY					; advance one byte
		CPY #LAST_API		; EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEK
		BNE fwi_loop		; until whole page is done (3/2)
	_NO_CRIT			; restore interrupts if needed, will restore size too (4)
	_DR_OK				; all done (8)

; PATCH, patch single function
; kerntab <- address of code
; Y <- function to be patched

fw_patch:
	_CRITIC				; disable interrupts and save sizes! (5)
	LDA kerntab				; get full pointer
	LDX kerntab+1
	STA fw_table, Y			; store into firmware
	TXA
	STA fw_table+1, Y
	_NO_CRIT				; restore interrupts and sizes (4)
	_DR_OK					; done (8)

; CONTEXT, zeropage & stack bankswitching
fw_ctx:
; ****** TO BE DONE ******
	_DR_ERR(UNAVAIL)	; not yet implemented

#else
; these functions will not work on 128-byte systems!
fw_install:
fw_patch:
fw_ctx:
	_DR_ERR(UNAVAIL)	; not implemented on smaller systems!

#endif

; ****************************
; *** some firmware tables ***
; ****************************

; magic string for NMI handler
fw_magic:
	.asc	"*jNU"		; REVERSED magic string

; power sub-function pointer table (eeeek)
fwp_func:
	.word	fwp_susp	; suspend	+FW_STAT
	.word	kernel		; shouldn't use this, just in case (standard from rom.s)
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
	.word	fw_s_brk	; SET_BRK set debugger, new 20170517
	.word	fw_jiffy	; JIFFY set jiffy IRQ speed, ** TBD **
	.word	fw_i_src	; IRQ_SOURCE get interrupt source in X for total ISR independence

; pretty hardware specific
	.word	fw_power	; POWEROFF power-off, suspend or cold boot
	.word	fw_fgen		; *** FREQ_GEN frequency generator hardware interface, TBD

; not for LOWRAM systems
#ifndef	LOWRAM
	.word	fw_install	; INSTALL copy jump table
	.word	fw_patch	; PATCH patch single function (renumbered)
	.word	fw_ctx		; *** CONTEXT context bankswitching
#endif

; *** minimOS BRK handler *** might go elsewhere
; not sure how to link this to IRQ
brk_hndl:				; label from vector list
; much like the ISR start
	PHA					; save registers
	_PHX
	_PHY
	JSR brk_call		; indirect call
	_PLY				; restore status and return
	_PLX
	PLA
	RTI
brk_call:
	JMP (fw_brk)		; new vectored handler

; ****** some odds ******

; if case of no headers, at least keep machine name somewhere
#ifdef	NOHEAD
fw_splash:
	.asc	"0.9.6 firmware for "
fw_mname:
	.asc	MACHINE_NAME, 0
#endif

; *** wrapper in case 816-enabled code calls 8-bit kernel??? ***
cop_hndl:				; label from vector list
#ifdef	C816
	.as: .xs: SEP #$30	; *** standard sizes, just in case ***
	JMP (fw_table, X)	; the old fashioned way
	RTI
#endif

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	kerncall-*, $FF
#endif

; ******************************
; *** standard ROM interface ***
; ******************************

; *** minimOS·65 function call interface ($FFC0) ***
* = kerncall
	_JMPX(fw_table)		; the old fashioned way

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	adm_call-*, $FF
#endif

; *** administrative meta-kernel call primitive ($FFD0) ***
* = adm_call
	_JMPX(fw_admin)		; takes 5/6 clocks

; ****** taking up some unused space ******

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

; **********************************
; ****** hardware ROM vectors ******
; **********************************

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
