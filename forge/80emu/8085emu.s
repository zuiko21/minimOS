; Intel 8080/8085 emulator for minimOS! *** REASONABLY COMPACT VERSION ***
; v0.1a5
; (c) 2016 Carlos J. Santisteban
; last modified 20160822-2226

#include "../../OS/options.h"	; machine specific
#include "../../OS/macros.h"
#include "../../OS/abi.h"
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
#define	_AH_BOUND		AND #hi_mask: BMI *+4: ORA #lo_mask

; increment Y checking injected boundary crossing (5/5/30) ** new compact version
#define	_PC_ADV		INY: BNE *+5: JSR wrap_pc

; compute pointer for direct absolute addressing mode (31/31.5/) eeeek
#define	_DIRECT		_PC_ADV: LDA (pc80), Y: STA tmptr: _PC_ADV: LDA (pc80), Y: _AH_BOUND: STA tmptr+1

; compute pointer from HL (17/17.5/18)
#define	_MEMORY		LDX l80: LDA h80: AH_BOUND: STX tmptr: STA tmptr+1

; check Z & S flags (6/8/10) will not set both bits at once! eeeek
#define _CC_SZ		BPL *+4: SMB7 f80: BNE *+4: SMB6 f80


; *** declare some constants ***
hi_mask	=	%10111111	; injects A15 hi into $8000-$BFFF, regardless of A14
lo_mask	=	%01000000	; injects A15 lo into $4000-$7FFF, regardless of A14
;lo_mask	=	%00100000	; injects into upper 8 K ($2000-$3FFF) for 16K RAM systems

; *** declare zeropage addresses ***
; ** 'uz' is first available zeropage address (currently $03 in minimOS) **
tmptr	=	uz		; temporary storage (up to 16 bit, little endian)
sp80		=	uz+2	; stack pointer (16 bit injected into host map)
pc80		=	uz+4	; program counter (16 bit injected into host map)
f80		=	uz+6	; flags SZ-H-VNC
a80		=	uz+7	; general purpose registers
; S is sign
; Z is zero
; H is half carry (for BCD, not testable)
; V is P/V, parity/overflow, sets on logical/rots with EVEN 1s
; N is add/subtract (for BCD, not testable) 1 is subtract
; C is carry, reset by AND, OR, XOR, borrow unlike 6502
c80		= uz+8
b80		= uz+9
e80		= uz+10
d80		= uz+11
l80		= uz+12
h80		= uz+13
rimask	= uz+14	; interrupt masks as set by SIM and read by RIM
; rimask = SID-I7-I6-I5-IE-M7-M6-M5
; SID is serial input (not implemented)
; I7~I5 are pending stati of INT7.5 ~ INT5.5, first one could be reset by SIM.D4
; IE is interrupt enable flag
; M7~M5 are the masks for INT7.5~INT5.5, set by SIM.d2~d0 iff d3=1
cdev		= uz+15		; I/O device *** minimOS specific ***

; *** minimOS executable header will go here ***

; *** startup code, minimOS specific stuff ***
	LDA #cdev-uz+1	; zeropage space needed
#ifdef	SAFE
	CMP z_used		; check available zeropage space
	BCC go_emu		; more than enough space
	BEQ go_emu		; just enough!
		_ERR(FULL)		; not enough memory otherwise (rare)
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
		_ERR(NO_RSRC)		; abort otherwise!
open_emu:
	STY cdev		; store device!!!
; should try to allocate memory here

; *** start the emulation! ***
reset80:
	LDY #0		; RST 0
	STY rimask	; restart with interrupts disabled
	STY pc80	; indirect indexed! NMOS savvy...
	LDA #lo_mask	; inject low memory into 65xx space
	STA pc80+1	; injected MSB

; *** main loop ***
execute:
		LDA (pc80), Y	; get opcode (needs CMOS) (5)
		ASL				; double it as will become pointer (2)
		TAX				; use as pointer, keeping carry (2)
		BCC lo_jump		; seems to be less opcodes with bit7 low... (2/3)
			JMP (opt_h, X)	; emulation routines for opcodes with bit7 hi (6)
lo_jump:
			JMP (opt_l, X)	; otherwise, emulation routines for opcodes with bit7 low

; *** NOP (4) arrives here, saving 3 bytes and 3 cycles ***
; also 'absurd' instructions like MOV B, B

_00:
_40:_49:_52:_5b:_64:_6d:_7f:

; continue execution via JMP next_op, will not arrive here otherwise
next_op:
		INY				; advance one byte (2)
		BNE execute		; fetch next instruction if no boundary is crossed (3/2)
; usual overhead is 22 clock cycles, not including final jump
; boundary crossing, simplified version
; ** should be revised for 16K RAM systems **
	INC pc80 + 1		; increment MSB otherwise, faster than using 'that macro' (5)
	BPL execute			; seems to stay in low area (3/2)
		RMB6 pc80 + 1		; in ROM area, A14 is goes low (5) *** Rockwell
	BRA execute			; fetch next (3)


; *** window title, optional and minimOS specific ***
title:
	.asc	"8085 simulator", 0
exit:
	.asc 13, "{HLT}", 13, 0


; *** interrupt support ***
; unsupported opcodes will be TRAPped

_cb:_ed:_dd:_fd:

	_PC_ADV			; skip illegal opcode (5)

nmi80:				; hardware interrupts, when available, to be checked AFTER incrementing PC
	LDX #$24			; offset for NMI entry point (2)

intr80:				; ** generic interrupt entry point, offset in X ** (70/)
	STX tmptr		; keep it eeeeeek^2 (3)
	TYA
	TAX			; retrieve current PC (2+2+3)
	LDA pc80+1
	JSR push	; save return address (50 best case)
; saved processor status
; seems to push PC only!!!
	LDX tmptr	; retrieve offset eeeeek^2 (3)

vector_pull:		; ** standard jump to entry point, offset in X **
	LDA #lo_mask	; get injected MSB (2)
	STA pc80+1	; set it (3)
	TXA
	TAY		; update PC (4)
	BRA execute		; continue with interrupt handler


; ** common routines **

; increment PC MSB in case of boundary crossing, rare (19/19.5/20)
wrap_pc:
	LDA pc80 + 1	; get MSB
	INC				; increment
	_AH_BOUND		; keep injected!
	STA pc80 + 1	; update pointer
	RTS				; *** to be used in rare cases, worth it ***

; push word from A/X into stack (44 best case)
push:
	PHA		; keep it!
	LDA sp80	; prefetch SP LSB
	BNE ph1n	; will not wrap!
		LDA sp80+1	; correct MSB
		DEC
		_AH_BOUND		; just in case
		STA sp80+1
ph1n:
	PLA		; retrieve LSB
	DEC sp80	; predecrement
	STA (sp80)	; store without altering status
	BNE ph2n	; will not wrap second time
		LDA sp80+1	; correct MSB otherwise
		DEC
		_AH_BOUND		; just in case
		STA sp80+1
ph2n:
	DEC sp80	; last predecrement
	TXA		; original LSB
	STA (sp80)	; push LSB last
	RTS

; pop word from stack into A/X (34 best case)
pop:
	LDA (sp80)	; pop first value as will be postincrementd
	TAX		; final LSB destination
	INC sp80	; postincrement
	BNE plnw	; did not wrap
		LDA sp80+1	; correct MSB otherwise
		INC
		_AH_BOUND		; just in case
		STA sp80+1
plnw:
	LDA (sp80)	; now pop other byte
	INC sp80	; postincrement
	BNE plend	; all OK
		PHA		; need to keep value
		LDA sp80+1	; correct MSB...
		INC
		_AH_BOUND		; ...and keep it injected
		STA sp80+1
		PLA		; retrieve value
plend:
	RTS

; ** common endings ** TBD **** TBD ****

; just check S & Z, then exit (3/5/14)
check_nz:
	BPL cnz_pl		; if minus...
		SMB7 f80		; set S *** Rockwell ***
cnz_pl:
	BNE next_op		; (check reach) if zero...
		SMB6 f80		; set Z *** Rockwell ***
	BRA next_op		; (check reach) standard end

; update indirect pointer and check NZ (11/13/22)
ind_nz:
	STA (tmptr)		; store at pointed address
	BRA check_nz	; check flags and exit

; check V & C bits, then N & V (9/13/31)
check_flags:
	BVC cvc_cc		; if overflow...
		SMB2 f80		; set V *** Rockwell ***
cvc_cc:
	BCS check_nz	; if carry...
		SMB0 f80		; set C *** Rockwell ***
	BRA check_nz	; continue checking


; *** *** valid opcode definitions *** ***

; ** move **
; to B

_41:
; MOV B,C (4)
; +12
	LDA c80	; source
	BRA movb	; common end

_42:
; MOV B,D (4)
; +12
	LDA d80	; source
	BRA movb	; common end

_43:
; MOV B,E (4)
; +12
	LDA e80	; source
	BRA movb	; common end

_44:
; MOV B,H (4)
; +12
	LDA h80	; source
	BRA movb	; common end

_45:
; MOV B,L (4)
; +12
	LDA l80	; source
	BRA movb	; common end

_46:
; MOV B,M (7) from memory
; +28
	_MEMORY		; prepare pointer
	LDA (tmptr)	; pointed source
movb:
	STA b80	; destination
	JMP next_op	; flags unaffected

_47:
; MOV B,A (4)
; +12
	LDA a80	; source
	BRA movb	; common end

; to C

_48:
; MOV C,B (4)
; +12
	LDA b80	; source
	BRA movc	; common end

_4a:
; MOV C,D (4)
; +12
	LDA d80	; source
	BRA movc	; common end

_4b:
; MOV C,E (4)
; +12
	LDA e80	; source
	BRA movc	; common end

_4c:
; MOV C,H (4)
; +12
	LDA h80	; source
	BRA movc	; common end

_4d:
; MOV C,L (4)
; 12
	LDA l80	; source
	BRA movc	; common end

_4e:
; MOV C,M (7) from memory
; +28
	_MEMORY		; prepare pointer
	LDA (tmptr)	; pointed source
movc:
	STA c80	; destination
	JMP next_op	; flags unaffected

_4f:
; MOV C,A (4)
; +12
	LDA a80	; source
	BRA movc	; common end

; to D

_50:
; MOV D,B (4)
; +12
	LDA b80	; source
	BRA movd	; common end

_51:
; MOV D,C (4)
; +12
	LDA c80	; source
	BRA movd	; common end

_53:
; MOV D,E (4)
; +12
	LDA e80	; source
	BRA movd	; common end

_54:
; MOV D,H (4)
; +12
	LDA h80	; source
	BRA movd	; common end

_55:
; MOV D,L (4)
; +12
	LDA l80	; source
	BRA movd	; common end

_56:
; MOV D,M (7) from memory
; +28
	_MEMORY		; prepare pointer
	LDA (tmptr)	; pointed source
movd:
	STA d80	; destination
	JMP next_op	; flags unaffected

_57:
; MOV D,A (4)
; +12
	LDA a80	; source
	BRA movd	; common end

; to E

_58:
; MOV E,B (4)
; +12
	LDA b80	; source
	BRA move	; common end

_59:
; MOV E,C (4)
; +12
	LDA c80	; source
	BRA move	; common end

_5a:
; MOV E,D (4)
; +12
	LDA d80	; source
	BRA move	; common end

_5c:
; MOV E,H (4)
; +12
	LDA h80	; source
	BRA move	; common end

_5d:
; MOV E,L (4)
; +12
	LDA l80	; source
	BRA move	; common end

_5e:
; MOV E,M (7) from memory
; +28
	_MEMORY		; prepare pointer
	LDA (tmptr)	; pointed source
move:
	STA e80	; destination
	JMP next_op	; flags unaffected

_5f:
; MOV E,A (4)
; +12
	LDA a80	; source
	BRA move	; common end

; to H

_60:
; MOV H,B (4)
; +12
	LDA b80	; source
	BRA movh	; common end

_61:
; MOV H,C (4)
; +12
	LDA c80	; source
	BRA movh	; common end

_62:
; MOV H,D (4)
; +12
	LDA d80	; source
	BRA movh	; common end

_63:
; MOV H,E (4)
; +12
	LDA e80	; source
	BRA movh	; common end

_65:
; MOV H,L (4)
; +12
	LDA l80	; source
	BRA movh	; common end

_66:
; MOV H,M (7) from memory
; +28
	_MEMORY		; prepare pointer
	LDA (tmptr)	; pointed source
movh:
	STA h80	; destination
	JMP next_op	; flags unaffected

_67:
; MOV H,A (4)
; +12
	LDA a80	; source
	BRA movh	; common end

; to L

_68:
; MOV L,B (4)
; +12
	LDA b80	; source
	BRA movl	; common end

_69:
; MOV L,C (4)
; +12
	LDA c80	; source
	BRA movl	; common end

_6a:
; MOV L,D (4)
; +12
	LDA d80	; source
	BRA movl	; common end

_6b:
; MOV L,E (4)
; +12
	LDA e80	; source
	BRA movl	; common end

_6c:
; MOV L,H (4)
; +12
	LDA h80	; source
	BRA movl	; common end

_6e:
; MOV L,M (7) from memory
; +28
	_MEMORY		; prepare pointer
	LDA (tmptr)	; pointed source
movl:
	STA l80	; destination
	JMP next_op	; flags unaffected

_6f:
; MOV L,A (4)
; +12
	LDX a80	; source
	BRA movl	; common end

; to memory

_70:
; MOV M,B (7)
; +33
	LDX b80	; source
	BRA movm	; common end

_71:
; MOV M,C (7)
; +33
	LDX c80	; source
	BRA movm	; common end

_72:
; MOV M,D (7)
; +33
	LDX d80	; source
	BRA movm	; common end

_73:
; MOV M,E (7)
; +33
	LDX e80	; source
	BRA movm	; common end

_74:
; MOV M,H (7)
; +33
	LDX h80	; source
	BRA movm	; common end

_75:
; MOV M,L (7)
; +33
	LDX l80	; source
	BRA movm	; common end

_77:
; MOV M,A (7) cannot use macro in order to stay generic
; +30
	LDX a80	; source
movm:
	LDA l80		; pointer LSB
	STA tmptr	; create temporary pointer
	LDA h80		; pointer MSB...
	_AH_BOUND	; ...to be bound
	STA tmptr+1	; pointer ready
	TXA		; get data
	STA (tmptr)	; pointed source
	JMP next_op	; flags unaffected

; to A

_78:
; MOV A,B (4)
; +12
	LDA b80	; source
	BRA mova	; common end

_79:
; MOV A,C (4)
; +12
	LDA c80	; source
	BRA mova	; common end

_7a:
; MOV A,D (4)
; +12
	LDA d80	; source
	BRA mova	; common end

_7b:
; MOV A,E (4)
; +12
	LDA e80	; source
	BRA mova	; common end

_7c:
; MOV A,H (4)
; +12
	LDA h80	; source
	BRA mova	; common end

_7d:
; MOV A,L (4)
; +12
	LDA l80	; source
	BRA mova	; common end

_7e:
; MOV A,M (7) from memory
; +28
	_MEMORY		; prepare pointer
	LDA (tmptr)	; pointed source
mova:
	STA a80	; destination
	JMP next_op	; flags unaffected

; immediate

_06:
; MVI B (7)
; +16
	_PC_ADV		; point to operand
	LDA (pc80), Y	; get immediate
	STA b80	; destination
	JMP next_op	; flags unaffected

_0d:
; MVI C (7)
; +16
	_PC_ADV		; point to operand
	LDA (pc80), Y	; get immediate
	STA c80	; destination
	JMP next_op	; flags unaffected

_16:
; MVI D (7)
; +16
	_PC_ADV		; point to operand
	LDA (pc80), Y	; get immediate
	STA d80	; destination
	JMP next_op	; flags unaffected

_1d:
; MVI E (7)
; +16
	_PC_ADV		; point to operand
	LDA (pc80), Y	; get immediate
	STA e80	; destination
	JMP next_op	; flags unaffected

_26:
; MVI H (7)
; +16
	_PC_ADV		; point to operand
	LDA (pc80), Y	; get immediate
	STA h80	; destination
	JMP next_op	; flags unaffected

_2d:
; MVI L (7)
; +16
	_PC_ADV		; point to operand
	LDA (pc80), Y	; get immediate
	STA l80	; destination
	JMP next_op	; flags unaffected

_36:
; MVI M (10) to memory
; +41
	_MEMORY		; prepare pointer
	_PC_ADV		; point to operand
	LDA (pc80), Y	; get immediate
	STA (tmptr)	; eeeeeeek
	JMP next_op	; flags unaffected

_3d:
; MVI A (7)
; +16
	_PC_ADV		; point to operand
	LDA (pc80), Y	; get immediate
	STA a80	; destination
	JMP next_op	; flags unaffected

; double immediate

_01:
; LXI B (10)
; +29
	_PC_ADV		; point to operand
	LDA (pc80), Y	; get first immediate
	STA c80	; LSB destination
	_PC_ADV		; advance to next byte
	LDA (pc80), Y	; get second immediate
	STA b80	; MSB destination
	JMP next_op	; flags unaffected

_11:
; LXI D (10)
; +29
	_PC_ADV		; point to operand
	LDA (pc80), Y	; get first immediate
	STA e80	; LSB destination
	_PC_ADV		; advance to next byte
	LDA (pc80), Y	; get second immediate
	STA d80	; MSB destination
	JMP next_op	; flags unaffected

_21:
; LXI H (10)
; +29
	_PC_ADV		; point to operand
	LDA (pc80), Y	; get first immediate
	STA l80	; LSB destination
	_PC_ADV		; advance to next byte
	LDA (pc80), Y	; get second immediate
	STA h80	; MSB destination
	JMP next_op	; flags unaffected

_31:
; LXI SP (10)
; +34
	_PC_ADV		; point to operand
	LDA (pc80), Y	; get first immediate
	STA sp80	; LSB destination
	_PC_ADV		; advance to next byte
	LDA (pc80), Y	; get second immediate
	_AH_BOUND		; SP is kept bound eeeeeeek
	STA sp80+1	; MSB destination
	JMP next_op	; flags unaffected

; ** load/store A indirect **

_0a:
; LDAX B (7)
; +28
	LDX c80		; pointer LSB
	LDA b80		; pointer MSB...
ldax:
	_AH_BOUND	; ...to be bound
	STX tmptr	; create temporary pointer
	STA tmptr+1
	LDA (tmptr)	; pointed source
	STA a80	; destination
	JMP next_op	; flags unaffected

_1a:
; LDAX D (7)
; +31
	LDX e80		; pointer LSB
	LDA d80		; pointer MSB...
	BRA ldax	; common end

_02:
; STAX B (7)
; +28
	LDX c80		; pointer LSB
	LDA b80		; pointer MSB...
stax:
	_AH_BOUND	; ...to be bound
	STX tmptr	; create temporary pointer
	STA tmptr+1
	LDA a80	; get source data
	STA (tmptr)	; indirect destination
	JMP next_op	; flags unaffected

_12:
; STAX D (7)
;+31
	LDX e80		; pointer LSB
	LDA d80		; pointer MSB...
	BRA stax	; common end

; ** load/store direct **

_3a:
; LDA (13)
;+42
	_DIRECT		; get pointer to operand
	LDA (tmptr)	; actual data
	STA a80	; destination
	JMP next_op	; flags unaffected
	
_2a:
; LHLD (16) load HL direct
;+58
	_DIRECT		; point to operand
	LDA (tmptr)	; actual LSB
	STA l80	; destination
	INC tmptr	; point to MSB
	BNE lhld	; did not wrap
		INC tmptr+1	; correct otherwise
lhld:
	LDA (tmptr)	; repeat for MSB
	STA h80
	JMP next_op	; flags unaffecfed
	
_32:
; STA (13)
;+42
	_DIRECT		; get destination address
	LDA a80	; source data
	STA (tmptr)	; store at destination
	JMP next_op	; flags unaffected

_22:
; SHLD (16) store HL direct
;+58
	_DIRECT		; point to operand
	LDA l80	; actual LSB
	STA (tmptr)	; destination
	INC tmptr	; point to MSB
	BNE shld	; did not wrap
		INC tmptr+1	; correct otherwise
shld:
	LDA h80	; repeat for MSB
	STA (tmptr)
	JMP next_op	; flags unaffecfed

; exchange DE & HL

_eb:
; XCHG (4)
;+27
	LDX d80	; preserve MSB
	LDA h80	; get other source
	STA d80	; substitute
	STX h80	; restore other MSB
	LDX e80	; same for LSB
	LDA l80
	STA e80
	STX l80
	JMP next_op	; flags unaffected


; ** jump **

_c3:
; JMP (10)
;+38
jmp:
	_DIRECT		; get target address in tmptr
do_jmp:
	LDY tmptr	; copy fetched address...
	LDX tmptr+1	; already bound MSB
	STX pc80+1	; ...into PC
	JMP execute	; jump to it!
	
_da:
; JC (7/10) if carry
;+44 if taken, +21 if not
		BBS0 f80, jmp	; best way
	BRA notjmp	; otherwise skip & continue

_d2:
; JNC (7/10) if not carry
;+44 if taken, +21 if not
		BBR0 f80, jmp	; best way
	BRA notjmp	; otherwise skip & continue

_f2:
; JP (7/10) if plus
;+44 if taken, +21 if not
		BBR7 f80, jmp	; best way
	BRA notjmp	; skip and continue

_fa:
; JM (7/10) if minus
;+44 if taken, +21 if not
		BBS7 f80, jmp	; best way
	BRA notjmp	; skip and continue

_ca:
; JZ (7/10) if zero
;+44 if taken, +21 if not
		BBS6 f80, jmp	; best way
	BRA notjmp	; skip and continue

_c2:
; JNZ (7/10) if not zero
;+44 if taken, +21 if not
		BBR6 f80, jmp	; best way in the most used one
notjmp:
	_PC_ADV		; skip unused address
	_PC_ADV
	JMP next_op	; continue otherwise

_ea:
; JPE (7/10) on parity even, better version
;+ 44 if taken, + 21 if not
		BBS2 f80, jmp	; jump on flag 2 set
	BRA notjmp	; otherwise skip and continue

_e2:
; JPO (7/10) on parity odd
;+ 44 if taken, + 21 if not
		BBR2 f80, jmp	; jump on flag 2 clear
	BRA notjmp	; otherwise skip and continue

_e9:
; PCHL (4) jump to address pointed by HL
;+12
	LDY l80		; get HL word
	LDA h80
	_AH_BOUND	; eeeeeek
	STA pc80+1	; set PC
	JMP execute


; ** call **

_cd:
; CALL (18)
;+100/
call:
	_DIRECT		; get target address in tmptr
	_PC_ADV		; set PC as the return address
	TYA
	TAX		; fetch PC LSB
	LDA pc80+1	; fetch PC MSB
	JSR push	; ***might be online*** push word in A/X
	BRA do_jmp	; continue like jump, shorter (7)
	
_dc:
; CC (9/18) if carry
;+106 if taken, +21 if not
		BBS0 f80, call	; best way
	BRA notjmp	; otherwise skip & continue

_d4:
; CNC (9/18) if not carry
;+106 if taken, +21 if not
		BBR0 f80, call	; best way
	BRA notjmp	; otherwise skip & continue

_f4:
; CP (9/18) if plus
;+106 if taken, +21 if not
		BBR7 f80, call	; better
	BRA notjmp	; skip and continue

_fc:
; CM (9/18) if minus
;+106 if taken, +21 if not
		BBS7 f80, call	; best way
	BRA notjmp	; otherwise skip & continue

_cc:
; CZ (9/18) if zero
;+106 if taken, +21 if not
		BBS6 f80, call	; best way
	BRA notjmp	; otherwise skip & continue

_c4:
; CNZ (9/18) if not zero
;+106 if taken, +21 if not
		BBR6 f80, call	; best way
	BRA notjmp	; otherwise skip & continue

_ec:
; CPE (9/18) on parity even, better version, saves 3 bytes & 2 clocks
;+ 106 if taken, + 21 if not
		BBS2 f80, call	; jump on flag 2 set
	BRA notjmp	; otherwise skip and continue

_e4:
; CPO (9/18) on parity odd
;+ 106 if taken, + 21 if not
		BBR2 f80, call	; jump on flag 2 clear
	BRA notjmp	; otherwise skip and continue


; ** return **

_c9:
; RET (10)
;+50
ret:
; pop return address from stack
	JSR pop		; ***might be online*** returns word in A/X
	_AH_BOUND		; just in case!
	STA pc80+1	; fetch injected MSB
	TXA		; fetch LSB...
	TAY		; ...into PC
	JMP execute	; back to caller
	
_d8:
; RC (6/12) if carry
;+56 if taken, +21 if not
		BBS0 f80, ret	; faster & shorter
	BRA notjmp	; otherwise skip & continue

_d0:
; RNC (6/12) if not carry
;+56 if taken, +21 if not
		BBR0 f80, ret	; faster & shorter
	BRA notjmp	; otherwise skip & continue

_f0:
; RP (6/12) if plus
;+56 if taken, +21 if not
		BBR7 f80, ret	; faster & shorter
	BRA notjmp	; otherwise skip & continue

_f8:
; RM (6/12) if minus
;+56 if taken, +21 if not
		BBS7 f80, ret	; faster & shorter
	BRA notjmp	; otherwise skip & continue

_c8:
; RZ (6/12) if zero
;+56 if taken, +21 if not
		BBS6 f80, ret	; faster & shorter
	BRA notjmp	; otherwise skip & continue

_c0:
; RNZ (6/12) if not zero
;+56 if taken, +21 if not
		BBR6 f80, ret	; faster & shorter
	BRA notjmp	; otherwise skip & continue

_e8:
; RPE (6/12) on parity even, better version
;+ 56 if taken, + 21 if not
		BBS2 f80, ret	; jump on flag 2 set
	BRA notjmp	; otherwise skip and continue

_e0:
; RPO (6/12) on parity odd
;+ 56 if taken, + 21 if not
		BBR2 f80, ret	; jump on flag 2 clear
	BRA notjmp	; otherwise skip and continue


; ** restart **
; faster, specific routines

_c7:
; RST 0 (11?)
;+80/
	_PC_ADV		; skip opcode
	LDX #0	; offset
	JMP intr80	; calling procedure

_cf:
; RST 1 (11?)
;+80/
	_PC_ADV		; skip opcode
	LDX #$08	; offset
	JMP intr80	; calling procedure

_d7:
; RST 2 (11?)
;+80/
	_PC_ADV		; skip opcode
	LDX #$10	; offset
	JMP intr80	; calling procedure

_df:
; RST 3 (11?)
;+80/
	_PC_ADV		; skip opcode
	LDX #$18	; offset
	JMP intr80	; calling procedure

_e7:
; RST 4 (11?)
;+80/
	_PC_ADV		; skip opcode
	LDX #$20	; offset
	JMP intr80	; calling procedure

_ef:
; RST 5 (11?)
;+80/
	_PC_ADV		; skip opcode
	LDX #$28	; offset
	JMP intr80	; calling procedure

_f7:
; RST 6 (11?)
;+80/
	_PC_ADV		; skip opcode
	LDX #$30	; offset
	JMP intr80	; calling procedure

_ff:
; RST 7 (11?)
;+80/
	_PC_ADV		; skip opcode
	LDX #$38	; offset
	JMP intr80	; calling procedure


; ** stack **

_c5:
; PUSH B (12) BE
;+62
	LDA b80		; load data word
	LDX c80
	BRA phcnt	; push and continue

_d5:
; PUSH D (12) DE
;+62
	LDA d80		; load data word
	LDX e80
	BRA phcnt	; push and continue

_e5:
; PUSH H (12) HL
;+62
	LDA h80		; load data word
	LDX l80
	BRA phcnt	; push and continue

_f5:
; PUSH PSW (12) AF
;+59
	LDA a80		; load data word
	LDX f80
phcnt:
	JSR push	; put in stack ** might optimise against interrupts
	JMP next_op	; flags unaffected

_c1:
; POP B (10) BC
;+52
	JSR pop		; retrieve from stack
	STA b80		; store MSB
	STX c80		; store LSB
	JMP next_op

_d1:
; POP D (10) DE
;+52
	JSR pop		; retrieve from stack
	STA d80		; store MSB
	STX e80		; store LSB
	JMP next_op

_e1:
; POP H (10) HL
;+52
	JSR pop		; retrieve from stack
	STA h80		; store MSB
	STX l80		; store LSB
	JMP next_op

_f1:
; POP PSW (10) AF
;+49
	JSR pop		; retrieve from stack
	STA a80		; store MSB
	STX f80		; store LSB
	JMP next_op

_e3:
; XTHL (16) exchange HL with top of stack
;+105, could be optimised
	JSR pop		; get top of stack
	STX tmptr	; store temporarily
	STA tmptr+1
	LDA h80		; original HL contents
	LDX l80
	JSR push	; put on stack
	LDX tmptr	; retrieve older top
	LDA tmptr+1
	STA h80		; new HL contents
	STX l80
	JMP next_op

_f9:
; SPHL (6) set SP as HL
;+20/
	LDA h80		; get HL word
	LDX l80
	_AH_BOUND		; eeeeeek
	STA sp80+1	; set SP
	STX sp80
	JMP next_op

_33:
; INX SP ()
;+11/
	INC sp80	; increment SP LSB
	BNE xsend	; no wrap
		LDA sp80+1	; get MSB
		INC
		_AH_BOUND		; just in case
		STA sp80+1	; update MSB 
xsend:
	JMP next_op	; flags unaffected

_3b:
; DCX SP ()
;+14
	LDX sp80	; preload LSB
	BNE dcxn	; will not wrap
		LDA sp80+1	original MSB
		DEC		; correct MSB otherwise
		_AH_BOUND	; just in case
		STA sp80+1
dcxn:
	DEC sp80	; decrement LSB
	JMP next_op


; ** control **

_fb:
; EI (4)
;+8
	SMB3 rimask	; enable interrupts
	JMP next_op

_f3:
; DI (4)
;+8
	RMB3 rimask	; disable interrupts
	JMP next_op

_76:
; HLT (5)
; abort emulation and return to shell
; ...sice interrupts are not yet supported!
	LDY cdev	; console device
	_KERNEL(FREE_W)	; release device or window
	_EXIT_OK		; *** go away ***


; ** specials **

_2f:
; CMA (4) complement A
;+19
	LDA a80		; get accumulator
	EOR #$FF	; complement
	STA a80		; update
	LDA f80		; status
	ORA #%00010010	; set H & N, rest unaffected
	STA f80		; update status
	JMP next_op

_37:
; STC (4) set carry
;+13
	LDA f80		; status
	AND #%11101100	; reset H & N, and C
	INC		; ...easier to set! save one byte, same clocks
	STA f80		; update status
	JMP next_op

_3f:
; CMC (4) complement carry
;+20
	LDA f80		; status
	AND #%11101101	; reset H & N
	ROR		; copy C in native carry
	ROL		; ...and back to original
	BCC cmc	; carry was not set
		ORA #%00010000	; otherwise copy old C into H
cmc:
	EOR #%00000001	; invert C
	STA f80		; update status
	JMP next_op

_27:
; DAA (4) decimal adjust
;+
	; ***** TO DO ***** TO DO ***** TO DO ***** TO DO *****


; ** input/output **
; * might be trapped easily *

_db:
; IN (10)
;+22
	_PC_ADV		; go for address
	LDA (pc80), Y	; get port
	TAX
	LDA IO_BASE, X	; actual port access
	STA a80		; gets into A
	JMP next_op	; flags unaffected

_d3:
; OUT (10)
;+22
	_PC_ADV		; go for address
	LDA (pc80), Y	; get port
	TAX
	LDA a80		; take data from A
	STA IO_BASE, X	; actual port access
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
;+16/
	LDA a80		; get argument
	BIT #%00010000	; check bit 4
	BEQ sim_r7	; will not clear I7.5
		RMB6 rimask	; otherwise reset it
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
; RLC (4) rotate A left
;+26/
	LDA f80		; old flags
	AND #%11101100	; reset H & N, C in case
	ROR		; lose C!
	BIT a80		; check bit 7!
	BPL rlc		; was off
		SEC		; otherwise set carry
rlc:
	ROL a80		; rotate register
	ROL		; return updated status
	STA f80		; store flags
	JMP next_op

_0f:
; RRC (4) rotate A right
;+24/
	LDA a80		; temporary check
	LSR		; copy bit 0 in native C
	LDA f80		; old flags
	AND #%11101100	; reset H, N & C!
	ROR a80		; rotate register
	BCC rrc		; no carry to set
		INC		; otherwise set bit 0!
rrc:
	STA f80		; store flags
	JMP next_op

_17:
; RAL (4) rotate A left thru carry
;+20
	LDA f80		; old flags
	AND #%11101101	; reset relevant
	ROR		; copy C on native
	ROL a80		; rotate register
	ROL		; return status with updated carry
	STA f80		; update status
	JMP next_op

_1f:
; RAR (4) rotate A right thru carry
;+20
	LDA f80		; old flags
	AND #%11101101	; reset relevant
	ROR		; copy C on native
	ROR a80		; rotate register
	ROL		; return status with updated carry
	STA f80		; update status
	JMP next_op
	

; ** increment & decrement **

_34:
; INR M (10)
;+69
	_MEMORY		; prepare pointer
	LDA (tmptr)	; older value
	TAX		; for further testing
	INC		; operation
	PHP		; keep status
	STA (tmptr)	; and update memory
	LDA f80		; get previous status
	AND #%00101001	; reset relevant bits
	PLP		; retrieve native status
iflags:
	BPL if_s	; positive...
		ORA #%1000000	; ...or set S
if_s:
	BNE if_z	; not zero...
		ORA #%01000000	; ...or set Z
if_z:
	CPX #$7F	; will overflow?
	BNE if_v	; not...
		ORA #%00000100	; ...or set V
if_v:
	STA f80		; store partial flags
	TXA		; get old value in accumulator
	AND #$0F	; filter low nibble
	CPX #$0F	; only value that will half carry after INR
	BNE if_h	; exit if done
		SMB4 f80	; ...or set H
if_h:
	JMP next_op

_04:
; INR B (4)
;+42/
	LDA f80		; common start
	AND #%00101001
	LDX b80		; appropriate register
	INC b80
	BRA iflags	; common ending

_0c:
; INR C (4)
;+42/
	LDA f80		; common start
	AND #%00101001
	LDX c80		; appropriate register
	INC c80
	BRA iflags	; common ending

_14:
; INR D (4)
;+42/
	LDA f80		; common start
	AND #%00101001
	LDX d80		; appropriate register
	INC d80
	BRA iflags	; common ending

_1c:
; INR E (4)
;+42/
	LDA f80		; common start
	AND #%00101001
	LDX e80		; appropriate register
	INC e80
	BRA iflags	; common ending

_24:
; INR H (4)
;+42/
	LDA f80		; common start
	AND #%00101001
	LDX h80		; appropriate register
	INC h80
	BRA iflags	; common ending

_2c:
; INR L (4)
;+42/
	LDA f80		; common start
	AND #%00101001
	LDX l80		; appropriate register
	INC l80
	BRA iflags	; common ending

_3c:
; INR A (4)
;+42/
	LDA f80		; common start
	AND #%00101001
	LDX a80		; appropriate register
	INC a80
	BRA iflags	; common ending

_35:
; DCR M (10)
;+69
	_MEMORY		; prepare pointer
	LDA (tmptr)	; older value
	TAX		; for further testing
	DEC		; operation
	PHP		; keep status
	STA (tmptr)	; and update memory
	LDA f80		; get previous status
	AND #%00101001	; reset relevant bits
	PLP		; retrieve native status
dflags:
	BPL if_s	; positive...
		ORA #%1000000	; ...or set S
df_s:
	BNE df_z	; not zero...
		ORA #%01000000	; ...or set Z
df_z:
	CPX #$80	; will overflow?
	BNE df_v	; not...
		ORA #%00000100	; ...or set V
df_v:
	STA f80		; store partial flags
	TXA		; get old value in accumulator
	AND #$0F	; filter low nibble, zero will overflow
	BNE df_h	; exit if done
		SMB4 f80	; ...or set H
df_h:
	JMP next_op

_05:
; DCR B (4)
;+42/
	LDA f80		; common start
	AND #%00101001
	LDX b80		; appropriate register
	DEC b80
	BRA dflags	; common ending

_0d:
; DCR C (4)
;+42/
	LDA f80		; common start
	AND #%00101001
	LDX c80		; appropriate register
	DEC c80
	BRA dflags	; common ending

_15:
; DCR D (4)
;+42/
	LDA f80		; common start
	AND #%00101001
	LDX d80		; appropriate register
	DEC d80
	BRA dflags	; common ending

_1d:
; DCR E (4)
;+42/
	LDA f80		; common start
	AND #%00101001
	LDX e80		; appropriate register
	DEC e80
	BRA dflags	; common ending

_25:
; DCR H (4)
;+42/
	LDA f80		; common start
	AND #%00101001
	LDX h80		; appropriate register
	DEC h80
	BRA dflags	; common ending

_2d:
; DCR L (4)
;+42/
	LDA f80		; common start
	AND #%00101001
	LDX l80		; appropriate register
	DEC l80
	BRA dflags	; common ending

_3d:
; DCR A (4)
;+42/
	LDA f80		; common start
	AND #%00101001
	LDX a80		; appropriate register
	DEC a80
	BRA dflags	; common ending

; 16-bit inc/dec 

_03:
; INX B (6)
;+11
	INC c80	; increment LSB
	BNE ixb	; no wrap
		INC b80	; correct MSB
ixb:
	JMP next_op	; flags unaffected

_0b:
; DCX B (6)
;+14
	LDX c80	; preload LSB
	BNE dxb	; will not wrap
		DEC b80	; correct MSB otherwise
dxb:
	DEC c80	; decrement LSB
	JMP next_op

_13:
; INX D (6)
;+11
	INC e80	; increment LSB
	BNE ixd	; no wrap
		INC d80	; correct MSB
ixd:
	JMP next_op	; flags unaffected

_1b:
; DCX D (6)
;+14
	LDX e80	; preload LSB
	BNE dxd	; will not wrap
		DEC d80	; correct MSB otherwise
dxd:
	DEC e80	; decrement LSB
	JMP next_op

_23:
; INX H (6)
;+11
	INC l80	; increment LSB
	BNE ixh	; no wrap
		INC h80	; correct MSB
ixh:
	JMP next_op	; flags unaffected

_2b:
; DCX H (6)
;+14
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
;+37/
	LDA b80		; variable term
	BRA anam	; generic routine

_a1:
; ANA C (4)
;+37/
	LDA c80		; variable term
	BRA anam	; generic routine

_a2:
; ANA D (4)
;+37/
	LDA d80		; variable term
	BRA anam	; generic routine

_a3:
; ANA E (4)
;+37/
	LDA e80		; variable term
	BRA anam	; generic routine

_a4:
; ANA H (4)
;+37/
	LDA h80		; variable term
	BRA anam	; generic routine

_a5:
; ANA L (4)
;+37/
	LDA b80		; variable term
	BRA anam	; generic routine

_a6:
; ANA M (7)
;+53/
; * should unused bits be respected... *
;	LDA f80		; get old flags
;	AND #%00111000	; reset S, Z, N, V & C
;	ORA #%00010000	; set H... and save it!!!*
	_MEMORY		; prepare pointer
	LDA (tmptr)	; variable term
anam:
	LDX #%00010000	; base flags, modify accordingly, does NOT respect unused bits*
	STX f80		; store base flags*
	TAX		; keep original value for overflow checking
	AND a80		; logical AND
	STA a80		; store result
l_flags:
	_CC_SZ		; check sign & zero bits
	TXA		; retrieve older value
	EOR a80		; just looking at bit 7 (overflow?)
	BPL ana_v	; did not change, no overflow
		SMB2 f80	; or set V
ana_v:
	JMP next_op

_a7:_b7:
; ANA A (4) somewhat special as will only update flags!
; ORA A (4) does pretty much the same!
;+28/
	LDA #%00010000	; base flags, modify accordingly, does not respect unused bits
	STA f80		; store base flags
	LDX a80		; original intact data
	BRA l_flags	; just check flags!
	

; exclusive or

_a8:
; XRA B (4)
;+
	LDA b80		; variable term
	BRA xram	; generic routine

_a9:
; XRA C (4)
;+
	LDA c80		; variable term
	BRA xram	; generic routine

_aa:
; XRA D (4)
;+
	LDA d80		; variable term
	BRA xram	; generic routine

_ab:
; XRA E (4)
;+
	LDA e80		; variable term
	BRA xram	; generic routine

_ac:
; XRA H (4)
;+
	LDA h80		; variable term
	BRA xram	; generic routine

_ad:
; XRA L (4)
;+
	LDA l80		; variable term
	BRA xram	; generic routine

_ae:
; XRA M (7) with parity instead of overflow!
;+
	_MEMORY		; prepare pointer
	LDA (tmptr)	; variable term
xram:
	LDX #%00010000	; base flags, modify accordingly, does NOT respect unused bits*
	STX f80		; store base flags*
	EOR a80		; logical Exclusive OR
	STA a80		; store result
	_CC_SZ		; check sign & zero bits
	LDX #0		; ones counter
xr_pc:
		LSR		; shift result
		BCC xr_z	; was zero
			INX		; otherwise count another one
xr_z:
		BNE xr_pc	; continue counting ones
	TXA		; retrieve count value
	LSR	; just looking at bit 0 (even/odd)
	BCS xra_v	; odd number, no parity
		SMB2 f80	; or set P
xra_v:
	JMP next_op

_af:
; XRA A (4) will always get zero,
;+11
	LDA #%01000100	; fixed flags!
	STA f80		; store flags
	STZ a80		; result is always zero!
	JMP next_op

; or

_b0:
; ORA B (4)
;+40
	LDA b80		; variable term
	BRA oram	; generic routine

_b1:
; ORA C (4)
;+40
	LDA c80		; variable term
	BRA oram	; generic routine

_b2:
; ORA D (4)
;+40
	LDA d80		; variable term
	BRA oram	; generic routine

_b3:
; ORA E (4)
;+40
	LDA e80		; variable term
	BRA oram	; generic routine

_b4:
; ORA H (4)
;+40
	LDA h80		; variable term
	BRA oram	; generic routine

_b5:
; ORA L (4)
;+40
	LDA l80		; variable term
	BRA oram	; generic routine

_b6:
; ORA M (7)
;+56/
	_MEMORY		; prepare pointer
	LDA (tmptr)	; variable term
oram:
	LDX #%00010000	; base flags, modify accordingly, does NOT respect unused bits*
	STX f80		; store base flags*
	TAX		; keep original value for overflow checking
	ORA a80		; logical OR
	STA a80		; store result
	BRA l_flags	; common status check... or is it parity like XOR???********


; compare with A

_b8:
; CMP B (4)
;+
	LDA b80		; variable term
	BRA cmpm	; generic routine

_b9:
; CMP C (4)
;+
	LDA c80		; variable term
	BRA cmpm	; generic routine

_ba:
; CMP D (4)
;+
	LDA d80		; variable term
	BRA cmpm	; generic routine

_bb:
; CMP E (4)
;+
	LDA e80		; variable term
	BRA cmpm	; generic routine

_bc:
; CMP H (4)
;+
	LDA h80		; variable term
	BRA cmpm	; generic routine

_bd:
; CMP L (4)
;+
	LDA l80		; variable term
	BRA cmpm	; generic routine

_be:
; CMP M (7)
;+
	_MEMORY		; prepare pointer
	LDA (tmptr)	; variable term
cmpm:
	LDX #%00010000	; base flags, modify accordingly, does NOT respect unused bits*
	STX f80		; store base flags*
	TAX		; keep original value for overflow checking
	SEC		; prepare subtraction
	SBC a80		; subtract without storing
	_CC_SZ		; check sign & zero bits
	BVC cmp_v	; no overflow
		SMB2 f80	; or set V
cmp_v:
	BCS cmp_c	; if native carry is set, there is NO borrow
		SMB0 f80	; otherwise set emulated C
cmp_c:
	JMP next_op

_bf:
; CMP A (4) special
;+8
	LDA #%01000000	; fixed flags!
	STA f80		; store flags
	JMP next_op


; and immediate

_e6:
; ANI (7)
;+44/
	_PC_ADV		; go for the operand
	LDA (pc80), Y	; immediate addressing
	BRA anam	; generic routine

; exclusive or immediate

_ee:
; XRI (7)
;+
	_PC_ADV		; go for the operand
	LDA (pc80), Y	; immediate addressing
	BRA xram	; generic routine

; or immediate

_f6:
; ORI (7)
;+47/
	_PC_ADV		; go for the operand
	LDA (pc80), Y	; immediate addressing
	BRA oram	; generic routine


; compare A immediate

_fe:
; CPI (7)
;+
	_PC_ADV		; go for the operand
	LDA (pc80), Y	; immediate addressing
	BRA cmpm	; generic routine
	

; ** addition **
_:
;()
;+
_:
;()
;+

_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+
_:
;()
;+








;******* older 6800 code ********
/*
_89:
; ADC A imm (2)
;  +75/81.5/
	_PC_ADV			; not worth using the macro (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc80 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA adcae		; continue as indirect addressing (61/67.5)

_b9:
; ADC A ext (4)
; +89/96/
	_EXTENDED		; point to operand (31/31.5)
adcae:				; +58/64.5 from here
	CLC				; prepare (2)
	BBR0 ccr80, adcae_cc	; no previous carry (6/6.5...) *** Rockwell ***
		SEC						; otherwise preset C
adcae_cc:			; +50/56/ from here
	LDA a80			; get accumulator A (3)
	BIT #%00010000	; check bit 4 (2)
	BEQ adcae_nh	; do not set H if clear (8/9...)
		SMB5 ccr80		; set H temporarily as b4 *** Rockwell ***
		BRA adcae_sh	; do not clear it
adcae_nh:
	RMB5 ccr80		; otherwise H is clear *** Rockwell ***
adcae_sh:
	ADC (tmptr)		; add operand (5)
adda:				; +32/37/ from here
	TAX				; store for later! (2)
	BIT #%00010000	; check bit 4 again (2)
	BNE adcae_nh2	; do not invert H (8/10...)
		LDA ccr80		; get original flags
		AND #%11110000	; clear relevant bits, respecting H
		EOR #%00100000	; toggle H
		BRA adcae_sh2	; do not reload CCR
adcae_nh2:
	LDA ccr80		; get original flags
	AND #%11110000	; clear relevant bits, respecting H
adcae_sh2:
	BCC adcae_nc	; only if carry... (3/3.5...)
		INC				; ...set C flag
adcae_nc:
	BVC adcae_nv	; only if overflow... (3/3.5...)
		ORA #%00000010	; ...set V flag
adcae_nv:
	STA ccr80		; update flags (3)
	TXA				; retrieve value! (2)
	JMP a_nz		; update A and check NZ 
	
; logical AND
_84:
; AND A imm (2)
; +42/44/
	_PC_ADV			; go for operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc80 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA andae		; continue as indirect addressing (28/30/39)


_b4:
; AND A ext (4)
; +56/58.5/
	_EXTENDED		; points to operand (31/31.5)
andae:				; +25/27/36 from here
	LDA ccr80		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr80		; update (3)
	LDA a80			; get A accumulator (3)
	AND (tmptr)		; AND with operand (5)
	JMP a_nz		; update A and check NZ (9/11/20)

; compare
_81:
; CMP A imm (2)
; +47/51/
	_PC_ADV			; get operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc80 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA cmpae		; continue as indirect addressing (33/37/55)

_b1:
; CMP A ext (4)
; +61/65.5/
	_EXTENDED		; get operand (31/31.5)
cmpae:				; +30/34/52 from here
	LDA ccr80		; get flags (3)
	AND #%11110000	; clear relevant bits (2)
	STA ccr80		; update (3)
	LDA a80			; get accumulator A (3)
	SEC				; prepare (2)
	SBC (tmptr)		; subtract without carry (5)
	JMP check_flags	; check NZVC and exit (12/16/34)


; decimal adjust
_19:
; DAA (2)
; +20/~400/1841?
; ** first approach, awfully slow!!! **
	LDA ccr80		; get original status
	AND #%11110001	; reset all relevant bits for CCR, do NOT reset C!
	STA ccr80		; store new flags
	LDX a80			; get binary number to be converted
		BEQ daa_ok		; nothing to convert
	CPX #100		; will it overflow?
	BCC daa_conv	; range OK
		SMB0 ccr80		; otherwise set C *** Rockwell ***
daa_conv:
	CLC				; prepare
	LDA #0			; will compute final value
	SED				; set decimal mode!!! (...28 worst)
daa_loop:
		ADC #1			; decimal increment
		DEX				; decrement counter
		BNE daa_loop	; until done (7x255+6 = 1791)
	CLD				; back to binary mode!!!
	BVC daa_nv		; only if overflow...
		SMB1 ccr80		; ...set V flag *** Rockwell ***
daa_nv:
	STA a80			; update accumulator with BCD value
daa_ok:
	JMP check_flags	; check and exit

_b8:
; EOR A ext (4)
; +56/58.5/
	_EXTENDED		; points to operand (31/31.5)
eorae:				; +25/27/36 from here
	LDA ccr80		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr80		; update (3)
	LDA a80			; get A accumulator (3)
	EOR (tmptr)		; EOR with operand (5)
	JMP a_nz		; update A, check NZ and exit (9/11/20)

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

; inclusive OR
_8a:
; ORA A imm (2)
; +
	_PC_ADV			; go for operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc80 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA oraae		; continue as indirect addressing (3+)

_ba:
; ORA A ext (4)
; +
	_EXTENDED		; points to operand (31/31.5)
oraae:
	LDA ccr80		; get flags (3)
	AND #%11110001	; clear relevant bits (2)
	STA ccr80		; update (3)
	LDA a80			; get A accumulator (3)
	ORA (tmptr)		; ORA with operand (5)
	JMP a_nz		; update A, check NZ and exit (9/11/20)

; store
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
	LDA a80			; get char in A
	STA zpar		; parameter for COUT
	_KERNEL(COUT)	; standard output
	LDA a80			; just for flags
	JMP check_nz	; usual ending


; subtract without carry
_80:
; SUB A imm (2)
; +
	_PC_ADV			; get operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc80 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA subae		; continue as indirect addressing 

_b0:
; SUB A ext (4)
; +67/73.5/
	_EXTENDED		; get operand (31/31.5)
subae:
	SEC				; prepare (2)
	JMP sbcae_do	; and continue (3+)

; subtract with carry
_82:
; SBC A imm (2)
; +
	_PC_ADV			; get operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc80 + 1	; get address MSB (3)
	STA tmptr + 1	; pointer is ready (3)
	BRA sbcae		; continue as indirect addressing (3+)

_b2:
; SBC A ext (4)
; +70/77/
	_EXTENDED		; get operand (31/31.5)
sbcae:
	SEC				; prepare (2)
	BBR0 ccr80, sbcae_do	; skip if C clear ** Rockwell **
		CLC				; otherwise, set carry, opposite of 6502 (2)
sbcae_do:
	LDA ccr80		; get flags (3)
	AND #%11110000	; clear relevant bits (2)
	STA ccr80		; update (3)
	LDA a80			; get accumulator A
	SBC (tmptr)		; subtract with carry (5)
	STA a80			; update accumulator (3)
	JMP check_flags	; and exit (12/16/34)
	

; ** index register and stack pointer ops **

; compare index
_8c:
; CPX imm (3)
; +
	_PC_ADV			; get first operand (5)
	STY tmptr		; store LSB of pointer (3)
	LDA pc80 + 1	; get address MSB (3)
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

_bc:
; CPX ext (5)
; +82/88.5/
	_EXTENDED		; get operand (31/31.5)
cpxe:
	LDA ccr80		; get original flags (3)
	AND #%11110001	; reset relevant bits (2)
	STA ccr80		; update flags (3)
	SEC				; prepare (2)
	LDA x80 + 1		; MSB at X (3)
	SBC (tmptr)		; subtract memory (5)
	TAX				; keep for later (2)
	BPL cpxe_pl		; not negative (3/5...)
		SMB3 ccr80		; otherwise set N flag *** Rockwell ***
cpxe_pl:
	INC tmptr		; point to next byte (5)
	BNE cpxe_nw		; usually will not wrap (3...)
		LDA tmptr + 1	; get original MSB
		INC				; advance
		_AH_BOUND		; inject
		STA tmptr + 1	; restore
cpxe_nw:
	LDA x80			; LSB at X (3)
	SBC (tmptr)		; value LSB (5)
	STX tmptr		; retrieve old MSB (3)
	ORA tmptr		; blend with stored MSB (3)
	BNE cpxe_nz		; if zero... (3...)
		SMB2 ccr80		; set Z *** Rockwell ***
cpxe_nz:
	BVC cpxe_nv		; if overflow... (3/5...)
		SMB1 ccr80		; set V *** Rockwell ***
cpxe_nv:
	JMP next_op		; standard end


*/


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
