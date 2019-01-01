; 6800 emulator for minimOS! *** COMPACT VERSION ***
; v0.1b2 -- complete minus hardware interrupts!
; (c) 2016-2019 Carlos J. Santisteban
; last modified 20160923-0935

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
	BCC go_emu		; more than enough space
	BEQ go_emu		; just enough!
		_ABORT(FULL)	; not enough memory otherwise (rare) new interface
go_emu:
#endif
	STA z_used		; set required ZP space as required by minimOS
	STZ zpar		; no screen size required
	STZ zpar+1		; neither MSB
	LDY #<title		; LSB of window title
	LDA #>title		; MSB of window title
	STY zaddr3		; set parameter
	STA zaddr3+1
	_KERNEL(OPEN_W)	; ask for a character I/O device
	BCC open_emu	; no errors
		_ABORT(NO_RSRC)	; abort otherwise!
open_emu:
	STY cdev		; store device!!!
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
			JMP (opt_h, X)	; emulation routines for opcodes with bit7 hi (6)
lo_jump:
			JMP (opt_l, X)	; otherwise, emulation routines for opcodes with bit7 low
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

; *** window title, optional and minimOS specific ***
title:
	.asc	"6800 simulator", 0

; *** opcode execution routines, labels must match those on tables below ***
; unsupported opcodes first
_00:_02:_03:_04:_05:_12:_13:_14:_15:_18:_1a:_1c:_1d:_1e:_1f:_21:_38:_3a:_3c:_3d
_41:_42:_45:_4b:_4e:_51:_52:_55:_5b:_5e:_61:_62:_65:_6b:_71:_72:_75:_7b
_83:_87:_8f:_93:_9d:_a3:_b3:_c3:_c7:_cc:_cd:_cf:_d3:_dc:_dd:_e3:_ec:_ed:_f3:_fc:_fd

; illegal opcodes will seem to trigger an interupt!
	_PC_ADV			; skip illegal opcode (5)
nmi68:				; hardware interrupts, when available, to be checked AFTER incrementing PC
	LDX #4			; offset for NMI vector (2)
intr68:				; ** generic interrupt entry point, offset in X **
	STX tmptr		; store offset for later (3)
; save processor status
	SEC				; prepare subtraction (2)
	LDA sp68		; get stack pointer LSB (3)
	SBC #7			; make room for stack frame (2)
	TAX				; store for later (2)
	BCS nmi_do		; no need for further action (3/11...)
		LDA sp68+1		; get MSB
		DEC				; wrap
		_AH_BOUND		; keep into emulated space
		STA sp68+1		; update pointer
nmi_do:
	STX sp68		; room already made (3)
	LDX #1			; index for register area stacking (skip fake PC LSB) (2)
	TYA				; actual PC LSB goes first! (2)
	LDY #7			; index for stack area (2)
	STA (sp68), Y	; push LSB first, then the loop (5)
	DEY				; post-decrement (2)
nmi_loop:
		LDA pc68, X			; get one byte from register area (4y)
		STA (sp68), Y		; store in free stack space (5y)
		INX					; increase original offset (2y)
		DEY					; stack grows backwards (2y)
		BNE nmi_loop		; zero is NOT included!!! (3y -1)
	LDX tmptr		; retrieve offset
vector_pull:		; ** standard vector pull entry point, offset in X **
	SMB4 ccr68		; mask interrupts! (5) *** Rockwell ***
	LDY e_top-7, X	; get LSB from emulated vector (4)
	LDA e_top-8, X	; get MSB... (4)
	_AH_BOUND		; ...but inject it into emulated space (5/5.5)
	STA pc68 + 1	; update PC (3)
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
		SMB3 ccr68		; set N *** Rockwell ***
cnz_pl:
	BNE next_op		; (check reach) if zero...
		SMB2 ccr68		; set Z *** Rockwell ***
	BRA next_op		; (check reach) standard end

; update indirect pointer and check NZ (11/13/22)
ind_nz:
	STA (tmptr)		; store at pointed address
	BRA check_nz	; check flags and exit

; check V & C bits, then N & V (9/13/31)
check_flags:
	BVC cvc_cc		; if overflow...
		SMB1 ccr68		; set V *** Rockwell ***
cvc_cc:
	BCS check_nz	; if carry...
		SMB0 ccr68		; set C *** Rockwell ***
	BRA check_nz	; continue checking

; ** accumulator and memory **

; add to A
_8b:
; ADD A imm (2)
; +72/78
	_PC_ADV			; not worth using the macro (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA addae		; continue as indirect addressing (58/64)

_9b:
; ADD A dir (3)
; +76/82/
	_DIRECT			; point to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA addae		; continue as indirect addressing (58/64)

_ab:
; ADD A ind (5)
; +89/95.5/
	_INDEXED		; point to operand 31/31.5
	BRA addae		; otherwise the same (58/64)

_bb:
; ADD A ext (4)
; +86/92.5/
	_EXTENDED		; point to operand (31/31.5)
addae:				; +55/61/ from here
	CLC				; this uses no carry (2)
	JMP adcae_cc	; otherwise the same as ADC (53/59)

_89:
; ADC A imm (2)
;  +75/81.5/
	_PC_ADV			; not worth using the macro (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA adcae		; continue as indirect addressing (61/67.5)

_99:
; ADC A dir (3)
; +79/85.5/
	_DIRECT			; point to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA adcae		; continue as indirect addressing (61/67.5)

_a9:
; ADC A ind (5)
; +92/99/
	_INDEXED		; point to operand (31/31.5)
	BRA adcae		; same (3+)

_b9:
; ADC A ext (4)
; +89/96/
	_EXTENDED		; point to operand (31/31.5)
adcae:				; +58/64.5 from here
	CLC				; prepare (2)
	BBR0 ccr68, adcae_cc	; no previous carry (6/6.5...) *** Rockwell ***
		SEC						; otherwise preset C
adcae_cc:			; +50/56/ from here
	LDA a68			; get accumulator A (3)
	BIT #%00010000	; check bit 4 (2)
	BEQ adcae_nh	; do not set H if clear (8/9...)
		SMB5 ccr68		; set H temporarily as b4 *** Rockwell ***
		BRA adcae_sh	; do not clear it
adcae_nh:
	RMB5 ccr68		; otherwise H is clear *** Rockwell ***
adcae_sh:
	ADC (tmptr)		; add operand (5)
adda:				; +32/37/ from here
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
	JMP a_nz		; update A and check NZ (9/11/20)

; add accumulators
_1b:
; ABA (2)
; +53/59/
	LDA a68			; get accumulator A (3)
	BIT #%00010000	; check bit 4 (2)
	BEQ aba_nh		; do not set H if clear (8/9...)
		SMB5 ccr68		; set H temporarily as b4 *** Rockwell ***
		BRA aba_sh		; do not clear it
aba_nh:
	RMB5 ccr68		; otherwise H is clear *** Rockwell ***
aba_sh:
	CLC				; prepare (2)
	ADC b68			; add second accumulator (3)
	BRA adda		; continue adding to A (35/40)

; add to B
_cb:
; ADD B imm (2)
; +75/81/
	_PC_ADV			; not worth using the macro (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA addbe		; continue as indirect addressing (61/67)

_db:
; ADD B dir (3)
; +79/85/
	_DIRECT			; point to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA addbe		; continue as indirect addressing (61/67)

_eb:
; ADD B ind (5)
; +92/98.5/
	_INDEXED		; point to operand (31/31.5)
	BRA addbe		; the same (61/67)

_fb:
; ADD B ext (4)
; +89/95.5/
	_EXTENDED		; point to operand (31/31.5)
addbe:				; +58/64/ from here
	CLC				; this takes no carry (2)
	JMP adcbe_cc	; otherwise the same as ADC! (56/62)

_c9:
; ADC B imm (2)
;  +78/84.5/
	_PC_ADV			; not worth using the macro (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA adcbe		; continue as indirect addressing (64/70.5)

_d9:
; ADC B dir (3)
; +82/88.5/
	_DIRECT			; point to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA adcbe		; continue as indirect addressing (64/70.5)

_e9:
; ADC B ind (5)
; +95/102/
	_INDEXED		; point to operand (31/31.5)
	BRA adcbe		; same (64/70.5)

_f9:
; ADC B ext (4)
; +92/99/
	_EXTENDED		; point to operand (31/31.5)
adcbe:				; +61/67.5/ from here
	CLC				; prepare (2)
	BBR0 ccr68, adcbe_cc	; no previous carry (6/6.5...) *** Rockwell ***
		SEC						; otherwise preset C
adcbe_cc:			; +53/59/ from here
	LDA b68			; get accumulator B (3)
	BIT #%00010000	; check bit 4 (2)
	BEQ adcbe_nh	; do not set H if clear (8/9...)
		SMB5 ccr68		; set H temporarily as b4 *** Rockwell ***
		BRA adcbe_sh	; do not clear it
adcbe_nh:
	RMB5 ccr68		; otherwise H is clear *** Rockwell ***
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
	JMP b_nz		; update B and check NZ (12/14/23)

; logical AND
_84:
; AND A imm (2)
; +42/44/
	_PC_ADV			; go for operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA andae		; continue as indirect addressing (28/30/39)

_94:
; AND A dir (3)
; +46/48/
	_DIRECT			; points to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA andae		; continue as indirect addressing (28/30/39)

_a4:
; AND A ind (5)
; +59/61.5/
	_INDEXED		; points to operand (31/31.5)
	BRA andae		; same (28/30/39)

_b4:
; AND A ext (4)
; +56/58.5/
	_EXTENDED		; points to operand (31/31.5)
andae:				; +25/27/36 from here
	LDA ccr68		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr68		; update (3)
	LDA a68			; get A accumulator (3)
	AND (tmptr)		; AND with operand (5)
	JMP a_nz		; update A and check NZ (9/11/20)

_c4:
; AND B imm (2)
; +45/47/
	_PC_ADV			; go for operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA andbe		; continue as indirect addressing (31/33/42)

_d4:
; AND B dir (3)
; +49/51/
	_DIRECT			; points to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA andbe		; continue as indirect addressing (31/33/42)

_e4:
; AND B ind (5)
; +62/64.5/
	_INDEXED		; points to operand (31/31.5)
	BRA andbe		; same (31/33/42)

_f4:
; AND B ext (4)
; +59/61.5/
	_EXTENDED		; points to operand (31/31.5)
andbe:				; +28/30/39 from here
	LDA ccr68		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr68		; update (3)
	LDA b68			; get B accumulator (3)
	AND (tmptr)		; AND with operand (5)
	JMP b_nz		; update B and check NZ (12/14/23)

; AND without modifying register
_85:
; BIT A imm (2)
; +39/41/
	_PC_ADV			; go for operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA bitae		; continue as indirect addressing (25/27/36)

_95:
; BIT A dir (3)
; +43/45/
	_DIRECT			; points to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA bitae		; continue as indirect addressing (25/27/36)

_a5:
; BIT A ind (5)
; +56/58.5/
	_INDEXED		; points to operand (31/31.5)
	BRA bitae		; same (25/27/36)

_b5:
; BIT A ext (4)
; +53/55.5/
	_EXTENDED		; points to operand (31/31.5)
bitae:				; +22/24/33 from here
	LDA ccr68		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr68		; update (3)
	LDA a68			; get A accumulator (3)
	AND (tmptr)		; AND with operand, just for flags (5)
	JMP check_nz	; check flags and end (6/8/17)

_c5:
; BIT B imm (2)
; +39/41/
	_PC_ADV			; go for operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA bitbe		; continue as indirect addressing (25/27/36)

_d5:
; BIT B dir (3)
; +43/45/
	_DIRECT			; points to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA bitbe		; continue as indirect addressing (25/27/36)

_e5:
; BIT B ind (5)
; +56/58.5/
	_INDEXED		; points to operand (31/31.5)
	BRA bitbe		; same (25/27/36)

_f5:
; BIT B ext (4)
; +53/55.5/
	_EXTENDED		; points to operand (31/31.5)
bitbe:				; +22/24/33 from here
	LDA ccr68		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr68		; update (3)
	LDA b68			; get B accumulator (3)
	AND (tmptr)		; AND with operand, just for flags (5)
	JMP check_nz	; check flags and end (6/8/17)

; clear
_4f:
; CLR A (2)
; +13
	STZ a68		; clear A (3)
clra:
	LDA ccr68	; get previous status (3)
	AND #%11110100	; clear N, V, C (2)
	ORA #%00000100	; set Z (2)
	STA ccr68	; update (3)
	JMP next_op	; standard end of routine

_5f:
; CLR B (2)
; +16
	STZ b68		; clear B (3)
	BRA clra	; same (13)

_6f:
; CLR ind (7)
; +54/54.5/
	_INDEXED		; prepare pointer (31/31.5)
	BRA clre		; same code (23)

_7f:
; CLR ext (6)
; +51/51.5/
	_EXTENDED		; prepare pointer (31/31.5)
clre:
	LDA #0			; no indirect STZ available (2)
	STA (tmptr)		; clear memory (5)
	BRA clra		; same (13)

; compare
_81:
; CMP A imm (2)
; +47/51/
	_PC_ADV			; get operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA cmpae		; continue as indirect addressing (33/37/55)

_91:
; CMP A dir (3)
; +51/55/
	_DIRECT			; get operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA cmpae		; continue as indirect addressing (33/37/55)

_a1:
; CMP A ind (5)
; +64/68.5/
	_INDEXED		; get operand (31/31.5)
	BRA cmpae		; same (33/37/55)

_b1:
; CMP A ext (4)
; +61/65.5/
	_EXTENDED		; get operand (31/31.5)
cmpae:				; +30/34/52 from here
	LDA ccr68		; get flags (3)
	AND #%11110000	; clear relevant bits (2)
	STA ccr68		; update (3)
	LDA a68			; get accumulator A (3)
	SEC				; prepare (2)
	SBC (tmptr)		; subtract without carry (5)
	JMP check_flags	; check NZVC and exit (12/16/34)

_c1:
; CMP B imm (2)
; +47/51/
	_PC_ADV			; get operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA cmpbe		; continue as indirect addressing (33/37/55)

_d1:
; CMP B dir (3)
; +51/55/
	_DIRECT			; get operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA cmpbe		; continue as indirect addressing (33/37/55)

_e1:
; CMP B ind (5)
; +64/68.5/
	_INDEXED		; get operand (31/31.5)
	BRA cmpbe		; same (33/37/55)

_f1:
; CMP B ext (4)
; +61/65.5/
	_EXTENDED		; get operand (31/31.5)
cmpbe:				; +30/34/52 from here
	LDA ccr68		; get flags (3)
	AND #%11110000	; clear relevant bits (2)
	STA ccr68		; update (3)
	LDA b68			; get accumulator B (3)
	SEC				; prepare (2)
	SBC (tmptr)		; subtract without carry (5)
	JMP check_flags	; check NZVC and exit (12/16/34)

; compare accumulators
_11:
; CBA (2)
; +28/32/50
	LDA ccr68		; get flags (3)
	AND #%11110000	; clear relevant bits (2)
	STA ccr68		; update (3)
	LDA a68			; get accumulator A (3)
	SEC				; prepare (2)
	SBC b68			; subtract B without carry (3)
	JMP check_flags	; check NZVC and exit (12/16/34)

; 1's complement
_43:
; COM A (2)
; +24/26/35
	LDA ccr68		; get original flags (3)
	AND #%11110000	; reset relevant bits (2)
	INC				; C always set (2)
	STA ccr68		; update status (3)
	LDA a68			; get A (3)
	EOR #$FF		; complement it (2)
	JMP a_nz		; update A, check NZ and exit (9/11/20)

_53:
; COM B (2)
; +27/29/38
	LDA ccr68		; get original flags (3)
	AND #%11110000	; reset relevant bits (2)
	INC				; C always set (2)
	STA ccr68		; update status (3)
	LDA b68			; get B (3)
	EOR #$FF		; complement it (2)
	JMP b_nz		; update B, check NZ and exit (12/14/23)

_63:
; COM ind (7)
; +65/67.5/
	_INDEXED		; compute pointer (31/31.5)
	BRA come		; same (34/36/45)

_73:
; COM ext (6)
; +62/64.5/
	_EXTENDED		; addressing mode (31/31.5)
come:				; +31/33/42 from here
	LDA ccr68		; get original flags (3)
	AND #%11110000	; reset relevant bits (2)
	INC				; C always set (2)
	STA ccr68		; update status (3)
	LDA (tmptr)		; get memory (5)
	EOR #$FF		; complement it (2)
	JMP ind_nz		; store, check flags and exit (14/17/25)

; 2's complement
_40:
; NEG A (2)
; +36/40/51
	LDA ccr68		; get original flags (3)
	AND #%11110000	; reset relevant bits (2)
	STA ccr68		; update status (3)
	SEC				; prepare subtraction (2)
	LDA #0			; (2)
	SBC a68			; negate A (3)
	STA a68			; update value (3)
nega:				; +18/22/33 from here
	BNE nega_nc		; carry only if zero (3)
		SMB0 ccr68		; set C flag *** Rockwell ***
nega_nc:
	TAX				; keep for later! (2)
	CMP #$80		; will overflow? (2)
	BNE nega_nv		; skip if not V (3)
		SMB1 ccr68		; set V flag *** Rockwell ***
nega_nv:
	TXA				; retrieve (2)
	JMP check_nz	; finish (6/8/17)

_50:
; NEG B (2)
; +39/43/54
	LDA ccr68		; get original flags (3)
	AND #%11110000	; reset relevant bits (2)
	STA ccr68		; update status (3)
	SEC				; prepare subtraction (2)
	LDA #0			; (2)
	SBC b68			; negate B (3)
	STA b68			; update value (3)
	BRA nega		; check flags (21/25/36)

_60:
; NEG ind (7)
; +77/81.5/
	_INDEXED		; compute pointer (31/31.5)
	BRA nege		; same (46/50/61)

_70:
; NEG ext (6)
; +74/78.5/
	_EXTENDED		; addressing mode (31/31.5)
nege:				; +43/47/58 from here
	LDA ccr68		; get original flags (3)
	AND #%11110000	; reset relevant bits (2)
	STA ccr68		; update status (3)
	SEC				; prepare subtraction (2)
	LDA #0			; (2)
	SBC (tmptr)		; negate memory (5)
	STA (tmptr)		; update value (5)
	BRA nega		; continue (21/25/36)

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
		SMB0 ccr68		; otherwise set C *** Rockwell ***
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
		SMB1 ccr68		; ...set V flag *** Rockwell ***
daa_nv:
	STA a68			; update accumulator with BCD value
daa_ok:
	JMP check_flags	; check and exit

; decrement
_4a:
; DEC A (2)
; +29/31/
	LDA ccr68		; get original status (3)
	AND #%11110001	; reset all relevant bits for CCR (2)
	STA ccr68		; store new flags (3)
	DEC a68			; decrease A (5)
	LDX a68			; check it! (3)
deca:				; +13/15/ from here
	CPX #$7F		; did change sign? (2)
	BNE deca_nv		; skip if not overflow (3...)
		SMB1 ccr68		; will set V flag *** Rockwell ***
deca_nv:
	TXA				; retrieve! (2)
	JMP check_nz	; end (6/8/17)

_5a:
; DEC B (2)
; +32/34/
	LDA ccr68		; get original status (3)
	AND #%11110001	; reset all relevant bits for CCR (2)
	STA ccr68		; store new flags (3)
	DEC b68			; decrease B (5)
	LDX b68			; check it! (3)
	BRA deca		; continue (16/18)

_6a:
; DEC ind (7)
; +72/74.5/
	_INDEXED		; addressing mode (31/31.5)
	BRA dece		; same (41/43)

_7a:
; DEC ext (6)
; +69/71.5/
	_EXTENDED		; addressing mode (31/31.5)
dece:				; +38/40/ from here
	LDA ccr68		; get original status (3)
	AND #%11110001	; reset all relevant bits for CCR (2)
	STA ccr68		; store new flags (3)
	LDA (tmptr)		; no DEC (tmptr) available... (5)
	DEC				; (2)
	STA (tmptr)		; (5)
	TAX				; store for later (2)
	BRA deca		; continue (16/18)

; exclusive OR
_88:
; EOR A imm (2)
; +42/44/
	_PC_ADV			; go for operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA eorae		; continue as indirect addressing (28/30/39)

_98:
; EOR A dir (3)
; +46/48/
	_DIRECT			; Points to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA eorae		; continue as indirect addressing (28/30/39)

_a8:
; EOR A ind (5)
; +59/61.5/
	_INDEXED		; points to operand (31/31.5)
	BRA eorae		; same (28/30/39)

_b8:
; EOR A ext (4)
; +56/58.5/
	_EXTENDED		; points to operand (31/31.5)
eorae:				; +25/27/36 from here
	LDA ccr68		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr68		; update (3)
	LDA a68			; get A accumulator (3)
	EOR (tmptr)		; EOR with operand (5)
	JMP a_nz		; update A, check NZ and exit (9/11/20)

_c8:
; EOR B imm (2)
; +45/48/
	_PC_ADV			; go for operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA eorbe		; continue as indirect addressing (31/33/42)

_d8:
; EOR B dir (3)
; +49/51/
	_DIRECT			; points to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA eorbe		; continue as indirect addressing (31/33/42)

_e8:
; EOR B ind (5)
; +62/64.5/
	_INDEXED		; points to operand (31/31.5)
	BRA eorbe		; same (31/33/42)

_f8:
; EOR B ext (4)
; +59/61.5/
	_EXTENDED		; points to operand (31/31.5)
eorbe:				; +28/30/39 from here
	LDA ccr68		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr68		; update (3)
	LDA b68			; get B accumulator (3)
	EOR (tmptr)		; EOR with operand (5)
	JMP b_nz		; update B, check NZ and exit (12/14/23)

; increment
_4c:
; INC A (2)
; +29/31/
	LDA ccr68		; get original status (3)
	AND #%11110001	; reset all relevant bits for CCR (2)
	STA ccr68		; store new flags (3)
	INC a68			; increase A (5)
	LDX a68			; check it! (3)
inca:				; +13/15/ from here
	CPX #$80		; did change sign? (2)
	BNE inca_nv		; skip if not overflow (3...)
		SMB1 ccr68		; will set V flag *** Rockwell ***
inca_nv:
	TXA				; retrieve! (2)
	JMP check_nz	; end (6/8/17)

_5c:
; INC B (2)
; +32/34/
	LDA ccr68		; get original status (3)
	AND #%11110001	; reset all relevant bits for CCR (2)
	STA ccr68		; store new flags (3)
	INC b68			; increase B (5)
	LDX b68			; check it! (3)
	BRA inca		; continue (3+)

_6c:
; INC ind (7)
; +72/74.5/
	_INDEXED		; addressing mode (31/31.5)
	BRA ince		; same (3+)

_7c:
; INC ext (6)
; +69/71.5/
	_EXTENDED		; addressing mode (31/31.5)
ince:
	LDA ccr68		; get original status (3)
	AND #%11110001	; reset all relevant bits for CCR (2)
	STA ccr68		; store new flags (3)
	LDA (tmptr)		; no INC (tmptr) available... (5)
	INC				; (2)
	STA (tmptr)		; (5)
	TAX				; store for later (2)
	BRA inca		; continue (3+)

; load accumulator
_86:
; LDA A imm (2)
; +39/41/
	_PC_ADV			; go for operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA ldaae		; continue as indirect addressing (25/27/36)

_96:
; LDA A dir (3) *** access to $00 is redirected to standard input ***
; +45/47
	_DIRECT				; X points to operand (10)
; ** trap address in case it goes to host console **
;	CMP #limit+1		; compare against last trapped address, optional (2)
;	BCC ldaad_trap		; ** intercept range, otherwise use BEQ (2)
	BEQ ldaad_trap		; ** intercept input! (2)
; ** continue execution otherwise **
		STA tmptr		; store LSB of pointer (3)
		LDA #>e_base	; emulated MSB (2)
		STA tmptr+1		; pointer is ready (3)
		BRA ldaae		; continue as indirect addressing (25/27/36)
; *** input from console, minimOS specific ***
ldaad_trap:
	LDY cdev		; *** minimOS standard device ***
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
; +56/58.5/
	_INDEXED		; points to operand (31/31.5)
	BRA ldaae		; same (25/27/36)

_b6:
; LDA A ext (4)
; +53/55.5/
	_EXTENDED		; points to operand (31/31.5)
ldaae:				; +22/24/33 from here
	LDA ccr68		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr68		; update (3)
	LDA (tmptr)		; get operand (5)
	JMP a_nz		; update A, check NZ and exit (9/11/20)

_c6:
; LDA B imm (2)
; +42/44/
	_PC_ADV			; go for operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA ldabe		; continue as indirect addressing (28/30/39)

_d6:
; LDA B dir (3) *** access to $00 is redirected to standard input ***
; +48/50/
	_DIRECT				; A points to operand (10)
; ** trap address in case it goes to host console **
;	CMP #limit+1		; compare against last trapped address, optional (2)
;	BCC ldabd_trap		; ** intercept range, otherwise use BEQ (2)
	BEQ ldabd_trap		; ** intercept input! (2)
; ** continue execution otherwise **
		STA tmptr		; store LSB of pointer (3)
		LDA #>e_base	; emulated MSB (2)
		STA tmptr+1		; pointer is ready (3)
		BRA ldabe		; continue as indirect addressing (28/30/39)
; *** input from console, minimOS specific ***
ldabd_trap:
	LDY cdev		; *** minimOS standard device ***
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
; +59/61.5/
	_INDEXED		; points to operand (31/31.5)
	BRA ldabe		; same (28/30/39)

_f6:
; LDA B ext (4)
; +56/58.5/
	_EXTENDED		; points to operand (31/31.5)
ldabe:				; +25/27/36
	LDA ccr68		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr68		; update (3)
	LDA (tmptr)		; get operand (5)
	JMP b_nz		; update B, check NZ and exit (12/14/23)

; inclusive OR
_8a:
; ORA A imm (2)
; + [[[[[[[[[[[[[[[[[[[[[[[[CONTINUE HERE]]]]]]]]]]]]]]]]]]]]]]]]
	_PC_ADV			; go for operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA oraae		; continue as indirect addressing (3+)

_9a:
; ORA A dir (3)
; +
	_DIRECT			; points to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA oraae		; continue as indirect addressing (3+)

_aa:
; ORA A ind (5)
; +
	_INDEXED		; points to operand (31/31.5)
	BRA oraae		; same (3+)

_ba:
; ORA A ext (4)
; +
	_EXTENDED		; points to operand (31/31.5)
oraae:
	LDA ccr68		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr68		; update (3)
	LDA a68			; get A accumulator (3)
	ORA (tmptr)		; ORA with operand (5)
	JMP a_nz		; update A, check NZ and exit (9/11/20)

_ca:
; ORA B imm (2)
; +
	_PC_ADV			; go for operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA orabe		; continue as indirect addressing (3+)

_da:
; ORA B dir (3)
; +
	_DIRECT			; points to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA orabe		; continue as indirect addressing (3+)

_ea:
; ORA B ind (5)
; +
	_INDEXED		; points to operand (31/31.5)
	BRA orabe		; same (3+)

_fa:
; ORA B ext (4)
; +
	_EXTENDED		; points to operand (31/31.5)
orabe:
	LDA ccr68		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr68		; update (3)
	LDA b68			; get B accumulator (3)
	ORA (tmptr)		; ORA with operand (5)
	JMP b_nz		; update B, check NZ and exit (12/14/23)

; push accumulator
_36:
; PSH A (4)
; +
	LDA a68			; get accumulator A (3)
psha:
	STA (sp68)		; put it on stack space (5)
	LDX sp68		; check LSB (3)
	BNE psha_nw		; will not wrap (3...)
		LDA sp68+1		; get MSB
		DEC				; decrease it
		_AH_BOUND		; and inject it
		STA sp68+1		; worst update
psha_nw:
	DEC sp68		; post-decrement (5)
	JMP next_op		; all done (3+)

_37:
; PSH B (4)
; +
	LDA b68			; get accumulator B (3)
	BRA psha		; same (3+)

; pull accumulator
_32:
; PUL A (4)
; +
	INC sp68		; pre-increment (5)
	BNE pula_nw		; should not correct MSB (3...)
		LDA sp68 + 1	; get stack pointer MSB
		INC				; increase MSB
		_AH_BOUND		; keep injected
		STA sp68 + 1	; update real thing
pula_nw:
	LDA (sp68)		; take value from stack (5)
	STA a68			; store it in accumulator A (3)
	JMP next_op		; standard end of routine

_33:
; PUL B (4)
; +
	INC sp68		; pre-increment (5)
	BNE pulb_nw		; should not correct MSB (3...)
		LDA sp68 + 1	; get stack pointer MSB
		INC				; increase MSB
		_AH_BOUND		; keep injected
		STA sp68 + 1	; update real thing
pulb_nw:
	LDA (sp68)		; take value from stack (5)
	STA b68			; store it in accumulator B (3)
	JMP next_op		; standard end of routine

; rotate left
_49:
; ROL A (2)
; +
	CLC				; prepare (2)
	BBR0 ccr68, rola_do	; skip if C clear (6/6.5...) *** Rockwell ***
		SEC					; otherwise, set carry
rola_do:
	ROL a68			; rotate A left (5)
	LDX a68			; keep for later (3)
rots:				; *** common rotation ending, with value in X ***
	LDA ccr68		; get flags again (3)
	AND #%11110000	; reset relevant bits (2)
	BCC rola_nc		; skip if there was no carry (3/4.5...)
		ORA #%00000001	; will set C flag (2)
		EOR #%00000010	; toggle V bit (2)
rola_nc:
	CPX #0			; watch computed value! (2)
	BNE rola_nz		; skip if not zero (3...)
		ORA #%00000100	; set Z flag (2)
		CPX #0			; retrieve again, much faster! (2)
rola_nz:
	BPL rola_pl		; skip if positive (3/4.5...)
		ORA #%00001000	; will set N bit (2)
		EOR #%00000010	; toggle V bit (2)
rola_pl:
	STA ccr68		; update status (3)
	JMP next_op		; standard end of routine

_59:
; ROL B (2)
; +
	CLC				; prepare (2)
	BBR0 ccr68, rolb_do	; skip if C clear (6/6.5...) *** Rockwell ***
		SEC					; otherwise, set carry
rolb_do:
	ROL b68			; rotate B left (5)
	LDX b68			; keep for later (3)
	BRA rots		; same code! (3+)

_79:
; ROL ext (6)
; +
	_EXTENDED		; addressing mode (31/31.5)
role:
	CLC				; prepare (2)
	BBR0 ccr68, role_do	; skip if C clear (6/6.5) *** Rockwell ***
		SEC					; otherwise, set carry
role_do:
	LDA (tmptr)		; get memory (5)
	ROL				; rotate left (2)
	STA (tmptr)		; modify (5)
	TAX				; keep for later (2)
	BRA rots		; continue (3+)

_69:
; ROL ind (7)
; +
	_INDEXED		; addressing mode (31/31.5)
	BRA role		; same (3+)

; rotate right
_46:
; ROR A (2)
; +
	CLC				; prepare (2)
	BBR0 ccr68, rora_do	; skip if C clear (6/6.5...) *** Rockwell ***
		SEC					; otherwise, set carry
rora_do:
	ROR a68			; rotate A right (5)
	LDX a68			; keep for later (3)
	JMP rots		; common end! (3+)

_56:
; ROR B (2)
; +
	CLC				; prepare (2)
	BBR0 ccr68, rorb_do	; skip if C clear (6/6.5...) *** Rockwell ***
		SEC					; otherwise, set carry
rorb_do:
	ROR b68			; rotate B right (5)
	LDX b68			; keep for later (3)
	JMP rots		; common end! (3+)

_66:
; ROR ind (7)
; +
	_INDEXED		; addressing mode (31/31.5)
	BRA rore		; same (3+)

_76:
; ROR ext (6)
; +
	_EXTENDED		; addressing mode (31/31.5)
rore:
	CLC				; prepare (2)
	BBR0 ccr68, rore_do	; skip if C clear (6/6.5...) *** Rockwell ***
		SEC					; otherwise, set carry
rore_do:
	LDA (tmptr)		; get memory (5)
	ROR				; rotate right (2)
	STA (tmptr)		; modify (5)
	TAX				; keep for later (2)
	JMP rots		; common end! (3+)

; arithmetic shift left
_48:
; ASL A (2)
; +
	ASL a68			; shift A left (5)
	LDX a68			; retrieve again! (3)
	JMP rots		; common end (3+)

_58:
; ASL B (2)
; +
	ASL b68			; shift B left (5)
	LDX b68			; retrieve again! (3)
	JMP rots		; common end (3+)

_68:
; ASL ind (7)
; +
	_INDEXED		; prepare pointer (31/31.5)
	BRA asle		; same (3+)

_78:
; ASL ext (6)
; +
	_EXTENDED		; prepare pointer (31/31.5)
asle:
	LDA (tmptr)		; get operand (5)
	ASL				; shift left (2)
	STA (tmptr)		; update memory (5)
	TAX				; save for later! (2)
	JMP rots		; common end! (3+)

; arithmetic shift right
_47:
; ASR A (2)
; +
	CLC				; prepare (2)
	BIT a68			; check bit 7 (3)
	BPL asra_do		; do not insert C if clear
		SEC				; otherwise, set carry (2)
asra_do:
	ROR a68			; emulate arithmetic shift left with preloaded-C rotation (5)
	TAX				; store for later (2)
	JMP rots		; common end! (3+)

_57:
; ASR B (2)
; +
	CLC				; prepare (2)
	BIT b68			; check bit 7 (3)
	BPL asrb_do		; do not insert C if clear
		SEC				; otherwise, set carry (2)
asrb_do:
	ROR b68			; emulate arithmetic shift left with preloaded-C rotation (5)
	TAX				; store for later (2)
	JMP rots		; common end! (3+)

_67:
; ASR ind (7)
; +
	_INDEXED		; get pointer to operand (31/31.5)
	BRA asre		; same (3+)

_77:
; ASR ext (6)
; +
	_EXTENDED		; get pointer to operand (31/31.5)
asre:
	CLC				; prepare (2)
	LDA (tmptr)		; check operand (5)
	BPL asre_do		; do not insert C if clear
		SEC				; otherwise, set carry (2)
asre_do:
	ROR 			; emulate arithmetic shift left with preloaded-C rotation (2)
	STA (tmptr)		; update memory (5)
	TAX				; store for later! (2)
	JMP rots		; common end! (3+)

; logical shift right
_44:
; LSR A (2)
; +
	LDA ccr68		; get original flags (3)
	AND #%11110000	; reset relevant bits (N always reset) (2)
	LSR a68			; shift A right (5)
lshift:				; *** common ending for logical shifts ***
	BNE lsra_nz		; skip if not zero (3...)
		ORA #%00000100	; set Z flag (2)
lsra_nz:
	BCC lsra_nc		; skip if there was no carry (3/3.5...)
		ORA #%00000011	; will set C and V flags, seems OK (2)
lsra_nc:
	STA ccr68		; update status (3)
	JMP next_op		; standard end of routine

_54:
; LSR B (2)
; +
	LDA ccr68		; get original flags (3)
	AND #%11110000	; reset relevant bits (N always reset) (2)
	LSR b68			; shift B right (5)
	BRA lshift		; common end! (3+)

_64:
; LSR ind (7)
; +
	_INDEXED		; addressing mode (31/31.5)
	BRA lsre		; same (3+)

_74:
; LSR ext (6)
; +
	_EXTENDED		; addressing mode (31/31.5)
lsre:
	LDA (tmptr)		; get operand (5)
	LSR				; (2)
	STA (tmptr)		; modify operand (5)
	PHP				; store status, really needed!!! (3)
	LDA ccr68		; get original flags (3)
	AND #%11110000	; reset relevant bits (N always reset) (2)
	PLP				; retrieve status, proper way!!! (4)
	BRA lshift		; common end! (3+)

; store accumulator [[[[continue from here]]]]]]
_97:
; STA A dir (4) *** access to $00 is redirected to minimOS standard output ***
; +
	_DIRECT				; A points to operand (10)
; ** trap address in case it goes to host console **
	BEQ staad_trap		; ** intercept input! (2)
; ** continue execution otherwise **
		STA tmptr		; store LSB of pointer (3)
		LDA #>e_base	; emulated MSB (2)
		STA tmptr+1		; pointer is ready (3)
		BRA staae		; continue as indirect addressing (3+)
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
	_INDEXED		; points to operand (31/31.5)
	BRA staae		; same (3+)

_b7:
; STA A ext (5)
; +53/55.5/
	_EXTENDED		; points to operand (31/31.5)
staae:
	LDA ccr68		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr68		; update (3)
	LDA a68			; get A accumulator (3)
	JMP ind_nz		; store, check NZ and exit (14/17/25)

_d7:
; STA B dir (4) *** access to $00 is redirected to minimOS standard output ***
; +
	_DIRECT				; A points to operand (10)
; ** trap address in case it goes to host console **
	BEQ stabd_trap		; ** intercept input! (2)
; ** continue execution otherwise **
		STA tmptr		; store LSB of pointer (3)
		LDA #>e_base	; emulated MSB (2)
		STA tmptr+1		; pointer is ready (3)
		BRA stabe		; continue as indirect addressing (3+)
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
	_INDEXED		; points to operand (31/31.5)
	BRA stabe		; same (3+)

_f7:
; STA B ext (5)
; +53/55.5/
	_EXTENDED		; points to operand (31/31.5)
stabe:
	LDA ccr68		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr68		; update (3)
	LDA b68			; get B accumulator (3)
	JMP ind_nz		; store, check NZ and exit (14/17/25)

; subtract without carry
_80:
; SUB A imm (2)
; +
	_PC_ADV			; get operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA subae		; continue as indirect addressing (3+)

_90:
; SUB A dir (3)
; +
	_DIRECT			; get operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA subae		; continue as indirect addressing (3+)

_a0:
; SUB A ind (5)
; +
	_INDEXED		; get operand (31/31.5)
	BRA subae		; same (3+)

_b0:
; SUB A ext (4)
; +67/73.5/
	_EXTENDED		; get operand (31/31.5)
subae:
	SEC				; prepare (2)
	JMP sbcae_do	; and continue (3+)

_c0:
; SUB B imm (2)
; +
	_PC_ADV			; get operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA subbe		; continue as indirect addressing (3+)

_d0:
; SUB B dir (3)
; +
	_DIRECT			; get operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA subbe		; continue as indirect addressing (3+)

_e0:
; SUB B ind (5)
; +
	_INDEXED		; get operand (31/31.5)
	BRA subbe		; same (3+)

_f0:
; SUB B ext (4)
; +67/73.5/
	_EXTENDED		; get operand (31/31.5)
subbe:
	SEC				; prepare (2)
	JMP sbcbe_do	; and continue (3+)

; subtract accumulators
_10:
; SBA (2)
; +31/37/43
	LDA ccr68		; get flags (3)
	AND #%11110000	; clear relevant bits (2)
	STA ccr68		; update (3)
	LDA a68			; get accumulator A (3)
	SEC				; prepare (2)
	SBC b68			; subtract B without carry (3)
	STA a68			; update accumulator A (3)
	JMP check_flags	; and exit (12/16/34)

; subtract with carry
_82:
; SBC A imm (2)
; +
	_PC_ADV			; get operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA sbcae		; continue as indirect addressing (3+)

_92:
; SBC A dir (3)
; +
	_DIRECT			; get operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA sbcae		; continue as indirect addressing (3+)

_a2:
; SBC A ind (5)
; +
	_INDEXED		; get operand (31/31.5)
	BRA sbcae		; same (3+)

_b2:
; SBC A ext (4)
; +70/77/
	_EXTENDED		; get operand (31/31.5)
sbcae:
	SEC				; prepare (2)
	BBR0 ccr68, sbcae_do	; skip if C clear ** Rockwell **
		CLC				; otherwise, set carry, opposite of 6502 (2)
sbcae_do:
	LDA ccr68		; get flags (3)
	AND #%11110000	; clear relevant bits (2)
	STA ccr68		; update (3)
	LDA a68			; get accumulator A
	SBC (tmptr)		; subtract with carry (5)
	STA a68			; update accumulator (3)
	JMP check_flags	; and exit (12/16/34)

_c2:
; SBC B imm (2)
; +
	_PC_ADV			; get operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA sbcbe		; continue as indirect addressing (3+)

_d2:
; SBC B dir (3)
; +
	_DIRECT			; get operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA sbcbe		; continue as indirect addressing (3+)

_e2:
; SBC B ind (5)
; +
	_INDEXED		; get operand (31/31.5)
	BRA sbcbe		; same (3+)

_f2:
; SBC B ext (4)
; +70/77/
	_EXTENDED		; get operand (31/31.5)
sbcbe:
	SEC				; prepare (2)
	BBR0 ccr68, sbcbe_do	; skip if C clear ** Rockwell **
		CLC				; otherwise, set carry, opposite of 6502 (2)
sbcbe_do:
	LDA ccr68		; get flags (3)
	AND #%11110000	; clear relevant bits (2)
	STA ccr68		; update (3)
	LDA b68			; get accumulator B (3)
	SBC (tmptr)		; subtract with carry (5)
	STA b68			; update accumulator (3)
	JMP check_flags	; and exit (12/16/34)

; transfer accumulator
_16:
; TAB (2)
; +20/22/24
	LDA ccr68		; get original flags (3)
	AND #%11110001	; reset N,Z, and always V (2)
	STA ccr68		; update status (3)
	LDA a68			; get A (3)
	JMP b_nz		; update B, check NZ and exit (12/14/23)

_17:
; TBA (2)
; +20/22/24
	LDA ccr68		; get original flags (3)
	AND #%11110001	; reset N,Z, and always V (2)
	STA ccr68		; update status (3)
	LDA b68			; get B (3)
	JMP a_nz		; update A, check NZ and exit (9/11/20)

; test for zero or minus
_4d:
; TST A (2)
; +17/19/21
	LDA ccr68		; get original flags (3)
	AND #%11110000	; reset relevant bits (2)
	STA ccr68		; update status (3)
	LDA a68			; check accumulator A (3)
	JMP check_nz	; (6/8/17)

_5d:
; TST B (2)
; +17/19/21
	LDA ccr68		; get original flags (3)
	AND #%11110000	; reset relevant bits (2)
	STA ccr68		; update status (3)
	LDA b68			; check accumulator B (3)
	JMP check_nz	; (6/8/17)

_6d:
; TST ind (7)
; +
	_INDEXED		; set pointer (31/31.5)
	BRA tste		; same (3+)

_7d:
; TST ext (6)
; +50/52.5/
	_EXTENDED		; set pointer (31/31.5)
tste:
	LDA ccr68		; get original flags (3)
	AND #%11110000	; reset relevant bits (2)
	STA ccr68		; update status (3)
	LDA (tmptr)		; check operand (5)
	JMP check_nz	; (6/8/17)

; ** index register and stack pointer ops **

; compare index
_8c:
; CPX imm (3)
; +
	_PC_ADV			; get first operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA cpxe		; continue as indirect addressing (3+)

_9c:
; CPX dir (4)
; +
	_DIRECT			; get operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA cpxe		; continue as indirect addressing (3+)

_ac:
; CPX ind (6)
; +
	_INDEXED		; get operand (31/31.5)
	BRA cpxe		; same (3+)

_bc:
; CPX ext (5)
; +82/88.5/
	_EXTENDED		; get operand (31/31.5)
cpxe:
	LDA ccr68		; get original flags (3)
	AND #%11110001	; reset relevant bits (2)
	STA ccr68		; update flags (3)
	SEC				; prepare (2)
	LDA x68 + 1		; MSB at X (3)
	SBC (tmptr)		; subtract memory (5)
	TAX				; keep for later (2)
	BPL cpxe_pl		; not negative (3/5...)
		SMB3 ccr68		; otherwise set N flag *** Rockwell ***
cpxe_pl:
	INC tmptr		; point to next byte (5)
	BNE cpxe_nw		; usually will not wrap (3...)
		LDA tmptr + 1	; get original MSB
		INC				; advance
		_AH_BOUND		; inject
		STA tmptr + 1	; restore
cpxe_nw:
	LDA x68			; LSB at X (3)
	SBC (tmptr)		; value LSB (5)
	STX tmptr		; retrieve old MSB (3)
	ORA tmptr		; blend with stored MSB (3)
	BNE cpxe_nz		; if zero... (3...)
		SMB2 ccr68		; set Z *** Rockwell ***
cpxe_nz:
	BVC cpxe_nv		; if overflow... (3/5...)
		SMB1 ccr68		; set V *** Rockwell ***
cpxe_nv:
	JMP next_op		; standard end

; decrement index
_09:
; DEX (4)
; +17/17/24
	LDA x68			; check LSB (3)
	BEQ dex_w		; if zero, will wrap upon decrease! (2)
		DEC x68			; otherwise just decrease LSB (5)
		BEQ dex_z		; if zero now, could be all zeroes! (2)
			RMB2 ccr68		; clear Z bit (5) *** Rockwell only! ***
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
	LDA sp68		; check older LSB (3)
	BEQ des_w		; will wrap upon decrease! (2)
		DEC sp68		; decrease LSB (5)
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
	INC x68		; increase LSB (5)
	BEQ inx_w	; wrap is a rare case (2)
		RMB2 ccr68	; clear Z bit (5) *** Rockwell only! ***
		JMP next_op	; usual end
inx_w:
	INC x68 + 1	; increase MSB
	BEQ inx_z	; becoming zero is even rarer!
		RMB2 ccr68	; clear Z bit *** Rockwell only! ***
		JMP next_op	; wrapped non-zero end
inx_z:
	SMB2 ccr68	; set Z bit *** Rockwell only! ***
	JMP next_op	; rarest end of routine

; increase stack pointer
_31:
; INS (4)
; +7/7/22
	INC sp68	; increase LSB (5)
	BEQ ins_w	; wrap is a rare case (2)
		JMP next_op	; usual end
ins_w:
	LDA sp68 + 1	; prepare to inject
	INC				; increase MSB
	_AH_BOUND		; keep injected
	STA sp68 + 1	; update pointer
	JMP next_op		; wrapped end

; load index
_ce:
; LDX imm (3)
; +
	_PC_ADV			; get first operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA ldxe		; continue as indirect addressing (3+)

_de:
; LDX dir (4)
; +
	_DIRECT			; get first operand pointer (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA ldxe		; continue as indirect addressing (3+)

_ee:
; LDX ind (6)
; +
	_INDEXED		; get operand address (31/31.5)
	BRA ldxe		; same (3+)

_fe:
; LDX ext (5)
; +72/76/
	_EXTENDED		; get operand address (31/31.5)
ldxe:
	LDA ccr68		; get original flags (3)
	AND #%11110001	; reset relevant bits (2)
	STA ccr68		; update flags (3)
	LDA (tmptr)		; value MSB (5)
	BPL ldxe_pl		; not negative (3/5...)
		SMB3 ccr68		; otherwise set N flag *** Rockwell ***
ldxe_pl:
	STA x68 + 1		; update register (3)
	INC tmptr		; go for next operand (5)
	BNE ldxe_nw		; rare wrap (3...)
		LDA tmptr+1		; get pointer MSB
		INC				; increment
		_AH_BOUND		; keep injected
		STA tmptr+1		; update pointer
ldxe_nw:
	LDA (tmptr)		; value LSB (5)
	STA x68			; register complete (3)
	ORA x68 + 1		; check for zero (3)
	BNE ldxe_nz		; was not zero (3...)
		SMB2 ccr68		; otherwise set Z *** Rockwell ***
ldxe_nz:
	JMP next_op		; standard end

; load stack pointer
_8e:
; LDS imm (3)
; +
	_PC_ADV			; get first operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc68 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA ldse		; continue as indirect addressing (3+)

_9e:
; LDS dir (4)
; +
	_DIRECT			; get operand address (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA ldse		; continue as indirect addressing (3+)

_ae:
; LDS ind (6)
; +
	_INDEXED		; get operand address (31/31.5)
	BRA ldse		; same (3+)

_be:
; LDS ext (5)
; +70/73/
	_EXTENDED		; get operand address (31/31.5)
ldse:
	LDA ccr68		; get original flags (3)
	AND #%11110001	; reset relevant bits -- Z always zero because of injection!
	STA ccr68		; update flags (3)
	LDA (tmptr)		; value MSB (5)
	BPL ldse_pl		; not negative (3/5...)
		SMB3 ccr68		; otherwise set N flag *** Rockwell ***
ldse_pl:
	_AH_BOUND		; keep injected (5/5.5)
	STA sp68 + 1	; update register (3)
	INC tmptr		; go for next operand (5)
	BEQ ldse_w		; rare wrap (2)
		LDA (tmptr)		; value LSB (5)
		STA sp68		; register complete (3)
;		ORA sp68 + 1	; check for zero
;		BNE ldse_nz		; was not zero
;			SMB2 ccr68		; otherwise set Z *** Rockwell ***
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
;		SMB2 ccr68		; otherwise set Z *** Rockwell ***
;ldse_wnz:
	JMP next_op		; standard end

; store index
_df:
; STX dir (5)
; +
	_DIRECT			; get first operand pointer (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA stxe		; continue as indirect addressing (3+)

_ef:
; STX ind (7)
; +
	_INDEXED		; get first operand pointer (31/31.5)
	BRA stxe		; same (3+)

_ff:
; STX ext (6)
; +72/76.5/
	_EXTENDED		; get first operand pointer (31/31.5)
stxe:
	LDA ccr68		; get original flags (3)
	AND #%11110001	; reset relevant bits (2)
	STA ccr68		; update flags (3)
	LDA x68 + 1		; value MSB (3)
	STA (tmptr)		; store it (5)
	BPL stxe_pl		; not negative (3/5...)
		SMB3 ccr68		; otherwise set N flag *** Rockwell ***
stxe_pl:
	INC tmptr		; go for next operand (5)
	BNE stxe_nw		; rare wrap (3...)
		LDA tmptr+1		; get pointer MSB
		INC				; increment
		_AH_BOUND		; keep injected
		STA tmptr+1		; update
stxe_nw:
	LDA x68			; value LSB (3)
	STA (tmptr)		; store in memory  (5)
	ORA x68 + 1		; check for zero (3)
	BNE stxe_nz		; was not zero (3...)
		SMB2 ccr68		; otherwise set Z *** Rockwell ***
stxe_nz:
	JMP next_op		; standard end

; store stack pointer
_9f:
; STS dir (5)
; +
	_DIRECT			; get operand address (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA stse		; continue as indirect addressing (3+)

_af:
; STS ind (7)
; +
	_INDEXED		; get operand address (31/31.5)
	BRA stse		; same (3+)

_bf:
; STS ext (6)
; +65/67.5/
	_EXTENDED		; get operand address (31/31.5)
stse:
	LDA ccr68		; get original flags (3)
	AND #%11110001	; reset relevant bits -- Z always zero because of injection! (2)
	STA ccr68		; update flags (3)
	LDA sp68 + 1	; value MSB (3)
	BPL stse_pl		; not negative (3/5...)
		SMB3 ccr68		; otherwise set N flag *** Rockwell ***
stse_pl:
	STA (tmptr)		; store in memory (5)
	INC tmptr		; go for next operand (5)
	BEQ stse_w		; rare wrap (2)
		LDA sp68		; value LSB (3)
		STA (tmptr)		; transfer complete (5)
;		ORA sp68 + 1	; check for zero
;		BNE stse_nz		; was not zero
;			SMB2 ccr68		; otherwise set Z *** Rockwell ***
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
;		SMB2 ccr68		; otherwise set Z *** Rockwell ***
;stse_wnz:
	JMP next_op		; standard end

; transfers between index and stack pointer 
_30:
; TSX (4)
; +16/16/25
	LDA sp68 + 1	; get stack pointer MSB, to be injected (3)
	LDX sp68		; get stack pointer LSB (3)
	INX				; point to last used!!! (2)
	STX x68			; store in X (3)
	BEQ tsx_w		; rare wrap (2)
tsx_do:
		STA x68 + 1		; pointer complete (3)
		JMP next_op		; standard end of routine
tsx_w:
	INC				; increase MSB
	_AH_BOUND		; inject
	STA x68 + 1		; pointer complete
	JMP next_op		; rarer end of routine

_35:
; TXS (4)
; +21/21/25
	LDA x68 + 1		; MSB will be injected (3)
	LDX x68			; check LSB (3)
	BEQ txs_w		; will wrap upon decrease (2)
		DEX				; as expected (2)
		STX sp68		; copy (3)
		_AH_BOUND		; always! (5/5.5)
		STA sp68 + 1	; pointer ready (3)
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
	_PC_ADV				; go for operand (5)
		BBS0 ccr68, bra_do	; either carry... *** Rockwell ***
		BBS2 ccr68, bra_do	; ...or zero will do *** Rockwell ***
	JMP next_op			; exit without branching

; branch if overflow clear
_28:
; BVC rel (4)
; +10/25/
	_PC_ADV				; go for operand (5)
		BBR1 ccr68, bra_do		; only if overflow clear *** Rockwell ***
	JMP next_op			; exit without branching

; branch if overflow set
_29:
; BVS rel (4)
; +10/25/
	_PC_ADV				; go for operand (5)
		BBS1 ccr68, bra_do	; only if overflow set *** Rockwell ***
	JMP next_op			; exit without branching

; branch if plus
_2a:
; BPL rel (4)
; +10/25/
	_PC_ADV				; go for operand (5)
		BBR3 ccr68, bra_do	; only if plus *** Rockwell ***
	JMP next_op			; exit without branching

; branch if minus
_2b:
; BMI rel (4)
; +10/25/
	_PC_ADV				; go for operand (5)
		BBS3 ccr68, bra_do	; only if negative *** Rockwell ***
	JMP next_op			; exit without branching

; branch always (used by other branches)
_20:
; BRA rel (4)
; -5 +25/32/
	_PC_ADV			; go for operand (5)
bra_do:				; +// from here
	SEC				; base offset is after the instruction (2)
	LDA (pc68), Y	; check direction (5)
	BMI bra_bk		; backwards jump
		TYA				; get current pc low (2)
		ADC (pc68), Y	; add offset (5)
		TAY				; new offset!!! (2)
		BCS bra_bc		; same msb, go away
bra_go:
			JMP execute		; resume execution
bra_bc:
		INC pc68 + 1	; carry on msb (5)
		BPL bra_lf		; skip if in low area
			RMB6 pc68+1		; otherwise clear A14 (5) *** Rockwell ***
			JMP execute		; and jump
bra_lf:
		SMB6 pc68+1			; low area needs A14 set (5) *** Rockwell ***
		JMP execute
bra_bk:
	TYA				; get current pc low (2)
	ADC (pc68), Y	; "subtract" offset (5)
	TAY				; new offset!!! (2)
		BCS bra_go		; all done
	DEC pc68 + 1	; borrow on msb (5)
		BPL bra_lf		; skip if in low area
 	RMB6 pc68+1		; otherwise clear A14 (5) *** Rockwell ***
	JMP execute		; and jump

; branch if carry clear
_24:
; BCC rel (4)
; +10/25/
	_PC_ADV				; go for operand (5)
		BBR0 ccr68, bra_do	; only if carry clear *** Rockwell ***
	JMP next_op			; exit without branching otherwise

; branch if carry set
_25:
; BCS rel (4)
; +10/25/
	_PC_ADV				; go for operand (5)
		BBS0 ccr68, bra_do	; only if carry set *** Rockwell ***
	JMP next_op			; exit without branching

; branch if not equal
_26:
; BNE rel (4)
; +10/25/
	_PC_ADV				; go for operand (5)
		BBR2 ccr68, bra_do	; only if zero clear *** Rockwell ***
	JMP next_op			; exit without branching

; branch if equal zero
_27:
; BEQ rel (4)
; +10/25/
	_PC_ADV				; go for operand (5)
		BBS2 ccr68, bra_do	; only if zero set *** Rockwell ***
	JMP next_op			; exit without branching

; branch if greater or equal (signed)
_2c:
; BGE rel (4)
; +17/34/
	_PC_ADV			; go for operand (5)
	LDA ccr68		; get flags (3)
	BIT #%00000010	; check V (2)
	BEQ bge_nx		; do not XOR N if clear
		EOR #%00001000	; toggle N (2)
bge_nx:
	AND #%00001010	; filter N and V only (2)
		BEQ branch		; branch if N XOR V is zero (2)
	JMP next_op		; exit without branching

; branch if less than (signed)
_2d:
; BLT rel (4)
; +17/34/
	_PC_ADV			; go for operand (5)
	LDA ccr68		; get flags (3)
	BIT #%00000010	; check V (2)
	BEQ blt_nx		; do not XOR N if clear
		EOR #%00001000	; toggle N (2)
blt_nx:
	AND #%00001010	; filter N and V only (2)
		BNE branch		; branch if N XOR V is true
	JMP next_op		; exit without branching

; branch if greater (signed)
_2e:
; BGT rel (4)
; +17/34/
	_PC_ADV			; go for operand (5)
	LDA ccr68		; get flags (3)
	BIT #%00000010	; check V (2)
	BEQ bgt_nx		; do not XOR N if clear
		EOR #%00001000	; toggle N (2)
bgt_nx:
	AND #%00001110	; filter Z, N and V (2)
		BEQ branch		; only if N XOR V (OR Z) is false
	JMP next_op		; exit without branching

; branch if less or equal (signed)
_2f:
; BLE rel (4)
; +17/34/
	_PC_ADV			; go for operand (5)
	LDA ccr68		; get flags (3)
	BIT #%00000010	; check V (2)
	BEQ ble_nx		; do not XOR N if clear
		EOR #%00001000	; toggle N (2)
ble_nx:
	AND #%00001110	; filter Z, N and V (2)
		BNE branch		; only if N XOR V (OR Z) is true
br_exit:
	JMP next_op		; exit without branching (reused)

; branch if higher
_22:
; BHI rel (4)
; +11/29/
	_PC_ADV			; go for operand (5)
		BBS0 ccr68, br_exit	; neither carry... *** Rockwell ***
		BBS2 ccr68, br_exit	; ...nor zero (reuse is OK) *** Rockwell ***
branch:
	JMP bra_do		; continue as usual (3+)

; branch to subroutine
_8d:
; BSR rel (8)
; +
	_PC_ADV			; go for operand (5)
; * push return address *
	TYA				; get current PC-LSB minus one (2)
	SEC				; return to next byte! (2)
	ADC #0			; will set carry if wrapped! (2)
	STA (sp68)		; stack LSB first (5)
	DEC sp68		; decrement SP (5)
	BNE bsr_phi		; no wrap, just push MSB (3...)
		LDA sp68 + 1	; get SP MSB
		DEC				; previous page
		_AH_BOUND		; inject
		STA sp68 + 1	; update pointer
bsr_phi:
	LDA pc68+1		; get current MSB (3)
	ADC #0			; take previous carry! (2)
	_AH_BOUND		; just in case (5/5.5)
	STA (sp68)		; push it! (5)
	DEC sp68		; update SP (5)
	BNE branch		; no wrap, ready to go! (3...)
		LDA sp68 + 1	; get SP MSB
		DEC				; previous page (2)
		_AH_BOUND		; inject
		STA sp68 + 1	; update pointer
	JMP bra_do		; do branch

; jump (and to subroutines)

_ad:
; JSR ind (8) *** ESSENTIAL for minimOS·63 kernel calling ***
; -5 +
	_PC_ADV			; point to offset (5)
; * push return address *
	TYA				; get current PC-LSB minus one (2)
	SEC				; return to next byte! (2)
	ADC #0			; will set carry if wrapped! (2)
	STA (sp68)		; stack LSB first (5)
	DEC sp68		; decrement SP (5)
	BNE jsri_phi		; no wrap, just push MSB (3...)
		LDA sp68 + 1	; get SP MSB
		DEC				; previous page
		_AH_BOUND		; inject
		STA sp68 + 1	; update pointer
jsri_phi:
	LDA pc68+1		; get current MSB (3)
	ADC #0			; take previous carry! (2)
	_AH_BOUND		; just in case (5/5.5)
	STA (sp68)		; push it! (5)
	DEC sp68		; update SP (5)
	BNE jmpi		; no wrap, ready to go! (3+)
		LDA sp68 + 1	; get SP MSB
		DEC				; previous page
		_AH_BOUND		; inject
		STA sp68 + 1	; update pointer
	BRA jmpi		; compute address and jump

_6e:
; JMP ind (4)
; -5+30...
	_PC_ADV			; get operand (5)
jmpi:
	LDA (pc68), Y	; set offset (5)
	CLC				; prepare (2)
	ADC x68			; add LSB (3)
	TAY				; this is new offset! (2)
	LDA x68 + 1		; get MSB (3)
	ADC #0			; propagate carry (2)
	_AH_BOUND		; stay injected (5/5.5)
	STA pc68 + 1	; update pointer (3)
	JMP execute		; do jump

_bd:
; JSR ext (9)
; -5 +
	_PC_ADV			; point to operand MSB (5)
; * push return address *
	TYA				; get current PC-LSB minus one (2)
	SEC				; return to next byte! (2)
	ADC #0			; will set carry if wrapped! (2)
	STA (sp68)		; stack LSB first (5)
	DEC sp68		; decrement SP (5)
	BNE jsre_phi		; no wrap, just push MSB (3...)
		LDA sp68 + 1	; get SP MSB
		DEC				; previous page
		_AH_BOUND		; inject
		STA sp68 + 1	; update pointer
jsre_phi:
	LDA pc68+1		; get current MSB (3)
	ADC #0			; take previous carry! (2)
	_AH_BOUND		; just in case (5/5.5)
	STA (sp68)		; push it! (5)
	DEC sp68		; update SP (5)
	BNE jmpe		; no wrap, ready to go! (3+)
		LDA sp68 + 1	; get SP MSB
		DEC				; previous page
		_AH_BOUND		; inject
		STA sp68 + 1	; update pointer
	BRA jmpe		; compute address and jump

_7e:
; JMP ext (3)
; -5 +
	_PC_ADV			; go for destination MSB (5)
jmpe:
	LDA (pc68), Y	; get it (5)
	_AH_BOUND		; check against emulated limits (5/5.5)
	TAX				; hold it for a moment (2)
	_PC_ADV			; now for the LSB (5)
	LDA (pc68), Y	; get it (5)
	TAY				; this works as index (2)
	STX pc68 + 1	; MSB goes into register area (3)
	JMP execute		; all done

; return from subroutine
_39:
; RTS (5)
; +
	LDX #1			; just the return address MSB to pull (2)
	BRA return68	; generic procedure (3+)

; return from interrupt
_3b:
; RTI (10)
; -5 +139/139/
	LDX #7			; bytes into stack frame (4 up here) (2)
return68:			; ** generic entry point, X = bytes to be pulled **
	STX tmptr		; store for later subtraction (3)
	LDY #1			; forget PC MSB, index for pulling from stack (2)
rti_loop:
		LDA (sp68), Y	; pull from stack (5x)
		STA pc68, X		; store into register area (3x)
		INY				; (pre)increment (2x)
		DEX				; go backwards (2x)
		BNE rti_loop	; zero NOT included (3x -1)
	LDA (sp68), Y	; last byte in frame is LSB (5)
	TAX				; store for later (2)
	LDA sp68		; correct stack pointer (3)
	CLC				; prepare (2)
	ADC tmptr		; release space (3)
	STA sp68		; update LSB (3)
	BCC rti_nw		; skip if did not wrap (3...)
		LDA sp68+1		; not just INC zp...
		INC				; next page
		_AH_BOUND		; ...must be kept injected
		STA sp68+1		; update MSB when needed
rti_nw:
	TXA				; get older LSB (2)
	TAY				; and make it effective! (2)
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
	_PC_ADV			; skip opcode (5)
	LDX #2			; SWI vector offset (2)
	JMP intr68		; generic interrupt handler (3+)

; ** status register opcodes **

; clear overflow
_0a:
; CLV (2)
; +5
	RMB1 ccr68	; clear V bit (5) *** Rockwell only! ***
	JMP next_op	; standard end of routine

; set overflow
_0b:
; SEV (2)
; +5
	SMB1 ccr68	; set V bit (5) *** Rockwell only! ***
	JMP next_op	; standard end of routine

; clear carry
_0c:
; CLC (2)
; +5
	RMB0 ccr68	; clear C bit (5) *** Rockwell only! ***
	JMP next_op	; standard end of routine

; set carry
_0d:
; SEC (2)
; +5
	SMB0 ccr68	; set C bit (5) *** Rockwell only! ***
	JMP next_op	; standard end of routine

; clear interrupt mask
_0e:
; CLI (2)
; +5
	RMB4 ccr68	; clear I bit (5) *** Rockwell only! ***
	JMP next_op	; standard end of routine

; set interrupt mask
_0f:
; SEI (2)
; +5
	SMB4 ccr68	; set I bit (5) *** Rockwell only! ***
	JMP next_op	; standard end of routine

; transfers between CCR and accumulator A
_06:
; TAP (2)
; +6
	LDA a68		; get A accumulator... (3)
	STA ccr68	; ...and store it in CCR (3)
	JMP next_op	; standard end of routine

_07:
; TPA (2)
; +6
	LDA ccr68	; get CCR... (3)
	STA a68		; ...and store it in A (3)
	JMP next_op	; standard end of routine

; *** opcode execution addresses table ***
; should stay no matter the CPU!
opt_l:
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
opt_h:
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
