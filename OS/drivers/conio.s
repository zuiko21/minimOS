; generic, UNIVERSAL firmware console support for minimOS!
; v0.6b4
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20220104-0114

; ***********************
; *** minimOS headers ***
; ***********************
;#include "../usual.h"

; *** begins with sub-function addresses table ***
	.byt	144			; physical driver number D_ID (TBD)
	.byt	A_BOUT|A_BLIN	; basic I/O driver, non-interrupt-driven
	.word	gfc_i		; read N bytes from 'serial'
	.word	gfc_o		; output N bytes to 'serial'
	.word	fwc_init	; initialise 'device', called by POST only
	.word	fwc_nul		; no periodic interrupt
	.word	0			; frequency makes no sense
	.word	gfc_nreq	; D_ASYN does nothing
	.word	gfc_nreq	; no config
	.word	gfc_nreq	; no status
	.word	fwc_nul		; shutdown procedure, does nothing
	.word	gfc_info	; points to descriptor string
	.word	0			; reserved, D_MEM

; *** driver description ***
gfc_info:
	.asc	"Generic  FW I/O console v0.6b1", 0

; **********************************************************************************
; *** this header will enable classic character routines within block procedures ***
; **********************************************************************************
gfc_i:
	LDA bl_ptr+1			; get pointer MSB
	PHA						; in case gets modified...
	LDY #0					; reset index
fwcr_l:
		_PHY				; keep this
		JSR fwc_i			; *** get one byte ***
			BCS blck_err	; any error ends transfer!
		_PLY				; restore index
		LDA io_c			; received byte...
		STA (bl_ptr), Y		; ...goes into buffer
		INY					; go for next
		BNE fwcr_nw			; still within page
			INC bl_ptr+1	; ...or increment MSB
fwcr_nw:
		DEC bl_siz			; one less to go
			BNE fwcr_l		; no wrap, continue
		LDA bl_siz+1		; check MSB otherwise EEEEEK
			BEQ blck_end	; no more!
		DEC bl_siz+1		; ...or one page less
		_BRA fwcr_l
blck_err:
	PLA						; was Y, but must respect error code!
blck_end:
	PLA						; gets pointer MSB back...
	STA bl_ptr+1			; ...and restores it
	RTS						; respect whatever error code

gfc_o:
	LDA bl_ptr+1			; get pointer MSB
	PHA						; in case gets modified...
	LDY #0					; reset index
fwcs_l:
		LDA (bl_ptr), Y		; buffer contents...
		STA io_c			; ...will be sent
		_PHY				; keep this
		JSR fwc_o			; *** send one byte ***
			BCS blck_err	; any error ends transfer!
		_PLY				; restore index
		INY					; go for next
		BNE fwcs_nw			; still within page
			INC bl_ptr+1	; ...or increment MSB
fwcs_nw:
		DEC bl_siz			; one less to go
			BNE fwcs_l		; no wrap, continue
		LDA bl_siz+1		; check MSB otherwise
			BEQ blck_end	; no more!
		DEC bl_siz+1		; ...or one page less
		_BRA fwcs_l

; ************************
; *** initialise stuff ***
; ************************
fwc_init:
	LDY #FORMFEED			; clear screen
	_ADMIN(CONIO)
_DR_OK
; no real need of initialising input "buffer" as will be cleared at first polling
	RTS						; respect error

; *****************************
; *** send one byte in io_c ***
; *****************************
fwc_o:
	LDY io_c				; char to be printed
	BEQ fwc_nul				; no way to print this!
	_ADMIN(CONIO)
fwc_nul:
	RTS						; respect error

; ************************
; *** receive one byte ***
; ************************
fwc_i:
	LDY #0					; input mode
	_ADMIN(CONIO)
	RTS						; respect error

; *** assorted stuff ***
gfc_nreq:
	NEXT_ISR				; just in case...
