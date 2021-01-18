; print text on arbitrary pixel boundaries
; 65(C)02-version
; (c) 2020-2021 Carlos J. Santisteban
; last modified 20210118-1102

; assume MAXIMUM 32x32 pixel font, bitmap VRAM layout (might be adapted to planar as well)
; supports variable width fonts!
; this code assumes Amstrad VRAM layout, but could use C64-style layout as well, just changing the y-offset LUT

#ifndef	HEADERS
#include "../../OS/macros.h"
#endif

; *** configuration options ***

; reducing MAX width to 16px dramatically improves things
#define	GW16	_GW16

; adds extra code for planar colour screens
#define	PLANAR	_PLANAR 

#ifdef	GW16
#define	MSKSIZ	3
#else
#define	MSKSIZ	5
#endif

	.zero

; *** zero page variables ***

f_ptr	.dsb	2			; indirect pointer for font reading
v_ptr	.dsb	2			; indirect pointer for screen writing

; *** required pointers *** parameters to be set by init or when selecting a font

font	.dsb	2			; font definition start pointer
wdth	.dsb	2			; font widths pointer
vram	.dsb	2			; screen start pointer

; these are recommended to be in ZP because of performance reasons
mask	.dsb	MSKSIZ		; shiftable 32 (or 16)+8-bit mask for printing
scan	.dsb	MSKSIZ		; copy of font scanline to be shifted

#ifdef	PLANAR
imsk	.dsb	MSKSIZ		; inverted versions of the above
iscn	.dsb	MSKSIZ
fg		.dsb	1			; foreground and background colours (may be read elsewhere)
bg		.dsb	1

nplan	.dsb	1			; max plane number *** set at init or screen switch
#endif

l_byt	.dsb	1			; last font byte for each scanline (number of bytes minus 1)
l_msk	.dsb	1			; last mask byte for each scanline (number of bytes minus 1, usually l_byt+1 but not always)

; *** variables not necessarily in ZP ***
; actual printing parameters, to be set every character!
x_pos	.dsb	2			; 16-bit x-position, fixed-point (5b LSB first, then 8b MSB)
; that MUST be equalized so the "low" part is 3b ONLY, incrementing column as needed
; systems with "wide" hardware chars (e.g. SIXtation) would take that into account when computing addresses
y_pos	.dsb	2			; 16-bit y-position, fixed-point (5b LSB first, then 8b MSB)
char	.dsb	1			; ASCII to be printed

hght	.dsb	1			; font height *** to be set at font change, no big deal on performance

; offset tables are to be generated at init or screen resizing
off_l	.dsb	64			; LSB of offsets for twice the max scanlines
off_h	.dsb	64			; MSB of the above

; table of bitplane combinations for quick jump *** for every character, as it may change colours, no advantage in ZP as is indexed
optab	.dsb	16			; 2*number of planes
 
; local variables
count	.dsb	1			; RAM variable for loops, allowing free use of X

; ****************************************************************************
; *** font format TBD, but is very important, especially if variable width ***
; ****************************************************************************
; for performance reasons, a highly extravagant binary is desired... even if it may take up to 32.25 kiB!
; planar-style storage for every scanline
; assuming i[x,y] where i is the character, x is the horizontal byte 0...3 (0 the leftmost) and y the scanline
; 0[0,0]-0[1,0]-0[2,0]-0[3,0]-1[0,0] ... 255[3,0]-0[0,1]-0[1,1]-0[2,1] ... 255[3,31] maximum
; *** could be cut in half if font is known to be up to 16 pixels wide (bytes 0...1) ***
; widths array is as simple as a 256-byte structure, in pixels (minus one!)
; every scanline is 1024 bytes apart (512 if 16px maximum width)
; glyph pointer is base+asc*4 (or *2)

	.text

; *** init code, before any printing ***

init:
; must load 'font', 'wdth' with font data, also 'hght' and 'vram'
; needs to fill offset tables! *** TO DO
	RTS						; anything else to do?

; ********************
; *** actual stuff *** give or take, worst case is ~t
; ********************

print:
; first thing should be to equalise the coordinates...
; *** perhaps systems with wide chars should do an 11-bit shift left on x_pos+1 ***
	LDA x_pos				; get original coordinate (3)
	AND #7					; extract intra-byte offset (2)
; perhaps shifting that would make a REAL fixed-point coordinate...
	TAX						; keep for later (2)
	LDA x_pos				; retrieve original, faster if in ZP (3)
	LSR						; divide by 8 (2+2+2+2)
	LSR
	LSR
	CLC
	ADC x_pos+1				; use long offset as address increment *** check above *** (3+3)
	STA x_pos+1
	STX x_pos				; and let LSB with minimal offset (3)
; determine sizes
	LDY char				; get ASCII as index (3)
	LDA (wdth), Y			; that character width (5)
	TAY						; this is the number of bits to insert (2)
	LSR						; how many bytes does it take? divide by 8! (2+2+2)
	LSR
	LSR
	STA l_byt				; store for later (glyph scanline size) (3+2+2)
	TYA						; retrieve original bit-width value
	CLC
	ADC x_pos				; interestingly, add offset for mask positioning (already equalised) (3)
	TAX						; how many bits must our mask be shifted? compute first! (2)
	LSR						; how many bytes does it take? divide by 8! (2+2+2)
	LSR
	LSR
	STA l_msk				; store for later (last byte of mask) (3)
; create mask of appropriate width
; *** current is 22/30b, 350/1012t for w16/w32 unshifted (X=Y=15/31) ***
	LDA #$FF				; set mask before rotating EEEEEEEEK (2)
	STA mask+1				; remaining bytes in memory (3+3)
	STA mask+2
#ifndef	GW16
	STA mask+3				; (3+3)
	STA mask+4
#endif
mk_set:
		CLC					; insert a LOW bit... EEEEEK (2)*w
mk_rot:
; not sure if worth optimising
			ROR				; ...into LSB... (2)*(w+o)
			ROR mask+1		; ...and the rest (5+5)*(w+o)
			ROR mask+2
#ifndef	GW16
			ROR mask+3		; might take up to 5 bytes (5+5)*(w+o)
			ROR mask+4
#endif
			DEX
			DEY
			BPL mk_set		; there is one more bit to CLEAR (2+2+3')*?
		CPX #0				; what happened to the shift counter instead?
		BPL mk_rot			; there is one more bit to rotate (C is known to be SET)
	STA mask				; mask is complete!
; that was for bitmaps, in case of a planar screen add the following
#ifdef	PLANAR
	LDY l_msk
im_l:
		LDA mask, Y
		EOR #$FF
		STA imsk, Y			; create inverted (shifted) mask
		DEY
		BPL im_l
#endif
; make f_ptr point to base glyph data
	_STZA f_ptr+1			; MSB of offset will be computed here
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
#ifdef	PLANAR
; create a combo index array for bitplane selection depending on colours!
; %00000fb0 for every plane, to be set before any scanline
	LDA bg					; background colour...
	STA scan				; ...temporarily stored
	LDA fg					; ditto for foreground colour
	STA scan+1
	LDX nplan				; number of planes minus one
p_opt:
		ASL scan+1			; shift FG
		ROL					; into A
		ASL scan			; also with BG
		ROL
		AND #3				; just two bytes
		ASL					; make it index!
		STA optab, X		; create entry *** check orientation
		DEX
		BPL p_opt			; eeeeeeek
#endif
; *** performance evaluation, s=scanlines, b=scan top byte, m=mask top, o=offset ***
; prepare scanline counter
	LDX hght				; worth doing forward this time -- WHY? (3) [grand total from here is ]
	STX count				; will be down to zero, as is total number of scanlines (3)
gs_loop:
; ********************************************
; *** this must be done for every scanline ***
; ********************************************
; copy (unshifted) scanline at 'scan' [takes up to ]
		LDY l_byt			; get bytes to be copied (n-1)
gs_cp:
			LDA (f_ptr), Y
			STA scan, Y		; this is absolute! may not work on '816 (5+5+2+3')*s*b
			DEY
			BPL gs_cp
; shift scanline pretty much like the mask after inserting all bits [takes up to ]
		LDY x_pos			; thanks to now equalised fixed-point, this is the number of bits to be shifted (3+3)*s
		BEQ v_draw			; EEEEEEEEEEEK
;		LDA scan			; should be already in A!
gs_mr:
			LSR				; rotate right all bytes (2+5+5)*s*o
			ROR scan+1
			ROR scan+2
#ifndef	GW16
			ROR scan+3		; (add 5+5)*s*o
			ROR scan+4
#endif
			DEY				; (2+3')*s*o
			BPL gs_mr
		STA scan			; EEEEEEEEK (3)*s
; that was for bitmaps, in case of a planar screen add the following
#ifdef	PLANAR
	LDY l_msk
is_l:
		LDA scan, Y
		EOR #$FF
		AND imsk, Y			; eeek^2
		STA iscn, Y			; create inverted (rotated and masked!) scanline
		DEY
		BPL is_l
#endif
; *** now read from VRAM, AND with 'mask' and OR with glyph data at 'scan' [takes up to 3104t]
v_draw:
		LDY l_msk			; get last byte for drawing!
vd_init:
#ifdef	PLANAR
; *** some init is needed before entering the blit loop *** TO DO *** TO DO
; essentially a plane counter, perhaps having previously created a combo index array!
; %00000fb0 for every plane, to be set before any character
; loop should use X, the scanline counter may be back to variable as matters little performance-wise
		LDX nplan			; going backwards? check generation!
#endif
blit:
; this is for a bitmapped B/W screen
; in case of planar screens, the ORA op will change according to the fg & bg bits
; if both are 0, do nothing (skip the ORA, actually)
; if only bg is 1, ORA iscn, Y -- which is an (INVERTED copy of shifted *scan*) AND mask
; if only fg is 1, proceed normally
; if both are 1, ORA imsk, Y -- which is an INVERTED copy of the ORIGINAL mask, before applying glyph!
#ifdef	PLANAR
; let's try something
; *** preset plane! *** TBD TBD TBD
			LDA optab, X	; get pointer to appropriate op for that bit combo
			_PHX			; eeeeek! no good for speed
			TAX				; ready for indexing
#endif
			LDA (v_ptr), Y	; get screen data (5)*s*b
			AND mask, Y		; clear where the glyph goes *** note for 65816 (4)*s*b
#ifdef	PLANAR
			_JMPX(vd_op)	; do as appropriate *** very bad on NMOS
; ****************************************
; *** *** operations pointer table *** ***
; ****************************************
vd_op:
				.word	vd_plan	; %00 = skip ORA (clears place)
				.word	vd_inv	; %01 = place inverted scan
				.word	vd_ora	; %10 = normal operation
				.word	vd_set	; %11 = set inverted mask
; **************************************
; *** *** alternative operations *** ***
; **************************************
vd_inv:
			ORA iscn, Y		; set inverted glyph bits *** ditto for 65816
			_BRA vd_plan
vd_set:
			ORA imsk, Y		; set all bits *** ditto for 65816
			_BRA vd_plan
#endif
; ***********************************************************
; *** *** this op is to be changed for planar screens *** ***
; ***********************************************************
; alternatively, jump to SMC opcode and then back after here (or a JMP ind with current routines)
vd_ora:
			ORA scan, Y		; set glyph pixels *** ditto for 65816 (4)*s*b
vd_plan:
; *** *** actually asking for Self-Modifying Code...  *** ***
			STA (v_ptr), Y	; update screen (6+2+3')*s*b
#ifdef	PLANAR
; loop for every plane
			_PLX			; eeeeeek! no good
			DEX
			BPL blit
#endif
			DEY
			BPL vd_init		; in case of planar-like init, otherwise same as blit
; now prepare for the next scanline! [up to 1439t, including all overhead except mask creation]
		LDA f_ptr+1			; get font pointer MSB (3)*s
		CLC					; will jump to next scanline, note planar-like format (2)*s
		ADC l_byt			; advance 512 or 1K *** CHECK
		STA f_ptr+1			; (3)*s
; ...but now must advance v_ptr too, with the help of the offset array! *** check relative reference
		LDY y_pos			; get this part of the coordinate (no need to equalise this) (3+3+2)*s
		LDA v_ptr
		CLC
		ADC off_l, Y		; add from offset table *** careful with 65816! (4+3)*s
		STA v_ptr
		LDA v_ptr+1			; ditto for MSB (3+4+3)*s
		ADC off_h, Y
		STA v_ptr+1
; X was free anyway, just count remaining scanlines
		DEC count			; all scanlines done? (5+3')*s
		BNE gs_loop
; *** *** is it all done now? *** ***
	_DR_OK
