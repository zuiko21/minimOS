; RTC test via the I2C inteface on FastSPI card
; (c) 2024 Carlos J. Santisteban
; last modified 20241015-0934

; send as binary blob via nanoBoot (-x 0x1000 option)

; *** constants ***
#define	SCL		%00010000
#define	SDA		%00100000
#define	I2C_C	%01000000
#define	I2C_D	%10000000
#define	A_SPI	%00001111
#define	RTC		$68

; *** hardware addresses ***
IO9rtc	= $DF97			; I2C port on FastSPI card

; *** memory allocation ***
i2str	= $FE			; global started condition

; ******************
; *** code start ***
; ******************
	*	= $1000

start:
 	LDA #A_SPI
	STA IO9rtc			; disable all SPI ports, just in case

; **************************
; *** interface routines ***
; **************************
i2send:				; *** send byte in A to address in X ***
	STZ i2str		; clear started condition
	PHA				; store date for later
	TXA				; retrieve address
	ASL				; put 0 at d0 as is a write operation
	JSR i2write		; send this byte in A
	PLA				; get stored data
;	BRA i2write		; and write data afterwards
i2write:			; *** raw byte in A sent thru I2C ***
	TAX				; save for later
; set start condition ***
	BIT i2str		; already started?
	BPL no_str		; if so, do restart
		LDA #SDA
		TSB IO9rtc	; set SDA
		LDA #SCL
		TSB IO9rtc	; set SCL
		JSR clk_str	; clock stretching!
no_str:
	JSR arbitr		; check if arbitration was lost
	LDA #SDA
	TRB IO9rtc		; high-to-low SDA is START condition
	DEC i2str		; dangerously set as started... and some delay as requested
	LDA #SCL
	TRB IO9rtc		; clear SCL as well
; end of start condition ***
	LDY #8			; number of bits per byte
is_loop:
		TXA			; get remaining bits
		ASL			; shift MSB out
		TAX			; keep current state
		LDA #SCL
		TRB IO9rtc	; clock goes low, may change data
		LDA #SDA
		BCS was_one	; if C is set, bit was 1
			TRB IO9rtc			; otherwise will set SDA bit low
		BRA sda_set
was_one:
		TSB IO9rtc				; in this case, SDA goes high
sda_set:
		LDA #SCL
		TSB IO9rtc	; SCL goes high, data bit is sampled
		DEY			; one bit less
		BNE is_loop
; check ACK * * * T B D * * *
	RTS				; this does NOT send stop bit

i2receive:			; *** receive byte in A from address in X ***
	TXA				; retrieve address
	SEC				; carry on...
	ROL				; ...put 1 at d0 as is a write operation
	JSR i2write		; send this byte in A
;	BRA i2read		; and read byte afterwards
i2read:				; *** raw read into A from I2C ***

; also check ACK, but if NACK received, jump to STOP

i2stop:				; *** generic send STOP condition ***
	LDA #SDA
	TRB IO9rtc		; SDA goes low, prepare for STOP condition
	LDA #SCL
	TSB IO9rtc		; SCL goes high
	JSR clk_str		; clock stretching
	LDA #SDA
	TSB IO9rtc		; low-to-high transition in SDA while SCL is high, is STOP condition
	STZ i2str		; no longer started
;	JMP arbitr		; after delay, check for arbitration and return
;	RTS

; *** check if arbitration is lost ***
arbitr:
	BIT IO9rtc		; check SDA
	BMI st_ok
		BRK			; if zero, arbitration lost
st_ok:
	RTS

; *** check for clock stretching with timeout ***
clk_str:
