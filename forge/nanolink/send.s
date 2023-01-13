; nanoLink sender routine (Durango-X speed)
; (c) 2023 Carlos J. Santisteban
; last modified 20230113-1222

; *** send one byte thru nanoLink ***
; input
;	ptr		address of byte (will be advanced)
; affects A, X and temp, autoincrements ptr (ZP)

nano_send:
.(
	LDA (ptr)				; get data, CMOS only (5)
	STA temp				; store byte (3+)
	LDX #7					; max bit index per byte (2)
send_loop:
		LDA #NANO_CLK
		STA IO9nano			; assert NMI in remote, needs time to disable hardware interrupts (2+4) *** NMI starts acknowledge here
		ASL temp			; extract MSb into C (5+ since NMI)
		ROL					; insert C into bit pattern (2, 7+ since NMI)
		NOP
		NOP
		NOP					; delay to be safe (2+2+2, 13+ since NMI)
		STA IO9nano			; data is sent, clock goes down, most likely safe to do right now (4, 17+ since NMI is pretty safe)
		ROR					; recover sent bit! (2, 19+ since NMI)
; with data bit already sent, cannot clear it before the NMI-enabled IRQ is executed!
; that's 58t for 0, 85t for 1 (might actually use the 58t delay everywhere and add 27t after reading)
		JSR wait			; wait for the bit to be read (42, 61+ since NMI)
		BCC was_zero		; transmitted zeros are faster! (3, 64+ since NMI or...)
			JSR wait2		; add 28t extra, minus one of not taken BCC (...27 if bit=1, 91+ after NMI)***********
was_zero:
		STZ IO9nano			; clear data, thus release interrupt line! (4, + since NMI)
		JSR exit			; interbit delay is needed! (14)
		DEX
		BPL send_loop		; all bits in byte (2+3)
	INC ptr					; advance to next byte (5)
	BNE same_page			; (3 within same page / 2+5 page crossing)
		INC ptr+1
same_page:
	JSR exit				; make sure cannot be called too early! (14) is this enough?
	RTS						; (6)

; *** support routines ***
wait:
; apply suitable delay (total 42t including call overhead)
	JSR exit
wait2:						; (28t including call overhead)
	JSR exit
exit:						; (14t including call overhead)
	NOP
	RTS
.)
