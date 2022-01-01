; minimOS 0.4.1 nano-monitor-debugger for LED keypad
; (c) 2013-2022 Carlos J. Santisteban
; last modified 20130611

n_tmp	= z2 + 1		; instead of systmp
;		.asc "UNj*"		; magic string for user-installed NMI

; prepare monitor
		LDX #5			; save some temporary space, 4+2 bytes
n_save:		LDA z6, X	; will get the whole z6L plus z2W
			PHA
			DEX
		BPL n_save
		LDA #<n_addr	; splash string address, low byte
		LDY #>n_addr	; splash string address, high byte
		JSR n_text		; print C-string pointed by A/Y
; clear input
n_res	_STZA n_tmp		; reset index
		_STZA z6		; alpha mode disabled by default, just in case!
; type 4-digit hex address
n_tad:		JSR n_hexin	; generic input @ z6, n_tmp as index
			BCC n_four	; normal processing
				CMP #27			; ESCAPE key
				BNE n_noesc		; stay for a while
n_conf:				LDA #<n_end	; exiting C-string address, low byte
					LDY #>n_end	; high byte
					JSR n_text	; print it
					JSR n_yesno	; wait for confirmation
					BCC n_fin	; user said OK, go away
					BCS n_res	; else start again
n_noesc:		CMP #'?'		; MENU key
				BEQ n_regs		; go to register control
n_four:		LDX n_tmp	; get index
			CPX #4		; completed address?
		BNE n_tad		; stay if not
		JSR n_yesno		; otherwise, wait for confirmation
		BCS n_res		; cancel typed address
		LDA #13			; new line
		JSR n_aout
		JSR n_hex2bin	; convert into sysptr (X is 4 here)
; enter editor mode		
n_disp:	JSR n_4d		; display address
		LDA #'='
		JSR n_aout		; place separator
		_LDAX (sysptr)	; get memory content, check NMOS-savvy macro!
		STA z2			; conversion input
		JSR n_2d		; print z2 as two hex digits
		LDA #13			; carriage return
		JSR n_aout		; newline
n_edit:		JSR n_read	; get a key (+/-/?/Esc)
			CMP #'+'	; next address
			BNE n_minus
				INC sysptr		; increase pointer
				BNE n_disp		; display new address and content
				INC sysptr+1	; in case of boundary crossing
				_BRA n_disp
n_minus:	CMP #'-'			; edit contents
			BNE n_keep			; if not, leave it alone
				LDX #4			; number of hex digits
;				JSR n_bin2hex	; get ASCII string for the current address
				JSR n_4d		; show address
				LDA #'-'		; different separator
				JSR n_aout
				_LDAX (sysptr)	; get previous memory content
				STA z2			; conversion input
				JSR n_2d		; print z2 as two hex digits
				LDA #'.'		; extra separator
				JSR n_aout		; print it
				_STZA n_tmp		; reset cursor
n_data:				JSR n_hexin	; get new data
					BCC n_two	; normal processing
						CMP #27	; ESCAPE key
						BEQ n_noed
n_two:				LDX n_tmp	; get index
					CPX #2		; completed byte?
				BNE n_data		; stay if not
				JSR n_yesno		; otherwise, wait for confirmation
				BCS n_disp		; cancel typed data 
				LDA sysptr		; save pointer!
				PHA
				JSR n_hex2bin	; convert into sysptr (X is 2 here)
				LDX sysptr		; copy result...
				PLA				; ...thru restored pointer...
				STA sysptr
				TXA
				_STAX (sysptr)	; ...into memory
n_noed:			LDA #13			; new line
				JSR n_aout
				_BRA n_disp		; show new value and continue
n_keep:		CMP #27		; ESCAPE key is JMP or JSR
			BNE n_noj
				LDA #<n_jsr		; JSR string address low
				LDY #>n_jsr		; high
				JSR n_text		; prompt
				JSR n_yesno		; confirm
				BCS n_noc		; no JSR, maybe JMP?
					LDA sysptr+1	; address high
					PHA
					LDA sysptr		; address low
					PHA
					PHP				; dirty trick
					RTI				; because lack of indirect call!
					_BRA n_res		; return to debugger
n_noc:			LDA #<n_jmp		; JMP string address low
				LDY #>n_jmp		; high
				JSR n_text		; prompt
				JSR n_yesno		; confirm
				BCS n_res		; wrong option, restart debugger
					JMP (sysptr)	; go there!
n_noj:		CMP #'?'			; MENU key
			BEQ n_regs			; go to register control
		_BRA n_edit				; keep editing
; change registers
n_regs:
		_STZA n_tmp				; register in use, S, P, A, X, Y = 0...4
n_rdis:		LDA n_tmp			; register in use
			ASL
			ASL					; multiply by four (pointer to string)
			CLC
			ADC #<n_sreg		; compute low byte of string address
			STA sysptr			; temporary storage
			LDA #>n_sreg+1		; compute high byte
			ADC #0				; propagate carry
			TAY					; MSB for n_text
			LDA sysptr			; retrieve LSB
			JSR n_txt			; display header
			TSX					; get actual stack pointer
			STX sysptr			; store for stack addressing
			LDA n_tmp			; which register?
			STA sysptr+1		; save it for later!
			BNE n_nosp			; pushed, not just the stack pointer
				LDA #6			; offset to SP prior to NMI
				CLC
				ADC sysptr		; previous SP
			_BRA n_dr2			; show value
n_nosp:			TXA				; original offset
				SEC
				SBC n_tmp		; point to desired register
				TAX				; just substracted from X
				LDA $0105, X	; should work!
n_dr2:		STA z2				; parameter input
			JSR n_2d			; print in ASCII
			; **** don't print CR, just wait for - and put . afterwards (same with memory)
		;**********
		_BRA n_tad
		
; exit debugger
n_fin:
		LDX #0
n_rest:		PLA			; get stored value
			STA z6, X	; will restore the whole z6L plus z2W
			INX
		CPX #6
		BNE n_rest
; *** standard NMI exit ***
		_PLY
		_PLX
		PLA
		RTI

; ***** subroutines *****

; print out C-string at A/Y
n_text:	STA sysptr		; store low address
		STY sysptr+1	; store high address
n_prn:		LDA (sysptr)	; get character
			BEQ n_term		; until terminator
			JSR n_aout		; print current character
			INC sysptr		; next
		BNE n_prn
		INC sysptr+1	; boundary crossing
		_BRA n_prn
n_term:	RTS				; we are done

; get processed key
n_read:			LDX #0
				LDY #5		; around 6.4 ms debouncing delay @ 1 MHz
n_delay:		DEX
				BNE n_delay
				DEY
			BNE n_delay
			JSR n_poll		; default device interrupt task, SPECIFIC
			LDY default_in	; the weakest link
			_KERNEL(CIN)	; get character (non locking)
		BCS n_read			; wait for a key
		LDA z2				; get ASCII code
		CMP #'@'			; if over 64...
		BPL n_ucase			; ...will clear bit 6
			AND #%10111111	; all upper case
n_ucase:	RTS				; done
		
; *** highly SPECIFIC driver call, used by n_read
n_poll:	JMP (drv_led + D_POLL)	; LED keypad

; wait for OK (C=0) or ESCAPE (C=1)
n_yesno:
		JSR n_read		; get key
		CMP #13			; OK?
		BNE n_nyet		; not yet
			CLC			; otherwise, user confirmed
			RTS
n_nyet:	CMP #27			; ESCAPE?
		BNE n_yesno		; wait for a valid key
			SEC			; user discarded action
			RTS

; print whatever is stored at A
n_aout:	STA z2			; usual parameter
		LDY default_out	; the weakest link
		_KERNEL(COUT)	; do print
		RTS

; convert string from z6L to number at sysptr, X indicates number of digits (2 or 4)
n_hex2bin:
		DEX				; get back
		LDY #0			; output byte
n_hexdig:	JSR n_hdig	; convert single digit
			STA systmp	; store low nibble
			DEX			; one digit to the left
			JSR n_hdig	; convert single digit
			ASL			; convert it into high nibble
			ASL
			ASL
			ASL
			ORA systmp	; add low nibble
			STA sysptr, Y	; store full byte
			INY			; in case another two digits are due
			DEX			; one digit to the left
		BPL n_hexdig	; some more to do
		RTS

; convert single gex digit, internally used by n_hex2bin (X<-index, A->nibble)
n_hdig:	LDA z6, X	; get digit
		SEC
		SBC #'0'	; convert to number
		CMP #10		; a letter instead?
		BMI n_val	; already done
			SEC
			SBC #7	; convert alpha to value
n_val:	RTS

; convert number at z2W to hex string at z6L, X indicates number of digits (2 or 4)
n_bin2hex:
		DEX				; get back
		LDY #0			; input byte
n_nibb:		LDA z2, Y	; get remaining low nibble
			AND #$0F	; filter out high nibble
			STA systmp	; store low nibble
			LDA z2, Y	; byte again
			CLC			; actually needed???
			LSR			; shift to the right
			LSR
			LSR
			LSR
			STA z2, Y	; value was divided into 16
			LDA systmp	; get nibble alone
			CLC
			ADC #'0'	; convert to ASCII
			CMP #'9'+1	; needs alpha?
			BNE n_b2h	; char is ready
				CLC
				ADC #7	; value to letter
n_b2h:		STA z6, X	; store character
			DEX			; one more to the left
			CPX #1		; more than 1 byte to be converted?
			BNE n_1bin	; two digits only
				INY		; otherwise go for next byte
n_1bin:	BPL n_nibb		; next digit
		RTS

; generic HEX input @ z6, n_tmp as index
n_hexin:	JSR n_read		; get pressed key, with appropriate debouncing delay
			CMP #"."		; toggle alpha mode?
			BNE n_nodot		; maybe a number
				LDX n_tmp	; get index
				LDA z6, X	; check whether alpha mode is set
				CMP #'.'	; already set?
				BNE n_let	; time to set it
					_STZA z6, X	; if it was set, will be disabled now
					LDA #8		; backspace
				_BRA n_dot		; clear trailing dot
n_let:				LDA #'.'	; a dot must appear
					STA z6, X	; store alpha mode
n_dot:				JSR n_aout	; print the dot
				CLC
				RTS			; *** wait for another

n_nodot:	CMP #'0'		; below 0?
			BMI n_nonum		; not a number!
			CMP #'F'+1		; not even hex digit?
			BPL n_nonum
				LDX n_tmp	; get index
				PHA			; save current character
				LDA z6, X	; get alpha mode state
				TAY			; store elsewhere
				PLA			; restore value
				CPY #'.'	; alpha mode?
				BNE n_num	; stay with numeric value
					PHA			; save again...
					LDA #8		; backspace
					JSR n_aout	; delete previous dot
					LDX n_tmp	; restore index
					PLA			; restore value again...
					CLC
					ADC #17		; convert to alpha
n_num:			STA z6, X	; store into buffer
				INC n_tmp	; advance index
				JSR n_aout	; print the digit
n_kend:			CLC
				RTS			; *** exit with new key

n_nonum:	CMP #27			; Escape key?
			BEQ n_err		; continue elsewhere				
			CMP #'?'		; MENU key?
			BNE n_kend		; no more things to do
n_err:			SEC			; *** special exit
				RTS
				
; print 2-digit hex string FROM binary z2
n_2d:	LDX #2			; number of hex digits
		JSR n_bin2hex	; convert to ASCII
		LDX #0
		STX n_tmp		; save index
n_2dc:		JSR n_dig	; print one ASCII digit from z6+(n_tmp)
			CPX #2		; check limit
		BNE n_2dc
		
; print 4-digit hex string FROM binary sysptr
n_4d:	LDA sysptr		; get LSB
		STA z2			; store as parameter
		LDA sysptr+1	; same with MSB
		STA z2+1
		LDX #4			; number of hex digits
		JSR n_bin2hex	; convert to ASCII
		LDX #0			; reset index
		STX n_tmp		; save index
n_4dc:		JSR n_dig	; print one ASCII digit from z6+(n_tmp)
			CPX #4		; check limit
		BNE n_4dc

; print single hex digit (z6+X) used by n_2d and n_4d
n_dig:	LDA z6, X		; get digit from buffer
		JSR n_aout		; print it (destroys registers)
		INC n_tmp		; advance digit
		LDX n_tmp		; restore index register
		RTS
		
; data strings
n_addr:	.asc "Addr", 0
n_end:	.asc "End?", 0
n_jsr:	.asc "JSR?", 0
n_jmp:	.asc "JMP?", 0
n_sreg:	.asc "S@", 0, 0, "P=", 0, 0, "A=", 0, 0, "X=", 0, 0, "Y=", 0, 0
