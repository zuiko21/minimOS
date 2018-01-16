; generic firmware template for minimOS·65
; v0.6b4
; (c)2015-2018 Carlos J. Santisteban
; last modified 20180116-1102

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
	.asc 0, "m", CPU_TYPE			; standard system file wrapper, new format 20161010, experimental type
	.asc "****", CR					; flags TBD
	.asc "boot", 0					; standard filename
fw_splash:
	.asc "0.6b2 firmware for "	; machine description as comment
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
	.asc	"0.6b2 firmware for "
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

; *********************************
; *** optional firmware modules ***
; *********************************

; optional boot selector
;#include "firmware/modules/bootoff.s"

; ***continue power-on self-test***
;post:				; this is no longer needed
; might check ROM integrity here
;#include "firmware/modules/romcheck.s"

; some systems might copy ROM-in-RAM and continue at faster speed!
;#include "firmware/modules/rominram.s"

; startup beep
#include "firmware/modules/beep.s"	; basic standard beep

; SRAM test
#include "firmware/modules/ramtest.s"

; ********************************
; *** hardware interrupt setup ***
; ********************************

; VIA initialisation (and stop beeping)
#include "firmware/modules/via_init.s"

; ***********************************
; *** firmware parameter settings ***
; ***********************************

; set default CPU type
; just set expected default type as defined in options.h...
;#include "firmware/modules/default_cpu.s"
; ...or actually check for it!
#include "firmware/modules/cpu_check.s"
; do NOT include both files at once!

; in case an NMOS CPU is used, make sure this was built for it
#include "firmware/modules/nmos_savvy.s"

; preset kernel start address
#include "firmware/modules/kern_addr.s"

; preset default BRK handler
#include "firmware/modules/brk_addr.s"

; no need to set NMI as it will be validated

; preset jiffy irq frequency
#include "firmware/jiffy_hz.s"

; reset jiffy count
#include "firmware/modules/jiffy_rst.s"

; reset last installed kernel (new)
#include "firmware/modules/rst_lastk.s"

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
; have to save systmp and sysptr, new faster (18 vs 41t) way, just one more byte!
	LDA sysptr			; get original byte (3)
	PHA					; put it on stack (3)
	LDA sysptr+1			; same with other bytes (3*4)
	PHA
	LDA systmp
	PHA				; eeeeeeeeek
#ifdef	SAFE
; check whether user NMI pointer is valid
; alternative faster way 39b, 58t (was 29b, 89t)
	LDY fw_nmi			; copy vector to zeropage (corrected 20150118) (4+4+3+3)
	LDA fw_nmi+1
	STY sysptr			; nicer way 20160407
	STA sysptr+1
	LDY #0				; offset for NMI code pointer (2)
	LDA (sysptr), Y		; get code byte (5)
	CMP #'U'			; match? (2)
		BNE rst_nmi			; not a valid routine (2/3)
	INY					; another byte (2)
	LDA (sysptr), Y		; get code byte (5)
	CMP #'N'			; match? (2)
		BNE rst_nmi			; not a valid routine (2/3)
	INY					; another byte (2)
	LDA (sysptr), Y		; get code byte (5)
	CMP #'j'			; match? (2)
		BNE rst_nmi			; not a valid routine (2/3)
	INY					; another byte (2)
	LDA (sysptr), Y		; get code byte (5)
	CMP #'*'			; match? (2)
		BNE rst_nmi			; not a valid routine (2/3)
#endif
do_nmi:
	JSR go_nmi			; call actual code, ending in RTS (6)
; *** here goes the former nmi_end routine ***
nmi_end:
; restore temporary vars, faster way is 9b, 24t (vs. 8b/40t)
	PLA					; get byte from stack (4)
	STA systmp		; restore it (4)
	PLA					; get byte from stack (4)
	STA sysptr+1		; restore it (4)
	PLA					; get byte from stack (4)
	STA sysptr		; restore it (4)
; restore registers
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

; magic string no longer needed!

; *** default code for NMI handler, if not installed or invalid, should end in RTS ***
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

fw_gestalt:
	LDX #<SPD_CODE		; CPU speed
	LDA #>SPD_CODE
	LDY fw_cpu		; CPU type
	STX c_speed		; set word
	STA c_speed+1
	STY cpu_ll
	LDX himem		; number of pages???
	STX k_ram		; set outputs
	LDY #<fw_mname		; get pointer to name
	LDA #>fw_mname
	STY str_pt		; set output
	STA str_pt+1
	LDY #<fw_map		; get pointer to map
	LDA #>fw_map
	STY ex_pt		; set output
	STA ex_pt+1
	_DR_OK

; ***********************
; SET_ISR, set IRQ vector
; ***********************
;	INPUT
; kerntab	= vector
; 0 means READ current

fw_s_isr:
	LDY kerntab				; get LSB, nicer (3)
	_CRITIC					; disable interrupts! (5)
	LDA kerntab+1			; get MSB (3)
		BEQ fw_r_isr				; will read instead (2/3)
	STY fw_isr				; store for firmware (4+4)
	STA fw_isr+1
fwsi_end:
	_NO_CRIT				; restore interrupts if needed (4)
	_DR_OK						; done (8)
fw_r_isr:
	LDY fw_isr				; get current if read (4+4)
	LDA fw_isr+1
	STY kerntab				; store result (3+3)
	STA kerntab+1
	_BRA fwsi_end

; ********************************
; SET_NMI, set NMI handler routine
; ********************************
; might check whether the pointed code starts with the magic string
; no need to disable interrupts as a partially set pointer would be rejected...
; ...unless SAFE is not selected (will not check upon NMI)
;	INPUT
; kerntab	= vector
; 0 means read current
; routine ending in RTS, regs already saved, but MUST respect sys_sp

fw_s_nmi:
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
;	INPUT
; kerntab	= vector
; 0 means read current
; routine ending in RTS, regs already saved, but MUST respect sys_sp

fw_s_brk:
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

; **************************
; JIFFY, set/check IRQ speed
; **************************
;		INPUT
; irq_hz	= desired period in uS (0 means no change)
;		OUTPUT
; irq_hz	= actually set period (if error or no change)
; C		= error, did not set

fw_jiffy:
	_CRITIC		; this is serious
	LDA irq_hz	; check LSB
	ORA irq_hz+1	; any bit set?
	BNE fj_set	; will adjust new value
		LDY irq_freq	; otherwise get current
		LDA irq_freq+1
		STY irq_hz	; set output
		STA irq_hz+1
fj_end:
; if successful must set final variable from parameter
		LDY irq_hz	; get parameter
		LDA irq_hz+1
		STY irq_freq	; set value, will not harm
		STA irq_freq+1
		_NO_CRIT	; all safe now
		_DR_OK		; will work always on this machine!
fj_set:
; *** compute VIA T1 values from uS at parameter ***
; ** multiply 16x16=32 bits, A.Y x SPD_CODE **
; * will return 16b, result is shifted 12b right *
	STY local1		; set local copy of 1st factor
	STA local1+1
	_STZA local1+2		; clear excess as will shift left
	_STZA local1+3
; local copy of 2nd factor, not worth inverting
	LDA #<SPD_CODE		; original LSB...
	STA local2		; ...at definitive location
	LDA #>SPD_CODE		; original MSB...
	STA local2+1		; ...at definitive location
; clear result variable, a loop just saves one byte and this is 12t vs 39t
; NMOS would prefer specific code!
	_STZA local3
	_STZA local3+1
	_STZA local3+2
	_STZA local3+3
fj_mul:
		LSR local2+1		; extract lsb from 2nd factor
		ROR local2
		BCC fj_next		; bit was clear, do not add
			LDX #0			; worth a loop for 4-byte addition!
			CLC
fj_add:
				LDA local1, X		; current 1st factor...
				ADC local3, X		; add to result
				STA local3, X		; and update it!
				INX
				CPX #4			; repeat until done
				BNE fj_add
; carry here means overflow, is that possible?
fj_next:
		ASL local1		; double 1st factor for next round
		ROL local1+1
		ROL local1+2
		ROL local1+3
; check remaining bits of 2nd factor
		LDA local2
		ORA local2+1
		BNE fj_mul		; still something to do
; multiply is done, but need to correct fixed point (12 bits right)
	LDX #4			; will shift 4 bits and discard LSB
fj_shift:
		LSR local3+3
		ROR local3+2
		ROR local3+1
		DEX			; one less to go
		BNE fj_shift
; if last shift gets C, should add one for accuracy! or subtract just one
; really must subtract 2 for VIA operation, LSB discarded
	LDA local3+1		; temporary LSB
; will not preset C and subtract just 1
	SBC #1			; minus 2 if C was clear
	TAY			; definitive LSB
	LDA local3+2		; this will be MSB
	SBC #0			; propagate borrow
; as result was in 2 middle bytes, MSB must be zero
	LDX local3+3		; is it clear?
	BNE fj_over		; no, outside range!
; start VIA counter as A.Y
		STY VIA_J+T1CL		; set computed period...
		STA VIA_J+T1CH		; ...and start counting!
		_BRA fj_end		; successful!
fj_over:
	_NO_CRIT
	_DR_ERR(INVALID)	; no changes were made

; ****************************************
; IRQ_SRC, investigate source of interrupt
; ****************************************
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
	RTS			; should be always good...

; *** hardware specific ***

; **********************
; POWEROFF, shutdown etc
; **********************
;		INPUT
; Y = mode (0=suspend, 2=warmboot, 4=coldboot, 6=power off)
; *** new interrupt invoke codes (10=NMI, 12=BRK) ***

fw_power:
	TYA					; get subfunction offset
	TAX					; use as index
	_JMPX(fwp_func)		; select from jump table

fwp_off:
	.byt	$DB		; STP in case a WDC CPU is used
	NOP			; avoid DCP abs,Y on NMOS
	NOP
	_PANIC("{OFF}")		; stop execution! just in case is handled
fwp_brk:
	JMP (fw_brk)		; call installed routine, perhaps will return
fwp_susp:
; could switch off VIA IRQ and use SEI/WAI for WDC use...
#ifndef	NMOS
	_CRITIC			; disable interrupts...
	.byt	$CB		; WAI in case of WDC CPU
	NOP			; # not used on other CMOS, but helpful anyway
	_NO_CRIT		; ...and back to business
#else
	_DR_ERR(UNAVAIL)	; avoid AXS# on NMOS
#endif
fw_ret:
	_DR_OK			; for NMI call eeeek
fwp_nmi:
	LDY #<fw_ret		; get correct return address
	LDA #>fw_ret
	PHA			; stack it in order
	_PHY
	PHP			; will end in RTI
	JMP nmi			; handle as usual

; sub-function jump table
fwp_func:
	.word	fwp_susp	; suspend	+FW_STAT
	.word	start_kernel	; shouldn't use this, just in case
	.word	reset		; coldboot	+FW_COLD
	.word	fwp_off		; poweroff	+FW_OFF
	.word	fwp_nmi		; PW_CLEAN is not allowed here!
; must include BRK/NMI invocation codes
	.word	fwp_nmi		; simulated NMI
	.word	fwp_brk		; execute handler

; ***********************************
; FREQ_GEN, generate frequency at PB7
; ***********************************
; ****** T B D ******
fw_fgen:
	_DR_ERR(UNAVAIL)		; not supported

; *** these are for systems with enough RAM ***
#ifndef		LOWRAM

; **************************
; INSTALL, supply jump table
; **************************
;		INPUT
; kerntab	= address of supplied jump table (0 means unpatch all)

fw_install:
; new feature, a null pointer means reinstall previously set jump table!
	LDA kerntab+1		; check whether null (cannot be in zeropage anyway)
	BNE fwi_nz			; not zero, proceed
		LDX fw_lastk		; or store last value
		LDA fw_lastk+1
		STX kerntab			; set previous value
		STA kerntab+1
fwi_nz:
; end of new feature, remove if not required
	LDY #0				; reset index (2)
	_CRITIC				; disable interrupts! (5)
fwi_loop:
		LDA (kerntab), Y	; get from table as supplied (5)
		STA fw_table, Y		; copy where the firmware expects it (4+2)
		INY
		CPY #LAST_API		; EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEK
		BNE fwi_loop		; until whole page is done (3/2)
; kernel successfully installed, keep original table address in case is reset
	LDY kerntab			; get current value...
	LDA kerntab+1
	STY fw_lastk		; ...and store as last valid pointer!
	STA fw_lastk+1
; end of table address storage
	_NO_CRIT			; restore interrupts if needed (4)
	_DR_OK				; all done (8)

; ****************************
; PATCH, patch single function
; ****************************
;		INPUT
; kerntab	= address of function code (0 means reset from last installed kernel)
; Y			= function to be patched

fw_patch:
	LDX kerntab+1			; check whether null, cannot be in zeropage, get MSB anyway (3)
; new feature, a null pointer means unpatch!
	BNE fwp_nz				; already a valid pointer
		LDX fw_lastk+1			; otherwise, let us point to the original kernel table
		LDA fw_lastk
		STX tmp_ktab+1			; prepare indirect pointer
		STA tmp_ktab
		INY						; will get MSB first
		LDA (tmp_ktab), Y		; MSB of entry...
		TAX						; ...will stay here
		DEY						; back to LSB
		LDA (tmp_ktab), Y
		_BRA fwp_rst			; X.A points to original function
fwp_nz:
; end of new feature
	LDA kerntab				; get LSB (3)
fwp_rsp:
	_CRITIC					; disable interrupts! (5)
	STA fw_table, Y			; store where the firmware expects it (4+4)
	TXA						; eeeeeeeeeeeek
	STA fw_table+1, Y
	_NO_CRIT				; restore interrupts if needed (4)
	_DR_OK					; done (8)

; ****************************
; CONTEXT, not supported here!
; ****************************

f_unavail:
	_DR_ERR(UNAVAIL)		; not supported

#endif

; WILL CHANGE


; **************** OLD ** CODE ** FOR ** REFERENCE ********************
; A10, poweroff etc
; Y <- mode (0 = poweroff, 2 = suspend, 4 = coldboot, 6 = warm?)
; C -> not implemented
;fw_power:
	TYA					; get subfunction offset
	TAX					; use as index
	_JMPX(fwp_func)		; select from jump table

;fwp_off:
#include "firmware/modules/poweroff.s"

;fwp_susp:
#include "firmware/modules/suspend.s"

;fwp_cold:
	JMP ($FFFC)			; call 6502 vector, as firmware start will initialize as needed
; ***************************** END *************************************

; **** some strange data ****
fw_map:
	.word	0		; PLACEHOLDER FOR MEMORY MAP

; *** administrative jump table ***
; might go elsewhere as it may grow, especially on NMOS
fw_admin:
; generic functions, esp. interrupt related
	.word	fw_gestalt
	.word	fw_s_isr
	.word	fw_s_nmi
	.word	fw_s_brk
	.word	fw_jiffy
	.word	fw_i_src

; pretty hardware specific
	.word	fw_power
	.word	fw_fgen

; not for LOWRAM systems
#ifndef	LOWRAM
	.word	fw_install
	.word	fw_patch
#ifdef	SAFE
	.word	f_unavail
#endif
#endif

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	kernel_call-*, $FF
#endif

; ******************************************************************
; ****** the following will come ALWAYS at standard addresses ****** last 64 bytes
; ******************************************************************

; *** minimOS function call primitive ($FFC0) ***
* = kerncall
	_JMPX(fw_table)	; macro for NMOS compatibility (6) this will be a wrapper on 816 firmware!

; filling for ready-to-blow ROM
#ifdef		ROM
	.dsb	admin_call-*, $FF
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

fw_end:					; for size computation
.)
