; devCart SD-card driver module for EhBASIC
; (c) 2023 Carlos J. Santisteban
; last modified 20230419-1636

#echo Using devCart SD card for LOAD... interactive filename prompt

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

-Ram_base	= $0500			; just in case

.(
; *** memory usage *** CHECK
f_eof	= $EC				; current file size, max 64 KiB
f_sig	= f_eof	+ 1			; $EE-$EF, filter by signature?
sd_ver	= f_sig				; $EE
crc		= sd_ver+ 1			; $EF
arg		= crc	+ 1			; $F0
res		= arg	+ 4			; $F4
mosi	= res	+ 5			; $F9
miso	= mosi	+ 1			; $FA
token	= miso	+ 1			; $FB
ptr		= token	+ 1			; $FC, buffer pointer
f_cur	= ptr	+ 2			; $FE, file cursor

; *** sector buffer and header pointers ***

buffer	= $300
magic1	= buffer+0			; must contain zero
magic2	= buffer+7			; must contain CR (13)
magic3	= buffer+255		; must contain zero (assume filesize < 16 MiB)
bootsig	= buffer+1			; must contain 'dX' for bootable ROM images, 'dA' for generic files, 'dL' for free space
fname	= buffer+8
ftime	= buffer+248		; time in MS-DOS format
fdate	= buffer+250		; date in MS-DOS format
fsize	= buffer+252		; file size INCLUDING 256-byte header

; **********************
; *** driver package ***
; **********************
; ********************************************************************************
+aux_in:					; *** device input (MUST restore devices upon EOF) ***
	LDA f_cur+1
	CMP f_eof+1				; compare cursor to size
	BCC not_eof				; if below, no EOF (sequential only)
		LDA f_cur
		CMP f_eof+1
	BCC not_eof
		STZ std_in
		STZ stdout			; restore devices!
		JMP LAB_WARM		; will this work? yes!
not_eof:
	LDA (ptr)				; get byte from current position
	INC ptr					; advance into buffer
	BNE adv_byte
		INC ptr+1
		LDX ptr+1			; check page
		CPX #>(buffer+512)	; usually 5 EEEEEK
	BNE adv_byte
; *** read next sector ***
		INC arg+3			; advance sector number, note big endian
		BNE load_next
			INC arg+2
		BNE load_next
			INC arg+1
		BNE load_next
			INC arg
load_next:
		PHA
		JSR ssec_rd			; actual sector read
		PLA					; retrieve last byte read
adv_byte:
	INC f_cur				; count another byte read
	BNE rd_byte
		INC f_cur+1
rd_byte:
	TAY						; exit value
	CLC						; eeeeeeeek
	RTS

; *************************************************
+aux_out:					; *** device output ***
	CPY #13					; check for CONIO/minimOS NEWLINE
	BNE do_aux_out
		LDY #10				; convert to UNIX LF
do_aux_out:
;*********code from read***
/*	LDA f_cur+1
	CMP f_eof+1				; compare cursor to size
	BCC not_eof				; if below, no EOF
		LDA f_cur
		CMP f_eof+1
		BCS in_eof
not_eof:
	LDA (ptr)				; get byte from current position
;*****end of code from read***** */
	TYA						; eeeeeeek
	STA (ptr)				; store into buffer
	INC ptr					; next 
	BNE adv_wbyte
		INC ptr+1
		LDX ptr+1			; check page
		CMP #>Ram_base		; usually 5
	BNE adv_wbyte
		LDX #>buffer
		STX ptr				; wrap buffer pointer
; *** write current sector and point to next one *** TBD TBD TBD
adv_wbyte:
	INC f_cur				; another byte written
	BNE wr_byte
		INC f_cur+1
wr_byte:
; *********** ? ****************
	RTS

; **********************************************************************************
+aux_load:					; *** prepare things for LOAD, Carry if not possible ***
	JSR LAB_SNBS			; this should avoid losing the first line (no, it doesn't)
	JSR set_name
	BCS auxl_end			; do nothing in case of error
		LDX #0
fnd_file:
			LDY fnd_msg, X
		BEQ fnd_ok
			PHX
			JSR conio		; show 'Found' message...
			PLX
			INX
			BNE fnd_file
fnd_ok:
		JSR name_prn		; ...and add detected filename
		STZ f_cur
		STZ f_cur+1			; reset file position *** may try setting both pointers at 256
		STZ ptr
		LDA #>(buffer+256)	; eeeeeeeek
		STA ptr+1			; skip header in buffer eeeeeeeek
		LDX fsize+1			; eeeeeeeek
		DEX					; minus header page *** if absolute, do not decrement
		LDY fsize
		STY f_eof
		STX f_eof+1
		CLC
auxl_end:
	RTS

; **********************************************************************************
+aux_save:					; *** prepare things for SAVE, Carry if not possible ***
	JSR set_name
	BCC auxs_end			; do nothing in case of error (file exists, $ should return to V_SAVE caller, not here)
;----------- [locate file], if exists > error, is it BCC?; else locate free, change name and reset pointers 
		CLC					; all OK this far!
auxs_end:
	RTS

; ******************************************************
+aux_close:					; *** tidy up after SAVE ***
;---------- save current sector, reload header, keep size, set size to cursor+256, regenerate free after it of old size-actual
	RTS						; nothing to do this far

set_name:
	JSR sd_init				; common for LOAD and SAVE, note stack depth in case of failure
	JSR ssec_rd				; read first volume sector into buffer!
; ask for the filename, or $ for directory listing
	LDX #0
prompt_l:
		LDY aux_prompt, X
		BEQ ask_name
		PHX
		JSR conio			; display prompt string
		PLX
		INX
		BNE prompt_l
ask_name:
	JSR LAB_INLN
	STX ut1_pl
	STY ut1_ph				; set indirect pointer
; might check here for '$' of directory listing request
	LDY #1
	LDA (ut1_pl)			; check first character
	CMP #'$'
	BNE name_ok
		LDA (ut1_pl), Y		; Y=1, thus check second character
	BNE name_ok
; $ was entered, thus show directory listing and exit
dir_lst:
		LDA magic1			; check magic1
	BNE end_lst				; no more valid headers
		LDA magic2		; check magic2
		CMP #13
	BNE end_lst
		LDA magic3			; if file<16 MiB
	BNE end_lst
		LDA bootsig			; check signature
		CMP #'d'
		BNE skp_hd			; not valid, skip to next header
; --- comment these lines if all suitable headers (d*) are to be shown ---
			LDA bootsig+1
			CMP #'A'		; generic file
;		BNE skp_hd			; * may try to recognise 'dL' as well *
			BEQ prn_name	; eeek
				CMP #'X'	; executable header?
			BNE skp_hd
				LDY #'*'	; place asterisk before name
				JSR conio
; --- header has passed filter, print filename
prn_name:
		JSR name_prn
skp_hd:
		JSR nxt_head		; jump and load next header
		BRA dir_lst			; check and print name, if suitable
end_lst:
; listing ended, abort without further errors
		JMP LAB_WARM		; best way
name_ok:
; look for file and return C if not found
		LDA magic1			; check magic1
	BNE bad_name			; no more valid headers
		LDA magic2			; check magic2
		CMP #13
	BNE bad_name
		LDA magic3			; if file<16 MiB
	BNE bad_name
		LDA bootsig			; check signature
		CMP #'d'
		BNE skp_fi			; not valid, skip to next header
			LDA bootsig+1
			CMP #'A'		; generic file
		BNE skp_fi
			LDY #0			; reset index
cmp_name:
				LDA (ut1_pl), Y			; start with typed name as a search term
			BEQ cmp_end		; search pattern ended without any mismatch
				CMP fname, Y			; compare chars
			BNE skp_fi		; different
				INY
				BNE cmp_name			; no need for BRA
skp_fi:
		JSR nxt_head		; jump and load next header
		BRA name_ok			; check this new header
bad_name:
	SEC
	RTS
; if arrived here, we found the file... or something matching the search term
cmp_end:
; --- uncomment these for strict name matching ---
;	LDA fname, Y			; check current position in filename
;		BNE skip_fi			; if not a terminator, match is incomplete
	CLC						; name was OK
	RTS

; *** print buffered filename ***
name_prn:
	LDX #0					; point to name in header
lname_l:
		LDY fname, X
	BEQ end_ln				; print full filename
		PHX
		JSR conio
		PLX
		INX
		BNE lname_l			; no need for BRA
end_ln:
	LDY #13
	JMP conio				; print CR and return

; *** advance to next header ***
nxt_head:
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
	JMP ssec_rd		; eeeeeek! and return


; ***********************************
; *** hardware-specific SD driver ***
; ***********************************
; SD interface definitions
#define	SD_CLK		%00000001
#define	SD_MOSI		%00000010
#define	SD_CS		%00000100
#define	SD_MISO		%10000000
#define	IOCart		$DFC0

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

; ***************************
; *** standard SD library ***
; ***************************

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

; *** init SD card in SPI mode ***
sd_init:
; ** SD_powerUpSeq is inlined here **
	JSR cs_disable			; for compatibility
	LDX #220				; 1 ms delay
sdpu_dl:
		NOP
		DEX
		BNE sdpu_dl
; continue with powerup sequence
	LDX #9					; one less as cs_disable sends another byte
sd80c:
		LDA #$FF
		JSR spi_tr
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
		JSR rd_r1
		JSR cs_disable

; continue set_idle loop
		LDA res
		CMP #1
	BEQ is_idle				; already idle...
		DEX					; ...or continue until timeout
		BNE set_idle
	LDX #IDLE_ERR			; *** ERROR 0 in red ***
	JMP sd_fail				; failed to set idle
is_idle:
;	LDX #IDLE_ERR			; eeeek
;	JSR pass_x				; *** PASS 0 in white ***
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
	JSR rd_r7
	JSR cs_disable			; deassert chip select

	STZ sd_ver				; ### default (0) is modern SD card ###
	LDA res
	LDX #SDIF_ERR			; moved here
	CMP #1					; check valid response
	BEQ sdic_ok
; ### if error, might be 1.x card, notify and skip to CMD58 or ACMD41 ###
;		LDX #OLD_SD			; ### message for older cards ###
		STX sd_ver			; ### store as flag ### (non-zero)
;		JSR disp_code
;		LDY #13
;		JSR conio
		BRA not_cmd8
sdptec:
		JMP sd_fail
sdic_ok:
;	JSR pass_x				; *** PASS 1 in white ***
; check pattern echo
	LDX #ECHO_ERR			; *** ERROR 2 in red ***
	LDA res+4
	CMP #$AA
		BNE sdptec			; SD_ERROR;
;	JSR pass_x				; *** PASS 2 in white ***
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
		JSR rd_r1
		JSR cs_disable		; deassert chip select
		LDA res				; return res1;

; if no error in response
		CMP #2
		BCS sa_err
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
			JSR rd_r1
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
			BNE d10m		; 10 ms delay;
		DEX					; up to 100 times
		BNE sd_ia
	LDX #INIT_ERR			; *** ERROR 3 in red ***
	JMP sd_fail
apc_rdy:
;	LDX #INIT_ERR
;	JSR pass_x				; *** PASS 3 in white ***
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
	JSR rd_r7
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
		JSR cs_enable		; assert chip select ### eeeeeeeeek
		STZ arg
		STZ arg+1			; assume CMD16_ARG upper 16 bits are zero
		LDA #>CMD16_ARG		; actually 2 for 512 bytes per sector
		STA arg+2
		STZ arg+3			; assume CMD16_ARG LSB is zero (512 mod 256)
		LDA #$FF
		STA crc				; assume CMD16_CRC is zero... or not? ***
		LDA #CMD16
		JSR sd_cmd
; should I check errors?
		JSR rd_r1
		JSR cs_disable		; deassert chip select ###
		LDA res				; *** wait for zero response
	BNE sd_sc				; *** maybe a timeout would be desired too
;		LDX #READY_ERR		; ### display standard capacity message and finish ###
;		BRA card_ok
hcxc:
;	LDX #HC_XC				; ### notify this instead ###
card_ok:
;	JMP pass_x				; *** PASS 4 in white ***
; *** card properly inited, may mount volume now ***
;	JMP mount_vol
; should look for 'durango.av' file but, this far, from the very first sector of card instead
	STZ arg
	STZ arg+1
	STZ arg+2
	STZ arg+3				; assume reading from the very first sector
	RTS

; *** read single sector ***
ssec_rd:
; * intended to read at $0300 *
	LDA #>buffer
;	LDY #<buffer			; expected to be page-aligned
	STA ptr+1
	STZ ptr					; or STY, if set
; * standard sector read, assume arg set with sector number *
; set token to none
	LDA #$FF
	STA token
	JSR cs_enable			; assert chip select
; send CMD17 (sector already at arg.l)
	STZ crc					; ** assume CMD17_CRC is 0 **
	LDA #CMD17
	JSR sd_cmd				; SD_command(CMD17, sector, CMD17_CRC);
; read response
	JSR rd_r1
	CMP #$FF
	BEQ no_res
; if response received from card wait for a response token (timeout = 100ms)
		LDX #SD_MAX_READ_ATTEMPTS
rd_wtok:
			DEX
		BEQ chk_tok			; this is done twice for a single-byte timeout loop
			LDA #$FF
			JSR spi_tr
			CMP #$FF
		BNE chk_tok
			LDA #$FF
			JSR spi_tr
			CMP #$FF
			BEQ rd_wtok		; if((read = SPI_transfer(0xFF)) != 0xFF)		break; (759t ~494µs)
chk_tok:
		STA res
		CMP #$FE
		BNE set_tk
; read 512 byte block
block:
			LDX #0			; 256-times loop reading 2-byte words => 512 bytes/sector
byte_rd:
				LDA #$FF
				JSR spi_tr
				STA (ptr)	; get one byte
				INC ptr		; won't do any page crossing here, as long as the base address is EVEN
				LDA #$FF
				JSR spi_tr
				STA (ptr)	; get a second byte
				INC ptr
				BNE brd_nw
					INC ptr+1
; cannot reach I/O page as this loads to RAM only
brd_nw:
				INX
				BNE byte_rd
; discard 16-bit CRC
rd_crc:
			LDA #$FF
			JSR spi_tr
			LDA #$FF
			JSR spi_tr
			LDA res
set_tk:
; set token to card response
		STA token
no_res:
	JSR cs_disable			; deassert chip select
	LDA res
; * get all ready for buffer access *
	LDX #>buffer
	STX ptr+1				; wrap buffer pointer (assume page aligned) eeeeek
	RTS

; *** exit point in case of error *** X = error code
sd_fail:
	TXA
	CLC
	ADC #'0'				; convert error code into ASCII
	TAY
	JSR conio
	LDX #0
fail_loop:
		LDY fail_msg, X
	BEQ fail_end
		PHX
		JSR conio
		PLX
		INX
		BNE fail_loop		; no need for BRA
fail_end:
	PLA
	PLA						; abort sd_init
	PLA
	PLA						; abort set_name
	SEC						; notify error
	RTS						; return to aux_load or aux_save

; ********************
; *** diverse data ***
; ********************

aux_prompt:
	.asc	"Filename", 0

fail_msg:
	.asc	") error with SD card", 7, 13, 0

fnd_msg:
	.asc	"Found ", 0
.)
