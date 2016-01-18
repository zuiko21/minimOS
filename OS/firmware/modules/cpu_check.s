; firmware CPU determining code for minimOS
; version 0.9b1
; (c) 2015-2016 Carlos J. Santisteban
; essentially from the work of David Empson, Oct. '94
; last modified 20150622-1235
; revised 20160115 for commit

	LDY #$00			; by default, NMOS 6502
	SED					; decimal mode
	LDA #$99			; load highest BCD number
	CLC					; prepare to add
	ADC #$01			; will wrap around in Decimal mode
	CLD					; back to binary
		BMI cpuck_set		; NMOS, N flag not affected by decimal add
	LDY #$03			; let's assume now '816
	LDX #$00			; sets Z temporarily
	TYX					; 65802 instruction will clear Z, NOP on all 65C02s won't
		BNE cpuck_set		; Branch only on 65802/816
	LDX $EA				; save contents of $EA, really needed???
	DEY					; try now with Rockwell
	STY $EA				; store '2' there
	RMB1 $EA			; Rockwell R65C02 instruction
	CPY $EA				; Location $EA unaffected on other 65C02
	STX $EA				; restore contents, really needed???
		BNE cpuck_set		; Branch only on Rockwell R65C02 (test CPY)
	DEY					; revert to generic 65C02
		BRA cpuck_set		; It's some form of 65C02, thus BRA is available
cpuck_list:
	.asc	"NBRV"		; codes for NMOS (N), generic CMOS (B), Rockwell 65C02 (R?) and 65816/65802 (V)
cpuck_set:
	LDA cpuck_list, Y	; get proper code from investigation
	STA fw_cpu			; store in variable ** firmware standard label

