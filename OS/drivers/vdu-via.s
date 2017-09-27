; VIA-connected 8 KiB VDU for minimOS!
; v0.6a5
; (c) 2017 Carlos J. Santisteban
; last modified 20170927-1430

; new VIA-connected device ID is $Cx for CRTC control, $Dx for VRAM access, will go into PB
; VIA bit functions (data goes thru PA)
;	in CRTC mode...
; E	= PB0 (easier pulsing)
; RS	= PB1
; R/W	= PB2
; (PB3 must be left as controls the CapsLock LED)
;
;	in VRAM mode, PB0-PB1 go to a '139 to decode...
; %00	= Latch address MSB on trailing edge (or idle) -- perhaps exchange with LSB?
; %01	= Latch address LSB on trailing edge (most frequent) -- see above
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
	.byt	205			; physical driver number D_ID (TBD)
	.byt	A_BOUT		; output driver, non-interrupt-driven
	.word	vdu_err		; does not read
	.word	vdu_prn		; print N characters
	.word	vdu_init	; initialise 'device', called by POST only
	.word	vdu_rts		; no periodic interrupt
	.word	0			; frequency makes no sense
	.word	vdu_err		; D_ASYN does nothing
	.word	vdu_err		; no config
	.word	vdu_err		; no status
	.word	vdu_rts		; shutdown procedure does nothing
	.word	vdu_text	; points to descriptor string
	.word	0			; reserved, D_MEM

; *** driver description ***
srs_info:
	.asc	"32 char VIA-VDU v0.6a5", 0

vdu_err:
	_DR_ERR(UNAVAIL)	; unavailable function

; *** define some constants ***
	VV_OTH	= %00001000	; bits to be kept, PB3 only
	VV_LH	= $D0		; mask for 'Latch High' command
	VV_LL	= $D1		; mask for 'Latch Low' command
	VV_WR	= $D2		; mask for 'Write VRAM' command
	VV_RD	= $D3		; mask for 'Read VRAM' command
	VV_CRTC	= $C0		; mask for CRTC access (E=RS=/WR = 0)

	V_SCANL	= 8			; number of scanlines (pretty hardwired)

; for easier wrapping and expansion, 8 KiB goes $E000-$FFFF
	VR_BASE		= $E000
	V_SCRLIM	= >VR_BASE+1024	; base plus 32x32 chars

; ************************
; *** initialise stuff ***
; ************************
vdu_init:
; must set up CRTC first
	JSR crtc_rst		; ready to control CRTC
; load CRTC registers
vi_crl:
		INY					; next address
		LDA vdu_data, Y		; get value for it
; set address (Y)/value (A) pair, then idle
		JSR crtc_set
		CPY #$F				; last register done?
		BNE vi_crl			; continue otherwise

; clear all VRAM!
; software cursor will be set by CLS routine!
	JSR vdu_cls			; reuse code upon Form Feed
; reset inverse video mask!
	_STZA vdu_xor		; clear mask is true video
; all done!
	_DR_OK				; succeeded

; ***************************************
; *** routine for clearing the screen ***
; ***************************************
; takes ((27x256)+34)x32+29 ~ 222kt
vdu_cls:
	LDA #>VR_BASE		; base address
	LDY #<VR_BASE
	STY vdu_ba			; set standard start point
	STA vdu_ba+1
	STY local1			; set local pointer... (3+3)
	STA local1+1
	STY vdu_cur			; ...and restore home position (4+4)
	STA vdu_cur+1
; new, preset scrolling limit
	LDA #V_SCRLIM		; original limit, will wrap around this constant
	STA vdu_sch+1		; set new var
	_STZA vdu_sch		; hopefully VRAM will be page-aligned!
; get VIA ready, assume all outputs
; set up VIA... for VRAM access!!!
	LDA VIA_U+IORB		; current PB (4)
	AND #VV_OTH			; respect PB3 only (2)
	ORA #VV_LH			; command = latch high address (2)
	STA VIA_U+IORB		; set command $D0/D8... (4)
vcl_lh:
		LDA local1+1		; get MSB (3)
		STA VIA_U+IORA		; is data to be latched... (4)
		INC VIA_U+IORB		; ...now! PB goes to $D1/D9 (6)
		LDA VIA_U+IORB		; worth keeping setL (4)
		TAX					; will be Write too... (2)
		INX					; ...$D2/DA (2)
vcl_ll:
			LDY local1			; get LSB (3)
			STY VIA_U+IORA		; is data to be latched... (4)
			STX VIA_U+IORB		; ...now! went to $D2/DA, faster than INC (4)
			_STZY VIA_U+IORA	; clear output data... (4)
			STA VIA_U+IORB		; ...now! back to $D1/D9, faster than DEC (4)
			INC local1			; next byte (5)
			BNE vcl_ll			; continue page (3, total 27)
		DEC VIA_U+IORB		; back to setH command $D0/D8 (6)
		INC local1+1		; next page! (5)
		BNE vcl_lh			; continue until end (3)
	RTS

; *********************************
; *** print block of characters *** mandatory loop
; *********************************
vdu_prn:
	LDA bl_ptr+1		; get pointer MSB
	PHA					; in case gets modified...
	LDY #0				; reset index
vp_l:
		_PHY				; keep this
		LDA (bl_ptr), Y		; buffer contents...
		STA io_c			; ...will be sent
		JSR vdu_char		; *** print one byte ***
			BCS vdu_exit		; any error ends transfer!
		_PLY				; restore index
		INY					; go for next
		DEC bl_siz			; one less to go
			BNE vp_l			; no wrap, continue
		LDA bl_siz+1		; check MSB otherwise
			BEQ vdu_end			; no more!
		DEC bl_siz+1		; ...or one page less
		_BRA vp_l
vdu_exit:
	PLA					; discard saved index
vdu_end:
	PLA					; get saved MSB...
	STA bl_ptr+1		; ...and restore it
vdu_rts:
	RTS					; exit, perhaps with an error code

; ******************************
; *** print one char in io_c ***
; ******************************
vdu_char:
; first check whether control char or printable
	LDA io_c			; get char (3)
	CMP #' '			; printable? (2)
	BCS vch_prn			; it is! skip further comparisons (3)
		CMP #FORMFEED		; clear screen?
		BNE vch_nff
			JMP vdu_cls			; clear and return!
vch_nff:
		CMP #CR				; newline?
		BNE vch_ncr
			JMP vdu_cr			; modify pointers (scrolling perhaps) and return
vch_ncr:
		CMP #HTAB			; tab?
		BNE vch_ntb
			JMP vdu_tab			; advance cursor
vch_ntb:
		CMP #BS				; backspace?
		BNE vch_nbs
			JMP vdu_bs			; deleta last character
vch_nbs:
		CMP #14				; shift out?
		BNE vch_nso
			LDA #$FF			; mask for reverse video
			_BRA vso_xor		; set mask and finish
vch_nso:
		CMP #15				; shift in?
		BNE vch_nsi
			LDA #$FF			; mask for true video
vso_xor:
			STA vdu_xor			; set new mask
			RTS					; all done for this setting
vch_nsi:
; non-printable neither accepted control, thus use substitution character
		LDA #'?'			; unrecognised char
		STA io_c			; store as required
vch_prn:
; convert ASCII into pointer offset, needs 11bit
	_STZA io_c+1		; clear MSB (3)
	LDX #3				; will shift 3 bits left (2)
vch_sh:
		ASL io_c			; shift left (5+5)
		ROL io_c+1
		DEX					; next shift (2+3)
		BNE vch_sh
; add offset to font base address
	LDA #<vdu_font		; add to base...
	CLC
	ADC io_c			; ...the computed offset
	STA local1			; store locally
	LDA #>vdu_font		; same for MSB
	ADC io_c+1
;	_DEC				; in case the font has no non-printable glyphs
	STA local1+1		; local1 is source pointer
; create local destination pointer
	LDY vdu_cur			; get current position
	LDA vdu_cur+1
	STY local2			; local2 will be destination pointer
	STA local2+1
; get VIA ready, assume all outputs
; set up VIA... for VRAM access!
	LDA VIA_U+IORB		; current PB (4)
	AND #VV_OTH			; respect PB3 only (2)
	ORA #VV_LL			; command = latch LOW address (2)
	STA VIA_U+IORB		; set command $D1/D9... (4)
	LDX local2			; get destination LSB (3)
	STX VIA_U+IORA		; as data to be latched... (4)
	DEC VIA_U+IORB		; ...now! ready for MSB (6)
	TXA					; current command (2)
	DEX					; worth keeping this value for terminating writes (2)
	_INC				; also interesting as most used commands are not contiguous (2)
	STA local2+2		; keep here as run out of registers (3)
; copy from font (+1...) to VRAM (+1024...)
	LDY #0				; scanline counter
vch_pl:
; transfer byte from glyph data to VRAM thru VIA...
		LDA local2+1		; get destination MSB (3)
		STA VIA_U+IORA		; as data to be latched... (4)
		LDA local2+2		; stored Write command (3)
		STA VIA_U+IORB		; ...now! ready for data write (4)
		LDA (local1), Y		; get glyph data (5)
		EOR vdu_xor			; apply mask! (4)
		STA VIA_U+IORA		; as data to be latched... (4)
		STX VIA_U+IORB		; ...now! quick return to LatchH (4)
; advance to next scanline
		LDA local2+1		; get current MSB (3)
		CLC
		ADC #4				; offset for next scanline is 1024 (2+2)
		STA local2+1		; update (3)
		INY					; next scanline (2)
		CPY #V_SCANL		; all done? (2)
		BNE vch_pl			; continue otherwise (3)
; printing is done, now advance current position
vch_adv:
	INC vdu_cur			; advance to next character (6)
	BNE vch_scs			; all done, no wrap (3)
		INC vdu_cur+1		; or increment MSB (6)
; should set CRTC cursor accordingly
vch_scs:
; set up VIA... (worth a subroutine)
	JSR crtc_rst		; ready to control CRTC
	LDA vdu_cur			; value LSB is first loaded
	LDY #15				; cur_l register on CRTC
vcur_l:
; set address (Y)/value (A) pair, then idle
		JSR crtc_set
; go for next
		LDA vdu_cur+1		; get MSB for next
		DEY					; previous reg
		CPY #13				; cur_h already done?
		BNE vcur_l			; no, go for MSB
; check whether scrolling is needed
		LDA vdu_cur+1		; check position (4)
		CMP vdu_sch+1		; all lines done? (4)
		BNE vch_ok			; no, just exit (3)
		LDA vdu_cur			; check LSB too...
		CMP vdu_sch
		BNE vch_ok
; otherwise must scroll... via CRTC
; increment base address, wrapping if needed
	CLC
	LDA vdu_ba			; get current base...
	ADC #32				; ...and add one line
	STA vdu_ba			; update variable LSB
	LDA vdu_ba+1		; now for MSB
	ADC #0				; propagate carry
	CMP #V_SCRLIM		; did it wrap?
	BNE vsc_nw			; no, just set CRTC and local
		LDA #>VR_BASE		; or yes, wrap value around
vsc_nw:
	STA vdu_ba+1		; update variable MSB...
; ...and CRTC registerSSSSSS!!!!
; VIA already set for CRTC control IDLE!
	LDY #12				; start_h register on CRTC
vsc_upd:
; set address (Y)/value (A) pair, then idle
		JSR crtc_set
; LSB too! eeeeeeeeeeeeek
		LDA vdu_ba			; get LSB
		INY					; following register
		CPY #14				; all done?
		BNE vsc_upd			; no, go for LSB then
; update vdu_sch
	LDA vdu_sch			; get LSB
	LDX vdu_sch+1		; see MSB
	CPX #V_SCRLIM		; already at limit?
	BNE vsc_blim		; not, just increment
		CMP #V_SLOW			; also LSB, just in case?******
	BNE vsc_blim		; not, just increment
		LDX #>VR_BASE		; yes, wrap to 2nd line
		LDA #<VR_BASE		; add one line to this
vsc_blim:
	CLC
	ADC #32				; full line length
	STA vdu_sch			; update variable
	STX vdu_sch+1
vch_ok:
	_DR_OK

; *** carriage return ***
; quite easy as 32 char per line
vdu_cr:
	LDA vdu_cur			; get LSB
	AND #%11100000		; modulo 32
	CLC
	ADC #32				; increment line
	STA vdu_cur			; eeeeeeeeek
vcr_chc:
	BCC vch_ok			; seems OK
		INC vdu_cur+1		; or propagate carry...
		BNE vch_scs			; ...update cursor and check for scrolling, no need for BRA

; *** tab (8 spaces) ***
vdu_tab:
	LDA vdu_cur			; get LSB
	AND #%11111000		; modulo 8
	CLC
	ADC #8				; increment position
vtb_l:
		PHA					; save desired position
		LDA #' '			; will print spaces
		STA io_c
		JSR vch_prn			; direct space printing, A holds 32 too
		PLA					; recover desired address
		CMP vdu_cur			; reached?
		BNE vtb_l			; no, continue
	_DR_OK				; yes, all done

; *** backspace ***
vdu_bs:
; first get cursor one position back...
	JSR vbs_bk			; will call it again at the end
; ...then print a space, the regular way...
	LDA #' '			; code of space
	STA io_c			; store as single char...
	JSR vdu_prn			; print whatever is in io_c
; ...and back again!
vbs_bk:
	DEC vdu_cur			; one position back
	LDA vdu_char		; check for carry
	CMP #$FF			; did it wrap?
	BNE vbs_end			; no, return or end function
		DEC vbs_cur+1		; yes, propagate carry
; really ought to check for possible scroll-UP...
; at least, avoid being outside feasible values
		LDA vbs_cur+1		; where are we?
		CMP #>VR_BASE		; cannot be below VRAM base
		BCS vbs_end			; no borrow, all OK
			LDY #<VR_BASE		; get base address
			LDA #>VR_BASE		; MSB too
			STY vdu_cur			; set current
			STA vdu_cur+1
			PLA					; discard return address, as nothing to print
			PLA
			_DR_ERR(EMPTY)		; try to complain, just in case
vbs_end:
	_DR_OK				; all done, CLC will not harm at first call

; *** generic routines ***
; set up VIA... (worth a subroutine) X=idle, Y=$FF
crtc_rst:
	LDA VIA_U+DDRB		; control port...
	ORA #%11110111		; ...with required outputs...
	STA VIA_U+DDRB		; ...just in case
	LDY #$FF			; all outputs...
	STY VIA_U+DDRA		; ...for data port
	LDA VIA_U+IORB		; original PB value on user VIA (new var)
	AND #VV_OTH			; clear device, leave PB3
	ORA #VV_CRTC		; CRTC mode
	TAX					; keep this status as 'idle' E=RS=0
	STA VIA_U+IORB		; ready to write in 6845 addr reg
	RTS

; set address (Y)/value (A) pair, then idle (X)
crtc_set:
	STY VIA_U+IORA		; select this address...
	INC VIA_U+IORB		; ...now!
	INC VIA_U+IORB		; RS=1, will provide value for register
	STA VIA_U+IORA		; here is the loaded value...
	INC VIA_U+IORB		; ...now!
	STX VIA_U+IORB		; go idle ASAP
	RTS

; ********************
; *** several data ***
; ********************

vdu_data:
; CRTC registers initial values

; values for 32x32, CCIR, 24.576 MHz dot clock
	.byt 48				; R0, horizontal total chars - 1
	.byt 32				; R1, horizontal displayed chars
	.byt 37				; R2, HSYNC position - 1
	.byt 132			; R3, HSYNC width (may have VSYNC in MSN)
	.byt 38				; R4, vertical total chars - 1
	.byt 0				; R5, total raster adjust
	.byt 32				; R6, vertical displayed chars
	.byt 34				; R7, VSYNC position - 1
	.byt 0				; R8, interlaced mode
	.byt 7				; R9, maximum raster - 1
	.byt 32				; R10, cursor start raster & blink/disable (off)
	.byt 7				; R11, cursor end raster
	.byt 224			; R12/13, start address (big endian)
	.byt 0
	.byt 224			; R14/15, cursor position (big endian)
	.byt 0
