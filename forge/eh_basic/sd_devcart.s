; devCart SD-card driver module for EhBASIC
; (c) 2023 Carlos J. Santisteban
; last modified 20230504-1748

; uncomment DEBUG version below, does actually write to the card, but also display sector number and contents
;#define	DEBUG
; uncomment STRICT version below, will look for exact match in filenames for LOADing
;#define	STRICT

#echo Using devCart SD card for LOAD and SAVE - interactive filename prompt
#ifdef	DEBUG
#echo Debugging version (displaying sizes?)
#endif

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
#define	CMD24		24
#define	SD_MAX_WRITE_ATTEMPTS	254
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
tmpba	= $E8				; $E8-$E9, no offset unlike multiboot
f_eof	= $EA				; $EA-$EC, current file size, max 16 MiB
f_cur	= f_eof	+ 3			; $ED-$EF, file cursor
arg		= f_cur	+ 3			; $F0, also current sector
res		= arg	+ 4			; $F4
mosi	= res	+ 5			; $F9
miso	= mosi	+ 1			; $FA
token	= miso	+ 1			; $FB
ptr		= token	+ 1			; $FC-$FD, buffer pointer (wrapping every 512 bytes)
sd_ver	= ptr	+ 2			; $FE
crc		= sd_ver+ 1			; $FF

; *** sector buffer and header pointers ***

tmp_siz	= $2FA				; $2FA-$2FB top 16 bits of temporary size for remaining free block (max. 16M)
hd_cache= tmp_siz+2			; $2FC-$2FF current header sector position (big-endian)
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
	LDA f_cur+2				; just in case
	CMP f_eof+2
	BCC not_eof
	LDA f_cur+1
	CMP f_eof+1				; compare cursor to size
	BCC not_eof				; if below, no EOF (sequential only)
		LDA f_cur
		CMP f_eof			; EEEEEEEEEEK
	BCC not_eof
; EOF is there, restore devices and we're done
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
	BNE rd_byte
		INC f_cur+2
rd_byte:
	TAY						; exit value
	CLC						; eeeeeeeek
	RTS

; *************************************************
+aux_out:					; *** device output ***
	TYA						; eeeeeeek
	STA (ptr)				; store into buffer
	INC ptr					; next 
	BNE adv_wbyte
		INC ptr+1
		LDX ptr+1			; check page
		CPX #>(buffer+512)	; usually 5 EEEEEEEEK
	BNE adv_wbyte
		JSR flush_sd		; write current sector
		LDX #>buffer
		STX ptr+1			; wrap buffer pointer (assume page aligned) EEEEEEEEK
		INC arg+3			; advance to next sector
	BNE adv_wbyte
		INC arg+2
	BNE adv_wbyte
		INC arg+1
	BNE adv_wbyte
		INC arg
adv_wbyte:
	INC f_cur				; another byte written
	BNE wr_byte
		INC f_cur+1
	BNE wr_byte
		INC f_cur+2
wr_byte:
	LDX f_cur+2				; just in case
	CPX f_eof+2
	BCC has_room
	LDX f_cur+1
	CPX f_eof+1				; compare against free space limit
	BCC has_room
		LDX f_cur
		CPX f_eof
	BCC has_room			; if ran out of space...
		LDX #0
oos_loop:
			LDY oospace, X
		BEQ oos_end
			PHX
			JSR conio
			PLX
			INX
			BNE oos_loop
oos_end:
		LDX #2				; device 2 is NULL eeeeeeek
		STX stdout			; redirect output to NULL!
		SEC					; notify error, probably ignored
has_room:
	RTS						; if arrived from 

; **********************************************************************************
+aux_load:					; *** prepare things for LOAD, Carry if not possible ***
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
		LDX #1				; actual read starts one page after the header
		STX f_cur+1			; reset file position, must skip header for reading
		STZ f_cur+2			; eeek
		STZ ptr
		LDA #>(buffer+256)	; eeeeeeeek
		STA ptr+1			; skip header in buffer eeeeeeeek
		LDA fsize+2			; now with 24-bit addressing
		LDX fsize+1			; eeeeeeeek
		LDY fsize
		STY f_eof
		STX f_eof+1
		STA f_eof+2
		CLC
auxl_end:
	RTS

; **********************************************************************************
+aux_save:					; *** prepare things for SAVE, Carry if not possible ***
	JSR set_name
		BCS do_save
	JMP auxs_end			; do nothing in case of error (file exists)
do_save:
; locate free, change name and reset pointers 
		STZ arg
		STZ arg+1
		STZ arg+2
		STZ arg+3			; back to first sector, actually should return to cached volume start
		LDA #>buffer
		STA ptr+1
		JSR ssec_rd			; read actual sector
scan_free:
			LDA magic1		; check magic1
		BNE auxs_end		; no more valid headers
			LDA magic2		; check magic2
			CMP #13
		BNE auxs_end
			LDA magic3		; if file<16 MiB
		BNE auxs_end
			LDA bootsig		; check signature
			CMP #'d'
			BNE skp_free	; not valid, skip to next header
				LDA bootsig+1
				CMP #'L'	; looking for free space...
		BEQ fnd_free		; found!
skp_free:
			JSR nxt_head	; jump and load next header
			BRA scan_free	; check this new header
fnd_free:
; currently at free space header
; cache it position for closing!
		LDX #3				; max offset
hdcach_st:
			LDA arg, X
			STA hd_cache, X	; copy sector number into cache (big endian!)
			DEX
			BPL hdcach_st
		LDA fsize+2			; get free block size
		LDX fsize+1
		LDY fsize			; likely to be zero
		STY f_eof
		STX f_eof+1
		STA f_eof+2			; store a copy of size (under 16 MiB)
; set new name
		LDY #0
cpy_name:
			LDA (ut1_pl), Y	; copy character
			STA fname, Y
		BEQ name_copied
			INY
			CPY #220		; maximum size!
			BNE cpy_name
		LDA #0				; in case of excessive length
		STA fname, Y		; terminate string
name_copied:
		INY
		STA fname, Y		; second terminator
; change signature from dL to dA
		LDA #'A'			; generic file signature
		STA bootsig+1
; won't be setting timestamp for now
; preset pointers
		STZ f_cur
		LDA #1				; starts at page 1 of file, skipping header!
		STA f_cur+1
		STZ f_cur+2			; eeek
		STZ ptr
		LDA #>(buffer+256)
		STA ptr+1
; confirm it's saving
		LDX #0
is_svng:
			LDY save_msg, X
		BEQ save_rdy
			PHX
			JSR conio
			PLX
			INX
			BNE is_svng
save_rdy:
		CLC					; allow actual SAVE
		RTS
auxs_end:
	SEC						; file exists, thus do Function call error
	RTS

; ******************************************************
+aux_close:					; *** tidy up after SAVE ***
;---------- save current sector, reload header, keep size, set size to cursor+256, regenerate free after it of old size-actual
; flush current sector... unless it's beyond EOF!
	LDA stdout				; check output device
	CMP #4					; must be AUX! (never NULL, #2)
		BEQ do_close
	JMP aux_closed
do_close:
		JSR flush_sd		; save current buffered sector
; the safest way is to generate the new free header after this sector (if there's room for it!),
; compute remaining free space into fsize
; round actual size into next 512-byte block
	LDX f_cur+2				; get MSB just in case
	LDA f_cur+1				; number of pages
	LDY f_cur				; check whether last sector is full
	BEQ cl_nofill
		INC					; round up to next page
		BNE cl_nofill		; always check carry
			INX
cl_nofill:
	BIT #1					; if odd...
	BEQ cl_fullsec
		INC					; ...add one more page for full sector
		BNE cl_fullsec
			INX
cl_fullsec:
	STA tmp_siz				; store mid byte(LSB is always zero)
	STX tmp_siz+1			; MSB may change
; rounded-up size is at tmp_size, let's compute previous free (f_eof) minus rounded size for the newly created header
	SEC
	LDA f_eof+1				; LSB is always zero during writes, of course
	SBC tmp_siz
	STA tmp_siz
	LDA f_eof+2				; MSB
	SBC tmp_siz+1
	STA tmp_siz+1			; computed value updated
; should skip the following if computed remaining size is ZERO (MSB was into A)
	ORA tmp_siz				; any remaining free space?
	BEQ close_hd			; if not, just update file header
; advance one sector for the new free block header
		INC arg+3
	BNE gen_free
		INC arg+2
	BNE gen_free
		INC arg+1
	BNE gen_free
		INC arg
gen_free:
; compose next free block header
		STZ magic1
		STZ magic3
		STZ fname			; free blocks have no name nor comment!
		STZ fname+1
		LDA #13
		STA magic2			; recognisable header
		LDA #'d'
		STA bootsig
		LDA #'L'			; free block signature
		STA bootsig+1
		LDA #'*'
		LDX #3				; max index from bootsig+2 (2...5)
star_fill:
			STA bootsig+2, X			; better fill the reserved field with stars
			DEX
			BPL star_fill
		LDX tmp_siz+1		; eeeeek
		LDY tmp_siz
		STX fsize+2
		STY fsize+1
		STZ fsize			; free blocks have always LSB = 0
		JSR flush_sd		; write actual free block
close_hd:
; then modify the current header (location cached somewhere!) to reflect actual size (and timestamp)
	LDX #3					; max sector offset
back2hd:
		LDA hd_cache, X
		STA arg, X
		DEX
		BPL back2hd			; copy cached sector number (big-endian!) into arg
	JSR ssec_rd				; get header back
; modify size accordingly
	LDX #2					; max size index <16M
new_size:
		LDA f_cur, X
		STA fsize, X
		DEX
		BPL new_size
; modify timestamp ---
	STZ fdate
	STZ fdate+1
	STZ ftime
	STZ ftime+1				; --- with no RTC this far, modify date will be midnight Jan-1 1980
	JSR flush_sd			; update media
; CLC or something?
aux_closed:
	RTS

; *** ask for name, perhaps list directory, and return C if not found ***
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
; * new, display free blocks! *
				CMP #'L'	; free space?
				BNE mark_exe
					LDY #'@'			; NEW free space indicator
					JSR conio			; display it...
				BRA prn_name			; ...but no more to show (name is empty and I need the CR anyway)
mark_exe:
; * end of free block display *
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
;	JMP chk_fn				; look for name, C set if not found, and return

; *** look for file and return C if not found ***
chk_fn:
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
			BEQ cmp_end					; search pattern ended without any mismatch
				CMP fname, Y			; compare chars
			BNE skp_fi					; different
				INY
				BNE cmp_name			; no need for BRA
skp_fi:
		JSR nxt_head		; jump and load next header
		BRA chk_fn			; check this new header
bad_name:
	SEC
	RTS
; if arrived here, we found the file... or something matching the search term
cmp_end:
#ifdef	STRICT
; --- uncomment these for strict name matching --- enabled with STRICT option
	LDA fname, Y			; check current position in filename
		BNE skip_fi			; if not a terminator, match is incomplete
#endif
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
#ifdef	DEBUG
	LDY #'['
	JSR conio
	LDY #'$'
	JSR conio
	LDA fsize+2				; page MSB
	JSR disphex
	LDA fsize+1
	JSR disphex
	LDA fsize
	JSR disphex
	LDY #']'
	JSR conio
#endif
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
	CLC				; eeeeeeeek (could come from BNE, not always BCC)
	LDA fsize+1
	ADC arg+3		; add to current sector, note big-endian!
	STA arg+3
	LDA fsize+2		; **
	ADC arg+2
	STA arg+2
;	LDA fsize+3		; just in case...
	LDA #0			; eeeeeek
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

; *** *** special version of the above, in case SDSC is byte-addressed, CMD17 and CMD24 only *** ***
ba_cmd:
; send command header
	ORA #$40
	JSR spi_tr				; SPI_transfer(cmd|0x40);
; precompute byte-addressed sector
	LDA arg+3
	ASL
	STA tmpba+1
	LDA arg+2
	ROL
	STA tmpba
	LDA arg+1
	ROL						; A holds MSB
; send argument
	JSR spi_tr
	LDA tmpba
	JSR spi_tr
	LDA tmpba+1
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

; ******************************** generic interface
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
		SEC
		ROR sd_ver			; *** attempt of marking D7 for SDSC cards, byte-addressed!
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
;		LDA res				; *** wait for zero response
;	BNE sd_sc				; *** maybe a timeout would be desired too

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

; **************************
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
	BIT sd_ver				; *** check whether SC or HC/XC
	BPL is_hcxc
		JSR ba_cmd			; SD_command(CMD17, sector, CMD17_CRC); *** a special version for SDSC cards is needed
		BRA cmd_ok
is_hcxc:
	JSR sd_cmd				; SD_command(CMD17, sector, CMD17_CRC); *** regular block-addressed version
cmd_ok:
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

; *********************************
; *** save current sector to SD ***
flush_sd:
#ifdef	DEBUG
; DEBUG version, display sector number (hex) in brackets
	LDY #14
	JSR conio
	LDY #'['
	JSR conio
	LDA arg+1
	JSR disphex
	LDA arg+2
	JSR disphex
	LDA arg+3
	JSR disphex
	LDY #']'
	JSR conio
	LDY #15
	JSR conio
	LDY #13
	JSR conio
; DEBUG, display sector contents in ASCII
	LDX #0					; 256 words = 512 bytes
	STX ptr					; no need for STZ
	LDA #>buffer
	STA ptr+1
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
	LDY #13
	JSR conio				; newline and... continue
#endif
; * intended to write from $0300 *
	LDA #>buffer
;	LDY #<buffer			; expected to be page-aligned
	STA ptr+1
	STZ ptr					; or STY, if set
; * standard sector write, assume arg set with sector number *
; set token to none
	LDA #$FF
	STA token
	JSR cs_enable			; assert chip select
; send CMD24 (sector already at arg.l)
	STZ crc					; ** assume CMD24_CRC is 0 **
	LDA #CMD24
	BIT sd_ver				; *** check whether SC or HC/XC
	BPL sv_hcxc
		JSR ba_cmd			; SD_command(CMD24, sector, CMD24_CRC); *** a special version for SDSC cards is needed
		BRA svcmd_ok
sv_hcxc:
	JSR sd_cmd				; SD_command(CMD24, sector, CMD24_CRC); *** regular block-addressed version
svcmd_ok:
; read response
	JSR rd_r1
	LDA res					; EEEEEEEEEEEK
	BNE no_wres				; if(res[0]==SD_READY) {
; send start token
		LDA #$FE
		JSR spi_tr			; SPI_transfer(SD_START_TOKEN);
; write buffer to card		; for(uint16_t i = 0; i < SD_BLOCK_LEN; i++) SPI_transfer(buf[i]);
wblock:
			LDX #0			; 256-times loop reading 2-byte words => 512 bytes/sector
byte_wr:
				LDA (ptr)	; get one byte
				JSR spi_tr
				INC ptr		; won't do any page crossing here, as long as the base address is EVEN
				LDA (ptr)	; get a second byte
				JSR spi_tr
				INC ptr
				BNE bwr_nw
					INC ptr+1
bwr_nw:
				INX
				BNE byte_wr
; wait for a response token (timeout = 250ms)
wr_done:
		LDX #SD_MAX_WRITE_ATTEMPTS
wr_tok:
			DEX
		BEQ chk_wtok		; this is done FOUR times for a single-byte timeout loop, each iteration ~1 ms
			LDA #$FF
			JSR spi_tr
			CMP #$FF
		BNE brk_wtok
			LDA #$FF
			JSR spi_tr
			CMP #$FF
		BNE brk_wtok
			LDA #$FF
			JSR spi_tr
			CMP #$FF
		BNE brk_wtok
			LDA #$FF
			JSR spi_tr
			CMP #$FF
			BEQ wr_tok		; if((read = SPI_transfer(0xFF)) != 0xFF)
brk_wtok:
		LDY #$FF
		STY token			; { *token = 0xFF; break; }
chk_wtok:
		AND #$1F
		CMP #5				; if((read & 0x1F) == 0x05)
		BNE no_wres
			STA token		; *token = 0x05
; wait for write to finish (timeout = 250ms)
			LDX #SD_MAX_WRITE_ATTEMPTS
wr_end:
				LDA #$FF
				JSR spi_tr	; again, this is done FOUR times for ~1 ms iteration time
			BNE no_wres
				LDA #$FF
				JSR spi_tr
			BNE no_wres
				LDA #$FF
				JSR spi_tr
			BNE no_wres
				LDA #$FF
				JSR spi_tr
			BNE no_wres
				DEX
				BNE wr_end
			STZ token
no_wres:
	JSR cs_disable			; deassert chip select
	LDA res
; * restore buffer access for convenience *
	LDX #>buffer
	STX ptr+1				; wrap buffer pointer (assume page aligned) eeeeek
	RTS
;#endif

#ifdef	DEBUG
; DEBUG support, display byte in hex
disphex:
	PHA						; save for later
	LSR
	LSR
	LSR
	LSR						; MSB first
	JSR bin2hex
	PLA
	AND #15					; restore LSB
bin2hex:
	CLC
	ADC #'0'				; convert to ASCII
	CMP #':'				; 10 or more?
	BCC no_let
		ADC #6				; add 7 (C was set)
no_let:
	TAY
	JMP conio				; display and return
#endif

; **************************************************
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
	JMP LAB_WARM

; ********************
; *** diverse data ***
; ********************

aux_prompt:
	.asc	"Filename", 0

fail_msg:
	.asc	") error with SD card", 7, 13, 0

fnd_msg:
	.asc	"Found ", 0

save_msg:
	.asc	"Saving...", 13, 0

oospace:
	.asc	"Out of space!", 7, 13, 0
.)
