; minimOS 0.4b3 enhanced routines, 6502
; (c) 2013 Carlos J. Santisteban
; last modified 2013-02-22

cout:
	TYA			; get device number
	BPL k0_logical		; not physical
; *** several ways to do, this is the hardwired one ***
	CPY #_acia_dev		; serial port
;	CPY drv_acia+_d_num	; more generic way
	BNE k0_not_acia
	JMP acia_cout		; needs external label
;	JMP (drv_acia+_d_out)	; more generic way
k0_not_acia:
	CPY #_ss22_dev		; SS-22 port
;	CPY drv_ss22+_d_num	; more generic way
	BNE k0_not_ss22
	JMP ss_cout		; needs external label
;	JMP (drv_ss22+_d_out)	; more generic way
k0_not_ss22:
	CPY #_led_dev		; LED keypad
;	CPY drv_led+_d_num	; more generic way
	BNE k0_not_led
	JMP led_cout		; needs external label
;	JMP (drv_led+_d_out)	; more generic way
k0_not_led:
	_ERR(_not_found)	; no such device
;	_BRA k0_error		; more compact way, saves one byte
; *** instead of the above, let's use a device pointer table *** 36 clocks! doesn't detect non-existent devices!
;	TYA			; get device
;	AND #$7F		; clear bit 7
;	ASL			; multiply by two
;	TAX			; it's index now
;	LDA drv_table, X	; get LSB
;	CLC
;	ADC #_d_cout-1		; pseudo-return
;	PHA
;	LDA drv_table+1, X	; get MSB
;	ADC #0			; carry from LSB
;	PHA
;	RTS			; will jump OK?
k0_logical:
	BNE k0_port		; check actual port
	LDY default_out
	BNE cout		; check again, never zero!
k0_port:
	CPY #_null_dev		; /dev/null @ API
;	CPY dummy_drv+_d_num	; more generic way
	BNE k0_not_null
; do anything at all?
	_EXIT_OK		; nothing to do
k0_not_null:
; put more logical devices like this
k0_error:
	_ERR(_not_found)	; no device

; ***********************************************

; generic, table-driven interrupt routine calling
; takes 12+n*19 clocks, not counting driver code
; needs safe sysvec or the like
	LDA #<a1_table		; LSB of authorized list
	STA sysvec
	LDA #>a1_table		; MSB
	BEQ auth_end		; end of the list
	STA sysvec+1
next_call:
	JSR auth_jmp
	INC sysvec		; MUST be even addr!
	INC sysvec
	BNE seq_call
	INC sysvec+1		; next page
	BNE seq_call		; shouldn't be zero anyway
auth_jmp:
	JMP (sysvec)		; indirect call
auth_end:
; we're done
