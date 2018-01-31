; firmware module for minimOS·65
; (c) 2015-2018 Carlos J. Santisteban
; last modified 20171221-1317

; *** CPU determining code *** 0.9.6b2
; essentially from the work of David Empson, Oct. '94
; NMOS and 65816 savvy, of course!
; alters fw_cpu

.(
	LDY #$00			; by default, NMOS 6502 (0)
	SED					; decimal mode
	LDA #$99			; load highest BCD number
	CLC					; prepare to add
	ADC #$01			; will wrap around in Decimal mode
	CLD					; back to binary
		BMI cck_set			; NMOS, N flag not affected by decimal add
	LDY #$03			; assume now '816 (3)
	LDX #$00			; sets Z temporarily
	.byt	$BB			; TYX, 65816 instruction will clear Z, NOP on all 65C02s will not
		BNE cck_set			; branch only on 65802/816
	DEY					; try now with Rockwell (2)
	STY $EA				; store '2' there, irrelevant contents
	.byt	$17, $EA	; RMB1 $EA, Rockwell R65C02 instruction will reset stored value, otherwise NOPs
	CPY $EA				; location $EA unaffected on other 65C02s
		BNE cck_set			; branch only on Rockwell R65C02 (test CPY)
	DEY					; revert to generic 65C02 (1)
		BNE cck_set			; cannot be zero, thus no need for BRA
cck_lst:
	.asc	"NBRV"		; codes for NMOS (N), generic CMOS (B), Rockwell 65C02 (R) and 65816/65802 (V)
cck_set:
	LDA cck_lst, Y		; get proper code from investigation
	STA fw_cpu			; store in variable (now nothing to do with firmware template)
.)
