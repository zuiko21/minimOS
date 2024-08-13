; Interrupt-driven SN76489 PSG player for Durango-X
; assume all registers saved, plus 'ticks' (usually $206) updated!
; (c) 2024 Carlos J. Santisteban
; last modified 20240813-1420

; use -DSCORE to activate the score reader task!

; ****************************
; *** hardware definitions ***
; ****************************

IO_PSG	= $DFDB

; **************************
; *** external interface ***
; **************************
; SCORE PLAYER
;sr_c1		.word			; pointer to Channel 1 score
;							; groups of three bytes
;							; terminator byte = 0 for END of score, 128...255 for REPEAT (nominally $FF)
;							; first byte = note (1...63/127 chromatic scale)
;							; * may use 64 as PCM, 65...127 for alternative tuning
;							; * could use 128...254 for more alternative indices as well
;							; second byte = envelope and volume (%eeeevvvv, where e>0 is decay, e<0 is soft attack, e=0 is constant; v=0 is silent, max. 15)
;							; third byte = length (in jiffies, $00=256)
;sr_c2		.word			; same for channel 2
;sr_c3		.word			; same for channel 3
;sr_nc		.word			; pointer to noise channel, same as above except
;							; "note", which is %01000frr (see below)

; SCALE
; Score readers converts note index into 10-bit value for PSG
; Maximum value is $1FF (TURBO mode will turn it into $3FE)
; this makes a minimum 107 Hz on v2, which fits [1]=A2, [63]=B7, albeit notes over F7 are quite off
; v1 plays ~1 tone lower, with 2 MHz overclock ~1 tone higher, not worth considering

; COMMON INTERFACE
;sr_ena		.byt			; enable/pause channels %n321n321, where high nybble controls score run (%1=run) and low nybble controls muting (%0=mute)
;sg_turbo	.byt			; d7 is on for faster machines (remaining bits reserved, nominally 0)

; SOUND GENERATOR
;sg_c1l		.byt			; channel 1 period low-order 4 bits  %0000llll
;sg_c1h		.byt			; channel 1 period high-order 6 bits %00hhhhhh
;sg_c1ve	.byt			; channel 1 envelope and volume, see score player format
;sg_c2l		.byt			; ditto for channel 2
;sg_c2h		.byt
;sg_c2ve	.byt
;sg_c3l		.byt			; ditto for channel 3
;sg_c3h		.byt
;sg_c3ve	.byt
;sg_nc		.byt			; noise channel rate and feedback, %00000frr
;sg_nve		.byt			; noise channel envelope and volume, same as above

; ****************************
; *** constants definition ***
; ****************************

; ***************************
; *** zeropage allocation ***
; ***************************
;sr_ptr		.word			; score reader pointer (will keep LSB as zero)

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

task_exit:

; ** ** after the module, finish the ISR the usual way ** **
; ** ** you migh want to check for BRK as well         ** **
; *** assume commented code below as the bare minimum ***

;	PLY
;	PLX
;	PLA
;	RTI
