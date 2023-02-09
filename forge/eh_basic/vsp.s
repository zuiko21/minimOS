; Virtual Serial Port driver module for EhBASIC (under perdita)
; (c) 2023 Carlos J. Santisteban
; last modified 20230209-2258

#echo "Using Virtual Serial Port for LOAD/SAVE"

#define	PSV_FOPEN	$11
#define	PSV_FREAD	$12
#define	PSV_FWRITE	$13
#define	PSV_FCLOSE	$1F

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
	LDA #PSV_FOPEN
	STA $DF94				; set VSP mode for setting filename
; must emit filename, placeholder below
	LDX #0
name_l:
		LDA filename, X		; get char
		BEQ name_ok			; until termination
		STA $DF93			; send name character to VSP
		INX					; eeeeeek
		BNE name_l
name_ok:
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
