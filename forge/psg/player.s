; interrupt-driven music player for PSG card in Durango-X!
; (c) 2023 Carlos J. Santisteban
; last modified 20230705-1008

; *** constants definition ***

#define	MAX_ATT	15
#define	ENV_CYC	10
; initial page for score data (may be ROMmable)
#define	SCORE	$50

; *** hardware definitions ***

IO_PSG	= $DFDB				; standard mono/central PSG address

; *** zeropage definitions ***
ptr		= $FC				; shall be reloaded with current channel desired list

; *** memory usage ***
pb_flag	= $280				; playback enable flag *** apparently safe address
rem_len	= pb_flag + 1		; remaining length in ticks *** init to 1!
c_index	= rem_lgt + 4		; cursor index (currently up to 256 notes, alas)
set_vol	= c_index + 4		; desired volume (0=SILENT, 15=max)
cur_vol	= set_vol + 4		; current volume for envelopes
e_type	= cur_vol + 4		; envelope type (-1=decay, 0=sustain, 1=attack)



; *****************
; *** init code ***
; *****************


; **********************
; *** interrupt task ***
; **********************
psg_isr:
.(
	LDX #3					; max channel index, should noise be treated differently?
chan_l:
		DEC rem_len, X		; still playing?
	BNE env_ctl
; actual stuff, new note for this channel!
		LDY c_index, X		; cursor for this channel
		LDA len_pg, Y		; get length list page
		STA ptr+1
;		STZ ptr				; assume LSB is always zero!
		LDA (ptr), Y		; note length
		BNE no_wrap
			STA c_index, X	; back to beginning of this channel
no_wrap:
		STA rem_len, X		; store into counter
		LDA vol_pg, Y		; get volume list page
		STA ptr+1
;		STZ ptr				; assume LSB is always zero!
		LDA (ptr), Y		; get volume
		STA set_vol, X
		STA cur_vol, X		; sustain and decay start at this value...
		LDA env_pg, Y		; get envelope list page
		STA ptr+1
;		STZ ptr				; assume LSB is always zero!
		LDA (ptr), Y		; get envelope type (-1 attack, 0 sustain, 1 decay)****
		STA e_type, X		; store it
		BMI not_attack
		BEQ not_attack
			STZ cur_vol, X	; ...but attack notes start at zero
not_attack:
		LDA cur_vol, X		; set current volume
		EOR #MAX_ATT		; convert into attenuation value, as used by PSG
		ORA cmd_svol, X
		STA IO_PSG
		LDA note_pg, Y		; get note list page
		STA ptr+1
;		STZ ptr				; assume LSB is always zero!
		LDA (ptr), Y		; note index
		PHX
		TAX					; use as frequency index
		LDA freq_l, X		; 4LS bits
		LDY freq_h, X		; 6MS bits
		PLX
		ORA cmd_snote, X	; convert into command
		STA IO_PSG
; make sure there are at least 32 cycles between writes
		INC c_index, X		; advance cursor (7)
		JSR delay
		JSR delay			; (12+12, plus 4 of store should be OK)
		STY IO_PSG			; frequency is set
		BRA task_exit		; prepare envelope counter and finish this channel
env_ctl:
; try updating envelope
		DEC irq_cnt, X		; is it time for it?
		BNE next_ch
			CLC
			LDA e_type, X	; 1 for Attack, -1 for Decay, 0 for sustain
			BEQ next_ch		; sustain uses no envelope *** maybe step_env enables clean restart
			BPL is_attack
				LDY cur_vol, X			; if decay, check current volume
			BEQ next_ch		; already off, do nothing
		BNE step_env
is_attack:
				TAY
				LDA cur_vol, X			; already at set volume?
				CMP set_vol, X
			BEQ next_ch		; if so, do nothing
				TYA
step_env:
			ADC cur_vol, X
			AND #MAX_ATT				; eeeeeek
			STA cur_vol, X				; otherwise update current volume
			ORA cmd_svol, X				; convert into PSG command
			EOR #MAX_ATT				; convert into attenuation value, as used by PSG
			STA IO_PSG					; * don't think I need to wait until 32 cycles passed *
task_exit:
			LDA #ENVCYC
			STA irq_cnt, X	; refresh counter for next
next_ch:
		DEX
		BPL chan_l			; down to zero, included
delay:
	RTS						; back to ISR handler

; *******************
; *** data tables ***
; *******************
cmd_snote:
	.byt	%10000000, %10100000, %11000000, %11100000
cmd_svol:
	.byt	%10010000, %10110000, %11010000, %11110000
; pointers to page-aligned score tables in RAM, usually just below screen 3 (4K total)
note_pg:
	.byt	SCORE,		SCORE+4,	SCORE+8,	SCORE+12
len_pg:
	.byt	SCORE+1,	SCORE+5,	SCORE+9,	SCORE+13
vol_pg:
	.byt	SCORE+2,	SCORE+6,	SCORE+10,	SCORE+14
env_pg:
	.byt	SCORE+3,	SCORE+7,	SCORE+11,	SCORE+15
; could add more tables for the LSB, for some space saving...
.)
