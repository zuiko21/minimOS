; minimOS opcode list for (dis)assembler modules
; (c) 2015-2020 Carlos J. Santisteban
; last modified 20200124-2154

; ***** for z80asm Z80 cross assembler *****
; *** DOCUMENTED opcodes only ***
; Opcode list as bit-7 terminated strings
; @ expects single byte, & expects word
; % expects RELATIVE addressing
; *** need some special characters for prefixes ***
; temporarily using *2, *4... (value + $80, not ASCII) for easier indexing
; 2@bits, 4@ix, 6@xtnd, 8@iy, 10@bits ix, 12@bits iy

; *************************************
; *** standard (unprefixed) opcodes *** @pointer table
; *************************************
z80_std:
; Z80 standard set, with 8085 mnemonics on comment
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
	.asc	"ADD A,(HL",')'+$80	; $86=ADD M
	.asc	"ADD A, ", 'A'+$80	; $87=ADD A
	.asc	"ADC A, ", 'B'+$80	; $88=ADC B
	.asc	"ADC A, ", 'C'+$80	; $89=ADC C
	.asc	"ADC A, ", 'D'+$80	; $8A=ADC D
	.asc	"ADC A, ", 'E'+$80	; $8B=ADC E
	.asc	"ADC A, ", 'H'+$80	; $8C=ADC H
	.asc	"ADC A, ", 'L'+$80	; $8D=ADC L
	.asc	"ADC A,(HL",')'+$80	; $8E=ADC M
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
	.asc	"SBC A,(HL",')'+$80	; $9E=SBB M
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
	.asc	'*', 2+$80			; $CB=...BITS	** Z80 PREFIX **
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
	.asc	'*', 4+$80			; $DD=...IX+D	** Z80 PREFIX **
	.asc	"SBA A, ", '@'+$80	; $DE=SBI
	.asc	"RST 18", 'H'+$80	; $DF=RST 3

	.asc	"RET P", 'O'+$80	; $E0=RPO
	.asc	"POP H", 'L'+$80	; $E1=POP H
	.asc	"JP PO, ", '&'+$80	; $E2=JPO
	.asc	"EX (SP),H",'L'+$80	; $E3=XTHL
	.asc	"CALL PO, ",'&'+$80	; $E4=CPO
	.asc	"PUSH H", 'L'+$80	; $E5=PUSH H
	.asc	"AND ", '@'+$80		; $E6=ANI
	.asc	"RST 20", 'H'+$80	; $E7=RST 4
	.asc	"RET P", 'E'+$80	; $E8=RPE
	.asc	"JP (HL", ')'+$80	; $E9=PCHL
	.asc	"JP PE, ", '&'+$80	; $EA=JPE
	.asc	"EX DE, H", 'L'+$80	; $EB=XCHG
	.asc	"CALL PE, ",'&'+$80	; $EC=CPE
	.asc	'*', 6+$80			; $ED=...EXTD	** Z80 PREFIX **
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
	.asc	'*', 8+$80			; $FD=...IY+D	** Z80 PREFIX **
	.asc	"CP ", '@'+$80		; $FE=CPI
	.asc	"RST 38", 'H'+$80	; $FF=RST 7

; *************************************
; *** BIT instructions ($CB prefix) *** @pointer table+2
; *************************************
z80_cb:
	.asc	"RLC ", 'B'+$80		; $CB $00=RLC B
	.asc	"RLC ", 'C'+$80		; $CB $01=RLC C
	.asc	"RLC ", 'D'+$80		; $CB $02=RLC D
	.asc	"RLC ", 'E'+$80		; $CB $03=RLC E
	.asc	"RLC ", 'H'+$80		; $CB $04=RLC H
	.asc	"RLC ", 'L'+$80		; $CB $05=RLC L
	.asc	"RLC (HL", ')'+$80	; $CB $06=RLC (HL)
	.asc	"RLC ", 'A'+$80		; $CB $07=RLC A
	.asc	"RRC ", 'B'+$80		; $CB $08=RRC B
	.asc	"RRC ", 'C'+$80		; $CB $09=RRC C
	.asc	"RRC ", 'D'+$80		; $CB $0A=RRC D
	.asc	"RRC ", 'E'+$80		; $CB $0B=RRC E
	.asc	"RRC ", 'H'+$80		; $CB $0C=RRC H
	.asc	"RRC ", 'L'+$80		; $CB $0D=RRC L
	.asc	"RRC (HL", ')'+$80	; $CB $0E=RRC (HL)
	.asc	"RRC ", 'A'+$80		; $CB $0F=RRC A

	.asc	"RL ", 'B'+$80		; $CB $10=RL B
	.asc	"RL ", 'C'+$80		; $CB $11=RL C
	.asc	"RL ", 'D'+$80		; $CB $12=RL D
	.asc	"RL ", 'E'+$80		; $CB $13=RL E
	.asc	"RL ", 'H'+$80		; $CB $14=RL H
	.asc	"RL ", 'L'+$80		; $CB $15=RL L
	.asc	"RL (HL", ')'+$80	; $CB $16=RL (HL)
	.asc	"RL ", 'A'+$80		; $CB $17=RL A
	.asc	"RR ", 'B'+$80		; $CB $18=RR B
	.asc	"RR ", 'C'+$80		; $CB $19=RR C
	.asc	"RR ", 'D'+$80		; $CB $1A=RR D
	.asc	"RR ", 'E'+$80		; $CB $1B=RR E
	.asc	"RR ", 'H'+$80		; $CB $1C=RR H
	.asc	"RR ", 'L'+$80		; $CB $1D=RR L
	.asc	"RR (HL", ')'+$80	; $CB $1E=RR (HL)
	.asc	"RR ", 'A'+$80		; $CB $1F=RR A

	.asc	"SLA ", 'B'+$80		; $CB $20=SLA B
	.asc	"SLA ", 'C'+$80		; $CB $21=SLA C
	.asc	"SLA ", 'D'+$80		; $CB $22=SLA D
	.asc	"SLA ", 'E'+$80		; $CB $23=SLA E
	.asc	"SLA ", 'H'+$80		; $CB $24=SLA H
	.asc	"SLA ", 'L'+$80		; $CB $25=SLA L
	.asc	"SLA (HL", ')'+$80	; $CB $26=SLA (HL)
	.asc	"SLA ", 'A'+$80		; $CB $27=SLA A
	.asc	"SRA ", 'B'+$80		; $CB $28=SRA B
	.asc	"SRA ", 'C'+$80		; $CB $29=SRA C
	.asc	"SRA ", 'D'+$80		; $CB $2A=SRA D
	.asc	"SRA ", 'E'+$80		; $CB $2B=SRA E
	.asc	"SRA ", 'H'+$80		; $CB $2C=SRA H
	.asc	"SRA ", 'L'+$80		; $CB $2D=SRA L
	.asc	"SRA (HL", ')'+$80	; $CB $2E=SRA (HL)
	.asc	"SRA ", 'A'+$80		; $CB $2F=SRA A

	.dsb	8, '?'+$80			; $CB30 ... $CB37 filler
	.asc	"SRL ", 'B'+$80		; $CB $38=SRL B
	.asc	"SRL ", 'C'+$80		; $CB $39=SRL C
	.asc	"SRL ", 'D'+$80		; $CB $3A=SRL D
	.asc	"SRL ", 'E'+$80		; $CB $3B=SRL E
	.asc	"SRL ", 'H'+$80		; $CB $3C=SRL H
	.asc	"SRL ", 'L'+$80		; $CB $3D=SRL L
	.asc	"SRL (HL", ')'+$80	; $CB $3E=SRL (HL)
	.asc	"SRL ", 'A'+$80		; $CB $3F=SRL A

	.asc	"BIT 0, ", 'B'+$80	; $CB $40=BIT 0, B
	.asc	"BIT 0, ", 'C'+$80	; $CB $41=BIT 0, C
	.asc	"BIT 0, ", 'D'+$80	; $CB $42=BIT 0, D
	.asc	"BIT 0, ", 'E'+$80	; $CB $43=BIT 0, E
	.asc	"BIT 0, ", 'H'+$80	; $CB $44=BIT 0, H
	.asc	"BIT 0, ", 'L'+$80	; $CB $45=BIT 0, L
	.asc	"BIT 0,(HL",')'+$80	; $CB $46=BIT 0,(HL)
	.asc	"BIT 0, ", 'A'+$80	; $CB $47=BIT 0, A
	.asc	"BIT 1, ", 'B'+$80	; $CB $48=BIT 1, B
	.asc	"BIT 1, ", 'C'+$80	; $CB $49=BIT 1, C
	.asc	"BIT 1, ", 'D'+$80	; $CB $4A=BIT 1, D
	.asc	"BIT 1, ", 'E'+$80	; $CB $4B=BIT 1, E
	.asc	"BIT 1, ", 'H'+$80	; $CB $4C=BIT 1, H
	.asc	"BIT 1, ", 'L'+$80	; $CB $4D=BIT 1, L
	.asc	"BIT 1,(HL",')'+$80	; $CB $4E=BIT 1,(HL)
	.asc	"BIT 1, ", 'A'+$80	; $CB $4F=BIT 1, A

	.asc	"BIT 2, ", 'B'+$80	; $CB $50=BIT 2, B
	.asc	"BIT 2, ", 'C'+$80	; $CB $51=BIT 2, C
	.asc	"BIT 2, ", 'D'+$80	; $CB $52=BIT 2, D
	.asc	"BIT 2, ", 'E'+$80	; $CB $53=BIT 2, E
	.asc	"BIT 2, ", 'H'+$80	; $CB $54=BIT 2, H
	.asc	"BIT 2, ", 'L'+$80	; $CB $55=BIT 2, L
	.asc	"BIT 2,(HL",')'+$80	; $CB $56=BIT 2,(HL)
	.asc	"BIT 2, ", 'A'+$80	; $CB $57=BIT 2, A
	.asc	"BIT 3, ", 'B'+$80	; $CB $58=BIT 3, B
	.asc	"BIT 3, ", 'C'+$80	; $CB $59=BIT 3, C
	.asc	"BIT 3, ", 'D'+$80	; $CB $5A=BIT 3, D
	.asc	"BIT 3, ", 'E'+$80	; $CB $5B=BIT 3, E
	.asc	"BIT 3, ", 'H'+$80	; $CB $5C=BIT 3, H
	.asc	"BIT 3, ", 'L'+$80	; $CB $5D=BIT 3, L
	.asc	"BIT 3,(HL",')'+$80	; $CB $5E=BIT 3,(HL)
	.asc	"BIT 3, ", 'A'+$80	; $CB $5F=BIT 3, A

	.asc	"BIT 4, ", 'B'+$80	; $CB $60=BIT 4, B
	.asc	"BIT 4, ", 'C'+$80	; $CB $61=BIT 4, C
	.asc	"BIT 4, ", 'D'+$80	; $CB $62=BIT 4, D
	.asc	"BIT 4, ", 'E'+$80	; $CB $63=BIT 4, E
	.asc	"BIT 4, ", 'H'+$80	; $CB $64=BIT 4, H
	.asc	"BIT 4, ", 'L'+$80	; $CB $65=BIT 4, L
	.asc	"BIT 4,(HL",')'+$80	; $CB $66=BIT 4,(HL)
	.asc	"BIT 4, ", 'A'+$80	; $CB $67=BIT 4, A
	.asc	"BIT 5, ", 'B'+$80	; $CB $68=BIT 5, B
	.asc	"BIT 5, ", 'C'+$80	; $CB $69=BIT 5, C
	.asc	"BIT 5, ", 'D'+$80	; $CB $6A=BIT 5, D
	.asc	"BIT 5, ", 'E'+$80	; $CB $6B=BIT 5, E
	.asc	"BIT 5, ", 'H'+$80	; $CB $6C=BIT 5, H
	.asc	"BIT 5, ", 'L'+$80	; $CB $6D=BIT 5, L
	.asc	"BIT 5,(HL",')'+$80	; $CB $6E=BIT 5,(HL)
	.asc	"BIT 5, ", 'A'+$80	; $CB $6F=BIT 5, A

	.asc	"BIT 6, ", 'B'+$80	; $CB $70=BIT 6, B
	.asc	"BIT 6, ", 'C'+$80	; $CB $71=BIT 6, C
	.asc	"BIT 6, ", 'D'+$80	; $CB $72=BIT 6, D
	.asc	"BIT 6, ", 'E'+$80	; $CB $73=BIT 6, E
	.asc	"BIT 6, ", 'H'+$80	; $CB $74=BIT 6, H
	.asc	"BIT 6, ", 'L'+$80	; $CB $75=BIT 6, L
	.asc	"BIT 6,(HL",')'+$80	; $CB $76=BIT 6,(HL)
	.asc	"BIT 6, ", 'A'+$80	; $CB $77=BIT 6, A
	.asc	"BIT 7, ", 'B'+$80	; $CB $78=BIT 7, B
	.asc	"BIT 7, ", 'C'+$80	; $CB $79=BIT 7, C
	.asc	"BIT 7, ", 'D'+$80	; $CB $7A=BIT 7, D
	.asc	"BIT 7, ", 'E'+$80	; $CB $7B=BIT 7, E
	.asc	"BIT 7, ", 'H'+$80	; $CB $7C=BIT 7, H
	.asc	"BIT 7, ", 'L'+$80	; $CB $7D=BIT 7, L
	.asc	"BIT 7,(HL",')'+$80	; $CB $7E=BIT 7,(HL)
	.asc	"BIT 7, ", 'A'+$80	; $CB $7F=BIT 7, A

	.asc	"RES 0, ", 'B'+$80	; $CB $80=RES 0, B
	.asc	"RES 0, ", 'C'+$80	; $CB $81=RES 0, C
	.asc	"RES 0, ", 'D'+$80	; $CB $82=RES 0, D
	.asc	"RES 0, ", 'E'+$80	; $CB $83=RES 0, E
	.asc	"RES 0, ", 'H'+$80	; $CB $84=RES 0, H
	.asc	"RES 0, ", 'L'+$80	; $CB $85=RES 0, L
	.asc	"RES 0,(HL",')'+$80	; $CB $86=RES 0,(HL)
	.asc	"RES 0, ", 'A'+$80	; $CB $87=RES 0, A
	.asc	"RES 1, ", 'B'+$80	; $CB $88=RES 1, B
	.asc	"RES 1, ", 'C'+$80	; $CB $89=RES 1, C
	.asc	"RES 1, ", 'D'+$80	; $CB $8A=RES 1, D
	.asc	"RES 1, ", 'E'+$80	; $CB $8B=RES 1, E
	.asc	"RES 1, ", 'H'+$80	; $CB $8C=RES 1, H
	.asc	"RES 1, ", 'L'+$80	; $CB $8D=RES 1, L
	.asc	"RES 1,(HL",')'+$80	; $CB $8E=RES 1,(HL)
	.asc	"RES 1, ", 'A'+$80	; $CB $8F=RES 1, A

	.asc	"RES 2, ", 'B'+$80	; $CB $90=RES 2, B
	.asc	"RES 2, ", 'C'+$80	; $CB $91=RES 2, C
	.asc	"RES 2, ", 'D'+$80	; $CB $92=RES 2, D
	.asc	"RES 2, ", 'E'+$80	; $CB $93=RES 2, E
	.asc	"RES 2, ", 'H'+$80	; $CB $94=RES 2, H
	.asc	"RES 2, ", 'L'+$80	; $CB $95=RES 2, L
	.asc	"RES 2,(HL",')'+$80	; $CB $96=RES 2,(HL)
	.asc	"RES 2, ", 'A'+$80	; $CB $97=RES 2, A
	.asc	"RES 3, ", 'B'+$80	; $CB $98=RES 3, B
	.asc	"RES 3, ", 'C'+$80	; $CB $99=RES 3, C
	.asc	"RES 3, ", 'D'+$80	; $CB $9A=RES 3, D
	.asc	"RES 3, ", 'E'+$80	; $CB $9B=RES 3, E
	.asc	"RES 3, ", 'H'+$80	; $CB $9C=RES 3, H
	.asc	"RES 3, ", 'L'+$80	; $CB $9D=RES 3, L
	.asc	"RES 3,(HL",')'+$80	; $CB $9E=RES 3,(HL)
	.asc	"RES 3, ", 'A'+$80	; $CB $9F=RES 3, A

	.asc	"RES 4, ", 'B'+$80	; $CB $A0=RES 4, B
	.asc	"RES 4, ", 'C'+$80	; $CB $A1=RES 4, C
	.asc	"RES 4, ", 'D'+$80	; $CB $A2=RES 4, D
	.asc	"RES 4, ", 'E'+$80	; $CB $A3=RES 4, E
	.asc	"RES 4, ", 'H'+$80	; $CB $A4=RES 4, H
	.asc	"RES 4, ", 'L'+$80	; $CB $A5=RES 4, L
	.asc	"RES 4,(HL",')'+$80	; $CB $A6=RES 4,(HL)
	.asc	"RES 4, ", 'A'+$80	; $CB $A7=RES 4, A
	.asc	"RES 5, ", 'B'+$80	; $CB $A8=RES 5, B
	.asc	"RES 5, ", 'C'+$80	; $CB $A9=RES 5, C
	.asc	"RES 5, ", 'D'+$80	; $CB $AA=RES 5, D
	.asc	"RES 5, ", 'E'+$80	; $CB $AB=RES 5, E
	.asc	"RES 5, ", 'H'+$80	; $CB $AC=RES 5, H
	.asc	"RES 5, ", 'L'+$80	; $CB $AD=RES 5, L
	.asc	"RES 5,(HL",')'+$80	; $CB $AE=RES 5,(HL)
	.asc	"RES 5, ", 'A'+$80	; $CB $AF=RES 5, A

	.asc	"RES 6, ", 'B'+$80	; $CB $B0=RES 6, B
	.asc	"RES 6, ", 'C'+$80	; $CB $B1=RES 6, C
	.asc	"RES 6, ", 'D'+$80	; $CB $B2=RES 6, D
	.asc	"RES 6, ", 'E'+$80	; $CB $B3=RES 6, E
	.asc	"RES 6, ", 'H'+$80	; $CB $B4=RES 6, H
	.asc	"RES 6, ", 'L'+$80	; $CB $B5=RES 6, L
	.asc	"RES 6,(HL",')'+$80	; $CB $B6=RES 6,(HL)
	.asc	"RES 6, ", 'A'+$80	; $CB $B7=RES 6, A
	.asc	"RES 7, ", 'B'+$80	; $CB $B8=RES 7, B
	.asc	"RES 7, ", 'C'+$80	; $CB $B9=RES 7, C
	.asc	"RES 7, ", 'D'+$80	; $CB $BA=RES 7, D
	.asc	"RES 7, ", 'E'+$80	; $CB $BB=RES 7, E
	.asc	"RES 7, ", 'H'+$80	; $CB $BC=RES 7, H
	.asc	"RES 7, ", 'L'+$80	; $CB $BD=RES 7, L
	.asc	"RES 7,(HL",')'+$80	; $CB $BE=RES 7,(HL)
	.asc	"RES 7, ", 'A'+$80	; $CB $BF=RES 7, A

	.asc	"SET 0, ", 'B'+$80	; $CB $C0=SET 0, B
	.asc	"SET 0, ", 'C'+$80	; $CB $C1=SET 0, C
	.asc	"SET 0, ", 'D'+$80	; $CB $C2=SET 0, D
	.asc	"SET 0, ", 'E'+$80	; $CB $C3=SET 0, E
	.asc	"SET 0, ", 'H'+$80	; $CB $C4=SET 0, H
	.asc	"SET 0, ", 'L'+$80	; $CB $C5=SET 0, L
	.asc	"SET 0,(HL",')'+$80	; $CB $C6=SET 0,(HL)
	.asc	"SET 0, ", 'A'+$80	; $CB $C7=SET 0, A
	.asc	"SET 1, ", 'B'+$80	; $CB $C8=SET 1, B
	.asc	"SET 1, ", 'C'+$80	; $CB $C9=SET 1, C
	.asc	"SET 1, ", 'D'+$80	; $CB $CA=SET 1, D
	.asc	"SET 1, ", 'E'+$80	; $CB $CB=SET 1, E
	.asc	"SET 1, ", 'H'+$80	; $CB $CC=SET 1, H
	.asc	"SET 1, ", 'L'+$80	; $CB $CD=SET 1, L
	.asc	"SET 1,(HL",')'+$80	; $CB $CE=SET 1,(HL)
	.asc	"SET 1, ", 'A'+$80	; $CB $CF=SET 1, A

	.asc	"SET 2, ", 'B'+$80	; $CB $D0=SET 2, B
	.asc	"SET 2, ", 'C'+$80	; $CB $D1=SET 2, C
	.asc	"SET 2, ", 'D'+$80	; $CB $D2=SET 2, D
	.asc	"SET 2, ", 'E'+$80	; $CB $D3=SET 2, E
	.asc	"SET 2, ", 'H'+$80	; $CB $D4=SET 2, H
	.asc	"SET 2, ", 'L'+$80	; $CB $D5=SET 2, L
	.asc	"SET 2,(HL",')'+$80	; $CB $D6=SET 2,(HL)
	.asc	"SET 2, ", 'A'+$80	; $CB $D7=SET 2, A
	.asc	"SET 3, ", 'B'+$80	; $CB $D8=SET 3, B
	.asc	"SET 3, ", 'C'+$80	; $CB $D9=SET 3, C
	.asc	"SET 3, ", 'D'+$80	; $CB $DA=SET 3, D
	.asc	"SET 3, ", 'E'+$80	; $CB $DB=SET 3, E
	.asc	"SET 3, ", 'H'+$80	; $CB $DC=SET 3, H
	.asc	"SET 3, ", 'L'+$80	; $CB $DD=SET 3, L
	.asc	"SET 3,(HL",')'+$80	; $CB $DE=SET 3,(HL)
	.asc	"SET 3, ", 'A'+$80	; $CB $DF=SET 3, A

	.asc	"SET 4, ", 'B'+$80	; $CB $E0=SET 4, B
	.asc	"SET 4, ", 'C'+$80	; $CB $E1=SET 4, C
	.asc	"SET 4, ", 'D'+$80	; $CB $E2=SET 4, D
	.asc	"SET 4, ", 'E'+$80	; $CB $E3=SET 4, E
	.asc	"SET 4, ", 'H'+$80	; $CB $E4=SET 4, H
	.asc	"SET 4, ", 'L'+$80	; $CB $E5=SET 4, L
	.asc	"SET 4,(HL",')'+$80	; $CB $E6=SET 4,(HL)
	.asc	"SET 4, ", 'A'+$80	; $CB $E7=SET 4, A
	.asc	"SET 5, ", 'B'+$80	; $CB $E8=SET 5, B
	.asc	"SET 5, ", 'C'+$80	; $CB $E9=SET 5, C
	.asc	"SET 5, ", 'D'+$80	; $CB $EA=SET 5, D
	.asc	"SET 5, ", 'E'+$80	; $CB $EB=SET 5, E
	.asc	"SET 5, ", 'H'+$80	; $CB $EC=SET 5, H
	.asc	"SET 5, ", 'L'+$80	; $CB $ED=SET 5, L
	.asc	"SET 5,(HL",')'+$80	; $CB $EE=SET 5,(HL)
	.asc	"SET 5, ", 'A'+$80	; $CB $EF=SET 5, A

	.asc	"SET 6, ", 'B'+$80	; $CB $F0=SET 6, B
	.asc	"SET 6, ", 'C'+$80	; $CB $F1=SET 6, C
	.asc	"SET 6, ", 'D'+$80	; $CB $F2=SET 6, D
	.asc	"SET 6, ", 'E'+$80	; $CB $F3=SET 6, E
	.asc	"SET 6, ", 'H'+$80	; $CB $F4=SET 6, H
	.asc	"SET 6, ", 'L'+$80	; $CB $F5=SET 6, L
	.asc	"SET 6,(HL",')'+$80	; $CB $F6=SET 6,(HL)
	.asc	"SET 6, ", 'A'+$80	; $CB $F7=SET 6, A
	.asc	"SET 7, ", 'B'+$80	; $CB $F8=SET 7, B
	.asc	"SET 7, ", 'C'+$80	; $CB $F9=SET 7, C
	.asc	"SET 7, ", 'D'+$80	; $CB $FA=SET 7, D
	.asc	"SET 7, ", 'E'+$80	; $CB $FB=SET 7, E
	.asc	"SET 7, ", 'H'+$80	; $CB $FC=SET 7, H
	.asc	"SET 7, ", 'L'+$80	; $CB $FD=SET 7, L
	.asc	"SET 7,(HL",')'+$80	; $CB $FE=SET 7,(HL)
	.asc	"SET 7, ", 'A'+$80	; $CB $FF=SET 7, A

; **********************************************
; *** IX+d indexed instructions ($DD prefix) *** @pointer table + 4
; **********************************************
z80_dd:
	.dsb	9, '?'+$80			; $DD00 ... $DD08 filler
	.asc	"ADD IX, B",'C'+$80	; $DD $09=ADD IX, BC

	.dsb	15, '?'+$80			; $DD0A ... $DD18 filler

	.asc	"ADD IX, D",'E'+$80	; $DD $19=ADD IX, DE

	.dsb	7, '?'+$80			; $DD1A ... $DD20 filler

	.asc	"LD IX, ", '&'+$80	; $DD $21=LD IX
	.asc	"LD (&), I",'X'+$80	; $DD $22=LD (**),IX
	.asc	"INC I", 'X'+$80	; $DD $23=INC IX
	.dsb	5, '?'+$80			; $DD24 ... $DD28 filler
	.asc	"ADD IX, I",'X'+$80	; $DD $29=ADD IX,IX
	.asc	"LD IX, (&",')'+$80	; $DD $2A=LD IX,(**)
	.asc	"DEC I", 'X'+$80	; $DD $2B=DEC IX

	.dsb	8, '?'+$80			; $DD2C ... $DD33 filler

	.asc	"INC (IX+@",')'+$80	; $DD $34=INC (IX+*)
	.asc	"DEC (IX+@",')'+$80	; $DD $35=DEC (IX+*)
	.asc	"LD (IX+@), ", $C0	; $DD $36=LD (IX+*),*	$C0 was '@'+$80
	.asc	2, '?'+$80			; $DD37 ... $DD38 filler
	.asc	"ADD IX, S",'P'+$80	; $DD $39=ADD IX,SP

	.asc	10, '?'+$80			; $DD3A ... $DD43 filler

	.asc	"LD B, IX", 'H'+$80	; $DD $44=LD B,IXH		UNDOCUMENTED!
	.asc	"LD B, IX", 'L'+$80	; $DD $45=LD B,IXL		UNDOCUMENTED!
	.asc	"LD B, (IX+@", $A9	; $DD $46=LD B,(IX+*)	$A9 was ')'+$80
	.asc	5, '?'+$80			; $DD47 ... $DD4B filler
	.asc	"LD C, IX", 'H'+$80	; $DD $4C=LD C,IXH		UNDOCUMENTED!
	.asc	"LD C, IX", 'L'+$80	; $DD $4D=LD C,IXL		UNDOCUMENTED!
	.asc	"LD C, (IX+@", $A9	; $DD $4E=LD C,(IX+*)	$A9 was ')'+$80

	.asc	5, '?'+$80			; $DD4F ... $DD53 filler

	.asc	"LD D, IX", 'H'+$80	; $DD $54=LD D,IXH		UNDOCUMENTED!
	.asc	"LD D, IX", 'L'+$80	; $DD $55=LD D,IXL		UNDOCUMENTED!
	.asc	"LD D, (IX+@", $A9	; $DD $56=LD D,(IX+*)	$A9 was ')'+$80
	.asc	5, '?'+$80			; $DD57 ... $DD5B filler
	.asc	"LD E, IX", 'H'+$80	; $DD $5C=LD E,IXH		UNDOCUMENTED!
	.asc	"LD E, IX", 'L'+$80	; $DD $5D=LD E,IXL		UNDOCUMENTED!
	.asc	"LD E, (IX+@", $A9	; $DD $5E=LD E,(IX+*)	$A9 was ')'+$80

	.asc	7, '?'+$80			; $DD5F ... $DD65 filler

	.asc	"LD H, (IX+@", $A9	; $DD $66=LD H,(IX+*)	$A9 was ')'+$80
	.asc	7, '?'+$80			; $DD67 ... $DD6D filler
	.asc	"LD L, (IX+@", $A9	; $DD $6E=LD L,(IX+*)	$A9 was ')'+$80
	.asc	'?'+$80				; $DD $6F

	.asc	"LD (IX+@),", $C2	; $DD $70=LD (IX+*),B	$C2 was 'B'+$80
	.asc	"LD (IX+@),", $C3	; $DD $71=LD (IX+*),C	$C3 was 'C'+$80
	.asc	"LD (IX+@),", $C4	; $DD $72=LD (IX+*),D	$C4 was 'D'+$80
	.asc	"LD (IX+@),", $C5	; $DD $73=LD (IX+*),E	$C5 was 'E'+$80
	.asc	"LD (IX+@),", $C8	; $DD $74=LD (IX+*),H	$C8 was 'H'+$80
	.asc	"LD (IX+@),", $CC	; $DD $75=LD (IX+*),L	$CC was 'L'+$80
	.asc	'?'+$80				; $DD $76
	.asc	"LD (IX+@),", $C1	; $DD $77=LD (IX+*),A	$C1 was 'A'+$80
	.asc	6, '?'+$80			; $DD78 ... $DD7D filler
	.asc	"LD A, (IX+@", $A9	; $DD $7E=LD A,(IX+*)	$A9 was ')'+$80

	.asc	7, '?'+$80			; $DD7F ... $DD85 filler

	.asc	"ADD A, (IX+@", $A9	; $DD $86=ADD A,(IX+*)	$A9 was ')'+$80
	.asc	7, '?'+$80			; $DD87 ... $DD8D filler
	.asc	"ADC A, (IX+@", $A9	; $DD $8E=ADC A,(IX+*)	$A9 was ')'+$80

	.asc	7, '?'+$80			; $DD8F ... $DD95 filler

	.asc	"SUB (IX+@",')'+$80	; $DD $96=SUB (IX+*)
	.asc	7, '?'+$80			; $DD97 ... $DD9D filler
	.asc	"SBC A, (IX+@", $A9	; $DD $9E=SBC A,(IX+*)	$A9 was ')'+$80

	.asc	7, '?'+$80			; $DD9F ... $DDA5 filler

	.asc	"AND (IX+@",')'+$80	; $DD $A6=AND (IX+*)
	.asc	7, '?'+$80			; $DDA7 ... $DDAD filler
	.asc	"XOR (IX+@",')'+$80	; $DD $AE=XOR (IX+*)

	.asc	7, '?'+$80			; $DDAF ... $DDB5 filler

	.asc	"OR (IX+@",')'+$80	; $DD $B6=OR (IX+*)
	.asc	7, '?'+$80			; $DDB7 ... $DDBD filler
	.asc	"CP (IX+@",')'+$80	; $DD $BE=CP (IX+*)

	.asc	12, '?'+$80			; $DDBF ... $DDCA filler

	.asc	'*', 10+$80			; $DD $CB=...IX BITS 	** Z80 PREFIXES **

	.asc	21, '?'+$80			; $DDCC ... $DDE0 filler

	.asc	"POP I", 'X'+$80	; $DD $E1=POP IX
	.asc	'?'+$80				; $DD $E2
	.asc	"EX (SP),I",'X'+$80	; $DD $E3=EX SP,IX
	.asc	'?'+$80				; $DD $E4
	.asc	"PUSH I", 'X'+$80	; $DD $E5=PUSH IX
	.asc	3, '?'+$80			; $DDE6 ... $DDE8 filler
	.asc	"JP (IX", ')'+$80	; $DD $E9=JMP (IX)

	.asc	15, '?'+$80			; $DDEA ... $DDF8 filler

	.asc	"LD SP, I", 'X'+$80	; $DD $F9=LD SP, IX
	.asc	6, '?'+$80			; $DDFA ... $DDFF filler

; ******************************************
; *** extended instructions ($ED prefix) *** @pointer table + 6
; ******************************************
z80_ed:
; needs to fill unused opcodes!
	.dsb	64, '?'+$80			; $ED00 ... $ED3F filler

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
	.asc	"NEG", '?'+$80		; $ED $4C=NEG			UNDOCUMENTED?
	.asc	"RET", 'I'+$80		; $ED $4D=RETI
	.asc	"IM 0/", '1'+$80	; $ED $4E=IM 0/1		UNDEFINED!
	.asc	"LD R, ", 'A'+$80	; $ED $4F=LD R, A

	.asc	"IN D, (C", ')'+$80	; $ED $50=IN D, (C)
	.asc	"OUT (C), ",'D'+$80	; $ED $51=OUT (C), D
	.asc	"SBC HL, D",'E'+$80	; $ED $52=SBC HL, DE
	.asc	"LD (&), D",'E'+$80	; $ED $53=LD (**), DE
	.asc	"NEG", '?'+$80		; $ED $54=NEG			UNDOCUMENTED?
	.asc	"RET", 'N'+$80		; $ED $55=RETN
	.asc	"IM ", '1'+$80		; $ED $56=IM 1
	.asc	"LD A, ", 'I'+$80	; $ED $57=LD A, I
	.asc	"IN E, (C", ')'+$80	; $ED $58=IN E, (C)
	.asc	"OUT (C), ",'E'+$80	; $ED $59=OUT (C), E
	.asc	"ADC HL, D",'E'+$80	; $ED $5A=ADC HL, DE
	.asc	"LD DE, (&",')'+$80	; $ED $5B=LD DE, (**)
	.asc	"NEG", '?'+$80		; $ED $5C=NEG			UNDOCUMENTED?
	.asc	"RET", 'N'+$80		; $ED $5D=RETN
	.asc	"IM ", '2'+$80		; $ED $5E=IM 2
	.asc	"LD A, ", 'R'+$80	; $ED $5F=LD A, R

	.asc	"IN H, (C", ')'+$80	; $ED $60=IN H, (C)
	.asc	"OUT (C), ",'H'+$80	; $ED $61=OUT (C), H
	.asc	"SBC HL, H",'L'+$80	; $ED $62=SBC HL, HL
	.asc	"LD (&), H",'L'+$80	; $ED $63=LD (**), HL	UNDOCUMENTED?
	.asc	"NEG", '?'+$80		; $ED $64=NEG			UNDOCUMENTED?
	.asc	"RET", 'N'+$80		; $ED $65=RETN
	.asc	"IM", '0'+$80		; $ED $66=IM 0
	.asc	"RR", 'D'+$80		; $ED $67=RRD
	.asc	"IN L, (C", ')'+$80	; $ED $68=IN L, (C)
	.asc	"OUT (C), ",'L'+$80	; $ED $69=OUT (C), L
	.asc	"ADC HL, H",'L'+$80	; $ED $6A=ADC HL, HL
	.asc	"LD HL, (&",')'+$80	; $ED $6B=LD HL, (**)	UNDOCUMENTED?
	.asc	"NEG", '?'+$80		; $ED $6C=NEG			UNDOCUMENTED?
	.asc	"RET", 'N'+$80		; $ED $6D=RETN
	.asc	"IM 0/", '1'+$80	; $ED $6E=IM O/1		UNDEFINED!
	.asc	"RL", 'D'+$80		; $ED $6F=RLD

	.asc	"IN (C", ')'+$80	; $ED $70=IN (C)		UNDOCUMENTED?
	.asc	"OUT (C), ",'0'+$80	; $ED $71=OUT (C), 0	UNDOCUMENTED?
	.asc	"SBC HL, S",'P'+$80	; $ED $72=SBC HL, SP
	.asc	"LD (&), S",'P'+$80	; $ED $73=LD (**), SP
	.asc	"NEG", '?'+$80		; $ED $74=NEG			UNDOCUMENTED?
	.asc	"RET", 'N'+$80		; $ED $75=RETN
	.asc	"IM ", '1'+$80		; $ED $76=IM 1
	.asc	'?'+$80				; $ED $77
	.asc	"IN A, (C", ')'+$80	; $ED $78=IN A, (C)
	.asc	"OUT (C), ",'A'+$80	; $ED $79=OUT (C), A
	.asc	"ADC HL, S",'P'+$80	; $ED $7A=ADC HL, SP
	.asc	"LD SP, (&",')'+$80	; $ED $7B=LD SP, (**)
	.asc	"NEG", '?'+$80		; $ED $7C=NEG			UNDOCUMENTED?
	.asc	"RET", 'N'+$80		; $ED $7D=RETN
	.asc	"IM ",'2'+$80		; $ED $7E=IM 2
	.asc	'?'+$80				; $ED $7F

	.dsb	32, '?'+$80			; $ED80 ... $ED9F filler

	.asc	"LD", 'I'+$80		; $ED $A0=LDI
	.asc	"CP", 'I'+$80		; $ED $A1=CPI
	.asc	"IN", 'I'+$80		; $ED $A2=INI
	.asc	"OUT", 'I'+$80		; $ED $A3=OUTI
	.asc	'?'+$80				; $ED $A4
	.asc	'?'+$80				; $ED $A5
	.asc	'?'+$80				; $ED $A6
	.asc	'?'+$80				; $ED $A7
	.asc	"LD", 'D'+$80		; $ED $A8=LDD
	.asc	"CP", 'D'+$80		; $ED $A9=CPD
	.asc	"IN", 'D'+$80		; $ED $AA=IND
	.asc	"OUT", 'D'+$80		; $ED $AB=OUTD
	.asc	'?'+$80				; $ED $AC
	.asc	'?'+$80				; $ED $AD
	.asc	'?'+$80				; $ED $AE
	.asc	'?'+$80				; $ED $AF

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

	.dsb	64, '?'+$80			; $EDC0 ... $EDFF filler

; **********************************************
; *** IY+d indexed instructions ($FD prefix) *** @pointer table + 8
; **********************************************
z80_fd:
	.dsb	9, '?'+$80			; $FD00 ... $FD08 filler
	.asc	"ADD IY, B",'C'+$80	; $FD $09=ADD IY, BC
	.dsb	6, '?'+$80			; $FD0A ... $FD0F filler

	.dsb	9, '?'+$80			; $FD10 ... $FD18 filler
	.asc	"ADD IY, D",'E'+$80	; $FD $19=ADD IY, DE
	.dsb	6, '?'+$80			; $FD1A ... $FD1F filler

	.asc	'?'+$80				; $FD $20
	.asc	"LD IY, ", '&'+$80	; $FD $21=LD IY
	.asc	"LD (&), I",'Y'+$80	; $FD $22=LD (**),IY
	.asc	"INC I", 'Y'+$80	; $FD $23=INC IY
	.asc	"INC IY", 'H'+$80	; $FD $24=INC IYH		UNDOCUMENTED!
	.asc	"DEC IY", 'H'+$80	; $FD $25=DEC IYH		UNDOCUMENTED!
	.asc	"LD IYH, ", '@'+$80	; $FD $26=LD IYH,*		UNDOCUMENTED!
	.asc	'?'+$80				; $FD $27
	.asc	'?'+$80				; $FD $28
	.asc	"ADD IY, I",'Y'+$80	; $FD $29=ADD IY,IY
	.asc	"LD IY, (&",')'+$80	; $FD $2A=LD IY,(**)
	.asc	"DEC I", 'Y'+$80	; $FD $2B=DEC IY
	.asc	"INC IY", 'L'+$80	; $FD $2C=INC IYL		UNDOCUMENTED!
	.asc	"DEC IY", 'L'+$80	; $FD $2D=DEC IYL		UNDOCUMENTED!
	.asc	"LD IYL, ", '@'+$80	; $FD $2E=LD IYL,*		UNDOCUMENTED!
	.asc	'?'+$80				; $FD $2F

	.asc	4, '?'+$80			; $FD30 ... $FD33 filler
	.asc	"INC (IY+@",')'+$80	; $FD $34=INC (IY+*)
	.asc	"DEC (IY+@",')'+$80	; $FD $35=DEC (IY+*)
	.asc	"LD (IY+@), ", $C0	; $FD $36=LD (IY+*),*	$C0 was '@'+$80
	.asc	2, '?'+$80			; $FD37 ... $FD38 filler
	.asc	"ADD IY, S",'P'+$80	; $FD $39=ADD IY,SP
	.asc	6, '?'+$80			; $FD3A ... $FD3F filler

	.asc	4, '?'+$80			; $FD40 ... $FD43 filler
	.asc	"LD B, IY", 'H'+$80	; $FD $44=LD B,IYH		UNDOCUMENTED!
	.asc	"LD B, IY", 'L'+$80	; $FD $45=LD B,IYL		UNDOCUMENTED!
	.asc	"LD B, (IY+@", $A9	; $FD $46=LD B,(IY+*)	$A9 was ')'+$80
	.asc	5, '?'+$80			; $FD47 ... $FD4B filler
	.asc	"LD C, IY", 'H'+$80	; $FD $4C=LD C,IYH		UNDOCUMENTED!
	.asc	"LD C, IY", 'L'+$80	; $FD $4D=LD C,IYL		UNDOCUMENTED!
	.asc	"LD C, (IY+@", $A9	; $FD $4E=LD C,(IY+*)	$A9 was ')'+$80
	.asc	'?'+$80				; $FD $4F

	.asc	4, '?'+$80			; $FD50 ... $FD53 filler
	.asc	"LD D, IY", 'H'+$80	; $FD $54=LD D,IYH		UNDOCUMENTED!
	.asc	"LD D, IY", 'L'+$80	; $FD $55=LD D,IYL		UNDOCUMENTED!
	.asc	"LD D, (IY+@", $A9	; $FD $56=LD D,(IY+*)	$A9 was ')'+$80
	.asc	5, '?'+$80			; $FD57 ... $FD5B filler
	.asc	"LD E, IY", 'H'+$80	; $FD $5C=LD E,IYH		UNDOCUMENTED!
	.asc	"LD E, IY", 'L'+$80	; $FD $5D=LD E,IYL		UNDOCUMENTED!
	.asc	"LD E, (IY+@", $A9	; $FD $5E=LD E,(IY+*)	$A9 was ')'+$80
	.asc	'?'+$80				; $FD $5F

	.asc	"LD IYH, ", 'B'+$80	; $FD $60=LD IYH,B		UNDOCUMENTED!
	.asc	"LD IYH, ", 'C'+$80	; $FD $61=LD IYH,C		UNDOCUMENTED!
	.asc	"LD IYH, ", 'D'+$80	; $FD $62=LD IYH,D		UNDOCUMENTED!
	.asc	"LD IYH, ", 'E'+$80	; $FD $63=LD IYH,E		UNDOCUMENTED!
	.asc	"LD IYH, ", 'H'+$80	; $FD $64=LD IYH,H		UNDOCUMENTED!
	.asc	"LD IYH, ", 'L'+$80	; $FD $65=LD IYH,L		UNDOCUMENTED!
	.asc	"LD H, (IY+@", $A9	; $FD $66=LD H,(IY+*)	$A9 was ')'+$80
	.asc	"LD IYH, ", 'A'+$80	; $FD $67=LD IYH,A		UNDOCUMENTED!
	.asc	"LD IYL, ", 'B'+$80	; $FD $68=LD IYL,B		UNDOCUMENTED!
	.asc	"LD IYL, ", 'C'+$80	; $FD $69=LD IYL,C		UNDOCUMENTED!
	.asc	"LD IYL, ", 'D'+$80	; $FD $6A=LD IYL,D		UNDOCUMENTED!
	.asc	"LD IYL, ", 'E'+$80	; $FD $6B=LD IYL,E		UNDOCUMENTED!
	.asc	"LD IYL, ", 'H'+$80	; $FD $6C=LD IYL,H		UNDOCUMENTED!
	.asc	"LD IYL, ", 'L'+$80	; $FD $6D=LD IYL,L		UNDOCUMENTED!
	.asc	"LD L, (IY+@", $A9	; $FD $6E=LD L,(IY+*)	$A9 was ')'+$80
	.asc	"LD IYL, ", 'A'+$80	; $FD $6F=LD IYL,A		UNDOCUMENTED!

	.asc	"LD (IY+@),", $C2	; $FD $70=LD (IY+*),B	$C2 was 'B'+$80
	.asc	"LD (IY+@),", $C3	; $FD $71=LD (IY+*),C	$C3 was 'C'+$80
	.asc	"LD (IY+@),", $C4	; $FD $72=LD (IY+*),D	$C4 was 'D'+$80
	.asc	"LD (IY+@),", $C5	; $FD $73=LD (IY+*),E	$C5 was 'E'+$80
	.asc	"LD (IY+@),", $C8	; $FD $74=LD (IY+*),H	$C8 was 'H'+$80
	.asc	"LD (IY+@),", $CC	; $FD $75=LD (IY+*),L	$CC was 'L'+$80
	.asc	'?'+$80				; $FD $76
	.asc	"LD (IY+@),", $C1	; $FD $77=LD (IY+*),A	$C1 was 'A'+$80
	.asc	4, '?'+$80			; $FD78 ... $FD7B filler
	.asc	"LD A, IY", 'H'+$80	; $FD $7C=LD A,IYH		UNDOCUMENTED!
	.asc	"LD A, IY", 'L'+$80	; $FD $7D=LD A,IYL		UNDOCUMENTED!
	.asc	"LD A, (IY+@", $A9	; $FD $7E=LD A,(IY+*)	$A9 was ')'+$80
	.asc	'?'+$80				; $FD $7F

	.asc	4, '?'+$80			; $FD80 ... $FD83 filler
	.asc	"ADD A, IY",'H'+$80	; $FD $84=ADD A,IYH		UNDOCUMENTED!
	.asc	"ADD A, IY",'L'+$80	; $FD $85=ADD A,IYL		UNDOCUMENTED!
	.asc	"ADD A, (IY+@", $A9	; $FD $86=ADD A,(IY+*)	$A9 was ')'+$80
	.asc	5, '?'+$80			; $FD87 ... $FD8B filler
	.asc	"ADC A, IY",'H'+$80	; $FD $8C=ADC A,IYH		UNDOCUMENTED!
	.asc	"ADC A, IY",'L'+$80	; $FD $8D=ADC A,IYL		UNDOCUMENTED!
	.asc	"ADC A, (IY+@", $A9	; $FD $8E=ADC A,(IY+*)	$A9 was ')'+$80
	.asc	'?'+$80				; $FD $8F

	.asc	4, '?'+$80			; $FD90 ... $FD93 filler
	.asc	"SUB IY", 'H'+$80	; $FD $94=SUB IYH		UNDOCUMENTED!
	.asc	"SUB IY", 'L'+$80	; $FD $95=SUB IYL		UNDOCUMENTED!
	.asc	"SUB (IY+@",')'+$80	; $FD $96=SUB (IY+*)
	.asc	5, '?'+$80			; $FD97 ... $FD9B filler
	.asc	"SBC A, IY",'H'+$80	; $FD $9C=SBC A,IYH		UNDOCUMENTED!
	.asc	"SBC A, IY",'L'+$80	; $FD $9D=SBC A,IYL		UNDOCUMENTED!
	.asc	"SBC A, (IY+@", $A9	; $FD $9E=SBC A,(IY+*)	$A9 was ')'+$80
	.asc	'?'+$80				; $FD $9F

	.asc	4, '?'+$80			; $FDA0 ... $FDA3 filler
	.asc	"AND IY", 'H'+$80	; $FD $A4=AND IYH		UNDOCUMENTED!
	.asc	"AND IY", 'L'+$80	; $FD $A5=AND IYL		UNDOCUMENTED!
	.asc	"AND (IY+@",')'+$80	; $FD $A6=AND (IY+*)
	.asc	5, '?'+$80			; $FDA7 ... $FDAB filler
	.asc	"XOR IY", 'H'+$80	; $FD $AC=XOR IYH		UNDOCUMENTED!
	.asc	"XOR IY", 'L'+$80	; $FD $AD=XOR IYL		UNDOCUMENTED!
	.asc	"XOR (IY+@",')'+$80	; $FD $AE=XOR (IY+*)
	.asc	'?'+$80				; $FD $AF

	.asc	4, '?'+$80			; $FDB0 ... $FDB3 filler
	.asc	"OR IY", 'H'+$80	; $FD $B4=OR IYH		UNDOCUMENTED!
	.asc	"OR IY", 'L'+$80	; $FD $B5=OR IYL		UNDOCUMENTED!
	.asc	"OR (IY+@",')'+$80	; $FD $B6=OR (IY+*)
	.asc	5, '?'+$80			; $FDB7 ... $FDBB filler
	.asc	"CP IY", 'H'+$80	; $FD $BC=CP IYH		UNDOCUMENTED!
	.asc	"CP IY", 'L'+$80	; $FD $BD=CP IYL		UNDOCUMENTED!
	.asc	"CP (IY+@",')'+$80	; $FD $BE=CP (IY+*)
	.asc	'?'+$80				; $FD $BF

	.asc	11, '?'+$80			; $FDC0 ... $FDCA filler
	.asc	'*', 10+$80			; $FD $CB=...IY BITS 	** Z80 PREFIYES **
	.asc	4, '?'+$80			; $FDCC ... $FDCF filler

	.asc	16, '?'+$80			; $FDD0 ... $FDDF filler

	.asc	'?'+$80				; $FD $E0
	.asc	"POP I", 'Y'+$80	; $FD $E1=POP IY
	.asc	'?'+$80				; $FD $E2
	.asc	"EX (SP),I",'Y'+$80	; $FD $E3=EX SP,IY
	.asc	'?'+$80				; $FD $E4
	.asc	"PUSH I", 'Y'+$80	; $FD $E5=PUSH IY
	.asc	3, '?'+$80			; $FDE6 ... $FDE8 filler
	.asc	"JP (IY", ')'+$80	; $FD $E9=JMP (IY)
	.asc	6, '?'+$80			; $FDEA ... $FDEF filler

	.asc	9, '?'+$80			; $FDF0 ... $FDF8 filler
	.asc	"LD SP, I", 'Y'+$80	; $FD $F9=LD SP, IY
	.asc	6, '?'+$80			; $FDFA ... $FDFF filler

; ****************************************************
; *** IX+d indexed BIT instructions ($DDCB prefix) *** @pointer table + 10!
; ****************************************************
z80_ddcb:
	.asc	"RLC (IX+@), ", $C2	; $DD $CB $00=RLC (IX+*),B	UNDOCUMENTED
	.asc	"RLC (IX+@), ", $C3	; $DD $CB $01=RLC (IX+*),C	UNDOCUMENTED
	.asc	"RLC (IX+@), ", $C4	; $DD $CB $02=RLC (IX+*),D	UNDOCUMENTED
	.asc	"RLC (IX+@), ", $C5	; $DD $CB $03=RLC (IX+*),E	UNDOCUMENTED
	.asc	"RLC (IX+@), ", $C8	; $DD $CB $04=RLC (IX+*),H	UNDOCUMENTED
	.asc	"RLC (IX+@), ", $CC	; $DD $CB $05=RLC (IX+*),L	UNDOCUMENTED
	.asc	"RLC (IX+@",')'+$80	; $DD $CB $06=RLC (IX+*)
	.asc	"RLC (IX+@), ", $C1	; $DD $CB $07=RLC (IX+*),A	UNDOCUMENTED
	.asc	"RRC (IX+@), ", $C2	; $DD $CB $08=RRC (IX+*),B	UNDOCUMENTED
	.asc	"RRC (IX+@), ", $C3	; $DD $CB $09=RRC (IX+*),C	UNDOCUMENTED
	.asc	"RRC (IX+@), ", $C4	; $DD $CB $0A=RRC (IX+*),D	UNDOCUMENTED
	.asc	"RRC (IX+@), ", $C5	; $DD $CB $0B=RRC (IX+*),E	UNDOCUMENTED
	.asc	"RRC (IX+@), ", $C8	; $DD $CB $0C=RRC (IX+*),H	UNDOCUMENTED
	.asc	"RRC (IX+@), ", $CC	; $DD $CB $0D=RRC (IX+*),L	UNDOCUMENTED
	.asc	"RRC (IX+@",')'+$80	; $DD $CB $0E=RRC (IX+*)
	.asc	"RRC (IX+@), ", $C1	; $DD $CB $0F=RRC (IX+*),A	UNDOCUMENTED

	.asc	"RL (IX+@), ", $C2	; $DD $CB $10=RL (IX+*),B	UNDOCUMENTED
	.asc	"RL (IX+@), ", $C3	; $DD $CB $11=RL (IX+*),C	UNDOCUMENTED
	.asc	"RL (IX+@), ", $C4	; $DD $CB $12=RL (IX+*),D	UNDOCUMENTED
	.asc	"RL (IX+@), ", $C5	; $DD $CB $13=RL (IX+*),E	UNDOCUMENTED
	.asc	"RL (IX+@), ", $C8	; $DD $CB $14=RL (IX+*),H	UNDOCUMENTED
	.asc	"RL (IX+@), ", $CC	; $DD $CB $15=RL (IX+*),L	UNDOCUMENTED
	.asc	"RL (IX+@",')'+$80	; $DD $CB $16=RL (IX+*)
	.asc	"RL (IX+@), ", $C1	; $DD $CB $17=RL (IX+*),A	UNDOCUMENTED
	.asc	"RR (IX+@), ", $C2	; $DD $CB $18=RR (IX+*),B	UNDOCUMENTED
	.asc	"RR (IX+@), ", $C3	; $DD $CB $19=RR (IX+*),C	UNDOCUMENTED
	.asc	"RR (IX+@), ", $C4	; $DD $CB $1A=RR (IX+*),D	UNDOCUMENTED
	.asc	"RR (IX+@), ", $C5	; $DD $CB $1B=RR (IX+*),E	UNDOCUMENTED
	.asc	"RR (IX+@), ", $C8	; $DD $CB $1C=RR (IX+*),H	UNDOCUMENTED
	.asc	"RR (IX+@), ", $CC	; $DD $CB $1D=RR (IX+*),L	UNDOCUMENTED
	.asc	"RR (IX+@",')'+$80	; $DD $CB $1E=RR (IX+*)
	.asc	"RR (IX+@), ", $C1	; $DD $CB $1F=RR (IX+*),A	UNDOCUMENTED

	.asc	"SLA (IX+@), ", $C2	; $DD $CB $20=SLA(IX+*),B	UNDOCUMENTED
	.asc	"SLA (IX+@), ", $C3	; $DD $CB $21=SLA(IX+*),C	UNDOCUMENTED
	.asc	"SLA (IX+@), ", $C4	; $DD $CB $22=SLA(IX+*),D	UNDOCUMENTED
	.asc	"SLA (IX+@), ", $C5	; $DD $CB $23=SLA(IX+*),E	UNDOCUMENTED
	.asc	"SLA (IX+@), ", $C8	; $DD $CB $24=SLA(IX+*),H	UNDOCUMENTED
	.asc	"SLA (IX+@), ", $CC	; $DD $CB $25=SLA(IX+*),L	UNDOCUMENTED
	.asc	"SLA (IX+@",')'+$80	; $DD $CB $26=SLA (IX+*)
	.asc	"SLA (IX+@), ", $C1	; $DD $CB $27=SLA(IX+*),A	UNDOCUMENTED
	.asc	"SRA (IX+@), ", $C2	; $DD $CB $28=SRA(IX+*),B	UNDOCUMENTED
	.asc	"SRA (IX+@), ", $C3	; $DD $CB $29=SRA(IX+*),C	UNDOCUMENTED
	.asc	"SRA (IX+@), ", $C4	; $DD $CB $2A=SRA(IX+*),D	UNDOCUMENTED
	.asc	"SRA (IX+@), ", $C5	; $DD $CB $2B=SRA(IX+*),E	UNDOCUMENTED
	.asc	"SRA (IX+@), ", $C8	; $DD $CB $2C=SRA(IX+*),H	UNDOCUMENTED
	.asc	"SRA (IX+@), ", $CC	; $DD $CB $2D=SRA(IX+*),L	UNDOCUMENTED
	.asc	"SRA (IX+@",')'+$80	; $DD $CB $2E=SRA (IX+*)
	.asc	"SRA (IX+@), ", $C1	; $DD $CB $2F=SRA(IX+*),A	UNDOCUMENTED

	.asc	"SLL (IX+@), ", $C2	; $DD $CB $30=SLL(IX+*),B	UNDOCUMENTED
	.asc	"SLL (IX+@), ", $C3	; $DD $CB $31=SLL(IX+*),C	UNDOCUMENTED
	.asc	"SLL (IX+@), ", $C4	; $DD $CB $32=SLL(IX+*),D	UNDOCUMENTED
	.asc	"SLL (IX+@), ", $C5	; $DD $CB $33=SLL(IX+*),E	UNDOCUMENTED
	.asc	"SLL (IX+@), ", $C8	; $DD $CB $34=SLL(IX+*),H	UNDOCUMENTED
	.asc	"SLL (IX+@), ", $CC	; $DD $CB $35=SLL(IX+*),L	UNDOCUMENTED
	.asc	"SLL (IX+@",')'+$80	; $DD $CB $36=SLL (IX+*)	UNDOCUMENTED!
	.asc	"SLL (IX+@), ", $C1	; $DD $CB $37=SLL(IX+*),A	UNDOCUMENTED
	.asc	"SRL (IX+@), ", $C2	; $DD $CB $38=SRL(IX+*),B	UNDOCUMENTED
	.asc	"SRL (IX+@), ", $C3	; $DD $CB $39=SRL(IX+*),C	UNDOCUMENTED
	.asc	"SRL (IX+@), ", $C4	; $DD $CB $3A=SRL(IX+*),D	UNDOCUMENTED
	.asc	"SRL (IX+@), ", $C5	; $DD $CB $3B=SRL(IX+*),E	UNDOCUMENTED
	.asc	"SRL (IX+@), ", $C8	; $DD $CB $3C=SRL(IX+*),H	UNDOCUMENTED
	.asc	"SRL (IX+@), ", $CC	; $DD $CB $3D=SRL(IX+*),L	UNDOCUMENTED
	.asc	"SRL (IX+@",')'+$80	; $DD $CB $3E=SRL (IX+*)
	.asc	"SRL (IX+@), ", $C1	; $DD $CB $3F=SRL(IX+*),A	UNDOCUMENTED

	.asc	"BIT 0, (IX+@", $A9	; $DD $CB $40=BIT 0,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 0, (IX+@", $A9	; $DD $CB $41=BIT 0,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 0, (IX+@", $A9	; $DD $CB $42=BIT 0,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 0, (IX+@", $A9	; $DD $CB $43=BIT 0,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 0, (IX+@", $A9	; $DD $CB $44=BIT 0,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 0, (IX+@", $A9	; $DD $CB $45=BIT 0,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 0, (IX+@", $A9	; $DD $CB $46=BIT 0,(IX+*)					$A9 was ')'+$80
	.asc	"BIT 0, (IX+@", $A9	; $DD $CB $47=BIT 0,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 1, (IX+@", $A9	; $DD $CB $48=BIT 1,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 1, (IX+@", $A9	; $DD $CB $49=BIT 1,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 1, (IX+@", $A9	; $DD $CB $4A=BIT 1,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 1, (IX+@", $A9	; $DD $CB $4B=BIT 1,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 1, (IX+@", $A9	; $DD $CB $4C=BIT 1,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 1, (IX+@", $A9	; $DD $CB $4D=BIT 1,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 1, (IX+@", $A9	; $DD $CB $4E=BIT 1,(IX+*)					$A9 was ')'+$80
	.asc	"BIT 1, (IX+@", $A9	; $DD $CB $4F=BIT 1,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80

	.asc	"BIT 2, (IX+@", $A9	; $DD $CB $50=BIT 2,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 2, (IX+@", $A9	; $DD $CB $51=BIT 2,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 2, (IX+@", $A9	; $DD $CB $52=BIT 2,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 2, (IX+@", $A9	; $DD $CB $53=BIT 2,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 2, (IX+@", $A9	; $DD $CB $54=BIT 2,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 2, (IX+@", $A9	; $DD $CB $55=BIT 2,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 2, (IX+@", $A9	; $DD $CB $56=BIT 2,(IX+*)					$A9 was ')'+$80
	.asc	"BIT 2, (IX+@", $A9	; $DD $CB $57=BIT 2,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 3, (IX+@", $A9	; $DD $CB $58=BIT 3,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 3, (IX+@", $A9	; $DD $CB $59=BIT 3,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 3, (IX+@", $A9	; $DD $CB $5A=BIT 3,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 3, (IX+@", $A9	; $DD $CB $5B=BIT 3,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 3, (IX+@", $A9	; $DD $CB $5C=BIT 3,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 3, (IX+@", $A9	; $DD $CB $5D=BIT 3,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 3, (IX+@", $A9	; $DD $CB $5E=BIT 3,(IX+*)					$A9 was ')'+$80
	.asc	"BIT 3, (IX+@", $A9	; $DD $CB $5F=BIT 3,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80

	.asc	"BIT 4, (IX+@", $A9	; $DD $CB $60=BIT 4,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 4, (IX+@", $A9	; $DD $CB $61=BIT 4,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 4, (IX+@", $A9	; $DD $CB $62=BIT 4,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 4, (IX+@", $A9	; $DD $CB $63=BIT 4,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 4, (IX+@", $A9	; $DD $CB $64=BIT 4,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 4, (IX+@", $A9	; $DD $CB $65=BIT 4,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 4, (IX+@", $A9	; $DD $CB $66=BIT 4,(IX+*)					$A9 was ')'+$80
	.asc	"BIT 4, (IX+@", $A9	; $DD $CB $67=BIT 4,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 5, (IX+@", $A9	; $DD $CB $68=BIT 5,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 5, (IX+@", $A9	; $DD $CB $69=BIT 5,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 5, (IX+@", $A9	; $DD $CB $6A=BIT 5,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 5, (IX+@", $A9	; $DD $CB $6B=BIT 5,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 5, (IX+@", $A9	; $DD $CB $6C=BIT 5,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 5, (IX+@", $A9	; $DD $CB $6D=BIT 5,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 5, (IX+@", $A9	; $DD $CB $6E=BIT 5,(IX+*)					$A9 was ')'+$80
	.asc	"BIT 5, (IX+@", $A9	; $DD $CB $6F=BIT 5,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80

	.asc	"BIT 6, (IX+@", $A9	; $DD $CB $70=BIT 6,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 6, (IX+@", $A9	; $DD $CB $71=BIT 6,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 6, (IX+@", $A9	; $DD $CB $72=BIT 6,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 6, (IX+@", $A9	; $DD $CB $73=BIT 6,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 6, (IX+@", $A9	; $DD $CB $74=BIT 6,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 6, (IX+@", $A9	; $DD $CB $75=BIT 6,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 6, (IX+@", $A9	; $DD $CB $76=BIT 6,(IX+*)					$A9 was ')'+$80
	.asc	"BIT 6, (IX+@", $A9	; $DD $CB $77=BIT 6,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 7, (IX+@", $A9	; $DD $CB $78=BIT 7,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 7, (IX+@", $A9	; $DD $CB $79=BIT 7,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 7, (IX+@", $A9	; $DD $CB $7A=BIT 7,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 7, (IX+@", $A9	; $DD $CB $7B=BIT 7,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 7, (IX+@", $A9	; $DD $CB $7C=BIT 7,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 7, (IX+@", $A9	; $DD $CB $7D=BIT 7,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 7, (IX+@", $A9	; $DD $CB $7E=BIT 7,(IX+*)					$A9 was ')'+$80
	.asc	"BIT 7, (IX+@", $A9	; $DD $CB $7F=BIT 7,(IX+*)	UNDOCUMENTED	$A9 was ')'+$80

	.asc	"RES 0,(IX+@),",$C2	; $DD $CB $80=RES 0,(IX+*),B	UNDOCUMENTED
	.asc	"RES 0,(IX+@),",$C3	; $DD $CB $81=RES 0,(IX+*),C	UNDOCUMENTED
	.asc	"RES 0,(IX+@),",$C4	; $DD $CB $82=RES 0,(IX+*),D	UNDOCUMENTED
	.asc	"RES 0,(IX+@),",$C5	; $DD $CB $83=RES 0,(IX+*),E	UNDOCUMENTED
	.asc	"RES 0,(IX+@),",$C8	; $DD $CB $84=RES 0,(IX+*),H	UNDOCUMENTED
	.asc	"RES 0,(IX+@),",$CC	; $DD $CB $85=RES 0,(IX+*),L	UNDOCUMENTED
	.asc	"RES 0, (IX+@", $A9	; $DD $CB $86=RES 0,(IX+*)		$A9 was ')'+$80
	.asc	"RES 0,(IX+@),",$C1	; $DD $CB $87=RES 0,(IX+*),A	UNDOCUMENTED
	.asc	"RES 1,(IX+@),",$C2	; $DD $CB $88=RES 1,(IX+*),B	UNDOCUMENTED
	.asc	"RES 1,(IX+@),",$C3	; $DD $CB $89=RES 1,(IX+*),C	UNDOCUMENTED
	.asc	"RES 1,(IX+@),",$C4	; $DD $CB $8A=RES 1,(IX+*),D	UNDOCUMENTED
	.asc	"RES 1,(IX+@),",$C5	; $DD $CB $8B=RES 1,(IX+*),E	UNDOCUMENTED
	.asc	"RES 1,(IX+@),",$C8	; $DD $CB $8C=RES 1,(IX+*),H	UNDOCUMENTED
	.asc	"RES 1,(IX+@),",$CC	; $DD $CB $8D=RES 1,(IX+*),L	UNDOCUMENTED
	.asc	"RES 1, (IX+@", $A9	; $DD $CB $8E=RES 1,(IX+*)		$A9 was ')'+$80
	.asc	"RES 1,(IX+@),",$C1	; $DD $CB $8F=RES 1,(IX+*),A	UNDOCUMENTED

	.asc	"RES 2,(IX+@),",$C2	; $DD $CB $90=RES 2,(IX+*),B	UNDOCUMENTED
	.asc	"RES 2,(IX+@),",$C3	; $DD $CB $91=RES 2,(IX+*),C	UNDOCUMENTED
	.asc	"RES 2,(IX+@),",$C4	; $DD $CB $92=RES 2,(IX+*),D	UNDOCUMENTED
	.asc	"RES 2,(IX+@),",$C5	; $DD $CB $93=RES 2,(IX+*),E	UNDOCUMENTED
	.asc	"RES 2,(IX+@),",$C8	; $DD $CB $94=RES 2,(IX+*),H	UNDOCUMENTED
	.asc	"RES 2,(IX+@),",$CC	; $DD $CB $95=RES 2,(IX+*),L	UNDOCUMENTED
	.asc	"RES 2, (IX+@", $A9	; $DD $CB $96=RES 2,(IX+*)		$A9 was ')'+$90
	.asc	"RES 2,(IX+@),",$C1	; $DD $CB $97=RES 2,(IX+*),A	UNDOCUMENTED
	.asc	"RES 3,(IX+@),",$C2	; $DD $CB $98=RES 3,(IX+*),B	UNDOCUMENTED
	.asc	"RES 3,(IX+@),",$C3	; $DD $CB $99=RES 3,(IX+*),C	UNDOCUMENTED
	.asc	"RES 3,(IX+@),",$C4	; $DD $CB $9A=RES 3,(IX+*),D	UNDOCUMENTED
	.asc	"RES 3,(IX+@),",$C5	; $DD $CB $9B=RES 3,(IX+*),E	UNDOCUMENTED
	.asc	"RES 3,(IX+@),",$C8	; $DD $CB $9C=RES 3,(IX+*),H	UNDOCUMENTED
	.asc	"RES 3,(IX+@),",$CC	; $DD $CB $9D=RES 3,(IX+*),L	UNDOCUMENTED
	.asc	"RES 3, (IX+@", $A9	; $DD $CB $9E=RES 3,(IX+*)		$A9 was ')'+$90
	.asc	"RES 3,(IX+@),",$C1	; $DD $CB $9F=RES 3,(IX+*),A	UNDOCUMENTED

	.asc	"RES 4,(IX+@),",$C2	; $DD $CB $A0=RES 4,(IX+*),B	UNDOCUMENTED
	.asc	"RES 4,(IX+@),",$C3	; $DD $CB $A1=RES 4,(IX+*),C	UNDOCUMENTED
	.asc	"RES 4,(IX+@),",$C4	; $DD $CB $A2=RES 4,(IX+*),D	UNDOCUMENTED
	.asc	"RES 4,(IX+@),",$C5	; $DD $CB $A3=RES 4,(IX+*),E	UNDOCUMENTED
	.asc	"RES 4,(IX+@),",$C8	; $DD $CB $A4=RES 4,(IX+*),H	UNDOCUMENTED
	.asc	"RES 4,(IX+@),",$CC	; $DD $CB $A5=RES 4,(IX+*),L	UNDOCUMENTED
	.asc	"RES 4, (IX+@", $A9	; $DD $CB $A6=RES 4,(IX+*)		$A9 was ')'+$A0
	.asc	"RES 4,(IX+@),",$C1	; $DD $CB $A7=RES 4,(IX+*),A	UNDOCUMENTED
	.asc	"RES 5,(IX+@),",$C2	; $DD $CB $A8=RES 5,(IX+*),B	UNDOCUMENTED
	.asc	"RES 5,(IX+@),",$C3	; $DD $CB $A9=RES 5,(IX+*),C	UNDOCUMENTED
	.asc	"RES 5,(IX+@),",$C4	; $DD $CB $AA=RES 5,(IX+*),D	UNDOCUMENTED
	.asc	"RES 5,(IX+@),",$C5	; $DD $CB $AB=RES 5,(IX+*),E	UNDOCUMENTED
	.asc	"RES 5,(IX+@),",$C8	; $DD $CB $AC=RES 5,(IX+*),H	UNDOCUMENTED
	.asc	"RES 5,(IX+@),",$CC	; $DD $CB $AD=RES 5,(IX+*),L	UNDOCUMENTED
	.asc	"RES 5, (IX+@", $A9	; $DD $CB $AE=RES 5,(IX+*)		$A9 was ')'+$A0
	.asc	"RES 5,(IX+@),",$C1	; $DD $CB $AF=RES 5,(IX+*),A	UNDOCUMENTED

	.asc	"RES 6,(IX+@),",$C2	; $DD $CB $B0=RES 6,(IX+*),B	UNDOCUMENTED
	.asc	"RES 6,(IX+@),",$C3	; $DD $CB $B1=RES 6,(IX+*),C	UNDOCUMENTED
	.asc	"RES 6,(IX+@),",$C4	; $DD $CB $B2=RES 6,(IX+*),D	UNDOCUMENTED
	.asc	"RES 6,(IX+@),",$C5	; $DD $CB $B3=RES 6,(IX+*),E	UNDOCUMENTED
	.asc	"RES 6,(IX+@),",$C8	; $DD $CB $B4=RES 6,(IX+*),H	UNDOCUMENTED
	.asc	"RES 6,(IX+@),",$CC	; $DD $CB $B5=RES 6,(IX+*),L	UNDOCUMENTED
	.asc	"RES 6, (IX+@", $A9	; $DD $CB $B6=RES 6,(IX+*)		$A9 was ')'+$B0
	.asc	"RES 6,(IX+@),",$C1	; $DD $CB $B7=RES 6,(IX+*),A	UNDOCUMENTED
	.asc	"RES 7,(IX+@),",$C2	; $DD $CB $B8=RES 7,(IX+*),B	UNDOCUMENTED
	.asc	"RES 7,(IX+@),",$C3	; $DD $CB $B9=RES 7,(IX+*),C	UNDOCUMENTED
	.asc	"RES 7,(IX+@),",$C4	; $DD $CB $BA=RES 7,(IX+*),D	UNDOCUMENTED
	.asc	"RES 7,(IX+@),",$C5	; $DD $CB $BB=RES 7,(IX+*),E	UNDOCUMENTED
	.asc	"RES 7,(IX+@),",$C8	; $DD $CB $BC=RES 7,(IX+*),H	UNDOCUMENTED
	.asc	"RES 7,(IX+@),",$CC	; $DD $CB $BD=RES 7,(IX+*),L	UNDOCUMENTED
	.asc	"RES 7, (IX+@", $A9	; $DD $CB $BE=RES 7,(IX+*)		$A9 was ')'+$B0
	.asc	"RES 7,(IX+@),",$C1	; $DD $CB $BF=RES 7,(IX+*),A	UNDOCUMENTED

	.asc	"SET 0,(IX+@),",$C2	; $DD $CB $C0=SET 0,(IX+*),B	UNDOCUMENTED
	.asc	"SET 0,(IX+@),",$C3	; $DD $CB $C1=SET 0,(IX+*),C	UNDOCUMENTED
	.asc	"SET 0,(IX+@),",$C4	; $DD $CB $C2=SET 0,(IX+*),D	UNDOCUMENTED
	.asc	"SET 0,(IX+@),",$C5	; $DD $CB $C3=SET 0,(IX+*),E	UNDOCUMENTED
	.asc	"SET 0,(IX+@),",$C8	; $DD $CB $C4=SET 0,(IX+*),H	UNDOCUMENTED
	.asc	"SET 0,(IX+@),",$CC	; $DD $CB $C5=SET 0,(IX+*),L	UNDOCUMENTED
	.asc	"SET 0, (IX+@", $A9	; $DD $CB $C6=SET 0,(IX+*)		$A9 was ')'+$80
	.asc	"SET 0,(IX+@),",$C1	; $DD $CB $C7=SET 0,(IX+*),A	UNDOCUMENTED
	.asc	"SET 1,(IX+@),",$C2	; $DD $CB $C8=SET 1,(IX+*),B	UNDOCUMENTED
	.asc	"SET 1,(IX+@),",$C3	; $DD $CB $C9=SET 1,(IX+*),C	UNDOCUMENTED
	.asc	"SET 1,(IX+@),",$C4	; $DD $CB $CA=SET 1,(IX+*),D	UNDOCUMENTED
	.asc	"SET 1,(IX+@),",$C5	; $DD $CB $CB=SET 1,(IX+*),E	UNDOCUMENTED
	.asc	"SET 1,(IX+@),",$C8	; $DD $CB $CC=SET 1,(IX+*),H	UNDOCUMENTED
	.asc	"SET 1,(IX+@),",$CC	; $DD $CB $CD=SET 1,(IX+*),L	UNDOCUMENTED
	.asc	"SET 1, (IX+@", $A9	; $DD $CB $CE=SET 1,(IX+*)		$A9 was ')'+$80
	.asc	"SET 1,(IX+@),",$C1	; $DD $CB $CF=SET 1,(IX+*),A	UNDOCUMENTED

	.asc	"SET 2,(IX+@),",$C2	; $DD $CB $D0=SET 2,(IX+*),B	UNDOCUMENTED
	.asc	"SET 2,(IX+@),",$C3	; $DD $CB $D1=SET 2,(IX+*),C	UNDOCUMENTED
	.asc	"SET 2,(IX+@),",$C4	; $DD $CB $D2=SET 2,(IX+*),D	UNDOCUMENTED
	.asc	"SET 2,(IX+@),",$C5	; $DD $CB $D3=SET 2,(IX+*),E	UNDOCUMENTED
	.asc	"SET 2,(IX+@),",$C8	; $DD $CB $D4=SET 2,(IX+*),H	UNDOCUMENTED
	.asc	"SET 2,(IX+@),",$CC	; $DD $CB $D5=SET 2,(IX+*),L	UNDOCUMENTED
	.asc	"SET 2, (IX+@", $A9	; $DD $CB $D6=SET 2,(IX+*)		$A9 was ')'+$90
	.asc	"SET 2,(IX+@),",$C1	; $DD $CB $D7=SET 2,(IX+*),A	UNDOCUMENTED
	.asc	"SET 3,(IX+@),",$C2	; $DD $CB $D8=SET 3,(IX+*),B	UNDOCUMENTED
	.asc	"SET 3,(IX+@),",$C3	; $DD $CB $D9=SET 3,(IX+*),C	UNDOCUMENTED
	.asc	"SET 3,(IX+@),",$C4	; $DD $CB $DA=SET 3,(IX+*),D	UNDOCUMENTED
	.asc	"SET 3,(IX+@),",$C5	; $DD $CB $DB=SET 3,(IX+*),E	UNDOCUMENTED
	.asc	"SET 3,(IX+@),",$C8	; $DD $CB $DC=SET 3,(IX+*),H	UNDOCUMENTED
	.asc	"SET 3,(IX+@),",$CC	; $DD $CB $DD=SET 3,(IX+*),L	UNDOCUMENTED
	.asc	"SET 3, (IX+@", $A9	; $DD $CB $DE=SET 3,(IX+*)		$A9 was ')'+$90
	.asc	"SET 3,(IX+@),",$C1	; $DD $CB $DF=SET 3,(IX+*),A	UNDOCUMENTED

	.asc	"SET 4,(IX+@),",$C2	; $DD $CB $E0=SET 4,(IX+*),B	UNDOCUMENTED
	.asc	"SET 4,(IX+@),",$C3	; $DD $CB $E1=SET 4,(IX+*),C	UNDOCUMENTED
	.asc	"SET 4,(IX+@),",$C4	; $DD $CB $E2=SET 4,(IX+*),D	UNDOCUMENTED
	.asc	"SET 4,(IX+@),",$C5	; $DD $CB $E3=SET 4,(IX+*),E	UNDOCUMENTED
	.asc	"SET 4,(IX+@),",$C8	; $DD $CB $E4=SET 4,(IX+*),H	UNDOCUMENTED
	.asc	"SET 4,(IX+@),",$CC	; $DD $CB $E5=SET 4,(IX+*),L	UNDOCUMENTED
	.asc	"SET 4, (IX+@", $A9	; $DD $CB $E6=SET 4,(IX+*)		$A9 was ')'+$A0
	.asc	"SET 4,(IX+@),",$C1	; $DD $CB $E7=SET 4,(IX+*),A	UNDOCUMENTED
	.asc	"SET 5,(IX+@),",$C2	; $DD $CB $E8=SET 5,(IX+*),B	UNDOCUMENTED
	.asc	"SET 5,(IX+@),",$C3	; $DD $CB $E9=SET 5,(IX+*),C	UNDOCUMENTED
	.asc	"SET 5,(IX+@),",$C4	; $DD $CB $EA=SET 5,(IX+*),D	UNDOCUMENTED
	.asc	"SET 5,(IX+@),",$C5	; $DD $CB $EB=SET 5,(IX+*),E	UNDOCUMENTED
	.asc	"SET 5,(IX+@),",$C8	; $DD $CB $EC=SET 5,(IX+*),H	UNDOCUMENTED
	.asc	"SET 5,(IX+@),",$CC	; $DD $CB $ED=SET 5,(IX+*),L	UNDOCUMENTED
	.asc	"SET 5, (IX+@", $A9	; $DD $CB $EE=SET 5,(IX+*)		$A9 was ')'+$A0
	.asc	"SET 5,(IX+@),",$C1	; $DD $CB $EF=SET 5,(IX+*),A	UNDOCUMENTED

	.asc	"SET 6,(IX+@),",$C2	; $DD $CB $F0=SET 6,(IX+*),B	UNDOCUMENTED
	.asc	"SET 6,(IX+@),",$C3	; $DD $CB $F1=SET 6,(IX+*),C	UNDOCUMENTED
	.asc	"SET 6,(IX+@),",$C4	; $DD $CB $F2=SET 6,(IX+*),D	UNDOCUMENTED
	.asc	"SET 6,(IX+@),",$C5	; $DD $CB $F3=SET 6,(IX+*),E	UNDOCUMENTED
	.asc	"SET 6,(IX+@),",$C8	; $DD $CB $F4=SET 6,(IX+*),H	UNDOCUMENTED
	.asc	"SET 6,(IX+@),",$CC	; $DD $CB $F5=SET 6,(IX+*),L	UNDOCUMENTED
	.asc	"SET 6, (IX+@", $A9	; $DD $CB $F6=SET 6,(IX+*)		$A9 was ')'+$B0
	.asc	"SET 6,(IX+@),",$C1	; $DD $CB $F7=SET 6,(IX+*),A	UNDOCUMENTED
	.asc	"SET 7,(IX+@),",$C2	; $DD $CB $F8=SET 7,(IX+*),B	UNDOCUMENTED
	.asc	"SET 7,(IX+@),",$C3	; $DD $CB $F9=SET 7,(IX+*),C	UNDOCUMENTED
	.asc	"SET 7,(IX+@),",$C4	; $DD $CB $FA=SET 7,(IX+*),D	UNDOCUMENTED
	.asc	"SET 7,(IX+@),",$C5	; $DD $CB $FB=SET 7,(IX+*),E	UNDOCUMENTED
	.asc	"SET 7,(IX+@),",$C8	; $DD $CB $FC=SET 7,(IX+*),H	UNDOCUMENTED
	.asc	"SET 7,(IX+@),",$CC	; $DD $CB $FD=SET 7,(IX+*),L	UNDOCUMENTED
	.asc	"SET 7, (IX+@", $A9	; $DD $CB $FE=SET 7,(IX+*)		$A9 was ')'+$B0
	.asc	"SET 7,(IX+@),",$C1	; $DD $CB $FF=SET 7,(IX+*),A	UNDOCUMENTED

; ****************************************************
; *** IY+d indexed BIT instructions ($FDCB prefix) *** @pointer table + 12!
; ****************************************************
z80_fdcb:
	.asc	"RLC (IY+@), ", $C2	; $FD $CB $00=RLC (IY+*),B	UNDOCUMENTED
	.asc	"RLC (IY+@), ", $C3	; $FD $CB $01=RLC (IY+*),C	UNDOCUMENTED
	.asc	"RLC (IY+@), ", $C4	; $FD $CB $02=RLC (IY+*),D	UNDOCUMENTED
	.asc	"RLC (IY+@), ", $C5	; $FD $CB $03=RLC (IY+*),E	UNDOCUMENTED
	.asc	"RLC (IY+@), ", $C8	; $FD $CB $04=RLC (IY+*),H	UNDOCUMENTED
	.asc	"RLC (IY+@), ", $CC	; $FD $CB $05=RLC (IY+*),L	UNDOCUMENTED
	.asc	"RLC (IY+@",')'+$80	; $FD $CB $06=RLC (IY+*)
	.asc	"RLC (IY+@), ", $C1	; $FD $CB $07=RLC (IY+*),A	UNDOCUMENTED
	.asc	"RRC (IY+@), ", $C2	; $FD $CB $08=RRC (IY+*),B	UNDOCUMENTED
	.asc	"RRC (IY+@), ", $C3	; $FD $CB $09=RRC (IY+*),C	UNDOCUMENTED
	.asc	"RRC (IY+@), ", $C4	; $FD $CB $0A=RRC (IY+*),D	UNDOCUMENTED
	.asc	"RRC (IY+@), ", $C5	; $FD $CB $0B=RRC (IY+*),E	UNDOCUMENTED
	.asc	"RRC (IY+@), ", $C8	; $FD $CB $0C=RRC (IY+*),H	UNDOCUMENTED
	.asc	"RRC (IY+@), ", $CC	; $FD $CB $0D=RRC (IY+*),L	UNDOCUMENTED
	.asc	"RRC (IY+@",')'+$80	; $FD $CB $0E=RRC (IY+*)
	.asc	"RRC (IY+@), ", $C1	; $FD $CB $0F=RRC (IY+*),A	UNDOCUMENTED

	.asc	"RL (IY+@), ", $C2	; $FD $CB $10=RL (IY+*),B	UNDOCUMENTED
	.asc	"RL (IY+@), ", $C3	; $FD $CB $11=RL (IY+*),C	UNDOCUMENTED
	.asc	"RL (IY+@), ", $C4	; $FD $CB $12=RL (IY+*),D	UNDOCUMENTED
	.asc	"RL (IY+@), ", $C5	; $FD $CB $13=RL (IY+*),E	UNDOCUMENTED
	.asc	"RL (IY+@), ", $C8	; $FD $CB $14=RL (IY+*),H	UNDOCUMENTED
	.asc	"RL (IY+@), ", $CC	; $FD $CB $15=RL (IY+*),L	UNDOCUMENTED
	.asc	"RL (IY+@",')'+$80	; $FD $CB $16=RL (IY+*)
	.asc	"RL (IY+@), ", $C1	; $FD $CB $17=RL (IY+*),A	UNDOCUMENTED
	.asc	"RR (IY+@), ", $C2	; $FD $CB $18=RR (IY+*),B	UNDOCUMENTED
	.asc	"RR (IY+@), ", $C3	; $FD $CB $19=RR (IY+*),C	UNDOCUMENTED
	.asc	"RR (IY+@), ", $C4	; $FD $CB $1A=RR (IY+*),D	UNDOCUMENTED
	.asc	"RR (IY+@), ", $C5	; $FD $CB $1B=RR (IY+*),E	UNDOCUMENTED
	.asc	"RR (IY+@), ", $C8	; $FD $CB $1C=RR (IY+*),H	UNDOCUMENTED
	.asc	"RR (IY+@), ", $CC	; $FD $CB $1D=RR (IY+*),L	UNDOCUMENTED
	.asc	"RR (IY+@",')'+$80	; $FD $CB $1E=RR (IY+*)
	.asc	"RR (IY+@), ", $C1	; $FD $CB $1F=RR (IY+*),A	UNDOCUMENTED

	.asc	"SLA (IY+@), ", $C2	; $FD $CB $20=SLA(IY+*),B	UNDOCUMENTED
	.asc	"SLA (IY+@), ", $C3	; $FD $CB $21=SLA(IY+*),C	UNDOCUMENTED
	.asc	"SLA (IY+@), ", $C4	; $FD $CB $22=SLA(IY+*),D	UNDOCUMENTED
	.asc	"SLA (IY+@), ", $C5	; $FD $CB $23=SLA(IY+*),E	UNDOCUMENTED
	.asc	"SLA (IY+@), ", $C8	; $FD $CB $24=SLA(IY+*),H	UNDOCUMENTED
	.asc	"SLA (IY+@), ", $CC	; $FD $CB $25=SLA(IY+*),L	UNDOCUMENTED
	.asc	"SLA (IY+@",')'+$80	; $FD $CB $26=SLA (IY+*)
	.asc	"SLA (IY+@), ", $C1	; $FD $CB $27=SLA(IY+*),A	UNDOCUMENTED
	.asc	"SRA (IY+@), ", $C2	; $FD $CB $28=SRA(IY+*),B	UNDOCUMENTED
	.asc	"SRA (IY+@), ", $C3	; $FD $CB $29=SRA(IY+*),C	UNDOCUMENTED
	.asc	"SRA (IY+@), ", $C4	; $FD $CB $2A=SRA(IY+*),D	UNDOCUMENTED
	.asc	"SRA (IY+@), ", $C5	; $FD $CB $2B=SRA(IY+*),E	UNDOCUMENTED
	.asc	"SRA (IY+@), ", $C8	; $FD $CB $2C=SRA(IY+*),H	UNDOCUMENTED
	.asc	"SRA (IY+@), ", $CC	; $FD $CB $2D=SRA(IY+*),L	UNDOCUMENTED
	.asc	"SRA (IY+@",')'+$80	; $FD $CB $2E=SRA (IY+*)
	.asc	"SRA (IY+@), ", $C1	; $FD $CB $2F=SRA(IY+*),A	UNDOCUMENTED

	.asc	"SLL (IY+@), ", $C2	; $FD $CB $30=SLL(IY+*),B	UNDOCUMENTED
	.asc	"SLL (IY+@), ", $C3	; $FD $CB $31=SLL(IY+*),C	UNDOCUMENTED
	.asc	"SLL (IY+@), ", $C4	; $FD $CB $32=SLL(IY+*),D	UNDOCUMENTED
	.asc	"SLL (IY+@), ", $C5	; $FD $CB $33=SLL(IY+*),E	UNDOCUMENTED
	.asc	"SLL (IY+@), ", $C8	; $FD $CB $34=SLL(IY+*),H	UNDOCUMENTED
	.asc	"SLL (IY+@), ", $CC	; $FD $CB $35=SLL(IY+*),L	UNDOCUMENTED
	.asc	"SLL (IY+@",')'+$80	; $FD $CB $36=SLL (IY+*)	UNDOCUMENTED!
	.asc	"SLL (IY+@), ", $C1	; $FD $CB $37=SLL(IY+*),A	UNDOCUMENTED
	.asc	"SRL (IY+@), ", $C2	; $FD $CB $38=SRL(IY+*),B	UNDOCUMENTED
	.asc	"SRL (IY+@), ", $C3	; $FD $CB $39=SRL(IY+*),C	UNDOCUMENTED
	.asc	"SRL (IY+@), ", $C4	; $FD $CB $3A=SRL(IY+*),D	UNDOCUMENTED
	.asc	"SRL (IY+@), ", $C5	; $FD $CB $3B=SRL(IY+*),E	UNDOCUMENTED
	.asc	"SRL (IY+@), ", $C8	; $FD $CB $3C=SRL(IY+*),H	UNDOCUMENTED
	.asc	"SRL (IY+@), ", $CC	; $FD $CB $3D=SRL(IY+*),L	UNDOCUMENTED
	.asc	"SRL (IY+@",')'+$80	; $FD $CB $3E=SRL (IY+*)
	.asc	"SRL (IY+@), ", $C1	; $FD $CB $3F=SRL(IY+*),A	UNDOCUMENTED

	.asc	"BIT 0, (IY+@", $A9	; $FD $CB $40=BIT 0,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 0, (IY+@", $A9	; $FD $CB $41=BIT 0,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 0, (IY+@", $A9	; $FD $CB $42=BIT 0,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 0, (IY+@", $A9	; $FD $CB $43=BIT 0,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 0, (IY+@", $A9	; $FD $CB $44=BIT 0,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 0, (IY+@", $A9	; $FD $CB $45=BIT 0,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 0, (IY+@", $A9	; $FD $CB $46=BIT 0,(IY+*)					$A9 was ')'+$80
	.asc	"BIT 0, (IY+@", $A9	; $FD $CB $47=BIT 0,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 1, (IY+@", $A9	; $FD $CB $48=BIT 1,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 1, (IY+@", $A9	; $FD $CB $49=BIT 1,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 1, (IY+@", $A9	; $FD $CB $4A=BIT 1,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 1, (IY+@", $A9	; $FD $CB $4B=BIT 1,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 1, (IY+@", $A9	; $FD $CB $4C=BIT 1,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 1, (IY+@", $A9	; $FD $CB $4D=BIT 1,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 1, (IY+@", $A9	; $FD $CB $4E=BIT 1,(IY+*)					$A9 was ')'+$80
	.asc	"BIT 1, (IY+@", $A9	; $FD $CB $4F=BIT 1,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80

	.asc	"BIT 2, (IY+@", $A9	; $FD $CB $50=BIT 2,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 2, (IY+@", $A9	; $FD $CB $51=BIT 2,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 2, (IY+@", $A9	; $FD $CB $52=BIT 2,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 2, (IY+@", $A9	; $FD $CB $53=BIT 2,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 2, (IY+@", $A9	; $FD $CB $54=BIT 2,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 2, (IY+@", $A9	; $FD $CB $55=BIT 2,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 2, (IY+@", $A9	; $FD $CB $56=BIT 2,(IY+*)					$A9 was ')'+$80
	.asc	"BIT 2, (IY+@", $A9	; $FD $CB $57=BIT 2,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 3, (IY+@", $A9	; $FD $CB $58=BIT 3,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 3, (IY+@", $A9	; $FD $CB $59=BIT 3,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 3, (IY+@", $A9	; $FD $CB $5A=BIT 3,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 3, (IY+@", $A9	; $FD $CB $5B=BIT 3,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 3, (IY+@", $A9	; $FD $CB $5C=BIT 3,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 3, (IY+@", $A9	; $FD $CB $5D=BIT 3,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 3, (IY+@", $A9	; $FD $CB $5E=BIT 3,(IY+*)					$A9 was ')'+$80
	.asc	"BIT 3, (IY+@", $A9	; $FD $CB $5F=BIT 3,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80

	.asc	"BIT 4, (IY+@", $A9	; $FD $CB $60=BIT 4,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 4, (IY+@", $A9	; $FD $CB $61=BIT 4,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 4, (IY+@", $A9	; $FD $CB $62=BIT 4,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 4, (IY+@", $A9	; $FD $CB $63=BIT 4,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 4, (IY+@", $A9	; $FD $CB $64=BIT 4,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 4, (IY+@", $A9	; $FD $CB $65=BIT 4,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 4, (IY+@", $A9	; $FD $CB $66=BIT 4,(IY+*)					$A9 was ')'+$80
	.asc	"BIT 4, (IY+@", $A9	; $FD $CB $67=BIT 4,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 5, (IY+@", $A9	; $FD $CB $68=BIT 5,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 5, (IY+@", $A9	; $FD $CB $69=BIT 5,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 5, (IY+@", $A9	; $FD $CB $6A=BIT 5,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 5, (IY+@", $A9	; $FD $CB $6B=BIT 5,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 5, (IY+@", $A9	; $FD $CB $6C=BIT 5,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 5, (IY+@", $A9	; $FD $CB $6D=BIT 5,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 5, (IY+@", $A9	; $FD $CB $6E=BIT 5,(IY+*)					$A9 was ')'+$80
	.asc	"BIT 5, (IY+@", $A9	; $FD $CB $6F=BIT 5,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80

	.asc	"BIT 6, (IY+@", $A9	; $FD $CB $70=BIT 6,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 6, (IY+@", $A9	; $FD $CB $71=BIT 6,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 6, (IY+@", $A9	; $FD $CB $72=BIT 6,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 6, (IY+@", $A9	; $FD $CB $73=BIT 6,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 6, (IY+@", $A9	; $FD $CB $74=BIT 6,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 6, (IY+@", $A9	; $FD $CB $75=BIT 6,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 6, (IY+@", $A9	; $FD $CB $76=BIT 6,(IY+*)					$A9 was ')'+$80
	.asc	"BIT 6, (IY+@", $A9	; $FD $CB $77=BIT 6,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 7, (IY+@", $A9	; $FD $CB $78=BIT 7,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 7, (IY+@", $A9	; $FD $CB $79=BIT 7,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 7, (IY+@", $A9	; $FD $CB $7A=BIT 7,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 7, (IY+@", $A9	; $FD $CB $7B=BIT 7,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 7, (IY+@", $A9	; $FD $CB $7C=BIT 7,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 7, (IY+@", $A9	; $FD $CB $7D=BIT 7,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80
	.asc	"BIT 7, (IY+@", $A9	; $FD $CB $7E=BIT 7,(IY+*)					$A9 was ')'+$80
	.asc	"BIT 7, (IY+@", $A9	; $FD $CB $7F=BIT 7,(IY+*)	UNDOCUMENTED	$A9 was ')'+$80

	.asc	"RES 0,(IY+@),",$C2	; $FD $CB $80=RES 0,(IY+*),B	UNDOCUMENTED
	.asc	"RES 0,(IY+@),",$C3	; $FD $CB $81=RES 0,(IY+*),C	UNDOCUMENTED
	.asc	"RES 0,(IY+@),",$C4	; $FD $CB $82=RES 0,(IY+*),D	UNDOCUMENTED
	.asc	"RES 0,(IY+@),",$C5	; $FD $CB $83=RES 0,(IY+*),E	UNDOCUMENTED
	.asc	"RES 0,(IY+@),",$C8	; $FD $CB $84=RES 0,(IY+*),H	UNDOCUMENTED
	.asc	"RES 0,(IY+@),",$CC	; $FD $CB $85=RES 0,(IY+*),L	UNDOCUMENTED
	.asc	"RES 0, (IY+@", $A9	; $FD $CB $86=RES 0,(IY+*)		$A9 was ')'+$80
	.asc	"RES 0,(IY+@),",$C1	; $FD $CB $87=RES 0,(IY+*),A	UNDOCUMENTED
	.asc	"RES 1,(IY+@),",$C2	; $FD $CB $88=RES 1,(IY+*),B	UNDOCUMENTED
	.asc	"RES 1,(IY+@),",$C3	; $FD $CB $89=RES 1,(IY+*),C	UNDOCUMENTED
	.asc	"RES 1,(IY+@),",$C4	; $FD $CB $8A=RES 1,(IY+*),D	UNDOCUMENTED
	.asc	"RES 1,(IY+@),",$C5	; $FD $CB $8B=RES 1,(IY+*),E	UNDOCUMENTED
	.asc	"RES 1,(IY+@),",$C8	; $FD $CB $8C=RES 1,(IY+*),H	UNDOCUMENTED
	.asc	"RES 1,(IY+@),",$CC	; $FD $CB $8D=RES 1,(IY+*),L	UNDOCUMENTED
	.asc	"RES 1, (IY+@", $A9	; $FD $CB $8E=RES 1,(IY+*)		$A9 was ')'+$80
	.asc	"RES 1,(IY+@),",$C1	; $FD $CB $8F=RES 1,(IY+*),A	UNDOCUMENTED

	.asc	"RES 2,(IY+@),",$C2	; $FD $CB $90=RES 2,(IY+*),B	UNDOCUMENTED
	.asc	"RES 2,(IY+@),",$C3	; $FD $CB $91=RES 2,(IY+*),C	UNDOCUMENTED
	.asc	"RES 2,(IY+@),",$C4	; $FD $CB $92=RES 2,(IY+*),D	UNDOCUMENTED
	.asc	"RES 2,(IY+@),",$C5	; $FD $CB $93=RES 2,(IY+*),E	UNDOCUMENTED
	.asc	"RES 2,(IY+@),",$C8	; $FD $CB $94=RES 2,(IY+*),H	UNDOCUMENTED
	.asc	"RES 2,(IY+@),",$CC	; $FD $CB $95=RES 2,(IY+*),L	UNDOCUMENTED
	.asc	"RES 2, (IY+@", $A9	; $FD $CB $96=RES 2,(IY+*)		$A9 was ')'+$90
	.asc	"RES 2,(IY+@),",$C1	; $FD $CB $97=RES 2,(IY+*),A	UNDOCUMENTED
	.asc	"RES 3,(IY+@),",$C2	; $FD $CB $98=RES 3,(IY+*),B	UNDOCUMENTED
	.asc	"RES 3,(IY+@),",$C3	; $FD $CB $99=RES 3,(IY+*),C	UNDOCUMENTED
	.asc	"RES 3,(IY+@),",$C4	; $FD $CB $9A=RES 3,(IY+*),D	UNDOCUMENTED
	.asc	"RES 3,(IY+@),",$C5	; $FD $CB $9B=RES 3,(IY+*),E	UNDOCUMENTED
	.asc	"RES 3,(IY+@),",$C8	; $FD $CB $9C=RES 3,(IY+*),H	UNDOCUMENTED
	.asc	"RES 3,(IY+@),",$CC	; $FD $CB $9D=RES 3,(IY+*),L	UNDOCUMENTED
	.asc	"RES 3, (IY+@", $A9	; $FD $CB $9E=RES 3,(IY+*)		$A9 was ')'+$90
	.asc	"RES 3,(IY+@),",$C1	; $FD $CB $9F=RES 3,(IY+*),A	UNDOCUMENTED

	.asc	"RES 4,(IY+@),",$C2	; $FD $CB $A0=RES 4,(IY+*),B	UNDOCUMENTED
	.asc	"RES 4,(IY+@),",$C3	; $FD $CB $A1=RES 4,(IY+*),C	UNDOCUMENTED
	.asc	"RES 4,(IY+@),",$C4	; $FD $CB $A2=RES 4,(IY+*),D	UNDOCUMENTED
	.asc	"RES 4,(IY+@),",$C5	; $FD $CB $A3=RES 4,(IY+*),E	UNDOCUMENTED
	.asc	"RES 4,(IY+@),",$C8	; $FD $CB $A4=RES 4,(IY+*),H	UNDOCUMENTED
	.asc	"RES 4,(IY+@),",$CC	; $FD $CB $A5=RES 4,(IY+*),L	UNDOCUMENTED
	.asc	"RES 4, (IY+@", $A9	; $FD $CB $A6=RES 4,(IY+*)		$A9 was ')'+$A0
	.asc	"RES 4,(IY+@),",$C1	; $FD $CB $A7=RES 4,(IY+*),A	UNDOCUMENTED
	.asc	"RES 5,(IY+@),",$C2	; $FD $CB $A8=RES 5,(IY+*),B	UNDOCUMENTED
	.asc	"RES 5,(IY+@),",$C3	; $FD $CB $A9=RES 5,(IY+*),C	UNDOCUMENTED
	.asc	"RES 5,(IY+@),",$C4	; $FD $CB $AA=RES 5,(IY+*),D	UNDOCUMENTED
	.asc	"RES 5,(IY+@),",$C5	; $FD $CB $AB=RES 5,(IY+*),E	UNDOCUMENTED
	.asc	"RES 5,(IY+@),",$C8	; $FD $CB $AC=RES 5,(IY+*),H	UNDOCUMENTED
	.asc	"RES 5,(IY+@),",$CC	; $FD $CB $AD=RES 5,(IY+*),L	UNDOCUMENTED
	.asc	"RES 5, (IY+@", $A9	; $FD $CB $AE=RES 5,(IY+*)		$A9 was ')'+$A0
	.asc	"RES 5,(IY+@),",$C1	; $FD $CB $AF=RES 5,(IY+*),A	UNDOCUMENTED

	.asc	"RES 6,(IY+@),",$C2	; $FD $CB $B0=RES 6,(IY+*),B	UNDOCUMENTED
	.asc	"RES 6,(IY+@),",$C3	; $FD $CB $B1=RES 6,(IY+*),C	UNDOCUMENTED
	.asc	"RES 6,(IY+@),",$C4	; $FD $CB $B2=RES 6,(IY+*),D	UNDOCUMENTED
	.asc	"RES 6,(IY+@),",$C5	; $FD $CB $B3=RES 6,(IY+*),E	UNDOCUMENTED
	.asc	"RES 6,(IY+@),",$C8	; $FD $CB $B4=RES 6,(IY+*),H	UNDOCUMENTED
	.asc	"RES 6,(IY+@),",$CC	; $FD $CB $B5=RES 6,(IY+*),L	UNDOCUMENTED
	.asc	"RES 6, (IY+@", $A9	; $FD $CB $B6=RES 6,(IY+*)		$A9 was ')'+$B0
	.asc	"RES 6,(IY+@),",$C1	; $FD $CB $B7=RES 6,(IY+*),A	UNDOCUMENTED
	.asc	"RES 7,(IY+@),",$C2	; $FD $CB $B8=RES 7,(IY+*),B	UNDOCUMENTED
	.asc	"RES 7,(IY+@),",$C3	; $FD $CB $B9=RES 7,(IY+*),C	UNDOCUMENTED
	.asc	"RES 7,(IY+@),",$C4	; $FD $CB $BA=RES 7,(IY+*),D	UNDOCUMENTED
	.asc	"RES 7,(IY+@),",$C5	; $FD $CB $BB=RES 7,(IY+*),E	UNDOCUMENTED
	.asc	"RES 7,(IY+@),",$C8	; $FD $CB $BC=RES 7,(IY+*),H	UNDOCUMENTED
	.asc	"RES 7,(IY+@),",$CC	; $FD $CB $BD=RES 7,(IY+*),L	UNDOCUMENTED
	.asc	"RES 7, (IY+@", $A9	; $FD $CB $BE=RES 7,(IY+*)		$A9 was ')'+$B0
	.asc	"RES 7,(IY+@),",$C1	; $FD $CB $BF=RES 7,(IY+*),A	UNDOCUMENTED

	.asc	"SET 0,(IY+@),",$C2	; $FD $CB $C0=SET 0,(IY+*),B	UNDOCUMENTED
	.asc	"SET 0,(IY+@),",$C3	; $FD $CB $C1=SET 0,(IY+*),C	UNDOCUMENTED
	.asc	"SET 0,(IY+@),",$C4	; $FD $CB $C2=SET 0,(IY+*),D	UNDOCUMENTED
	.asc	"SET 0,(IY+@),",$C5	; $FD $CB $C3=SET 0,(IY+*),E	UNDOCUMENTED
	.asc	"SET 0,(IY+@),",$C8	; $FD $CB $C4=SET 0,(IY+*),H	UNDOCUMENTED
	.asc	"SET 0,(IY+@),",$CC	; $FD $CB $C5=SET 0,(IY+*),L	UNDOCUMENTED
	.asc	"SET 0, (IY+@", $A9	; $FD $CB $C6=SET 0,(IY+*)		$A9 was ')'+$80
	.asc	"SET 0,(IY+@),",$C1	; $FD $CB $C7=SET 0,(IY+*),A	UNDOCUMENTED
	.asc	"SET 1,(IY+@),",$C2	; $FD $CB $C8=SET 1,(IY+*),B	UNDOCUMENTED
	.asc	"SET 1,(IY+@),",$C3	; $FD $CB $C9=SET 1,(IY+*),C	UNDOCUMENTED
	.asc	"SET 1,(IY+@),",$C4	; $FD $CB $CA=SET 1,(IY+*),D	UNDOCUMENTED
	.asc	"SET 1,(IY+@),",$C5	; $FD $CB $CB=SET 1,(IY+*),E	UNDOCUMENTED
	.asc	"SET 1,(IY+@),",$C8	; $FD $CB $CC=SET 1,(IY+*),H	UNDOCUMENTED
	.asc	"SET 1,(IY+@),",$CC	; $FD $CB $CD=SET 1,(IY+*),L	UNDOCUMENTED
	.asc	"SET 1, (IY+@", $A9	; $FD $CB $CE=SET 1,(IY+*)		$A9 was ')'+$80
	.asc	"SET 1,(IY+@),",$C1	; $FD $CB $CF=SET 1,(IY+*),A	UNDOCUMENTED

	.asc	"SET 2,(IY+@),",$C2	; $FD $CB $D0=SET 2,(IY+*),B	UNDOCUMENTED
	.asc	"SET 2,(IY+@),",$C3	; $FD $CB $D1=SET 2,(IY+*),C	UNDOCUMENTED
	.asc	"SET 2,(IY+@),",$C4	; $FD $CB $D2=SET 2,(IY+*),D	UNDOCUMENTED
	.asc	"SET 2,(IY+@),",$C5	; $FD $CB $D3=SET 2,(IY+*),E	UNDOCUMENTED
	.asc	"SET 2,(IY+@),",$C8	; $FD $CB $D4=SET 2,(IY+*),H	UNDOCUMENTED
	.asc	"SET 2,(IY+@),",$CC	; $FD $CB $D5=SET 2,(IY+*),L	UNDOCUMENTED
	.asc	"SET 2, (IY+@", $A9	; $FD $CB $D6=SET 2,(IY+*)		$A9 was ')'+$90
	.asc	"SET 2,(IY+@),",$C1	; $FD $CB $D7=SET 2,(IY+*),A	UNDOCUMENTED
	.asc	"SET 3,(IY+@),",$C2	; $FD $CB $D8=SET 3,(IY+*),B	UNDOCUMENTED
	.asc	"SET 3,(IY+@),",$C3	; $FD $CB $D9=SET 3,(IY+*),C	UNDOCUMENTED
	.asc	"SET 3,(IY+@),",$C4	; $FD $CB $DA=SET 3,(IY+*),D	UNDOCUMENTED
	.asc	"SET 3,(IY+@),",$C5	; $FD $CB $DB=SET 3,(IY+*),E	UNDOCUMENTED
	.asc	"SET 3,(IY+@),",$C8	; $FD $CB $DC=SET 3,(IY+*),H	UNDOCUMENTED
	.asc	"SET 3,(IY+@),",$CC	; $FD $CB $DD=SET 3,(IY+*),L	UNDOCUMENTED
	.asc	"SET 3, (IY+@", $A9	; $FD $CB $DE=SET 3,(IY+*)		$A9 was ')'+$90
	.asc	"SET 3,(IY+@),",$C1	; $FD $CB $DF=SET 3,(IY+*),A	UNDOCUMENTED

	.asc	"SET 4,(IY+@),",$C2	; $FD $CB $E0=SET 4,(IY+*),B	UNDOCUMENTED
	.asc	"SET 4,(IY+@),",$C3	; $FD $CB $E1=SET 4,(IY+*),C	UNDOCUMENTED
	.asc	"SET 4,(IY+@),",$C4	; $FD $CB $E2=SET 4,(IY+*),D	UNDOCUMENTED
	.asc	"SET 4,(IY+@),",$C5	; $FD $CB $E3=SET 4,(IY+*),E	UNDOCUMENTED
	.asc	"SET 4,(IY+@),",$C8	; $FD $CB $E4=SET 4,(IY+*),H	UNDOCUMENTED
	.asc	"SET 4,(IY+@),",$CC	; $FD $CB $E5=SET 4,(IY+*),L	UNDOCUMENTED
	.asc	"SET 4, (IY+@", $A9	; $FD $CB $E6=SET 4,(IY+*)		$A9 was ')'+$A0
	.asc	"SET 4,(IY+@),",$C1	; $FD $CB $E7=SET 4,(IY+*),A	UNDOCUMENTED
	.asc	"SET 5,(IY+@),",$C2	; $FD $CB $E8=SET 5,(IY+*),B	UNDOCUMENTED
	.asc	"SET 5,(IY+@),",$C3	; $FD $CB $E9=SET 5,(IY+*),C	UNDOCUMENTED
	.asc	"SET 5,(IY+@),",$C4	; $FD $CB $EA=SET 5,(IY+*),D	UNDOCUMENTED
	.asc	"SET 5,(IY+@),",$C5	; $FD $CB $EB=SET 5,(IY+*),E	UNDOCUMENTED
	.asc	"SET 5,(IY+@),",$C8	; $FD $CB $EC=SET 5,(IY+*),H	UNDOCUMENTED
	.asc	"SET 5,(IY+@),",$CC	; $FD $CB $ED=SET 5,(IY+*),L	UNDOCUMENTED
	.asc	"SET 5, (IY+@", $A9	; $FD $CB $EE=SET 5,(IY+*)		$A9 was ')'+$A0
	.asc	"SET 5,(IY+@),",$C1	; $FD $CB $EF=SET 5,(IY+*),A	UNDOCUMENTED

	.asc	"SET 6,(IY+@),",$C2	; $FD $CB $F0=SET 6,(IY+*),B	UNDOCUMENTED
	.asc	"SET 6,(IY+@),",$C3	; $FD $CB $F1=SET 6,(IY+*),C	UNDOCUMENTED
	.asc	"SET 6,(IY+@),",$C4	; $FD $CB $F2=SET 6,(IY+*),D	UNDOCUMENTED
	.asc	"SET 6,(IY+@),",$C5	; $FD $CB $F3=SET 6,(IY+*),E	UNDOCUMENTED
	.asc	"SET 6,(IY+@),",$C8	; $FD $CB $F4=SET 6,(IY+*),H	UNDOCUMENTED
	.asc	"SET 6,(IY+@),",$CC	; $FD $CB $F5=SET 6,(IY+*),L	UNDOCUMENTED
	.asc	"SET 6, (IY+@", $A9	; $FD $CB $F6=SET 6,(IY+*)		$A9 was ')'+$B0
	.asc	"SET 6,(IY+@),",$C1	; $FD $CB $F7=SET 6,(IY+*),A	UNDOCUMENTED
	.asc	"SET 7,(IY+@),",$C2	; $FD $CB $F8=SET 7,(IY+*),B	UNDOCUMENTED
	.asc	"SET 7,(IY+@),",$C3	; $FD $CB $F9=SET 7,(IY+*),C	UNDOCUMENTED
	.asc	"SET 7,(IY+@),",$C4	; $FD $CB $FA=SET 7,(IY+*),D	UNDOCUMENTED
	.asc	"SET 7,(IY+@),",$C5	; $FD $CB $FB=SET 7,(IY+*),E	UNDOCUMENTED
	.asc	"SET 7,(IY+@),",$C8	; $FD $CB $FC=SET 7,(IY+*),H	UNDOCUMENTED
	.asc	"SET 7,(IY+@),",$CC	; $FD $CB $FD=SET 7,(IY+*),L	UNDOCUMENTED
	.asc	"SET 7, (IY+@", $A9	; $FD $CB $FE=SET 7,(IY+*)		$A9 was ')'+$B0
	.asc	"SET 7,(IY+@),",$C1	; $FD $CB $FF=SET 7,(IY+*),A	UNDOCUMENTED
