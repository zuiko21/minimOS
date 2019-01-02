; firmware module for minimOS·65
; (c) 2018-2019 Carlos J. Santisteban
; last modified 20180319-0955

; ********************************
; SET_NMI, set NMI handler routine
; ********************************
; might check whether the pointed code starts with the magic string
; no need to disable interrupts as a partially set pointer would be rejected...
; ...unless SAFE is not selected (will not check upon NMI)
; will use CRITIC section as will save register sizes as well
;	INPUT
; ex_pt		= pointer to ISR
;	OUTPUT
; ex_pt		= currently set pointer (if was NULL at input)
; sizes irrelevant!
; routine ending in RTS, regs already saved, but MUST respect sys_sp in case a 816 kernel uses it!!!

-set_nmi:
.(
	LDA ex_pt+1			; get MSB (3)
		BEQ fw_r_nmi		; read instead (2/3)
#ifdef	SAFE
	LDY #0				; offset for NMI code pointer (2)
	LDA (ex_pt), Y		; get code byte (5) not worth CMOS indirect
	CMP #'U'			; match? (2)
		BNE fw_nerr			; not a valid routine (2/3)
	INY					; another byte (2)
	LDA (ex_pt), Y		; get code byte (5)
	CMP #'N'			; match? (2)
		BNE fw_nerr			; not a valid routine (2/3)
	INY					; another byte (2)
	LDA (ex_pt), Y		; get code byte (5)
	CMP #'j'			; match? (2)
		BNE fw_nerr			; not a valid routine (2/3)
	INY					; another byte (2)
	LDA (ex_pt), Y		; get code byte (5)
	CMP #'*'			; match? (2)
		BNE fw_nerr			; not a valid routine (2/3)
#endif
	LDY ex_pt			; get LSB (3)
	STY fw_nmi			; store for firmware (4+4)
	STA fw_nmi+1
	_DR_OK				; done (8)
fw_r_nmi:
	LDY fw_nmi			; get current if read (4+4)
	LDA fw_nmi+1
	STY ex_pt			; store result (3+3)
	STA ex_pt+1
	_DR_OK
fw_nerr:
	_DR_ERR(CORRUPT)	; invalid magic string!
.)
