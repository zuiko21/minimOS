; Virtual R65C02 for minimOS-16!!!
; v0.1a2
; (c) 2016-2018 Carlos J. Santisteban
; last modified 20180713-0936

#include "../OS/usual.h"

; ** some useful macros **
; these make listings more succint

; increment Y checking boundary crossing (5/5/9) ** must be in 8 bit mode!
#define	_PC_ADV		INY: BNE *+4: INC pc65+1

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
; will currently assume whole bank 1

; *** start the emulation! ***
reset65:
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
; must add illegal NMOS opcodes as NOPs

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
; DEC
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
; INC
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
; +23
	LDA a65		; copy accumulator...
	STA x65		; ...to index
	TAX		; operation result in X
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_ab:
; TAY
; +23
	LDA a65		; copy accumulator...
	STA y65		; ...to index
	TAX		; operation result in X
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_ba:
; TSX
; +23
	LDA s65		; copy stack pointer...
	STA x65		; ...to index
	TAX		; operation result in X
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_8a:
; TXA
; +23
	LDA x65		; copy index...
	STA a65		; ...to accumulator
	TAX		; operation result in X
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_9a:
; TXS
; +23
	LDA x65		; copy index...
	STA s65		; ...to stack pointer
	TAX		; operation result in X
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_98:
; TYA
; +23
	LDA y65		; copy index...
	STA a65		; ...to accumulator
	TAX		; operation result in X
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
	_FINISH		; stop emulation, this far

_cb:
; WAI
; +
	BRA _db		; without proper interrupt support, just like STP

; *** bit testing ***

_89:
; BIT imm
; +
	PC_ADV		; get immediate operand
	LDA (pc65), Y
	AND a65		; AND with memory
	BEQ 89z		; will set Z
		LDA #2		; or clear Z in previous status
		TRB p65		; updated
		JMP next_op
89z:
	LDA #2		; set Z in previous status
	TSB p65		; updated
; all done
	JMP next_op

_24:
; BIT zp
; +
	PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
; operand in A, common BIT routine
	AND a65		; AND with memory
	TAX		; keep this value
	BEQ 24z		; will set Z
		LDA #2		; or clear Z in previous status
		TRB p65		; updated
		JMP 24nv	; check highest bits
24z:
	LDA #2		; set Z in previous status
	TSB p65		; updated
24nv:
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
	PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	LDA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
; operand in A, common BIT routine
	AND a65		; AND with memory
	TAX		; keep this value
	BEQ 34z		; will set Z
		LDA #2		; or clear Z in previous status
		TRB p65		; updated
		JMP 34nv	; check highest bits
34z:
	LDA #2		; set Z in previous status
	TSB p65		; updated
34nv:
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; get operand
; operand in A, common BIT routine
	AND a65		; AND with memory
	TAX		; keep this value
	BEQ 2cz		; will set Z
		LDA #2		; or clear Z in previous status
		TRB p65		; updated
		JMP 2cnv	; check highest bits
2cz:
	LDA #2		; set Z in previous status
	TSB p65		; updated
2cnv:
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC x65
	STA tmptr	; store in vector
	PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA (tmptr)	; get operand
; operand in A, common BIT routine
	AND a65		; AND with memory
	TAX		; keep this value
	BEQ 3cz		; will set Z
		LDA #2		; or clear Z in previous status
		TRB p65		; updated
		JMP 3cnv	; check highest bits
3cz:
	LDA #2		; set Z in previous status
	TSB p65		; updated
3cnv:
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
	PC_ADV		; get relative address
	LDA (pc65), Y
; *** to do *** to do *** to do *** to do ***
	JMP execute	; PC is ready!


; * absolute jumps *

_4c:
; JMP abs
; +
	PC_ADV		; get LSB
	LDA (pc65), Y
	TAX		; store temporarily
	PC_ADV		; get MSB
	LDA (pc65), Y
	STA pc65+1	; update PC
	TXY		; pointer is ready!
	JMP execute

_6c:
; JMP indirect
; +
	PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store temporarily
	PC_ADV		; get MSB
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store temporarily
	PC_ADV		; get MSB
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store temporarily
	PC_ADV		; get MSB
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
	PC_ADV		; get immediate operand
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
	PC_ADV		; get zeropage address
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
	PC_ADV		; get zeropage address
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	PC_ADV		; get MSB
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC y65
	STA tmptr	; store in vector
	PC_ADV		; get MSB
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
	PC_ADV		; get immediate operand
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
	PC_ADV		; get zeropage address
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
	PC_ADV		; get zeropage address
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	PC_ADV		; get MSB
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC x65
	STA tmptr	; store in vector
	PC_ADV		; get MSB
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
	PC_ADV		; get immediate operand
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
	PC_ADV		; get zeropage address
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
	PC_ADV		; get zeropage address
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	PC_ADV		; get MSB
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC x65
	STA tmptr	; store in vector
	PC_ADV		; get MSB
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC y65
	STA tmptr	; store in vector
	PC_ADV		; get MSB
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
	PC_ADV		; get zeropage pointer
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
	PC_ADV		; get zeropage pointer
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
	PC_ADV		; get zeropage pointer
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
	PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA x65		; value to be stored
	STA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_96:
; STX zp, Y
; +
	PC_ADV		; get zeropage address
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA x65		; value to be stored
	STA (tmptr)	; store operand
	JMP next_op

_84:
; STY zp
; +
	PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA y65		; value to be stored
	STA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_94:
; STY zp, X
; +
	PC_ADV		; get zeropage address
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA y65		; value to be stored
	STA (tmptr)	; store operand
	JMP next_op

_64:
; STZ zp
; +
	PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	STZ !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_74:
; STZ zp, X
; +
	PC_ADV		; get zeropage address
	LDA (pc65), Y
	CLC
	ADC x65		; add index, forget carry as will page-wrap
	TAX		; temporary index...
	STZ !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_9c:
; STZ abs
; +
	PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA #0
	STA (tmptr)	; clear operand
	JMP next_op

_9e:
; STZ abs, X
; +
	PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC x65
	STA tmptr	; store in vector
	PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA #0
	STA (tmptr)	; clear operand
	JMP next_op

_8d:
; STA abs
; +
	PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	PC_ADV		; get MSB
	LDA (pc65), Y
	STA tmptr+1	; vector is complete
	LDA a65		; value to be stored
	STA (tmptr)	; store operand
	JMP next_op

_9d:
; STA abs, X
; +
	PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC x65
	STA tmptr	; store in vector
	PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA a65		; value to be stored
	STA (tmptr)	; store operand
	JMP next_op

_99:
; STA abs, Y
; +
	PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC y65
	STA tmptr	; store in vector
	PC_ADV		; get MSB
	LDA (pc65), Y
	ADC #0		; in case of page boundary crossing
	STA tmptr+1	; vector is complete
	LDA a65		; value to be stored
	STA (tmptr)	; store operand
	JMP next_op

_85:
; STA zp
; +
	PC_ADV		; get zeropage address
	LDA (pc65), Y
	TAX		; temporary index...
	LDA a65		; value to be stored
	STA !0, X	; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_95:
; STA zp, X
; +
	PC_ADV		; get zeropage address
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
	PC_ADV		; get zeropage pointer
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
	PC_ADV		; get zeropage pointer
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
	PC_ADV		; get zeropage pointer
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
	PC_ADV		; get immediate operand
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
	PC_ADV		; get zeropage address
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
	PC_ADV		; get zeropage address
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	PC_ADV		; get MSB
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC x65
	STA tmptr	; store in vector
	PC_ADV		; get MSB
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC y65
	STA tmptr	; store in vector
	PC_ADV		; get MSB
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
	PC_ADV		; get zeropage pointer
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
	PC_ADV		; get zeropage pointer
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
	PC_ADV		; get zeropage pointer
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
	PC_ADV		; get immediate operand
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
	PC_ADV		; get zeropage address
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
	PC_ADV		; get zeropage address
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	PC_ADV		; get MSB
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC x65
	STA tmptr	; store in vector
	PC_ADV		; get MSB
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC y65
	STA tmptr	; store in vector
	PC_ADV		; get MSB
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
	PC_ADV		; get zeropage pointer
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
	PC_ADV		; get zeropage pointer
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
	PC_ADV		; get zeropage pointer
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
	PC_ADV		; get immediate operand
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
	PC_ADV		; get zeropage address
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
	PC_ADV		; get zeropage address
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	STA tmptr	; store in vector
	PC_ADV		; get MSB
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC x65
	STA tmptr	; store in vector
	PC_ADV		; get MSB
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
	PC_ADV		; get LSB
	LDA (pc65), Y
	CLC		; do indexing
	ADC y65
	STA tmptr	; store in vector
	PC_ADV		; get MSB
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
	PC_ADV		; get zeropage pointer
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
	PC_ADV		; get zeropage pointer
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
	PC_ADV		; get zeropage pointer
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

; *** ***

_:
;
; +

_:
;
; +

_:
;
; +





; *** ***

; increment/decrement
_:
; DEC
; +23
	DEC a65		; decrement 
; LUT-based flag setting, 11b 15t
	LDX a65		; check result
; operation result in X
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

_:
; INC
; +23
	INC a65		; increment 
; LUT-based flag setting, 11b 15t
	LDX a65		; check result
; operation result in X
	LDA p65		; previous status...
	AND #$82	; ...minus NZ...
	ORA nz_lut, X	; ...adds flag mask
	STA p65
; all done
	JMP next_op

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


;------------------------------- old 8080 opcodes -----------------------------------

; ** stack **

_c5:
; PUSH B (11, 13 @ 8085) BE
;+36
	.al:	REP #%00100000	; ** 16 bit memory **
	LDA bc80		; load data word
	BRA phcnt	; continue in 16 bit

_d5:
; PUSH D (11, 13 @ 8085) DE
;+36
	.al:	REP #%00100000	; ** 16 bit memory **
	LDA de80		; load data word
	BRA phcnt	; continue in 16 bit

_e5:
; PUSH H (11, 13 @ 8085) HL
;+36
	.al:	REP #%00100000	; ** 16 bit memory **
	LDA hl80		; load data word
	BRA phcnt	; continue in 16 bit

_f5:
; PUSH PSW (11, 12! @ 8085) AF
;+33
	.al:	REP #%00100000	; ** 16 bit memory **
	LDA af80	; get origin
phcnt:
	DEC sp80	; make room
	DEC sp80
	STA (sp80)	; push value
	.as:	SEP #%00100000	; ** back to 8 bit **
	JMP next_op	; flags unaffected

_c1:
; POP B (10) BC
;+33
	.al:	REP #%00100000	; ** 16 bit memory **
	LDA (sp80)	; pop from stack
	INC sp80		; correct SP
	INC sp80
	STA bc80		; store word
	.as:	SEP #%00100000	; ** back to 8 bit **
	JMP next_op

_d1:
; POP D (10) DE
;+33
	.al:	REP #%00100000	; ** 16 bit memory **
	LDA (sp80)	; pop from stack
	INC sp80		; correct SP
	INC sp80
	STA de80		; store word
	.as:	SEP #%00100000	; ** back to 8 bit **
	JMP next_op

_e1:
; POP H (10) HL
;+33
	.al:	REP #%00100000	; ** 16 bit memory **
	LDA (sp80)	; pop from stack
	INC sp80		; correct SP
	INC sp80
	STA hl80		; store word
	.as:	SEP #%00100000	; ** back to 8 bit **
	JMP next_op

_f1:
; POP PSW (10) AF
;+33
	.al:	REP #%00100000	; ** 16 bit memory **
	LDA (sp80)	; pop from stack
	INC sp80		; correct SP
	INC sp80
	STA af80		; store word
	.as:	SEP #%00100000	; ** back to 8 bit **
	JMP next_op

_e3:
; XTHL (18, 16 @ 8085) exchange HL with top of stack
;+31
	.al:	REP #%00100000	; ** 16 bit memory **
	LDA (sp80)	; top of stack
	LDX hl80	; HL contents
	STA hl80	; exchange them
	TXA
	STA (sp80)
	.as:	SEP #%00100000	; ** back to 8 bit **
	JMP next_op

_f9:
; SPHL (5, 6 @ 8085) set SP as HL
;+17
	.al:	REP #%00100000	; ** 16 bit memory **
	LDA hl80	; HL contents
	STA sp80	; copy into SP
	.as:	SEP #%00100000	; ** back to 8 bit **
	JMP next_op

_33:
; INX SP (5, 6 @ 8085)
;+16
	.al:	REP #%00100000	; ** 16 bit memory **
	INC sp80	; increment SP
	.as:	SEP #%00100000	; ** back to 8 bit **
	JMP next_op	; flags unaffected

_3b:
; DCX SP (5, 6 @ 8085)
;+16
	.al:	REP #%00100000	; ** 16 bit memory **
	DEC sp80	; decrement SP
	.as:	SEP #%00100000	; ** back to 8 bit **
	JMP next_op	; flags unaffected


; ** control **

_fb:
; EI (4)
;+10
; ***** actually delays enabling for one instruction! *****
	LDA #%00001000	; bit 3
	TSB rimask	; enable interrupts
	JMP next_op

_f3:
; DI (4)
;+10
	LDA #%00001000	; bit 3
	TRB rimask	; disable interrupts
	JMP next_op

_76:
; HLT (7, 5 @ 8085)
; abort emulation and return to shell...
; ...since interrupts are not yet supported!
	LDY cdev	; console device
	_KERNEL(FREE_W)	; release device or window
	_FINISH		; *** go away ***


; ** specials **

_2f:
; CMA (4) complement A
;+11
	LDA a80		; get accumulator
	EOR #$FF	; complement
	STA a80		; update
	JMP next_op

_37:
; STC (4) set carry
;+10
	LDA #1		; C flag mask
	TSB f80	; easiest way in Intel CPUs
	JMP next_op

_3f:
; CMC (4) complement carry
;+11
	LDA f80		; status
;	AND #%11101101	; reset H & N, only for Z80?
	EOR #%00000001	; invert C
	STA f80		; update status
	JMP next_op

_27:
; DAA (4) decimal adjust
;+59/76/93
	LDA a80		; binary value
	TAX		; worth saving
	LDA f80		; check flags
	AND #%00010000	; H mask
		BNE llp6	; halfcarry was set, add 6
	TXA		; restore!
	AND #$0F	; low nibble
	CMP #10		; BCD valid?
		BCS llp6	; if not, reload value and add 6
daah:
	LSR f80		; flags again, get bit 0 (C) easily
		BCS hp6	; normal carry was set, add 6 to hi nibble
	TXA		; reload current value
	AND #$F0	; hi nibble
	CMP #10		; valid BCD?
	BCC daa_nc	; OK, do not add anything
hp6:
		TXA		; A was lost
		CLC
		ADC #$60	; add 6 to hi nibble, might set native C
		STA a80		; update value!
		TAX		; right value
daa_nc:
	ROL f80		; set C as native, restoring flags
	JMP i_szp		; check usual flags and exit (18)

; pseudo-routine for low nibble
llp6:
	TXA		; reload as was masked
	CLC
	ADC #6	; correct low nibble
	STA a80		; update
	TXA		; get older value, not sure about H
	EOR a80		; check differences
	AND #%00001000	; looking for bit 3
	BEQ lp_nh	; no change, no half carry
		LDA #%00010000	; H mask
		TSB f80	; or set H
lp_nh:
	LDX a80		; retrieve new value
	BRA daah	; and try next nibble


; ** input/output **
; * might be trapped easily *

_db:
; IN (10)
;+23/23/27
	_PC_ADV		; go for address
	LDA (pc80), Y	; get port
	TAX
	LDA @IO_BASE, X	; actual port access, long mode
	STA a80		; gets into A
	JMP next_op	; flags unaffected

_d3:
; OUT (10)
;+23/23/27
	_PC_ADV		; go for address
	LDA (pc80), Y	; get port
	TAX
	LDA a80		; take data from A
	STA @IO_BASE, X	; actual port access, long mode
	JMP next_op	; flags unaffected


; ** new 8085 instructions **

_20:
; RIM (4) read interrupt mask
;+11
	LDA rimask	; get data
	AND #%01111111	; no serial input this far...
	STA a80		; transfer to A
	JMP next_op	; anything else?

_30:
; SIM (4) set interrupt mask
;+16/28/40
	LDA a80		; get argument
	BIT #%00010000	; check bit 4
	BEQ sim_r7	; will not clear I7.5
		LDA #%01000000	; mask bit 6
		TRB rimask	; otherwise reset it
		LDA a80		; reload!
sim_r7:
	BIT #%00001000	; check bit 3
	BEQ sim_m	; no mask change
		AND #%00000111	; otherwise filter new masks
		STA tmptr	; save them
		LDA rimask	; older values
		AND #%11111000	; delete older
		ORA tmptr	; put new ones
		STA rimask	; update
sim_m:
	JMP next_op	; anything else?

	
;** rotate **

_07:
; RLC (4) rotate A left, Z80 needs older version of rots
; +23
	LSR f80		; lose C
	LDA a80		; check bit 7
	ASL		; if one, set native carry
	ROL a80		; rotate register
	ROL f80		; restore new C
	JMP next_op

_0f:
; RRC (4) rotate A right
;+23
	LSR f80		; lose C
	LDA a80		; temporary check
	LSR		; copy bit 0 in native C
	ROR a80		; rotate register
	ROL f80		; restore new C
	JMP next_op

_17:
; RAL (4) rotate A left thru carry
;+18
	LSR f80		; copy C on native
	ROL a80		; rotate register
	ROL f80		; return status with updated carry
	JMP next_op

_1f:
; RAR (4) rotate A right thru carry
;+18
	LSR f80		; copy C on native
	ROR a80		; rotate register
	ROL f80		; return status with updated carry
	JMP next_op
	

; ** increment & decrement **

_34:
; INR M (10!)
;+43/43/49
; ***** affects all but C *****
	LDA (hl80)	; older value
	INC		; operation
	TAX		; FINAL result for further testing, status OK
	STA (hl80)	; and update memory
iflags:
	LDA #%00010000	; mask for H (+29/29/35)
	TRB f80		; clear it! eeeeeeeek
	TXA		; needed for generic code
	AND #$0F	; filter low nibble
	BNE i_szp		; not zero, could not set H
		LDA #%00010000	; mask for H
		TSB f80	; ...or set H
i_szp:
	LDA f80		; get previous status (+15)
	AND #%00111011	; reset SZP, H already checked
x_szp:
	ORA szp_lut, X	; set appropriate flags! (+10)
	STA f80		; update status
	JMP next_op

_04:
; INR B (5, 4 @ 8085)
;+40/40/46
	INC b80
	LDX b80		; appropriate register
	BRA iflags	; common ending

_0c:
; INR C (5, 4 @ 8085)
;+40/40/46
	INC c80
	LDX c80		; appropriate register
	BRA iflags	; common ending

_14:
; INR D (5, 4 @ 8085)
;+40/40/46
	INC d80
	LDX d80		; appropriate register
	BRA iflags	; common ending

_1c:
; INR E (5, 4 @ 8085)
;+40/40/46
	INC e80
	LDX e80		; appropriate register
	BRA iflags	; common ending

_24:
; INR H (5, 4 @ 8085)
;+40/40/46
	INC h80
	LDX h80		; appropriate register
	BRA iflags	; common ending

_2c:
; INR L (5, 4 @ 8085)
;+40/40/46
	INC l80
	LDX l80		; appropriate register
	BRA iflags	; common ending

_3c:
; INR A (5, 4 @ 8085)
;+40/40/46
	INC a80
	LDX a80		; appropriate register
	BRA iflags	; common ending

_35:
; DCR M (10!)
;+43/43/51
;***** affects all but C *****
	LDA (hl80)	; older value
	DEC		; operation
	TAX		; FINAL result for further testing, status OK
	STA (hl80)	; and update memory
dflags:
	LDA #%00010000	; mask for H (+29/29/38)
	TRB f80		; clear it! eeeeeeeek
	TXA		; needed for generic code
	AND #$0F	; filter low nibble
	CMP #$0F	; only value that could set H
	BNE i_szp		; not zero, could not set H
		LDA #%00010000	; mask for bit 4
		TSB f80	; ...or set H
	BRA i_szp	; common ending

_05:
; DCR B (5, 4 @ 8085)
;+40/40/49
	DEC b80
	LDX b80		; appropriate register
	BRA dflags	; common ending

_0d:
; DCR C (5, 4 @ 8085)
;+40/40/49
	DEC c80
	LDX c80		; appropriate register
	BRA dflags	; common ending

_15:
; DCR D (5, 4 @ 8085)
;+40/40/49
	DEC d80
	LDX d80		; appropriate register
	BRA dflags	; common ending

_1d:
; DCR E (5, 4 @ 8085)
;+40/40/49
	DEC e80
	LDX e80		; appropriate register
	BRA dflags	; common ending

_25:
; DCR H (5, 4 @ 8085)
;+40/40/49
	DEC h80
	LDX h80		; appropriate register
	BRA dflags	; common ending

_2d:
; DCR L (5, 4 @ 8085)
;+40/40/49
	DEC l80
	LDX l80		; appropriate register
	BRA dflags	; common ending

_3d:
; DCR A (5, 4 @ 8085)
;+40/40/49
	DEC a80
	LDX a80		; appropriate register
	BRA dflags	; common ending

; 16-bit inc/dec

_03:
; INX B (5, 6 @ 8085)
;+11/11/15
	INC c80	; increment LSB
	BNE ixb	; no wrap
		INC b80	; correct MSB
ixb:
	JMP next_op	; flags unaffected

_0b:
; DCX B (5, 6 @ 8085)
;+14/14/18
	LDX c80	; preload LSB
	BNE dxb	; will not wrap
		DEC b80	; correct MSB otherwise
dxb:
	DEC c80	; decrement LSB
	JMP next_op

_13:
; INX D (5, 6 @ 8085)
;+11/11/15
	INC e80	; increment LSB
	BNE ixd	; no wrap
		INC d80	; correct MSB
ixd:
	JMP next_op	; flags unaffected

_1b:
; DCX D (5, 6 @ 8085)
;+14/14/18
	LDX e80	; preload LSB
	BNE dxd	; will not wrap
		DEC d80	; correct MSB otherwise
dxd:
	DEC e80	; decrement LSB
	JMP next_op

_23:
; INX H (5, 6 @ 8085)
;+11/11/15
	INC l80	; increment LSB
	BNE ixh	; no wrap
		INC h80	; correct MSB
ixh:
	JMP next_op	; flags unaffected

_2b:
; DCX H (5, 6 @ 8085)
;+14/14/18
	LDX l80	; preload LSB
	BNE dxh	; will not wrap
		DEC h80	; correct MSB otherwise
dxh:
	DEC l80	; decrement LSB
	JMP next_op


; ** logical **

; and

_a0:
; ANA B (4)
;+34
	LDA b80		; variable term
	BRA anai	; generic routine

_a1:
; ANA C (4)
;+34
	LDA c80		; variable term
	BRA anai	; generic routine

_a2:
; ANA D (4)
;+34
	LDA d80		; variable term
	BRA anai	; generic routine

_a3:
; ANA E (4)
;+34
	LDA e80		; variable term
	BRA anai	; generic routine

_a4:
; ANA H (4)
;+34
	LDA h80		; variable term
	BRA anai	; generic routine

_a5:
; ANA L (4)
;+34
	LDA b80		; variable term
	BRA anai	; generic routine

_a6:
; ANA M (7)
;+33
; ***** WARNING, 8085 (and Z80?) sets H, but 8080 computes old.d3 OR new.d3 for H *****
; ***** clears just C *****
	LDA (hl80)	; variable term
anai:
	AND a80		; logical AND (+28)
	STA a80		; store result
	TAX		; keep final result
	LDA f80		; get old flags
	AND #%00111010	; reset S, Z, P & C, ANA specific masks
	ORA #%00010000	; set H... 8085 behaviour
	JMP x_szp	; common flag set & exit

_a7:
; ANA A (4) somewhat special as will only update flags! not worth
; +34
	LDA a80		; original intact data
	BRA anai

; and immediate

_e6:
; ANI (7)
;+41/41/45
	_PC_ADV		; go for the operand
	LDA (pc80), Y	; immediate addressing
	BRA anai	; generic routine

; exclusive or

_a8:
; XRA B (4)
;+32
	LDA b80		; variable term
	BRA xrai	; generic routine

_a9:
; XRA C (4)
;+32
	LDA c80		; variable term
	BRA xrai	; generic routine

_aa:
; XRA D (4)
;+32
	LDA d80		; variable term
	BRA xrai	; generic routine

_ab:
; XRA E (4)
;+32
	LDA e80		; variable term
	BRA xrai	; generic routine

_ac:
; XRA H (4)
;+32
	LDA h80		; variable term
	BRA xrai	; generic routine

_ad:
; XRA L (4)
;+32
	LDA l80		; variable term
	BRA xrai	; generic routine

_ae:
; XRA M (7) with parity instead of overflow!
;+31
; ***** clears C & H *****
	LDA (hl80)	; variable term
xrai:
	EOR a80		; exclusive OR (+26)
l_flags:
	STA a80		; store result (+23)
	TAX		; keep final result
	LDA f80		; get old flags
	AND #%00101010	; reset S, Z, H, P & C
	JMP x_szp	; common flag set & exit

_af:
; XRA A (4) will always get zero, worth optimising as a quick way to zero A
;+16
	LDA f80		; get old flags
	AND #%01101110	; reset S, H & C
	ORA #%01000100	; set Z & P
	STA f80		; store base flags
	STZ a80		; result is always zero!
	JMP next_op

; or

_b6:
; ORA M (7)
;+34
;***** resets C & H ***
	LDA (hl80)	; variable term
orai:
	ORA a80		; logical OR (+29)
	BRA l_flags	; store & check flags

; exclusive or immediate

_ee:
; XRI (7)
;+39/39/43
	_PC_ADV		; go for the operand
	LDA (pc80), Y	; immediate addressing
	BRA xrai	; generic routine

_b0:
; ORA B (4)
;+35
	LDA b80		; variable term
	BRA orai	; generic routine

_b1:
; ORA C (4)
;+35
	LDA c80		; variable term
	BRA orai	; generic routine

_b2:
; ORA D (4)
;+35
	LDA d80		; variable term
	BRA orai	; generic routine

_b3:
; ORA E (4)
;+35
	LDA e80		; variable term
	BRA orai	; generic routine

_b4:
; ORA H (4)
;+35
	LDA h80		; variable term
	BRA orai	; generic routine

_b5:
; ORA L (4)
;+35
	LDA l80		; variable term
	BRA orai	; generic routine

_b7:
; ORA A (4) not really the same as AND A (this clears H)
;+35
	LDA a80		; variable term
	BRA orai	; generic routine

; or immediate

_f6:
; ORI (7)
;+42/42/46
	_PC_ADV		; go for the operand
	LDA (pc80), Y	; immediate addressing
	BRA orai	; generic routine

; compare with A

_b8:
; CMP B (4)
;+61/67/73
	LDA b80		; variable term
	BRA cmpi	; generic routine

_b9:
; CMP C (4)
;+61/67/73
	LDA c80		; variable term
	BRA cmpi	; generic routine

_ba:
; CMP D (4)
;+61/67/73
	LDA d80		; variable term
	BRA cmpi	; generic routine

_bb:
; CMP E (4)
;+61/67/73
	LDA e80		; variable term
	BRA cmpi	; generic routine

_bc:
; CMP H (4)
;+61/67/73
	LDA h80		; variable term
	BRA cmpi	; generic routine

_bd:
; CMP L (4)
;+61/67/73
	LDA l80		; variable term
	BRA cmpi	; generic routine

_be:
; CMP M (7)
;+60/66/72
	LDA (hl80)	; variable term
cmpi:
	STA tmptr	; keep first operand! (+55/61/67)
	LDA a80		; have a look at accumulator
	STA tmptr+1	; store second operand!
	SEC		; prepare subtraction
	SBC tmptr	; subtract without storing
	TAX		; keep final result
	LDA #%00010001	; mask for H & C
	TRB f80	; clear them! eeeeeeek
	BCS cmp_c	; if native carry is set, there is NO borrow
		LDA #1		; mask for C
		TSB f80	; otherwise set emulated C
cmp_c:
	TXA		; restore result for H computation!
	EOR tmptr	; exclusive OR of result with both operands
	EOR tmptr+1
	AND #%00010000	; just look at bit 4
	BEQ cmp_h	; no half carry if zero
		TSB f80	; or set H, A already was %00010000
cmp_h:
	JMP i_szp	; update flags and continue (18)

_bf:
; CMP A (4) special
;+13
	LDA f80		; old flags
	AND #%01101010	; clear S, H, P & C
	ORA #%01000000	; set Z!
	STA f80		; store flags
	JMP next_op

; compare A immediate

_fe:
; CPI (7)
;+68/74/84
	_PC_ADV		; go for the operand
	LDA (pc80), Y	; immediate addressing
	BRA cmpi	; generic routine


; ** addition **

; without carry

_86:
; ADD M (7)
;+65/70/75
	LDA (hl80)	; variable term
addi:
	STA tmptr	; keep first operand! (+60/65/70)
	LDA a80		; look at accumulator
	STA tmptr+1	; keep second
	CLC		; ignore previous carry
	ADC tmptr	; addition
	STA a80		; store result
	TAX		; keep final result
	LDA #%00010001	; mask for H & C
	TRB f80	; clear them! eeeeeeek
	BCC a_flags	; no carry was generated
		LDA #1		; mask for C
		TSB f80	; or set C
a_flags:
	TXA		; restore result for H computation! (+31/33/35)
	EOR tmptr	; exclusive OR on three values
	EOR tmptr+1
	AND #%00010000	; bit 4 only
	BEQ add_h	; no change, no halfcarry
		TSB f80	; or set H, A already was %00010000
add_h:
	JMP i_szp	; update flags and continue (18)

_80:
; ADD B (4)
;+66/71/76
	LDA b80		; appropriate register
	BRA addi	; common routine

_81:
; ADD C (4)
;+66/71/76
	LDA c80		; appropriate register
	BRA addi	; common routine

_82:
; ADD D (4)
;+66/71/76
	LDA d80		; appropriate register
	BRA addi	; common routine

_83:
; ADD E (4)
;+66/71/76
	LDA e80		; appropriate register
	BRA addi	; common routine

_84:
; ADD H (4)
;+66/71/76
	LDA h80		; appropriate register
	BRA addi	; common routine

_85:
; ADD L (4)
;+66/71/76
	LDA l80		; appropriate register
	BRA addi	; common routine

_87:
; ADD A (4), worth optimising? rot left, if C then toggle H, should recheck SZ & P
;+66/71/76
	LDA a80		; appropriate register
	BRA addi	; common routine

; immediate

_c6:
; ADI (7)
;+73/78/87
	_PC_ADV		; go for the operand
	LDA (pc80), Y	; immediate addressing
	BRA addi	; generic routine

; with carry

_8e:
; ADC M (7)
;+71/73/75
	LDA (hl80)	; variable term
adci:
	STA tmptr	; keep first operand! (+66/68/70)
	LDA f80		; get old flags
	LSR		; transfer emulated C on native carry! 
	AND #%01110111	; clear H, note shift
	STA f80		; store base flags
	LDA a80		; look at accumulator
	STA tmptr+1	; keep second
	ADC tmptr	; addition with carry
	STA a80		; store result
	TAX		; here too! eeeek
	ROL f80		; restore flags with result C
	JMP a_flags	; continue (34/36/38)

_88:
; ADC B (4)
;+72/74/76
	LDA b80		; appropriate register
	BRA adci

_89:
; ADC C (4)
;+72/74/76
	LDA b80		; appropriate register
	BRA adci

_8a:
; ADC D (4)
;+72/74/76
	LDA b80		; appropriate register
	BRA adci

_8b:
; ADC E (4)
;+72/74/76
	LDA b80		; appropriate register
	BRA adci

_8c:
; ADC H (4)
;+72/74/76
	LDA b80		; appropriate register
	BRA adci

_8d:
; ADC L (4)
;+72/74/76
	LDA b80		; appropriate register
	BRA adci

_8f:
; ADC A (4) might optimise as emulated C is OK for rots
;+72/74/76
	LDA b80		; appropriate register
	BRA adci

; immediate

_ce:
; ACI (7)
;+79/81/87
	_PC_ADV		; go for the operand
	LDA (pc80), Y	; immediate addressing
	BRA adci	; generic routine

_09:
; DAD B (10)
;+31
;***** affects just C ***** no faster but shorter
	LSR f80		; move C to native carry
	.al:	REP #%00100000	; ** 16 bit memory **
	LDA hl80		; add word
	ADC bc80
	STA hl80		; store result
	.as:	SEP #%00100000	; ** back to 8 bit **
	ROL f80		; restore emulated C flag
	JMP next_op

_19:
; DAD D (10)
;+31
	LSR f80		; move C to native carry
	.al:	REP #%00100000	; ** 16 bit memory **
	LDA hl80		; add word
	ADC de80
	STA hl80		; store result
	.as:	SEP #%00100000	; ** back to 8 bit **
	ROL f80		; restore emulated C flag
	JMP next_op


_29:
; DAD H (10)
;+31
	LSR f80		; move C to native carry
	.al:	REP #%00100000	; ** 16 bit memory **
	LDA hl80		; add word
	ADC hl80
	STA hl80		; store result
	.as:	SEP #%00100000	; ** back to 8 bit **
	ROL f80		; restore emulated C flag
	JMP next_op


_39:
; DAD SP (10)
;+31
	LSR f80		; move C to native carry
	.al:	REP #%00100000	; ** 16 bit memory **
	LDA hl80		; add word
	ADC sp80
	STA hl80		; store result
	.as:	SEP #%00100000	; ** back to 8 bit **
	ROL f80		; restore emulated C flag
	JMP next_op


; ** subtract **

_90:
; SUB B (4)
;+69/74/79
	LDA b80		; get register
	BRA subm	; common code

_91:
; SUB C (4)
;+69/74/79
	LDA c80		; get register
	BRA subm	; common code

_92:
; SUB D (4)
;+69/74/79
	LDA d80		; get register
	BRA subm	; common code

_93:
; SUB E (4)
;+69/74/79
	LDA e80		; get register
	BRA subm	; common code

_94:
; SUB H (4)
;+69/74/79
	LDA h80		; get register
	BRA subm	; common code

_95:
; SUB L (4)
;+69/74/79
	LDA l80		; get register
	BRA subm	; common code

_96:
; SUB M (7)
;+68/73/78
	LDA (hl80)		; variable term
subm:
	STA tmptr	; keep first operand! (+63/68/73)
	LDA a80		; look at accumulator
	STA tmptr+1	; keep second
	SEC		; ignore previous carry
	SBC tmptr	; subtraction
	STA a80		; store result
s_flags:
	TAX		; keep final result (+46/51/56)
	LDA #%00010001	; mask for H & C
	TRB f80	; clear them! eeeeeeek
	BCS s_nb	; no borrow was generated
		LDA #1		; mask for C
		TSB f80	; or set C
s_nb:
	JMP a_flags	; continue with rest of flags (34/36/38)

_97:
; SUB A (4) special as always returns zero
;+13
	LDA f80		; get flags
	AND #%01101110	; clear S, H & C
	ORA #%01000100	; set Z & P
	STZ a80		; clear A
	JMP next_op
	
; immediate

_d6:
; SUI (7)
;+76/81/90
	_PC_ADV		; go for the operand
	LDA (pc80), Y	; immediate addressing
	BRA subm	; generic routine

; * with borrow *

_98:
; SBB B (4)
;+85/90.5/96
	LDA b80		; get register
	BRA sbbm	; common code

_99:
; SBB C (4)
;+85/90.5/96
	LDA c80		; get register
	BRA sbbm	; common code

_9a:
; SBB D (4)
;+85/90.5/96
	LDA d80		; get register
	BRA sbbm	; common code

_9b:
; SBB E (4)
;+85/90.5/96
	LDA e80		; get register
	BRA sbbm	; common code

_9c:
; SBB H (4)
;+85/90.5/96
	LDA h80		; get register
	BRA sbbm	; common code

_9d:
; SBB L (4)
;+85/90.5/96
	LDA l80		; get register
	BRA sbbm	; common code

_9e:
; SBB M (7)
;+84/89.5/95
	LDA (hl80)		; variable term
sbbm:
	STA tmptr		; keep first operand! (+79/84.5/90)
	LDA f80			; old flags
	SEC
	BIT #%00000001	; check original C
	BNE sbb_c		; if set, no borrow! eeeeek
		CLC				; native carry
sbb_c:
	AND #%00101010	; clear SZHPC
	STA f80			; store base flags
	LDA a80			; look at accumulator
	STA tmptr+1		; keep second
	SBC tmptr		; subtraction
	STA a80			; store result
	JMP s_flags		; common end (49/54/59)

_9f:
; SBB A (4) result depends on C, not worth optimising
;+85/90.5/96
	LDA a80		; get register
	BRA sbbm	; common code

; immediate

_de:
; SBI (7)
;+92/97.5/107
	_PC_ADV		; go for the operand
	LDA (pc80), Y	; immediate addressing
	BRA sbbm	; generic routine

; *** LUT for S, Z & P status bits directly based on result as index ***
szp_lut:
	.byt	%01000100, %000, %000, %100, %000, %100, %100, %000	; zero to 7
	.byt		%000, %100, %100, %000, %100, %000, %000, %100	; 8-15
	.byt		%000, %100, %100, %000, %100, %000, %000, %100	; 16-23
	.byt		%100, %000, %000, %100, %000, %100, %100, %000	; 24-31
	.byt		%000, %100, %100, %000, %100, %000, %000, %100	; 32-39
	.byt		%100, %000, %000, %100, %000, %100, %100, %000	; 40-47
	.byt		%100, %000, %000, %100, %000, %100, %100, %000	; 48-55
	.byt		%000, %100, %100, %000, %100, %000, %000, %100	; 56-63
	.byt		%000, %100, %100, %000, %100, %000, %000, %100	; 64-71
	.byt		%100, %000, %000, %100, %000, %100, %100, %000	; 72-79
	.byt		%100, %000, %000, %100, %000, %100, %100, %000	; 80-87
	.byt		%000, %100, %100, %000, %100, %000, %000, %100	; 88-95
	.byt		%100, %000, %000, %100, %000, %100, %100, %000	; 96-103
	.byt		%000, %100, %100, %000, %100, %000, %000, %100	; 104-111
	.byt		%000, %100, %100, %000, %100, %000, %000, %100	; 112-119
	.byt		%100, %000, %000, %100, %000, %100, %100, %000	; 120-127
	.byt	$80, $84, $84, $80, $84, $80, $80, $84	; negative, 128-135
	.byt	$84, $80, $80, $84, $80, $84, $84, $80	; 136-143
	.byt	$84, $80, $80, $84, $80, $84, $84, $80	; 144-151
	.byt	$80, $84, $84, $80, $84, $80, $80, $84	; 152-159
	.byt	$84, $80, $80, $84, $80, $84, $84, $80	; 160-167
	.byt	$80, $84, $84, $80, $84, $80, $80, $84	; 168-175
	.byt	$80, $84, $84, $80, $84, $80, $80, $84	; 176-183
	.byt	$84, $80, $80, $84, $80, $84, $84, $80	; 184-191
	.byt	$84, $80, $80, $84, $80, $84, $84, $80	; 192-199
	.byt	$80, $84, $84, $80, $84, $80, $80, $84	; 200-207
	.byt	$80, $84, $84, $80, $84, $80, $80, $84	; 208-215
	.byt	$84, $80, $80, $84, $80, $84, $84, $80	; 216-223
	.byt	$80, $84, $84, $80, $84, $80, $80, $84	; 224-231
	.byt	$84, $80, $80, $84, $80, $84, $84, $80	; 232-239
	.byt	$84, $80, $80, $84, $80, $84, $84, $80	; 240-247
	.byt	$80, $84, $84, $80, $84, $80, $80, $84	; 248-255

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

