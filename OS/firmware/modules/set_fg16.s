; *** SET_FG, enable/disable frequency generator (Phi2/n) on VIA_FG ***
; (c) 2018-2022 Carlos J. Santisteban
; last modified 20190206-0843

; **************************************************
; *** SET_FG, enable/disable frequency generator *** TO BE REVISED
; **************************************************
;		INPUT
; zpar.w = dividing factor (times two?)
;		OUTPUT
; C = busy
;
; should be Phi2-rate independent... input as Hz, or 100uS steps?
; *** TO DO *** temporarily made 8-bit savvy
; no long addressing...

set_fg:
.(
	.al: REP #$20		; *** 16-bit memory ***
; switch DBR as it accesses a lot of kernel data!
	PHB					; eeeeeeeeek (3)
	PHK					; bank zero into stack (3)
	PLB					; set DBR! do not forget another PLB upon end! (4)
; proceed
	LDA zpar			; take whole word
		BEQ fg_dis			; if zero, disable output
	LDX VIA_FG+ACR		; get current configuration byte
		BMI fg_busy			; already in use
	LDA VIA_FG+T1LL		; get older T1 latch values
	STA old_t1			; save them
; *** TO_DO - should compare old and new values in order to adjust quantum size accordingly ***
	LDA zpar			; get new division factor
	STA VIA_FG+T1LL		; store it
	STA VIA_FG+T1CH		; get it running!
	.as: SEP #$20		; *** back to 8-bit memory ***
	TXA					; process configuration
	ORA #$C0			; enable free-run PB7 output
	STA VIA_FG+ACR		; update config
fg_none:
	PLB					; restore!
	_DR_OK				; finish anyway

fg_dis:
	.al:				; called from above
	LDX VIA_FG+ACR		; get current configuration
		BPL fg_none			; it wasn't playing!
	TXA					; process configuration
	AND #$007F			; disable PB7 only
	TAX					; please respect 2nd byte!
	STX VIA_FG+ACR		; update config
	LDA old_t1			; older T1L
	STA VIA_FG+T1LL		; restore old value
; *** TO_DO - restore standard quantum ***
	PLB					; restore!
	_DR_OK
fg_busy:
	PLB					; restore!
	_DR_ERR(BUSY)		; couldn't set
.)

.as:
