; VirtualDurango emulator for DurangoPLUS! *** COMPACT VERSION ***
; v0.1a1
; (c) 2016-2024 Carlos J. Santisteban
; last modified 20241010-1526
; needs at least 128K RAM

; ** some useful macros **
; these make listings more succint

; inject address MSB into 16+16K space (5/5.5/6)
;#define	_AH_BOUND	AND #hi_mask: BMI *+4: ORA #lo_mask
; increase Y checking injected boundary crossing (5/5/30) ** new compact version
#define	_PC_ADV		INY: BNE *+5: INC pc65 + 1
; compute pointer for indexed addressing mode (31/31.5/)
;#define	_INDEXED	_PC_ADV: LDA (pc65), Y: CLC: ADC x65: STA tmptr: LDA x65+1: ADC #0: _AH_BOUND: STA tmptr+1
; compute pointer for extended addressing mode (31/31.5/)
;#define	_EXTENDED	_PC_ADV: LDA (pc65), Y: _AH_BOUND: STA tmptr+1: _PC_ADV: LDA (pc65), Y: STA tmptr
; compute pointer (as A index) for zeropage addressing mode (10/10/)
;#define	_ZP		_PC_ADV: LDA (pc65), Y

; check Z & N flags (6/8/10) will not set both bits at once!
;#define _CC_NZ		BNE *+4: SMB2 ccr65: BPL *+4: SMB3 ccr65

; *** some constants ***
#define	N_FLAG	%10110000
#define	V_FLAG	%01110000
; note there's no B flag, IRQ will actually set it low, otherwise is high
#define	D_FLAG	%00111000
#define	I_FLAG	%00110100
#define	Z_FLAG	%00110010
#define	C_FLAG	%00110001

#define	N_MASK	%01111111
#define	V_MASK	%10111111
#define	B_MASK	%11101111
#define	D_MASK	%11110111
#define	I_MASK	%11111011
#define	Z_MASK	%11111101
#define	C_MASK	%11111110

; vector offsets from $FFFA
#define	NMI_VEC	0
#define	RST_VEC	2
#define	IRQ_VEC	4

; *** hardware definitions ***
IOAie	=	$DFA0

; *** declare zeropage addresses ***
; ** 'uz' is first available zeropage address (currently $03 in minimOS) **
tmptr	=	uz				; temporary storage (up to 16 bit, little endian)
sp65	=	tmptr+2			; stack pointer (8-bit emulated, 16-bit for access, assume $01xx)
ccr65	=	sp65+2			; status register (8 bit) same as stacking order
pc65	=	ccr65+1			; program counter (16 bit, little-endian)
x65		=	pc65+2			; index register X (8 bit)
y65		=	x65+1			; index register Y (8 bit)
a65		=	y65+1			; accumulator (8 bit)
temp	=	a65+1			; generic temporary

; *** minimOS executable header will go here ***
*	= $8000					; DurangoPLUS ROMs are 32K banks
; *** *** standard header *** ***
rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"virtuaDurango", 0					; C-string with filename @ [8], max 238 chars
	.asc	"for DurangoPLUS with 128K+ RAM"	; optional comment
	.byt	0				; second terminator for optional comment, just in case

; advance to end of header *** NEW format
	.dsb	rom_start + $E6 - *, $FF

; NEW library commit (user field 2)
	.asc	"$$$$$$$$"
; NEW main commit (user field 1)
	.asc	"$$$$$$$$"
; NEW coded version number
	.word	$0101			; 0.1a1		%vvvvrrrrsshhbbbb, where revision = %hhrrrr, ss = %00 (alpha), %01 (beta), %10 (RC), %11 (final)
; date & time in MS-DOS format at byte 248 ($F8)
	.word	$9400			; time, 18.32		%1001 0-100 000-0 0000
	.word	$5949			; date, 2024/10/9	%0101 100-1 010-0 1001
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start			; filesize (rom_end is actually $10000)
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number

; ********************************************
; *** standard init, note 65C816 specifics ***
; ********************************************
reset:
	SEI
	CLD						; just in case, a must for NMOS (2)
; reset the 65816 to emulation mode, just in case
	SEC						; would set back emulation mode on C816
	XCE						; XCE on 816, NOP on C02, but illegal 'ISC $0005, Y' on NMOS!
	ORA 0					; the above would increment some random address in zeropage (NMOS) but this one is inocuous on all CMOS
; now we are surely into emulation mode, initialise basic stack at $1FF
	LDX #$FF				; initial stack pointer, must be done in emulation for '816 (2)
	TXS						; initialise stack (2)
	STX IOAie				; * turn off error LED *
; look for 65C816 presence, or nothing!
; derived from the work of David Empson, Oct. '94
	CLD
	LDA #$99				; load highest BCD number (sets N too)
	CLC						; prepare to add
	ADC #$02				; will wrap around in Decimal mode (should clear N)
	CLD						; back to binary
	BMI cpu_bad				; NMOS, N flag not affected by decimal add
		TAY					; let us preload Y with 1 from above
		LDX #$00			; sets Z temporarily
		TYX					; TYX, 65802 instruction will clear Z, NOP on all 65C02s will not
	BNE cpu_OK				; Branch only on 65802/816
cpu_bad:
				INX
				BNE cpu_bad
			INY
			BNE cpu_bad		; usual delay cycle
		INC
		STA IOAie			; toggle error LED
		JMP cpu_bad			; for utmost safety!
cpu_OK:
; *** set back to native 816 mode ***
; it can be assumed 65816 from this point on
	CLC						; set NATIVE mode eeeeeeeeeeek
	XCE						; still with 8-bit registers
; seems I really need to (re)set DP if rebooting
	PHK						; stack two zeroes
	PHK
	PLD						; simpler than TCD et al

; assume cartridge is copied into $18000-$1FFFF

; ****************************
; *** start the emulation! ***
; ****************************
reset65:
	LDA #1					; this will make (sp) point to $101ss
	PHA
	PLB						; set this bank value, also bank for PC
	STA sp65+1				; pointer is ready
	STZ pc65				; allow Y-indexed reads
	LDX #RST_VEC			; offset for reset
	BRA vector_pull			; generic startup!

; *** main loop ***
execute:
		LDA (pc65), Y		; get opcode (5)
		ASL					; double it as will become pointer (2)
		TAX					; use as pointer, keeping carry (2)
		BCC lo_jump			; opcodes with bit7 low seem to be less frequent... (2/3)
			JMP (opt_h, X)	; emulation routines for opcodes with bit7 hi (6)
lo_jump:
			JMP (opt_l, X)	; otherwise, emulation routines for opcodes with bit7 low
; *** NOP (2) arrives here, saving 3 bytes and 3 cycles ***
_EA:
; CMOS disabled opcodes will execute like NOP as well (including WDC's)
_02:_03:_0B:_13:_1B:_22:_23:_2B:_33:_3B:_42:_43:_4B:_53:_5B:_62:_63:_6B:_73:_7B:
_82:_83:_8B:_93:_9B:_A2:_A3:_AB:_B3:_BB:_C2:_C3:_CB:_D3:_DB:_E2:_E3:_EB:_F3:_FB:

#ifndef	ROCKWELL
_07:_0F:_17:_1F:_27:_2F:_37:_3F:_47:_4F:_57:_5F:_67:_6F:_77:_7F:
_87:_8F:_97:_9F:_A7:_AF:_B7:_BF:_C7:_CF:_D7:_DF:_E7:_EF:_F7:_FF:
#endif
; continue execution via JMP next_op, will not arrive here otherwise
next_op:
		INY					; advance one byte (2)
		BNE execute			; fetch next instruction if no boundary is crossed (3/2)
; boundary crossing, simplified version
	INC pc65 + 1			; increase MSB otherwise, faster than using 'that macro' (5)
		BNE execute			; seems to stay in a feasible area (3/2)
	BRK						; ** otherwise is a strange ROM overrun ** TBD

; *** opcode execution routines, labels must match those on tables below ***
; illegal opcodes will seem to trigger an interupt (?) CHECK
	_PC_ADV					; skip illegal opcode (5)
nmi65:						; hardware interrupts, when available, to be checked AFTER incrementing PC
	LDX #NMI_VEC			; offset for NMI vector (2)

intr65:						; ** generic interrupt entry point, offset in X **
; save processor status, new way (26b, 41t)
	LDX sp65				; current SP, pointing to first free byte in stack (3)
	LDA pc65 +1				; get PCH (3)
	STA $0100, X			; push it within bank 1 (5)
	DEX						; post-decrement (2)
	LDA pc65				; get PCL (3)
	STA $0100, X			; push it (5)
	DEX						; post-decrement (2)
	LDA ccr65 +1			; get PSR (3)
	STA $0100, X			; push it (5)
	ORA #B_FLAG				; current PSR has always B flag set (2)
	STA ccr65				; update status (3)
	DEX						; post-decrement to free byte (2)
	STX sp65				; update SP (3)
vector_pull:				; ** standard vector pull entry point, offset in X **
	LDA #I_FLAG
	TSB ccr65				; mask interrupts! (2+5)
	LDY $FFFA, X			; get LSB from emulated vector, bank already set (5)
	LDA $FFFB, X			; get MSB (5)
	STA pc65 + 1			; update PC (3)
	BRA execute				; continue with NMI handler

; ********************************
; *** valid opcode definitions ***
; ********************************

; *** common endings ***
; update indirect pointer and check NZ
ind_nz:
	STA (tmptr)				; store at pointed address
	BRA check_nz			; check flags and exit

; update A and check N & Z bits +21
a_nz:
	STA a65					; update accumulator A
; just check N & Z, then exit +18
check_nz:
; LUT approach for N & Z flags (10b, 15t, was 14b 23t)
	TAX						; use A as index (2)
x2nz:						; +16 from here, assume X loaded
	LDA ccr65				; check previous state (3)
	AND #N_MASK&Z_MASK		; clear just N & Z... (2)
	ORA nz_lut, X			; ...and set accordingly (4)
	STA ccr65				; update P (3)
	BRA next_op

; check V & C bits, then N & Z +26
check_flags:
	PHP						; get current status (3+4)
	PLA
	AND #C_FLAG|V_FLAG|N_FLAG|Z_FLAG	; keep relevant flags (2)
	STA temp							; store flags to be set (3)
	LDA #C_MASK&V_MASK&N_MASK&Z_MASK	; relevant bits (2)
	AND ccr65				; clear bits by default on previous CCR (3)
	ORA temp				; set where needed (3)
	STA ccr65				; update CCR (3)
	BRA next_op

; *** implicit instructions ***

; * flag settings *
_18:
; CLC (2) +10
	LDA #C_FLAG				; C flag...
	TRB ccr65				; gets cleared
	JMP next_op

_D8:
; CLD (2) +10
	LDA #D_FLAG				; D flag...
	TRB ccr65				; gets cleared
	JMP next_op

_58:
; CLI (2) +10
	LDA #I_FLAG				; I flag...
	TRB ccr65				; gets cleared
	JMP next_op

_B8:
; CLV (2) +10
	LDA #V_FLAG				; V flag...
	TRB ccr65				; gets cleared
	JMP next_op

_38:
; SEC (2) +10
	LDA #C_FLAG				; C flag...
	TSB ccr65				; gets set
	JMP next_op

_F8:
; SED (2) +10
	LDA #D_FLAG				; D flag...
	TSB ccr65				; gets set
	JMP next_op

_78:
; SEI (2) +10
	LDA #I_FLAG				; I flag...
	TSB ccr65				; gets set
	JMP next_op

; * register inc/dec *
_CA:
; DEX (2) +27
	DEC x65					; decrement index (5)
; LUT-based flag setting
	LDX x65					; check result (3)
	JMP x2nz				; 3+16

_88:
; DEY (2) +27
	DEC y65					; decrement index (5)
; LUT-based flag setting
	LDX y65					; check result (3)
	JMP x2nz				; 3+16

_E8:
; INX (2) +27
	INC x65					; increment index (5)
; LUT-based flag setting
	LDX x65					; check result (3)
	JMP x2nz				; 3+16

_C8:
; INY (2) +27
	INC y65					; increment index (5)
; LUT-based flag setting
	LDX y65					; check result (3)
	JMP x2nz				; 3+16

_3A:
; DEC [DEC A] (2) +27
	DEC a65					; decrement A
; LUT-based flag setting
	LDX a65					; check result
	JMP x2nz				; 3+16

_1A:
; INC [INC A] (2) +27
	INC a65					; increment A
; LUT-based flag setting
	LDX a65					; check result
	JMP x2nz				; 3+16

; * register transfer *
_AA:
; TAX (2) +25
	LDX a65					; copy accumulator... (3)
	STX x65					; ...to index X (3)
	JMP x2nz				; ...and update flags 3+16

_A8:
; TAY (2) +25
	LDX a65					; copy accumulator... (3)
	STX y65					; ...to index Y, value in X (3)
	JMP x2nz				; ...and update flags 3+16

_BA:
; TSX (2) +25
	LDX sp65				; copy stack pointer... (3)
	STX x65					; ...to index X (3)
	JMP x2nz				; ...and update flags 3+16

_8A:
; TXA (2) +25
	LDX x65					; copy X... (3)
	STX a65					; ...to accumulator, value in X (3)
	JMP x2nz				; ...and update flags 3+16

_9A:
; TXS (2) +25
	LDX x65					; copy X... (3)
	STX sp65				; ...to stack pointer, value in X (3)
	JMP x2nz				; ...and update flags 3+16

_98:
; TYA (2) +25
	LDX y65					; copy Y... (3)
	STX a65					; ...to accumulator, value in X (3)
	JMP x2nz				; ...and update flags 3+16

; *** stack operations ***  CONTINUE HERE * * * * * * * *

; * push *
_48:
; PHA
; +18
	LDA a65		; get accumulator
; standard push of value in A, does not affect flags
; new code, same speed but 1 byte less
	LDX s65		; and current SP
	STA $0100, X	; push into stack
	DEC s65		; post-decrement
; all done
	JMP next_op

_DA:
; PHX
; +18
	LDA x65		; get index
; standard push of value in A, does not affect flags
; new code, same speed but 1 byte less
	LDX s65		; and current SP
	STA $0100, X	; push into stack
	DEC s65		; post-decrement
; all done
	JMP next_op

_5A:
; PHY
; +18
	LDA y65		; get index
; standard push of value in A, does not affect flags
; new code, same speed but 1 byte less
	LDX s65		; and current SP
	STA $0100, X	; push into stack
	DEC s65		; post-decrement
; all done
	JMP next_op

_08:
; PHP
; +18
	LDA ccr65		; get status
; standard push of value in A, does not affect flags
; new code, same speed but 1 byte less
	LDX s65		; and current SP
	STA $0100, X	; push into stack
	DEC s65		; post-decrement
; all done
	JMP next_op

; * pull *

_68:
; PLA
; +32
	INC s65		; pre-increment SP
	LDX s65		; use as index
	LDA $0100, X	; pull from stack
	STA a65		; pulled value goes to A
	TAX		; operation result in X
; standard NZ flag setting
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_FA:
; PLX
; +32
	INC s65		; pre-increment SP
	LDX s65		; use as index
	LDA $0100, X	; pull from stack
	STA x65		; pulled value goes to X
	TAX		; operation result in X
; standard NZ flag setting
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_7A:
; PLY
; +32
	INC s65		; pre-increment SP
	LDX s65		; use as index
	LDA $0100, X	; pull from stack
	STA y65		; pulled value goes to Y
	TAX		; operation result in X
; standard NZ flag setting
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_28:
; PLP
; +32
	INC s65		; pre-increment SP
	LDX s65		; use as index
	LDA $0100, X	; pull from stack
	STA ccr65		; pulled value goes to PSR
	TAX		; operation result in X
; standard NZ flag setting
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

; * return instructions *

_40:
; RTI
; +34
	LDX s65		; get current SP
	INX		; pre-increment
	LDA $0100, X	; pull from stack
	STA ccr65		; pulled value goes to PSR
	INX		; pre-increment
	LDY $0100, X	; pull from stack PC-LSB eeeeeeek
	INX		; pre-increment
	LDA $0100, X	; pull from stack
	STA pc65+1	; pulled value goes to PC-MSB
	STX s65		; update SP
; all done
	JMP execute	; PC already set!

_60:
; RTS
; +29
	LDX s65		; get current SP
	INX		; pre-increment
	.al: REP #$20	; worth going 16-bit
	LDA $0100, X	; pull full return address from stack
	INC		; correct it!
	.as: SEP #$20	; back to 8-bit
	TAY		; eeeeeeeeeeek
	XBA		; LSB done, now for MSB
	STA pc65+1	; pulled value goes to PC
	INX		; skip both bytes
	STX s65		; update SP
; all done
	JMP execute	; PC already set!

; *** WDC-exclusive instructions ***

;_db:
; STP
; should print some results or message...

;_cb:
; WAI

; *** bit testing ***

_89:
; BIT imm
; +25/25/30
	_PC_ADV		; get immediate operand
	LDA (pc65), Y
	AND a65		; AND with memory
	BEQ g89z	; will set Z
		LDA #2		; or clear Z in previous status
		TRB ccr65		; updated
		JMP next_op
g89z:
	LDA #2		; set Z in previous status
	TSB ccr65		; updated
; all done
	JMP next_op

_24:
; BIT zp
; +50/50/56
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
; operand in A, common BIT routine (34/34/36)
	AND a65		; AND with memory
	TAX		; keep this value
	BNE g24z	; will clear Z
		LDA #2		; or set Z in previous status
		TSB ccr65		; updated
		JMP g24nv	; check highest bits
g24z:
	LDA #2		; clear Z in previous status
	TRB ccr65		; updated
g24nv:
	LDA #$C0	; pre-clear NV
	TRB ccr65
	TXA		; retrieve old result
	AND #$C0	; only two highest bits
	TSB ccr65		; final status
; all done
	JMP next_op

_34:
; BIT zp, X
; +55/55/61
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
; operand in A, common BIT routine
	AND a65		; AND with memory
	TAX		; keep this value
	BNE g34z	; will clear Z
		LDA #2		; or set Z in previous status
		TSB ccr65		; updated
		JMP g34nv	; check highest bits
g34z:
	LDA #2		; clear Z in previous status
	TRB ccr65		; updated
g34nv:
	LDA #$C0	; pre-clear NV
	TRB ccr65
	TXA		; retrieve old result
	AND #$C0	; only two highest bits
	TSB ccr65		; final status
; all done
	JMP next_op

_2C:
; BIT abs
; +65/65/75
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; get operand
; operand in A, common BIT routine
	AND a65		; AND with memory
	TAX		; keep this value
	BNE g2cz		; will clear Z
		LDA #2		; or set Z in previous status
		TSB ccr65		; updated
		JMP g2cnv	; check highest bits
g2cz:
	LDA #2		; clear Z in previous status
	TRB ccr65		; updated
g2cnv:
	LDA #$C0	; pre-clear NV
	TRB ccr65
	TXA		; retrieve old result
	AND #$C0	; only two highest bits
	TSB ccr65		; final status
; all done
	JMP next_op

_3C:
; BIT abs, X
; +72/72/82
	_PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC x65
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; get operand
; operand in A, common BIT routine
	AND a65		; AND with memory
	TAX		; keep this value
	BNE g3cz	; will reset Z
		LDA #2		; or set Z in previous status
		TSB ccr65		; updated
		JMP g3cnv	; check highest bits
g3cz:
	LDA #2		; set Z in previous status
	TRB ccr65		; updated
g3cnv:
	LDA #$C0	; pre-clear NV
	TRB ccr65
	TXA		; retrieve old result
	AND #$C0	; only two highest bits
	TSB ccr65		; final status
; all done
	JMP next_op

; *** jumps ***

; * conditional branches *

_90:
; BCC rel
; +16/16/20 if not taken
; +// * if taken
	_PC_ADV		; PREPARE relative address
	LDA #1		; will check C flag
	BIT ccr65
	BNE g90		; will not branch
		LDA (pc65), Y
; *** to do *** to do *** to do *** to do ***
		JMP execute	; PC is ready!
g90:
	JMP next_op

_B0:
; BCS rel
; +16/16/20 if not taken
; +// * if taken
	_PC_ADV		; PREPARE relative address
	LDA #1		; will check C flag
	BIT ccr65
	BEQ gb0		; will not branch
		LDA (pc65), Y
; *** to do *** to do *** to do *** to do ***
		JMP execute	; PC is ready!
gb0:
	JMP next_op

_30:
; BMI rel
; +16/16/20 if not taken
; +// * if taken
	_PC_ADV		; PREPARE relative address
	LDA #128	; will check N flag
	BIT ccr65
	BEQ g30		; will not branch
		LDA (pc65), Y
; *** to do *** to do *** to do *** to do ***
		JMP execute	; PC is ready!
g30:
	JMP next_op

_10:
; BPL rel
; +16/16/20 if not taken
; +// * if taken
	_PC_ADV		; PREPARE relative address
	LDA #128	; will check N flag
	BIT ccr65
	BNE g10		; will not branch
		LDA (pc65), Y
; *** to do *** to do *** to do *** to do ***
		JMP execute	; PC is ready!
g10:
	JMP next_op

_F0:
; BEQ rel
; +16/16/20 if not taken
; +// * if taken
	_PC_ADV		; PREPARE relative address
	LDA #2		; will check Z flag
	BIT ccr65
	BEQ gf0		; will not branch
		LDA (pc65), Y
; *** to do *** to do *** to do *** to do ***
		JMP execute	; PC is ready!
gf0:
	JMP next_op

_D0:
; BNE rel
; +16/16/20 if not taken
; +// * if taken
	_PC_ADV		; PREPARE relative address
	LDA #2		; will check Z flag
	BIT ccr65
	BNE gd0		; will not branch
		LDA (pc65), Y
; *** to do *** to do *** to do *** to do ***
		JMP execute	; PC is ready!
gd0:
	JMP next_op

_50:
; BVC rel
; +16/16/20 if not taken
; +// * if taken
	_PC_ADV		; PREPARE relative address
	LDA #64		; will check V flag
	BIT ccr65
	BNE g50		; will not branch
		LDA (pc65), Y
; *** to do *** to do *** to do *** to do ***
		JMP execute	; PC is ready!
g50:
	JMP next_op

_70:
; BVS rel
; +16/16/20 if not taken
; +// * if taken
	_PC_ADV		; PREPARE relative address
	LDA #64		; will check V flag
	BIT ccr65
	BNE g70		; will not branch
		LDA (pc65), Y
; *** to do *** to do *** to do *** to do ***
		JMP execute	; PC is ready!
g70:
	JMP next_op

_80:
; BRA rel
; +// *
	_PC_ADV		; get relative address
	LDA (pc65), Y
; *** to do *** to do *** to do *** to do ***
	JMP execute	; PC is ready!

; * absolute jumps *

_4C:
; JMP abs
; +30/30/38*
	_PC_ADV		; get LSB
	LDA (pc65), Y
	TAX		; store temporarily
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA pc65+1	; update PC
	TXY		; pointer is ready!
	JMP execute

_6C:
; JMP indirect
; +46/46/54*
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store temporarily
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; indirect pointer ready
	LDY #1		; indirect MSB offset
	LDA (tmptr), Y	; final MSB
	STA pc65+1
	LDA (tmptr)	; final LSB
	TAY		; pointer is ready!
	JMP execute

_7C:
; JMP indirect indexed
; +51/51/59*
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store temporarily
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; indirect pointer ready
	LDY x65		; indexing
	INY		; but get MSB first
	LDA (tmptr), Y	; final MSB
 	STA pc65+1
	DEY		; go for LSB
	LDA (tmptr), Y	; final LSB
	TAY		; pointer is ready!
	JMP execute

; * subroutine call *

_20:
; JSR abs
; +63/63/71*
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store temporarily
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; destination ready
; now push the CURRENT address as we are at the last byte of the instruction
	TYX			; eeeeeeeeek
	LDA pc65+1		; get PC MSB...
	LDY s65			; and current SP
	STA $0100, Y		; store in emulated stack
	DEY			; post-decrement
	TXA			; same for LSB eeeeeeeeek!
	STA $0100, Y		; store in emulated stack
	DEY			; post-decrement
	STY s65			; update SP
; jump to previously computed address
	LDA tmptr+1	; retrieve MSB
	STA pc65+1
	LDY tmptr	; pointer is ready!
	JMP execute

; *** load / store ***

; * load *

_A2:
; LDX imm
; +30/30/34
	_PC_ADV		; get immediate operand
	LDA (pc65), Y
	STA x65		; update register
; standard NZ flag setting (+17)
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_A6:
; LDX zp
; +36/36/40
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA x65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_B6:
; LDX zp, Y
; +41/41/45
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC y65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA x65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_AE:
; LDX abs
; +51/51/59
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; load operand
	STA x65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_BE:
; LDX abs, Y
; +58/58/66
	_PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC y65
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; load operand
	STA x65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_A0:
; LDY imm
; +30/30/34
	_PC_ADV		; get immediate operand
	LDA (pc65), Y
	STA x65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_A4:
; LDY zp
; +36/36/40
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA y65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_B4:
; LDY zp, X
; +41/41/45
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA y65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_AC:
; LDY abs
; +51/51/59
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; load operand
	STA y65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_BC:
; LDY abs, X
; +58/58/66
	_PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC x65
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; load operand
	STA y65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_A9:
; LDA imm
; +30/30/34
	_PC_ADV		; get immediate operand
	LDA (pc65), Y
	STA a65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_A5:
; LDA zp
; +36/36/40
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA a65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_B5:
; LDA zp, X
; +41/41/45
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA a65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_AD:
; LDA abs
; +51/51/59
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; load operand
	STA a65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_BD:
; LDA abs, X
; +58/58/66
	_PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC x65
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; load operand
	STA a65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_B9:
; LDA abs, Y
; +58/58/66
	_PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC y65
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; load operand
	STA a65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_B2:
; LDA (zp)
; +51/51/55
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	LDA !1, X	; same for MSB
	STA tmptr+1
	LDA (tmptr)	; read operand
	STA a65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_B1:
; LDA (zp), Y
; +58/58/62
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	CLC
	ADC y65		; indexed
	LDA !1, X	; same for MSB
	ADC #0		; in case of boundary crossing
	STA tmptr+1
	LDA (tmptr)	; read operand
	STA a65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_A1:
; LDA (zp, X)
; +56/56/60
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	CLC
	ADC x65		; preindexing, forget C as will wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	LDA !1, X	; same for MSB
	STA tmptr+1
	LDA (tmptr)	; read operand
	STA a65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

; * store *

_86:
; STX zp
; +22/22/26
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA x65		; value to be stored
	STA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_96:
; STX zp, Y
; +27/27/31
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC y65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA x65		; value to be stored
	STA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_8E:
; STX abs
; +37/37/45
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA x65		; value to be stored
	STA (tmptr)	; store operand
	JMP next_op

_84:
; STY zp
; +22/22/26
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA y65		; value to be stored
	STA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_94:
; STY zp, X
; +27/27/31
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA y65		; value to be stored
	STA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_8C:
; STY abs
; +37/37/45
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA y65		; value to be stored
	STA (tmptr)	; store operand
	JMP next_op

_64:
; STZ zp
; +19/19/23
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	STZ !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_74:
; STZ zp, X
; +24/24/28
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	STZ !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_9C:
; STZ abs
; +36/36/44
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA #0
	STA (tmptr)	; clear operand
	JMP next_op

_9E:
; STZ abs, X
; +43/43/51
	_PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC x65
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA #0
	STA (tmptr)	; clear operand
	JMP next_op

_8D:
; STA abs
; +37/37/45
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA a65		; value to be stored
	STA (tmptr)	; store operand
	JMP next_op

_9D:
; STA abs, X
; +44/44/52
	_PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC x65
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA a65		; value to be stored
	STA (tmptr)	; store operand
	JMP next_op

_99:
; STA abs, Y
; +44/44/52
	_PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC y65
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA a65		; value to be stored
	STA (tmptr)	; store operand
	JMP next_op

_85:
; STA zp
; +22/22/26
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA a65		; value to be stored
	STA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_95:
; STA zp, X
; +27/27/31
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA a65		; value to be stored
	STA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_92:
; STA (zp)
; +37/37/41
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	LDA !1, X	; same for MSB
	STA tmptr+1
	LDA a65		; value to be stored
	STA (tmptr)
	JMP next_op

_91:
; STA (zp), Y
; +44/44/48
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	CLC
	ADC y65		; indexed
	LDA !1, X	; same for MSB
	ADC #0		; in case of boundary crossing
	STA tmptr+1
	LDA a65		; value to be stored
	STA (tmptr)
	JMP next_op

_81:
; STA (zp, X)
; +42/42/46
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	CLC
	ADC x65		; preindexing, forget C as will wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	LDA !1, X	; same for MSB
	STA tmptr+1
	LDA a65		; value to be stored
	STA (tmptr)
	JMP next_op

; *** bitwise ops ***

; * logic and *

_29:
; AND imm
; +33/33/37
	_PC_ADV		; get immediate operand
	LDA (pc65), Y
	AND a65		; do AND
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting (17)
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_25:
; AND zp
; +39/39/43
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	AND a65		; do AND
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_35:
; AND zp, X
; +44/44/48
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	AND a65		; do AND
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_2D:
; AND abs
; +54/54/62
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; read operand
	AND a65		; do AND
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_3D:
; AND abs, X
; +61/61/69
	_PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC x65
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; read operand
	AND a65		; do AND
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_39:
; AND abs, Y
; +61/61/69
	_PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC y65
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; read operand
	AND a65		; do AND
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_32:
; AND (zp)
; +54/54/58
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	LDA !1, X	; same for MSB
	STA tmptr+1
	LDA (tmptr)	; read operand
	AND a65		; do AND
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_31:
; AND (zp), Y
; +61/61/65
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	CLC
	ADC y65		; indexed
	LDA !1, X	; same for MSB
	ADC #0		; in case of boundary crossing
	STA tmptr+1
	LDA (tmptr)	; read operand
	AND a65		; do AND
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_21:
; AND (zp, X)
; +59/59/63
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	CLC
	ADC x65		; preindexing, forget C as will wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	LDA !1, X	; same for MSB
	STA tmptr+1
	LDA (tmptr)	; read operand
	AND a65		; do AND
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

; * logic or *

_09:
; ORA imm
; +33/33/37
	_PC_ADV		; get immediate operand
	LDA (pc65), Y
	ORA a65		; do OR
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_05:
; ORA zp
; +39/39/43
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	ORA a65		; do OR
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_15:
; ORA zp, X
; +44/44/48
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	ORA a65		; do OR
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_0D:
; ORA abs
; +54/54/62
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; read operand
	ORA a65		; do OR
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_1D:
; ORA abs, X
; +61/61/69
	_PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC x65
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; read operand
	ORA a65		; do OR
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_19:
; ORA abs, Y
; +61/61/69
	_PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC y65
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; read operand
	ORA a65		; do OR
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_12:
; ORA (zp)
; +54/54/58
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	LDA !1, X	; same for MSB
	STA tmptr+1
	LDA (tmptr)	; read operand
	ORA a65		; do OR
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_11:
; ORA (zp), Y
; +61/61/65
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	CLC
	ADC y65		; indexed
	LDA !1, X	; same for MSB
	ADC #0		; in case of boundary crossing
	STA tmptr+1
	LDA (tmptr)	; read operand
	ORA a65		; do OR
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_01:
; ORA (zp, X)
; +59/59/63
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	CLC
	ADC x65		; preindexing, forget C as will wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	LDA !1, X	; same for MSB
	STA tmptr+1
	LDA (tmptr)	; read operand
	ORA a65		; do OR
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

; * exclusive or *

_49:
; EOR imm
; +33/33/37
	_PC_ADV		; get immediate operand
	LDA (pc65), Y
	EOR a65		; do XOR
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_45:
; EOR zp
; +39/39/43
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	EOR a65		; do XOR
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_55:
; EOR zp, X
; +44/44/48
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	EOR a65		; do XOR
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_4D:
; EOR abs
; +54/54/62
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; read operand
	EOR a65		; do XOR
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_5D:
; EOR abs, X
; +61/61/69
	_PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC x65
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; read operand
	EOR a65		; do XOR
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_59:
; EOR abs, Y
; +61/61/69
	_PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC y65
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; read operand
	EOR a65		; do XOR
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_52:
; EOR (zp)
; +54/54/58
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	LDA !1, X	; same for MSB
	STA tmptr+1
	LDA (tmptr)	; read operand
	EOR a65		; do XOR
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_51:
; EOR (zp), Y
; +61/61/65
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	CLC
	ADC y65		; indexed
	LDA !1, X	; same for MSB
	ADC #0		; in case of boundary crossing
	STA tmptr+1
	LDA (tmptr)	; read operand
	EOR a65		; do XOR
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_41:
; EOR (zp, X)
; +59/59/63
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	CLC
	ADC x65		; preindexing, forget C as will wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	LDA !1, X	; same for MSB
	STA tmptr+1
	LDA (tmptr)	; read operand
	EOR a65		; do XOR
	STA a65		; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

; *** arithmetic ***

; * add with carry *

_69:
; ADC imm
; +46/46/50
	_PC_ADV		; get immediate operand
	LDA (pc65), Y
; copy virtual status (+36)
	PHP
	LDX ccr65		; assume virtual status
	PHX
	PLP		; as both d5 and d4 are kept 1, no problem
; proceed
	ADC a65		; do add
	STA a65		; update value
; with so many flags to set, best sync with virtual P
	PHP		; new status
	PLA
	STA ccr65		; update virtual
	PLP
; all done
	JMP next_op

_65:
; ADC zp
; +52/52/56
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
; copy virtual status
	PHP
	LDX ccr65		; assume virtual status
	PHX
	PLP		; as both d5 and d4 are kept 1, no problem
; proceed
	ADC a65		; do add
	STA a65		; update value
; with so many flags to set, best sync with virtual P
	PHP		; new status
	PLA
	STA ccr65		; update virtual
	PLP
; all done
	JMP next_op

_75:
; ADC zp, X
; +57/57/61
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
; copy virtual status
	PHP
	LDX ccr65		; assume virtual status
	PHX
	PLP		; as both d5 and d4 are kept 1, no problem
; proceed
	ADC a65		; do add
	STA a65		; update value
; with so many flags to set, best sync with virtual P
	PHP		; new status
	PLA
	STA ccr65		; update virtual
	PLP
; all done
	JMP next_op

_6D:
; ADC abs
; +67/67/75
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; read operand
; copy virtual status
	PHP
	LDX ccr65		; assume virtual status
	PHX
	PLP		; as both d5 and d4 are kept 1, no problem
; proceed
	ADC a65		; do add
	STA a65		; update value
; with so many flags to set, best sync with virtual P
	PHP		; new status
	PLA
	STA ccr65		; update virtual
	PLP
; all done
	JMP next_op

_7D:
; ADC abs, X
; +74/74/82
	_PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC x65
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; read operand
; copy virtual status
	PHP
	LDX ccr65		; assume virtual status
	PHX
	PLP		; as both d5 and d4 are kept 1, no problem
; proceed
	ADC a65		; do add
	STA a65		; update value
; with so many flags to set, best sync with virtual P
	PHP		; new status
	PLA
	STA ccr65		; update virtual
	PLP
; all done
	JMP next_op

_79:
; ADC abs, Y
; +74/74/82
	_PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC y65
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; read operand
; copy virtual status
	PHP
	LDX ccr65		; assume virtual status
	PHX
	PLP		; as both d5 and d4 are kept 1, no problem
; proceed
	ADC a65		; do add
	STA a65		; update value
; with so many flags to set, best sync with virtual P
	PHP		; new status
	PLA
	STA ccr65		; update virtual
	PLP
; all done
	JMP next_op

_72:
; ADC (zp)
; +67/67/71
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	LDA !1, X	; same for MSB
	STA tmptr+1
	LDA (tmptr)	; read operand
; copy virtual status
	PHP
	LDX ccr65		; assume virtual status
	PHX
	PLP		; as both d5 and d4 are kept 1, no problem
; proceed
	ADC a65		; do add
	STA a65		; update value
; with so many flags to set, best sync with virtual P
	PHP		; new status
	PLA
	STA ccr65		; update virtual
	PLP
; all done
	JMP next_op

_71:
; ADC (zp), Y
; +74/74/78
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	CLC
	ADC y65		; indexed
	LDA !1, X	; same for MSB
	ADC #0		; in case of boundary crossing
	STA tmptr+1
	LDA (tmptr)	; read operand
; copy virtual status
	PHP
	LDX ccr65		; assume virtual status
	PHX
	PLP		; as both d5 and d4 are kept 1, no problem
; proceed
	ADC a65		; do add
	STA a65		; update value
; with so many flags to set, best sync with virtual P
	PHP		; new status
	PLA
	STA ccr65		; update virtual
	PLP
; all done
	JMP next_op

_61:
; ADC (zp, X)
; +72/72/76
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	CLC
	ADC x65		; preindexing, forget C as will wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	LDA !1, X	; same for MSB
	STA tmptr+1
	LDA (tmptr)	; read operand
; copy virtual status
	PHP
	LDX ccr65		; assume virtual status
	PHX
	PLP		; as both d5 and d4 are kept 1, no problem
; proceed
	ADC a65		; do add
	STA a65		; update value
; with so many flags to set, best sync with virtual P
	PHP		; new status
	PLA
	STA ccr65		; update virtual
	PLP
; all done
	JMP next_op

; * subtract with borrow *

_E9:
; SBC imm
; +
	_PC_ADV		; PREPARE immediate operand
; copy virtual status
	PHP
	LDX ccr65		; assume virtual status
	PHX
	PLP		; as both d5 and d4 are kept 1, no problem
; proceed
	LDA a65
	SBC (pc65), Y	; subtract operand
	STA a65		; update value
; with so many flags to set, best sync with virtual P
	PHP		; new status
	PLA
	STA ccr65		; update virtual
	PLP
; all done
	JMP next_op

_E5:
; SBC zp
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
; copy virtual status
	PHP
	LDA ccr65		; assume virtual status
	PHA
	PLP		; as both d5 and d4 are kept 1, no problem
; proceed
	LDA a65
	SBC !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA a65		; update value
; with so many flags to set, best sync with virtual P
	PHP		; new status
	PLA
	STA ccr65		; update virtual
	PLP
; all done
	JMP next_op

_F5:
; SBC zp, X
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
; copy virtual status
	PHP
	LDA ccr65		; assume virtual status
	PHA
	PLP		; as both d5 and d4 are kept 1, no problem
; proceed
	LDA a65
	SBC !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA a65		; update value
; with so many flags to set, best sync with virtual P
	PHP		; new status
	PLA
	STA ccr65		; update virtual
	PLP
; all done
	JMP next_op

_ED:
; SBC abs
; +
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
; copy virtual status
	PHP
	LDX ccr65		; assume virtual status
	PHX
	PLP		; as both d5 and d4 are kept 1, no problem
; proceed
	LDA a65
	SBC (tmptr)	; subtract operand
	STA a65		; update value
; with so many flags to set, best sync with virtual P
	PHP		; new status
	PLA
	STA ccr65		; update virtual
	PLP
; all done
	JMP next_op

_FD:
; SBC abs, X
; +
	_PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC x65
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
; copy virtual status
	PHP
	LDX ccr65		; assume virtual status
	PHX
	PLP		; as both d5 and d4 are kept 1, no problem
; proceed
	LDA a65
	SBC (tmptr)	; subtract operand
	STA a65		; update value
; with so many flags to set, best sync with virtual P
	PHP		; new status
	PLA
	STA ccr65		; update virtual
	PLP
; all done
	JMP next_op

_F9:
; SBC abs, Y
; +
	_PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC y65
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
; copy virtual status
	PHP
	LDX ccr65		; assume virtual status
	PHX
	PLP		; as both d5 and d4 are kept 1, no problem
; proceed
	LDA a65
	SBC (pc65), Y	; subtract operand
	STA a65		; update value
; with so many flags to set, best sync with virtual P
	PHP		; new status
	PLA
	STA ccr65		; update virtual
	PLP
; all done
	JMP next_op

_F2:
; SBC (zp)
; +
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	LDA !1, X	; same for MSB
	STA tmptr+1
; copy virtual status
	PHP
	LDX ccr65		; assume virtual status
	PHX
	PLP		; as both d5 and d4 are kept 1, no problem
; proceed
	LDA a65
	SBC (tmptr)	; subtract operand
	STA a65		; update value
; with so many flags to set, best sync with virtual P
	PHP		; new status
	PLA
	STA ccr65		; update virtual
	PLP
; all done
	JMP next_op

_F1:
; SBC (zp), Y
; +
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	CLC
	ADC y65		; indexed
	LDA !1, X	; same for MSB
	ADC #0		; in case of boundary crossing
	STA tmptr+1
; copy virtual status
	PHP
	LDX ccr65		; assume virtual status
	PHX
	PLP		; as both d5 and d4 are kept 1, no problem
; proceed
	LDA a65
	SBC (tmptr)	; subtract operand
	STA a65		; update value
; with so many flags to set, best sync with virtual P
	PHP		; new status
	PLA
	STA ccr65		; update virtual
	PLP
; all done
	JMP next_op

_E1:
; ADC (zp, X)
; +72/72/76
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	CLC
	ADC x65		; preindexing, forget C as will wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	LDA !1, X	; same for MSB
	STA tmptr+1
; copy virtual status
	PHP
	LDX ccr65		; assume virtual status
	PHX
	PLP		; as both d5 and d4 are kept 1, no problem
; proceed
	LDA a65
	SBC (tmptr)	; subtract operand
	STA a65		; update value
; with so many flags to set, best sync with virtual P
	PHP		; new status
	PLA
	STA ccr65		; update virtual
	PLP
; all done
	JMP next_op

; * inc/dec memory *

_E6:
; INC zp
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	INC !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	LDA !0, X	; retrieve value
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_F6:
; INC zp, X
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	INC !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	LDA !0, X	; retrieve value
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_EE
; INC abs
; +
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; read operand
	INC
	STA (tmptr)	; update
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_FE:
; INC abs, X
; +
	_PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC x65
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; read operand
	INC
	STA (tmptr)	; update
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op
_C6:
; DEC zp
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	DEC !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	LDA !0, X	; retrieve value
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_D6:
; DEC zp, X
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	DEC !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	LDA !0, X	; retrieve value
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_CE:
; DEC abs
; +
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; read operand
	DEC
	STA (tmptr)	; update
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op

_DE:
; DEC abs, X
; +
	_PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC x65
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; read operand
	DEC
	STA (tmptr)	; update
; standard NZ flag setting
	TAX		; index for LUT
	LDA ccr65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA ccr65
; all done
	JMP next_op


; ** ** ** old 6800 stuff ** ** **
; ** accumulator and memory ** CONTINUE HERE

; add to A
_89:
; ADC imm (2)

	_PC_ADV			; not worth using the macro (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc65 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA adcae		; continue as indirect addressing (61/67.5)

_99:
; ADC zp (3)
; +79/85.5/
	_DIRECT			; point to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA adcae		; continue as indirect addressing (61/67.5)

_a9:
; ADC a,x (4)
; +92/99/
	_INDEXED		; point to operand (31/31.5)
	BRA adcae		; same (3+)

_b9:
; ADC abs (4)
; +89/96/
	_EXTENDED		; point to operand (31/31.5)
adcae:				; +58/64.5 from here
	CLC				; prepare (2)
	BBR0 ccr65, adcae_cc	; no previous carry (6/6.5...) *** Rockwell ***
		SEC						; otherwise preset C
adcae_cc:			; +50/56/ from here
	LDA a65			; get accumulator A (3)
	BIT #%00010000	; check bit 4 (2)
	BEQ adcae_nh	; do not set H if clear (8/9...)
		SMB5 ccr65		; set H temporarily as b4 *** Rockwell ***
		BRA adcae_sh	; do not clear it
adcae_nh:
	RMB5 ccr65		; otherwise H is clear *** Rockwell ***
adcae_sh:
	ADC (tmptr)		; add operand (5)
adda:				; +32/37/ from here
	TAX				; store for later! (2)
	BIT #%00010000	; check bit 4 again (2)
	BNE adcae_nh2	; do not invert H (8/10...)
		LDA ccr65		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		BRA adcae_sh2	; do not reload CCR
adcae_nh2:
	LDA ccr65		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
adcae_sh2:
	BCC adcae_nc	; only if carry... (3/3.5...)
		INC				; ...set C flag
adcae_nc:
	BVC adcae_nv	; only if overflow... (3/3.5...)
		ORA #%00000010	; ...set V flag
adcae_nv:
	STA ccr65		; update flags (3)
	TXA				; retrieve value! (2)
	JMP a_nz		; update A and check NZ (9/11/20)

; logical AND
_84:
; AND imm (2)
; +42/44/
	_PC_ADV			; go for operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc65 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA andae		; continue as indirect addressing (28/30/39)

_94:
; AND zp (3)
; +46/48/
	_DIRECT			; points to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA andae		; continue as indirect addressing (28/30/39)

_a4:
; AND a,x (5)
; +59/61.5/
	_INDEXED		; points to operand (31/31.5)
	BRA andae		; same (28/30/39)

_b4:
; AND abs (4)
; +56/58.5/
	_EXTENDED		; points to operand (31/31.5)
andae:				; +25/27/36 from here
	LDA ccr65		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr65		; update (3)
	LDA a65			; get A accumulator (3)
	AND (tmptr)		; AND with operand (5)
	JMP a_nz		; update A and check NZ (9/11/20)

; AND without modifying register
_85:
; BIT imm (2)
; +39/41/
	_PC_ADV			; go for operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc65 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA bitae		; continue as indirect addressing (25/27/36)

_95:
; BIT zp (3)
; +43/45/
	_DIRECT			; points to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA bitae		; continue as indirect addressing (25/27/36)

_a5:
; BIT a,x (5)
; +56/58.5/
	_INDEXED		; points to operand (31/31.5)
	BRA bitae		; same (25/27/36)

_b5:
; BIT abs (4)
; +53/55.5/
	_EXTENDED		; points to operand (31/31.5)
bitae:				; +22/24/33 from here
	LDA ccr65		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr65		; update (3)
	LDA a65			; get A accumulator (3)
	AND (tmptr)		; AND with operand, just for flags (5)
	JMP check_nz	; check flags and end (6/8/17)

; clear
_4f:
; CLR A (2)
; +13
	STZ a65		; clear A (3)
clra:
	LDA ccr65	; get previous status (3)
	AND #%11110100	; clear N, V, C (2)
	ORA #%00000100	; set Z (2)
	STA ccr65	; update (3)
	JMP next_op	; standard end of routine

_6f:
; CLR a,x (7)
; +54/54.5/
	_INDEXED		; prepare pointer (31/31.5)
	BRA clre		; same code (23)

_7f:
; CLR abs (6)
; +51/51.5/
	_EXTENDED		; prepare pointer (31/31.5)
clre:
	LDA #0			; no indirect STZ available (2)
	STA (tmptr)		; clear memory (5)
	BRA clra		; same (13)

; compare
_81:
; CMP imm (2)
; +47/51/
	_PC_ADV			; get operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc65 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA cmpae		; continue as indirect addressing (33/37/55)

_91:
; CMP zp (3)
; +51/55/
	_DIRECT			; get operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA cmpae		; continue as indirect addressing (33/37/55)

_a1:
; CMP a,x (5)
; +64/68.5/
	_INDEXED		; get operand (31/31.5)
	BRA cmpae		; same (33/37/55)

_b1:
; CMP abs (4)
; +61/65.5/
	_EXTENDED		; get operand (31/31.5)
cmpae:				; +30/34/52 from here
	LDA ccr65		; get flags (3)
	AND #%11110000	; clear relevant bits (2)
	STA ccr65		; update (3)
	LDA a65			; get accumulator A (3)
	SEC				; prepare (2)
	SBC (tmptr)		; subtract without carry (5)
	JMP check_flags	; check NZVC and exit (12/16/34)

; decrement
_4a:
; DEC (2)
; +29/31/
	LDA ccr65		; get original status (3)
	AND #%11110001	; reset all relevant bits for CCR (2)
	STA ccr65		; store new flags (3)
	DEC a65			; decrease A (5)
	LDX a65			; check it! (3)
deca:				; +13/15/ from here
	CPX #$7F		; did change sign? (2)
	BNE deca_nv		; skip if not overflow (3...)
		SMB1 ccr65		; will set V flag *** Rockwell ***
deca_nv:
	TXA				; retrieve! (2)
	JMP check_nz	; end (6/8/17)

_6a:
; DEC a,x (7)
; +72/74.5/
	_INDEXED		; addressing mode (31/31.5)
	BRA dece		; same (41/43)

_7a:
; DEC abs (6)
; +69/71.5/
	_EXTENDED		; addressing mode (31/31.5)
dece:				; +38/40/ from here
	LDA ccr65		; get original status (3)
	AND #%11110001	; reset all relevant bits for CCR (2)
	STA ccr65		; store new flags (3)
	LDA (tmptr)		; no DEC (tmptr) available... (5)
	DEC				; (2)
	STA (tmptr)		; (5)
	TAX				; store for later (2)
	BRA deca		; continue (16/18)

; exclusive OR
_88:
; EOR imm (2)
; +42/44/
	_PC_ADV			; go for operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc65 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA eorae		; continue as indirect addressing (28/30/39)

_98:
; EOR zp (3)
; +46/48/
	_DIRECT			; Points to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA eorae		; continue as indirect addressing (28/30/39)

_a8:
; EOR a,x (5)
; +59/61.5/
	_INDEXED		; points to operand (31/31.5)
	BRA eorae		; same (28/30/39)

_b8:
; EOR abs (4)
; +56/58.5/
	_EXTENDED		; points to operand (31/31.5)
eorae:				; +25/27/36 from here
	LDA ccr65		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr65		; update (3)
	LDA a65			; get A accumulator (3)
	EOR (tmptr)		; EOR with operand (5)
	JMP a_nz		; update A, check NZ and exit (9/11/20)

; increment
_4c:
; INC (2)
; +29/31/
	LDA ccr65		; get original status (3)
	AND #%11110001	; reset all relevant bits for CCR (2)
	STA ccr65		; store new flags (3)
	INC a65			; increase A (5)
	LDX a65			; check it! (3)
inca:				; +13/15/ from here
	CPX #$80		; did change sign? (2)
	BNE inca_nv		; skip if not overflow (3...)
		SMB1 ccr65		; will set V flag *** Rockwell ***
inca_nv:
	TXA				; retrieve! (2)
	JMP check_nz	; end (6/8/17)

_6c:
; INC a,x (7)
; +72/74.5/
	_INDEXED		; addressing mode (31/31.5)
	BRA ince		; same (3+)

_7c:
; INC abs (6)
; +69/71.5/
	_EXTENDED		; addressing mode (31/31.5)
ince:
	LDA ccr65		; get original status (3)
	AND #%11110001	; reset all relevant bits for CCR (2)
	STA ccr65		; store new flags (3)
	LDA (tmptr)		; no INC (tmptr) available... (5)
	INC				; (2)
	STA (tmptr)		; (5)
	TAX				; store for later (2)
	BRA inca		; continue (3+)

; load accumulator
_86:
; LDA imm (2)
; +39/41/
	_PC_ADV			; go for operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc65 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA ldaae		; continue as indirect addressing (25/27/36)

_96:
; LDA zp (3)
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
; LDA a,x (5)
; +56/58.5/
	_INDEXED		; points to operand (31/31.5)
	BRA ldaae		; same (25/27/36)

_b6:
; LDA abs (4)
; +53/55.5/
	_EXTENDED		; points to operand (31/31.5)
ldaae:				; +22/24/33 from here
	LDA ccr65		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr65		; update (3)
	LDA (tmptr)		; get operand (5)
	JMP a_nz		; update A, check NZ and exit (9/11/20)

_
; inclusive OR
_8a:
; ORA imm (2)
; + [[[[[[[[[[[[[[[[[[[[[[[[CONTINUE HERE]]]]]]]]]]]]]]]]]]]]]]]]
	_PC_ADV			; go for operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc65 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA oraae		; continue as indirect addressing (3+)

_9a:
; ORA zp (3)
; +
	_DIRECT			; points to operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA oraae		; continue as indirect addressing (3+)

_aa:
; ORA a,x (5)
; +
	_INDEXED		; points to operand (31/31.5)
	BRA oraae		; same (3+)

_ba:
; ORA abs (4)
; +
	_EXTENDED		; points to operand (31/31.5)
oraae:
	LDA ccr65		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr65		; update (3)
	LDA a65			; get A accumulator (3)
	ORA (tmptr)		; ORA with operand (5)
	JMP a_nz		; update A, check NZ and exit (9/11/20)

; push accumulator
_36:
; PHA (4)
; +
	LDA a65			; get accumulator A (3)
psha:
	STA (sp65)		; put it on stack space (5)
	LDX sp65		; check LSB (3)
	BNE psha_nw		; will not wrap (3...)
		LDA sp65+1		; get MSB
		DEC				; decrease it
		_AH_BOUND		; and inject it
		STA sp65+1		; worst update
psha_nw:
	DEC sp65		; post-decrement (5)
	JMP next_op		; all done (3+)

_37:
; PHX (4)
; +
	LDA b68			; get accumulator B (3)
	BRA psha		; same (3+)

; pull accumulator
_32:
; PLA (4)
; +
	INC sp65		; pre-increment (5)
	BNE pula_nw		; should not correct MSB (3...)
		LDA sp65 + 1	; get stack pointer MSB
		INC				; increase MSB
		_AH_BOUND		; keep injected
		STA sp65 + 1	; update real thing
pula_nw:
	LDA (sp65)		; take value from stack (5)
	STA a65			; store it in accumulator A (3)
	JMP next_op		; standard end of routine

_33:
; PLX (4)
; +
	INC sp65		; pre-increment (5)
	BNE pulb_nw		; should not correct MSB (3...)
		LDA sp65 + 1	; get stack pointer MSB
		INC				; increase MSB
		_AH_BOUND		; keep injected
		STA sp65 + 1	; update real thing
pulb_nw:
	LDA (sp65)		; take value from stack (5)
	STA b68			; store it in accumulator B (3)
	JMP next_op		; standard end of routine

; rotate left
_49:
; ROL (2)
; +
	CLC				; prepare (2)
	BBR0 ccr65, rola_do	; skip if C clear (6/6.5...) *** Rockwell ***
		SEC					; otherwise, set carry
rola_do:
	ROL a65			; rotate A left (5)
	LDX a65			; keep for later (3)
rots:				; *** common rotation ending, with value in X ***
	LDA ccr65		; get flags again (3)
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
	STA ccr65		; update status (3)
	JMP next_op		; standard end of routine

_79:
; ROL abs (6)
; +
	_EXTENDED		; addressing mode (31/31.5)
role:
	CLC				; prepare (2)
	BBR0 ccr65, role_do	; skip if C clear (6/6.5) *** Rockwell ***
		SEC					; otherwise, set carry
role_do:
	LDA (tmptr)		; get memory (5)
	ROL				; rotate left (2)
	STA (tmptr)		; modify (5)
	TAX				; keep for later (2)
	BRA rots		; continue (3+)

_69:
; ROL a,x (7)
; +
	_INDEXED		; addressing mode (31/31.5)
	BRA role		; same (3+)

; rotate right
_46:
; ROR (2)
; +
	CLC				; prepare (2)
	BBR0 ccr65, rora_do	; skip if C clear (6/6.5...) *** Rockwell ***
		SEC					; otherwise, set carry
rora_do:
	ROR a65			; rotate A right (5)
	LDX a65			; keep for later (3)
	JMP rots		; common end! (3+)

_66:
; ROR a,x (7)
; +
	_INDEXED		; addressing mode (31/31.5)
	BRA rore		; same (3+)

_76:
; ROR abs (6)
; +
	_EXTENDED		; addressing mode (31/31.5)
rore:
	CLC				; prepare (2)
	BBR0 ccr65, rore_do	; skip if C clear (6/6.5...) *** Rockwell ***
		SEC					; otherwise, set carry
rore_do:
	LDA (tmptr)		; get memory (5)
	ROR				; rotate right (2)
	STA (tmptr)		; modify (5)
	TAX				; keep for later (2)
	JMP rots		; common end! (3+)

; arithmetic shift left
_48:
; ASL (2)
; +
	ASL a65			; shift A left (5)
	LDX a65			; retrieve again! (3)
	JMP rots		; common end (3+)

_68:
; ASL a,x (7)
; +
	_INDEXED		; prepare pointer (31/31.5)
	BRA asle		; same (3+)

_78:
; ASL abs (6)
; +
	_EXTENDED		; prepare pointer (31/31.5)
asle:
	LDA (tmptr)		; get operand (5)
	ASL				; shift left (2)
	STA (tmptr)		; update memory (5)
	TAX				; save for later! (2)
	JMP rots		; common end! (3+)

; logical shift right
_44:
; LSR A (2)
; +
	LDA ccr65		; get original flags (3)
	AND #%11110000	; reset relevant bits (N always reset) (2)
	LSR a65			; shift A right (5)
lshift:				; *** common ending for logical shifts ***
	BNE lsra_nz		; skip if not zero (3...)
		ORA #%00000100	; set Z flag (2)
lsra_nz:
	BCC lsra_nc		; skip if there was no carry (3/3.5...)
		ORA #%00000011	; will set C and V flags, seems OK (2)
lsra_nc:
	STA ccr65		; update status (3)
	JMP next_op		; standard end of routine

_64:
; LSR a,x (7)
; +
	_INDEXED		; addressing mode (31/31.5)
	BRA lsre		; same (3+)

_74:
; LSR abs (6)
; +
	_EXTENDED		; addressing mode (31/31.5)
lsre:
	LDA (tmptr)		; get operand (5)
	LSR				; (2)
	STA (tmptr)		; modify operand (5)
	PHP				; store status, really needed!!! (3)
	LDA ccr65		; get original flags (3)
	AND #%11110000	; reset relevant bits (N always reset) (2)
	PLP				; retrieve status, proper way!!! (4)
	BRA lshift		; common end! (3+)

; store accumulator [[[[continue from here]]]]]]
_97:
; STA zp (4)
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
	LDA a65			; get char in A
	STA zpar		; parameter for COUT
	_KERNEL(COUT)	; standard output
	LDA a65			; just for flags
	JMP check_nz	; usual ending

_a7:
; STA a,x (6)
; +
	_INDEXED		; points to operand (31/31.5)
	BRA staae		; same (3+)

_b7:
; STA abs (5)
; +53/55.5/
	_EXTENDED		; points to operand (31/31.5)
staae:
	LDA ccr65		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr65		; update (3)
	LDA a65			; get A accumulator (3)
	JMP ind_nz		; store, check NZ and exit (14/17/25)

; subtract with carry
_82:
; SBC imm (2)
; +
	_PC_ADV			; get operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc65 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA sbcae		; continue as indirect addressing (3+)

_92:
; SBC zp (3)
; +
	_DIRECT			; get operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA sbcae		; continue as indirect addressing (3+)

_a2:
; SBC a,x (5)
; +
	_INDEXED		; get operand (31/31.5)
	BRA sbcae		; same (3+)

_b2:
; SBC abs (4)
; +70/77/
	_EXTENDED		; get operand (31/31.5)
sbcae:
	SEC				; prepare (2)
	BBR0 ccr65, sbcae_do	; skip if C clear ** Rockwell **
		CLC				; otherwise, set carry, opposite of 6502 (2)
sbcae_do:
	LDA ccr65		; get flags (3)
	AND #%11110000	; clear relevant bits (2)
	STA ccr65		; update (3)
	LDA a65			; get accumulator A
	SBC (tmptr)		; subtract with carry (5)
	STA a65			; update accumulator (3)
	JMP check_flags	; and exit (12/16/34)

; transfer accumulator
_16:
; TAX (2)
; +20/22/24
	LDA ccr65		; get original flags (3)
	AND #%11110001	; reset N,Z, and always V (2)
	STA ccr65		; update status (3)
	LDA a65			; get A (3)
	JMP b_nz		; update B, check NZ and exit (12/14/23)

_17:
; TXA (2)
; +20/22/24
	LDA ccr65		; get original flags (3)
	AND #%11110001	; reset N,Z, and always V (2)
	STA ccr65		; update status (3)
	LDA b68			; get B (3)
	JMP a_nz		; update A, check NZ and exit (9/11/20)

; test for zero or minus
_4d:
; TST A (2)
; +17/19/21
	LDA ccr65		; get original flags (3)
	AND #%11110000	; reset relevant bits (2)
	STA ccr65		; update status (3)
	LDA a65			; check accumulator A (3)
	JMP check_nz	; (6/8/17)

_6d:
; TST a,x (7)
; +
	_INDEXED		; set pointer (31/31.5)
	BRA tste		; same (3+)

_7d:
; TST abs (6)
; +50/52.5/
	_EXTENDED		; set pointer (31/31.5)
tste:
	LDA ccr65		; get original flags (3)
	AND #%11110000	; reset relevant bits (2)
	STA ccr65		; update status (3)
	LDA (tmptr)		; check operand (5)
	JMP check_nz	; (6/8/17)

; ** index register and stack pointer ops **

; compare index
_8c:
; CPX imm (3)
; +
	_PC_ADV			; get first operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc65 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA cpxe		; continue as indirect addressing (3+)

_9c:
; CPX zp (4)
; +
	_DIRECT			; get operand (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA cpxe		; continue as indirect addressing (3+)

_ac:
; CPX a,x (6)
; +
	_INDEXED		; get operand (31/31.5)
	BRA cpxe		; same (3+)

_bc:
; CPX abs (5)
; +82/88.5/
	_EXTENDED		; get operand (31/31.5)
cpxe:
	LDA ccr65		; get original flags (3)
	AND #%11110001	; reset relevant bits (2)
	STA ccr65		; update flags (3)
	SEC				; prepare (2)
	LDA x65 + 1		; MSB at X (3)
	SBC (tmptr)		; subtract memory (5)
	TAX				; keep for later (2)
	BPL cpxe_pl		; not negative (3/5...)
		SMB3 ccr65		; otherwise set N flag *** Rockwell ***
cpxe_pl:
	INC tmptr		; point to next byte (5)
	BNE cpxe_nw		; usually will not wrap (3...)
		LDA tmptr + 1	; get original MSB
		INC				; advance
		_AH_BOUND		; inject
		STA tmptr + 1	; restore
cpxe_nw:
	LDA x65			; LSB at X (3)
	SBC (tmptr)		; value LSB (5)
	STX tmptr		; retrieve old MSB (3)
	ORA tmptr		; blend with stored MSB (3)
	BNE cpxe_nz		; if zero... (3...)
		SMB2 ccr65		; set Z *** Rockwell ***
cpxe_nz:
	BVC cpxe_nv		; if overflow... (3/5...)
		SMB1 ccr65		; set V *** Rockwell ***
cpxe_nv:
	JMP next_op		; standard end

; decrement index
_09:
; DEX (4)
; +17/17/24
	LDA x65			; check LSB (3)
	BEQ dex_w		; if zero, will wrap upon decrease! (2)
		DEC x65			; otherwise just decrease LSB (5)
		BEQ dex_z		; if zero now, could be all zeroes! (2)
			RMB2 ccr65		; clear Z bit (5) *** Rockwell only! ***
			JMP next_op		; usual end
dex_w:
		DEC x65			; decrease as usual
		DEC x65 + 1		; wrap MSB
		RMB2 ccr65		; clear Z bit, *** Rockwell only! ***
		JMP next_op		; usual end
dex_z:
	LDA x65 + 1		; check MSB
	BEQ dex_zz		; it went down to zero!
		RMB2 ccr65		; clear Z bit, *** Rockwell only! ***
		JMP next_op		; usual end
dex_zz:
	SMB2 ccr65	; set Z bit, *** Rockwell only! ***
	JMP next_op	; rarest end of routine

; increase index
_08:
; INX (4)
; +12/12/21
	INC x65		; increase LSB (5)
	BEQ inx_w	; wrap is a rare case (2)
		RMB2 ccr65	; clear Z bit (5) *** Rockwell only! ***
		JMP next_op	; usual end
inx_w:
	INC x65 + 1	; increase MSB
	BEQ inx_z	; becoming zero is even rarer!
		RMB2 ccr65	; clear Z bit *** Rockwell only! ***
		JMP next_op	; wrapped non-zero end
inx_z:
	SMB2 ccr65	; set Z bit *** Rockwell only! ***
	JMP next_op	; rarest end of routine

; load index
_ce:
; LDX imm (3)
; +
	_PC_ADV			; get first operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc65 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA ldxe		; continue as indirect addressing (3+)

_de:
; LDX zp (4)
; +
	_DIRECT			; get first operand pointer (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA ldxe		; continue as indirect addressing (3+)

_ee:
; LDX a,x (6)
; +
	_INDEXED		; get operand address (31/31.5)
	BRA ldxe		; same (3+)

_fe:
; LDX abs (5)
; +72/76/
	_EXTENDED		; get operand address (31/31.5)
ldxe:
	LDA ccr65		; get original flags (3)
	AND #%11110001	; reset relevant bits (2)
	STA ccr65		; update flags (3)
	LDA (tmptr)		; value MSB (5)
	BPL ldxe_pl		; not negative (3/5...)
		SMB3 ccr65		; otherwise set N flag *** Rockwell ***
ldxe_pl:
	STA x65 + 1		; update register (3)
	INC tmptr		; go for next operand (5)
	BNE ldxe_nw		; rare wrap (3...)
		LDA tmptr+1		; get pointer MSB
		INC				; increment
		_AH_BOUND		; keep injected
		STA tmptr+1		; update pointer
ldxe_nw:
	LDA (tmptr)		; value LSB (5)
	STA x65			; register complete (3)
	ORA x65 + 1		; check for zero (3)
	BNE ldxe_nz		; was not zero (3...)
		SMB2 ccr65		; otherwise set Z *** Rockwell ***
ldxe_nz:
	JMP next_op		; standard end

; store index
_df:
; STX zp (5)
; +
	_DIRECT			; get first operand pointer (10)
	STA tmptr		; store LSB of pointer (3)
	LDA #>e_base	; emulated MSB (2)
	STA tmptr+1		; pointer is ready (3)
	BRA stxe		; continue as indirect addressing (3+)

_ef:
; STX a,x (7)
; +
	_INDEXED		; get first operand pointer (31/31.5)
	BRA stxe		; same (3+)

_ff:
; STX abs (6)
; +72/76.5/
	_EXTENDED		; get first operand pointer (31/31.5)
stxe:
	LDA ccr65		; get original flags (3)
	AND #%11110001	; reset relevant bits (2)
	STA ccr65		; update flags (3)
	LDA x65 + 1		; value MSB (3)
	STA (tmptr)		; store it (5)
	BPL stxe_pl		; not negative (3/5...)
		SMB3 ccr65		; otherwise set N flag *** Rockwell ***
stxe_pl:
	INC tmptr		; go for next operand (5)
	BNE stxe_nw		; rare wrap (3...)
		LDA tmptr+1		; get pointer MSB
		INC				; increment
		_AH_BOUND		; keep injected
		STA tmptr+1		; update
stxe_nw:
	LDA x65			; value LSB (3)
	STA (tmptr)		; store in memory  (5)
	ORA x65 + 1		; check for zero (3)
	BNE stxe_nz		; was not zero (3...)
		SMB2 ccr65		; otherwise set Z *** Rockwell ***
stxe_nz:
	JMP next_op		; standard end

; transfers between index and stack pointer 
_30:
; TSX (4)
; +16/16/25
	LDA sp65 + 1	; get stack pointer MSB, to be injected (3)
	LDX sp65		; get stack pointer LSB (3)
	INX				; point to last used!!! (2)
	STX x65			; store in X (3)
	BEQ tsx_w		; rare wrap (2)
tsx_do:
		STA x65 + 1		; pointer complete (3)
		JMP next_op		; standard end of routine
tsx_w:
	INC				; increase MSB
	_AH_BOUND		; inject
	STA x65 + 1		; pointer complete
	JMP next_op		; rarer end of routine

_35:
; TXS (4)
; +21/21/25
	LDA x65 + 1		; MSB will be injected (3)
	LDX x65			; check LSB (3)
	BEQ txs_w		; will wrap upon decrease (2)
		DEX				; as expected (2)
		STX sp65		; copy (3)
		_AH_BOUND		; always! (5/5.5)
		STA sp65 + 1	; pointer ready (3)
		JMP next_op		; standard end
txs_w:
	DEX				; as expected
	STX sp65		; copy
	DEC				; will also affect MSB
	_AH_BOUND		; always!
	STA sp65 + 1	; pointer ready
	JMP next_op		; standard end

; ** jumps and branching **

; branch if overflow clear
_28:
; BVC rel (4)
; +10/25/
	_PC_ADV				; go for operand (5)
		BBR1 ccr65, bra_do		; only if overflow clear *** Rockwell ***
	JMP next_op			; exit without branching

; branch if overflow set
_29:
; BVS rel (4)
; +10/25/
	_PC_ADV				; go for operand (5)
		BBS1 ccr65, bra_do	; only if overflow set *** Rockwell ***
	JMP next_op			; exit without branching

; branch if plus
_2a:
; BPL rel (4)
; +10/25/
	_PC_ADV				; go for operand (5)
		BBR3 ccr65, bra_do	; only if plus *** Rockwell ***
	JMP next_op			; exit without branching

; branch if minus
_2b:
; BMI rel (4)
; +10/25/
	_PC_ADV				; go for operand (5)
		BBS3 ccr65, bra_do	; only if negative *** Rockwell ***
	JMP next_op			; exit without branching

; branch always (used by other branches)
_20:
; BRA rel (4)
; -5 +25/32/
	_PC_ADV			; go for operand (5)
bra_do:				; +// from here
	SEC				; base offset is after the instruction (2)
	LDA (pc65), Y	; check direction (5)
	BMI bra_bk		; backwards jump
		TYA				; get current pc low (2)
		ADC (pc65), Y	; add offset (5)
		TAY				; new offset!!! (2)
		BCS bra_bc		; same msb, go away
bra_go:
			JMP execute		; resume execution
bra_bc:
		INC pc65 + 1	; carry on msb (5)
		BPL bra_lf		; skip if in low area
			RMB6 pc65+1		; otherwise clear A14 (5) *** Rockwell ***
			JMP execute		; and jump
bra_lf:
		SMB6 pc65+1			; low area needs A14 set (5) *** Rockwell ***
		JMP execute
bra_bk:
	TYA				; get current pc low (2)
	ADC (pc65), Y	; "subtract" offset (5)
	TAY				; new offset!!! (2)
		BCS bra_go		; all done
	DEC pc65 + 1	; borrow on msb (5)
		BPL bra_lf		; skip if in low area
 	RMB6 pc65+1		; otherwise clear A14 (5) *** Rockwell ***
	JMP execute		; and jump

; branch if carry clear
_24:
; BCC rel (4)
; +10/25/
	_PC_ADV				; go for operand (5)
		BBR0 ccr65, bra_do	; only if carry clear *** Rockwell ***
	JMP next_op			; exit without branching otherwise

; branch if carry set
_25:
; BCS rel (4)
; +10/25/
	_PC_ADV				; go for operand (5)
		BBS0 ccr65, bra_do	; only if carry set *** Rockwell ***
	JMP next_op			; exit without branching

; branch if not equal
_26:
; BNE rel (4)
; +10/25/
	_PC_ADV				; go for operand (5)
		BBR2 ccr65, bra_do	; only if zero clear *** Rockwell ***
	JMP next_op			; exit without branching

; branch if equal zero
_27:
; BEQ rel (4)
; +10/25/
	_PC_ADV				; go for operand (5)
		BBS2 ccr65, bra_do	; only if zero set *** Rockwell ***
	JMP next_op			; exit without branching

; jump (and to subroutines)
_6e:
; JMP a,x (4)
; -5+30...
	_PC_ADV			; get operand (5)
jmpi:
	LDA (pc65), Y	; set offset (5)
	CLC				; prepare (2)
	ADC x65			; add LSB (3)
	TAY				; this is new offset! (2)
	LDA x65 + 1		; get MSB (3)
	ADC #0			; propagate carry (2)
	_AH_BOUND		; stay injected (5/5.5)
	STA pc65 + 1	; update pointer (3)
	JMP execute		; do jump

_bd:
; JSR abs (9)
; -5 +
	_PC_ADV			; point to operand MSB (5)
; * push return address *
	TYA				; get current PC-LSB minus one (2)
	SEC				; return to next byte! (2)
	ADC #0			; will set carry if wrapped! (2)
	STA (sp65)		; stack LSB first (5)
	DEC sp65		; decrement SP (5)
	BNE jsre_phi		; no wrap, just push MSB (3...)
		LDA sp65 + 1	; get SP MSB
		DEC				; previous page
		_AH_BOUND		; inject
		STA sp65 + 1	; update pointer
jsre_phi:
	LDA pc65+1		; get current MSB (3)
	ADC #0			; take previous carry! (2)
	_AH_BOUND		; just in case (5/5.5)
	STA (sp65)		; push it! (5)
	DEC sp65		; update SP (5)
	BNE jmpe		; no wrap, ready to go! (3+)
		LDA sp65 + 1	; get SP MSB
		DEC				; previous page
		_AH_BOUND		; inject
		STA sp65 + 1	; update pointer
	BRA jmpe		; compute address and jump

_7e:
; JMP abs (3)
; -5 +
	_PC_ADV			; go for destination MSB (5)
jmpe:
	LDA (pc65), Y	; get it (5)
	_AH_BOUND		; check against emulated limits (5/5.5)
	TAX				; hold it for a moment (2)
	_PC_ADV			; now for the LSB (5)
	LDA (pc65), Y	; get it (5)
	TAY				; this works as index (2)
	STX pc65 + 1	; MSB goes into register area (3)
	JMP execute		; all done

; return from subroutine
_39:
; RTS (5)
; +
	LDX #1			; just the return address MSB to pull (2)
	BRA return65	; generic procedure (3+)

; return from interrupt
_3b:
; RTI (10)
; -5 +139/139/
	LDX #7			; bytes into stack frame (4 up here) (2)
return65:			; ** generic entry point, X = bytes to be pulled **
	STX tmptr		; store for later subtraction (3)
	LDY #1			; forget PC MSB, index for pulling from stack (2)
rti_loop:
		LDA (sp65), Y	; pull from stack (5x)
		STA pc65, X		; store into register area (3x)
		INY				; (pre)increment (2x)
		DEX				; go backwards (2x)
		BNE rti_loop	; zero NOT included (3x -1)
	LDA (sp65), Y	; last byte in frame is LSB (5)
	TAX				; store for later (2)
	LDA sp65		; correct stack pointer (3)
	CLC				; prepare (2)
	ADC tmptr		; release space (3)
	STA sp65		; update LSB (3)
	BCC rti_nw		; skip if did not wrap (3...)
		LDA sp65+1		; not just INC zp...
		INC				; next page
		_AH_BOUND		; ...must be kept injected
		STA sp65+1		; update MSB when needed
rti_nw:
	TXA				; get older LSB (2)
	TAY				; and make it effective! (2)
	JMP execute		; resume execution

; software interrupt
_3f:
; BRK (7)
; -5 +
	_PC_ADV			; skip opcode (5)
	LDX #2			; SWI vector offset (2)
	JMP intr65		; generic interrupt handler (3+)

; ** status register opcodes **

; clear overflow
_0a:
; CLV (2)
; +5
	RMB1 ccr65	; clear V bit (5) *** Rockwell only! ***
	JMP next_op	; standard end of routine

; clear carry
_0c:
; CLC (2)
; +5
	RMB0 ccr65	; clear C bit (5) *** Rockwell only! ***
	JMP next_op	; standard end of routine

; set carry
_0d:
; SEC (2)
; +5
	SMB0 ccr65	; set C bit (5) *** Rockwell only! ***
	JMP next_op	; standard end of routine

; clear interrupt mask
_0e:
; CLI (2)
; +5
	RMB4 ccr65	; clear I bit (5) *** Rockwell only! ***
	JMP next_op	; standard end of routine

; set interrupt mask
_0f:
; SEI (2)
; +5
	SMB4 ccr65	; set I bit (5) *** Rockwell only! ***
	JMP next_op	; standard end of routine

; *** LUT for Z & N status bits directly based on result as index ***
nz_lut:
	.byt	Z_FLAG, 0, 0, 0, 0, 0, 0, 0	; zero to 7
	.byt	0, 0, 0, 0, 0, 0, 0, 0	; 8-15
	.byt	0, 0, 0, 0, 0, 0, 0, 0	; 16-23
	.byt	0, 0, 0, 0, 0, 0, 0, 0	; 24-31
	.byt	0, 0, 0, 0, 0, 0, 0, 0	; 32-39
	.byt	0, 0, 0, 0, 0, 0, 0, 0	; 40-47
	.byt	0, 0, 0, 0, 0, 0, 0, 0	; 48-55
	.byt	0, 0, 0, 0, 0, 0, 0, 0	; 56-63
	.byt	0, 0, 0, 0, 0, 0, 0, 0	; 64-71
	.byt	0, 0, 0, 0, 0, 0, 0, 0	; 72-79
	.byt	0, 0, 0, 0, 0, 0, 0, 0	; 80-87
	.byt	0, 0, 0, 0, 0, 0, 0, 0	; 88-95
	.byt	0, 0, 0, 0, 0, 0, 0, 0	; 96-103
	.byt	0, 0, 0, 0, 0, 0, 0, 0	; 104-111
	.byt	0, 0, 0, 0, 0, 0, 0, 0	; 112-119
	.byt	0, 0, 0, 0, 0, 0, 0, 0	; 120-127
	.byt	N_FLAG, N_FLAG, N_FLAG, N_FLAG,	N_FLAG, N_FLAG, N_FLAG, N_FLAG	; negative, 128-135
	.byt	N_FLAG, N_FLAG, N_FLAG, N_FLAG,	N_FLAG, N_FLAG, N_FLAG, N_FLAG	; negative, 136-143
	.byt	N_FLAG, N_FLAG, N_FLAG, N_FLAG,	N_FLAG, N_FLAG, N_FLAG, N_FLAG	; negative, 144-151
	.byt	N_FLAG, N_FLAG, N_FLAG, N_FLAG,	N_FLAG, N_FLAG, N_FLAG, N_FLAG	; negative, 152-159
	.byt	N_FLAG, N_FLAG, N_FLAG, N_FLAG,	N_FLAG, N_FLAG, N_FLAG, N_FLAG	; negative, 160-167
	.byt	N_FLAG, N_FLAG, N_FLAG, N_FLAG,	N_FLAG, N_FLAG, N_FLAG, N_FLAG	; negative, 168-175
	.byt	N_FLAG, N_FLAG, N_FLAG, N_FLAG,	N_FLAG, N_FLAG, N_FLAG, N_FLAG	; negative, 176-183
	.byt	N_FLAG, N_FLAG, N_FLAG, N_FLAG,	N_FLAG, N_FLAG, N_FLAG, N_FLAG	; negative, 184-191
	.byt	N_FLAG, N_FLAG, N_FLAG, N_FLAG,	N_FLAG, N_FLAG, N_FLAG, N_FLAG	; negative, 192-199
	.byt	N_FLAG, N_FLAG, N_FLAG, N_FLAG,	N_FLAG, N_FLAG, N_FLAG, N_FLAG	; negative, 200-207
	.byt	N_FLAG, N_FLAG, N_FLAG, N_FLAG,	N_FLAG, N_FLAG, N_FLAG, N_FLAG	; negative, 208-215
	.byt	N_FLAG, N_FLAG, N_FLAG, N_FLAG,	N_FLAG, N_FLAG, N_FLAG, N_FLAG	; negative, 216-223
	.byt	N_FLAG, N_FLAG, N_FLAG, N_FLAG,	N_FLAG, N_FLAG, N_FLAG, N_FLAG	; negative, 224-231
	.byt	N_FLAG, N_FLAG, N_FLAG, N_FLAG,	N_FLAG, N_FLAG, N_FLAG, N_FLAG	; negative, 232-239
	.byt	N_FLAG, N_FLAG, N_FLAG, N_FLAG,	N_FLAG, N_FLAG, N_FLAG, N_FLAG	; negative, 240-247
	.byt	N_FLAG, N_FLAG, N_FLAG, N_FLAG,	N_FLAG, N_FLAG, N_FLAG, N_FLAG	; negative, 248-25t

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
