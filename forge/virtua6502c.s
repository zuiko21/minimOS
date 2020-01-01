; Virtual R65C02 for minimOS-16!!!
; COMPACT version!
; v0.1a7
; (c) 2016-2020 Carlos J. Santisteban
; last modified 20180731-1617

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

; *** allow optional kernel call trap ***
#define	TRAP	_TRAP

; *** declare zeropage addresses ***
; ** 'uz' is first available zeropage address (currently $03 in minimOS) **
s65		= uz		; stack pointer, may use next byte as zero
p65		= s65+2		; flags, keep MSB at zero

a65		= p65+2		; accumulator, all these with extra byte
x65		= a65+2		; X index
y65		= x65+2		; Y index

tmp		= y65+2		; temporary storage (word)

#ifdef	TRAP
; * TRAP option will use some memory for custom MALLOC structures *
t_min	= tmp+2		; first allocated page (2...127, 0 if empty)
t_max	= t_min+1	; first free page after allocated heap (up to 128)
t_page	= t_max+1	; array of allocated start pages (2...127) 16 entries
t_siz	= t_page+16	; array of allocated sizes (bit 7 hi if free)
cdev	= t_siz+16	; last address is I/O device
#else
cdev	= tmp+2		; I/O device *** minimOS specific ***
#endif

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
	PHX				; will be pulled later
#ifdef	TRAP
; *** *** preset bank pointers (see CAVEATS about kernel trap) *** ***
	STX zpar3+2		; preset 24b bank pointers (for current ABI)
	STX zpar2+2
; custom MALLOC init
;	STZ t_min		; means empty heap, will not use t_max
; newer scheme makes no distinction of empty case
	LDA #2			; start of available pages
	STA t_min		; set both sentinels
	STA t_max
	LDX #15			; max array offset
t_reset:
		STZ t_page, X	; clear entry
		STZ t_siz, X
		DEX
		BPL t_reset
#endif
; set virtual bank as current
	PLB				; switch to pushed bank!
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

; must add illegal NMOS opcodes (not yet used in 65C02) as NOPs

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
	ORA #%00010000	; but current virtual status remains with B (aka X) flag set!!!
	STA p65
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
; common clear flag code, CLC seems most used
do_clc:
	TRB p65			; gets cleared
	JMP next_op

_d8:
; CLD
; +13
	LDA #8			; D flag...

	BRA do_clc		; +11

_58:
; CLI
; +13
	LDA #4			; I flag...

	BRA do_clc		; +11

_b8:
; CLV
; +13
	LDA #$40		; V flag...

	BRA do_clc		; +11

_38:
; SEC
; +10
	LDA #1			; C flag...
; common set flag code, SEC seems most used
do_sec:
	TSB p65			; gets set
	JMP next_op

_f8:
; SED
; +13
	LDA #8			; D flag...

	BRA do_sec		; +11

_78:
; SEI
; +13
	LDA #4			; I flag...

	BRA do_sec		; +11

; * register inc/dec *

_ca:
; DEX
; +28
	DEC x65			; decrement index
	LDX x65			; check result, extra zero

	BRA std_nz		; check NZ (+19)

_88:
; DEY
; +28
	DEC y65			; decrement index
	LDX y65			; check result

	BRA std_nz		; check NZ (+19)

_e8:
; INX
; +28
	INC x65			; increment index
	LDX x65			; check result

	BRA std_nz		; check NZ (+19)

_c8:
; INY
; +28
	INC y65			; increment index
	LDX y65			; check result

	BRA std_nz		; check NZ (+19)

_3a:
; DEC [DEC A]
; +28
	DEC a65			; decrement A
	LDX a65			; check result

	BRA std_nz		; check NZ (+19)

_1a:
; INC [INC A]
; +28
	INC a65			; increment A
	LDX a65			; check result

	BRA std_nz		; check NZ (+19)

; * register transfer *

_aa:
; TAX
; +24
	LDA a65			; copy accumulator...
	STA x65			; ...to index
; *** standard NZ setting (+18, 16 if already in X) ***
tax_nz:
	TAX				; put value in X as LUT index
std_nz:
	LDA p65			; current status...
	AND #$7D		; ...minus previous NZ...
	ORA nz_lut, X	; ...plus flag mask
	STA p65
; all done
	JMP next_op

_a8:
; TAY
; +27
	LDA a65			; copy accumulator...
	STA y65			; ...to index

	BRA tax_nz		; check NZ from result (+21)

_ba:
; TSX
; +27
	LDA s65			; copy stack pointer...
	STA x65			; ...to index

	BRA tax_nz		; check NZ from result (+21)

_8a:
; TXA
; +27
	LDA x65			; copy index...
	STA a65			; ...to accumulator

	BRA tax_nz		; check NZ from result (+21)

_9a:
; TXS
; +27
	LDA x65			; copy index...
	STA s65			; ...to stack pointer

	BRA tax_nz		; check NZ from result (+21)

_98:
; TYA
; +27
	LDA y65			; copy index...
	STA a65			; ...to accumulator

	BRA tax_nz		; check NZ from result (+21)

; *** stack operations ***
; * push *

_48:
; PHA
; +20
	LDA a65			; get accumulator
; *** standard push of value in A, does not affect flags (+17) ***
do_pha:
	LDX s65			; and current SP, extra zero
	STA $0100, X	; push into stack
	DEC s65			; post-decrement
; all done
	JMP next_op

_da:
; PHX
; +23
	LDA x65			; get index

	BRA do_pha		; (+20)
_5a:
; PHY
; +23
	LDA y65			; get index

	BRA do_pha		; (+20)

_08:
; PHP
; +23
	LDA p65			; get status

	BRA do_pha		; (+20)

; * pull *

_68:
; PLA
; +38
	INC s65			; pre-increment SP
	LDX s65			; use as index, extra zero
	LDA $0100, X	; pull from stack
	STA a65			; pulled value goes to A

	BRA tax_nz		; +21

_fa:
; PLX
; +38
	INC s65			; pre-increment SP
	LDX s65			; use as index
	LDA $0100, X	; pull from stack
	STA x65			; pulled value goes to X

	BRA tax_nz		; +21

_7a:
; PLY
; +38
	INC s65			; pre-increment SP
	LDX s65			; use as index
	LDA $0100, X	; pull from stack
	STA y65			; pulled value goes to Y

	BRA tax_nz		; +21

_28:
; PLP
; +38
	INC s65			; pre-increment SP
	LDX s65			; use as index
	LDA $0100, X	; pull from stack
	STA p65			; pulled value goes to PSR

	BRA tax_nz		; +21

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
; immediate BIT does not use common code as no NV setting
	AND a65			; AND with accumulator
	BEQ g89z		; was zero
		LDA #2			; otherwise clear Z
		TRB p65
		JMP next_op		; all done if not Z
g89z:
	LDA #2			; otherwise set Z
	TSB p65
	JMP next_op

_24:
; BIT zp
; +42/42/50
	_PC_ADV			; get zeropage address
	LDA !0, Y		; cannot get extra byte!
	TAX				; temporary index...
; *** fastest common BIT code (+33/33/41) ***
bit_nv:
	LDA !0, X		; get value
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
; +50/50/58
	_PC_ADV			; get zeropage address
	LDA !0, Y		; cannot get extra byte!
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	BRA bit_nv		; +36-44

_2c:
; BIT abs
; +46/46/54
	_PC_ADV			; point to operand
	LDX !0, Y		; just full address!
	_PC_ADV			; skip MSB

	BRA bit_nv		; +36-44

_3c:
; BIT abs, X
; +61/61/69
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	BRA bit_nv		; +36-44

; *** jumps ***
; * conditional branches *

_90:
; BCC rel
; +12 if not taken
; +50/50.5/51* if taken
	_PC_ADV			; PREPARE relative address
	LDA #1			; will check C flag
	AND p65
	BEQ do_bra		; will branch
		JMP next_op		; or just continue

_b0:
; BCS rel
; +12 if not taken
; +50/50.5/51* if taken
	_PC_ADV			; PREPARE relative address
	LDA #1			; will check C flag
	AND p65
	BNE do_bra		; will branch
		JMP next_op		; or just continue

_30:
; BMI rel
; +12 if not taken
; +50/50.5/51* if taken
	_PC_ADV			; PREPARE relative address
	LDA #128		; will check N flag
	AND p65
	BNE do_bra		; will branch
		JMP next_op		; or just continue

_10:
; BPL rel
; +12 if not taken
; +50/50.5/51* if taken
	_PC_ADV			; PREPARE relative address
	LDA #128		; will check N flag
	AND p65
	BEQ do_bra		; will branch
		JMP next_op		; or just continue

_f0:
; BEQ rel
; +12 if not taken
; +50/50.5/51* if taken
	_PC_ADV			; PREPARE relative address
	LDA #2			; will check Z flag
	AND p65
	BNE do_bra		; will branch
		JMP next_op		; or just continue

_d0:
; BNE rel
; +12 if not taken
; +50/50.5/51* if taken
	_PC_ADV			; PREPARE relative address
	LDA #2			; will check Z flag
	AND p65
	BEQ do_bra			; will branch
		JMP next_op		; or just continue

_80:
; BRA rel
; +40/40.5/41*
; *** common branch code ***
do_bra:
	LDX #0			; will use as sign extention
	LDA !0, Y		; get offset
	BPL g80p		; forward jump, no extention
		DEX			; backwards means at least MSB is $FF
g80p:
	STX tmp			; store MSB and extra
	STA tmp			; this is LSB only
	.al: REP #$21		; 16-bit add & CLC
	_PC_ADV			; skip whole instruction!
	TYA			; next address...
	ADC tmp			; ...plus or minus offset
	TAY			; result in PC
	LDA #0			; clear B
	.as: SEP #$20
	JMP execute		; PC is ready!

_50:
; BVC rel
; +12 if not taken
; +50/50.5/51* if taken
	_PC_ADV			; PREPARE relative address
	LDA #64			; will check V flag
	AND p65
	BEQ do_bra		; will branch
		JMP next_op		; or just continue

_70:
; BVS rel
; +12 if not taken
; +50/50.5/51* if taken
	_PC_ADV			; PREPARE relative address
	LDA #64			; will check V flag
	AND p65
	BNE do_bra		; will branch
		JMP next_op		; or just continue

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
; +44* (+5 or +10 if support for native mOS calls)
	_PC_ADV			; point to addeess
; first compute return address
	.al: REP #$20
	TYA				; copy PC...
	INC				; at MSB
; push address as we are at the last byte of the instruction
	LDX s65			; current SP with extra
	DEX				; LSB location
	STA !$0100, X	; return address into virtual stack
	DEX				; post-decrement
	STX s65			; update SP
	LDA #0			; clear B
	.as: SEP #20
; jump to destination
	LDX !0, Y		; target address
; *** should include here a trap for NATIVE minimOS Kernel calls! ***
#ifdef	TRAP
	CPX #$FFC0		; minimOS Kernel call?
		BEQ mos_k		; execute natively!
;	CPX #$FFD0		; minimOS firmware call? worth it?
;		BEQ mos_f		; execute natively! * TO DO *
#endif
; *** disable the above code if not needed ***
; jump to target address
	TXY				; ready!
	JMP execute

#ifdef	TRAP
; *** management of trapped native calls ***
mos_f:
; not sure if worth it...
; repeat kpar_l loop and make special JSL $FFD8, then go after COP
mos_k:
; *** transfer virtual parameters to host space ***
	LDX #11			; max offset on parameter area
kpar_l:
		LDA !$F0, X		; copy parameter from virtual space...
		STA $F0, X		; ...into host zeropage
		DEX			; until done
		BPL kpar_l
	LDY y65			; base parameter
; *** call native OS ***
	LDX x65			; requested kernel function
; *** *** *** CAVEATS *** *** ***
; 1. R65C02 code is unaware of 24-bit pointers, but actual call is issued by
;    virtua6502, which stands as a 16-bit app, disabling pointer auto-fill.
;    A feasible workaround would be presetting the bank address on pointer
;    parameters with the current bank address.
; 2. MALLOC calls should NOT provide blocks from bank 0, as expected with 6502
;    code, because they will NOT be reachable from EMULATED code! It sholud use
;    the memory _inside_ the virtual space bank, as long as its vital
;    structures (zeropage, stack, app code...) are respected. The only way I can
;    think is re-trapping those calls to a custom MALLOC/FREE, allegedly much
;    simpler as guaranteed to be single-task.
; *** *** *** *** *** *** *** ***
	CPX #MALLOC		; is it trying to allocate memory?
		BEQ t_aloc		; use custom code!
	CPX #FREE		; ditto for releasing memory
		BEQ t_free
; * end of MALLOC/FREE trap *
	CLC
	COP #$7F		; NATIVE 65816 minimOS Kernel call (no macro)
; *** return error flag, if available ***
	BCC mos_ok		; no error to report
		LDA #1			; set virtual C flag
		TSB p65
mos_ok:
; *** extract possible return values ***
	STY y65			; base parameter
	LDX #11			; max offset on parameter area
kpar_r:
		LDA $F0, X		; copy host values...
		STA !$F0, X		; ...into virtual space
		DEX			; until done
		BPL kpar_r
; *** return to caller, worth using virtual RTS ***
	JMP _60			; execute virtual RTS, even faster

t_free:
	BRA t_free2		; was too far...

; *** *** custom MALLOC code *** ***
t_aloc:
; * note that ma_align is ignored! Always page-aligned *
; should convert generic size request into full pages... and detect full-size requests
	LDA ma_rs
	ORA ma_rs+1		; asking for full size?
	BNE m_nfull		; no, regular procedure
; t_min can no longer be zero
;		LDA t_min		; yes, first check wheter empty
;		BNE mf_siz		; not empty, deduce size
;			LDA #126		; full 31.5K otherwise!
;			STA ma_rs+1
;			BRA do_fp		; proceed in a simple way
;mf_siz:
		LDA t_min		; look for space before heap
		SEC
		SBC #2			; minus reserved
		STA ma_pt+1		; store leading size
		LDA #128		; let us look after the heap
		SEC
		SBC t_max		; this is trailing size
		CMP ma_pt+1		; bigger than leading?
		BCC mf_max		; no, already set at maximum
			STA ma_pt+1		; yes, update size
mf_max:
		BRA m_pgft		; allocate this size
m_nfull:
	LDA ma_rs		; check whether complete pages
	BEQ m_pgft		; yes, leave parameter
		INC ma_rs+1		; no, round up to full page
m_pgft:
; look for some room
; t_min can no longer be zero
	LDA t_min		; look space before heap first
;	BNE do_aloc		; not empty, regular procedure
;do_fp:
;		LDA #2			; yes, set heap start...
;		STA t_min			; ...as new minimum
;		JSR in_list		; create first entry
;		LDA ma_rs+1		; plus size...
;		CLC
;		ADC #2			; ...from start...
;		BPL fp_ok		; fits fine
;			LDA #2			; no, remove very first entry
;			BRA tma_err		; over 32K, no way!
;fp_ok:
;		STA t_max		; ...is new end
;		BRA tma_ok
;do_aloc:
	DEC				; check whether it fits before heap...
	DEC				; ...subtract reserved pages
	CMP ma_rs+1		; how many pages were asked?
	BCC m_heap		; no room before, put it after heap
		INC				; fits! will stick before heap
		INC				; as fast but smaller
		SBC ma_rs+1		; C already set
		STA t_min		; new minimum is the address
		JSR in_list		; insert into list
		BRA tma_ok		; was successful
m_heap:
	LDA t_max		; the end of the heap is allocated address
	PHA				; best way
	JSR in_list		; create entry
	PLA				; original value...
	CLC
	ADC ma_rs+1		; ...plus size...
	BPL mh_ok		; fits fine
		LDA t_max		; no, remove this entry
		BRA tma_err		; over 32K, no way!
mh_ok:
	STA t_max		; ...is the new end
tma_ok:
; * successfull MALLOC *
	STZ !ma_pt		; always page-aligned (direct into virtual ZP)
	LDA #1			; mask for C flag
	TRB p65			; no error!
	JMP _60			; execute virtual RTS
;tma_err:
;	BRA tma_err2		; too far...

; *** *** custom FREE code *** ***
t_free2:
	LDA ma_pt+1		; get allocated page (assume all aligned)
	LDX #15			; max array offset
fr_loop:
		CMP t_page, X	; requested entry?
			BEQ fr_this		; yes, fill it
		DEX			; no, go for next
		BPL fr_loop
; ***************************
; ** common error routines **
fr_not:
; * notify error and abort *
	LDA #N_FOUND		; no entry to be freed
	STA y65			; set error code
	LDA #1			; mask for C flag
	TSB p65			; indicate error!
	JMP _60			; execute virtual RTS

tma_err:			; was err2
; * could not allocate, A is bogus allocated page *
		JSR out_lst		; remove failed entry
tma_not:
; notify error and abort
	LDA #FULL		; no more available entries
	STA y65			; set error code
	LDA #1			; mask for C flag
	TSB p65			; indicate error!
	JMP _60			; execute virtual RTS
; ** end of error routines **
; ***************************
fr_this:
	LDA t_siz, X	; let us mark entry as deleted...
	ORA #128		; ...by setting bit 7
	STA t_siz, X
	LDA ma_pt+1		; where was the allocated block?
	CMP t_min		; at heap beginning?
	BNE fr_end		; no, look at the other side
; try to delete as many blocks to the left as possible
fr_left:
		CLC				; yes, delete lower side of heap...
		TAY				; (keep current minimum for later)
		ADC t_siz, X	; ...by adding current size to minimum
		STA t_min
		TYA				; retrieve deleted block...
		JSR out_lst		; ...and delete its entry
; now let us check for deleted entries at heap start in case they can be skipped
		LDA t_min		; current heap start
		LDX #15			; max offset
fr_dl:
			CMP t_page, X	; is this entry at start...?
			BNE fd_nxl
				BIT t_siz, X	; ...and deleted?
				BMI fr_left		; yes, remove it
fd_nxl:
			DEX				; try next
			BPL fr_dl
		BRA tma_ok		; all done, no errors!
fr_end:
	CLC
	ADC t_siz, X	; add size to check where it ends
	CMP t_max		; was it last?
	BNE tma_ok		; could not delete anything, but that is OK
; otherwise try to delete as many blocks to the right as possible
fr_right:
		SEC				; yes, delete upper side of heap...
		TAY				; (keep current maximum for later)
		SBC t_siz, X	; ...by subtracting current size to maximum
		STA t_max
		TYA				; retrieve deleted block...
		JSR out_lst		; ...and delete its entry
; now let us check for deleted entries at heap start in case they can be skipped
		LDA t_max		; current heap start
		LDX #15			; max offset
fr_dr:
			CMP t_page, X	; is this entry at end...?
			BNE fd_nxr
				BIT t_siz, X	; ...and deleted?
				BMI fr_right		; yes, remove it
fd_nxr:
			DEX				; try next
			BPL fr_dr
		BRA tma_ok		; all done, no errors!

; *** supporting routines ***
; ** create list entry, A is allocated page **
in_list:
	STA !ma_pt+1		; A is the allocated address (virtual ZP)
	TAY			; keep for later, RTS will set it
	LDX #15			; max array offset
il_loop:
		LDA t_page, X	; free entry?
			BEQ il_free		; yes, fill it
		DEX			; no, go for next
		BPL il_loop
	PLA			; discard return address eeeeeeeeek
	PLA
	BRA tma_not		; no entry to remove, just notify
; found free entry, create new
il_free:
	TYA				; retrieve allocated bank
	STA t_page, X	; create entry
	LDA ma_rs+1		; include size too
	STA t_siz+1, X
	RTS

; ** remove list entry, A is allocated page **
out_lst:
	LDX #15			; max offset
ol_loop:
		CMP t_page, X	; is the requested entry?
			BEQ ol_found		; yes, remove it
		DEX			; no, try next
		BPL ol_loop
		BMI ol_rts		; not found, just return
ol_found:
	STZ t_page, X	; clear entry
	STZ t_siz, X
ol_rts:
	RTS
#endif

; *** load / store ***

; * load *

_a2:
; LDX imm
; +31
	_PC_ADV			; get immediate operand
	LDA !0, Y
	STA x65			; update register

	JMP tax_nz		; +21

_a6:
; LDX zp
; +35
	_PC_ADV			; get zeropage address
	LDA !0, Y		; temporary index...
	TAX				; ...cannot pick extra...
	LDA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA x65			; update register

	JMP tax_nz		; +21

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

	JMP tax_nz		; +21

_ae:
; LDX abs
; +36
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
	LDA !0, X		; load operand
	STA x65			; update register

	JMP tax_nz		; +21

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

	JMP tax_nz		; +21

_a0:
; LDY imm
; +28
	_PC_ADV			; get immediate operand
	LDA !0, Y
	STA x65			; update register

	JMP tax_nz		; +21

_a4:
; LDY zp
; +35
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA y65			; update register

	JMP tax_nz		; +21

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

	JMP tax_nz		; +21

_ac:
; LDY abs
; +36
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
	LDA !0, X		; load operand
	STA y65			; update register

	JMP tax_nz		; +21

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

	JMP tax_nz		; +21

_a9:
; LDA imm
; +28
	_PC_ADV			; get immediate operand
	LDA !0, Y
	STA a65			; update register

	JMP tax_nz		; +21

_a5:
; LDA zp
; +35
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	STA a65			; update register

	JMP tax_nz		; +21

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

	JMP tax_nz		; +21

_ad:
; LDA abs
; +36
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
	LDA !0, X		; load operand
	STA a65			; update register

	JMP tax_nz		; +21

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

	JMP tax_nz		; +21

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

	JMP tax_nz		; +21

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

	JMP tax_nz		; +21

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

	JMP tax_nz		; +21

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

	JMP tax_nz		; +21

; * store *

_86:
; STX zp
; +20
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
; *** common STX (11) ***
do_stx:
	LDA x65			; value to be stored
	STA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	JMP next_op

_96:
; STX zp, Y
; +28
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC y65			; add offset
	TAX				; temporary index...

	BRA do_stx		; +14
_8e:
; STX abs
; +24
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB

	BRA do_stx		; +14

_84:
; STY zp
; +23
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	BRA do_sty		; +14

_94:
; STY zp, X
; +28
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add offset
	TAX				; temporary index...

	BRA do_sty		; +14

_8c:
; STY abs
; +21
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
do_sty:
	LDA y65			; value to be stored
	STA !0, X		; store operand
	JMP next_op

_64:
; STZ zp
; +17
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
do_stz:
	STZ !0, X		; store operand
	JMP next_op

_74:
; STZ zp, X
; +25
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add offset
	TAX				; temporary index...

	BRA do_stz		; +11

_9c:
; STZ abs
; +21
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB

	BRA do_stz		; +11

_9e:
; STZ abs, X
; +36
	_PC_ADV			; get address
	.al: REP #21	; 16-b... and CLC
	LDA !0, Y		; base address
	ADC x65			; pluss offset & extra
	_PC_ADV			; skip MSB
	TAX				; final address
	LDA #0			; clear B
	.as: SEP #$20

	BRA do_stz		; +11

_8d:
; STA abs
; +21
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
do_sta:
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

	BRA do_sta		; +14

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

	BRA do_sta		; +14

_85:
; STA zp
; +20
	_PC_ADV			; get zeropage address
	LDA !0, Y		; base address
	TAX				; temporary index...

	BRA do_sta		; +14

_95:
; STA zp, X
; +25
	_PC_ADV			; get zeropage address
	LDA !0, Y		; base address
	CLC
	ADC x65			; add index
	TAX				; temporary index...

	BRA do_sta		; +14

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

	BRA do_sta		; +14

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

	BRA do_sta		; +14

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

	BRA do_sta		; +14

; *** logic ops ***
; * and *

_29:
; AND imm
; +39
	_PC_ADV			; get immediate operand
	TYX			; common code ready

	BRA do_and		; +35

_25:
; AND zp
; +41
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
; *** common AND code (+32) ***
do_and:
	LDA !0, X		; get data
	AND a65			; do AND
	STA a65			; eeeeeeeeeeeeek

	JMP tax_nz		; +21
_35:
; AND zp, X
; +49
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	BRA do_and		; +35

_2d:
; AND abs
; +45
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB

	BRA do_and		; +35

_3d:
; AND abs, X
; +61
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	BRA do_and		; +35

_39:
; AND abs, Y
; +61
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC y65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	BRA do_and		; +35

_32:
; AND (zp)
; +62
	_PC_ADV			; get zeropage pointer
	LDA !0, Y		; cannot pick extra
	TAX				; temporary index...
	.al: REP #$20
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	BRA do_and		; +35

_31:
; AND (zp), Y
; +66
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	TAX				; temporary index...
	.al: REP #$21	; 16b & CLC
	LDA !0, X		; ...pick full pointer from emulated zeropage
	ADC y65			; indexed
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	BRA do_and		; +35

_21:
; AND (zp, X)
; +66
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	.al: REP #$21	; 16b & CLC
	ADC x65			; preindexing, worth picking extra
	TAX				; temporary index...
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	BRA do_and		; +35

; * inclusive or *

_09:
; ORA imm
; +39
	_PC_ADV			; get immediate operand
	TYX

	BRA do_ora		; +35

_05:
; ORA zp
; +41
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
; common ORA +32
do_ora:
	LDA !0, X		; read operand
	ORA a65			; do OR
	STA a65			; eeeeeeeeeeeeek

	JMP tax_nz		; +21

_15:
; ORA zp, X
; +49
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	BRA do_ora		; +35

_0d:
; ORA abs
; +45
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB

	BRA do_ora		; +35

_1d:
; ORA abs, X
; +61
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	BRA do_ora		; +35

_19:
; ORA abs, Y
; +61
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC y65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	BRA do_ora		; +35

_12:
; ORA (zp)
; +62
	_PC_ADV			; get zeropage pointer
	LDA !0, Y		; cannot pick extra
	TAX				; temporary index...
	.al: REP #$20
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	BRA do_ora		; +35

_11:
; ORA (zp), Y
; +66
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	TAX				; temporary index...
	.al: REP #$21	; 16b & CLC
	LDA !0, X		; ...pick full pointer from emulated zeropage
	ADC y65			; indexed
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	BRA do_ora		; +35

_01:
; ORA (zp, X)
; +66
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	.al: REP #$21	; 16b & CLC
	ADC x65			; preindexing, worth picking extra
	TAX				; temporary index...
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	BRA do_ora		; +35

; * exclusive or *

_49:
; EOR imm
; +39
	_PC_ADV			; get immediate operand
	TYX

	BRA do_xor		; +35

_45:
; EOR zp
; +41
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
do_xor:
	LDA !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	EOR a65			; do XOR
	STA a65			; eeeeeeeeeeeeek

	JMP tax_nz		; +21

_55:
; EOR zp, X
; +49
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	BRA do_xor		; +35

_4d:
; EOR abs
; +45
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB

	BRA do_xor		; +35

_5d:
; EOR abs, X
; +61
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	BRA do_xor		; +35

_59:
; EOR abs, Y
; +61
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC y65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	BRA do_xor		; +35

_52:
; EOR (zp)
; +62
	_PC_ADV			; get zeropage pointer
	LDA !0, Y		; cannot pick extra
	TAX				; temporary index...
	.al: REP #$20
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	BRA do_xor		; +35

_51:
; EOR (zp), Y
; +66
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	TAX				; temporary index...
	.al: REP #$21	; 16b & CLC
	LDA !0, X		; ...pick full pointer from emulated zeropage
	ADC y65			; indexed
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	BRA do_xor		; +35

_41:
; EOR (zp, X)
; +66
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	.al: REP #$21	; 16b & CLC
	ADC x65			; preindexing, worth picking extra
	TAX				; temporary index...
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	BRA do_xor		; +35

; *** arithmetic ***
; * add with carry *

_69:
; ADC imm
; +54
	_PC_ADV			; seek immediate operand
	TYX

	BRA do_adc		; +50

_65:
; ADC zp
; +59
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	BRA do_adc		; +50

_75:
; ADC zp, X
; +64
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	BRA do_adc		; +50

_6d:
; ADC abs
; +57
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
; *** common ADC ***
do_adc:
; copy virtual status (+47)
	PHP				; will tinker with host status!
	LDA p65			; pick virtual status
	ORA #$20		; make sure M=1 & X=0!
	AND #$EF
	PHA
	PLP				; assume virtual status (X=0!)
; proceed
	LDA !0, X		; worth TYX in compact
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

_7d:
; ADC abs, X
; +75
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	BRA do_adc		; +50

_79:
; ADC abs, Y
; +75
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC y65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	BRA do_adc		; +50

_72:
; ADC (zp)
; +76
	_PC_ADV			; get zeropage pointer
	LDA !0, Y		; cannot pick extra
	TAX				; temporary index...
	.al: REP #$20
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	BRA do_adc		; +50

_71:
; ADC (zp), Y
; +80
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	TAX				; temporary index...
	.al: REP #$21	; 16b & CLC
	LDA !0, X		; ...pick full pointer from emulated zeropage
	ADC y65			; indexed
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	BRA do_adc		; +50

_61:
; ADC (zp, X)
; +80
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	.al: REP #$21	; 16b & CLC
	ADC x65			; preindexing, worth picking extra
	TAX				; temporary index...
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	BRA do_adc		; +50

; * subtract with borrow *

_e9:
; SBC imm
; +54
	_PC_ADV			; get immediate operand
	TYX

	BRA do_sbc		; +50

_e5:
; SBC zp
; +59
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	BRA do_sbc		; +50

_f5:
; SBC zp, X
; +64
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	BRA do_sbc		; +50

_ed:
; SBC abs
; +57
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB

; *** common SBC ***
do_sbc:
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

_fd:
; SBC abs, X
; +75
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	BRA do_sbc		; +50

_f9:
; SBC abs, Y
; +75
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	BRA do_sbc		; +50

_f2:
; SBC (zp)
; +76
	_PC_ADV			; get zeropage pointer
	LDA !0, Y		; cannot pick extra
	TAX				; temporary index...
	.al: REP #$20
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	BRA do_sbc		; +50

_f1:
; SBC (zp), Y
; +80
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	TAX				; temporary index...
	.al: REP #$21	; 16b & CLC
	LDA !0, X		; ...pick full pointer from emulated zeropage
	ADC y65			; indexed
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	BRA do_sbc		; +50

_e1:
; SBC (zp, X)
; +80
	_PC_ADV			; get zeropage pointer
	LDA !0, Y
	.al: REP #$21	; 16b & CLC
	ADC x65			; preindexing, worth picking extra
	TAX				; temporary index...
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	BRA do_sbc		; +50

; * inc/dec memory *

_e6:
; INC zp
; +42
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
; *** common INC (+33) ***
do_inc:
	INC !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	LDA !0, X		; retrieve value

	JMP tax_nz

_f6:
; INC zp, X
; +50
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	BRA do_inc		; +36

_ee:
; INC abs
; +46
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB

	BRA do_inc		; +36

_fe:
; INC abs, X
; +61
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	BRA do_inc		; +36

_c6:
; DEC zp
; +42
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
; *** common DEC *** (+33)
do_dec:
	DEC !0, X		; ...for emulated zeropage *** must use absolute for emulated bank ***
	LDA !0, X		; retrieve value

	JMP tax_nz

_d6:
; DEC zp, X
; +50
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	BRA do_dec		; +36

_ce:
; DEC abs
; +46
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB

	BRA do_dec		; +36

_de:
; DEC abs, X
; +61
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	BRA do_dec		; +36

; * comparisons *

_cd:
; CMP abs
; +57
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB

	BRA do_cmp		; +47

_dd:
; CMP abs, X
; +72
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	BRA do_cmp		; +47

_d9:
; CMP abs, Y
; +72
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	BRA do_cmp		; +47

_c9:
; CMP imm
; +48
	_PC_ADV			; get immediate operand
	TYX
; *** common CMP ***
do_cmp:
; copy virtual status (+44)
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

_c5:
; CMP zp
; +56
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	BRA do_cmp		; +47

_d5:
; CMP zp, X
; +61
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	BRA do_cmp		; +47

_d2:
; CMP (zp)
; +73
	_PC_ADV			; get zeropage pointer
	LDA !0, Y		; cannot pick extra
	TAX				; temporary index...
	.al: REP #$20
	LDA !0, X		; ...pick full pointer from emulated zeropage
	TAX				; final address...
	LDA #0			; clear B
	.as: SEP #$20

	BRA do_cmp		; +47

_d1:
; CMP (zp), Y
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

	BRA do_cmp		; +47

_c1:
; CMP (zp, X)
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

	BRA do_cmp		; +47

_ec:
; CPX abs
; +54
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
; *** common CPX code ***
do_cpx:
; copy virtual status (+44)
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
; +51
	_PC_ADV			; get immediate operand
	TYX

	BRA do_cpx		; +47

_e4:
; CPX zp
; +53
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	BRA do_cpx		; +47

_cc:
; CPY abs
; +54
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
; *** common CPY code ***
do_cpy:
; copy virtual status (+44)
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
; +51
	_PC_ADV			; get immediate operand
	TYX

	BRA do_cpy		; +47

_c4:
; CPY zp
; +56
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	BRA do_cpy		; +47

; *** bit shifting ***
; * shift *

_0e:
; ASL abs
; +42
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
; common ASL code, address in X (+32)
do_asl:
	ASL !0, X		; shift destination
	LDA !0, X		; get result...
; *** check NZ.. and C *** (+20)
set_nzc:
	TAX				; LUT index
	LDA p65			; original status
	AND #$7C		; ...minus NZC!
	ORA nz_lut, X	; ...adds flag mask
	ADC #0			; and C, if set!
	STA p65
	JMP next_op

_1e:
; ASL abs, X
; +60
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	BRA do_asl		; +35

_0a:
; ASL [ASL A]
; +31
	ASL a65			; shift accumulator
	LDA a65			; get result, cannot pick extra

	BRA set_nzc		; +23

_06:
; ASL zp
; +44
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	BRA do_asl		; +35

_16:
; ASL zp, X
; +49
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	BRA do_asl		; +35

_4e:
; LSR abs
; +45
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
; common LSR code, address in X (+35)
do_lsr:
	LSR !0, X		; shift destination
	LDA !0, X		; get result...

	BRA set_nzc		; +23

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

	BRA do_lsr		; +38

_4a:
; LSR [LSR A]
; +31
	LSR a65			; shift destination
	LDA a65			; get result...

	BRA set_nzc		; +23

_46:
; LSR zp
; +47
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	BRA do_lsr		; +38

_56:
; LSR zp, X
; +52
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	BRA do_lsr		; +38

; * rotation *

_2e:
; ROL abs
; +47
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
; *** common ROL code, address in X (+37) ***
do_rol:
	LSR p65			; extract previous C
	ROL !0, X		; rotate destination
	LDA !0, X		; get result...
; set shifted NZC (+20)
rot_nzc:
	TAX				; LUT index
	LDA p65			; original SHIFTED status
	AND #$3E		; ...minus NZC! Note shift
	ROL				; unshift and insert C
	ORA nz_lut, X	; add flag mask
	STA p65
	JMP next_op

_3e:
; ROL abs, X
; +65
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	BRA do_rol		; +40

_2a:
; ROL [ROL A]
; +36

	LSR p65			; extract previous C
	ROL a65			; rotate destination
	LDA a65			; get result...

	BRA rot_nzc		; +23

_26:
; ROL zp
; +49
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	BRA rot_nzc		; +23

_36:
; ROL zp, X
; +54
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	BRA rot_nzc		; +23

_6e:
; ROR abs
; +50
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
; *** common ROR code, address in X (+40) ***
do_ror:
	LSR p65			; extract previous C
	ROR !0, X		; rotate destination
	LDA !0, X		; get result...
	BRA rot_nzc		; +23

_7e:
; ROR abs, X
; +68
	_PC_ADV			; get LSB
	.al: REP #$21	; 16-bit... and clear C
	LDA !0, Y		; just full address!
	_PC_ADV			; skip MSB
	ADC x65			; do indexing, picks extra
	TAX				; final address, B remains touched
	LDA #0			; use extra byte to clear B
	.as: SEP #$20

	BRA do_ror		; +43

_6a:
; ROR [ROR A]
; +36

	LSR p65			; extract previous C
	ROR a65			; rotate destination
	LDA a65			; get result...

	BRA rot_nzc		; +23

_66:
; ROR zp
; +52
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	BRA do_ror		; +43

_76:
; ROR zp, X
; +57
	_PC_ADV			; get zeropage address
	LDA !0, Y
	CLC
	ADC x65			; add index, forget carry as will page-wrap
	TAX				; temporary index...

	BRA do_ror		; +43

; *** bit handling ***
; * test & lock *

_1c:
; TRB abs
; +47/47/49
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
; common native TRB routine 30b (+37-39) BEST
do_trb:
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
; +49/49/52
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	BRA do_trb		; +40-43

_0c:
; TSB abs
; +44/44/45
	_PC_ADV			; get address
	LDX !0, Y
	_PC_ADV			; skip MSB
; common TSB routine (+34-35) 30b
do_tsb:
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
; +46/46/47
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...

	BRA do_tsb		; +37-38


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
do_rmb:
	AND !0, X		; keep all but selected
	STA !0, X
	JMP next_op

_17:
; RMB1 zp
; +27
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #%11111101	; REVERSE mask for bit 1

	BRA do_rmb		; +16

_27:
; RMB2 zp
; +27
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #%11111011	; REVERSE mask for bit 2

	BRA do_rmb		; +16

_37:
; RMB3 zp
; +27
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #%11110111	; REVERSE mask for bit 3

	BRA do_rmb		; +16

_47:
; RMB4 zp
; +27
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #%11101111	; REVERSE mask for bit 4

	BRA do_rmb		; +16

_57:
; RMB5 zp
; +27
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #%11011111	; REVERSE mask for bit 5

	BRA do_rmb		; +16

_67:
; RMB6 zp
; +27
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #%10111111	; REVERSE mask for bit 6

	BRA do_rmb		; +16

_77:
; RMB7 zp
; +27
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #%01111111	; REVERSE mask for bit 7

	BRA do_rmb		; +16

_87:
; SMB0 zp
; +24
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #1			; mask for bit 0
; common SMB, mask in A, address in X (+13)
do_smb:
	ORA !0, X		; set selected
	STA !0, X
	JMP next_op

_97:
; SMB1 zp
; +27
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #2			; mask for bit 1

	BRA do_smb		; +16

_a7:
; SMB2 zp
; +27
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #4			; mask for bit 2

	BRA do_smb		; +16

_b7:
; SMB3 zp
; +27
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #8			; mask for bit 3

	BRA do_smb		; +16

_c7:
; SMB4 zp
; +27
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #16			; mask for bit 4

	BRA do_smb		; +16

_d7:
; SMB5 zp
; +27
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #32			; mask for bit 5

	BRA do_smb		; +16

_e7:
; SMB6 zp
; +27
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #64			; mask for bit 6

	BRA do_smb		; +16

_f7:
; SMB7 zp
; +27
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #128		; mask for bit 7

	BRA do_smb		; +16

; * branch on bits *

_0f:
; BBR0 zp, rel
; +24 if not taken
; +63/63.5/64* if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #1			; mask for bit 0
; common BBR code (+13, +52/52.5/53*)
do_bbr:
	_PC_ADV			; skip to displacement
	AND !0, X		; is it set?
	BNE g0f			; will not branch
		JMP do_bra		; do branch, already set at offset
g0f:
	JMP next_op

_1f:
; BBR1 zp, rel
; +27 if not taken
; +66/66.5/67* if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #2			; mask for bit 1

	BRA do_bbr		; +16

_2f:
; BBR2 zp, rel
; +27 if not taken
; +66/66.5/67* if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #4			; mask for bit 2

	BRA do_bbr		; +16

_3f:
; BBR3 zp, rel
; +27 if not taken
; +66/66.5/67* if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #8			; mask for bit 3

	BRA do_bbr		; +16

_4f:
; BBR4 zp, rel
; +27 if not taken
; +66/66.5/67* if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #16			; mask for bit 4

	BRA do_bbr		; +16

_5f:
; BBR5 zp, rel
; +27 if not taken
; +66/66.5/67* if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #32			; mask for bit 5

	BRA do_bbr		; +16

_6f:
; BBR6 zp, rel
; +27 if not taken
; +66/66.5/67* if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #64			; mask for bit 6

	BRA do_bbr		; +16

_7f:
; BBR7 zp, rel
; +27 if not taken
; +66/66.5/67* if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #128		; mask for bit 7

	BRA do_bbr		; +16

_8f:
; BBS0 zp, rel
; +24 if not taken
; +63/63.5/64 * if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #1			; mask for bit 0
; common BBS code (+13, +52/52.5/53*)
do_bbs:
	_PC_ADV			; skip to displacement
	AND !0, X		; is it clear?
	BEQ g8f			; will not branch
		JMP do_bra		; do branch, already set at offset
g8f:
	JMP next_op

_9f:
; BBS1 zp, rel
; +27 if not taken
; +66/66.5/67* if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #2			; mask for bit 1

	BRA do_bbs		; +16

_af:
; BBS2 zp, rel
; +27 if not taken
; +66/66.5/67* if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #4			; mask for bit 2

	BRA do_bbs		; +16

_bf:
; BBS3 zp, rel
; +27 if not taken
; +66/66.5/67* if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #8			; mask for bit 3

	BRA do_bbs		; +16

_cf:
; BBS4 zp, rel
; +27 if not taken
; +66/66.5/67* if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #16			; mask for bit 4

	BRA do_bbs		; +16

_df:
; BBS5 zp, rel
; +27 if not taken
; +66/66.5/67* if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #32			; mask for bit 5

	BRA do_bbs		; +16

_ef:
; BBS6 zp, rel
; +27 if not taken
; +66/66.5/67* if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #64			; mask for bit 6

	BRA do_bbs		; +16

_ff:
; BBS7 zp, rel
; +27 if not taken
; +66/66.5/67* if taken
	_PC_ADV			; get zeropage address
	LDA !0, Y
	TAX				; temporary index...
	LDA #128		; mask for bit 7

	BRA do_bbs		; +16

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
