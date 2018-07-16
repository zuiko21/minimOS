; Virtual R65C02 for minimOS-16!!!
; v0.1a4
; (c) 2016-2018 Carlos J. Santisteban
; last modified 20180716-1922

//#include "../OS/usual.h"
#include "../OS/macros.h"
#include "../OS/abi.h"
.zero
#include "../OS/zeropage.h"
.text

; ** some useful macros **
; these make listings more succint

; increment Y checking boundary crossing (5/5/9) ** must be in 8 bit mode!
#define	_PC_ADV		INY: BNE *+4: INC pc65+1
; a on-generic, faster approach would use INY, BEQ somewhere

; *** declare zeropage addresses ***
; ** 'uz' is first available zeropage address (currently $03 in minimOS) **
tmptr		= uz		; temporary storage (up to 16 bit, little endian)

s65		= uz+2		; stack pointer
pc65		= s65+1		; program counter
p65		= pc65+2	; flags

a65		= p65+1		; accumulator
x65		= a65+1		; X index
y65		= x65+1		; Y index

cdev		= y65+1		; I/O device *** minimOS specific ***

; *** minimOS executable header will go here ***

; *** startup code, minimOS specific stuff ***
; ** assume 8-bit register size, native mode **

	LDA #cdev-uz+1	; zeropage space needed
#ifdef	SAFE
	CMP z_used		; check available zeropage space
	BCC go_emu		; more than enough space
	BEQ go_emu		; just enough!
nomem:
		_ABORT(FULL)	; not enough memory otherwise (rare) new interface
go_emu:
#endif
	STA z_used		; set required ZP space as required by minimOS
	.al: REP #%00100000	; 16 bit memory
	STZ w_rect		; no screen size required, 16 bit op?
	LDA #title		; address window title
	STA str_pt		; set parameter
	_KERNEL(OPEN_W)	; ask for a character I/O device
	BCC open_emu	; no errors
		_ABORT(NO_RSRC)	; abort otherwise!
open_emu:
	STY cdev		; store device!!!
; should try to allocate memory here
	STZ ma_rs		; will ask for...
	LDX #1
	STX ma_rs+2		; ...one full bank
	LDX #$FF		; bank aligned!
	STX ma_align
	_KERNEL(MALLOC)
		BCS nomem		; could not get a full bank
	LDX ma_pt+2		; where is the allocated bank?
	PHX
	PLB			; switch to that bank!
; *** *** MUST load virtual ROM from somewhere *** ***

; *** start the emulation! ***
reset65:
	.as: .xs: SEP #$30	; make sure all in 8-bit mode
	LDX #2			; RST @ $FFFC
; standard interrupt handling, expects vector offset in X
x_vect:
	LDA $FFFB, X		; read appropriate vector MSB
	STA pc65+1		; will resume execution there
	LDY $FFFA, X		; read appropriate vector LSB eeeeek
	STZ pc65		; *** must be zero at all times ***
	LDA p65			; original status
	ORA #%00010100		; disable further interrupts...
	AND #%11110111		; ...and clear decimal flag!
	STA p65

; *** main loop ***
execute:
		LDA (pc65), Y	; get opcode (5)
		ASL				; double it as will become pointer (2)
		TAX				; use as pointer, keeping carry (2)
		BCC lo_jump		; seems to have less opcodes with bit7 low... (2/3)
			JMP (opt_h, X)	; emulation routines for opcodes with bit7 hi (6)
lo_jump:
			JMP (opt_l, X)	; otherwise, emulation routines for opcodes with bit7 low

; *** NOP (4) arrives here, saving 3 bytes and 3 cycles ***
; must add illegal NMOS opcodes (not yet used in NMOS) as NOPs

_ea:
_02:_22:_42:_62:_82:_c2:_e2:
_03:_13:_23:_33:_43:_53:_63:_73:_83:_93:_a3:_b3:_c3:_d3:_e3:_f3:
_44:_54:_d4:_f4:
_0b:_1b:_2b:_3b:_4b:_5b:_6b:_7b:_8b:_9b:_ab:_bb:_eb:_fb:
_5c:_dc:_fc:

; continue execution via JMP next_op, will not arrive here otherwise
next_op:
		INY				; advance one byte (2)
		BNE execute		; fetch next instruction if no boundary is crossed (3/2)

; usual overhead is 22 clock cycles, not including final jump
; boundary crossing, much simpler on 816?

	INC pc65+1			; increment MSB otherwise (5)
	BRA execute			; fetch next (3)


; *** window title, optional and minimOS specific ***
title:
	.asc	"virtua6502", 0
exit:
	.asc 13, "{HLT}", 13, 0


; *** interrupt support ***
; no unsupported opcodes on CMOS!

nmi65:				; hardware interrupts, when available, to be checked AFTER incrementing PC
	LDX #0			; NMI @ $FFFA
	BRA int_stat		; save common status and execute
irq65:
_00:
	LDX #4			; both IRQ & BRK @ $FFFE
	LDA (pc65), Y		; check whether IRQ or BRK
	BEQ int_stat		; was soft, leave B flag on
		LDA p65			; hard otherwise
		AND #%11101111		; clear B
		STA p65
int_stat:
; first save current PC into stack
	PHY			; EEEEEEEEEEEEEEEEEEK
	LDA pc65+1		; get PC MSB...
	LDY s65			; and current SP
	STA $0100, Y		; store in emulated stack
	DEY			; post-decrement
	PLA			; same for LSB eeeeeeeeek
	STA $0100, Y		; store in emulated stack
	DEY			; post-decrement
; now push current status
	LDA p65			; status...
	STA $0100, Y		; store in emulated stack
	DEY			; post-decrement
	STY s65			; update SP
	BRA x_vect		; execute interrupt code

; *** proper exit point ***
v6exit:
; should I print anything?
	PHB			; current bank...
	PLX			; ...is MSB of pointer
	STX ma_pt+2
	.al: REP #$20		; 16-bit memory
	STZ ma_pt		; this completes the pointer
	_KERNEL(FREE)		; release the virtual bank!
	LDY cdev		; in case is a window...
	_KERNEL(FREE_W)		; ...allow further examination
	_FINISH			; end without errors?

	.as:

; ****************************************
; *** *** valid opcode definitions *** ***
; ****************************************

; *** implicit instructions ***
; * flag settings *

_18:
; CLC
; +10
	LDA #1		; C flag...
	TRB p65		; gets cleared
	JMP next_op

_d8:
; CLD
; +10
	LDA #8		; D flag...
	TRB p65		; gets cleared
	JMP next_op

_58:
; CLI
; +10
	LDA #4		; I flag...
	TRB p65		; gets cleared
	JMP next_op

_b8:
; CLV
; +10
	LDA #$40	; V flag...
	TRB p65		; gets cleared
	JMP next_op

_38:
; SEC
; +10
	LDA #1		; C flag...
	TSB p65		; gets set
	JMP next_op

_f8:
; SED
; +10
	LDA #8		; D flag...
	TSB p65		; gets set
	JMP next_op
_78:
; SEI
; +10
	LDA #4		; I flag...
	TSB p65		; gets set
	JMP next_op

; * register inc/dec *

_ca:
; DEX
; +23
	DEC x65		; decrement index
; LUT-based flag setting, 11b 15t
	LDX x65		; check result
; operation result in X
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_88:
; DEY
; +23
	DEC y65		; decrement index
; LUT-based flag setting, 11b 15t
	LDX y65		; check result
; operation result in X
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_e8:
; INX
; +23
	INC x65		; increment index
; LUT-based flag setting, 11b 15t
	LDX x65		; check result
; operation result in X
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_c8:
; INY
; +23
	INC y65		; increment index
; LUT-based flag setting, 11b 15t
	LDX y65		; check result
; operation result in X
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_3a:
; DEC [DEC A]
; +23
	DEC a65		; decrement A
; LUT-based flag setting, 11b 15t
	LDX a65		; check result
; operation result in X
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_1a:
; INC [INC A]
; +23
	INC a65		; increment A
; LUT-based flag setting, 11b 15t
	LDX a65		; check result
; operation result in X
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

; * register transfer *

_aa:
; TAX
; +21
	LDX a65		; copy accumulator...
	STX x65		; ...to index (value in X)
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_a8:
; TAY
; +21
	LDX a65		; copy accumulator...
	STX y65		; ...to index
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_ba:
; TSX
; +21
	LDX s65		; copy stack pointer...
	STX x65		; ...to index
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_8a:
; TXA
; +21
	LDX x65		; copy index...
	STX a65		; ...to accumulator
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_9a:
; TXS
; +21
	LDX x65		; copy index...
	STX s65		; ...to stack pointer
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_98:
; TYA
; +21
	LDX y65		; copy index...
	STX a65		; ...to accumulator
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

; *** stack operations ***
; * push *

_48:
; PHA
; +18
	LDA a65		; get accumulator
; standard push of value in A, does not affect flags
	LDX s65		; and current SP
	STA $0100, X	; push into stack
	DEX		; post-decrement
	STX s65		; update SP
; all done
	JMP next_op

_da:
; PHX
; +18
	LDA x65		; get index
; standard push of value in A, does not affect flags
	LDX s65		; and current SP
	STA $0100, X	; push into stack
	DEX		; post-decrement
	STX s65		; update SP
; all done
	JMP next_op

_5a:
; PHY
; +18
	LDA y65		; get index
; standard push of value in A, does not affect flags
	LDX s65		; and current SP
	STA $0100, X	; push into stack
	DEX		; post-decrement
	STX s65		; update SP
; all done
	JMP next_op

_08:
; PHP
; +18
	LDA p65		; get status
; standard push of value in A, does not affect flags
	LDX s65		; and current SP
	STA $0100, X	; push into stack
	DEX		; post-decrement
	STX s65		; update SP
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
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_fa:
; PLX
; +32
	INC s65		; pre-increment SP
	LDX s65		; use as index
	LDA $0100, X	; pull from stack
	STA x65		; pulled value goes to X
	TAX		; operation result in X
; standard NZ flag setting
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_7a:
; PLY
; +32
	INC s65		; pre-increment SP
	LDX s65		; use as index
	LDA $0100, X	; pull from stack
	STA y65		; pulled value goes to Y
	TAX		; operation result in X
; standard NZ flag setting
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_28:
; PLP
; +32
	INC s65		; pre-increment SP
	LDX s65		; use as index
	LDA $0100, X	; pull from stack
	STA p65		; pulled value goes to PSR
	TAX		; operation result in X
; standard NZ flag setting
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

; * return instructions *

_40:
; RTI
; +34
	LDX s65		; get current SP
	INX		; pre-increment
	LDA $0100, X	; pull from stack
	STA p65		; pulled value goes to PSR
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

_db:
; STP
; +
; should print some results or message...
	JMP v6exit	; stop emulation, this far

_cb:
; WAI
; +
	BRA _db		; without proper interrupt support, just like STP

; *** bit testing ***

_89:
; BIT imm
; +
	_PC_ADV		; get immediate operand
	LDA (pc65), Y
	AND a65		; AND with memory
	BEQ g89z	; will set Z
		LDA #2		; or clear Z in previous status
		TRB p65		; updated
		JMP next_op
g89z:
	LDA #2		; set Z in previous status
	TSB p65		; updated
; all done
	JMP next_op

_24:
; BIT zp
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
; operand in A, common BIT routine
	AND a65		; AND with memory
	TAX		; keep this value
	BEQ g24z	; will set Z
		LDA #2		; or clear Z in previous status
		TRB p65		; updated
		JMP g24nv	; check highest bits
g24z:
	LDA #2		; set Z in previous status
	TSB p65		; updated
g24nv:
	LDA #$C0	; pre-clear NV
	TRB p65
	TXA		; retrieve old result
	AND #$C0	; only two highest bits
	TSB p65		; final status
; all done
	JMP next_op

_34:
; BIT zp, X
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
; operand in A, common BIT routine
	AND a65		; AND with memory
	TAX		; keep this value
	BEQ g34z	; will set Z
		LDA #2		; or clear Z in previous status
		TRB p65		; updated
		JMP g34nv	; check highest bits
g34z:
	LDA #2		; set Z in previous status
	TSB p65		; updated
g34nv:
	LDA #$C0	; pre-clear NV
	TRB p65
	TXA		; retrieve old result
	AND #$C0	; only two highest bits
	TSB p65		; final status
; all done
	JMP next_op

_2c:
; BIT abs
; +
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
	BEQ g2cz	; will set Z
		LDA #2		; or clear Z in previous status
		TRB p65		; updated
		JMP g2cnv	; check highest bits
g2cz:
	LDA #2		; set Z in previous status
	TSB p65		; updated
g2cnv:
	LDA #$C0	; pre-clear NV
	TRB p65
	TXA		; retrieve old result
	AND #$C0	; only two highest bits
	TSB p65		; final status
; all done
	JMP next_op

_3c:
; BIT abs, X
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
	LDA (tmptr)	; get operand
; operand in A, common BIT routine
	AND a65		; AND with memory
	TAX		; keep this value
	BEQ g3cz	; will set Z
		LDA #2		; or clear Z in previous status
		TRB p65		; updated
		JMP g3cnv	; check highest bits
g3cz:
	LDA #2		; set Z in previous status
	TSB p65		; updated
g3cnv:
	LDA #$C0	; pre-clear NV
	TRB p65
	TXA		; retrieve old result
	AND #$C0	; only two highest bits
	TSB p65		; final status
; all done
	JMP next_op

; *** jumps ***

; * conditional branches *

_90:
; BCC
; +
	_PC_ADV		; get relative address
	LDA (pc65), Y
; *** to do *** to do *** to do *** to do ***
	JMP execute	; PC is ready!


; * absolute jumps *

_4c:
; JMP abs
; +
	_PC_ADV		; get LSB
	LDA (pc65), Y
	TAX		; store temporarily
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA pc65+1	; update PC
	TXY		; pointer is ready!
	JMP execute

_6c:
; JMP indirect
; +
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

_7c:
; JMP indirect indexed
; +
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
; +
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

_a2:
; LDX imm
; +
	_PC_ADV		; get immediate operand
	LDA (pc65), Y
	STA x65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_a6:
; LDX zp
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA x65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_b6:
; LDX zp, Y
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC y65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA x65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_ae:
; LDX abs
; +
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
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_be:
; LDX abs, Y
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
	LDA (tmptr)	; load operand
	STA x65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_a0:
; LDY imm
; +
	_PC_ADV		; get immediate operand
	LDA (pc65), Y
	STA x65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_a4:
; LDY zp
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA y65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_b4:
; LDY zp, X
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA y65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_ac:
; LDY abs
; +
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
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_bc:
; LDY abs, X
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
	LDA (tmptr)	; load operand
	STA y65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_a9:
; LDA imm
; +
	_PC_ADV		; get immediate operand
	LDA (pc65), Y
	STA a65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_a5:
; LDA zp
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA a65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_b5:
; LDA zp, X
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA a65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_ad:
; LDA abs
; +
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
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_bd:
; LDA abs, X
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
	LDA (tmptr)	; load operand
	STA a65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_b9:
; LDA abs, Y
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
	LDA (tmptr)	; load operand
	STA a65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_b2:
; LDA (zp)
; +
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
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_b1:
; LDA (zp), Y
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
	LDA (tmptr)	; read operand
	STA a65		; update register
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_a1:
; LDA (zp, X)
; +
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
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

; * store *

_86:
; STX zp
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA x65		; value to be stored
	STA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_96:
; STX zp, Y
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC y65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA x65		; value to be stored
	STA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_8e:
; STX abs
; +
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
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA y65		; value to be stored
	STA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_94:
; STY zp, X
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA y65		; value to be stored
	STA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_8c:
; STY abs
; +
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
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	STZ !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_74:
; STZ zp, X
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	STZ !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_9c:
; STZ abs
; +
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA #0
	STA (tmptr)	; clear operand
	JMP next_op

_9e:
; STZ abs, X
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
	LDA #0
	STA (tmptr)	; clear operand
	JMP next_op

_8d:
; STA abs
; +
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA a65		; value to be stored
	STA (tmptr)	; store operand
	JMP next_op

_9d:
; STA abs, X
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
	LDA a65		; value to be stored
	STA (tmptr)	; store operand
	JMP next_op

_99:
; STA abs, Y
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
	LDA a65		; value to be stored
	STA (tmptr)	; store operand
	JMP next_op

_85:
; STA zp
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA a65		; value to be stored
	STA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_95:
; STA zp, X
; +
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
; +
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
	LDA a65		; value to be stored
	STA (tmptr)
	JMP next_op

_81:
; STA (zp, X)
; +
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
; +
	_PC_ADV		; get immediate operand
	LDA (pc65), Y
	AND a65		; do AND
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_25:
; AND zp
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	AND a65		; do AND
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_35:
; AND zp, X
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	AND a65		; do AND
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_2d:
; AND abs
; +
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; read operand
	AND a65		; do AND
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_3d:
; AND abs, X
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
	AND a65		; do AND
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_39:
; AND abs, Y
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
	LDA (tmptr)	; read operand
	AND a65		; do AND
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_32:
; AND (zp)
; +
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	LDA !1, X	; same for MSB
	STA tmptr+1
	LDA (tmptr)	; read operand
	AND a65		; do AND
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_31:
; AND (zp), Y
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
	LDA (tmptr)	; read operand
	AND a65		; do AND
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_21:
; AND (zp, X)
; +
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
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

; * logic or *

_09:
; ORA imm
; +
	_PC_ADV		; get immediate operand
	LDA (pc65), Y
	ORA a65		; do OR
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_05:
; ORA zp
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	ORA a65		; do OR
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_15:
; ORA zp, X
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	ORA a65		; do OR
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_0d:
; ORA abs
; +
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; read operand
	ORA a65		; do OR
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_1d:
; ORA abs, X
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
	ORA a65		; do OR
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_19:
; ORA abs, Y
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
	LDA (tmptr)	; read operand
	ORA a65		; do OR
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_12:
; ORA (zp)
; +
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	LDA !1, X	; same for MSB
	STA tmptr+1
	LDA (tmptr)	; read operand
	ORA a65		; do OR
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_11:
; ORA (zp), Y
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
	LDA (tmptr)	; read operand
	ORA a65		; do OR
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_01:
; ORA (zp, X)
; +
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
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

; * exclusive or *

_49:
; EOR imm
; +
	_PC_ADV		; get immediate operand
	LDA (pc65), Y
	EOR a65		; do XOR
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_45:
; EOR zp
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	EOR a65		; do XOR
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_55:
; EOR zp, X
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	EOR a65		; do XOR
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_4d:
; EOR abs
; +
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; read operand
	EOR a65		; do XOR
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_5d:
; EOR abs, X
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
	EOR a65		; do XOR
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_59:
; EOR abs, Y
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
	LDA (tmptr)	; read operand
	EOR a65		; do XOR
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_52:
; EOR (zp)
; +
	_PC_ADV		; get zeropage pointer
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA tmptr	; this was LSB
	LDA !1, X	; same for MSB
	STA tmptr+1
	LDA (tmptr)	; read operand
	EOR a65		; do XOR
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_51:
; EOR (zp), Y
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
	LDA (tmptr)	; read operand
	EOR a65		; do XOR
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_41:
; EOR (zp, X)
; +
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
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

; *** arithmetic ***

; * inc/dec memory *

_e6:
; INC zp
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	EOR a65		; do XOR
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_f6:
; INC zp, X
; +
	_PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	EOR a65		; do XOR
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_ee:
; INC abs
; +
	_PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	_PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; read operand
	EOR a65		; do XOR
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_fe:
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
	EOR a65		; do XOR
; standard NZ flag setting
	TAX		; index for LUT
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op



/*_:
_:
;
; +

_:
;
; +

_:
;
; +

_:
; 
; +

_:
;
; +

_:
;
; +

_:
;
; +

_:
;
; +

_:
;
; +

_:
;
; +

_:
;
; +

_:
;
; +

_:
;
; +

_:
;
; +

_:
;
; +

_:
;
; +

_:
;
; +

_:
;
; +

_:
;
; +

_:
;
; +

_:
;
; +
*/

; *** LUT for Z & N status bits directly based on result as index ***
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

