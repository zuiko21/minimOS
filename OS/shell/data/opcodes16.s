; minimOS opcode list for (dis)assembler modules
; (c) 2015-2018 Carlos J. Santisteban
; last modified 20170420-0958

; Opcode list as bit-7 terminated strings
; @ expects single byte, & expects word
; % expects RELATIVE addressing
; * expects LONG RELATIVE addressing (new)
; = expects 24-bit address
; ! will take 8 or 16 bits depending on X flag
; ? will take 8 or 16 bits depending on M flag
; 65C816 version!
; will be used by the assembler module too

#ifndef	OPCODELIST
#define		OPCODELIST	_OPCODELIST
	.asc	"BRK ", '@'+$80	; $00=BRK (actually a 2-byte opcode)
	.asc	"ORA (@, X", ')'+$80	; $01=ORA (zp,X)
	.asc	"COP #", '@'+$80	; $02=COP #		65816
	.asc	"ORA @, ", 'S'+$80	; $03=ORA s		65816
	.asc	"TSB ", '@'+$80	; $04=TSB zp	CMOS
	.asc	"ORA ", '@'+$80	; $05=ORA zp
	.asc	"ASL ", '@'+$80	; $06=ASL zp
	.asc	"ORA [@", ']'+$80	; $07=ORA [zp]	65816
	.asc	"PH", 'P'+$80	; $08=PHP
	.asc	"ORA #", '?'+$80	; $09=ORA #
	.asc	"AS", 'L'+$80	; $0A=ASL
	.asc	"PH", 'D'+$80	; $0B=PHD		65816
	.asc	"TSB ", '&'+$80	; $0C=TSB abs	CMOS
	.asc	"ORA ", '&'+$80	; $0D=ORA abs
	.asc	"ASL ", '&'+$80	; $0E=ASL abs
	.asc	"ORA ", '='+$80	; $0F=ORA long	65816
	.asc	"BPL ", '%'+$80	; $10=BPL rel
	.asc	"ORA (@), ", 'Y'+$80	; $11=ORA (zp),Y
	.asc	"ORA (@", ')'+$80	; $12=ORA (zp)	CMOS
	.asc	"ORA (@, S), ", 'Y'+$80	; $13=ORA (s),Y		65816
	.asc	"TRB ", '@'+$80	; $14=TRB zp	CMOS
	.asc	"ORA @, ", 'X'+$80	; $15=ORA zp,X
	.asc	"ASL @, ", 'X'+$80	; $16=ASL zp,X
	.asc	"ORA [@], ", 'Y'+$80	; $17=ORA [zp],Y	65816
	.asc	"CL", 'C'+$80	; $18=CLC
	.asc	"ORA &, ", 'Y'+$80	; $19=ORA abs,Y
	.asc	"IN", 'C'+$80	; $1A=INC		CMOS
	.asc	"TC", 'S'+$80	; $1B=TCS		65816
	.asc	"TRB ", '&'+$80	; $1C=TRB abs	CMOS
	.asc	"ORA &, ", 'X'+$80	; $1D=ORA abs,X
	.asc	"ASL &, ", 'X'+$80	; $1E=ASL abs,X
	.asc	"ORA =, ", 'X'+$80	; $1F=ORA long,X	65816
	.asc	"JSR ", '&'+$80	; $20=JSR abs
	.asc	"AND (@, X", ')'+$80	; $21=AND (zp,X)
	.asc	"JSL ", '='+$80	; $22=JSL long		65816
	.asc	"AND @, ", 'S'+$80	; $23=AND s		65816
	.asc	"BIT ", '@'+$80	; $24=BIT zp
	.asc	"AND ", '@'+$80	; $25=AND zp
	.asc	"ROL ", '@'+$80	; $26=ROL zp
	.asc	"AND [@", ']'+$80	; $27=AND [zp]	65816
	.asc	"PL", 'P'+$80	; $28=PLP
	.asc	"AND #", '?'+$80	; $29=AND #
	.asc	"RO", 'L'+$80	; $2A=ROL
	.asc	"PL", 'D'+$80	; $2B=PLD		65816
	.asc	"BIT ", '&'+$80	; $2C=BIT abs
	.asc	"AND ", '&'+$80	; $2D=AND abs
	.asc	"ROL ", '&'+$80	; $2E=ROL abs
	.asc	"AND ", '='+$80	; $2F=AND long	65816
	.asc	"BMI ", '%'+$80	; $30=BMI rel
	.asc	"AND (@), ", 'Y'+$80	; $31=AND (zp),Y
	.asc	"AND (@", ')'+$80	; $32=AND (zp)	CMOS
	.asc	"AND (@, S), ", 'Y'+$80	; $33=AND (s),Y		65816
	.asc	"BIT @, ", 'X'+$80	; $34=BIT zp,X	CMOS
	.asc	"AND @, ", 'X'+$80	; $35=AND zp,X
	.asc	"ROL @, ", 'X'+$80	; $36=ROL zp,X
	.asc	"AND [@], ", 'Y'+$80	; $37=AND [zp],Y	65816
	.asc	"SE", 'C'+$80	; $38=SEC
	.asc	"AND &, ", 'Y'+$80	; $39=AND abs,Y
	.asc	"DE", 'C'+$80	; $3A=DEC		CMOS
	.asc	"TS", 'C'+$80	; $3B=TSC		65816
	.asc	"BIT &, ", 'X'+$80	; $3C=BIT abs,X	CMOS
	.asc	"AND &, ", 'X'+$80	; $3D=AND abs,X
	.asc	"ROL &, ", 'X'+$80	; $3E=ROL abs,X
	.asc	"AND =, ", 'X'+$80	; $3F=AND long,X	65816
	.asc	"RT", 'I'+$80	; $40=RTI
	.asc	"EOR (@, X", ')'+$80	; $41=EOR (zp,X)
	.asc	"WD", 'M'+$80	; $42=WDM		65816
	.asc	"EOR @, ", 'S'+$80	; $43=EOR s		65816
	.asc	"MVP @, ", '@'+$80	; $44=MVP		65816
	.asc	"EOR ", '@'+$80	; $45=EOR zp
	.asc	"LSR ", '@'+$80	; $46=LSR zp
	.asc	"EOR [@", ']'+$80	; $47=EOR [zp]	65816
	.asc	"PH", 'A'+$80	; $48=PHA
	.asc	"EOR #", '?'+$80	; $49=EOR #
	.asc	"LS", 'R'+$80	; $4A=LSR
	.asc	"PH", 'K'+$80	; $4B=PHK		65816
	.asc	"JMP ", '&'+$80	; $4C=JMP abs
	.asc	"EOR ", '&'+$80	; $4D=EOR abs
	.asc	"LSR ", '&'+$80	; $4E=LSR abs
	.asc	"EOR ", '='+$80	; $4F=EOR long	65816
	.asc	"BVC ", '%'+$80	; $50=BVC rel
	.asc	"EOR (@), ", 'Y'+$80	; $51=EOR (zp),Y
	.asc	"EOR (@", ')'+$80	; $52=EOR (zp)	CMOS
	.asc	"EOR (@, S), ", 'Y'+$80	; $53=EOR (s),Y		65816
	.asc	"MVN @, ", '@'+$80	; $54=MVN		65816
	.asc	"EOR @, ", 'X'+$80	; $55=EOR zp,X
	.asc	"LSR @, ", 'X'+$80	; $56=LSR zp,X
	.asc	"EOR [@], ", 'Y'+$80	; $57=EOR [zp],Y	65816
	.asc	"CL", 'I'+$80	; $58=CLI
	.asc	"EOR &, ", 'Y'+$80	; $59=EOR abs,Y
	.asc	"PH", 'Y'+$80	; $5A=PHY		CMOS
	.asc	"TC", 'D'+$80	; $5B=TCD		65816
	.asc	"JML ", '='+$80	; $5C=JML long		65816
	.asc	"EOR &, ", 'X'+$80	; $5D=EOR abs,X
	.asc	"LSR &, ", 'X'+$80	; $5E=LSR abs,X
	.asc	"EOR =, ", 'X'+$80	; $5F=EOR long,X	65816
	.asc	"RT", 'S'+$80	; $60=RTS
	.asc	"ADC (@, X", ')'+$80	; $61=ADC (zp,X)
	.asc	"PER ", '*'+$80	; $62=PER rlong	65816
	.asc	"ADC @, ", 'S'+$80	; $63=ADC s		65816
	.asc	"STZ ", '@'+$80	; $64=STZ zp	CMOS
	.asc	"ADC ", '@'+$80	; $65=ADC zp
	.asc	"ROR ", '@'+$80	; $66=ROR zp
	.asc	"ADC [@", ']'+$80	; $67=ADC [zp]	65816
	.asc	"PL", 'A'+$80	; $68=PLA
	.asc	"ADC #", '?'+$80	; $69=ADC #
	.asc	"RO", 'R'+$80	; $6A=ROR
	.asc	"RT", 'L'+$80	; $6B=RTL		65816
	.asc	"JMP (&", ')'+$80	; $6C=JMP (abs)
	.asc	"ADC ", '&'+$80	; $6D=ADC abs
	.asc	"ROR ", '&'+$80	; $6E=ROR abs
	.asc	"ADC ", '='+$80	; $6F=ADC long	65816
	.asc	"BVS ", '%'+$80	; $70=BVS rel
	.asc	"ADC (@), ", 'Y'+$80	; $71=ADC (zp),Y
	.asc	"ADC (@", ')'+$80	; $72=ADC (zp)	CMOS
	.asc	"ADC (@, S), ", 'Y'+$80	; $73=ADC (s),Y		65816
	.asc	"STZ @, ", 'X'+$80	; $74=STZ zp,X	CMOS
	.asc	"ADC @, ", 'X'+$80	; $75=ADC zp,X
	.asc	"ROR @, ", 'X'+$80	; $76=ROR zp,X
	.asc	"ADC [@], ", 'Y'+$80	; $77=ADC [zp],Y	65816
	.asc	"SE", 'I'+$80	; $78=SEI
	.asc	"ADC &, ", 'Y'+$80	; $79=ADC abs, Y
	.asc	"PL", 'Y'+$80	; $7A=PLY		CMOS
	.asc	"TD", 'C'+$80	; $7B=TDC		65816
	.asc	"JMP (&, X", ')'+$80	; $7C=JMP (abs,X)	CMOS
	.asc	"ADC &, ", 'X'+$80	; $7D=ADC abs, X
	.asc	"ROR &, ", 'X'+$80	; $7E=ROR abs, X
	.asc	"ADC =, ", 'X'+$80	; $7F=ADC long,X	65816
	.asc	"BRA ", '%'+$80	; $80=BRA rel	CMOS
	.asc	"STA (@, X", ')'+$80	; $81=STA (zp,X)
	.asc	"BRL ", '*'+$80	; $82=BRL rlong		65816
	.asc	"STA @, ", 'S'+$80	; $83=STA s		65816
	.asc	"STY ", '@'+$80	; $84=STY zp
	.asc	"STA ", '@'+$80	; $85=STA zp
	.asc	"STX ", '@'+$80	; $86=STX zp	CMOS
	.asc	"STA [@", ']'+$80	; $87=ADC [zp]	65816
	.asc	"DE", 'Y'+$80	; $88=DEY
	.asc	"BIT #", '?'+$80	; $89=BIT #
	.asc	"TX", 'A'+$80	; $8A=TXA
	.asc	"PH", 'B'+$80	; $8B=PHB		65816
	.asc	"STY ", '&'+$80	; $8C=STY abs
	.asc	"STA ", '&'+$80	; $8D=STA abs
	.asc	"STX ", '&'+$80	; $8E=STX abs
	.asc	"STA ", '='+$80	; $8F=STA long	65816
	.asc	"BCC ", '%'+$80	; $90=BCC rel
	.asc	"STA (@), ", 'Y'+$80	; $91=STA (zp),Y
	.asc	"STA (@", ')'+$80	; $92=STA (zp)	CMOS
	.asc	"STA (@, S), ", 'Y'+$80	; $93=STA (s),Y		65816
	.asc	"STY @, ", 'X'+$80	; $94=STY zp,X
	.asc	"STA @, ", 'X'+$80	; $95=STA zp,X
	.asc	"STX @, ", 'Y'+$80	; $96=STX zp,Y
	.asc	"STA [@], ", 'Y'+$80	; $97=STA [zp],Y	65816
	.asc	"TY", 'A'+$80	; $98=TYA
	.asc	"STA &, ", 'Y'+$80	; $99=STA abs, Y
	.asc	"TX", 'S'+$80	; $9A=TXS
	.asc	"TX", 'Y'+$80	; $9B=TXY		65816
	.asc	"STZ ", '&'+$80	; $9C=STZ abs	CMOS
	.asc	"STA &, ", 'X'+$80	; $9D=STA abs,X
	.asc	"STZ &, ", 'X'+$80	; $9E=STZ abs,X	CMOS
	.asc	"STA =, ", 'X'+$80	; $9F=STA long,X	65816
	.asc	"LDY #", '!'+$80	; $A0=LDY #
	.asc	"LDA (@, X", ')'+$80	; $A1=LDA (zp,X)
	.asc	"LDX #", '!'+$80	; $A2=LDX #
	.asc	"LDA @, ", 'S'+$80	; $A3=LDA s		65816
	.asc	"LDY ", '@'+$80	; $A4=LDY zp
	.asc	"LDA ", '@'+$80	; $A5=LDA zp
	.asc	"LDX ", '@'+$80	; $A6=LDX zp
	.asc	"LDA [@", ']'+$80	; $A7=LDA [zp]	65816
	.asc	"TA", 'Y'+$80	; $A8=TAY
	.asc	"LDA #", '?'+$80	; $A9=LDA #
	.asc	"TA", 'X'+$80	; $AA=TAX
	.asc	"PL", 'B'+$80	; $AB=PLB		65816
	.asc	"LDY ", '&'+$80	; $AC=LDY abs
	.asc	"LDA ", '&'+$80	; $AD=LDA abs
	.asc	"LDX ", '&'+$80	; $AE=LDX abs
	.asc	"LDA ", '='+$80	; $AF=LDA long	65816
	.asc	"BCS ", '%'+$80	; $B0=BCS rel
	.asc	"LDA (@), ", 'Y'+$80	; $B1=LDA (zp),Y
	.asc	"LDA (@", ')'+$80	; $B2=LDA (zp)	CMOS
	.asc	"LDA (@, S), ", 'Y'+$80	; $B3=LDA (s),Y		65816
	.asc	"LDY @, ", 'X'+$80	; $B4=LDY zp,X
	.asc	"LDA @, ", 'X'+$80	; $B5=LDA zp,X
	.asc	"LDX @,", 'Y'+$80	; $B6=LDX zp,Y
	.asc	"LDA [@], ", 'Y'+$80	; $B7=LDA [zp],Y	65816
	.asc	"CL", 'V'+$80	; $B8=CLV
	.asc	"LDA &, ", 'Y'+$80	; $B9=LDA abs, Y
	.asc	"TS", 'X'+$80	; $BA=TSX
	.asc	"TY", 'X'+$80	; $BB=TYX		65816
	.asc	"LDY &, ", 'X'+$80	; $BC=LDY abs,X
	.asc	"LDA &, ", 'X'+$80	; $BD=LDA abs,X
	.asc	"LDX &, ", 'Y'+$80	; $BE=LDX abs,Y
	.asc	"LDA =, ", 'X'+$80	; $BF=LDA long,X	65816
	.asc	"CPY #", '!'+$80	; $C0=CPY #
	.asc	"CMP (@, X", ')'+$80	; $C1=CMP (zp,X)
	.asc	"REP #", '@'+$80	; $C2=REP #		65816
	.asc	"CMP @, ", 'S'+$80	; $C3=CMP s		65816
	.asc	"CPY ", '@'+$80	; $C4=CPY zp
	.asc	"CMP ", '@'+$80	; $C5=CMP zp
	.asc	"DEC ", '@'+$80	; $C6=DEC zp
	.asc	"CMP [@", ']'+$80	; $C7=CMP [zp]	65816
	.asc	"IN", 'Y'+$80	; $C8=INY
	.asc	"CMP #", '?'+$80	; $C9=CMP #
	.asc	"DE", 'X'+$80	; $CA=DEX
	.asc	"WA", 'I'+$80	; $CB=WAI	CMOS WDC
	.asc	"CPY ", '&'+$80	; $CC=CPY abs
	.asc	"CMP ", '&'+$80	; $CD=CMP abs
	.asc	"DEC ", '&'+$80	; $CE=DEC abs
	.asc	"CMP ", '='+$80	; $CF=CMP long	65816
	.asc	"BNE ", '%'+$80	; $D0=BNE rel
	.asc	"CMP (@), ", 'Y'+$80	; $D1=CMP (zp),Y
	.asc	"CMP (@", ')'+$80	; $D2=CMP (zp)	CMOS
	.asc	"CMP (@, S), ", 'Y'+$80	; $D3=CMP (s),Y		65816
	.asc	"PEI ", '@'+$80	; $D4=PEI zp	65816
	.asc	"CMP @, ", 'X'+$80	; $D5=CMP zp,X
	.asc	"DEC @, ", 'X'+$80	; $D6=DEC zp,X
	.asc	"CMP [@], ", 'Y'+$80	; $D7=CMP [zp],Y	65816
	.asc	"CL", 'D'+$80	; $D8=CLD
	.asc	"CMP &, ", 'Y'+$80	; $D9=CMP abs, Y
	.asc	"PH", 'X'+$80	; $DA=PHX		CMOS
	.asc	"ST", 'P'+$80	; $DB=STP	CMOS WDC
	.asc	"JML [&", ']'+$80	; $DC=JML [abs]		65816
	.asc	"CMP &, ", 'X'+$80	; $DD=CMP abs,X
	.asc	"DEC &, ", 'X'+$80	; $DE=DEC abs,X
	.asc	"CMP =, ", 'X'+$80	; $DF=CMP long,X	65816
	.asc	"CPX #", '!'+$80	; $E0=CPX #
	.asc	"SBC (@, X", ')'+$80	; $E1=SBC (zp,X)
	.asc	"SEP #", '@'+$80	; $E2=SEP #		65816
	.asc	"SBC @, ", 'S'+$80	; $E3=SBC s		65816
	.asc	"CPX ", '@'+$80	; $E4=CPX zp
	.asc	"SBC ", '@'+$80	; $E5=SBC zp
	.asc	"INC ", '@'+$80	; $E6=INC zp
	.asc	"SBC [@", ']'+$80	; $E7=SBC [zp]	65816
	.asc	"IN", 'X'+$80	; $E8=INX
	.asc	"SBC #", '?'+$80	; $E9=SBC #
	.asc	"NO", 'P'+$80	; $EA=NOP
	.asc	"XB", 'A'+$80	; $EB=XBA		65816
	.asc	"CPX ", '&'+$80	; $EC=CPX abs
	.asc	"SBC ", '&'+$80	; $ED=SBC abs
	.asc	"INC ", '&'+$80	; $EE=INC abs
	.asc	"SBC ", '='+$80	; $EF=SBC long	65816
	.asc	"BEQ ", '%'+$80	; $F0=BEQ rel
	.asc	"SBC (@), ", 'Y'+$80	; $F1=SBC (zp),Y
	.asc	"SBC (@", ')'+$80	; $F2=SBC (zp)	CMOS
	.asc	"SBC (@, S), ", 'Y'+$80	; $F3=SBC (s),Y		65816
	.asc	"PEA #", '&'+$80	; $F4=PEA #		65816
	.asc	"SBC @, ", 'X'+$80	; $F5=SBC zp,X
	.asc	"INC @, ", 'X'+$80	; $F6=INC zp,X
	.asc	"SBC [@], ", 'Y'+$80	; $37=SBC [zp],Y	65816
	.asc	"SE", 'D'+$80	; $F8=SED
	.asc	"SBC &, ", 'Y'+$80	; $F9=SBC abs,Y
	.asc	"PL", 'X'+$80	; $FA=PLX		CMOS
	.asc	"XC", 'E'+$80	; $FB=XCE		65816
	.asc	"JSR (&, X", ')'+$80	; $FC=JSR (abs,X)	65816
	.asc	"SBC &, ", 'X'+$80	; $FD=SBC abs,X
	.asc	"INC &, ", 'X'+$80	; $FE=INC abs,X
	.asc	"SBC =, ", 'X'+$80	; $FF=SBC long,X	65816
#endif
