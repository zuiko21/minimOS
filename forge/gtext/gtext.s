; print text on arbitrary pixel boundaries
; 65C02-version
; (c) 2020-2021 Carlos J. Santisteban
; last modified 20210107-2034

; assume MAXIMUM 32x32 pixel font, bitmap VRAM layout (might be adapted to planar as well)
; supports variable width fonts!
; this code assumes Amstrad VRAM layout, but could use C64-style layout as well, just changing the y-offset LUT

; reducing MAX width to 16px dramatically improves things
#define	GW16	_GW16

; *** zero page variables ***

f_ptr	.dsb	2			; indirect pointer for font reading
v_ptr	.dsb	2			; indirect pointer for screen writing

; *** variables not necessarily in ZP ***
x_pos	.dsb	2			; 16-bit x-position, fixed-point (5b LSB first, then 8b MSB)
y_pos	.dsb	2			; 16-bit y-position, fixed-point (5b LSB first, then 8b MSB)
char	.dsb	1			; ASCII to be printed
c_wid	.dsb	1			; temporary width storage

; these are recommended to be in ZP because of performance reasons
#ifdef	GW16
mask	.dsb	3			; shiftable 16+8-bit mask for printing
scan	.dsb	3			; copy of font scanline to be shifted
#else
mask	.dsb	5			; shiftable 32+8-bit mask for printing
scan	.dsb	5			; copy of font scanline to be shifted
#endif

; *** required constants *** may be in RAM for versatilty

font	.dsb	2			; font definition start pointer
wdth	.dsb	2			; font widths pointer
vram	.dsb	2			; screen start pointer
hght	.dsb	1			; font height

; ****************************************************************************
; *** font format TBD, but is very important, especially if variable width ***
; ****************************************************************************
; for performance reasons, a highly extravagant binary is desired... even if it may take up to 32 kiB!
; planar-style storage for every scanline
; assuming i[x,y] where i is the character, x is the horizontal byte 0...3 (0 the leftmost) and y the scanline
; 0[0,0]-0[1,0]-0[2,0]-0[3,0]-1[0,0] ... 255[3,0]-0[0,1]-0[1,1]-0[2,1] ... 255[3,31] maximum
; *** could be cut in half if font is known to be up to 16 pixels wide (bytes 0...1) ***
; widths array is as simple as a 256-byte structure, in pixels
; every scanline is 1024 bytes apart (512 if 16px maximum width)
; glyph pointer is base+asc*4 (or *2)

	.text

; *** init code, before any printing ***

init:
	LDA font				; use base address for pointer
	STA f_ptr
	LDA font
; needs to fill offset tables! TO DO
	RTS						; anything else to do?

; ********************
; *** actual stuff ***
; ********************

print:
; create mask first
	LDY char				; get ASCII as index
	LDA (wdth), Y			; that character width
;	STA c_wid				; stored here, really needed?
	TAY						; this is the number of bits to insert
	CLC
	ADC x_pos				; interestingly, add *************************** this only works for up to 8-bit wide
	TAX						; how many bits must our mask be shifted? compute first!
	LDA #$FF				; set mask before rotating EEEEEEEEK
	STA mask+1				; remaining bytes in memory
	STA mask+2
#ifndef	GW16
	STA mask+3
	STA mask+4
#endif
mk_set:
		CLC					; insert a LOW bit... EEEEEK
mk_rot:
			ROR				; ...into LSB... 
			ROR mask+1		; ...and the rest
			ROR mask+2
#ifndef	GW16
			ROR mask+3		; might take up to 5 bytes
			ROR mask+4
#endif
			DEX
			DEY
			BPL mk_set		; there is one more bit to CLEAR
		CPX #0				; what happened to the shift counter instead?
		BPL mk_rot			; there is one more bit to rotate (C is known to be SET)
	STA mask				; mask is complete!
; make f_ptr point to base glyph data
	STZ f_ptr+1				; MSB of offset will be computed here
	LDA char				; multiply ASCII by 2 or 4
	ASL
	ROL f_ptr+1
#ifndef	GW16
	ASL						; in case of 32-bit width, it's 4 bytes per scanline/char
	ROL f_ptr+1
#endif
	CLC						; add base pointer
	ADC font				; LSB
	STA f_ptr
	LDA f_ptr+1				; high offset...
	ADC font+1				; ...plus high base (and possible carry)...
	STA f_ptr+1				; ...makes MSB

; must prepare base v_ptr! *** TO DO

; prepare scanline counter, fortunately X is kept all the time
	LDX #0					; worth doing forward this time
gs_loop:
; *** this must be done for every scanline ***
; copy (unshifted) scanline at 'scan'
#ifdef	GW16
		LDY #1				; will copy 2 bytes for scanline
#else
		LDY #3				; will copy 4 bytes for scanline, not sure if worth optimising further
#endif
gs_cp:
			LDA (f_ptr), Y
			STA scan, Y		; this is absolute! may not work on '816
			DEY
			BPL gs_cp
; shift scanline pretty much like the mask after inserting all bits
		LDY x_pos			; thanks to fixed-point, this is the number of bits to be shifted, extract from x coordinate otherwise *** nope
		LDA scan
gs_mr:
			LSR				; rotate right all bytes
			ROR scan+1
			ROR scan+2
#ifndef	GW16
			ROR scan+3
			ROR scan+4
#endif
			DEY
			BPL gs_mr
		STA scan			; EEEEEEEEK
; *** now read from VRAM, AND with 'mask' and OR with glyph data at 'scan'
#ifdef	GW16
		LDY #1				; will operate on 2 bytes for scanline
#else
		LDY #3				; will operate on 4 bytes for scanline, not sure if worth optimising
#endif
blit:
			LDA (v_ptr), Y	; get screen data
			AND mask, Y		; clear where the glyph goes *** note for 65816
			ORA scan, Y		; set glyph pixels *** ditto for 65816
			STA (v_ptr), Y	; update screen
			DEY
			BPL blit
; now prepare for the next scanline!
		LDA f_ptr+1			; get font pointer MSB
		CLC					; will jump to next scanline, note planar-like format
#ifdef	GW16
		ADC #2				; 512 bytes ahead
#else
		ADC #4				; 1 K ahead
#endif
		STA f_ptr+1
; ...but now must advance v_ptr too, with the help of the offset array! *** TO DO
; hopefully respects X
		INX
		CPX hght			; all scanlines done?
		BNE gs_loop
; *** *** is it all done now? *** ***

/* old code ***
	STZ f_ptr+1				; reset for temporary use
	LDA char				; get ascii
	ASL						; 16-bit rotation, three times
	ROL f_ptr+1
	ASL
	ROL f_ptr+1
	ASL
	ROL f_ptr+1
	TAY						; keep offset LSB as index (always < 248)
	LDA #>FONT				; prepare MSB too
	CLC
	ADC f_ptr+1				; add offset to base
	STA f_ptr+1
; with C64-style, VRAM offset is (x-x MOD 8)+INT(y/8)*320, thus the remaining is the pointer LSB, other layouts will differ
	LDA x_pos				; get X position again, now for the rest
	AND #248
;	CLC
;	ADC #<VRAM				; in case is not page aligned (rare)
	STA v_ptr				; still missing Y-offset
;	LDA y_pos+1				; in case Y.H is relevant
;	STA v_ptr+1
	LDA y_pos
;	ASL v_ptr+1				; if used, the following istruction is to be ROL instead
	ASL						; divide-by-eight
;	ASL v_ptr+1				; the same, three times
	ASL
;	ASL v_ptr+1
	ASL
		
s_loop:
		LDA (f_ptr), Y		; get font data
		STA scan			; put on LSB...
		STZ scan+1			; ...with clear MSB
		STZ mask			; mask is 0 where printed...
		LDA #$FF			; ...and 1 where original pixel is to be kept
		STA mask+1
		LDA x_pos			; get X position, just for the bit-offset
		AND #7
		TAX					; number of pixels to shift within byte
x_loop:
			ASL scan		; rotate font data...
			ROL scan+1
			ASL mask		; ...and mask
			ROL masl+1
			DEX
			BPL x_loop
		
*** */
