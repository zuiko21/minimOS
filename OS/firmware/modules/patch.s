; firmware module for minimOS·65
; (c) 2018-2020 Carlos J. Santisteban
; last modified 20180131-1319

; ****************************
; PATCH, patch single function
; ****************************
;		INPUT
; kerntab	= address of function code (NULL means reset from originally installed kernel)
; Y			= function to be patched
;		OUTPUT
; kerntab	= previously set address (new)
; uses tmp_ktab & un_ptch (.w)

-patch:
.(
; first get current address, not worth a subroutine
	LDX fw_table, Y			; current pointer LSB... (4+4)
	LDA fw_table+1, Y
	STX un_ptch				; ...temporarily stored (3+3)
	STA un_ptch+1
; check what are we asking for
	LDA kerntab+1			; check whether null, cannot be in zeropage, get MSB anyway (3)
; *** new feature, a null pointer means unpatch! ***
	BNE fwp_nz				; already a valid pointer
; otherwise, extract original pointer from previously installed kernel!
		LDX fw_lastk			; get previous installed table eeeeeeeeeeeek
		LDA fw_lastk+1
		STX tmp_ktab			; set temporary indirect pointer eeeeeeeeeeeeek
		STA tmp_ktab+1
		LDA (tmp_ktab), Y		; LSB of entry...
		TAX						; ...will stay here
		INY						; now for LSB
		LDA (tmp_ktab), Y
		DEY						; back to original parameter!
		_BRA fwp_rst			; X.A points to original function
fwp_nz:
; *** end of new feature ***
	LDX kerntab				; get LSB in X, A already holds MSB (3)
fwp_rst:
	_CRITIC					; disable interrupts! (5)
	STA fw_table+1, Y		; store where the firmware expects it (4+4)
	TXA						; eeeeeeeeeeeek
	STA fw_table, Y			; no STX abs,Y
; report previously registered address (new)
	LDA un_ptch+1			; previous pointer... (3+3)
	LDX un_ptch
	STA kerntab+1			; ...as output parameter (3+3)
	STX kerntab
	_NO_CRIT				; restore interrupts if needed (4)
	_DR_OK					; done (8)
.)
