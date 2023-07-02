; interrupt-driven music player for PSG card in Durango-X!
; (c) 2023 Carlos J. Santisteban
; last modified 20230703-0115

; *** constants definition ***

#define	MAX_ATT	15
#define	ENV_CYC	10

; *** hardware definitions ***

IO_PSG	= $DFDB				; standard mono/central PSG address

; *** zeropage definitions ***

; *** memory usage ***

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
		DEC rem_lgt, X		; still playing?
	BNE env_ctl
; actual stuff, new note for this channel!
		LDY c_index, X		; cursor for this channel
		LDA length, Y		; note length
		BNE no_wrap
			STA c_index, X	; back to beginning of this channel
no_wrap:
		STA rem_lgt, X		; store into counter
		LDA volume, Y		; get attenuation (0=max volume, 15=off)
		STA set_vol, X
		STA cur_vol, X		; sustain and decay start at this value...
		LDA envelope, Y		; get envelope type (-1 attack, 0 sustain, 1 decay)
		STA e_type, X		; store it
		BPL not_attack
			LDA #MAX_ATT
			STA cur_vol, X	; ...but attack notes start at zero
not_attack:
		LDA cur_vol, X		; set current volume
		ORA cmd_svol, X
		STA IO_PSG
		PHX
		LDX note, Y			; note index
		LDA freq_l, X		; 4LS bits
		LDY freq_h, X		; 6MS bits
		PLX
		ORA cmd_snote, X	; convert into command
		STA IO_PSG
; make sure there are at least 32 cycles between writes
		STY IO_PSG			; frequency is set
		INC c_index, X		; advance cursor
		BRA task_exit		; prepare envelope counter and finish this channel
env_ctl:
; try updating envelope
		DEC irq_cnt, X		; is it time for it?
		BNE next_ch
			CLC
			LDA e_type, X	; -1 for Attack, 1 for Decay, 0 for sustain
			BEQ next_ch		; sustain uses no envelope
			BMI is_attack
				LDY cur_vol, X			; if decay, check current attenuation
				CPY #MAX_ATT			; check against max. attenuation (15)
		BEQ next_ch						; already off, do nothing
			BNE step_env
is_attack:
			TAY
			LDA cur_vol, X	; already at set volume?
			CMP set_vol, X
		BEQ next_ch			; if so, do nothing
			TYA
step_env:
			ADC cur_vol, X
			AND #MAX_ATT				; eeeeeek
			STA cur_vol, X				; otherwise update current volume
			ORA cmd_svol, X				; convert into PSG command
			STA IO_PSG					; * don't think I need to wait until 32 cycles passed *
task_exit:
			LDA #ENVCYC
			STA irq_cnt, X	; refresh counter for next
next_ch:
		DEX
		BPL chan_l			; down to zero, included
	RTS						; back to ISR handler

; *******************
; *** data tables ***
; *******************
cmd_snote:
	.byt	%10000000, %10100000, %11000000, %11100000
cmd_svol:
	.byt	%10010000, %10110000, %11010000, %11110000
.)
