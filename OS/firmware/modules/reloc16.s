; firmware module for minimOS·16
; (c) 2018 Carlos J. Santisteban
; last modified 20181210-1237

; *** relocate 65816-based code and data ***
; interface TBD
; ex_rlc <- code start address (24b) including bank at bnk_rl (+2)
; sv_rlc <- data start address, usually for kernel/drivers only (16b)
; rl_tab <- pointer to list of offsets (might point to ...

#ifdef	LOWRAM
.(
	.al: REP #$20		; save a couple bytes by going 16-bit again
; must check THREE relocation tables: code (all), data (usually kernels & drivers only) and banks (for 65816)
; do NOT check headers here!!! use ZP parameters
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
			EOR d_mask			; will be $4000 for data and 0 otherwise!
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
