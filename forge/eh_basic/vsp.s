; Virtual Serial Port driver module for EhBASIC (under perdita)
; (c) 2023 Carlos J. Santisteban
; last modified 20230209-2338

#echo "Using Virtual Serial Port for LOAD/SAVE"

#define	PSV_FOPEN	$11
#define	PSV_FREAD	$12
#define	PSV_FWRITE	$13
#define	PSV_FCLOSE	$1F

; *** redefine placeholders for EhBASIC LOAD/SAVE routines ***
-aux_in:					; *** device input (MUST restore devices upon EOF) ***
	LDA $DF93				; get char from VSP
	BEQ in_eof				; until terminator
	CMP #10
	BNE in_ok
		LDA #13				; convert UNIX newline to CONIO/minimOS
in_ok:
	CMP #$FF				; EOF?
	BNE do_in
		LDA #$20
do_in:
	CLC						; eeeeeeeek
	RTS
in_eof:
	STZ std_in
	STZ stdout				; restore devices!
	LDA	#<LAB_RMSG			; point to "Ready" message low byte
	LDY	#>LAB_RMSG			; point to "Ready" message high byte
	JMP	LAB_18C3			; go do print string... and return

-aux_out:					; *** device output ***
	CMP #13					; check for CONIO/minimOS NEWLINE
	BNE do_aux_out
		LDA #10				; convert to UNIX LF
do_aux_out:
	STA $DF93				; send char to VSP
	RTS

-aux_load:					; *** prepare things for LOAD, Carry if not possible ***
	LDA #PSV_FOPEN
	STA $DF94				; set VSP mode for setting filename
; must emit filename, placeholder below
	LDX #0
name_l:
		LDA filename, X		; get char
		BEQ load_ok			; until termination
		STA $DF93			; send name character to VSP
		INX					; eeeeeek
		BNE name_l
load_ok:
	LDA #PSV_FREAD
	STA $DF94				; will use open file for reading
	CLC
	RTS

-aux_save:					; *** prepare things for SAVE, Carry if not possible ***
	LDA #PSV_FOPEN
	STA $DF94				; set VSP mode for setting filename
; must emit filename, placeholder below
	LDX #0
name_s:
		LDA filename, X		; get char
		BEQ save_ok			; until termination
		STA $DF93			; send name character to VSP
		INX					; eeeeeek
		BNE name_s
save_ok:
	LDA #PSV_FWRITE
	STA $DF94				; will use open file for writing
	CLC						; all OK this far!
	RTS
filename:
	.asc	"test.bas", 0

-aux_close:					; *** tidy up after SAVE ***
	LDA #PSV_FCLOSE
	STA $DF94				; tell VSP to close file
	RTS						; nothing to do this far
