; Durango-X devcart SD loader
; (c) 2023 Carlos J. Santisteban
; based on code from http://www.rjhcoding.com/avrc-sd-interface-1.php and https://en.wikipedia.org/wiki/Serial_Peripheral_Interface
; last modified 20230308-2354

; to be included into nanoboot ROM

#define	SD_CLK		%00000001
#define	SD_MOSI		%00000010
#define	SD_CS		%00000100
#define	SD_MISO		%10000000

#define	CMD0		0
#define	CMD0_ARG	0
#define	CMD0_CRC	$94
#define	CMD8		8
#define	CMD8_ARG	$01AA
#define	CMD8_CRC	$86
#define	ACMD41		41
#define	ACMD41_ARG	$40
#define	ACMD41_CRC	0
#define	CMD55		55
#define	CMD55_ARG	0
#define	CMD55_CRC	0
#define	CMD58		58
#define	CMD58_ARG	0
#define	CMD58_CRC	0

#define	CMD17		17
#define	CMD17_CRC	0
#define	SD_MAX_READ_ATTEMPTS	203

#define	IOCart		$DFC0
#define	logo		$6000

; *** memory usage ***
crc		= $EF
arg		= crc + 1	; $F0
res		= arg + 4	; $F4
mosi	= res + 5	; $F9
miso	= mosi + 1	; $FA
token	= miso + 1	; $FB
ptr		= token + 1	; $FC
;cnt	= ptr + 2	; $FE

; **********************
; *** SD-card module ***
; **********************
sdmain:
.(
; ** SD_init is inlined here... **
; ** ...as is SD_powerUpSeq **
	LDA #SD_CS				; CS bit
	TSB IOCart				; CS_DISABLE();
;	LDX #36					; ** may substitute SD logo load for this delay **
;sdpu_dl:
;		NOP
;		INX
;		BNE sdpu_dl			; delayMicroseconds(1000);
; * display SD logo here, works as a delay *
	LDX #>sd_logo
	LDY #<sd_logo
	STY res					; temporary source pointer
	STX res+1
	LDX #>logo
	LDY #<logo
	STY ptr					; should be zero
logo_p:
		STX ptr+1
logo_l:
			LDA (res), Y
			STA (ptr), Y		; copy image data
			INY
			BNE logo_l
		INC res+1			; next source page
		INX					; next pointer page
		CPX #$6B			; 11 pages = 44 lines
		BNE logo_p
; continue with powerup sequence
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
		LDA #CMD0_CRC
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
	LDX #0					; *** ERROR 0 in red ***
	JMP sd_fail				; if(cmdAttempts > 10)	return SD_ERROR;
is_idle:
	LDX #0					; eeeek
	JSR pass_x				; *** PASS 0 in white ***
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
		LDX #1				; *** ERROR 1 in red ***
sdptec:
		JMP sd_fail			; if(res[0] != 0x01) return SD_ERROR;
sdic_ok:
	LDX #1					; eeeeeek
	JSR pass_x				; *** PASS 1 in white ***
; check pattern echo
	LDX #2					; *** ERROR 2 in red ***
	LDA res+4
	CMP #$AA
		BNE sdptec			; if(res[4] != 0xAA) return SD_ERROR;
	JSR pass_x				; *** PASS 2 in white ***
; attempt to initialize card
	LDX #101				; cmdAttempts = 0;
sd_ia:
; send app cmd
; ** res[0] = SD_sendApp() inlined here **
		JSR cs_enable		; assert chip select
; send CMD55
		STZ arg
		STZ arg+1
		STZ arg+2
		STZ arg+3
		STZ crc				; ** assume CMD55_ARG and CMD55_CRC are 0 **
		LDA #CMD55
		JSR sd_cmd			; SD_command(CMD55, CMD55_ARG, CMD55_CRC);
; read response
		JSR rd_r1			; u_int8_t res1 = SD_readRes1();
		JSR cs_disable		; deassert chip select
		LDA res				; return res1;

; if no error in response
		CMP #2
		BCS sa_err			; if(res[0] < 2)	eeeeeeeeek
; ** res[0] = SD_sendOpCond() inlined here **
			JSR cs_enable	; assert chip select
; send CMD55
			LDA #ACMD41_ARG	; only MSB is not zero
			STA arg
			STZ arg+1
			STZ arg+2
			STZ arg+3
			STZ crc			; ** assume rest of ACMD41_ARG and ACMD41_CRC are 0 **
			LDA #ACMD41
			JSR sd_cmd		; SD_command(ACMD41, ACMD41_ARG, ACMD41_CRC);
; read response
			JSR rd_r1		; u_int8_t res1 = SD_readRes1();
			JSR cs_disable	; deassert chip select
sa_err:
		LDA res				; return res1; (needed here in case of error)
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
	LDX #3					; *** ERROR 3 in red ***
	JMP sd_fail				; if(cmdAttempts > 100) return SD_ERROR;
apc_rdy:
	LDX #3
	JSR pass_x				; *** PASS 3 in white ***
; read OCR
; ** SD_readOCR(res) is inlined here **
	JSR cs_enable			; assert chip select
; send CMD58
	STZ arg
	STZ arg+1
	STZ arg+2
	STZ arg+3
	STZ crc					; ** assume CMD58_ARG and CMD58_CRC are 0 **
	LDA #CMD58
	JSR sd_cmd				; SD_command(CMD58, CMD58_ARG, CMD58_CRC);
; read response
	JSR rd_r7				; SD_readRes7(res); actually R3
	JSR cs_disable			; deassert chip select

; check whether card is ready
	LDX #4					; *** ERROR 4 in red ***
	LDA res+1				; eeeeeeeeek
	BMI card_rdy			; eeeeeeeeek
		JMP sd_fail			; if(!(res[1] & 0x80)) return SD_ERROR;
card_rdy:					; * SD_init OK! *
	JSR pass_x				; *** PASS 4 in white ***

; ** load 64 sectors from SD **
	LDX #>$8000				; ROM start address
	STX ptr+1
	STZ ptr					; assume ROM is page-aligned, of course
	STZ arg
	STZ arg+1
	STZ arg+2
	STZ arg+3				; assume reading from the very first sector
boot:
		JSR ssec_rd			; read one 512-byte sector
; might do some error check here...
		LDX ptr+1			; current page (after switching)
		LDA #$FF			; elongated white dots
		STA $7EFE, X
		STA $7EFF, X		; display on screen (finished pages)
		INC arg+3			; only 64 sectors, no need to check MSB... EEEEEEEEK endianness!
		TXA					; LDA ptr+1		; check current page
		BNE boot			; until completion
; ** after image is loaded... **
	JMP switch				; start code loaded into cartidge RAM!

; ************************
; *** support routines ***
; ************************

; *** send data in A, return received data in A *** nominally ~4.4 kiB/s
spi_tr:
	STA mosi
	LDY #8					; x = 8;
	LDA #SD_CLK
	TRB IOCart				; digitalWrite(SCK, 0); (13t)
tr_l:						; while (x)
		ASL mosi
		LDA IOCart
		AND #SD_MOSI^$FF
		BCC mosi_set
			ORA #SD_MOSI
mosi_set:
		STA IOCart			; digitalWrite(MOSI, data & 128); data <<= 1;
		INC IOCart			; digitalWrite(SCK, 1);	** assume SD_CLK  is   1 **
		ASL					; in <<= 1;				** assume SD_MISO is $80 **
		ROL miso			; if(digitalRead(MISO)) in++;
		DEC IOCart			; digitalWrite(SCK, 0);	** assume SD_CLK  is   1 **
		DEY					; x--;
		BNE tr_l			; (worst case, 8*43 = 344t)
	LDA miso				; return in; (total including call overhead = 372t, ~242 µs)
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

; *** read R1 response *** return result in res and A
rd_r1:
	PHX						; eeeeeeeek
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
	PLX
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

; *** read single sector ***
; ptr MUST be even, NOT starting at $DF00 and certainly (two) page-aligned
ssec_rd:
; set token to none
	LDA #$FF
	STA token				; *token = 0xFF;
	JSR cs_enable			; assert chip select
; send CMD17 (sector already at arg.l)
	STZ crc					; ** assume CMD17_CRC is 0 **
	LDA #CMD17
	JSR sd_cmd				; SD_command(CMD17, sector, CMD17_CRC);
; read response
	JSR rd_r1				; res1 = SD_readRes1();
	CMP #$FF
	BEQ no_res				; if(res1 != 0xFF) {
; if response received from card wait for a response token (timeout = 100ms)
		LDX #SD_MAX_READ_ATTEMPTS		; readAttempts = 0;
rd_wtok:
			DEX
		BEQ chk_tok			; while(++readAttempts != SD_MAX_READ_ATTEMPTS)
			LDA #$FF
			JSR spi_tr
			CMP #$FF
		BNE chk_tok			; this is done twice for a single-byte timeout loop
			LDA #$FF
			JSR spi_tr
			CMP #$FF
			BEQ rd_wtok		; if((read = SPI_transfer(0xFF)) != 0xFF)		break; (759t ~494µs)
chk_tok:
		STA res				; read = ...
		CMP #$FE
		BNE set_tk			; if(read == 0xFE) {
; read 512 byte block
block:
			LDX #0			; 256-times loop reading 2-byte words => 512 bytes/sector
byte_rd:					; for(u_int16_t i = 0; i < 512; i++) {
				LDA #$FF
				JSR spi_tr
				STA (ptr)	; *buf++ = SPI_transfer(0xFF);
				INC ptr		; won't do any page crossing here, as long as the base address is EVEN
				LDA #$FF
				JSR spi_tr
				STA (ptr)	; *buf++ = SPI_transfer(0xFF);
				INC ptr
				BNE brd_nw
					INC ptr+1
; must skip I/O page! eeeeeek
					LDA ptr+1
					CMP #$DF			; already at I/O page?
					BEQ io_skip
brd_nw:
				INX
				BNE byte_rd	; ... i < 512; i++)
; discard 16-bit CRC
rd_crc:
			LDA #$FF
			JSR spi_tr		; SPI_transfer(0xFF);
			LDA #$FF
			JSR spi_tr		; SPI_transfer(0xFF);
			LDA res			; ... = read
set_tk:
; set token to card response
		STA token			; *token = read;
no_res:
	JSR cs_disable			; deassert chip select
	LDA res					; return res1;
	RTS
; * special code for I/O page skipping *
io_skip:
		LDA #$FF
		JSR spi_tr			; get one byte for $DF00-$DF7F, as per Emilio's request
		STA (ptr)			; ptr originally pointing to $DF00
		INC ptr				; no page crossing in the first half
		BPL io_skip			; this will fill the accesible area at page $DF (up to $DF7F)
io_dsc:
		LDA #$FF
		JSR spi_tr			; discard one byte
		INC ptr
		BNE io_dsc			; until the end of page
	INC ptr+1				; continue from page $E0
	BNE rd_crc				; current sector actually ended EEEEK

; *** display pass code ***
pass_x:
	LDA #$FF				; white dots (will clear left half upon error)
	STA $6AB0, X
	RTS

; ********************
; *** diverse data ***
; ********************
sd_logo:
	.dsb	64, 0			; padding for 44-line, 11-page image
	.bin	0, 0, "sd.sv"	; uncompressed 128x42 picture
	.dsb	64, 0			; padding for 44-line, 11-page image
grey:
	.dsb	64, $F0
	.dsb	64, 0
	.dsb	64, $0F
	.dsb	64, 0
;	.dsb	64, $F0
;	.dsb	64, $0F

; ***************************
; *** standard exit point ***
; ***************************
sd_fail:					; SD card failed, try nanoBoot instead
	LDA #$02				; red dot
	STA $6AB0, X
; grey out logo
	LDX #>logo
	LDY #<logo
	STY ptr					; should be zero
grey_p:
		STX ptr+1
grey_l:
			LDA (ptr), Y
			AND grey, Y		; put pattern on image
			STA (ptr), Y
			INY
			BNE grey_l
		INX					; next pointer page
		CPX #$6B			; 11 pages = 44 lines
		BNE grey_p
end_sd:
.)
