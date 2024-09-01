; Interrupt-driven SN76489 PSG player for Durango-X
; assume all registers saved, plus 'ticks' (usually $206) updated!
; (c) 2024 Carlos J. Santisteban
; last modified 20240901-1959

; use -DSCORE to activate the score reader task!

; ****************************
; *** hardware definitions ***
; ****************************

-IO_PSG	= $DFDB

; **************************
; *** external interface ***
; **************************

#ifdef	SCORE
; SCORE PLAYER					supply address sr_if, returns sr_end
sr_c1	= sr_if				; pointer to Channel 1 score
;							; groups of three bytes
;							; terminator byte = 0 for END of score, 128...255 for REPEAT (nominally $FF)
;							; first byte = note (1...63/127 chromatic scale)
;							; * may use 64 as PCM, 65...127 for alternative tuning
;							; * could use 128...254 for more alternative indices as well
;							; second byte = envelope and volume (%eeeevvvv, where e>0 is decay, e<0 is soft attack, e=0 is constant; v=0 is silent, max. 15)
;							; third byte = length (in jiffies, $00=256)
sr_c2	= sr_c1+2			; same for channel 2
sr_c3	= sr_c2+2			; same for channel 3
sr_nc	= sr_c3+2			; pointer to noise channel, same as above except
;							; "note", which is %01000frr (see below)
sr_ena	= sr_nc+2			; enable/pause channels %n321n321, where high nybble controls score run (%1=run) and low nybble controls muting (%0=mute)
sr_rst	= sr_ena+1			; reset (and preload address) channels %xxxxn321 (%1=reset), will be automatically reset
sr_tempo= sr_rst+1			; tempo divider (234.375 bpm/n+1)
sr_end	= sr_tempo+1		; * * * sr_end = sr_if+11 * * *

; SCALE
; Score readers converts note index into 10-bit value for PSG
; Maximum value is $1FF (TURBO mode will turn it into $3FE)
; this makes a minimum 107 Hz on v2, which fits [1]=A2, [63]=B7, albeit notes over F7 are quite off
; v1 plays ~1 tone lower, with 2 MHz overclock ~1 tone higher, not worth considering
#endif

; SOUND GENERATOR				supply address psg_if, returns psg_end
sg_turbo	= psg_if		; d7 is on for faster machines (remaining bits reserved, nominally 0)
sg_envsp	= sg_turbo+1	; envelope update in ticks (typically 16 for max. 1s envelope)
; note indexing-savvy addresses
sg_c1ve		= sg_envsp+1	; channel 1 envelope and volume, see score player format
sg_c2ve		= sg_c1ve+1		; channel 2
sg_c3ve		= sg_c2ve+1		; channel 3
sg_nve		= sg_c3ve+1		; noise channel envelope and volume, same as above
sg_c1l		= sg_nve+1		; channel 1 period low-order 4 bits  %0000llll
sg_c2l		= sg_c1l+1		; ditto for channel 2
sg_c3l		= sg_c2l+1		; ditto for channel 3
sg_nc		= sg_c3l+1		; noise channel rate and feedback, %00000frr
sg_c1h		= sg_nc+1		; channel 1 period high-order 6 bits %00hhhhhh
sg_c2h		= sg_c1h+1		; ditto for remaining channels
sg_c3h		= sg_c2h+1
; noise channel has no second tone value
psg_end		= sg_c3h+1		; * * * psg_end = psg_if+13 * * *

; ****************************
; *** constants definition ***
; ****************************

; ***************************
; *** zeropage allocation ***
; ***************************
-sr_ptr	= $FC				; Score player NEEDS this in zeropage (will keep LSB as zero)

; *************************
; *** memory allocation ***
; *************************
;sr_p1		.word			; pointer to current position on channel 1 score
;sr_p2		.word			; pointer to current position on channel 2 score
;sr_p3		.word			; pointer to current position on channel 3 score
;sr_np		.word			; pointer to current position on noise score
;

; *****************
; *** main code ***
; *****************
; ** ** this is to be inserted into a regular ISR ** **
; *** assume commented code below as the bare minimum ***

;	PHA
;	PHX
;	PHY						; save full status
;	INC ticks				; increment jiffy counter (typically at $0206)
;;	BNE jiffies				; usually will use more bytes, but not needed for this
;;	INC ticks+1
;;	BNE jiffies
;;	INC ticks+2
;;	BNE jiffies
;;	INC ticks+3
;;jiffies:

; ****************************
; *** sound generator task ***
; ****************************
; check for new note on noise channel
	LDX #3					; max channel offset, will scan backwards
ch_upd:
		LDA sg_c1l, X		; anything new?
		BEQ nx_cht
; update tone
			STZ sg_c1l, X	; clear this entry for next time
			ORA ch_lowt, X	; will set low-order tone
			STA IO_PSG
			CPX #3			; noise channel...
			BEQ ch_noise	; ...has no high order bits
				LDA sg_c1h, X			; now for high order bits
				JSR delay24				; is this enough?
				STA IO_PSG
ch_noise:
; update volume settings
			LDA sg_c1ve, X	; this is envelope (MSN) and volume (LSN)
			BMI cc_attk		; negative envelope is slow attack, start at zero
				AND #$0F				; otherwise start at current volume
				STZ psg_ct, X			; eventually will fade out
				BRA set_cv
cc_attk:
			AND #$0F		; if slow attack, this will be target volume instead
			STA psg_ct, X
			LDA #0			; default null volume
set_cv:
			STA psg_cv, X	; this is current volume
			ORA ch_vol, X	; will set volume
			EOR #%00001111	; invert bits for attenuation!
			JSR delay		; 12t should suffice
			STA IO_PSG		; send to PSG!
			LDA sg_envsp	; get generic envelope speed
			STA psg_ce, X	; store into this channel envelope timer
			JSR delay24		; may need this before next
nx_cht:
		DEX					; one less to go
		BPL ch_upd
; now let's update volume according to envelopes
	LDX #3					; max channel offset, will scan backwards
ev_upd:
		LDA psg_ce, X		; time for update?
		BNE nx_env
			LDA sg_envsp	; yes, reload timer
			STA psg_ce, X
; do actual envelope ********
			BRA env_ok
nx_env:
		DEC psg_ce, X		; one less to go
env_ok:
		DEX
		BPL ev_upd

#ifdef	SCORE
; *************************
; *** score reader task ***
; *************************

#endif
	JMP task_exit			; skip all data before returning!

; ********************
; *** data segment ***
; ********************
; indexed-note periods, calibrated for 1.75 MHz
ni_low:						; indexed note values 4-bit LSB, A2-B7
	.byt	 0,  1,  5, 11	; A2-B2, note padding [0]
	.byt	 2, 11,  4,  0, 12,  9,  8,  7,  7,  9, 11, 13	; C3-B3
	.byt	 1,  5, 10,  0,  6, 13,  4, 12,  4, 12,  5, 15	; C4-B4
	.byt	 9,  3, 13,  8,  3, 14, 10,  6,  2, 14, 11,  7	; C5-B5
	.byt	 4,  1, 15, 12,  9,  7,  5,  3,  1, 15, 13, 12	; C6-B6
	.byt	10,  9,  7,  6,  5,  4,  2,  1,  0,  0, 15, 14	; C7-B7
ni_hi:						; indexed note values 6-bit MSB, A2-B7
	.byt	 0, 31, 29, 27	; A2-B2, note padding [0]
	.byt	26, 24, 23, 22, 20, 19, 18, 17, 16, 15, 14, 13	; C3-B3
	.byt	13, 12, 11, 11, 10,  9,  9,  8,  8,  7,  7,  6	; C4-B4
	.byt	 6,  6,  5,  5,  5,  4,  4,  4,  4,  3,  3,  3	; C5-B5
	.byt	 3,  3,  2,  2,  2,  2,  2,  2,  2,  1,  1,  1	; C6-B6
	.byt	 1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0	; C7-B7 
; NOTE; octave 7 will be poorly tuned, unless you use values for TURBO only
 
task_exit:
; ** ** after the module, finish the ISR the usual way ** **
; ** ** you migh want to check for BRK as well         ** **
; *** assume commented code below as the bare minimum    ***

;	PLY
;	PLX
;	PLA
;	RTI
