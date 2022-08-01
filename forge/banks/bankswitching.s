; bankswitching routines for Durango cartridges
; (c) 2022 Carlos J. Santisteban
; last modified 20220801-2355

; *** whole 32K banks, non-readable '174 *** (max. 2 MiB ROM)
; general address format is A=bank, X=page, Y=offset

* = $8000					; switch routine at start of EVERY bank

far_jmp:					; non-return switch via JMP $8000 with A, X, Y set as above
	STX bs_ptr+1
sw_ya:
	STY bs_ptr				; set indirect jump pointer
	STA IOCbank				; *** do bankswitching, remaining code must be in ALL (destination) banks ***
		JMP (bs_ptr)		; jump to address without return

; *** a far subroutine call needs some sort of readable '174, perhaps with a '245 plus suitable decoding ***
far_call:					; via JSR far_call with A, X, Y set as above
#ifdef	NMOS
	STA br_ptr				; temporary storage!
	LDA IOCbank				; take note of current bank
	PHA						; stack is now old.b, (old-1).o, (old-1).p
	LDA br_ptr				; restore bank
	JSR switch				; will stack next address *in destination bank*
#else
	STX bs_ptr+1			; free X
	LDX IOCbank				; take note of current bank
	PHX						; stack is now old.b, (old-1).o, (old-1).p (CMOS only)
	JSR sw_ya				; X already set, set Y and bank reusing code
#endif
		PLA					; retrieve stored bank (will execute in destination bank)
		STA IOCbank			; switch back to *calling bank*
	RTS						; resume interbank execution

; ***************************
; *** circuit description ***
; ***************************

; * base non-readable '174 *
;	174.CLK		= ~IOC
;	174.Dx		= Dx
;	ROM.A(x+15)	= 174.Qx

; * readable '174 *
;	174.Dx		= Dx
;	ROM.A(x+15)	= 174.Qx
;	245.Bx		= 174.Qx
;	245.Ax		= Dx
;	245.DIR		= '0'
;	139.~EN		= ~IOC
;	139.A0		= ~WE, will it cause bus contention?
;	139.A1		= '0' ['1'] *** may be controlled via, say, A5 for finer addressing
;	174.CLK		= 139.Y0 [Y2]
;	245.~OE		= 139.Y1 [Y3]

; this last circuit may be wired as non-readable with the following changes:
;	do not use '139 or '245
;		139.Y0	= 139.~EN

; **********************************************************
; *** lower 16K bank switchable, fixed upper 16K version *** (max. 1 MiB ROM)
; **********************************************************

; makes much more sense as bankswitching is more suitable for DATA in 65xx systems
; any of the above circuits may be used with this mod:
; (using a '365 for clarity but another '245 would be suitable as well)

;	365.Ix		= 174.Qx
;	365.~OE		= A14
;	ROM.A(x+15)	= 365.Ox + strongish pull-ups ($C000-$FFFF = last bank)

; *** same as above with 4-bit bank selection *** (max. 256 kiB ROM)
; limited to 16 banks allows the use of a single '244 instead of the '245+'365
; may use a '175 instead of the '174 as well, but no pin-count or availability advantage
