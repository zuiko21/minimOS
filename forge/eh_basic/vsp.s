; Virtual Serial Port driver module for EhBASIC (under perdita)
; (c) 2023 Carlos J. Santisteban
; last modified 20230414-1751

#echo Using Virtual Serial Port for LOAD/SAVE, interactive filename prompt

#define	PSV_FOPEN	$11
#define	PSV_FREAD	$12
#define	PSV_FWRITE	$13
#define	PSV_FCLOSE	$1F

; *** redefine placeholders for EhBASIC LOAD/SAVE routines ***
-aux_in:					; *** device input (MUST restore devices upon EOF) ***
	LDY $DF93				; get char from VSP ***** EEEEEEEEEEEEEEEEEEEEEEEEEEEEKKKKKKKKKKKK
	BEQ in_eof				; until terminator
	CPY #10					; NEWLINE?
	BEQ make_cr
	CPY #$FF				; EOF?
	BNE do_in
make_cr:
		LDY #13				; convert UNIX newline to CONIO/minimOS
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
	CPY #13					; check for CONIO/minimOS NEWLINE
	BNE do_aux_out
		LDY #10				; convert to UNIX LF
do_aux_out:
	STY $DF93				; send char to VSP
	RTS

-aux_load:					; *** prepare things for LOAD, Carry if not possible ***
	JSR set_name
	BCS auxl_end			; do nothing in case of error
		LDA #PSV_FREAD
		STA $DF94			; will use open file for reading
		CLC
auxl_end:
	RTS

-aux_save:					; *** prepare things for SAVE, Carry if not possible ***
	JSR set_name
	BCS auxs_end			; do nothing in case of error
		LDA #PSV_FWRITE
		STA $DF94			; will use open file for writing
		CLC					; all OK this far!
auxs_end:
	RTS

-aux_close:					; *** tidy up after SAVE ***
	LDA #PSV_FCLOSE
	STA $DF94				; tell VSP to close file
	RTS						; nothing to do this far

set_name:
	LDA #PSV_FOPEN
	STA $DF94				; set VSP mode for setting filename
; ask for the filename, or $ for directory listing
	LDX #0
prompt_l:
		LDY aux_prompt, X
		BEQ ask_name
		PHX
		JSR conio			; display prompt string
		PLX
		INX
		BNE prompt_l
ask_name:
	JSR LAB_INLN
	STX ut1_pl
	STY ut1_ph				; set indirect pointer
; *** might check here for '$' of directory listing request

; send filename to VSP
	LDY #0
name_l:
		LDA (ut1_pl), Y		; get char
		BEQ name_ok			; until termination
		STA $DF93			; send name character to VSP
		INY					; eeeeeek
		DEX
		BNE name_l
name_ok:
	CLC						; name was OK
	RTS

aux_prompt:
	.asc	"Filename", 0

