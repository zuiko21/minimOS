; (c) 2020 Carlos J. Santisteban
#define	VIA	$6FF0
#include <via.h>

user	= 2

* = $FC00

reset:	SEI
		CLD
		LDX #$FF
		TXS
		STX ddra	; all output
		STX ddrb
		STZ iora	; initial value = 0
		STZ iorb
		LDA #$C0	; CB2 low, else inputs
		STA pcr
		STZ acr		; no timers, shift, handshake, etc
		LDA #$7F	; no interrupts enabled
		STA ier
		LDX #0		; reset index
		LDA #$55	; initial pattern
test0:	STA 0, X	; write it...
		CMP 0, X	; ...and check it back
		BNE error	; must be the same!
		EOR #$FF	; toggle bits
		BMI test0	; second chance
		INC iora	; display checked byte
		INX			; next byte
		BNE test0	; last in page?
		INC iorb	; increase page number on display
test1:	STA $100, X	; write it...
		CMP $100, X	; ...and check it back
		BNE error	; must be the same!
		EOR #$FF	; toggle bits
		BMI test1	; second chance
		INC iora	; display checked byte
		INX			; next byte
		BNE test1	; last in page?
		INC iorb	; increase page number on display
test2:	STA $200, X	; write it...
		CMP $200, X	; ...and check it back
		BNE error	; must be the same!
		EOR #$FF	; toggle bits
		BMI test2	; second chance
		INC iora	; display checked byte
		INX			; next byte
		BNE test2	; last in page?
		INC iorb	; increase page number on display
test3:	STA $300, X	; write it...
		CMP $300, X	; ...and check it back
		BNE error	; must be the same!
		EOR #$FF	; toggle bits
		BMI test3	; second chance
		INC iora	; display checked byte
		INX			; next byte
		BNE test3	; last in page?
		INC iorb	; increase page number on display
		BRA test4	; skip error routine

error:	LDA iorb	; displayed page number
		ORA #$E0	; put an 'E' in front, it won't go over 08 anyway
		STA iorb
loop:	DEX			; about 0.3s delay loop
		BNE loop
		DEY
		BNE loop
		LDA pcr
		EOR #%00100000	; toggle CB2
		STA pcr
		BRA loop	; stay blinking forever
		
test4:	STA $400, X	; write it...
		CMP $400, X	; ...and check it back
		BNE error	; must be the same!
		EOR #$FF	; toggle bits
		BMI test4	; second chance
		INC iora	; display checked byte
		INX			; next byte
		BNE test4	; last in page?
		INC iorb	; increase page number on display
test5:	STA $500, X	; write it...
		CMP $500, X	; ...and check it back
		BNE error	; must be the same!
		EOR #$FF	; toggle bits
		BMI test5	; second chance
		INC iora	; display checked byte
		INX			; next byte
		BNE test5	; last in page?
		INC iorb	; increase page number on display
test6:	STA $600, X	; write it...
		CMP $600, X	; ...and check it back
		BNE error	; must be the same!
		EOR #$FF	; toggle bits
		BMI test6	; second chance
		INC iora	; display checked byte
		INX			; next byte
		BNE test6	; last in page?
		INC iorb	; increase page number on display
test7:	STA $700, X	; write it...
		CMP $700, X	; ...and check it back
		BNE error	; must be the same!
		EOR #$FF	; toggle bits
		BMI test7	; second chance
		INC iora	; display checked byte
		INX			; next byte
		BNE test7	; last in page?
		INC iorb	; increase page number on display

		LDY #0
		LDX #7		; last allowable page
		LDA #$FF	; last byte in page
		STA user	; indirect addressing vector
		LDA #8		; number of pages (X+1)
page:	STX user+1	; MSB
		STA (user), Y	; store page number
		DEX
		DEC
		BNE page
		LDA $7FF	; check number readable at last address
		BEQ a_err	; there has to be something!
		AND #$0F	; mask
		ORA #$C0	; append 'C' at the beginning
		STA iorb	; update display
		
		LDX #$FF	; byte pointer
		LDA #0
pz:		STA 0, X	; fill zero page
		DEX			; backwards
		DEC
		BNE pz
		LDA $FF		; get actual number of bytes in zero page (in case < 256)
		BEQ a_chk	; there's more than one page
		STA iora	; update dislayed size
		DEC iorb
		TAX			; limit further testing to actual size
		DEX
a_chk:	STX iora	; change display during last test (?)
		CMP 0, X	; check for different values
		BNE a_err
		DEX
		DEC
		BNE a_chk	; after this, all OK

		LDA #$E0	; CB2 hi, no dots
		STA pcr
lock:	BRA lock	; test ended successfully

a_err:	LDA iorb
		AND #$0F	; mask displayed page
		ORA #$A0	; append an 'A' (Address Error)
		STA iorb
		JMP loop	; go blinking dots

; ID string for easier linking
		.asc " Exhaustive RAM check for SDd / CHIHUAHUA, 1.1 ", 0

* = $FFF7			; placeholder with lots of bit to reset

nmi:
irq:	RTI			; no interrupts defined yet

* = $FFFA			; 65C02 hardware vectors

		.word	nmi
		.word	reset
		.word	irq
