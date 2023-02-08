; Virtual Serial Port driver module for EhBASIC (under perdita)
; (c) 2023 Carlos J. Santisteban
; last modified 20230209-0008

#echo "Using Virtual Serial Port for LOAD/SAVE"

; *** redefine placeholders for EhBASIC LOAD/SAVE routines ***
-aux_in:					; *** device input (MUST restore devices upon EOF) ***
;just aborts LOAD
;	LDA #0					; EOF marker
	STZ std_in
	STZ stdout				; restore devices!
;	LDA	#<LAB_RMSG			; point to "Ready" message low byte
;	LDY	#>LAB_RMSG			; point to "Ready" message high byte
;	JMP	LAB_18C3			; go do print string... and return
	RTS

-aux_out:					; *** device output ***
	CMP #13					; check for CONIO/minimOS NEWLINE
	BNE do_aux_out
		LDA #10				; convert to UNIX LF
do_aux_out:
	STA $DF93				; send char to VSP
	RTS

-aux_load:					; *** prepare things for LOAD, Carry if not possible ***
	CLC
	RTS

-aux_save:					; *** prepare things for SAVE, Carry if not possible ***
	LDA #$F1				; PSV_ASCII
	STA $DF94				; set VSP mode
	CLC						; all OK this far!
	RTS

-aux_close:					; *** tidy up after SAVE ***
	RTS						; nothing to do this far
