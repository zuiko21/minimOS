; RTC test via the I2C inteface on FastSPI card
; (c) 2024 Carlos J. Santisteban
; last modified 20241015-1814

; send as binary blob via nanoBoot (-x 0x1000 option)

; *** constants ***
#define	SCL		%00010000
#define	SDA		%00100000
#define	I2C_C	%01000000
#define	I2C_D	%10000000
#define	A_SPI	%00001111
#define	RTC		$68

; *** hardware addresses ***
IO8attr	= $DF80
IO9rtc	= $DF97				; I2C port on FastSPI card
IOAie	= $DFA0

; *** memory allocation *** needs two bytes, not necessarily on ZP
#ifdef	I2C_LOCAL
i2str	= I2C_LOCAL
#else
i2str	= $FE				; global started condition
ptr		= i2str				; temporary pointer
#endif
i2time	= i2str+1			; timeout counter

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
	LDA #$EE				; fill with fuchsia
cls_pg:
		STX ptr+1			; update page
cls_l:
			STA (ptr), Y
			INY
			BNE cls_l
		INX
		BPL cls_pg			; usual fill screen
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
	PLA						; get stored data
;	JMP i2write				; and write data afterwards

i2write:					; *** raw byte in A sent thru I2C ***
	TAX						; save for later
	JSR i2start				; set START condition
	LDY #8					; number of bits per byte
is_loop:
		TXA					; get remaining bits
		ASL					; shift MSB out
		TAX					; keep current state
		LDA #SCL
		TRB IO9rtc			; clock goes low, may change data
		LDA #SDA
		BCS was_one			; if C is set, bit was 1
			TRB IO9rtc		; otherwise will set SDA bit low
		BRA sda_set
was_one:
		TSB IO9rtc			; in this case, SDA goes high
sda_set:
		LDA #SCL
		TSB IO9rtc			; SCL goes high, data bit is sampled
		DEY					; one bit less
		BNE is_loop
; check ACK * * * T B D * * *
	RTS						; this does NOT send stop bit

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

i2receive:					; *** receive byte in A from address in X ***
	TXA						; retrieve address
	SEC						; carry on...
	ROL						; ...put 1 at d0 as is a write operation
	JSR i2write				; send this byte in A
;	BRA i2read				; and read byte afterwards
i2read:						; *** raw read into A from I2C ***

; also check ACK, but if NACK received, jump to STOP

i2stop:						; *** generic send STOP condition ***
	LDA #SDA
	TRB IO9rtc				; SDA goes low, prepare for STOP condition
	JSR delay				; timing!
	LDA #SCL
	TSB IO9rtc				; SCL goes high
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

; *** check for clock stretching with timeout (~25 ms, standard overhead is 22t) ***
clk_str:
	STZ i2time		; reset timeout counter (base loop is 342*256=87552t, 25.04 mS at least, up to 57)
str_l:
		BIT IO9rtc	; check I2C_C (4)
	BVS clk_ok		; already high, all OK (2)
		PHY			; best here (3)
		LDY #64		; inner iterations (2)
str_il:
			DEY		; inner loop (5*64-1=319)
			BNE str_il
		PLY			; (4)
		INC i2time	; otherwise increment counter (5 or 6)
		BNE str_l	; (3)
	BRK				; until timeout!
clk_ok:
	RTS

; *** interrupt handler (for BRK) ***
isr:
	PHA						; let's do things right...
	PHX
	TSX
	LDA $0103, X			; stored P
	AND $10					; B flag
	BEQ exit				; not BRK, restore
				INX
				BNE isr
			INY
			BNE isr			; usual delay
		INC
		STA IOAie			; will toggle error LED
		BRA isr				; forever
exit:
	PLX						; restore status and return
	PLA
	RTI
