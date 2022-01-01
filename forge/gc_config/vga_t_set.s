; graphic card auto-configuration firmware module
; suitable for Tampico and perhaps Acapulco computers
; (c) 2020-2022 Carlos J. Santisteban
; last modified 20200508-2143

; ******************************************
; *** variable storage, best in zeropage ***
; ******************************************

	vs_mode	= uz			; table offset for selected mode +7
	zvs_p	= vs_mode + 1		; indirect pointer
	vs_tmout= zvs_p + 2		; timeout counter
#ifdef	NMOS
	vs_cnt	= vs_tmout + 1		; raster loop counter (NMOS only)
#endif

; **********************
; *** initialisation ***
; **********************

; first of all, preconfigure CRTC with common data (R8...R15)
	LDX #15			; last common register
vs_init:
		STX CRTC_RS		; select register
		LDA crtc_com-8, X	; get COMMON table data for all modes
		STA CRTC_DA		; configure selected register
		DEX
		CPX #7			; check whether outside common regs
		BNE vs_init		; until all done
; particular mode data comes next, X is ready for standard 40-col mode!
;	LDX #7			; [A] 40 col industry-standard offset (backwards!)
	JSR vs_setm		; this will reset timeout too

	JSR vs_cls		; *** clear the screen ***

; *******************************************************************************
; *** now let's place some patterns at the corners of every screen resolution ***
; *******************************************************************************

; 170 for left side, 85 for the right (via LSR/ASL)
; $6000 is upper left on ALL modes
; add 31, 35 or 39 for upper right ($601F, $6023 & $6027)
; bottom is much more difficult... base scanline offset is 7168 (7 Ki) or $8C00
; but must add (rows-1)*cols for the left, adding (cols-1) for the right
	LDA #%10101010	; leftmost pattern
	STA $6000		; upper left is always the same address
	STA $7FA0		; store at bottom left places (32, 40 & 36)
	STA $7FC0
	STA $7FCC
	LSR				; makes %01010101 for rightmost pattern
	STA $601F		; store at upper right positions (32, 36 & 40)
	STA $6023
	STA $6027
	STA $7FBF		; store at bottom right places (32, 40 & 36)
	STA $7FE7
	STA $7FEF

; with suitable patterns on screen, make a 10s timeout
; if CR is pressed, keep current mode and go on
; if timeout expired, set safe mode (36-D) and go on
; every time SPC is pressed, cycle between modes and reset timer
; suggested [mode] order is:
; [A] 40	(40x25, industry-standard VGA timing)
; [B] 40DS	(40x25, slow dotclock and shorter sync)
; [C] 36	(36x28, standard VGA timing)
; [D] 36D	(36x28, slow dotclock) *** SAFEST mode ***
; [E] 32L	(32x30, leading VSYNC)
; [F] 32DL	(32x30, slow dotclock, leading VSYNC)
; [G] 32T	(32x30, trailing VSYNC)
; [H] 32DT	(32x30, slow dotclock, trailing VSYNC)

; *****************************
; *** set timeout interrupt ***
; *****************************
	LDA VIA_J+ACR
	AND #%00111111
	ORA #%01000000		; T1 free run, no PB7
	STA VIA_J+ACR
	LDA #$FF		; no longer from timeout reset...
	STA VIA_J+T1CL		; set VIA T1
	STA VIA_J+T1CH
	LSR				; make that $7F
	STA VIA_J+IER		; disable ALL interrupts
	SEI
	LDX #>vs_isr		; supplied ISR
	LDY #<vs_isr
	STX fw_isr+1		; set IRQ vector
	STY fw_isr
	LDA #٪11000000
	STA VIA_J+IER		; enable T1 only
	CLI

; ********************************************
; *** main loop, wait for press or timeout ***
; ********************************************
vs_loop:
		LDY #0				; set for firmware input
		_ADMIN(CONIO)		; firmware BIOS call
			BCS vs_chk		; wait until press or timeout
		CPY #SPACE		; space bar pressed?
		BNE vs_nsp
; *** SPACE: toggle mode and reset timeout ***
			LDA vs_mode		; last set mode
			CLC
			ADC #8			; each mode table takes 8 bytes
			AND #63			; mod 64
			TAX
			JSR vs_setm
			_BRA vs_loop
vs_nsp:
		CPY #NEWL		; newline pressed?
; *** ENTER: keep this mode and exit ***
			BEQ vs_keep
vs_chk:
		LDA vs_tmout		; did timeout expire?
	BEQ vs_fail

; *****************************
; *** print timeout counter ***
; *****************************
		AND #٪11100000	; filter countdown 8...1 (-1)
		LSR			; keep 8 scanlines
		LSR
		TAX
		LDA #0		; no offset
		JSR vs_prn	; print counter
; print letter identifying mode, too
		LDA vs_mode
		AND #%00111000	; filter base table pointer
		ORA #128	; first mode makes 'A'
		TAX
		LDA #1		; just beside the counter
		JSR vs_prn	; print mode
		BEQ vs_loop	; Z was set, no need for BRA

; ***********************************************
; *** *** TIMEOUT, set safe mode and exit *** ***
; ***********************************************
vs_fail:
	LDX #31				; MODE 3 offset (SAFEST)
	JSR vs_setm
vs_keep:
	JMP vs_exit			; will be far as routines and tables are in between

; *****************************************
; *****************************************
; *** skip routines, ISR and table data ***
; *****************************************
; *****************************************

; *********************
; *** set CRTC mode ***
; *********************
vs_setm:
	STX vs_mode
	LDY #7			; reset loop counter (n-1)
vsm_l:
		STY CRTC_RS		; select register (R7...R0)
		LDA crtc_tab, X	; get table data for this mode
		STA CRTC_DA		; configure selected register
		DEX
		DEY
		BPL vsm_l		; until all done
; as Y is $FF, will give nearly 11 seconds at slowest interrupt rate @ 1.5 MHz
	STY vs_tmout
	RTS

; ************************
; *** clear the screen ***
; ************************
vs_cls:
	LDX #$60		; Tampico & Acapulco screen takes $6000-$7FFF in line-doubled mode
	LDY #0			; will reset index too
	TYA				; clear value (could use $FF for white background)
	STX z_pt+1		; set zeropage pointer
	STY z_pt
vcl_l:
		STA (z_pt), Y	; clear screen byte
		INY				; go for next byte in page
		BNE vcl_l
			INC z_pt+1		; next page
		BPL vcl_l	; fortunately, it's up to the last "positive" address!

; *************************************************************
; *** ISR, check whether from T1, decrement timeout counter ***
; *************************************************************
; this version is 11b, 13t if skipped, 21t if done (tmout on ZP)
; any other VIA-enabled interrupt will lock!
vs_isr:
	BIT VIA_J+IFR
	BVC vs_iexit
		BIT VIA_J+T1CL			; ack interrupt, meaningless read
		DEC vs_tmout			; timeout countdown
vs_iexit:
	RTI

; *****************************************************
; *** print around screen centre +A, X=(ASCII-49)*8 ***
; *****************************************************
vs_prn:
	LDY #$62		; middle of the screen is around $6200
	STY zvs_p+1
	STA zvs_p		; new parameter, printing offset
#ifndef	NMOS
	LDY #8				; raster counter
#else
	LDY #0				; replace STZ and keep Y clear
	LDA #8
	STA vs_cnt		; NMOS raster counter
#endif
vs_cl:
		LDA c_font+392, X	; get raster data (from ASCII '1')
#ifndef	NMOS
		STA (zvs_p)		; *** NEEDS CMOS or another counter ***
#else
		STA (zvs_p), Y		; Y is kept 0 in NMOS
#endif
		LDA zvs_p+1
		CLC
		ADC #4			; advance 1KB each raster
		STA zvs_p+1
		INX				; next font byte
#ifndef	NMOS
		DEY				; * for CMOS-only version *
#else
		DEC vs_cnt
#endif
		BNE vs_cl
	RTS				; returns with Z flag set

; ***************************
; *** *** table data  *** ***
; ***************************

; *** specific mode data, [X] preloaded with LAST offset ***
crtc_tab:
; [ 7] 40	(40x25, industry-standard VGA timing)
	.byt	49		; R0, total columns
	.byt	40		; R1, displayed columns
	.byt	41		; R2, HSYNC column position
	.byt	38		; R3, sync width (H=6 col, V=2 raster)
	.byt	31		; R4, total rows
	.byt	13		; R5, vertical raster adjust
	.byt	25		; R6, displayed rows
	.byt	26		; R7, VSYNC row position

; [15] 40DS	(40x25, slow dotclock and shorter sync)

; [23] 36	(36x28, standard VGA timing)

; [31] 36D	(36x28, slow dotclock) *** SAFEST mode ***

; [39] 32L	(32x30, leading VSYNC)

; [47] 32DL	(32x30, slow dotclock, leading VSYNC)

; [55] 32T	(32x30, trailing VSYNC)

; [63] 32DT	(32x30, slow dotclock, trailing VSYNC)

; *** common registers (R8...R15) ***
crtc_com:
	.byt	0		; R8, no interlace, no skew
	.byt	15		; R9, maximum raster
	.byt	32		; R10, no cursor (starts at raster 0)
	.byt	0		; R11, cursor ends at raster 15, if shown
	.word	0		; R12-13, start address, 0 is double-raster
	.word	0		; R14-15, cursor address

; ****************************************
; ****************************************
; *** CONTINUE FIRMWARE INITIALISATION ***
; ****************************************
; ****************************************
vs_exit:
; ** ** may store mode in a permanent fashion, plus setting some driver parameters ** **
	JSR vs_cls		; clear again and exit
