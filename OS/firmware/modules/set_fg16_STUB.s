; **************************************************
; *** SET_FG, enable/disable frequency generator *** TO BE REVISED
; **************************************************
;		INPUT
; zpar.w = dividing factor (times two?)
;		OUTPUT
; C = busy
;
; should use some firmware interface, just in case it doesn't affect jiffy-IRQ!
; should also be Phi2-rate independent... input as Hz, or 100uS steps?
; *** TO DO *** temporarily made 8-bit savvy
; no long addressing...

set_fg:
	.al: REP #$20		; *** 16-bit memory ***
; switch DBR as it accesses a lot of kernel data!
	PHB					; eeeeeeeeek (3)
	PHK					; bank zero into stack (3)
	PLB					; set DBR! do not forget another PLB upon end! (4)
; proceed
	LDA zpar			; take whole word
		BEQ fg_dis			; if zero, disable output
	LDX VIA+ACR			; get current configuration byte
		BMI fg_busy			; already in use
	LDA VIA+T1LL		; get older T1 latch values
	STA old_t1			; save them
; *** TO_DO - should compare old and new values in order to adjust quantum size accordingly ***
	LDA zpar			; get new division factor
	STA VIA+T1LL		; store it
	STA VIA+T1CH		; get it running!
	.as: SEP #$20		; *** back to 8-bit memory ***
	TXA					; process configuration
	ORA #$C0			; enable free-run PB7 output
	STA VIA+ACR			; update config
fg_none:
	PLB					; restore!
	_EXIT_OK			; finish anyway

fg_dis:
	.al:				; called from above
	LDX VIA+ACR			; get current configuration
		BPL fg_none			; it wasn't playing!
	TXA					; process configuration
	AND #$007F			; disable PB7 only
	TAX					; please respect 2nd byte!
	STX VIA+ACR			; update config
	LDA old_t1			; older T1L
	STA VIA+T1LL		; restore old value
; *** TO_DO - restore standard quantum ***
	PLB					; restore!
	_EXIT_OK
fg_busy:
;	.al:
	PLB					; restore!
	_ERR(BUSY)			; couldn't set

