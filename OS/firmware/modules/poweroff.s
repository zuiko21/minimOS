; firmware module for minimOS·65
; (c) 2018 Carlos J. Santisteban
; last modified 20181222-2203

; *****************************************
; POWEROFF, resets and interrupt invocation
; *****************************************
;	INPUT
; Y <- mode (0 = suspend, 2 = warmboot, 4 = coldboot, 6 = poweroff, 8 = cleanly shutted down, 10 = NMI, 12 = BRK)
;	OUTPUT
; C -> not implemented
; NMOS savvy
; this must be further modularised

-poweroff:
.(
	TYA					; get subfunction offset
	TAX					; use as index
	_JMPX(fwp_func)		; select from jump table
; *** power handlers ***
; power off
fwp_off:
	.byt	$DB			; STP in case a WDC CPU is used
	NOP					; avoid DCP abs,Y on NMOS
	NOP
	_PANIC("{OFF}")		; stop execution! just in case is handled
; suspend
fwp_susp:
#ifndef	NMOS
	_CRITIC				; disable interrupts...
; first shut off interrupt sources! *** only useful with WDC CPUs ***
	LDA VIA_J + IER		; get current interrupt sources
	PHA					; save for later (with bit 7 high)
	AND #$7F			; turn bit 7 low
	STA VIA_J + IER		; this will disable every enabled interrupt source
	.byt	$CB			; WAI in case of WDC CPU, NOP otherwise
; *** system expected to be suspended here ***
	NOP					; # not used on other CMOS, but helpful anyway
; after waking up, reenable interrupt sources!
	PLA					; get saved config (with bit 7 high)
	STA VIA_J + IER		; this will enable every previously set interrupt source
	_NO_CRIT			; ...and back to business
#else
; should an NMOS device had an actual powerdown feature, use it here!
	_DR_ERR(UNAVAIL)	; avoid AXS# on NMOS
#endif
; this is also the exit for software interrupt simulation
fwp_end:
	_DR_OK				; for NMI call eeeek
; *** interrupt simulators ***
fwp_nmi:
	LDY #<fwp_end		; get correct return address
	LDA #>fwp_end
	PHA					; stack it in order
	_PHY
	PHP					; will end in RTI
	JMP nmi				; handle as usual
fwp_brk:
; this is a special case, as will be called from IRQ ISR with full state already on stack!
; will just forget the return address and just let nmi_end return to caller
	JMP (fw_dbg)
; sub-function jump table
fwp_func:
; regular shutdown commands
	.word	fwp_susp	; suspend	+FW_STAT
	.word	start_kernel	; shouldn't use this, just in case
	.word	reset		; coldboot	+FW_COLD
	.word	fwp_off		; poweroff	+FW_OFF
; scheduler second phase handler
	.word	fwp_nmi		; PW_CLEAN is not allowed here!
; must include BRK/NMI invocation codes
	.word	fwp_nmi		; simulated NMI
	.word	fwp_brk		; execute BRK handler
.)
