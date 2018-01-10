; firmware module for minimOS·65
; (c)2018 Carlos J. Santisteban
; last modified 20180110-1401

; *** check whether an actual 65816 is in use ***
; no interface needed

; as this firmware should be 65816-only, check for its presence or nothing!
; derived from the work of David Empson, Oct. '94
#ifdef	SAFE
.(
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
.)
#endif
