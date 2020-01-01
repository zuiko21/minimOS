; minimOS 0.4.1 nano-monitor-debugger for LED keypad
; (c) 2013-2020 Carlos J. Santisteban
; last modified 20130614

; LED-Keypad supplied ASCII codes
#define		K_OK	13
#define		ESC		27
#define		MENU	'?'
#define		SHIFT	'.'
#define		NEXT	'+'
#define		PREV	'-'

vector	= sysptr		; for easier non-NMI version
param	= z2
buffer	= z6
n_tmp	= param + 1		; instead of systmp
temp	= systmp		; an extra byte is needed somewhere

;		.asc "UNj*"		; magic string for user-installed NMI

; *** prepare monitor -- not needed for non-NMI version ***
		LDX #5				; save some temporary space, 4+2 bytes
n_save:		LDA buffer, X	; will get the whole bufferL plus paramW
			PHA
			DEX
		BPL n_save

; ask for address
n_rst:	LDA #<n_addr	; splash string address, low byte
		LDY #>n_addr	; splash string address, high byte
		JSR n_text		; print C-string pointed by A/Y
; clear input
		_STZA n_tmp		; reset index
		_STZA buffer	; alpha mode disabled by default, just in case!
; type 4-digit hex address
n_tad:		JSR n_hexin		; generic input @ buffer, n_tmp as index
			CMP #ESC		; ESCAPE key
			BNE n_noesc		; stay for a while
n_conf:			LDA #<n_end	; exiting C-string address, low byte
				LDY #>n_end	; high byte
				JSR n_text	; print it
				JSR n_yesno	; wait for confirmation
				BCC n_fin	; user said OK, go away
				BCS n_rst	; else start again
n_noesc:	CMP #MENU		; MENU key
				BEQ n_regs	; go to register control
n_four:		LDX n_tmp		; get index
			CPX #4			; completed address?
		BNE n_tad			; stay if not
		JSR n_yesno		; otherwise, wait for confirmation
		BCS n_rst		; cancel typed address
		JSR n_hex2bin	; convert into vector (X is 4 here)
; enter editor mode		
n_disp:	JSR n_4d		; display newline + address
		LDA #'='
		JSR n_aout		; place separator
		_LDAX (vector)	; get memory content, check NMOS-savvy macro!
		STA param		; conversion input
		JSR n_2d		; print param as two hex digits
n_edit:		JSR n_read	; get a key (+/-/?/Esc)
			CMP #NEXT	; next address
			BNE n_minus
				INC vector		; increase pointer
				BNE n_disp		; display new address and content
				INC vector+1	; in case of boundary crossing
				_BRA n_disp
n_minus:	CMP #PREV			; edit contents
			BNE n_keep			; if not, leave it alone
				LDA #'.'		; extra separator
				JSR n_aout		; print it
				_STZA n_tmp		; reset cursor
n_data:				JSR n_hexin	; get new data
					CMP #ESC	; ESCAPE key
						BEQ n_noed		; discard edit
n_two:				LDX n_tmp	; get index
					CPX #2		; completed byte?
				BNE n_data		; stay if not
				JSR n_yesno		; otherwise, wait for confirmation
				BCS n_disp		; cancel typed data 
				LDA vector		; save pointer!
				PHA
				JSR n_hex2bin	; convert into vector (X is 2 here)
				LDX vector		; copy result...
				PLA				; ...thru restored pointer...
				STA vector
				TXA
				_STAX (vector)	; ...into memory
n_noed:			_BRA n_disp		; show new value and continue
n_keep:		CMP #ESC	; ESCAPE key is JMP or JSR
			BNE n_nojump
				LDA #<n_jsr		; JSR string address low
				LDY #>n_jsr		; high
				JSR n_text		; prompt -- BUT DESTROYS vector!!!!!!!!!!
				JSR n_yesno		; confirm
				BCS n_nocall	; no JSR, maybe JMP?
					JSR n_jump		; indirect call ****** but get registers before, anyway!!!!
					_BRA n_rst		; return to debugger
n_nocall:		LDA #<n_jmp		; JMP string address low
				LDY #>n_jmp		; high
				JSR n_text		; prompt
				JSR n_yesno		; confirm
					BCS n_rst	; wrong option, restart debugger
n_jump:			JMP (vector)	; go there! ****** but get registers anyway!!!! JMP may just return to a modified stack!
n_nojump:	CMP #MENU			; MENU key
			BEQ n_regs			; go to register control
		_BRA n_edit				; keep editing
; change registers *** storage will change severely in non-NMI version ***
n_regs:
		_STZA n_tmp			; register in use, S, P, A, X, Y = 0...4
n_rdis:		LDA n_tmp		; register in use
			ASL				; that would set C=0, no CLC needed afterwards
			ADC n_tmp		; multiply by three (pointer to string)
			CLC
			ADC #<n_sreg	; compute low byte of string address
			TAX				; temporary storage
			LDA #>n_sreg+1	; compute high byte
			ADC #0			; propagate carry
			TAY				; MSB for n_text
			TXA				; retrieve LSB
			JSR n_txt		; display header
			TSX				; get actual stack pointer
			STX vector		; store for stack addressing
			LDA n_tmp		; which register?
			BNE n_nosp		; pushed, not just the stack pointer
				LDA #6			; offset to SP prior to NMI
				CLC
				ADC vector		; previous SP
			_BRA n_dr2		; show value
n_nosp:			TXA				; original offset
				SEC
				SBC n_tmp		; point to desired register
				TAX				; just substracted from X
				LDA $0105, X	; should work!
n_dr2:		STA param		; parameter input
			JSR n_2d		; print in ASCII
			JSR n_read		; get key
			CMP #NEXT		; next register
			BNE n_mreg
				INC n_tmp		; increase pointer
				LDA n_tmp
				CMP #5			; check if passed thru all registers
				BNE n_rdis
					_STZA n_tmp		; back to 0 (SP)
				_BRA n_rdis
n_mreg:		CMP #PREV		; modify register
			BNE n_rmenu
				LDA n_tmp		; check whether SP
					BEQ n_rdis		; will not change
				LDA #'.'		; extra separator
				JSR n_aout		; print it
				_STZA n_tmp		; reset cursor
n_value:			JSR n_hexin		; get new data
					CMP #ESC		; ESCAPE key
						BEQ n_rdis		; discard edit
n_two:				LDX n_tmp		; get index
					CPX #2			; completed byte?
				BNE n_value		; stay if not
				JSR n_yesno		; otherwise, wait for confirmation
				BCS n_rdis		; cancel typed data 
				JSR n_hex2bin	; convert into vector (X is 2 here)
;********* check this!
				TSX
				TXA				; original offset
				SEC
				SBC n_tmp		; point to desired register
				TAX				; just substracted from X
				LDA vector		; get result
				STA $0105, X	; should work!
;**********
n_rmenu:	CMP #MENU		; MENU key
		BNE n_rdis		; stay on register page
		BEQ n_rst		; or back to beginning

; exit debugger
n_fin:
		LDX #0			; *** restore parameters, only for NMI version ***
n_rest:		PLA				; get stored value
			STA buffer, X	; will restore the whole buffer plus param
			INX
		CPX #6
		BNE n_rest
; *** standard NMI exit, remove from non-NMI version ***
		_PLY
		_PLX
		PLA
		RTI				; *** non-NMI version will just use RTS instead ***

; ***** subroutines *****

; print out C-string at A/Y
n_text:	STA vector		; store low address
		STY vector+1	; store high address
		LDA #13			; carriage return
		JSR n_aout		; implicit newline before any string
n_prn:		LDA (vector)	; get character
			BEQ n_term		; until terminator
			JSR n_aout		; print current character
			INC vector		; next
		BNE n_prn
		INC vector+1	; boundary crossing
		_BRA n_prn
n_term:	RTS				; we are done

; get processed key
n_read:			LDX #0			; *** delay loop for NMI-version ***
				LDY #5			; around 6.4 ms debouncing delay @ 1 MHz
n_delay:		DEX
				BNE n_delay
				DEY
			BNE n_delay
			JSR n_poll		; *** default device interrupt task, not needed in non-NMI version ***
			LDY default_in	; the weakest link
			_KERNEL(CIN)	; get character (non locking)
		BCS n_read		; wait for a key
		LDA param		; get ASCII code
		CMP #'@'		; if over 64...
		BPL n_ucase		; ...will clear bit 6
			AND #%10111111	; all upper case
n_ucase:	RTS				; done
		
; *** highly SPECIFIC driver call, used by n_read, not if non-NMI
n_poll:	JMP (drv_led + D_POLL)	; LED keypad

; wait for OK (C=0) or ESCAPE (C=1)
n_yesno:
		JSR n_read		; get key
		CMP #K_OK		; OK?
		BNE n_nyet		; not yet
			CLC				; otherwise, user confirmed
			RTS
n_nyet:	CMP #ESC		; ESCAPE?
		BNE n_yesno		; wait for a valid key
			SEC				; user discarded action
			RTS

; print whatever is stored at A
n_aout:	STA param			; usual parameter
		LDY default_out		; the weakest link
		_KERNEL(COUT)		; do print
		RTS

; convert string from buffer to number at vector, X indicates number of digits (2 or 4)
n_hex2bin:
		DEX				; get back
		LDY #0			; clear output byte
n_hexdig:	JSR n_hdig		; convert single digit
			STA temp		; store low nibble
			DEX				; one digit to the left
			JSR n_hdig		; convert single digit
			ASL				; convert it into high nibble
			ASL
			ASL
			ASL
			ORA temp		; add low nibble
			STA vector, Y	; store full byte
			INY				; in case another two digits are due
			DEX				; one digit to the left
		BPL n_hexdig	; some more to do
		RTS

; convert single gex digit, internally used by n_hex2bin (X<-index, A->nibble)
n_hdig:	LDA buffer, X	; get digit
		SEC
		SBC #'0'		; convert to number
		CMP #10			; a letter instead?
		BMI n_val		; already done
			SEC
			SBC #7			; convert alpha to value
n_val:	RTS

; convert number at param to hex string at buffer, X indicates number of digits (2 or 4)
n_bin2hex:
		DEX				; get back
		LDY #0			; input byte
n_nibb:		LDA param, Y	; get remaining low nibble
			AND #$0F		; filter out high nibble
			STA temp		; store low nibble
			LDA param, Y	; byte again
			CLC				; actually needed???
			LSR				; shift to the right
			LSR
			LSR
			LSR
			STA param, Y	; value was divided into 16
			LDA temp		; get nibble alone
			CLC
			ADC #'0'		; convert to ASCII
			CMP #'9'+1		; needs alpha?
			BNE n_b2h		; char is ready
				CLC
				ADC #7			; value to letter
n_b2h:		STA buffer, X	; store character
			DEX				; one more to the left
			CPX #1			; more than 1 byte to be converted?
			BNE n_1bin		; two digits only
				INY				; otherwise go for next byte
n_1bin:	BPL n_nibb		; next digit
		RTS

; generic HEX input @ buffer, n_tmp as index
n_hexin:	JSR n_read		; get pressed key, with appropriate debouncing delay
			CMP #SHIFT		; toggle alpha mode?
			BNE n_nodot		; maybe a number
				LDX n_tmp		; get index
				LDA buffer, X	; check whether alpha mode is set
				CMP #'.'		; already set?
				BNE n_let		; time to set it
					_STZA buffer, X		; if it was set, will be disabled now
					LDA #8				; backspace
				_BRA n_dot		; clear trailing dot
n_let:				LDA #'.'			; a dot must appear
					STA buffer, X		; store alpha mode
n_dot:				JSR n_aout			; print the dot
				CLC
				RTS			; *** wait for another

n_nodot:	CMP #'0'		; below 0?
			BMI n_nonum		; not a number!
			CMP #'F'+1		; not even hex digit?
			BPL n_nonum
				LDX n_tmp		; get index
				LDY buffer, X	; get alpha mode state
				CPY #'.'		; alpha mode?
				BNE n_num		; stay with numeric value
					PHA				; save current character
					LDA #8			; backspace
					JSR n_aout		; delete previous dot
					LDX n_tmp		; restore index
					PLA				; restore character
					CLC
					ADC #17			; convert to alpha
n_num:			STA buffer, X	; store into buffer
				INC n_tmp		; advance index
				JSR n_aout		; print the digit
n_nonum:	RTS				; regular exit, no need to set carry
				
; print 2-digit hex string FROM binary param
n_2d:	LDX #2			; number of hex digits
		JSR n_bin2hex	; convert to ASCII
		LDX #0
		STX n_tmp		; save index
n_2dc:		JSR n_dig		; print one ASCII digit from buffer+(n_tmp)
			CPX #2			; check limit
		BNE n_2dc
		
; print 4-digit hex string FROM binary vector
n_4d:	LDA #13			; carriage return
		JSR n_aout		; print newline
		LDA vector		; get LSB
		STA param		; store as parameter
		LDA vector+1	; same with MSB
		STA param+1
		LDX #4			; number of hex digits
		JSR n_bin2hex	; convert to ASCII
		LDX #0			; reset index
		STX n_tmp		; save index
n_4dc:		JSR n_dig		; print one ASCII digit from buffer+(n_tmp)
			CPX #4			; check limit
		BNE n_4dc

; print single hex digit (buffer+X) used by n_2d and n_4d
n_dig:	LDA buffer, X	; get digit from buffer
		JSR n_aout		; print it (destroys registers)
		INC n_tmp		; advance digit
		LDX n_tmp		; restore index register
		RTS
		
; data strings
n_addr:	.asc "Addr", 13, 0
n_end:	.asc "End?", 13, 0
n_jsr:	.asc "JSR?", 0
n_jmp:	.asc "JMP?", 0
n_sreg:	.asc "S@", 0, "P=", 0, "A=", 0, "X=", 0, "Y=", 0
