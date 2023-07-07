; interrupt-driven music player for PSG card in Durango-X!
; (c) 2023 Carlos J. Santisteban
; last modified 20230707-1833

; *** constants definition ***

#define	MAX_ATT	15
#define	ENV_CYC	10

; *** hardware definitions ***

IO_PSG	= $DF98;DFDB				; standard mono/central PSG address

; *** zeropage definitions ***
ptr		= $FC				; shall be reloaded with current channel desired list

; *** memory usage ***
pb_flag	= $280				; playback channel enable flag *** apparently safe address
rem_len	= pb_flag + 1		; remaining length in ticks *** init to 1!
c_index	= rem_len + 4		; cursor index (currently up to 256 notes, alas)
set_vol	= c_index + 4		; desired volume (0=SILENT, 15=max)
cur_vol	= set_vol + 4		; current volume for envelopes
e_type	= cur_vol + 4		; envelope type (-1=decay, 0=sustain, 1=attack)
irq_cnt	= e_type + 4		; interrupt count for envelopes

;SCORE	= $50				; initial page for score data (may be ROMmable)

; *****************
; *** init code ***
; *****************
psg_init:
	STZ pb_flag				; no channels at startup!
	LDX #3
linl:
		STZ rem_len, X		; fill 'em all
		STZ c_index, X		; also reset cursors
		DEX
		BPL linl
; routine for muting the PSG
quiet:
	CLC
	LDA	#%10011111			; set ch1 volume to zero (max. att.)
qt_loop:
		STA IO_PSG
		JSR delay			; eeeek
		JSR delay
JSR delay	; just in case for 1 MHz
jsr delay
		ADC #32				; next channel
		BMI qt_loop
	RTS

; **********************
; *** interrupt task ***
; **********************
psg_isr:
	LDX pb_flag				; max authorised channel index, should noise be treated differently?
	BEQ quiet				; actually exit (and mute!) if all disabled
		DEX
		CPX #4				; was valid value (1...4)?
	BCS quiet				; if not, just go away, muting just in case
chan_l:
		LDA rem_len, X		; still playing?
	BNE env_ctl
; actual stuff, new note for this channel!
new_note:
		LDY c_index, X		; cursor for this channel
		LDA len_pg, X		; get length list page eeeek
		STA ptr+1
		STZ ptr				; assume LSB is always zero!
		LDA (ptr), Y		; note length
		BNE no_wrap
			STA c_index, X	; back to beginning of this channel
			BEQ new_note	; and try again
no_wrap:
		DEC					; always total length minus one!
		STA rem_len, X		; store into counter
		LDA vol_pg, X		; get volume list page eeeeeek
		STA ptr+1
;		STZ ptr				; assume LSB is always zero!
		LDA (ptr), Y		; get volume
		STA set_vol, X
		STA cur_vol, X		; sustain and decay start at this value...
		LDA env_pg, X		; get envelope list page eeeeek
		STA ptr+1
;		STZ ptr				; assume LSB is always zero!
		LDA (ptr), Y		; get envelope type (1 for Attack, -1 for Decay, 0 for sustain)
		STA e_type, X		; store it
		BMI not_attack
		BEQ not_attack
			STZ cur_vol, X	; ...but attack notes start at zero
not_attack:
		LDA cur_vol, X		; set current volume
		EOR #MAX_ATT		; convert into attenuation value, as used by PSG
		ORA cmd_svol, X
		STA IO_PSG
JSR delay
JSR delay
jsr delay
jsr delay
		LDA note_pg, X		; get note list page eeeeek
		STA ptr+1
;		STZ ptr				; assume LSB is always zero!
		LDA (ptr), Y		; note index
		TAY					; use as frequency index
		LDA freq_l, Y		; 4LS bits
		ORA cmd_snote, X	; convert into command
		STA IO_PSG
; make sure there are at least 32 cycles between writes
		INC c_index, X		; advance cursor (7)
		JSR delay			; should suffice (12+5)
JSR delay	; needed at 1 MHz
jsr delay
jsr delay
		LDA freq_h, Y		; 6MS bits (4)
		STA IO_PSG			; frequency is set (4)
		BRA task_exit		; prepare envelope counter and finish this channel
env_ctl:
; try updating envelope
		DEC rem_len, X		; advance timer for this channel, as it's playing
		LDY e_type, X		; 1 for Attack, -1 for Decay, 0 for sustain
		BEQ next_ch			; sustain uses no envelope *** maybe step_env enables clean restart
			BPL is_attack
				LDA cur_vol, X			; if decay, check current volume
		BEQ next_ch			; already off, do nothing
			BNE step_env
is_attack:
				LDA cur_vol, X			; already at set volume?
				CMP set_vol, X
			BEQ task_exit	; if so, do nothing
step_env:
			TYA				; recover envelope step as must be added to volume
			LDY irq_cnt, X	; is it time for it?
		BNE count_irq
			CLC
			ADC cur_vol, X
			AND #MAX_ATT	; eeeeeek
			STA cur_vol, X	; otherwise update current volume
			ORA cmd_svol, X	; convert into PSG command
			EOR #MAX_ATT	; convert into attenuation value, as used by PSG
			STA IO_PSG		; * don't think I need to wait until 32 cycles passed *
jsr delay ; just in case
jsr delay
jsr delay
;			BRA next_ch		; eeeeeeek
task_exit:
		LDA #ENV_CYC
		STA irq_cnt, X		; refresh counter for next
		BNE next_ch
count_irq:
		DEC irq_cnt, X		; update for next
next_ch:
		DEX
	BMI finish
		JMP chan_l			; down to zero, included
delay:
finish:
	RTS						; back to ISR handler

; *******************
; *** data tables ***
; *******************
; PSG-command masks
cmd_snote:
	.byt	%10000000, %10100000, %11000000, %11100000
cmd_svol:
	.byt	%10010000, %10110000, %11010000, %11110000
; pointers to page-aligned score tables in RAM, usually just below screen 3 (4K total)
; could add more tables for the LSB, for some space saving...
note_pg:
	.byt	SCORE,		SCORE+4,	SCORE+8,	SCORE+12
len_pg:
	.byt	SCORE+1,	SCORE+5,	SCORE+9,	SCORE+13
vol_pg:
	.byt	SCORE+2,	SCORE+6,	SCORE+10,	SCORE+14
env_pg:
	.byt	SCORE+3,	SCORE+7,	SCORE+11,	SCORE+15
; note index to period conversion (C2 to B6)
;			C	C#	D	D#	E	F	F#	G	G#	A	A#	B
freq_h:
	.byt	45, 43, 40, 38, 36, 34, 32, 30, 28, 27, 25, 24	; octave 2
	.byt	22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 12	; octave 3
	.byt	11, 10, 10,  9,  9,  8,  8,  7,  7,  6,  6,  6	; octave 4
	.byt	 5,  5,  5,  4,  4,  4,  4,  3,  3,  3,  3,  3	; octave 5
	.byt	 2,  2,  2,  2,  2,  2,  2,  1,  1,  1,  1,  1	; octave 6
freq_l:
	.byt	14,  5, 14,  9,  7,  6,  7, 10, 14,  4, 12,  5	; octave 2
	.byt	15, 10,  7,  5,  3,  3,  3,  5,  7, 10, 14,  2	; octave 3
	.byt	 7, 13,  3, 10,  2,  9,  2, 10,  4, 13,  7,  1	; octave 4
	.byt	12,  7,  2, 13,  9,  5,  1, 13, 10,  7,  3,  1	; octave 5
	.byt	14, 11,  9,  7,  4,  2,  0, 15, 13, 11, 10,  8	; octave 6
