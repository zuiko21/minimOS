; firmware module for minimOS·16
; (c)2018 Carlos J. Santisteban
; last modified 20180122-1047

; ********************************
; SET_NMI, set NMI handler routine
; ********************************
; might check whether the pointed code starts with the magic string
; no need to disable interrupts as a partially set pointer would be rejected...
; ...unless SAFE is not selected (will not check upon NMI)
; will use CRITIC section as will save register sizes as well
;	INPUT
; ex_pt		= pointer to ISR (24b)
;	OUTPUT
; ex_pt		= currently set pointer (if was NULL at input)
; sizes irrelevant!
; routine ending in *RTL* (RTS is valid in bank zero, id est, 6502 code), regs already saved, but MUST respect sys_sp

set_nmi:
	_CRITIC				; will preserve sizes (5)
	.al: REP #$20		; ** 16b memory, 8b index ** (3+3)
	.xs: SEP #$10

#ifdef	SUPPORT
	LDX run_arch		; from 8-bit code? (4)
	BEQ fw_sn24b			; no, bank already set (3/2)
		STZ kerntab+2		; yes, assume it is bank zero (4)
fw_sn24b:
#endif

	LDA kerntab+1		; get MSB+bank (4)
		BEQ fw_r_nmi		; zero means read instead (2/3)

#ifdef	SAFE
	LDA [kerntab]		; get first word (7)
	CMP #'U'+256*'N'	; correct? (3)
		BNE fw_nerr			; not a valid routine (2/3)
	LDY #2				; point to second word (2)
	LDA [kerntab], Y	; get that (7)
	CMP #'j'+256*'*'	; correct? (3)
		BNE fw_nerr			; not a valid routine (2/3)
#endif

	LDY kerntab			; get LSB (3)
	STY fw_nmi			; store for firmware (4)
	STA fw_nmi+1		; includes MSB + bank (5)
	_DR_OK				; done (8)
fw_r_nmi:
	LDY fw_nmi			; get current if read (4+5)
	LDA fw_nmi+1
	STY kerntab			; store result (3+4)
	STA kerntab+1
	_NO_CRIT			; restore sizes
	_DR_OK
fw_nerr:
	_NO_CRIT			; restore sizes too
	_DR_ERR(CORRUPT)	; invalid magic string!

	.as: .xs			; just in case...
