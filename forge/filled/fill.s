; Durango-X filled rectangle routine
; (c) 2022 Carlos J. Santisteban
; last modified 20220821-1919

.bss
; *** input ***
	*	= $F4				; *** placeholder (zpar2) ***

x1:		.byt	0			; NW corner x coordinate (<128 in colour, <256 in HIRES), but all NW/NE/SW/SE combos are accepted
y1:		.byt	0			; NW corner y coordinate (<128 in colour, <256 in HIRES), but all NW/NE/SW/SE combos are accepted
x2:		.byt	0			; _not included_ SE corner x coordinate (<128 in colour, <256 in HIRES), but all NW/NE/SW/SE combos are accepted
y2:		.byt	0			; _not included_ SE corner y coordinate (<128 in colour, <256 in HIRES), but all NW/NE/SW/SE combos are accepted
col:	.byt	0			; pixel colour, in II format (17*index), ignored in HIRES (actually zpar)

; *** zeropage usage and local variables ***
	*	= $E4				; *** placeholder (local1) ***

cio_pt:	.word	0			; screen pointer

; *** other variables (not necessarily in zero page) ***
exc:	.byt	0			; flag for incomplete bytes at each side (could be elshewhere)
tmp:	.byt	0			; temporary use (could be elsewhere)
lines:	.byt	0			; raster counter (could be elsewhere)
bytes:	.byt	0			; drawn line width (could be elsewhere)
l_ex:	.byt	0			; extra W pixels (id, HIRES only)
r_ex:	.byt	0			; extra E pixels (id, HIRES only)

; *** Durango definitions ***
-IO8attr= $DF80				; compatible IO8lh for setting attributes (d7=HIRES, d6=INVERSE, now d5-d4 include screen block)

.text
	*	= $F000				; *** placeholder ***

filled:
; first of all, check whether coordinates are inverted in any way, to get them sorted as NW-SE
	LDA x2					; should be W
	CMP x1					; thus less than E
	BEQ exit				; don't draw anything if zero width!
	BCS x_ok
		LDX x1				; otherwise, swap x1-x2
		STX x2
		STA x1
x_ok:
	LDA y2					; should be S
	CMP y1					; thus less than N
	BEQ exit				; don't draw anything if zero height!
	BCS y_ok
		LDX y1				; otherwise swap y1-y2
		STX y2
		STA y1
y_ok:
; may now compute number of lines and bytes ***(bytes could be done later, as differs from HIRES)
	LDA x1					; lower limit
	LSR						; check odd bit into C
	LDA x2					; higher limit...
	ADC #0					; ...needs one more if lower was odd
	SEC
	SBC x1					; roughly number of pixels
	LSR						; half of that, is bytes
	ROR exc					; E pixel is active, will end at D6 (after second rotation)
	STA bytes
; number of lines is straightforward
	LDA y2
	SEC
	SBC y1
	STA lines				; all OK
; compute NW screen address (once)
	LDA y1					; get North coordinate... (3)
	STA cio_pt+1			; will be operated later
	LDA #0					; this will be stored at cio_pt
	LSR cio_pt+1
	ROR
	LSR cio_pt+1
	ROR						; divide by 4 instead of times 64, already OK for colour (2+5+2+5)
	BIT IO8attr				; check screen mode (4)
		BPL colfill
		BMI hrfill			; jump to HIRES routine
exit:
		RTS
colfill:
	STA cio_pt				; temporary storage
	LDA x1					; get W coordinate
	LSR						; halved
	ROR exc					; this will store W extra pixel at D7
	CLC						; as we don't know previous exc contents
	ADC cio_pt
	STA cio_pt				; LSB ready, the ADD won't cross page
	LDA IO8attr				; get flags... (4)
	AND #$30				; ...for the selected screen... (2)
	ASL						; ...and shift them to final position (2)
	ORA cio_pt+1			; add to MSB (3+3)
	STA cio_pt+1
c_line:
; first draw whole bytes ASAP
		LDA col				; get colour index twice
		LDY bytes			; number of bytes, except odd E
			BEQ c_sete		; only one pixel (E), manage separately
		DEY					; maximum offset
			BEQ c_setw		; only one pixel (W), manage separately
cbytloop:
			STA (cio_pt), Y	; store whole byte
			DEY
			BNE cbytloop	; do not reach zero
c_exc:
; check for extra pixels
		BIT exc				; check uneven bits
		BVS c_setw			; extra at W (or BMI?)
		BMI c_sete			; extra at E (or BVS?)
			STA (cio_pt), Y	; otherwise last byte is full
			BRA c_eok
c_setw:
		AND #$0F			; keep rightmost pixel colour
		STA tmp				; mask is ready
		LDA (cio_pt), Y		; get original screen contents! (Y=0)
		AND #$F0			; filter out right pixel...
		ORA tmp				; ...as we fill it now
		STA (cio_pt), Y
		BIT exc				; unfortunately we must do this, or manage W pixel first
		BPL c_eok			; no extra bit at E (or BVC?)
			LDA col			; in case next filter gets triggered
c_sete:
			LDY bytes		; this is now the proper index!
			AND #$F0		; keep leftmost pixel
			STA tmp			; mask is ready
			LDA (cio_pt), Y	; get original screen contents!
			AND #$0F		; filter out left pixel...
			ORA tmp			; ...as we fill it now
			STA (cio_pt), Y
c_eok:
; advance to next line
		LDA #$40			; OK for colour
;		BIT IO8attr			; check mode
;		BPL nx_lin
;			LSR				; HIRES adds just $20
;nx_lin:
		CLC
		ADC cio_pt
		STA cio_pt
		BCC cl_nowrap
			INC cio_pt+1
cl_nowrap:
		DEC lines
		BNE c_line			; repeat for remaining lines
	RTS
; *** HIRES version ***
hrfill:
; finish proper Y-address computation
	LSR cio_pt+1
	ROR						; divide by 8 instead of times 32 in HIRES mode
	STA cio_pt				; temporary storage
	LDA IO8attr				; get flags... (4)
	AND #$30				; ...for the selected screen... (2)
	ASL						; ...and shift them to final position (2)
	ORA cio_pt+1			; add to MSB (3+3)
	STA cio_pt+1
; lines is OK, but both 'bytes' and new l_ex & r_ex values must be recomputed, plus 'exc'
; determine extra EW pixels
	LDA x2
	AND #7					; modulo 8
	STA r_ex				; 0...7 extra E pixels
	CMP #1					; Carry if >0
	ROR exc					; E pixels present, flag will end at D6 (after second rotation)
	LDA x1
	AND #7					; modulo 8
	STA l_ex				; 0...7 extra W pixels
	CMP #1					; Carry if >0
	ROR exc					; W pixels present, flag at D7
; compute bytes
	LDA exc					; get flags...
	ASL						; ...and put W flag into carry
	LDA x2
	SEC
	SBC x1					; QUICK AND DIRTY**********
	LSR
	LSR
	LSR
	STA bytes				; ...give or take
; add X offset
	LDA x1
	LSR
	LSR
	LSR						; NW / 8
	CLC
	ADC cio_pt
	STA cio_pt				; no C is expected
h_line:
; first draw whole bytes ASAP
		LDA col				; get 'colour' value (0=black, $FF=white)
		LDY bytes			; number of bytes, except extra E
			BEQ h_sete		; only extra E pixels, manage separately
		DEY					; maximum offset
			BEQ h_setw		; only extra W pixels, manage separately
hbytloop:
			STA (cio_pt), Y	; store whole byte
			DEY
			BNE hbytloop	; do not reach zero
h_exc:
; check for extra pixels
		BIT exc				; check uneven bits
		BVS h_setw			; extra at W (or BMI?)
		BMI h_sete			; extra at E (or BVS?)
			STA (cio_pt), Y	; otherwise last byte is full
			BRA h_eok
h_setw:
		LDX l_ex			; get mask index
		AND w_mask, X		; keep rightmost pixels
		STA tmp				; mask is ready
		LDA w_mask, X		; get mask again...
		EOR #$FF			; ...inverted
		AND (cio_pt), Y		; extract original screen intact pixels... (Y=0)
		ORA tmp				; ...as we add the remaining ones now
		STA (cio_pt), Y
		BIT exc				; unfortunately we must do this, or manage W pixel first
		BPL h_eok			; no extra bit at E (or BVC?)
			LDA col			; in case next filter gets triggered
h_sete:
			LDY bytes		; this is now the proper index!
			AND e_mask, X	; keep leftmost pixels
			STA tmp			; mask is ready
			LDA e_mask, X	; get mask again...
			EOR #$FF		; ...inverted
			AND (cio_pt), Y	; extract original screen intact pixels... (Y=0)
			ORA tmp			; ...as we add the remaining ones now
			STA (cio_pt), Y
h_eok:
; advance to next line
		LDA #$20			; OK for HIRES
		CLC
		ADC cio_pt
		STA cio_pt
		BCC hl_nowrap
			INC cio_pt+1
hl_nowrap:
		DEC lines
		BNE h_line			; repeat for remaining lines
	RTS

; *** data tables ***
e_mask:
	.byt	0, %10000000, %11000000, %11100000, %11110000, %11111000, %11111100, %11111110	; [0] never used
w_mask:
	.byt	0, %00000001, %00000011, %00000111, %00001111, %00011111, %00111111, %01111111	; [0] never used
