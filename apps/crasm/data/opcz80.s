; minimOS opcode list for (dis)assembler modules
; (c) 2015-2020 Carlos J. Santisteban
; last modified 20200122-1233

; ***** for z80asm Z80 cross assembler *****
; Z80 set, with 8085 mnemonics on comment
; Opcode list as bit-7 terminated strings
; @ expects single byte, & expects word
; % expects RELATIVE addressing
; *** need some special characters for prefixes *** TBD

	.asc	"NO", 'P'+$80		; $00=NOP
	.asc	"LD BC, ", '&'+$80	; $01=LXI B
	.asc	"LD (BC), ",'A'+$80	; $02=STAX B
	.asc	"INC B", 'C'+$80	; $03=INX B
	.asc	"INC ", 'B'+$80		; $04=INR B
	.asc	"DEC ", 'B'+$80		; $05=DCR B
	.asc	"LD B, ", '@'+$80	; $06=MVI B
	.asc	"RLC", 'A'+$80		; $07=RLC
	.asc	"EX AF, AF",$27+$80	; $08=EX AF, AF'	Z80 ONLY!
	.asc	"ADD HL, B",'C'+$80	; $09=DAD B
	.asc	"LD A, (BC",')'+$80	; $0A=LDAX B
	.asc	"DEC B", 'C'+$80	; $0B=DCX B
	.asc	"INC ", 'C'+$80		; $0C=INR C
	.asc	"DEC ", 'C'+$80		; $0D=DCR C
	.asc	"LD C, ", '@'+$80	; $0E=MVI C
	.asc	"RRC", 'A'+$80		; $0F=RRC

	.asc	"DJNZ, ", '@'+$80	; $10=DJNZ		Z80 ONLY!
	.asc	"LD DE, ", '&'+$80	; $11=LXI D
	.asc	"LD (DE), ",'A'+$80	; $12=STAX D
	.asc	"INC D", 'E'+$80	; $13=INX D
	.asc	"INC ", 'D'+$80		; $14=INR D
	.asc	"DEC ", 'D'+$80		; $15=DCR D
	.asc	"LD D, ", '@'+$80	; $16=MVI D
	.asc	"RL", 'A'+$80		; $17=RAL
	.asc	"JR ", '%'+$80		; $18=JR		Z80 ONLY!
	.asc	"ADD HL, D",'E'+$80	; $19=DAD D
	.asc	"LD A, (DE",')'+$80	; $1A=LDAX D
	.asc	"DEC D", 'E'+$80	; $1B=DCX D
	.asc	"INC ", 'E'+$80		; $1C=INR E
	.asc	"DEC ", 'E'+$80		; $1D=DCR E
	.asc	"LD E, ", '@'+$80	; $1E=MVI E
	.asc	"RR", 'A'+$80		; $1F=RAR

	.asc	"JR NZ, ", '%'+$80	; $20=JR NZ		Z80 ONLY!
	.asc	"LD HL, ", '&'+$80	; $21=LXI H
	.asc	"LD (&), H",'L'+$80	; $22=SHLD
	.asc	"INC H", 'L'+$80	; $23=INX H
	.asc	"INC ", 'H'+$80		; $24=INR H
	.asc	"DEC ", 'H'+$80		; $25=DCR H
	.asc	"LD H, ", '@'+$80	; $26=MVI H
	.asc	"DA", 'A'+$80		; $27=DAA
	.asc	"JR Z, ", '@'+$80	; $28=JR Z		Z80 ONLY!
	.asc	"ADD HL, H",'L'+$80	; $29=DAD H
	.asc	"LD HL, (&",')'+$80	; $2A=LDHL
	.asc	"DEC H", 'L'+$80	; $2B=DCX H
	.asc	"INC ", 'L'+$80		; $2C=INR L
	.asc	"DEC ", 'L'+$80		; $2D=DCR L
	.asc	"LD L, ", '@'+$80	; $2E=MVI L
	.asc	"CP", 'L'+$80		; $2F=CMA

	.asc	"JR NC, ", '%'+$80	; $30=JR NC		UNLIKE 8085
	.asc	"LD SP, ", '&'+$80	; $31=LXI SP
	.asc	"LD (&), ", 'A'+$80	; $32=STA
	.asc	"INC S", 'P'+$80	; $33=INX SP
	.asc	"INC (HL", ')'+$80	; $34=INR M
	.asc	"DEC (HL", ')'+$80	; $35=DCR M
	.asc	"LD (HL), ",'@'+$80	; $36=MVI M
	.asc	"SC", 'F'+$80		; $37=STC
	.asc	"JR C, ", '%'+$80	; $38=JR C		Z80 ONLY!
	.asc	"ADD HL, S",'P'+$80	; $39=DAD SP
	.asc	"LD A, (&", ')'+$80	; $3A=LDA
	.asc	"DEC S", 'P'+$80	; $3B=DCX SP
	.asc	"INC ", 'A'+$80		; $3C=INR A
	.asc	"DEC ", 'A'+$80		; $3D=DCR A
	.asc	"LD A, ", '@'+$80	; $3E=MVI A
	.asc	"CC", 'F'+$80		; $3F=CMC

	.asc	"LD B, ", 'B'+$80	; $40=MOV B,B
	.asc	"LD B, ", 'C'+$80	; $41=MOV B,C
	.asc	"LD B, ", 'D'+$80	; $42=MOV B,D
	.asc	"LD B, ", 'E'+$80	; $43=MOV B,E
	.asc	"LD B, ", 'H'+$80	; $44=MOV B,H
	.asc	"LD B, ", 'L'+$80	; $45=MOV B,L
	.asc	"LD B, (HL",')'+$80	; $46=MOV B,M
	.asc	"LD B, ", 'A'+$80	; $47=MOV B,A
	.asc	"LD C, ", 'B'+$80	; $48=MOV C,B
	.asc	"LD C, ", 'C'+$80	; $49=MOV C,C
	.asc	"LD C, ", 'D'+$80	; $4A=MOV C,D
	.asc	"LD C, ", 'E'+$80	; $4B=MOV C,E
	.asc	"LD C, ", 'H'+$80	; $4C=MOV C,H
	.asc	"LD C, ", 'L'+$80	; $4D=MOV C,L
	.asc	"LD C, (HL",')'+$80	; $4E=MOV C,M
	.asc	"LD C, ", 'A'+$80	; $4F=MOV C,A


	.asc	"LD D, ", 'B'+$80	; $50=MOV D,B
	.asc	"LD D, ", 'C'+$80	; $51=MOV D,C
	.asc	"LD D, ", 'D'+$80	; $52=MOV D,D
	.asc	"LD D, ", 'E'+$80	; $53=MOV D,E
	.asc	"LD D, ", 'H'+$80	; $54=MOV D,H
	.asc	"LD D, ", 'L'+$80	; $55=MOV D,L
	.asc	"LD D, (HL",')'+$80	; $56=MOV D,M
	.asc	"LD D, ", 'A'+$80	; $57=MOV D,A
	.asc	"LD E, ", 'B'+$80	; $58=MOV E,B
	.asc	"LD E, ", 'C'+$80	; $59=MOV E,C
	.asc	"LD E, ", 'D'+$80	; $5A=MOV E,D
	.asc	"LD E, ", 'E'+$80	; $5B=MOV E,E
	.asc	"LD E, ", 'H'+$80	; $5C=MOV E,H
	.asc	"LD E, ", 'L'+$80	; $5D=MOV E,L
	.asc	"LD E, (HL",')'+$80	; $5E=MOV E,M
	.asc	"LD E, ", 'A'+$80	; $5F=MOV E,A

	.asc	"LD H, ", 'B'+$80	; $60=MOV H,B
	.asc	"LD H, ", 'C'+$80	; $61=MOV H,C
	.asc	"LD H, ", 'D'+$80	; $62=MOV H,D
	.asc	"LD H, ", 'E'+$80	; $63=MOV H,E
	.asc	"LD H, ", 'H'+$80	; $64=MOV H,H
	.asc	"LD H, ", 'L'+$80	; $65=MOV H,L
	.asc	"LD H, (HL",')'+$80	; $66=MOV H,M
	.asc	"LD H, ", 'A'+$80	; $67=MOV H,A
	.asc	"LD L, ", 'B'+$80	; $68=MOV L,B
	.asc	"LD L, ", 'C'+$80	; $69=MOV L,C
	.asc	"LD L, ", 'D'+$80	; $6A=MOV L,D
	.asc	"LD L, ", 'E'+$80	; $6B=MOV L,E
	.asc	"LD L, ", 'H'+$80	; $6C=MOV L,H
	.asc	"LD L, ", 'L'+$80	; $6D=MOV L,L
	.asc	"LD L, (HL",')'+$80	; $6E=MOV L,M
	.asc	"LD L, ", 'A'+$80	; $6F=MOV L,A

	.asc	"LD (HL), ",'B'+$80	; $70=MOV M,B
	.asc	"LD (HL), ",'C'+$80	; $71=MOV M,C
	.asc	"LD (HL), ",'D'+$80	; $72=MOV M,D
	.asc	"LD (HL), ",'E'+$80	; $73=MOV M,E
	.asc	"LD (HL), ",'H'+$80	; $74=MOV M,H
	.asc	"LD (HL), ",'L'+$80	; $75=MOV M,L
	.asc	"HAL", 'T'+$80		; $76=HLT
	.asc	"LD (HL), ",'A'+$80	; $77=MOV M,A
	.asc	"LD A, ", 'B'+$80	; $78=MOV A,B
	.asc	"LD A, ", 'C'+$80	; $79=MOV A,C
	.asc	"LD A, ", 'D'+$80	; $7A=MOV A,D
	.asc	"LD A, ", 'E'+$80	; $7B=MOV A,E
	.asc	"LD A, ", 'H'+$80	; $7C=MOV A,H
	.asc	"LD A, ", 'L'+$80	; $7D=MOV A,L
	.asc	"LD A, (HL",')'+$80	; $7E=MOV A,M
	.asc	"LD A, ", 'A'+$80	; $7F=MOV A,A

	.asc	"ADD A, ", 'B'+$80	; $80=ADD B
	.asc	"ADD A, ", 'C'+$80	; $81=ADD C
	.asc	"ADD A, ", 'D'+$80	; $82=ADD D
	.asc	"ADD A, ", 'E'+$80	; $83=ADD E
	.asc	"ADD A, ", 'H'+$80	; $84=ADD H
	.asc	"ADD A, ", 'L'+$80	; $85=ADD L
	.asc	"ADD A, (HL",')'+$80	; $86=ADD M
	.asc	"ADD A, ", 'A'+$80	; $87=ADD A
	.asc	"ADC A, ", 'B'+$80	; $88=ADC B
	.asc	"ADC A, ", 'C'+$80	; $89=ADC C
	.asc	"ADC A, ", 'D'+$80	; $8A=ADC D
	.asc	"ADC A, ", 'E'+$80	; $8B=ADC E
	.asc	"ADC A, ", 'H'+$80	; $8C=ADC H
	.asc	"ADC A, ", 'L'+$80	; $8D=ADC L
	.asc	"ADC A, (HL",')'+$80	; $8E=ADC M
	.asc	"ADC A, ", 'A'+$80	; $8F=ADC A

	.asc	"SUB ", 'B'+$80		; $90=SUB B
	.asc	"SUB ", 'C'+$80		; $91=SUB C
	.asc	"SUB ", 'D'+$80		; $92=SUB D
	.asc	"SUB ", 'E'+$80		; $93=SUB E
	.asc	"SUB ", 'H'+$80		; $94=SUB H
	.asc	"SUB ", 'L'+$80		; $95=SUB L
	.asc	"SUB (HL", ')'+$80	; $96=SUB M
	.asc	"SUB ", 'A'+$80		; $97=SUB A
	.asc	"SBC A, ", 'B'+$80	; $98=SBB B
	.asc	"SBC A, ", 'C'+$80	; $99=SBB C
	.asc	"SBC A, ", 'D'+$80	; $9A=SBB D
	.asc	"SBC A, ", 'E'+$80	; $9B=SBB E
	.asc	"SBC A, ", 'H'+$80	; $9C=SBB H
	.asc	"SBC A, ", 'L'+$80	; $9D=SBB L
	.asc	"SBC A, (HL",')'+$80	; $9E=SBB M
	.asc	"SBC A, ", 'A'+$80	; $9F=SBB A

	.asc	"AND ", 'B'+$80		; $A0=ANA B
	.asc	"AND ", 'C'+$80		; $A1=ANA C
	.asc	"AND ", 'D'+$80		; $A2=ANA D
	.asc	"AND ", 'E'+$80		; $A3=ANA E
	.asc	"AND ", 'H'+$80		; $A4=ANA H
	.asc	"AND ", 'L'+$80		; $A5=ANA L
	.asc	"AND (HL", ')'+$80	; $A6=ANA M
	.asc	"AND ", 'A'+$80		; $A7=ANA A
	.asc	"XOR ", 'B'+$80		; $A8=XRA B
	.asc	"XOR ", 'C'+$80		; $A9=XRA C
	.asc	"XOR ", 'D'+$80		; $AA=XRA D
	.asc	"XOR ", 'E'+$80		; $AB=XRA E
	.asc	"XOR ", 'H'+$80		; $AC=XRA H
	.asc	"XOR ", 'L'+$80		; $AD=XRA L
	.asc	"XOR (HL", ')'+$80	; $AE=XRA M
	.asc	"XOR ", 'A'+$80		; $AF=XRA A

	.asc	"OR ", 'B'+$80		; $B0=ORA B
	.asc	"OR ", 'C'+$80		; $B1=ORA C
	.asc	"OR ", 'D'+$80		; $B2=ORA D
	.asc	"OR ", 'E'+$80		; $B3=ORA E
	.asc	"OR ", 'H'+$80		; $B4=ORA H
	.asc	"OR ", 'L'+$80		; $B5=ORA L
	.asc	"OR (HL", ')'+$80	; $B6=ORA M
	.asc	"OR ", 'A'+$80		; $B7=ORA A
	.asc	"CP ", 'B'+$80		; $B8=CMP B
	.asc	"CP ", 'C'+$80		; $B9=CMP C
	.asc	"CP ", 'D'+$80		; $BA=CMP D
	.asc	"CP ", 'E'+$80		; $BB=CMP E
	.asc	"CP ", 'H'+$80		; $BC=CMP H
	.asc	"CP ", 'L'+$80		; $BD=CMP L
	.asc	"CP (HL", ')'+$80	; $BE=CMP M
	.asc	"CP ", 'A'+$80		; $BF=CMP A

	.asc	"RET N", 'Z'+$80	; $C0=RNZ
	.asc	"POP B", 'C'+$80	; $C1=POP B
	.asc	"JP NZ, ", '&'+$80	; $C2=JNZ
	.asc	"JP ", '&'+$80		; $C3=JMP
	.asc	"CALL NZ, ",'&'+$80	; $C4=CNZ
	.asc	"PUSH B", 'C'+$80	; $C5=PUSH B
	.asc	"ADD A, ", '@'+$80	; $C6=ADI
	.asc	"RST 00", 'H'+$80	; $C7=RST 0
	.asc	"RET ", 'Z'+$80		; $C8=RZ
	.asc	"RE", 'T'+$80		; $C9=RET
	.asc	"JP Z, ", '&'+$80	; $CA=JZ
	.asc	"?", ' '+$80		; $CB=**BITS**		** Z80 PREFIX **
	.asc	"CALL Z, ", '&'+$80	; $CC=CZ
	.asc	"CALL ", '&'+$80	; $CD=CALL
	.asc	"ADC A, ", '@'+$80	; $CE=ACI
	.asc	"RST 08", 'H'+$80	; $CF=RST 1

	.asc	"RET N", 'C'+$80	; $D0=RNC
	.asc	"POP D", 'E'+$80	; $D1=POP D
	.asc	"JP NC, ", '&'+$80	; $D2=JNC
	.asc	"OUT (@), ",'A'+$80	; $D3=OUT
	.asc	"CALL NC, ",'&'+$80	; $D4=CNC
	.asc	"PUSH D", 'E'+$80	; $D5=PUSH D
	.asc	"SUB ", '@'+$80		; $D6=SUI
	.asc	"RST 10", 'H'+$80	; $D7=RST 2
	.asc	"RET ", 'C'+$80		; $D8=RC
	.asc	"EX", 'X'+$80		; $D9=EXX		Z80 ONLY!
	.asc	"JP C, ", '&'+$80	; $DA=JC
	.asc	"IN A, (@", ')'+$80	; $DB=IN
	.asc	"CALL C, ", '&'+$80	; $DC=CC
	.asc	"?", ' '+$80		; $DD=**IX+D**		** Z80 PREFIX **
	.asc	"SBA A, ", '@'+$80	; $DE=SBI
	.asc	"RST 18", 'H'+$80	; $DF=RST 3

	.asc	"RET P", 'O'+$80	; $E0=RPO
	.asc	"POP H", 'L'+$80	; $E1=POP H
	.asc	"JP PO, ", '&'+$80	; $E2=JPO
	.asc	"EX (SP), H",'L'+$80	; $E3=XTHL
	.asc	"CALL PO, ",'&'+$80	; $E4=CPO
	.asc	"PUSH H", 'L'+$80	; $E5=PUSH H
	.asc	"AND ", '@'+$80		; $E6=ANI
	.asc	"RST 20", 'H'+$80	; $E7=RST 4
	.asc	"RET P", 'E'+$80	; $E8=RPE
	.asc	"JP (HL", ')'+$80	; $E9=PCHL
	.asc	"JP PE, ", '&'+$80	; $EA=JPE
	.asc	"EX DE, H", 'L'+$80	; $EB=XCHG
	.asc	"CALL PE, ",'&'+$80	; $EC=CPE
	.asc	"?", ' '+$80		; $ED=**EXTD**		** Z80 PREFIX **
	.asc	"XOR ", '@'+$80		; $EE=XRI
	.asc	"RST 28", 'H'+$80	; $EF=RST 5

	.asc	"RET ", 'P'+$80		; $F0=RP
	.asc	"POP A", 'F'+$80	; $F1=POP PSW
	.asc	"JP P, ", '&'+$80	; $F2=JP
	.asc	"D", 'I'+$80		; $F3=DI
	.asc	"CALL P, ", '&'+$80	; $F4=CP
	.asc	"PUSH A", 'F'+$80	; $F5=PUSH PSW
	.asc	"OR ", '@'+$80		; $F6=ORI
	.asc	"RST 30", 'H'+$80	; $F7=RST 6
	.asc	"RET ", 'M'+$80		; $F8=RM
	.asc	"LD SP, H", 'L'+$80	; $F9=SPHL
	.asc	"JP M, ", '&'+$80	; $FA=JM
	.asc	"E", 'I'+$80		; $FB=EI
	.asc	"CALL M, ", '&'+$80	; $FC=CM
	.asc	"?", ' '+$80		; $FD=**IY+D**		** Z80 PREFIX **
	.asc	"CP ", '@'+$80		; $FE=CPI
	.asc	"RST 38", 'H'+$80	; $FF=RST 7

; *************************************
; *** BIT instructions ($CB prefix) *** TO DO
; *************************************
z80_cb:
	.asc	"RLC ", 'B'+$80		; $CB $00=RLC B
	.asc	"RLC ", '&'+$80	; $CB $01=RLC C
	.asc	"LD (BC), ",'A'+$80	; $CB $02=RLC D
	.asc	"INC B", 'C'+$80	; $CB $03=RLC E
	.asc	"INC ", 'B'+$80		; $CB $04=RLC H
	.asc	"DEC ", 'B'+$80		; $CB $05=RLC L
	.asc	"LD B, ", '@'+$80	; $CB $06=RLC (HL)
	.asc	"RLC", 'A'+$80		; $CB $07=RLC A
	.asc	"EX AF, AF",$27+$80	; $CB $08=RRC B
	.asc	"ADD HL, B",'C'+$80	; $CB $09=RRC C
	.asc	"LD A, (BC",')'+$80	; $CB $0A=RRC D
	.asc	"DEC B", 'C'+$80	; $CB $0B=RRC E
	.asc	"INC ", 'C'+$80		; $CB $0C=RRC H
	.asc	"DEC ", 'C'+$80		; $CB $0D=RRC L
	.asc	"LD C, ", '@'+$80	; $CB $0E=RRC (HL)
	.asc	"RRC", 'A'+$80		; $CB $0F=RRC A

	.asc	"DJNZ, ", '@'+$80	; $CB $10=DJNZ		Z80 ONLY!
	.asc	"LD DE, ", '&'+$80	; $CB $11=LXI D
	.asc	"LD (DE), ",'A'+$80	; $CB $12=STAX D
	.asc	"INC D", 'E'+$80	; $CB $13=INX D
	.asc	"INC ", 'D'+$80		; $CB $14=INR D
	.asc	"DEC ", 'D'+$80		; $CB $15=DCR D
	.asc	"LD D, ", '@'+$80	; $CB $16=MVI D
	.asc	"RL", 'A'+$80		; $CB $17=RAL
	.asc	"JR ", '%'+$80		; $CB $18=JR		Z80 ONLY!
	.asc	"ADD HL, D",'E'+$80	; $CB $19=DAD D
	.asc	"LD A, (DE",')'+$80	; $CB $1A=LDAX D
	.asc	"DEC D", 'E'+$80	; $CB $1B=DCX D
	.asc	"INC ", 'E'+$80		; $CB $1C=INR E
	.asc	"DEC ", 'E'+$80		; $CB $1D=DCR E
	.asc	"LD E, ", '@'+$80	; $CB $1E=MVI E
	.asc	"RR", 'A'+$80		; $CB $1F=RAR

	.asc	"JR NZ, ", '%'+$80	; $CB $20=JR NZ		Z80 ONLY!
	.asc	"LD HL, ", '&'+$80	; $CB $21=LXI H
	.asc	"LD (&), H",'L'+$80	; $CB $22=SHLD
	.asc	"INC H", 'L'+$80	; $CB $23=INX H
	.asc	"INC ", 'H'+$80		; $CB $24=INR H
	.asc	"DEC ", 'H'+$80		; $CB $25=DCR H
	.asc	"LD H, ", '@'+$80	; $CB $26=MVI H
	.asc	"DA", 'A'+$80		; $CB $27=DAA
	.asc	"JR Z, ", '@'+$80	; $CB $28=JR Z		Z80 ONLY!
	.asc	"ADD HL, H",'L'+$80	; $CB $29=DAD H
	.asc	"LD HL, (&",')'+$80	; $CB $2A=LDHL
	.asc	"DEC H", 'L'+$80	; $CB $2B=DCX H
	.asc	"INC ", 'L'+$80		; $CB $2C=INR L
	.asc	"DEC ", 'L'+$80		; $CB $2D=DCR L
	.asc	"LD L, ", '@'+$80	; $CB $2E=MVI L
	.asc	"CP", 'L'+$80		; $CB $2F=CMA

	.asc	"JR NC, ", '%'+$80	; $CB $30=JR NC		UNLIKE 8085
	.asc	"LD SP, ", '&'+$80	; $CB $31=LXI SP
	.asc	"LD (&), ", 'A'+$80	; $CB $32=STA
	.asc	"INC S", 'P'+$80	; $CB $33=INX SP
	.asc	"INC (HL", ')'+$80	; $CB $34=INR M
	.asc	"DEC (HL", ')'+$80	; $CB $35=DCR M
	.asc	"LD (HL), ",'@'+$80	; $CB $36=MVI M
	.asc	"SC", 'F'+$80		; $CB $37=STC
	.asc	"JR C, ", '%'+$80	; $CB $38=JR C		Z80 ONLY!
	.asc	"ADD HL, S",'P'+$80	; $CB $39=DAD SP
	.asc	"LD A, (&", ')'+$80	; $CB $3A=LDA
	.asc	"DEC S", 'P'+$80	; $CB $3B=DCX SP
	.asc	"INC ", 'A'+$80		; $CB $3C=INR A
	.asc	"DEC ", 'A'+$80		; $CB $3D=DCR A
	.asc	"LD A, ", '@'+$80	; $CB $3E=MVI A
	.asc	"CC", 'F'+$80		; $CB $3F=CMC

	.asc	"LD B, ", 'B'+$80	; $CB $40=MOV B,B
	.asc	"LD B, ", 'C'+$80	; $CB $41=MOV B,C
	.asc	"LD B, ", 'D'+$80	; $CB $42=MOV B,D
	.asc	"LD B, ", 'E'+$80	; $CB $43=MOV B,E
	.asc	"LD B, ", 'H'+$80	; $CB $44=MOV B,H
	.asc	"LD B, ", 'L'+$80	; $CB $45=MOV B,L
	.asc	"LD B, (HL",')'+$80	; $CB $46=MOV B,M
	.asc	"LD B, ", 'A'+$80	; $CB $47=MOV B,A
	.asc	"LD C, ", 'B'+$80	; $CB $48=MOV C,B
	.asc	"LD C, ", 'C'+$80	; $CB $49=MOV C,C
	.asc	"LD C, ", 'D'+$80	; $CB $4A=MOV C,D
	.asc	"LD C, ", 'E'+$80	; $CB $4B=MOV C,E
	.asc	"LD C, ", 'H'+$80	; $CB $4C=MOV C,H
	.asc	"LD C, ", 'L'+$80	; $CB $4D=MOV C,L
	.asc	"LD C, (HL",')'+$80	; $CB $4E=MOV C,M
	.asc	"LD C, ", 'A'+$80	; $CB $4F=MOV C,A


	.asc	"LD D, ", 'B'+$80	; $CB $50=MOV D,B
	.asc	"LD D, ", 'C'+$80	; $CB $51=MOV D,C
	.asc	"LD D, ", 'D'+$80	; $CB $52=MOV D,D
	.asc	"LD D, ", 'E'+$80	; $CB $53=MOV D,E
	.asc	"LD D, ", 'H'+$80	; $CB $54=MOV D,H
	.asc	"LD D, ", 'L'+$80	; $CB $55=MOV D,L
	.asc	"LD D, (HL",')'+$80	; $CB $56=MOV D,M
	.asc	"LD D, ", 'A'+$80	; $CB $57=MOV D,A
	.asc	"LD E, ", 'B'+$80	; $CB $58=MOV E,B
	.asc	"LD E, ", 'C'+$80	; $CB $59=MOV E,C
	.asc	"LD E, ", 'D'+$80	; $CB $5A=MOV E,D
	.asc	"LD E, ", 'E'+$80	; $CB $5B=MOV E,E
	.asc	"LD E, ", 'H'+$80	; $CB $5C=MOV E,H
	.asc	"LD E, ", 'L'+$80	; $CB $5D=MOV E,L
	.asc	"LD E, (HL",')'+$80	; $CB $5E=MOV E,M
	.asc	"LD E, ", 'A'+$80	; $CB $5F=MOV E,A

	.asc	"LD H, ", 'B'+$80	; $CB $60=MOV H,B
	.asc	"LD H, ", 'C'+$80	; $CB $61=MOV H,C
	.asc	"LD H, ", 'D'+$80	; $CB $62=MOV H,D
	.asc	"LD H, ", 'E'+$80	; $CB $63=MOV H,E
	.asc	"LD H, ", 'H'+$80	; $CB $64=MOV H,H
	.asc	"LD H, ", 'L'+$80	; $CB $65=MOV H,L
	.asc	"LD H, (HL",')'+$80	; $CB $66=MOV H,M
	.asc	"LD H, ", 'A'+$80	; $CB $67=MOV H,A
	.asc	"LD L, ", 'B'+$80	; $CB $68=MOV L,B
	.asc	"LD L, ", 'C'+$80	; $CB $69=MOV L,C
	.asc	"LD L, ", 'D'+$80	; $CB $6A=MOV L,D
	.asc	"LD L, ", 'E'+$80	; $CB $6B=MOV L,E
	.asc	"LD L, ", 'H'+$80	; $CB $6C=MOV L,H
	.asc	"LD L, ", 'L'+$80	; $CB $6D=MOV L,L
	.asc	"LD L, (HL",')'+$80	; $CB $6E=MOV L,M
	.asc	"LD L, ", 'A'+$80	; $CB $6F=MOV L,A

	.asc	"LD (HL), ",'B'+$80	; $CB $70=MOV M,B
	.asc	"LD (HL), ",'C'+$80	; $CB $71=MOV M,C
	.asc	"LD (HL), ",'D'+$80	; $CB $72=MOV M,D
	.asc	"LD (HL), ",'E'+$80	; $CB $73=MOV M,E
	.asc	"LD (HL), ",'H'+$80	; $CB $74=MOV M,H
	.asc	"LD (HL), ",'L'+$80	; $CB $75=MOV M,L
	.asc	"HAL", 'T'+$80		; $CB $76=HLT
	.asc	"LD (HL), ",'A'+$80	; $CB $77=MOV M,A
	.asc	"LD A, ", 'B'+$80	; $CB $78=MOV A,B
	.asc	"LD A, ", 'C'+$80	; $CB $79=MOV A,C
	.asc	"LD A, ", 'D'+$80	; $CB $7A=MOV A,D
	.asc	"LD A, ", 'E'+$80	; $CB $7B=MOV A,E
	.asc	"LD A, ", 'H'+$80	; $CB $7C=MOV A,H
	.asc	"LD A, ", 'L'+$80	; $CB $7D=MOV A,L
	.asc	"LD A, (HL",')'+$80	; $CB $7E=MOV A,M
	.asc	"LD A, ", 'A'+$80	; $CB $7F=MOV A,A

	.asc	"ADD A, ", 'B'+$80	; $CB $80=ADD B
	.asc	"ADD A, ", 'C'+$80	; $CB $81=ADD C
	.asc	"ADD A, ", 'D'+$80	; $CB $82=ADD D
	.asc	"ADD A, ", 'E'+$80	; $CB $83=ADD E
	.asc	"ADD A, ", 'H'+$80	; $CB $84=ADD H
	.asc	"ADD A, ", 'L'+$80	; $CB $85=ADD L
	.asc	"ADD A, (HL",')'+$80	; $CB $86=ADD M
	.asc	"ADD A, ", 'A'+$80	; $CB $87=ADD A
	.asc	"ADC A, ", 'B'+$80	; $CB $88=ADC B
	.asc	"ADC A, ", 'C'+$80	; $CB $89=ADC C
	.asc	"ADC A, ", 'D'+$80	; $CB $8A=ADC D
	.asc	"ADC A, ", 'E'+$80	; $CB $8B=ADC E
	.asc	"ADC A, ", 'H'+$80	; $CB $8C=ADC H
	.asc	"ADC A, ", 'L'+$80	; $CB $8D=ADC L
	.asc	"ADC A, (HL",')'+$80	; $CB $8E=ADC M
	.asc	"ADC A, ", 'A'+$80	; $CB $8F=ADC A

	.asc	"SUB ", 'B'+$80		; $CB $90=SUB B
	.asc	"SUB ", 'C'+$80		; $CB $91=SUB C
	.asc	"SUB ", 'D'+$80		; $CB $92=SUB D
	.asc	"SUB ", 'E'+$80		; $CB $93=SUB E
	.asc	"SUB ", 'H'+$80		; $CB $94=SUB H
	.asc	"SUB ", 'L'+$80		; $CB $95=SUB L
	.asc	"SUB (HL", ')'+$80	; $CB $96=SUB M
	.asc	"SUB ", 'A'+$80		; $CB $97=SUB A
	.asc	"SBC A, ", 'B'+$80	; $CB $98=SBB B
	.asc	"SBC A, ", 'C'+$80	; $CB $99=SBB C
	.asc	"SBC A, ", 'D'+$80	; $CB $9A=SBB D
	.asc	"SBC A, ", 'E'+$80	; $CB $9B=SBB E
	.asc	"SBC A, ", 'H'+$80	; $CB $9C=SBB H
	.asc	"SBC A, ", 'L'+$80	; $CB $9D=SBB L
	.asc	"SBC A, (HL",')'+$80	; $CB $9E=SBB M
	.asc	"SBC A, ", 'A'+$80	; $CB $9F=SBB A

	.asc	"AND ", 'B'+$80		; $CB $A0=ANA B
	.asc	"AND ", 'C'+$80		; $CB $A1=ANA C
	.asc	"AND ", 'D'+$80		; $CB $A2=ANA D
	.asc	"AND ", 'E'+$80		; $CB $A3=ANA E
	.asc	"AND ", 'H'+$80		; $CB $A4=ANA H
	.asc	"AND ", 'L'+$80		; $CB $A5=ANA L
	.asc	"AND (HL", ')'+$80	; $CB $A6=ANA M
	.asc	"AND ", 'A'+$80		; $CB $A7=ANA A
	.asc	"XOR ", 'B'+$80		; $CB $A8=XRA B
	.asc	"XOR ", 'C'+$80		; $CB $A9=XRA C
	.asc	"XOR ", 'D'+$80		; $CB $AA=XRA D
	.asc	"XOR ", 'E'+$80		; $CB $AB=XRA E
	.asc	"XOR ", 'H'+$80		; $CB $AC=XRA H
	.asc	"XOR ", 'L'+$80		; $CB $AD=XRA L
	.asc	"XOR (HL", ')'+$80	; $CB $AE=XRA M
	.asc	"XOR ", 'A'+$80		; $CB $AF=XRA A

	.asc	"OR ", 'B'+$80		; $CB $B0=ORA B
	.asc	"OR ", 'C'+$80		; $CB $B1=ORA C
	.asc	"OR ", 'D'+$80		; $CB $B2=ORA D
	.asc	"OR ", 'E'+$80		; $CB $B3=ORA E
	.asc	"OR ", 'H'+$80		; $CB $B4=ORA H
	.asc	"OR ", 'L'+$80		; $CB $B5=ORA L
	.asc	"OR (HL", ')'+$80	; $CB $B6=ORA M
	.asc	"OR ", 'A'+$80		; $CB $B7=ORA A
	.asc	"CP ", 'B'+$80		; $CB $B8=CMP B
	.asc	"CP ", 'C'+$80		; $CB $B9=CMP C
	.asc	"CP ", 'D'+$80		; $CB $BA=CMP D
	.asc	"CP ", 'E'+$80		; $CB $BB=CMP E
	.asc	"CP ", 'H'+$80		; $CB $BC=CMP H
	.asc	"CP ", 'L'+$80		; $CB $BD=CMP L
	.asc	"CP (HL", ')'+$80	; $CB $BE=CMP M
	.asc	"CP ", 'A'+$80		; $CB $BF=CMP A

	.asc	"RET N", 'Z'+$80	; $CB $C0=RNZ
	.asc	"POP B", 'C'+$80	; $CB $C1=POP B
	.asc	"JP NZ, ", '&'+$80	; $CB $C2=JNZ
	.asc	"JP ", '&'+$80		; $CB $C3=JMP
	.asc	"CALL NZ, ",'&'+$80	; $CB $C4=CNZ
	.asc	"PUSH B", 'C'+$80	; $CB $C5=PUSH B
	.asc	"ADD A, ", '@'+$80	; $CB $C6=ADI
	.asc	"RST 00", 'H'+$80	; $CB $C7=RST 0
	.asc	"RET ", 'Z'+$80		; $CB $C8=RZ
	.asc	"RE", 'T'+$80		; $CB $C9=RET
	.asc	"JP Z, ", '&'+$80	; $CB $CA=JZ
	.asc	"?", ' '+$80		; $CB $CB=**BITS**		** Z80 PREFIX **
	.asc	"CALL Z, ", '&'+$80	; $CB $CC=CZ
	.asc	"CALL ", '&'+$80	; $CB $CD=CALL
	.asc	"ADC A, ", '@'+$80	; $CB $CE=ACI
	.asc	"RST 08", 'H'+$80	; $CB $CF=RST 1

	.asc	"RET N", 'C'+$80	; $CB $D0=RNC
	.asc	"POP D", 'E'+$80	; $CB $D1=POP D
	.asc	"JP NC, ", '&'+$80	; $CB $D2=JNC
	.asc	"OUT (@), ",'A'+$80	; $CB $D3=OUT
	.asc	"CALL NC, ",'&'+$80	; $CB $D4=CNC
	.asc	"PUSH D", 'E'+$80	; $CB $D5=PUSH D
	.asc	"SUB ", '@'+$80		; $CB $D6=SUI
	.asc	"RST 10", 'H'+$80	; $CB $D7=RST 2
	.asc	"RET ", 'C'+$80		; $CB $D8=RC
	.asc	"EX", 'X'+$80		; $CB $D9=EXX		Z80 ONLY!
	.asc	"JP C, ", '&'+$80	; $CB $DA=JC
	.asc	"IN A, (@", ')'+$80	; $CB $DB=IN
	.asc	"CALL C, ", '&'+$80	; $CB $DC=CC
	.asc	"?", ' '+$80		; $CB $DD=**IX+D**		** Z80 PREFIX **
	.asc	"SBA A, ", '@'+$80	; $CB $DE=SBI
	.asc	"RST 18", 'H'+$80	; $CB $DF=RST 3

	.asc	"RET P", 'O'+$80	; $CB $E0=RPO
	.asc	"POP H", 'L'+$80	; $CB $E1=POP H
	.asc	"JP PO, ", '&'+$80	; $CB $E2=JPO
	.asc	"EX (SP), H",'L'+$80	; $CB $E3=XTHL
	.asc	"CALL PO, ",'&'+$80	; $CB $E4=CPO
	.asc	"PUSH H", 'L'+$80	; $CB $E5=PUSH H
	.asc	"AND ", '@'+$80		; $CB $E6=ANI
	.asc	"RST 20", 'H'+$80	; $CB $E7=RST 4
	.asc	"RET P", 'E'+$80	; $CB $E8=RPE
	.asc	"JP (HL", ')'+$80	; $CB $E9=PCHL
	.asc	"JP PE, ", '&'+$80	; $CB $EA=JPE
	.asc	"EX DE, H", 'L'+$80	; $CB $EB=XCHG
	.asc	"CALL PE, ",'&'+$80	; $CB $EC=CPE
	.asc	"?", ' '+$80		; $CB $ED=**EXTD**		** Z80 PREFIX **
	.asc	"XOR ", '@'+$80		; $CB $EE=XRI
	.asc	"RST 28", 'H'+$80	; $CB $EF=RST 5

	.asc	"RET ", 'P'+$80		; $CB $F0=RP
	.asc	"POP A", 'F'+$80	; $CB $F1=POP PSW
	.asc	"JP P, ", '&'+$80	; $CB $F2=JP
	.asc	"D", 'I'+$80		; $CB $F3=DI
	.asc	"CALL P, ", '&'+$80	; $CB $F4=CP
	.asc	"PUSH A", 'F'+$80	; $CB $F5=PUSH PSW
	.asc	"OR ", '@'+$80		; $CB $F6=ORI
	.asc	"RST 30", 'H'+$80	; $CB $F7=RST 6
	.asc	"RET ", 'M'+$80		; $CB $F8=RM
	.asc	"LD SP, H", 'L'+$80	; $CB $F9=SPHL
	.asc	"JP M, ", '&'+$80	; $CB $FA=JM
	.asc	"E", 'I'+$80		; $CB $FB=EI
	.asc	"CALL M, ", '&'+$80	; $CB $FC=CM
	.asc	"?", ' '+$80		; $CB $FD=**IY+D**		** Z80 PREFIX **
	.asc	"CP ", '@'+$80		; $CB $FE=CPI
	.asc	"RST 38", 'H'+$80	; $CB $FF=RST 7

; **********************************************
; *** IX+d indexed instructions ($DD prefix) *** TO DO
; **********************************************
z80_dd:
	.asc	"NO", 'P'+$80		; $DD $00=NOP
	.asc	"LD BC, ", '&'+$80	; $DD $01=LXI B
	.asc	"LD (BC), ",'A'+$80	; $DD $02=STAX B
	.asc	"INC B", 'C'+$80	; $DD $03=INX B
	.asc	"INC ", 'B'+$80		; $DD $04=INR B
	.asc	"DEC ", 'B'+$80		; $DD $05=DCR B
	.asc	"LD B, ", '@'+$80	; $DD $06=MVI B
	.asc	"RLC", 'A'+$80		; $DD $07=RLC
	.asc	"EX AF, AF",$27+$80	; $DD $08=EX AF, AF'	Z80 ONLY!
	.asc	"ADD HL, B",'C'+$80	; $DD $09=DAD B
	.asc	"LD A, (BC",')'+$80	; $DD $0A=LDAX B
	.asc	"DEC B", 'C'+$80	; $DD $0B=DCX B
	.asc	"INC ", 'C'+$80		; $DD $0C=INR C
	.asc	"DEC ", 'C'+$80		; $DD $0D=DCR C
	.asc	"LD C, ", '@'+$80	; $DD $0E=MVI C
	.asc	"RRC", 'A'+$80		; $DD $0F=RRC

	.asc	"DJNZ, ", '@'+$80	; $DD $10=DJNZ		Z80 ONLY!
	.asc	"LD DE, ", '&'+$80	; $DD $11=LXI D
	.asc	"LD (DE), ",'A'+$80	; $DD $12=STAX D
	.asc	"INC D", 'E'+$80	; $DD $13=INX D
	.asc	"INC ", 'D'+$80		; $DD $14=INR D
	.asc	"DEC ", 'D'+$80		; $DD $15=DCR D
	.asc	"LD D, ", '@'+$80	; $DD $16=MVI D
	.asc	"RL", 'A'+$80		; $DD $17=RAL
	.asc	"JR ", '%'+$80		; $DD $18=JR		Z80 ONLY!
	.asc	"ADD HL, D",'E'+$80	; $DD $19=DAD D
	.asc	"LD A, (DE",')'+$80	; $DD $1A=LDAX D
	.asc	"DEC D", 'E'+$80	; $DD $1B=DCX D
	.asc	"INC ", 'E'+$80		; $DD $1C=INR E
	.asc	"DEC ", 'E'+$80		; $DD $1D=DCR E
	.asc	"LD E, ", '@'+$80	; $DD $1E=MVI E
	.asc	"RR", 'A'+$80		; $DD $1F=RAR

	.asc	"JR NZ, ", '%'+$80	; $DD $20=JR NZ		Z80 ONLY!
	.asc	"LD HL, ", '&'+$80	; $DD $21=LXI H
	.asc	"LD (&), H",'L'+$80	; $DD $22=SHLD
	.asc	"INC H", 'L'+$80	; $DD $23=INX H
	.asc	"INC ", 'H'+$80		; $DD $24=INR H
	.asc	"DEC ", 'H'+$80		; $DD $25=DCR H
	.asc	"LD H, ", '@'+$80	; $DD $26=MVI H
	.asc	"DA", 'A'+$80		; $DD $27=DAA
	.asc	"JR Z, ", '@'+$80	; $DD $28=JR Z		Z80 ONLY!
	.asc	"ADD HL, H",'L'+$80	; $DD $29=DAD H
	.asc	"LD HL, (&",')'+$80	; $DD $2A=LDHL
	.asc	"DEC H", 'L'+$80	; $DD $2B=DCX H
	.asc	"INC ", 'L'+$80		; $DD $2C=INR L
	.asc	"DEC ", 'L'+$80		; $DD $2D=DCR L
	.asc	"LD L, ", '@'+$80	; $DD $2E=MVI L
	.asc	"CP", 'L'+$80		; $DD $2F=CMA

	.asc	"JR NC, ", '%'+$80	; $DD $30=JR NC		UNLIKE 8085
	.asc	"LD SP, ", '&'+$80	; $DD $31=LXI SP
	.asc	"LD (&), ", 'A'+$80	; $DD $32=STA
	.asc	"INC S", 'P'+$80	; $DD $33=INX SP
	.asc	"INC (HL", ')'+$80	; $DD $34=INR M
	.asc	"DEC (HL", ')'+$80	; $DD $35=DCR M
	.asc	"LD (HL), ",'@'+$80	; $DD $36=MVI M
	.asc	"SC", 'F'+$80		; $DD $37=STC
	.asc	"JR C, ", '%'+$80	; $DD $38=JR C		Z80 ONLY!
	.asc	"ADD HL, S",'P'+$80	; $DD $39=DAD SP
	.asc	"LD A, (&", ')'+$80	; $DD $3A=LDA
	.asc	"DEC S", 'P'+$80	; $DD $3B=DCX SP
	.asc	"INC ", 'A'+$80		; $DD $3C=INR A
	.asc	"DEC ", 'A'+$80		; $DD $3D=DCR A
	.asc	"LD A, ", '@'+$80	; $DD $3E=MVI A
	.asc	"CC", 'F'+$80		; $DD $3F=CMC

	.asc	"LD B, ", 'B'+$80	; $DD $40=MOV B,B
	.asc	"LD B, ", 'C'+$80	; $DD $41=MOV B,C
	.asc	"LD B, ", 'D'+$80	; $DD $42=MOV B,D
	.asc	"LD B, ", 'E'+$80	; $DD $43=MOV B,E
	.asc	"LD B, ", 'H'+$80	; $DD $44=MOV B,H
	.asc	"LD B, ", 'L'+$80	; $DD $45=MOV B,L
	.asc	"LD B, (HL",')'+$80	; $DD $46=MOV B,M
	.asc	"LD B, ", 'A'+$80	; $DD $47=MOV B,A
	.asc	"LD C, ", 'B'+$80	; $DD $48=MOV C,B
	.asc	"LD C, ", 'C'+$80	; $DD $49=MOV C,C
	.asc	"LD C, ", 'D'+$80	; $DD $4A=MOV C,D
	.asc	"LD C, ", 'E'+$80	; $DD $4B=MOV C,E
	.asc	"LD C, ", 'H'+$80	; $DD $4C=MOV C,H
	.asc	"LD C, ", 'L'+$80	; $DD $4D=MOV C,L
	.asc	"LD C, (HL",')'+$80	; $DD $4E=MOV C,M
	.asc	"LD C, ", 'A'+$80	; $DD $4F=MOV C,A


	.asc	"LD D, ", 'B'+$80	; $DD $50=MOV D,B
	.asc	"LD D, ", 'C'+$80	; $DD $51=MOV D,C
	.asc	"LD D, ", 'D'+$80	; $DD $52=MOV D,D
	.asc	"LD D, ", 'E'+$80	; $DD $53=MOV D,E
	.asc	"LD D, ", 'H'+$80	; $DD $54=MOV D,H
	.asc	"LD D, ", 'L'+$80	; $DD $55=MOV D,L
	.asc	"LD D, (HL",')'+$80	; $DD $56=MOV D,M
	.asc	"LD D, ", 'A'+$80	; $DD $57=MOV D,A
	.asc	"LD E, ", 'B'+$80	; $DD $58=MOV E,B
	.asc	"LD E, ", 'C'+$80	; $DD $59=MOV E,C
	.asc	"LD E, ", 'D'+$80	; $DD $5A=MOV E,D
	.asc	"LD E, ", 'E'+$80	; $DD $5B=MOV E,E
	.asc	"LD E, ", 'H'+$80	; $DD $5C=MOV E,H
	.asc	"LD E, ", 'L'+$80	; $DD $5D=MOV E,L
	.asc	"LD E, (HL",')'+$80	; $DD $5E=MOV E,M
	.asc	"LD E, ", 'A'+$80	; $DD $5F=MOV E,A

	.asc	"LD H, ", 'B'+$80	; $DD $60=MOV H,B
	.asc	"LD H, ", 'C'+$80	; $DD $61=MOV H,C
	.asc	"LD H, ", 'D'+$80	; $DD $62=MOV H,D
	.asc	"LD H, ", 'E'+$80	; $DD $63=MOV H,E
	.asc	"LD H, ", 'H'+$80	; $DD $64=MOV H,H
	.asc	"LD H, ", 'L'+$80	; $DD $65=MOV H,L
	.asc	"LD H, (HL",')'+$80	; $DD $66=MOV H,M
	.asc	"LD H, ", 'A'+$80	; $DD $67=MOV H,A
	.asc	"LD L, ", 'B'+$80	; $DD $68=MOV L,B
	.asc	"LD L, ", 'C'+$80	; $DD $69=MOV L,C
	.asc	"LD L, ", 'D'+$80	; $DD $6A=MOV L,D
	.asc	"LD L, ", 'E'+$80	; $DD $6B=MOV L,E
	.asc	"LD L, ", 'H'+$80	; $DD $6C=MOV L,H
	.asc	"LD L, ", 'L'+$80	; $DD $6D=MOV L,L
	.asc	"LD L, (HL",')'+$80	; $DD $6E=MOV L,M
	.asc	"LD L, ", 'A'+$80	; $DD $6F=MOV L,A

	.asc	"LD (HL), ",'B'+$80	; $DD $70=MOV M,B
	.asc	"LD (HL), ",'C'+$80	; $DD $71=MOV M,C
	.asc	"LD (HL), ",'D'+$80	; $DD $72=MOV M,D
	.asc	"LD (HL), ",'E'+$80	; $DD $73=MOV M,E
	.asc	"LD (HL), ",'H'+$80	; $DD $74=MOV M,H
	.asc	"LD (HL), ",'L'+$80	; $DD $75=MOV M,L
	.asc	"HAL", 'T'+$80		; $DD $76=HLT
	.asc	"LD (HL), ",'A'+$80	; $DD $77=MOV M,A
	.asc	"LD A, ", 'B'+$80	; $DD $78=MOV A,B
	.asc	"LD A, ", 'C'+$80	; $DD $79=MOV A,C
	.asc	"LD A, ", 'D'+$80	; $DD $7A=MOV A,D
	.asc	"LD A, ", 'E'+$80	; $DD $7B=MOV A,E
	.asc	"LD A, ", 'H'+$80	; $DD $7C=MOV A,H
	.asc	"LD A, ", 'L'+$80	; $DD $7D=MOV A,L
	.asc	"LD A, (HL",')'+$80	; $DD $7E=MOV A,M
	.asc	"LD A, ", 'A'+$80	; $DD $7F=MOV A,A

	.asc	"ADD A, ", 'B'+$80	; $DD $80=ADD B
	.asc	"ADD A, ", 'C'+$80	; $DD $81=ADD C
	.asc	"ADD A, ", 'D'+$80	; $DD $82=ADD D
	.asc	"ADD A, ", 'E'+$80	; $DD $83=ADD E
	.asc	"ADD A, ", 'H'+$80	; $DD $84=ADD H
	.asc	"ADD A, ", 'L'+$80	; $DD $85=ADD L
	.asc	"ADD A, (HL",')'+$80	; $DD $86=ADD M
	.asc	"ADD A, ", 'A'+$80	; $DD $87=ADD A
	.asc	"ADC A, ", 'B'+$80	; $DD $88=ADC B
	.asc	"ADC A, ", 'C'+$80	; $DD $89=ADC C
	.asc	"ADC A, ", 'D'+$80	; $DD $8A=ADC D
	.asc	"ADC A, ", 'E'+$80	; $DD $8B=ADC E
	.asc	"ADC A, ", 'H'+$80	; $DD $8C=ADC H
	.asc	"ADC A, ", 'L'+$80	; $DD $8D=ADC L
	.asc	"ADC A, (HL",')'+$80	; $DD $8E=ADC M
	.asc	"ADC A, ", 'A'+$80	; $DD $8F=ADC A

	.asc	"SUB ", 'B'+$80		; $DD $90=SUB B
	.asc	"SUB ", 'C'+$80		; $DD $91=SUB C
	.asc	"SUB ", 'D'+$80		; $DD $92=SUB D
	.asc	"SUB ", 'E'+$80		; $DD $93=SUB E
	.asc	"SUB ", 'H'+$80		; $DD $94=SUB H
	.asc	"SUB ", 'L'+$80		; $DD $95=SUB L
	.asc	"SUB (HL", ')'+$80	; $DD $96=SUB M
	.asc	"SUB ", 'A'+$80		; $DD $97=SUB A
	.asc	"SBC A, ", 'B'+$80	; $DD $98=SBB B
	.asc	"SBC A, ", 'C'+$80	; $DD $99=SBB C
	.asc	"SBC A, ", 'D'+$80	; $DD $9A=SBB D
	.asc	"SBC A, ", 'E'+$80	; $DD $9B=SBB E
	.asc	"SBC A, ", 'H'+$80	; $DD $9C=SBB H
	.asc	"SBC A, ", 'L'+$80	; $DD $9D=SBB L
	.asc	"SBC A, (HL",')'+$80	; $DD $9E=SBB M
	.asc	"SBC A, ", 'A'+$80	; $DD $9F=SBB A

	.asc	"AND ", 'B'+$80		; $DD $A0=ANA B
	.asc	"AND ", 'C'+$80		; $DD $A1=ANA C
	.asc	"AND ", 'D'+$80		; $DD $A2=ANA D
	.asc	"AND ", 'E'+$80		; $DD $A3=ANA E
	.asc	"AND ", 'H'+$80		; $DD $A4=ANA H
	.asc	"AND ", 'L'+$80		; $DD $A5=ANA L
	.asc	"AND (HL", ')'+$80	; $DD $A6=ANA M
	.asc	"AND ", 'A'+$80		; $DD $A7=ANA A
	.asc	"XOR ", 'B'+$80		; $DD $A8=XRA B
	.asc	"XOR ", 'C'+$80		; $DD $A9=XRA C
	.asc	"XOR ", 'D'+$80		; $DD $AA=XRA D
	.asc	"XOR ", 'E'+$80		; $DD $AB=XRA E
	.asc	"XOR ", 'H'+$80		; $DD $AC=XRA H
	.asc	"XOR ", 'L'+$80		; $DD $AD=XRA L
	.asc	"XOR (HL", ')'+$80	; $DD $AE=XRA M
	.asc	"XOR ", 'A'+$80		; $DD $AF=XRA A

	.asc	"OR ", 'B'+$80		; $DD $B0=ORA B
	.asc	"OR ", 'C'+$80		; $DD $B1=ORA C
	.asc	"OR ", 'D'+$80		; $DD $B2=ORA D
	.asc	"OR ", 'E'+$80		; $DD $B3=ORA E
	.asc	"OR ", 'H'+$80		; $DD $B4=ORA H
	.asc	"OR ", 'L'+$80		; $DD $B5=ORA L
	.asc	"OR (HL", ')'+$80	; $DD $B6=ORA M
	.asc	"OR ", 'A'+$80		; $DD $B7=ORA A
	.asc	"CP ", 'B'+$80		; $DD $B8=CMP B
	.asc	"CP ", 'C'+$80		; $DD $B9=CMP C
	.asc	"CP ", 'D'+$80		; $DD $BA=CMP D
	.asc	"CP ", 'E'+$80		; $DD $BB=CMP E
	.asc	"CP ", 'H'+$80		; $DD $BC=CMP H
	.asc	"CP ", 'L'+$80		; $DD $BD=CMP L
	.asc	"CP (HL", ')'+$80	; $DD $BE=CMP M
	.asc	"CP ", 'A'+$80		; $DD $BF=CMP A

	.asc	"RET N", 'Z'+$80	; $DD $C0=RNZ
	.asc	"POP B", 'C'+$80	; $DD $C1=POP B
	.asc	"JP NZ, ", '&'+$80	; $DD $C2=JNZ
	.asc	"JP ", '&'+$80		; $DD $C3=JMP
	.asc	"CALL NZ, ",'&'+$80	; $DD $C4=CNZ
	.asc	"PUSH B", 'C'+$80	; $DD $C5=PUSH B
	.asc	"ADD A, ", '@'+$80	; $DD $C6=ADI
	.asc	"RST 00", 'H'+$80	; $DD $C7=RST 0
	.asc	"RET ", 'Z'+$80		; $DD $C8=RZ
	.asc	"RE", 'T'+$80		; $DD $C9=RET
	.asc	"JP Z, ", '&'+$80	; $DD $CA=JZ
	.asc	"?", ' '+$80		; $DD $CB=**BITS**		** Z80 PREFIX **
	.asc	"CALL Z, ", '&'+$80	; $DD $CC=CZ
	.asc	"CALL ", '&'+$80	; $DD $CD=CALL
	.asc	"ADC A, ", '@'+$80	; $DD $CE=ACI
	.asc	"RST 08", 'H'+$80	; $DD $CF=RST 1

	.asc	"RET N", 'C'+$80	; $DD $D0=RNC
	.asc	"POP D", 'E'+$80	; $DD $D1=POP D
	.asc	"JP NC, ", '&'+$80	; $DD $D2=JNC
	.asc	"OUT (@), ",'A'+$80	; $DD $D3=OUT
	.asc	"CALL NC, ",'&'+$80	; $DD $D4=CNC
	.asc	"PUSH D", 'E'+$80	; $DD $D5=PUSH D
	.asc	"SUB ", '@'+$80		; $DD $D6=SUI
	.asc	"RST 10", 'H'+$80	; $DD $D7=RST 2
	.asc	"RET ", 'C'+$80		; $DD $D8=RC
	.asc	"EX", 'X'+$80		; $DD $D9=EXX		Z80 ONLY!
	.asc	"JP C, ", '&'+$80	; $DD $DA=JC
	.asc	"IN A, (@", ')'+$80	; $DD $DB=IN
	.asc	"CALL C, ", '&'+$80	; $DD $DC=CC
	.asc	"?", ' '+$80		; $DD $DD=**IX+D**		** Z80 PREFIX **
	.asc	"SBA A, ", '@'+$80	; $DD $DE=SBI
	.asc	"RST 18", 'H'+$80	; $DD $DF=RST 3

	.asc	"RET P", 'O'+$80	; $DD $E0=RPO
	.asc	"POP H", 'L'+$80	; $DD $E1=POP H
	.asc	"JP PO, ", '&'+$80	; $DD $E2=JPO
	.asc	"EX (SP), H",'L'+$80	; $DD $E3=XTHL
	.asc	"CALL PO, ",'&'+$80	; $DD $E4=CPO
	.asc	"PUSH H", 'L'+$80	; $DD $E5=PUSH H
	.asc	"AND ", '@'+$80		; $DD $E6=ANI
	.asc	"RST 20", 'H'+$80	; $DD $E7=RST 4
	.asc	"RET P", 'E'+$80	; $DD $E8=RPE
	.asc	"JP (HL", ')'+$80	; $DD $E9=PCHL
	.asc	"JP PE, ", '&'+$80	; $DD $EA=JPE
	.asc	"EX DE, H", 'L'+$80	; $DD $EB=XCHG
	.asc	"CALL PE, ",'&'+$80	; $DD $EC=CPE
	.asc	"?", ' '+$80		; $DD $ED=**EXTD**		** Z80 PREFIX **
	.asc	"XOR ", '@'+$80		; $DD $EE=XRI
	.asc	"RST 28", 'H'+$80	; $DD $EF=RST 5

	.asc	"RET ", 'P'+$80		; $DD $F0=RP
	.asc	"POP A", 'F'+$80	; $DD $F1=POP PSW
	.asc	"JP P, ", '&'+$80	; $DD $F2=JP
	.asc	"D", 'I'+$80		; $DD $F3=DI
	.asc	"CALL P, ", '&'+$80	; $DD $F4=CP
	.asc	"PUSH A", 'F'+$80	; $DD $F5=PUSH PSW
	.asc	"OR ", '@'+$80		; $DD $F6=ORI
	.asc	"RST 30", 'H'+$80	; $DD $F7=RST 6
	.asc	"RET ", 'M'+$80		; $DD $F8=RM
	.asc	"LD SP, H", 'L'+$80	; $DD $F9=SPHL
	.asc	"JP M, ", '&'+$80	; $DD $FA=JM
	.asc	"E", 'I'+$80		; $DD $FB=EI
	.asc	"CALL M, ", '&'+$80	; $DD $FC=CM
	.asc	"?", ' '+$80		; $DD $FD=**IY+D**		** Z80 PREFIX **
	.asc	"CP ", '@'+$80		; $DD $FE=CPI
	.asc	"RST 38", 'H'+$80	; $DD $FF=RST 7

; ******************************************
; *** extended instructions ($ED prefix) ***
; ******************************************
z80_ed:
	.asc	"IN B, (C", ')'+$80	; $ED $40=IN B, (C)
	.asc	"OUT (C), ",'B'+$80	; $ED $41=OUT (C), B
	.asc	"SBC HL, B",'C'+$80	; $ED $42=SBC HL, BC
	.asc	"LD (&), B",'C'+$80	; $ED $43=LD (**), BC
	.asc	"NE", 'G'+$80		; $ED $44=NEG
	.asc	"RET", 'N'+$80		; $ED $45=RETN
	.asc	"IM ", '0'+$80		; $ED $46=IM 0
	.asc	"LD I, ", 'A'+$80	; $ED $47=LD I, A
	.asc	"IN C, (C", ')'+$80	; $ED $48=IN C, (C)
	.asc	"OUT (C), ",'C'+$80	; $ED $49=OUT (C), C
	.asc	"ADC HL, B",'C'+$80	; $ED $4A=ADC HL, BC
	.asc	"LD BC, (&",')'+$80	; $ED $4B=LD BC, (**)
	.asc	"NEG", '?'+$80		; $ED $4C=NEG			**REPEATED**
	.asc	"RET", 'I'+$80		; $ED $4D=RETI
	.asc	"IM 0/", '1'+$80	; $ED $4E=IM 0/1		UNDEFINED!
	.asc	"LD R, ", 'A'+$80	; $ED $4F=LD R, A


	.asc	"IN D, (C", ')'+$80	; $ED $50=IN D, (C)
	.asc	"OUT (C), ",'D'+$80	; $ED $51=OUT (C), D
	.asc	"SBC HL, D",'E'+$80	; $ED $52=SBC HL, DE
	.asc	"LD (&), D",'E'+$80	; $ED $53=LD (**), DE
	.asc	"NEG", '?'+$80		; $ED $54=NEG			**REPEATED**
	.asc	"RET", 'N'+$80		; $ED $55=RETN
	.asc	"IM ", '1'+$80		; $ED $56=IM 1
	.asc	"LD A, ", 'I'+$80	; $ED $57=LD A, I
	.asc	"IN E, (C", ')'+$80	; $ED $58=IN E, (C)
	.asc	"OUT (C), ",'E'+$80	; $ED $59=OUT (C), E
	.asc	"ADC HL, D",'E'+$80	; $ED $5A=ADC HL, DE
	.asc	"LD DE, (&",')'+$80	; $ED $5B=LD DE, (**)
	.asc	"NEG", '?'+$80		; $ED $5C=NEG			**REPEATED**
	.asc	"RET", 'N'+$80		; $ED $5D=RETN
	.asc	"IM ", '2'+$80		; $ED $5E=IM 2
	.asc	"LD A, ", 'R'+$80	; $ED $5F=LD A, R

	.asc	"IN H, (C", ')'+$80	; $ED $60=IN H, (C)
	.asc	"OUT (C), ",'H'+$80	; $ED $61=OUT (C), H
	.asc	"SBC HL, H",'L'+$80	; $ED $62=SBC HL, HL
	.asc	"LD (&), H",'L'+$80	; $ED $63=LD (**), HL	**REPEATED**
	.asc	"NEG", '?'+$80		; $ED $64=NEG			**REPEATED**
	.asc	"RET", 'N'+$80		; $ED $65=RETN
	.asc	"IM", '0'+$80		; $ED $66=IM 0
	.asc	"RR", 'D'+$80		; $ED $67=RRD
	.asc	"IN L, (C", ')'+$80	; $ED $68=IN L, (C)
	.asc	"OUT (C), ",'L'+$80	; $ED $69=OUT (C), L
	.asc	"ADC HL, H",'L'+$80	; $ED $6A=ADC HL, HL
	.asc	"LD HL, (&",')'+$80	; $ED $6B=LD HL, (**)	**REPEATED**
	.asc	"NEG", '?'+$80		; $ED $6C=NEG			**REPEATED**
	.asc	"RET", 'N'+$80		; $ED $6D=RETN
	.asc	"IM 0/", '1'+$80	; $ED $6E=IM O/1		UNDEFINED!
	.asc	"RL", 'D'+$80		; $ED $6F=RLD

	.asc	"IN (C", ')'+$80	; $ED $70=IN (C)		UNDOCUMENTED?
	.asc	"OUT (C), ",'0'+$80	; $ED $71=OUT (C), 0	UNDOCUMENTED?
	.asc	"SBC HL, S",'P'+$80	; $ED $72=SBC HL, SP
	.asc	"LD (&), S",'P'+$80	; $ED $73=LD (**), SP
	.asc	"NEG", '?'+$80		; $ED $74=NEG			**REPEATED**
	.asc	"RET", 'N'+$80		; $ED $75=RETN
	.asc	"IM ", '1'+$80		; $ED $76=IM 1
	.asc	"?", ' '+$80		; $ED $77				UNDEFINED
	.asc	"IN A, (C", ')'+$80	; $ED $78=IN A, (C)
	.asc	"OUT (C), ",'A'+$80	; $ED $79=OUT (C), A
	.asc	"ADC HL, S",'P'+$80	; $ED $7A=ADC HL, SP
	.asc	"LD SP, (&",')'+$80	; $ED $7B=LD SP, (**)
	.asc	"NEG", '?'+$80		; $ED $7C=NEG			**REPEATED**
	.asc	"RET", 'N'+$80		; $ED $7D=RETN
	.asc	"IM ",'2'+$80		; $ED $7E=IM 2
	.asc	"?", ' '+$80		; $ED $7F				UNDEFINED

	.asc	"LD", 'I'+$80		; $ED $A0=LDI
	.asc	"CP", 'I'+$80		; $ED $A1=CPI
	.asc	"IN", 'I'+$80		; $ED $A2=INI
	.asc	"OUT", 'I'+$80		; $ED $A3=OUTI
	.asc	"?", ' '+$80		; $ED $A4				UNDEFINED
	.asc	"?", ' '+$80		; $ED $A5				UNDEFINED
	.asc	"?", ' '+$80		; $ED $A6				UNDEFINED
	.asc	"?", ' '+$80		; $ED $A7				UNDEFINED
	.asc	"LD", 'D'+$80		; $ED $A8=LDD
	.asc	"CP", 'D'+$80		; $ED $A9=CPD
	.asc	"IN", 'D'+$80		; $ED $AA=IND
	.asc	"OUT", 'D'+$80		; $ED $AB=OUTD
	.asc	"?", ' '+$80		; $ED $AC				UNDEFINED
	.asc	"?", ' '+$80		; $ED $AD				UNDEFINED
	.asc	"?", ' '+$80		; $ED $AE				UNDEFINED
	.asc	"?", ' '+$80		; $ED $AF				UNDEFINED

	.asc	"LDI", 'R'+$80		; $ED $B0=LDIR
	.asc	"CPI", 'R'+$80		; $ED $B1=CPIR
	.asc	"INI", 'R'+$80		; $ED $B2=INIR
	.asc	"OTI", 'R'+$80		; $ED $B3=OTIR
	.asc	"?", ' '+$80		; $ED $B4				UNDEFINED
	.asc	"?", ' '+$80		; $ED $B5				UNDEFINED
	.asc	"?", ' '+$80		; $ED $B6				UNDEFINED
	.asc	"?", ' '+$80		; $ED $B7				UNDEFINED
	.asc	"LDD", 'R'+$80		; $ED $B8=LDDR
	.asc	"CPD", 'R'+$80		; $ED $B9=CPDR
	.asc	"IND", 'R'+$80		; $ED $BA=INDR
	.asc	"OTD", 'R'+$80		; $ED $BB=OTDR
	.asc	"?", ' '+$80		; $ED $BC				UNDEFINED
	.asc	"?", ' '+$80		; $ED $BD				UNDEFINED
	.asc	"?", ' '+$80		; $ED $BE				UNDEFINED
	.asc	"?", ' '+$80		; $ED $BF				UNDEFINED

; **********************************************
; *** IY+d indexed instructions ($FD prefix) *** TO DO
; **********************************************
z80_fd:
	.asc	"NO", 'P'+$80		; $FD $00=NOP
	.asc	"LD BC, ", '&'+$80	; $FD $01=LXI B
	.asc	"LD (BC), ",'A'+$80	; $FD $02=STAX B
	.asc	"INC B", 'C'+$80	; $FD $03=INX B
	.asc	"INC ", 'B'+$80		; $FD $04=INR B
	.asc	"DEC ", 'B'+$80		; $FD $05=DCR B
	.asc	"LD B, ", '@'+$80	; $FD $06=MVI B
	.asc	"RLC", 'A'+$80		; $FD $07=RLC
	.asc	"EX AF, AF",$27+$80	; $FD $08=EX AF, AF'	Z80 ONLY!
	.asc	"ADD HL, B",'C'+$80	; $FD $09=DAD B
	.asc	"LD A, (BC",')'+$80	; $FD $0A=LDAX B
	.asc	"DEC B", 'C'+$80	; $FD $0B=DCX B
	.asc	"INC ", 'C'+$80		; $FD $0C=INR C
	.asc	"DEC ", 'C'+$80		; $FD $0D=DCR C
	.asc	"LD C, ", '@'+$80	; $FD $0E=MVI C
	.asc	"RRC", 'A'+$80		; $FD $0F=RRC

	.asc	"DJNZ, ", '@'+$80	; $FD $10=DJNZ		Z80 ONLY!
	.asc	"LD DE, ", '&'+$80	; $FD $11=LXI D
	.asc	"LD (DE), ",'A'+$80	; $FD $12=STAX D
	.asc	"INC D", 'E'+$80	; $FD $13=INX D
	.asc	"INC ", 'D'+$80		; $FD $14=INR D
	.asc	"DEC ", 'D'+$80		; $FD $15=DCR D
	.asc	"LD D, ", '@'+$80	; $FD $16=MVI D
	.asc	"RL", 'A'+$80		; $FD $17=RAL
	.asc	"JR ", '%'+$80		; $FD $18=JR		Z80 ONLY!
	.asc	"ADD HL, D",'E'+$80	; $FD $19=DAD D
	.asc	"LD A, (DE",')'+$80	; $FD $1A=LDAX D
	.asc	"DEC D", 'E'+$80	; $FD $1B=DCX D
	.asc	"INC ", 'E'+$80		; $FD $1C=INR E
	.asc	"DEC ", 'E'+$80		; $FD $1D=DCR E
	.asc	"LD E, ", '@'+$80	; $FD $1E=MVI E
	.asc	"RR", 'A'+$80		; $FD $1F=RAR

	.asc	"JR NZ, ", '%'+$80	; $FD $20=JR NZ		Z80 ONLY!
	.asc	"LD HL, ", '&'+$80	; $FD $21=LXI H
	.asc	"LD (&), H",'L'+$80	; $FD $22=SHLD
	.asc	"INC H", 'L'+$80	; $FD $23=INX H
	.asc	"INC ", 'H'+$80		; $FD $24=INR H
	.asc	"DEC ", 'H'+$80		; $FD $25=DCR H
	.asc	"LD H, ", '@'+$80	; $FD $26=MVI H
	.asc	"DA", 'A'+$80		; $FD $27=DAA
	.asc	"JR Z, ", '@'+$80	; $FD $28=JR Z		Z80 ONLY!
	.asc	"ADD HL, H",'L'+$80	; $FD $29=DAD H
	.asc	"LD HL, (&",')'+$80	; $FD $2A=LDHL
	.asc	"DEC H", 'L'+$80	; $FD $2B=DCX H
	.asc	"INC ", 'L'+$80		; $FD $2C=INR L
	.asc	"DEC ", 'L'+$80		; $FD $2D=DCR L
	.asc	"LD L, ", '@'+$80	; $FD $2E=MVI L
	.asc	"CP", 'L'+$80		; $FD $2F=CMA

	.asc	"JR NC, ", '%'+$80	; $FD $30=JR NC		UNLIKE 8085
	.asc	"LD SP, ", '&'+$80	; $FD $31=LXI SP
	.asc	"LD (&), ", 'A'+$80	; $FD $32=STA
	.asc	"INC S", 'P'+$80	; $FD $33=INX SP
	.asc	"INC (HL", ')'+$80	; $FD $34=INR M
	.asc	"DEC (HL", ')'+$80	; $FD $35=DCR M
	.asc	"LD (HL), ",'@'+$80	; $FD $36=MVI M
	.asc	"SC", 'F'+$80		; $FD $37=STC
	.asc	"JR C, ", '%'+$80	; $FD $38=JR C		Z80 ONLY!
	.asc	"ADD HL, S",'P'+$80	; $FD $39=DAD SP
	.asc	"LD A, (&", ')'+$80	; $FD $3A=LDA
	.asc	"DEC S", 'P'+$80	; $FD $3B=DCX SP
	.asc	"INC ", 'A'+$80		; $FD $3C=INR A
	.asc	"DEC ", 'A'+$80		; $FD $3D=DCR A
	.asc	"LD A, ", '@'+$80	; $FD $3E=MVI A
	.asc	"CC", 'F'+$80		; $FD $3F=CMC

	.asc	"LD B, ", 'B'+$80	; $FD $40=MOV B,B
	.asc	"LD B, ", 'C'+$80	; $FD $41=MOV B,C
	.asc	"LD B, ", 'D'+$80	; $FD $42=MOV B,D
	.asc	"LD B, ", 'E'+$80	; $FD $43=MOV B,E
	.asc	"LD B, ", 'H'+$80	; $FD $44=MOV B,H
	.asc	"LD B, ", 'L'+$80	; $FD $45=MOV B,L
	.asc	"LD B, (HL",')'+$80	; $FD $46=MOV B,M
	.asc	"LD B, ", 'A'+$80	; $FD $47=MOV B,A
	.asc	"LD C, ", 'B'+$80	; $FD $48=MOV C,B
	.asc	"LD C, ", 'C'+$80	; $FD $49=MOV C,C
	.asc	"LD C, ", 'D'+$80	; $FD $4A=MOV C,D
	.asc	"LD C, ", 'E'+$80	; $FD $4B=MOV C,E
	.asc	"LD C, ", 'H'+$80	; $FD $4C=MOV C,H
	.asc	"LD C, ", 'L'+$80	; $FD $4D=MOV C,L
	.asc	"LD C, (HL",')'+$80	; $FD $4E=MOV C,M
	.asc	"LD C, ", 'A'+$80	; $FD $4F=MOV C,A


	.asc	"LD D, ", 'B'+$80	; $FD $50=MOV D,B
	.asc	"LD D, ", 'C'+$80	; $FD $51=MOV D,C
	.asc	"LD D, ", 'D'+$80	; $FD $52=MOV D,D
	.asc	"LD D, ", 'E'+$80	; $FD $53=MOV D,E
	.asc	"LD D, ", 'H'+$80	; $FD $54=MOV D,H
	.asc	"LD D, ", 'L'+$80	; $FD $55=MOV D,L
	.asc	"LD D, (HL",')'+$80	; $FD $56=MOV D,M
	.asc	"LD D, ", 'A'+$80	; $FD $57=MOV D,A
	.asc	"LD E, ", 'B'+$80	; $FD $58=MOV E,B
	.asc	"LD E, ", 'C'+$80	; $FD $59=MOV E,C
	.asc	"LD E, ", 'D'+$80	; $FD $5A=MOV E,D
	.asc	"LD E, ", 'E'+$80	; $FD $5B=MOV E,E
	.asc	"LD E, ", 'H'+$80	; $FD $5C=MOV E,H
	.asc	"LD E, ", 'L'+$80	; $FD $5D=MOV E,L
	.asc	"LD E, (HL",')'+$80	; $FD $5E=MOV E,M
	.asc	"LD E, ", 'A'+$80	; $FD $5F=MOV E,A

	.asc	"LD H, ", 'B'+$80	; $FD $60=MOV H,B
	.asc	"LD H, ", 'C'+$80	; $FD $61=MOV H,C
	.asc	"LD H, ", 'D'+$80	; $FD $62=MOV H,D
	.asc	"LD H, ", 'E'+$80	; $FD $63=MOV H,E
	.asc	"LD H, ", 'H'+$80	; $FD $64=MOV H,H
	.asc	"LD H, ", 'L'+$80	; $FD $65=MOV H,L
	.asc	"LD H, (HL",')'+$80	; $FD $66=MOV H,M
	.asc	"LD H, ", 'A'+$80	; $FD $67=MOV H,A
	.asc	"LD L, ", 'B'+$80	; $FD $68=MOV L,B
	.asc	"LD L, ", 'C'+$80	; $FD $69=MOV L,C
	.asc	"LD L, ", 'D'+$80	; $FD $6A=MOV L,D
	.asc	"LD L, ", 'E'+$80	; $FD $6B=MOV L,E
	.asc	"LD L, ", 'H'+$80	; $FD $6C=MOV L,H
	.asc	"LD L, ", 'L'+$80	; $FD $6D=MOV L,L
	.asc	"LD L, (HL",')'+$80	; $FD $6E=MOV L,M
	.asc	"LD L, ", 'A'+$80	; $FD $6F=MOV L,A

	.asc	"LD (HL), ",'B'+$80	; $FD $70=MOV M,B
	.asc	"LD (HL), ",'C'+$80	; $FD $71=MOV M,C
	.asc	"LD (HL), ",'D'+$80	; $FD $72=MOV M,D
	.asc	"LD (HL), ",'E'+$80	; $FD $73=MOV M,E
	.asc	"LD (HL), ",'H'+$80	; $FD $74=MOV M,H
	.asc	"LD (HL), ",'L'+$80	; $FD $75=MOV M,L
	.asc	"HAL", 'T'+$80		; $FD $76=HLT
	.asc	"LD (HL), ",'A'+$80	; $FD $77=MOV M,A
	.asc	"LD A, ", 'B'+$80	; $FD $78=MOV A,B
	.asc	"LD A, ", 'C'+$80	; $FD $79=MOV A,C
	.asc	"LD A, ", 'D'+$80	; $FD $7A=MOV A,D
	.asc	"LD A, ", 'E'+$80	; $FD $7B=MOV A,E
	.asc	"LD A, ", 'H'+$80	; $FD $7C=MOV A,H
	.asc	"LD A, ", 'L'+$80	; $FD $7D=MOV A,L
	.asc	"LD A, (HL",')'+$80	; $FD $7E=MOV A,M
	.asc	"LD A, ", 'A'+$80	; $FD $7F=MOV A,A

	.asc	"ADD A, ", 'B'+$80	; $FD $80=ADD B
	.asc	"ADD A, ", 'C'+$80	; $FD $81=ADD C
	.asc	"ADD A, ", 'D'+$80	; $FD $82=ADD D
	.asc	"ADD A, ", 'E'+$80	; $FD $83=ADD E
	.asc	"ADD A, ", 'H'+$80	; $FD $84=ADD H
	.asc	"ADD A, ", 'L'+$80	; $FD $85=ADD L
	.asc	"ADD A, (HL",')'+$80	; $FD $86=ADD M
	.asc	"ADD A, ", 'A'+$80	; $FD $87=ADD A
	.asc	"ADC A, ", 'B'+$80	; $FD $88=ADC B
	.asc	"ADC A, ", 'C'+$80	; $FD $89=ADC C
	.asc	"ADC A, ", 'D'+$80	; $FD $8A=ADC D
	.asc	"ADC A, ", 'E'+$80	; $FD $8B=ADC E
	.asc	"ADC A, ", 'H'+$80	; $FD $8C=ADC H
	.asc	"ADC A, ", 'L'+$80	; $FD $8D=ADC L
	.asc	"ADC A, (HL",')'+$80	; $FD $8E=ADC M
	.asc	"ADC A, ", 'A'+$80	; $FD $8F=ADC A

	.asc	"SUB ", 'B'+$80		; $FD $90=SUB B
	.asc	"SUB ", 'C'+$80		; $FD $91=SUB C
	.asc	"SUB ", 'D'+$80		; $FD $92=SUB D
	.asc	"SUB ", 'E'+$80		; $FD $93=SUB E
	.asc	"SUB ", 'H'+$80		; $FD $94=SUB H
	.asc	"SUB ", 'L'+$80		; $FD $95=SUB L
	.asc	"SUB (HL", ')'+$80	; $FD $96=SUB M
	.asc	"SUB ", 'A'+$80		; $FD $97=SUB A
	.asc	"SBC A, ", 'B'+$80	; $FD $98=SBB B
	.asc	"SBC A, ", 'C'+$80	; $FD $99=SBB C
	.asc	"SBC A, ", 'D'+$80	; $FD $9A=SBB D
	.asc	"SBC A, ", 'E'+$80	; $FD $9B=SBB E
	.asc	"SBC A, ", 'H'+$80	; $FD $9C=SBB H
	.asc	"SBC A, ", 'L'+$80	; $FD $9D=SBB L
	.asc	"SBC A, (HL",')'+$80	; $FD $9E=SBB M
	.asc	"SBC A, ", 'A'+$80	; $FD $9F=SBB A

	.asc	"AND ", 'B'+$80		; $FD $A0=ANA B
	.asc	"AND ", 'C'+$80		; $FD $A1=ANA C
	.asc	"AND ", 'D'+$80		; $FD $A2=ANA D
	.asc	"AND ", 'E'+$80		; $FD $A3=ANA E
	.asc	"AND ", 'H'+$80		; $FD $A4=ANA H
	.asc	"AND ", 'L'+$80		; $FD $A5=ANA L
	.asc	"AND (HL", ')'+$80	; $FD $A6=ANA M
	.asc	"AND ", 'A'+$80		; $FD $A7=ANA A
	.asc	"XOR ", 'B'+$80		; $FD $A8=XRA B
	.asc	"XOR ", 'C'+$80		; $FD $A9=XRA C
	.asc	"XOR ", 'D'+$80		; $FD $AA=XRA D
	.asc	"XOR ", 'E'+$80		; $FD $AB=XRA E
	.asc	"XOR ", 'H'+$80		; $FD $AC=XRA H
	.asc	"XOR ", 'L'+$80		; $FD $AD=XRA L
	.asc	"XOR (HL", ')'+$80	; $FD $AE=XRA M
	.asc	"XOR ", 'A'+$80		; $FD $AF=XRA A

	.asc	"OR ", 'B'+$80		; $FD $B0=ORA B
	.asc	"OR ", 'C'+$80		; $FD $B1=ORA C
	.asc	"OR ", 'D'+$80		; $FD $B2=ORA D
	.asc	"OR ", 'E'+$80		; $FD $B3=ORA E
	.asc	"OR ", 'H'+$80		; $FD $B4=ORA H
	.asc	"OR ", 'L'+$80		; $FD $B5=ORA L
	.asc	"OR (HL", ')'+$80	; $FD $B6=ORA M
	.asc	"OR ", 'A'+$80		; $FD $B7=ORA A
	.asc	"CP ", 'B'+$80		; $FD $B8=CMP B
	.asc	"CP ", 'C'+$80		; $FD $B9=CMP C
	.asc	"CP ", 'D'+$80		; $FD $BA=CMP D
	.asc	"CP ", 'E'+$80		; $FD $BB=CMP E
	.asc	"CP ", 'H'+$80		; $FD $BC=CMP H
	.asc	"CP ", 'L'+$80		; $FD $BD=CMP L
	.asc	"CP (HL", ')'+$80	; $FD $BE=CMP M
	.asc	"CP ", 'A'+$80		; $FD $BF=CMP A

	.asc	"RET N", 'Z'+$80	; $FD $C0=RNZ
	.asc	"POP B", 'C'+$80	; $FD $C1=POP B
	.asc	"JP NZ, ", '&'+$80	; $FD $C2=JNZ
	.asc	"JP ", '&'+$80		; $FD $C3=JMP
	.asc	"CALL NZ, ",'&'+$80	; $FD $C4=CNZ
	.asc	"PUSH B", 'C'+$80	; $FD $C5=PUSH B
	.asc	"ADD A, ", '@'+$80	; $FD $C6=ADI
	.asc	"RST 00", 'H'+$80	; $FD $C7=RST 0
	.asc	"RET ", 'Z'+$80		; $FD $C8=RZ
	.asc	"RE", 'T'+$80		; $FD $C9=RET
	.asc	"JP Z, ", '&'+$80	; $FD $CA=JZ
	.asc	"?", ' '+$80		; $FD $CB=**BITS**		** Z80 PREFIX **
	.asc	"CALL Z, ", '&'+$80	; $FD $CC=CZ
	.asc	"CALL ", '&'+$80	; $FD $CD=CALL
	.asc	"ADC A, ", '@'+$80	; $FD $CE=ACI
	.asc	"RST 08", 'H'+$80	; $FD $CF=RST 1

	.asc	"RET N", 'C'+$80	; $FD $D0=RNC
	.asc	"POP D", 'E'+$80	; $FD $D1=POP D
	.asc	"JP NC, ", '&'+$80	; $FD $D2=JNC
	.asc	"OUT (@), ",'A'+$80	; $FD $D3=OUT
	.asc	"CALL NC, ",'&'+$80	; $FD $D4=CNC
	.asc	"PUSH D", 'E'+$80	; $FD $D5=PUSH D
	.asc	"SUB ", '@'+$80		; $FD $D6=SUI
	.asc	"RST 10", 'H'+$80	; $FD $D7=RST 2
	.asc	"RET ", 'C'+$80		; $FD $D8=RC
	.asc	"EX", 'X'+$80		; $FD $D9=EXX		Z80 ONLY!
	.asc	"JP C, ", '&'+$80	; $FD $DA=JC
	.asc	"IN A, (@", ')'+$80	; $FD $DB=IN
	.asc	"CALL C, ", '&'+$80	; $FD $DC=CC
	.asc	"?", ' '+$80		; $FD $DD=**IX+D**		** Z80 PREFIX **
	.asc	"SBA A, ", '@'+$80	; $FD $DE=SBI
	.asc	"RST 18", 'H'+$80	; $FD $DF=RST 3

	.asc	"RET P", 'O'+$80	; $FD $E0=RPO
	.asc	"POP H", 'L'+$80	; $FD $E1=POP H
	.asc	"JP PO, ", '&'+$80	; $FD $E2=JPO
	.asc	"EX (SP), H",'L'+$80	; $FD $E3=XTHL
	.asc	"CALL PO, ",'&'+$80	; $FD $E4=CPO
	.asc	"PUSH H", 'L'+$80	; $FD $E5=PUSH H
	.asc	"AND ", '@'+$80		; $FD $E6=ANI
	.asc	"RST 20", 'H'+$80	; $FD $E7=RST 4
	.asc	"RET P", 'E'+$80	; $FD $E8=RPE
	.asc	"JP (HL", ')'+$80	; $FD $E9=PCHL
	.asc	"JP PE, ", '&'+$80	; $FD $EA=JPE
	.asc	"EX DE, H", 'L'+$80	; $FD $EB=XCHG
	.asc	"CALL PE, ",'&'+$80	; $FD $EC=CPE
	.asc	"?", ' '+$80		; $FD $ED=**EXTD**		** Z80 PREFIX **
	.asc	"XOR ", '@'+$80		; $FD $EE=XRI
	.asc	"RST 28", 'H'+$80	; $FD $EF=RST 5

	.asc	"RET ", 'P'+$80		; $FD $F0=RP
	.asc	"POP A", 'F'+$80	; $FD $F1=POP PSW
	.asc	"JP P, ", '&'+$80	; $FD $F2=JP
	.asc	"D", 'I'+$80		; $FD $F3=DI
	.asc	"CALL P, ", '&'+$80	; $FD $F4=CP
	.asc	"PUSH A", 'F'+$80	; $FD $F5=PUSH PSW
	.asc	"OR ", '@'+$80		; $FD $F6=ORI
	.asc	"RST 30", 'H'+$80	; $FD $F7=RST 6
	.asc	"RET ", 'M'+$80		; $FD $F8=RM
	.asc	"LD SP, H", 'L'+$80	; $FD $F9=SPHL
	.asc	"JP M, ", '&'+$80	; $FD $FA=JM
	.asc	"E", 'I'+$80		; $FD $FB=EI
	.asc	"CALL M, ", '&'+$80	; $FD $FC=CM
	.asc	"?", ' '+$80		; $FD $FD=**IY+D**		** Z80 PREFIX **
	.asc	"CP ", '@'+$80		; $FD $FE=CPI
	.asc	"RST 38", 'H'+$80	; $FD $FF=RST 7

; *** remaining prefix COMBOS ***
; TO DO
