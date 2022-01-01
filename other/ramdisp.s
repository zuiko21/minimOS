; display detected non-mirrored RAM on mux. display
; (c) 2020-2022 Carlos J. Santisteban
; last modified 20210220-2321

; *** integrated with ramprobe.s and ltc4622s.s ***

#define	DOWNL	_DOWNL

	.zero

	* = 2					; 6510 and NMOS-savvy

; *** ramprobe variables ***
chkptr	.dsb	2			; pointer to tested byte
chkpag	.dsb	1			; pointer for mirroring test (including next byte)
chkmsk	.dsb	1			; shift counter for new bit

; *** ramdisp variables ***
hexstr	.dsb	4			; room for 4 hex-chars
dp_str	.dsb	2			; decimal point pattern (will change)
count	.dsb	1			; delay counter

; *** display parameters, in a minimOS-savvy configuration ***

	* = $F2					; minimOS compatible string address

d_ptr	.dsb 2				; pointer to AND-mask for each bitmap (abc* on MSN only)
c_ptr	.dsb 2				; pointer to hex-string (2 char)
anode	.dsb 1				; index for selected anode
ch_i	.dsb 1				; index for read hex-char

; *** *** *** *** *** ***
	.text

#ifdef	DOWNL
	* = $400
#else
	* = $FE80
#endif

; *********************
; *** ramprobe code ***
; *********************
ramtest:
	LDX #$80				; MSB is set first
	STX chkmsk
	TXS						; also suitable for stack pointer, even on 128-byte systems (leaves 8-byte stack space)
	LDX #0
	STX chkptr				; reset pointer as well
	STX chkptr+1
	LDY #14					; this will make the code VIA-savvy (IER will be affected)
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
zpchk:
		LDA #$AA			; test pattern
		DEX					; initial value was zero, now $FF
		CPX #15				; cannot fully check down to zero, such a system would be quite useless anyway
		BNE patchk			; *** locked if no more than 8 bytes of RAM ***
; *** special code to put '--' on the display while locked ***
lock:
			LDA #%11100100	; dash on digit 1
lock_dis:
				STA $FFF0	; put it on port
lock_dp:
					INX
					BNE lock_dp	; wait for a while
				EOR #%00000101	; switch between digits
				BNE lock_dis	; no need for BRA
; *** interrupt locks will show '==' ***
irq_trap:
		LDA #%01100100		; '=' on digit 1
		BNE lock_dis		; otherwise the same 
; *** end of lock ***
patchk:
			STA 0, X		; try writing it
			CMP 0, X		; wrote OK?
			BNE zpchk		; try another if it did not
		LSR					; go for next pattern ($55 or exit)
		BCC patchk			; try both patterns
	STX chkptr				; if arrived here, X points to the highest byte (MSB expected to be zero)
; *** at this point, chkptr points to the highest addressable RAM byte, mirrored or not ***
mirror:
	INX						; EEEEEEEEEEEEEEEEEEEEEEEEK
	TXA						; if X=0, we have more than 256 bytes of RAM, thus check for page mirroring **** NOOOOO, X was $FF ****
	BNE zp_bw				; otherwise just check zeropage
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
				BEQ no_page	; if they match, there is no mirroring
			DEC chkpag+1	; otherwise try previous page
			BNE pgr_loop
;		STA chkptr+1		; now that's the real last page
; perhaps there's only zeropage mirrored elsewhere
no_page:
	LDX #$FF				; assume full page is OK
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
		CPX #15
		BNE zp_mr
zp_nm:
	STX chkpag				; non-mirrored zeropage last byte! *** instead of chkptr
; *** chkpag holds the last real address of non-mirrored RAM *** instead of chkptr

; ********************
; *** ramdisp code ***
; ********************
ramdisp:
; * convert 16-bit value into 4 hex-char *
	LDX #0					; byte index, start checking little-endian LSB...
	LDY #3					; hex-char index ...as we start at LSD, which is last
str_loop:
		LDA chkpag, X		; get this byte *** instead of chkptr, which is limit of addressable RAM
		AND #$0F			; LSN only
; might convert to ASCII here
		STA hexstr, Y		; store non-ASCII value (absolute)
		DEY
		LDA chkpag, X		; get this byte again *** not chkptr
		LSR					; MSN down x16
		LSR
		LSR
		LSR
; might convert to ASCII here
		STA hexstr, Y		; two hex-chars complete
		INX
		DEY
		BPL str_loop		; go for value MSB

; * display size in loop *
	LDY #<dp_str			; fixed pointer to DP string
	LDX #>dp_str
	STY d_ptr
	STX d_ptr+1
	LDY #<hexstr			; get pointer to highest hex-chars
;	LDX #>hexstr
	STY c_ptr
	STX c_ptr+1				; all in ZP, no need to reload MSB
	LDA #$FF				; DP is off
	STA dp_str				; first char never has it
	STA dp_str+1			; ...neither second char, this time
cyc_loop:
		LDA #200			; about 1-sec delay
		STA count
ds_loop:
			JSR display
			DEC count
			BNE ds_loop
		LDA dp_str+1		; get DP status for second char
		EOR #$10			; toggle DP
		STA dp_str+1
; toggle somehow +/-2 c_ptr!
		AND #$10			; just keep updated D4 (is zero about to show LSB)
		EOR #$10			; we need the opposite
		LSR
		LSR
		LSR					; divide-by-8 for the offset of two... and clear C!
		ADC #<hexstr		; base pointer
		STA c_ptr			; display routine parameter updated
		JMP cyc_loop		; display forever

; ************************
; *** display routines ***
; ************************
display:
	LDA #%1000				; highest anode select line
	STA anode
	LDA #1
	STA ch_i				; pointing to last character
cloop:
		LDY ch_i			; retrieve index
		LDA (c_ptr), Y		; read pointed character
		TAX					; use as bitmap index
		LDA bitmap, X		; get pattern
		AND (d_ptr), Y		; apply the mask, in case a dot is shown
		AND #$F0			; keep MSN only
		JSR disdel			; enable anode and make delay
		LDA bitmap, X		; get pattern again
; could add here AND with the mask for d...g segments, but retrieving Y index, not really worth it
		ASL					; will set LSN as MSN (mask won't apply as no DP here)
		ASL
		ASL
		ASL
		JSR disdel			; enable, store and delay
		DEC ch_i			; back to previous character
		BPL cloop
	RTS

; *** delay routine ***
disdel:
	ORA anode				; add anode selection to cathode pattern
	STA $FFF0				; set output port
dl_loop:
		INY
		BNE dl_loop			; about 1.3 ms delay
	LSR anode				; enable next anode, non decoded version
	RTS

; *** bitmap ***
; being cathodes, 0 means ON
bitmap:
;			 abc*defg
	.byt	%00010001		; 0
	.byt	%10011111		; 1
	.byt	%00110010		; 2
	.byt	%00010110		; 3
	.byt	%10011100		; 4
	.byt	%01010100		; 5
	.byt	%01010000		; 6
	.byt	%00011111		; 7
	.byt	%00010000		; 8
	.byt	%00011100		; 9
	.byt	%00011000		; A
	.byt	%11010000		; B
	.byt	%01110001		; C
	.byt	%10010010		; D
	.byt	%01110000		; E
	.byt	%01111000		; F
;	.byt	$FF				; special blank value (16)

; *** *** *** *** *** ***
#ifndef	DOWNL
	.dsb	$FFFA-*, $FF	; ROM filling

; *** hardware vectors ***
vectors:
	.word	irq_trap
	.word	ramtest
	.word	irq_trap		; all interrupts show '=='
#endif
