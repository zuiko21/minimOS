; Virtual R65C02 for minimOS-16!!!
; specially fast version!
; v0.1a5
; (c) 2016-2018 Carlos J. Santisteban
; last modified 20180722-1136

//#include "../OS/usual.h"
#include "../OS/macros.h"
#include "../OS/abi.h"
.zero
#include "../OS/zeropage.h"
.text

; ** some useful macros **
; these make listings more succint

; increment Y checking boundary crossing (2) ** must be in 16-bit index mode!
#define	_PC_ADV		INY

; *** declare zeropage addresses ***
; ** 'uz' is first available zeropage address (currently $03 in minimOS) **
s65		= uz		; stack pointer, may use next byte as zero
p65		= s65+2		; flags, keep MSB at zero

a65		= p65+2		; accumulator, all these with extra byte
x65		= a65+2		; X index
y65		= x65+2		; Y index

tmp		= y65+2		; temporary storage
cdev	= tmp+2		; I/O device *** minimOS specific ***

; *** minimOS executable header will go here ***

; *** startup code, minimOS specific stuff ***
; ** assume 8-bit register size, native mode **

	LDA #cdev-uz+2	; zeropage space needed, note cdev extra byte
#ifdef	SAFE
	CMP z_used		; check available zeropage space
	BCC go_emu		; more than enough space
	BEQ go_emu		; just enough!
nomem:
		_ABORT(FULL)	; not enough memory otherwise (rare) new interface
go_emu:
#endif
	STA z_used		; set required ZP space as required by minimOS
	.al: REP #$20	; 16 bit memory
	STZ w_rect		; no screen size required, 16 bit op?
	LDA #title		; address window title
	STA str_pt		; set parameter
	_KERNEL(OPEN_W)	; ask for a character I/O device
	BCC open_emu	; no errors
		_ABORT(NO_RSRC)	; abort otherwise!
#ifndef	SAFE
nomem:
		_ABORT(FULL)	; not enough memory
#endif
open_emu:
	STZ a65			; clear these (for MSBs)
	STZ x65			; clear these (for MSBs)
	STZ y65			; clear these (for MSBs)
	STZ cdev		; make sure MSB is zero!
	STY cdev		; store device!!!
; should try to allocate memory here
	STZ ma_rs		; will ask for...
	LDX #1
	STX ma_rs+2		; ...one full bank
	LDX #$FF		; bank aligned!
	STX ma_align
	STX p65			; *** trick to make sure B and reserved flag (aka M & X) stay set! ***
	_KERNEL(MALLOC)
		BCS nomem		; could not get a full bank
	LDX ma_pt+2		; where is the allocated bank?
	PHX
	PLB				; switch to that bank!
; *** *** MUST load virtual ROM from somewhere *** ***

; *** start the emulation! ***
reset65:
	.as: SEP #$20	; make sure memory in 8-bit mode
	.xl: REP #$10	; make sure index in 16-bit mode!
	LDX #2			; RST @ $FFFC
; standard interrupt handling, expects vector offset in X
x_vect:
	LDY $FFFA, X	; read appropriate vector as PC
	LDA p65			; original status
	ORA #%00100100	; disable further interrupts (and keep M set)...
	AND #%11100111	; ...and clear decimal flag (and X)!
	STA p65
	LDA #0			; clear B
	XBA

; *** main loop ***
execute:
		LDA !0, Y		; get opcode (5)
		ASL				; double it as will become pointer (2)
		TAX				; use as pointer with B zero, keeping carry (2)
		BCC lo_jump		; seems to have less opcodes with bit7 low... (2/3)
			JMP (opt_h, X)	; emulation routines for opcodes with bit7 hi (6)
lo_jump:
			JMP (opt_l, X)	; otherwise, emulation routines for opcodes with bit7 low

; *** NOP (2) arrives here, saving 3 bytes and 3 cycles ***

_ea:

; must add illegal NMOS opcodes (not yet used in NMOS) as NOPs

_02:_22:_42:_62:_82:_c2:_e2:
_03:_13:_23:_33:_43:_53:_63:_73:_83:_93:_a3:_b3:_c3:_d3:_e3:_f3:
_44:_54:_d4:_f4:
_0b:_1b:_2b:_3b:_4b:_5b:_6b:_7b:_8b:_9b:_ab:_bb:_eb:_fb:
_5c:_dc:_fc:

; continue execution via JMP next_op, will not arrive here otherwise
next_op:
		INY				; advance one byte (2)
		BNE execute		; fetch next instruction (3)

; usual overhead is 22 clock cycles, not including final jump (3)
; (*) PC-setting instructions like jumps save 5t

; if PC wraps, will abort emulation!

; *** proper exit point ***
v6exit:
; should I print anything?
	PHB				; current bank...
	PLA				; ...is MSB of pointer
	STA ma_pt+2
	STZ ma_pt+1
	STZ ma_pt		; this completes the pointer
	_KERNEL(FREE)	; release the virtual bank!
	LDY cdev		; in case is a window... reads extra byte
	_KERNEL(FREE_W)	; ...allow further examination
	_FINISH			; end without errors?



; *** window title, optional and minimOS specific ***
title:
	.asc	"virtua6502", 0
exit:
;	.asc 13, "{HLT}", 13, 0	; not yet used!!!


; *** interrupt support ***
; no unsupported opcodes on CMOS!

	.xl: .as:

nmi65:				; hardware interrupts, when available, to be checked AFTER incrementing PC
	LDX #0			; NMI @ $FFFA
	JMP int_stat	; save common status and execute
irq65:
_00:
	LDX #4			; both IRQ & BRK @ $FFFE
	LDA !0, Y		; check whether IRQ or BRK
	BEQ int_stat	; was soft, leave B flag on
		LDA #%00010000	; hard otherwise, clear B-flag
		TRB p65
int_stat:
; first save current PC into stack
	TYA				; get PC, affects B
	LDX s65			; and current SP, gets extra zero
	.al: REP #$20	; worth 16-bit
	DEX				; post-decrement
	STA $0100, X	; store in emulated stack
	DEX				; post-decrement
; now push current status
	LDA p65			; status... and zero for B
	.as: SEP #$20
	STA $0100, X	; store in emulated stack
	DEX				; post-decrement
	STX s65			; update SP, MSB should be zero
	JMP x_vect		; execute interrupt code


; ****************************************
; *** *** valid opcode definitions *** ***
; ****************************************

	.as: .xl:

; *** implicit instructions ***
; * flag settings *

_18:
; CLC
; +10
	LDA #1			; C flag...
	TRB p65			; gets cleared
	JMP next_op

_d8:
; CLD
; +10
	LDA #8			; D flag...
	TRB p65			; gets cleared
	JMP next_op

_58:
; CLI
; +10
	LDA #4			; I flag...
	TRB p65			; gets cleared
	JMP next_op

_b8:
; CLV
; +10
	LDA #$40		; V flag...
	TRB p65			; gets cleared
	JMP next_op

_38:
; SEC
; +10
	LDA #1			; C flag...
	TSB p65			; gets set
	JMP next_op

_f8:
; SED
; +10
	LDA #8			; D flag...
	TSB p65			; gets set
	JMP next_op
_78:
; SEI
; +10
	LDA #4			; I flag...
	TSB p65			; gets set
	JMP next_op

; * register inc/dec *

_ca:
; DEX
; +25
	DEC x65			; decrement index
	LDX x65			; check result, extra zero
; operation result in X (+16)
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_88:
; DEY
; +25
	DEC y65			; decrement index
	LDX y65			; check result

	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_e8:
; INX
; +25
	INC x65			; increment index
	LDX x65			; check result

	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_c8:
; INY
; +25
	INC y65			; increment index
	LDX y65			; check result

	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_3a:
; DEC [DEC A]
; +25
	DEC a65			; decrement A
	LDX a65			; check result

	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_1a:
; INC [INC A]
; +25
	INC a65			; increment A
	LDX a65			; check result

	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

; * register transfer *

_aa:
; TAX
; +24
	LDA a65			; copy accumulator...
	STA x65			; ...to index
; standard NZ setting (+18)
	TAX				; (value in X)
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_a8:
; TAY
; +24
	LDA a65			; copy accumulator...
	STA y65			; ...to index

	TAX
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_ba:
; TSX
; +24
	LDA s65			; copy stack pointer...
	STA x65			; ...to index

	TAX
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_8a:
; TXA
; +24
	LDA x65			; copy index...
	STA a65			; ...to accumulator

	TAX
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_9a:
; TXS
; +24
	LDA x65			; copy index...
	STA s65			; ...to stack pointer

	TAX
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_98:
; TYA
; +24
	LDA y65			; copy index...
	STA a65			; ...to accumulator

	TAX
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

; *** stack operations ***
; * push *

_48:
; PHA
; +20
	LDA a65			; get accumulator
; standard push of value in A, does not affect flags (+17)
	LDX s65			; and current SP, extra zero
	STA $0100, X	; push into stack
	DEC s65			; post-decrement
; all done
	JMP next_op

_da:
; PHX
; +20
	LDA x65			; get index

	LDX s65			; and current SP
	STA $0100, X	; push into stack
	DEC s65			; post-decrement
	JMP next_op

_5a:
; PHY
; +20
	LDA y65			; get index

	LDX s65			; and current SP
	STA $0100, X	; push into stack
	DEC s65			; post-decrement
	JMP next_op

_08:
; PHP
; +20
	LDA p65			; get status

	LDX s65			; and current SP
	STA $0100, X	; push into stack
	DEC s65			; post-decrement
	JMP next_op

; * pull *

_68:
; PLA
; +35
	INC s65			; pre-increment SP
	LDX s65			; use as index, extra zero
	LDA $0100, X	; pull from stack
	STA a65			; pulled value goes to A
; standard NZ flag setting
	TAX				; operation result in X
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_fa:
; PLX
; +35
	INC s65			; pre-increment SP
	LDX s65			; use as index
	LDA $0100, X	; pull from stack
	STA x65			; pulled value goes to X

	TAX				; operation result in X
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_7a:
; PLY
; +35
	INC s65			; pre-increment SP
	LDX s65			; use as index
	LDA $0100, X	; pull from stack
	STA y65			; pulled value goes to Y

	TAX				; operation result in X
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_28:
; PLP
; +35
	INC s65			; pre-increment SP
	LDX s65			; use as index
	LDA $0100, X	; pull from stack
	STA p65			; pulled value goes to PSR

	TAX				; operation result in X
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

; * return instructions *

_40:
; RTI
; +31*
	LDX s65			; get current SP, extra zero
	INX				; pre-increment
	LDA $0100, X	; pull from stack
	STA p65			; pulled value goes to PSR
	INX				; pre-increment
	LDY $0100, X	; pull from stack to PC
	INX				; skip MSB
	STX s65			; update SP, extra byte
; all done
	JMP execute		; PC already set!

_60:
; RTS
; +23*
	LDX s65			; get current SP, extra zero
	INX				; pre-increment
	LDY $0100, X	; pull full return address from stack
	INY				; correct it!
	INX				; skip both bytes
	STX s65			; update SP
; all done
	JMP execute		; PC already set!

; *** WDC-exclusive instructions ***

_db:
; STP
; +...
; should print some results or message...
	JMP v6exit		; stop emulation, this far

_cb:
; WAI
; +...
	BRA _db			; without proper interrupt support, just like STP

; *** bit testing ***

_89:
; BIT imm
; +22/22/23
	_PC_ADV			; get immediate operand, just INY
	LDA !0, Y
; absolute BIT does not use common code as no NV setting
	AND a65			; AND with memory
	BEQ g89z		; will set Z
		LDA #2			; or clear Z in previous status
		TRB p65			; updated
		JMP next_op
g89z:
	LDA #2			; set Z in previous status
	TSB p65			; updated
; all done
	JMP next_op

_24:
; BIT zp
; +42/42/50
	_PC_ADV			; get zeropage address
	LDA !0, Y		; cannot get extra byte!
	TAX				; temporary index...
; fastest common BIT code (+33/33/41)
	LDA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	TAX				; keep this
	AND #$C0		; only two highest bits
	STA tmp			; temporary storage to be ORed
	LDA p65			; previous status...
	AND #%00111101	; ...minus NVZ...
	ORA tmp			; and copy NV from operand
	STA p65
	TXA				; retrieve operand
	AND a65			; AND with accumulator
	BEQ g24z
		JMP next_op		; all done if not Z
g24z:
	LDA #2			; otherwise set Z
	TSB p65

	JMP next_op

_34:
; BIT zp, X
; +47/47/55
	_PC_ADV			; get zeropage address
	LDA !0, Y		; cannot get extra byte!
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	LDA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	TAX				; keep this
	AND #$C0		; only two highest bits
	STA tmp			; temporary storage to be ORed
	LDA p65			; previous status...
	AND #%00111101	; ...minus NVZ...
	ORA tmp			; and copy NV from operand
	STA p65
	TXA				; retrieve operand
	AND a65			; AND with accumulator
	BEQ g34z
		JMP next_op		; all done if not Z
g34z:
	LDA #2			; otherwise set Z
	TSB p65
	JMP next_op

_2c:
; BIT abs
; +43/43/51
	_PC_ADV			; point to operand
	LDX !0, Y		; just full address!
	_PC_ADV			; skip MSB

	LDA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	TAX				; keep this
	AND #$C0		; only two highest bits
	STA tmp			; temporary storage to be ORed
	LDA p65			; previous status...
	AND #%00111101	; ...minus NVZ...
	ORA tmp			; and copy NV from operand
	STA p65
	TXA				; retrieve operand
	AND a65			; AND with accumulator
	BEQ g2cz
		JMP next_op		; all done if not Z
g2cz:
	LDA #2			; otherwise set Z
	TSB p65
	JMP next_op

_3c:
; BIT abs, X
; +58/58/66
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	LDA !0, X		; get final data
	TAX				; keep this
	AND #$C0		; only two highest bits
	STA tmp			; temporary storage to be ORed
	LDA p65			; previous status...
	AND #%00111101	; ...minus NVZ...
	ORA tmp			; and copy NV from operand
	STA p65
	TXA				; retrieve operand
	AND a65			; AND with accumulator
	BEQ g3cz
		JMP next_op		; all done if not Z
g3cz:
	LDA #2			; otherwise set Z
	TSB p65
	JMP next_op

; *** jumps ***
; * conditional branches *

_90:
; BCC rel
; +13 if not taken
; +// * if taken
	_PC_ADV			; PREPARE relative address
	LDA #1			; will check C flag
	BIT p65
	BNE g90			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
g90:
	JMP next_op

_b0:
; BCS rel
; +13 if not taken
; +// * if taken
	_PC_ADV			; PREPARE relative address
	LDA #1			; will check C flag
	BIT p65
	BEQ gb0			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
gb0:
	JMP next_op

_30:
; BMI rel
; +13 if not taken
; +// * if taken
	_PC_ADV			; PREPARE relative address
	LDA #128		; will check N flag
	BIT p65
	BEQ g30			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
g30:
	JMP next_op

_10:
; BPL rel
; +13 if not taken
; +// * if taken
	_PC_ADV			; PREPARE relative address
	LDA #128		; will check N flag
	BIT p65
	BNE g10			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
g10:
	JMP next_op

_f0:
; BEQ rel
; +13 if not taken
; +// * if taken
	_PC_ADV			; PREPARE relative address
	LDA #2			; will check Z flag
	BIT p65
	BEQ gf0			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
gf0:
	JMP next_op

_d0:
; BNE rel
; +13 if not taken
; +// * if taken
	_PC_ADV			; PREPARE relative address
	LDA #2			; will check Z flag
	BIT p65
	BNE gd0			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
gd0:
	JMP next_op

_50:
; BVC rel
; +13 if not taken
; +// * if taken
	_PC_ADV			; PREPARE relative address
	LDA #64			; will check V flag
	BIT p65
	BNE g50			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
g50:
	JMP next_op

_70:
; BVS rel
; +13 if not taken
; +// * if taken
	_PC_ADV			; PREPARE relative address
	LDA #64			; will check V flag
	BIT p65
	BNE g70			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
g70:
	JMP next_op

_80:
; BRA rel
; +// *
	_PC_ADV			; get relative address
; *** to do *** to do *** to do *** to do ***
	JMP execute		; PC is ready!

; * absolute jumps *

_4c:
; JMP abs
; +13*
	_PC_ADV			; point to operand
	LDX !0, Y		; full address!
	TXY				; pointer is ready!
	JMP execute

_6c:
; JMP indirect
; +17*
	_PC_ADV			; point to pointer
	LDX !0, Y		; full address!
	LDY !0, X		; and destination ready!
	JMP execute

_7c:
; JMP indirect indexed
; +32*
	_PC_ADV			; point to pointer
	.al: REP #$21	; 16-bit... and CLC
	LDA !0, Y		; full table address!
	ADC x65			; indexing, extra byte
	TAX				; final address
	LDA #0			; must clear B
	.as: SEP #$20
	LDY !0, X		; and destination ready!
	JMP execute

; * subroutine call *

_20:
; JSR abs
; +44*
	_PC_ADV			; point to addeess
; first compute return address
	.al: REP #$20
	TYA				; copy PC...
	INC				; at MSB
; push the CURRENT address as we are at the last byte of the instruction
	LDX s65			; current SP with extra
	DEX				; LSB location
	STA !$0100, X	; return address into virtual stack
	DEX				; post-decrement
	STX s65			; update SP
	LDA #0			; clear B
	.as: SEP #20
; jump to destination
	LDX !0, Y		; target address
	TXY				; ready!
	JMP execute

; *** load / store ***

; * load *

_a2:
; LDX imm
; +28
	_PC_ADV			; get immediate operand
	LDA !0, Y
	STA x65			; update register
; standard NZ flag setting (+18)
	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_a6:
; LDX zp
; +35
	_PC_ADV			; get zeropage address
	LDA !0, Y		; temporary index...
	TAX				; ...cannot pick extra...
	LDA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA x65			; update register

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_b6:
; LDX zp, Y
; +40
	_PC_ADV			; get zeropage address
	LDA !0, Y		; temporary index...
	CLC
	ADC y65			; add index, forget carry as will page-wrap
	TAX				; ...cannot pick extra...
	LDA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA x65			; update register

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_ae:
; LDX abs
; +36
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
	LDA !0, X		; load operand
	STA x65			; update register

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_be:
; LDX abs, Y
; +51
	_PC_ADV			; get address
	.al: REP #21	; 16-b... and CLC
	LDA !0, Y		; base address
	ADC y65			; pluss offset & extra
	_PC_ADV			; skip MSB
	TAX				; final address
	LDA #0			; clear B
	.as: SEP #$20
	LDA !0, X		; load operand
	STA x65			; update register

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_a0:
; LDY imm
; +28
	_PC_ADV			; get immediate operand
	LDA !0, Y
	STA x65			; update register

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_a4:
; LDY zp
; +35
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA y65			; update register

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_b4:
; LDY zp, X
; +40
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...
	LDA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA y65			; update register

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_ac:
; LDY abs
; +36
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
	LDA !0, X		; load operand
	STA y65			; update register

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_bc:
; LDY abs, X
; +51
	_PC_ADV			; get address
	.al: REP #21		; 16-b... and CLC
	LDA !0, Y		; base address
	ADC x65			; pluss offset & extra
	_PC_ADV			; skip MSB
	TAX				; final address
	LDA #0			; clear B
	.as: SEP #$20
	LDA !0, X		; load operand
	STA y65			; update register

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_a9:
; LDA imm
; +28
	_PC_ADV			; get immediate operand
	LDA !0, Y
	STA a65			; update register

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_a5:
; LDA zp
; +35
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA a65			; update register

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_b5:
; LDA zp, X
; +40
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...
	LDA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA a65			; update register

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_ad:
; LDA abs
; +36
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
	LDA !0, X		; load operand
	STA a65			; update register

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_bd:
; LDA abs, X
; +51
	_PC_ADV			; get address
	.al: REP #21	; 16-b... and CLC
	LDA !0, Y		; base address
	ADC x65			; pluss offset & extra
	_PC_ADV			; skip MSB
	TAX				; final address
	LDA #0			; clear B
	.as: SEP #$20
	LDA !0, X		; load operand
	STA a65			; update register

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_b9:
; LDA abs, Y
; +51
	_PC_ADV			; get address
	.al: REP #21	; 16-b... and CLC
	LDA !0, Y		; base address
	ADC y65			; pluss offset & extra
	_PC_ADV			; skip MSB
	TAX				; final address
	LDA #0			; clear B
	.as: SEP #$20
	LDA !0, X		; load operand
	STA a65			; update register

	TAX			; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_b2:
; LDA (zp)
; +52
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	TAX				; temporary index...
	.al: REP #$20
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20
	LDA !0, X		; ...of final data
	STA a65			; update register

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_b1:
; LDA (zp), Y
; +56
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	TAX				; temporary index...
	.al: REP #$21	; 16b & CLC
	LDA !0, X		; ...pick full pointer from emulated zeropage
	ADC y65			; indexed plus extra
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20
	LDA !0, X		; ...of final data
	STA a65			; update register

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_a1:
; LDA (zp, X)
; +56
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	.al: REP #$21	; 16b & CLC
	ADC x65			; preindexing, worth picking extra
	TAX				; temporary index...
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20
	LDA !0, X		; ...of final data
	STA a65			; update register

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

; * store *

_86:
; STX zp
; +20
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	LDA x65			; value to be stored
	STA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_96:
; STX zp, Y
; +25
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC y65			; add offset
	TAX				; temporary index...

	LDA x65			; value to be stored
	STA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_8e:
; STX abs
; +21
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB

	LDA x65			; value to be stored
	STA !0, X		; store operand
	JMP next_op

_84:
; STY zp
; +20
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	LDA y65			; value to be stored
	STA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_94:
; STY zp, X
; +25
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add offset
	TAX				; temporary index...

	LDA y65			; value to be stored
	STA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_8c:
; STY abs
; +21
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB

	LDA y65			; value to be stored
	STA !0, X		; store operand
	JMP next_op

_64:
; STZ zp
; +17
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	STZ !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_74:
; STZ zp, X
; +22
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add offset
	TAX				; temporary index...

	STZ !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_9c:
; STZ abs
; +18
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB

	STZ !0, X		; store operand
	JMP next_op

_9e:
; STZ abs, X
; +33
	_PC_ADV			; get address
	.al: REP #21	; 16-b... and CLC
	LDA !0, Y		; base address
	ADC x65			; pluss offset & extra
	_PC_ADV			; skip MSB
	TAX				; final address
	LDA #0			; clear B
	.as: SEP #$20

	STZ !0, X		; clear destination
	JMP next_op

_8d:
; STA abs
; +21
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB

	LDA a65			; value to be stored
	STA !0, X		; store operand
	JMP next_op

_9d:
; STA abs, X
; +36
	_PC_ADV			; get address
	.al: REP #21	; 16-b... and CLC
	LDA !0, Y		; base address
	ADC x65			; plus offset & extra
	_PC_ADV			; skip MSB
	TAX				; final address
	LDA #0			; clear B
	.as: SEP #$20

	LDA a65			; value to be stored
	STA !0, X		; store destination
	JMP next_op

_99:
; STA abs, Y
; +36
	_PC_ADV			; get address
	.al: REP #21	; 16-b... and CLC
	LDA !0, Y		; base address
	ADC y65			; plus offset & extra
	_PC_ADV			; skip MSB
	TAX				; final address
	LDA #0			; clear B
	.as: SEP #$20

	LDA a65			; value to be stored
	STA !0, X		; store destination
	JMP next_op

_85:
; STA zp
; +20
	_PC_ADV			; get zeropage address
	LDA !0, Y		; base address
	TAX				; temporary index...

	LDA a65			; value to be stored
	STA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_95:
; STA zp, X
; +25
	_PC_ADV			; get zeropage address
	LDA !0, Y		; base address
	CLC
	ADC x65			; add index
	TAX				; temporary index...

	LDA a65			; value to be stored
	STA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_92:
; STA (zp)
; +37
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	TAX				; temporary index...
	.al: REP #$20
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	LDA a65			; value to be stored
	STA !0, X		; ...as final data
	JMP next_op

_91:
; STA (zp), Y
; +41
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	TAX				; temporary index...
	.al: REP #$21	; 16b & CLC
	LDA !0, X		; ...pick full pointer from emulated zeropage
	ADC y65			; indexed
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	LDA a65			; value to be stored
	STA !0, X		; ...as final data
	JMP next_op

_81:
; STA (zp, X)
; +41
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	.al: REP #$21	; 16b & CLC
	ADC x65			; preindexing, worth picking extra
	TAX				; temporary index...
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	LDA a65			; value to be stored
	STA !0, X		; ...as final data
	JMP next_op

; *** logic ops ***
; * and *

_29:
; AND imm
; +31
	_PC_ADV			; get immediate operand
	LDA !0, Y
; worth using TYX in COMPACT version
	AND a65			; do AND
	STA a65			; eeeeeeeeeeeeek
; standard NZ flag setting (+18)
	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_25:
; AND zp
; +38
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	LDA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	AND a65			; do AND
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_35:
; AND zp, X
; +43
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	LDA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	AND a65			; do AND
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_2d:
; AND abs
; +39
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB

	LDA !0, X		; read operand
	AND a65			; do AND
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_3d:
; AND abs, X
; +54
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	LDA !0, X		; get final data
	AND a65			; do AND
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_39:
; AND abs, Y
; +54
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC y65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	LDA !0, X		; get final data
	AND a65			; do AND
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_32:
; AND (zp)
; +55
	_PC_ADV			; get zeropage pointer
	LDA !0, Y		; cannot pick extra
	TAX				; temporary index...
	.al: REP #$20
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	LDA !0, X		; read operand
	AND a65			; do AND
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_31:
; AND (zp), Y
; +59
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	TAX				; temporary index...
	.al: REP #$21	; 16b & CLC
	LDA !0, X		; ...pick full pointer from emulated zeropage
	ADC y65			; indexed
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	LDA !0, X		; final data
	AND a65			; do AND
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_21:
; AND (zp, X)
; +59
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	.al: REP #$21	; 16b & CLC
	ADC x65			; preindexing, worth picking extra
	TAX				; temporary index...
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	LDA !0, X		; ...final data
	AND a65			; do AND
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

; * inclusive or *

_09:
; ORA imm
; +31
	_PC_ADV			; get immediate operand
	LDA !0, Y
; worth using TYX in compact
	ORA a65			; do OR
	STA a65			; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_05:
; ORA zp
; +38
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	LDA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	ORA a65			; do OR
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_15:
; ORA zp, X
; +43
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	LDA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	ORA a65			; do OR
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_0d:
; ORA abs
; +39
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB

	LDA !0, X		; read operand
	ORA a65			; do OR
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_1d:
; ORA abs, X
; +54
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	LDA !0, X		; get final data
	ORA a65			; do OR
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_19:
; ORA abs, Y
; +54
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC y65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	LDA !0, X		; get final data
	ORA a65			; do OR
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_12:
; ORA (zp)
; +55
	_PC_ADV			; get zeropage pointer
	LDA !0, Y		; cannot pick extra
	TAX				; temporary index...
	.al: REP #$20
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	LDA !0, X		; read operand
	ORA a65			; do OR
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_11:
; ORA (zp), Y
; +59
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	TAX				; temporary index...
	.al: REP #$21	; 16b & CLC
	LDA !0, X		; ...pick full pointer from emulated zeropage
	ADC y65			; indexed
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	LDA !0, X		; final data
	ORA a65			; do OR
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_01:
; ORA (zp, X)
; +59
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	.al: REP #$21	; 16b & CLC
	ADC x65			; preindexing, worth picking extra
	TAX				; temporary index...
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	LDA !0, X		; ...final data
	ORA a65			; do OR
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

; * exclusive or *

_49:
; EOR imm
; +31
	_PC_ADV			; get immediate operand
	LDA !0, Y
; worth TYX in compact
	EOR a65			; do XOR
	STA a65			; eeeeeeeeeeeeek
; standard NZ flag setting
	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_45:
; EOR zp
; +38
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	LDA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	EOR a65			; do XOR
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_55:
; EOR zp, X
; +43
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	LDA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	EOR a65			; do XOR
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_4d:
; EOR abs
; +39
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB

	LDA !0, X		; read operand
	EOR a65			; do XOR
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_5d:
; EOR abs, X
; +54
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	LDA !0, X		; get final data
	EOR a65			; do XOR
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_59:
; EOR abs, Y
; +54
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC y65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	LDA !0, X		; get final data
	EOR a65			; do XOR
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_52:
; EOR (zp)
; +55
	_PC_ADV			; get zeropage pointer
	LDA !0, Y		; cannot pick extra
	TAX				; temporary index...
	.al: REP #$20
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	LDA !0, X		; read operand
	EOR a65			; do XOR
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_51:
; EOR (zp), Y
; +59
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	TAX				; temporary index...
	.al: REP #$21	; 16b & CLC
	LDA !0, X		; ...pick full pointer from emulated zeropage
	ADC y65			; indexed
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	LDA !0, X		; final data
	EOR a65			; do XOR
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_41:
; EOR (zp, X)
; +59
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	.al: REP #$21	; 16b & CLC
	ADC x65			; preindexing, worth picking extra
	TAX				; temporary index...
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	LDA !0, X		; ...final data
	EOR a65			; do XOR
	STA a65			; eeeeeeeeeeeeek

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

; *** arithmetic ***
; * add with carry *

_69:
; ADC imm
; +49
	_PC_ADV			; seek immediate operand
; copy virtual status (+47)
	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
; proceed
	LDA !0, Y		; worth TYX in compact
	ADC a65			; do add
	STA a65			; update value
; with so many flags to set, best sync with virtual P (minus X-flag!)
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
; all done
	JMP next_op

_65:
; ADC zp
; +56
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA !0, X		; from emulated zeropage
	ADC a65			; do add
	STA a65			; update value
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_75:
; ADC zp, X
; +61
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA !0, X		; from emulated zeropage
	ADC a65			; do add
	STA a65			; update value
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_6d:
; ADC abs
; +57
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA !0, X		; read operand
	ADC a65			; do add
	STA a65			; update value
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_7d:
; ADC abs, X
; +72
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA !0, X		; get final data
	ADC a65			; do add
	STA a65			; update value
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_79:
; ADC abs, Y
; +72
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC y65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA !0, X		; get final data
	ADC a65			; do add
	STA a65			; update value
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_72:
; ADC (zp)
; +73
	_PC_ADV			; get zeropage pointer
	LDA !0, Y		; cannot pick extra
	TAX				; temporary index...
	.al: REP #$20
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA !0, X		; read operand
	ADC a65			; do add
	STA a65			; update value
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_71:
; ADC (zp), Y
; +77
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	TAX				; temporary index...
	.al: REP #$21	; 16b & CLC
	LDA !0, X		; ...pick full pointer from emulated zeropage
	ADC y65			; indexed
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA !0, X		; final data
	ADC a65			; do add
	STA a65			; update value
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_61:
; ADC (zp, X)
; +77
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	.al: REP #$21	; 16b & CLC
	ADC x65			; preindexing, worth picking extra
	TAX				; temporary index...
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA !0, X		; ...final data
	ADC a65			; do add
	STA a65			; update value
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

; * subtract with borrow *

_e9:
; SBC imm
; +49
	_PC_ADV			; PREPARE immediate operand
; copy virtual status (+47)
	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
; proceed
	LDA a65
	SBC !0, Y		; subtract operand, worth TYX in compact
	STA a65			; update value
; with so many flags to set, best sync with virtual P (minus X-flag!)
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
; all done
	JMP next_op

_e5:
; SBC zp
; +56
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA a65
	SBC !0, X		; subtract operand
	STA a65			; update value
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_f5:
; SBC zp, X
; +61
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA a65
	SBC !0, X		; subtract operand
	STA a65			; update value
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_ed:
; SBC abs
; +57
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA a65
	SBC !0, X		; subtract operand
	STA a65			; update value
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_fd:
; SBC abs, X
; +72
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA a65
	SBC !0, X		; subtract operand
	STA a65			; update value
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_f9:
; SBC abs, Y
; +72
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA a65
	SBC !0, X		; subtract operand
	STA a65			; update value
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_f2:
; SBC (zp)
; +73
	_PC_ADV			; get zeropage pointer
	LDA !0, Y		; cannot pick extra
	TAX				; temporary index...
	.al: REP #$20
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA a65
	SBC !0, X		; subtract operand
	STA a65			; update value
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_f1:
; SBC (zp), Y
; +77
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	TAX				; temporary index...
	.al: REP #$21	; 16b & CLC
	LDA !0, X		; ...pick full pointer from emulated zeropage
	ADC y65			; indexed
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA a65
	SBC !0, X		; subtract operand
	STA a65			; update value
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_e1:
; SBC (zp, X)
; +77
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	.al: REP #$21	; 16b & CLC
	ADC x65			; preindexing, worth picking extra
	TAX				; temporary index...
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA a65
	SBC !0, X		; subtract operand
	STA a65			; update value
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

; * inc/dec memory *

_e6:
; INC zp
; +39
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	INC !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	LDA !0, X		; retrieve value
; standard NZ flag setting (+18)
	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_f6:
; INC zp, X
; +44
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	INC !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	LDA !0, X		; retrieve value

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_ee:
; INC abs
; +40
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB

	INC !0, X		; update operand
	LDA !0, X		; retrieve value

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_fe:
; INC abs, X
; +55
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	INC !0, X		; update final data
	LDA !0, X		; retrieve value

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_c6:
; DEC zp
; +39
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	DEC !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	LDA !0, X		; retrieve value

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_d6:
; DEC zp, X
; +44
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	DEC !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	LDA !0, X		; retrieve value

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_ce:
; DEC abs
; +40
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB

	DEC !0, X		; update operand
	LDA !0, X		; retrieve value

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

_de:
; DEC abs, X
; +55
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	DEC !0, X		; update final data
	LDA !0, X		; retrieve value

	TAX				; index for LUT
	LDA p65			; previous status...
	AND #$7D		; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
	JMP next_op

; * comparisons *

_cd:
; CMP abs
; +54
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
; copy virtual status (+44) common CMP code
	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
; proceed
	LDA a65			; from accumulator...
	CMP !0, X		; ...do comparison
; with so many flags to set, best sync with virtual P (minus X-flag!)
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
; all done
	JMP next_op

_dd:
; CMP abs, X
; +68
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA a65			; from accumulator...
	CMP !0, X		; ...do comparison
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_d9:
; CMP abs, Y
; +68
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA a65			; from accumulator...
	CMP !0, X		; ...do comparison
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_c9:
; CMP imm
; +46
	_PC_ADV			; get immediate operand
; somewhat special code, same speed (TYX worth on compact version)
	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA a65			; from accumulator...
	CMP !0, Y		; ...do comparison (immediate)
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_c5:
; CMP zp
; +53
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA a65			; from accumulator...
	CMP !0, X		; ...do comparison
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_d5:
; CMP zp, X
; +58
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA a65			; from accumulator...
	CMP !0, X		; ...do comparison
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_d2:
; CMP (zp)
; +70
	_PC_ADV			; get zeropage pointer
	LDA !0, Y		; cannot pick extra
	TAX				; temporary index...
	.al: REP #$20
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA a65			; from accumulator...
	CMP !0, X		; ...do comparison
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_d1:
; CMP (zp), Y
; +74
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	TAX				; temporary index...
	.al: REP #$21	; 16b & CLC
	LDA !0, X		; ...pick full pointer from emulated zeropage
	ADC y65			; indexed
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA a65			; from accumulator...
	CMP !0, X		; ...do comparison
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_c1:
; CMP (zp, X)
; +74
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	.al: REP #$21	; 16b & CLC
	ADC x65			; preindexing, worth picking extra
	TAX				; temporary index...
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA a65			; from accumulator...
	CMP !0, X		; ...do comparison
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_ec:
; CPX abs
; +54
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
; copy virtual status (+44) common CPX code
	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
; proceed
	LDA x65			; from X...
	CMP !0, X		; ...do comparison
; with so many flags to set, best sync with virtual P (minus X-flag!)
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
; all done
	JMP next_op

_e0:
; CPX imm
; +46
	_PC_ADV			; get immediate operand
; adapted code
	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA x65			; from X...
	CMP !0, Y		; ...do comparison (immediate)
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_e4:
; CPX zp
; +53
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA x65			; from X...
	CMP !0, X		; ...do comparison
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_cc:
; CPY abs
; +54
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
; copy virtual status (+44) common CPY code
	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
; proceed
	LDA y65			; from Y...
	CMP !0, X		; ...do comparison
; with so many flags to set, best sync with virtual P (minus X-flag!)
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
; all done
	JMP next_op

_c0:
; CPY imm
; +46
	_PC_ADV			; get immediate operand
; adapted code
	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA y65			; from Y...
	CMP !0, Y		; ...do comparison (immediate)
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

_c4:
; CPY zp
; +53
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
	LDA y65			; from Y...
	CMP !0, X		; ...do comparison
	PHP				; new status
	PLA
	ORA #$10		; this puts B-flag back to 1
	STA p65			; update virtual
	PLP
	JMP next_op

; *** bit shifting ***
; * shift *

_0e:
; ASL abs
; +42
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
; common ASL code, address in X (+32)
	ASL !0, X		; shift destination
	LDA !0, X		; get result...
	TAX				; LUT index
	LDA p65			; original status
	AND #$7C		; ...minus NZC!
	ORA nz_lut, X	; ...adds flag mask
	ADC #0			; and C, if set!
	STA p65
	JMP next_op

_1e:
; ASL abs, X
; +57
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	ASL !0, X		; shift destination
	LDA !0, X		; get result...
	TAX				; LUT index
	LDA p65			; original status
	AND #$7C		; ...minus NZC!
	ORA nz_lut, X	; ...adds flag mask
	ADC #0			; and C, if set!
	STA p65
	JMP next_op

_0a:
; ASL [ASL A]
; +28
	ASL a65			; shift accumulator
	LDA a65			; get result, cannot pick extra
; common part
	TAX				; LUT index
	LDA p65			; original status
	AND #$7C		; ...minus NZC!
	ORA nz_lut, X	; ...adds flag mask
	ADC #0			; and C, if set!
	STA p65
	JMP next_op

_06:
; ASL zp
; +41
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	ASL !0, X		; shift destination
	LDA !0, X		; get result...
	TAX				; LUT index
	LDA p65			; original status
	AND #$7C		; ...minus NZC!
	ORA nz_lut, X	; ...adds flag mask
	ADC #0			; and C, if set!
	STA p65
	JMP next_op

_16:
; ASL zp, X
; +46
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	ASL !0, X		; shift destination
	LDA !0, X		; get result...
	TAX				; LUT index
	LDA p65			; original status
	AND #$7C		; ...minus NZC!
	ORA nz_lut, X	; ...adds flag mask
	ADC #0			; and C, if set!
	STA p65
	JMP next_op

_4e:
; LSR abs
; +42
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
; common LSR code, address in X (+32)
	LSR !0, X		; shift destination
	LDA !0, X		; get result...
	TAX				; LUT index
	LDA p65			; original status
	AND #$7C		; ...minus NZC!
	ORA nz_lut, X	; ...adds flag mask
	ADC #0			; and C, if set!
	STA p65
	JMP next_op

_5e:
; LSR abs, X
; +57
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	LSR !0, X		; shift destination
	LDA !0, X		; get result...
	TAX				; LUT index
	LDA p65			; original status
	AND #$7C		; ...minus NZC!
	ORA nz_lut, X	; ...adds flag mask
	ADC #0			; and C, if set!
	STA p65
	JMP next_op

_4a:
; LSR [LSR A]
; +28
	LSR a65			; shift destination
	LDA a65			; get result...
; specific code
	TAX				; LUT index
	LDA p65			; original status
	AND #$7C		; ...minus NZC!
	ORA nz_lut, X	; ...adds flag mask
	ADC #0			; and C, if set!
	STA p65
	JMP next_op

_46:
; LSR zp
; +41
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	LSR !0, X		; shift destination
	LDA !0, X		; get result...
	TAX				; LUT index
	LDA p65			; original status
	AND #$7C		; ...minus NZC!
	ORA nz_lut, X	; ...adds flag mask
	ADC #0			; and C, if set!
	STA p65
	JMP next_op

_56:
; LSR zp, X
; +46
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	LSR !0, X		; shift destination
	LDA !0, X		; get result...
	TAX				; LUT index
	LDA p65			; original status
	AND #$7C		; ...minus NZC!
	ORA nz_lut, X	; ...adds flag mask
	ADC #0			; and C, if set!
	STA p65
	JMP next_op

; * rotation *

_2e:
; ROL abs
; +47
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
; common ROL code, address in X (+37)
	LSR p65			; extract previous C
	ROL !0, X		; rotate destination
	LDA !0, X		; get result...
	TAX				; LUT index
	LDA p65			; original SHIFTED status
	AND #$3E		; ...minus NZC! Note shift
	ROL				; unshift and insert C
	ORA nz_lut, X	; add flag mask
	STA p65
	JMP next_op

_3e:
; ROL abs, X
; +62
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	LSR p65			; extract previous C
	ROL !0, X		; rotate destination
	LDA !0, X		; get result...
	TAX				; LUT index
	LDA p65			; original SHIFTED status
	AND #$3E		; ...minus NZC! Note shift
	ROL				; unshift and insert C
	ORA nz_lut, X	; add flag mask
	STA p65
	JMP next_op

_2a:
; ROL [ROL A]
; +33

	LSR p65			; extract previous C
	ROL a65			; rotate destination
	LDA a65			; get result...
; common part
	TAX				; LUT index
	LDA p65			; original SHIFTED status
	AND #$3E		; ...minus NZC! Note shift
	ROL				; unshift and insert C
	ORA nz_lut, X	; add flag mask
	STA p65
	JMP next_op

_26:
; ROL zp
; +46
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	LSR p65			; extract previous C
	ROL !0, X		; rotate destination
	LDA !0, X		; get result...
	TAX				; LUT index
	LDA p65			; original SHIFTED status
	AND #$3E		; ...minus NZC! Note shift
	ROL				; unshift and insert C
	ORA nz_lut, X	; add flag mask
	STA p65
	JMP next_op

_36:
; ROL zp, X
; +51
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	LSR p65			; extract previous C
	ROL !0, X		; rotate destination
	LDA !0, X		; get result...
	TAX				; LUT index
	LDA p65			; original SHIFTED status
	AND #$3E		; ...minus NZC! Note shift
	ROL				; unshift and insert C
	ORA nz_lut, X	; add flag mask
	STA p65
	JMP next_op

_6e:
; ROR abs
; +47
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
; common ROR code, address in X (+37)
	LSR p65			; extract previous C
	ROR !0, X		; rotate destination
	LDA !0, X		; get result...
	TAX				; LUT index
	LDA p65			; original SHIFTED status
	AND #$3E		; ...minus NZC! Note shift
	ROL				; unshift and insert C
	ORA nz_lut, X	; add flag mask
	STA p65
	JMP next_op

_7e:
; ROR abs, X
; +62
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	LSR p65			; extract previous C
	ROR !0, X		; rotate destination
	LDA !0, X		; get result...
	TAX				; LUT index
	LDA p65			; original SHIFTED status
	AND #$3E		; ...minus NZC! Note shift
	ROL				; unshift and insert C
	ORA nz_lut, X	; add flag mask
	STA p65
	JMP next_op

_6a:
; ROR [ROR A]
; +33

	LSR p65			; extract previous C
	ROR a65			; rotate destination
	LDA a65			; get result...
	TAX				; LUT index
	LDA p65			; original SHIFTED status
	AND #$3E		; ...minus NZC! Note shift
	ROL				; unshift and insert C
	ORA nz_lut, X	; add flag mask
	STA p65
	JMP next_op

_66:
; ROR zp
; +46
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	LSR p65			; extract previous C
	ROR !0, X		; rotate destination
	LDA !0, X		; get result...
	TAX				; LUT index
	LDA p65			; original SHIFTED status
	AND #$3E		; ...minus NZC! Note shift
	ROL				; unshift and insert C
	ORA nz_lut, X	; add flag mask
	STA p65
	JMP next_op

_76:
; ROR zp, X
; +51
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	LSR p65			; extract previous C
	ROR !0, X		; rotate destination
	LDA !0, X		; get result...
	TAX				; LUT index
	LDA p65			; original SHIFTED status
	AND #$3E		; ...minus NZC! Note shift
	ROL				; unshift and insert C
	ORA nz_lut, X	; add flag mask
	STA p65
	JMP next_op

; *** bit handling ***
; * test & lock *

_1c:
; TRB abs
; +51/51/52
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
; common native TRB routine 30b (+37-39) BEST
	LDA !0, X		; get operand
	STA tmp			; must be accesible
	LDA a65			; get mask
	TRB tmp			; proceed natively
	BEQ g1cz		; will set Z
		LDA #2			; or clear Z in previous status
		TRB p65			; updated
		JMP g1cu
g1cz:
	LDA #2			; set Z in previous status
	TSB p65			; updated
g1cu:
	LDA tmp			; write final value
	STA !0, X
	JMP next_op

_14:
; TRB zp
; +
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	LDA !0, X		; get operand
	STA tmp			; must be accesible
	LDA a65			; get mask
	TRB tmp			; proceed natively
	BEQ g14z		; will set Z
		LDA #2			; or clear Z in previous status
		TRB p65			; updated
		JMP g14u
g14z:
	LDA #2			; set Z in previous status
	TSB p65			; updated
g14u:
	LDA tmp			; write final value
	STA !0, X
	JMP next_op

_0c:
; TSB abs
; +
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
; common TSB routine (+34-35) 30b
	LDA !0, X		; get operand
	STA tmp			; save for later
	ORA a65			; set selected bits
	STA !0, X
	LDA tmp			; retrieve
	AND a65			; test selected bits
	BEQ g0c			; will set Z
		LDA #2			; or clear Z in previous status
		TRB p65			; updated
		JMP next_op
g0c:
	LDA #2			; set Z in previous status
	TSB p65			; updated
	JMP next_op

_04:
; TSB zp
; +
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	LDA !0, X		; get operand
	STA tmp			; save for later
	ORA a65			; set selected bits
	STA !0, X
	LDA tmp			; retrieve
	AND a65			; test selected bits
	BEQ g04			; will set Z
		LDA #2			; or clear Z in previous status
		TRB p65			; updated
		JMP next_op
g04:
	LDA #2			; set Z in previous status
	TSB p65			; updated
	JMP next_op


; *** Rockwell/WDC exclusive ***
; * (re)set bits *

_07:
; RMB0 zp
; +24
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #%11111110	; REVERSE mask for bit 0
; common RMB, reverse mask in A, address in X (+13)
	AND !0, X		; keep all but selected
	STA !0, X
	JMP next_op

_17:
; RMB1 zp
; +24
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #%11111101	; REVERSE mask for bit 1

	AND !0, X		; keep all but selected
	STA !0, X
	JMP next_op

_27:
; RMB2 zp
; +24
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #%11111011	; REVERSE mask for bit 2

	AND !0, X		; keep all but selected
	STA !0, X
	JMP next_op

_37:
; RMB3 zp
; +24
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #%11110111	; REVERSE mask for bit 3

	AND !0, X		; keep all but selected
	STA !0, X
	JMP next_op

_47:
; RMB4 zp
; +24
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #%11101111	; REVERSE mask for bit 4

	AND !0, X		; keep all but selected
	STA !0, X
	JMP next_op

_57:
; RMB5 zp
; +24
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #%11011111	; REVERSE mask for bit 5

	AND !0, X		; keep all but selected
	STA !0, X
	JMP next_op

_67:
; RMB6 zp
; +24
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #%10111111	; REVERSE mask for bit 6

	AND !0, X		; keep all but selected
	STA !0, X
	JMP next_op

_77:
; RMB7 zp
; +24
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #%01111111	; REVERSE mask for bit 7

	AND !0, X		; keep all but selected
	STA !0, X
	JMP next_op

_87:
; SMB0 zp
; +24
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #1			; mask for bit 0
; common SMB, mask in A, address in X (+13)
	ORA !0, X		; set selected
	STA !0, X
	JMP next_op

_97:
; SMB1 zp
; +24
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #2			; mask for bit 1
; common SMB, mask in A, address in X (+13)
	ORA !0, X		; set selected
	STA !0, X
	JMP next_op

_a7:
; SMB2 zp
; +24
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #4			; mask for bit 2
; common SMB, mask in A, address in X (+13)
	ORA !0, X		; set selected
	STA !0, X
	JMP next_op

_b7:
; SMB3 zp
; +24
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #8			; mask for bit 3
; common SMB, mask in A, address in X (+13)
	ORA !0, X		; set selected
	STA !0, X
	JMP next_op

_c7:
; SMB4 zp
; +24
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #16			; mask for bit 4
; common SMB, mask in A, address in X (+13)
	ORA !0, X		; set selected
	STA !0, X
	JMP next_op

_d7:
; SMB5 zp
; +24
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #32			; mask for bit 5
; common SMB, mask in A, address in X (+13)
	ORA !0, X		; set selected
	STA !0, X
	JMP next_op

_e7:
; SMB6 zp
; +24
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #64			; mask for bit 6
; common SMB, mask in A, address in X (+13)
	ORA !0, X		; set selected
	STA !0, X
	JMP next_op

_f7:
; SMB7 zp
; +24
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #128		; mask for bit 7
; common SMB, mask in A, address in X (+13)
	ORA !0, X		; set selected
	STA !0, X
	JMP next_op

; * branch on bits *

_0f:
; BBR0 zp, rel
; +24 if not taken
; +// * if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #1			; mask for bit 0
; common BBR code (+13/+*)
	_PC_ADV			; skip to displacement
	AND !0, X		; is it set?
	BNE g0f			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
g0f:
	JMP next_op

_1f:
; BBR1 zp, rel
; +24 if not taken
; +// * if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #2			; mask for bit 1

	_PC_ADV			; skip to displacement
	AND !0, X		; is it set?
	BNE g1f			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
g1f:
	JMP next_op

_2f:
; BBR2 zp, rel
; +24 if not taken
; +// * if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #4			; mask for bit 2

	_PC_ADV			; skip to displacement
	AND !0, X		; is it set?
	BNE g2f			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
g2f:
	JMP next_op

_3f:
; BBR3 zp, rel
; +24 if not taken
; +// * if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #8			; mask for bit 3

	_PC_ADV			; skip to displacement
	AND !0, X		; is it set?
	BNE g3f			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
g3f:
	JMP next_op

_4f:
; BBR4 zp, rel
; +24 if not taken
; +// * if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #16			; mask for bit 4

	_PC_ADV			; skip to displacement
	AND !0, X		; is it set?
	BNE g4f			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
g4f:
	JMP next_op

_5f:
; BBR5 zp, rel
; +24 if not taken
; +// * if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #32			; mask for bit 5

	_PC_ADV			; skip to displacement
	AND !0, X		; is it set?
	BNE g5f			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
g5f:
	JMP next_op

_6f:
; BBR6 zp, rel
; +24 if not taken
; +// * if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #64			; mask for bit 6

	_PC_ADV			; skip to displacement
	AND !0, X		; is it set?
	BNE g6f			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
g6f:
	JMP next_op

_7f:
; BBR7 zp, rel
; +24 if not taken
; +// * if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #128		; mask for bit 7

	_PC_ADV			; skip to displacement
	AND !0, X		; is it set?
	BNE g7f			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
g7f:
	JMP next_op

_8f:
; BBS0 zp, rel
; +24 if not taken
; +// * if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #1			; mask for bit 0
; common BBS code (+13/+*)
	_PC_ADV			; skip to displacement
	AND !0, X		; is it clear?
	BEQ g8f			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
g8f:
	JMP next_op

_9f:
; BBS1 zp, rel
; +24 if not taken
; +// * if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #2			; mask for bit 1

	_PC_ADV			; skip to displacement
	AND !0, X		; is it clear?
	BEQ g9f			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
g9f:
	JMP next_op

_af:
; BBS2 zp, rel
; +24 if not taken
; +// * if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #4			; mask for bit 2

	_PC_ADV			; skip to displacement
	AND !0, X		; is it clear?
	BEQ gaf			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
gaf:
	JMP next_op

_bf:
; BBS3 zp, rel
; +24 if not taken
; +// * if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #8			; mask for bit 3

	_PC_ADV			; skip to displacement
	AND !0, X		; is it clear?
	BEQ gbf			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
gbf:
	JMP next_op

_cf:
; BBS4 zp, rel
; +24 if not taken
; +// * if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #16			; mask for bit 4

	_PC_ADV			; skip to displacement
	AND !0, X		; is it clear?
	BEQ gcf			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
gcf:
	JMP next_op

_df:
; BBS5 zp, rel
; +24 if not taken
; +// * if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #32			; mask for bit 5

	_PC_ADV			; skip to displacement
	AND !0, X		; is it clear?
	BEQ gdf			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
gdf:
	JMP next_op

_ef:
; BBS6 zp, rel
; +24 if not taken
; +// * if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #64			; mask for bit 6

	_PC_ADV			; skip to displacement
	AND !0, X		; is it clear?
	BEQ gef			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
gef:
	JMP next_op

_ff:
; BBS7 zp, rel
; +24 if not taken
; +// * if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #128		; mask for bit 7

	_PC_ADV			; skip to displacement
	AND !0, X		; is it clear?
	BEQ gff			; will not branch
; *** to do *** to do *** to do *** to do ***
		JMP execute		; PC is ready!
gff:
	JMP next_op

; *******************************************************************
; *** LUT for Z & N status bits directly based on result as index ***
; *******************************************************************
nz_lut:
	.byt	2, 0, 0, 0, 0, 0, 0, 0	; zero to 7
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
	.byt	$80, $80, $80, $80, $80, $80, $80, $80	; negative, 128-135
	.byt	$80, $80, $80, $80, $80, $80, $80, $80	; negative, 136-143
	.byt	$80, $80, $80, $80, $80, $80, $80, $80	; negative, 144-151
	.byt	$80, $80, $80, $80, $80, $80, $80, $80	; negative, 152-159
	.byt	$80, $80, $80, $80, $80, $80, $80, $80	; negative, 160-167
	.byt	$80, $80, $80, $80, $80, $80, $80, $80	; negative, 168-175
	.byt	$80, $80, $80, $80, $80, $80, $80, $80	; negative, 176-183
	.byt	$80, $80, $80, $80, $80, $80, $80, $80	; negative, 184-191
	.byt	$80, $80, $80, $80, $80, $80, $80, $80	; negative, 192-199
	.byt	$80, $80, $80, $80, $80, $80, $80, $80	; negative, 200-207
	.byt	$80, $80, $80, $80, $80, $80, $80, $80	; negative, 208-215
	.byt	$80, $80, $80, $80, $80, $80, $80, $80	; negative, 216-223
	.byt	$80, $80, $80, $80, $80, $80, $80, $80	; negative, 224-231
	.byt	$80, $80, $80, $80, $80, $80, $80, $80	; negative, 232-239
	.byt	$80, $80, $80, $80, $80, $80, $80, $80	; negative, 240-247
	.byt	$80, $80, $80, $80, $80, $80, $80, $80	; negative, 248-25t

; ****************************************
; *** opcode execution addresses table ***
; ****************************************

; should stay the same no matter the CPU!
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
	.word	_80
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
