; 5x8 keyboard to joypad conversion
; (c) 2022 Carlos J. Santisteban
; last modified 20221114-2317

; col1= A2··t1··--L1··--
; col2= B2R2e1··--D1U1--
; col3= e2D2B1U2--R1··--
; col4= t2L2A1··--····--
; col5 --
; standard pad= AtBeULDR

	LDX #8
	STX $DF9C
loop:
		STX $DF9D
		DEX
		BNE loop			; get pads from interface
	LDA $DF9C
	EOR pad1mask			; format conversion
	STA pad1
	LDA $DF9D
	EOR pad2mask
	STA pad2
; read keyboard in case any button is emulated
	LDY #4					; last column
	STY $DF9B				; select column
	LDX $DF9B				; get rows
	STX temp				; store value
; col4= t2L2A1··--····--
	BPL no_t2
		LDA #bit_t
		TSB pad2
no_t2:
	ASL temp
	BPL no_L2
		LDA #bit_L
		TSB pad2
no_L2:
	ASL temp
	BPL no_A1
		LDA #bit_A
		TSB pad1
no_A1:
	DEY						; next column
	STY $DF9B				; select column
	LDX $DF9B				; get rows
	STX temp				; store value
; col3= e2D2B1U2--R1··--
	BPL no_e2
		LDA #bit_e
		TSB pad1
no_e2:
	ASL temp
	BPL no_D2
		LDA #bit_D
		TSB pad2
no_D2:
	ASL temp
	BPL no_B1
		LDA #bit_B
		TSB pad1
no_B1:
	ASL temp
	BPL no_U2
		LDA #bit_U
		TSB pad2
no_U2:
	ASL temp
	ASL temp
	BPL no_R1
		LDA #bit_R
		TSB pad1
no_R1:
	DEY						; next column
	STY $DF9B				; select column
	LDX $DF9B				; get rows
	STX temp				; store value
; col2= B2R2e1··--D1U1--
	BPL no_B2
		LDA #bit_B
		TSB pad2
no_B2:
	ASL temp
	BPL no_R2
		LDA #bit_R
		TSB pad2
no_R2:
	ASL temp
	BPL no_e1
		LDA #bit_e
		TSB pad1
no_e1:
	ASL temp
	ASL temp
	ASL temp
	BPL no_D1
		LDA #bit_D
		TSB pad1
no_D1:
	ASL temp
	BPL no_U1
		LDA #bit_U
		TSB pad1
no_U1:
	DEY						; next column
	STY $DF9B				; select column
	LDX $DF9B				; get rows
	STX temp				; store value
; col1= A2··t1··--L1··--
	BPL no_A2
		LDA #bit_A
		TSB pad2
no_A2:
	ASL temp
	ASL temp
	BPL no_t1
		LDA #bit_t
		TSB pad1
no_t1:
	ASL temp
	ASL temp
	ASL temp
	BPL no_L1
		LDA #bit_L
		TSB pad1
no_L1:
