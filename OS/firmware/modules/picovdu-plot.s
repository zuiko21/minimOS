; picoVDU pixel routines
; (c) 2022-2024 Carlos J. Santisteban
; last modified 20240526-1015

; *** input ***
; X = x coordinate
; Y = y coordinate
; px_col = colour (reads d7 only)

; *** zeropage usage ***
; cio_pt (screen pointer)
; gr_tmp (temporary storage, could be elsewhere)

; NEW performance data
; *) remove 1t if variable in ZP
; HIRES PLOT = 23+2+48*+19 = 92t ~60 µs
; HIRES UNPLOT = 23+2+48*+22 = 95t ~62 µs
; COLOUR EVEN = 23+3+27+3+31*** = 84-87t ~55-57 µs
; COLOUR ODD = 23+3+27+6+31*** = 87-90t ~57-59 µs

#ifndef	USE_PLOT
cio_pt	= $FB				; screen pointer
gr_tmp	= cio_pt+2			; (temporary storage, could be elsewhere) cleaner this way
tmp		= gr_tmp			; hopefully works! (demo only)
#endif

dxplot:
.(
	STZ cio_pt				; common to all modes (3)
	TYA						; get Y coordinate... (2)
	LSR
	ROR cio_pt
	LSR
	ROR cio_pt				; divide by 4 instead of times 64, already OK for colour (2+5+2+5)
	LSR
	ROR cio_pt			; divide by 8 instead of times 32! (2+5)
	STA cio_pt+1		; LSB ready, temporary MSB (3)
	LDA #$60			; fixed screen position (2)
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
	BIT px_col			; check colour to plot (4*)
	BPL unplot_h		; alternative clear routine (2/3)
		ORA (cio_pt), Y		; add to previous data (5/ + 6/ + 6/)
		STA (cio_pt), Y
		RTS
unplot_h:
	EOR #$FF			; * HIRES UNPLOT * negate pattern (/2)
	AND (cio_pt), Y		; subtract pixel from previous data (/5 + /6 + /6)
	STA (cio_pt), Y
	RTS
; *** data ***
pixtab:
	.byt	128, 64, 32, 16, 8, 4, 2, 1		; bit patterns from offset
.)
