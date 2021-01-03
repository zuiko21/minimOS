; firmware module for minimOS·16
; (c) 2019-2021 Carlos J. Santisteban
; last modified 20181210-1344

; *** relocate 65816-based code and data ***
; ex_rlc <- code start address (24b) including bank at bnk_rl (+2)
; sv_rlc <- data start address, usually for kernel/drivers only (16b)
; ex_tab <- pointer (24b) to relocatable code offsets (16b) will be modified
; sv_tab <- pointer (24b) to relocatable data offsets (16b) as local, make it point to NUL-NUL if not used!
; bn_tab <- pointer (24b) to relocatable bank offsets (16b) as local, make it point to NUL-NUL if not used!

#ifdef	LOWRAM
.(
	.al: REP #$20		; save a couple bytes by going 16-bit again
; must check THREE relocation tables: code (all), data (usually kernels & drivers only) and banks (for 65816)
; do NOT check headers here!! use ZP parameters, some of them passed as locals!
	PHB					; must save DBR anyway
; try some loop for the three tables...
	LDX #8				; index assumes parameters are bn_tab, sv_tab @+4 and ex_tab @+8
; ............................................


; non-looped version, first relocate code addresses
; could just use [dyntab] and load that vector from bn_tab, X among other changes
	LDY #0				; reset table offset
rl_xl:
		LDA [ex_tab], Y		; get entry from table
			BEQ rl_xx			; end of table, go away
		STA tmptr			; add another indirection!
		LDA (tmptr)			; assume data bank set
;		EOR $4000			; could just use a mask
		CLC
		ADC ex_rlc			; compute as offset from base address
		STA (tmptr)			; store modified reference
		INY					; go for next entry
		INY
		BNE rl_xl			; safer than bra, 128-entry limit, though
rl_xx:
	LDY #0				; reset table offset
rl_vl:
		LDA [sv_tab], Y		; get entry from table
			BEQ rl_vx			; end of table, go away
		STA tmptr			; add another indirection!
		LDA (tmptr)			; assume data bank set (as zero!)
		EOR $4000			; these are data addresses! (only difference)
		CLC
		ADC sv_rlc			; compute as offset from base address
		STA (tmptr)			; store modified reference
		INY					; go for next entry
		INY
		BNE rl_vl			; safer than bra, 128-entry limit, though
rl_vx:
; 65816-only code follows
	LDY #0				; reset table offset
rl_bl:
		LDA [bn_tab], Y		; get entry from table
			BEQ rl_bx			; end of table, go away
		STA tmptr			; add another indirection!
		.as: SEP #$20		; following op in 8-bit mode!
		LDA (tmptr)			; assume data bank set
		CLC
		ADC ex_rlc			; compute as offset from base address
		STA (tmptr)			; store modified reference
		.al: REP #$20		; back to 16-bit for table offsets
		INY					; go for next entry
		INY
		BNE rl_bl			; safer than bra, 128-entry limit, though
rl_bx:



tab_l:
		LDA bn_tab, X		; get table base (assume order above!)
		PHA					; into stack! will use (stack, S), Y mode
		LDY bn_tab+2, X		; bank for the above...
		PHY					; ...will be set...
		PLB					; ...as default data bank!
; all set in order to scan the table as (stack, 1), Y
		LDA ex_pt			; get code location...
		STA dynmem			; is the first 

		SEC
		SBC #256			; ...minus one page...
		STA rtab_pt			; ...and set as local header pointer
		LDY #REL_TAB		; offset for the first relocation table in headers
	rl_tab:
			LDA (rtab_pt), Y	; get this table offset
			CLC
			ADC ex_pt			; get initial address
			STA dyntab			; use as local pointer
			PHY					; save for next table!
	; relocate all references from current table
			LDY #0				; reset counter
	; all set, let us convert the references
	dyd_rel:
				LDA (dyntab), Y		; any more to convert?
					BEQ dd_end			; no, all done
				CLC
				ADC ex_pt			; yes, compute actual location of address
				STA tmptr			; store temporary pointer
				LDA (tmptr)			; this is the generic address to be converted
				EOR rl_mask			; will be $4000 for data and 0 otherwise!
				CLC
				ADC dynmem			; the destination of these references
				STA (tmptr)			; address is corrected!
				INY					; go for next offset (assume 16-bit indexes)
				INY
				BRA dyd_rel
	dd_end:
.)
#else
	_DR_ERR(UNAVAIL)			; relocation not implemented
#endif
