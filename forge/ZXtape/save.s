; minimOS ZX tape interface!
; v0.1a2
; (c) 2016-2020 Carlos J. Santisteban
; last modified 20160803-1632

; ***** Save block of bytes at (data_pt), size stored at data_size *****
; proper 17 byte header at (header_pt)

; *** needed data ***
; ddrx = VIA DDRx
; px0out = VIA IORx
; speedcode = stores CPU speed in fixed point format ($10 = 1 MHz)
; *** zeropage ***
; pointer (word)
; length (word) is best on ZP
; sys_sp is safe to use when interrupts are disabled

zx_save:

; disable interrupts!!!
	_ENTER_CS	; actually PHP and SEI
	
; initialise output port
	LDA ddrx	; previous data direction register on VIA
	ORA #1	; make sure bit 0 is output
	STA ddrx	; set direction
	LDA px0out	; VIA IORA or IORB, output at bit 0 for easier toggling
	AND #%11111110	; clear bit 0
	STA px0out	; port is ready

; prepare header parameters as will be rather time critical
	LDY #17	; header size (not including flag & checksum)
	LDA #1	; MSB plus 1!!!
	STY length	; store size
	STA length+1
	LDA #>header_pt	; addresss of header
	LDY #<header_pt
	STY pointer	; set actual pointer
	STA pointer+1

; first generate about 5 seconds of guide tone plus sync pulse...
	LDA #16	; MSB+1 (not 15!!!)
	TAY		; approximate LSB (0.2 sec short)
	JSR guide5	; generate tone for specified length
	
; ...and the 19 byte header (parameters already set)
	LDA #0	; flag for header
	JSR send_data	; send header

; let us pause for about a second (optional)
	LDA #7	; MSB plus 1
	TAY		; approximate LSB
delay1sec:
		JSR del38semi	; about 0.624 ms
		DEY		; LSB counter
	BNE delay1sec	; continue
		SEC
		SBC #1	; if expired check MSB, NMOS savvy
	BNE delay1sec	; until the end

; as usual, set time critical parameters in advance
	LDA data_size
	LDY data_size+1
	INY		; MSB plus 1!!!
	STA length	; store size, note different order
	STY length+1
	LDA data_pt+1	; data pointer
	LDY data_pt
	STY pointer	; set actual pointer
	STA pointer+1

; now generate about 2 seconds of guide tone plus sync pulse...
	LDA #7	; MSB+1 (not 6!!!)
	TAY		; approximate LSB (0.07 sec short)
	JSR guide5	; as specified
			
; ...and then the REAL data!
	LDA #$FF	; flag for data
	JSR send_data	; cannot optimise
	_EXIT_CS	; actually PLP
	RTS		; ***** DONE *****

; ***** useful routines *****

; ** generate guide tone for number of cycles specified in A/Y **

guide5:

; one cycle of guide tone should take about 1.24 ms
		JSR del38semi	; (623* @ 1 MHz)
		INC px0out	; (6*) toggle output hi
		JSR del38semi
		DEC px0out	; (6*) toggle output back to zero
; repeat as needed

		DEY		; (2*) counter LSB
	BNE guide5	; (3*) continue
		SEC
		SBC #1	; if expired check MSB, NMOS savvy
	BNE guide5	; until the end
	
; now make the asymmetric sync pulse!
	LDX speedcode	; (4) saved loop reference, first 12 clocks per speedcode
sync1:
		CPX sys_sp	; (3*) harmless
		CPX $0100	; (4*)
 		DEX		; (2*)
		BNE sync1	; (3*)
	INC px0out	; (6) toggle output hi
	LDX speedcode	; (4) saved loop reference, now 13 clocks per speedcode
sync2:
		CPX $0100	; (4*) 
		CPX $0100	; (4*)
 		DEX		; (2*)
		BNE sync1	; (3*)
	DEC px0out	; (6) toggle output back to zero
	RTS

; ** delay half period of the guide tone **
del38semi:	; (15+s*38, incl call)

	LDX speedcode	; (4) saved loop reference
del38loop:
		JSR del33	; (33*)
		DEX		; (2*)
		BNE del38loop	; (3*)
	RTS		; (6)

; ** delay half period of the 'one' pulse **
del30semi:	; (15+s*30, incl call)

	LDX speedcode	; (4) saved loop reference
del30loop:
		JSR del25	; (25*)
		DEX		; (2*)
		BNE del30loop	; (3*)
	RTS		; (6)

; ** delay half period of the 'zero' pulse **
del15semi:	; (15+s*15, incl call)

	LDX speedcode	; (4) saved loop reference
del15loop:
		DEC sys_sp	; (5+5) harmless anyway
		INC sys_sp
		DEX		; (2*)
		BNE del15loop	; (3*)
	RTS		; (6)

; ** add delay until 25 clocks (12 already by call) for the 'one' bit *
del25:

	DEC sys_sp	; (5) harmless anyway
	JMP del_end	; (3+5)

; ** add delay until 33 clocks (12 already by call) for the guide tone **
del33:

	JSR some_rts	; (12) just lose some time
	CPX $0100	; (4)
del_end:
	INC sys_sp	; (5) harmless
some_rts:
	RTS		; (6 included)

; ** send block of bytes preceeded by flag in A **
send_data:

	LDY #0
	STY checksum	; NMOS savvy (2+3)
	JSR send_byte	; send the flag and include it in checksum (6...)
data_loop:
		LDA (pointer), Y	; get byte to send! Y was zero (5+6...)*
		JSR send_byte
		INC pointer	; go for next byte (5*)
		DEC length	; counter LSB (5*)
	BNE data_loop	; get another (3*)
		DEC length+1	; if expired check MSB
	BNE data_loop
; all bytes were sent, now end with the checksum
	LDA checksum
; will arrive at send_byte to emit the checkdum and return!
	
; ** send byte in A and update checksum **
send_byte:

	LDY #8	; bits per byte (2)
bit_loop:
		ASL		; shift left (2)
		BCS send_one
; generate a 'zero' bit
			JSR del15semi	; (255 @ 1 MHz)
			INC px0out	; (6) toggle output hi
; might add some delay for symmetry
			JSR del15semi
			DEC px0out	; (6) toggle output back to zero
			JMP sent	; NMOS savvy
send_one:
; generate a 'one' bit
			JSR del30semi	; (495 @ 1 MHz)
			INC px0out	; (6) toggle output hi
; might add some delay for symmetry
			JSR del30semi
			DEC px0out	; (6) toggle output back to zero
sent:
		DEY		; one bit less (2)
		BNE bit_loop	; until the byte is done (3)
	LDA checksum	
	EOR (pointer), Y	; NMOS savvy, Y was zero anyway (3+5)
	STA checksum	; xor with last byte (3+6)
	RTS
