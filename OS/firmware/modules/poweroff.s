; firmware module for minimOS·65
; (c) 2018-2019 Carlos J. Santisteban
; last modified 20190111-2318

; *****************************************
; POWEROFF, resets and interrupt invocation
; *****************************************
;	INPUT
; Y <- mode	(0 = suspend, 2 = warmboot, 4 = coldboot, 6 = poweroff,
;			8 = cleanly shut down, 10 = NMI simulation, 12 = IRQ simulation)
;	OUTPUT
; C -> not implemented
; NMOS savvy
; this must be further modularised

-poweroff:
.(
	TYA					; get subfunction offset
	TAX					; use as index
clc:adc#'0':jsr$c0c2
	_JMPX(fwp_func)		; select from jump table

; **********************
; *** power handlers ***
; **********************

; *** power off ***
fwp_off:
;	.byt	$DB			; STP in case a WDC CPU is used
	ORA #0					; avoid DCP abs,Y on NMOS
	_PANIC("{OFF}")		; stop execution, if ever arrives here!

; *** suspend ***
fwp_susp:
lda#'s':jsr$c0c2
	LDA fw_cpu			; get current CPU type
	CMP #'N'			; is it NMOS?
	BNE fwp_stat			; if not, cannot be suspended!
; should an NMOS device had an actual powerdown feature, use it here!
		_DR_ERR(UNAVAIL)	; avoid AXS# on NMOS
fwp_stat:
lda#'h':jsr$c0c2
	_CRITIC				; disable interrupts...
; first shut off interrupt sources! *** only useful with WDC CPUs ***
	LDA VIA_J + IER		; get current interrupt sources
	PHA					; save for later (with bit 7 high)
	AND #$7F			; turn bit 7 low
	STA VIA_J + IER		; this will disable every enabled interrupt source
;	.byt	$CB			; WAI in case of WDC CPU, NOP otherwise
; *** systems with hardware suspend should enable it here!
	NOP					; # not used on other CMOS, but helpful anyway
; after waking up, reenable interrupt sources!
	PLA					; get saved config (with bit 7 high)
	STA VIA_J + IER		; this will enable every previously set interrupt source
	_NO_CRIT			; ...and back to business
; this is also the exit for software interrupt simulation
fwp_end:
	_DR_OK				; for NMI call eeeek

; *** interrupt simulators ***
; these must be properly handled. BRK simulation makes no sense!
; despite both FW vectors being together, should NOT unify these chunks as JMP nmi is
; MUCH safer than JMP (fw_nmi), plus state must be saved anyway.
fwp_nmi:
lda#'N':jsr$c0c2
	LDY #<fwp_end		; get correct return address
	LDA #>fwp_end
	PHA					; stack it in order
	_PHY
	PHP					; will end in RTI
	JMP nmi				; handle as usual (standard label)
; note that register values will make no sense on debuggers
fwp_irq:
lda#'I':jsr$c0c2
	LDY #<fwp_end		; get correct return address
	LDA #>fwp_end
	PHA					; stack it in order
	_PHY
	PHP					; will end in RTI
	JMP (fw_isr)				; handle installed ISR as usual

; *******************************
; *** sub-function jump table ***
; *******************************
fwp_func:
; regular shutdown commands
	.word	fwp_susp	; suspend	+FW_STAT
	.word	start_kernel	; shouldn't use this, just in case
	.word	reset		; coldboot	+FW_COLD
	.word	fwp_off		; poweroff	+FW_OFF
; scheduler second phase handler
	.word	fwp_nmi		; PW_CLEAN is not allowed here!
; must include IRQ/NMI invocation codes
	.word	fwp_nmi		; simulated NMI
	.word	fwp_irq		; simulated IRQ
.)
