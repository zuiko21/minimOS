; firmware module for minimOS·16
; (c) 2018-2021 Carlos J. Santisteban
; last modified 20181109-1237

; *** check whether an actual 65816 is in use ***
; no interface needed, might call lock routine!

; as this firmware should be 65816-only, check for its presence or nothing!
; derived from the work of David Empson, Oct. '94
.(
#ifdef	SAFE
	SED					; decimal mode
	LDA #$99			; load highest BCD number (sets N too)
	CLC					; prepare to add
	ADC #$02			; will wrap around in Decimal mode (should clear N)
	CLD					; back to binary
		BMI cpu_bad			; NMOS, N flag not affected by decimal add
	TAY					; let us preload Y with 1 from above
	LDX #$00			; sets Z temporarily
	TYX					; TYX, 65802 instruction will clear Z, NOP on all 65C02s will not
	BNE fw_cpuOK		; Branch only on 65802/816
cpu_bad:
		JMP lock		; cannot handle BRK, alas
fw_cpuOK:
#endif

; *** set back to native 816 mode ***
; it can be assumed 65816 from this point on
	CLC					; set NATIVE mode eeeeeeeeeeek
	XCE					; still with 8-bit registers
; seems I really need to (re)set DP and DBR if rebooting
	PHK					; stacks a zero
	PLB					; reset this value
	PHK					; stack two zeroes
	PHK
	PLD					; simpler than TCD et al
.)
