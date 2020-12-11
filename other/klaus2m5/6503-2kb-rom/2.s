;
; 6 5 0 2		F U N C T I O N A L		T E S T		P A R T		2
;
; Copyright (C) 2012-2020	Klaus Dormann
; *** this version ROM-adapted by Carlos J. Santisteban ***
; *** for xa65 assembler, previously processed by cpp ***
; *** partial test to fit into 2 kiB ROM for 6503 etc ***
; *** last modified 20201204-1617 ***
;
; *** all comments added by me go between sets of three asterisks ***
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.	If not, see <www.gnu.org/licenses/>.


; This program is designed to test all opcodes of a 6502 emulator using all
; addressing modes with focus on proper setting of the processor status
; register bits.
;
; version 05-jan-2020
; contact info at http://2m5.de or email K@2m5.de
;
; assembled with AS65 written by Frank A. Kingswood
; The assembler as65_142.zip can be obtained from my GitHub repository 
; command line switches: -l -m -s2 -w -h0
;	|	|	|	|	no page headers in listing
;	|	|	|	wide listing (133 char/col)
;	|	|	write intel hex file instead of binary
;	|	expand macros in listing
;	generate pass2 listing
;
; No IO - should be run from a monitor with access to registers.
; To run load intel hex image with a load command, than alter PC to 400 hex
; (code_segment) and enter a go command.
; Loop on program counter determines error or successful completion of test.
; Check listing for relevant traps (jump/branch *).
; Please note that in early tests some instructions will have to be used before
; they are actually tested!
;
; RESET, NMI or IRQ should not occur and will be trapped if vectors are enabled.
; Tests documented behavior of the original NMOS 6502 only! No unofficial
; opcodes. Additional opcodes of newer versions of the CPU (65C02, 65816) will
; not be tested. Decimal ops will only be tested with valid BCD operands and
; N V Z flags will be ignored.
;
; Debugging hints:
;	Most of the code is written sequentially. if you hit a trap, check the
;	immediately preceeding code for the instruction to be tested. Results are
;	tested first, flags are checked second by pushing them onto the stack and
;	pulling them to the accumulator after the result was checked. The "real"
;	flags are no longer valid for the tested instruction at this time!
;	If the tested instruction was indexed, the relevant index (X or Y) must
;	also be checked. Opposed to the flags, X and Y registers are still valid.
;
; versions:
;	28-jul-2012	1st version distributed for testing
;	29-jul-2012	fixed references to location 0, now #0
;	added license - GPLv3
;	30-jul-2012	added configuration options
;	01-aug-2012	added trap macro to allow user to change error handling
;	01-dec-2012	fixed trap in branch field must be a branch
;	02-mar-2013	fixed PLA flags not tested
;	19-jul-2013	allowed ROM vectors to be loaded when load_data_direct = 0
;	added test sequence check to detect if tests jump their fence
;	23-jul-2013	added RAM integrity check option
;	16-aug-2013	added error report to standard output option
;	13-dec-2014	added binary/decimal opcode table switch test
;	14-dec-2014	improved relative address test
;	23-aug-2015	added option to disable self modifying tests
;	24-aug-2015	all self modifying immediate opcodes now execute in data RAM
;	added small branch offset pretest
;	21-oct-2015	added option to disable decimal mode ADC & SBC tests
;	04-dec-2017	fixed BRK only tested with interrupts enabled
;	added option to skip the remainder of a failing test
;	in report.i65
;	05-jan-2020	fixed shifts not testing zero result and flag when last 1-bit
;	is shifted out

; *************************
; C O N F I G U R A T I O N
; *************************
; *** DEFINEs seem more suitable for xa ***

;ROM_vectors writable (0=no, 1=yes)
;if ROM vectors can not be used interrupts will not be trapped
;as a consequence BRK can not be tested but will be emulated to test RTI
; *** since this is an ad-hoc tester ROM, hard vectors will always point to these supplied routines ***

;load_data_direct (0=move from code segment, 1=load directly)
;loading directly is preferred but may not be supported by your platform
;0 produces only consecutive object code, 1 is not suitable for a binary image
; *** it will be disabled all the time	***

;I_flag behavior (0=force enabled, 1=force disabled, 2=prohibit change, 3=allow
;change) 2 requires extra code and is not recommended. SEI & CLI can only be
;tested if you allow changing the interrupt status (I_flag=3)
; *** value 2 is NOT accepted ***
#define	I_flag			3

;configure memory - try to stay away from memory used by the system
;zero_page memory start address, $52 (82) consecutive Bytes required
;	add 2 if I_flag=2
; *** really not using anything else... might just start at 2 for the sake of 6510 compatibility ***
zero_page				= $A

;data_segment memory start address, $7B (123) consecutive Bytes required
data_segment			= $200
;low byte of data_segment MUST be $00 !!

;code_segment memory start address, 13.1kB of consecutive space required
;	add 2.5 kB if I_flag=2
code_segment			= $F800		; *** no longer $400, special 2 kiB version ***

;self modifying code may be disabled to allow running in ROM
;0=part of the code is self modifying and must reside in RAM
;1=tests disabled: branch range
;*** SMC was used on test 1, thus disabled on the remaining tests ***

;report errors through standard self trap loops
;report = 0
; *** won't be used by me because 6502 tester has no other I/O than a LED on A10! ***

;RAM integrity test option. Checks for undesired RAM writes.
;set lowest non RAM or RAM mirror address page (-1=disable, 0=64k, $40=16k)
;leave disabled if a monitor, OS or background interrupt is allowed to alter RAM
#define	ram_top			8
; *** 2 kiB for 6503-savvy (6116 SRAM) ***

;disable test decimal mode ADC & SBC, 0=enable, 1=disable,
;2=disable including decimal flag in processor status
; *** 2 is not used by me ***
; *** decimal test is only for last part, no need for setting ***

; putting larger portions of code (more than 3 bytes) inside the trap macro
; may lead to branch range problems for some tests.

#define	hash			#
; *** this is needed for xa's CPP-like preprocessor! ***

; *** always report errors thru trap addresses ***
#define	trap			JMP *
;failed anyway

#define	trap_eq			BEQ *
;failed equal (zero)

#define	trap_ne			BNE *
;failed not equal (non zero)

#define	trap_cs			BCS *
;failed carry set

#define	trap_cc			BCC *
;failed carry clear

#define	trap_mi			BMI *
;failed minus (bit 7 set)

#define	trap_pl			BPL *
;failed plus (bit 7 clear)

#define	trap_vs			BVS *
;failed overflow set

#define	trap_vc			BVC *
;failed overflow clear

; please observe that during the test the stack gets invalidated
; therefore a RTS inside the success macro is not possible
#define	success			JMP ram_blink
;test passed, no errors
; *** will jump between two delay routines, alternating between ROM and RAM in order to blink a LED at, say, A10 ***

; *** reports are disabled all the time as the CPU-checker lacks I/O ***

carry	= %00000001			;flag bits in status
zero	= %00000010
intdis	= %00000100
decmode = %00001000
break	= %00010000
reserv	= %00100000
overfl	= %01000000
minus	= %10000000

fc		= carry
fz		= zero
fzc		= carry+zero
fv		= overfl
fvz		= overfl+zero
fn		= minus
fnc		= minus+carry
fnz		= minus+zero
fnzc	= minus+zero+carry
fnv		= minus+overfl

; *** as xa lacks ~ operator, inverted bytes follow ***
Nfz		= fz ^ $FF
Nfn		= fn ^ $FF
Nfv		= fv ^ $FF
Nfnz	= fnz ^ $FF
Nfnv	= fnv ^ $FF
Nfzc	= fzc ^ $FF

fao		= break+reserv		;bits always on after PHP, BRK
fai		= fao+intdis		;+ forced interrupt disable
faod	= fao+decmode		;+ ignore decimal
faid	= fai+decmode		;+ ignore decimal
m8		= $ff				;8 bit mask
m8i		= %11111011			;8 bit mask - interrupt disable *** changed ***

; *************************
; *** macro definitions ***
; *************************
;macros to allow masking of status bits.
;masking test of decimal bit
;masking of interrupt enable/disable on load and compare
;masking of always on bits after PHP or BRK (unused & break) on compare
#if I_flag == 0
;		*** I_FLAG IS ZERO ***
#define	load_flag(a)	LDA hash a &m8i
;force enable interrupts (mask I)

#define	cmp_flag(a)		CMP hash (a|fao)&m8i
;I_flag is always enabled + always on bits

#define	eor_flag(a)		CMP hash (a&m8i|fao)
;mask I, invert expected flags + always on bits
#endif

#if I_flag== 1
;		*** I_FLAG IS ONE ***
#define	load_flag(a)	LDA hash a|intdis
;force disable interrupts

#define	cmp_flag(a)		CMP hash (a|fai)&m8
;I_flag is always disabled + always on bits

#define	eor_flag(a)		CMP hash (a|fai)
;invert expected flags + always on bits + I
#endif

; *** I_FLAG is never 2 ***

#if I_flag== 3
;		*** I_FLAG IS THREE ***
#define	load_flag(a)	LDA hash a
;allow test to change I-flag (no mask)

#define	cmp_flag(a)		CMP hash (a|fao)&m8
;expected flags + always on bits

#define	eor_flag(a)		CMP hash (a|fao)
;invert expected flags + always on bits
#endif

; *** this was for disable_decimal=2, not implemented ***

;macros to set (register|memory|zeropage) & status
#define	set_stat(a)		load_flag(a):PHA:PLP

#define	set_a(a,b)		load_flag(b):PHA:LDA hash a:PLP
;precharging accu & status

#define	set_x(a,b)		load_flag(b):PHA:LDX hash a:PLP
;precharging index & status

#define	set_y(a,b)		load_flag(b):PHA:LDY hash a:PLP
;precharging index & status

#define	set_ax(a,b)		load_flag(b):PHA:LDA a,X:PLP
;precharging indexed accu & immediate status

#define	set_ay(a,b)		load_flag(b):PHA:LDA a,Y:PLP
;precharging indexed accu & immediate status

#define	set_z(a,b)		load_flag(b):PHA:LDA a,X:STA zpt:PLP
;precharging indexed accu & immediate status

#define	set_zx(a,b)		load_flag(b):PHA:LDA a,X:STA zpt,X:PLP
;precharging zp,x & immediate status

#define	set_abs(a,b)	load_flag(b):PHA:LDA a,X:STA abst:PLP
;precharging indexed memory & immediate status

#define	set_absx(a,b)	load_flag(b):PHA:LDA a,X:STA abst,X:PLP
;precharging abs,x & immediate status

;macros to test (register|memory|zeropage) & status & (mask)
#define	tst_stat(a)		PHP:PLA:PHA:cmp_flag(a):trap_ne:PLP
;testing flags in the processor status register
	
#define	tst_a(a,b)		PHP:CMP hash a:trap_ne:PLA:PHA:cmp_flag(b):trap_ne:PLP
;testing result in accu & flags

#define	tst_x(a,b)		PHP:CPX hash a:trap_ne:PLA:PHA:cmp_flag(b):trap_ne:PLP
;testing result in x index & flags

#define	tst_y(a,b)		PHP:CPY hash a:trap_ne:PLA:PHA:cmp_flag(b):trap_ne:PLP
;testing result in Y index & flags

#define	tst_ax(a,b,c)	PHP:CMP a,X:trap_ne:PLA:eor_flag(c):CMP b,X:trap_ne
;indexed testing result in accu & flags

#define	tst_ay(a,b,c)	PHP:CMP a,Y:trap_ne:PLA:eor_flag(c):CMP b,Y:trap_ne
;indexed testing result in accu & flags
	
#define	tst_z(a,b,c)	PHP:LDA zpt:CMP a,X:trap_ne:PLA:eor_flag(c):CMP b,X:trap_ne
;indexed testing result in zp & flags

#define	tst_zx(a,b,c)	PHP:LDA zpt,X:CMP a,X:trap_ne:PLA:eor_flag(c):CMP b,X:trap_ne
;testing result in zp,x & flags

#define	tst_abs(a,b,c)	PHP:LDA abst:CMP a,X:trap_ne:PLA:eor_flag(c):CMP b,X:trap_ne
;indexed testing result in memory & flags

#define	tst_absx(a,b,c)	PHP:LDA abst,X:CMP a,X:trap_ne:PLA:eor_flag(c):CMP b,X:trap_ne
;testing result in abs,x & flags
	
; RAM integrity test
;	verifies that none of the previous tests has altered RAM outside of the
;	designated write areas.
;	uses zpt word as indirect pointer, zpt+2 word as checksum
#if ram_top > -1
; non-SMC version *** EEEEEEEK
; *** CPP admits no temporary labels, thus resolved as relative references ***
#define	check_ram			\
	cld:					\
	lda #0:					\
	sta zpt:				\
	sta zpt+3:				\
	clc:					\
	ldx #zp_bss-zero_page:	\
	adc zero_page,x:		\
	bcc *+5:				\
	inc zpt+3:				\
	clc:					\
	inx:					\
	bne *-8:				\
	ldx #>abs1:				\
	stx zpt+1:				\
	ldy #<abs1:				\
	adc (zpt),y:			\
	bcc *+5:				\
	inc zpt+3:				\
	clc:					\
	iny:					\
	bne *-8:				\
	inx:					\
	stx zpt+1:				\
	cpx #ram_top:			\
	bne *-15:				\
	sta zpt+2:				\
	cmp ram_chksm:			\
	trap_ne:				\
	lda zpt+3:				\
	cmp ram_chksm+1:		\
	trap_ne
#else
;RAM check disabled - RAM size not set
#define	check_ram		;disabled_RAM_check
#endif

;make sure, tests don't jump the fence
; *** note redefinable label test_num ***
#define	next_test 			\
	lda test_case:			\
	cmp #test_num:			\
	trap_ne:				\
	-test_num=test_num+1:	\
	lda #test_num:			\
	sta test_case

; *** place checkRam above to find altered RAM after each test, otherwise supress it (and previous \) ***

; ********************
; *** memory usage ***
; ********************
; *** load_data_direct is always off ***
; *** checked for unused references ***
		.zero

		* =		zero_page
zpt:							;6 bytes store/modify test area
		.dsb	6
zp_bss:
; *** byte definitions for reference only, will be stored later *** optimised
zp1		.byt	$c3,$82,$41,0	;test patterns for LDx BIT ROL ROR ASL LSR
zp_bss_end:

			.bss
			* = data_segment
test_case	.dsb	1			;current test number
ram_chksm	.dsb	2			;checksum for RAM integrity test
;add/subtract operand copy - abs tests write area
abst:							;6 bytes store/modify test area
			.dsb	6
data_bss:
; *** definitions for the label addresses only *** optimised
abs1	.byt	$c3,$82,$41,0	;test patterns for LDx BIT ROL ROR ASL LSR
;loads
fLDx	.byt	fn,fn,0,fz		;expected flags for load
; *** after RAM data, blinking routine ***
ram_blink
		.dsb	10			; *** blinking routine should be copied here ***
ram_ret
		.dsb	2			; *** actual ROM return address ***
data_bss_end:

; *** no SMC branch test to generate ***

; **********************************************
; *** beginning of ROM code, no fillings yet ***
; **********************************************
		.text

		* =		code_segment

		.asc	"6503 klaus2m5 test 2", 0	; *** shorter ID text ***
start						; *** actual 6502 start ***
		cld
		ldx #$ff
		txs
		lda #0				; *** test 0 = initialize ***
		sta test_case

		test_num = 0

;stop interrupts before initializing BSS
#if I_flag== 1
		sei
#endif
	
; *** no I/O channel ***

; *** *** *** D I S A B L E D   T E S T S *** *** ***
;pretest small branch offset

; *** *** *** BACK TO ENABLED CODE *** *** ***
;initialize BSS segment
; *** this code preloads data on ZP, thus OK ***
		ldx #zp_end-zp_init-1
ld_zp	lda zp_init,x
		sta zp_bss,x
		dex
		bpl ld_zp
; *** preloading RAM area should copy blinking routine too ***
		ldx #data_end-data_init-1
ld_data lda data_init,x
		sta data_bss,x
		dex
		bpl ld_data
; *** *** change jump address accordingly *** ***
		LDY #<rom_blink
		LDX #>rom_blink
		STY ram_ret
		STX ram_ret+1
; *** vectors are always in ROM ***

; *** *** *** D I S A B L E D   T E S T S *** *** ***
; *** this is the time to create the SMC ***

; *** *** *** BACK TO ENABLED CODE *** *** ***
;generate checksum for RAM integrity test
#if	ram_top > -1
		lda #0 
		sta zpt					;set low byte of indirect pointer
		sta ram_chksm+1			;checksum high byte
		clc
		ldx #zp_bss-zero_page	;zeropage - write test area
gcs3	adc zero_page,x
		bcc gcs2
		inc ram_chksm+1			;carry to high byte
		clc
gcs2	inx
		bne gcs3
		ldx #>abs1				;set high byte of indirect pointer
		stx zpt+1
		ldy #<abs1				;data after write & execute test area
gcs5	adc (zpt),y
		bcc gcs4
		inc ram_chksm+1			;carry to high byte
		clc
gcs4	iny
		bne gcs5
		inx						;advance RAM high address
		stx zpt+1
		cpx #ram_top
		bne gcs5
		sta ram_chksm			;checksum complete
#endif
		next_test

; *** *** *** D I S A B L E D   T E S T S *** *** ***
;testing relative addressing with BEQ
;partial test BNE & CMP, CPX, CPY immediate
;testing stack operations PHA PHP PLA PLP
;testing branch decisions BPL BMI BVC BVS BCC BCS BNE BEQ
; partial pretest EOR #
; PC modifying instructions except branches (NOP, JMP, JSR, RTS, BRK, RTI)
; break & return from interrupt
; test set and clear flags CLC CLI CLD CLV SEC SEI SED

; *** *** *** BACK TO ENABLED CODE *** *** ***

; *** test_case = 1 ***
; testing index register increment/decrement and transfer
; INX INY DEX DEY TAX TXA TAY TYA 
lab_t13:
		ldx #$fe
		set_stat($ff)
		inx					;ff
		tst_x($ff,$ff-zero)
		inx					;00
		tst_x(0,$ff-minus)
		inx					;01
		tst_x(1,$ff-minus-zero)
		dex					;00
		tst_x(0,$ff-minus)
		dex					;ff
		tst_x($ff,$ff-zero)
		dex					;fe
		set_stat(0)
		inx					;ff
		tst_x($ff,minus)
		inx					;00
		tst_x(0,zero)
		inx					;01
		tst_x(1,0)
		dex					;00
		tst_x(0,zero)
		dex					;ff
		tst_x($ff,minus)

		ldy #$fe
		set_stat($ff)
		iny					;ff
		tst_y($ff,$ff-zero)
		iny					;00
		tst_y(0,$ff-minus)
		iny					;01
		tst_y(1,$ff-minus-zero)
		dey					;00
		tst_y(0,$ff-minus)
		dey					;ff
		tst_y($ff,$ff-zero)
		dey					;fe
		set_stat(0)
		iny					;ff
		tst_y($ff,0+minus)
		iny					;00
		tst_y(0,zero)
		iny					;01
		tst_y(1,0)
		dey					;00
		tst_y(0,zero)
		dey					;ff
		tst_y($ff,minus)
		
		ldx #$ff
		set_stat($ff)
		txa
		tst_a($ff,$ff-zero)
		php
		inx					;00
		plp
		txa
		tst_a(0,$ff-minus)
		php
		inx					;01
		plp
		txa
		tst_a(1,$ff-minus-zero)
		set_stat(0)
		txa
		tst_a(1,0)
		php
		dex					;00
		plp
		txa
		tst_a(0,zero)
		php
		dex					;ff
		plp
		txa
		tst_a($ff,minus)
		
		ldy #$ff
		set_stat($ff)
		tya
		tst_a($ff,$ff-zero)
		php
		iny					;00
		plp
		tya
		tst_a(0,$ff-minus)
		php
		iny					;01
		plp
		tya
		tst_a(1,$ff-minus-zero)
		set_stat(0)
		tya
		tst_a(1,0)
		php
		dey					;00
		plp
		tya
		tst_a(0,zero)
		php
		dey					;ff
		plp
		tya
		tst_a($ff,minus)

		load_flag($ff)
		pha
		ldx #$ff			;ff
		txa
		plp	
		tay
		tst_y($ff,$ff-zero)
		php
		inx					;00
		txa
		plp
		tay
		tst_y(0,$ff-minus)
		php
		inx					;01
		txa
		plp
		tay
		tst_y(1,$ff-minus-zero)
		load_flag(0)
		pha
		lda #0
		txa
		plp
		tay
		tst_y(1,0)
		php
		dex					;00
		txa
		plp
		tay
		tst_y(0,zero)
		php
		dex					;ff
		txa
		plp
		tay
		tst_y($ff,minus)

		load_flag($ff)
		pha
		ldy #$ff			;ff
		tya
		plp
		tax
		tst_x($ff,$ff-zero)
		php
		iny					;00
		tya
		plp
		tax
		tst_x(0,$ff-minus)
		php
		iny					;01
		tya
		plp
		tax
		tst_x(1,$ff-minus-zero)
		load_flag(0)
		pha
		lda #0				;preset status
		tya
		plp
		tax
		tst_x(1,0)
		php
		dey					;00
		tya
		plp
		tax
		tst_x(0,zero)
		php
		dey					;ff
		tya
		plp
		tax
		tst_x($ff,minus)
		next_test

; *** test_case = 2 ***
;TSX sets NZ - TXS does not
;	This section also tests for proper stack wrap around.
lab_t14:
		ldx #1				;01
		set_stat($ff)
		txs
		php
		lda $101
		cmp_flag($ff)
		trap_ne
		set_stat(0)
		txs
		php
		lda $101
		cmp_flag(0)
		trap_ne
		dex					;00
		set_stat($ff)
		txs
		php
		lda $100
		cmp_flag($ff)
		trap_ne
		set_stat(0)
		txs
		php
		lda $100
		cmp_flag(0)
		trap_ne
		dex					;ff
		set_stat($ff)
		txs
		php
		lda $1ff
		cmp_flag($ff)
		trap_ne
		set_stat(0)
		txs
		php
		lda $1ff
		cmp_flag(0)
		
		ldx #1
		txs					;sp=01
		set_stat($ff)
		tsx					;clears Z, N
		php					;sp=00
		cpx #1
		trap_ne
		lda $101
		cmp_flag($ff-minus-zero)
		trap_ne
		set_stat($ff)
		tsx					;clears N, sets Z
		php					;sp=ff
		cpx #0
		trap_ne
		lda $100
		cmp_flag($ff-minus)
		trap_ne
		set_stat($ff)
		tsx					;clears N, sets Z
		php					;sp=fe
		cpx #$ff
		trap_ne
		lda $1ff
		cmp_flag($ff-zero)
		trap_ne
		
		ldx #1
		txs					;sp=01
		set_stat(0)
		tsx					;clears Z, N
		php					;sp=00
		cpx #1
		trap_ne
		lda $101
		cmp_flag(0)
		trap_ne
		set_stat(0)
		tsx					;clears N, sets Z
		php					;sp=ff
		cpx #0
		trap_ne
		lda $100
		cmp_flag(zero)
		trap_ne
		set_stat(0)
		tsx					;clears N, sets Z
		php					;sp=fe
		cpx #$ff
		trap_ne
		lda $1ff
		cmp_flag(minus)
		trap_ne
		pla					;sp=ff
		next_test

; *** test_case = 3 ***
; testing index register load & store LDY LDX STY STX all addressing modes
; LDX / STX - zp,y / abs,y
lab_t15:
		ldy #3
tldx	
		set_stat(0)
		ldx zp1,y
		php					;test stores do not alter flags
		txa
		eor #$c3
		plp
		sta abst,y
		php					;flags after load/store sequence
		eor #$c3
		cmp abs1,y			;test result
		trap_ne
		pla					;load status
		eor_flag(0)
		cmp fLDx,y			;test flags
		trap_ne
		dey
		bpl tldx

		ldy #3
tldx1	
		set_stat($ff)
		ldx zp1,y
		php					;test stores do not alter flags
		txa
		eor #$c3
		plp
		sta abst,y
		php					;flags after load/store sequence
		eor #$c3
		cmp abs1,y			;test result
		trap_ne
		pla					;load status
		eor_flag(Nfnz) 		;mask bits not altered
		cmp fLDx,y			;test flags
		trap_ne
		dey
		bpl tldx1	

		ldy #3
tldx2	
		set_stat(0)
		ldx abs1,y
		php					;test stores do not alter flags
		txa
		eor #$c3
		tax
		plp
		stx zpt,y
		php					;flags after load/store sequence
		eor #$c3
		cmp zp1,y			;test result
		trap_ne
		pla					;load status
		eor_flag(0)
		cmp fLDx,y			;test flags
		trap_ne
		dey
		bpl tldx2	

		ldy #3
tldx3	
		set_stat($ff)
		ldx abs1,y
		php					;test stores do not alter flags
		txa
		eor #$c3
		tax
		plp
		stx zpt,y
		php					;flags after load/store sequence
		eor #$c3
		cmp zp1,y			;test result
		trap_ne
		pla					;load status
		eor_flag(Nfnz)		;mask bits not altered
		cmp fLDx,y			;test flags
		trap_ne
		dey
		bpl tldx3
		
		ldy #3				;testing store result
		ldx #0
tstx	lda zpt,y
		eor #$c3
		cmp zp1,y
		trap_ne				;store to zp data
		stx zpt,y			;clear	
		lda abst,y
		eor #$c3
		cmp abs1,y
		trap_ne				;store to abs data
		txa
		sta abst,y			;clear	
		dey
		bpl tstx
		next_test

; *** test_case = 4 ***
; indexed wraparound test (only zp should wrap)
lab_t16:
		ldy #3+$fa
tldx4	ldx zp1-$fa& $ff,y	;wrap on indexed zp
		txa
		sta abst-$fa,y		;no STX abs,y!
		dey
		cpy #$fa
		bcs tldx4	
		ldy #3+$fa
tldx5	ldx abs1-$fa,y		;no wrap on indexed abs
		stx zpt-$fa&$ff,y
		dey
		cpy #$fa
		bcs tldx5	
		ldy #3				;testing wraparound result
		ldx #0
tstx1	lda zpt,y
		cmp zp1,y
		trap_ne				;store to zp data
		stx zpt,y			;clear	
		lda abst,y
		cmp abs1,y
		trap_ne				;store to abs data
		txa
		sta abst,y			;clear	
		dey
		bpl tstx1
		next_test

; *** test_case = 5 ***
; LDY / STY - zp,x / abs,x
lab_t17:
		ldx #3
tldy	
		set_stat(0)
		ldy zp1,x
		php					;test stores do not alter flags
		tya
		eor #$c3
		plp
		sta abst,x
		php					;flags after load/store sequence
		eor #$c3
		cmp abs1,x			;test result
		trap_ne
		pla					;load status
		eor_flag(0)
		cmp fLDx,x			;test flags
		trap_ne
		dex
		bpl tldy	

		ldx #3
tldy1	
		set_stat($ff)
		ldy zp1,x
		php					;test stores do not alter flags
		tya
		eor #$c3
		plp
		sta abst,x
		php					;flags after load/store sequence
		eor #$c3
		cmp abs1,x			;test result
		trap_ne
		pla					;load status
		eor_flag(Nfnz) 		;mask bits not altered
		cmp fLDx,x			;test flags
		trap_ne
		dex
		bpl tldy1	

		ldx #3
tldy2	
		set_stat(0)
		ldy abs1,x
		php					;test stores do not alter flags
		tya
		eor #$c3
		tay
		plp
		sty zpt,x
		php					;flags after load/store sequence
		eor #$c3
		cmp zp1,x			;test result
		trap_ne
		pla					;load status
		eor_flag(0)
		cmp fLDx,x			;test flags
		trap_ne
		dex
		bpl tldy2	

		ldx #3
tldy3
		set_stat($ff)
		ldy abs1,x
		php					;test stores do not alter flags
		tya
		eor #$c3
		tay
		plp
		sty zpt,x
		php					;flags after load/store sequence
		eor #$c3
		cmp zp1,x			;test result
		trap_ne
		pla					;load status
		eor_flag(Nfnz)		;mask bits not altered
		cmp fLDx,x			;test flags
		trap_ne
		dex
		bpl tldy3

		ldx #3				;testing store result
		ldy #0
tsty	lda zpt,x
		eor #$c3
		cmp zp1,x
		trap_ne				;store to zp,x data
		sty zpt,x			;clear	
		lda abst,x
		eor #$c3
		cmp abs1,x
		trap_ne				;store to abs,x data
		txa
		sta abst,x			;clear	
		dex
		bpl tsty
		next_test

; *** test_case = 6 ***
; indexed wraparound test (only zp should wrap)
lab_t18:
		ldx #3+$fa
tldy4	ldy zp1-$fa&$ff,x	;wrap on indexed zp
		tya
		sta abst-$fa,x		;no STX abs,x!
		dex
		cpx #$fa
		bcs tldy4	
		ldx #3+$fa
tldy5	ldy abs1-$fa,x		;no wrap on indexed abs
		sty zpt-$fa&$ff,x
		dex
		cpx #$fa
		bcs tldy5	
		ldx #3				;testing wraparound result
		ldy #0
tsty1	lda zpt,x
		cmp zp1,x
		trap_ne				;store to zp,x data
		sty zpt,x			;clear
		lda abst,x
		cmp abs1,x
		trap_ne				;store to abs,x data
		txa
		sta abst,x			;clear
		dex
		bpl tsty1
		next_test

; *** test_case = 7 *** this one looks susitable
; testing load / store accumulator LDA / STA all addressing modes
; LDA / STA - zp,x / abs,x
lab_t21:
		ldx #3
tldax	
		set_stat(0)
		lda zp1,x
		php					;test stores do not alter flags
		eor #$c3
		plp
		sta abst,x
		php					;flags after load/store sequence
		eor #$c3
		cmp abs1,x			;test result
		trap_ne
		pla					;load status
		eor_flag(0)
		cmp fLDx,x			;test flags
		trap_ne
		dex
		bpl tldax	

		ldx #3
tldax1	
		set_stat($ff)
		lda zp1,x
		php					;test stores do not alter flags
		eor #$c3
		plp
		sta abst,x
		php					;flags after load/store sequence
		eor #$c3
		cmp abs1,x			;test result
		trap_ne
		pla					;load status
		eor_flag(Nfnz)		;mask bits not altered
		cmp fLDx,x			;test flags
		trap_ne
		dex
		bpl tldax1	

		ldx #3
tldax2	
		set_stat(0)
		lda abs1,x
		php					;test stores do not alter flags
		eor #$c3
		plp
		sta zpt,x
		php					;flags after load/store sequence
		eor #$c3
		cmp zp1,x			;test result
		trap_ne
		pla					;load status
		eor_flag(0)
		cmp fLDx,x			;test flags
		trap_ne
		dex
		bpl tldax2	

		ldx #3
tldax3
		set_stat($ff)
		lda abs1,x
		php					;test stores do not alter flags
		eor #$c3
		plp
		sta zpt,x
		php					;flags after load/store sequence
		eor #$c3
		cmp zp1,x			;test result
		trap_ne
		pla					;load status
		eor_flag(Nfnz)		;mask bits not altered
		cmp fLDx,x			;test flags
		trap_ne
		dex
		bpl tldax3

		ldx #3				;testing store result
		ldy #0
tstax	lda zpt,x
		eor #$c3
		cmp zp1,x
		trap_ne				;store to zp,x data
		sty zpt,x			;clear
		lda abst,x
		eor #$c3
		cmp abs1,x
		trap_ne				;store to abs,x data
		txa
		sta abst,x			;clear
		dex
		bpl tstax

; *** *** *********************************** *** ***
; *** *** *** D I S A B L E D   T E S T S *** *** ***
; *** *** *********************************** *** ***
; LDX / STX - zp / abs / #
; LDY / STY - zp / abs / #
; LDA / STA - (zp),y / abs,y / (zp,x)
; LDA / STA - zp / abs / #
; testing bit test & compares BIT CPX CPY CMP all addressing modes
; testing shifts - ASL LSR ROL ROR all addressing modes
; testing memory increment/decrement - INC DEC all addressing modes
; testing logical instructions - AND EOR ORA all addressing modes
; full binary add/subtract test
; decimal add/subtract test
; decimal/binary switch test * tests CLD, SED, PLP, RTI to properly switch between decimal & binary opcode

lab_t43end:
		lda test_case
		cmp #test_num
		trap_ne				;previous test is out of sequence
		lda #$f0			;mark opcode testing complete
		sta test_case

; final RAM integrity test
;	verifies that none of the previous tests has altered RAM outside of the
;	designated write areas.
		check_ram
; *** DEBUG INFO ***
; to debug checksum errors uncomment check_ram in the next_test macro to
; narrow down the responsible opcode.
; may give false errors when monitor, OS or other background activity is
; allowed during previous tests.

; S U C C E S S ************************************************
; -------------	
		success				;if you get here everything went well
; *** this will jump to RAM blink routine for faster LED indication ***
; -------------	
; S U C C E S S ************************************************

; *** ...and nothing else as it is already flashing the A10 LED ***

; *** *** *** D I S A B L E D   T E S T S *** *** ***
; core subroutine of the decimal add/subtract test
; core subroutine of the full binary add/subtract test
; target for the jump absolute test
; target for the jump indirect test
; target for the jump subroutine test

; *** *** *** NEEDS AN ENABLED RTI FOR ACCIDENTAL INTERRUPT *** *** ***
irq_trap
		rti

; *** no reports ***

;**************************************
;copy of data to initialize BSS segment
;***   including blinking routine   ***
;**************************************
; *** free from unused references! ***
zp_init
zp1_	.byt	$c3,$82,$41,0	;test patterns for LDx BIT ROL ROR ASL LSR
zp_end

#if (zp_end - zp_init) != (zp_bss_end - zp_bss)	
	;force assembler error if size is different	
	ERROR ERROR ERROR			;mismatch between bss and zeropage data
#endif
 
data_init
;zps	.byt	$80,1			;additional shift patterns test zero result & flag
abs1_	.byt	$c3,$82,$41,0	;test patterns for LDx BIT ROL ROR ASL LSR
abs7f_	.byt	$7f				;test pattern for compare
;loads
fLDx_	.byt	fn,fn,0,fz		;expected flags for load
; ************************************************************
; *** after all data, blinking routine code will be copied ***
rom_blink
		NOP:NOP:NOP			; just some suitable delay
		INX
		BNE rom_blink		; relative branches will generate the same binary
		INY
		BNE rom_blink		; relative branches will generate the same binary
		JMP ram_blink		; original jump, will be changed in RAM
; *** end of blinking routine *** 12 bytes reserved!
; *******************************
data_end

#if (data_end - data_init) != (data_bss_end - data_bss)
	;force assembler error if size is different	
	ERROR ERROR ERROR			;mismatch between bss and data
#endif 

;end of RAM init data
	
; *** hardware vectors are always set, with padding ***
vec_bss = $fffa
		.dsb	vec_bss - *, $FF

		* = vec_bss
;vectors
		.word	ram_blink	; *** without monitor or any IO, will just acknowledge NMI as successful ***
		.word	start		; *** only functionality of this device ***
		.word	irq_trap
