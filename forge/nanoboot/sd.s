; Durango-X devcart SD loader
; (c) 2023 Carlos J. Santisteban
; based on code from http://www.rjhcoding.com/avrc-sd-interface-1.php and https://en.wikipedia.org/wiki/Serial_Peripheral_Interface
; last modified 20230304-0040

; to be included into nanoboot ROM

sdmain:
; draw SD logo?

; * SD_init is inlined here... *
; ...as is SD_powerUpSeq
	LDA #SD_CS				; CS bit
	TSB IOCart				; CS_DISABLE();
	LDX #36
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
sdid_l:
; sd_idle is inlined here
		JSR cs_enable		; assert chip select
		
; send CMD0
; SD_command(CMD0, CMD0_ARG, CMD0_CRC);

; read response
; u_int8_t res1 = SD_readRes1();

		JSR cs_disable		; deassert chip select

; continue set_idle loop
		LDA res
		CMP #1
	BEQ sdid_is				; while((res[0] = SD_goIdleState()) != 0x01)
		DEX					; cmdAttempts++;
		BNE sdid_l
	JMP sd_fail				; if(cmdAttempts > 10)	return SD_ERROR;
sdid_is:
; SD_sendIfCond is inlined here

	JSR cs_enable			; assert chip select

; send CMD8
; SD_command(CMD8, CMD8_ARG, CMD8_CRC);

; read response
; SD_readRes7(res);

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
; res[0] = SD_sendApp();

; if no error in response
; if(res[0] < 2)	res[0] = SD_sendOpCond();

		LDA res
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

; *** send data in A, return received data in A ***
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

; ***************************
; *** standard exit point ***
; ***************************
sd_fail:					; SD card failed, try nanoBoot instead
; could make a beep here and wait for a second
