; minimOS opcode list for (dis)assembler modules
; (c) 2015-2020 Carlos J. Santisteban
; last modified 20200201-1142

; ***** for 69asm MC6809 cross assembler *****
; Regular Motorola set (not 6309 yet)
; Opcode list as bit-7 terminated strings
; @ expects single byte, & expects word
; % expects RELATIVE addressing
; = expects LONG RELATIVE addressing (unlike 816, as * is used for prefixes)
; *** need some special characters for prefixes ***
; temporarily using *2, *4... (value + $80, not ASCII) for easier indexing

	.asc	"NEG ", '@'+$80		; $00=NEG dir
	.asc	'?'+$80				; $01=?
	.asc	'?'+$80				; $02=?
	.asc	"COM ", '@'+$80		; $03=COM d
	.asc	"LSR ", '@'+$80		; $04=LSR d
	.asc	'?'+$80				; $05=?
	.asc	"ROR ", '@'+$80		; $06=ROR d
	.asc	"ASR ", '@'+$80		; $07=ASR d
	.asc	"ASL ", '@'+$80		; $08=ASL d (LSL d)
	.asc	"ROL ", '@'+$80		; $09=ROL d
	.asc	"DEC ", '@'+$80		; $0A=DEC d
	.asc	'?'+$80				; $0B=?
	.asc	"INC ", '@'+$80		; $0C=INC d
	.asc	"TST ", '@'+$80		; $0D=TST d
	.asc	"JMP ", '@'+$80		; $0E=JMP d
	.asc	"CLR ", '@'+$80		; $0F=CLR d

	.asc	'*', 2+$80			; $10		** 6809 PREFIX **
	.asc	'*', 4+$80			; $11		** 6809 PREFIX **
	.asc	"NO", 'P'+$80		; $12=NOP
	.asc	"SYN", 'C'+$80		; $13=SYNC
	.asc	'?'+$80				; $14=?
	.asc	'?'+$80				; $15=?
	.asc	"LBRA ", '='+$80	; $16=LBRA lr
	.asc	"LBSR ", '='+$80	; $17=LBSR lr
	.asc	'?'+$80				; $18=?
	.asc	"DA", 'A'+$80		; $19=DAA
	.asc	"ORCC ", '@'+$80	; $1A=ORCC #
	.asc	'?'+$80				; $1B=?
	.asc	"ANDCC ", '@'+$80	; $1C=ANDCC #
	.asc	"SE", 'X'+$80		; $1D=SEX
	.asc	"EXG ", '@'+$80		; $1E=EXG #
	.asc	"TFR ", '@'+$80		; $1F=TFR #

	.asc	"BRA ", '%'+$80		; $20=BRA rel
	.asc	"BRN ", '%'+$80		; $21=BRN rel
	.asc	"BHI ", '%'+$80		; $22=BHI rel
	.asc	"BLS ", '%'+$80		; $23=BLS rel
	.asc	"BCC ", '%'+$80		; $24=BCC rel (BHS)
	.asc	"BCS ", '%'+$80		; $25=BCS rel (BLO)
	.asc	"BNE ", '%'+$80		; $26=BNE rel
	.asc	"BEQ ", '%'+$80		; $27=BEQ rel
	.asc	"BVC ", '%'+$80		; $28=BVC rel
	.asc	"BVS ", '%'+$80		; $29=BVS rel
	.asc	"BPL ", '%'+$80		; $2A=BPL rel
	.asc	"BMI ", '%'+$80		; $2B=BMI rel
	.asc	"BGE ", '%'+$80		; $2C=BGE rel
	.asc	"BLT ", '%'+$80		; $2D=BLT rel
	.asc	"BGT ", '%'+$80		; $2E=BGT rel
	.asc	"BLE ", '%'+$80		; $2F=BLE rel

	.asc	"LEAX ", '?'+$80		; $30=LEAX idx ?
	.asc	"LEAY ", '?'+$80		; $31=LEAY ?
	.asc	"LEAS ", '?'+$80		; $32=LEAS ?
	.asc	"LEAU ", '?'+$80		; $33=LEAU ?
	.asc	"PSHS ", '@'+$80	; $34=PSHS #
	.asc	"PULS ", '@'+$80	; $35=PULS #
	.asc	"PSHU ", '@'+$80	; $36=PSHU #
	.asc	"PULU ", '@'+$80	; $37=PULU #
	.asc	'?'+$80				; $38=?
	.asc	"RT", 'S'+$80		; $39=RTS
	.asc	"AB", 'X'+$80		; $3A=ABX
	.asc	"RT", 'I'+$80		; $3B=RTI
	.asc	"CWAI ", '@'+$80	; $3C=CWAI #
	.asc	"MU", 'L'+$80		; $3D=MUL
	.asc	'?'+$80				; $3E=?
	.asc	"SW", 'I'+$80		; $3F=SWI

	.asc	"NEG ", 'A'+$80		; $40=NEG A
	.asc	'?'+$80				; $41=?
	.asc	'?'+$80				; $42=?
	.asc	"COM ", 'A'+$80		; $43=COM A
	.asc	"LSR ", 'A'+$80		; $44=LSR A
	.asc	'?'+$80				; $45=?
	.asc	"ROR ", 'A'+$80		; $46=ROR A
	.asc	"ASR ", 'A'+$80		; $47=ASR A
	.asc	"ASL ", 'A'+$80		; $48=ASL A (LSLA)
	.asc	"ROL ", 'A'+$80		; $49=ROL A
	.asc	"DEC ", 'A'+$80		; $4A=DEC A
	.asc	'?'+$80				; $4B=?
	.asc	"INC ", 'A'+$80		; $4C=INC A
	.asc	"TST ", 'A'+$80		; $4D=TST A
	.asc	'?'+$80				; $4E=?
	.asc	"CLR ", 'A'+$80		; $4F=CLR A

	.asc	"NEG ", 'B'+$80		; $50=NEG B
	.asc	'?'+$80				; $51=?
	.asc	'?'+$80				; $52=?
	.asc	"COM ", 'B'+$80		; $53=COM B
	.asc	"LSR ", 'B'+$80		; $54=LSR B
	.asc	'?'+$80				; $55=?
	.asc	"ROR ", 'B'+$80		; $56=ROR B
	.asc	"ASR ", 'B'+$80		; $57=ASR B
	.asc	"ASL ", 'B'+$80		; $58=ASL B (LSLB)
	.asc	"ROL ", 'B'+$80		; $59=ROL B
	.asc	"DEC ", 'B'+$80		; $5A=DEC B
	.asc	'?'+$80				; $5B=?
	.asc	"INC ", 'B'+$80		; $5C=INC B
	.asc	"TST ", 'B'+$80		; $5D=TST B
	.asc	'?'+$80				; $5E=?
	.asc	"CLR ", 'B'+$80		; $5F=CLR B

	.asc	"NEG @, ", 'X'+$80	; $60=NEG idx
	.asc	'?'+$80				; $61=?
	.asc	'?'+$80				; $62=?
	.asc	"COM @, ", 'X'+$80	; $63=COM idx
	.asc	"LSR @, ", 'X'+$80	; $64=LSR idx
	.asc	'?'+$80				; $65=?
	.asc	"ROR @, ", 'X'+$80	; $66=ROR idx
	.asc	"ASR @, ", 'X'+$80	; $67=ASR idx
	.asc	"ASL @, ", 'X'+$80	; $68=ASL idx (LSL)
	.asc	"ROL @, ", 'X'+$80	; $69=ROL idx
	.asc	"DEC @, ", 'X'+$80	; $6A=DEC idx
	.asc	'?'+$80				; $6B=?
	.asc	"INC @, ", 'X'+$80	; $6C=INC idx
	.asc	"TST @, ", 'X'+$80	; $6D=TST idx
	.asc	"JMP @, ", 'X'+$80	; $6E=JMP idx
	.asc	"CLR @, ", 'X'+$80	; $6F=CLR idx

	.asc	"NEG ", '&'+$80		; $70=NEG ext
	.asc	'?'+$80				; $71=?
	.asc	'?'+$80				; $72=?
	.asc	"COM ", '&'+$80		; $73=COM ext
	.asc	"LSR ", '&'+$80		; $74=LSR ext
	.asc	'?'+$80				; $75=?
	.asc	"ROR ", '&'+$80		; $76=ROR ext
	.asc	"ASR ", '&'+$80		; $77=ASR ext
	.asc	"ASL ", '&'+$80		; $78=ASL ext (LSL)
	.asc	"ROL ", '&'+$80		; $79=ROL ext
	.asc	"DEC ", '&'+$80		; $7A=DEC ext
	.asc	'?'+$80				; $7B=?
	.asc	"INC ", '&'+$80		; $7C=INC ext
	.asc	"TST ", '&'+$80		; $7D=TST ext
	.asc	"JMP ", '&'+$80		; $7E=JMP ext
	.asc	"CLR ", '&'+$80		; $7F=CLR ext

	.asc	"SUBA #", '@'+$80	; $80=SUB A #
	.asc	"CMPA #", '@'+$80	; $81=CMP A #
	.asc	"SBCA #", '@'+$80	; $82=SBC A #
	.asc	"SUBD #", '&'+$80	; $83=SUBD #
	.asc	"ANDA #", '@'+$80	; $84=AND A #
	.asc	"BITA #", '@'+$80	; $85=BIT A #
	.asc	"LDA #", '@'+$80	; $86=LDA #
	.asc	'?'+$80				; $87=?
	.asc	"EORA #", '@'+$80	; $88=EOR A #
	.asc	"ADCA #", '@'+$80	; $89=ADC A #
	.asc	"ORA #", '@'+$80	; $8A=ORA #
	.asc	"ADDA #", '@'+$80	; $8B=ADD A #
	.asc	"CMPX # ", '&'+$80	; $8C=CMPX #
	.asc	"BSR ", '%'+$80		; $8D=BSR rel
	.asc	"LDX #", '&'+$80	; $8E=LDX #
	.asc	"?", ' '+$80		; $8F=?

	.asc	"SUBA ", '@'+$80	; $90=SUB A dir
	.asc	"CMPA ", '@'+$80	; $91=CMP A dir
	.asc	"SBCA ", '@'+$80	; $92=SBC A dir
	.asc	"SUBD ", '@'+$80	; $93=SUBD dir
	.asc	"ANDA ", '@'+$80	; $94=AND A dir
	.asc	"BITA ", '@'+$80	; $95=BIT A dir
	.asc	"LDA ", '@'+$80		; $96=LDA dir
	.asc	"STA ", '@'+$80		; $97=STA dir
	.asc	"EORA ", '@'+$80	; $98=EOR A dir
	.asc	"ADCA ", '@'+$80	; $99=ADC A dir
	.asc	"ORA ", '@'+$80		; $9A=ORA dir
	.asc	"ADDA ", '@'+$80	; $9B=ADD A dir
	.asc	"CMPX ", '@'+$80	; $9C=CMPX dir
	.asc	"JSR ", '@'+$80		; $9D=JSR dir
	.asc	"LDX ", '@'+$80		; $9E=LDX dir
	.asc	"STX ", '@'+$80		; $9F=STX dir

	.asc	"SUBA @, ", 'X'+$80	; $A0=SUB A idx
	.asc	"CMPA @, ", 'X'+$80	; $A1=CMP A idx
	.asc	"SBCA @, ", 'X'+$80	; $A2=SBC A idx
	.asc	"SUBD @, ", 'X'+$80	; $A3=SUBD idx
	.asc	"ANDA @, ", 'X'+$80	; $A4=AND A idx
	.asc	"BITA @, ", 'X'+$80	; $A5=BIT A idx
	.asc	"LDA @, ", 'X'+$80		; $A6=LDA idx
	.asc	"STA @, ", 'X'+$80		; $A7=STA idx
	.asc	"EORA @, ", 'X'+$80	; $A8=EOR A idx
	.asc	"ADCA @, ", 'X'+$80	; $A9=ADC A idx
	.asc	"ORA @, ", 'X'+$80		; $AA=ORA idx
	.asc	"ADDA @, ", 'X'+$80	; $AB=ADD A idx
	.asc	"CMPX @, ", 'X'+$80	; $AC=CMPX idx
	.asc	"JSR @, ", 'X'+$80		; $AD=JSR idx
	.asc	"LDX @, ", 'X'+$80		; $AE=LDX idx
	.asc	"STX @, ", 'X'+$80		; $AF=STX idx

	.asc	"SUBA ", '&'+$80	; $B0=SUB A ext
	.asc	"CMPA ", '&'+$80	; $B1=CMP A ext
	.asc	"SBCA ", '&'+$80	; $B2=SBC A ext
	.asc	"SUBD ", '&'+$80	; $B3=SUBD ext
	.asc	"ANDA ", '&'+$80	; $B4=AND A ext
	.asc	"BITA ", '&'+$80	; $B5=BIT A ext
	.asc	"LDA ", '&'+$80		; $B6=LDA ext
	.asc	"STA ", '&'+$80		; $B7=STA ext
	.asc	"EORA ", '&'+$80	; $B8=EOR A ext
	.asc	"ADCA ", '&'+$80	; $B9=ADC A ext
	.asc	"ORA ", '&'+$80		; $BA=ORA ext
	.asc	"ADDA ", '&'+$80	; $BB=ADD A ext
	.asc	"CMPX ", '&'+$80	; $BC=CMPX ext
	.asc	"JSR ", '&'+$80		; $BD=JSR ext
	.asc	"LDX ", '&'+$80		; $BE=LDX ext
	.asc	"STX ", '&'+$80		; $BF=STX ext

	.asc	"SUBB #", '@'+$80	; $C0=SUB B #
	.asc	"CMPB #", '@'+$80	; $C1=CMP B #
	.asc	"SBCB #", '@'+$80	; $C2=SBC B #
	.asc	"ADDD #", '&'+$80	; $C3=ADDD #
	.asc	"ANDB #", '@'+$80	; $C4=AND B #
	.asc	"BITB #", '@'+$80	; $C5=BIT B #
	.asc	"LDB #", '@'+$80	; $C6=LDB #
	.asc	'?'+$80				; $C7=?
	.asc	"EORB #", '@'+$80	; $C8=EOR B #
	.asc	"ADCB #", '@'+$80	; $C9=ADC B #
	.asc	"ORB #", '@'+$80	; $CA=ORB #
	.asc	"ADDB #", '@'+$80	; $CB=ADD B #
	.asc	"LDD #", '&'+$80	; $CC=LDD #
	.asc	'?'+$80				; $CD=?
	.asc	"LDU #", '&'+$80	; $CE=LDU #
	.asc	'?'+$80				; $CF=?

	.asc	"SUBB ",'@'+$80	; $D0=SUB B dir
	.asc	"CMPB ",'@'+$80	; $D1=CMP B dir
	.asc	"SBCB ",'@'+$80	; $D2=SBC B dir
	.asc	"ADDD ",'@'+$80	; $D3=ADDD dir
	.asc	"ANDB ",'@'+$80	; $D4=AND B dir
	.asc	"BITB ",'@'+$80	; $D5=BIT B dir
	.asc	"LDB ", '@'+$80	; $D6=LDB dir
	.asc	"STB ", '@'+$80	; $D7=STB dir
	.asc	"EORB ",'@'+$80	; $D8=EOR B dir
	.asc	"ADCB ",'@'+$80	; $D9=ADC B dir
	.asc	"ORB ", '@'+$80	; $DA=ORB dir
	.asc	"ADDB ",'@'+$80	; $DB=ADD B dir
	.asc	"LDD ", '@'+$80	; $DC=LDD dir
	.asc	"STD ", '@'+$80	; $DD=STD dir
	.asc	"LDU ", '@'+$80	; $DE=LDU dir
	.asc	"STU ", '@'+$80	; $DF=STU dir

	.asc	"SUBB @, ", 'X'+$80	; $E0=SUB B idx
	.asc	"CMPB @, ", 'X'+$80	; $E1=CMP B idx
	.asc	"SBCB @, ", 'X'+$80	; $E2=SBC B idx
	.asc	"ADDD @, ", 'X'+$80	; $E3=ADDD idx
	.asc	"ANDB @, ", 'X'+$80	; $E4=AND B idx
	.asc	"BITB @, ", 'X'+$80	; $E5=BIT B idx
	.asc	"LDB @, ", 'X'+$80	; $E6=LDB idx
	.asc	"STB @, ", 'X'+$80	; $E7=STB idx
	.asc	"EORB @, ", 'X'+$80	; $E8=EOR B idx
	.asc	"ADCB @, ", 'X'+$80	; $E9=ADC B idx
	.asc	"ORB @, ", 'X'+$80	; $EA=ORB idx
	.asc	"ADDB @, ", 'X'+$80	; $EB=ADD B idx
	.asc	"LDD @, ", 'X'+$80	; $EC=LDD idx
	.asc	"STD @, ", 'X'+$80	; $ED=STD idx
	.asc	"LDU @, ", 'X'+$80	; $EE=LDU idx
	.asc	"STU @, ", 'X'+$80	; $EF=STU idx

	.asc	"SUBB ",'&'+$80	; $F0=SUB B ext
	.asc	"CMPB ",'&'+$80	; $F1=CMP B ext
	.asc	"SBCB ",'&'+$80	; $F2=SBC B ext
	.asc	"ADDD ",'&'+$80	; $F3=ADDD ext
	.asc	"ANDB ",'&'+$80	; $F4=AND B ext
	.asc	"BITB ",'&'+$80	; $F5=BIT B ext
	.asc	"LDB ", '&'+$80	; $F6=LDB ext
	.asc	"STB ", '&'+$80	; $F7=STB ext
	.asc	"EORB ",'&'+$80	; $F8=EOR B ext
	.asc	"ADCB ",'&'+$80	; $F9=ADC B ext
	.asc	"ORB ", '&'+$80	; $FA=ORB ext
	.asc	"ADDB ",'&'+$80	; $FB=ADD B ext
	.asc	"LDD ", '&'+$80	; $FC=LDD ext
	.asc	"STD ", '&'+$80	; $FD=STD ext
	.asc	"LDU ", '&'+$80	; $FE=LDU ext
	.asc	"STU ", '&'+$80	; $FF=STU ext

; ******************
; *** $10 PREFIX ***
; ******************

; ******************
; *** $11 PREFIX ***
; ******************

