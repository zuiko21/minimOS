; RTC test via the I2C inteface on FastSPI card
; (c) 2024 Carlos J. Santisteban
; last modified 20241021-1838

; send as binary blob via nanoBoot (-x 0x1000 option)

; *** constants ***
; bit-banging interface
#define	SCL		%00010000
#define	SDA		%00100000
#define	I2C_C	%01000000
#define	I2C_D	%10000000
#define	A_SPI	%00111111
; RTC I2C address
#define	RTC_I	$68
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

; *** hardware addresses ***
IO8attr	= $DF80
IO9rtc	= $DF97				; I2C port on FastSPI card
IOAie	= $DFA0

; *** memory allocation *** needs nine bytes, not necessarily on ZP
#ifdef	I2C_LOCAL
i2str	= I2C_LOCAL
#else
i2str	= $F7				; global started condition
#endif

ptr		= i2str				; temporary pointer
i2time	= i2str+1			; timeout counter
i2nak	= i2time+1			; NAK at d7
nak1st	= i2nak+1			; NAK to be sent after first byte reception
temp	= nak1st+1			; temporary var EEEK
result	= temp+1			; stored time
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
; *** I2C-RTC test suite ***
start:
	LDA #A_SPI
	STA IO9rtc				; disable all SPI ports, just in case
; set address register to seconds, for the CH bit
	LDX #RTC_I				; select device address
	LDA #DS_S				; select seconds to access CH bit
	JSR i2send				; this will set address register, no further writes
	JSR i2stop				; end of this transfer
; read seconds register
	LDA #$FF				; next will be NAK
	STA nak1st				; single-byte reception
	LDX #RTC_I				; select device address
	JSR i2receive			; get first byte [0] and send STOP afterwards
#echo addr+rcv1
brk
; clear CH bit and resend register
	AND #$7F				; make sure bit 7 (CH) is clear
	PHA						; keep register value eeeeek
	LDX #RTC_I				; another transfer
	LDA #DS_S				; seconds to access CH bit
	JSR i2send				; write both device and register addresses
	PLA						; retrieve actual register value
	JSR i2write				; write it
	JSR i2stop				; both addresses and data have been transferred
clock:
; first of all, select address of seconds (first) register
		LDX #RTC_I			; select address
		LDA #DS_S			; seconds to access CH bit
		JSR i2send			; this will set address register, no further writes
		JSR i2stop			; end of this transfer
; now copy the current values
; first of all, selected byte
		STZ nak1st			; multi-byte reception
		LDX #RTC_I			; select address
		JSR i2receive		; set device and get first byte [0]
		STA result+2		; will be stored reversed!
; now go for the remaining bytes (not worth a loop)
		JSR i2read
		STA result+1
		DEC i2nak			; third and last byte
		JSR i2read			; this will send STOP as well
		STA result
; if something changed, display time
		LDA result+2		; check seconds
		CMP olds			; same as before?
;#echo cont display
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
i2send:						; *** send byte in A to address in X ***
	STZ i2str				; clear started condition
	PHA						; store date for later EEEEEK
	JSR i2start				; set START condition, here?
	TXA						; retrieve address
	ASL						; put 0 at d0 as is a write operation
	JSR i2write				; send this byte in A
; might check for NAK here...
	PLA						; get stored data
;	BRA i2write				; and write data afterwards

i2write:					; *** raw byte in A sent thru I2C ***
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
	JSR r_bit				; read bit (NAK) into C
	ROR i2nak				; store flag (d7)
	RTS						; just end, check NAK afterwards and send STOP if needed

i2receive:					; *** receive byte in A from address in X ***
	TXA						; retrieve address
	SEC						; carry on...
	ROL						; ...put 1 at d0 as is a write operation
	JSR i2write				; send this byte in A
; might check for NAK here...
	LDA nak1st				; ...but determine whether it's a single byte transfer
	STA i2nak
;	BRA i2read				; and read byte afterwards

i2read:						; *** raw read into A from I2C, sending ACK/NAK afterwards ***
	LDA #1					; note trick to activate C upon full byte reception
	STA temp				; reset received byte
ir_loop:
		JSR r_bit			; read single bit into C...
		ROL temp			; inject received bit
		BCC ir_loop			; until that C appears!
; send ACK or NAK, accordingly
	LDA i2nak				; get flag (d7)
	ASL						; now into C
	JSR w_bit				; send ACK/NAK
	BIT i2nak				; recheck NAK
	BPL no_stop
		JSR i2stop			; if NAK, send STOP too... but finish reading afterwards!
no_stop:
	LDA temp				; return received byte EEEEEEEEEEEEEEK
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
	STZ i2str				; no longer started
;	BRA arbitr				; after delay, check for arbitration and return
#echo no stop arb
rts

arbitr:						; *** check if arbitration is lost ***
	BIT IO9rtc				; check I2C_D
	BMI st_ok				; if zero, arbitration lost
		LDA #$22			; red
;#echo no arb
		BRA error			; display and halt
st_ok:
	RTS

i2start:					; *** generic set START condition ***
#echo no restart
;	BIT i2str				; already started?
;	BPL no_str				; if so, do restart
		LDA #SDA
		TSB IO9rtc			; set SDA
		JSR delay			; ensure timing!
		LDA #SCL
		TSB IO9rtc			; set SCL
		JSR clk_str			; clock stretching! and right timing!
no_str:
;	JSR arbitr				; check if arbitration was lost
	LDA #SDA
	TRB IO9rtc				; high-to-low SDA is START condition
	DEC i2str				; dangerously set as started... and some delay as requested
	NOP: LDA i2str			; timing!
	LDA #SCL
	TRB IO9rtc				; clear SCL as well
delay:
	RTS

; *** write single bit from C ***
w_bit:
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
#echo no write arb
;		BCC no_arb			; if bit is ZERO, do not check arbitration
;			JSR arbitr
no_arb:
		LDA #SCL
		TRB IO9rtc			; clear SCL
	RTS

; *** read single bit into C ***
r_bit:
		LDA #SDA
		TSB IO9rtc			; set SDA
		JSR delay			; timing!
		LDA #SCL
		TSB IO9rtc			; set SCL
		JSR clk_str			; stretching
		LDA IO9rtc			; read SDA...
		ASL					; ...and store it in C!
		LDA #SCL
		TRB IO9rtc			; clear SCL (should not affect C)
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
