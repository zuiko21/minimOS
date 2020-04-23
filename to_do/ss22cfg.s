; SS-22 auto-configuration protocol
; (c)2020 Carlos J. Santisteban

/*
Init:
	Set 15625 bps
	Send $55, receive (CA2=entry1)
Entry 1:
	Got $55? Send $22, receive (CA2=entry2)
	Got $22?	if not shifted, DISABLE!
			else Send S, receive (CA2=entry3)
	Got anything else? DISABLE!
Entry 2:
	Get X=other end's speed
	Send S=my speed, go to link
Entry 3:
	If not shifted, DISABLE!
	else Get X
Link:
	Set bps via T2 value:
		if x>s, T2=0
		else if x=s, T2=1
		else T2=myTab[x]
	Set CA2 to standard buffer reception
*/

ssc_init:
	LDA #$55
	JSR ssc_send
	LDA #			; speed to give 15625 bps or lower (might be 166 kbps if known to never run below 1 MHz
	STA VIA_S+T2CL
	LDX #6			; index for stage 1
ssc_rcv:
; reception, set CA2 as input, enable int, set index and go away
	STX ssc_idx

	_DR_OK
ssc_ca2:
; driver sets this for CA2 interrupt
; Check whether is CA2-sourced

	LDX ssc_idx
	JMP (ssc_ent, X)	; receive according to stage
ssc_ent:
; table of autoconfiguration stages
	.word	ssc_std		; normal reception
	.word	ssc_e3		; get speed reply
	.word	ssc_e2		; get other speed and reply with my own speed
	.word	ssc_e1		; identify link
ssc_std:
ssc_e1:
	LDA VIA_S+VSR
	CMP #$55
	BNE ssc_n55
; must reply to master
		LDA #$22
		JSR ssc_send
		LDX #4			; go to stage 2
		BNE ssc_rcv
ssc_n55:
	CMP #$22		; am I master?
	BNE ssc_err		; abort otherwise
; must report my own speed
		JSR ssc_cks		; set data must have been pulled
		LDA #MY_SPD		; send my speed
		JSR ssc_send
		LDX #2			; go to stage 3
		BNE ssc_rcv
ssc_e2:
; get X
	LDA #MY_SPD		; send my speed
	JSR ssc_send
	BRA ssc_lnk
ssc_e3:
	JSR ssc_cks		; set data must have been pulled
; get X
ssc_lnk:

ssc_cks:
; if not shifted, skip the RTS, discard return and disable interrupt
		RTS
ssc_abt:
	PLA
	PLA
ssc_err:
; link failed, disable CA2 interrupt and exit quietly
