; LTC4622 display test
; (c) 2020-2021 Carlos J. Santisteban
; last modified 20201213-1520

	.zero

	* = 2					; 6510-savvy LOL!

anode	.dsb	1			; needs this address
dly		.dsb	1			; another counter

	.text

;	* = $FF80
	* = $FF00				; *** *** patch! *** ***
patch:
	JMP irq
	.dsb	$FF80-*, $FF	; *** ROM filling ***
; *** *** end of patch *** ***

; main code, executes forever
reset:
	LDX #$0F				; start on F, down to 0
dloop:
			JSR display		; show that char!
			INC dly			; for a while
			BNE dloop
		DEX
		BPL dloop			; keep going
	BMI reset				; or start again

; *** interrupt traps ***
; put '--' on the display while locked via IRQ
irq:
;		  23456789			; pins on LTC
;	LDA #%11100100			; dash on digit 1
	LDA #%11100101			; dash on BOTH digits ***
lock_dis:
		STA $FFF0			; put it on port
lock_dp:
;			INX
;			BNE lock_dp		; wait for a while
;		EOR #%00000101		; switch between digits
		BNE lock_dis		; no need for BRA *** will lock forever ***
; NMI lock will show '==' instead
nmi:
;	LDA #%01100100			; '=' on digit 1
	LDA #%01100101			; '=' on BOTH digits ***
	BNE lock_dis			; otherwise the same 
; *** end of lock ***

; routines
display:
	LDA #8					; first anode
	STA anode
cloop:
		LDA bitmap, X		; get pattern
		AND #$F0			; keep MSN only
		JSR disdel			; enable anode and make delay
		LDA bitmap, X		; get pattern again
		ASL					; will set LSN as MSN (mask won't apply as no DP here)
		ASL
		ASL
		ASL
		JSR disdel			; enable, store and delay
		BCC cloop			; not last anode, so continue
	RTS

; *** delay routine ***
disdel:
	ORA anode				; add anode selection to cathode pattern
	STA $FFF0				; set output port
dl_loop:
		INY
		BNE dl_loop			; about 1.3 ms delay
	LSR anode				; enable next anode, non decoded version
	RTS

; *** bitmap ***
; being cathodes, 0 means ON
bitmap:
;			 abc*defg
	.byt	%00010001		; 0
	.byt	%10011111		; 1
	.byt	%00110010		; 2
	.byt	%00010110		; 3
	.byt	%10011100		; 4
	.byt	%01010100		; 5
	.byt	%01010000		; 6
	.byt	%00011111		; 7
	.byt	%00010000		; 8
	.byt	%00011100		; 9
	.byt	%00011000		; A
	.byt	%11010000		; B
	.byt	%01110001		; C
	.byt	%10010010		; D
	.byt	%01110000		; E
	.byt	%01111000		; F

; *** *** *** *** *** ***

	.asc	0, "LTCtest ***PATCH 2***", 0	; some ID

	.dsb	$FFFA-*, $FF	; ROM filling

; *** hardware vectors ***
vectors:
	.word	nmi				; NMI shows '=='
	.word	patch			; *** not reset
	.word	irq				; IRQ shows '--'
