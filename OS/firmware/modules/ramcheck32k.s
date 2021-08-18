; firmware module for minimOS
; 32 KiB RAM checker routine 0.9.6a1
; suitable for most!
; (c) 2021 Carlos J. Santisteban
; last modified 20210818-1339

.(
; *** declare some temprorary vars ***
ptr		= z_used
r_top	= z_used+2

; first of all, check zeropage for pointer availability
	LDA #1					; intial value sets D0
#ifdef	CBM64
	LDX #2					; 6510 must skip port!
#else
	LDX #0
#endif
init:
		STA 0, X			; fill with initial value
		CMP 0, X			; check this first bit!
			BNE bad
		INX
		BNE init
#ifdef	CBM64
	LDX #2					; 6510 must skip port!
#endif
z_test:
		CLC					; we will rotate, not shift
		LDY #7				; number of shifts before C will set
z_shift:
			ROL 0, X		; try current byte
				BCS bad
			DEY				; until all bits are shifted
			BNE z_shift
		ROL 0, X			; one more time
			BCC bad			; should appear in carry...
			BNE bad			; ...while being all clear!
		INX					; go for next ZP byte
		BNE z_test
; with ZP checked, indirect pointer is feasible
;	LDY #0					; pointer LSB and index reset, but known to be zero
;	LDA #1					; this is pointer MSB, but A still holds it!
	STY ptr
	STA ptr+1
; once again, we have A set as 1, let's fill all memory with it
fill:
			STA (ptr), Y
			CMP (ptr), Y
				BNE top		; this fail could be an unexpected <32 KB RAMTOP
			INY
			BNE fill
		INC ptr+1			; next page
		BPL fill			; up to 32 KB
f_ret:
; unfortunately no RMW with indirect postindexed mode
	LDX #7					; number of feasible shifts before clearing byte
	CLC						; this only needed once, as BCS will trap
cycle:
		LDA #1
		STA ptr+1			; reset MSB (skipping ZP)
		LDY #0				; rarely needed...
r_pag:
				LDA (ptr), Y
				ROL
					BCS top1
				STA (ptr), Y
				INY
				BNE r_pag
			INC ptr+1
			BPL r_pag
p_ret:
		DEX
		BNE cycle
; now all should be 128, let's clear it
	LDA #1
	STA ptr+1				; reset MSB (skipping ZP)
;	LDY #0					; no need to reset index?
clear:
			LDA (ptr), Y
			ROL
				BCC top2
				BNE top2
			STA (ptr), Y
			DEY
			BNE clear
		INC ptr+1
		BPL clear
	BMI ram_ok
; this code detects possible RAMTOP
top:
	STY r_top
	LDA ptr+1
	STA r_top+1
	BNE f_ret
; further errors must match detected limit... unless the foating bus is 1!
top1:
	CPY r_top
		BNE bad
	LDA ptr+1
	CMP r_top+1
		BNE bad
	BEQ p_ret
; last check
top2:
	CPY r_top
		BNE bad
	LDA ptr+1
	CMP r_top+1
		BEQ ram_ok
; error handling
bad:
; ** ** ** TBD ** ** **
; otherwise continue normally
ram_ok:
