; Durango-X pixel routines
; (c) 2022 Carlos J. Santisteban
; last modified 20220712-2314

; *** input ***
; X = x coordinate (<128 in colour, <256 in HIRES)
; Y = y coordinate (<128 in colour, <256 in HIRES)
; fw_mask (for inverse/emphasis mode) is $FF to delete pixel, 0 otherwise
; fw_ccol (array PP.PI.IP.II of two-pixel combos, will store ink & paper for COLOUR only)

; *** zeropage usage ***
; cio_pt (screen pointer)
; fw_cbyt (temporary storage, could be elsewhere)

; assuming all but cio_pt is outside ZP, performance is expected as follows (not including CONIO overhead)
; code size = 125 bytes (including table)
; HIRES PLOT = 23+2+48*+19 = 92t ~60 µs
; HIRES UNPLOT = 23+2+48*+22 = 95t ~62 µs
; COLOUR PLOT = 23+3+34*!+5+29** = 94t ~61 µs
; COLOUR UNPLOT = 23+3+34*!+10+29** = 99t ~65 µs
; *) remove 1t if variable in ZP
; !) add 1t for odd pixels

-IO8attr= $DF80				; compatible IO8lh for setting attributes (d7=HIRES, d6=INVERSE, now d5-d4 include screen block)

dxplot:
	STZ cio_pt				; common to all modes (3)
	TYA						; get Y coordinate... (2)
	LSR
	ROR cio_pt
	LSR
	ROR cio_pt				; divide by 4 instead of times 64, already OK for colour (2+5+2+5)
	BIT IO8attr				; check screen mode (4)
	BPL colplot				; * HIRES plot below * (3/2 for COLOUR/HIRES)
		LSR
		ROR cio_pt			; divide by 8 instead of times 32! (2+5)
		STA cio_pt+1		; LSB ready, temporary MSB (3)
		LDA IO8attr			; get flags... (4)
		AND #$30			; ...for the selected screen... (2)
		ASL					; ...and shift them to final position (2)
		ORA cio_pt+1
		STA cio_pt+1		; full pointer ready! (3+3)
		TXA					; get X coordinate (2)
		LSR
		LSR
		LSR					; 8 pixels per byte (2+2+2)
		TAY					; this is actual indexing offset (2)
		TXA					; X again (2)
		AND #7				; MOD 8 (2)
		TAX					; use as index (2)
		LDA pixtab, X		; get pixel within byte (4)
		BIT fw_mask			; check if plot or unplot (4*)
		BVS unplot_h		; * HIRES PLOT below (2/3 for PLOT/UNPLOT)
			ORA (cio_pt), Y	; add to previous data (5/ + 6/ + 6/)
			STA (cio_pt), Y
			RTS
unplot_h:
		EOR #$FF			; * HIRES UNPLOT * negate pattern (/2)
		AND (cio_pt), Y		; subtract pixel from previous data (/5 + /6 + /6)
		STA (cio_pt), Y
		RTS
colplot:
	STA cio_pt+1			; LSB ready, temporary MSB (3)
	LDA IO8attr				; get flags... (4)
	AND #$30				; ...for the selected screen... (2)
	ASL						; ...and shift them to final position (2)
	ORA cio_pt+1			; add to MSB (3+3)
	STA cio_pt+1
	TXA						; get X coordinate (2)
	LSR						; in half (C is set for odd pixels) (2)
	TAY						; this is actual indexing offset (2)
	LDA #$F0				; mask for even pixel (2)
	BCC evpix
		LDA #$0F			; otherwise is odd (3/2+2 for even/odd)
evpix:
	TAX						; keep selected (2)
	BIT fw_mask				; check whether plot or unplot (4*)
	BVS unplot_c
		AND fw_ccol+3		; ink bits in proper place (2+3/3 for PLOT/UNPLOT)
bytecol:
		STA fw_cbyt			; store temporarily (4*)
		TXA					; retrieve mask... (2)
		EOR #$FF			; ...inverted! (2)
		AND (cio_pt), Y		; keep original data in byte... (5)
		ORA fw_cbyt			; ...adding new pixel (4*)
		STA (cio_pt), Y		; EEEEEEEEK (6+6)
		RTS
unplot_c:
	AND fw_ccol				; if unplotting, get paper bits instead (/4* + /3)
	BRA bytecol

; *** data ***
pixtab:
	.dsb	128, 64, 32, 16, 8, 4, 2, 1		; bit patterns from offset
