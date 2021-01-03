; SS-22 auto-configuration protocol
; (c) 2020-2021 Carlos J. Santisteban
; last modified 20200428-2055

/*
Init:
	Set 15625 bps
	Send $55, receive (CA2=entry1)
Entry 1:
	Got $55? Send $22, receive (CA2=entry2)
	Got $22?	if not shifted, DISABLE! but cannot know...
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

/*** variables used ***/
ssc_spd	.byt	0		; speed link
ssc_idx	.byt	0		; stage index

/* standard reception into buffer */
ssc_std:
	JSR ssc_get		; get read byte into A...
				; ...and store it somewhere
	_DR_OK

/********************************/
/* auto-configuration procedure */
/********************************/
ssc_init:
; might check for CA2 as input
	LDA #$55
	JSR ssc_send
	LDA #SS_SPEED		; speed to give 15625 bps or lower (might be 166 kbps if known to never run below 1 MHz
	STA ssc_spd
	LDX #6			; index for stage 1
ssc_rcv:
; reception, set CA2 as input, enable int, set index and go away
	STX ssc_idx
	LDA VIA_S+PCR
	AND #%11110001
	ORA #%00000010		; CA2 independent interrupt, neg. edge
	STA VIA_S+PCR
	LDA #%10000001		; enable CA2 interrupt
	STA VIA_S+IER
	_DR_OK
/* these must be close to ssc_rcv */
ssc_e1:
	JSR ssc_get
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
;		JSR ssc_cks		; set data must have been pulled... but cannot know
		LDA #>SPD_CODE		; send my speed
		JSR ssc_send
		LDX #2			; go to stage 3
		BNE ssc_rcv
ssc_e2:
	JSR ssc_get
	TAX				; keep other end's speed
	LDA #>SPD_CODE		; send my speed, and we're done
	JSR ssc_send
	BRA ssc_lnk
ssc_e3:
	JSR ssc_cks		; my speed must have been pulled before getting other's
	JSR ssc_get
	TAX				; keep other end's speed
ssc_lnk:
; compute speed according to X and set ordinary reception
	LDA #0			; max speed for faster others
	CPX #>SPD_CODE
	BCS ssc_fast		; other end is faster, do not check table
		LDA ss_spds-1, X	; get correct value, including 1 for same speed
ssc_fast:
	STA ssc_spd		; store detected speed, and we're done
	STZ ssc_idx		; final stage, regular action
	_DR_OK
/* must be close to above */
ssc_cks:
; if not shifted, skip the RTS, discard return and disable interrupt
	LDA #%00000100		; VSR interrupt flag
	BIT VIA_S+IFR
;	BPL ssc_abt		; no interrupt... but arrived here because of CA2
	BNE ssc_abt		; previous data not shifted... must abort
		STA VIA_S+IFR		; otherwise clear flag
		RTS
ssc_abt:
	PLA
	PLA
ssc_err:
; link failed, disable CA2 interrupt and exit quietly
	LDA #%00000001		; clear CA2 enable flag
	STA VIA_S+IER		; disable CA2
	_DR_ERR(CORRUPT)
/* independent block */
ssc_get:
; ** pull value (generic) **
	LDA ssc_spd
	STA VIA_S+T2CL		; set current speed, could be done before?
	LDA VIA_S+ACR
	AND #%11100011
	ORA #%00000100		; shift in under T2 control
	STA VIA_S+ACR
	LDA #%00000100		; SR flag mask
	LDX VIA_S+VSR 		; dummy read starts shifting
ssc_shf:
		BIT VIA_S+IFR		; read complete? busy wait!
		BNE ssc_shf
	STA VIA_S+IFR		; ack flag
	LDA VIA_S+VSR 		; here is the data
	RTS
/* this block could be elsewhere */
ssc_send:
; trasmission, load shift register and pulse CA2 **generic**
; this should some flag before...
	STA VIA_S+VSR
	LDA VIA_S+ACR
	ORA #%00011100		; shift out under CB1 control
	STA VIA_S+ACR
	LDA VIA_S+PCR		; current CA2 config
	TAY				; save previous state
	AND #%11110001
	ORA #%00001100		; send STROBE, make CA2 low...
	STA VIA_S+PCR
	STY VIA_S+PCR		; ...and back to input (pulled up)
	RTS
/* another independent block */
ssc_ca2:
; driver sets this for CA2 interrupt
; Check whether is CA2-sourced
	LDA #1			; CA2 flag
	BIT VIA_S+IFR		; check interrupt source
	BNE ssc_isr		; it is CA2, proceed with isr
		_NXT_ISR		; if not, look for another
ssc_isr:
	STA VIA_S+IFR		; acknowledge interrupt
	LDX ssc_idx
	JMP (ssc_ent, X)	; receive according to stage
/* another independent block */
ssc_ent:
; table of autoconfiguration stages
	.word	ssc_std		; normal reception
	.word	ssc_e3		; get speed reply
	.word	ssc_e2		; get other speed and reply with my own speed
	.word	ssc_e1		; identify link
ss_spds:
; table of speeds depending on other's speed code, starts from 1 and ends with same speed (set as 1)
	.byt	$FF		; T2 for speedcode 1...
; ...
	.byt	1		; adequate value for same speed link
