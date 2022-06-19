; devX cartridge NMI handler
; 128K RAM + 64K ROM
; (c) 2022 Carlos J. Santisteban
; last modified 20220619-1919

; *** I/O addresses ***
	IO8attr	= $DF80			; resolution settings as always (D7=HIRES, D6=INVERT, D5-4=SCREEN, D3=RGB)
	IO8sync = $DF88			; blanking signals (D7=LINE, D6=FRAME)
	IOCbank	= $DFFF			; bankswitching register (D7=!ROM, D5-4=high bank $C000-$FFFF (+4), D2-0=low bank $8000-$BFFF

; *** variables ***
	IOCold	= $0100			; storage for original bankswitching status *** KLUDGE
;	nmi_deb	= place to store a magic number ($65) to prevent NMI-button bounce

; *** parameters needed ***
;	oldat	= original gameplay screen mode (usually $38)
;	newat	= debugger screen mode (usually $B0)

; *******************
; *** NMI handler ***
; *******************
dx_nmi:
; usual status save
	PHA						; easiest way to keep original stack frame
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

; save extended status *** TBD

; EEEEEEK! must store bankswitching register, try using an *unused* stack address in order to retain the standard stack frame
	LDA IOCbank				; switch low bank...
	PHA						; ...saving previos setting...
	AND #%11111000			; ...to zero (may use ORA afterwards)
	STA IOCbank
	STA IOCold				; hopefully $0100 is not used...

; *** make a full memory dump on bankswitched RAM ***
; first goes specific zeropage code, won't need any pointers
	LDX #0					; reset index (will actually waste a few cycles for extended status)
zp_save:
		LDA 0, X
		STA $8000, X		; copy ZP at low-bank bottom
		INX
		BNE zp_save

; may store SP at *stored* sys_sp ($80FF), really needed?
	TSX
	STX $80FF				; copy of SP, must retrieve that upon return

; we may dispose of actual ZP freely now
	LDX #1					; first page for source pointer
	STX sys_sp				; unusual location!
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

; *** tweak firmware CONIO with $70 as top page - TBD

; store old (gameplay) and set new (debugging) video mode
	LDA IO8attr				; get current mode
	STA oldat				; store for resolution switcher!
	LDA #$B0				; new debug screen mode (usually HIRES)
	STA newat				; store to be retrieved
	STA IO8attr				; and set new mode for debugging

; ***********************
; *** main debug loop ***
; ***********************
; may initialise monitor *** TBD
db_loop:
		JSR switch			; try to display top half of the screen in colour, bottom in HIRES
		JSR debug			; invoke (on inline) miniMoDA or similar monitor
		BCC db_loop			; debug until returns with C set (for instance)

	LDA oldat				; restore old video mode (firmware tweak will be undone by memory restore)
	STA IO8attr

; ******************************************
; *** exit debugger, restore full status ***
; ******************************************
; pretty much the same in reverse order
	LDX #1					; first page for now DEST pointer, skipping ZP
	STX sys_sp				; unusual location!
	LDX #$81				; first page for SOURCE, will remain in register
hi_rst:
		STX sysptr+1		; use savvy interrupt pointer
		LDY #0				; byte index, always zero
		STY sysptr			; complete pointers
		STY systmp			; note unusual DESTINATION address location
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

; may retrieve SP from *stored* sys_sp ($80FF)
	LDX $80FF				; copy of SP, must retrieve that upon return
	TXS						; does this make ANY sense?

; finally goes specific zeropage code, won't need any pointers
	LDX #0					; reset index (will actually waste a few cycles for extended status)
zp_rst:
		LDA $8000, X		; copy from low-bank bottom to ZP
		STA 0, X
		INX
		BNE zp_rst

; restore extended state *** TBD

; memory is restored, now the registers
	LDA IOCold				; retreive old banks...
	STA IOCbank
	_PLY					; usual end of restore sequence
	_PLX
#ifdef	DEBOUNCE
	INC nmi_deb				; ugly, but will allow next NMI invocation, may use STZ as well
#endif
	_PLA
	RTI
