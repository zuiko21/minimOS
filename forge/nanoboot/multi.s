; Durango-X devcart SD multi-boot loader
; now with sidecar/fast SPI support
; (c) 2023 Carlos J. Santisteban
; based on code from http://www.rjhcoding.com/avrc-sd-interface-1.php and https://en.wikipedia.org/wiki/Serial_Peripheral_Interface
; last modified 20231027-0027

; assemble from here with		xa multi.s -I ../../OS/firmware 
; add -DSCREEN for screenshots display capability
; add -DTALLY for LED access indicator
; add -DDEBUG if desired

#echo	FastSPI @ $DF96-7, SPI ID=0...3

; SD interface definitions
#define	SD_CLK		%00000001
#define	SD_MOSI		%00000010
#define	SD_CS		%00000100
#define	SD_MISO		%10000000

#define	CMD0		0
#define	CMD0_CRC	$94
#define	CMD8		8
#define	CMD8_ARG	$01AA
#define	CMD8_CRC	$86
#define	CMD16		16
#define	CMD16_ARG	$0200
#define	ACMD41		41
#define	ACMD41_ARG	$40
#define	CMD55		55
#define	CMD58		58

#define	CMD17		17
#define	SD_MAX_READ_ATTEMPTS	203

; error code messages
#define	IDLE_ERR	0
#define	SDIF_ERR	1
#define	ECHO_ERR	2
#define	INIT_ERR	3
#define	READY_ERR	4
#define	OK_MSG		5
#define	FAIL_MSG	6
#define	INVALID_SD	7
#define	SEL_MSG		8
#define	LOAD_MSG	9
#define	PAGE_MSG	10
#define	SPCR_MSG	11
#define	OLD_SD		12
#define	HC_XC		13
#define	SPLASH		14
#define	NX_DEVICE	15
#define	ABORT		16

; *** hardware definitions ***
IO8attr	= $DF80
IO8blk	= $DF88
IO9kbd	= $DF9B				; should be into firmware
IO9nes0	= $DF9C
IO9nlat	= IO9nes0
IO9nes1	= $DF9D
IO9nclk	= IO9nes1
IO9sp_d	= $DF96				; new, Fast SPI data transfer *** NO LONGER $DF9E
IO9sp_c	= $DF97				; new, Fast SPI control       *** NO LONGER $DF9F
IOAie	= $DFA0
IOBeep	= $DFB0
IOCart	= $DFC0
IO_PSG	= $DFDB				; PSG riser port

#define	KBDMAT

; *** memory usage ***
dev_id	= $EB		; $EB 1...4=SPI, 241=devCart, 0=RasPi; will turn into '0...3' and ' ' (and '/') for display
crc		= dev_id+ 1	; $EC
en_ix	= crc	+ 1	; $ED ### directory storage ###
sd_ver	= en_ix	+ 1 ; $EE ### not so temporary ###
arg		= sd_ver+ 1	; $F0-$F3
res		= arg	+ 4	; $F4-$F8
mosi	= res	+ 5	; $F9
miso	= mosi	+ 1	; $FA
token	= miso	+ 1	; $FB
ptr		= token	+ 1	; $FC-$FD
cnt		= ptr	+ 2	; $FE
tmpba	= cnt	- 1	; actually $FE-$FF, as $FD will NOT be used

; *** sector buffer and header pointers ***
buffer	= $400
magic1	= buffer+0			; must contain zero
magic2	= buffer+7			; must contain CR (13)
magic3	= buffer+255		; must contain zero (assume filesize < 16 MiB)
bootsig	= buffer+1			; must contain 'dX' for bootable ROM images
fname	= buffer+8
ftime	= buffer+248		; time in MS-DOS format
fdate	= buffer+250		; date in MS-DOS format
fsize	= buffer+252		; file size INCLUDING 256-byte header

; *** directory storage ***
en_tab		= $300
sig_tab		= $2F0			; NEW, store signature ('X'=executable, 'S'=16-colour screen, 'R'=HIRES screen)

; *** interface vectors ***	NEW for extra SD interfaces
v_spi_tr		= $2EA
v_cs_enable		= $2EC
v_cs_disable	= $2EE


; *****************************************************
; *** firmware & hardware definitions for Durango-X ***
; *****************************************************
fw_irq		= $0200			; ### usual minimOS interrupt vectors ###
fw_nmi		= $0202
ticks		= $0206			; jiffy counter EEEEK
; make room for keyboard driver ($020A-$020F)
; CONIO specific variables
fw_cbin		= $0210			; $210 integrated picoVDU/Durango-X specifics
fw_fnt		= fw_cbin	+1	; $211 (new, pointer to relocatable 2KB font file)
fw_mask		= fw_fnt	+2	; $213 (for inverse/emphasis mode)
fw_chalf	= fw_mask	+1	; $214 (remaining pages to write)
fw_sind		= fw_chalf	+1	; $215
fw_ccol		= fw_sind	+3	; $218 (no longer SPARSE array of two-pixel combos, will store ink & paper)
fw_ctmp		= fw_ccol	+4	; $21C
fw_cbyt		= fw_ctmp		; (temporary glyph storage) other tmp
fw_ccnt		= fw_cbyt		; (bytes per raster counter, no longer X) actually the same tmp
fw_ciop		= fw_ccnt	+1	; $21D cursor position
fw_vbot		= fw_ciop	+2	; $21F page start of screen at current hardware setting (updated upon FF)
fw_vtop		= fw_vbot	+1	; $220 first non-VRAM page (new)
fw_io9		= fw_vtop	+1	; $221 received keypress
fw_scur		= fw_io9	+1	; $222 NEW, cursor control
fw_knes		= fw_scur	+1	; $223 NEW, NES-pad alternative keyboard *** different use here
GAMEPAD_MASK1	= fw_knes		+1		; $224 EEEEEEEEK
GAMEPAD_MASK2	= GAMEPAD_MASK1	+1		; $225 needed for standard gamepad support
gamepad1		= GAMEPAD_MASK2	+1		; "standard" read value at $226
gamepad2		= gamepad1		+1		; "standard" read value at $227
; CONIO zeropage usage ($E4-$E7)
cio_pt		= $E6
cio_src		= $E4

	* = $E000

; ***********************
; *** standard header *** to be found before ANY ROM image
; ***********************
rom_start:
; header ID
	.byt	0				; [0]=NUL, first magic number
	.asc	"dX"			; bootable ROM for Durango-X devCart
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"devCart/FastSPI multiboot"		; C-string with filename @ [8], max 220 chars
#ifdef	SCREEN
	.asc	" & image browser"
#endif
#ifdef	DEBUG
	.asc	" (D", "EBUG version)"
#endif
; note terminator below
; optional C-string with comment after filename, filename+comment up to 220 chars
	.asc	0, 0

; advance to end of header *** NEW format
	.dsb	rom_start + $E6 - *, $FF

; NEW library commit (user field 2)
	.dsb	8, '$'			; unused field
; NEW main commit (user field 1) *** currently the hash BEFORE actual commit on multi.s
	.asc	"$$$$$$$$"
; NEW coded version number
	.word	$11C0			; 1.1f
; date & time in MS-DOS format at byte 248 ($F8)
	.word	$5A00			; time, 11.16		%0101 1-010 000-0 0000
	.word	$5755			; date, 2023/10/21	%0101 011-1 010-1 0101
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$10000-rom_start			; filesize (rom_end is actually $10000)
	.word	0							; 64K space does not use upper 16 bits, [255]=NUL may be third magic number

; **********************
; *** SD-card module ***
; **********************
sd_main:
.(
	LDX #SPLASH
	JSR disp_code			; display splash screen
; select first SD device (devCart) and try
	LDA #241				; devCart ID
	STA dev_id
	LDX #vec_dc_sd-vec_sd	; set vectors for devCart device
vecload:
	LDA dev_id				; get present device ID
	CLC
	ADC #'0'-1				; convert into ASCII (' ' for devCart)
	TAY
	PHX
	JSR conio				; print ID
	PLX						; retrieve vector index and continue
	LDY #0					; worth going upwards
vl_loop:
		LDA vec_sd, X
		STA v_spi_tr, Y		; assume it's first vector!
		PHY					; *** print device name ***
		PHX
		LDY sd_name, X		; get character
		JSR conio
		PLX
		PLY					; restore regs and go for next byte
		INX
		INY
		CPY #6				; number of bytes per entry
		BNE vl_loop
; SD device driver has been installed, proceed to check for SD card as usual
sd_selected:
	JSR sd_init				; check SD card
	LDY #13
	JSR conio				; newline
; *** list SD contents ***
; get ready to read first sector
	STZ arg
	STZ arg+1
	STZ arg+2
	STZ arg+3				; assume reading from the very first sector
	STZ en_ix				; reset index
ls_disp:
; * load current sector *
#ifdef	DEBUG
			LDX #0
			TXA				; this will clear the read buffer, just in case
canary:
				STA buffer, X
				STA buffer+256, X
				INX
				BNE canary	
#endif
			LDX #>buffer	; temporary load address
			STX ptr+1
			STZ ptr			; assume buffer is page-aligned
			JSR ssec_rd		; read one 512-byte sector
; might do some error check here...
; * look for a valid header *
			LDA magic1		; check magic number one
			BEQ magic1_ok 
		JMP end_vol
magic1_ok:
			LDA magic2		; check magic number two
			CMP #13			; must be NEWL instead of zero
		BNE end_vol_near
			LDA magic3		; check magic number three
		BNE end_vol_near
; header is valid, check whether bootable or not
			LDA bootsig		; check Durango-X bootable ROM image signature
			CMP #'d'
		BNE next_file
			LDA bootsig+1
			CMP #'X'
#ifdef	SCREEN
		BEQ ls_page			; it is bootable, but check for screenshots too
			CMP #'S'		; 16-colour mode
		BEQ ls_page
			CMP #'R'		; HIRES mode
#endif
		BNE next_file

; * bootable ROM image detected, register sector and display entry *
ls_page:
			LDX en_ix		; last registered entry
			CPX #9			; already full?
		BCS skip_hd
#ifdef	SCREEN
			STA sig_tab, X	; store accepted type NEW
#endif
			TXA
			ASL
			ASL				; 4-byte entries
			TAX
			LDY #3			; max sector offset
en_loop:
				LDA arg, Y				; current sector (big endian)
				STA en_tab, X			; store locally (little endian)
				INX
				DEY
				BPL en_loop				; complete four bytes
			INC en_ix		; one entry has been detected
; print entry number before filename
			LDY #14
			JSR conio		; set inverse mode
			LDA en_ix
			CLC
			ADC #'0'		; get entry (1-based now) as ASCII number
			TAY
			JSR conio
			LDY #15
			JSR conio		; standard video
#ifdef	SCREEN
			LDA bootsig+1
			CMP #'S'		; is it a screenshot? (non-executable)
		BEQ is_ss
			CMP #'R'
		BNE not_ss
is_ss:
				LDY #16		; DLE
				JSR conio
				LDY #12		; paper glyph
				JSR conio
not_ss:
#endif
			LDY #' '
			JSR conio		; space between number and filename
; now print filename
			LDX #0			; string index
name_loop:
				LDY fname, X			; get char
			BEQ name_end				; until terminator
				PHX
				JSR conio				; print char
				PLX
				INX
; *** might check for maximum screen length...
				BNE name_loop			; no need for BRA
name_end:
; *** might display some metadata here...
			LDY #13
			JSR conio		; next line
#ifdef	DEBUG
			JSR show_sector
#endif
			BRA next_file
end_vol_near:
		BRA end_vol
; * in any case, jump and read next header *
next_file:
; compute next header sector
			JSR next_sector
			JMP ls_disp		; no need for BRA
end_vol:
		LDA en_ix			; check if volume ended with no entries listed
	BEQ skip_err
		CMP #9
		BNE last_pg
skip_hd:
		LDX #PAGE_MSG
		JSR disp_code		; add next page option
		LDX #NX_DEVICE
		JSR disp_code		; and next device (new)
last_pg:
		JSR sel_en			; wait for a valid entry...
		STZ en_ix			; ...but if arrived here, skip to new page
		LDX #SPCR_MSG
		JSR disp_code		; clean up for next page
		JMP ls_page			; avoid re-reading the sector
skip_err:
	LDX #INVALID_SD			; invalid contents error
	JMP sd_fail

; *******************************************
; *** image is selected, now boot from it ***
; *******************************************
do_boot:
	SEI						; no more interaction needed, slight performance improvement.
; reload sector of selected entry into buffer
	LDX #>buffer			; temporary load address
	STX ptr+1
	STZ ptr					; assume buffer is page-aligned
	JSR ssec_rd				; read first 512-byte sector of the file (will be read again)
; print loading message with filename
	LDX #LOAD_MSG
	JSR disp_code
	LDX #0
pr_load:
		LDY fname, X		; get filename from buffered first sector
	BEQ prl_ok
		PHX
		JSR conio			; print it
		PLX
		INX
		BNE pr_load			; no need for BRA
prl_ok:
; check size, determine ptr towards end of 64K space (or select screen address right now)
#ifdef	SCREEN
	LDA bootsig+1
	CMP #'X'				; if not executable, it's a screenshot
	BEQ rom_siz
		LDX #$80
		STX fsize+3			; tweak this indicator with end page!
		LDA #$5E			; will load header sector off-screen!
	BNE set_ptr				; always screen address
rom_siz:
#endif
	LDA #0
	SEC
	SBC fsize+1				; subtract number of pages
set_ptr:
	STA ptr+1
	STZ ptr					; definitive pointer is ready, proceed with load!
boot:
		JSR ssec_rd			; read one 512-byte sector
; might do some error check here...
; in the meanwhile, check for BREAK key
		LDA #1				; first column has both SPACE & SHIFT
		STA IO9kbd
		LDA IO9kbd			; get active rows
		STZ IO9kbd			; just for good measure
		AND #%10100000		; mask relevant keys
		CMP #%10100000		; both SHIFT & SPACE?
		BNE no_break
			LDX #ABORT
			JSR disp_code	; show abort message EEEEK
			LDX #vec_dc_sd-vec_sd		; set vectors for devCart device
			LDA dev_id		; really DevCart?
			BMI do_repeat	; seem so
				LDX #vec_sp_sd-vec_sd
do_repeat:
			JMP vecload		; init card again, same device
no_break:
; continue as usual
		JSR progress
;		LDX ptr+1			; current page (after switching)
;		LDA #$FF			; elongated white dots *** may change feedback
;		STA $7EFE, X
;		STA $7EFF, X		; display on screen (finished pages)
		INC arg+3			; only 64 sectors, no need to check MSB... EEEEEEEEK endianness!
		BNE no_wrap
			INC arg+2		; now could have several images, may wrap...
		BNE no_wrap
			INC arg+1		; now could have several images, may wrap...
		BNE no_wrap
			INC arg			; now could have several images, may wrap...
no_wrap:
		LDA ptr+1			; check current page
		CMP fsize+3			; this is usually zero... unless it's a screenshot!
		BNE boot			; until completion
; ** after image is loaded... **
#ifdef	SCREEN
	LDA bootsig+1			; signature of selected file
	CMP #'X'				; if executable, go run it!
	BEQ launch_rom			; otherwise it's a screenshot, S clears HIRES bit, R sets it
		CMP #'S'			; C set if ='S', clear if 'R', just the opposite we need
		LDA #%01110000		; shifted left 1, non-inverse, screen3, RGB, Emilio's LED off
		ROR					; now it's %C0111000, C clear
		EOR #%10000000		; invert operation, as desired
		STA IO8attr			; set proper video mode
		BRK
launch_rom:
#endif
; Interrupts already shut off for performance, good for reset anyway
	JMP switch				; start code loaded into cartidge RAM!

; ************************
; *** support routines ***
; ************************
; *** *** vectored hardware calls *** *** NEW
spi_tr:
	JMP (v_spi_tr)
cs_enable:
	JMP (v_cs_enable)
cs_disable:
	JMP (v_cs_disable)

; *** *** hardware interface for devCart *** ***
; *** send data in A, return received data in A *** nominally ~4.4 kiB/s
dc_spi_tr:
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
dc_cs_enable:
	LDA #$FF
	JSR spi_tr				; SPI_transfer(0xFF);
	LDA #SD_CS
	TRB IOCart				; CS_ENABLE();
	LDA #$FF
#ifdef	TALLY
	STZ IOAie				; *** this will turn LED on ***
#endif
	JMP dc_spi_tr			; SPI_transfer(0xFF); ...and return

; *** disable card transfer ***
dc_cs_disable:
	LDA #$FF
	JSR spi_tr				; SPI_transfer(0xFF);
	LDA #SD_CS
	TSB IOCart				; CS_DISABLE();
	LDA #$FF
#ifdef	TALLY
	STA IOAie				; *** this will turn LED off ***
#endif
	JMP dc_spi_tr			; SPI_transfer(0xFF); ...and return

; *** *** hardware interface for Fast SPI *** ***
; *** send data in A, return received data in A ***
sp_spi_tr:
	STA IO9sp_d				; store outgoing byte
	LDA IO9sp_c				; send 8 clock pulses (quickly)
;	LDA IO9sp_c				; actually seven, as Parallel load will make first bit available!
	LDA IO9sp_c
	LDA IO9sp_c
	LDA IO9sp_c
	LDA IO9sp_c
	LDA IO9sp_c
	LDA IO9sp_c
	LDA IO9sp_d				; retrieve incoming data
	RTS

; *** enable card transfer ***
sp_cs_enable:
	LDA #$FF
	JSR spi_tr				; SPI_transfer(0xFF);
	LDY dev_id				; must preserve X! eeek!
	LDA sid_en, Y			; get enable mask for selected ID
	STA IO9sp_c				; CS_ENABLE();
#ifdef	TALLY
	STA IOAie				; *** this will turn LED on ***
#endif
	LDA #$FF
	JMP sp_spi_tr			; SPI_transfer(0xFF); ...and return

; *** disable card transfer ***
sp_cs_disable:
	LDA #$FF
	JSR spi_tr				; SPI_transfer(0xFF);
	LDA #%11111111			; all SPI devices disabled
	STA IO9sp_c				; CS_DISABLE();
#ifdef	TALLY
	STA IOAie				; *** this will turn LED off ***
#endif
;	LDA #$FF
	JMP sp_spi_tr			; SPI_transfer(0xFF); ...and return

; *** *** standard SD card support *** ***
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

; *** *** special version of the above, in case SDSC is byte-addressed, CMD17 and CMD24 only *** ***
ba_cmd:
; send command header
	ORA #$40
	JSR spi_tr				; SPI_transfer(cmd|0x40);
; precompute byte-addressed sector
	LDA arg+3
	ASL
	STA tmpba+2				; only two bytes actually used (+1...+2)
	LDA arg+2
	ROL
	STA tmpba+1
	LDA arg+1
	ROL
;	STA tmpba
; send argument
;	LDA tmpba
	JSR spi_tr
	LDA tmpba+1
	JSR spi_tr
	LDA tmpba+2
	JSR spi_tr
	LDA #0					; always zero as 512 bytes/sector
	JSR spi_tr
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

; *** init SD card in SPI mode ***
sd_init:
; ** SD_powerUpSeq is inlined here **
	LDA #SD_CS				; CS bit
	TSB IOCart				; CS_DISABLE();
	LDX #220				; ** may substitute SD logo load for this delay **
sdpu_dl:
		NOP
		DEX
		BNE sdpu_dl			; delayMicroseconds(1000);
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
	LDX #IDLE_ERR			; *** ERROR 0 in red ***
	JMP sd_fail				; if(cmdAttempts > 10)	return SD_ERROR;
is_idle:
	LDX #IDLE_ERR			; eeeek
	JSR pass_x				; *** PASS 0 in white ***
; ** SD_sendIfCond is inlined here **
	JSR cs_enable			; assert chip select
; send CMD8
	STZ arg
	STZ arg+1				; CMD8_ARG upper 16 bits are zero
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

	STZ sd_ver				; ### default (0) is modern SD card ###
	LDA res
	LDX #SDIF_ERR			; moved here
	CMP #1					; check valid response
	BEQ sdic_ok
; ### if error, might be 1.x card, notify and skip to CMD58 or ACMD41 ###
		LDX #OLD_SD			; ### message for older cards ###
		STX sd_ver			; ### store as flag ###
		JSR disp_code
		LDY #13
		JSR conio
		BRA not_cmd8
sdptec:
		JMP sd_fail			; if(res[0] != 0x01) return SD_ERROR;
sdic_ok:
	JSR pass_x				; *** PASS 1 in white ***
; check pattern echo
	LDX #ECHO_ERR			; *** ERROR 2 in red ***
	LDA res+4
	CMP #$AA
		BNE sdptec			; if(res[4] != 0xAA) return SD_ERROR;
	JSR pass_x				; *** PASS 2 in white ***
; ### jump here for 1.x cards ###
not_cmd8:
; attempt to initialize card *** could add CMD58 for voltage check
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
	LDX #INIT_ERR			; *** ERROR 3 in red ***
	JMP sd_fail				; if(cmdAttempts > 100) return SD_ERROR;
apc_rdy:
	LDX #INIT_ERR
	JSR pass_x				; *** PASS 3 in white ***
; ### old SD cards are always SC ###
	LDA sd_ver
		BNE sd_sc
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
	LDX #READY_ERR			; *** ERROR 4 in red ***
	BIT res+1				; eeeeeeeeek ### will check CCS as well ###
	BMI card_rdy			; eeeeeeeeek
		JMP sd_fail			; if(!(res[1] & 0x80)) return SD_ERROR;
card_rdy:					; * SD_init OK! *
; ### but check whether standard or HC/XC, as the former needs asserting 512-byte block size ###
; ### if V is set then notify and skip CMD16 ###
	BVS hcxc
; ### set 512-byte block size ###
sd_sc:
		SEC
		ROR sd_ver			; *** attempt of marking D7 for SDSC cards, byte-addressed!
		JSR cs_enable		; assert chip select ### eeeeeeeeek
		STZ arg
		STZ arg+1			; assume CMD16_ARG upper 16 bits are zero
		LDA #>CMD16_ARG		; actually 2 for 512 bytes per sector
		STA arg+2
;		LDA #<CMD16_ARG
;		STA arg+3
		STZ arg+3			; assume CMD16_ARG LSB is zero (512 mod 256)
		STZ crc				; assume CMD16_CRC is zero
		LDA #CMD16
		JSR sd_cmd
; should I check errors?
		JSR rd_r1
		JSR cs_disable		; deassert chip select ###
		LDX #READY_ERR		; ### display standard capacity message and finish ###
		BRA card_ok
hcxc:
	LDX #HC_XC				; ### notify this instead ###
card_ok:
	JMP pass_x				; *** PASS 4 in white ***

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
	BIT sd_ver				; *** check whether SC or HC/XC
	BPL is_hcxc
		JSR ba_cmd			; SD_command(CMD17, sector, CMD17_CRC); *** a special version for SDSC cards is needed
		BRA cmd_ok
is_hcxc:
	JSR sd_cmd				; SD_command(CMD17, sector, CMD17_CRC); *** regular block-addressed version
cmd_ok:
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

; *** advance to next sector according to filesize ***
next_sector:
; first, convert size into number of sectors
	LDX fsize		; any padding used?
	BEQ full_pg
		INC fsize+1			; if so, count as one more page
		BNE full_pg			; ** eeeeeek
			INC fsize+2		; ** now supporting up to 16M headers!
full_pg:
	LSR fsize+2		; **
	ROR fsize+1		; half the number of sectors...
	BCC below64
		INC fsize+1	; ...unless it was odd
	BNE below64		; **
		INC fsize+2	; **
below64:
	LDA fsize+1
	ADC arg+3		; add to current sector, note big-endian!
	STA arg+3
	LDA fsize+2		; **
	ADC arg+2
	STA arg+2
	LDA fsize+3		; just in case...
	ADC arg+1		; propagate carry, just in case
	STA arg+1
	BCC sec_ok
		INC arg
sec_ok:
	RTS

; *** display pass code ***
pass_x:
	JSR disp_code			; display message
	LDX #OK_MSG				; OK message
;	JMP disp_code			; print and return

; *** display code message ***
disp_code:
	LDA msg_ix, X			; reindex from X=error code
	TAX
dc_loop:
		LDY msg_sd, X		; get char
	BEQ dc_end				; message ended
		PHX
		JSR conio			; display char
		PLX
		INX
		BNE dc_loop			; next char
dc_end:
	RTS

; *** wait for user selection ***
; 1...9 = entry index (may be selected with up/down)
; 0     = next page   (may be selected with right or left)
; when selected via game pad, use FIRE/SELECT/B/START to boot
sel_en:
;	STZ fw_knes				; reset input-by-pad
sel_loop:
		LDY #0
		JSR conio			; input char
		BCS sel_loop		; wait for a key ** KEYBOARD ONLY
;		LDA gamepad1		; check also pad input
;		ORA gamepad2
		CPY #'0'			; next page?
	BEQ exit_sel
		CPY #'d'			; next device? (new)
	BEQ exit_dev
;		BIT #%00000101		; check left or right
;	BEQ exit_sel			; also means next page
;		PHY					; eeeek
;		BIT #%00000010		; check down
;	BEQ no_down
; try to advance selection
;		LDX fw_knes
;		CPX en_ix			; room for it?
;		BCS no_down
;			INX				; update value
;			JSR show_sel	; and display new selection
no_down:
;		BIT #%00001000		; check up
;	BEQ no_up
; try to decrement selection
;		LDX fw_knes
;		BEQ no_up			; no previous selection
;			DEX				; update value
;		BEQ no_up			; was first one, do nothing
;			JSR show_sel	; or display new selection
no_up:
;		PLY
;		BIT #%11110000		; check any selection button
;	BEQ sel_loop;	BNE pad_sel
		TYA
		CMP #'1'			; less than 1 is ignored
	BCC sel_loop
;		CMP #'9'+1			; but 1...9 is accepted
;	BCS sel_loop
;		SEC
		SBC #'0'			; convert to index 1...9
;		BRA launch
pad_sel:
;		LDA fw_knes			; get selection
;		BEQ sel_loop		; nothing yet!
launch:
; arrived here with A = 1...9 selected entry, no return
		DEC					; make A = 0...8
; should check if within detected entries
		CMP en_ix
	BCS sel_err
		ASL
		ASL					; times 4
		TAX					; table index (little endian)
		LDY #3				; max offset (big endian)
lnch_l:
			LDA en_tab, X
			STA arg, Y		; copy entry byte, reversing endianness
			INX
			DEY
			BPL lnch_l
		JMP do_boot			; start booting from selected sector!
sel_err:
	LDY #7
	JSR conio				; error beep
	BRA sel_loop			; and try agin
exit_sel:
	LDA en_ix
	CMP #9					; does next page make any sense?
		BNE sel_err
	RTS						; if next page is requested, just return
exit_dev:
	LDX #OK_MSG				; eeeek
	JMP switch_dev			; no FAIL, please

; *** display selected entry ***
; X = new entry position (1...9)
show_sel:
	STX fw_knes				; must update this value
	TXA
	CLC
	ADC #'0'				; to ASCII
	TAY
	JSR conio				; display number
	LDX #SEL_MSG			; selection message
	JSR disp_code
rls_gp:
		LDA gamepad1
		ORA gamepad2		; check gamepads
		BNE rls_gp			; wait until release
	RTS

; *** new progress indicator ***
progress:
#ifdef	SCREEN
	LDA bootsig+1
	CMP #'X'
		BNE no_bar			; if it's a screenshot, do not display progress
#endif
	LDA ptr+1				; check new page
	DEC						; last completed page
	TAY						; save!
	LSR
	LSR
	LSR						; 256 pages into 32 bytes (HIRES)
	TAX						; offset ready
	TYA						; back
	AND #7					; number of pixels set, after adding 1; expected EVEN
	TAY						; as index
	LDA prog_pat, Y			; proper bitmap
	STA $7F80, X
	STA $7FA0, X
	STA $7FC0, X
	STA $7FE0, X			; beautifully displayed
no_bar:
	RTS

#ifdef	DEBUG
show_sector:
	LDX #0					; 256 words = 512 bytes
	DEC ptr+1
	DEC ptr+1				; 512 bytes back
fsd_loop:
		PHX
		LDY #16				; binary mode!
		JSR conio
		LDA (ptr)			; first byte in word
		TAY
		JSR conio
		INC ptr				; no wrap here
		LDY #16				; binary mode!
		JSR conio
		LDA (ptr)			; second byte in word
		TAY
		JSR conio
		INC ptr
		BNE fsd_nw
			INC ptr+1
fsd_nw:
		PLX
		INX
		BNE fsd_loop		; repeat for every word

	ldy#13
	jsr conio
	inc arg+2	; WTF
	inc arg+2	; WTFeeeeeeeeeeeek
	jsr ssec_rd
	LDX #0					; 256 words = 512 bytes
	DEC ptr+1
	DEC ptr+1				; 512 bytes back
ffsd_loop:
		PHX
		LDY #16				; binary mode!
		JSR conio
		LDA (ptr)			; first byte in word
		TAY
		JSR conio
		INC ptr				; no wrap here
		LDY #16				; binary mode!
		JSR conio
		LDA (ptr)			; second byte in word
		TAY
		JSR conio
		INC ptr
		BNE ffsd_nw
			INC ptr+1
ffsd_nw:
		PLX
		INX
		BNE ffsd_loop		; repeat for every word	

	dec arg+2		; WTF
	dec arg+2		; WTFeeeeeeeeeeek

	LDY #13
	JMP conio				; newline and... return
#endif

; ***************************
; *** standard exit point ***
; ***************************
sd_fail:					; SD card failed
	JSR disp_code			; display message
	LDX #FAIL_MSG			; FAIL message
switch_dev:
	JSR disp_code
; before locking, try another device *** NEW AND IMPROVED
	LDA dev_id
		BEQ was_raspi
	DEC dev_id				; check next device
	BEQ no_spi				; ID=0 for RasPi
	BPL next_dev			; or continue with next SPI
		LDA #4				; came from devCart, set "first" SPI device
		STA dev_id
next_dev:
	LDX #vec_sp_sd-vec_sd	; try SPI interface otherwise
	JMP vecload				; will get back to init procedure
no_spi:
; here could come the Raspberry Pi module instead (nanoBoot)
	BRK						; just lock with error LED
was_raspi:
	JMP sd_main				; restart if switching device from RasPi (placeholder)

; ********************
; *** diverse data ***
; ********************

; messages for SD init, with offsets
msg_sd:
	.asc	"Set Idle", 0
sd_old:
	.asc	"v1.x "			; ### special prefix for older v1.x cards ###
sd_m1:
	.asc	"SD Interface", 0
sd_m2:
	.asc	"Pattern echo", 0
sd_m3:
	.asc	"Card Init", 0
sd_hc:
	.asc	"HC/XC "		; ### special prefix if CCS=1 ###
sd_m4:
	.asc	"Card Ready", 0
sd_ok:
	.asc	15, " OK", 13, 0
sd_err:
	.asc	" ", 14, "FAIL!", 15, 7, 13, 13, 0
sd_inv:
	.asc	" ", 14, "No ROM image found", 15, 7, 0
sd_sel:
	.asc	" is selected", 1, 0
sd_load:
	.asc	13, 14, "Loading ", 0
sd_page:
	.asc	13, 14, "0", 15, " next page...", 0
sd_spcr:
	.asc	13, "-----------", 13, 0
sd_splash:
	.asc	14,"Durango·X", 15, " SD bootloader 1.2b3", 13, 13, 0
sd_next:
	.asc	13, "SELECT next ", 14, "D", 15, "evice...", 0
sd_abort:
	.asc	" -STOPPED!", 7, 15, 13, 13, 0

#echo	1.2b3

; offset table for the above messages
msg_ix:
	.byt	0				; IDLE_ERR
	.byt	sd_m1-msg_sd	; SDIF_ERR
	.byt	sd_m2-msg_sd	; ECHO_ERR
	.byt	sd_m3-msg_sd	; INIT_ERR
	.byt	sd_m4-msg_sd	; READY_ERR
	.byt	sd_ok-msg_sd	; OK_MSG
	.byt	sd_err-msg_sd	; FAIL_MSG	with beep
	.byt	sd_inv-msg_sd	; INVALID_SD
	.byt	sd_sel-msg_sd	; SEL_MSG	display selected and return to line start
	.byt	sd_load-msg_sd	; LOAD_MSG	loading message
	.byt	sd_page-msg_sd	; PAGE_MSG	ask for next page
	.byt	sd_spcr-msg_sd	; SPCR_MSG	page separator
	.byt	sd_old-msg_sd	; OLD_SD	v1.x before SD Interface
	.byt	sd_hc-msg_sd	; HC_XC		before Card Ready
	.byt	sd_splash-msg_sd	; SPLASH		splash screen
	.byt	sd_next-msg_sd	; NX_DEVICE
	.byt	sd_abort-msg_sd	; ABORT

; vector table
vec_sd:
vec_dc_sd:
	.word	dc_spi_tr,	dc_cs_enable,	dc_cs_disable		; vectors for devCart interface
vec_sp_sd:
	.word	sp_spi_tr,	sp_cs_enable,	sp_cs_disable		; vectors for Fast SPI interface

; SPI device names, in 6-byte packs (like vectors)
sd_name:
	.asc	"devC?", 13		; devCart SD interface
	.asc	":SPI?", 13		; Fast SPI interface!
;	.asc	"RasPI:"		; nanoBoot (placeholder)

; other tables
prog_pat:
	.byt	%10000000, %11000000, %11100000, %11110000, %11111000, %11111100, %11111110, %11111111
sid_en:
	.byt	%11111111, %11111110, %11111101, %11111011, %11110111	; SPI /CS patterns for ID0..3 (index 1..4, 0 is disable)
.)
end_sd:

; ************************
; *** firmware support ***
; ************************
reset:
	SEI
	CLD
	LDX #$FF
	TXS						; usual 6502 stuff
; Durango-X specifics, including PSG mute!
	LDA #%10011111			; max. attenuation channel 0
psg_mute:
		STA IO_PSG
		JSR psg_del			; suitable 36-cycle delay
		CLC
		ADC #32				; next channel
		BMI psg_mute
; standard stuff
	STX IOAie				; enable interrupt hardware, turn off error LED
	LDA #%10110000			; HIRES screen 3
	STA IO8attr
;	INX						; now it's zero
;zp_res:
;		STZ 0, X			; just in case, reset whole zeropage
;		INX
;		BNE zp_res

	STZ fw_scur				; as bit 7 is OFF, de-activates cursor
	LDX #3					; max jiffy counter index
jf_res:
		STZ ticks, X		; reset all jiffy counter bytes
		STZ kb_asc, X		; init all keyboard variables too, up to kb_scan (4 bytes)
		DEX
		BPL jf_res
	LDX #>std_irq
	LDY #<std_irq
	STY fw_irq				; set standard interrupt vectors
	STX fw_irq+1
;	LDX #>std_nmi			; danger if commented!
;	LDY #<std_nmi
;	STY fw_nmi
;	STX fw_nmi+1
; init gamepad
	STA IO9nes0				; latch pad status
	LDX #8					; number of bits to read
nes_init:
		STA IO9nes1			; send clock pulse
		DEX
		BNE nes_init		; all bits read @ IO9nes0
	LDA IO9nes0				; get bits
	LDX IO9nes1				; get bits for pad 2
	STA GAMEPAD_MASK1		; * MUST have a standard address, and MUST be initialised! *
	STX GAMEPAD_MASK2		; * MUST have a standard address, and MUST be initialised! *
; * check keyboard *
	LDX #0					; default is PASK
	LDA #32					; column 6
	STA IO9m5x8				; select it
	LDA IO9m5x8				; and read rows
	CMP #$2C				; is it a 5x8 matrix? EEEEEEEEK
	BNE not_5x8
		LDX #2				; set as default keyboard
not_5x8:
	STX kb_type				; set selected type
; * init CONIO *
	STZ fw_cbin				; EEEEEEK
	STZ fw_mask
	STZ fw_io9
;	LDA #$87				; yellow on blue intial colours (not for HIRES)
;	STA fw_ccol+1			; will reconstruct colours from this upon FF
	LDY #12					; FF = clear screen
	JSR conio

	CLI						; must enable interrupts!
	JMP sd_main				; start loader!

; delay routine for PSG access
psg_del:
	JSR psg_rts
	JSR psg_rts
psg_rts:
	RTS

; **************************
; *** interrupt handlers ***
; **************************
irq:
	JMP (fw_irq)			; standard minimOS vector
std_irq:
; *** minimOS jiffy counter ***
	INC ticks
	BNE irq_sup
		INC ticks+1
	BNE irq_sup
		INC ticks+2
	BNE irq_sup
		INC ticks+3
irq_sup:
	PHA
	PHX
	PHY						; needed for 5x8 matrix support
; *** interrupt support for matrix keyboard ***
	JSR kbd_isr
; * after reading keyboard, gamepads are read, may suppress this for slight performance improvement *
; keep gamepad input updated (already done for KBD emulation)
	STA IO9nes0				; latch pad status
	LDX #8					; number of bits to read
nes_loop:
		STA IO9nes1			; send clock pulse
		DEX
		BNE nes_loop		; all bits read @ IO9nes0/1
; done, but check GAMEPAD_MASK1 & GAMEPAD_MASK2 after reading ports in BASIC!
	LDA IO9nes0
	EOR GAMEPAD_MASK1
	STA gamepad1			; corrected value at $226, or 550
	LDA IO9nes1
	EOR GAMEPAD_MASK2
	STA gamepad2			; corrected value at $227, or 551
; * end of gamepad code *
; in extremis check for (catastrophic) BRK
;	PHX						; already saved
	TSX
	LDA $104, X				; get pushed PSR (note stack frame)
	AND #$10				; check BRK bit
	BEQ not_brk
; *** BRK happened *** will keep the LED flashing, as no debugger is installed
brk_panic:
				INX
				BNE brk_panic
			INY
			BNE brk_panic	; 0.2s delay
		INC					; cycle LED
		STA IOAie
		BRA brk_panic
not_brk:
	PLY						; for 5x8 matrix support
	PLX
	PLA
	RTI

;nmi:
;	JMP (fw_nmi)			; standard minimOS vector

; *** multi-keyboard support ***
kbd_isr:
	LDX kb_type
	JMP (kbd_drv, X)		; CMOS only
; generic PASK driver
drv_pask:
	LDA IO9pask				; PASK peripheral address
	STA kb_asc				; store for software
	RTS

; drivers pointer list
kbd_drv:
	.word	drv_pask
	.word	drv_5x8

; ********************
; *** *** BIOS *** ***
; ********************

#include "../../OS/macros.h"
; EMPTY definition from abi.h
#define	EMPTY	6
#define	SAFE
-conio:
#include "../../OS/firmware/modules/conio-durango-fast.s"

; keyboard driver
#include "../../OS/firmware/modules/durango-5x8key.s"

fw_end:

; ***************************
; *** devcart ROM support ***
; ***************************

	.dsb	$FFD6-*, $FF
	.asc	"DmOS"			; standard minimOS signature

	.dsb	$FFDC-*, $FF

switch:
	LDA #%01100100			; ROM disabled, protected RAM, and SD disabled just in case
do_sw:
	STA IOCart
; * = $FFE1
autoreset:
	JMP ($FFFC)				; RESET on loaded image *** mandatory instruction on any ROM image ***
 
	.dsb	$FFFA-*, $FF

; *****************************
; *** standard 6502 vectors ***
; *****************************
* = $FFFA
	.word	reset			; NMI does warm reset
	.word	reset
	.word	irq
rom_end:
