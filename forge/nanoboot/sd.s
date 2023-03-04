; Durango-X devcart SD loader
; (c) 2023 Carlos J. Santisteban
; based on code from http://www.rjhcoding.com/avrc-sd-interface-1.php and https://en.wikipedia.org/wiki/Serial_Peripheral_Interface
; last modified 20230304-1044

; to be included into nanoboot ROM

#define	SD_CLK		%00000001
#define	SD_MOSI		%00000010
#define	SD_CS		%00000100
#define	SD_MISO		%10000000

#define	CMD0		0
#define	CMD0_ARG	$00000000
#define	CMD0_CRC	$94
#define	CMD8		8
#define	CMD8_ARG	$01AA
#define	CMD8_CRC	$86
#define	CMD55		55
#define	CMD55_ARG	0
#define	CMD55_CRC	0

sdmain:
; draw SD logo?

; ** SD_init is inlined here... **
; ** ...as is SD_powerUpSeq **
	LDA #SD_CS				; CS bit
	TSB IOCart				; CS_DISABLE();
	LDX #36					; ** may substitute SD logo load for this delay **
sdpu_dl:
		NOP
		INX
		BNE sdpu_dl			; delayMicroseconds(1000);
	LDX #9					; for (u_int8_t i = 0; i < 10; i++)		; one less as cs_disable sends another byte
sd80c:
		LDA #$FF
		JSR spi_tr			; SPI_transfer(0xFF);
		DEX
		BNE sd80c			; this sends 80 clocks to synchronise
	JSR cs_disable

; command card to idle
	LDX #10
set_idle:
; ** SD_goIdleState is inlined here **
		JSR cs_enable		; assert chip select
; send CMD0
		STZ arg
		STZ arg+1
		STZ arg+2
		STZ arg+3			; ** assume CMD0_ARG is 0 *
		LDA #$CMD0_CRC
		STA crc
		LDA #CMD0
		JSR sd_cmd			; SD_command(CMD0, CMD0_ARG, CMD0_CRC);
; read response
		JSR rd_r1			; u_int8_t res1 = SD_readRes1();
		JSR cs_disable		; deassert chip select

; continue set_idle loop
		LDA res
		CMP #1
	BEQ is_idle				; while((res[0] = SD_goIdleState()) != 0x01)
		DEX					; cmdAttempts++;
		BNE set_idle
	JMP sd_fail				; if(cmdAttempts > 10)	return SD_ERROR;
is_idle:
; ** SD_sendIfCond is inlined here **
	JSR cs_enable			; assert chip select
; send CMD8
	STZ arg
	STZ arg+1
	LDA #>CMD8_ARG
	STA arg+2
	LDA #<CMD8_ARG
	STA arg+3
	LDA #CMD8_CRC
	STA crc
	LDA #CMD8
	JSR sd_cmd				; SD_command(CMD8, CMD8_ARG, CMD8_CRC);
; read response
	JSR rd_r7				; SD_readRes7(res);
	JSR cs_disable			; deassert chip select

	LDA res
	CMP #1
	BEQ sdic_ok
sdptec:
		JMP sd_fail			; if(res[0] != 0x01) return SD_ERROR;
sdic_ok:
; check pattern echo
	LDA res+4
	CMP #$AA
		BNE sdptec			; if(res[4] != 0xAA) return SD_ERROR;
; attempt to initialize card
	LDX #101				; cmdAttempts = 0;
sd_ia:
; send app cmd
		JSR sd_app			; res[0] = SD_sendApp();
; if no error in response
		CMP #2
		BCC sa_err
			JSR sd_soc		; if(res[0] < 2)	res[0] = SD_sendOpCond();
sa_err:
		LDA res				; actually needed in case of error
	BEQ apc_rdy				; while(res[0] != SD_READY);
; wait 10 ms
		LDA #12
d10m:
				INY
				BNE d10m
			DEC
			BNE d10m		; delayMicroseconds(10000);
		DEX					; cmdAttempts++;
		BNE sd_ia
	JMP sd_fail				; if(cmdAttempts > 100) return SD_ERROR;
apc_rdy:

; read OCR
; SD_readOCR(res);

; check whether card is ready
	LDA res
	BPL card_rdy
		JMP sd_fail			; if(!(res[1] & 0x80)) return SD_ERROR;
card_rdy:					; * SD_init OK! *

; ** load 64 sectors from SD **

; ** after image is loaded... **
	JMP switch				; start RAM-loaded code!

; ************************
; *** support routines ***
; ************************

; *** send data in A, return received data in A *** nominally ~4.4 kiB/s
spi_tr:
	STA mosi
	LDY #8					; x = 8;
	LDA #SD_CLK
	TRB IOCart				; digitalWrite(SCK, 0);
tr_l:						; while (x)
		ASL mosi
		LDA IOCart
		AND #~SD_MOSI
		BCC mosi_set
			ORA #SD_MOSI
mosi_set:
		STA IOCart			; digitalWrite(MOSI, data & 128); data <<= 1;
		INC IOCart			; digitalWrite(SCK, 1);	** assume SD_CLK  is   1 **
		ASL					; in <<= 1;				** assume SD_MISO is $80 **
		ROL miso			; if(digitalRead(MISO)) in++;
		DEC IOCart			; digitalWrite(SCK, 0);	** assume SD_CLK  is   1 **
		DEY					; x--;
		BNE tr_l
	LDA miso				; return in;
	RTS

; *** enable card transfer ***
cs_enable:
	LDA #$FF
	JSR spi_tr				; SPI_transfer(0xFF);
	LDA #SD_CS
	TRB IOCart				; CS_ENABLE();
	LDA #$FF
	JMP spi_tr				; SPI_transfer(0xFF); ...and return

; *** disable card transfer ***
cs_disable:
	LDA #$FF
	JSR spi_tr				; SPI_transfer(0xFF);
	LDA #SD_CS
	TSB IOCart				; CS_DISABLE();
	LDA #$FF
	JMP spi_tr				; SPI_transfer(0xFF); ...and return

; *** send command in A to card *** arg.l, crc.b
sd_cmd:
; send command header
	ORA #$40
	JSR spi_tr				; SPI_transfer(cmd|0x40);
; send argument
	LDA arg
	JSR spi_tr				; SPI_transfer((u_int8_t)(arg >> 24));
	LDA arg+1
	JSR spi_tr				; SPI_transfer((u_int8_t)(arg >> 16));
	LDA arg+2
	JSR spi_tr				; SPI_transfer((u_int8_t)(arg >> 8));
	LDA arg+3
	JSR spi_tr				; SPI_transfer((u_int8_t)(arg));
; send CRC
	LDA crc
	ORA #1
	JMP spi_tr				; SPI_transfer(crc|0x01); ...and return

; *** send app command in A to card ***
sd_app:
	JSR cs_enable			; assert chip select
; send CMD55
	STZ arg
	STZ arg+1
	STZ arg+2
	STZ arg+3
	STZ crc					; ** assume CMD55_ARG and CMD55_CRC are 0 **
	LDA #CMD55
	JSR sd_cmd				; SD_command(CMD55, CMD55_ARG, CMD55_CRC);
; read response
	JSR rd_r1				; u_int8_t res1 = SD_readRes1();
	JSR cs_disable			; deassert chip select
	LDA res					; return res1;
	RTS

; *** read R1 response *** return result in res and A
rd_r1:
	LDX #8					; u_int8_t i = 0, res1;
; keep polling until actual data received
r1_l:
		LDA #$FF
		JSR spi_tr
		CMP #$FF
	BNE r1_got				; while((res1 = SPI_transfer(0xFF)) == 0xFF)
		DEX					; i++;
		BNE r1_l			; if(i > 8) break;
r1_got:
	STA res					; return res1; (also in A)
	RTS

; *** read R7 response *** return result in res[]
rd_r7:
	JSR rd_r1				; res[0] = SD_readRes1();
	CMP #2
	BCS r7end				; if(res[0] > 1) return; {in case of error}
; read remaining bytes
		LDX #1
r7loop:
			LDA #$FF
			JSR spi_tr
			STA res, X		; res[ X ] = SPI_transfer(0xFF);
			INX
			CPX #5
			BNE r7loop
r7end:
	RTS

; ***************************
; *** standard exit point ***
; ***************************
sd_fail:					; SD card failed, try nanoBoot instead
; could make a beep here and wait for a second
