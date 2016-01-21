; 6800 emulator for minimOS!
; v0.1a1
; (c) 2016 Carlos J. Santisteban
; last modified 20160121

#include "options.h"	; machine specific
#include "macros.h"
#include "abi.h"		; ** new filename **
.zero
#include "zeropage.h"
.bss
#include "firmware/firmware.h"	; machine specific
#include "sysvars.h"
.text

; minimOS executable header will go here

; declare zeropage addresses
pc68	=	uz		; program counter (16 bit, little-endian, negative $4000 offset)
sp68	=	uz+2	; stack pointer (16 bit, little-endian, positive $4000 offset)
x68		=	uz+4	; index register (16 bit, little-endian, positive $4000 offset)
a68		=	uz+6	; first accumulator (8 bit)
b68		=	uz+7	; second accumulator (8 bit)
psr68	=	uz+8	; status register (8 bit)
tmptr	=	uz+9	; temporary storage (up to 16 bit)

; *** startup code ***
#ifdef	SAFE
	LDA z_used		; check available zeropage space
	CMP #11			; currently needed space
	BCS go_emu		; enough space
		_ERR(FULL)		; not enough memory otherwise (rare)
go_emu:
#endif
; might check here whether a Rockwell 65C02 is used!
	LDA #11			; actually needed zeropage space
	STA z_used		; set value as required
; should try to allocate memory here

; *** start the emulation! ***
reset68:
	LDA $BFFF		; get RESET vector LSB from emulated ROM (this is big-endian!)
	STA pc68		; store as inicial PC
	LDA $BFFE		; same for MSB... but create offset!
	AND #%10111111	; use two 16K chunks only
	BMI set_pc		; $C000-$FFFF goes into $8000-$BFFF (emulated ROM area)
		EOR #%01000000	; otherwise goes into emulated RAM area ($4000-$7FFF)
set_pc:
	STA pc68+1		; address fully generated
; *** init a few values more ***
	LDY #1			; preset index for operand access, will serve to reset instruction length
; *** main loop ***
execute:
		LDA (pc68)		; get opcode (needs CMOS) (5)
		ASL				; double it as will become pointer (2)
		TAX				; use as pointer, keeping carry (2)
		BCC lo_jump		; seems to be less opcodes with bit7 low... (2/3)
			JMP (optable_h, X)	; emulation routines for opcodes with bit7 hi (6)
lo_jump:
		JMP (optable_l, X)	; otherwise, emulation routines for opcodes with bit7 low
next_op:					; continue execution via JMP next_op, will not arrive here otherwise (...3)
		CLC				; prepare to increase PC (2)
		ADC pc68		; add up to LSB (3+3)
		STA pc68
			BCC execute		; go for next instruction if not carry (3/2)
		INC pc68		; increase MSB (5)
		BIT pc68		; let us check it against emulated limits (3)
	BMI negative	; will it be in ROM area
		BVS execute		; continue in RAM area
	; ***
negative:
	BVC execute		; no wrap in ROM area
	; ***

; *** opcode execution routines, labels must match those on tables below ***
; unsupported opcodes first
_00:_02:_03:_04:_05:_12:_13:_14:_15:_18:_1a:_1c:_1d:_1e:_1f:_21:_38:_3a:_3c:_3d
_41:_42:_45:_4b:_4e:_51:_52:_55:_5b:_5e:_61:_62:_65:_6b:_71:_72:_75:_7b
_83:_87:_8f:_93:_9d:_a3:_b3:_c3:_c7:_cc:_cd:_cf:_d3:_dc:_dd:_e3:_ec:_ed:_f3:_fc:_fd
	BRK		; *** really do not know what to do upon an illegal opcode!
; useful opcodes
_01:	; NOP
	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_06:	; TAP (2)
	LDA a68		; get A accumulator...
	STA psr68	; ...and store it in CCR (+6)
	TYA			; number of bytes as required
	JMP next_op	; standard end of routine (all +5)
_07:	; TPA (2)
	LDA psr68	; get CCR...
	STA a68		; ...and store it in A (+6)
	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
;_08:	; INX (4) slower 18 bytes
;	INC x68		; increase LSB
;	BNE inx_nw	; no wrap
;		INC x68 + 1	; increase MSB too
;	BNE inx_nw	; no zero anyway (+15 in this case)
;		SMB2 psr68	; set Z bit, *** Rockwell only! ***
;		BRA inx_z	; all done (+22 worst case)
;inx_nw:
;	RMB2 psr68	; clear Z bit, *** Rockwell only! *** (+13 mostly)
;inx_z:
;	TYA			; number of bytes as required
;	JMP next_op	; standard end of routine
_08:	; INX (4) faster 22 bytes
	TYA			; number of bytes as required
	RMB2 psr68	; clear Z bit, *** Rockwell only! ***
	INC x68		; increase LSB
	BEQ inx_w	; wrap is a rare case
		JMP next_op	; usual end (+12 mostly, worth it)
inx_w:
	INC x68 + 1	; increase MSB
	BEQ inx_z	; becoming zero is even rarer!
		JMP next_op	; wrapped non-zero end (+20 in this case)
inx_z:
	SMB2 psr68	; set Z bit, *** Rockwell only! *** (+26 worst case)
	JMP next_op	; rarest end of routine
_09:	; DEX (4)
	TYA			; number of bytes as required
	RMB2 psr68	; clear Z bit, *** Rockwell only! ***
	DEC x68		; decrease LSB
		BEQ dex_z	; could be zero
	LDX x68		; let us see...
	CPX #$FF	; check for wrap
	BEQ dex_w	; wrap is a rare case
		JMP next_op	; usual end (+19 mostly)
dex_w:
	DEC x68 + 1	; decrease MSB
	JMP next_op	; wrapped non-zero end (+25 worst case)
dex_z:
	LDX x68 + 1	; let us see the MSB contents
	BEQ dex_zz	; it really is all zeroes!
		JMP next_op	; go away otherwise (+18)
dex_zz:
	SMB2 psr68	; set Z bit, *** Rockwell only! *** (+24 in this case)
	JMP next_op	; rarest end of routine
_0a:	; CLV (2)
	RMB1 psr68	; clear V bit, *** Rockwell only! *** (+5)
	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_0b:	; SEV (2)
	SMB1 psr68	; set V bit, *** Rockwell only! *** (+5)
	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_0c:	; CLC (2)
	RMB0 psr68	; clear C bit, *** Rockwell only! *** (+5)
	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_0d:	; SEC (2)
	SMB0 psr68	; set C bit, *** Rockwell only! *** (+5)
	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_0e:	; CLI (2)
	RMB4 psr68	; clear I bit, *** Rockwell only! *** (+5)
	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_0f:	; SEI (2)
	SMB4 psr68	; set I bit, *** Rockwell only! *** (+5)
	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_10:	; SBA

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_11:	; CBA

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_16:	; TAB

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_17:	; TBA

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_19:	; DAA

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_1b:	; ABA

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_20:	; BRA rel

	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_22:	; BHI rel

	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_23:	; BLS rel

	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_24:	; BCC rel

	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_25:	; BCS rel

	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_26:	; BNE rel

	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_27:	; BEQ rel

	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_28:	; BVC rel

	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_29:	; BVS rel

	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_2a:	; BPL rel

	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_2b:	; BMI rel

	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_2c:	; BGE rel

	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_2d:	; BLT rel

	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_2e:	; BGT rel

	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_2f:	; BLE rel

	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_30:	; TSX (2)
	LDA sp68		; get stack pointer LSB
	STA x68			; store in X
	LDA sp68 + 1	; same for MSB (+12)
	STA x68 + 1
	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_31:	; INS (4)
	TYA			; number of bytes as required
	INC sp68	; increase LSB
	BEQ ins_w	; wrap is a rare case
		JMP next_op	; usual end (+7 mostly)
ins_w:
	INC sp68 + 1	; increase MSB
	JMP next_op		; wrapped end (+13 worst case)
_32:	; PUL A

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_33:	; PUL B

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_34:	; DES (4)
	TYA			; number of bytes as required
	DEC sp68	; decrease LSB
	LDX sp68	; let us see...
	CPX #$FF	; check for wrap
	BEQ des_w	; wrap is a rare case
		JMP next_op	; usual end (+12 mostly)
des_w:
	DEC sp68 + 1	; decrease MSB
	JMP next_op	; wrapped end (+18 worst case)
_35:	; TXS (2)
	LDA x68		; get X LSB
	STA sp68	; store as stack pointer
	LDA x68 + 1	; same for MSB (+12)
	STA sp68 + 1
	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_36:	; PSH A

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_37:	; PSH B

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_39:	; RTS

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_3b:	; RTI

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_3e:	; WAI

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_3f:	; SWI

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_40:	; NEG A

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_43:	; COM A

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_44:	; LSR A

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_46:	; ROR A

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_47:	; ASR A

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_48:	; ASL A

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_49:	; ROL A

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_4a:	; DEC A

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_4c:	; INC A

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_4d:	; TST A

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_4f:	; CLR A
	STZ a68		; clear A
	LDA psr68	; get previous status
	AND #%11110100	; clear N, V, C
	ORA #%00000100	; set Z
	STA psr68	; update
	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_50:	; NEG B

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_53:	; COM B

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_54:	; LSR B

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_56:	; ROR B

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_57:	; ASR B

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_58:	; ASL B

	TYA		; number of bytes as required
	JMP next_op	; standard end of routine
_59:	; ROL B

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_5a:	; DEC B

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_5c:	; INC B

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_5d:	; TST B

	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_5f:	; CLR B
	STZ b68		; clear B
	LDA psr68	; get previous status
	AND #%11110100	; clear N, V, C
	ORA #%00000100	; set Z
	STA psr68	; update
	TYA			; number of bytes as required
	JMP next_op	; standard end of routine
_60:	; NEG ind
	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_63:	; COM ind
	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_64:	; LSR ind
	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_66:	; ROR ind
	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_67:	; ASR ind
	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_68:	; ASL ind
	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_69:	; ROL ind
	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_6a:	; DEC ind
	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_6c:	; INC ind
	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_6d:	; TST ind
	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_6e:	; JMP ind
	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_6f:	; CLR ind
	LDA #2		; number of bytes as required
	JMP next_op	; standard end of routine
_70:	; NEG ext
	LDA #3		; number of bytes as required
	JMP next_op	; standard end of routine
_73:	; COM ext
	LDA #3		; number of bytes as required
	JMP next_op	; standard end of routine
_74:	; LSR ext
	LDA #3		; number of bytes as required
	JMP next_op	; standard end of routine
_76:	; ROR ext
	LDA #3		; number of bytes as required
	JMP next_op	; standard end of routine
_77:	; ASR ext
	LDA #3		; number of bytes as required
	JMP next_op	; standard end of routine
_78:	; ASL ext
	LDA #3		; number of bytes as required
	JMP next_op	; standard end of routine
_79:	; ROL ext
	LDA #3		; number of bytes as required
	JMP next_op	; standard end of routine
_7a:	; DEC ext
	LDA #3		; number of bytes as required
	JMP next_op	; standard end of routine
_7c:	; INC ext
	LDA #3		; number of bytes as required
	JMP next_op	; standard end of routine
_7d:	; TST ext
	LDA #3		; number of bytes as required
	JMP next_op	; standard end of routine
_7e:	; JMP ext
	LDA #3		; number of bytes as required
	JMP next_op	; standard end of routine
_7f:	; CLR ext
	LDA #3		; number of bytes as required
	JMP next_op	; standard end of routine
_80:	; SUB A imm
	LDA #2		; number of bytes
	JMP next_op	; standard end
_81:	; CMP A imm
	LDA #2		; number of bytes
	JMP next_op	; standard end
_82:	; SBC A imm
	LDA #2		; number of bytes
	JMP next_op	; standard end
_84:	; AND A imm
	LDA #2		; number of bytes
	JMP next_op	; standard end
_85:	; BIT A imm
	LDA #2		; number of bytes
	JMP next_op	; standard end
_86:	; LDA A imm
	LDA #2		; number of bytes
	JMP next_op	; standard end
_88:	; EOR A imm
	LDA #2		; number of bytes
	JMP next_op	; standard end
_89:	; ADC A imm
	LDA #2		; number of bytes
	JMP next_op	; standard end
_8a:	; ORA A imm
	LDA #2		; number of bytes
	JMP next_op	; standard end
_8b:	; ADD A imm
	LDA #2		; number of bytes
	JMP next_op	; standard end
_8c:	; CPX imm
	LDA #3		; number of bytes
	JMP next_op	; standard end
_8d:	; BSR rel
	LDA #2		; number of bytes
	JMP next_op	; standard end
_8e:	; LDS imm
	LDA #3		; number of bytes
	JMP next_op	; standard end
_90:	; SUB A dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_91:	; CMP A dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_92:	; SBC A dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_94:	; AND A dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_95:	; BIT A dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_96:	; LDA A dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_97:	; STA A dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_98:	; EOR A dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_99:	; ADC A dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_9a:	; ORA A dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_9b:	; ADD A dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_9c:	; CPX dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_9e:	; LDS dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_9f:	; STS dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_a0:	; SUB A ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_a1:	; CMP A ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_a2:	; SBC A ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_a4:	; AND A ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_a5:	; BIT A ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_a6:	; LDA A ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_a7:	; STA A ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_a8:	; EOR A ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_a9:	; ADC A ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_aa:	; ORA A ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_ab:	; ADD A ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_ac:	; CPX ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_ad:	; JSR ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_ae:	; LDS ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_af:	; STS ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_b0:	; SUB A ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_b1:	; CMP A ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_b2:	; SBC A ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_b4:	; AND A ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_b5:	; BIT A ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_b6:	; LDA A ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_b7:	; STA A ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_b8:	; EOR A ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_b9:	; ADC A ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_ba:	; ORA A ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_bb:	; ADD A ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_bc:	; CPX ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_bd:	; JSR ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_be:	; LDS ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_bf:	; STS ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_c0:	; SUB B imm
	LDA #2		; number of bytes
	JMP next_op	; standard end
_c1:	; CMP B imm
	LDA #2		; number of bytes
	JMP next_op	; standard end
_c2:	; SBC B imm
	LDA #2		; number of bytes
	JMP next_op	; standard end
_c4:	; AND B imm
	LDA #2		; number of bytes
	JMP next_op	; standard end
_c5:	; BIT B imm
	LDA #2		; number of bytes
	JMP next_op	; standard end
_c6:	; LDA B imm
	LDA #2		; number of bytes
	JMP next_op	; standard end
_c8:	; EOR B imm
	LDA #2		; number of bytes
	JMP next_op	; standard end
_c9:	; ADC B imm
	LDA #2		; number of bytes
	JMP next_op	; standard end
_ca:	; ORA B imm
	LDA #2		; number of bytes
	JMP next_op	; standard end
_cb:	; ADD B imm
	LDA #2		; number of bytes
	JMP next_op	; standard end
_ce:	; LDX ind
	LDA #3		; number of bytes
	JMP next_op	; standard end
_d0:	; SUB B dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_d1:	; CMP B dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_d2:	; SBC B dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_d4:	; AND B dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_d5:	; BIT B dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_d6:	; LDA B dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_d7:	; STA B dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_d8:	; EOR B dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_d9:	; ADC B dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_da:	; ORA B dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_db:	; ADD B dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_de:	; LDX dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_df:	; STX dir
	LDA #2		; number of bytes
	JMP next_op	; standard end
_e0:	; SUB B ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_e1:	; CMP B ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_e2:	; SBC B ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_e4:	; AND B ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_e5:	; BIT B ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_e6:	; LDA B ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_e7:	; STA B ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_e8:	; EOR B ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_e9:	; ADC B ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_ea:	; ORA B ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_eb:	; ADD B ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_ee:	; LDX ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_ef:	; STX ind
	LDA #2		; number of bytes
	JMP next_op	; standard end
_f0:	; SUB B ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_f1:	; CMP B ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_f2:	; SBC B ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_f4:	; AND B ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_f5:	; BIT B ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_f6:	; LDA B ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_f7:	; STA B ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_f8:	; EOR B ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_f9:	; ADC B ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_fa:	; ORA B ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_fb:	; ADD B ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_fe:	; LDX ext
	LDA #3		; number of bytes
	JMP next_op	; standard end
_ff:	; STX ext
	LDA #3		; number of bytes
	JMP next_op	; standard end

; *** opcode execution addresses table ***
; should stay no matter the CPU!
optable_l:
	.word	_00
	.word	_01
	.word	_02
	.word	_03
	.word	_04
	.word	_05
	.word	_06
	.word	_07
	.word	_08
	.word	_09
	.word	_0a
	.word	_0b
	.word	_0c
	.word	_0d
	.word	_0e
	.word	_0f
	.word	_10
	.word	_11
	.word	_12
	.word	_13
	.word	_14
	.word	_15
	.word	_16
	.word	_17
	.word	_18
	.word	_19
	.word	_1a
	.word	_1b
	.word	_1c
	.word	_1d
	.word	_1e
	.word	_1f
	.word	_20
	.word	_21
	.word	_22
	.word	_23
	.word	_24
	.word	_25
	.word	_26
	.word	_27
	.word	_28
	.word	_29
	.word	_2a
	.word	_2b
	.word	_2c
	.word	_2d
	.word	_2e
	.word	_2f
	.word	_30
	.word	_31
	.word	_32
	.word	_33
	.word	_34
	.word	_35
	.word	_36
	.word	_37
	.word	_38
	.word	_39
	.word	_3a
	.word	_3b
	.word	_3c
	.word	_3d
	.word	_3e
	.word	_3f
	.word	_40
	.word	_41
	.word	_42
	.word	_43
	.word	_44
	.word	_45
	.word	_46
	.word	_47
	.word	_48
	.word	_49
	.word	_4a
	.word	_4b
	.word	_4c
	.word	_4d
	.word	_4e
	.word	_4f
	.word	_50
	.word	_51
	.word	_52
	.word	_53
	.word	_54
	.word	_55
	.word	_56
	.word	_57
	.word	_58
	.word	_59
	.word	_5a
	.word	_5b
	.word	_5c
	.word	_5d
	.word	_5e
	.word	_5f
	.word	_60
	.word	_61
	.word	_62
	.word	_63
	.word	_64
	.word	_65
	.word	_66
	.word	_67
	.word	_68
	.word	_69
	.word	_6a
	.word	_6b
	.word	_6c
	.word	_6d
	.word	_6e
	.word	_6f
	.word	_70
	.word	_71
	.word	_72
	.word	_73
	.word	_74
	.word	_75
	.word	_76
	.word	_77
	.word	_78
	.word	_79
	.word	_7a
	.word	_7b
	.word	_7c
	.word	_7d
	.word	_7e
	.word	_7f
optable_h:
	.word	_80
	.word	_81
	.word	_82
	.word	_83
	.word	_84
	.word	_85
	.word	_86
	.word	_87
	.word	_88
	.word	_89
	.word	_8a
	.word	_8b
	.word	_8c
	.word	_8d
	.word	_8e
	.word	_8f
	.word	_90
	.word	_91
	.word	_92
	.word	_93
	.word	_94
	.word	_95
	.word	_96
	.word	_97
	.word	_98
	.word	_99
	.word	_9a
	.word	_9b
	.word	_9c
	.word	_9d
	.word	_9e
	.word	_9f
	.word	_a0
	.word	_a1
	.word	_a2
	.word	_a3
	.word	_a4
	.word	_a5
	.word	_a6
	.word	_a7
	.word	_a8
	.word	_a9
	.word	_aa
	.word	_ab
	.word	_ac
	.word	_ad
	.word	_ae
	.word	_af
	.word	_b0
	.word	_b1
	.word	_b2
	.word	_b3
	.word	_b4
	.word	_b5
	.word	_b6
	.word	_b7
	.word	_b8
	.word	_b9
	.word	_ba
	.word	_bb
	.word	_bc
	.word	_bd
	.word	_be
	.word	_bf
	.word	_c0
	.word	_c1
	.word	_c2
	.word	_c3
	.word	_c4
	.word	_c5
	.word	_c6
	.word	_c7
	.word	_c8
	.word	_c9
	.word	_ca
	.word	_cb
	.word	_cc
	.word	_cd
	.word	_ce
	.word	_cf
	.word	_d0
	.word	_d1
	.word	_d2
	.word	_d3
	.word	_d4
	.word	_d5
	.word	_d6
	.word	_d7
	.word	_d8
	.word	_d9
	.word	_da
	.word	_db
	.word	_dc
	.word	_dd
	.word	_de
	.word	_df
	.word	_e0
	.word	_e1
	.word	_e2
	.word	_e3
	.word	_e4
	.word	_e5
	.word	_e6
	.word	_e7
	.word	_e8
	.word	_e9
	.word	_ea
	.word	_eb
	.word	_ec
	.word	_ed
	.word	_ee
	.word	_ef
	.word	_f0
	.word	_f1
	.word	_f2
	.word	_f3
	.word	_f4
	.word	_f5
	.word	_f6
	.word	_f7
	.word	_f8
	.word	_f9
	.word	_fa
	.word	_fb
	.word	_fc
	.word	_fd
	.word	_fe
	.word	_ff
