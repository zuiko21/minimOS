; nanoBoot v2 (w/ support for Durango Cartridge & Pocket format, plus Chihuahua·D)
; (c) 2024 Carlos J. Santisteban
; last modified 20240626-1819

; add -DALONE for standalone version (otherwise module after multiboot.s)
#echo	fixed Durango init, Chihuahua-D compatible (with feedback)

#ifdef ALONE
	*		= $E000			; skip I/O, just in case
; standard pointers
	fw_irq	= $0200
	fw_nmi	= $0202
; standard hardware definitions
	IO8attr	= $DF80
	IO9kbd	= $DF9B
	IOAie	= $DFA0
	IOCart	= $DFC0
	screen3	= $6000
; *** Chihuahua·D VIA definitions ***
	D_IORB	= $BFF0
	D_DDRB	= $BFF2
	D_PCR	= $BFFC
	D_IFR	= $BFFD
	D_IER	= $BFFE

; might add standard header too
rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"nanoBoot v2.1"	; C-string with filename @ [8], max 220 chars
; note terminator below
; optional C-string with comment after filename, filename+comment up to 220 chars
	.asc	0, 0

; advance to end of header *** NEW format
	.dsb	rom_start + $E6 - *, $FF

; NEW library commit (user field 2)
	.asc	"$$$$$$$$"
; NEW main commit (user field 1)
	.asc	"$$$$$$$$"
; NEW coded version number
	.word	$2141			; 2.1b1		%vvvvrrrrsshhbbbb, where revision = %hhrrrr, ss = %00 (alpha), %01 (beta), %10 (RC), %11 (final)
; date & time in MS-DOS format at byte 248 ($F8)
	.word	$8F00			; time, 17.56		%1000 1-111 000-0 0000
	.word	$58DA			; date, 2024/6/26	%0101 100-0 110-1 1010
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start			; filesize (rom_end is actually $10000)
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number
#endif

; *** zeropage usage ***
	nb_ex	= $F8			; copy of initial address, or execution address
	nb_ptr	= $FA			; initial address, will be used as pointer (will reuse for screen drawing)
	nb_end	= $FC			; final address (consecutive) after downloaded chunk
	nb_type	= $FE			; magic number

; *******************
; *** actual code ***
; *******************
nb_start:
	SEI						; just in case!

#ifdef	ALONE
	CLD						; continue standard 6502 init
	LDX #$FF
	TXS
	LDA #%10110000			; *** Durango·X init, HIRES mode ***
	STA IO8attr				; eeeek
; clear screen
	LDX #>screen3			; standard screen start address
	LDY #<screen3			; should be zero!
	STY nb_ptr
	LDA #0					; clear screen for good measure
nc_page:
		STX nb_ptr+1		; update page
nc_loop:
			STA (nb_ptr), Y	; clear byte
			INY
			BNE nc_loop		; full page
		INX
		BPL nc_page			; next page until end of RAM
; * display nanoBoot banner *
s_ban:
	LDX #3					; max offset
sb_loop:
		LDA banner, X
		STA $770A, X
		LDA banner+4, X
		STA $772A, X
		LDA banner+8, X
		STA $774A, X
		LDA banner+12, X
		STA $776A, X
		LDA banner+16, X
		STA $778A, X
		DEX
		BPL sb_loop
	LDA #$FF				; ** Chihuahua specifics **
	STA D_DDRB				; set PB all outputs for feedback
	STZ D_IORB				; all LEDs off
	LSR						; now A is $7F
	STA D_IER				; disable all interrupt sources
	STA D_IFR				; and clear any previous interrupt
; might check if D_IER reads $80, but anyway...
	LDA #%11001110			; make sure CB2 is low (no sound!)
	STA D_PCR
#else
; display ready message thru CONIO
	LDX #banner-msg			; reset offset
	JSR sb_loop				; and print selected message
#endif

; *** all inited, get ready for reception ***
nb_rdy:
	STZ IOAie				; note we keep IRQ disabled! *CMOS
	LDA #%11100000			; Chihuahua pattern
	STA D_IORB
	LDY #<nb_irq
	LDA #>nb_irq			; get receiver ISR address
	STY fw_irq
	STA fw_irq+1			; standard vector
	LDY #<nb_nmi
	LDA #>nb_nmi			; get receiver NMI address
	STY fw_nmi
	STA fw_nmi+1			; standard vector
; since we have no registers left, preselect keyboard column
	LDA #1					; (2+4) first column has both SPACE & SHIFT
	STA IO9kbd

; *** receive full header and set things accordingly ***
	LDY #4					; (2) max header offset
nh_rcv:
		LDX #8				; (2) prepare for next byte
nh_rby:
; inner loop is the best place for aborting
			PHY				; (3) EEEEK
			LDY IO9kbd		; (4) column is already selected
			CPY #%10100000	; (2) both SHIFT & SPACE?
			BNE no_ab		; (usually 3)
				PLY			; (4) EEEEK
				JMP nb_error			; PLACEHOLDER, note stack imbalance
no_ab:
			PLY				; (4) EEEEEEEEEEEEEEEEEEEK
#ifdef	ALONE
#ifdef	DEBUG
			STA $77CA, Y	; (5) funny header display
#endif
#endif
			CPX #0			; (2)
			BNE nh_rby		; (3/2) wait for complete byte
		STA nb_ptr, Y		; (5) store received byte
		DEY					; (2) next header byte (note reversed order)
		BPL nh_rcv			; (3/2) until all 40 bits done
	STZ IO9kbd				; (4) for good measure

; check header
	LDX nb_type				; (3) first of all, check for a valid magic number
	CPX #$4B				; (2) below $4B?
		BCC nb_error		; (2/3) if so, not valid
	CPX #$4F				; (2) above $4E?
		BCS nb_error		; (2/3) if so, not valid EEEEK
	LDY nb_ptr
	LDA nb_ptr+1			; (3+3) copy start address...
	STY nb_ex
	STA nb_ex+1				; (3+3) ...for future use
; display detected type
;	LDX nb_type
	TXA
	SEC
	SBC #$4B				; (2+2+2) turn $4B...$4E into 0...3
#ifdef	ALONE
	TAX
	LDA type, X
	STA $770E
	LDA type+4, X
	STA $772E
	LDA type+8, X
	STA $774E
	LDA type+12, X
	STA $776E
	LDA type+16, X
	STA $778E
#else
; display type thru CONIO
;	CLC						; assume C is set per SBC above
	ADC #'B'-1				; note offset via carry, will turn 0...3 into 'B'...'E'
	TAY
	JSR conio
#endif
	LDY nb_ptr				; (3) retrieve base offset in Y
	STZ nb_ptr				; (3) clear offset, and we are ready!

; *** receive payload ***
nb_rcv:
		LDX #8				; (2) prepare for next byte
nb_rby:
			CPX #0			; (2) byte done?
			BNE nb_rby		; (3/2) wait for complete byte
		STA (nb_ptr), Y		; (6) store received byte
		INY					; (2) next address
		BNE nb_nw			; (3/2) no wrap
			INC nb_ptr+1	; (5) or next page
			LDX nb_ptr+1	; (3) but skip I/O!
			CPX #$DF		; (2) is it IO page?
			BNE no_io		; (3/2)
				INC nb_ptr+1			; (5) skip it EEEEEEK
no_io:
; may check for break key (inlined)
			LDA #1			; (2+2) first column has both SPACE & SHIFT
			STA IO9kbd
			LDA IO9kbd		; (4+4) get active rows
			STZ IO9kbd		; (4) just for good measure
;			AND #%10100000	; (2) mask relevant keys NOPE, this way Chihuahua·D compatible too!
			CMP #%10100000	; (2) both SHIFT & SPACE?
			BNE nb_cont		; (3/2) nope, just continue
;				JMP nb_error			; (3) PLACEHOLDER

; *****************************************************************************************************
; *** if no valid magic number, set null clock handler for lines on screen to mark transmission end *** moved
nb_error:
	LDY #<nb_dis			; (2+2) get null clock handler
	LDX #>nb_dis
	STY fw_nmi				; (3+3) redirect handler (might become simply STZ fw_nmi if aligned!)
	STX fw_nmi+1
	SEI
; draw some feedback
#ifdef	ALONE
	LDA #$FF				; whole byte
	LDX #5					; max offset
err_loop:
		STA $772A, X		; strike two lines
		STA $776A, X
		DEX
		BPL err_loop
#else
; more elaborate error feedback
	LDX #error-msg			; preset offset
	JSR sb_loop				; and print selected message
#endif
	LDA #$FF				; all LEDs
lock:
				INX
				BNE lock
			INY
			BNE lock
		STA IOAie			; update ERROR LED
		STA D_IORB			; Chihuahua too
		EOR #$FF			; will keep flashing
		BRA lock			; just press RST when transmission has ended!
; *****************************************************************************************************

nb_cont:
; add some page feedback
			PHY				; eeeek
			JSR progress	; generic call
			PLY
; check limits
nb_nw:
		CPY nb_end			; (3) already finished?
			BNE nb_rcv		; (3/2) no, get next byte
		LDA nb_ptr+1		; (3+3) check MSB too
		CMP nb_end+1
			BNE nb_rcv		; (3/2)

; *** transfer ended ***
	LDY #<nb_rti
	LDA #>nb_rti			; (2+2) set null interrupt vectors, just in case
	STY fw_nmi
	STY fw_irq
	STA fw_nmi+1
	STA fw_irq+1			; (3+3+3+3) all clear
	LDA #1					; (2) this will enable IRQ generator
	STA IOAie				; (4) turn off LED
;	BNE nb_exec				; (3) try executing, no need for BRA

; *** execute if possible *** continue
nb_exec:
	LDA nb_type				; (3) get magic byte
	CMP #$4B				; (2) legacy nanoBoot binary?
	BNE not_bin				; (3/2)
		JMP (nb_ex)			; (6) go for it!
not_bin:
	CMP #$4C				; (2) Durango ROM image?
	BNE not_cart			; (3/2)
		JMP switch			; (3) standard ShadowRAM boot
not_cart:
	CMP #$4D				; (2) generic data?
	BNE not_data			; (3/2)
#ifdef	ALONE
		STZ $770E			; (20) just clear detected type on screen
		STZ $772E
		STZ $774E
		STZ $776E
		STZ $778E
#else
	LDX #clrtype-msg		; preset offset
	JSR sb_loop				; and print selected message	
#endif
		JMP nb_rdy			; (3) back to receiving mode
not_data:
	CMP #$4E				; (2) Pocket executable?
	BNE nb_bad				; (3/2) if not, bad byte *** should NEVER happen ***
; else, point to execution address in loaded file header EEEEEEK
		LDY #5				; (2) execution address offset
		LDA (nb_ex), Y		; (5) extract LSB from header
		STA nb_ptr			; (3) reuse this pointer for final indirect jump
		INY					; (2) go for MSB (offset 6)
		LDA (nb_ex), Y		; (5) extract MSB from header
		STA nb_ptr+1		; (3) indirect pointer is complete
		JMP (nb_ptr)		; (6) actual execution pointer is *pointed* here
nb_bad:
	JMP nb_error

; ************************
; *** feedback support ***
; ************************
#ifdef	ALONE
; progress bar routine (already installed for SD)
progress:
	LDA nb_type
	CMP #$4D
	BEQ no_bar				; if it's generic data (could be screenshot), do not display progress
		LDA nb_ptr+1		; check new page
		STA D_IORB			; * Display page in binary thru Chihuahua simple I/O *
		DEC					; last completed page
		TAY					; save!
		LSR
		LSR
		LSR					; 256 pages into 32 bytes (HIRES)
		TAX					; offset ready
		TYA					; back
		AND #7				; number of pixels set, after adding 1; expected EVEN
		TAY					; as index
		LDA prog_pat, Y		; proper bitmap
		STA $7F80, X
		STA $7FA0, X
		STA $7FC0, X
		STA $7FE0, X		; beautifully displayed
no_bar:
	RTS
#else
; print message from selected offset
sb_loop:
		LDY msg, X			; get char
	BEQ sb_exit				; until end
		PHX
		JSR conio			; print it
		PLX
		INX					; next char
		BNE sb_loop			; no need for BRA
sb_exit:
	RTS
#endif

; ***********************************
; *** nanoBoot interrupt handlers ***
; ***********************************

; *** SERCLK handler ***
nb_dis:
; disabled clock handler! (best if page-aligned)
	PHA
	LDA IO8attr				; get video mode
	AND #$F0				; filter readable bits (no need to add RGB mode)
	EOR #64					; toggle inverse video
	STA IO8attr				; update
	PLA						; EEEEK
	RTI
; * actual clock pulse reception *
nb_nmi:
; received bits should be LSB first!
	CLC						; bits are *OFF* by default (2)
	PHA						; preserve A, as ISR will change it! (3)
	CLI						; enable interrupts for a moment (2... plus 22)
; if /IRQ was low, ISR will *set* C, thus injecting a one
	SEI						; what happened? (2)
	PLA						; retrieve A, but C won't be affected (4)
	ROR						; inject C into byte, LSB first (2)
	DEX						; this will turn 0 when done, if preloaded with 8 (2)
nb_rti:
	RTI						; (6) total 23, plus 22 for ISR, plus 7 for ACK (worst 52)

; *** SERDAT handler ***
nb_irq:
; *** this modifies A (and stored P), thus PHA is needed on NMI for proper operation ***
; since this has to set I flag anyway, clear stored C as received bit value
	PLA						; saved status... (4)
	ORA #%00000101			; ...now with I set *AND* C set (2)
	PHA						; restore all (A changed) (3)
	RTI						; (6) whole routine takes only 15 clocks, plus acknowledge (total 22)

; *******************************************************
; *** end of module, start of required firmware ahead ***
; *******************************************************

#ifdef	ALONE
; *** standard interrupt handlers ***
irq:
	JMP (fw_irq)
nmi:
	JMP (fw_nmi)

; * feedback data *
; banner data
banner:
	.byt	$04, $00, $C0, $04
	.byt	$C2, $C4, $A4, $4E
	.byt	$AE, $AA, $CA, $A4
	.byt	$AA, $AA, $AA, $A4
	.byt	$AE, $A4, $C4, $42

; microfont data 'B', 'C', 'D', 'E' by rasters
type:
	.byt	$1C, $0C, $1C, $1E
	.byt	$12, $12, $12, $10
	.byt	$9C, $90, $92, $9E
	.byt	$12, $12, $12, $10
	.byt	$9C, $8C, $9C, $9E

; progress bar patterns
prog_pat:
	.byt	%10000000, %11000000, %11100000, %11110000, %11111000, %11111100, %11111110, %11111111

; *****************************
; *** alignment and ROM end ***
; *****************************
	.dsb	$FFD6-*, $FF	; padding

	.asc	"DmOS"			; standard minimOS signature

	.dsb	$FFDC-*, $FF

switch:
	LDA #%01100100			; ROM disabled, protected RAM, and SD disabled just in case
do_sw:
	STA IOCart

; * = $FFE1
autoreset:
	JMP ($FFFC)				; RESET on loaded image *** mandatory instruction on any ROM image ***
 
; *****************************
; *** standard 6502 vectors ***
; *****************************
	.dsb	$FFFA-*, $FF

; * = $FFFA
	.word	nmi
	.word	nb_start
	.word	irq
#else
; * feedback messages for CONIO *
msg:						; base address
banner:
	.asc	"nanoBoot?", 2, 14, 0		; standard banner
clrtype:
	.asc	15, ' ', 2, 14, 0		; clear previously displayed type
error:
	.asc	15, ' ', 14, "FAIL!", 15, 7, 0		; error message
#endif
