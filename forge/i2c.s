; RTC test via the I2C inteface on FastSPI card
; (c) 2024 Carlos J. Santisteban
; last modified 20241024-1836

; send as binary blob via nanoBoot (-x 0x1000 option)

; *** constants ***
; bit-banging interface
#define	SCL		%00010000
#define	SDA		%00100000
;define	I2C_C	%01000000
;define	I2C_D	%10000000
#define	A_SPI	%00111111
; RTC I2C address (with R/W bit)
#define	RTC_W	%11010000
#define	RTC_R	%11010001
; RTC registers
#define	DS_S	0
#define	DS_M	1
#define	DS_H	2
#define	DS_DAY	3
#define	DS_DATE	4
#define	DS_MON	5
#define	DS_YEAR	6
#define	DS_CTL	7
; user interface
#define	COLOUR		$FF
#define	BACKGROUND	$EE
#define	POS_H		$6F

; *** hardware & firmware addresses ***
fw_irq	= $0200				; standard IRQ vector
fw_nmi	= $0202				; standard NMI vector
screen	= $6000				; standard screen
IO8attr	= $DF80
IO9rtc	= $DF97				; I2C port on FastSPI card
IOAie	= $DFA0

; *** memory allocation *** needs nine bytes, not necessarily on ZP
#ifdef	I2C_LOCAL
rcvd	= I2C_LOCAL
#else
rcvd	= $F7				; received byte
#endif

ptr		= rcvd+1			; temporary pointer
i2time	= ptr+2				; timeout counter
i2nak	= i2time+1			; NAK at d7
result	= i2nak+1			; stored time
olds	= result+3			; previous seconds

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
	LDA #$38				; colour mode, screen 3 as usual
	STA IO8attr
	LDX #>isr				; BRK handler
	LDY #<isr
	STY fw_irq
	STX fw_irq+1			; set IRQ vector
	LDX #>reset				; warm reset
	LDY #<reset
	STY fw_nmi
	STX fw_nmi+1			; set NMI vector
; fill the screen
	LDX #>screen			; screen start
	LDY #0					; MUST be zero!
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
; *** I2C-RTC test suite ***
start:
	LDA #A_SPI
	STA IO9rtc				; disable all SPI ports, just in case
; set address register to seconds, for the CH bit
	JSR i2start				; set START condition
	LDA #RTC_W				; select device address for write
	JSR i2send
	LDA #DS_S				; select seconds register to access CH bit
	JSR i2send				; this will set address register, no further writes
	JSR i2stop				; end of this transfer
; read seconds register
	JSR i2start				; set START condition
	LDA #RTC_R				; select device address for future read
	JSR i2send
	LDA #$FF				; next will be NAK
	STA i2nak				; single-byte reception
	JSR i2receive			; get first byte [0] and send STOP afterwards
; clear CH bit and resend register
	AND #$7F				; make sure bit 7 (CH) is clear
	PHA						; keep register value eeeeek
	JSR i2start				; set START condition
	LDA #RTC_W				; select device address for write
	JSR i2send
	LDA #DS_S				; select seconds register to access CH bit
	JSR i2send				; this will set address register...
	PLA						; ...retrieve actual register value...
	JSR i2send				; ...and write it
	JSR i2stop				; end of this transfer
clock:
; first of all, select address of seconds (first) register
		JSR i2start			; set START condition
		LDA #RTC_W			; select device address for write
		JSR i2send
		LDA #DS_S			; select seconds register
		JSR i2send			; this will set address register
		JSR i2stop			; end of this transfer
; now copy the current values
		JSR i2start			; set START condition
; first of all, selected byte
		LDA #RTC_R			; select device address for read
		JSR i2send
		STZ i2nak			; multi-byte reception
		JSR i2receive		; get first byte
		STA result+2		; will be stored reversed!
; now go for the remaining bytes (not worth a loop)
		JSR i2receive
		STA result+1
		DEC i2nak			; third and last byte
		JSR i2receive		; this will send STOP as well
		STA result
		LDA #%01000000		; but check 12/24h
		TRB result			; clear flag for dislplay...
		; ...and if Z, was in 12hr mode
; if something changed, display time
		LDA result+2		; check seconds
		CMP olds			; same as before?
	BEQ clock				; check again!
		STA olds			; update displayed time
		LDX #2				; offset group
disp_l:
			PHX
			LDA result, X	; get group data
			JSR bcd_prn		; display full number eeeek
			PLX
			DEX
			BPL disp_l		; all groups
		BRA clock

; **************************
; *** interface routines ***
; **************************
i2send:						; *** send byte in A ***
	TAX						; save for later
	LDY #8					; number of bits per byte
is_loop:
		TXA					; get remaining bits
		ASL					; shift MSB out
		TAX					; keep current state
		JSR w_bit			; write single bit from C
		DEY					; one bit less
		BNE is_loop
; read NAK
	LDA #SDA
	TSB IO9rtc				; set SDA
	LDA #SCL
	TSB IO9rtc				; set SCL, could be done simultaneously?
	JSR delay
	JSR r_bit				; read bit (NAK) into C
	ROR i2nak				; store flag (d7)
	LDA #SCL
	TRB IO9rtc				; SCL off!
	RTS						; just end, check NAK afterwards and send STOP if needed

w_bit:						; *** write single bit from C ***
	LDA #SDA
	BCS was_one				; if C is set, bit was 1
		TRB IO9rtc			; otherwise will set SDA bit low
	BRA sda_set
was_one:
		TSB IO9rtc			; in this case, SDA goes high
sda_set:
	JSR delay				; timing!
	LDA #SCL
	TSB IO9rtc				; SCL goes high, data bit is sampled
	JSR clk_str				; stretching, also delays
#echo no write arb
;		BCC no_arb			; if bit is ZERO, do not check arbitration
;			JSR arbitr
no_arb:
	LDA #SCL
	TRB IO9rtc				; clear SCL
	JMP delay				; just in case... and return

i2receive:					; *** receive byte into A ***
	LDA #1					; note trick to activate C upon full byte reception
	STA rcvd				; reset received byte
	LDA #SDA
	TSB IO9rtc				; SDA on!
ir_loop:
		JSR r_bit			; read single bit into C
		ROL rcvd			; inject received bit
		BCC ir_loop			; until that C appears!
; send ACK or NAK, accordingly
	LDA i2nak				; get flag (d7)
	ASL						; now into C
	JSR w_bit				; send ACK/NAK
	LDA #SDA
	TSB IO9rtc				; SDA on!
	BIT i2nak				; recheck NAK
	BPL no_stop
		JSR i2stop			; if NAK, send STOP too... but finish reading afterwards!
no_stop:
	LDA rcvd				; return received byte EEEEEEEEEEEEEEK
	RTS

r_bit:						; *** read single bit into C ***
	LDA #SCL
	TSB IO9rtc				; set SCL
	JSR clk_str				; stretching
	LDA IO9rtc				; read SDA...
	ASL						; ...and store it in C
	JSR delay				; timing!
	LDA #SCL
	TRB IO9rtc				; clear SCL (should not affect C)
	RTS

; *** more useful routines ***
i2stop:						; *** generic send STOP condition ***
	LDA #SDA
	TRB IO9rtc				; clear SDA, prepare for STOP condition
	JSR delay				; timing!
	LDA #SCL
	TSB IO9rtc				; set SCL
	JSR clk_str				; clock stretching and timing!
	LDA #SDA
	TSB IO9rtc				; low-to-high transition in SDA while SCL is high, is STOP condition
;	BRA arbitr				; after delay, check for arbitration and return
#echo no stop arb
	JMP delay				; in case of no arbitration check

arbitr:						; *** check if arbitration is lost ***
	BIT IO9rtc				; check I2C_D
	BMI st_ok				; if zero, arbitration lost
		LDA #$22			; red
;#echo no arb
		BRA error			; display and halt
st_ok:
	RTS

i2start:					; *** generic set START condition ***
	LDA #SDA
	TSB IO9rtc				; set SDA
	JSR delay				; ensure timing!
	LDA #SCL
	TSB IO9rtc				; set SCL
	JSR clk_str				; clock stretching! and right timing!
#echo no start arb
;	JSR arbitr				; check if arbitration was lost
	LDA #SDA
	TRB IO9rtc				; high-to-low SDA is START condition
	JSR delay				; timing!
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
	LDA #$11				; timeout is mid green
		BRA error			; display and halt
clk_ok:
	RTS

error:						; *** display colour band and halt ***
	LDX #0
err_l:
		STA $7200, X		; fill part of screen
		INX
		BNE err_l
	BRK						; halt!

; ***********************************
; *** interrupt handler (for BRK) ***
; ***********************************
isr:
	PHA						; let's do things right...
	PHX
	TSX
	LDA $0103, X			; stored P
	AND #$10				; B flag EEEEEK
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

; ***************************
; * print BCD value in byte *
; **************************
; input
;	A		BCD byte
;	X		group offset (0=hours, 1=minutes, 2=seconds)
bcd_prn:
	TAY						; keep value while address is computed
	LDA #POS_H				; check base address for this group
	STA ptr+1				; store base pointer
	LDA pos_l, X
	STA ptr
	TYA
	PHA						; whole byte must be kept
	LSR
	LSR
	LSR
	LSR						; keep high nibble for now
	JSR bcd_disp			; display it
	LDA #POS_H				; recheck base address for this group
	STA ptr+1				; store base pointer
	LDA pos_l, X
	CLC
	ADC #2					; next figure is two bytes to the right
	STA ptr
	PLA						; retrieve full byte...
	AND #$F					; ...but keep LSN only, display and return
;	BRA bcd_disp

; * single number printing *
; input
;	A		BCD nibble
;	ptr		base address
bcd_disp:
	PHX						; for safe operation of caller
	ASL						; two bytes per raster
	TAX						; first raster address
	LDY #0
n_rast:
			LDA numbers, X
			EOR #$FF
			AND #BACKGROUND
			STA rcvd		; keep background nibble
			LDA numbers, X
			AND #COLOUR		; foreground pixels
			ORA rcvd		; mix
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
	PLX						; restore status!
	RTS
code_end:

; ********************
; *** diverse data ***
; ********************
pos_l:
	.byt	$18, $1E, $24	; horizontal positions of groups, somewhat centered
numbers:
	.bin	0, 0, "../../columns/art/numbers.sv20"	; generic number images, 20-byte wide
file_end:
