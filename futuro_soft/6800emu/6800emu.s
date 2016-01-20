; 6800 emulator for minimOS!
; v0.1a1
; (c) 2016 Carlos J. Santisteban
; last modified 20160120

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
		TXA				; X will receive number of bytes for last instruction! (2)
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
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_06:	; TAP
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_08:	; INX
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_09:	; DEX
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_0a:	; CLV
	RMB1 psr68	; clear V bit, Rockwell only!
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_0b:	; SEV
	SMB1 psr68	; set V bit, Rockwell only!
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_0c:	; CLC
	RMB0 psr68	; clear C bit, Rockwell only!
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_0d:	; SEC
	SMB0 psr68	; set C bit, Rockwell only!
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_0e:	; CLI
	RMB4 psr68	; clear I bit, Rockwell only!
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_0f:	; SEI
	SMB4 psr68	; set I bit, Rockwell only!
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_10:	; SBA

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_11:	; CBA

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_16:	; TAB

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_17:	; TBA

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_19:	; DAA

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_1b:	; ABA

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_20:	; BRA rel

	LDX #2		; number of bytes as required
	JMP next_op	; standard end of routine
_22:	; BHI rel

	LDX #2		; number of bytes as required
	JMP next_op	; standard end of routine
_23:	; BLS rel

	LDX #2		; number of bytes as required
	JMP next_op	; standard end of routine
_24:	; BCC rel

	LDX #2		; number of bytes as required
	JMP next_op	; standard end of routine
_25:	; BCS rel

	LDX #2		; number of bytes as required
	JMP next_op	; standard end of routine
_26:	; BNE rel

	LDX #2		; number of bytes as required
	JMP next_op	; standard end of routine
_27:	; BEQ rel

	LDX #2		; number of bytes as required
	JMP next_op	; standard end of routine
_28:	; BVC rel

	LDX #2		; number of bytes as required
	JMP next_op	; standard end of routine
_29:	; BVS rel

	LDX #2		; number of bytes as required
	JMP next_op	; standard end of routine
_2a:	; BPL rel

	LDX #2		; number of bytes as required
	JMP next_op	; standard end of routine
_2b:	; BMI rel

	LDX #2		; number of bytes as required
	JMP next_op	; standard end of routine
_2c:	; BGE rel

	LDX #2		; number of bytes as required
	JMP next_op	; standard end of routine
_2d:	; BLT rel

	LDX #2		; number of bytes as required
	JMP next_op	; standard end of routine
_2e:	; BGT rel

	LDX #2		; number of bytes as required
	JMP next_op	; standard end of routine
_2f:	; BLE rel

	LDX #2		; number of bytes as required
	JMP next_op	; standard end of routine
_30:	; TSX

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_31:	; INS

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_32:	; PUL A

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_33:	; PUL B

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_34:	; DES

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_35:	; TXS

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_36:	; PSH A

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_37:	; PSH B

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_39:	; RTS

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_3b:	; RTI

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_3e:	; WAI

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_3f:	; SWI

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_40:	; NEG A

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_43:	; COM A

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_44:	; LSR A

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_46:	; ROR A

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_47:	; ASR A

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_48:	; ASL A

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_49:	; ROL A

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_4a:	; DEC A

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_4c:	; INC A

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_4d:	; TST A

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_4f:	; CLR A
	STZ a68		; clear A
	LDA psr68	; get previous status
	AND #%11110100	; clear N, V, C
	ORA #%00000100	; set Z
	SRA psr68	; update
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_50:	; NEG B

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_53:	; COM B

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_54:	; LSR B

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_56:	; ROR B

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_57:	; ASR B

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_58:	; ASL B

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_59:	; ROL B

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_5a:	; DEC B

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_5c:	; INC B

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_5d:	; TST B

	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_5f:	; CLR B
	STZ b68		; clear B
	LDA psr68	; get previous status
	AND #%11110100	; clear N, V, C
	ORA #%00000100	; set Z
	SRA psr68	; update
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine
_07:	; TPA
	LDX #1		; number of bytes as required
	JMP next_op	; standard end of routine


; *** opcode execution addresses table ***
optable_l:
	.word	_00
	.word	_01
	.word	_
