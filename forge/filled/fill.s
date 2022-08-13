; Durango-X filled rectangle routine
; (c) 2022 Carlos J. Santisteban
; last modified 20220813-1523

.bss
; *** input ***
	*	= $F4				; placeholder (zpar2)

x1:		.byt	0			; NW corner x coordinate (<128 in colour, <256 in HIRES), but all NW/NE/SW/SE combos are accepted
y1:		.byt	0			; NW corner y coordinate (<128 in colour, <256 in HIRES), but all NW/NE/SW/SE combos are accepted
x2:		.byt	0			; _not included_ SE corner x coordinate (<128 in colour, <256 in HIRES), but all NW/NE/SW/SE combos are accepted
y2:		.byt	0			; _not included_ SE corner y coordinate (<128 in colour, <256 in HIRES), but all NW/NE/SW/SE combos are accepted
col:	.byt	0			; pixel colour, in II format (17*index), ignored in HIRES (actually zpar)

; *** zeropage usage and local variables ***
	*	= $E4				; placeholder (local1)

exc:	.byt	0			; flag for incomplete bytes at each side (could be elshewhere)
tmp:	.byt	0			; temporary use (could be elsewhere)
cio_pt:	.word	0			; screen pointer
lines:	.byt	0			; raster counter (could be elsewhere)
bytes:	.byt	0			; drawn line width (could be elsewhere)

; *** Durango definitions ***
-IO8attr= $DF80				; compatible IO8lh for setting attributes (d7=HIRES, d6=INVERSE, now d5-d4 include screen block)

.text
	*	= $F000				; placeholder

filled:
; first of all, check whether coordinates are inverted in any way, to get them sorted as NW-SE
	LDA x2					; should be W
	CMP x1					; thus less than E
	BCS x_ok
		LDX x1				; otherwise, swap x1-x2
		STX x2
		STA x1
x_ok:
	LDA y2					; should be S
	CMP y1					; thus less than N
	BCS y_ok
		LDX y1				; otherwise swap y1-y2
		STX y2
		STA y1
y_ok:
; may now compute number of lines and bytes
	LDA x2
	SEC
	SBC x1
	LSR						; *** this is OK for colour, not HIRES
	ADC #0					; *** is this OK?
	STA bytes				; *** this is OK for colour, not HIRES
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
	BPL colfill				; * HIRES (TBD) below * (3/2 for COLOUR/HIRES)

colfill:
	STA cio_pt				; temporary storage
	LDA x1					; get W coordinate
	LSR						; halved
	ROR exc					; this stores x1-oddbit at D7 (for now)
	CLC
	ADC cio_pt
	STA cio_pt				; LSB ready, the ADD won't cross page
	LDA IO8attr				; get flags... (4)
	AND #$30				; ...for the selected screen... (2)
	ASL						; ...and shift them to final position (2)
	ORA cio_pt+1			; add to MSB (3+3)
	STA cio_pt+1
; check for uneven byte at E
	LDA x2
	LSR
	ROR exc					; now exc.D7=uneven E, exc.D6=uneven W
c_line:
; first draw whole bytes ASAP
		LDA col				; get colour index twice
		LDY bytes			; backwards index
cbytloop:
			STA (cio_pt), Y	; store whole byte
			DEY
			BNE cbytloop	; do not reach zero
; check for extra pixels
		BIT exc				; check uneven bits
		BVC c_wok			; no extra at W
			LDA col
			AND #$0F		; keep rightmost pixel
			STA tmp			; mask is ready
			LDA (cio_pt), Y	; get original screen contents! (Y=0)
			AND #$F0		; filter out right pixel...
			ORA tmp			; ...as we fill it now
			STA (cio_pt), Y
			BIT c_wok		; unfortunately we must do this, or manage W pixel first
c_wok:
		BMI c_eok			; no extra bit at E
			LDY bytes
			INY				; one more than those already filled
			LDA col
			AND #$F0		; keep leftmost pixel
			STA tmp			; mask is ready
			LDA (cio_pt), Y	; get original screen contents!
			AND #$0F		; filter out left pixel...
			ORA tmp			; ...as we fill it now
			STA (cio_pt), Y
c_eok:
; advance to next line
		LDA #$40			; OK for colour
		BIT IO8attr			; check mode
		BPL nx_lin
			LSR				; HIRES adds $20
nx_lin:
		CLC
		ADC cio_pt
		STA cio_pt
		BCC cl_nowrap
			INC cio_pt+1
cl_nowrap:
		DEC lines
		BNE c_line			; repeat for remaining lines
	RTS
