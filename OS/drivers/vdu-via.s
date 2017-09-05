; VIA-connected 8 KiB VDU for minimOS!
; v0.6a1
; (c) 2017 Carlos J. Santisteban
; last modified 20170905-2114

; new VIA-connected device ID is $Cx for CRTC control, $Dx for VRAM access, will go into PB
; VIA bit functions (data goes thru PA)
;	in CRTC mode...
; E	= PB0 (easier pulsing)
; RS	= PB1
; R/W	= PB2
; (PB3 must be left as controls the CapsLock LED)
;
;	in VRAM mode, PB0-PB1 go to a '139 to decode...
; %00	= Latch address MSB on trailing edge (or idle)
; %01	= Latch address LSB on trailing edge (most frequent)
; %10	= Write data (perhaps internally pulsed ~300nS for lower noise)
; %11	= Read data (really needed?)
; PB2 should be set to ZERO, for compatibility with future expansion
; again, keep PB3 status!

; ***********************
; *** minimOS headers ***
; ***********************
#include "usual.h"

.(
; *** begins with sub-function addresses table ***
	.byt	205		; physical driver number D_ID (TBD)
	.byt	A_BOUT		; output driver, non-interrupt-driven
	.word	vdu_err		; does not read
	.word	vdu_prn		; print N characters
	.word	vdu_init	; initialise 'device', called by POST only
	.word	vdu_rts		; no periodic interrupt
	.word	0		; frequency makes no sense
	.word	vdu_err		; D_ASYN does nothing
	.word	vdu_err		; no config
	.word	vdu_err		; no status
	.word	vdu_rts		; shutdown procedure does nothing
	.word	vdu_text	; points to descriptor string
	.word	0			; reserved, D_MEM

; *** driver description ***
srs_info:
	.asc	"32 char VIA-VDU v0.6a1", 0

vdu_err:
	_DR_ERR(UNAVAIL)	; unavailable function

; ************************
; *** initialise stuff ***
; ************************
vdu_init:
; must set up CRTC first
; set up VIA...
	LDA VIA_U+IORB		; original PB value on user VIA (new var)
	AND #%00001000		; clear device, E, RS and set to write, leave PB3
	ORA #$C0		; CRTC mode
	STA VIA_U+IORB		; ready to write in 6845 addr reg
	TAY			; keep this status as 'idle' E=RS=0
	LDX #$FF		; all outputs...
	STX VIA_U+DDRB		; ...just in case
	STX VIA_U+DDRA		; data will be sent
; load CRTC registers
vi_crl:
		INX			; next address
		STX VIA_U+IORA		; desired register
		INC VIA_U+IORB		; pulse E, latch address...
		INC VIA_U+IORB		; ...and set RS=1
		LDA vdu_tab, X		; get value for it
		STA VIA_U+IORA		; on data port
		INC VIA_U+IORB		; pulse E, set register...
		STY VIA_U+IORB		; ...and back to idle!
		CPX #$F			; last register done?
		BNE vi_crl		; continue otherwise
; preset some sysvars
; for easier wrapping and expansion, 8 KiB goes $E000-$FFFF
	VR_BASE	=	$E000

	LDA #>VR_BASE		; base address
	LDY #<VR_BASE
	STY vdu_ba		; set standard start point
	STA vdu_ba+1
; software cursor will be set by CLS routine!
; clear all VRAM!
	JSR vdu_cls		; reuse code upon Form Feed
; all done!
	_DR_OK			; succeeded

; ***************************************
; *** routine for clearing the screen ***
; ***************************************
; takes ((27x256)+34)x32+33 ~ 222kt
vdu_cls:
	LDY vdu_ba		; get current base from vars (4+4)
	LDA vdu_ba+1
	STY local1		; set local pointer... (3+3)
	STA local1+1
	STY vdu_cur		; ...and restore home position (4+4)
	STA vdu_cur+1
; get VIA ready, assume all outputs
	LDA VIA_U+IORB		; current PB (4)
	AND #%00001000		; respect PB3 only (2)
	ORA #$D0		; command = latch high address (2)
	STA VIA_U+IORB		; set command $D0/D8... (4)
vcl_lh:
		LDA local1+1		; get MSB (3)
		STA VIA_U+IORA		; is data to be latched... (4)
		INC VIA_U+IORB		; ...now! PB goes to $D1/D9 (6)
		LDA VIA_U+IORB		; worth keeping setL (4)
		TAX			; will be Write too... (2)
		INX			; ...$D2/DA (2)
vcl_ll:
			LDY local1		; get LSB (3)
			STY VIA_U+IORA		; is data to be latched... (4)
			STX VIA_U+IORB		; ...now! went to $D2/DA, faster than INC (4)
			_STZY VIA_U+IORA	; clear output data... (4)
			STA VIA_U+IORB		; ...now! back to $D1/D9, faster than DEC (4)
			INC local1		; next byte (5)
			BNE vcl_ll		; continue page (3, total 27)
		DEC VIA_U+IORB		; back to setH command $D0/D8 (6)
		INC local1+1		; next page! (5)
		BNE vcl_lh		; continue until end (3)
	RTS

; *********************************
; *** print block of characters *** mandatory loop
; *********************************
vdu_prn:
	LDA bl_ptr+1		; get pointer MSB
	PHA			; in case gets modified...
	LDY #0			; reset index
vp_l:
		LDA (bl_ptr), Y		; buffer contents...
		STA io_c		; ...will be sent
		_PHY			; keep this
		JSR vdu_char		; *** print one byte ***
			BCS vdu_exit		; any error ends transfer!
		_PLY			; restore index
		INY			; go for next
		DEC bl_siz		; one less to go
			BNE vp_l		; no wrap, continue
		LDA bl_siz+1		; check MSB otherwise
			BEQ vdu_rts		; no more!
		DEC bl_siz+1		; ...or one page less
		BRA _l
vdu_exit:
	PLA			; discard saved index
	PLA			; get saved MSB...
	STA bl_ptr+1		; ...and restore it
vdu_rts:
	RTS			; exit, perhaps with an error code

; ******************************
; *** print one char in io_c ***
; ******************************
vdu_char:


; ********************
; *** several data ***
; ********************

; CRTC registers initial values
vdu_tab:
	.byt
