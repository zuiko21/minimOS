; Interrupt-based polyphonic player for Durango-X
; (c) 2022 Carlos J. Santisteban
; last modified 20220414-2246

#include "../../macros.h"
#include "../../zeropage.h"

; constant for max number of voices
#define	MAXVOICE	4

; *** some global definitions ***
IOBeep	= $DFB0

; *** input parameters ***
.bss
*	= $300					; hopefully a safe address!

voices		.byt	0		; number of active voices (set 0 to disable and reset all channels)
tempo		.byt	0		; tempo setting (number of 4ms interrupts between semiquavers, 31 means b=119)
; might add pointers to note lists

; *** local variables ***
wait		.byt	0		; remaining interrupts to trigger play (countdown from tempo)
index		.dsb	MAXVOICE, 0		; note position in its queue (from $0303)
count		.dsb	MAXVOICE, 0		; remaining times to play this note

; *** installation code ***
.text
*	= $400					; safe download address

; reset all structures
	JSR restore				; clears count & index arrays, plus voices variable, just in case
	LDY #<mp_isr			; interrupt handler!
	LDA #>mp_isr
	STY fw_isr				; set interrupt vector ** does NOT respect previous routines **
	STA fw_isr+1
; for demo purposes, set some test values
	LDA #31					; crotchet = 119
	STA tempo
	LDA #3					; number of voices
	STA voices
	CLI						; make sure interrupts are on!
	RTS						; return to shell

; *** interrupt handler ***
mp_isr:
; usual transparency stuff
	PHA
	_PHX
	_PHY
; check whether player is enabled
	LDX voices
	BEQ mp_stop				; will reset and shutoff player
; * otherwise go on playing! *
		DEC wait			; but check first if it's time to play anything
	BNE mp_exit				; not yet
		LDA tempo
		STA wait			; it's time to play, thus preset this counter for the next time
		DEX					; make control arrays 0...voices-1
; voice routine (will try to index them)
vloop:
		LDA count, X		; note still active?
		BNE cont
			INC index, X
chk:
			LDA index, X	; cursor for first voice
			TAY
			LDA c1d, Y		; get duration for
			BNE cont1		; still within list limits
				STA index, X		; otherwise reset index (A known to have zero)
				BEQ chk		; ...and try again
cont: 
			STA count, X	; reset counter
			_PHX			; will affect X right now, play routine will save Y
			LDX c1p, Y		; get pitch for this note
		BEQ vend			; if it's a rest, try next note
			JSR play		; otherwise play for 4 cycles
vend:
			_PLX
			DEC count, X	; one slot less remains (will check later)
		DEX
		BPL vloop			; next voice
	BMI mp_exit				; this slot completed, do not reset anything
; * exit player if no active voices remain! *
mp_stop:
	JSR restore				; to stop playing, all structures must be reset
mp_exit:
; restore stuff before exit
	_PLY
	_PLX
	PLA
	RTI

; *** useful stuff ***
restore:
	LDX #MAXVOICE-1			; number of elements per array
	LDA #0					; NMOS savvy
res_loop:
		STA index, X		; restart list...
		STA count, X		; ...and current note
		DEX
		BPL res_loop
	STA voices				; essential to keep player stopped
	LDA tempo
	STA wait				; slight, but controlled delay at start
	RTS

play:
	TXA
	PHA						; needs a copy of X in A anyway, thus no PHX
	LDY #8					; number of semicycles to play (may be computed depending on pitch)
cyloop:
		TAX					; retrieve pitch cycles
ploop:
			DEX
			JSR delay		; 12t extra
;			STY IOBeep		; 4t extra (for 9x+10, min ~333 Hz)
			BNE ploop		; this takes (17X+10)t per semicycle (min ~177 Hz)
		DEY
		STY IOBeep			; toggle speaker 
		BNE cyloop
	_PLX
delay:
	RTS

; *** music score *** note labels
; format for tone list (c·p) is delay cycles (total time= n*6.51µs?), 0 if silence
; format for duration list (c·d) is number of interrupt slots (1=semiquaver... 16=whole), 0 means go back to start
c1p:
	.byt	0				; (at least one rest if empty)
c1d:
	.byt	1, 0	; end as loop
c2p:
	.byt	0				; (at least one rest if empty)
c2d:
	.byt	1, 0	; end as loop
c3p:
	.byt	0				; (at least one rest if empty)
c3d:
	.byt	1, 0	; end as loop
c4p:
	.byt	0				; (at least one rest if empty)
c4d:
	.byt	1, 0	; end as loop
