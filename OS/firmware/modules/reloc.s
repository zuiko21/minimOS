; firmware module for minimOS·65
; (c) 2018-2021 Carlos J. Santisteban
; last modified 20181210-1047

; *** relocate 65(C)02-based code and data ***
; interface TBD

#ifdef	LOWRAM
.(
; TODO TODO TODO TODO TODO
	LDY #<sysvars		; note beginning of kernel space
	LDA #>sysvars
	STY 			; store as parameter
	STA +1
; *** this section may be used for code relocation too ***
        LDY #D_DYN         ; get offset to relocation table
        LDA (da_ptr), Y
        CLC
        ADC da_ptr         ; get absolute pointer
        STA dyntab         ; use as local pointer
        LDY #0             ; reset counter
; all set, let us convert the variable references
dyd_rel:
            LDA (dyntab), Y    ; any more to convert?
                BEQ dd_end         ; no, all done
            CLC
            ADC da_ptr         ; yes, compute actual location of address
            STA tmptr          ; store temporary pointer
            LDA (tmptr)        ; this is the generic address to be converted
; generic data addresses may start at $4000 (up to 16K), while code relocation...
; ...may just start from zero, as skipping the header will provide addresses over $100
; in any case, 65xx jumps have no zeropage addressing anyway. 68xx may need...
; ...to make sure early jumps (or references) are assembled as full 16-bit.
; data relocation could start from $8000 as well, but $4000 gives it a chance to work...
; ...on unaware 32K RAM systems!
            EOR #$4000         ; *** assume generic addresses start @ $4000 and no more than 16k is used ***
            CLC
            ADC dynmem         ; the location of this driver's variables
            STA (tmptr)        ; address is corrected!
            INY                ; go for next offset (assume 16-bit indexes)
            INY
            BRA dyd_rel
dd_end:
.)
#else
	_DR_ERR(UNAVAIL)			; relocation not implemented
#endif
