; Interrupt-based polyphonic player for Durango-X
; (c) 2022 Carlos J. Santisteban
; last modified 20220418-0036

#include "../../OS/macros.h"
#include "../../OS/zeropage.h"

#define	CHUNK	_CHUNK

; constant for max number of voices
#define	MAXVOICE	4

; *** some global definitions ***
fw_isr	= $0200				; ROM standard
IOBeep	= $DFB0

; *** zeropage ***
.zero
; will use system-defined sysprt -- for interrupts only!
; also systmp (plus adjacent sys_sp) for performance reasons

; *** input parameters ***
.bss
#ifdef	CHUNK
*	= $5FF0
#else
*	= $300					; hopefully a safe address!
#endif

voices		.byt	0		; number of active voices (set 0 to disable and reset all channels)
tempo		.byt	0		; tempo setting (number of 4ms interrupts between semiquavers, 31 means b=119)
; really needs pointers to note lists
;pptarr		.dsb	2*MAXVOICE, 0	; 4 pointers to pitch lists
;dptarr		.dsb	2*MAXVOICE, 0	; 4 pointers to duration lists


; *** local variables ***
wait		.byt	0		; remaining interrupts to trigger play (countdown from tempo)
index		.dsb	MAXVOICE, 0		; note position in its queue (from $0303)
count		.dsb	MAXVOICE, 0		; remaining times to play this note

; *** installation code ***
.text
#ifdef	CHUNK
*	= $D000					; install address
#else
*	= $400					; safe download address
#endif

; reset all structures
	JSR restore				; clears count & index arrays, plus voices variable, just in case
	LDY #<mp_isr			; interrupt handler!
	LDA #>mp_isr
	SEI						; some critical section!
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
		BNE cont			; keep playing it
			INC index, X	; otherwise advance to next note
; * must copy appropriate pointer(s) *
			TXA
			ASL				; voice index times two for pointer load
			TAY
			LDA dptarr, Y	; copy LSB
			STA sysptr		; temporary!
			LDA dptarr+1, Y	; copy MSB too
			STA sysptr+1
			LDA pptarr, Y	; do the same for pitch list pointer
			STA systmp
			LDA pptarr+1, Y
			STA systmp+1	; actually sys_sp
; * now will use (sysptr), Y instead of c1d, Y and (systmp), Y instead of c1p, Y *
chk:
			LDY index, X	; cursor for current voice
			LDA (sysptr), Y	; get duration
			BNE cont		; still within list limits
				STA index, X		; otherwise reset index (A known to have zero)
				BEQ chk		; ...and try again
cont: 
			STA count, X	; reset counter if needed
			_PHX			; will affect X right now, play routine will save Y
			LDA (systmp), Y	; get pitch for this note
		BEQ vend			; if it's a rest, try next note
; otherwise play for 4 cycles *** inlined ***
; *******************************************
#ifdef	NMOS
			TAX				; needs both A & X equal
			TYA
			PHA				; save Y
			TXA				; needs a copy of X in A anyway
#else
			PHY				; X already saved, A will be transferred to X
#endif
			LDY #8			; number of semicycles to play (may be computed depending on pitch)
cyloop:
				TAX			; retrieve pitch cycles
ploop:
					DEX
					JSR delay		; 12t extra
					BNE ploop		; this takes (17X+10)t per semicycle (min ~177 Hz)
				DEY
				STY IOBeep	; toggle speaker 
				BNE cyloop
			_PLY
; *******************************************
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
	LDY #MAXVOICE-1			; number of elements per array
res_loop:
		LDA #$FF			; eeeeeeeek, unfortunately STX only Y-indexed in ZP anyway
		STA index, Y		; restart list...
		LDA #0				; NMOS savvy
		STA count, Y		; ...and current note
		DEY
		BPL res_loop
	STA voices				; essential to keep player stopped
	LDA tempo
	STA wait				; slight, but controlled delay at start
delay:
	RTS

; *** list pointers *** should be at known RAM address
pptarr:
	.word	c1p
	.word	c2p
	.word	c3p
	.word	0
dptarr:
	.word	c1d
	.word	c2d
	.word	c3d
	.word	0

; *** music score *** note labels
; format for pitch list (c·p) is delay cycles, 0 means rest
; format for duration list (c·d) is number of interrupt slots (1=semiquaver... 16=whole), 0 means go back to start
c1p:
	.byt	136,0,136,0,136,0,			115,0,230,0
	.byt	115,0,136,0,172,0,			129,0,115,0,122,129,0
	.byt	136,0,86,68,64,0,76,68,		0,86,0,102,91,115,0
	.byt	172,0,115,0,86,0,			129,0,86,0,129,0
	.byt	172,0,115,0,115,86,			0,32,0,32,0,115,0
	.byt	172,0,115,0,86,0,			129,0,86,0,129,0
	.byt	172,0,108,0,96,0,			86,0,112,0,172,0
c1d:
	.byt	2,1,1,1,2,1,				1,3,1,3
	.byt	1,2,1,2,1,2,				1,1,1,1,1,1,1
	.byt	1,1,1,1,1,1,1,1,			1,1,1,1,1,1,2
	.byt	1,2,1,2,1,1,				1,2,1,2,1,1
	.byt	1,2,1,2,1,1,				1,1,1,2,1,1,1
	.byt	1,2,1,2,1,1,				1,2,1,2,1,1
	.byt	1,1,1,2,1,2,				1,2,2,1,1,1
	.byt	0				; end as loop
c2p:
	.byt	60,0,60,0,60,0,				45,0,57,0
	.byt	68,0,86,0,115,0,			86,0,76,0,81,86,0
	.byt	86,0,57,45,43,0,51,45,		0,51,0,68,64,76,0
	.byt	34,36,38,45,0,43,			0,68,64,57,0,86,68,64
	.byt	0,34,36,38,45,0,43,			0,28,0,28,0
	.byt	34,36,38,45,0,43,			0,68,64,57,0,86,68,64
	.byt	0,54,0,64,0,				68,0
c2d:
	.byt	2,1,1,1,2,1,				1,3,1,3
	.byt	1,2,1,2,1,2,				1,1,1,1,1,1,1
	.byt	1,1,1,1,1,1,1,1,			1,1,1,1,1,1,4
	.byt	1,1,1,1,1,1,				1,1,1,1,1,1,1,1
	.byt	2,1,1,1,1,1,1,				1,1,1,2,5
	.byt	1,1,1,1,1,1,				1,1,1,1,1,1,1,1
	.byt	2,1,2,1,2,					1,7
	.byt	0				; end as loop
c3p:
	.byt	34,0,34,0,43,34,0,			28,0
	.byt	43,0,57,0,68,0,				51,0,45,0,48,51,0
	.byt	57,0,34,28,25,0,32,28,		0,34,0,43,38,45,0
	.byt	28,30,32,36,0,34,			0,54,51,43,0,51,43,38
	.byt	0,28,30,32,36,0,34,			0,21,0,21,0
	.byt	28,30,32,36,0,34,			0,54,51,43,0,51,43,38
	.byt	0,36,0,38,0,				43,0
c3d:
	.byt	2,1,1,1,1,1,1,				1,7
	.byt	1,2,1,2,1,2,				1,1,1,1,1,1,1
	.byt	1,1,1,1,1,1,1,1,			1,1,1,1,1,1,4
	.byt	1,1,1,1,1,1,				1,1,1,1,1,1,1,1
	.byt	2,1,1,1,1,1,1,				1,1,1,2,5
	.byt	1,1,1,1,1,1,				1,1,1,1,1,1,1,1
	.byt	2,1,2,1,2,					1,7
	.byt	0				; end as loop
/*
c4p:
	.byt				
	.byt				
	.byt				
	.byt				
	.byt				
c4d:
	.byt				
	.byt				
	.byt				
	.byt				
	.byt				
	.byt				
	.byt				
	.byt	0				; end as loop
*/
mp_end:
