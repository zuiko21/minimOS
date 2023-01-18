; nanoLink sender routine (Durango-X speed)
; (c) 2023 Carlos J. Santisteban
; last modified 20230119-0011

; *** send one byte thru nanoLink ***
; input
;	A		byte to be sent
; affects A, X and temp


; *** hardware definitions ***
IO9nano	= $DF97				; port address

nano_send:
byte_send:					; alternative access
.(
; *** zeropage allocation ***
temp	= $ED				; minimOS local3+1, could be elsewhere
ptr		= $EE

	STA temp				; store byte (3+)
	LDX #7					; max bit index per byte (2)
send_loop:
		LDA #2				; nanoLink clock bit position
		STA IO9nano			; assert NMI in remote, needs time to disable hardware interrupts (2+4) *** NMI starts acknowledge here
		ASL temp			; extract MSb into C (5+ since NMI)
		ROL					; insert C into bit pattern (2, 7+ since NMI)
		NOP
		NOP
		NOP					; delay to be safe (2+2+2, 13+ since NMI)
		STA IO9nano			; data is sent, clock goes down, most likely safe to do right now (4, 17+ since NMI is pretty safe)
		ROR					; recover sent bit into C! (2, 19+ since NMI)
; with data bit already sent, cannot clear it before the NMI-enabled IRQ is executed!
; ~42+ after NMI fire
		JSR wait			; wait for the bit to be read (28, 47+ since NMI)
		BCC was_zero		; transmitted zeros are faster! (3, 50+ since NMI or...)
			NOP
			NOP
			JSR exit		; add 18t extra, minus one of not taken BCC (...17 if bit=1, 67+ after NMI)
was_zero:
		STZ IO9nano			; clear data, thus release interrupt line! (4, 54+/71+ since NMI)*********
		JSR exit			; interbit delay is needed! (14, 82+/109+)
		DEX
		BPL send_loop		; all bits in byte (2+3, 87+/114+ and still 6 clocks of margin)
	JSR exit				; make sure cannot be called too early! (14, 100+/127+) adding calling overhead is enough
	RTS						; (6, no less than 106+/133+, actually valid even for page crossing)

;	CLI						; enable interrupt... (2, 42+)
;	PLA						; (4+6, 84/106+ single bit, 116/138+ last bit, 120/142+ page cross, 126/148+ check limit, 130/152+ limit while crossing)

; *** support routines ***
wait:
; apply suitable delay (28t including call overhead)
	JSR exit
exit:						; (14t including call overhead)
	NOP
	RTS
.)
