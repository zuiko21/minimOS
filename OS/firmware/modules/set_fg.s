; *** SET_FG, enable/disable frequency generator (Phi2/n) on VIA_FG *** revised 20150208...
; (c) 2015-2020 Carlos J. Santisteban
; last modified 20190206-0901

; **************************************************
; *** SET_FG, enable/disable frequency generator *** TO BE REVISED
; **************************************************
;		INPUT
; zpar.w = dividing factor (times two?)
;		OUTPUT
; C = busy
;
; should be Phi2-rate independent... input as Hz, or 100uS steps?
; zpar.W <- dividing factor (times two?), C -> busy
; destroys A, X...

; *******TO BE REVISED*********
-set_fg:
.(
	LDA zpar			; check requested value
	ORA zpar+1
		BEQ fg_dis			; if zero, disable output
	LDA VIA_FG+ACR		; get current configuration
		BMI fg_busy			; already in use
	LDX VIA_FG+T1LL		; get older T1 latch values
	STX old_t1			; save them
	LDX VIA_FG+T1LH
	STX old_t1+1
; *** TO_DO - should compare old and new values in order to adjust quantum size accordingly ***
	LDX zpar			; get new division factor
	STX VIA_FG+T1LL		; store it
	LDX zpar+1
	STX VIA_FG+T1LH
	STX VIA_FG+T1CH		; get it running!
	ORA #$C0			; enable free-run PB7 output
	STA VIA_FG+ACR		; update config
fg_none:
	_DR_OK				; finish anyway
fg_dis:
	LDA VIA_FG+ACR		; get current configuration
		BPL fg_none			; it wasn't playing!
	AND #$7F			; disable PB7 only
	STA VIA_FG+ACR		; update config
	LDA old_t1			; older T1L_L
	STA VIA_FG+T1LL		; restore old value
	LDA old_t1+1
	STA VIA_FG+T1LH		; it's supposed to be running already
; *** TO_DO - restore standard quantum ***
	_DR_OK				; all done
fg_busy:
	_DR_ERR(BUSY)		; couldn't set
.)
