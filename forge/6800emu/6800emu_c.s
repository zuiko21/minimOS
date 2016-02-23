; 6800 emulator for minimOS! *** COMPACT VERSION ***
; v0.1a6 -- complete minus hardware interrupts!
; (c) 2016 Carlos J. Santisteban
; last modified 20160222

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
; increase Y checking injected boundary crossing (5/5/30) ** new compact version
#define	_PC_ADV		INY: BNE *+5: JSR wrap_pc
; compute pointer for indexed addressing mode (31/31.5/)
#define	_INDEXED	_PC_ADV: LDA (pc68), Y: CLC: ADC x68: STA tmptr: LDA x68+1: ADC #0: _AH_BOUND: STA tmptr+1
; compute pointer for extended addressing mode (31/31.5/)
#define	_EXTENDED	_PC_ADV: LDA (pc68), Y: _AH_BOUND: STA tmptr+1: _PC_ADV: LDA (pc68), Y: STA tmptr
; compute pointer (as A index) for direct addressing mode (10/10/)
#define	_DIRECT		_PC_ADV: LDA (pc68), Y

; check Z & N flags (6/8/10) will not set both bits at once!
#define _CC_NZ		BNE *+4: SMB2 ccr68: BPL *+4: SMB3 ccr68


; *** declare some constants ***
hi_mask	=	%10111111	; injects A15 hi into $8000-$BFFF, regardless of A14
lo_mask	=	%01000000	; injects A15 lo into $4000-$7FFF, regardless of A14
;lo_mask	=	%00100000	; injects into upper 8 K ($2000-$3FFF) for 16K RAM systems
e_base	=	$4000		; emulated space start ($2000 for 16K systems)
e_top	=	$C000		; top over emulated space (third 16K block in most systems)

; *** declare zeropage addresses ***
; ** 'uz' is first available zeropage address (currently $03 in minimOS) **
tmptr	=	uz		; temporary storage (up to 16 bit, little endian)
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
	LDX #6			; offset for reset
	BRA vector_pull	; generic startup!

; *** main loop ***
execute:
		LDA (pc68), Y	; get opcode (needs CMOS) (5)
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

; illegal opcodes will seem to trigger an interupt!
	_PC_ADV			; skip illegal opcode
nmi68:				; hardware interrupts, when available, to be checked AFTER incrementing PC
	LDX #4			; offset for NMI vector
intr68:				; ** generic interrupt entry point, offset in X **
	STX tmptr		; store offset for later
; save processor status
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
	LDX #1			; index for register area stacking (skip fake PC LSB)
	TYA				; actual PC LSB goes first!
	LDY #7			; index for stack area
	STA (sp68), Y	; push LSB first, then the loop
	DEY				; post-decrement
nmi_loop:
		LDA pc68, X			; get one byte from register area
		STA (sp68), Y		; store in free stack space
		INX					; increase original offset
		DEY					; stack grows backwards
		BNE nmi_loop		; zero is NOT included!!!
	LDX tmptr		; retrieve offset
vector_pull:		; ** standard vector pull entry point, offset in X **
	SMB4 ccr68		; mask interrupts! *** Rockwell ***
	LDY e_top-7, X	; get LSB from emulated vector
	LDA e_top-8, X	; get MSB...
	_AH_BOUND		; ...but inject it into emulated space
	STA pc68 + 1	; update PC
	BRA execute		; continue with NMI handler

; *** valid opcode definitions ***

; ** common routines **

; increment PC MSB in case of boundary crossing, rare (19/19.5/20)
wrap_pc:
	LDA pc68 + 1	; get MSB
	INC				; increment
	_AH_BOUND		; keep injected!
	STA pc68 + 1	; update pointer
	RTS				; *** only subroutine as of 160222 in rare cases, worth it ***

; ** common endings **

; update B and check N & Z bits (9/11/20)
b_nz:
	STA b68			; update accumulator B
	BRA check_nz	; check usual flags

; update A and check N & Z bits (6/8/17)
a_nz:
	STA a68			; update accumulator A

; just check N & Z, then exit (3/5/14)
check_nz:
	BPL cnz_pl		; if minus...
		SMB3 ccr68		; set N
cnz_pl:
	BNE next_op		; (check reach) if zero...
		SMB2 ccr68		; set Z
	BRA next_op		; (check reach) standard end

; update indirect pointer and check NZ (11/13/22)
ind_nz:
	STA (tmptr)		; store at pointed address
	BRA check_nz	; check flags and exit
	
; check V & C bits, then N & V (9/13/31)
check_flags:
	BVC cvc_cc		; if overflow...
		SMB1 ccr68		; set V
cvc_cc:
	BCS check_nz	; if carry...
		SMB0 ccr68		; set C
	BRA check_nz	; continue checking

; ** accumulator and memory **

; add to A
_8b:
; ADD A imm (2)
; +71/77.5/
	_PC_ADV			; not worth using the macro (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA addae		; continue as indirect addressing (3+)

_9b:
; ADD A dir (3)
; +75/81.5/
	_DIRECT			; point to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA addae		; continue as indirect addressing (3+)

_ab:
; ADD A ind (5)
; +89/96/
	_INDEXED		; point to operand 31/31.5
	BRA addae		; otherwise the same 3+

_bb:
; ADD A ext (4)
; +86/93/
	_EXTENDED		; point to operand (31/31.5)
addae:				; +55/61.5/ from here
	CLC				; this uses no carry (2)
	JMP adcae_cc	; otherwise the same as ADC (3+)

_89:
; ADC A imm (2)
;  +74/81/
	_PC_ADV			; not worth using the macro (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA adcae		; continue as indirect addressing (3+)

_99:
; ADC A dir (3)
; +78/85/
	_DIRECT			; point to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA adcae		; continue as indirect addressing (3+)

_a9:
; ADC A ind (5)
; +91/98.5/
	_INDEXED		; point to operand 31/31.5
	BRA adcae		; same 3+

_b9:
; ADC A ext (4)
; +88/95.5/
	_EXTENDED		; point to operand (31/31.5)
adcae:				; +57/64/ from here
	CLC				; prepare (2)
	BBR0 ccr68, adcae_cc	; no previous carry (6/6.5...)
		SEC						; otherwise preset C
adcae_cc:			; +49/55.5/  from here
	LDA a68			; get accumulator A (3)
	BIT #%00010000	; check bit 4 (2)
	BEQ adcae_nh	; do not set H if clear (8/9...)
		SMB5 ccr68		; set H temporarily as b4
		BRA adcae_sh	; do not clear it
adcae_nh:
	RMB5 ccr68		; otherwise H is clear
adcae_sh:
	ADC (tmptr)		; add operand (5)
adda:				; +31/36.5/ from here
	TAX				; store for later! (2)
	BIT #%00010000	; check bit 4 again (2)
	BNE adcae_nh2	; do not invert H (8/10...)
		LDA ccr68		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		BRA adcae_sh2	; do not reload CCR
adcae_nh2:
	LDA ccr68		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
adcae_sh2:
	BCC adcae_nc	; only if carry... (3/3.5...)
		INC				; ...set C flag
adcae_nc:
	BVC adcae_nv	; only if overflow... (3/3.5...)
		ORA #%00000010	; ...set V flag
adcae_nv:
	STA ccr68		; update flags (3)
	TXA				; retrieve value! (2)
	JMP a_nz		; update A and check NZ (3+)

; add accumulators
_1b:
; ABA (2)
; + 52/58.5/
	LDA a68			; get accumulator A (3)
	BIT #%00010000	; check bit 4 (2)
	BEQ aba_nh		; do not set H if clear (8/9...)
		SMB5 ccr68		; set H temporarily as b4
		BRA aba_sh		; do not clear it
aba_nh:
	RMB5 ccr68		; otherwise H is clear
aba_sh:
	CLC				; prepare (2)
	ADC b68			; add second accumulator (3)
	BRA adda		; continue adding to A (3+)

; add to B
_cb:
; ADD B imm (2)
; +76/81.5/
	_PC_ADV			; not worth using the macro (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA addbe		; continue as indirect addressing (3+)

_db:
; ADD B dir (3)
; +80/85.5/
	_DIRECT			; point to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA addbe		; continue as indirect addressing (3+)

_eb:
; ADD B ind (5)
; +93/99/
	_INDEXED		; point to operand (31/31.5)
	BRA addbe		; the same (3+)

_fb:
; ADD B ext (4)
; +90/96/
	_EXTENDED		; point to operand (31/31.5)
addbe:				; +59/64.5/ from here
	CLC				; this takes no carry (2)
	JMP adcbe_cc	; otherwise the same as ADC! (3+)

_c9:
; ADC B imm (2)
;  +79/85/
	_PC_ADV			; not worth using the macro (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA adcbe		; continue as indirect addressing (3+)

_d9:
; ADC B dir (3)
; +83/89/
	_DIRECT			; point to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA adcbe		; continue as indirect addressing (3+)

_e9:
; ADC B ind (5)
; +96/102.5/
	_INDEXED		; point to operand (31/31.5)
	BRA adcbe		; same (3+)

_f9:
; ADC B ext (4)
; +93/99.5/
	_EXTENDED		; point to operand (31/31.5)
adcbe:				; +62/68/ from here
	CLC				; prepare (2)
	BBR0 ccr68, adcbe_cc	; no previous carry (6/6.5...)
		SEC						; otherwise preset C
adcbe_cc:			; +54/59.5/ from here
	LDA b68			; get accumulator B (3)
	BIT #%00010000	; check bit 4 (2)
	BEQ adcbe_nh	; do not set H if clear (8/9...)
		SMB5 ccr68		; set H temporarily as b4
		BRA adcbe_sh	; do not clear it
adcbe_nh:
	RMB5 ccr68		; otherwise H is clear
adcbe_sh:
	ADC (tmptr)		; add operand (5)
	TAX				; store for later! (2)
	BIT #%00010000	; check bit 4 again (2)
	BNE adcbe_nh2	; do not invert H (8/10...)
		LDA ccr68		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		BRA adcbe_sh2	; do not reload CCR
adcbe_nh2:
	LDA ccr68		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
adcbe_sh2:
	BCC adcbe_nc	; only if carry... (3/3.5...)
		INC				; ...set C flag
adcbe_nc:
	BVC adcbe_nv	; only if overflow... (3/3.5...)
		ORA #%00000010	; ...set V flag
adcbe_nv:
	STA ccr68		; update flags (3)
	TXA				; retrieve value! (2)
	JMP b_nz		; update B and check NZ (3+)

; logical AND
_84:
; AND A imm (2)
; +42/44/
	_PC_ADV			; go for operand
	STY tmptr		; store LSB of pointer
	LDA pc68 + 1	; get address MSB
	STA tmptr + 1	; pointer is ready
	BRA andae		; continue as indirect addressing

_94:
; AND A dir (3)
; +46/48/
	_DIRECT			; points to operand
	STA tmptr		; store LSB of pointer
	LDA #>e_base	; emulated MSB
	STA tmptr+1		; pointer is ready
	BRA andae		; continue as indirect addressing

_a4:
; AND A ind (5)
; +59/61.5/
	_INDEXED		; points to operand
	BRA andae		; same

_b4:
; AND A ext (4)
; +56/58.5/
	_EXTENDED		; points to operand
andae:				; +25/27/36 from here
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA a68			; get A accumulator
	AND (tmptr)		; AND with operand
	JMP a_nz		; update A and check NZ

_c4:
; AND B imm (2)
; +45/47/
	_PC_ADV			; go for operand
	STY tmptr		; store LSB of pointer
	LDA pc68 + 1	; get address MSB
	STA tmptr + 1	; pointer is ready
	BRA andbe		; continue as indirect addressing

_d4:
; AND B dir (3)
; +49/51/
	_DIRECT			; points to operand
	STA tmptr		; store LSB of pointer
	LDA #>e_base	; emulated MSB
	STA tmptr+1		; pointer is ready
	BRA andbe		; continue as indirect addressing

_e4:
; AND B ind (5)
; +62/64.5/
	_INDEXED		; points to operand
	BRA andbe		; same

_f4:
; AND B ext (4)
; +59/61.5/
	_EXTENDED		; points to operand
andbe:				; +28/30/39 from here
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA b68			; get B accumulator
	AND (tmptr)		; AND with operand
	JMP b_nz		; update B and check NZ

; AND without modifying register
_85:
; BIT A imm (2)
; +39/41/
	_PC_ADV			; go for operand
	STY tmptr		; store LSB of pointer
	LDA pc68 + 1	; get address MSB
	STA tmptr + 1	; pointer is ready
	BRA bitae		; continue as indirect addressing

_95:
; BIT A dir (3)
; +43/45/
	_DIRECT			; points to operand
	STA tmptr		; store LSB of pointer
	LDA #>e_base	; emulated MSB
	STA tmptr+1		; pointer is ready
	BRA bitae		; continue as indirect addressing

_a5:
; BIT A ind (5)
; +56/58.5/
	_INDEXED		; points to operand
	BRA bitae		; same

_b5:
; BIT A ext (4)
; +53/55.5/
	_EXTENDED		; points to operand
bitae:				; +22/24/33 from here
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA a68			; get A accumulator
	AND (tmptr)		; AND with operand, just for flags
	JMP check_nz	; check flags and end

_c5:
; BIT B imm (2)
; +39/41/
	_PC_ADV			; go for operand
	STY tmptr		; store LSB of pointer
	LDA pc68 + 1	; get address MSB
	STA tmptr + 1	; pointer is ready
	BRA bitbe		; continue as indirect addressing

_d5:
; BIT B dir (3)
; +43/45/
	_DIRECT			; points to operand
	STA tmptr		; store LSB of pointer
	LDA #>e_base	; emulated MSB
	STA tmptr+1		; pointer is ready
	BRA bitbe		; continue as indirect addressing

_e5:
; BIT B ind (5)
; +56/58.5/
	_INDEXED		; points to operand
	BRA bitbe		; same

_f5:
; BIT B ext (4)
; +53/55.5/
	_EXTENDED		; points to operand
bitbe:				; +22/24/33 from here
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA b68			; get B accumulator
	AND (tmptr)		; AND with operand, just for flags
	JMP check_nz	; check flags and end

; clear
_4f:
; CLR A (2)
; +13
	STZ a68		; clear A
clra:
	LDA ccr68	; get previous status
	AND #%11110100	; clear N, V, C
	ORA #%00000100	; set Z
	STA ccr68	; update
	JMP next_op	; standard end of routine

_5f:
; CLR B (2)
; +16
	STZ b68		; clear B
	BRA clra	; same

_6f:
; CLR ind (7)
; +57/57.5/
	_INDEXED		; prepare pointer
	BRA clre		; same code

_7f:
; CLR ext (6)
; +54/54.5/
	_EXTENDED		; prepare pointer
clre:
	LDA #0			; no indirect STZ available
	STA (tmptr)		; clear memory
	BRA clra		; same

; compare
_81:
; CMP A imm (2)
; +47/51/
	_PC_ADV			; get operand
	STY tmptr		; store LSB of pointer
	LDA pc68 + 1	; get address MSB
	STA tmptr + 1	; pointer is ready
	BRA cmpae		; continue as indirect addressing

_91:
; CMP A dir (3)
; +51/55/
	_DIRECT			; get operand
	STA tmptr		; store LSB of pointer
	LDA #>e_base	; emulated MSB
	STA tmptr+1		; pointer is ready
	BRA cmpae		; continue as indirect addressing

_a1:
; CMP A ind (5)
; +64/68.5/
	_INDEXED		; get operand
	BRA cmpae		; same

_b1:
; CMP A ext (4)
; +61/65.5/
	_EXTENDED		; get operand
cmpae:				; +30/34/52 from here
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	LDA a68			; get accumulator A
	SEC				; prepare
	SBC (tmptr)		; subtract without carry
	JMP check_flags	; check NZVC and exit

_c1:
; CMP B imm (2)
; +47/51/
	_PC_ADV			; get operand
	STY tmptr		; store LSB of pointer
	LDA pc68 + 1	; get address MSB
	STA tmptr + 1	; pointer is ready
	BRA cmpbe		; continue as indirect addressing

_d1:
; CMP B dir (3)
; +51/55/
	_DIRECT			; get operand
	STA tmptr		; store LSB of pointer
	LDA #>e_base	; emulated MSB
	STA tmptr+1		; pointer is ready
	BRA cmpbe		; continue as indirect addressing

_e1:
; CMP B ind (5)
; +64/68.5/
	_INDEXED		; get operand
	BRA cmpbe		; same

_f1:
; CMP B ext (4)
; +61/65.5/
	_EXTENDED		; get operand
cmpbe:				; +30/34/52 from here
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	LDA b68			; get accumulator B
	SEC				; prepare
	SBC (tmptr)		; subtract without carry
	JMP check_flags	; check NZVC and exit

; compare accumulators
_11:
; CBA (2)
; +28/32/50
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	LDA a68			; get accumulator A
	SEC				; prepare
	SBC b68			; subtract B without carry
	JMP check_flags	; check NZVC and exit

; 1's complement
_43:
; COM A (2)
; +24/26/35
	LDA ccr68		; get original flags
	AND #%11110000	; reset relevant bits
	INC				; C always set
	STA ccr68		; update status
	LDA a68			; get A
	EOR #$FF		; complement it
	JMP a_nz		; update A, check NZ and exit

_53:
; COM B (2)
; +27/29/38
	LDA ccr68		; get original flags
	AND #%11110000	; reset relevant bits
	INC				; C always set
	STA ccr68		; update status
	LDA b68			; get B
	EOR #$FF		; complement it
	JMP b_nz		; update B, check NZ and exit

_63:
; COM ind (7)
; +65/67.5/
	_INDEXED		; compute pointer
	BRA come		; same

_73:
; COM ext (6)
; +62/64.5/
	_EXTENDED		; addressing mode
come:				; +31/33/42 from here
	LDA ccr68		; get original flags
	AND #%11110000	; reset relevant bits
	INC				; C always set
	STA ccr68		; update status
	LDA (tmptr)		; get memory
	EOR #$FF		; complement it
	JMP ind_nz		; store, check flags and exit

; 2's complement
_40:
; NEG A (2)
; +18/24/37
	LDA ccr68		; get original flags
	AND #%11110000	; reset relevant bits
	STA ccr68		; update status
	SEC				; prepare subtraction
	LDA #0
	SBC a68			; negate A
	STA a68			; update value
nega:				; +// from here
	BNE nega_nc		; carry only if zero
		SMB0 ccr68		; set C flag
nega_nc:
	TAX				; keep for later!
	CMP #$80		; will overflow?
	BNE nega_nv		; skip if not V
		SMB1 ccr68		; set V flag
nega_nv:
	TXA				; retrieve
	JMP check_nz	; finish

_50:
; NEG B (2)
; +21/27/40
	LDA ccr68		; get original flags
	AND #%11110000	; reset relevant bits
	STA ccr68		; update status
	SEC				; prepare subtraction
	LDA #0
	SBC b68			; negate B
	STA b68			; update value
	BRA nega		; check flags

_60:
; NEG ind (7)
; +77/83.5/
	_INDEXED		; compute pointer
	BRA nege		; same

_70:
; NEG ext (6)
; +74/80.5/
	_EXTENDED		; addressing mode
nege:				; +43/49/62 from here
	LDA ccr68		; get original flags
	AND #%11110000	; reset relevant bits
	STA ccr68		; update status
	SEC				; prepare subtraction
	LDA #0
	SBC (tmptr)		; negate memory
	STA (tmptr)		; update value
	BRA nega		; continue

; decimal adjust
_19:
; DAA (2)
; +20/~400/1841?
; ** first approach, awfully slow!!! **
	LDA ccr68		; get original status
	AND #%11110001	; reset all relevant bits for CCR, do NOT reset C!
	STA ccr68		; store new flags
	LDX a68			; get binary number to be converted
		BEQ daa_ok		; nothing to convert
	CPX #100		; will it overflow?
	BCC daa_conv	; range OK
		SMB0 ccr68		; otherwise set C
daa_conv:
	CLC				; prepare
	LDA #0			; will compute final value
	SED				; set decimal mode!!! (...28 worst)
daa_loop:
		ADC #1			; decimal increase
		DEX				; decrement counter
		BNE daa_loop	; until done (7x255+6 = 1791)
	CLD				; back to binary mode!!!
	BVC daa_nv		; only if overflow...
		SMB1 ccr68		; ...set V flag
daa_nv:
	STA a68			; update accumulator with BCD value
daa_ok:
	JMP check_flags	; check and exit

; decrement
_4a:
; DEC A (2)
; +29/33/44
	LDA ccr68		; get original status
	AND #%11110001	; reset all relevant bits for CCR
	STA ccr68		; store new flags
	DEC a68			; decrease A
	LDX a68			; check it!
deca:				; +13/17/28 from here
	CPX #$7F		; did change sign?
	BNE deca_nv		; skip if not overflow
		SMB1 ccr68		; will set V flag
deca_nv:
	TXA				; retrieve!
	JMP check_nz	; end

_5a:
; DEC B (2)
; +33/36/47
	LDA ccr68		; get original status
	AND #%11110001	; reset all relevant bits for CCR
	STA ccr68		; store new flags
	DEC b68			; decrease B
	LDX b68			; check it!
	BRA deca		; continue

_6a:
; DEC ind (7)
; +
	_INDEXED		; addressing mode
	BRA dece		; same

_7a:
; DEC ext (6)
; +
	_EXTENDED		; addressing mode
dece:
	LDA ccr68		; get original status
	AND #%11110001	; reset all relevant bits for CCR
	STA ccr68		; store new flags
	LDA (tmptr)		; no DEC (tmptr) available...
	DEC
	STA (tmptr)
	TAX				; store for later
	BRA deca		; continue

; exclusive OR
_88:
; EOR A imm (2)
; +
	_PC_ADV			; go for operand
	STY tmptr		; store LSB of pointer
	LDA pc68 + 1	; get address MSB
	STA tmptr + 1	; pointer is ready
	BRA eorae		; continue as indirect addressing

_98:
; EOR A dir (3)
; +
	_DIRECT			; Points to operand
	STA tmptr		; store LSB of pointer
	LDA #>e_base	; emulated MSB
	STA tmptr+1		; pointer is ready
	BRA eorae		; continue as indirect addressing

_a8:
; EOR A ind (5)
; +
	_INDEXED		; points to operand
	BRA eorae		; same

_b8:
; EOR A ext (4)
; +
	_EXTENDED		; points to operand
eorae:
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA a68			; get A accumulator
	EOR (tmptr)		; EOR with operand
	JMP a_nz		; update A, check NZ and exit

_c8:
; EOR B imm (2)
; +
	_PC_ADV			; go for operand
	STY tmptr		; store LSB of pointer
	LDA pc68 + 1	; get address MSB
	STA tmptr + 1	; pointer is ready
	BRA eorbe		; continue as indirect addressing

_d8:
; EOR B dir (3)
; +
	_DIRECT			; points to operand
	STA tmptr		; store LSB of pointer
	LDA #>e_base	; emulated MSB
	STA tmptr+1		; pointer is ready
	BRA eorbe		; continue as indirect addressing

_e8:
; EOR B ind (5)
; +
	_INDEXED		; points to operand
	BRA eorbe		; same

_f8:
; EOR B ext (4)
; +
	_EXTENDED		; points to operand
eorbe:
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA b68			; get B accumulator
	EOR (tmptr)		; EOR with operand
	JMP b_nz		; update B, check NZ and exit

; increment
_4c:
; INC A (2)
; +
	LDA ccr68		; get original status
	AND #%11110001	; reset all relevant bits for CCR 
	STA ccr68		; store new flags
	INC a68			; increase A
	LDX a68			; check it!
inca:
	CPX #$80		; did change sign?
	BNE inca_nv		; skip if not overflow
		SMB1 ccr68		; will set V flag
inca_nv:
	TXA				; retrieve!
	JMP check_nz	; end

_5c:
; INC B (2)
; +
	LDA ccr68		; get original status
	AND #%11110001	; reset all relevant bits for CCR 
	STA ccr68		; store new flags
	INC b68			; increase B
	LDX b68			; check it!
	BRA inca		; continue

_6c:
; INC ind (7)
; +
	_INDEXED		; addressing mode
	BRA ince		; same

_7c:
; INC ext (6)
; +
	_EXTENDED		; addressing mode
ince:
	LDA ccr68		; get original status
	AND #%11110001	; reset all relevant bits for CCR 
	STA ccr68		; store new flags
	LDA (tmptr)		; no INC (tmptr) available...
	INC
	STA (tmptr)
	TAX				; store for later
	BRA inca		; continue

; load accumulator
_86:
; LDA A imm (2)
; +
	_PC_ADV			; go for operand
	STY tmptr		; store LSB of pointer
	LDA pc68 + 1	; get address MSB
	STA tmptr + 1	; pointer is ready
	BRA ldaae		; continue as indirect addressing

_96:
; LDA A dir (3) *** access to $00 is redirected to minimOS standard input ***
; +
	_DIRECT				; X points to operand
; ** trap address in case it goes to host console **
	BEQ ldaad_trap		; ** intercept input!
; ** continue execution otherwise **
		STA tmptr		; store LSB of pointer
		LDA #>e_base	; emulated MSB
		STA tmptr+1		; pointer is ready
		BRA ldaae		; continue as indirect addressing
; *** trap input, minimOS specific ***
ldaad_trap:
	LDY #0			; *** minimOS standard device, TBD ***
	_KERNEL(CIN)	; standard input, non locking
	BCC ldaad_ok	; there was something available
		LDA #0			; otherwise, NUL means no char was available
		BRA ldaad_ret	; continue
ldaad_ok:
	LDA zpar		; get received character
ldaad_ret:
	JMP a_nz		; update A, check NZ and exit

_a6:
; LDA A ind (5)
; +
	_INDEXED		; points to operand
	BRA ldaae		; same

_b6:
; LDA A ext (4)
; +
	_EXTENDED		; points to operand
ldaae:
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA (tmptr)		; get operand
	JMP a_nz		; update A, check NZ and exit

_c6:
; LDA B imm (2)
; +
	_PC_ADV			; go for operand
	STY tmptr		; store LSB of pointer
	LDA pc68 + 1	; get address MSB
	STA tmptr + 1	; pointer is ready
	BRA ldabe		; continue as indirect addressing

_d6:
; LDA B dir (3) *** access to $00 is redirected to minimOS standard input ***
; +
	_DIRECT				; A points to operand
; ** trap address in case it goes to host console **
	BEQ ldabd_trap		; ** intercept input!
; ** continue execution otherwise **
		STA tmptr		; store LSB of pointer
		LDA #>e_base	; emulated MSB
		STA tmptr+1		; pointer is ready
		BRA ldabe		; continue as indirect addressing
; *** trap input, minimOS specific ***
ldabd_trap:
	LDY #0			; *** minimOS standard device, TBD ***
	_KERNEL(CIN)	; standard input, non locking
	BCC ldabd_ok	; there was something available
		LDA #0			; otherwise, NUL means no char was available
		BRA ldabd_ret	; continue
ldabd_ok:
	LDA zpar		; get received character, it was slow anyway
ldabd_ret:
	JMP b_nz		; update B, check NZ and exit

_e6:
; LDA B ind (5)
; +
	_INDEXED		; points to operand
	BRA ldabe		; same

_f6:
; LDA B ext (4)
; +
	_EXTENDED		; points to operand
ldabe:
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA (tmptr)		; get operand
	JMP b_nz		; update B, check NZ and exit

; inclusive OR
_8a:
; ORA A imm (2)
; +
	_PC_ADV			; go for operand
	STY tmptr		; store LSB of pointer
	LDA pc68 + 1	; get address MSB
	STA tmptr + 1	; pointer is ready
	BRA oraae		; continue as indirect addressing

_9a:
; ORA A dir (3)
; +
	_DIRECT			; points to operand
	STA tmptr		; store LSB of pointer
	LDA #>e_base	; emulated MSB
	STA tmptr+1		; pointer is ready
	BRA oraae		; continue as indirect addressing

_aa:
; ORA A ind (5)
; +
	_INDEXED		; points to operand
	BRA oraae		; same

_ba:
; ORA A ext (4)
; +
	_EXTENDED		; points to operand
oraae:
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA a68			; get A accumulator
	ORA (tmptr)		; ORA with operand
	JMP a_nz		; update A, check NZ and exit

_ca:
; ORA B imm (2)
; +
	_PC_ADV			; go for operand
	STY tmptr		; store LSB of pointer
	LDA pc68 + 1	; get address MSB
	STA tmptr + 1	; pointer is ready
	BRA orabe		; continue as indirect addressing

_da:
; ORA B dir (3)
; +
	_DIRECT			; points to operand
	STA tmptr		; store LSB of pointer
	LDA #>e_base	; emulated MSB
	STA tmptr+1		; pointer is ready
	BRA orabe		; continue as indirect addressing

_ea:
; ORA B ind (5)
; +
	_INDEXED		; points to operand
	BRA orabe		; same

_fa:
; ORA B ext (4)
; +
	_EXTENDED		; points to operand
orabe:
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA b68			; get B accumulator
	ORA (tmptr)		; ORA with operand
	JMP b_nz		; update B, check NZ and exit

; push accumulator
_36:
; PSH A (4)
; +
	LDA a68			; get accumulator A
psha:
	STA (sp68)		; put it on stack space
	LDX sp68		; check LSB
	BNE psha_nw		; will not wrap
		LDA sp68+1		; get MSB
		DEC				; decrease it
		_AH_BOUND		; and inject it
		STA sp68+1		; worst update
psha_nw:
	DEC sp68		; post-decrement
	JMP next_op		; all done

_37:
; PSH B (4)
; +
	LDA b68			; get accumulator B
	BRA psha		; same

; pull accumulator
_32:
; PUL A (4)
; +
	INC sp68		; pre-increment
	BNE pula_nw		; should not correct MSB
		LDA sp68 + 1	; get stack pointer MSB
		INC				; increase MSB
		_AH_BOUND		; keep injected
		STA sp68 + 1	; update real thing
pula_nw:
	LDA (sp68)		; take value from stack
	STA a68			; store it in accumulator A
	JMP next_op		; standard end of routine

_33:
; PUL B (4)
; +
	INC sp68		; pre-increment
	BNE pulb_nw		; should not correct MSB
		LDA sp68 + 1	; get stack pointer MSB
		INC				; increase MSB
		_AH_BOUND		; keep injected
		STA sp68 + 1	; update real thing
pulb_nw:
	LDA (sp68)		; take value from stack
	STA b68			; store it in accumulator B
	JMP next_op		; standard end of routine

; rotate left
_49:
; ROL A (2)
; +
	CLC				; prepare
	BBR0 ccr68, rola_do	; skip if C clear
		SEC					; otherwise, set carry
rola_do:
	ROL a68			; rotate A left
	LDX a68			; keep for later
rots:				; *** common rotation ending, with value in X ***
	LDA ccr68		; get flags again
	AND #%11110000	; reset relevant bits
	CPX #0			; watch computed value!
	BNE rola_nz		; skip if not zero
		ORA #%00000100	; set Z flag
		CPX #0			; retrieve again, much faster!
rola_nz:
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
; +
	CLC				; prepare
	BBR0 ccr68, rolb_do	; skip if C clear
		SEC					; otherwise, set carry
rolb_do:
	ROL b68			; rotate B left
	LDX b68			; keep for later
	BRA rots		; same code!

_79:
; ROL ext (6)
; +
	_EXTENDED		; addressing mode
role:
	CLC				; prepare
	BBR0 ccr68, role_do	; skip if C clear
		SEC					; otherwise, set carry
role_do:
	LDA (tmptr)		; get memory
	ROL				; rotate left
	STA (tmptr)		; modify
	TAX				; keep for later
	BRA rots		; continue

_69:
; ROL ind (7)
; +
	_INDEXED		; addressing mode
	BRA role		; same

; rotate right
_46:
; ROR A (2)
; +
	CLC				; prepare
	BBR0 ccr68, rora_do	; skip if C clear
		SEC					; otherwise, set carry
rora_do:
	ROR a68			; rotate A right
	LDX a68			; keep for later
	JMP rots		; common end!

_56:
; ROR B (2)
; +
	CLC				; prepare
	BBR0 ccr68, rorb_do	; skip if C clear
		SEC					; otherwise, set carry
rorb_do:
	ROR b68			; rotate B right
	LDX b68			; keep for later
	JMP rots		; common end!

_66:
; ROR ind (7)
; +
	_INDEXED		; addressing mode
	BRA rore		; same

_76:
; ROR ext (6)
; +
	_EXTENDED		; addressing mode
rore:
	CLC				; prepare
	BBR0 ccr68, rore_do	; skip if C clear
		SEC					; otherwise, set carry
rore_do:
	LDA (tmptr)		; get memory
	ROR				; rotate right
	STA (tmptr)		; modify
	TAX				; keep for later
	JMP rots		; common end!

; arithmetic shift left
_48:
; ASL A (2)
; +
	ASL a68			; shift A left
	LDX a68			; retrieve again!
	JMP rots		; common end

_58:
; ASL B (2)
; +
	ASL b68			; shift B left
	LDX b68			; retrieve again!
	JMP rots		; common end

_68:
; ASL ind (7)
; +
	_INDEXED		; prepare pointer
	BRA asle		; same

_78:
; ASL ext (6)
; +
	_EXTENDED		; prepare pointer
asle:
	LDA (tmptr)		; get operand
	ASL				; shift left
	STA (tmptr)		; update memory
	TAX				; save for later!
	JMP rots		; common end!

; arithmetic shift right
_47:
; ASR A (2)
; +
	CLC				; prepare
	BIT a68			; check bit 7
	BPL asra_do		; do not insert C if clear
		SEC				; otherwise, set carry
asra_do:
	ROR a68			; emulate arithmetic shift left with preloaded-C rotation
	TAX				; store for later
	JMP rots		; common end!

_57:
; ASR B (2)
; +
	CLC				; prepare
	BIT b68			; check bit 7
	BPL asrb_do		; do not insert C if clear
		SEC				; otherwise, set carry
asrb_do:
	ROR b68			; emulate arithmetic shift left with preloaded-C rotation
	TAX				; store for later
	JMP rots		; common end!

_67:
; ASR ind (7)
; +
	_INDEXED		; get pointer to operand
	BRA asre		; same

_77:
; ASR ext (6)
; +
	_EXTENDED		; get pointer to operand
asre:
	CLC				; prepare
	LDA (tmptr)		; check operand
	BPL asre_do		; do not insert C if clear
		SEC				; otherwise, set carry
asre_do:
	ROR 			; emulate arithmetic shift left with preloaded-C rotation
	STA (tmptr)		; update memory
	TAX				; store for later!
	JMP rots		; common end!

; logical shift right
_44:
; LSR A (2)
; +
	LDA ccr68		; get original flags
	AND #%11110000	; reset relevant bits (N always reset)
	LSR a68			; shift A right
lshift:				; *** common ending for logical shifts ***
	BNE lsra_nz		; skip if not zero
		ORA #%00000100	; set Z flag
lsra_nz:
	BCC lsra_nc		; skip if there was no carry
		ORA #%00000011	; will set C and V flags, seems OK
lsra_nc:
	STA ccr68		; update status
	JMP next_op		; standard end of routine

_54:
; LSR B (2)
; +
	LDA ccr68		; get original flags
	AND #%11110000	; reset relevant bits (N always reset)
	LSR b68			; shift B right
	BRA lshift		; common end!

_64:
; LSR ind (7)
; +
	_INDEXED		; addressing mode
	BRA lsre		; same

_74:
; LSR ext (6)
; +
	_EXTENDED		; addressing mode
lsre:
	LDA (tmptr)		; get operand
	LSR
	STA (tmptr)		; modify operand
	TAX				; store for later, worth it
	LDA ccr68		; get original flags
	AND #%11110000	; reset relevant bits (N always reset)
	CPX #0			; retrieve value
	BRA lshift		; common end!

; store accumulator [[[[continue from here]]]]]]
_97:
; STA A dir (4) *** access to $00 is redirected to minimOS standard output ***
; +
	_DIRECT				; A points to operand
; ** trap address in case it goes to host console **
	BEQ staad_trap		; ** intercept input!
; ** continue execution otherwise **
		STA tmptr		; store LSB of pointer
		LDA #>e_base	; emulated MSB
		STA tmptr+1		; pointer is ready
		BRA staae		; continue as indirect addressing
; *** trap output, minimOS specific ***
staad_trap:
	LDY #0			; *** minimOS standard device, TBD ***
	LDA a68			; get char in A
	STA zpar		; parameter for COUT
	_KERNEL(COUT)	; standard output
	LDA a68			; just for flags
	JMP check_nz	; usual ending

_a7:
; STA A ind (6)
; +
	_INDEXED		; points to operand
	BRA staae		; same

_b7:
; STA A ext (5)
; +53/55.5/
	_EXTENDED		; points to operand
staae:
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA a68			; get A accumulator
	JMP ind_nz		; store, check NZ and exit

_d7:
; STA B dir (4) *** access to $00 is redirected to minimOS standard output ***
; +
	_DIRECT				; A points to operand
; ** trap address in case it goes to host console **
	BEQ stabd_trap		; ** intercept input!
; ** continue execution otherwise **
		STA tmptr		; store LSB of pointer
		LDA #>e_base	; emulated MSB
		STA tmptr+1		; pointer is ready
		BRA stabe		; continue as indirect addressing
; *** trap output, minimOS specific ***
stabd_trap:
	LDY #0			; *** minimOS standard device, TBD ***
	LDA b68			; get char in B
	STA zpar		; parameter for COUT
	_KERNEL(COUT)	; standard output
	LDA b68			; just for flags
	JMP check_nz	; ended

_e7:
; STA B ind (6)
; +
	_INDEXED		; points to operand
	BRA stabe		; same

_f7:
; STA B ext (5)
; +53/55.5/
	_EXTENDED		; points to operand
stabe:
	LDA ccr68		; get flags
	AND #%11110001	; clear relevant bits
	STA ccr68		; update
	LDA b68			; get B accumulator
	JMP ind_nz		; store, check NZ and exit

; subtract without carry
_80:
; SUB A imm (2)
; +
	_PC_ADV			; get operand
	STY tmptr		; store LSB of pointer
	LDA pc68 + 1	; get address MSB
	STA tmptr + 1	; pointer is ready
	BRA subae		; continue as indirect addressing

_90:
; SUB A dir (3)
; +
	_DIRECT			; get operand
	STA tmptr		; store LSB of pointer
	LDA #>e_base	; emulated MSB
	STA tmptr+1		; pointer is ready
	BRA subae		; continue as indirect addressing

_a0:
; SUB A ind (5)
; +
	_INDEXED		; get operand
	BRA subae		; same

_b0:
; SUB A ext (4)
; +67/73.5/
	_EXTENDED		; get operand
subae:
	SEC				; prepare
	JMP sbcae_do	; and continue

_c0:
; SUB B imm (2)
; +
	_PC_ADV			; get operand
	STY tmptr		; store LSB of pointer
	LDA pc68 + 1	; get address MSB
	STA tmptr + 1	; pointer is ready
	BRA subbe		; continue as indirect addressing

_d0:
; SUB B dir (3)
; +
	_DIRECT			; get operand
	STA tmptr		; store LSB of pointer
	LDA #>e_base	; emulated MSB
	STA tmptr+1		; pointer is ready
	BRA subbe		; continue as indirect addressing

_e0:
; SUB B ind (5)
; +
	_INDEXED		; get operand
	BRA subbe		; same

_f0:
; SUB B ext (4)
; +67/73.5/			; get operand
subbe:
	SEC				; prepare
	JMP sbcbe_do	; and continue

; subtract accumulators
_10:
; SBA (2)
; +31/37/43
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	LDA a68			; get accumulator A
	SEC				; prepare
	SBC b68			; subtract B without carry
	STA a68			; update accumulator A
	JMP check_flags	; and exit

; subtract with carry
_82:
; SBC A imm (2)
; +
	_PC_ADV			; get operand
	STY tmptr		; store LSB of pointer
	LDA pc68 + 1	; get address MSB
	STA tmptr + 1	; pointer is ready
	BRA sbcae		; continue as indirect addressing

_92:
; SBC A dir (3)
; +
	_DIRECT			; get operand
	STA tmptr		; store LSB of pointer
	LDA #>e_base	; emulated MSB
	STA tmptr+1		; pointer is ready
	BRA sbcae		; continue as indirect addressing

_a2:
; SBC A ind (5)
; +
	_INDEXED		; get operand
	BRA sbcae		; same

_b2:
; SBC A ext (4)
; +70/77/
	_EXTENDED		; get operand
sbcae:
	SEC				; prepare
	BBR0 ccr68, sbcae_do	; skip if C clear ** Rockwell **
		CLC				; otherwise, set carry, opposite of 6502
sbcae_do:
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	LDA a68			; get accumulator A
	SBC (tmptr)		; subtract with carry
	STA a68			; update accumulator
	JMP check_flags	; and exit

_c2:
; SBC B imm (2)
; +
	_PC_ADV			; get operand
	STY tmptr		; store LSB of pointer
	LDA pc68 + 1	; get address MSB
	STA tmptr + 1	; pointer is ready
	BRA sbcbe		; continue as indirect addressing

_d2:
; SBC B dir (3)
; +
	_DIRECT			; get operand
	STA tmptr		; store LSB of pointer
	LDA #>e_base	; emulated MSB
	STA tmptr+1		; pointer is ready
	BRA sbcbe		; continue as indirect addressing

_e2:
; SBC B ind (5)
; +
	_INDEXED		; get operand
	BRA sbcbe		; same

_f2:
; SBC B ext (4)
; +70/77/
	_EXTENDED		; get operand
sbcbe:
	SEC				; prepare
	BBR0 ccr68, sbcbe_do	; skip if C clear ** Rockwell **
		CLC				; otherwise, set carry, opposite of 6502
sbcbe_do:
	LDA ccr68		; get flags
	AND #%11110000	; clear relevant bits
	STA ccr68		; update
	LDA b68			; get accumulator B
	SBC (tmptr)		; subtract with carry
	STA b68			; update accumulator
	JMP check_flags	; and exit

; transfer accumulator
_16:
; TAB (2)
; +20/22/24
	LDA ccr68	; get original flags
	AND #%11110001	; reset N,Z, and always V
	STA ccr68	; update status
	LDA a68		; get A
	JMP b_nz	; update B, check NZ and exit

_17:
; TBA (2)
; +20/22/24
	LDA ccr68	; get original flags
	AND #%11110001	; reset N,Z, and always V
	STA ccr68	; update status
	LDA b68		; get B
	JMP a_nz	; update A, check NZ and exit

; test for zero or minus
_4d:
; TST A (2)
; +17/19/21
	LDA ccr68	; get original flags
	AND #%11110000	; reset relevant bits
	STA ccr68	; update status
	LDA a68		; check accumulator A
	JMP check_nz

_5d:
; TST B (2)
; +17/19/21
	LDA ccr68	; get original flags
	AND #%11110000	; reset relevant bits
	STA ccr68	; update status
	LDA b68		; check accumulator B
	JMP check_nz

_6d:
; TST ind (7)
; +
	_INDEXED		; set pointer
	BRA tste		; same

_7d:
; TST ext (6)
; +50/52.5/
	_EXTENDED		; set pointer
tste:
	LDA ccr68		; get original flags
	AND #%11110000	; reset relevant bits
	STA ccr68		; update status
	LDA (tmptr)		; check operand
	JMP check_nz

; ** index register and stack pointer ops **

; compare index
_8c:
; CPX imm (3)
; +
	_PC_ADV			; get first operand
	STY tmptr		; store LSB of pointer
	LDA pc68 + 1	; get address MSB
	STA tmptr + 1	; pointer is ready
	BRA cpxe		; continue as indirect addressing

_9c:
; CPX dir (4)
; +
	_DIRECT			; get operand
	STA tmptr		; store LSB of pointer
	LDA #>e_base	; emulated MSB
	STA tmptr+1		; pointer is ready
	BRA cpxe		; continue as indirect addressing

_ac:
; CPX ind (6)
; +
	_INDEXED		; get operand
	BRA cpxe		; same

_bc:
; CPX ext (5)
; +82/88.5/
	_EXTENDED		; get operand
cpxe:
	LDA ccr68		; get original flags
	AND #%11110001	; reset relevant bits
	STA ccr68		; update flags
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
	BNE cpxe_nz		; if zero...
		SMB2 ccr68		; set Z
cpxe_nz:
	BVC cpxe_nv		; if overflow...
		SMB1 ccr68		; set V
cpxe_nv:
	JMP next_op		; standard end

; decrement index
_09:
; DEX (4)
; +17/17/24
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

; decrement stack pointer
_34:
; DES (4)
; +10/10/22
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

; increase index
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

; increase stack pointer
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

; load index
_ce:
; LDX imm (3)
; +
	_PC_ADV			; get first operand
	STY tmptr		; store LSB of pointer
	LDA pc68 + 1	; get address MSB
	STA tmptr + 1	; pointer is ready
	BRA ldxe		; continue as indirect addressing

_de:
; LDX dir (4)
; +
	_DIRECT			; get first operand pointer
	STA tmptr		; store LSB of pointer
	LDA #>e_base	; emulated MSB
	STA tmptr+1		; pointer is ready
	BRA ldxe		; continue as indirect addressing

_ee:
; LDX ind (6)
; +
	_INDEXED		; get operand address
	BRA ldxe		; same

_fe:
; LDX ext (5)
; +72/76/
	_EXTENDED		; get operand address
ldxe:
	LDA ccr68		; get original flags
	AND #%11110001	; reset relevant bits
	STA ccr68		; update flags
	LDA (tmptr)		; value MSB
	BPL ldxe_pl		; not negative
		SMB3 ccr68		; otherwise set N flag
ldxe_pl:
	STA x68 + 1		; update register
	INC tmptr		; go for next operand
	BNE ldxe_nw		; rare wrap
		LDA tmptr+1		; get pointer MSB
		INC				; increment
		_AH_BOUND		; keep injected
		STA tmptr+1		; update pointer
ldxe_nw:
	LDA (tmptr)		; value LSB
	STA x68			; register complete
	ORA x68 + 1		; check for zero
	BNE ldxe_nz		; was not zero
		SMB2 ccr68		; otherwise set Z
ldxe_nz:
	JMP next_op		; standard end

; load stack pointer
_8e:
; LDS imm (3)
; +
	_PC_ADV			; get first operand
	STY tmptr		; store LSB of pointer
	LDA pc68 + 1	; get address MSB
	STA tmptr + 1	; pointer is ready
	BRA ldse		; continue as indirect addressing

_9e:
; LDS dir (4)
; +
	_DIRECT			; get operand address
	STA tmptr		; store LSB of pointer
	LDA #>e_base	; emulated MSB
	STA tmptr+1		; pointer is ready
	BRA ldse		; continue as indirect addressing

_ae:
; LDS ind (6)
; +
	_INDEXED		; get operand address
	BRA ldse		; same

_be:
; LDS ext (5)
; +70/73/
	_EXTENDED		; get operand address
ldse:
	LDA ccr68		; get original flags
	AND #%11110001	; reset relevant bits -- Z always zero because of injection!
	STA ccr68		; update flags
	LDA (tmptr)		; value MSB
	BPL ldse_pl		; not negative
		SMB3 ccr68		; otherwise set N flag
ldse_pl:
	_AH_BOUND		; keep injected
	STA sp68 + 1	; update register
	INC tmptr		; go for next operand
	BEQ ldse_w		; rare wrap
		LDA (tmptr)		; value LSB
		STA sp68		; register complete
;		ORA sp68 + 1	; check for zero
;		BNE ldse_nz		; was not zero
;			SMB2 ccr68		; otherwise set Z
;ldse_nz:
		JMP next_op		; standard end
ldse_w:
	LDA tmptr+1		; get pointer MSB
	INC				; increment
	_AH_BOUND		; keep injected
	STA tmptr+1		; update pointer
	LDA (tmptr)		; value LSB
	STA sp68		; register complete
;	ORA sp68 + 1	; check for zero
;	BNE ldse_wnz	; was not zero
;		SMB2 ccr68		; otherwise set Z
;ldse_wnz:
	JMP next_op		; standard end

; store index
_df:
; STX dir (5)
; +
	_DIRECT			; get first operand pointer
	STA tmptr		; store LSB of pointer
	LDA #>e_base	; emulated MSB
	STA tmptr+1		; pointer is ready
	BRA stxe		; continue as indirect addressing

_ef:
; STX ind (7)
; +
	_INDEXED		; get first operand pointer
	BRA stxe		; same

_ff:
; STX ext (6)
; +72/76.5/
	_EXTENDED		; get first operand pointer
stxe:
	LDA ccr68		; get original flags
	AND #%11110001	; reset relevant bits
	STA ccr68		; update flags
	LDA x68 + 1		; value MSB
	STA (tmptr)		; store it
	BPL stxe_pl		; not negative
		SMB3 ccr68		; otherwise set N flag
stxe_pl:
	INC tmptr		; go for next operand
	BEQ stxe_nw		; rare wrap
		LDA tmptr+1		; get pointer MSB
		INC				; increment
		_AH_BOUND		; keep injected
		STA tmptr+1		; update
stxe_nw:
	LDA x68			; value LSB
	STA (tmptr)		; store in memory 
	ORA x68 + 1		; check for zero
	BNE stxe_nz		; was not zero
		SMB2 ccr68		; otherwise set Z
stxe_nz:
	JMP next_op		; standard end

; store stack pointer
_9f:
; STS dir (5)
; +
	_DIRECT			; get operand address
	STA tmptr		; store LSB of pointer
	LDA #>e_base	; emulated MSB
	STA tmptr+1		; pointer is ready
	BRA stse		; continue as indirect addressing

_af:
; STS ind (7)
; +
	_INDEXED		; get operand address
	BRA stse		; same

_bf:
; STS ext (6)
; +65/67.5/
	_EXTENDED		; get operand address
stse:
	LDA ccr68		; get original flags
	AND #%11110001	; reset relevant bits -- Z always zero because of injection!
	STA ccr68		; update flags
	LDA sp68 + 1	; value MSB
	BPL stse_pl		; not negative
		SMB3 ccr68		; otherwise set N flag
stse_pl:
	STA (tmptr)		; store in memory
	INC tmptr		; go for next operand
	BEQ stse_w		; rare wrap
		LDA sp68		; value LSB
		STA (tmptr)		; transfer complete
;		ORA sp68 + 1	; check for zero
;		BNE stse_nz		; was not zero
;			SMB2 ccr68		; otherwise set Z
;stse_nz:
		JMP next_op		; standard end
stse_w:
	LDA tmptr+1		; get pointer MSB
	INC				; increment
	_AH_BOUND		; keep injected
	STA tmptr+1		; update pointer
	LDA sp68		; value LSB
	STA (tmptr)		; transfer complete
;	ORA sp68 + 1	; check for zero
;	BNE stse_wnz	; was not zero
;		SMB2 ccr68		; otherwise set Z
;stse_wnz:
	JMP next_op		; standard end

; transfers between index and stack pointer 
_30:
; TSX (4)
; +16/16/25
	LDA sp68 + 1	; get stack pointer MSB, to be injected
	LDX sp68		; get stack pointer LSB
	INX				; point to last used!!!
	STX x68			; store in X
	BEQ tsx_w		; rare wrap
tsx_do:
		STA x68 + 1		; pointer complete
		JMP next_op		; standard end of routine
tsx_w:
	INC				; increase MSB
	_AH_BOUND		; inject
	STA x68 + 1		; pointer complete
	JMP next_op		; rarer end of routine

_35:
; TXS (4)
; +21/21/25
	LDA x68 + 1		; MSB will be injected
	LDX x68			; check LSB
	BEQ txs_w		; will wrap upon decrease
		DEX				; as expected
		STX sp68		; copy
		_AH_BOUND		; always!
		STA sp68 + 1	; pointer ready
		JMP next_op		; standard end
txs_w:
	DEX				; as expected
	STX sp68		; copy
	DEC				; will also affect MSB
	_AH_BOUND		; always!
	STA sp68 + 1	; pointer ready
	JMP next_op		; standard end

; ** jumps and branching **

; branch if lower or same
_23:
; BLS rel (4)
; +15/30/
	_PC_ADV				; go for operand
		BBS0 ccr68, bra_do	; either carry...
		BBS2 ccr68, bra_do	; ...or zero will do
	JMP next_op			; exit without branching

; branch if overflow clear
_28:
; BVC rel (4)
; +10/25/
	_PC_ADV				; go for operand
		BBR1 ccr68, bra_do		; only if overflow clear
	JMP next_op			; exit without branching

; branch if overflow set
_29:
; BVS rel (4)
; +10/25/
	_PC_ADV				; go for operand
		BBS1 ccr68, bra_do	; only if overflow set
	JMP next_op			; exit without branching

; branch if plus
_2a:
; BPL rel (4)
; +10/25/
	_PC_ADV				; go for operand
		BBR3 ccr68, bra_do	; only if plus
	JMP next_op			; exit without branching

; branch if minus
_2b:
; BMI rel (4)
; +10/25/
	_PC_ADV				; go for operand
		BBS3 ccr68, bra_do	; only if negative
	JMP next_op			; exit without branching

; branch always (used by other branches)
_20:
; BRA rel (4)
; -5 +25/32/
	_PC_ADV			; go for operand
bra_do:				; max. from 29 here
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

; branch if carry clear
_24:
; BCC rel (4)
; +10/25/
	_PC_ADV				; go for operand
		BBR0 ccr68, bra_do	; only if carry clear
	JMP next_op			; exit without branching otherwise

; branch if carry set
_25:
; BCS rel (4)
; +10/25/
	_PC_ADV				; go for operand
		BBS0 ccr68, bra_do	; only if carry set
	JMP next_op			; exit without branching

; branch if not equal
_26:
; BNE rel (4)
; +10/25/
	_PC_ADV				; go for operand
		BBR2 ccr68, bra_do	; only if zero clear
	JMP next_op			; exit without branching

; branch if equal zero
_27:
; BEQ rel (4)
; +10/25/
	_PC_ADV				; go for operand
		BBS2 ccr68, bra_do	; only if zero set
	JMP next_op			; exit without branching

; branch if greater or equal (signed)
_2c:
; BGE rel (4)
; +17/34/
	_PC_ADV			; go for operand
	LDA ccr68		; get flags
	BIT #%00000010	; check V
	BEQ bge_nx		; do not XOR N if clear
		EOR #%00001000	; toggle N
bge_nx:
	AND #%00001010	; filter N and V only
		BEQ branch		; branch if N XOR V is zero
	JMP next_op		; exit without branching

; branch if less than (signed)
_2d:
; BLT rel (4)
; +17/34/
	_PC_ADV			; go for operand
	LDA ccr68		; get flags
	BIT #%00000010	; check V
	BEQ blt_nx		; do not XOR N if clear
		EOR #%00001000	; toggle N
blt_nx:
	AND #%00001010	; filter N and V only
		BNE branch		; branch if N XOR V is true
	JMP next_op		; exit without branching

; branch if greater (signed)
_2e:
; BGT rel (4)
; +17/34/
	_PC_ADV			; go for operand
	LDA ccr68		; get flags
	BIT #%00000010	; check V
	BEQ bgt_nx		; do not XOR N if clear
		EOR #%00001000	; toggle N
bgt_nx:
	AND #%00001110	; filter Z, N and V
		BEQ branch		; only if N XOR V (OR Z) is false
	JMP next_op		; exit without branching

; branch if less or equal (signed)
_2f:
; BLE rel (4)
; +17/34/
	_PC_ADV			; go for operand
	LDA ccr68		; get flags
	BIT #%00000010	; check V
	BEQ ble_nx		; do not XOR N if clear
		EOR #%00001000	; toggle N
ble_nx:
	AND #%00001110	; filter Z, N and V
		BNE branch		; only if N XOR V (OR Z) is true
br_exit:
	JMP next_op		; exit without branching (reused)

; branch if higher
_22:
; BHI rel (4)
; +11/29/
	_PC_ADV			; go for operand
		BBS0 ccr68, br_exit	; neither carry...
		BBS2 ccr68, br_exit	; ...nor zero (reuse is OK)
branch:
	JMP bra_do		; continue as usual

; branch to subroutine
_8d:
; BSR rel (8)
; +
	_PC_ADV			; go for operand
; * push return address *
	TYA				; get current PC-LSB minus one
	SEC				; return to next byte!
	ADC #0			; will set carry if wrapped!
	STA (sp68)		; stack LSB first
	DEC sp68		; decrement SP
	BNE bsr_phi		; no wrap, just push MSB
		LDA sp68 + 1	; get SP MSB
		DEC				; previous page
		_AH_BOUND		; inject
		STA sp68 + 1	; update pointer
bsr_phi:
	LDA pc68+1		; get current MSB
	ADC #0			; take previous carry!
	_AH_BOUND		; just in case
	STA (sp68)		; push it!
	DEC sp68		; update SP
	BNE branch		; no wrap, ready to go!
		LDA sp68 + 1	; get SP MSB
		DEC				; previous page
		_AH_BOUND		; inject
		STA sp68 + 1	; update pointer
	JMP bra_do		; do branch

; jump (and to subroutines)

_ad:
; JSR ind (8) *** ESSENTIAL for minimOS·63 kernel calling ***
; -5 +
	_PC_ADV			; point to offset
; * push return address *
	TYA				; get current PC-LSB minus one
	SEC				; return to next byte!
	ADC #0			; will set carry if wrapped!
	STA (sp68)		; stack LSB first
	DEC sp68		; decrement SP
	BNE jsri_phi		; no wrap, just push MSB
		LDA sp68 + 1	; get SP MSB
		DEC				; previous page
		_AH_BOUND		; inject
		STA sp68 + 1	; update pointer
jsri_phi:
	LDA pc68+1		; get current MSB
	ADC #0			; take previous carry!
	_AH_BOUND		; just in case
	STA (sp68)		; push it!
	DEC sp68		; update SP
	BNE jmpi		; no wrap, ready to go!
		LDA sp68 + 1	; get SP MSB
		DEC				; previous page
		_AH_BOUND		; inject
		STA sp68 + 1	; update pointer
	BRA jmpi		; compute address and jump

_6e:
; JMP ind (4)
; -5+30...
	_PC_ADV			; get operand
jmpi:
	LDA (pc68), Y	; set offset
	CLC				; prepare
	ADC x68			; add LSB
	TAY				; this is new offset!
	LDA x68 + 1		; get MSB
	ADC #0			; propagate carry
	_AH_BOUND		; stay injected
	STA pc68 + 1	; update pointer
	JMP execute		; do jump

_bd:
; JSR ext (9)
; -5 +
	_PC_ADV			; point to operand MSB
; * push return address *
	TYA				; get current PC-LSB minus one
	SEC				; return to next byte!
	ADC #0			; will set carry if wrapped!
	STA (sp68)		; stack LSB first
	DEC sp68		; decrement SP
	BNE jsre_phi		; no wrap, just push MSB
		LDA sp68 + 1	; get SP MSB
		DEC				; previous page
		_AH_BOUND		; inject
		STA sp68 + 1	; update pointer
jsre_phi:
	LDA pc68+1		; get current MSB
	ADC #0			; take previous carry!
	_AH_BOUND		; just in case
	STA (sp68)		; push it!
	DEC sp68		; update SP
	BNE jmpe		; no wrap, ready to go!
		LDA sp68 + 1	; get SP MSB
		DEC				; previous page
		_AH_BOUND		; inject
		STA sp68 + 1	; update pointer
	BRA jmpe		; compute address and jump

_7e:
; JMP ext (3)
; -5+32//46
	_PC_ADV			; go for destination MSB
jmpe:
	LDA (pc68), Y	; get it
	_AH_BOUND		; check against emulated limits
	TAX				; hold it for a moment
	_PC_ADV			; now for the LSB
	LDA (pc68), Y	; get it
	TAY				; this works as index
	STX pc68 + 1	; MSB goes into register area
	JMP execute		; all done (-5 for jumps, all this is +32...46)

; return from subroutine
_39:
; RTS (5)
; +
	LDX #1			; just the return address MSB to pull
	BRA return68	; generic procedure

; return from interrupt
_3b:
; RTI (10)
; -5 +139/139/
	LDX #7			; bytes into stack frame (4 up here)
return68:			; ** generic entry point, X = bytes to be pulled **
	STX tmptr		; store for later subtraction
	LDY #1			; forget PC MSB, index for pulling from stack
rti_loop:
		LDA (sp68), Y	; pull from stack
		STA pc68, X		; store into register area
		INY				; (pre)increment
		DEX				; go backwards
		BNE rti_loop	; zero NOT included (111 total loop)
	LDA (sp68), Y	; last byte in frame is LSB
	TAX				; store for later
	LDA sp68		; correct stack pointer
	CLC				; prepare
	ADC tmptr		; release space
	STA sp68		; update LSB
	BCC rti_nw		; skip if did not wrap
		LDA sp68+1		; not just INC zp...
		INC
		_AH_BOUND		; ...must be kept injected
		STA sp68+1		; update MSB when needed
rti_nw:
	TXA				; get older LSB
	TAY				; and make it effective! (24 lastly)
	JMP execute		; resume execution

; wait for interrupt
_3e:
; WAI (9)
; +
	; ***** TO DO ***** TO DO *****
	; *** should just check the external interrupt source... if I bit is clear ***
	; *** then call intr68 with appropriate X value ***
	JMP next_op		; standard end of routine

; software interrupt
_3f:
; SWI (12)
; -5 +
	_PC_ADV			; skip opcode
	LDX #2			; SWI vector offset
	JMP intr68		; generic interrupt handler

; ** status register opcodes **

; clear overflow
_0a:
; CLV (2)
; +5
	RMB1 ccr68	; clear V bit, *** Rockwell only! ***
	JMP next_op	; standard end of routine

; set overflow
_0b:
; SEV (2)
; +5
	SMB1 ccr68	; set V bit, *** Rockwell only! ***
	JMP next_op	; standard end of routine

; clear carry
_0c:
; CLC (2)
; +5
	RMB0 ccr68	; clear C bit, *** Rockwell only! ***
	JMP next_op	; standard end of routine

; set carry
_0d:
; SEC (2)
; +5
	SMB0 ccr68	; set C bit, *** Rockwell only! ***
	JMP next_op	; standard end of routine

; clear interrupt mask
_0e:
; CLI (2)
; +5
	RMB4 ccr68	; clear I bit, *** Rockwell only! ***
	JMP next_op	; standard end of routine

; set interrupt mask
_0f:
; SEI (2)
; +5
	SMB4 ccr68	; set I bit, *** Rockwell only! ***
	JMP next_op	; standard end of routine

; transfers between CCR and accumulator A
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
