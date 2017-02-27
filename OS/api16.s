; minimOS·16 generic Kernel API!
; v0.5.1b15, should match kernel16.s
; (c) 2016-2017 Carlos J. Santisteban
; last modified 20170227-2235

; no way for standalone assembly, neither internal calls...

; ***************************************
; *** dummy function, not implemented ***
; ***************************************

unimplemented:			; placeholder here, not currently used
	.xs: SEP #$10		; standard index size for a moment
	_ERR(UNAVAIL)		; go away!


; ********************************
; *** COUT, output a character ***
; ********************************
;		INPUT
; Y		= dev
; io_c	= char
;		OUTPUT
; C = I/O error
;		USES iol_dev, plus whatever the driver takes
; cio_lock is a kernel structure
; * 8-bit savvy *

cout:
	.as: .xs: SEP #$30	; *** standard register size *** (3)
; switch DBR as it accesses a lot of kernel data!
	PHB					; eeeeeeeeek (3)
	PHK					; bank zero into stack (3)
	PLB					; set DBR! do not forget another PLB upon end! (4)
; proceed
	TYA					; update flags upon dev number (2)
	BNE co_port			; not default (3/2)
		LDA stdout			; new per-process standard device (3)
		BNE co_port			; already a valid device (3/2)
			LDA default_out		; otherwise get system global (4)
co_port:
	BMI co_phys			; not a logic device (3/2)
		CMP #64				; first file-dev??? (2)
			BCC co_win			; below that, should be window manager (3/2)
; ** optional filesystem access **
#ifdef	FILESYSTEM
		CMP #64+MAX_FILES	; still within file-devs?
			BCS co_log			; that value or over, not a file
; *** manage here output to open file ***
#endif
; *** virtual windows manager TO DO ***
co_win:
		LDY #NO_RSRC		; not yet implemented ***placeholder***
		PLB					; restore DBR!!!
		BRA cio_setc		; direct error notify
; ** end of filesystem access **
co_log:
; investigate rest of logical devices
		CMP #DEV_NULL		; lastly, ignore output
		BEQ co_ok			; /dev/null is always OK
; final error otherwise
			LDY #N_FOUND		; unknown device
			BRA cio_abort		; restore & notify
co_ok:
		PLB					; restore!!!
		RTI					; end of function without errors
co_phys:
; arrived here with dev # in A
; new per-phys-device MUTEX for COUT, no matter if singletask!
	ASL					; convert to proper physdev index (2)
	STA iol_dev			; keep device-index temporarily, worth doing here (3)
; CS not needed for MUTEX as per 65816 API
co_loop:
		LDX iol_dev			; retrieve index!
		LDA cio_lock, X		; check whether THAT device is in use (4) 24-bit!
			BEQ co_lckd			; resume operation if free (3)
; otherwise yield CPU time and repeat
; faster KERNEL(B_YIELD)
		LDX #MM_YIELD		; internal multitasking index (2)
		JSR (drv_opt-MM_YIELD, X)	; direct to driver skipping the kernel, note deindexing! (8)
		BRA co_loop			; try again! (3)
co_lckd:
	JSR cio_pid			; get ours in A, corrected for singletask systems!
	STA cio_lock, X		; *reserve this (4)
; 65816 API runs on interrupts off, thus no explicit CS exit
; direct driver call, proper physdev index in X
	JSR (drv_opt, X)	; direct CALL!!! driver should end in RTS as usual via the new DR_ macros

; ***************************
; *** common I/O routines ***
; ***************************

; ** cio_unlock **
; gets physdevnum and clears its mutex, restores DBR and exit with proper error code if C set
; must be called in all 8-bit size!!!
cio_unlock:
	LDX iol_dev			; **need to clear new lock! (3)
	STZ cio_lock, X		; ...because I have to clear MUTEX! *new indexed form (4)
	PLB					; we are leaving... into cio_callend

; ** cio_callend **
; preserve C status after the RTI, signaling error to caller
; may be called from whatever register size!
cio_callend:
	BCC cio_notc		; no need to clear carry
; alternative exit for precomputed error codes
cio_setc:
		PLP
		SEC					; otherwise set stored carry
		PHP
cio_notc:
	RTI					; end of call procedure

; ** cio_abort **
; will restore DBR and then notify error directly...
; likely to become inline
cio_abort:
	PLB					; restore DBR!!!
	BRA cio_setc		; direct notify error

; ** cio_pid **
; return ASAP running (corrected) PID of this task, uses new SET_CURR interface
; might become inline as is much smaller and faster code!
; * needs 8-bit memory *
cio_pid:
; much faster KERNEL(GET_PID)
	LDA run_pid			; get internally stored PID (4)
	BNE co_mm			; valid PID, no need to simulate (3/2)
		INC					; pseudo PID=1 for singletask systems (0/2)
co_mm:
	RTS					; all done, X and Y were preserved (6)

; *****************************
; *** CIN,  get a character ***
; *****************************
;		INPUT
; Y = dev
;		OUTPUT
; io_c	= char
; C		= not available
;		USES iol_dev, and whatever the driver takes
; cio_lock & cin_mode are kernel structures
; * 8-bit savvy *

cin:
	.as: .xs: SEP #$30	; *** standard register size *** (3)
; switch DBR as it accesses a lot of kernel data!
	PHB					; eeeeeeeeek (3)
	PHK					; bank zero into stack (3)
	PLB					; set DBR! do not forget another PLB upon end! (4)
; proceed
	TYA					; set flags upon devnum (2)
	BNE ci_port			; specified (3/2)
		LDA std_in			; new per-process standard device (3)
		BNE ci_port			; already a valid device (3/2)
			LDA default_in		; otherwise get system global (0/4)
ci_port:
	BPL ci_nph			; logic device (2/3)
; new MUTEX for CIN
	ASL					; convert to proper physdev index (2)
	STA iol_dev			; keep physdev temporarily, worth doing here (3)
; CS not needed for MUTEX as per 65816 API
ci_loop:
	LDX iol_dev			; *restore previous status (3)
	LDA cio_lock, X		; *check whether THAT device in use (4)
	BEQ ci_lckd			; resume operation if free (3)
; otherwise yield CPU time and repeat
; but first check whether it was me (waiting on binary mode)
		JSR cio_pid			; who am I?
		CMP cio_lock, X		; *was it me who locked? (4)
			BEQ ci_lckdd		; *if so, resume execution (3)
; if the above, could first check whether the device is in binary mode, otherwise repeat loop!
; continue with regular mutex
; faster KERNEL(B_YIELD)
		LDX #MM_YIELD		; internal multitasking index (2)
		JSR (drv_opt-MM_YIELD, X)	; direct to driver skipping the kernel, note deindexing! (8)
		BRA ci_loop			; try again! (3)
ci_lckd:
	JSR cio_pid			; who is me?
	STA cio_lock, X		; *reserve this (4)
ci_lckdd:
; 65816 API runs on interrupts off, thus no explicit CS exit
; ** new direct indexing **
		JSR (drv_ipt, X)	; direct CALL!!!
			BCS cio_unlock		; clear MUTEX and return whatever error!

; ** EVENT management **
; this might be revised, or supressed altogether!
		LDX iol_dev			; **use physdev as index! worth doing here (3)
		LDA io_c			; get received character
		CMP #' '			; printable?
			BCS ci_exitOK		; if so, will not be an event, exit with NO error
; otherwise might be an event ** REVISE
; check for binary mode first
		LDY cin_mode, X		; *get flag, new sysvar 20150617
		BEQ ci_event		; should process possible event
			STZ cin_mode, X		; *back to normal mode
ci_exitOK:
			STZ cio_lock, X		; *otherwise clear mutex!!! (4)
			PLB					; essential!
			_EXIT_OK			; all done without error!
ci_event:
		CMP #16				; is it DLE?
		BNE ci_notdle		; otherwise check next
			STA cin_mode, X		; *set binary mode! safer and faster!
			LDY #EMPTY			; and supress received character
			BRA cio_abort		; restore & notify (will stay locked!)
ci_notdle:
		CMP #3				; is it ^C? (TERM)
		BNE ci_noterm		; otherwise check next
			LDA #SIGTERM
			BRA ci_signal		; send signal
ci_noterm:
		CMP #4				; is it ^D? (KILL) somewhat dangerous...
		BNE ci_nokill		; otherwise check next
			LDA #SIGKILL
			BRA ci_signal		; send signal
ci_nokill:
		CMP #26				; is it ^Z? (STOP)
			BNE ci_exitOK		; otherwise there is no more to check
		LDA #SIGSTOP		; last signal to be sent
ci_signal:
		STA b_sig			; set signal as parameter
; much faster KERNEL(GET_PID)
		JSR cio_pid			; internal PID in A
		TAY					; as needed by B_SIGNAL
; faster KERNEL(B_SIGNAL)
		LDX #MM_SIGNAL		; internal multitasking index (2)
		JSR (drv_opt-MM_SIGNAL, X)	; direct to driver skipping the kernel, note deindexing! (8)
		LDY #EMPTY			; no character was received
		SEC					; eeeeeeeek
		JMP cio_unlock		; release device and exit!

ci_nph:
	CMP #64				; first file-dev??? ***
		BCC ci_win			; below that, should be window manager
; ** optional filesystem access **
#ifdef	FILESYSTEM
	CMP #64+MAX_FILES	; still within file-devs?
		BCS ci_log			; that or over, not a file
; *** manage here input from open file ***
#endif
; *** virtual window manager TO DO ***
ci_win:
	LDY #NO_RSRC		; not yet implemented ***placeholder***
	JMP cio_abort		; restore & notify
; manage logical devices...
ci_log:
	CMP #DEV_RND		; getting a random number?
		BEQ ci_rnd			; compute it!
	CMP #DEV_NULL		; lastly, ignore input
		BEQ ci_exitOK
	LDY #N_FOUND		; unknown device
	JMP cio_abort		; restore & notify

ci_rnd:
; *** generate random number (TO DO) ***
	LDA ticks			; simple placeholder
	STA io_c			; eeeeeeeeeeeeeeeeek
	BRA ci_exitOK


; ******************************
; *** MALLOC, reserve memory ***
; ******************************
;		INPUT
; ma_rs		= 24b size (0 means reserve as much memory as available)
; ma_align	= page mask (0=page/not aligned, 1=512b, $FF=bank aligned)
;		OUTPUT
; ma_pt	= 24b pointer to reserved block
; ma_rs	= 24b actual size (esp. if ma_rs was 0, but check LSB too)
; C		= not enough memory/corruption detected
;		USES ma_ix.b, ma_lim
; ram_stat & ram_pid (= ram_stat+1) are interleaved in minimOS-16
; * MUST limit 6502 blocks to "current" bank!!! * TO DO * TO DO
; otherwise it is 02-savvy already
; think about managing the multiple exit points as this is a rather slow function

malloc:
	.al: REP #$20		; *** 16-bit memory ***
	.xs: SEP #$10		; *** 8-bit indexes ***
	PHB					; eeeeeeeek! do not forget to restore
	LDX #0				; reset index
	PHX					; put one zero byte into stack
	PLB					; preset DBR as default zero!
	STX ma_align+1		; **clear MSB in cass of a 16-bit BIT!**
; detect caller architecture in order to enable 24-bit addressing
	LDY run_arch		; zero for native 65816, respect X as it holds zero
	BEQ ma_24b			; OK for 24b addressing
		STX ma_rs+2			; clear it just in case!
		PLY					; otherwise get saved bank, respecting X...
		PHY					; ...restore it...
		STY ma_lim			; ...and set as only feasible bank
		STY ma_lim+1		; maximum (MSB) is the same as minimum (LSB)
		BRA ma_go			; continue
ma_24b:
	LDA #$FF00			; full range of banks
	STA ma_lim			; set unrestricted limits
ma_go:
; limits set, proceed as usual
	LDY ma_rs			; check individual bytes, just in case
	BEQ ma_nxpg			; no extra page needed
		INC ma_rs+1			; otherwise increase number of pages
		STX ma_rs			; ...and just in case, clear asked bytes!
ma_nxpg:
; default 816 API functions run on interrupts masked, thus no need for CS
	LDA ma_rs+1			; get number of asked pages
	BNE ma_scan			; work on specific size
; ***TO DO check limits
; otherwise check for biggest available block -- new ram_stat word format 161105
ma_biggest:
#ifdef	SAFE
			CPX #MAX_LIST*2		; already past?
				BEQ ma_corrupt		; something was wrong!!!
; *** self-healing feature for full memory assignment! ***
			LDA ram_pos+2, X	; get end position (5)
			SEC
			SBC ram_pos, X		; subtract current for size! (2+5)
				BCC ma_corrupt		; corruption detected!
#endif
			LDY ram_stat, X		; get status of block (4)
;			CPY #FREE_RAM		; not needed if FREE_RAM is zero! (2)
			BNE ma_nxbig		; go for next as this one was not free (3/2)
				JSR ma_alsiz		; **compute size according to alignment mask**
				CMP ma_rs+1			; compare against current maximum (4)
				BCC ma_nxbig		; this was not bigger (3/2)
					STA ma_rs+1			; otherwise keep track of it... (4)
					STX ma_ix			; ...and its index! (3)
ma_nxbig:
			INX					; advance index (2+2)
			INX
			LDY ram_stat, X		; peek next status (4)
			CPY #END_RAM		; check whether at end (2)
			BNE ma_biggest		; or continue (3/2)
; is there at least one available block?
		LDA ma_rs+1			; should not be zero
		BNE ma_fill			; there is at least one block to allocate
			PLB				; restore!
			_ERR(FULL)		; otherwise no free memory!
; report allocated size
ma_fill:
		LDX ma_ix			; retrieve index
		BRA ma_falgn		; nothing to scan, only if aligned eeeeeek
ma_scan:
; *** this is the place for the self-healing feature! ***
#ifdef	SAFE
		CPX #MAX_LIST*2		; already past?
			BEQ ma_corrupt		; something was wrong!!!
; check UNALIGNED size for self-healing feature! worth a routine?
		LDA ram_pos+2, X	; get end position (5)
		SEC
		SBC ram_pos, X		; subtract current for size! (2+5)
		BCS ma_nobad		; no corruption was seen (3/2) **instead of BPL** eeeeeek
ma_corrupt:
			LDX #>user_sram		; beginning of available ram, as defined... in rom.s
			LDY #<user_sram		; LSB misaligned?
			BEQ ma_zlsb			; nothing to align
				INX					; otherwise start at next page
ma_zlsb:
			TXA					; will set MSB (bank) as zero
			LDX #LOCK_RAM		; ...that will become locked (new value)
			STA ram_pos			; create values
			STX ram_stat		; **should it clear the PID field too???**
			LDA #SRAM			; physical top of RAM...
			LDX #END_RAM		; ...as non-plus-ultra
			STA ram_pos+2		; create second set of values
			STX ram_stat+2
			PLB					; restore!
			_ERR(CORRUPT)		; report but do not turn system down
ma_nobad:
#endif
		LDY ram_stat, X		; get state of current entry (4)
;		CPY #FREE_RAM		; looking for a free one (2) not needed if free is zero
			BEQ ma_found		; got one (2/3)
		CPY #END_RAM		; got already to the end? (2)
			BEQ ma_nobank		; could not found anything suitable (2/3)
ma_cont:
		INX					; increase index (2+2)
		INX
		CPX #MAX_LIST*2		; until the end (2+3)
		BNE ma_scan
ma_nobank:
; one end of CS
	PLB					; restore!
	_ERR(FULL)			; no room for it!
ma_found:
	JSR ma_alsiz		; **compute size according to alignment mask**
	CMP ma_rs+1			; compare (5)
		BCC ma_cont			; smaller, thus continue searching (2/3)
; here we go! first of all check whether aligned or not
ma_falgn:
	PHA					; save current size
	LDA ram_pos, X		; check start address for alignment failure
	BIT ma_align		; any offending bits?
	BEQ ma_aok			; already aligned, nothing needed
		ORA ma_align		; set disturbing bits...
		INC					; ...and reset them after increasing the rest
		PHA					; need to keep the new aligned pointer!
		JSR ma_adv			; create room for assigned block (BEFORE advancing eeeeeeeek)
		INX					; skip the alignment blank
		INX
		PLA					; retrieve aligned address
		STA ram_pos, X		; update pointer on assigned block
ma_aok:
	PLA					; retrieve created blank size (skipped possible alignment block)
; make room for new entry... if not exactly the same size
	CMP ma_rs+1			; compare this block with requested size eeeeek
	BEQ ma_updt			; was same size, will not generate new entry
; **in safe mode should push 16 bits into stack for proper address discarding!
		JSR ma_adv			; make room otherwise, and set the following one as free padding
; **in safe mode should toss the previoulsy stacked word
; create after the assigned block a FREE entry!
		LDA ram_pos, X		; newly assigned slice will begin there eeeeeeeeeek
		CLC
		ADC ma_rs+1			; add number of assigned pages
		STA ram_pos+2, X	; update value
		LDA #FREE_RAM		; let us mark it as free, PID is irrelevant!
		STA ram_stat+2, X	; next to the assigned one, no STY abs,X!!!
ma_updt:
	STZ ma_pt			; clear pointer LSB... plus extra byte
	LDA ram_pos, X		; get address of block to be assigned
	STA ma_pt+1			; note this is address of PAGE
	LDA #USED_RAM		; now is reserved
	STA ram_stat, X		; update table entry, will destroy PID temporarily but no STY abs,X!!!
; ** new 20161106, store PID of caller **
	.as: SEP #$20		; *** back to 8-bit because interleaved array! ***
	LDA run_pid			; get uncorrected PID in A
	STA ram_pid, X		; store PID, interleaved array will apply some offset
; theoretically we are done, end of CS
	PLB					; restore!
	_EXIT_OK

	.al					; as routines will be called in 16-bit memory!!!

; **** routine for aligned-block size computation ****
; returns found size in A, sets C if OK, error otherwise (C clear!)
ma_alsiz:
	LDA ram_pos, X		; get bottom address (5)
	BIT ma_align		; check for set bits from mask (5)
	BEQ ma_fit			; none was set, thus already aligned (3/2)
		ORA ma_align		; set masked bits... (4)
		INC					; ...and increase address for alignment (2)
ma_fit:
	EOR #$FFFF			; invert bits as will be subtracted to next entry (3)
	SEC					; needs one more for twos-complement (2)
	ADC ram_pos+2, X	; compute size from top ptr MINUS bottom one (5)
	RTS

; **** routine for making room for an entry ****
ma_adv:
	STX ma_ix			; store current index
ma_2end:
		INX					; previous was free, thus check next
		INX
#ifdef	SAFE
		CPX #MAX_LIST*2		; just in case, check offset!!! eeeeeeek^2
		BCC ma_notend		; could expand
			PLA					; discard return address (still in 16-bit mode)
			JMP ma_nobank		; notice error
ma_notend:
#endif
		LDY ram_stat, X		; check status of block
		CPY #END_RAM		; scan for the end-of-memory marker
		BNE ma_2end			; hope will eventually finish!
ma_room:
		LDA ram_pos, X		; get block address
		STA ram_pos+2, X	; one position forward
		LDA ram_stat, X		; get block status **plus new PID field, new 161106**
		STA ram_stat+2, X	; advance it **would use LDY/STY if not storing PID**
		DEX					; down one entry
		DEX
		CPX ma_ix			; position of updated entry
		BNE ma_room			; continue until done
	RTS


; *******************************
; **** FREE,  release memory ****
; *******************************
;		INPUT
; ma_pt = 24b addr
;		OUTPUT
; C = no such used block
;
; ram_pos & ram_stat are kernel structures
; * 8-bit savvy *

free:
	.al: REP #$20		; *** 16-bit memory ***
	.xs: SEP #$10		; *** 8-bit indexes ***
	PHB					; eeeeeeeek! do not forget to restore
	LDX #0				; reset index
	PHX					; put one zero byte into stack
	PLB					; preset DBR as default zero!
#ifdef	SAFE
	LDY ma_pt			; LSB currently not implemented
		BNE fr_no			; could not find
#endif
; check architecture in order to discard bank address
	LDY run_arch		; will be zero for native 65816, please respect X!
	BEQ fr_24b			; 24-bit enabled
		PLY					; otherwise get stored caller bank...
		PHY					; ...restore it...
		STY ma_pt+2			; ...and use as default
fr_24b:
	LDA ma_pt+1			; get comparison PAGE eeeeeeeeek
fr_loop:
		CMP ram_pos, X		; is what we are looking for?
			BEQ fr_found		; go free it!
		INX					; advance index
		INX
		LDY ram_stat, X		; anyway check status
		CPY #END_RAM		; no more in list?
		BNE fr_loop			; continue until end
; this could be one end of CS
fr_no:
	PLB					; restore!
	_ERR(N_FOUND)		; no such block!
fr_found:
	LDY ram_stat, X		; only used blocks can be freed!
	CPY #USED_RAM		; was it in use?
		BNE fr_no			; if not, cannot free it!
	LDA #FREE_RAM		; most likely zero, could I use STZ in 16-bit mode??? irrelevant PID
	STA ram_stat, X		; no STY abs,Y... this block is now free, but...
; really should join possible adjacent free blocks
	LDY ram_stat+2, X	; check status of following entry
;	CPY #FREE_RAM		; was it free? could be supressed if value is zero
	BNE fr_notafter		; was not free, thus nothing to optimise forward
		PHX					; keep actual position eeeeeeeek
		JSR fr_join			; integrate following free block
		PLX					; retrieve position
	BEQ fr_ok			; if the first block, cannot look back eeeeeeeeeek
fr_notafter:
	TXY					; check whether it was the first block
		BEQ fr_ok			; do not even try to look back eeeeeeeeeeek
	DEX					; let us have a look to the previous block
	DEX
	LDY ram_stat, X		; is this one free?
;	CPY #FREE_RAM		; could be supressed if value is zero
	BNE fr_ok			; nothing to optimise backwards
		JSR fr_join			; otherwise integrate it too
fr_ok:
; we are done
	PLB					; restore!
	_EXIT_OK

; routine for obliterating the following empty entry
fr_join:
		INX					; go for next entry
		INX
		LDA ram_pos+2, X	; get following address
		STA ram_pos, X		; store one entry below
		LDA ram_stat+2, X	; check status of following! **but PID field too**
		STA ram_stat, X		; store one entry below **otherwise LDY/STY**
		TAY					; **will transfer just status, PID will be ripped off**
		CPY #END_RAM		; end of list?
		BNE fr_join			; repeat until done
	DEX					; return to previous position
	DEX
	RTS


; **************************************
; *** OPEN_W, get I/O port or window ***
; **************************************
;		INPUT
; w_rect	= 16b size VV.HH
; w_rect+2	= 16b pos VV.HH
; str_pt	= 24b pointer to title string
;		OUTPUT
; Y = dev
; C = not supported/not available
; * 8-bit savvy *

open_w:
	.al: REP #$20		; *** 16-bit memory size ***
	.xs: SEP #$10		; *** 8-bit register, just in case ***
	LDA w_rect			; asking for some size? includes BOTH bytes
	BEQ ow_no_window	; wouldn't do it
		_ERR(NO_RSRC)
ow_no_window:
	LDY #DEVICE			; constant default device, REVISE
; EXIT_OK on subsequent system calls!!!

; ********************************************************
; *** CLOSE_W,  close window *****************************
; *** FREE_W, release window, will be closed by kernel ***
; ********************************************************
;		INPUT
; Y = dev
; * 8-bit savvy *

close_w:				; doesn't do much
free_w:					; doesn't do much, either
	_EXIT_OK


; **************************************
; *** UPTIME, get approximate uptime ***
; **************************************
;		OUTPUT
; up_ticks	= 16b ticks, new standard format 20161006
; up_sec	= 32b uptime in seconds
; * 8-bit savvy *

uptime:
	.al: REP #$20		; *** optimum 16-bit memory ***
; default 816 API functions run on interrupts masked, thus no need for CS
; not worth setting DBR, note long addressing
		LDA @ticks		; get system variable word (5)
		STA up_ticks	; and store them in output parameter (4)
		LDA @ticks+2	; get system variable uptime (5)
		STA up_sec		; and store it in output parameter (4)
		LDA @ticks+4	; another word, as per new format (5)
		STA up_sec+2	; store that (4)
; end of CS
	_EXIT_OK


; ***************************************************************
; *** LOAD_LINK, get address once in RAM/ROM (in development) ***
; ***************************************************************
;		INPUT
; str_pt = 24b pointer to filename path (will be altered!)
;		OUTPUT
; ex_pt		= 24b pointer to executable code
; cpu_ll	= architecture
;		USES rh_scan
;
; now supports 24-bit addressing! but only for 65816 code
; otherwise, 8-bit savvy

load_link:
; *** first look for that filename in ROM headers ***
	.al: REP #$20		; *** 16-bit memory ***
	.xs: SEP #$10		; *** standard index size ***
; no need to set DBR
; check architecture in order to discard bank address
; *****this is wrong and lacks direct-page savvyness
	LDX run_arch		; will be zero for native 65816
	BEQ ll_24b			; 24-bit enabled
		PLX					; otherwise get stored caller bank...
		PHX					; ...restore it...
		STZ str_pt+2		; ...and use as default (extra byte is cleared)
ll_24b:
; first of all, correct parameter pointer as will be aligned with header!
	LDA str_pt			; get whole pointer (minus bank)
	SEC
	SBC #8				; subtract name position in header!
	STA str_pt			; modified value
	BCS ll_reset		; nothing else to do if no borrow
		DEC str_pt+2		; otherwise will point to previous BANK (may affect fourth byte)
ll_reset:
; get initial address! beacuse of the above, no longer adds filename offset!
	LDA #ROM_BASE		; begin of ROM contents
	STA	rh_scan			; set local pointer
	STZ rh_scan+2		; standard bank for long pointer into kernel function!
ll_geth:
; ** check whether we are on a valid header!!! **
		.as: SEP #$20		; *** back to standard memory ***
		LDA [rh_scan]		; get first byte in header
			BNE ll_nfound		; link was lost, no more to scan
		LDY #7				; after type and size, a CR is expected
		LDA [rh_scan], Y	; get eigth byte in header!
		CMP #CR				; was it a CR?
			BNE ll_nfound		; if not, go away
; look for the name
		INY					; reset scanning index (now at name position, was @7)
ll_nloop:
			LDA [rh_scan], Y	; get character in found name
			CMP [str_pt], Y		; compare with what we are looking for
				BNE ll_nthis		; difference found
			ORA [str_pt], Y		; otherwise check whether at EOL
				BEQ ll_found		; all were zero, both ended names are the same!
			INY					; otherwise continue search
			BNE ll_nloop		; will not do forever, no need for BRA
ll_nthis:
; not this one, correct local pointer for the next header
		LDY #252			; relative offset to size eeeeeeeek
		LDA [rh_scan], Y	; get LSB
		TAX					; keep it
		INY					; advance to number of pages!
		.al: REP #$20		; *** back to 16-bit memory for a moment ***
		LDA [rh_scan], Y	; get number of pages to skip (24-bit pointer)
		TXY					; check that LSB
		BEQ ll_nwad			; if page is not full...
			INC					; ...advance to next boundary EEEEEEEEK
ll_nwad:
		SEC					; ...plus header itself! eeeeeeek
		ADC rh_scan+1		; add to previous value
		STA rh_scan+1		; update pointer
		BCC ll_geth			; inspect new header (if no wrap! 24-bit addressing)
ll_nfound:
	_ERR(N_FOUND)		; all was scanned and the query was not found
ll_found:
; this was the original load_link code prior to 20161202, will be executed after the header was found!
	.as: .xs: SEP #$30	; *** standard register size ***
	LDY #1				; offset for filetype
	LDA [rh_scan], Y	; check filetype
	CMP #'m'			; must be minimOS app!
		BNE ll_wrap			; error otherwise
	INY					; next byte is CPU type then
	LDA [rh_scan], Y	; get it
	CMP #'V'			; Rockwell is the only unsupported type! but look for any other 65xx option
		BEQ ll_native		; native 65816 is OK *AND* will allow 24-bit addressing this far 
	CMP #'B'			; generic 65C02
		BEQ ll_valid		; also OK but will NOT support 24-bit (for now)	
	CMP #'N'			; old NMOS
		BEQ ll_valid		; if neither this one, unsupported CPU type!
ll_wrap:
	_ERR(INVALID)		; unsupported CPU
ll_valid:
; CPU-type is compatible but has 8-bit code, should install 64-byte wrapper at end of bank, or limit to bank zero!
	LDX rh_scan+2			; check THIRD byte, still not supported in 8-bit code
	BEQ ll_native			; still in bank 0, OK to proceed
		_ERR(FULL)				; somewhat confusing error...
ll_native:
; either is 65816 code or 02 into bank zero
	STA cpu_ll			; set CPU type, now will not matter whether XIP or not!
	.al: REP #$20		; *** 16-bit memory again ***
	LDA rh_scan+1		; get pointer MSB+BANK
	INC					; start from next page (skip header)
	STZ ex_pt			; *** assume all headers are page-aligned *** eeeeek
	STA ex_pt+1			; save rest of execution pointer
	_EXIT_OK


; *********************************
; *** STRING, prints a C-string ***
; *********************************
;		INPUT
; Y			= dev
; str_pt	= 24b pointer to string (might be altered!) 24-bit ready!
;		OUTPUT
; C = device error
;		USES str_dev and whatever the driver takes
;
; cio_lock is a kernel structure
; * 8-bit savvy *

string:
; ** actual code from COUT here, might save space using a common routine, but adds a bit of overhead
	.as: .xs: SEP #$30	; *** standard register size ***
; switch DBR as it accesses a lot of kernel data!
	PHB					; eeeeeeeeek
	LDA #0				; this will work on bank 0
	PHA					; into stack
	PLB					; set DBR! do not forget another PLB upon end!
; check architecture in order to discard bank address
	BIT run_arch		; will be zero for native 65816
	BEQ str_24b			; 24-bit enabled
		PLX					; otherwise get stored caller bank...
		PHX					; ...restore it...
		STX str_pt+2		; ...and use as default
str_24b:
; proceed
	TYA					; set flags upon devnum (2)
	BNE str_port		; not default (3/2)
		LDA stdout			; new per-process standard device ### apply this to ·65
		BNE str_port		; already a valid device
			LDA default_out		; otherwise get system global (4)
str_port:
	BMI str_phys		; not a logic device (3/2)
		CMP #64				; first file-dev??? ***
			BCC str_win			; below that, should be window manager
; ** optional filesystem access **
#ifdef	FILESYSTEM
		CMP #64+MAX_FILES	; still within file-devs?
			BCS str_log			; that value or over, not a file
; *** manage here output to open file ***
#endif
; *** virtual windows manager TO DO ***
str_win:
		LDY #NO_RSRC		; not yet implemented ***placeholder***
		BRA str_abort		; restore and notify
; ** end of filesystem/window access **
str_log:
; investigate rest of logical devices
		CMP #DEV_NULL		; lastly, ignore output
			BNE str_nfound		; final error otherwise
; /dev/null is always OK
str_exit:
		PLB					; restore!!!
		RTI					; end of function without errors
str_nfound:
	LDY #N_FOUND		; unknown device
str_abort:
	PLB					; restore!
	JMP cio_setc		; notify error directly

; proceed with a physical device number
str_phys:
; new MUTEX eeeeeeek
	ASL					; convert to index (2)
	STA str_dev			; store for indexed call! (3)
; CS not needed for MUTEX as per 65816 API
str_wait:
	LDX str_dev			; restore previous status, *new style (3)
	LDA cio_lock, X		; *check whether THAT device in use (4)
	BEQ str_lckd		; resume operation if free (3)
; otherwise yield CPU time and repeat
;		KERNEL(B_YIELD)		; give way... scheduler would switch on interrupts as needed *** direct internal API call!
		LDX #MM_YIELD		; internal multitasking index (2)
		JSR (drv_opt-MM_YIELD, X)	; direct to driver skipping the kernel, note deindexing! (8)
		BRA str_wait		; try again! (3)
str_lckd:
	JSR cio_pid			; who am I?
	STA cio_lock, X		; *reserve this (4)
; 65816 API runs on interrupts off, thus no explicit CS exit
; continue with mutually exclusive COUT code
	LDY #0				; eeeeeeeek! (2)
; ** the actual printing loop **
str_loop:
		PHY					; save just in case COUT destroys it (3)
		LDA [str_pt], Y		; get character from string, new approach, now 24-bit!
		BNE str_cont		; not terminated! (3/2)
			PLA					; otherwise discard saved Y (4) eeeeeeeek
			BRA str_exit		; and go away!
str_cont:
		STA io_c			; store output character for COUT (3)
		LDX str_dev			; get driver pointer position (3)
		JSR (drv_opt, X)	; go at stored pointer (...6)
			BCS str_err			; return error from driver
		PLY					; restore index (4)
		INY					; eeeeeeeeeeeek (2)
		BNE str_loop		; still within same page
	INC str_pt+1		; otherwise increase, parameter has changed! should I save it?
	BRA str_loop		; continue, will check for termination later (3)
str_err:
	PLX					; discard saved Y while keeping error code eeeeeeeeeek^2
	JMP cio_unlock		; otherwise return code AND clear MUTEX eeeeeeeeeek^2


; ******************************
; *** READLN, buffered input ***
; ******************************
;		INPUT
; Y			= dev
; str_pt	= 24b pointer to buffer (24-bit mandatory)
; ln_siz	= max offset
;		OUTPUT
; C = some error
;		USES rl_dev, rl_cur and whatever CIN/COUT take
; * 8-bit savvy *

readLN:
	.as: .xs: SEP #$30	; *** standard register size ***
; no need to switch DBR as regular I/O calls would do it
; check architecture in order to discard bank address
	BIT run_arch		; will be zero for native 65816
	BEQ rl_24b			; 24-bit enabled
		PHB					; otherwise get (current) caller bank...
		PLA					; ...get its value...
		STA str_pt+2		; ...and use as default in pointer
rl_24b:
	STY rl_dev			; preset device ID!
	STZ rl_cur			; reset variable
rl_l:
		_KERNEL(B_YIELD)	; always useful
		LDY rl_dev			; use device
		_KERNEL(CIN)		; get one character
		BCC rl_rcv			; got something
			CPY #EMPTY			; otherwise is just waiting?
		BEQ rl_l			; continue then
rl_abort:
			LDA #0				; no indirect STZ
			STA [str_pt]		; if any other error, terminate string at the beginning
			JMP cio_setc		; and return whatever error
rl_rcv:
		LDA io_c			; get received
		LDY rl_cur			; retrieve index
		CMP #CR				; hit CR?
			BEQ rl_cr			; all done then
		CMP #BS				; is it backspace?
		BNE rl_nbs			; delete then
			TYA					; check index
				BEQ rl_l			; ignore if already zero
			DEC rl_cur			; otherwise reduce index
			BRA rl_echo			; and resume operation
rl_nbs:
		CPY ln_siz			; overflow? eeeeeeeeeeeek
			BCS rl_l			; ignore if so
		STA [str_pt], Y		; store into buffer
		INC	rl_cur			; update index
rl_echo:
		LDY rl_dev			; retrieve device
		_KERNEL(COUT)		; echo received character
		BRA rl_l			; and continue
rl_cr:
	LDY rl_dev			; retrieve device
	_KERNEL(COUT)		; print newline (ignoring errors)
	LDY rl_cur			; retrieve cursor!!!!!
	LDA #0				; no STZ indirect indexed
	STA [str_pt], Y		; terminate string
	_EXIT_OK			; and all done!


; **************************************************
; *** SET_FG, enable/disable frequency generator *** TO BE REVISED
; **************************************************
;		INPUT
; zpar.w = dividing factor (times two?)
;		OUTPUT
; C = busy
;
; should use some firmware interface, just in case it doesn't affect jiffy-IRQ!
; should also be Phi2-rate independent... input as Hz, or 100uS steps?
; *** TO DO *** temporarily made 8-bit savvy

set_fg:
	.al: REP #$20		; *** 16-bit memory ***
	.xs: SEP #$10		; *** 8-bit indexes ***
; switch DBR as it accesses a lot of kernel data!
	PHB					; eeeeeeeeek (3)
	LDX #0				; this will work on bank 0 (2)
	PHX					; into stack (3)
	PLB					; set DBR! do not forget another PLB upon end! (4)
; proceed	
	LDA zpar			; take whole word
		BEQ fg_dis			; if zero, disable output
	LDX VIA+ACR		; get current configuration byte
		BMI fg_busy			; already in use
	LDA VIA+T1LL		; get older T1 latch values
	STA old_t1			; save them
; *** TO_DO - should compare old and new values in order to adjust quantum size accordingly ***
	LDA zpar			; get new division factor
	STA VIA+T1LL		; store it
	STA VIA+T1CH		; get it running!
	.as: SEP #$20		; *** back to 8-bit memory ***
	TXA					; process configuration
	ORA #$C0			; enable free-run PB7 output
	STA VIA+ACR			; update config
fg_none:
	PLB					; restore!
	_EXIT_OK			; finish anyway

	.al					; called from above

fg_dis:
	LDX VIA+ACR			; get current configuration
		BPL fg_none			; it wasn't playing!
	TXA					; process configuration
	AND #$007F			; disable PB7 only
	TAX					; please respect 2nd byte!
	STX VIA+ACR			; update config
	LDA old_t1			; older T1L
	STA VIA+T1LL		; restore old value
; *** TO_DO - restore standard quantum ***
	PLB					; restore!
	_EXIT_OK
fg_busy:
	PLB					; restore!
	_ERR(BUSY)			; couldn't set


; ***********************************************************
; *** SHUTDOWN, proper shutdown, with or without poweroff ***
; ***********************************************************
;		INPUT
; Y = subfunction code ()
;		OUTPUT
; C = couldn't poweroff or reboot (?)
;		USES b_sig (calls B_SIGNAL)
; sd_flag is a kernel variable
; * 8-bit savvy (I hope) *

shutdown:
	.as: .xs: SEP #$30	; *** standard register size ***
; switch DBR as it accesses some kernel data!
	PHB					; eeeeeeeeek
	LDA #0				; this will work on bank 0
	PHA					; into stack
	PLB					; set DBR! do not forget another PLB upon end!
; proceed
	CPY #PW_CLEAN		; from scheduler only!
		BEQ sd_2nd			; continue with second stage
	CPY #PW_STAT		; is it going to suspend?
		BEQ sd_stat			; do not shutdown system then!
	STY sd_flag			; store mode for later, first must do proper system shutdown, note long addressing
; ask all braids to terminate
	LDY #0				; PID=0 means ALL braids
	LDA #SIGTERM		; will be asked to terminate
	STA b_sig			; store signal type
;	KERNEL(B_SIGNAL)	; ask braids to terminate
	LDX #MM_SIGNAL		; internal multitasking index (2)
	JSR (drv_opt-MM_SIGNAL, X)	; direct to driver skipping the kernel, note deindexing! (8)
	PLB					; restore before further tinkering!!!
	PLP					; original mask is buried in stack, no DBR was saved!
	CLI					; make sure all will keep running!
	PHP					; restore for subsequent RTI
	_EXIT_OK			; unified stack frame makes irrelevant whether XIP or not
; actually RTI for 816

; firmware interface
sd_off:
	LDY #PW_OFF			; poweroff
sd_fw:
	_ADMIN(POWEROFF)	; except for suspend, shouldn't return...
	JMP cio_callend			; just in case was not implemented!
sd_stat:
	LDY #PW_STAT		; suspend
	BRA sd_fw			; shared code
sd_cold:
	LDY #PW_COLD		; cold boot
	BRA sd_fw
sd_warm:
	SEP #%00001001		; disable interrupts and set carry...
	XCE					; ...to set emulation mode for a moment
	CLD					; clear decimal mode
	JMP warm			; firmware no longer should take pointer, generic kernel knows anyway

; the scheduler will wait for NO braids active
; now let's disable all drivers
sd_2nd:
	LDA sd_flag			; check what was pending
	BNE sd_shut			; something to do
		_PANIC("{sched}")	; otherwise it is an error!
sd_shut:
	SEI					; disable interrupts (forever)
#ifdef	SAFE
	STZ dpoll_mx		; disable interrupt queues, just in case
	STZ dreq_mx
	STZ dsec_mx
#endif
; call each driver's shutdown routine
	LDX #0				; reset index
; first get the pointer to each driver table
sd_loop:
		.al: REP #$20		; *** 16-bit memory *** as might be reset by dr_call!
; get address index
		LDA drivers_ad, X	; get address from original list
			BEQ sd_done			; no more drivers to shutdown!
		STA sysptr			; store temporarily
; check here whether the driver was successfully installed, get ID as index for drv_opt/ipt
		LDY #D_ID			; point to ID of driver
		LDA (sysptr), Y		; get ID... plus extra byte
		ASL					; convert to index
;			BCC sd_next			; invalid device ID!
		TAY					; use as index, LSB only
		LDA #dr_error		; installed address at unused drivers
		CMP drv_opt, Y		; check pointer
		BNE sd_msb			; OK to shutdown
			CMP drv_ipt, Y		; check if not installed!
				BEQ sd_next			; nothing to shutoff
sd_msb:
		PHX					; save index for later
		PHP					; and register size, just in case!
		LDY #D_BYE			; shutdown MSB offset
		JSR dr_call			; call routine from generic code!!!
		.xs: SEP #$10		; just in case... memory size will be reset later
		PLP					; back to original size, will ignore error code anyway
		PLX					; retrieve index
sd_next:
		INX					; advance to next entry (2+2)
		INX
		BRA sd_loop			; repeat
; system cleanly shut, time to let the firmware turn-off or reboot
sd_done:
	LDX sd_flag			; retrieve mode as index!
	JMP (sd_tab-2, X)	; do as appropriate *** please note that X=0 means scheduler ran off of tasks!


; *************************************
; *** B_FORK, reserve available PID ***
; *************************************
;		OUTPUT
; Y = PID (0 means either singletask system or no more available braids)
;
; uses common code from GET_PID
; * 8-bit savvy * verify driver anyway

b_fork:
	.as: .xs: SEP #$30	; *** standard register size ***
	LDX #MM_FORK		; subfunction code
	BRA sig_call		; go for the driver


; *****************************************
; *** B_EXEC, launch new loaded process ***
; *****************************************
;		INPUT
; Y			= PID
; ex_pt		= 24b execution pointer (was z2L)
; cpu_ll	= architecture
; def_io	= 16b default std_in (LSB) & stdout (MSB)
;
; uses common code from GET_PID
; no need to indicate XIP or not! will push start address at bottom of stack anyway
; API still subject to change... (rendez-vous mode TBD)
; * 8-bit savvy * verify driver anyway

b_exec:
	.as: .xs: SEP #$30	; *** standard register size ***
	LDX #MM_EXEC		; subfunction code
	BRA sig_call		; go for the driver


; **************************************************
; *** B_SIGNAL, send UNIX-like signal to a braid ***
; **************************************************
;		INPUT
; b_sig	= signal to be sent
; Y		= PID
;		OUTPUT
; C = invalid PID
;
; uses common code from GET_PID
; * 8-bit savvy * verify driver anyway

signal:
	.as: .xs: SEP #$30	; *** standard register size ***
	LDX #MM_SIGNAL		; subfunction code
	BRA sig_call		; go for the driver


; ************************************************
; *** B_STATUS, get execution flags of a braid ***
; ************************************************
;		INPUT
; Y = addressed braid
;		OUTPUT
; Y = flags ***TBD
; C = invalid PID
;
; uses common code from GET_PID
; * 8-bit savvy * verify driver anyway

status:
	.as: .xs: SEP #$30	; *** standard register size ***
	LDX #MM_STATUS		; subfunction code
	BRA sig_call		; go for the driver


; **************************************
; *** GET_PID, get current braid PID ***
; **************************************
;		OUTPUT
; Y = PID (0 means singletask system)
; * 8-bit savvy * verify driver anyway
; note that there is a faster, unsafer version for internal kernel use (run_pid)

get_pid:
	.as: .xs: SEP #$30	; *** standard register size ***
	LDX #MM_PID			; subfunction code
; * unified calling procedure, get subfunction code in X * new faster interface 20161102
sig_call:
; new code is 6 bytes, 10 clocks! old code was 8 bytes, 13 clocks
	PEA cio_callend-1	; push correct return address!
	JMP (drv_opt)		; as will be the first one in list, best to use non-indexed indirect


; **************************************************************
; *** SET_HNDL, set SIGTERM handler, default is like SIGKILL ***
; **************************************************************
;		INPUT
; Y		= PID
; ex_pt = 24b SIGTERM handler routine (ending in RTI!)
;		OUTPUT
; C = bad PID
;
; uses common code from GET_PID
; revise as might be processed without driver!
; * 8-bit savvy * verify driver anyway

set_handler:
	.as: .xs: SEP #$30	; *** standard register size ***
	LDX #MM_HANDL		; subfunction code
	BRA sig_call		; go for the driver


; *********************************************
; *** B_YIELD, Yield CPU time to next braid ***
; *********************************************
; (no interface needed)
;
; uses common code from GET_PID
; * 8-bit savvy * verify driver anyway

yield:
	.as: .xs: SEP #$30	; *** standard register size ***
	LDX #MM_YIELD		; subfunction code
	BRA sig_call		; go for the driver


; ***************************************************************
; *** TS_INFO, get taskswitching info for multitasking driver *** REVISE ASAP ******
; ***************************************************************
;		OUTPUT
; Y		= number of bytes
; ex_pt = 24b pointer to the proposed stack frame (likeky in bank 0)
; ***** REVISE ASAP ****** REVISE ASAP ***** MULTITASK label to be deprecated

ts_info:
	.xs: SEP #$10			; *** standard index size ***
#ifdef	MULTITASK
	.al: REP #$20			; *** 16-bit memory ***
	LDA #tsi_str			; pointer to proposed stack frame
	STA ex_pt				; store output word
	LDY #tsi_end-tsi_str	; number of bytes
	_EXIT_OK
#else
	_ERR(UNAVAIL)			; non-supporting kernel!
#endif


; *********************************************
; *** RELEASE, release ALL memory for a PID ***
; *********************************************
;		INPUT
; Y = PID
;		USES ma_pt and whatever takes FREE (will call it)
; this is NOT intended to be called by apps, kernel & multitasking driver only, thus do not care about architecture
; but make certain that FREE calls are 24-bit enabled!
; * 8-bit savvy, I think *

release:
	.as: .xs: SEP #$30	; *** 8-bit sizes ***
; switch DBR as it accesses a lot of kernel data!
	PHB					; eeeeeeeeek
	LDA #0				; this will work on bank 0
	PHA					; into stack
	PLB					; set DBR! do not forget another PLB upon end!
; proceed
; ** not sure if I really need to save this value... **
	LDX run_arch		; "current" (?) architecture
	PHX					; save it!
	STA run_arch		; clear this to make it 24-bit enabled (was zero)
; continue as usual
	TYA					; as no CPY abs,X
	XBA					; exchange...
	LDA #USED_RAM		; the status we will be looking for! PID @ MSB
	.al: REP #$20		; *** 16-bit memory ***
rls_again:
		LDX #0				; reset index
rls_loop:
			CMP ram_stat, X		; will check both stat (LSB) AND PID (MSB) of this block
				BNE rls_oth			; it is not mine and/or not in use
			PHA					; otherwise save registers
			PHX
			LDA ram_pos, X		; get pointer to targeted block
			STZ ma_pt			; clearing PAGE addresses, beware of order on 16-bit accesses!!!
			STA ma_pt+1			; will be used by FREE eeeeeeeeek
			_KERNEL(FREE)		; release it! ***by NO means a direct call might be used here***
			PLX					; retrieve status
			PLA
			BCC rls_again
rls_oth:
		INX					; advance to next block
		INX
		LDY ram_stat, X		; look status only
		CPY #END_RAM		; are we done?
		BNE rls_loop		; continue if not yet
; ** since run_arch was saved and destroyed, maybe I should restore it here **
	PLX					; take a byte from stack
	STX run_arch		; restore value, just in case
	PLB					; restore!
	_EXIT_OK			; no errors...


; ***********************************************************
; *** SET_CURR, set internal kernel info for running task ***
; ***********************************************************
;		INPUT
; Y			= PID
; cpu_ll	= architecture (0=65816, 2=Rockwell, 4=65C02, 6=NMOS)
; affects internal sysvars run_pid & run_arch
; * 8-bit savvy *

set_curr:
	.as: .xs: SEP #$30	; *** 8-bit sizes ***
	STY @run_pid		; store PID into kernel variables (5)
	LDA cpu_ll			; get architecture from multitasking driver (3)
	STA @run_arch		; and store it for kernel use (5)
	_EXIT_OK



; ****** space for deprecated functions ******
; *** SU_POKE, write to protected addresses ***
; WILL be deprecated, not sure if of any use in other architectures
; Y <- value, zpar <- addr
; destroys A (and maybe Y on NMOS)

su_poke:
	.as: .xs: SEP #$30	; *** standard register size ***
	TYA					; transfer value
	STA (zpar)			; store value
	_EXIT_OK

; *** SU_PEEK, read from protected addresses ***
; WILL be deprecated, not sure if of any use in other architectures
; Y -> value, zpar <- addr
; destroys A

su_peek:
	.as: .xs: SEP #$30	; *** standard register size ***
	LDA (zpar)			; store value
	TAY					; transfer value
	_EXIT_OK

; *** SU_SEI, disable interrupts ***
; C -> not authorized (?)
; probably not needed on 65xx, _CS macros are much more interesting anyway
su_sei:
	SEI					; disable interrupts
	_EXIT_OK			; no error so far

; *** SU_CLI, enable interrupts ***
; probably not needed on 65xx, _CS macros are much more interesting anyway

su_cli:					; not needed for 65xx, even with protection hardware
	CLI					; enable interrupts
	_EXIT_OK			; no error

; *** GO_SHELL, launch default shell *** probably DEPRECATE
; no interface needed
go_shell:
	JMP shell			; simply... *** SHOULD initialise SP and other things anyway ***


; *******************************
; *** end of kernel functions ***
; *******************************

; ****debug code*****
hexdebug:		; print A in hex
.al:rep#$20
.xs:sep#$10
	PHA			; keep whole value
	LSR			; shift right four times (just the MSB)
	LSR
	LSR
	LSR
	JSR hxd_ascii	; convert and print this cipher
	PLA			; retrieve full value
	AND #$0F	; keep just the LSB... and repeat procedure
hxd_ascii:
	CMP #10		; will be a letter?
	BCC hxd_num	; just a number
		ADC #6			; convert to letter (plus carry)
hxd_num:
	ADC #'0'	; convert to ASCII (carry is clear)
	JSR $c0c2	; direct print
	RTS
; *******************

; other data and pointers
sd_tab:					; check order in abi.h!
	.word	sd_stat		; suspend
	.word	sd_warm		; warm boot direct by kernel
	.word	sd_cold		; cold boot via firmware
	.word	sd_off		; poweroff system

tsi_str:
; pre-created reversed stack frame for firing tasks up, regardless of multitasking driver implementation
	.word	isr_sched_ret-1	; corrected reentry address **standard label** REVISE REVISE
	.byt	0				; stored X value, best if multitasking driver is the first one
	.word	0, 0, 0			; irrelevant Y, X, A values
tsi_end:
; end of stack frame for easier size computation


; **************************************************
; *** jump table, if not in separate 'jump' file ***
; **************************************************

#ifndef		DOWNLOAD
k_vec:
	.word	cout		; output a character
	.word	cin			; get a character
	.word	malloc		; reserve memory
	.word	free		; release memory
	.word	open_w		; get I/O port or window
	.word	close_w		; close window
	.word	free_w		; will be closed by kernel
	.word	uptime		; approximate uptime in ticks
	.word	b_fork		; get available PID
	.word	b_exec		; launch new process
	.word	load_link	; get addr. once in RAM/ROM
	.word	su_poke		; write protected addresses
	.word	su_peek		; read protected addresses
	.word	string		; prints a C-string
	.word	readLN		; buffered input, INSERTED 20170113
	.word	su_sei		; disable interrupts, aka dis_int
	.word	su_cli		; enable interrupts (not needed for 65xx) aka en_int
	.word	set_fg		; enable frequency generator (VIA T1@PB7)
	.word	go_shell	; launch default shell, INSERTED 20150604
	.word	shutdown	; proper shutdown procedure, new 20150409, renumbered 20150604
	.word	signal		; send UNIX-like signal to a braid, new 20150415, renumbered 20150604
	.word	status		; get execution flags of a braid, EEEEEEEEEEEEEEEK
	.word	get_pid		; get PID of current braid, new 20150415, renumbered 20150604
	.word	set_handler	; set SIGTERM handler, new 20150417, renumbered 20150604
	.word	yield		; give away CPU time for I/O-bound process, new 20150415, renumbered 20150604
	.word	ts_info		; get taskswitching info, new 20150507-08, renumbered 20150604
	.word	release		; release ALL memory for a PID, new 20161115
	.word	set_curr	; set internal kernel info for running task (PID & architecture)
#endif
