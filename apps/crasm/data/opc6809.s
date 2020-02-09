; minimOS opcode list for (dis)assembler modules
; (c) 2015-2020 Carlos J. Santisteban
; last modified 20200209-1200

; ***** for 09asm MC6809 cross assembler *****
; Regular Motorola set (not 6309 yet)
; Opcode list as bit-7 terminated strings
; @ expects single byte, & expects word
; % expects RELATIVE addressing
; } expects LONG RELATIVE addressing
; *** new relative SIGNED offsets ***
; temporarily using ~ for 8-bit, \ for 16-bit offsets
; future versions should not use * or = anywhere!
; *** needs some special characters for prefixes, like Z80 ***
; temporarily using {2, {4... (value + $80, not ASCII) for easier indexing
; *** 6809 uses three kinds of postbytes! ***
; may work as generic prefixes, {6 for indexed, {8 for stack ops, {10 for reg.transfers

mc6809_std:
	.asc	"NEG ", '@'+$80		; $00=NEG dir
	.asc	'?'+$80				; $01=?
	.asc	'?'+$80				; $02=?
	.asc	"COM ", '@'+$80		; $03=COM dir
	.asc	"LSR ", '@'+$80		; $04=LSR dir
	.asc	'?'+$80				; $05=?
	.asc	"ROR ", '@'+$80		; $06=ROR dir
	.asc	"ASR ", '@'+$80		; $07=ASR dir
	.asc	"ASL ", '@'+$80		; $08=ASL dir (LSL)
	.asc	"ROL ", '@'+$80		; $09=ROL dir
	.asc	"DEC ", '@'+$80		; $0A=DEC dir
	.asc	'?'+$80				; $0B=?
	.asc	"INC ", '@'+$80		; $0C=INC dir
	.asc	"TST ", '@'+$80		; $0D=TST dir
	.asc	"JMP ", '@'+$80		; $0E=JMP dir
	.asc	"CLR ", '@'+$80		; $0F=CLR dir

	.asc	'{', 2+$80			; $10		** 6809 PREFIX **
	.asc	'{', 4+$80			; $11		** 6809 PREFIX **
	.asc	"NO", 'P'+$80		; $12=NOP
	.asc	"SYN", 'C'+$80		; $13=SYNC
	.asc	'?'+$80				; $14=?
	.asc	'?'+$80				; $15=?
	.asc	"LBRA ", '}'+$80	; $16=LBRA longrel
	.asc	"LBSR ", '}'+$80	; $17=LBSR longrel
	.asc	'?'+$80				; $18=?
	.asc	"DA", 'A'+$80		; $19=DAA
	.asc	"ORCC #", '@'+$80	; $1A=ORCC #
	.asc	'?'+$80				; $1B=?
	.asc	"ANDCC #", '@'+$80	; $1C=ANDCC #
	.asc	"SE", 'X'+$80		; $1D=SEX
	.asc	"EXG {", 10+$80		; $1E=EXG...
	.asc	"TFR {", 10+$80		; $1F=TFR...

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

	.asc	"LEAX {", 6+$80		; $30=LEAX idx
	.asc	"LEAY {", 6+$80		; $31=LEAY idx
	.asc	"LEAS {", 6+$80		; $32=LEAS idx
	.asc	"LEAU {", 6+$80		; $33=LEAU idx
	.asc	"PSHS {", 8+$80		; $34=PSHS...
	.asc	"PULS {", 8+$80		; $35=PULS...
	.asc	"PSHU {", 8+$80		; $36=PSHU...
	.asc	"PULU {", 8+$80		; $37=PULU...
	.asc	'?'+$80				; $38=?
	.asc	"RT", 'S'+$80		; $39=RTS
	.asc	"AB", 'X'+$80		; $3A=ABX
	.asc	"RT", 'I'+$80		; $3B=RTI
	.asc	"CWAI #", '@'+$80	; $3C=CWAI #
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

	.asc	"NEG {", 6+$80		; $60=NEG idx
	.asc	'?'+$80				; $61=?
	.asc	'?'+$80				; $62=?
	.asc	"COM {", 6+$80		; $63=COM idx
	.asc	"LSR {", 6+$80		; $64=LSR idx
	.asc	'?'+$80				; $65=?
	.asc	"ROR {", 6+$80		; $66=ROR idx
	.asc	"ASR {", 6+$80		; $67=ASR idx
	.asc	"ASL {", 6+$80		; $68=ASL idx (LSL)
	.asc	"ROL {", 6+$80		; $69=ROL idx
	.asc	"DEC {", 6+$80		; $6A=DEC idx
	.asc	'?'+$80				; $6B=?
	.asc	"INC {", 6+$80		; $6C=INC idx
	.asc	"TST {", 6+$80		; $6D=TST idx
	.asc	"JMP {", 6+$80		; $6E=JMP idx
	.asc	"CLR {", 6+$80		; $6F=CLR idx

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

	.asc	"SUBA {", 6+$80		; $A0=SUB A idx
	.asc	"CMPA {", 6+$80		; $A1=CMP A idx
	.asc	"SBCA {", 6+$80		; $A2=SBC A idx
	.asc	"SUBD {", 6+$80		; $A3=SUBD idx
	.asc	"ANDA {", 6+$80		; $A4=AND A idx
	.asc	"BITA {", 6+$80		; $A5=BIT A idx
	.asc	"LDA {", 6+$80		; $A6=LDA idx
	.asc	"STA {", 6+$80		; $A7=STA idx
	.asc	"EORA {", 6+$80		; $A8=EOR A idx
	.asc	"ADCA {", 6+$80		; $A9=ADC A idx
	.asc	"ORA {", 6+$80		; $AA=ORA idx
	.asc	"ADDA {", 6+$80		; $AB=ADD A idx
	.asc	"CMPX {", 6+$80		; $AC=CMPX idx
	.asc	"JSR {", 6+$80		; $AD=JSR idx
	.asc	"LDX {", 6+$80		; $AE=LDX idx
	.asc	"STX {", 6+$80		; $AF=STX idx

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

	.asc	"SUBB ", '@'+$80	; $D0=SUB B dir
	.asc	"CMPB ", '@'+$80	; $D1=CMP B dir
	.asc	"SBCB ", '@'+$80	; $D2=SBC B dir
	.asc	"ADDD ", '@'+$80	; $D3=ADDD dir
	.asc	"ANDB ", '@'+$80	; $D4=AND B dir
	.asc	"BITB ", '@'+$80	; $D5=BIT B dir
	.asc	"LDB ", '@'+$80		; $D6=LDB dir
	.asc	"STB ", '@'+$80		; $D7=STB dir
	.asc	"EORB ", '@'+$80	; $D8=EOR B dir
	.asc	"ADCB ", '@'+$80	; $D9=ADC B dir
	.asc	"ORB ", '@'+$80		; $DA=ORB dir
	.asc	"ADDB ", '@'+$80	; $DB=ADD B dir
	.asc	"LDD ", '@'+$80		; $DC=LDD dir
	.asc	"STD ", '@'+$80		; $DD=STD dir
	.asc	"LDU ", '@'+$80		; $DE=LDU dir
	.asc	"STU ", '@'+$80		; $DF=STU dir

	.asc	"SUBB {", 6+$80		; $E0=SUB B idx
	.asc	"CMPB {", 6+$80		; $E1=CMP B idx
	.asc	"SBCB {", 6+$80		; $E2=SBC B idx
	.asc	"ADDD {", 6+$80		; $E3=ADDD idx
	.asc	"ANDB {", 6+$80		; $E4=AND B idx
	.asc	"BITB {", 6+$80		; $E5=BIT B idx
	.asc	"LDB {", 6+$80		; $E6=LDB idx
	.asc	"STB {", 6+$80		; $E7=STB idx
	.asc	"EORB {", 6+$80		; $E8=EOR B idx
	.asc	"ADCB {", 6+$80		; $E9=ADC B idx
	.asc	"ORB {", 6+$80		; $EA=ORB idx
	.asc	"ADDB {", 6+$80		; $EB=ADD B idx
	.asc	"LDD {", 6+$80		; $EC=LDD idx
	.asc	"STD {", 6+$80		; $ED=STD idx
	.asc	"LDU {", 6+$80		; $EE=LDU idx
	.asc	"STU {", 6+$80		; $EF=STU idx

	.asc	"SUBB ", '&'+$80	; $F0=SUB B ext
	.asc	"CMPB ", '&'+$80	; $F1=CMP B ext
	.asc	"SBCB ", '&'+$80	; $F2=SBC B ext
	.asc	"ADDD ", '&'+$80	; $F3=ADDD ext
	.asc	"ANDB ", '&'+$80	; $F4=AND B ext
	.asc	"BITB ", '&'+$80	; $F5=BIT B ext
	.asc	"LDB ", '&'+$80		; $F6=LDB ext
	.asc	"STB ", '&'+$80		; $F7=STB ext
	.asc	"EORB ", '&'+$80	; $F8=EOR B ext
	.asc	"ADCB ", '&'+$80	; $F9=ADC B ext
	.asc	"ORB ", '&'+$80		; $FA=ORB ext
	.asc	"ADDB ", '&'+$80	; $FB=ADD B ext
	.asc	"LDD ", '&'+$80		; $FC=LDD ext
	.asc	"STD ", '&'+$80		; $FD=STD ext
	.asc	"LDU ", '&'+$80		; $FE=LDU ext
	.asc	"STU ", '&'+$80		; $FF=STU ext

; ******************
; *** $10 PREFIX ***
; ******************
mc6809_10:
	.dsb	33, '?'+$80			; filler $00-20

	.asc	"LBRN ", '}'+$80	; $10 $21=LBRN long rel
	.asc	"LBHI ", '}'+$80	; $10 $22=LBHI long rel
	.asc	"LBLS ", '}'+$80	; $10 $23=LBLS long rel
	.asc	"LBCC ", '}'+$80	; $10 $24=LBCC long rel
	.asc	"LBCS ", '}'+$80	; $10 $25=LBCS long rel
	.asc	"LBNE ", '}'+$80	; $10 $26=LBNE long rel
	.asc	"LBEQ ", '}'+$80	; $10 $27=LBEQ long rel
	.asc	"LBVC ", '}'+$80	; $10 $28=LBVC long rel
	.asc	"LBVS ", '}'+$80	; $10 $29=LBVS long rel
	.asc	"LBPL ", '}'+$80	; $10 $2A=LBPL long rel
	.asc	"LBMI ", '}'+$80	; $10 $2B=LBMI long rel
	.asc	"LBGE ", '}'+$80	; $10 $2C=LBGE long rel
	.asc	"LBLT ", '}'+$80	; $10 $2D=LBLT long rel
	.asc	"LBGT ", '}'+$80	; $10 $2E=LBGT long rel
	.asc	"LBLE ", '}'+$80	; $10 $2F=LBLE long rel

	.dsb	15, '?'+$80			; filler $30-3E
	.asc	"SWI", '2'+$80		; $10 $3F=SWI2

	.dsb	67, '?'+$80			; filler $40-82

	.asc	"CMPD #", '&'+$80	; $10 $83=CMPD #
	.dsb	8, '?'+$80			; filler $84-8B
	.asc	"CMPY #", '&'+$80	; $10 $8C=CMPY #
	.asc	'?'+$80				; $10 $8D=?
	.asc	"LDY #", '&'+$80	; $10 $8E=LDY #

	.dsb	4, '?'+$80			; filler $8F-92

	.asc	"CMPD ", '@'+$80	; $10 $93=CMPD dir
	.dsb	8, '?'+$80			; filler $94-9B
	.asc	"CMPY ", '@'+$80	; $10 $9C=CMPY dir
	.asc	'?'+$80				; $10 $9D=?
	.asc	"LDY ", '@'+$80		; $10 $9E=LDY dir
	.asc	"STY ", '@'+$80		; $10 $9F=STY dir

	.dsb	3, '?'+$80			; filler $A0-A2
	.asc	"CMPD {", 6+$80		; $10 $A3=CMPD idx
	.dsb	8, '?'+$80			; filler $A4-AB
	.asc	"CMPY {", 6+$80		; $10 $AC=CMPY idx
	.asc	'?'+$80				; $10 $AD=?
	.asc	"LDY {", 6+$80		; $10 $AE=LDY idx
	.asc	"STY {", 6+$80		; $10 $AF=STY idx

	.dsb	3, '?'+$80			; filler $B0-B2
	.asc	"CMPD ", '&'+$80	; $10 $B3=CMPD ext
	.dsb	8, '?'+$80			; filler $B4-BB
	.asc	"CMPY ", '&'+$80	; $10 $BC=CMPY ext
	.asc	'?'+$80				; $10 $BD=?
	.asc	"LDY ", '&'+$80		; $10 $BE=LDY ext
	.asc	"STY ", '&'+$80		; $10 $BF=STY ext

	.dsb	14, '?'+$80			; filler $C0-CD
	.asc	"LDS #", '&'+$80	; $10 $CE=LDS #

	.dsb	15, '?'+$80			; filler $CF-DD

	.asc	"LDS ", '@'+$80		; $10 $DE=LDS dir
	.asc	"STS ", '@'+$80		; $10 $DF=STS dir

	.dsb	14, '?'+$80			; filler $E0-ED
	.asc	"LDS {", 6+$80		; $10 $EE=LDS idx
	.asc	"STS {", 6+$80		; $10 $EF=STS idx

	.dsb	14, '?'+$80			; filler $F0-FD
	.asc	"LDS ", '&'+$80		; $10 $FE=LDS ext
	.asc	"STS ", '&'+$80		; $10 $FF=STS ext

; ******************
; *** $11 PREFIX ***
; ******************
mc6809_11:
	.dsb	63, '?'+$80			; filler $00-3E

	.asc	"SWI", '3'+$80		; $11 $3F=SWI3

	.dsb	67, '?'+$80			; filler $40-82

	.asc	"CMPU #", '&'+$80	; $11 $83=CMPU #
	.dsb	8, '?'+$80			; filler $84-8B
	.asc	"CMPS #", '&'+$80	; $11 $8C=CMPS #

	.dsb	6, '?'+$80			; filler $8D-92

	.asc	"CMPU ", '@'+$80	; $11 $93=CMPU dir
	.dsb	8, '?'+$80			; filler $94-9B
	.asc	"CMPS ", '@'+$80	; $11 $9C=CMPS dir

	.dsb	6, '?'+$80			; filler $9D-A2

	.asc	"CMPU {", 6+$80		; $11 $A3=CMPU idx
	.dsb	8, '?'+$80			; filler $A4-AB
	.asc	"CMPS {", 6+$80		; $11 $AC=CMPS idx

	.dsb	6, '?'+$80			; filler $AD-B2

	.asc	"CMPU ", '&'+$80	; $11 $B3=CMPU ext
	.dsb	8, '?'+$80			; filler $B4-BB
	.asc	"CMPS ", '&'+$80	; $11 $BC=CMPS ext

	.dsb	67, '?'+$80			; filler $BD-FF

; ******************************************************************
; *** should include some strings for the substitution postbytes ***
; ******************************************************************

; **************************************
; *** brute force indexed post bytes ***
; **************************************
mc6809_idx:
	.asc	"0, ", 'X'+$80		; %00000000 = X with offset 0?
	.asc	"1, ", 'X'+$80		; %000sdddd = X with 5-bit offset
	.asc	"2, ", 'X'+$80
	.asc	"3, ", 'X'+$80
	.asc	"4, ", 'X'+$80
	.asc	"5, ", 'X'+$80
	.asc	"6, ", 'X'+$80
	.asc	"7, ", 'X'+$80
	.asc	"8, ", 'X'+$80
	.asc	"9, ", 'X'+$80
	.asc	"10, ", 'X'+$80
	.asc	"11, ", 'X'+$80
	.asc	"12, ", 'X'+$80
	.asc	"13, ", 'X'+$80
	.asc	"14, ", 'X'+$80
	.asc	"15, ", 'X'+$80

	.asc	"-16, ", 'X'+$80
	.asc	"-15, ", 'X'+$80
	.asc	"-14, ", 'X'+$80
	.asc	"-13, ", 'X'+$80
	.asc	"-12, ", 'X'+$80
	.asc	"-11, ", 'X'+$80
	.asc	"-10, ", 'X'+$80
	.asc	"-9, ", 'X'+$80
	.asc	"-8, ", 'X'+$80
	.asc	"-7, ", 'X'+$80
	.asc	"-6, ", 'X'+$80
	.asc	"-5, ", 'X'+$80
	.asc	"-4, ", 'X'+$80
	.asc	"-3, ", 'X'+$80
	.asc	"-2, ", 'X'+$80
	.asc	"-1, ", 'X'+$80

	.asc	"0, ", 'Y'+$80		; %00100000 = Y with offset 0?
	.asc	"1, ", 'Y'+$80		; %001sdddd = Y with 5-bit offset
	.asc	"2, ", 'Y'+$80
	.asc	"3, ", 'Y'+$80
	.asc	"4, ", 'Y'+$80
	.asc	"5, ", 'Y'+$80
	.asc	"6, ", 'Y'+$80
	.asc	"7, ", 'Y'+$80
	.asc	"8, ", 'Y'+$80
	.asc	"9, ", 'Y'+$80
	.asc	"10, ", 'Y'+$80
	.asc	"11, ", 'Y'+$80
	.asc	"12, ", 'Y'+$80
	.asc	"13, ", 'Y'+$80
	.asc	"14, ", 'Y'+$80
	.asc	"15, ", 'Y'+$80

	.asc	"-16, ", 'Y'+$80
	.asc	"-15, ", 'Y'+$80
	.asc	"-14, ", 'Y'+$80
	.asc	"-13, ", 'Y'+$80
	.asc	"-12, ", 'Y'+$80
	.asc	"-11, ", 'Y'+$80
	.asc	"-10, ", 'Y'+$80
	.asc	"-9, ", 'Y'+$80
	.asc	"-8, ", 'Y'+$80
	.asc	"-7, ", 'Y'+$80
	.asc	"-6, ", 'Y'+$80
	.asc	"-5, ", 'Y'+$80
	.asc	"-4, ", 'Y'+$80
	.asc	"-3, ", 'Y'+$80
	.asc	"-2, ", 'Y'+$80
	.asc	"-1, ", 'Y'+$80

	.asc	"0, ", 'U'+$80		; %01000000 = U with offset 0?
	.asc	"1, ", 'U'+$80		; %010sdddd = U with 5-bit offset
	.asc	"2, ", 'U'+$80
	.asc	"3, ", 'U'+$80
	.asc	"4, ", 'U'+$80
	.asc	"5, ", 'U'+$80
	.asc	"6, ", 'U'+$80
	.asc	"7, ", 'U'+$80
	.asc	"8, ", 'U'+$80
	.asc	"9, ", 'U'+$80
	.asc	"10, ", 'U'+$80
	.asc	"11, ", 'U'+$80
	.asc	"12, ", 'U'+$80
	.asc	"13, ", 'U'+$80
	.asc	"14, ", 'U'+$80
	.asc	"15, ", 'U'+$80

	.asc	"-16, ", 'U'+$80
	.asc	"-15, ", 'U'+$80
	.asc	"-14, ", 'U'+$80
	.asc	"-13, ", 'U'+$80
	.asc	"-12, ", 'U'+$80
	.asc	"-11, ", 'U'+$80
	.asc	"-10, ", 'U'+$80
	.asc	"-9, ", 'U'+$80
	.asc	"-8, ", 'U'+$80
	.asc	"-7, ", 'U'+$80
	.asc	"-6, ", 'U'+$80
	.asc	"-5, ", 'U'+$80
	.asc	"-4, ", 'U'+$80
	.asc	"-3, ", 'U'+$80
	.asc	"-2, ", 'U'+$80
	.asc	"-1, ", 'U'+$80

	.asc	"0, ", 'S'+$80		; %01100000 = S with offset 0?
	.asc	"1, ", 'S'+$80		; %011sdddd = S with 5-bit offset
	.asc	"2, ", 'S'+$80
	.asc	"3, ", 'S'+$80
	.asc	"4, ", 'S'+$80
	.asc	"5, ", 'S'+$80
	.asc	"6, ", 'S'+$80
	.asc	"7, ", 'S'+$80
	.asc	"8, ", 'S'+$80
	.asc	"9, ", 'S'+$80
	.asc	"10, ", 'S'+$80
	.asc	"11, ", 'S'+$80
	.asc	"12, ", 'S'+$80
	.asc	"13, ", 'S'+$80
	.asc	"14, ", 'S'+$80
	.asc	"15, ", 'S'+$80

	.asc	"-16, ", 'S'+$80
	.asc	"-15, ", 'S'+$80
	.asc	"-14, ", 'S'+$80
	.asc	"-13, ", 'S'+$80
	.asc	"-12, ", 'S'+$80
	.asc	"-11, ", 'S'+$80
	.asc	"-10, ", 'S'+$80
	.asc	"-9, ", 'S'+$80
	.asc	"-8, ", 'S'+$80
	.asc	"-7, ", 'S'+$80
	.asc	"-6, ", 'S'+$80
	.asc	"-5, ", 'S'+$80
	.asc	"-4, ", 'S'+$80
	.asc	"-3, ", 'S'+$80
	.asc	"-2, ", 'S'+$80
	.asc	"-1, ", 'S'+$80

	.asc	", X", '+'+$80		; %10000000 = ,X+
	.asc	", X+", '+'+$80		; %10000001 = ,X++
	.asc	", -", 'X'+$80		; %10000010 = ,-X
	.asc	", --", 'X'+$80		; %10000011 = ,--X
	.asc	", ", 'X'+$80		; %10000100 = ,X (no offset)
	.asc	"B, ", 'X'+$80		; %10000101 = B,X
	.asc	"A, ", 'X'+$80		; %10000110 = A,X
	.asc	'?'+$80				; %10000111 ILLEGAL
	.asc	"~, ", 'X'+$80		; %10001000 = n,X (8-bit offset)
	.asc	"\, ", 'X'+$80		; %10001001 = nn,X (16-bit offset)
	.asc	'?'+$80				; %10001010 ILLEGAL
	.asc	"D, ", 'X'+$80		; %10001011 = D,X
	.asc	"~, P", 'C'+$80		; %1xx01100 = n,PC (8-bit offset)
	.asc	"\, P", 'C'+$80		; %1xx01101 = nn,PC (16-bit offset)
	.asc	'?'+$80				; %10001110 ILLEGAL
	.asc	'?'+$80				; %10001111 ILLEGAL

	.asc	'?'+$80				; %10010000 ILLEGAL
	.asc	"[, X++", ']'+$80	; %10010001 = [,X++]
	.asc	'?'+$80				; %10010010 ILLEGAL
	.asc	"[, --X", ']'+$80	; %10010011 = [,--X]
	.asc	"[, X", ']'+$80		; %10010100 = [,X] (no offset)
	.asc	"[B, X", ']'+$80	; %10010101 = [B,X]
	.asc	"[A, X", ']'+$80	; %10010110 = [A,X]
	.asc	'?'+$80				; %10010111 ILLEGAL
	.asc	"[~, X", ']'+$80	; %10011000 = [n,X] (8-bit offset)
	.asc	"[\, X", ']'+$80	; %10011001 = [nn,X] (16-bit offset)
	.asc	'?'+$80				; %10011010 ILLEGAL
	.asc	"[D, X", ']'+$80	; %10011011 = [D,X]
	.asc	"[~, P", ']'+$80	; %1xx11100 = [n,PC] (8-bit offset)
	.asc	"[\, P", ']'+$80	; %1xx11101 = [nn,PC] (16-bit offset)
	.asc	'?'+$80				; %10001110 ILLEGAL
	.asc	"[&", ']'+$80		; %10011111 = [nn]

	.asc	", Y", '+'+$80		; %10100000 = ,Y+
	.asc	", Y+", '+'+$80		; %10100001 = ,Y++
	.asc	", -", 'Y'+$80		; %10100010 = ,-Y
	.asc	", --", 'Y'+$80		; %10100011 = ,--Y
	.asc	", ", 'Y'+$80		; %10100100 = ,Y (no offset)
	.asc	"B, ", 'Y'+$80		; %10100101 = B,Y
	.asc	"A, ", 'Y'+$80		; %10100110 = A,Y
	.asc	'?'+$80				; %10100111 ILLEGAL
	.asc	"~, ", 'Y'+$80		; %10101000 = n,Y (8-bit offset)
	.asc	"\, ", 'Y'+$80		; %10101001 = nn,Y (16-bit offset)
	.asc	'?'+$80				; %10101010 ILLEGAL
	.asc	"D, ", 'Y'+$80		; %10101011 = D,Y
	.asc	"~, P", 'C'+$80		; %1xx01100 = n,PC (8-bit offset)
	.asc	"\, P", 'C'+$80		; %1xx01101 = nn,PC (16-bit offset)
	.asc	'?'+$80				; %10101110 ILLEGAL
	.asc	'?'+$80				; %10101111 ILLEGAL

	.asc	'?'+$80				; %10110000 ILLEGAL
	.asc	"[, Y++", ']'+$80	; %10110001 = [,Y++]
	.asc	'?'+$80				; %10110010 ILLEGAL
	.asc	"[, --Y", ']'+$80	; %10110011 = [,--Y]
	.asc	"[, Y", ']'+$80		; %10110100 = [,Y] (no offset)
	.asc	"[B, Y", ']'+$80	; %10110101 = [B,Y]
	.asc	"[A, Y", ']'+$80	; %10110110 = [A,Y]
	.asc	'?'+$80				; %10110111 ILLEGAL
	.asc	"[~, Y", ']'+$80	; %10111000 = [n,Y] (8-bit offset)
	.asc	"[\, Y", ']'+$80	; %10111001 = [nn,Y] (16-bit offset)
	.asc	'?'+$80				; %10111010 ILLEGAL
	.asc	"[D, Y", ']'+$80	; %10111011 = [D,Y]
	.asc	"[~, P", ']'+$80	; %1xx11100 = [n,PC] (8-bit offset)
	.asc	"[\, P", ']'+$80	; %1xx11101 = [nn,PC] (16-bit offset)
	.asc	'?'+$80				; %10101110 ILLEGAL
	.asc	"[&", ']'+$80		; %10111111 = [nn] ? ?

	.asc	", U", '+'+$80		; %11000000 = ,U+
	.asc	", U+", '+'+$80		; %11000001 = ,U++
	.asc	", -", 'U'+$80		; %11000010 = ,-U
	.asc	", --", 'U'+$80		; %11000011 = ,--U
	.asc	", ", 'U'+$80		; %11000100 = ,U (no offset)
	.asc	"B, ", 'U'+$80		; %11000101 = B,U
	.asc	"A, ", 'U'+$80		; %11000110 = A,U
	.asc	'?'+$80				; %11000111 ILLEGAL
	.asc	"~, ", 'U'+$80		; %11001000 = n,U (8-bit offset)
	.asc	"\, ", 'U'+$80		; %11001001 = nn,U (16-bit offset)
	.asc	'?'+$80				; %11001010 ILLEGAL
	.asc	"D, ", 'U'+$80		; %11001011 = D,U
	.asc	"~, P", 'C'+$80		; %1xx01100 = n,PC (8-bit offset)
	.asc	"\, P", 'C'+$80		; %1xx01101 = nn,PC (16-bit offset)
	.asc	'?'+$80				; %11001110 ILLEGAL
	.asc	'?'+$80				; %11001111 ILLEGAL

	.asc	'?'+$80				; %11010000 ILLEGAL
	.asc	"[, U++", ']'+$80	; %11010001 = [,U++]
	.asc	'?'+$80				; %11010010 ILLEGAL
	.asc	"[, --U", ']'+$80	; %11010011 = [,--U]
	.asc	"[, U", ']'+$80		; %11010100 = [,U] (no offset)
	.asc	"[B, U", ']'+$80	; %11010101 = [B,U]
	.asc	"[A, U", ']'+$80	; %11010110 = [A,U]
	.asc	'?'+$80				; %11010111 ILLEGAL
	.asc	"[~, U", ']'+$80	; %11011000 = [n,U] (8-bit offset)
	.asc	"[\, U", ']'+$80	; %11011001 = [nn,U] (16-bit offset)
	.asc	'?'+$80				; %11011010 ILLEGAL
	.asc	"[D, U", ']'+$80	; %11011011 = [D,U]
	.asc	"[~, P", ']'+$80	; %1xx11100 = [n,PC] (8-bit offset)
	.asc	"[\, P", ']'+$80	; %1xx11101 = [nn,PC] (16-bit offset)
	.asc	'?'+$80				; %11001110 ILLEGAL
	.asc	"[&", ']'+$80		; %11011111 = [nn] ? ?

	.asc	", S", '+'+$80		; %11100000 = ,S+
	.asc	", S+", '+'+$80		; %11100001 = ,S++
	.asc	", -", 'S'+$80		; %11100010 = ,-S
	.asc	", --", 'S'+$80		; %11100011 = ,--S
	.asc	", ", 'S'+$80		; %11100100 = ,S (no offset)
	.asc	"B, ", 'S'+$80		; %11100101 = B,S
	.asc	"A, ", 'S'+$80		; %11100110 = A,S
	.asc	'?'+$80				; %11100111 ILLEGAL
	.asc	"~, ", 'S'+$80		; %11101000 = n,S (8-bit offset)
	.asc	"\, ", 'S'+$80		; %11101001 = nn,S (16-bit offset)
	.asc	'?'+$80				; %11101010 ILLEGAL
	.asc	"D, ", 'S'+$80		; %11101011 = D,S
	.asc	"~, P", 'C'+$80		; %1xx01100 = n,PC (8-bit offset)
	.asc	"\, P", 'C'+$80		; %1xx01101 = nn,PC (16-bit offset)
	.asc	'?'+$80				; %11101110 ILLEGAL
	.asc	'?'+$80				; %11101111 ILLEGAL

	.asc	'?'+$80				; %11110000 ILLEGAL
	.asc	"[, S++", ']'+$80	; %11110001 = [,S++]
	.asc	'?'+$80				; %11110010 ILLEGAL
	.asc	"[, --S", ']'+$80	; %11110011 = [,--S]
	.asc	"[, S", ']'+$80		; %11110100 = [,S] (no offset)
	.asc	"[B, S", ']'+$80	; %11110101 = [B,S]
	.asc	"[A, S", ']'+$80	; %11110110 = [A,S]
	.asc	'?'+$80				; %11110111 ILLEGAL
	.asc	"[~, S", ']'+$80	; %11111000 = [n,S] (8-bit offset)
	.asc	"[\, S", ']'+$80	; %11111001 = [nn,S] (16-bit offset)
	.asc	'?'+$80				; %11111010 ILLEGAL
	.asc	"[D, S", ']'+$80	; %11111011 = [D,S]
	.asc	"[~, P", ']'+$80	; %1xx11100 = [n,PC] (8-bit offset)
	.asc	"[\, P", ']'+$80	; %1xx11101 = [nn,PC] (16-bit offset)
	.asc	'?'+$80				; %11101110 ILLEGAL
	.asc	"[&", ']'+$80		; %11111111 = [nn] ? ?

; ***************************************
; *** brute force stackops post bytes ***
; ***************************************
mc6809_sp:
; think about simply using an immediate parameter...
	.asc	'?'+$80				; %00000000	ILLEGAL
	.asc	"C", 'C'+$80		; %00000001 = CC
	.asc	'A'+$80				; %00000010 = A
	.asc	"A, C", 'C'+$80		; %00000011 = A,CC
	.asc	'B'+$80				; %00000100 = B
	.asc	"B, C", 'C'+$80		; %00000101 = B,CC
	.asc	"B, ", 'A'+$80		; %00000110 = B,A
	.asc	"B, A, C", 'C'+$80	; %00000111 = B,A,CC
	.asc	"D", 'P'+$80		; %00001000 = DP
	.asc	"DP, C", 'C'+$80	; %00001001 = DP,CC
	.asc	"DP, ", 'A'+$80		; %00001010 = DP,A
	.asc	"DP, A, C", 'C'+$80	; %00001011 = DP,A,CC
	.asc	"DP, ", 'B'+$80		; %00001100 = DP,B
	.asc	"DP, B, C", 'C'+$80	; %00001101 = DP,B,CC
	.asc	"DP, B, ", 'A'+$80	; %00001110 = DP,B,A
	.asc	"DP, B, A, C", 'C'+$80	; %00001111 = DP,B,A,CC

	.asc	'X'+$80				; %00010000 = X
	.asc	"X, C", 'C'+$80		; %00010001 = X,CC
	.asc	"X, ", 'A'+$80		; %00010010 = X,A
	.asc	"X, A, C", 'C'+$80	; %00010011 = X,A,CC
	.asc	"X, ", 'B'+$80		; %00010100 = X,B
	.asc	"X, B, C", 'C'+$80	; %00010101 = X,B,CC
	.asc	"X, B, ", 'A'+$80	; %00010110 = X,B,A
	.asc	"X, B, A, C", 'C'+$80	; %00010111 = X,B,A,CC
	.asc	"X, D", 'P'+$80		; %00011000 = X,DP
	.asc	"X, DP, C", 'C'+$80	; %00011001 = X,DP,CC
	.asc	"X, DP, ", 'A'+$80	; %00011010 = X,DP,A
	.asc	"X, DP, A, C", 'C'+$80	; %00011011 = X,DP,A,CC
	.asc	"X, DP, ", 'B'+$80	; %00011100 = X,DP,B
	.asc	"X, DP, B, C", 'C'+$80	; %00011101 = X,DP,B,CC
	.asc	"X, DP, B, ", 'A'+$80	; %00011110 = X,DP,B,A
	.asc	"X,DP,B,A,C", 'C'+$80	; %00011111 = X,DP,B,A,CC



; *******************************************
; *** brute force reg.transfer post bytes ***
; *******************************************
mc6809_reg:
	.asc	"D, ", 'D'+$80		; $00 = D > D
	.asc	"D, ", 'X'+$80		; $01 = D > X
	.asc	"D, ", 'Y'+$80		; $02 = D > Y
	.asc	"D, ", 'U'+$80		; $03 = D > U
	.asc	"D, ", 'S'+$80		; $04 = D > S
	.asc	"D, P", 'C'+$80		; $05 = D > PC
	.asc	'?'+$80				; $06 ILLEGAL
	.asc	'?'+$80				; $07 ILLEGAL
	.asc	"D, ", 'A'+$80		; $08 = D > A
	.asc	"D, ", 'B'+$80		; $09 = D > B
	.asc	"D, C", 'C'+$80		; $0A = D > CC
	.asc	"D, D", 'P'+$80		; $0B = D > DP
	.asc	'?'+$80				; $0C ILLEGAL
	.asc	'?'+$80				; $0D ILLEGAL
	.asc	'?'+$80				; $0E ILLEGAL
	.asc	'?'+$80				; $0F ILLEGAL

	.asc	"X, ", 'D'+$80		; $10 = X > D
	.asc	"X, ", 'X'+$80		; $11 = X > X
	.asc	"X, ", 'Y'+$80		; $12 = X > Y
	.asc	"X, ", 'U'+$80		; $13 = X > U
	.asc	"X, ", 'S'+$80		; $14 = X > S
	.asc	"X, P", 'C'+$80		; $15 = X > PC
	.asc	'?'+$80				; $16 ILLEGAL
	.asc	'?'+$80				; $17 ILLEGAL
	.asc	"X, ", 'A'+$80		; $18 = X > A
	.asc	"X, ", 'B'+$80		; $19 = X > B
	.asc	"X, C", 'C'+$80		; $1A = X > CC
	.asc	"X, D", 'P'+$80		; $1B = X > DP
	.asc	'?'+$80				; $1C ILLEGAL
	.asc	'?'+$80				; $1D ILLEGAL
	.asc	'?'+$80				; $1E ILLEGAL
	.asc	'?'+$80				; $1F ILLEGAL

	.asc	"Y, ", 'D'+$80		; $20 = Y > D
	.asc	"Y, ", 'X'+$80		; $21 = Y > X
	.asc	"Y, ", 'Y'+$80		; $22 = Y > Y
	.asc	"Y, ", 'U'+$80		; $23 = Y > U
	.asc	"Y, ", 'S'+$80		; $24 = Y > S
	.asc	"Y, P", 'C'+$80		; $25 = Y > PC
	.asc	'?'+$80				; $26 ILLEGAL
	.asc	'?'+$80				; $27 ILLEGAL
	.asc	"Y, ", 'A'+$80		; $28 = Y > A
	.asc	"Y, ", 'B'+$80		; $29 = Y > B
	.asc	"Y, C", 'C'+$80		; $2A = Y > CC
	.asc	"Y, D", 'P'+$80		; $2B = Y > DP
	.asc	'?'+$80				; $2C ILLEGAL
	.asc	'?'+$80				; $2D ILLEGAL
	.asc	'?'+$80				; $2E ILLEGAL
	.asc	'?'+$80				; $2F ILLEGAL

	.asc	"U, ", 'D'+$80		; $30 = U > D
	.asc	"U, ", 'X'+$80		; $31 = U > X
	.asc	"U, ", 'Y'+$80		; $32 = U > Y
	.asc	"U, ", 'U'+$80		; $33 = U > U
	.asc	"U, ", 'S'+$80		; $34 = U > S
	.asc	"U, P", 'C'+$80		; $35 = U > PC
	.asc	'?'+$80				; $36 ILLEGAL
	.asc	'?'+$80				; $37 ILLEGAL
	.asc	"U, ", 'A'+$80		; $38 = U > A
	.asc	"U, ", 'B'+$80		; $39 = U > B
	.asc	"U, C", 'C'+$80		; $3A = U > CC
	.asc	"U, D", 'P'+$80		; $3B = U > DP
	.asc	'?'+$80				; $3C ILLEGAL
	.asc	'?'+$80				; $3D ILLEGAL
	.asc	'?'+$80				; $3E ILLEGAL
	.asc	'?'+$80				; $3F ILLEGAL

	.asc	"S, ", 'D'+$80		; $40 = S > D
	.asc	"S, ", 'X'+$80		; $41 = S > X
	.asc	"S, ", 'Y'+$80		; $42 = S > Y
	.asc	"S, ", 'U'+$80		; $43 = S > U
	.asc	"S, ", 'S'+$80		; $44 = S > S
	.asc	"S, P", 'C'+$80		; $45 = S > PC
	.asc	'?'+$80				; $46 ILLEGAL
	.asc	'?'+$80				; $47 ILLEGAL
	.asc	"S, ", 'A'+$80		; $48 = S > A
	.asc	"S, ", 'B'+$80		; $49 = S > B
	.asc	"S, C", 'C'+$80		; $4A = S > CC
	.asc	"S, D", 'P'+$80		; $4B = S > DP
	.asc	'?'+$80				; $4C ILLEGAL
	.asc	'?'+$80				; $4D ILLEGAL
	.asc	'?'+$80				; $4E ILLEGAL
	.asc	'?'+$80				; $4F ILLEGAL

	.asc	"PC, ", 'D'+$80		; $50 = PC > D
	.asc	"PC, ", 'X'+$80		; $51 = PC > X
	.asc	"PC, ", 'Y'+$80		; $52 = PC > Y
	.asc	"PC, ", 'U'+$80		; $53 = PC > U
	.asc	"PC, ", 'S'+$80		; $54 = PC > S
	.asc	"PC, P", 'C'+$80	; $55 = PC > PC
	.asc	'?'+$80				; $56 ILLEGAL
	.asc	'?'+$80				; $57 ILLEGAL
	.asc	"PC, ", 'A'+$80		; $58 = PC > A
	.asc	"PC, ", 'B'+$80		; $59 = PC > B
	.asc	"PC, C", 'C'+$80	; $5A = PC > CC
	.asc	"PC, D", 'P'+$80	; $5B = PC > DP
	.asc	'?'+$80				; $5C ILLEGAL
	.asc	'?'+$80				; $5D ILLEGAL
	.asc	'?'+$80				; $5E ILLEGAL
	.asc	'?'+$80				; $5F ILLEGAL

	.dsb	32, '?'+$80			; $60-7F filler

	.asc	"A, ", 'D'+$80		; $80 = A > D
	.asc	"A, ", 'X'+$80		; $81 = A > X
	.asc	"A, ", 'Y'+$80		; $82 = A > Y
	.asc	"A, ", 'U'+$80		; $83 = A > U
	.asc	"A, ", 'S'+$80		; $84 = A > S
	.asc	"A, P", 'C'+$80		; $85 = A > PC
	.asc	'?'+$80				; $86 ILLEGAL
	.asc	'?'+$80				; $87 ILLEGAL
	.asc	"A, ", 'A'+$80		; $88 = A > A
	.asc	"A, ", 'B'+$80		; $89 = A > B
	.asc	"A, C", 'C'+$80		; $8A = A > CC
	.asc	"A, D", 'P'+$80		; $8B = A > DP
	.asc	'?'+$80				; $8C ILLEGAL
	.asc	'?'+$80				; $8D ILLEGAL
	.asc	'?'+$80				; $8E ILLEGAL
	.asc	'?'+$80				; $8F ILLEGAL

	.asc	"B, ", 'D'+$80		; $90 = B > D
	.asc	"B, ", 'X'+$80		; $91 = B > X
	.asc	"B, ", 'Y'+$80		; $92 = B > Y
	.asc	"B, ", 'U'+$80		; $93 = B > U
	.asc	"B, ", 'S'+$80		; $94 = B > S
	.asc	"B, P", 'C'+$80		; $95 = B > PC
	.asc	'?'+$80				; $96 ILLEGAL
	.asc	'?'+$80				; $97 ILLEGAL
	.asc	"B, ", 'A'+$80		; $98 = B > A
	.asc	"B, ", 'B'+$80		; $99 = B > B
	.asc	"B, C", 'C'+$80		; $9A = B > CC
	.asc	"B, D", 'P'+$80		; $9B = B > DP
	.asc	'?'+$80				; $9C ILLEGAL
	.asc	'?'+$80				; $9D ILLEGAL
	.asc	'?'+$80				; $9E ILLEGAL
	.asc	'?'+$80				; $9F ILLEGAL

	.asc	"CC, ", 'D'+$80		; $A0 = CC > D
	.asc	"CC, ", 'X'+$80		; $A1 = CC > X
	.asc	"CC, ", 'Y'+$80		; $A2 = CC > Y
	.asc	"CC, ", 'U'+$80		; $A3 = CC > U
	.asc	"CC, ", 'S'+$80		; $A4 = CC > S
	.asc	"CC, P", 'C'+$80	; $A5 = CC > PC
	.asc	'?'+$80				; $A6 ILLEGAL
	.asc	'?'+$80				; $A7 ILLEGAL
	.asc	"CC, ", 'A'+$80		; $A8 = CC > A
	.asc	"CC, ", 'B'+$80		; $A9 = CC > B
	.asc	"CC, C", 'C'+$80	; $AA = CC > CC
	.asc	"CC, D", 'P'+$80	; $AB = CC > DP
	.asc	'?'+$80				; $AC ILLEGAL
	.asc	'?'+$80				; $AD ILLEGAL
	.asc	'?'+$80				; $AE ILLEGAL
	.asc	'?'+$80				; $AF ILLEGAL

	.asc	"DP, ", 'D'+$80		; $B0 = DP > D
	.asc	"DP, ", 'X'+$80		; $B1 = DP > X
	.asc	"DP, ", 'Y'+$80		; $B2 = DP > Y
	.asc	"DP, ", 'U'+$80		; $B3 = DP > U
	.asc	"DP, ", 'S'+$80		; $B4 = DP > S
	.asc	"DP, P", 'C'+$80	; $B5 = DP > PC
	.asc	'?'+$80				; $B6 ILLEGAL
	.asc	'?'+$80				; $B7 ILLEGAL
	.asc	"DP, ", 'A'+$80		; $B8 = DP > A
	.asc	"DP, ", 'B'+$80		; $B9 = DP > B
	.asc	"DP, C", 'C'+$80	; $BA = DP > CC
	.asc	"DP, D", 'P'+$80	; $BB = DP > DP
	.asc	'?'+$80				; $BC ILLEGAL
	.asc	'?'+$80				; $BD ILLEGAL
	.asc	'?'+$80				; $BE ILLEGAL
	.asc	'?'+$80				; $BF ILLEGAL

	.dsb	64, '?'+$80			; $C0-FF filler
