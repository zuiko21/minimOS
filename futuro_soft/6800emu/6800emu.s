; 6800 emulator for minimOS!
; v0.1a5
; (c) 2016 Carlos J. Santisteban
; last modified 20160209

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
; inject address MSB into 16+16K space (5/5.5/6)
#define	_AH_BOUND	AND #hi_mask: BMI *+4: ORA #lo_mask
; increase Y checking injected boundary crossing (5/5/18)
#define	_PC_ADV		INY: BNE *+13: LDA pc68+1: INC: _AH_BOUND: STA pc68+1
; compute pointer for indexed addressing mode (31/31.5/45)
#define	_INDEXED	_PC_ADV: LDA (pc68), Y: CLC: ADC x68: STA tmptr: LDA x68+1: ADC #0: _AH_BOUND: STA tmptr+1
; compute pointer for extended addressing mode (31/31.5/45)
#define	_EXTENDED	_PC_ADV: LDA (pc68), Y: _AH_BOUND: STA tmptr+1: _PC_ADV: LDA (pc68), Y: STA tmptr
; compute pointer (as X index) for direct addressing mode (12/12/25)
#define	_DIRECT		_PC_ADV: LDA (pc68), Y: TAX
; get immediate operand directly into tmptr, unless further optimisation is available (13/13/26)
#define	_IMMEDIATE	_PC_ADV: LDA (pc68), Y: STA tmptr

; check Z & N flags (6/8/14) will not set both bits at once!
#define _CC_NZ		BNE *+4: SMB2 ccr68: BPL *+4: SMB3 ccr68

; declare some constants
hi_mask	=	%10111111	; injects A15 hi into $8000-$BFFF, regardless of A14
lo_mask	=	%01000000	; injects A15 lo into $4000-$7FFF, regardless of A14
;lo_mask	=	%00100000	; injects into 8 K ($2000-$3FFF) for 16K RAM systems
e_base	=	$4000		; emulated space start ($2000 for 16K systems)

; declare zeropage addresses
tmptr	=	uz		; temporary storage (up to 16 bit)
sp68	=	uz+2	; stack pointer (16 bit, little-endian, now injected into host map)
pc68	=	uz+4	; program counter (16 bit, little-endian, injected into host map) same as stacking order
x68		=	uz+6	; index register (16 bit, little-endian)
a68		=	uz+8	; first accumulator (8 bit)
b68		=	uz+9	; second accumulator (8 bit)
ccr68	=	uz+10	; status register (8 bit)
cdev	=	uz+11	; I/O device *** minimOS specific ***

; *** minimOS executable header will go here ***

; *** startup code, minimOS specific stuff ***
	LDA #cdev-uz+1	; zeropage space needed
#ifdef	SAFE
	CMP z_used		; check available zeropage space
	BCC go_emu		; nore than enough space
	BEQ go_emu		; just enough!
		_ERR(FULL)		; not enough memory otherwise (rare)
go_emu:
#endif
	STA z_used		; set required ZP space as required by minimOS
	STZ zpar		; no screen size required
	_KERNEL(OPEN_W)	; ask for a character I/O device
	
; might check here whether a Rockwell 65C02 is used!
; should try to allocate memory here

; *** start the emulation! ***
reset68:
	LDA #%11010000	; restart with interrupts masked
	STA ccr68		; store initial flags
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
; *** NOP (2) arrives here, saving 3 bytes and 3 cycles ***
_01:
; continue execution via JMP next_op, will not arrive here otherwise
next_op:
		INY				; advance one byte (2)
		BNE execute		; fetch next instruction if no boundary is crossed (3/2)
; usual overhead is now 22+3=25 clock cycles, instead of 33
; boundary crossing, simplified version
; ** should be revised for 16K RAM systems **
	INC pc68 + 1		; increase MSB otherwise, faster than using 'that macro' (5)
	BPL execute			; seems to stay in RAM area (3/2)
		RMB6 pc68 + 1		; in ROM area, A14 is goes low (5) *** Rockwell
	BRA execute			; fetch next (3)

; *** opcode execution routines, labels must match those on tables below ***
; unsupported opcodes first
_00:_02:_03:_04:_05:_12:_13:_14:_15:_18:_1a:_1c:_1d:_1e:_1f:_21:_38:_3a:_3c:_3d
_41:_42:_45:_4b:_4e:_51:_52:_55:_5b:_5e:_61:_62:_65:_6b:_71:_72:_75:_7b
_83:_87:_8f:_93:_9d:_a3:_b3:_c3:_c7:_cc:_cd:_cf:_d3:_dc:_dd:_e3:_ec:_ed:_f3:_fc:_fd

; illegal opcodes will seem to trigger an NMI!
nmi68:
	_PC_ADV			; hardware interrupts (when available) supposedly checked before incrementing PC, anyway skip illegal opcode
	SEC				; prepare subtraction
	LDA sp68		; get stack pointer LSB
	SBC #7			; make room for stack frame
	TAX				; store for later
	BCS nmi_do		; no need for further action
		LDA sp68+1		; get MSB
		DEC				; wrap
		_AH_BOUND		; keep into emulated space
		STA sp68+1		; update pointer
nmi_do:
	STX sp68		; room already made
	LDX #0			; index for register area stacking
	LDY #7			; index for stack area
nmi_loop:
		LDA pc68, X			; get one byte from register area
		STA (sp68), Y		; store in free stack space
		INX					; increase original offset
		DEY					; stack grows backwards
		BMI nmi_loop		; zero is included
	SMB4 ccr68		; mask interrupts! *** Rockwell ***
	LDY $BFFD		; get LSB from emulated NMI vector
	LDA $BFFC		; get MSB...
	_AH_BOUND		; ...but inject it into emulated space
	STA pc68 + 1	; update PC
	JMP execute		; continue with NMI handler

; *** valid opcode definitions ***

; ** accumulator and memory **

_8b:
; ADD A imm (2)
; +57/63/
	_PC_ADV			; not worth using the macro
	LDA a68			; get accumulator A
	BIT #%00010000	; check bit 4
	BEQ addam_nh	; do not set H if clear
		SMB5 ccr68		; set H temporarily as b4
		JMP addam_sh	; do not clear it
addam_nh:
	RMB5 ccr68		; otherwise H is clear
addam_sh:
	CLC				; prepare
	ADC (pc68), Y	; add operand
	STA a68			; update accumulator
	TAX				; store for later!
	BIT #%00010000	; check bit 4 again
	BNE addam_nh2	; do not invert H
		LDA ccr68		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		JMP addam_sh2	; do not reload CCR
addam_nh2:
	LDA ccr68		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
addam_sh2:
	BCC addam_nc	; only if carry...
		INC				; ...set C flag
addam_nc:
	BVC addam_nv	; only if overflow...
		ORA #%00000010	; ...set V flag
addam_nv:
	STA ccr68		; update flags
	TXA				; retrieve value!
	_CC_NZ			; check final bits
	JMP next_op		; standard end

_9b:
; ADD A dir (3)
; +65/69.5?
	_DIRECT			; point to operand in X
	LDA a68			; get accumulator A
	BIT #%00010000	; check bit 4
	BEQ addad_nh	; do not set H if clear
		SMB5 ccr68		; set H temporarily as b4
		JMP addad_sh	; do not clear it
addad_nh:
	RMB5 ccr68		; otherwise H is clear
addad_sh:
	CLC				; prepare
	ADC e_base, X	; add operand
	STA a68			; update accumulator
	PHA				; store for later!
	BIT #%00010000	; check bit 4 again
	BNE addad_nh2	; do not invert H
		LDA ccr68		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		JMP addad_sh2	; do not reload CCR
addad_nh2:
	LDA ccr68		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
addad_sh2:
	BCC addad_nc	; only if carry...
		INC				; ...set C flag
addad_nc:
	BVC addad_nv	; only if overflow...
		ORA #%00000010	; ...set V flag
addad_nv:
	STA ccr68		; update flags
	PLA				; retrieve value!
	_CC_NZ			; check final bits
	JMP next_op		; standard end

_ab:
; ADD A ind (5)
; +83/
	_INDEXED		; point to operand
	LDA a68			; get accumulator A
	BIT #%00010000	; check bit 4
	BEQ addai_nh	; do not set H if clear
		SMB5 ccr68		; set H temporarily as b4
		JMP addai_sh	; do not clear it
addai_nh:
	RMB5 ccr68		; otherwise H is clear
addai_sh:
	CLC				; prepare
	ADC (tmptr)		; add operand
	STA a68			; update accumulator
	TAX				; store for later!
	BIT #%00010000	; check bit 4 again
	BNE addai_nh2	; do not invert H
		LDA ccr68		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		JMP addai_sh2	; do not reload CCR
addai_nh2:
	LDA ccr68		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
addai_sh2:
	BCC addai_nc	; only if carry...
		INC				; ...set C flag
addai_nc:
	BVC addai_nv	; only if overflow...
		ORA #%00000010	; ...set V flag
addai_nv:
	STA ccr68		; update flags
	TXA				; retrieve value!
	_CC_NZ			; check final bits
	JMP next_op		; standard end

_bb:
; ADD A ext (4)
; +83...
	_EXTENDED		; point to operand
	LDA a68			; get accumulator A
	BIT #%00010000	; check bit 4
	BEQ addae_nh	; do not set H if clear
		SMB5 ccr68		; set H temporarily as b4
		JMP addae_sh	; do not clear it
addae_nh:
	RMB5 ccr68		; otherwise H is clear
addae_sh:
	CLC				; prepare
	ADC (tmptr)		; add operand
	STA a68			; update accumulator
	TAX				; store for later!
	BIT #%00010000	; check bit 4 again
	BNE addae_nh2	; do not invert H
		LDA ccr68		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		JMP addae_sh2	; do not reload CCR
addae_nh2:
	LDA ccr68		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
addae_sh2:
	BCC addae_nc	; only if carry...
		INC				; ...set C flag
addae_nc:
	BVC addae_nv	; only if overflow...
		ORA #%00000010	; ...set V flag
addae_nv:
	STA ccr68		; update flags
	TXA				; retrieve value!
	_CC_NZ			; check final bits
	JMP next_op		; standard end

_cb:
; ADD B imm (2)
; +57/63/
	_PC_ADV			; not worth using the macro
	LDA b68			; get accumulator B
	BIT #%00010000	; check bit 4
	BEQ addbm_nh	; do not set H if clear
		SMB5 ccr68		; set H temporarily as b4
		JMP addbm_sh	; do not clear it
addbm_nh:
	RMB5 ccr68		; otherwise H is clear
addbm_sh:
	CLC				; prepare
	ADC (pc68), Y	; add operand
	STA b68			; update accumulator
	TAX				; store for later!
	BIT #%00010000	; check bit 4 again
	BNE addbm_nh2	; do not invert H
		LDA ccr68		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		JMP addbm_sh2	; do not reload CCR
addbm_nh2:
	LDA ccr68		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
addbm_sh2:
	BCC addbm_nc	; only if carry...
		INC				; ...set C flag
addbm_nc:
	BVC addbm_nv	; only if overflow...
		ORA #%00000010	; ...set V flag
addbm_nv:
	STA ccr68		; update flags
	TXA				; retrieve value!
	_CC_NZ			; check final bits
	JMP next_op		; standard end

_db:
; ADD B dir (3)
; +60/67.5/
	_DIRECT			; point to operand in X
	LDA b68			; get accumulator B
	BIT #%00010000	; check bit 4
	BEQ addbd_nh	; do not set H if clear
		SMB5 ccr68		; set H temporarily as b4
		JMP addbd_sh	; do not clear it
addbd_nh:
	RMB5 ccr68		; otherwise H is clear
addbd_sh:
	CLC				; prepare
	ADC e_base, X	; add operand
	STA b68			; update accumulator
	PHA				; store for later!
	BIT #%00010000	; check bit 4 again
	BNE addbd_nh2	; do not invert H
		LDA ccr68		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		JMP addbd_sh2	; do not reload CCR
addbd_nh2:
	LDA ccr68		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
addbd_sh2:
	BCC addbd_nc	; only if carry...
		INC				; ...set C flag
addbd_nc:
	BVC addbd_nv	; only if overflow...
		ORA #%00000010	; ...set V flag
addbd_nv:
	STA ccr68		; update flags
	PLA				; retrieve value!
	_CC_NZ			; check final bits
	JMP next_op		; standard end

_eb:
; ADD B ind (5)
; +83...
	_INDEXED		; point to operand
	LDA b68			; get accumulator B
	BIT #%00010000	; check bit 4
	BEQ addbi_nh	; do not set H if clear
		SMB5 ccr68		; set H temporarily as b4
		JMP addbi_sh	; do not clear it
addbi_nh:
	RMB5 ccr68		; otherwise H is clear
addbi_sh:
	CLC				; prepare
	ADC (tmptr)		; add operand
	STA b68			; update accumulator
	TAX				; store for later!
	BIT #%00010000	; check bit 4 again
	BNE addbi_nh2	; do not invert H
		LDA ccr68		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		JMP addbi_sh2	; do not reload CCR
addbi_nh2:
	LDA ccr68		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
addbi_sh2:
	BCC addbi_nc	; only if carry...
		INC				; ...set C flag
addbi_nc:
	BVC addbi_nv	; only if overflow...
		ORA #%00000010	; ...set V flag
addbi_nv:
	STA ccr68		; update flags
	TXA				; retrieve value!
	_CC_NZ			; check final bits
	JMP next_op		; standard end

_fb:
; ADD B ext (4)
; +83...
	_EXTENDED		; point to operand
	LDA b68			; get accumulator B
	BIT #%00010000	; check bit 4
	BEQ addbe_nh	; do not set H if clear
		SMB5 ccr68		; set H temporarily as b4
		JMP addbe_sh	; do not clear it
addbe_nh:
	RMB5 ccr68		; otherwise H is clear
addbe_sh:
	CLC				; prepare
	ADC (tmptr)		; add operand
	STA b68			; update accumulator
	TAX				; store for later!
	BIT #%00010000	; check bit 4 again
	BNE addbe_nh2	; do not invert H
		LDA ccr68		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		JMP addbe_sh2	; do not reload CCR
addbe_nh2:
	LDA ccr68		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
addbe_sh2:
	BCC addbe_nc	; only if carry...
		INC				; ...set C flag
addbe_nc:
	BVC addbe_nv	; only if overflow...
		ORA #%00000010	; ...set V flag
addbe_nv:
	STA ccr68		; update flags
	TXA				; retrieve value!
	_CC_NZ			; check final bits
	JMP next_op		; standard end

_1b:
; ABA (2)
; +50/56/
	LDA a68			; get accumulator A
	BIT #%00010000	; check bit 4
	BEQ aba_nh		; do not set H if clear
		SMB5 ccr68		; set H temporarily as b4
		JMP aba_sh		; do not clear it
aba_nh:
	RMB5 ccr68		; otherwise H is clear
aba_sh:
	CLC				; prepare
	ADC b68			; add second accumulator
	STA a68			; update accumulator
	TAX				; store for later!
	BIT #%00010000	; check bit 4 again
	BNE aba_nh2		; do not invert H
		LDA ccr68		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		JMP aba_sh2		; do not reload CCR
aba_nh2:
	LDA ccr68		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
aba_sh2:
	BCC aba_nc		; only if carry...
		INC				; ...set C flag
aba_nc:
	BVC aba_nv		; only if overflow...
		ORA #%00000010	; ...set V flag
aba_nv:
	STA ccr68		; update flags
	TXA				; retrieve value!
	_CC_NZ			; check final bits
	JMP next_op		; standard end

_89:
; ADC A imm (2)
; +65/70.5/
	_PC_ADV			; not worth using the macro
	LDA a68			; get accumulator A
	BIT #%00010000	; check bit 4
	BEQ adcam_nh	; do not set H if clear
		SMB5 ccr68		; set H temporarily as b4
		JMP adcam_sh	; do not clear it
adcam_nh:
	RMB5 ccr68		; otherwise H is clear
adcam_sh:
	CLC				; prepare
	BBR0 ccr68, adcam_cc	; no previous carry
		SEC						; otherwise preset C
adcam_cc:
	ADC (pc68), Y	; add operand
	STA a68			; update accumulator
	TAX				; store for later!
	BIT #%00010000	; check bit 4 again
	BNE adcam_nh2	; do not invert H
		LDA ccr68		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		JMP adcam_sh2	; do not reload CCR
adcam_nh2:
	LDA ccr68		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
adcam_sh2:
	BCC adcam_nc	; only if carry...
		INC				; ...set C flag
adcam_nc:
	BVC adcam_nv	; only if overflow...
		ORA #%00000010	; ...set V flag
adcam_nv:
	STA ccr68		; update flags
	TXA				; retrieve value!
	_CC_NZ			; check final bits
	JMP next_op		; standard end

_99:
; ADC A dir (3)
; +
	_DIRECT			; point to operand in X
	LDA a68			; get accumulator A
	BIT #%00010000	; check bit 4
	BEQ adcad_nh	; do not set H if clear
		SMB5 ccr68		; set H temporarily as b4
		JMP adcad_sh	; do not clear it
adcad_nh:
	RMB5 ccr68		; otherwise H is clear
adcad_sh:
	CLC				; prepare
	BBR0 ccr68, adcad_cc	; no previous carry
		SEC						; otherwise preset C
adcad_cc:
	ADC e_base, X	; add operand
	STA a68			; update accumulator
	PHA				; store for later!
	BIT #%00010000	; check bit 4 again
	BNE adcad_nh2	; do not invert H
		LDA ccr68		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		JMP adcad_sh2	; do not reload CCR
adcad_nh2:
	LDA ccr68		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
adcad_sh2:
	BCC adcad_nc	; only if carry...
		INC				; ...set C flag
adcad_nc:
	BVC adcad_nv	; only if overflow...
		ORA #%00000010	; ...set V flag
adcad_nv:
	STA ccr68		; update flags
	PLA				; retrieve value!
	_CC_NZ			; check final bits
	JMP next_op		; standard end

_a9:
; ADC A ind (5)
; +
	_INDEXED		; point to operand
	LDA a68			; get accumulator A
	BIT #%00010000	; check bit 4
	BEQ adcai_nh	; do not set H if clear
		SMB5 ccr68		; set H temporarily as b4
		JMP adcai_sh	; do not clear it
adcai_nh:
	RMB5 ccr68		; otherwise H is clear
adcai_sh:
	CLC				; prepare
	BBR0 ccr68, adcai_cc	; no previous carry
		SEC						; otherwise preset C
adcai_cc:
	ADC (tmptr)		; add operand
	STA a68			; update accumulator
	TAX				; store for later!
	BIT #%00010000	; check bit 4 again
	BNE adcai_nh2	; do not invert H
		LDA ccr68		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		JMP adcai_sh2	; do not reload CCR
adcai_nh2:
	LDA ccr68		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
adcai_sh2:
	BCC adcai_nc	; only if carry...
		INC				; ...set C flag
adcai_nc:
	BVC adcai_nv	; only if overflow...
		ORA #%00000010	; ...set V flag
adcai_nv:
	STA ccr68		; update flags
	TXA				; retrieve value!
	_CC_NZ			; check final bits
	JMP next_op		; standard end

_b9:
; ADC A ext (4)
; +
	_EXTENDED		; point to operand
	LDA a68			; get accumulator A
	BIT #%00010000	; check bit 4
	BEQ adcae_nh	; do not set H if clear
		SMB5 ccr68		; set H temporarily as b4
		JMP adcae_sh	; do not clear it
adcae_nh:
	RMB5 ccr68		; otherwise H is clear
adcae_sh:
	CLC				; prepare
	BBR0 ccr68, adcae_cc	; no previous carry
		SEC						; otherwise preset C
adcae_cc:
	ADC (tmptr)		; add operand
	STA a68			; update accumulator
	TAX				; store for later!
	BIT #%00010000	; check bit 4 again
	BNE adcae_nh2	; do not invert H
		LDA ccr68		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		JMP adcae_sh2	; do not reload CCR
adcae_nh2:
	LDA ccr68		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
adcae_sh2:
	BCC adcae_nc	; only if carry...
		INC				; ...set C flag
adcae_nc:
	BVC adcae_nv	; only if overflow...
		ORA #%00000010	; ...set V flag
adcae_nv:
	STA ccr68		; update flags
	TXA				; retrieve value!
	_CC_NZ			; check final bits
	JMP next_op		; standard end

_c9:
; ADC B imm (2)
; +65/70.5/
	_PC_ADV			; not worth using the macro
	LDA b68			; get accumulator B
	BIT #%00010000	; check bit 4
	BEQ adcbm_nh	; do not set H if clear
		SMB5 ccr68		; set H temporarily as b4
		JMP adcbm_sh	; do not clear it
adcbm_nh:
	RMB5 ccr68		; otherwise H is clear
adcbm_sh:
	CLC				; prepare
	BBR0 ccr68, adcbm_cc	; no previous carry
		SEC						; otherwise preset C
adcbm_cc:
	ADC (pc68), Y	; add operand
	STA b68			; update accumulator
	TAX				; store for later!
	BIT #%00010000	; check bit 4 again
	BNE adcbm_nh2	; do not invert H
		LDA ccr68		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		JMP adcbm_sh2	; do not reload CCR
adcbm_nh2:
	LDA ccr68		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
adcbm_sh2:
	BCC adcbm_nc	; only if carry...
		INC				; ...set C flag
adcbm_nc:
	BVC adcbm_nv	; only if overflow...
		ORA #%00000010	; ...set V flag
adcbm_nv:
	STA ccr68		; update flags
	TXA				; retrieve value!
	_CC_NZ			; check final bits
	JMP next_op		; standard end

_d9:
; ADC B dir (3)
; +
	_DIRECT			; point to operand in X
	LDA b68			; get accumulator B
	BIT #%00010000	; check bit 4
	BEQ adcbd_nh	; do not set H if clear
		SMB5 ccr68		; set H temporarily as b4
		JMP adcbd_sh	; do not clear it
adcbd_nh:
	RMB5 ccr68		; otherwise H is clear
adcbd_sh:
	CLC				; prepare
	BBR0 ccr68, adcbd_cc	; no previous carry
		SEC						; otherwise preset C
adcbd_cc:
	ADC e_base, X	; add operand
	STA b68			; update accumulator
	PHA				; store for later!
	BIT #%00010000	; check bit 4 again
	BNE adcbd_nh2	; do not invert H
		LDA ccr68		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		JMP adcbd_sh2	; do not reload CCR
adcbd_nh2:
	LDA ccr68		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
adcbd_sh2:
	BCC adcbd_nc	; only if carry...
		INC				; ...set C flag
adcbd_nc:
	BVC adcbd_nv	; only if overflow...
		ORA #%00000010	; ...set V flag
adcbd_nv:
	STA ccr68		; update flags
	PLA				; retrieve value!
	_CC_NZ			; check final bits
	JMP next_op		; standard end

_e9:
; ADC B ind (5)
; +
	_INDEXED		; point to operand
	LDA b68			; get accumulator B
	BIT #%00010000	; check bit 4
	BEQ adcbi_nh	; do not set H if clear
		SMB5 ccr68		; set H temporarily as b4
		JMP adcbi_sh	; do not clear it
adcbi_nh:
	RMB5 ccr68		; otherwise H is clear
adcbi_sh:
	CLC				; prepare
	BBR0 ccr68, adcbi_cc	; no previous carry
		SEC						; otherwise preset C
adcbi_cc:
	ADC (tmptr)		; add operand
	STA b68			; update accumulator
	TAX				; store for later!
	BIT #%00010000	; check bit 4 again
	BNE adcbi_nh2	; do not invert H
		LDA ccr68		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		JMP adcbi_sh2	; do not reload CCR
adcbi_nh2:
	LDA ccr68		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
adcbi_sh2:
	BCC adcbi_nc	; only if carry...
		INC				; ...set C flag
adcbi_nc:
	BVC adcbi_nv	; only if overflow...
		ORA #%00000010	; ...set V flag
adcbi_nv:
	STA ccr68		; update flags
	TXA				; retrieve value!
	_CC_NZ			; check final bits
	JMP next_op		; standard end

_f9:
; ADC B ext (4)
; +
	_EXTENDED		; point to operand
	LDA b68			; get accumulator B
	BIT #%00010000	; check bit 4
	BEQ adcbe_nh	; do not set H if clear
		SMB5 ccr68		; set H temporarily as b4
		JMP adcbe_sh	; do not clear it
adcbe_nh:
	RMB5 ccr68		; otherwise H is clear
adcbe_sh:
	CLC				; prepare
	BBR0 ccr68, adcbe_cc	; no previous carry
		SEC						; otherwise preset C
adcbe_cc:
	ADC (tmptr)		; add operand
	STA b68			; update accumulator
	TAX				; store for later!
	BIT #%00010000	; check bit 4 again
	BNE adcbe_nh2	; do not invert H
		LDA ccr68		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		JMP adcbe_sh2	; do not reload CCR
adcbe_nh2:
	LDA ccr68		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
adcbe_sh2:
	BCC adcbe_nc	; only if carry...
		INC				; ...set C flag
adcbe_nc:
	BVC adcbe_nv	; only if overflow...
		ORA #%00000010	; ...set V flag
adcbe_nv:
	STA ccr68		; update flags
	TXA				; retrieve value!
	_CC_NZ			; check final bits
	JMP next_op		; standard end

_84:
; AND A imm (2)
; +30...
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_PC_ADV			; go for operand
	LDA (pc68), Y	; immediate
	AND a68			; AND with accumulator A
	STA a68			; update
	_CC_NZ			; check these
	JMP next_op		; standard end

_94:
; AND A dir (3)
; +36...
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_DIRECT			; X points to operand
	LDA a68			; get A accumulator
	AND e_base, X	; AND with operand
	STA a68			; update A
	_CC_NZ			; set flags
	JMP next_op		; standard end

_a4:
; AND A ind (5)
; +56...
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_INDEXED		; points to operand
	LDA a68			; get A accumulator
	AND (tmptr)		; AND with operand
	STA a68			; update A
	_CC_NZ			; set flags
	JMP next_op		; standard end

_b4:
; AND A ext (4)
; +
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_EXTENDED		; points to operand
	LDA a68			; get A accumulator
	AND (tmptr)		; AND with operand
	STA a68			; update A
	_CC_NZ			; set flags
	JMP next_op		; standard end

_c4:
; AND B imm (2)
; +30...
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_PC_ADV			; go for operand
	LDA (pc68), Y	; immediate
	AND b68			; AND with accumulator B
	STA b68			; update
	_CC_NZ			; check these
	JMP next_op		; standard end

_d4:
; AND B dir (3)
; +
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_DIRECT			; X points to operand
	LDA b68			; get B accumulator
	AND e_base, X	; AND with operand
	STA b68			; update B
	_CC_NZ			; set flags
	JMP next_op		; standard end

_e4:
; AND B ind (5)
; +
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_INDEXED		; points to operand
	LDA b68			; get B accumulator
	AND (tmptr)		; AND with operand
	STA b68			; update B
	_CC_NZ			; set flags
	JMP next_op		; standard end

_f4:
; AND B ext (4)
; +
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_EXTENDED		; points to operand
	LDA b68			; get B accumulator
	AND (tmptr)		; AND with operand
	STA b68			; update B
	_CC_NZ			; set flags
	JMP next_op		; standard end

_85:
; BIT A imm (2)
; +27...
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_PC_ADV			; go for operand
	LDA (pc68), Y	; immediate
	AND a68			; AND with accumulator A
	_CC_NZ			; check these
	JMP next_op		; standard end

_95:
; BIT A dir (3)
; +33...
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_DIRECT			; X points to operand
	LDA a68			; get A accumulator
	AND e_base, X	; test operand
	_CC_NZ			; set flags
	JMP next_op		; standard end

_a5:
; BIT A ind (5)
; +53...
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_INDEXED		; points to operand
	LDA a68			; get A accumulator
	AND (tmptr)		; AND with operand, just for flags
	_CC_NZ			; set flags
	JMP next_op		; standard end

_b5:
; BIT A ext (4)
; +
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_EXTENDED		; points to operand
	LDA a68			; get A accumulator
	AND (tmptr)		; AND with operand, just for flags
	_CC_NZ			; set flags
	JMP next_op		; standard end

_c5:
; BIT B imm (2)
; +27...
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_PC_ADV			; go for operand
	LDA (pc68), Y	; immediate
	AND b68			; AND with accumulator B
	_CC_NZ			; check these
	JMP next_op		; standard end

_d5:
; BIT B dir (3)
; +
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_DIRECT			; X points to operand
	LDA b68			; get B accumulator
	AND e_base, X	; AND with operand
	_CC_NZ			; set flags
	JMP next_op		; standard end

_e5:
; BIT B ind (5)
; +
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_INDEXED		; points to operand
	LDA b68			; get B accumulator
	AND (tmptr)		; AND with operand, just for flags
	_CC_NZ			; set flags
	JMP next_op		; standard end

_f5:
; BIT B ext (4)
; +
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_EXTENDED		; points to operand
	LDA b68			; get B accumulator
	AND (tmptr)		; AND with operand, just for flags
	_CC_NZ			; set flags
	JMP next_op		; standard end

_4f:
; CLR A (2)
; +13
	STZ a68		; clear A
	LDA ccr68	; get previous status
	AND #%11110100	; clear N, V, C
	ORA #%00000100	; set Z
	STA ccr68	; update
	JMP next_op	; standard end of routine

_5f:
; CLR B (2)
; +13...
	STZ b68		; clear B
	LDA ccr68	; get previous status
	AND #%11110100	; clear N, V, C
	ORA #%00000100	; set Z
	STA ccr68	; update
	JMP next_op	; standard end of routine

_6f:
; CLR ind (7)
; +48...
	_INDEXED		; prepare pointer
	LDA #0			; no indirect STZ available
	STA (tmptr)		; clear memory
	LDA ccr68		; get previous status
	AND #%11110100	; clear N, V, C
	ORA #%00000100	; set Z
	STA ccr68		; update flags
	JMP next_op		; standard end of routine

_7f:
; CLR ext (6)
; +
	_EXTENDED		; prepare pointer
	LDA #0			; no indirect STZ available
	STA (tmptr)		; clear memory
	LDA ccr68		; get previous status
	AND #%11110100	; clear N, V, C
	ORA #%00000100	; set Z
	STA ccr68		; update flags
	JMP next_op		; standard end of routine

_81:
; CMP A imm (2)
; +41...
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	_IMMEDIATE		; get operand
	LDA a68			; get accumulator A
	SEC				; prepare
	SBC tmptr		; subtract without carry
	BCS cmpam_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502)
cmpam_nc:
	BVC cmpam_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
cmpam_nv:
	_CC_NZ			; check these
	JMP next_op		; standard end

_91:
; CMP A dir (3)
; +41...
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	_DIRECT			; get operand
	LDA a68			; get accumulator A
	SEC				; prepare
	SBC e_base, X	; subtract without carry
	BCS cmpad_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502)
cmpad_nc:
	BVC cmpad_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
cmpad_nv:
	_CC_NZ			; check these
	JMP next_op		; standard end

_a1:
; CMP A ind (5)
; +61...
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	_INDEXED		; get operand
	LDA a68			; get accumulator A
	SEC				; prepare
	SBC (tmptr)		; subtract without carry
	BCS cmpai_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502)
cmpai_nc:
	BVC cmpai_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
cmpai_nv:
	_CC_NZ			; check these
	JMP next_op		; standard end

_b1:
; CMP A ext (4)
; +
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	_EXTENDED		; get operand
	LDA a68			; get accumulator A
	SEC				; prepare
	SBC (tmptr)		; subtract without carry
	BCS cmpae_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502)
cmpae_nc:
	BVC cmpae_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
cmpae_nv:
	_CC_NZ			; check these
	JMP next_op		; standard end

_c1:
; CMP B imm (2)
; +41...
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	_IMMEDIATE		; get operand
	LDA b68			; get accumulator B
	SEC				; prepare
	SBC tmptr		; subtract without carry
	BCS cmpbm_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502)
cmpbm_nc:
	BVC cmpbm_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
cmpbm_nv:
	_CC_NZ			; check these
	JMP next_op		; standard end

_d1:
; CMP B dir (3)
; +41...
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	_DIRECT			; get operand
	LDA b68			; get accumulator B
	SEC				; prepare
	SBC e_base, X	; subtract without carry
	BCS cmpbd_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502)
cmpbd_nc:
	BVC cmpbd_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
cmpbd_nv:
	_CC_NZ			; check these
	JMP next_op		; standard end

_e1:
; CMP B ind (5)
; +
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	_INDEXED		; get operand
	LDA b68			; get accumulator B
	SEC				; prepare
	SBC (tmptr)		; subtract without carry
	BCS cmpbi_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502)
cmpbi_nc:
	BVC cmpbi_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
cmpbi_nv:
	_CC_NZ			; check these
	JMP next_op		; standard end

_f1:
; CMP B ext (4)
; +
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	_EXTENDED		; get operand
	LDA b68			; get accumulator B
	SEC				; prepare
	SBC (tmptr)		; subtract without carry
	BCS cmpbe_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502)
cmpbe_nc:
	BVC cmpbe_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
cmpbe_nv:
	_CC_NZ			; check these
	JMP next_op		; standard end

_11:
; CBA (2)
; +39/42.5/46
; ** might set V according to native 6502 result ** CONTINUE CLEANUP HERE
	LDA a68		; get A
	BPL cba_nm	; skip if was positive
		SMB1 ccr68	; set V like N, to be toggled later ***Rockwell***
		BRA cba_sv	; do not clear V
cba_nm:
	RMB1 ccr68	; clear V ***Rockwell***
cba_sv:
	SEC			; prepare subtraction, simulating comparison
	SBC b68		; minus B
	TAX			; store for later
	LDA ccr68	; get original flags
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
	STA ccr68	; update status
	JMP next_op	; standard end of routine

_43:
; COM A (2)
; +24/28/32
	LDA ccr68	; get original flags
	AND #%11110000	; reset relevant bits
	INC			; C always set
	STA ccr68	; update status
	LDA a68		; get A
	EOR #$FF	; complement it
	STA a68		; update value
	_CC_NZ		; check these
	JMP next_op	; standard end of routine

_53:
; COM B (2)
; +24/28/32
	LDA ccr68	; get original flags
	AND #%11110000	; reset relevant bits
	INC			; C always set
	STA ccr68	; update status
	LDA b68		; get B
	EOR #$FF	; complement it
	STA b68		; update value
	_CC_NZ		; check these
	JMP next_op	; standard end of routine

_63:
; COM ind (7)
; +59...
	LDA ccr68	; get original flags
	AND #%11110000	; reset relevant bits
	INC			; C always set
	STA ccr68	; update status
	_INDEXED	; compute pointer
	LDA (tmptr)	; get memory
	EOR #$FF	; complement it
	STA (tmptr)	; update value
	_CC_NZ		; check these
	JMP next_op	; standard end of routine

_73:
; COM ext (6)
; +59...
	LDA ccr68	; get original flags
	AND #%11110000	; reset relevant bits
	INC			; C always set
	STA ccr68	; update status
	_EXTENDED	; addressing mode
	LDA (tmptr)	; get memory
	EOR #$FF	; complement it
	STA (tmptr)	; update value
	_CC_NZ		; check these
	JMP next_op	; standard end of routine

_40:
; NEG A (2)
; +29/35/41
	LDA ccr68	; get original flags
	AND #%11110000	; reset relevant bits
	STA ccr68	; update status
	SEC			; prepare subtraction
	LDA #0
	SBC a68		; negate A
	STA a68		; update value
	_CC_NZ		; check these
	CMP #$80	; did change sign?
	BNE nega_nv	; skip if not V
		SMB1 ccr68	; set V flag
nega_nv:
	JMP next_op	; standard end of routine

_50:
; NEG B (2)
; +29/35/41
	LDA ccr68	; get original flags
	AND #%11110000	; reset relevant bits
	STA ccr68	; update status
	SEC			; prepare subtraction
	LDA #0
	SBC b68		; negate B
	STA b68		; update value
	_CC_NZ		; check these
	CMP #$80	; did change sign?
	BNE negb_nv	; skip if not V
		SMB1 ccr68	; set V flag
negb_nv:
	JMP next_op	; standard end of routine

_60:
; NEG ind (7)
; +64...
	LDA ccr68	; get original flags
	AND #%11110000	; reset relevant bits
	STA ccr68	; update status
	_INDEXED	; compute pointer
	SEC			; prepare subtraction
	LDA #0
	SBC (tmptr)	; negate memory
	STA (tmptr)	; update value
	_CC_NZ		; check these
	CMP #$80	; did change sign?
	BNE negi_nv	; skip if not V
		SMB1 ccr68	; set V flag
negi_nv:
	JMP next_op	; standard end of routine

_70:
; NEG ext (6)
; +64...
	LDA ccr68		; get original flags
	AND #%11110000	; reset relevant bits
	STA ccr68		; update status
	_EXTENDED		; addressing mode
	SEC				; prepare subtraction
	LDA #0
	SBC (tmptr)		; negate memory
	STA (tmptr)		; update value
	_CC_NZ			; check these
	CMP #$80		; did change sign?
	BNE nege_nv		; skip if not V
		SMB1 ccr68		; set V flag
nege_nv:
	JMP next_op	; standard end of routine

_19:
; DAA (2)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end of routine

_4a:
; DEC A (2)
; +27//39
	LDA ccr68	; get original status
	AND #%11110001	; reset all relevant bits for CCR
	STA ccr68	; store new flags
	DEC a68		; decrease A
	_CC_NZ		; check these
	LDX a68		; check it!
	CPX #$7F	; did change sign?
	BNE deca_nv	; skip if not overflow
		SMB1 ccr68	; will set V flag
deca_nv:
	JMP next_op	; standard end of routine

_5a:
; DEC B (2)
; +27//39
	LDA ccr68	; get original status
	AND #%11110001	; reset all relevant bits for CCR
	STA ccr68	; store new flags
	DEC b68		; decrease B
	_CC_NZ		; check these
	LDX b68		; check it!
	CPX #$7F	; did change sign?
	BNE decb_nv	; skip if not overflow
		SMB1 ccr68	; will set V flag
decb_nv:
	JMP next_op	; standard end of routine

_6a:
; DEC ind (7)
; +62...
	LDA ccr68		; get original status
	AND #%11110001	; reset all relevant bits for CCR
	STA ccr68		; store new flags
	_INDEXED		; addressing mode
	LDA (tmptr)		; no DEC (tmptr) available...
	DEC
	STA (tmptr)
	_CC_NZ			; check these
	CMP #$7F		; did change sign?
	BNE deci_nv		; skip if not overflow
		SMB1 ccr68		; will set V flag
deci_nv:
	JMP next_op		; standard end of routine

_7a:
; DEC ext (6)
; +
	LDA ccr68		; get original status
	AND #%11110001	; reset all relevant bits for CCR
	STA ccr68		; store new flags
	_EXTENDED		; addressing mode
	LDA (tmptr)		; no DEC (tmptr) available...
	DEC
	STA (tmptr)
	_CC_NZ			; check these
	CMP #$7F		; did change sign?
	BNE dece_nv		; skip if not overflow
		SMB1 ccr68		; will set V flag
dece_nv:
	JMP next_op		; standard end of routine

_88:
; EOR A imm (2)
; +30...
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_PC_ADV			; go for operand
	LDA (pc68), Y	; immediate
	EOR a68			; EOR with accumulator A
	STA a68			; update
	_CC_NZ			; check these
	JMP next_op		; standard end

_98:
; EOR A dir (3)
; +36...
	_DIRECT			; X points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA a68			; get A accumulator
	EOR e_base, X	; EOR with operand
	STA a68			; update A
	_CC_NZ			; set flags
	JMP next_op		; standard end

_a8:
; EOR A ind (5)
; +56...
	_INDEXED		; points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA a68			; get A accumulator
	EOR (tmptr)		; EOR with operand
	STA a68			; update A
	_CC_NZ			; set flags
	JMP next_op		; standard end

_b8:
; EOR A ext (4)
; +
	_EXTENDED		; points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA a68			; get A accumulator
	EOR (tmptr)		; EOR with operand
	STA a68			; update A
	_CC_NZ			; set flags
	JMP next_op		; standard end

_c8:
; EOR B imm (2)
; +30...
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_PC_ADV			; go for operand
	LDA (pc68), Y	; immediate
	EOR b68			; EOR with accumulator B
	STA b68			; update
	_CC_NZ			; check these
	JMP next_op		; standard end

_d8:
; EOR B dir (3)
; +
	_DIRECT			; X points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA b68			; get B accumulator
	EOR e_base, X	; EOR with operand
	STA b68			; update B
	_CC_NZ			; set flags
	JMP next_op		; standard end

_e8:
; EOR B ind (5)
; +
	_INDEXED		; points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA b68			; get B accumulator
	EOR (tmptr)		; EOR with operand
	STA b68			; update B
	_CC_NZ			; set flags
	JMP next_op		; standard end

_f8:
; EOR B ext (4)
; +
	_EXTENDED		; points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA b68			; get B accumulator
	EOR (tmptr)		; EOR with operand
	STA b68			; update B
	_CC_NZ			; set flags
	JMP next_op		; standard end

_4c:
; INC A (2)
; +27//39
	LDA ccr68	; get original status
	AND #%11110001	; reset all relevant bits for CCR 
	STA ccr68	; store new flags
	INC a68		; increase A
	_CC_NZ		; check these
	LDX a68		; check it!
	CPX #$80	; did change sign?
	BNE inca_nv	; skip if not overflow
		SMB1 ccr68	; will set V flag
inca_nv:
	JMP next_op	; standard end of routine

_5c:
; INC B (2)
; +27//39
	LDA ccr68	; get original status
	AND #%11110001	; reset all relevant bits for CCR 
	STA ccr68	; store new flags
	INC b68		; increase B
	_CC_NZ		; check these
	LDX b68		; check it!
	CPX #$80	; did change sign?
	BNE incb_nv	; skip if not overflow
		SMB1 ccr68	; will set V flag
incb_nv:
	JMP next_op	; standard end of routine

_6c:
; INC ind (7)
; +62...
	LDA ccr68		; get original status
	AND #%11110001	; reset all relevant bits for CCR 
	STA ccr68		; store new flags
	_INDEXED		; addressing mode
	LDA (tmptr)		; no INC (tmptr) available...
	INC
	STA (tmptr)
	_CC_NZ			; check these
	CMP #$80		; did change sign?
	BNE inci_nv		; skip if not overflow
		SMB1 ccr68		; will set V flag
inci_nv:
	JMP next_op		; standard end of routine

_7c:
; INC ext (6)
; +
	LDA ccr68		; get original status
	AND #%11110001	; reset all relevant bits for CCR 
	STA ccr68		; store new flags
	_EXTENDED		; addressing mode
	LDA (tmptr)		; no INC (tmptr) available...
	INC
	STA (tmptr)
	_CC_NZ			; check these
	CMP #$80		; did change sign?
	BNE ince_nv		; skip if not overflow
		SMB1 ccr68		; will set V flag
ince_nv:
	JMP next_op		; standard end of routine

_86:
; LDA A imm (2)
; +27...
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_PC_ADV			; go for operand
	LDA (pc68), Y	; immediate
	STA a68			; update accumulator A
	_CC_NZ			; check these
	JMP next_op		; standard end

_96:
; LDA A dir (3)
; +33...
	_DIRECT			; X points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA e_base, X	; get operand
	STA a68			; load into A
	_CC_NZ			; set flags
	JMP next_op		; standard end

_a6:
; LDA A ind (5)
; +53...
	_INDEXED		; points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA (tmptr)		; get operand
	STA a68			; load into A
	_CC_NZ			; set flags
	JMP next_op		; standard end

_b6:
; LDA A ext (4)
; +
	_EXTENDED		; points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA (tmptr)		; get operand
	STA a68			; load into A
	_CC_NZ			; set flags
	JMP next_op		; standard end

_c6:
; LDA B imm (2)
; +27...
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_PC_ADV			; go for operand
	LDA (pc68), Y	; immediate
	STA b68			; update accumulator B
	_CC_NZ			; check these
	JMP next_op		; standard end

_d6:
; LDA B dir (3)
; +
	_DIRECT			; X points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA e_base, X	; get operand
	STA b68			; laod into B
	_CC_NZ			; set flags
	JMP next_op		; standard end

_e6:
; LDA B ind (5)
; +
	_INDEXED		; points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA (tmptr)		; get operand
	STA b68			; load into B
	_CC_NZ			; set flags
	JMP next_op		; standard end

_f6:
; LDA B ext (4)
; +
	_EXTENDED		; points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA (tmptr)		; get operand
	STA b68			; load into B
	_CC_NZ			; set flags
	JMP next_op		; standard end

_8a:
; ORA A imm (2)
; +30...
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_PC_ADV			; go for operand
	LDA (pc68), Y	; immediate
	ORA a68			; OR with accumulator A
	STA a68			; update
	_CC_NZ			; check these
	JMP next_op		; standard end

_9a:
; ORA A dir (3)
; +36...
	_DIRECT			; X points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA a68			; get A accumulator
	ORA e_base, X	; ORA with operand
	STA a68			; update A
	_CC_NZ			; set flags
	JMP next_op		; standard end

_aa:
; ORA A ind (5)
; +56...
	_INDEXED		; points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA a68			; get A accumulator
	ORA (tmptr)		; ORA with operand
	STA a68			; update A
	_CC_NZ			; set flags
	JMP next_op		; standard end

_ba:
; ORA A ext (4)
; +
	_EXTENDED		; points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA a68			; get A accumulator
	ORA (tmptr)		; ORA with operand
	STA a68			; update A
	_CC_NZ			; set flags
	JMP next_op		; standard end

_ca:
; ORA B imm (2)
; +30...
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	_PC_ADV			; go for operand
	LDA (pc68), Y	; immediate
	ORA b68			; OR with accumulator B
	STA b68			; update
	_CC_NZ			; check these
	JMP next_op		; standard end

_da:
; ORA B dir (3)
; +
	_DIRECT			; X points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA b68			; get B accumulator
	ORA e_base, X	; ORA with operand
	STA b68			; update B
	_CC_NZ			; set flags
	JMP next_op		; standard end

_ea:
; ORA B ind (5)
; +
	_INDEXED		; points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA b68			; get B accumulator
	ORA (tmptr)		; ORA with operand
	STA b68			; update B
	_CC_NZ			; set flags
	JMP next_op		; standard end

_fa:
; ORA B ext (4)
; +
	_EXTENDED		; points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA b68			; get B accumulator
	ORA (tmptr)		; ORA with operand
	STA b68			; update B
	_CC_NZ			; set flags
	JMP next_op		; standard end

_36:
; PSH A (4)
; +18/18/33
	LDA a68		; get accumulator A
	STA (sp68)	; put it on stack space
	LDX sp68	; check LSB
	BEQ psha_w	; will wrap
		DEX			; post-decrease
		STX sp68	; update real value
		JMP next_op	; all done
psha_w:
	DEX			; post-decrease
	STX sp68	; update real value
	LDA sp68+1	; get MSB
	DEC			; decrease it
	_AH_BOUND	; and inject it
	STA sp68+1	; worst update
	JMP next_op		; all done

_37:
; PSH B (4)
; +18/18/33
	LDA b68		; get accumulator B
	STA (sp68)	; put it on stack space
	LDX sp68	; check LSB
	BEQ pshb_w	; will wrap
		DEX			; post-decrease
		STX sp68	; update real value
		JMP next_op	; all done
pshb_w:
	DEX			; post-decrease
	STX sp68	; update real value
	LDA sp68+1	; get MSB
	DEC			; decrease it
	_AH_BOUND	; and inject it
	STA sp68+1	; worst update
	JMP next_op		; all done

_32:
; PUL A (4)
; +15/15/30
	INC sp68		; pre-increment
	BEQ pula_w		; should correct MSB, rare?
pula_do:
		LDA (sp68)		; take value from stack
		STA a68			; store it in accumulator A
		JMP next_op		; standard end of routine
pula_w:
	LDA sp68 + 1	; get stack pointer MSB
	INC				; increase MSB
	_AH_BOUND		; keep injected
	STA sp68 + 1	; update real thing
	LDA (sp68)		; take value from stack
	STA a68			; store it in accumulator A
	JMP next_op		; standard end of routine

_33:
; PUL B (4)
; +15/15/30
	INC sp68		; pre-increment
	BEQ pulb_w		; should correct MSB, rare?
pulb_do:
		LDA (sp68)		; take value from stack
		STA b68			; store it in accumulator B
		JMP next_op		; standard end of routine
pulb_w:
	LDA sp68 + 1	; get stack pointer MSB
	INC				; increase MSB
	_AH_BOUND		; keep injected
	STA sp68 + 1	; update real thing
	LDA (sp68)		; take value from stack
	STA b68			; store it in accumulator B
	JMP next_op		; standard end of routine

_49:
; ROL A (2)
; +32/36/40
	CLC				; prepare
	LDA ccr68		; get original flags
	BIT #%00000001	; mask for C flag
	BEQ rola_do		; skip if C clear
		SEC				; otherwise, set carry
rola_do:
	AND #%11110000	; reset relevant bits
	ROL a68			; rotate A left
	BNE rola_nz		; skip if not zero
		ORA #%00000100	; set Z flag
rola_nz:
	LDX a68			; retrieve again!
	BPL rola_pl		; skip if positive
		ORA #%00001000	; will set N bit
		EOR #%00000010	; toggle V bit
rola_pl:
	BCC rola_nc		; skip if there was no carry
		ORA #%00000001	; will set C flag
		EOR #%00000010	; toggle V bit
rola_nc:
	STA ccr68		; update status
	JMP next_op		; standard end of routine

_59:
; ROL B (2)
; +32/36/40
	CLC			; prepare
	LDA ccr68	; get original flags
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
	STA ccr68	; update status
	JMP next_op	; standard end of routine

_69:
; ROL ind (7)
; +76...
	_INDEXED		; addressing mode
	CLC				; prepare
	LDA ccr68		; get original flags
	BIT #%00000001	; mask for C flag
	BEQ roli_do		; skip if C clear
		SEC				; otherwise, set carry
roli_do:
	LDA (tmptr)		; get memory
	ROL				; rotate left
	STA (tmptr)		; modify
	TAX				; keep for later
	LDA ccr68		; get flags again
	AND #%11110000	; reset relevant bits
	BCC roli_nc		; skip if there was no carry
		ORA #%00000001	; will set C flag
		EOR #%00000010	; toggle V bit
roli_nc:
	CPX #0			; watch computed value!
	BNE roli_nz		; skip if not zero
		ORA #%00000100	; set Z flag
roli_nz:
	CPX #0			; watch computed value!
	BPL roli_pl		; skip if positive
		ORA #%00001000	; will set N bit
		EOR #%00000010	; toggle V bit
roli_pl:
	STA ccr68		; update status
	JMP next_op		; standard end of routine

_79:
; ROL ext (6)
; +
	_EXTENDED		; addressing mode
	CLC				; prepare
	LDA ccr68		; get original flags
	BIT #%00000001	; mask for C flag
	BEQ role_do		; skip if C clear
		SEC				; otherwise, set carry
role_do:
	LDA (tmptr)		; get memory
	ROL				; rotate left
	STA (tmptr)		; modify
	TAX				; keep for later
	LDA ccr68		; get flags again
	AND #%11110000	; reset relevant bits
	BCC role_nc		; skip if there was no carry
		ORA #%00000001	; will set C flag
		EOR #%00000010	; toggle V bit
role_nc:
	CPX #0			; watch computed value!
	BNE role_nz		; skip if not zero
		ORA #%00000100	; set Z flag
role_nz:
	CPX #0			; watch computed value!
	BPL role_pl		; skip if positive
		ORA #%00001000	; will set N bit
		EOR #%00000010	; toggle V bit
role_pl:
	STA ccr68		; update status
	JMP next_op		; standard end of routine

_46:
; ROR A (2)
; +32/36/40
	CLC			; prepare
	LDA ccr68	; get original flags
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
	STA ccr68	; update status
	JMP next_op	; standard end of routine

_56:
; ROR B (2)
; +32/36/40
	CLC			; prepare
	LDA ccr68	; get original flags
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
	STA ccr68	; update status
	JMP next_op	; standard end of routine

_66:
; ROR ind (7)
; +76...
	_INDEXED		; addressing mode
	CLC				; prepare
	LDA ccr68		; get original flags
	BIT #%00000001	; mask for C flag
	BEQ rori_do		; skip if C clear
		SEC				; otherwise, set carry
rori_do:
	LDA (tmptr)		; get memory
	ROR				; rotate right
	STA (tmptr)		; modify
	TAX				; keep for later
	LDA ccr68		; get flags again
	AND #%11110000	; reset relevant bits
	BCC rori_nc		; skip if there was no carry
		ORA #%00000001	; will set C flag
		EOR #%00000010	; toggle V bit
rori_nc:
	CPX #0			; watch computed value!
	BNE rori_nz		; skip if not zero
		ORA #%00000100	; set Z flag
rori_nz:
	CPX #0			; watch computed value!
	BPL rori_pl		; skip if positive
		ORA #%00001000	; will set N bit
		EOR #%00000010	; toggle V bit
rori_pl:
	STA ccr68		; update status
	JMP next_op		; standard end of routine

_76:
; ROR ext (6)
; +
	_EXTENDED		; addressing mode
	CLC				; prepare
	LDA ccr68		; get original flags
	BIT #%00000001	; mask for C flag
	BEQ rore_do		; skip if C clear
		SEC				; otherwise, set carry
rore_do:
	LDA (tmptr)		; get memory
	ROR				; rotate right
	STA (tmptr)		; modify
	TAX				; keep for later
	LDA ccr68		; get flags again
	AND #%11110000	; reset relevant bits
	BCC rore_nc		; skip if there was no carry
		ORA #%00000001	; will set C flag
		EOR #%00000010	; toggle V bit
rore_nc:
	CPX #0			; watch computed value!
	BNE rore_nz		; skip if not zero
		ORA #%00000100	; set Z flag
rore_nz:
	CPX #0			; watch computed value!
	BPL rore_pl		; skip if positive
		ORA #%00001000	; will set N bit
		EOR #%00000010	; toggle V bit
rore_pl:
	STA ccr68		; update status
	JMP next_op		; standard end of routine

_48:
; ASL A (2)
; +25/28.5/32
	LDA ccr68	; get original flags
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
	STA ccr68	; update status
	JMP next_op	; standard end of routine

_58:
; ASL B (2)
; +25/28.5/32
	LDA ccr68	; get original flags
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
	STA ccr68	; update status
	JMP next_op	; standard end of routine

_68:
; ASL ind (7)
; +66...
	_INDEXED		; prepare pointer
	LDA (tmptr)		; get operand
	ASL				; shift left
	STA (tmptr)		; update memory
	TAX				; save for later!
	LDA ccr68		; get original flags
	AND #%11110000	; reset relevant bits
	BCC asli_nc		; skip if there was no carry
		ORA #%00000001	; will set C flag
		EOR #%00000010	; toggle V bit
asli_nc:
	CPX #0			; retrieve value
	BNE asli_nz		; skip if not zero
		ORA #%00000100	; set Z flag
asli_nz:
	CPX #0			; retrieve again!
	BPL asli_pl		; skip if positive
		ORA #%00001000	; will set N bit
		EOR #%00000010	; toggle V bit
asli_pl:
	STA ccr68		; update status
	JMP next_op		; standard end of routine

_78:
; ASL ext (6)
; +
	_EXTENDED		; prepare pointer
	LDA (tmptr)		; get operand
	ASL				; shift left
	STA (tmptr)		; update memory
	TAX				; save for later!
	LDA ccr68		; get original flags
	AND #%11110000	; reset relevant bits
	BCC asle_nc		; skip if there was no carry
		ORA #%00000001	; will set C flag
		EOR #%00000010	; toggle V bit
asle_nc:
	CPX #0			; retrieve value
	BNE asle_nz		; skip if not zero
		ORA #%00000100	; set Z flag
asle_nz:
	CPX #0			; retrieve again!
	BPL asle_pl		; skip if positive
		ORA #%00001000	; will set N bit
		EOR #%00000010	; toggle V bit
asle_pl:
	STA ccr68		; update status
	JMP next_op		; standard end of routine

_47:
; ASR A (2)
; +33/37/41
	LDA ccr68	; get original flags
	AND #%11110000	; reset relevant bits
	CLC			; prepare
	BIT a68		; check bit 7
	BPL asra_do	; do not insert C if clear
		SEC			; otherwise, set carry
asra_do:
	ROR a68		; emulate arithmetic shift left with preloaded-C rotation
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
	STA ccr68	; update status
	JMP next_op	; standard end of routine

_57:
; ASR B (2)
; +33/37/41
	LDA ccr68	; get original flags
	AND #%11110000	; reset relevant bits
	CLC			; prepare
	BIT b68		; check bit 7
	BPL asrb_do	; do not insert C if clear
		SEC			; otherwise, set carry
asrb_do:
	ROR b68		; emulate arithmetic shift left with preloaded-C rotation
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
	STA ccr68	; update status
	JMP next_op	; standard end of routine

_67:
; ASR ind (7)
; +71...
	_INDEXED		; get pointer to operand
	CLC				; prepare
	LDA (tmptr)		; check operand
	BPL asri_do		; do not insert C if clear
		SEC				; otherwise, set carry
asri_do:
	ROR 			; emulate arithmetic shift left with preloaded-C rotation
	STA (tmptr)		; update memory
	TAX				; store for later!
	LDA ccr68		; get original flags
	AND #%11110000	; reset relevant bits
	BCC asri_nc		; skip if there was no carry
		ORA #%00000001	; will set C flag
		EOR #%00000010	; toggle V bit
asri_nc:
	CPX #0			; retrieve value
	BNE asri_nz		; skip if not zero
		ORA #%00000100	; set Z flag
asri_nz:
	CPX #0			; retrieve again!
	BPL asri_pl		; skip if positive
		ORA #%00001000	; will set N bit
		EOR #%00000010	; toggle V bit
asri_pl:
	STA ccr68		; update status
	JMP next_op		; standard end of routine

_77:
; ASR ext (6)
; +
	_EXTENDED		; get pointer to operand
	CLC				; prepare
	LDA (tmptr)		; check operand
	BPL asre_do		; do not insert C if clear
		SEC				; otherwise, set carry
asre_do:
	ROR 			; emulate arithmetic shift left with preloaded-C rotation
	STA (tmptr)		; update memory
	TAX				; store for later!
	LDA ccr68		; get original flags
	AND #%11110000	; reset relevant bits
	BCC asre_nc		; skip if there was no carry
		ORA #%00000001	; will set C flag
		EOR #%00000010	; toggle V bit
asre_nc:
	CPX #0			; retrieve value
	BNE asre_nz		; skip if not zero
		ORA #%00000100	; set Z flag
asre_nz:
	CPX #0			; retrieve again!
	BPL asre_pl		; skip if positive
		ORA #%00001000	; will set N bit
		EOR #%00000010	; toggle V bit
asre_pl:
	STA ccr68		; update status
	JMP next_op		; standard end of routine

_44:
; LSR A (2)
; +19/20/21
	LDA ccr68		; get original flags
	AND #%11110000	; reset relevant bits (N always reset)
	LSR a68			; shift A right
	BNE lsra_nz		; skip if not zero
		ORA #%00000100	; set Z flag
lsra_nz:
	BCC lsra_nc		; skip if there was no carry
		ORA #%00000011	; will set C and V flags, is that OK?
lsra_nc:
	STA ccr68		; update status
	JMP next_op		; standard end of routine

_54:
; LSR B (2)
; +19/20/21
	LDA ccr68		; get original flags
	AND #%11110000	; reset relevant bits (N always reset)
	LSR b68			; shift B right
	BNE lsrb_nz		; skip if not zero
		ORA #%00000100	; set Z flag
lsrb_nz:
	BCC lsrb_nc		; skip if there was no carry
		ORA #%00000011	; will set C and V flags, OK?
lsrb_nc:
	STA ccr68		; update status
	JMP next_op		; standard end of routine

_64:
; LSR ind (7)
; +61...
	_INDEXED	; addressing mode
	LDA (tmptr)	; get operand
	LSR
	STA (tmptr)	; modify operand
	TAX			; store for later, worth it
	LDA ccr68	; get original flags
	AND #%11110000	; reset relevant bits (N always reset)
	BCC lsri_nc	; skip if there was no carry
		ORA #%00000011	; will set C and V flags
lsri_nc:
	CPX #0		; retrieve value
	BNE lsri_nz	; skip if not zero
		ORA #%00000100	; set Z flag
lsri_nz:
	STA ccr68	; update status
	JMP next_op	; standard end of routine

_74:
; LSR ext (6)
; +
	_EXTENDED	; addressing mode
	LDA (tmptr)	; get operand
	LSR
	STA (tmptr)	; modify operand
	TAX			; store for later, worth it
	LDA ccr68	; get original flags
	AND #%11110000	; reset relevant bits (N always reset)
	BCC lsre_nc	; skip if there was no carry
		ORA #%00000011	; will set C and V flags
lsre_nc:
	CPX #0		; retrieve value
	BNE lsre_nz	; skip if not zero
		ORA #%00000100	; set Z flag
lsre_nz:
	STA ccr68	; update status
	JMP next_op	; standard end of routine

_97:
; STA A dir (4)
; +33...
	_DIRECT			; X points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA a68			; get A accumulator
	STA e_base, X	; store at operand
	_CC_NZ			; set flags
	JMP next_op		; standard end

_a7:
; STA A ind (6)
; +53...
	_INDEXED		; points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA a68			; get A accumulator
	STA (tmptr)		; store at operand
	_CC_NZ			; set flags
	JMP next_op		; standard end

_b7:
; STA A ext (5)
; +
	_EXTENDED		; points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA a68			; get A accumulator
	STA (tmptr)		; store at operand
	_CC_NZ			; set flags
	JMP next_op		; standard end

_d7:
; STA B dir (4)
; +
	_DIRECT			; X points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA b68			; get B accumulator
	STA e_base, X	; store into operand
	_CC_NZ			; set flags
	JMP next_op		; standard end

_e7:
; STA B ind (6)
; +
	_INDEXED		; points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA b68			; get B accumulator
	STA (tmptr)		; store at operand
	_CC_NZ			; set flags
	JMP next_op		; standard end

_f7:
; STA B ext (5)
; +
	_EXTENDED		; points to operand
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA b68			; get B accumulator
	STA (tmptr)		; store at operand
	_CC_NZ			; set flags
	JMP next_op		; standard end

_80:
; SUB A imm (2)
; +44...
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	_IMMEDIATE		; get operand
	LDA a68			; get accumulator A
	SEC				; prepare
	SBC tmptr		; subtract without carry
	STA a68			; update accumulator
	_CC_NZ			; check these
	BCS subam_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502?)
subam_nc:
	BVC subam_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
subam_nv:
	JMP next_op		; standard end

_90:
; SUB A dir (3)
; +44...
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	_DIRECT			; get operand
	LDA a68			; get accumulator A
	SEC				; prepare
	SBC e_base,X		; subtract without carry
	STA a68			; update accumulator
	_CC_NZ			; check these
	BCS subad_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502?)
subad_nc:
	BVC subad_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
subad_nv:
	JMP next_op		; standard end

_a0:
; SUB A ind (5)
; +64...
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	_INDEXED		; get operand
	LDA a68			; get accumulator A
	SEC				; prepare
	SBC (tmptr)		; subtract without carry
	STA a68			; update accumulator
	_CC_NZ			; check these
	BCS subai_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502?)
subai_nc:
	BVC subai_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
subai_nv:
	JMP next_op		; standard end

_b0:
; SUB A ext (4)
; +
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	_EXTENDED		; get operand
	LDA a68			; get accumulator A
	SEC				; prepare
	SBC (tmptr)		; subtract without carry
	STA a68			; update accumulator
	_CC_NZ			; check these
	BCS subae_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502?)
subae_nc:
	BVC subae_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
subae_nv:
	JMP next_op		; standard end

_c0:
; SUB B imm (2)
; +
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	_IMMEDIATE		; get operand
	LDA b68			; get accumulator B
	SEC				; prepare
	SBC tmptr		; subtract without carry
	STA b68			; update accumulator
	_CC_NZ			; check these
	BCS subbm_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502?)
subbm_nc:
	BVC subbm_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
subbm_nv:
	JMP next_op		; standard end

_d0:
; SUB B dir (3)
; +
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	_DIRECT			; get operand
	LDA b68			; get accumulator B
	SEC				; prepare
	SBC e_base, X	; subtract without carry
	STA b68			; update accumulator
	_CC_NZ			; check these
	BCS subbd_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502?)
subbd_nc:
	BVC subbd_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
subbd_nv:
	JMP next_op		; standard end

_e0:
; SUB B ind (5)
; +
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	_INDEXED		; get operand
	LDA b68			; get accumulator B
	SEC				; prepare
	SBC (tmptr)		; subtract without carry
	STA b68			; update accumulator
	_CC_NZ			; check these
	BCS subbi_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502?)
subbi_nc:
	BVC subbi_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
subbi_nv:
	JMP next_op		; standard end

_f0:
; SUB B ext (4)
; +
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	_EXTENDED		; get operand
	LDA b68			; get accumulator B
	SEC				; prepare
	SBC (tmptr)		; subtract without carry
	STA b68			; update accumulator
	_CC_NZ			; check these
	BCS subbe_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502?)
subbe_nc:
	BVC subbe_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
subbe_nv:
	JMP next_op		; standard end

_10:
; SBA (2)
; +42/45.5/49
; ** might set V according to native 6502 result **
	LDA a68		; get A
	BPL sba_nm	; skip if was positive
		SMB1 ccr68	; set V like N, to be toggled later ***Rockwell***
		BRA sba_sv	; do not clear V
sba_nm:
	RMB1 ccr68	; clear V ***Rockwell***
sba_sv:
	SEC			; prepare for subtraction
	SBC b68		; minus B
	STA a68		; store result in A
	LDA ccr68	; get original flags
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
	STA ccr68	; update flags
	JMP next_op	; standard end of routine

_82:
; SBC A imm (2)
; +52...
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	_IMMEDIATE		; get operand
	SEC				; prepare
	LDA ccr68		; get original flags
	BIT #%00000001	; mask for C flag
	BEQ sbcam_do	; skip if C clear
		CLC				; otherwise, set carry, opposite of 6502?
sbcam_do:
	LDA a68			; get accumulator A
	SBC tmptr		; subtract with carry
	STA a68			; update accumulator
	_CC_NZ			; check these
	BCS sbcam_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502?)
sbcam_nc:
	BVC sbcam_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
sbcam_nv:
	JMP next_op		; standard end

_92:
; SBC A dir (3)
; +52...
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	_DIRECT			; get operand
	SEC				; prepare
	LDA ccr68		; get original flags
	BIT #%00000001	; mask for C flag
	BEQ sbcad_do	; skip if C clear
		CLC				; otherwise, set carry, opposite of 6502?
sbcad_do:
	LDA a68			; get accumulator A
	SBC e_base, X	; subtract with carry
	STA a68			; update accumulator
	_CC_NZ			; check these
	BCS sbcad_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502?)
sbcad_nc:
	BVC sbcad_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
sbcad_nv:
	JMP next_op		; standard end

_a2:
; SBC A ind (5)
; +72...
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	_INDEXED		; get operand
	SEC				; prepare
	LDA ccr68		; get original flags
	BIT #%00000001	; mask for C flag
	BEQ sbcai_do	; skip if C clear
		CLC				; otherwise, set carry, opposite of 6502?
sbcai_do:
	LDA a68			; get accumulator A
	SBC (tmptr)		; subtract with carry
	STA a68			; update accumulator
	_CC_NZ			; check these
	BCS sbcai_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502?)
sbcai_nc:
	BVC sbcai_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
sbcai_nv:
	JMP next_op		; standard end

_b2:
; SBC A ext (4)
; +
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	_EXTENDED		; get operand
	SEC				; prepare
	LDA ccr68		; get original flags
	BIT #%00000001	; mask for C flag
	BEQ sbcae_do	; skip if C clear
		CLC				; otherwise, set carry, opposite of 6502?
sbcae_do:
	LDA a68			; get accumulator A
	SBC (tmptr)		; subtract with carry
	STA a68			; update accumulator
	_CC_NZ			; check these
	BCS sbcae_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502?)
sbcae_nc:
	BVC sbcae_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
sbcae_nv:
	JMP next_op		; standard end

_c2:
; SBC B imm (2)
; +
	_IMMEDIATE		; get operand
	SEC				; prepare
	LDA ccr68		; get original flags
	BIT #%00000001	; mask for C flag
	BEQ sbcbm_do	; skip if C clear
		CLC				; otherwise, set carry, opposite of 6502?
sbcbm_do:
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	LDA b68			; get accumulator B
	SBC tmptr		; subtract with carry
	STA b68			; update accumulator
	_CC_NZ			; check these
	BCS sbcbm_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502?)
sbcbm_nc:
	BVC sbcbm_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
sbcbm_nv:
	JMP next_op		; standard end

_d2:
; SBC B dir (3)
; +
	_DIRECT			; get operand
	SEC				; prepare
	LDA ccr68		; get original flags
	BIT #%00000001	; mask for C flag
	BEQ sbcbd_do	; skip if C clear
		CLC				; otherwise, set carry, opposite of 6502?
sbcbd_do:
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	LDA b68			; get accumulator B
	SBC e_base, X	; subtract with carry
	STA b68			; update accumulator
	_CC_NZ			; check these
	BCS sbcbd_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502?)
sbcbd_nc:
	BVC sbcbd_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
sbcbd_nv:
	JMP next_op		; standard end

_e2:
; SBC B ind (5)
; +
	_INDEXED		; get operand
	SEC				; prepare
	LDA ccr68		; get original flags
	BIT #%00000001	; mask for C flag
	BEQ sbcbi_do	; skip if C clear
		CLC				; otherwise, set carry, opposite of 6502?
sbcbi_do:
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	LDA b68			; get accumulator B
	SBC (tmptr)		; subtract with carry
	STA b68			; update accumulator
	_CC_NZ			; check these
	BCS sbcbi_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502?)
sbcbi_nc:
	BVC sbcbi_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
sbcbi_nv:
	JMP next_op		; standard end

_f2:
; SBC B ext (4)
; +
	_EXTENDED		; get operand
	SEC				; prepare
	LDA ccr68		; get original flags
	BIT #%00000001	; mask for C flag
	BEQ sbcbe_do	; skip if C clear
		CLC				; otherwise, set carry, opposite of 6502?
sbcbe_do:
	AND #%11110000	; clear relevant bits
	STA ccr68		; update flags
	LDA b68			; get accumulator B
	SBC (tmptr)		; subtract with carry
	STA b68			; update accumulator
	_CC_NZ			; check these
	BCS sbcbe_nc	; only if borrow...
		SMB0 ccr68		; ...set C flag (opposite of 6502?)
sbcbe_nc:
	BVC sbcbe_nv	; only if overflow...
		SMB1 ccr68		; ...set V flag
sbcbe_nv:
	JMP next_op		; standard end

_16:
; TAB (2)
; +20/24/28
	LDA ccr68	; get original flags
	AND #%11110001	; reset N,Z, and always V
	STA ccr68	; update status
	LDX a68		; get A
	STX b68		; store in B
	_CC_NZ		; set NZ flags when needed
	JMP next_op	; standard end of routine

_17:
; TBA (2)
; +20/24/28
	LDA ccr68	; get original flags
	AND #%11110001	; reset N,Z, and always V
	STA ccr68	; update status
	LDX b68		; get B
	STX a68		; store in A
	_CC_NZ		; check these flags
	JMP next_op	; standard end of routine

_4d:
; TST A (2)
; +17...
	LDA ccr68	; get original flags
	AND #%11110000	; reset relevant bits
	STA ccr68	; update status
	LDA a68		; check accumulator A
	_CC_NZ		; check these flags
	JMP next_op	; standard end of routine

_5d:
; TST B (2)
; +17...
	LDA ccr68	; get original flags
	AND #%11110000	; reset relevant bits
	STA ccr68	; update status
	LDA b68		; check accumulator B
	_CC_NZ		; check these flags
	JMP next_op	; standard end of routine

_6d:
; TST ind (7)
; +50...
	LDA ccr68		; get original flags
	AND #%11110000	; reset relevant bits
	STA ccr68		; update status
	_INDEXED		; set pointer
	LDA (tmptr)		; check operand
	_CC_NZ			; check these flags
	JMP next_op		; standard end of routine

_7d:
; TST ext (6)
; +
	LDA ccr68		; get original flags
	AND #%11110000	; reset relevant bits
	STA ccr68		; update status
	_EXTENDED		; set pointer
	LDA (tmptr)		; check operand
	_CC_NZ			; check these flags
	JMP next_op		; standard end of routine

; ** index register and stack pointer ops **

_8c:
; CPX imm (3)
; +51...
	LDA ccr68		; get original flags
	AND #%11110001	; reset relevant bits
	STA ccr68		; update flags
	_PC_ADV			; get first operand
	SEC				; prepare
	LDA x68 + 1		; MSB at X
	SBC (pc68), Y	; subtract memory
	STA tmptr		; keep for later
	BPL cpxm_pl		; not negative
		SMB3 ccr68		; otherwise set N flag
cpxm_pl:
	_PC_ADV			; get second operand
	LDA x68			; LSB at X
	SBC (pc68), Y	; value LSB
	ORA tmptr		; blend with stored MSB
	BNE cpxm_nz		; was not zero
		SMB2 ccr68		; otherwise set Z
cpxm_nz:
	BVC cpxm_nv		; only if overflow...
		SMB1 ccr68		; ...set V flag
cpxm_nv:
	JMP next_op		; standard end

_9c:
; CPX dir (4)
; +56...
	LDA ccr68		; get original flags
	AND #%11110001	; reset relevant bits
	STA ccr68		; update flags
	_DIRECT			; get operand
	SEC				; prepare
	LDA x68 + 1		; MSB at X
	SBC e_base, X	; subtract memory
	STA tmptr		; keep for later
	BPL cpxd_pl		; not negative
		SMB3 ccr68		; otherwise set N flag
cpxd_pl:
	_PC_ADV			; get second operand
	LDA x68			; LSB at X
	SBC e_base + 1, X	; value LSB
	ORA tmptr		; blend with stored MSB
	BNE cpxd_nz		; was not zero
		SMB2 ccr68		; otherwise set Z
cpxd_nz:
	BVC cpxd_nv		; only if overflow...
		SMB1 ccr68		; ...set V flag
cpxd_nv:
	JMP next_op		; standard end

_ac:
; CPX ind (6)
; +82...
	LDA ccr68		; get original flags
	AND #%11110001	; reset relevant bits
	STA ccr68		; update flags
	_INDEXED		; get operand
	SEC				; prepare
	LDA x68 + 1		; MSB at X
	SBC (tmptr)		; subtract memory
	TAX				; keep for later
	BPL cpxi_pl		; not negative
		SMB3 ccr68		; otherwise set N flag
cpxi_pl:
	INC tmptr		; point to next byte
	BNE cpxi_nw		; usually will not wrap
		LDA tmptr + 1	; get original MSB
		INC				; advance
		_AH_BOUND		; inject
		STA tmptr + 1	; restore
cpxi_nw:
	LDA x68			; LSB at X
	SBC (tmptr)		; value LSB
	STX tmptr		; retrieve old MSB
	ORA tmptr		; blend with stored MSB
	BNE cpxi_nz		; was not zero
		SMB2 ccr68		; otherwise set Z
cpxi_nz:
	BVC cpxi_nv		; only if overflow...
		SMB1 ccr68		; ...set V flag
cpxi_nv:
	JMP next_op		; standard end

_bc:
; CPX ext (5)
; +
	LDA ccr68		; get original flags
	AND #%11110001	; reset relevant bits
	STA ccr68		; update flags
	_EXTENDED		; get operand
	SEC				; prepare
	LDA x68 + 1		; MSB at X
	SBC (tmptr)		; subtract memory
	TAX				; keep for later
	BPL cpxe_pl		; not negative
		SMB3 ccr68		; otherwise set N flag
cpxe_pl:
	INC tmptr		; point to next byte
	BNE cpxe_nw		; usually will not wrap
		LDA tmptr + 1	; get original MSB
		INC				; advance
		_AH_BOUND		; inject
		STA tmptr + 1	; restore
cpxe_nw:
	LDA x68			; LSB at X
	SBC (tmptr)		; value LSB
	STX tmptr		; retrieve old MSB
	ORA tmptr		; blend with stored MSB
	BNE cpxe_nz		; was not zero
		SMB2 ccr68		; otherwise set Z
cpxe_nz:
	BVC cpxe_nv		; only if overflow...
		SMB1 ccr68		; ...set V flag
cpxe_nv:
	JMP next_op		; standard end

_09:
; DEX (4)
; +17...
	LDA x68			; check LSB
	BEQ dex_w		; if zero, will wrap upon decrease!
		DEC x68			; otherwise just decrease LSB
		BEQ dex_z		; if zero now, could be all zeroes!
			RMB2 ccr68		; clear Z bit, *** Rockwell only! ***
			JMP next_op		; usual end
dex_w:
		DEC x68			; decrease as usual
		DEC x68 + 1		; wrap MSB
		RMB2 ccr68		; clear Z bit, *** Rockwell only! ***
		JMP next_op		; usual end
dex_z:
	LDA x68 + 1		; check MSB
	BEQ dex_zz		; it went down to zero!
		RMB2 ccr68		; clear Z bit, *** Rockwell only! ***
		JMP next_op		; usual end
dex_zz:
	SMB2 ccr68	; set Z bit, *** Rockwell only! ***
	JMP next_op	; rarest end of routine

_34:
; DES (4)
; +10/10/24
	LDA sp68		; check older LSB
	BEQ des_w		; will wrap upon decrease!
		DEC sp68		; decrease LSB
		JMP next_op		; usual end
des_w:
	DEC sp68		; as usual
	LDA sp68 + 1	; get MSB
	DEC				; decrease
	_AH_BOUND		; keep injected
	JMP next_op		; wrapped end

_08:
; INX (4)
; +12/12/21
	INC x68		; increase LSB
	BEQ inx_w	; wrap is a rare case
		RMB2 ccr68	; clear Z bit, *** Rockwell only! ***
		JMP next_op	; usual end
inx_w:
	INC x68 + 1	; increase MSB
	BEQ inx_z	; becoming zero is even rarer!
		RMB2 ccr68	; clear Z bit, *** Rockwell only! ***
		JMP next_op	; wrapped non-zero end (+20 in this case)
inx_z:
	SMB2 ccr68	; set Z bit, *** Rockwell only! ***
	JMP next_op	; rarest end of routine

_31:
; INS (4)
; +7/7/22
	INC sp68	; increase LSB
	BEQ ins_w	; wrap is a rare case
		JMP next_op	; usual end
ins_w:
	LDA sp68 + 1	; prepare to inject
	INC				; increase MSB
	_AH_BOUND
	STA sp68 + 1	; update pointer
	JMP next_op		; wrapped end

_ce:
; LDX imm (3)
; +43...
	LDA ccr68		; get original flags
	AND #%11110001	; reset relevant bits
	STA ccr68		; update flags
	_PC_ADV			; get first operand
	LDA (pc68), Y	; value MSB
	BPL ldxm_pl		; not negative
		SMB3 ccr68		; otherwise set N flag
ldxm_pl:
	STA x68 + 1		; update register
	_PC_ADV			; get second operand
	LDA (pc68), Y	; value LSB
	STA x68			; register complete
	ORA x68 + 1		; check for zero
	BNE ldxm_nz		; was not zero
		SMB2 ccr68		; otherwise set Z
ldxm_nz:
	JMP next_op		; standard end

_de:
; LDX dir (4)
; +73...
	LDA ccr68		; get original flags (3)
	AND #%11110001	; reset relevant bits (2)
	STA ccr68		; update flags (3)
	_DIRECT			; get operand address (31...)
	LDX #2			; counter of expected zeroes (2)
	LDA (tmptr)		; value MSB (5)
	BNE ldxd_nz1	; skip first zero detection (3/2)
		DEX				; MSB was zero (0/2)
ldxd_nz1:
	BPL ldxd_pl		; not negative (3/2)
		SMB3 ccr68		; otherwise set N flag (0/5)
ldxd_pl:
	STA x68 + 1		; update register (3)
	INC tmptr		; point to next byte! (5)
	BEQ ldxd_w		; rare wrap (2/3)
		LDA (tmptr)		; value LSB (5)
		BNE ldxd_nz2	; not zero anyway (3/2)
			DEX				; LSB was zero
			BNE ldxd_nz2	; and neither was MSB
				SMB2 ccr68		; otherwise set Z flag
ldxd_nz2:
		STA x68			; register complete (3)
		JMP next_op		; standard end
ldxd_w:
	LDA tmptr + 1	; check pointer MSB
	INC				; increase from wrapping
	_AH_BOUND		; keep injected
	STA tmptr + 1	; update pointer
	LDA (tmptr)		; value LSB
	BNE ldxd_nz3	; not zero anyway
		DEX				; LSB was zero
		BNE ldxd_nz3	; and neither was MSB
			SMB2 ccr68		; otherwise set Z flag
ldxd_nz3:
	STA x68			; register complete
	JMP next_op		; standard end

_ee:
; LDX ind (6)
; +73...
	LDA ccr68		; get original flags (3)
	AND #%11110001	; reset relevant bits (2)
	STA ccr68		; update flags (3)
	_INDEXED		; get operand address (31...)
	LDX #2			; counter of expected zeroes (2)
	LDA (tmptr)		; value MSB (5)
	BNE ldxi_nz1	; skip first zero detection (3/2)
		DEX				; MSB was zero (0/2)
ldxi_nz1:
	BPL ldxi_pl		; not negative (3/2)
		SMB3 ccr68		; otherwise set N flag (0/5)
ldxi_pl:
	STA x68 + 1		; update register (3)
	INC tmptr		; point to next byte! (5)
	BEQ ldxi_w		; rare wrap (2/3)
		LDA (tmptr)		; value LSB (5)
		BNE ldxi_nz2	; not zero anyway (3/2)
			DEX				; LSB was zero
			BNE ldxi_nz2	; and neither was MSB
				SMB2 ccr68		; otherwise set Z flag
ldxi_nz2:
		STA x68			; register complete (3)
		JMP next_op		; standard end
ldxi_w:
	LDA tmptr + 1	; check pointer MSB
	INC				; increase from wrapping
	_AH_BOUND		; keep injected
	STA tmptr + 1	; update pointer
	LDA (tmptr)		; value LSB
	BNE ldxi_nz3	; not zero anyway
		DEX				; LSB was zero
		BNE ldxi_nz3	; and neither was MSB
			SMB2 ccr68		; otherwise set Z flag
ldxi_nz3:
	STA x68			; register complete
	JMP next_op		; standard end

_fe:
; LDX ext (5)
; +73...
	LDA ccr68		; get original flags (3)
	AND #%11110001	; reset relevant bits (2)
	STA ccr68		; update flags (3)
	_EXTENDED		; get operand address (31...)
	LDX #2			; counter of expected zeroes (2)
	LDA (tmptr)		; value MSB (5)
	BNE ldxe_nz1	; skip first zero detection (3/2)
		DEX				; MSB was zero (0/2)
ldxe_nz1:
	BPL ldxe_pl		; not negative (3/2)
		SMB3 ccr68		; otherwise set N flag (0/5)
ldxe_pl:
	STA x68 + 1		; update register (3)
	INC tmptr		; point to next byte! (5)
	BEQ ldxe_w		; rare wrap (2/3)
		LDA (tmptr)		; value LSB (5)
		BNE ldxe_nz2	; not zero anyway (3/2)
			DEX				; LSB was zero
			BNE ldxe_nz2	; and neither was MSB
				SMB2 ccr68		; otherwise set Z flag
ldxe_nz2:
		STA x68			; register complete (3)
		JMP next_op		; standard end
ldxe_w:
	LDA tmptr + 1	; check pointer MSB
	INC				; increase from wrapping
	_AH_BOUND		; keep injected
	STA tmptr + 1	; update pointer
	LDA (tmptr)		; value LSB
	BNE ldxe_nz3	; not zero anyway
		DEX				; LSB was zero
		BNE ldxe_nz3	; and neither was MSB
			SMB2 ccr68		; otherwise set Z flag
ldxe_nz3:
	STA x68			; register complete
	JMP next_op		; standard end

_8e:
; LDS imm (3)
; +42...
	LDA ccr68		; get original flags
	AND #%11110001	; reset relevant bits -- Z always zero because of injection!
	STA ccr68		; update flags
	_PC_ADV			; get first operand
	LDA (pc68), Y	; value MSB
	BPL ldsm_pl		; not negative
		SMB3 ccr68		; otherwise set N flag
ldsm_pl:
	_AH_BOUND		; keep injected
	STA sp68 + 1	; update register
	_PC_ADV			; get second operand
	LDA (pc68), Y	; value LSB
	STA sp68		; register complete
	JMP next_op		; standard end

_9e:
; LDS dir (4)
; +42...
	LDA ccr68		; get original flags
	AND #%11110001	; reset relevant bits -- Z always zero because of injection!
	STA ccr68		; update flags
	_DIRECT			; get operand address
	LDA e_base, X	; value MSB
	BPL ldsd_pl		; not negative
		SMB3 ccr68		; otherwise set N flag
ldsd_pl:
	_AH_BOUND		; keep injected
	STA sp68 + 1	; update register
	LDA e_base + 1, X	; value LSB
	STA sp68		; register complete
	JMP next_op		; standard end

_ae:
; LDS ind (6)
; +70...
	LDA ccr68		; get original flags
	AND #%11110001	; reset relevant bits -- Z always zero because of injection!
	STA ccr68		; update flags
	_INDEXED		; get operand address
	LDA (tmptr)		; value MSB
	BPL ldsi_pl		; not negative
		SMB3 ccr68		; otherwise set N flag
ldsi_pl:
	_AH_BOUND		; keep injected
	STA sp68 + 1	; update register
	INC tmptr		; point to next byte!
	BEQ ldsi_w		; rare wrap
		LDA (tmptr)		; value LSB
		STA sp68		; register complete
		JMP next_op		; standard end
ldsi_w:
	LDA tmptr + 1	; check pointer MSB
	INC				; increase from wrapping
	_AH_BOUND		; keep injected
	STA tmptr + 1	; update pointer
	LDA (tmptr)		; value LSB
	STA sp68		; register complete
	JMP next_op		; standard end

_be:
; LDS ext (5)
; +
	LDA ccr68		; get original flags
	AND #%11110001	; reset relevant bits -- Z always zero because of injection!
	STA ccr68		; update flags
	_EXTENDED		; get operand address
	LDA (tmptr)		; value MSB
	BPL ldse_pl		; not negative
		SMB3 ccr68		; otherwise set N flag
ldse_pl:
	_AH_BOUND		; keep injected
	STA sp68 + 1	; update register
	INC tmptr		; point to next byte!
	BEQ ldse_w		; rare wrap
		LDA (tmptr)		; value LSB
		STA sp68		; register complete
		JMP next_op		; standard end
ldse_w:
	LDA tmptr + 1	; check pointer MSB
	INC				; increase from wrapping
	_AH_BOUND		; keep injected
	STA tmptr + 1	; update pointer
	LDA (tmptr)		; value LSB
	STA sp68		; register complete
	JMP next_op		; standard end

_df:
; STX dir (5)
; +56...
	LDA ccr68		; get original flags (3)
	AND #%11110001	; reset relevant bits (2)
	LDX x68 + 1		; check sign! (3)
	BPL stxd_pl		; was not negative (3/2)
		ORA #%00001000	; set N flag otherwise (0/2)
stxd_pl:
	STA ccr68		; update flags (3)
	TXA				; retrieve MSB (2)
	ORA x68			; blend with LSB (3)
	BNE stxd_nz		; only if it is zero (3/2)
		SMB2 ccr68		; set Z flag (0/5)
stxd_nz:
	_DIRECT			; get operand address (12...)
	LDA x68 + 1		; value MSB (3)
	STA e_base, X	; store in memory (4)
	INC tmptr		; point to next byte! (5)
	BEQ stxd_w		; rare wrap (2/3)
		LDA x68			; value LSB (3)
		STA e_base + 1, X	; store in memory (4)
		JMP next_op		; standard end
stxd_w:
	LDA tmptr + 1	; check pointer MSB
	INC				; increase from wrapping
	_AH_BOUND		; keep injected
	STA tmptr + 1	; update pointer
	LDA x68			; value LSB (3)
	STA e_base + 1, X	; store in memory (4)
	JMP next_op		; standard end

_ef:
; STX ind (7)
; +75...
	LDA ccr68		; get original flags (3)
	AND #%11110001	; reset relevant bits (2)
	LDX x68 + 1		; check sign! (3)
	BPL stxi_pl		; was not negative (3/2)
		ORA #%00001000	; set N flag otherwise (0/2)
stxi_pl:
	STA ccr68		; update flags (3)
	TXA				; retrieve MSB (2)
	ORA x68			; blend with LSB (3)
	BNE stxi_nz		; only if it is zero (3/2)
		SMB2 ccr68		; set Z flag (0/5)
stxi_nz:
	_INDEXED		; get operand address (31...)
	TXA				; value MSB, already loaded (2)
	STA (tmptr)		; store in memory (5)
	INC tmptr		; point to next byte! (5)
	BEQ stxi_w		; rare wrap (2/3)
		LDA x68			; value LSB (3)
		STA (tmptr)		; store in memory (5)
		JMP next_op		; standard end
stxi_w:
	LDA tmptr + 1	; check pointer MSB
	INC				; increase from wrapping
	_AH_BOUND		; keep injected
	STA tmptr + 1	; update pointer
	LDA x68			; value LSB (3)
	STA (tmptr)		; store in memory (5)
	JMP next_op		; standard end

_ff:
; STX ext (6)
; +75...
	LDA ccr68		; get original flags (3)
	AND #%11110001	; reset relevant bits (2)
	LDX x68 + 1		; check sign! (3)
	BPL stxe_pl		; was not negative (3/2)
		ORA #%00001000	; set N flag otherwise (0/2)
stxe_pl:
	STA ccr68		; update flags (3)
	TXA				; retrieve MSB (2)
	ORA x68			; blend with LSB (3)
	BNE stxe_nz		; only if it is zero (3/2)
		SMB2 ccr68		; set Z flag (0/5)
stxe_nz:
	_EXTENDED		; get operand address (31...)
	TXA				; value MSB, already loaded (2)
	STA (tmptr)		; store in memory (5)
	INC tmptr		; point to next byte! (5)
	BEQ stxe_w		; rare wrap (2/3)
		LDA x68			; value LSB (3)
		STA (tmptr)		; store in memory (5)
		JMP next_op		; standard end
stxe_w:
	LDA tmptr + 1	; check pointer MSB
	INC				; increase from wrapping
	_AH_BOUND		; keep injected
	STA tmptr + 1	; update pointer
	LDA x68			; value LSB (3)
	STA (tmptr)		; store in memory (5)
	JMP next_op		; standard end

_9f:
; STS dir (5)
; +37...
	LDA ccr68		; get original flags
	AND #%11110001	; reset relevant bits -- Z always zero because of injection!
	STA ccr68		; update flags
	_DIRECT			; get operand address
	LDA sp68		; get original
	STA e_base, X	; value MSB
	BPL stsd_pl		; not negative
		SMB3 ccr68		; otherwise set N flag
stsd_pl:
	LDA sp68 + 1	; get LSB
	STA e_base + 1, X	; store it
	JMP next_op		; standard end

_af:
; STS ind (7)
; +65...
	LDA ccr68		; get original flags
	AND #%11110001	; reset relevant bits -- Z always zero because of injection!
	STA ccr68		; update flags
	_INDEXED		; get operand address
	LDA sp68 + 1	; value MSB
	STA (tmptr)		; store in memory
	BPL stsi_pl		; not negative
		SMB3 ccr68		; otherwise set N flag
stsi_pl:
	INC tmptr		; point to next byte!
	BEQ stsi_w		; rare wrap
		LDA sp68		; value LSB
		STA (tmptr)		; register complete
		JMP next_op		; standard end
stsi_w:
	LDA tmptr + 1	; check pointer MSB
	INC				; increase from wrapping
	_AH_BOUND		; keep injected
	STA tmptr + 1	; update pointer
	LDA sp68		; value LSB
	STA (tmptr)		; register complete
	JMP next_op		; standard end

_bf:
; STS ext (6)
; +
	LDA ccr68		; get original flags
	AND #%11110001	; reset relevant bits -- Z always zero because of injection!
	STA ccr68		; update flags
	_EXTENDED		; get operand address
	LDA sp68 + 1	; value MSB
	STA (tmptr)		; store in memory
	BPL stse_pl		; not negative
		SMB3 ccr68		; otherwise set N flag
stse_pl:
	INC tmptr		; point to next byte!
	BEQ stse_w		; rare wrap
		LDA sp68		; value LSB
		STA (tmptr)		; register complete
		JMP next_op		; standard end
stse_w:
	LDA tmptr + 1	; check pointer MSB
	INC				; increase from wrapping
	_AH_BOUND		; keep injected
	STA tmptr + 1	; update pointer
	LDA sp68		; value LSB
	STA (tmptr)		; register complete
	JMP next_op		; standard end

_30:
; TSX (4)
; +21/23/25
	LDA sp68+1		; get stack pointer MSB, to be injected
	LDX sp68		; get stack pointer LSB
	INX				; point to last used!!!
	STX x68			; store in X
	BEQ tsx_w		; rare wrap
tsx_do:
		_AH_BOUND		; inject
		STA x68 + 1		; pointer complete
		JMP next_op		; standard end of routine
tsx_w:
	INC				; increase MSB
	_AH_BOUND		; inject
	STA x68 + 1		; pointer complete
	JMP next_op		; rarer end of routine

_35:
; TXS (4)
; +21/21.5/25
	LDA x68+1		; MSB will be injected
	LDX x68			; check LSB
	BEQ txs_w		; will wrap upon decrease
		DEX				; as expected
		STX sp68		; copy
		_AH_BOUND		; always!
		STA sp68+1		; pointer ready
		JMP next_op		; standard end
txs_w:
	DEX				; as expected
	STX sp68		; copy
	DEC				; will also affect MSB
	_AH_BOUND		; always!
	STA sp68+1		; pointer ready
	JMP next_op		; standard end

; ** jumps and branching **

_20:
; BRA rel (4)
; -5+25/34.3/52
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
			JMP execute		; resume execution
bra_bc:
		INC pc68 + 1	; carry on msb
		BPL bra_lf		; skip if in low area
			RMB6 pc68+1		; otherwise clear A14
			JMP execute		; and jump
bra_lf:
		SMB6 pc68+1			; low area needs A14 set
		JMP execute
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
; +11/24.8/65
	_PC_ADV				; go for operand
	BBS0 ccr68, bhi_go	; neither carry...
	BBS2 ccr68, bhi_go	; ...nor zero...
		JMP bra_do		; ...do branch
bhi_go:
	JMP next_op		; exit without branching

_23:
; BLS rel (4)
; +11...
	_PC_ADV				; go for operand
	BBS0 ccr68, bls_do	; either carry...
	BBS2 ccr68, bls_do	; ...or zero will do
		JMP next_op			; exit without branching
bls_do:
		JMP bra_do		; do branch

_24:
; BCC rel (4)
; +10...
	_PC_ADV				; go for operand
	BBR0 ccr68, bcc_do	; only if carry clear
		JMP next_op			; exit without branching otherwise
bcc_do:
	JMP bra_do			; do branch

_25:
; BCS rel (4)
; +10...
	_PC_ADV				; go for operand
	BBS0 ccr68, bcs_do	; only if carry set...
		JMP next_op			; exit without branching
bcs_do:
	JMP bra_do			; branch

_26:
; BNE rel (4)
; +10...
	_PC_ADV				; go for operand
	BBR2 ccr68, bne_do	; only if zero clear...
		JMP next_op			; exit without branching
bne_do:
	JMP bra_do			; branch

_27:
; BEQ rel (4)
; +10...
	_PC_ADV				; go for operand
	BBS2 ccr68, beq_do	; only if zero set...
		JMP next_op			; exit without branching
beq_do:
	JMP bra_do			; branch

_28:
; BVC rel (4)
; +10...
	_PC_ADV				; go for operand
	BBR1 ccr68, bvc_do		; only if overflow clear...
		JMP next_op			; exit without branching
bvc_do:
	JMP bra_do			; branch

_29:
; BVS rel (4)
; +10...
	_PC_ADV				; go for operand
	BBS1 ccr68, bvs_do	; only if overflow set...
		JMP next_op			; exit without branching
bvs_do:
	JMP bra_do			; branch

_2a:
; BPL rel (4)
; +10...
	_PC_ADV				; go for operand
	BBR3 ccr68, bpl_do	; only if plus...
		JMP next_op			; exit without branching
bpl_do:
		JMP bra_do			; branch

_2b:
; BMI rel (4)
; +10...
	_PC_ADV				; go for operand
	BBS3 ccr68, bmi_do	; only if negative...
		JMP next_op			; exit without branching
bmi_do:
	JMP bra_do			; ...do branch

_2c:
; BGE rel (4)
; +17...
	_PC_ADV			; go for operand
	LDA ccr68		; get flags
	AND #%00001010	; filter N and V only
	BIT #%00000010	; check V
	BEQ bge_nx		; do not XOR N if clear
		EOR #%00001000	; toggle N
bge_nx:
	BEQ bge_do		; branch N XOR V is zero
		JMP next_op		; exit without branching
bge_do:
	JMP bra_do		; jump otherwise

_2d:
; BLT rel (4)
; +17...
	_PC_ADV			; go for operand
	LDA ccr68		; get flags
	AND #%00001010	; filter N and V only
	BIT #%00000010	; check V
	BEQ blt_nx		; do not XOR N if clear
		EOR #%00001000	; toggle N
blt_nx:
	BNE blt_do		; branch if N XOR V is true
		JMP next_op		; exit without branching
blt_do:
	JMP bra_do		; jump otherwise

_2e:
; BGT rel (4)
; +17...
	_PC_ADV			; go for operand
	LDA ccr68		; get flags
	AND #%00001110	; filter Z, N and V
	BIT #%00000010	; check V
	BEQ bgt_nx		; do not XOR N if clear
		EOR #%00001000	; toggle N
bgt_nx:
	BEQ bgt_do		; only if N XOR V (OR Z) is false
		JMP next_op		; exit without branching
bgt_do:
	JMP bra_do		; jump otherwise

_2f:
; BLE rel (4)
; +17...
	_PC_ADV			; go for operand
	LDA ccr68		; get flags
	AND #%00001110	; filter Z, N and V
	BIT #%00000010	; check V
	BEQ ble_nx		; do not XOR N if clear
		EOR #%00001000	; toggle N
ble_nx:
	BNE ble_do		; only if N XOR V (OR Z) is true
		JMP next_op		; exit without branching
ble_do:
	JMP bra_do		; jump otherwise

_8d:
; BSR rel (8)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_6e:
; JMP ind (4)
; -5+30...
	_PC_ADV			; get operand
	LDA (pc68), Y	; set offset
	CLC				; prepare
	ADC x68			; add LSB
	TAY				; this is new offset!
	LDA x68 + 1		; get MSB
	ADC #0			; propagate carry
	_AH_BOUND		; stay injected
	STA pc68 + 1	; update pointer
	JMP execute		; do jump

_7e:
; JMP ext (3)
; -5+32//46
	_PC_ADV		; go for destination MSB
	LDA (pc68), Y	; get it
	_AH_BOUND	; check against emulated limits
	TAX			; hold it for a moment
	_PC_ADV		; now for the LSB
	LDA (pc68), Y	; get it
	TAY			; this works as index
	STX pc68 + 1	; MSB goes into register area
	JMP execute	; all done (-5 for jumps, all this is +32...46)

_ad:
; JSR ind (8)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_bd:
; JSR ext (9)
	; ***** TO DO ***** TO DO *****
	JMP next_op	; standard end

_39:
; RTS (5)
; +29/29/44
	INC sp68		; pre-increment
	BEQ rts_w		; should correct MSB, rare?
rts_do:
		LDA (sp68)		; take return MSB from stack
		STA pc68 + 1	; store into register
		INC sp68		; go for next
		BEQ rts_w2		; another chance for wrapping
			LDA (sp68)		; pop the LSB
			TAY				; which is new offset
			JMP execute		; and resume execution
rts_w:
	LDA sp68 + 1	; get stack pointer MSB
	INC				; increase MSB
	_AH_BOUND		; keep injected
	STA sp68 + 1	; update real thing
	LDA (sp68)		; take return MSB from stack
	STA pc68 + 1	; store into register
	INC sp68		; go for next
	LDA (sp68)		; pop the LSB
	TAY				; which is new offset
	JMP execute		; and resume execution
rts_w2:
	LDA sp68 + 1	; get stack pointer MSB
	INC				; increase MSB
	_AH_BOUND		; keep injected
	STA sp68 + 1	; update real thing
	LDA (sp68)		; pop the LSB
	TAY				; which is new offset
	JMP execute		; and resume execution

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

; ** status register opcodes **

_0a:
; CLV (2)
; +5
	RMB1 ccr68	; clear V bit, *** Rockwell only! ***
	JMP next_op	; standard end of routine

_0b:
; SEV (2)
; +5
	SMB1 ccr68	; set V bit, *** Rockwell only! ***
	JMP next_op	; standard end of routine

_0c:
; CLC (2)
; +5
	RMB0 ccr68	; clear C bit, *** Rockwell only! ***
	JMP next_op	; standard end of routine

_0d:
; SEC (2)
; +5
	SMB0 ccr68	; set C bit, *** Rockwell only! ***
	JMP next_op	; standard end of routine

_0e:
; CLI (2)
; +5
	RMB4 ccr68	; clear I bit, *** Rockwell only! ***
	JMP next_op	; standard end of routine

_0f:
; SEI (2)
; +5
	SMB4 ccr68	; set I bit, *** Rockwell only! ***
	JMP next_op	; standard end of routine

_06:
; TAP (2)
; +6
	LDA a68		; get A accumulator...
	STA ccr68	; ...and store it in CCR
	JMP next_op	; standard end of routine

_07:
; TPA (2)
; +6
	LDA ccr68	; get CCR...
	STA a68		; ...and store it in A
	JMP next_op	; standard end of routine

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
