; minimOS•16 firmware module
; memory size estimation (needs mirroring, undecoded areas not allowed)
; 20-bit Jalapa version
; v0.6a3
; (c) 2017 Carlos J. Santisteban
; last modified 20170725-1948

	LDA #$FF		; initial MSB
	STA uz			; set pointer LSB
	LSR			; will point inside the lower 32k of each bank
	STA uz+1		; set pointer MSB
	LDA #$07		; base bank for high RAM
	STA uz+2		; pointer is complete
rs_hiram:
		STA [uz]		; store current bank
		LSR			; shift to half size...
		STA uz+2		; ...and update pointer
		BNE rs_hiram		; repeat until bank 0
	STZ $7FFF		; in case 64K or less
	LDA @$77FFF		; *** number of RAM banks ***
; store somewhere...
	STZ uz			; ROM lsb
	LDA #$80		; buggest ROM
	LDA #$5A		; initial value (will swap with $A5)
rs_shft:
			STA (uz)		; store current value
			CMP (uz)		; is correct?
				BNE rs_not		; not, it must be ROM
			EOR #$FF		; otherwise switch value...
			BMI rs_shft		; ...until both done
		SEC
		ROR uz+1		; next size
		BCC rs_shft		; at least 256 byte ROM
	LDA uz+1		; *** first ROM page ***
; store somewhere...
; to be safe, check for RAM 32K or less
	PHA			; save for later
	DEC uz+1		; one less is max low-RAM address
	DEC uz			; was 0, thus borrow OK
	DEC			; page number...
	STA (uz)		; ...written there
	LDA #$7F		; standard 32K
	STA uz+1		; new pointer
rs_low:
		STA (uz)		; page number written there
		LSR			; in half
		STA uz+1		; update
		BNE rs_low		; at least 256 bytes
	PLA			; theoretical end of RAM
	STA uz+1		; restore pointer
	LDA (uz)		; get supposed size
	CMP $7FFF		; more than 32k?
	BCS rs_done		; size in A is OK
