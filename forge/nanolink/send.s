; nanoLink sender routine (Durango-X speed)
; (c) 2023 Carlos J. Santisteban
; last modified 20230112-1329

; *** send one byte thru nanoLink ***
; input
;	ptr		address of byte (will be advanced)

nano_send:
.(
	LDA (ptr)				; get data, CMOS only (5)
	STA temp				; store byte (3)
	LDX #8					; bits per byte (2)
send_loop:
		LDA #NANO_CLK
		STA IO9nano			; assert NMI in remote, needs time to disable hardware interrupts (2+4)*8
		ASL temp			; extract MSb into C (5)*8, 5 since NMI
		ROL					; insert C into bit pattern (2)*8, 7 since NMI
		STA IO9nano			; data is sent, clock goes down, most likely safe to do right now (4)*8, 11 since NMI
		JSR wait			; wait for the bit to be read (42)*8, 53 since NMI seems OK!
		STZ IO9nano			; clear data, thus release interrupt line! (4)*8, 57 since NMI, 
		JSR exit			; interbit delay is needed! (14) 57+11=68, up to 82?
		DEX
		BNE send_loop		; all bits in byte (2+3)*8 -1
	INC ptr					; advance to next byte (5)
	BNE same_page			; (3 within same page / 2+5 page crossing)
		INC ptr+1
same_page:
	JSR exit				; make sure cannot be called too early! (14) is this enough?
	RTS						; (6)

; *** support routines ***
wait:
; apply suitable delay (total 42t including call)
	JSR exit
	JSR exit
exit:
	NOP
	RTS
.)
