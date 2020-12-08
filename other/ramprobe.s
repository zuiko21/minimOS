; *** RAM probe for 65(C)02 v2       ***
; *** (c) 2020 Carlos J. Santisteban ***
; *** last modified 20201208-1635    ***

	.zero
; *** zeropage declarations ***

	* = 2					; 6510-savvy

chkptr	.dsb	2			; pointer to tested byte
chkpag	.dsb	1			; pointer for mirroring test (including next byte)
chkmsk	.dsb	1			; shift counter for new bit


	.text
; *******************
; *** actual code ***
; *******************

	* = $FF80

ramtest:
	LDA #$80				; MSB is set first
	STA chkmsk
	LDX #0
	STX chkptr				; reset pointer as well
	STX chkptr+1
	LDY #4					; this will make the code VIA-savvy (T1 counter will be affected)
try:
		LDA chkptr+1		; get current value...
		ORA chkmsk			; ...and add suggested bit
		STA chkptr+1
		LDA #$AA			; test pattern
bytchk:
			STA (chkptr), Y	; try writing it
			CMP (chkptr), Y	; wrote OK?
				BNE bad		; abort loop if it did not
			LSR				; go for next pattern ($55 or exit)
			BCC bytchk		; try both patterns
		BCS good			; that byte is OK, thus try to add another (less significant) bit
bad:
; the proposed bit goes beyond addressable RAM and must be removed
			LDA chkmsk		; offending bit
			EOR #$FF		; mask for removing
			AND chkptr+1	; previous pointer minus offending bit
			STA chkptr+1	; now back to a safe location, may try a lower bit
good:
		LSR chkmsk			; try a lower bit now
		BCC try
; chkptr+1 is the highest addressable RAM page (mirrored or not)
	LDX chkptr+1			; more than 256 bytes?
	BNE mirror				; as expected, investigate mirroring
; here we have no more than 256 bytes of RAM, thus check them all
zpchk:
		LDA #$AA			; test pattern
		DEX					; initial value was zero, now $FF
		CPX #7				; cannot fully check down to zero, such a system would be quite useless anyway
		BEQ *				; *** locked (no more than 8 bytes of RAM) ***
patchk:
			STA 0, X		; try writing it
			CMP 0, X		; wrote OK?
				BNE zpchk	; try another if it did not
			LSR				; go for next pattern ($55 or exit)
			BCC patchk		; try both patterns
		STX chkptr			; if arrived here, X points to the highest byte (MSB expected to be zero)
; *** at this point, chkptr points to the highest addressable RAM byte, mirrored or not ***
mirror:
	TXA						; if X=0, we have more than 256 bytes of RAM, thus check for page mirroring
	BNE no_page				; otherwise just check zeropage
; check pages for mirroring *** first write page number on every available page
		STX chkpag			; (re)set pointers, it was zero
		LDA chkptr+1
		STA chkpag+1
pgw_loop:
			LDA chkpag+1	; reload page number
			STA (chkpag), Y	; store page number
			DEC chkpag+1	; previous page
			BNE pgw_loop
		TXA					; write a zero...
		STA (chkpag), Y		; on what should be chkpag @ zeropage, in case it's mirrored!
; now have a look at the stored values, whether they're read at their respective pages
		LDA chkptr+1		; let's scan pages again
		STA chkpag+1
pgr_loop:
			LDA chkpag+1	; reload page number
			CMP (chkpag), Y	; compare with stored page number
				BEQ pg_found	; if they match, there is no mirroring
			DEC chkpag+1	; otherwise try previous page
			BNE pgr_loop
; if arrived here, there's only zeropage mirrored elsewhere
no_page:
	STA chkptr+1			; now that's the real last byte
zp_bw:
		TXA					; reload byte number
		STA 0, X			; try to store it
		DEX					; previous byte
		CPX #7				; do not touch first 8 bytes
		BNE zp_bw
	LDX chkptr				; retrieve stored count
zp_mr:
		TXA					; there should be the byte number itself
		CMP 0, X			; matches read value?
			BEQ zp_nm		; found highest real byte!
		DEX					; or try previous byte, as usual
		CPX #1
		BNE zp_mr
zp_nm:
 	STX chkptr				; non-mirrored zeropage last byte!
; *** chkptr holds the last real address of non-mirrored RAM ***
