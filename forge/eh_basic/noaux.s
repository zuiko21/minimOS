; dummy driver module for EhBASIC (under perdita)
; (c) 2023-2024 Carlos J. Santisteban
; last modified 20240130-1349

#echo "No device for LOAD/SAVE!"

; *** driver info string NEW ***
driver_id:
	.asc	14, "No storage!", 15, $0D, 0

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
	RTS

-aux_load:					; *** prepare things for LOAD, Carry if not possible ***
	SEC
	RTS

-aux_save:					; *** prepare things for SAVE, Carry if not possible ***
	SEC
	RTS

-aux_close:					; *** tidy up after SAVE ***
	RTS						; nothing to do this far
