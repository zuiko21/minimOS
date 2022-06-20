; devX cartridge NMI handler
; 128K RAM + 64K ROM
; (c) 2022 Carlos J. Santisteban
; last modified 20220620-1653

#include "../../OS/macros.h"
#include "../../OS/zeropage.h"

#define	DEBOUNCE	_DEBOUNCE

; *** I/O addresses ***
	IO8attr	= $DF80			; resolution settings as always (D7=HIRES, D6=INVERT, D5-4=SCREEN, D3=RGB)
	IO8sync = $DF88			; blanking signals (D7=LINE, D6=FRAME)
	IOCbank	= $DFFF			; bankswitching register (D7=!ROM, D5-4=high bank $C000-$FFFF (+4), D2-0=low bank $8000-$BFFF

; *** variables ***
	nmi_deb	= $0100			; place to store a magic number ($65) to prevent NMI-button bounce
	IOCold	= $0101			; storage for original bankswitching status *** KLUDGE

; *** parameters needed ***
	oldat	= sys_sp		; address of original gameplay screen mode (usually stores $38), ununsed otherwise
	newat	= $B0			; debugger screen mode

; *******************
; *** NMI handler ***
; *******************

	*	= $FF00				; placeholder address

dx_nmi:
; *******************************************
; *** common NMI handler in all ROM banks *** over $C000
; usual status saving
	PHA						; easiest way to keep original stack frame
; EEEEEEK! must store bankswitching register, try using an *unused* stack address in order to retain the standard stack frame
	LDA IOCbank				; switch banks...
	STA IOCold				; ...hopefully $0100 is not used... EEEEK
	AND #%00001000			; ...to lowest of both ROM[4] and RAM[0] (may use ORA afterwards)
;	AND #%11111000			; use this instead if NMI code is present in all (or current) hi-banks
	STA IOCbank
; *** code afterwards doesn't need to be in all ROM banks ***
; ***********************************************************

dx_cont:
#ifdef	DEBOUNCE
	LDA #$65				; look for magic constant in memory
	CMP nmi_deb				; are we already executing NMI?
	BNE do_nmi				; no, set lock and proceed
		PLA					; otherwise, forget it
		RTI
do_nmi:
	STA nmi_deb				; this will prevent calling another NMI on top of this one
#endif
	_PHX
	_PHY					; continue saving status

; as this will save the WHOLE ZP, no need for saving extended status!

; *** make a full memory dump on bankswitched RAM ***
; first goes specific zeropage code, won't need any pointers
	LDX #0					; reset index (will include extended status)
zp_save:
		LDA 0, X
		STA $8000, X		; copy ZP at low-bank bottom
		INX
		BNE zp_save

; no actual need to store SP
; we may dispose of actual ZP freely now
	LDX #1					; first page for source pointer
	STX sys_sp				; unusual location! won't disturb oldat
	LDX #$81				; first page for destination, will remain in register
hi_blk:
		STX sysptr+1		; use savvy interrupt pointer
		LDY #0				; byte index, always zero
		STY sysptr			; complete pointers
		STY systmp			; note unusual source address
mem_save:
			LDA (systmp), Y	; copy one byte into bankswitched RAM
			STA (sysptr), Y
			INY
			BNE mem_save
		INC sys_sp			; next page
		BMI saved			; all copied!
			INX				; otherwise advance destination pointer
			CPX #$C0		; still within low bank?
			BNE hi_blk		; yes, update pointer MSB with X value
		LDX #$80			; otherwise, roll back to low-bank bottom
		INC IOCbank			; eeeeeeek!
		BNE hi_blk			; no need for BRA
saved:

; *** tweak firmware CONIO with $70 as top page ***
	LDA #$70
	STA fw_vbot				; actually TOP of screen...

; store old (gameplay) and set new (debugging) video mode
	LDA IO8attr				; get current mode
	ORA #%00001000			; *** may assume RGB mode?
	STA oldat				; store for resolution switcher! sys_sp no longer in use
	LDA #newat				; new debug screen mode (usually HIRES)
	STA IO8attr				; and set new mode for debugging

; ***********************
; *** main debug loop ***
; ***********************

	JSR init				; initialise debugger, or at least clear screen with new limits
db_loop:
		JSR switch			; try to display top half of the screen in colour, bottom in HIRES
		JSR debug			; invoke (on inline) miniMoDA or similar monitor (hopefully less than 11.7 ms)
		BCC db_loop			; debug until returns with C set (for instance)

	LDA oldat				; restore old video mode (firmware tweak will be undone by memory restore)
	STA IO8attr				; sys_sp is now free for the loops

; ******************************************
; *** exit debugger, restore full status ***
; ******************************************
; pretty much the same in reverse order
	LDX #1					; first page for now DEST pointer, skipping ZP
	STX sys_sp				; unusual location!
	LDX #$81				; first page for SOURCE, will remain in register
	LDY #0					; byte index, always zero
	STY sysptr				; complete pointers
	STY systmp				; note unusual DESTINATION address location
	STY IOCbank				; EEEEEEEEEEK
hi_rst:
		STX sysptr+1		; update savvy interrupt pointer
mem_rst:
			LDA (sysptr), Y	; copy one byte FROM bankswitched RAM
			STA (systmp), Y
			INY
			BNE mem_rst
		INC sys_sp			; next page
		BMI restored		; all copied!
			INX				; otherwise advance SOURCE pointer
			CPX #$C0		; still within low bank?
			BNE hi_rst		; yes, update pointer MSB with X value
		LDX #$80			; otherwise, roll back to low-bank bottom
		INC IOCbank			; eeeeeeek!
		BNE hi_rst			; no need for BRA
restored:

; finally goes specific zeropage code, won't need any pointers
	LDX #0					; reset index
	STX IOCbank				; EEEEEEEEK
zp_rst:
		LDA $8000, X		; copy from low-bank bottom to ZP
		STA 0, X
		INX
		BNE zp_rst

; memory is restored, now the registers
	_PLY					; usual end of restore sequence
	_PLX
	LDA IOCold				; retrieve old banks...
	STA IOCbank
#ifdef	DEBOUNCE
	INC nmi_deb				; ugly, but will allow next NMI invocation, may use STZ as well
#endif
	_BRA dx_exit			; advance to common exit point!

	.dsb	$FFBE-*, $FF	; filler

dx_exit:
; *****************************************************
; *** this must be at a common address in all banks *** usually $FFBE, savvy dx_exit address
	PLA
	RTI
; *** end of common NMI handler *** usually at minimOS-savvy $FFC0
; *********************************
dx_end:
