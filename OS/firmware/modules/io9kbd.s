; firmware module for minimOS
; IO9 keyboard access 0.9.6a1
; suitable for anything with a single R/W address
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20210815-0014

.(
; *** single address definition *** modify as required
io9kbd	= $9000				; canonical address, any $9xxx should do

; *** variables in use *** (from io9kbd.h)
;fw_caps					d4=CAPS LOCK flag (0=ON) will be used as last column index (postdecrement!)
;fw_kcol					column scan limit, actually modifiers (including current CAPS LOCK status, %00001111 if ON, %00011111 if OFF)
;fw_kmod					modifier key index (0=none, 1=alt, 2=control, 4=shift, 8=caps?...)

; stub!

	LDA fw_kcol				; get modifiers

	ASL						; times two
	STA fw_kmod				; store index
	TAX						; column counter
ik_loop:
		DEX
		STX io9kbd			; latch selected column + CAPS LED
		LDA io9kbd			; and get appropriate rows
		EOR #$F				; invert bits in use
			BNE ik_get		; some keys pressed!
		CPX fw_caps			; otherwise check whether at first column already
		BNE ik_loop
	JMP ik_done				; all keys scanned, nothing was pressed
; decode key
	LDY #0					; reset shift counter
ik_bits:
		LSR					; get lowest bit
		BCS ik_this			; this was pressed
		INY
		CPY #4				; no more than 4 rows
		BNE ik_bits
; Y and X point to detected key



; ***********************
; *** keyboard matrix *** is this valid?
; ***********************
ik_lay:
#include "../../drivers/keys/akbd_lay.s"

; ******************************
; continue CONIO firmware module
; ******************************
ik_done:
	
