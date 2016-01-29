; 6800 emulator for minimOS!
; v0.1a1
; (c) 2016 Carlos J. Santisteban
; last modified 20160129

#include "../../OS/options.h"	; machine specific
#include "../../OS/macros.h"
#include "../../OS/abi.h"		; ** new filename **
.zero
#include "../../OS/zeropage.h"
.bss
#include "../../OS/firmware/firmware.h"	; machine specific
#include "../../OS/sysvars.h"
.text

; ** some useful macros **
; these need to be used in xa65, might go into macros.h
#define	RMB0	RMB #0,
#define RMB1	RMB #1,
#define RMB2	RMB #2,
#define RMB3	RMB #3,
#define RMB4	RMB #4,
#define RMB5	RMB #5,
#define RMB6	RMB #6,
#define RMB7	RMB #7,
#define SMB0	SMB #0,
#define SMB1	SMB #1,
#define SMB2	SMB #2,
#define SMB3	SMB #3,
#define SMB4	SMB #4,
#define SMB5	SMB #5,
#define SMB6	SMB #6,
#define SMB7	SMB #7,
; these almost got me nuts!
#define BBR0	BBR #0,
#define BBR1	BBR #1,
#define BBR2	BBR #2,
#define BBR3	BBR #3,
#define BBR4	BBR #4,
#define BBR5	BBR #5,
#define BBR6	BBR #6,
#define BBR7	BBR #7,
#define BBS0	BBS #0,
#define BBS1	BBS #1,
#define BBS2	BBS #2,
#define BBS3	BBS #3,
#define BBS4	BBS #4,
#define BBS5	BBS #5,
#define BBS6	BBS #6,
#define BBS7	BBS #7,

; these make listings more succint
; inject address MSB into 16+16K space (5...6)
#define	_AH_BOUND	AND #%10111111: BMI *+4: ORA #%01000000
; increase Y checking injected boundary crossing (5...18)
#define _PC_ADV		INY: BNE *+13: LDA pc68+1: INC: _AH_BOUND: STA pc68+1
; check Z & N flags (6...14)
#define _CC_NZ		BNE *+4: SMB2 psr68: BPL *+4: SMB3 psr68

; ** minimOS executable header will go here **

; declare zeropage addresses
pc68	=	uz		; program counter (16 bit, little-endian)
sp68	=	uz+2	; stack pointer (16 bit, little-endian)
x68		=	uz+4	; index register (16 bit, little-endian)
a68		=	uz+6	; first accumulator (8 bit)
b68		=	uz+7	; second accumulator (8 bit)
psr68	=	uz+8	; status register (8 bit)
tmptr	=	uz+9	; temporary storage (up to 16 bit)

; *** startup code ***
#ifdef	SAFE
	LDA z_used		; check available zeropage space
	CMP #tmptr-uz+2		; currently needed space
	BCS go_emu		; enough space
		_ERR(FULL)		; not enough memory otherwise (rare)
go_emu:
#endif
; might check here whether a Rockwell 65C02 is used!
	LDA #tmptr-uz+2		; actually needed zeropage space
	STA z_used		; set value as required
; should try to allocate memory here

; *** start the emulation! ***
reset68:
	LDY $BFFF		; get RESET vector LSB from emulated ROM (this is big-endian!)
	LDA $BFFE		; same for MSB... but create offset!
	_AH_BOUND		; use two 16K chunks ignoring A14
	STZ pc68		; base offset is 0, Y index holds LSB
	STA pc68+1		; address fully generated
; *** main loop ***
execute:
		LDA (pc68), Y		; get opcode (needs CMOS) (5)
		ASL				; double it as will become pointer (2)
		TAX				; use as pointer, keeping carry (2)
		BCC lo_jump		; seems to be less opcodes with bit7 low... (2/3)
			JMP (optable_h, X)	; emulation routines for opcodes with bit7 hi (6)
lo_jump:
			JMP (optable_l, X)	; otherwise, emulation routines for opcodes with bit7 low
next_op:					; continue execution via JMP next_op, will not arrive here otherwise
		INY			; advance one byte (2)
		BNE execute		; fetch next instruction if no boundary is crossed (3/2)
; usual overhead is now 22+3=25 clock cycles, instead of 33
; boundary crossing **original version is 15-16 cycles, 12 bytes**
	INC pc68 + 1		; increase MSB otherwise, faster than using 'that macro' (5)
	BMI negative		; this will be in ROM area (3/2)
		SMB6 pc68 + 1		; in RAM area, A14 is always high (5) *** Rockwell
		BRA execute		; fetch next (3)
negative:
	RMB6 pc68 + 1		; in ROM area, A14 is always low (5) *** Rockwell
	BRA execute		; fetch next (3) worst case 39+3 cycles

; alternative is 15-16 cycles, 17 bytes **NOT WORTH here but perhaps for other memory schemes**
;	LDA pc68+1			; get MSB (3)
;	INC					; advance (2)
;	BMI negative		; into emulated ROM? (3/2)
;		ORA #%01000000		; otherwise set A14 (0/2)
;		STA pc68+1			; update pointer (0/3)
;		BRA execute			; continue (0/3)
;negative:
;	AND #10111111		; inject into lower 16K ROM (2/0)
;	STA pc68+1			; update pointer (3/0)
;	BRA execute			; continue (3/0)

; *** opcode execution routines, labels must match those on tables below ***
; unsupported opcodes first
_00:_02:_03:_04:_05:_12:_13:_14:_15:_18:_1a:_1c:_1d:_1e:_1f:_21:_38:_3a:_3c:_3d
_41:_42:_45:_4b:_4e:_51:_52:_55:_5b:_5e:_61:_62:_65:_6b:_71:_72:_75:_7b
_83:_87:_8f:_93:_9d:_a3:_b3:_c3:_c7:_cc:_cd:_cf:_d3:_dc:_dd:_e3:_ec:_ed:_f3:_fc:_fd
	BRK		; *** really do not know what to do upon an illegal opcode!

; valid opcode definitions
_01:
; NOP (2)
	JMP next_op	; standard end of routine (all +3 unless otherwise noted)

_06:
; TAP (2)
	LDA a68		; get A accumulator...
	STA psr68	; ...and store it in CCR (+6)
	JMP next_op	; standard end of routine

_07:
; TPA (2)
	LDA psr68	; get CCR...
	STA a68		; ...and store it in A (+6)
	JMP next_op	; standard end of routine

_08:
; INX (4) faster 22 bytes
	INC x68		; increase LSB
	BEQ inx_w	; wrap is a rare case
		RMB2 psr68	; clear Z bit, *** Rockwell only! ***
		JMP next_op	; usual end (+12 mostly, worth it)
inx_w:
	INC x68 + 1	; increase MSB
	BEQ inx_z	; becoming zero is even rarer!
		RMB2 psr68	; clear Z bit, *** Rockwell only! ***
		JMP next_op	; wrapped non-zero end (+20 in this case)
inx_z:
	SMB2 psr68	; set Z bit, *** Rockwell only! *** (+21 worst case)
	JMP next_op	; rarest end of routine

_09:
; DEX (4)
	DEC x68		; decrease LSB
	BEQ dex_z	; could be zero
		LDX x68		; let us see...
		CPX #$FF	; check for wrap
		BEQ dex_w	; wrap is a rare case
			RMB2 psr68	; clear Z bit, *** Rockwell only! ***
			JMP next_op	; usual end (+19 mostly)
dex_w:
		DEC x68 + 1	; decrease MSB
		RMB2 psr68	; clear Z bit, *** Rockwell only! ***
		JMP next_op	; wrapped non-zero end (+25 worst case)
dex_z:
	LDX x68 + 1	; let us see the MSB contents
	BEQ dex_zz	; it really is all zeroes!
		RMB2 psr68	; clear Z bit, *** Rockwell only! ***
		JMP next_op	; go away otherwise (+18)
dex_zz:
	SMB2 psr68	; set Z bit, *** Rockwell only! ***
	JMP next_op	; rarest end of routine (+19 in this case)

_0a:
; CLV (2)
	RMB1 psr68	; clear V bit, *** Rockwell only! *** (+5)
	JMP next_op	; standard end of routine

_0b:
; SEV (2)
	SMB1 psr68	; set V bit, *** Rockwell only! *** (+5)
	JMP next_op	; standard end of routine

_0c:
; CLC (2)
	RMB0 psr68	; clear C bit, *** Rockwell only! *** (+5)
	JMP next_op	; standard end of routine

_0d:
; SEC (2)
	SMB0 psr68	; set C bit, *** Rockwell only! *** (+5)
	JMP next_op	; standard end of routine

_0e:
; CLI (2)
	RMB4 psr68	; clear I bit, *** Rockwell only! *** (+5)
	JMP next_op	; standard end of routine

_0f:
; SEI (2)
	SMB4 psr68	; set I bit, *** Rockwell only! *** (+5)
	JMP next_op	; standard end of routine

_10:
; SBA (2)
	LDA a68		; get A
	BPL sba_nm	; skip if was positive
		SMB1 psr68	; set V like N, to be toggled later ***Rockwell***
		BRA sba_sv	; do not clear V
sba_nm:
	RMB1 psr68	; clear V ***Rockwell***
sba_sv:
	SEC			; prepare for subtraction
	SBC b68		; minus B
	STA a68		; store result in A
	LDA psr68	; get original flags
	LDA #%11110010	; mask out affected bits (but keep V)
	BCC sba_nc	; check for carry, will it work just like the 6502?
		INC			; will set C flag
sba_nc:
	LDX a68		; retrieve value
	BNE sba_nz	; skip if not zero
		ORA #%00000100	; set Z flag
sba_nz:
	LDX a68		; retrieve again!
	BPL sba_pl	; skip if positive
		ORA #%00001000	; set N flag
		EOR #%00000010	; toggle V flag (see above)
sba_pl:
	STA psr68	; update flags
	JMP next_op	; standard end of routine (+42...49)

_11:
; CBA (2)
	LDA a68		; get A
	BPL cba_nm	; skip if was positive
		SMB1 psr68	; set V like N, to be toggled later ***Rockwell***
		BRA cba_sv	; do not clear V
cba_nm:
	RMB1 psr68	; clear V ***Rockwell***
cba_sv:
	SEC			; prepare subtraction, simulating comparison
	SBC b68		; minus B
	TAX			; store for later
	LDA psr68	; get original flags
	LDA #%11110010	; mask out affected bits (but keep V)
	BCC cba_nc	; check for carry, will it work just like the 6502?
		INC			; will set C flag
cba_nc:
	CPX #0		; test value, hope it is OK
	BNE cba_nz	; skip if not zero
		ORA #%00000100	; set Z flag
cba_nz:
	CPX #0		; retrieve again!
	BPL cba_pl	; skip if positive
		ORA #%00001000	; set N flag
		EOR #%00000010	; toggle V flag (see above)
cba_pl:
	STA psr68	; update status (+39...46)
	JMP next_op	; standard end of routine

_16:
; TAB (2)
	LDA psr68	; get original flags
	AND #%11110001	; reset N,Z, and always V
	STA psr68	; update status
	LDX a68		; get A
	STX b68		; store in B
	_CC_NZ		; set NZ flags when needed
	JMP next_op	; standard end of routine (+20...28)

_17:
; TBA (2)
	LDA psr68	; get original flags
	AND #%11110001	; reset N,Z, and always V
	STA psr68	; update status
	LDX b68		; get B
	STX a68		; store in A
	_CC_NZ		; check these flags
	JMP next_op	; standard end of routine (+20...28)

_19:
; DAA (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end of routine

_1b:
; ABA (2)
	LDA a68		; get A
	BPL aba_nm	; skip if was positive
		SMB1 psr68	; set V like N, to be toggled later ***Rockwell***
		BRA aba_sv	; do not clear V
aba_nm:
	RMB1 psr68	; clear V ***Rockwell***
aba_sv:
	CLC			; prepare to add
	ADC b68		; plus B
	STA a68		; store result in A
	LDA psr68	; get original flags
	LDA #%11110010	; mask out affected bits (but keep V)
	BCC aba_nc	; check for carry, will it work just like the 6502?
		INC			; will set C flag
aba_nc:
	LDX a68		; retrieve value
	BNE aba_nz	; skip if not zero
		ORA #%00000100	; set Z flag
aba_nz:
	LDX a68		; retrieve again!
	BPL aba_pl	; skip if positive
		ORA #%00001000	; set N flag
		EOR #%00000010	; toggle V flag (see above)
aba_pl:
	STA psr68	; update status (+42...49)
	JMP next_op	; standard end of routine

_20:
; BRA rel (4)
	_PC_ADV			; go for operand (5...18)
bra_do:
	SEC				; base offset is after the instruction
	LDA (pc68), Y	; check direction
	BMI bra_bk		; backwards jump
		TYA				; get current pc low
		ADC (pc68), Y	; add offset
		TAY				; new offset!!!
		BCS bra_bc		; same msb, go away
bra_go:
			JMP execute		; resume execution (-5 because jump, here +28...42)
bra_bc:
; this version is 14 bytes, 15-16 cycles
		INC pc68 + 1	; carry on msb
		BPL bra_lf		; skip if in low area
			RMB6 pc68+1		; otherwise clear A14
			JMP execute		; and jump
bra_lf:
		SMB6 pc68+1			; low area needs A14 set
		JMP execute
; this other version is 14 bytes, 16-17 clocks, perhaps worth in other schemes
;			LDA pc68+1	; get MSB
;			INC			; increase
;			_AH_BOUND	; inject into emulated space
;			STA pc68+1	; update pointer
;bra_go:
;		JMP execute	; do jump
bra_bk:
	TYA				; get current pc low
	ADC (pc68), Y	; "subtract" offset
	TAY				; new offset!!!
		BCS bra_go		; all done
	DEC pc68 + 1	; borrow on msb
		BPL bra_lf		; skip if in low area
 	RMB6 pc68+1		; otherwise clear A14
	JMP execute		; and jump

_22:
; BHI rel (4)
	_PC_ADV			; go for operand
	BBS0 psr68, bhi_go	; neither carry...
	BBS2 psr68, bhi_go	; ...nor zero...
		JMP bra_do		; ...do branch (+11...50)
bhi_go:
	JMP next_op	; exit without branching

_23:
; BLS rel (4)
	_PC_ADV			; go for operand
	BBS0 psr68, bls_do	; either carry...
	BBS2 psr68, bls_do	; ...or zero will do
		JMP next_op	; exit without branching
bls_do:
		JMP bra_do		; do branch (+15...51)

_24:
; BCC rel (4)
	_PC_ADV			; go for operand
	BBS0 psr68, bcc_go	; only if carry clear...
		JMP bra_do		; ...do branch (+11...45)
bcc_go:
	JMP next_op		; exit without branching

_25:
; BCS rel (4)
	_PC_ADV			; go for operand
	BBR0 psr68, bcs_go	; only if carry set...
		JMP bra_do		; ...do branch (+11...45)
bcs_go:
	JMP next_op		; exit without branching

_26:
; BNE rel (4)
	_PC_ADV			; go for operand
	BBS2 psr68, bne_go	; only if zero clear...
		JMP bra_do		; ...do branch (+11...45)
bne_go:
	JMP next_op		; exit without branching

_27:
; BEQ rel (4)
	_PC_ADV			; go for operand
	BBR2 psr68, beq_go	; only if zero set...
		JMP bra_do		; ...do branch (+11...45)
beq_go:
	JMP next_op		; exit without branching

_28:
; BVC rel (4)
	_PC_ADV			; go for operand
	BBS1 psr68, bvc_go	; only if overflow clear...
		JMP bra_do		; ...do branch (+11...45)
bvc_go:
	JMP next_op		; exit without branching

_29:
; BVS rel (4)
	_PC_ADV			; go for operand
	BBR1 psr68, bvs_go	; only if overflow set...
		JMP bra_do		; ...do branch (+11...45)
bvs_go:
	JMP next_op		; exit without branching

_2a:
; BPL rel (4)
	_PC_ADV			; go for operand
	BBS3 psr68, bpl_go	; only if plus...
		JMP bra_do		; ...do branch (+11...45)
bpl_go:
	JMP next_op		; exit without branching

_2b:
; BMI rel (4)
	_PC_ADV			; go for operand
	BBR3 psr68, bmi_go	; only if negative...
		JMP bra_do		; ...do branch (+11...45)
bmi_go:
	JMP next_op		; exit without branching

_2c:
; BGE rel (4)
	_PC_ADV			; go for operand
	LDA psr68		; get flags
	AND #%00001010	; filter N and V only
	BIT #%00000010	; check V
	BEQ bge_nx		; do not XOR N if clear
		EOR #%00001000	; toggle N
bge_nx:
	BNE bge_go		; N XOR V is one, do not branch
		JMP bra_do		; jump otherwise (+18...53)?
bge_go:
	JMP next_op		; exit without branching

_2d:
; BLT rel (4)
	_PC_ADV			; go for operand
	LDA psr68		; get flags
	AND #%00001010	; filter N and V only
	BIT #%00000010	; check V
	BEQ blt_nx		; do not XOR N if clear
		EOR #%00001000	; toggle N
blt_nx:
	BEQ blt_go		; N XOR V is zero, do not branch
		JMP bra_do		; jump otherwise (+18...53)?
blt_go:
	JMP next_op		; exit without branching

_2e:
; BGT rel (4)
	_PC_ADV			; go for operand
	LDA psr68		; get flags
	AND #%00011010	; filter Z, N and V
	BIT #%00000010	; check V
	BEQ bgt_nx		; do not XOR N if clear
		EOR #%00001000	; toggle N
bgt_nx:
	BNE bgt_go		; N XOR V (OR Z) is one, do not branch
		JMP bra_do		; jump otherwise (+18...53)?
bgt_go:
	JMP next_op		; exit without branching

_2f:
; BLE rel (4)
	_PC_ADV			; go for operand
	BBS2 psr68, ble_do	; will branch if zero
		LDA psr68		; get flags
		AND #%00001010	; filter N and V only
		BIT #%00000010	; check V
		BEQ ble_nx		; do not XOR N if clear
			EOR #%00001000	; toggle N
ble_nx:
		BEQ ble_go		; N XOR V is zero, do not branch
ble_do:
	JMP bra_do		; jump otherwise (+23...58) maybe worth like BGT
ble_go:
	JMP next_op		; exit without branching

_30:
; TSX (4)
	LDA sp68		; get stack pointer LSB
	STA x68			; store in X
	LDA sp68 + 1	; same for MSB (+12)
	STA x68 + 1
	JMP next_op		; standard end of routine

_31:
; INS (4)
	INC sp68	; increase LSB
	BEQ ins_w	; wrap is a rare case
		JMP next_op	; usual end (+7 mostly)
ins_w:
	INC sp68 + 1	; increase MSB
	JMP next_op		; wrapped end (+13 worst case)

_32:
; PUL A (4)
	; ***** TO DO ***** TO DO *****
	
	JMP next_op	; standard end of routine

_33:
; PUL B (4)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_34:
; DES (4)
	DEC sp68	; decrease LSB
	LDX sp68	; let us see...
	CPX #$FF	; check for wrap
	BEQ des_w	; wrap is a rare case
		JMP next_op	; usual end (+12 mostly)
des_w:
	DEC sp68 + 1	; decrease MSB
	JMP next_op	; wrapped end (+18 worst case)

_35:
; TXS (4)
	LDA x68		; get X LSB
	STA sp68	; store as stack pointer
	LDA x68 + 1	; same for MSB (+12)
	STA sp68 + 1
	JMP next_op	; standard end of routine

_36:
; PSH A (4)
	; ***** TO DO ***** TO DO *****
	LDX sp68		; get SP LSB
	LDA sp68 + 1	; now for MSB
	_AH_BOUND		; but inject it into emulated space
	STX tmptr		; store in pointer
	STA sp68 + 1	; pointer is ready
	DEX				; and post-decrease
	CPX #$FF		; check for wrap
	BEQ psha_w		; rare case
		LDA a68			; get A contents
	STA (tmptr)	; store in into stack space
	DEC sp68	; post-decrease
	LDX
	JMP next_op	; standard end of routine

_37:
; PSH B (4)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_39:
; RTS (5)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_3b:
; RTI (10)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_3e:
; WAI (9)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_3f:
; SWI (12)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_40:
; NEG A (2)
	LDA psr68	; get original flags
	AND #%11110000	; reset relevant bits
	STA psr68	; update status
	SEC			; prepare subtraction
	LDA #0
	SBC a68		; negate A
	STA a68		; update value
	_CC_NZ		; check these
	CMP #$80	; did change sign?
	BNE nega_nv	; skip if not V
		SMB1 psr68	; set V flag
nega_nv:
	JMP next_op	; standard end of routine (+29...41)

_43:
; COM A (2)
	LDA psr68	; get original flags
	AND #%11110000	; reset relevant bits
	INC			; C always set
	STA psr68	; update status
	LDA a68		; get A
	EOR #$FF	; complement it
	STA a68		; update value
	_CC_NZ		; check these
	CPX #$80	; did change sign?
	BNE coma_nv	; skip if not V
		SMB1 psr68	; set V flag
coma_nv:
	JMP next_op	; standard end of routine (+29...41)

_44:
; LSR A (2)
	LDA psr68	; get original flags
	AND #%11110000	; reset relevant bits (N always reset)
	LSR a68		; shift A right
	BNE lsra_nz	; skip if not zero
		ORA #%00000100	; set Z flag
lsra_nz:
	BCC lsra_nc	; skip if there was no carry
		ORA #%00000011	; will set C and V flags
lsra_nc:
	STA psr68	; update status (+19...21)
	JMP next_op	; standard end of routine

_46:
; ROR A (2)
	CLC			; prepare
	LDA psr68	; get original flags
	BIT #%00000001	; mask for C flag
	BEQ rora_do	; skip if C clear
		SEC			; otherwise, set carry
rora_do:
	AND #%11110000	; reset relevant bits
	ROR a68		; rotate A right
	BNE rora_nz	; skip if not zero
		ORA #%00000100	; set Z flag
rora_nz:
	LDX a68		; retrieve again!
	BPL rora_pl	; skip if positive
		ORA #%00001000	; will set N bit
		EOR #%00000010	; toggle V bit
rora_pl:
	BCC rora_nc	; skip if there was no carry
		ORA #%00000001	; will set C flag
		EOR #%00000010	; toggle V bit
rora_nc:
	STA psr68	; update status (+32...40)
	JMP next_op	; standard end of routine

_47:
; ASR A (2)
	LDA psr68	; get original flags
	AND #%11110000	; reset relevant bits
	CLC			; prepare
	BIT a68		; check bit 7
	BPL asra_do	; do not insert C if clear
		SEC			; otherwise, set carry
asra_do:
	ROR a68		; emulate aritmetic shift left with preloaded-C rotation
	BNE asra_nz	; skip if not zero
		ORA #%00000100	; set Z flag
asra_nz:
	LDX a68		; retrieve again!
	BPL asra_pl	; skip if positive
		ORA #%00001000	; will set N bit
		EOR #%00000010	; toggle V bit
asra_pl:
	BCC asra_nc	; skip if there was no carry
		ORA #%00000001	; will set C flag
		EOR #%00000010	; toggle V bit
asra_nc:
	STA psr68	; update status (+33...41)
	JMP next_op	; standard end of routine

_48:
; ASL A (2)
	LDA psr68	; get original flags
	AND #%11110000	; reset relevant bits
	ASL a68		; shift A left
	BNE asla_nz	; skip if not zero
		ORA #%00000100	; set Z flag
asla_nz:
	LDX a68		; retrieve again!
	BPL asla_pl	; skip if positive
		ORA #%00001000	; will set N bit
		EOR #%00000010	; toggle V bit
asla_pl:
	BCC asla_nc	; skip if there was no carry
		ORA #%00000001	; will set C flag
		EOR #%00000010	; toggle V bit
asla_nc:
	STA psr68	; update status (+25...32)
	JMP next_op	; standard end of routine

_49:
; ROL A (2)
	CLC			; prepare
	LDA psr68	; get original flags
	BIT #%00000001	; mask for C flag
	BEQ rola_do	; skip if C clear
		SEC			; otherwise, set carry
rola_do:
	AND #%11110000	; reset relevant bits
	ROL a68		; rotate A left
	BNE rola_nz	; skip if not zero
		ORA #%00000100	; set Z flag
rola_nz:
	LDX a68		; retrieve again!
	BPL rola_pl	; skip if positive
		ORA #%00001000	; will set N bit
		EOR #%00000010	; toggle V bit
rola_pl:
	BCC rola_nc	; skip if there was no carry
		ORA #%00000001	; will set C flag
		EOR #%00000010	; toggle V bit
rola_nc:
	STA psr68	; update status (+32...40)
	JMP next_op	; standard end of routine

_4a:
; DEC A (2)
	LDA psr68	; get original status
	AND #%11110001	; reset all relevant bits for CCR
	STA psr68	; store new flags
	DEC a68		; decrease A
	_CC_NZ		; check these
	LDX a68		; check it!
	CPX #$7F	; did change sign?
	BNE deca_nv	; skip if not overflow
		SMB1 psr68	; will set V flag
deca_nv:
	JMP next_op	; standard end of routine (+27...39)

_4c:
; INC A (2)
	LDA psr68	; get original status
	AND #%11110001	; reset all relevant bits for CCR 
	STA psr68	; store new flags
	INC a68		; increase A
	_CC_NZ		; check these
	LDX a68		; check it!
	CPX #$80	; did change sign?
	BNE inca_nv	; skip if not overflow
		SMB1 psr68	; will set V flag
inca_nv:
	JMP next_op	; standard end of routine (+27...39)

_4d:
; TST A (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end of routine

_4f:
; CLR A (2)
	STZ a68		; clear A
	LDA psr68	; get previous status
	AND #%11110100	; clear N, V, C
	ORA #%00000100	; set Z
	STA psr68	; update (+13)
	JMP next_op	; standard end of routine

_50:
; NEG B (2)
	LDA psr68	; get original flags
	AND #%11110000	; reset relevant bits
	STA psr68	; update status
	SEC			; prepare subtraction
	LDA #0
	SBC b68		; negate B
	STA b68		; update value
	_CC_NZ		; check these
	CMP #$80	; did change sign?
	BNE negb_nv	; skip if not V
		SMB1 psr68	; set V flag
negb_nv:
	JMP next_op	; standard end of routine (+29...41)

_53:
; COM B (2)
	LDA psr68	; get original flags
	AND #%11110000	; reset relevant bits
	INC			; C always set
	STA psr68	; update status
	LDA b68		; get B
	EOR #$FF	; complement it
	STA b68		; update value
	_CC_NZ		; check these
	CPX #$80	; did change sign?
	BNE comb_nv	; skip if not V
		SMB1 psr68	; set V flag
comb_nv:
	JMP next_op	; standard end of routine (+29...41)

_54:
; LSR B (2)
	LDA psr68	; get original flags
	AND #%11110000	; reset relevant bits (N always reset)
	LSR b68		; shift B right
	BNE lsrb_nz	; skip if not zero
		ORA #%00000100	; set Z flag
lsrb_nz:
	BCC lsrb_nc	; skip if there was no carry
		ORA #%00000011	; will set C and V flags
lsrb_nc:
	STA psr68	; update status (+19...21)
	JMP next_op	; standard end of routine

_56:
; ROR B (2)
	CLC			; prepare
	LDA psr68	; get original flags
	BIT #%00000001	; mask for C flag
	BEQ rorb_do	; skip if C clear
		SEC			; otherwise, set carry
rorb_do:
	AND #%11110000	; reset relevant bits
	ROR b68		; rotate B right
	BNE rorb_nz	; skip if not zero
		ORA #%00000100	; set Z flag
rorb_nz:
	LDX b68		; retrieve again!
	BPL rorb_pl	; skip if positive
		ORA #%00001000	; will set N bit
		EOR #%00000010	; toggle V bit
rorb_pl:
	BCC rorb_nc	; skip if there was no carry
		ORA #%00000001	; will set C flag
		EOR #%00000010	; toggle V bit
rorb_nc:
	STA psr68	; update status (+32...40)
	JMP next_op	; standard end of routine

_57:
; ASR B (2)
	LDA psr68	; get original flags
	AND #%11110000	; reset relevant bits
	CLC			; prepare
	BIT b68		; check bit 7
	BPL asrb_do	; do not insert C if clear
		SEC			; otherwise, set carry
asrb_do:
	ROR b68		; emulate aritmetic shift left with preloaded-C rotation
	BNE asrb_nz	; skip if not zero
		ORA #%00000100	; set Z flag
asrb_nz:
	LDX b68		; retrieve again!
	BPL asrb_pl	; skip if positive
		ORA #%00001000	; will set N bit
		EOR #%00000010	; toggle V bit
asrb_pl:
	BCC asrb_nc	; skip if there was no carry
		ORA #%00000001	; will set C flag
		EOR #%00000010	; toggle V bit
asrb_nc:
	STA psr68	; update status (+33...41)
	JMP next_op	; standard end of routine

_58:
; ASL B (2)
	LDA psr68	; get original flags
	AND #%11110000	; reset relevant bits
	ASL b68		; shift B left
	BNE aslb_nz	; skip if not zero
		ORA #%00000100	; set Z flag
aslb_nz:
	LDX b68		; retrieve again!
	BPL aslb_pl	; skip if positive
		ORA #%00001000	; will set N bit
		EOR #%00000010	; toggle V bit
aslb_pl:
	BCC aslb_nc	; skip if there was no carry
		ORA #%00000001	; will set C flag
		EOR #%00000010	; toggle V bit
aslb_nc:
	STA psr68	; update status (+25...32)
	JMP next_op	; standard end of routine

_59:
; ROL B (2)
	CLC			; prepare
	LDA psr68	; get original flags
	BIT #%00000001	; mask for C flag
	BEQ rolb_do	; skip if C clear
		SEC			; otherwise, set carry
rolb_do:
	AND #%11110000	; reset relevant bits
	ROL b68		; rotate B left
	BNE rolb_nz	; skip if not zero
		ORA #%00000100	; set Z flag
rolb_nz:
	LDX b68		; retrieve again!
	BPL rolb_pl	; skip if positive
		ORA #%00001000	; will set N bit
		EOR #%00000010	; toggle V bit
rolb_pl:
	BCC rolb_nc	; skip if there was no carry
		ORA #%00000001	; will set C flag
		EOR #%00000010	; toggle V bit
rolb_nc:
	STA psr68	; update status (+32...40)
	JMP next_op	; standard end of routine


_5a:
; DEC B (2)
	LDA psr68	; get original status
	AND #%11110001	; reset all relevant bits for CCR
	STA psr68	; store new flags
	DEC b68		; decrease B
	_CC_NZ		; check these
	LDX b68		; check it!
	CPX #$7F	; did change sign?
	BNE decb_nv	; skip if not overflow
		SMB1 psr68	; will set V flag
decb_nv:
	JMP next_op	; standard end of routine (+27...39)

_5c:
; INC B (2)
	LDA psr68	; get original status
	AND #%11110001	; reset all relevant bits for CCR 
	STA psr68	; store new flags
	INC b68		; increase B
	_CC_NZ		; check these
	LDX b68		; check it!
	CPX #$80	; did change sign?
	BNE incb_nv	; skip if not overflow
		SMB1 psr68	; will set V flag
incb_nv:
	JMP next_op	; standard end of routine (+27...39)

_5d:
; TST B (2)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end

_5f:
; CLR B (2)
	STZ b68		; clear B
	LDA psr68	; get previous status
	AND #%11110100	; clear N, V, C
	ORA #%00000100	; set Z
	STA psr68	; update (+13)
	JMP next_op	; standard end of routine

_60:
; NEG ind (7)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_63:
; COM ind (7)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_64:
; LSR ind (7)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_66:
; ROR ind (7)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_67:
; ASR ind (7)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_68:
; ASL ind (7)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_69:
; ROL ind (7)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_6a:
; DEC ind (7)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_6c:
; INC ind (7)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_6d:
; TST ind (7)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_6e:
; JMP ind
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_6f:
; CLR ind (7)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_70:
; NEG ext (6)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_73:
; COM ext (6)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_74:
; LSR ext (6)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_76:
; ROR ext (6)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_77:
; ASR ext (6)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_78:
; ASL ext (6)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_79:
; ROL ext (6)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_7a:
; DEC ext (6)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_7c:
; INC ext (6)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_7d:
; TST ext (6)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_7e:
; JMP ext
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_7f:
; CLR ext (6)
	; ***** TO DO ***** TO DO *****

	JMP next_op	; standard end of routine

_80:
; SUB A imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_81:
; CMP A imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_82:
; SBC A imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_84:
; AND A imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_85:
; BIT A imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_86:
; LDA A imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_88:
; EOR A imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_89:
; ADC A imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_8a:
; ORA A imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_8b:
; ADD A imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_8c:
; CPX imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_8d:
; BSR rel
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_8e:
; LDS imm
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_90:
; SUB A dir (3)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_91:
; CMP A dir (3)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_92:
; SBC A dir (3)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_94:
; AND A dir (3)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_95:
; BIT A dir (3)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_96:
; LDA A dir (3)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_97:
; STA A dir (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_98:
; EOR A dir (3)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_99:
; ADC A dir (3)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_9a:
; ORA A dir (3)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_9b:
; ADD A dir (3)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_9c:
; CPX dir
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_9e:
; LDS dir
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_9f:
; STS dir
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_a0:
; SUB A ind (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_a1:
; CMP A ind (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_a2:
; SBC A ind (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_a4:
; AND A ind (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_a5:
; BIT A ind (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_a6:
; LDA A ind (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_a7:
; STA A ind (6)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_a8:
; EOR A ind (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_a9:
; ADC A ind (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_aa:
; ORA A ind (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_ab:
; ADD A ind (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_ac:
; CPX ind
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_ad:
; JSR ind
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_ae:
; LDS ind
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_af:
; STS ind
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_b0:
; SUB A ext (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_b1:
; CMP A ext (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_b2:
; SBC A ext (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_b4:
; AND A ext (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_b5:
; BIT A ext (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_b6:
; LDA A ext (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_b7:
; STA A ext (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_b8:
; EOR A ext (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_b9:
; ADC A ext (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_ba:
; ORA A ext (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_bb:
; ADD A ext (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_bc:
; CPX ext
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_bd:
; JSR ext
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_be:
; LDS ext
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_bf:
; STS ext
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_c0:
; SUB B imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_c1:
; CMP B imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_c2:
; SBC B imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_c4:
; AND B imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_c5:
; BIT B imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_c6:
; LDA B imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_c8:
; EOR B imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_c9:
; ADC B imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_ca:
; ORA B imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_cb:
; ADD B imm (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_ce:
; LDX ind ()
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_d0:
; SUB B dir (3)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_d1:
; CMP B dir (3)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_d2:
; SBC B dir (3)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_d4:
; AND B dir (3)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_d5:
; BIT B dir (3)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_d6:
; LDA B dir (3)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_d7:
; STA B dir (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_d8:
; EOR B dir (3)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_d9:
; ADC B dir (3)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_da:
; ORA B dir (3)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_db:
; ADD B dir (3)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_de:
; LDX dir (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_df:
; STX dir (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_e0:
; SUB B ind (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_e1:
; CMP B ind (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_e2:
; SBC B ind (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_e4:
; AND B ind (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_e5:
; BIT B ind (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_e6:
; LDA B ind (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_e7:
; STA B ind (6)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_e8:
; EOR B ind (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_e9:
; ADC B ind (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_ea:
; ORA B ind (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_eb:
; ADD B ind (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_ee:
; LDX ind (6)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_ef:
; STX ind (7)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_f0:
; SUB B ext (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_f1:
; CMP B ext (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_f2:
; SBC B ext (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_f4:
; AND B ext (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_f5:
; BIT B ext (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_f6:
; LDA B ext (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_f7:
; STA B ext (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_f8:
; EOR B ext (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_f9:
; ADC B ext (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_fa:
; ORA B ext (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_fb:
; ADD B ext (4)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_fe:
; LDX ext (5)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_ff:
; STX ext (6)
	; ***** TO DO ***** TO DO *****
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
