; RTC test via the I2C inteface on FastSPI card
; (c) 2024 Carlos J. Santisteban
; last modified 20241017-1810

; send as binary blob via nanoBoot (-x 0x1000 option)

; *** constants ***
#define	SCL		%00010000
#define	SDA		%00100000
#define	I2C_C	%01000000
#define	I2C_D	%10000000
#define	A_SPI	%00001111
#define	RTC		$68
#define	COLOUR	$FF
#define	BACKGROUND	$EE
; *** hardware addresses ***
IO8attr	= $DF80
IO9rtc	= $DF97				; I2C port on FastSPI card
IOAie	= $DFA0

; *** memory allocation *** needs four bytes, not necessarily on ZP
#ifdef	I2C_LOCAL
i2str	= I2C_LOCAL
#else
i2str	= $FC				; global started condition
#endif

ptr		= i2str				; temporary pointer
i2time	= i2str+1			; timeout counter
i2nak	= i2time+1			; NACK at d7
nak1st	= i2nak+1			; NACK to be sent after first byte reception
temp	= nak1st			; temporary var
; ******************
; *** code start ***
; ******************
	*	= $1000

reset:
	SEI						; usual 6502 stuff
	CLD
	LDX #$FF
	TXS
	STX IOAie				; Durango specifics
	LDA #$38				; colour mode
	STA IO8attr
	LDX #>isr				; BRK handler
	LDY #<isr
	STY $0200
	STX $0201				; set IRQ vector
	LDX #>reset				; warm reset
	LDY #<reset
	STY $0202
	STX $0203				; set NMI vector
; fill the screen
	LDX #$60				; screen start
	LDY #0
	STY ptr
	LDA #BACKGROUND			; fill with fuchsia
cls_pg:
		STX ptr+1			; update page
cls_l:
			STA (ptr), Y
			INY
			BNE cls_l
		INX
		BPL cls_pg			; usual fill screen
; TEST CODE
	LDA #$18				; somewhat centered
	STY ptr
test_l:
		LDX #$6C
		STA ptr
		STX ptr+1
		PHA
		AND #$0F
		CMP #$0A
		BCC dec_ok
			SBC #$0A
dec_ok:
		JSR bcd_disp
		PLA
		INC
		INC
		CMP #$28
		BCC test_l
	BRK
; *** I2C-RTC test suite ***
start:
 	LDA #A_SPI
	STA IO9rtc				; disable all SPI ports, just in case

; **************************
; *** interface routines ***
; **************************
i2send:						; *** send byte in A to address in X ***
	STZ i2str				; clear started condition
	PHA						; store date for later
	TXA						; retrieve address
	ASL						; put 0 at d0 as is a write operation
	JSR i2write				; send this byte in A
; might check for NACK here...
	PLA						; get stored data
;	BRA i2write				; and write data afterwards

i2write:					; *** raw byte in A sent thru I2C ***
	TAX						; save for later
	JSR i2start				; set START condition, here?
	LDY #8					; number of bits per byte
is_loop:
		TXA					; get remaining bits
		ASL					; shift MSB out
		TAX					; keep current state
; write single bit from C...
		LDA #SDA
		BCS was_one			; if C is set, bit was 1
			TRB IO9rtc		; otherwise will set SDA bit low
		BRA sda_set
was_one:
			TSB IO9rtc		; in this case, SDA goes high
sda_set:
		JSR delay			; timing!
		LDA #SCL
		TSB IO9rtc			; SCL goes high, data bit is sampled
		JSR clk_str			; stretching
		BCC no_arb			; if bit is ZERO, do not check arbitration
			JSR arbitr
no_arb:
		LDA #SCL
		TRB IO9rtc			; clear SCL
; ...bit sent
		DEY					; one bit less
		BNE is_loop
; read NACK
	LDA IO9rtc				; will set N if NACK
	STA i2nak				; store flag (d7)
;	BRA i2stop				; this will send stop bit and return

i2stop:						; *** generic send STOP condition ***
	LDA #SDA
	TRB IO9rtc				; clear SDA, prepare for STOP condition
	JSR delay				; timing!
	LDA #SCL
	TSB IO9rtc				; set SCL
	JSR clk_str				; clock stretching and timing!
	LDA #SDA
	TSB IO9rtc				; low-to-high transition in SDA while SCL is high, is STOP condition
	STZ i2str				; no longer started
;	JMP arbitr				; after delay, check for arbitration and return

arbitr:						; *** check if arbitration is lost ***
	BIT IO9rtc				; check I2C_D
	BMI st_ok
		BRK					; if zero, arbitration lost
st_ok:
	RTS

i2receive:					; *** receive byte in A from address in X ***
	TXA						; retrieve address
	SEC						; carry on...
	ROL						; ...put 1 at d0 as is a write operation
	JSR i2write				; send this byte in A
; might check for NACK here...
	LDA nak1st				; ...but determine whether it's a single byte transfer
	STA i2nak
;	BRA i2read				; and read byte afterwards
i2read:						; *** raw read into A from I2C, sendind ACK/NACK afterwards ***

; also check ACK, but if NACK received, jump to STOP

; *** more useful routines ***
i2start:					; *** generic set START condition ***
	BIT i2str				; already started?
	BPL no_str				; if so, do restart
		LDA #SDA
		TSB IO9rtc			; set SDA
		JSR delay			; ensure timing!
		LDA #SCL
		TSB IO9rtc			; set SCL
		JSR clk_str			; clock stretching! and right timing!
no_str:
	JSR arbitr				; check if arbitration was lost
	LDA #SDA
	TRB IO9rtc				; high-to-low SDA is START condition
	DEC i2str				; dangerously set as started... and some delay as requested
	NOP: LDA i2str			; timing!
	LDA #SCL
	TRB IO9rtc				; clear SCL as well
delay:
	RTS

; *** check for clock stretching with timeout (~25 ms, standard overhead is 22t) ***
clk_str:
	STZ i2time				; reset timeout counter (base loop is 342*256=87552t, 25.04 mS at least, up to 57)
str_l:
		BIT IO9rtc			; check I2C_C (4)
	BVS clk_ok				; already high, all OK (2)
		PHY					; best here (3)
		LDY #64				; inner iterations (2)
str_il:
			DEY				; inner loop (5*64-1=319)
			BNE str_il
		PLY					; (4)
		INC i2time			; otherwise increment counter (5 or 6)
		BNE str_l			; (3)
	BRK						; until timeout!
clk_ok:
	RTS

; ***********************************
; *** interrupt handler (for BRK) ***
; ***********************************
isr:
	PHA						; let's do things right...
	PHX
	TSX
	LDA $0103, X			; stored P
	AND $10					; B flag
	BEQ exit				; not BRK, restore
lock:
				INX
				BNE lock	; eeeeek
			INY
			BNE lock		; usual delay
		INC
		STA IOAie			; will toggle error LED
		BRA lock			; forever
exit:
	PLX						; restore status and return
	PLA
	RTI

; **************************
; * single number printing *
; **************************
; input
;	A		BCD nibble
;	ptr		base address
bcd_disp:
	ASL						; two bytes per raster
	TAX						; first raster address
	LDY #0
n_rast:
			LDA numbers, X
			EOR #$FF
			AND #BACKGROUND
			STA temp		; keep background nibble
			LDA numbers, X
			AND #COLOUR		; foreground pixels
			ORA temp		; mix
			STA (ptr), Y	; copy glyph raster into screen
			INX
			INY
			TYA				; check parity
			LSR
			BCS n_rast		; untl next even index
		TYA
		CLC
		ADC #62				; one raster minus 2 bytes of a number
		TAY
		BCC ras_nw
			INC ptr+1
ras_nw:
		TXA
		CLC
		ADC #18				; advance to next raster in font (30 for hex)
		TAX
		CPX #140			; within valid raster? (10 numbers * 2 bytes * 7 rasters) (224 for hex)
		BCC n_rast
	RTS

numbers:
	.bin	0, 0, "../../columns/art/numbers.sv20"	; generic number images, 20-byte wide
