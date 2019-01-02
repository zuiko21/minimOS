; firmware module for minimOS·16
; (c) 2018-2019 Carlos J. Santisteban
; last modified 20180129-1328

; *****************************************
; POWEROFF, resets and interrupt invocation
; *****************************************
;	INPUT
; Y <- mode (0 = suspend, 2 = warmboot, 4 = coldboot, 6 = poweroff, 8 = cleanly shutted down, 10 = NMI, 12 = BRK)
;	OUTPUT
; C -> not implemented
; this must be further modularised

-poweroff:
.(
	_CRITIC				; save sizes eeeeeeeeek
	.as: .xs: SEP #$30	; *** all 8-bit ***
	TYX					; get subfunction offset as index
	JMP (fwp_func, X)	; select from jump table
fwp_off:
; include here shutdown code
	STP					; $DB in case a WDC CPU is used
	_PANIC("{OFF}")		; just in case is handled
fwp_susp:
; first shut off interrupts!
	LDA VIA_J + IER		; get current interrupt sources
	PHA					; save for later (with bit 7 high)
	AND #$7F			; turn bit 7 low
	STA VIA_J + IER		; this will disable every enabled interrupt source
; in case a WDC CPU is used, apply SEI/WAI sequence (SEI already done)
	WAI					; $CB, wait for some interrupt
; *** system expected to be suspended here ***
; after waking up, reenable interrupt sources!
	PLA					; get saved config (with bit 7 high)
	STA VIA_J + IER		; this will enable every previously set interrupt source
; this is also the exit for software interrupt simulation
fwp_end:
	_NO_CRIT			; restore sizes
	_DR_OK				; just continue execution
; software interrupt calls
fwp_nmi:
	PHK					; always in bank 0
	PEA fwp_end			; push correct return
	PHP					; will end in RTI
	JMP nmi				; handle as usual *** standard template label
fwp_brk:
	PHK					; always in bank 0
	PEA fwp_end			; push correct return
	PHP					; will end in RTI
	JMP brk_hndl		; handle as usual *** standard template label

; sub-function jump table (eeeek)
fwp_func:
	.word	fwp_susp	; suspend	+FW_STAT
	.word	start_kernel	; should not use this, just in case *** standard template label
	.word	reset		; coldboot	+FW_COLD
	.word	fwp_off		; poweroff	+FW_OFF
; might include here the BRK/NMI invocation codes
	.word	fwp_nmi		; PW_CLEAN not allowed here!
	.word	fwp_nmi		; simulate NMI
	.word	fwp_brk		; execute BRK, not sure if needed
.)
