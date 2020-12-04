;
; 6 5 0 2		F U N C T I O N A L		T E S T		P A R T		1
;
; Copyright (C) 2012-2020	Klaus Dormann
; *** this version ROM-adapted by Carlos J. Santisteban ***
; *** for xa65 assembler, previously processed by cpp ***
; *** partial test to fit into 2 kiB ROM for 6503 etc ***
; *** last modified 202011203-1555 ***
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
;*** if enabled, does generate relevant section into RAM ***
;*** only part 1 will use SMC, otherwise is deleted, no need for the setting ***

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
; *** SMC version EEEEEEEK ***
; *** CPP admits no temporary labels, thus resolved as relative references ***
#define	check_ram			\
	cld:					\
	lda #0:					\
	sta zpt:				\
	sta zpt+3:				\
		sta range_adr:		\
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
; *** might/should check for unused references ***
		.zero

		* =		zero_page
;break test interrupt save
irq_a	.dsb	1				;a register
irq_x	.dsb	1				;x register
; *** I_flag is never 2 ***
zpt:							;6 bytes store/modify test area
		.dsb	6
zp_bss:
; *** byte definitions for reference only, will be stored later ***	OPTIMISED ***
zp_bss_end:

; *** especially important to check for unused references ***
			.bss
			* = data_segment
test_case	.dsb	1			;current test number
ram_chksm	.dsb	2			;checksum for RAM integrity test
abst:							;6 bytes store/modify test area
			.dsb	6
data_bss:
; *** definitions for the label addresses only *** OPTIMISED
abs1	.byt	$c3,$82,$41,0	;test patterns for LDx BIT ROL ROR ASL LSR
; *** after RAM data, blinking routine ***
ram_blink
		.dsb	10			; *** blinking routine should be copied here ***
ram_ret
		.dsb	2			; *** actual ROM return address ***
data_bss_end:

; *** here should define some space for the SMC branch test ***
; *** some "set" values just for reference, as all will be filled/poked ***
smc_bra		.dsb	131, $CA	; filled with DEX
range_op	.byt	$F0			;test target with zero flag=0, z=1 if previous dex *** will be poked with BEQ ***
range_adr	.byt	64			;modifiable relative address *** BEQ +64 if called without modification ***
			.dsb	127, $CA	; more DEX filling
smc_nops	.dsb	5, $EA		; first batch of NOPs (loop will fill all 20 bytes, poking 3 bytes afterwards)
smc_rok		.dsb	15, $EA		; NOPs but will poke BEQ and TRAP (5 bytes)
smc_ret		.dsb	3, $4C		; JMP to rom_ret (proper address to be poked as well)

; **********************************************
; *** beginning of ROM code, no fillings yet ***
; **********************************************
		.text

		* =		code_segment

		.asc	"6503 klaus2m5 test 1", 0	; *** shorter ID text ***
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

;pretest small branch offset
lab_t00:
		ldx #5
		jmp psb_test
psb_bwok
		ldy #5
		bne psb_forw
		trap				;branch should be taken
		dey					;forward landing zone
		dey
		dey
		dey
		dey
psb_forw
		dey
		dey
		dey
		dey
		dey
		beq psb_fwok
		trap				;forward offset

		dex					;backward landing zone
		dex
		dex
		dex
		dex
psb_back
		dex
		dex
		dex
		dex
		dex
		beq psb_bwok
		trap				;backward offset
psb_test	
		bne psb_back
		trap				;branch should be taken
psb_fwok
lab_t00end:
;initialize BSS segment
; *** no ZP data to preload, no code ***
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
		STX ram_ret
; *** vectors are always in ROM ***

; *** this is the time to create the SMC ***
		LDY #2				; as I need more than 255 bytes to fill, count two rounds
		LDX #255			; intial value for first round
		LDA #$CA			; DEX opcode
dex_fill:
			STA smc_bra-1, X	; fill byte! note offset
			DEX					; next byte
			BNE dex_fill
			DEY					; if round finished, update counter
				BEQ dex_ok			; 2 rounds done, go for NOPs
			LDX #5				; initial value for second round
			BNE dex_fill		; and fill the rest
dex_ok:
		LDX #20				; number of NOPs
		LDA #$EA			; NOP opcode
nop_fill:
			STA smc_nops-1, X	; fill byte! note offset
			DEX
			BNE nop_fill		; finish loop
; *** now for the pokes... ***
		LDA #$F0			; BEQ opcode goes in two places
		STA range_op
		STA smc_rok
		LDY #8				; range_ok offset
		STY smc_rok+1
		LDA #$4C			; JMP opcode
		STA smc_ret
		LDY #<rom_ret		; pointer for jump
		LDX #>rom_ret
		STY smc_ret+1
		STX smc_ret+2

;generate checksum for RAM integrity test
#if	ram_top > -1
		lda #0 
		sta zpt					;set low byte of indirect pointer
		sta ram_chksm+1			;checksum high byte
		sta range_adr			;reset self modifying code
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

; *** test_case = 1 ***
; *** init code, then jump to SMC generated into RAM ***
;testing relative addressing with BEQ
lab_t01:
		ldy #$fe			;testing maximum range, not -1/-2 (invalid/self adr)
range_loop
		dey					;next relative address
		tya
		tax					;precharge count to end of loop
		bpl range_fw		;calculate relative address
		clc					;avoid branch self or to relative address of branch
		adc #2
		nop					;offset landing zone - tolerate +/-5 offset to branch
		nop
		nop
		nop
		nop
range_fw
		nop
		nop
		nop
		nop
		nop
		eor #$7f			;complement except sign
		sta range_adr		;load into test target *** RAM address ***
		lda #0				;should set zero flag in status register
		jmp range_op		; *** as this is on RAM, jump to copy address ***
; ********************************************
; *** SMC is called between these segments ***
; ********************************************
rom_ret:
; *** continue after SMC ***
		cpy #0
		beq range_end	
		jmp range_loop
range_end					;range test successful
		next_test

; *** test_case = 2 ***
;partial test BNE & CMP, CPX, CPY immediate
lab_t02:
		cpy #1				;testing BNE true
		bne test_bne
		trap 
test_bne
		lda #0 
		cmp #0				;test compare immediate 
		trap_ne
		trap_cc
		trap_mi
		cmp #1
		trap_eq 
		trap_cs
		trap_pl
		tax 
		cpx #0				;test compare x immediate
		trap_ne
		trap_cc
		trap_mi
		cpx #1
		trap_eq 
		trap_cs
		trap_pl
		tay 
		cpy #0				;test compare y immediate
		trap_ne
		trap_cc
		trap_mi
		cpy #1
		trap_eq 
		trap_cs
		trap_pl
		next_test

; *** test_case = 3 ***
;testing stack operations PHA PHP PLA PLP
lab_t03:
		ldx #$ff			;initialize stack
		txs
		lda #$55
		pha
		lda #$aa
		pha
		cmp $1fe			;on stack ?
		trap_ne
		tsx
		txa					;overwrite accu
		cmp #$fd			;sp decremented?
		trap_ne
		pla
		cmp #$aa			;successful retreived from stack?
		trap_ne
		pla
		cmp #$55
		trap_ne
		cmp $1ff			;remains on stack?
		trap_ne
		tsx
		cpx #$ff			;sp incremented?
		trap_ne
		next_test

; *** test_case = 4 ***
;testing branch decisions BPL BMI BVC BVS BCC BCS BNE BEQ
lab_t04:
		set_stat($ff)		;all on
		bpl nbr1			;branches should not be taken
		bvc nbr2
		bcc nbr3
		bne nbr4
		bmi br1				;branches should be taken
		trap 
br1		bvs br2
		trap 
br2		bcs br3
		trap 
br3		beq br4
		trap 
nbr1
		trap				;previous bpl taken 
nbr2
		trap				;previous bvc taken
nbr3
		trap				;previous bcc taken
nbr4
		trap				;previous bne taken
br4		php
		tsx
		cpx #$fe			;sp after php?
		trap_ne
		pla
		cmp_flag($ff)		;returned all flags on?
		trap_ne
		tsx
		cpx #$ff			;sp after php?
		trap_ne
		set_stat(0)			;all off
		bmi nbr11			;branches should not be taken
		bvs nbr12
		bcs nbr13
		beq nbr14
		bpl br11			;branches should be taken
		trap 
br11	bvc br12
		trap 
br12	bcc br13
		trap 
br13	bne br14
		trap 
nbr11
		trap				;previous bmi taken 
nbr12
		trap				;previous bvs taken 
nbr13
		trap				;previous bcs taken 
nbr14
		trap				;previous beq taken 
br14	php
		pla
		cmp_flag(0)			;flags off except break (pushed by sw) + reserved?
		trap_ne
;crosscheck flags
		set_stat(zero)
		bne brzs1
		beq brzs2
brzs1
		trap				;branch zero/non zero
brzs2	bcs brzs3
		bcc brzs4
brzs3
		trap				;branch carry/no carry
brzs4	bmi brzs5
		bpl brzs6
brzs5
		trap				;branch minus/plus
brzs6	bvs brzs7
		bvc brzs8
brzs7
		trap				;branch overflow/no overflow
brzs8
		set_stat(carry)
		beq brcs1
		bne brcs2
brcs1
		trap				;branch zero/non zero
brcs2	bcc brcs3
		bcs brcs4
brcs3
		trap				;branch carry/no carry
brcs4	bmi brcs5
		bpl brcs6
brcs5
		trap				;branch minus/plus
brcs6	bvs brcs7
		bvc brcs8
brcs7
		trap				;branch overflow/no overflow

brcs8
		set_stat(minus)
		beq brmi1
		bne brmi2
brmi1
		trap				;branch zero/non zero
brmi2	bcs brmi3
		bcc brmi4
brmi3
		trap				;branch carry/no carry
brmi4	bpl brmi5
		bmi brmi6
brmi5
		trap				;branch minus/plus
brmi6	bvs brmi7
		bvc brmi8
brmi7
		trap				;branch overflow/no overflow
brmi8
		set_stat(overfl)
		beq brvs1
		bne brvs2
brvs1
		trap				;branch zero/non zero
brvs2	bcs brvs3
		bcc brvs4
brvs3
		trap				;branch carry/no carry
brvs4	bmi brvs5
		bpl brvs6
brvs5
		trap				;branch minus/plus
brvs6	bvc brvs7
		bvs brvs8
brvs7
		trap				;branch overflow/no overflow
brvs8
		set_stat($ff-zero)
		beq brzc1
		bne brzc2
brzc1
		trap				;branch zero/non zero
brzc2	bcc brzc3
		bcs brzc4
brzc3
		trap				;branch carry/no carry
brzc4	bpl brzc5
		bmi brzc6
brzc5
		trap				;branch minus/plus
brzc6	bvc brzc7
		bvs brzc8
brzc7
		trap				;branch overflow/no overflow
brzc8
		set_stat($ff-carry)
		bne brcc1
		beq brcc2
brcc1
		trap				;branch zero/non zero
brcc2	bcs brcc3
		bcc brcc4
brcc3
		trap				;branch carry/no carry
brcc4	bpl brcc5
		bmi brcc6
brcc5
		trap				;branch minus/plus
brcc6	bvc brcc7
		bvs brcc8
brcc7
		trap				;branch overflow/no overflow
brcc8
		set_stat($ff-minus)
		bne brpl1
		beq brpl2
brpl1
		trap				;branch zero/non zero
brpl2	bcc brpl3
		bcs brpl4
brpl3
		trap				;branch carry/no carry
brpl4	bmi brpl5
		bpl brpl6
brpl5
		trap				;branch minus/plus
brpl6	bvc brpl7
		bvs brpl8
brpl7
		trap				;branch overflow/no overflow
brpl8
		set_stat($ff-overfl)
		bne brvc1
		beq brvc2
brvc1
		trap				;branch zero/non zero
brvc2	bcc brvc3
		bcs brvc4
brvc3
		trap				;branch carry/no carry
brvc4	bpl brvc5
		bmi brvc6
brvc5
		trap				;branch minus/plus
brvc6	bvs brvc7
		bvc brvc8
brvc7
		trap				;branch overflow/no overflow
brvc8
		next_test

; *** test_case = 5 ***
; test PHA does not alter flags or accumulator but PLA does
lab_t05:
		ldx #$55			;x & y protected
		ldy #$aa
		set_a(1,$ff)		;push
		pha
		tst_a(1,$ff)
		set_a(0,0)
		pha
		tst_a(0,0)
		set_a($ff,$ff)
		pha
		tst_a($ff,$ff)
		set_a(1,0)
		pha
		tst_a(1,0)
		set_a(0,$ff)
		pha
		tst_a(0,$ff)
		set_a($ff,0)
		pha
		tst_a($ff,0)
		set_a(0,$ff)		;pull
		pla
		tst_a($ff,$ff-zero)
		set_a($ff,0)
		pla
		tst_a(0,zero)
		set_a($fe,$ff)
		pla
		tst_a(1,$ff-zero-minus)
		set_a(0,0)
		pla
		tst_a($ff,minus)
		set_a($ff,$ff)
		pla
		tst_a(0,$ff-minus)
		set_a($fe,0)
		pla
		tst_a(1,0)
		cpx #$55			;x & y unchanged?
		trap_ne
		cpy #$aa
		trap_ne
		next_test

; *** test_case = 6 *** 
; partial pretest EOR #
lab_t06:
		set_a($3c,0)
		eor #$c3
		tst_a($ff,fn)
		set_a($c3,0)
		eor #$c3
		tst_a(0,fz)
		next_test

; *** test_case = 7 ***
; PC modifying instructions except branches (NOP, JMP, JSR, RTS, BRK, RTI)
; testing NOP
lab_t07:
		ldx #$24
		ldy #$42
		set_a($18,0)
		nop
		tst_a($18,0)
		cpx #$24
		trap_ne
		cpy #$42
		trap_ne
		ldx #$DB
		ldy #$bd
		set_a($e7,$ff)
		nop
		tst_a($e7,$ff)
		cpx #$DB
		trap_ne
		cpy #$bd
		trap_ne
		next_test

; *** test_case = 8 ***
; jump absolute
lab_t08:
		set_stat($0)
		lda #'F'
		ldx #'A'
		ldy #'R'			;N=0, V=0, Z=0, C=0
		jmp test_far
		nop
		nop
		trap_ne				;runover protection
		inx
		inx
far_ret 
		trap_eq				;returned flags OK?
		trap_pl
		trap_cc
		trap_vc
		cmp #('F'^$aa)		;returned registers OK?
		trap_ne
		cpx #('A'+1)
		trap_ne
		cpy #('R'-3)
		trap_ne
		dex
		iny
		iny
		iny
		eor #$aa			;N=0, V=1, Z=0, C=1
		jmp test_near
		nop
		nop
		trap_ne				;runover protection
		inx
		inx
test_near
		trap_eq				;passed flags OK?
		trap_mi
		trap_cc
		trap_vc
		cmp #'F'			;passed registers OK?
		trap_ne
		cpx #'A'
		trap_ne
		cpy #'R'
		trap_ne
		next_test

; *** test_case = 9 ***
; jump indirect
lab_t09:
		set_stat(0)
		lda #'I'
		ldx #'N'
		ldy #'D'			;N=0, V=0, Z=0, C=0
		jmp (ptr_tst_ind)
		nop
		trap_ne				;runover protection
		dey
		dey
ind_ret 
		php					;either SP or Y count will fail, if we do not hit
		dey
		dey
		dey
		plp
		trap_eq				;returned flags OK?
		trap_pl
		trap_cc
		trap_vc
		cmp #('I'^$aa)		;returned registers OK?
		trap_ne
		cpx #('N'+1)
		trap_ne
		cpy #('D'-6)
		trap_ne
		tsx					;SP check
		cpx #$ff
		trap_ne
		next_test

; *** test_case = 10 ***
; jump subroutine & return from subroutine
lab_t10:
		set_stat(0)
		lda #'J'
		ldx #'S'
		ldy #'R'			;N=0, V=0, Z=0, C=0
		jsr test_jsr
jsr_ret = *-1				;last address of jsr = return address
		php					;either SP or Y count will fail, if we do not hit
		dey
		dey
		dey
		plp
		trap_eq				;returned flags OK?
		trap_pl
		trap_cc
		trap_vc
		cmp #('J'^$aa)		;returned registers OK?
		trap_ne
		cpx #('S'+1)
		trap_ne
		cpy #('R'-6)
		trap_ne
		tsx					;sp?
		cpx #$ff
		trap_ne
		next_test

; *** test_case = 11 ***
; break & return from interrupt
lab_t11:
		load_flag(0)			;with interrupts enabled if allowed!
		pha
		lda #'B'
		ldx #'R'
		ldy #'K'
		plp					;N=0, V=0, Z=0, C=0
		brk
		dey					;should not be executed
brk_ret0					;address of break return
		php					;either SP or Y count will fail, if we do not hit
		dey
		dey
		dey
		cmp #'B'^$aa		;returned registers OK?
;the IRQ vector was never executed if A & X stay unmodified
		trap_ne
		cpx #'R'+1
		trap_ne
		cpy #'K'-6
		trap_ne
		pla					;returned flags OK (unchanged)?
		cmp_flag(0)
		trap_ne
		tsx					;sp?
		cpx #$ff
		trap_ne
		load_flag($ff)		;with interrupts disabled if allowed!
		pha
		lda #$ff-'B'
		ldx #$ff-'R'
		ldy #$ff-'K'
		plp					;N=1, V=1, Z=1, C=1
		brk
		dey					;should not be executed
brk_ret1					;address of break return
		php					;either SP or Y count will fail, if we do not hit
		dey
		dey
		dey
		cmp #($ff-'B')^$aa	;returned registers OK?
;the IRQ vector was never executed if A & X stay unmodified
		trap_ne
		cpx #$ff-'R'+1
		trap_ne
		cpy #$ff-'K'-6
		trap_ne
		pla					;returned flags OK (unchanged)?
		cmp_flag($ff)
		trap_ne
		tsx					;sp?
		cpx #$ff
		trap_ne
		next_test

; *** test_case = 12 ***
; test set and clear flags CLC CLI CLD CLV SEC SEI SED
lab_t12:
		set_stat($ff)
		clc
		tst_stat($ff-carry)
		sec
		tst_stat($ff)
#if I_flag== 3
		cli
		tst_stat($ff-intdis)
		sei
		tst_stat($ff)
#endif
		cld
		tst_stat($ff-decmode)
		sed
		tst_stat($ff)
		clv
		tst_stat($ff-overfl)
		set_stat(0)
		tst_stat(0)
		sec
		tst_stat(carry)
		clc
		tst_stat(0)
#if I_flag== 3
		sei
		tst_stat(intdis)
		cli
		tst_stat(0)
#endif	
		sed
		tst_stat(decmode)
		cld
		tst_stat(0)
		set_stat(overfl)
		tst_stat(overfl)
		clv
		tst_stat(0)

; *** *** *** D I S A B L E D   T E S T S *** *** ***
; testing index register increment/decrement and transfer
; testing index register load & store LDY LDX STY STX all addressing modes
; testing load / store accumulator LDA / STA all addressing modes
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
		success	;if you get here everything went well
; *** this will jump to RAM blink routine for faster LED indication ***
; -------------	
; S U C C E S S ************************************************

; *** ...and nothing else as it is already flashing the A10 LED ***

; *** *** *** D I S A B L E D   T E S T S *** *** ***
; core subroutine of the decimal add/subtract test
; core subroutine of the full binary add/subtract test

; *** jumps and interrupt targets needed for test 1 ***
; target for the jump absolute test
lab_r3:
		dey
		dey
test_far
		php					;either SP or Y count will fail, if we do not hit
		dey
		dey
		dey
		plp
		trap_cs				;flags loaded?
		trap_vs
		trap_mi
		trap_eq 
		cmp #'F'			;registers loaded?
		trap_ne
		cpx #'A'
		trap_ne	
		cpy #('R'-3)
		trap_ne
		pha					;save a,x
		txa
		pha
		tsx
		cpx #$fd			;check SP
		trap_ne
		pla					;restore x
		tax
		set_stat($ff)
		pla					;restore a
		inx					;return registers with modifications
		eor #$aa			;N=1, V=1, Z=0, C=1
		jmp far_ret

; target for the jump indirect test
lab_r4:
		align
ptr_tst_ind .word test_ind
ptr_ind_ret .word ind_ret
		trap				;runover protection
		dey
		dey
test_ind
		php					;either SP or Y count will fail, if we do not hit
		dey
		dey
		dey
		plp
		trap_cs				;flags loaded?
		trap_vs
		trap_mi
		trap_eq 
		cmp #'I'			;registers loaded?
		trap_ne
		cpx #'N'
		trap_ne	
		cpy #('D'-3)
		trap_ne
		pha					;save a,x
		txa
		pha
		tsx
		cpx #$fd			;check SP
		trap_ne
		pla					;restore x
		tax
		set_stat($ff)
		pla					;restore a
		inx					;return registers with modifications
		eor #$aa			;N=1, V=1, Z=0, C=1
		jmp (ptr_ind_ret)
		trap				;runover protection *** cannot continue ***

; target for the jump subroutine test
lab_r5:
		dey
		dey
test_jsr
		php					;either SP or Y count will fail, if we do not hit
		dey
		dey
		dey
		plp
		trap_cs				;flags loaded?
		trap_vs
		trap_mi
		trap_eq 
		cmp #'J'			;registers loaded?
		trap_ne
		cpx #'S'
		trap_ne	
		cpy #('R'-3)
		trap_ne
		pha	;save a,x
		txa
		pha	
		tsx					;sp -4? (return addr,a,x)
		cpx #$fb
		trap_ne
		lda $1ff			;proper return on stack
		cmp #>jsr_ret
		trap_ne
		lda $1fe
		cmp #<jsr_ret
		trap_ne
		set_stat($ff)
		pla					;pull x,a
		tax
		pla
		inx					;return registers with modifications
		eor #$aa			;N=1, V=1, Z=0, C=1
ex_rts						; *** label for delay via JSR/RTS ***
		rts
		trap				;runover protection *** cannot continue ***
		
;trap in case of unexpected IRQ, NMI, BRK, RESET - BRK test target
; *** no monitor or IO to check NMI stack status, just end test acknowledging NMI ***
; *** no res_trap as will just start the test ***		
lab_r6:
		dey
		dey
irq_trap					;BRK test or unextpected BRK or IRQ
		php					;either SP or Y count will fail, if we do not hit
		dey
		dey
		dey
;next traps could be caused by unexpected BRK or IRQ
;check stack for BREAK and originating location
;possible jump/branch into weeds (uninitialized space)
		cmp #$ff-'B'		;BRK pass 2 registers loaded?
		beq break2
		cmp #'B'			;BRK pass 1 registers loaded?
		trap_ne
		cpx #'R'
		trap_ne	
		cpy #'K'-3
		trap_ne
		sta irq_a			;save registers during break test
		stx irq_x
		tsx					;test break on stack
		lda $102,x
		cmp_flag(0)			;break test should have B=1 & unused=1 on stack
		trap_ne				; - no break flag on stack
		pla
		cmp_flag(intdis)	;should have added interrupt disable
		trap_ne
		tsx
		cpx #$fc			;sp -3? (return addr, flags)
		trap_ne
		lda $1ff			;proper return on stack
		cmp #>brk_ret0
		trap_ne
		lda $1fe
		cmp #<brk_ret0
		trap_ne
		load_flag($ff)
		pha
		ldx irq_x
		inx					;return registers with modifications
		lda irq_a
		eor #$aa
		plp					;N=1, V=1, Z=1, C=1 but original flags should be restored
		rti
		trap				;runover protection *** cannot continue ***
lab_r7:
break2						;BRK pass 2	
		cpx #$ff-'R'
		trap_ne	
		cpy #$ff-'K'-3
		trap_ne
		sta irq_a			;save registers during break test
		stx irq_x
		tsx					;test break on stack
		lda $102,x
		cmp_flag($ff)		;break test should have B=1
		trap_ne				; - no break flag on stack
		pla
		ora #decmode		;ignore decmode cleared if 65c02
		cmp_flag($ff)		;actual passed flags
		trap_ne
		tsx
		cpx #$fc			;sp -3? (return addr, flags)
		trap_ne
		lda $1ff			;proper return on stack
		cmp #>brk_ret1
		trap_ne
		lda $1fe
		cmp #<brk_ret1
		trap_ne
		load_flag(intdis)
		pha	
		ldx irq_x
		inx					;return registers with modifications
		lda irq_a
		eor #$aa
		plp					;N=0, V=0, Z=0, C=0 but original flags should be restored
		rti
		trap				;runover protection *** cannot continue ***
lab_r7end:
; *** no reports ***

;**************************************
;copy of data to initialize BSS segment
;***   including blinking routine   ***
;**************************************
; *** free from unused references! ***
zp_init
zp_end

#if (zp_end - zp_init) != (zp_bss_end - zp_bss)	
	;force assembler error if size is different	
	ERROR ERROR ERROR			;mismatch between bss and zeropage data
#endif
 
data_init
abs1_	.byt	$c3,$82,$41,0	;test patterns for LDx BIT ROL ROR ASL LSR	*** needed for RAMcheck
; ************************************************************
; *** after all data, blinking routine code will be copied ***
rom_blink:
		JSR ex_rts			; just some suitable delay
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
		.word	irq_trap	; *** this one will hang upon unexpected interrupt, as BRK is not tested
