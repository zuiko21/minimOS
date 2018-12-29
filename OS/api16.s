; minimOS·16 generic Kernel API!
; v0.6rc20, should match kernel16.s
; (c) 2016-2018 Carlos J. Santisteban
; last modified 20181229-1245

; **************************************************
; *** jump table, if not in separate 'jump' file ***
; **************************************************

#ifndef		DOWNLOAD
k_vec:
; basic I/O
	.word	cout		; output a character
	.word	cin			; get a character
	.word	string		; prints a C-string
	.word	readln		; buffered input
; block I/O
	.word	blout		; block output
	.word	blin		; block input
	.word	bl_cnfg		; configure device
	.word	bl_stat		; device status
; simple windowing system (placeholders)
	.word	open_w		; get I/O port or window
	.word	close_w		; close window
	.word	free_w		; will be closed by kernel
	.word	float_w		; put window/device in foreground ***new placeholder
; other generic functions
	.word	uptime		; approximate uptime in ticks
; * no longer set_fg! *
	.word	shutdown	; proper shutdown procedure
	.word	loadlink	; get addr. once in RAM/ROM
; simplified task management
	.word	b_fork		; get available PID ***returns 0
	.word	b_exec		; launch new process ***simpler
	.word	b_signal	; send UNIX-like signal to a braid ***SIGTERM & SIGKILL only
	.word	b_flags		; get execution flags of a task ***eeeeeeeeeek
	.word	set_hndl	; set SIGTERM handler
	.word	b_yield		; give away CPU time for I/O-bound process ***does nothing
	.word	b_fore		; set foreground task ***new
	.word	get_fg		; get foreground task ***newer
; non-patched task management
	.word	b_event		; send signal to foreground task ***new
	.word	get_pid		; get PID of current braid (as set by SET_CURR)
; new driver functionalities TBD
	.word	dr_info		; get driver header
	.word	aq_mng		; manage asynchronous task queue
	.word	pq_mng		; manage periodic task queue
; advanced functions
; drivers...
	.word	dr_inst		; install driver
	.word	dr_shut		; remove driver
; memory...
	.word	malloc		; reserve memory
	.word	free		; release memory
	.word	memlock		; reserve some address
	.word	release		; release ALL memory for a PID
; multitasking...
	.word	ts_info		; get taskswitching info
	.word	set_curr	; set internal kernel info for running task
#endif

; ****************************
; ****************************
; *** Kernel API functions ***
; ****************************
; ****************************

; no way for standalone assembly, neither internal calls...
; assumes 8-bit sizes upon call...
.as:.xs

; ***************************************
; *** dummy function, not implemented ***
; ***************************************

memlock:				; *** FUTURE IMPLEMENTATION ***
aq_mng:
pq_mng:
bl_cnfg:
bl_stat:

unimplemented:			; placeholder here, not currently used
	_ERR(UNAVAIL)		; go away!


; *****************************
; *** CIN,  get a character *** and manage events
; *****************************
;		INPUT
; Y = dev
;		OUTPUT
; io_c	= char
; C		= not available
;		USES iol_dev, and whatever the driver takes
	.asc	"<CIN>"
cin:
; if every zp is page-aligned as recommended, use this code
	TDC					; where is direct page?
	XBA					; switch to MSB
	STA bl_ptr+1		; set on pointer
	LDA #io_c			; point to ZP parameter
	STA bl_ptr			; ready, will not need to resolve!
	STZ bl_ptr+2		; always bank zero! eeeeeeek
; set fixed size and proceed
	LDA #1				; single byte
	STA bl_siz			; set size
	STZ bl_siz+1
	_KERNEL(BLIN)
	RTI					; ** keep possible error **
; worth switching back DBR
;	PHB					; eeeeeeeeek (3)
;	PHK					; bank zero into stack (3)
;	PLB					; set DBR! do not forget another PLB upon end! (4)
; ** EVENT management no longer here **
;	LDX iol_dev			; **use physdev as index! (3)
;	LDA io_c			; get received character
;	CMP #' '			; printable?
;		BCS ci_exitOK		; if so, will not be an event, exit with NO error
; events no longer here!
; check for binary mode first
;	LDY cin_mode, X		; *get flag, new sysvar 20150617
;	BNE ci_nevent		; otherwise should process possible event
; *** event processing ***
;		CMP #16				; is it DLE?
;		BNE ci_notdle		; otherwise check next
;			STA cin_mode, X		; *set binary mode! safer and faster!
;			LDY #EMPTY			; and supress received character
;			BRA cio_abort		; restore & notify (will stay locked!)
;ci_notdle:
;		CMP #3				; is it ^C? (TERM)
;		BNE ci_noterm		; otherwise check next
;			LDA #SIGTERM
;			BRA ci_signal		; send signal
;ci_noterm:
;		CMP #4				; is it ^D? (KILL) somewhat dangerous...
;		BNE ci_nokill		; otherwise check next
;			LDA #SIGKILL
;			BRA ci_signal		; send signal
;ci_nokill:
;		CMP #26				; is it ^Z? (STOP)
;			BNE ci_exitOK		; otherwise there is no more to check
;		LDA #SIGSTOP		; last signal to be sent
;ci_signal:
;		STA b_sig			; set signal as parameter
; much faster KERNEL(GET_PID)
;		LDY run_pid			; internal PID in Y...
;		KERNEL(B_SIGNAL)	; send signal to myself *** could be patched!
;		LDY #EMPTY			; no character was received
;		SEC					; eeeeeeeek
;		JMP cio_unlock		; release device and exit!


; ********************************
; *** COUT, output a character ***
; ********************************
;		INPUT
; Y		= dev
; io_c	= char
;		OUTPUT
; C = I/O error
;		USES BLOUT
; cio_lock is a kernel structure
	.asc	"<COUT>"
cout:
; if every zp is page-aligned as recommended, use this code
	TDC					; where is direct page?
	XBA					; switch to MSB
	STA bl_ptr+1		; set on pointer
	LDA #io_c			; point to ZP parameter
	STA bl_ptr			; ready, will not need to resolve!
	STZ bl_ptr+2		; always in bank zero! eeeeeeeeeek
; set fixed size and proceed
	LDA #1				; single byte
	STA bl_siz			; set size
	STZ bl_siz+1
; ...and fall into BLOUT

; **************************
; *** BLOUT, block output ***
; **************************
;		INPUT
; Y		= dev
; bl_ptr	= buffer address
; bl_siz	= block size
;		OUTPUT
; bl_siz	= remaining bytes
; C		= I/O error
;		USES iol_dev, plus whatever the driver takes
; cio_lock is a kernel structure
; * 8-bit savvy *
	BRA blout
	.asc	"<BLOUT>"
blout:
; switch DBR as it accesses a lot of kernel data!
	PHB					; eeeeeeeeek (3)
	PHK					; bank zero into stack (3)
	PLB					; set DBR! do not forget another PLB upon end! (4)
; ****** from 8-bit code MUST check pointer in case is in direct page!!! ******
#ifdef	SUPPORT
	LDX run_arch		; from 6502 code?
	BEQ blo_24b			; no, nothing to correct
		STZ bl_ptr+2		; 6502 always in bank zero
		LDA bl_ptr+1		; check page
		BNE blo_24b			; all OK
			TDC					; where is direct page?
			XBA					; go for MSB (assume page-aligned!)
			STA bl_ptr+1		; physical address
blo_24b:
#endif
; proceed
	TYA					; update flags upon dev number (2)
	BNE co_port			; not default (3/2)
		LDY stdout			; new per-process standard device (3)
		BNE co_port			; already a valid device (3/2)
			LDY dfltout			; otherwise get system global (4)
co_port:
	BMI co_phys			; not a logic device (3/2)
		CPY #64				; first file-dev??? (2)
			BCC co_win			; below that, should be window manager (3/2)
; ** optional filesystem access **
#ifdef	FILESYSTEM
		CPY #64+MX_FILES	; still within file-devs?
			BCS co_log			; that value or over, not a file
; *** manage here output to open file ***
#endif
; *** virtual windows manager TO DO ***
co_win:
		LDY #NO_RSRC		; not yet implemented ***placeholder***
		BRA cio_abort		; restore DBR and notify error
; ** end of filesystem access **
co_log:
; investigate rest of logical devices
		CPY #DEV_NULL		; lastly, ignore output
		BEQ co_ok			; /dev/null is always OK
; final error otherwise
			LDY #N_FOUND		; unknown device
			BRA cio_abort		; restore & notify
co_ok:
		STZ bl_siz			; /dev/null transfers are complete
		STZ bl_siz+1
		PLB					; restore!!!
		_EXIT_OK			; end of function without errors

; *** some common routines ***
; these could be called in 8 or 16-bit index size, but always 8-bit memory!
;ci_nevent:
;	STZ cin_mode, X		; back to normal mode ***first entry is dummy in case a wrong device is asked!
ci_exitOK:
	STZ cio_lock, X		; otherwise clear mutex!!! (4)
	PLB					; essential!
	_EXIT_OK			; all done without error!

; ** cio_abort **
; will restore DBR and then notify error directly...
; likely to become inline
cio_abort:
	PLB					; restore DBR!!!
	BRA cio_setc		; direct notify error

; *** continue ***
co_phys:
; arrived here with dev # in Y!
; new per-phys-device MUTEX for COUT, no matter if singletask!
; new indirect-sparse array system!
	LDX dr_ind-128, Y	; get proper index for that physical ID (4)
; a dummy first entry in pointer arrays make checking for available devices unnecessary!
; newly computed index is stored as usual
	STX iol_dev			; keep device-index temporarily, worth doing here (3)
; CS not needed for MUTEX as per 65816 API
co_loop:
		LDA cio_lock, X		; check whether THAT device is in use (4) 24-bit!
			BEQ co_lckd			; resume operation if free (3)
		_KERNEL(B_YIELD)	; otherwise yield CPU time and repeat *** could be patched!
		LDX iol_dev			; retrieve index!
		BRA co_loop			; try again! (3)

co_lckd:
	LDA run_pid			; get ours in A, faster!
	STA cio_lock, X		; reserve this (4)
; 65816 API runs on interrupts off, thus no explicit CS exit
; direct driver call, proper sparse physdev index in X
	JSR (drv_opt, X)	; direct CALL!!! driver should end in RTS as usual via the new DR_ macros
	.as:.xs: SEP #$30	; *** please make sure we are back in 8-bit sizes ***
; ...and then into cio_unlock

; ***************************
; *** common I/O routines ***
; ***************************

; ** cio_unlock **
; gets physdevnum and clears its mutex, restores DBR and exit with proper error code if C set
; must be called in all 8-bit size!!!
cio_unlock:
	LDX iol_dev			; **need to clear new lock! (3)
	STZ cio_lock, X		; ...because I have to clear MUTEX! (4)
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


; ***********************
; *** BLIN, get block ***
; ***********************
;		INPUT
; Y		= dev
; bl_ptr	= buffer address
; bl_siz	= maximum transfer size
;		OUTPUT
; bl_siz	= remaining bytes
; C		= I/O error

;		USES iol_dev, and whatever the driver takes
; cio_lock is kernel structure
	.asc	"<BLIN>"
blin:
; switch DBR as it accesses a lot of kernel data!
	PHB					; eeeeeeeeek (3)
	PHK					; bank zero into stack (3)
	PLB					; set DBR! do not forget another PLB upon end! (4)
#ifdef	SUPPORT
	LDX run_arch		; from 6502 code?
	BEQ bli_24b			; no, nothing to correct
		STZ bl_ptr+2		; 6502 always in bank zero
		LDA bl_ptr+1		; check page
		BNE bli_24b			; all OK
			TDC					; where is direct page?
			XBA					; go for MSB (assume page-aligned!)
			STA bl_ptr+1		; physical address
bli_24b:
#endif
; proceed
	TYA					; set flags upon devnum (2)
	BNE ci_port			; specified (3/2)
		LDY std_in			; new per-process standard device (3)
		BNE ci_port			; already a valid device (3/2)
			LDY dflt_in			; otherwise get system global (0/4)
ci_port:
	BPL ci_nph			; logic device (2/3)
; new MUTEX for CIN
; new indirect-sparse array system!
	LDX dr_ind-128, Y	; get proper index for that physical ID (4)
; a dummy first entry in pointer arrays make checking for available devices unnecessary!
; newly computed index is stored as usual
	STX iol_dev			; keep sparse physdev temporarily, worth doing here (3)
; CS not needed for MUTEX as per 65816 API
ci_loop:
		LDA cio_lock, X		; check whether THAT device in use (4)
			BEQ ci_lckd			; resume operation if free (3)
; otherwise yield CPU time and repeat
; but first check whether it was me (waiting on binary mode)
		LDA run_pid			; who am I?
		CMP cio_lock, X		; was it me who locked? (4)
			BEQ ci_lckdd		; if so, resume execution (3)
; if the above, could first check whether the device is in binary mode, otherwise repeat loop!
; continue with regular mutex
		_KERNEL(B_YIELD)	; otherwise yield CPU time and repeat *** could be patched!
		LDX iol_dev			; restore previous offset (3)
		BRA ci_loop			; try again! (3)
ci_lckd:
	LDA run_pid			; who is me?
	STA cio_lock-1, X	; reserve this (4)
ci_lckdd:
; 65816 API runs on interrupts off, thus no explicit CS exit
; ** new direct indexing **
		JSR (drv_ipt, X)	; direct CALL!!!
		.as:.xs: SEP #$30	; *** please make sure we are back in 8-bit sizes ***
			BCS cio_unlock		; clear MUTEX and return whatever error!
ci_nph:
	CPY #64				; first file-dev??? ***
		BCC ci_win			; below that, should be window manager
; ** optional filesystem access **
#ifdef	FILESYSTEM
	CPY #64+MAX_FILES	; still within file-devs?
		BCS ci_log			; that or over, not a file
; *** manage here input from open file ***
#endif
; *** virtual window manager TO DO ***
ci_win:
	LDY #NO_RSRC		; not yet implemented ***placeholder***
	JMP cio_abort		; restore & notify

; *** manage logical devices ***
ci_log:
	CPY #DEV_RND		; getting a random number?
		BEQ ci_rnd			; compute it!
	CPY #DEV_NULL		; lastly, clear buffer!!!
		BEQ ci_null
	LDY #N_FOUND		; unknown device
	JMP cio_abort		; restore & notify

; surely there is a way to unify these loops...
; fill buffer with zeroes like "/dev/zero"
ci_null:
	LDY #0				; reset index, will be complete
	TYA					; filling value as above***
	.xl: REP #$10		; *** 16-bit index ***
	LDX bl_siz			; get size in full
	BNE ci_nulend		; nothing to do
ci_nll:
		STA [bl_ptr], Y		; clear byte in buffer
		INY					; go for next
		DEX					; one less to go
		BNE ci_nll
ci_nulend:
	JMP ci_exitOK		; nothing else

	.xs:

ci_rnd:
; *** generate random number (TO DO) ***
	LDY #0				; reset index, will be complete
	.xl: REP #$10		; *** 16-bit index ***
	LDX bl_siz			; get size in full
	BNE ci_rndend		; nothing to do
; load some random number in A
ci_rndl:
		LDA ticks			; simple placeholder***
		STA [bl_ptr], Y		; clear byte in buffer
		INY					; go for next
		DEX					; one less to go
		BNE ci_rndl
ci_rndend:
	JMP ci_exitOK		; nothing else

	.xs:

; ******************************
; *** MALLOC, reserve memory *** MUST change in a bidirectional way
; ******************************
;		INPUT
; ma_rs		= 24b size (0 means reserve as much memory as available)
; ma_align	= page mask (0=page/not aligned, 1=512b, $FF=bank aligned)
;		OUTPUT
; ma_pt	= 24b pointer to reserved block
; ma_rs	= 24b actual size (esp. if ma_rs was 0, but check LSB too)
; C		= not enough memory/corruption detected
;		USES ma_ix.b and, in the future, ma_lim
; ram_stat & ram_pid (= ram_stat+1) are interleaved in minimOS-16
; MUST limit 6502 blocks to bank zero
; 02-savvy, but should check ma_lim properly
; think about managing the multiple exit points as this is a rather slow function
	.asc	"<MALLOC>"
malloc:
	.al: REP #$20		; *** 16-bit memory ***
	PHB					; eeeeeeeek! do not forget to restore
	LDX #0				; reset index (can be used for storing any 8-bit zero)
	PHX					; put one zero byte into stack (no need for PHK as this X is needed afterwards)
	PLB					; preset DBR as default zero!
	STZ ma_align+1		; **clear MSB for the 16-bit BIT!**

#ifdef	SUPPORT
; detect caller architecture in order to enable 24-bit addressing
	LDY run_arch		; zero for native 65816, respect X as it holds zero
	BEQ ma_24b			; OK for 24b addressing
		TXY					; ...or just bank 0 (was in X) for 6502
		STX ma_rs+2			; clear number of banks just in case!
		BRA ma_lset
ma_24b:
	LDY #$FF			; full range of banks
ma_lset:
#else
	LDY #$FF			; full range of banks
#endif
	STY ma_lim			; set limit
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
			PLB					; restore!
			_ERR(FULL)			; otherwise no free memory!
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
; recreate a valid memory map, should use GESTALT instead
			LDX #>user_ram		; beginning of available ram, as defined... in rom.s
			LDY #<user_ram		; LSB misaligned?
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

; ****** temporary code for limiting 6502 requests to bank zero! ******
#ifdef	SUPPORT
; should stop loops somewhere upon exceeding ma_lim
; in case of  size 0, set as 1 bank!
	LDA run_arch		; get architecture
	BEQ ma_bankOK		; native 65816 means no trouble
		LDA ma_pt+2			; otherwise check out assigned bank
		BEQ ma_bankOK		; bank zero is OK for everyone
			PHA					; otherwise set data bank temprorarily...
			PLB					; ...as will be taken by FREE from 8-bit code
			_KERNEL(FREE)		; release what was wrongly assigned
			PLB					; 6502 cannot run outside bank zero!
			_ERR(FULL)			; and exit with no suitable memory available
ma_bankOK:
#endif
; **** end of temporary code, remove as soon as properly handled!! ****

	PLB					; restore!
	_EXIT_OK

; ******************************
; *** common MALLOC routines ***
; ******************************
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

	.as:

; *******************************
; **** FREE,  release memory ****
; *******************************
;		INPUT
; ma_pt = 24b addr (cannot point to direct page)
;		OUTPUT
; C = no such used block
;
; ram_pos & ram_stat are kernel structures
	.asc	"<FREE>"
free:
	.al: REP #$20		; *** 16-bit memory ***
	PHB					; eeeeeeeek! do not forget to restore
	LDX #0				; reset index (will be used afterwards)
	PHX					; put one zero byte into stack (no need for PHK)
	PLB					; preset DBR as default zero!

#ifdef	SAFE
	LDY ma_pt			; LSB currently not implemented
		BNE fr_no			; could not find
#endif

#ifdef	SUPPORT
; check architecture in order to discard bank address
	LDY run_arch		; will be zero for native 65816, please respect X!
	BEQ fr_24b			; 24-bit enabled
		STZ ma_pt+2			; otherwise is bank 0!
fr_24b:
#endif

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
		JSR fr_join			; integrate following free block
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
		LDA ram_pos+4, X	; get following address
		STA ram_pos+2, X	; store one entry below
		LDA ram_stat+4, X	; check status of following! **but PID field too**
		STA ram_stat+2, X	; store one entry below **otherwise LDY/STY**
		TAY					; **will transfer just status, PID will be ripped off**
		CPY #END_RAM		; end of list?
		BNE fr_join			; repeat until done
	RTS

	.as:

; **************************************
; *** OPEN_W, get I/O port or window ***
; **************************************
;		INPUT
; w_rect	= 16b size VV.HH
; w_rect+2	= 16b pos VV.HH
; str_pt	= 24b pointer to title string, NONE yet used (SHOULD be DP-savvy)
;		OUTPUT
; Y = dev
; C = not supported/not available
	.asc	"<OPEN_W>"
open_w:
	.al: REP #$20		; *** 16-bit memory size ***
	LDA w_rect			; asking for some size? includes BOTH bytes
	BEQ ow_no_window	; wouldn't do it
		_ERR(NO_RSRC)
ow_no_window:
	.as: SEP #$20		; for peace of mind...

; ******************************************
; *** B_FORK, get available PID ************
; *** GET_FG, get current foreground PID ***
; ******************************************
;		OUTPUT
; Y		= PID, 0 means not available or singletask
	BRA b_fork
	.asc	"<B_FORK,GET_FG>"
b_fork:
get_fg:
	LDY #0				; standard device or single task PID
; EXIT_OK on subsequent system calls!!!

; ********************************************************
; *** B_YIELD, yield CPU time to next braid **************
; ********************************************************
; *** CLOSE_W,  close window *****************************
; *** FREE_W, release window, will be closed by kernel ***
; *** FLOAT_W, put window in foreground ******************
; ********************************************************
;		INPUT
; Y = dev
	BRA b_yield
	.asc	"<B_YIELD,CLOSE_W,FREE_W,FLOAT_W>"
b_yield:
close_w:				; doesn't do much
free_w:					; doesn't do much, either
float_w:				; placeholder
	_EXIT_OK


; **************************************
; *** UPTIME, get approximate uptime ***
; **************************************
;		OUTPUT
; up_ticks	= 32b tick counter, new format 20170822
; up_sec	= 24b approximate uptime in seconds for API compatibility
	.asc	"<UPTIME>"
uptime:
	.al: REP #$20		; *** optimum 16-bit memory ***
; default 816 API functions run on interrupts masked, thus no need for CS
; not worth setting DBR, note long addressing
	LDA @ticks			; get system variable word (6)
	STA up_ticks		; and store them in output parameter (4)
	LDA @ticks+2		; get system variable uptime (6)
	STA up_ticks+2		; and store it in output parameter (4)
; end of CS
	_EXIT_OK

	.as:

; *****************************************
; *** B_EXEC, launch new loaded process *** revamped 20170524
; *****************************************
;		INPUT
; Y			= PID (0 for singletask only)
; ex_pt		= 24b execution pointer
; cpu_ll	= architecture
; def_io	= 16b default std_in (LSB) & stdout (MSB)
;
; API still subject to change... (register values, rendez-vous mode TBD)
	.asc	"<B_EXEC>"
b_exec:
; non-multitasking version
#ifdef	SAFE
	TYA					; should be system reserved PID, best way
	BEQ exec_st			; OK for single-task system
		_ERR(NO_RSRC)		; no way without multitasking *** or INVALID from sig_pid?
exec_st:
#endif
; set data bank, as some ops will need it, singletasking means this is a point of no return
	PHK					; push 0
	PLB					; work on data from bank 0
; initialise stack EEEEEEK
	LDA #1				; standard stack page
	XBA					; use as MSB
	LDA #$FF			; initial stack pointer, not using SPTR
	TCS					; eeeeeeeeeek
; as before, the 16-bit version makes simpler to simulate a call, thus no JSL here
	LDX ex_pt+2			; get bank in X *** needed elsewhere ***
; *** in case of non-XIP code, push the block address at the very bottom of stack ***
	PHX					; bank goes first! eeeeeeek
	PEI (ex_pt)			; 65816 fashion!
; *** end of non-XIP code, will not harm anyway ***
; set architecture, will behave differently for 65xx02 code
	LDA cpu_ll			; check architecture
; *** do the EOR trick for easy API architecture detection ***
	EOR #'V'			; ** will be zero only for native **
	STA run_arch		; set as current, no longer long addressing!
; as 6502 code will not run beyond bank 0, no need for wrappers etc!
; now will push the standard SIGKILL return address
	PHK					; push return bank address, actually zero (3) no matter the architecture!
	PEA sig_kill-1		; push corrected return address (5)
; set default SIGTERM handler! eeeeeeeeeeeeeeeeeeeeek
	STZ mm_sterm+2		; clear standard bank, but respect hibyte!
	.al: REP #$20		; *** worth going 16-bit memory ***
	LDA #sig_kill		; get full address
	STA mm_sterm		; set variable (bank already set)
; this is how a task should replace the shell
	LDY #ZP_AVAIL		; eeeeeeeeeeek, use 8-bit only but RESPECT bank!
	STY z_used			; otherwise SAFE will not work
; and set default devices!!! eeeeeeeeeeeeeeeeeeeeeeek
	LDA def_io			; standard I/O
	STA std_in			; set as defaults
; right now should set DBR as there is no scheduler to preload it! eeeeeeek
	PHX					; push bank into stack for a moment
	PLB					; ...and now properly set for the task
; *** soon will preset registers according to new API ***
; at last, launch code
	.as: SEP #$20		; *** default 8-bit launch! ***
	CLI					; time to do it!
; assume the stack is already preloaded with SIGKILL address (or wrapper RTL above that)
	JMP [ex_pt]			; forthcoming RTL will end via SIGKILL

; ***** SIGKILL handler, either from B_SIGNAL or at task completion *****
sig_kill:
	.as: .xs: SEP #$30	; *** standard sizes all the way, in case a task was killed ***
; *** TO DO *** this should save Y & P.C (carry) somewhere for status report! ***
; first, free up all memory from previous task
	LDY #0				; standard PID
; should correct DP, just in case
	TYA					; use that zero as standard DP
	XBA					; that was MSB
	TYA					; and this the LSB
	TCD					; set proper zeropage for singletask systems!
;	KERNEL(RELEASE)	; free all memory eeeeeeeek
; *** non-XIP code should release its own block! ***
; * assume 8-bit sizes *
; this code is 11b, 43t
	LDX #3				; number of bytes for pointer
sk_loop:				; *** this code valid for singletask 816 ***
		LDA @$1FC, X		; get byte from bottom of stack
		STA ma_pt-1, X		; set pointer eeeeeeeeeeeek
		DEX					; previous byte
		BNE sk_loop			; until all done
;*****alternative direct way, 16b, 24t
;	.al
;	REP #$20			; *** 16-bit memory *** (3)
;	LDA @$1FD			; get word from stack bottom... (6)
;	STA ma_pt			; store pointer (3)
;	LDA @$1FF			; get bank (and garbage) from stack bottom... (6)
;	STA ma_pt+2			; extra will not harm (3)
;	.as
;	SEP #$20			; *** 8-bit memory *** (3)

; previous RELEASE marked pointer as 24b valid! otherwise STZ run_arch
	STZ run_arch		; see above
	_KERNEL(FREE)		; free it or fail quietly
; *** end of non-XIP code, will not harm anyway ***
; then, check for any shutdown command
	LDA @sd_flag		; some pending action?
	BEQ rst_shell		; if not, just restart the shell
		LDY #PW_CLEAN		; or go into second phase...
		_KERNEL(SHUTDOWN)	; ...of shutdown procedure (no direct call)
; if none of the above, a single task system can only restart the shell!
; * make certain it arrives here in 8-bit memory mode *
rst_shell:
;	.as
;	.xs
;	SEP #$30			; *** all 8-bit ***
	LDA #1				; standard stack page
	XBA					; use as MSB
	LDA #$FF			; initial stack pointer LSB, not using SPTR
	TCS					; init SP again (in case SIGKILL was called)
	JMP sh_exec			; back to kernel shell! *** standard label from kernel16.s ***


; **************************************************
; *** B_SIGNAL, send UNIX-like signal to a braid ***
; **************************************************
;		INPUT
; b_sig	= signal to be sent
; Y		= PID (0 means TO ALL)
	.asc	"<B_SIGNAL>"
b_signal:
#ifdef	SAFE
	TYA					; check correct PID
		BNE sig_pid			; invalid braid
#endif
	LDY b_sig			; get the signal
	CPY #SIGTERM		; clean task shutdown?
	BNE sig_suic		; if so, call supplied routine (SIGKILL by default)
; SIGTERM no longer needs to end in RTI!
		JSR @sig_term		; indirect long call, JSL actually
		_EXIT_OK			; return to caller
sig_suic:
	CPY #SIGKILL		; suicide?
		BEQ sig_kill		; release MEMORY, windows etc
sig_pid:
	_ERR(INVALID)		; unrecognised signal, notify error
sig_term:
	JMP [mm_sterm]		; actual JUMP, will return as usual


; ************************************************
; *** B_FLAGS, get execution flags of a braid ***
; ************************************************
;		INPUT
; Y			= addressed braid
;		OUTPUT
; Y			= flags ***TBD
; cpu_ll	= running architecture
; C			= invalid PID
	.asc	"<B_FLAGS>"
b_flags:
#ifdef	SAFE
	TYA					; check PID
		BNE sig_pid			; only 0 accepted
#endif
	LDY #BR_RUN			; single-task systems are always running
	LDA @run_arch		; get running architecture (new)
	STA cpu_ll			; report it
sig_exit:
	_EXIT_OK


; **************************************************************
; *** SET_HNDL, set SIGTERM handler, default is like SIGKILL ***
; **************************************************************
;		INPUT
; Y		= PID (0 means to myself)
; ex_pt = 24b SIGTERM handler routine no longer ending in RTI!
;		OUTPUT
; C		= bad PID
	.asc	"<SET_HNDL>"
set_hndl:
#ifdef	SAFE
	TYX					; check PID
		BNE sig_pid			; only 0 accepted
#endif
	LDX ex_pt+2			; 65816 takes bank too
	.al: REP #$20		; *** 16-bit memory size ***
#ifdef	SUPPORT
; must check for 02 code in order to preset bank!
	LDA @run_arch		; check current code EEEEEEK takes extra byte
	AND #$00FF			; filter irrelevant byte, as no LDY long
	BEQ st_shset		; if native, bank is set
		LDX #0				; otherwise is in bank 0!
st_shset:
#endif
	LDA ex_pt			; get pointer
	STA @mm_sterm		; store in single variable, 24-bit addr!
	.as: SEP #$20		; *** back to 8-bit ***
	TXA					; no long STX...
	STA @mm_sterm+2		; bank stored just after regular pointer, 24-bit addr!
	_EXIT_OK


; **************************************
; *** GET_PID, get current braid PID ***
; **************************************
;		OUTPUT
; Y		= PID, 0 on singletask systems
; may not need to be patched in multitasking systems!
	.asc	"<GET_PID>"
get_pid:
	LDY run_pid			; new kernel variable
	_EXIT_OK


; ***********************************
; *** B_FORE, set foreground task ***
; ***********************************
;		INPUT
; Y		= PID of task, 0 if myself or single-task, $FF switch to next!
	.asc	"<B_FORE>"
b_fore:
#ifdef	SAFE
	CPY #$FF			; asking for another?
	BEQ bf_ok			; will stay anyway
		TYA					; check PID
		BNE sig_pid			; must be zero, complain otherwise
bf_ok:
#endif
	_EXIT_OK

; ************************************************
; *** B_EVENT, send signal to appropriate task ***
; ************************************************
;		INPUT
; Y		= transferred char (assumed *previously* stored into buffer or io_c)
; affects b_sig as it may call B_SIGNAL
; may not need to be patched?
; this MUST handle DLEs accordingly, cin_mode as global or PID-based array???
	.asc	"<B_EVENT>"
b_event:
	CPY #3				; is it ^C?
	BNE be_nc
		LDA #SIGTERM
		BNE be_sig			; no need for BRA
be_nc:
	CPY #4				; is it ^D?
	BNE be_nd
		LDA #SIGKILL		; somewhat dangerous!
		BEQ be_sig			; no need for BRA (this was zero)
be_nd:
	CPY #26				; is it ^Z?
	BNE be_none			; this is the last recognised event
		LDA #SIGSTOP
be_sig:
	STA b_sig			; set signal
	_KERNEL(GET_FG)		; get foreground task, may be patched!
	JSR b_signal		; execute...
	_ERR(EMPTY)			; ...and discard input char!
be_none:
	_EXIT_OK			; regular char or maybe a discarded event, will just be ingored

; **************************************************************
; *** LOADLINK, get address once in RAM/ROM (in development) ***
; **************************************************************
;		INPUT
; str_pt = 24b pointer to filename path, ZP corrected (will be altered!)
;		OUTPUT
; ex_pt		= 24b pointer to executable code
; cpu_ll	= architecture (as stated in headers!)
;		USES rh_scan
	.asc	"<LOADLINK>"
loadlink:
; *** first look for that filename in ROM headers ***
; no need to set DBR

#ifndef	NOHEAD
; LOADLINK only useful with ROM headers!
#ifdef	SUPPORT
; check architecture in order to discard bank address
	LDA @run_arch		; will be zero for native 65816
	BEQ ll_24b			; 24-bit enabled
		STZ str_pt+2		; ..or zero as default bank
; *** special corrections are needed in case the pointer is in direct page! ***
		LDX str_pt+1		; get page numberk...
		BNE ll_24b			; outside DP, nothing more to correct
			TDC					; current context location
			XBA					; assume page-aligned!
			STA str_pt+1		; store corrected value, 6502 caller should update its local MSB at least!
ll_24b:
#endif
	.al: REP #$20		; *** 16-bit memory ***
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
	STA rh_scan			; set local pointer
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
; this was the original loadlink code prior to 20161202, will be executed after the header was found!
	.as: .xs: SEP #$30	; *** standard register size ***
	LDY #1				; offset for filetype
	LDA [rh_scan], Y	; check filetype
	CMP #'m'			; must be minimOS app!
		BNE ll_wrap			; error otherwise
	INY					; next byte is CPU type then
	LDA [rh_scan], Y	; get it
	CMP #'V'			; Rockwell is the only unsupported type! but look for any other 65xx option
		BEQ ll_native		; native 65816 is fine!
#ifdef	SUPPORT
	CMP #'B'			; generic 65C02
		BEQ ll_valid		; also OK but bank 0 only
	CMP #'N'			; old NMOS
		BEQ ll_valid		; if neither this one, unsupported CPU type!
#endif
ll_wrap:
	_ERR(INVALID)		; unsupported CPU
#ifdef	SUPPORT
ll_valid:
; *** CPU-type is compatible but has 8-bit code, this would only work at bank zero! ***
	LDX ex_pt+2			; check bank
		BNE ll_wrap			; outside 0, not for this kind of code!
#endif
ll_native:
; either is 65816 code anywhere, or 6502 in bank 0
	STA cpu_ll			; set CPU type, now will not matter whether XIP or not!
	.al: REP #$20		; *** 16-bit memory again ***
	LDA rh_scan+1		; get pointer MSB+BANK
	INC					; start from next page (skip header)
	STZ ex_pt			; *** assume all headers are page-aligned *** eeeeek
	STA ex_pt+1			; save rest of execution pointer
	_EXIT_OK

	.as					; EEEEEEEEEEEK
#else
	_ERR(UNAVAIL)		; no headers to scan
#endif


; *********************************
; *** STRING, prints a C-string ***
; *********************************
;		INPUT
; Y			= dev
; str_pt	= 24b pointer to string (might be altered!) ZP corrected!
;		OUTPUT
; C = device error
;		USES iol_dev and whatever the driver takes
;
; cio_lock is a kernel structure
	.asc	"<STRING>"
string:
#ifdef	SUPPORT
; check architecture in order to discard bank address
	LDA @run_arch		; will be zero for native 65816
	BEQ str_24b			; 24-bit enabled
		STZ str_pt+2		; ...or bank 0!
		LDA str_pt+1		; was zeropage?
		BNE str_24b			; no, proceed
			TDC					; ...or get context, full 16-bit regardless of M bit
			XBA					; MSB only, assume page-aligned
			STA str_pt+1
str_24b:
#endif
	PHY					; eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeek
	LDY #0				; will be fully cleared...
	.xl: REP #$10		; *** 16-bit indexes ***
	LDX str_pt			; must transfer parameter!!!!!!!!!!!!!!!!!!
	LDA str_pt+2		; and bank too eeeeeeeeeeeeeeeeeek
	STX bl_ptr			; eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeek
	STA bl_ptr+2		; eeeeeeeeeeeeeeeeek
str_loop:
		LDA [str_pt], Y		; check pointed char
			BEQ str_end		; NULL terminates
		INY					; continue
		BRA str_loop
str_end:
	STY bl_siz			; simply store size! eeeeeeeeeeeeeeeeeeeeeeeeeek
	.xs: SEP #$10		; *** stack pull needs standard index size ***
	PLY					; eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeek^2
	_KERNEL(BLOUT)		; and call block output (could be patched)
	JMP cio_callend		; will return proper error


; ******************************
; *** READLN, buffered input ***
; ******************************
;		INPUT
; Y			= device
; str_pt	= 24b pointer to buffer, ZP corrected!
; ln_siz	= max offset
;		OUTPUT
; C = some error
;		USES rl_dev, rl_cur and whatever CIN/COUT take
	.asc	"<READLN>"
readln:
; no need to switch DBR as regular I/O calls would do it
#ifdef	SUPPORT
; check architecture in order to discard bank address
	LDA @run_arch		; will be zero for native 65816 eeeeeeeeeek
	BEQ rl_24b			; 24-bit enabled
		STZ str_pt+2		; ...or bank 0 only
		LDA str_pt+1		; zeropage?
		BNE rl_24b			; do not correct...
			TDC					; ...or get context
			XBA					; MSB only (assume page aligned)
			STA str_pt+1		; correct pointer
rl_24b:
#endif
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


; ***********************************************************
; *** SHUTDOWN, proper shutdown, with or without poweroff ***
; ***********************************************************
;		INPUT
; Y = subfunction code
;		OUTPUT
; C = couldn't poweroff or reboot (?)
;		USES b_sig (calls B_SIGNAL)
; sd_flag is a kernel variable
	.asc	"<SHUTDOWN>"
shutdown:
	CPY #PW_CLEAN		; from scheduler only!
		BEQ sd_2nd			; continue with second stage
	CPY #PW_STAT		; is it going to suspend?
		BEQ sd_fw			; do not shutdown system then!
; interrupt invoking, although for internal use
	CPY #PW_NMI		; some invoking?
		BCS sd_fw			; just pass to FW
	TYA					; no longer switches DBR
	STA @sd_flag		; store mode for later, first must do proper system shutdown, note long addressing
; ask all braids to terminate
	LDY #0				; PID=0 means ALL braids
	LDA #SIGTERM		; will be asked to terminate
	STA b_sig			; store signal type
	_KERNEL(B_SIGNAL)	; ask braids to terminate *** no longer deindexing call as could be patched!
	PLP					; original mask is buried in stack, no DBR was saved!
	CLI					; make sure all will keep running!
	PHP					; restore for subsequent RTI
	_EXIT_OK			; unified stack frame makes irrelevant whether XIP or not
; actually RTI for 816

; firmware interface
sd_fw:
	_ADMIN(POWEROFF)	; except for suspend, shouldn't return...
	JMP cio_callend		; return successfully (suspend) or notify error
sd_off:
	LDY #PW_OFF			; poweroff
	BRA sd_fw			; shared code
sd_cold:
	LDY #PW_COLD		; cold boot
	BRA sd_fw
sd_warm:
; current status may vary widely, thus clean up some things a bit
; not sure about keeping this as SAFE mode already does it on kernel...
; ...thus just put .word warm on table!
	SEC					; set carry...
	XCE					; ...to set emulation mode for a moment
	PHK					; a zero on stack...
	PLB					; ...will be current data bank, not guaranteed elsewhere!
; SEI & CLD is always done by kernel
	JMP warm			; firmware no longer should take pointer, generic kernel knows anyway

; the scheduler will wait for NO braids active
; now let's disable all drivers
sd_2nd:
	LDA @sd_flag		; check what was pending
	BNE sd_shut			; something to do
		_PANIC("{sched}")	; otherwise it is an error!
sd_shut:
	SEI					; disable interrupts (forever)
; let us shut down all drivers thru DR_SHUT! (11b, was 25b)
	LDX #128			; first valid device driver ID
sd_loop:
		LDA @dr_ind, X		; is this ID in use?
		BEQ sdl_skip		; no, just skip it
			PHX					; must save
			TXY					; use as parameter
			_KERNEL(DR_SHUT)	; turn this off
			PLX					; retrieve
sdl_skip:
		INX					; next device
		BNE sd_loop			; until done!
; system cleanly shut, time to let the firmware turn-off or reboot
sd_done:
	LDA @sd_flag		; retrieve mode...
	TAX					; ...as index!
	JMP (sd_tab-2, X)	; do as appropriate *** note offset as sd_stat will not be called from here

sd_tab:					; check order in abi.h!
; no more sd_stat!
	.word	sd_warm		; warm boot direct by kernel ***or just 'warm'
	.word	sd_cold		; cold boot via firmware
	.word	sd_off		; poweroff system


; *******************************
; *** DR_INST, install driver ***
; *******************************
;		INPUT
; da_ptr	= 16b pointer to the proposed driver header (certainly in bank 0)
;		OUTPUT
; Y			= actually assigned ID (if mutable)
; C			= could not install driver (ID in use or invalid, queue full, init failed)
	.asc	"<DR_INST>"
dr_inst:
; make sure we work on bank zero!
	PHB					; eeeeeeeeeeeeeeeeeeeeeeeeeek
	PHK					; zero...
	PLB					; ...is the bank!
; minimOS•16 API defaults to 8 bit sizes
; get some info from header
; dynamic drivers currently not supported
#ifdef	SAFE
	LDY #D_MEM
	LDA (da_ptr), Y
	INY
	ORA (da_ptr), Y
		BNE dr_derr
#endif
; assuming D_ID is zero, just use non-indexed indirect to get ID (not much used anyway)
	LDA (da_ptr)		; check ID...
; will be stored later, in case is changed
#ifdef	SAFE
	BMI dr_phys			; only physical devices (3/2)
; logical devices cannot be installed this way, function should return INVALID error
dr_derr:
		JMP dr_iabort		; reject logical devices (3)
dr_phys:
#endif

; *** before registering, check whether the driver COULD be successfully installed ***
; that means 1.the ID is not already in use eeeeeeeek
; 2.there must be room enough on the interrupt queues for its tasks, if supplied
; and 3.the D_INIT routine succeeded as usual
; otherwise, skip the installing procedure altogether for that driver

; * 1) first check whether this ID was not in use *
; since I/O pointers are always set, pseudo-drivers are detected too!
; always using sparse arrays, will not convert ID to index yet...
	TAX					; definitive ID must end here, just in case, but also in A (2)
	LDY dr_ind-128, X	; get proper offset as arrays are sparse!
; new 170523, TASK_DEV is nothing to be checked
; offsets are +1, thus 0 means free entry!
	BEQ dr_empty		; if free, all done
#ifdef		MUTABLE
; new system for mutable IDs, 171013
; filter bits and scan possible IDs for this kind of device
; original ID must be already in A
		AND #%11110000		; filter relevant
		TAX					; base offset
		LDY #8				; devs per kind
dr_nxid:
			LDA dr_ind-128, X	; ID in use?
				BEQ dr_empty		; no, all OK now
			INX					; yes, try next
			DEY					; one less to go
			BNE dr_nxid
#endif
dr_busy:
; already in use, function should return BUSY error code
		JMP dr_babort		; already in use (3)
dr_empty:
	STX dr_id			; keep updated ID

; * 2) check room in queues, where needed *
	LDY #D_AUTH			; let us get the provided features (2)
	LDA (da_ptr), Y		; will be checked in a non-destructive way (5)
	STA dr_aut			; also saved for later (3)
	LDX #1				; last queue (2)
dr_chk:
		ASL					; extract MSB (will be A_POLL first, then A_REQ) best done in 8-bit! (2)
		BCC dr_ntsk			; skip verification if task not enabled (3/2)
			LDY queue_mx, X		; get current tasks in queue, no offset (4)
			CPY #MX_QUEUE		; room for another? (2)
			BCC dr_ntsk			; there is (3/2)
; again, no room for driver, return FULL error code
				JMP dr_fabort		; or no way OK (3)
dr_ntsk:
		DEX					; check next feature (2)
		BNE dr_chk			; zero included (3/2) ***BNE works on 8-bit, but does NOT check A_REQ! should be BPL...

; * 2b) in case of DYNAMIC drivers, requested space must be allocated successfully
; but if D_INIT fails afterwards, FREE must be called!

; * 3) if arrived here, it is possible to install, but run init code to confirm *
	.al: REP #$20		; *** 16-bit memory as required by dr_icall *** (3)
	JSR dr_icall		; call routine (6+...)
	.xs: .as: SEP #$30	; *** 8-bit indexes AND MEMORY just in case *** (3)
; as 816 function exit does not care about *memory* size, just return some error here...
	BCC dr_isuc			; init was successful, proceed
		JMP dr_uabort		; no way, forget about this (2/3)
dr_isuc:
; if arrived here, it is OK to install the driver!

; all checked OK, do actual driver installation!
; *** now adapted for new sparse arrays! ***
; time to look for an empty entry on sparse array
	LDX #2				; will not assing index 0 (2)
dr_ios:
		LDA drv_ads+1, X	; check MSB of entry, now on mandatory array (4)
			BEQ dr_sarr			; found a free entry (2/3)
		INX					; go for next (2+2)
		INX
		CPX #2*MX_DRVRS+2	; otherwise, is there room for more? (2) note +2 offset
		BNE dr_ios			; yes, continue (3)
	JMP dr_fabort		; no, complain (3)
dr_sarr:
; sequential index is computed, store it into direct array
	LDY dr_id			; get direct, mutable ID eeeeeeeeeeeeeeek (3)
	TXA					; alas, no STX abs,Y (2)
	STA dr_ind-128, Y	; store sparse index (4)
; proper index already in X and A
	.al: REP #$20		; *** 16-bit memory again, just in case *** (3)

; * 4) Set I/O pointers *
; no longer checks I/O availability as drv_ads array is mandatory!
; thus not worth a loop...
	LDY #D_BLIN			; offset for input routine (2)
	LDA (da_ptr), Y		; get full address (6)
	STA drv_ipt, X		; store full pointer in table, leaving dummy entry (5)
	LDY #D_BOUT			; offset for output routine (2)
	LDA (da_ptr), Y		; get full address (6)
	STA drv_opt, X		; store full pointer in table, leaving dummy entry (5)

; * 5) register interrupt routines * new, much cleaner approach
; dr_aut is now kept intact...
; time to get a pointer to the-block-of-pointers (source)
	LDY #D_POLL			; should be the FIRST of the three words (D_POLL, D_FREQ, D_ASYN)
	LDA (da_ptr), Y		; get full address (6)
	STA pfa_ptr			; get the source pointer
; also a temporary pointer to the particular queue
	LDA #drv_poll		; must be the first queue!
	STA dq_ptr			; store queue pointer
; new functionality 170519, pointer to (interleaved) task enabling queues
	LDA #drv_p_en		; this is the second one, will be decremented for async
	STA dte_ptr			; yet another temporary pointer...
; all set now, now easier to use a loop
	LDX #1				; index for periodic queue (2)
; *** suspicious code follows ***
dr_iqloop:
		.as: SEP #$20		; *** 8-bit shift *** eeeeeeeeeeeeeeek
		ASL dr_aut			; extract MSB (will be A_POLL first, then A_REQ) eeeeeeeeeeeeeeeeeeeeeeeeeeeeek
		BCC dr_noten		; skip installation if task not enabled
; prepare another entry into queue
			LDY queue_mx, X		; get index of free entry, will stay!
			INC queue_mx, X		; add another task in queue
			INC queue_mx, X		; pointer takes two bytes
; install entry into queue
; read pointer from header (inline version of dr_itask)
			al: REP #$20		; *** 16-bit memory ***
			LDA (pfa_ptr)		; get source pointer
; write pointer into queue
			STA (dq_ptr), Y		; store into reserved place!
; save for frequency queue, flags must be enabled for this task!
			.as: SEP #$20		; *** needs to go into 8-bit mode for a moment ***
			LDA dr_id			; use ID as flags, simplifies search and bit 7 hi (as per physical device) means enabled by default
			STA (dte_ptr), Y	; set default flags
; let us see if we are doing periodic task, in case frequency must be set also
			.al: REP #$20		; *** back to 16-bit, flags unaffected *** eeeeeeeeeeeeeeek
			TXA					; doing periodic?
				BEQ dr_ended		; if zero, is doing async queue, thus skip frequencies (in fact, already ended)
; will just return successfully if BEQ above gets executed...
			JSR dr_nextq		; advance to next queue (frequencies)
; read frequency value from header (inline version of dr_itask)
			LDA (pfa_ptr)		; non-indexed indirect
; write unmodified value into its queue
			STA (dq_ptr), Y		; store into reserved place!
; *** and copy A into drv_count, unmodified! ***
			STA drv_cnt, Y		; simply!
			BRA dr_doreq		; nothing to skip, go for async queue
dr_noten:
		.al: REP #$20		; needed for subsequent routine
		JSR dr_nextq		; if periodic was not enabled, this will skip frequencies queue
dr_doreq:
; as this will get into async, switch enabling queue
		DEC dte_ptr			; one before as it is interleaved
; continue into async queue
		JSR dr_nextq		; go for next queue
		DEX					; now 0, index for async queue (2)
		BPL dr_iqloop
; *** end of suspicious code ***
dr_ended:
	LDY dr_id			; must return actual ID, as might be mutable!
; sparse indexes always!
	.al: REP #$20
	LDX dr_ind-128, Y	; convert to sparse index!
	LDA da_ptr			; get header pointer, we were in 16-bit A (4)
	STA drv_ads, X		; store in proper entry, leaving dummy entry (5)
; function arriving here will simply exit successfully
	PLB					; *** make sure apps can call this from anywhere ***
	_EXIT_OK			; if arrived here, did not fail initialisation
; memory size seems irrelevant here, as long as 8-bit indexes

; **********************
; *** error handling ***
; **********************
dr_iabort:
	LDY #INVALID		; logical devices cannot be installed
	BRA dr_abort
dr_fabort:
	LDY #FULL			; no room on queue
	BRA dr_abort
dr_babort:
	LDY #BUSY			; ID already in use
	BRA dr_abort
dr_uabort:
	LDY #UNAVAIL		; init failed
dr_abort:
	PLB					; *** make sure apps can call this from anywhere ***
	JMP cio_setc		; * shared error exit *

; *****************************************
; *** some driver installation routines ***
; *****************************************

; * routine for advancing to next queue *
; both pointers in dq_ptr (destination queue) and pfa_ptr (pointer to header)
; A in 16-bit mode

dr_nextq:
	LDA dq_ptr			; get original queue pointer
	CLC
	ADC #MX_QUEUE		; go to next queue
	STA dq_ptr
	INC pfa_ptr			; increment the origin pointer!
	INC pfa_ptr			; not worth the old way
	RTS

; dr_itask is now inlined, and has dq_off already in Y!

dr_icall:
	LDY #D_INIT			; original pointer offset (2)
; *** generic driver call, pointer set at da_ptr, Y holds table offset
; *** assume 16-bit memory and 8-bit indexes ***
; takes 7 bytes (could be 2 less) 21 clocks, was 10 bytes, 29 clocks
; make certain about DBR in calls... but should be for kernel/API only
dr_call:
	LDA (da_ptr), Y		; destination pointer (6)
	DEC					; one less for RTS (2)
	PHA					; push it (4)
	.as: .xs: SEP #$30	; make sure driver is called in 8-bit size (3)
	RTS					; actual CORRECTED jump (6)


; ******************************
; *** DR_SHUT, remove driver ***
; ******************************
;		INPUT
; Y			= target ID
;		OUTPUT
; da_ptr	= pointer to header from removed driver (if available, C otherwise)
	.asc	"<DR_SHUT>"
dr_shut:

#ifdef	SAFE
	TYA					; check device
	BMI ds_phys			; should be OK...
		_ERR(INVALID)		; ...or bust!
ds_phys:
#endif

	LDX dr_ind-128, Y	; is that being used?
	BNE ds_used			; yes, proceed to remove
		_ERR(N_FOUND)		; no, nothing to remove
ds_used:
	LDA #0				; this means free device, unfortunately no STZ abs,Y
	STA dr_ind-128, Y	; this is no more, any problem here? ***use whatever null value***
	.al: REP #$20		; *** 16-bit memory ***
	LDA drv_ads, X		; get full header pointer
	STA da_ptr			; report from removed, will serve as ZP pointer too
; make sure this entry is reported as free for future use
	STZ drv_ads, X		; clear this entry as now mandatory (first entry is dummy)
; needs to disable interrupt tasks!
; *** perhaps using AQ_MNG and PQ_MNG???
	STY dr_id			; targeted ID must be compared to entries
	LDX #MX_QUEUE-1		; maximum valid index, including interleaving
	.as: SEP #$20		; *** back to 8-bit ***
ds_qseek:
		LDA drv_a_en, X		; get entry from whatever queue
		ORA #%10000000		; disabled or not
		CMP dr_id			; is this entry from targeted ID?
		BNE dr_qnxt			; no, try another
			STZ drv_a_en, X		; yes, clear queue entry
dr_qnxt:
		DEX				; previous entry, will switch queue
		BPL ds_qseek	; ***will work below 128 bytes
; finally, execute proper shutdown
	_CRITIC
	LDY #D_BYE			; offset to shutdown routine
	JSR dr_call			; execute shutdown procedure via GENERIC routine *** interrupts off ***
	_NO_CRIT
	_EXIT_OK			; all done


; *********************************************
; *** DR_INFO, get pointer to driver header ***
; *********************************************
;		INPUT
; Y			= requested device ID
;		OUTPUT
; ex_pt		= 16b pointer to driver header, for any suitable Y
; def_io	= std_in@L and stdout@H devices, if Y=0!
	.asc	"<DR_INFO>"
dr_info:
	TYA					; asking for defaults (2)
	BNE di_ndef			; no, proceed as usual (3/2)
; try to resolve default global devices
; initial attempt going into 16-bit mode was 23 bytes, best 25 cycles, worst 35 cycles
; *** alternative approach on full 8-bit *** 18 bytes, best 18 cycles, worst 24 bytes
		LDX std_in			; get std_in here (LSB) (/3)
		BNE di_sinz			; non-standard input (/3/2)
			LDX dflt_in			; otherwise, get system global! (//4)
di_sinz:
		LDA stdout			; get stdout too (/3)
		BNE di_sonz			; non-standard output (/3/2)
			LDA dfltout			; otherwise get system global (//4)
di_sonz:
		STA def_io+1		; now store MSB as exit parameter (/3)
		STX def_io			; this is the already processed LSB (/3)
		_EXIT_OK
di_ndef:
; as drv_ads is now mandatory, no need for MUTABLE option
	LDX dr_ind-128, Y	; get sparse index, is it free? (4+)
	BEQ di_none			; yes, signal error (3/2)
		.al: REP #$20		; *** 16-bit memory *** (/3)
		LDA drv_ads, X		; otherwise get full pointer (first entry is dummuy)... (/5)
		STA ex_pt			; ...and store it as exit parameter (/4)
		_EXIT_OK
di_none:
	_ERR(N_FOUND)		; no such ID

	.xs:


; ***************************************************************
; *** TS_INFO, get taskswitching info for multitasking driver ***
; ***************************************************************
;		OUTPUT
; Y		= number of bytes
; ex_pt = 16b pointer to the proposed stack frame (certainly in bank 0)
	.asc	"<TS_INFO>"
ts_info:
	.al: REP #$20		; *** 16-bit memory ***
	LDA #tsi_str		; pointer to proposed stack frame
	STA ex_pt			; store output word
;	STZ ex_pt+2			; clear if needed
	LDY #tsi_end-tsi_str	; number of bytes
	_EXIT_OK

tsi_str:
; pre-created reversed stack frame for firing tasks up, regardless of multitasking driver implementation
	.word	isr_schd-1	; corrected reentry address, standard label from ISR
	.byt	1				; stored X value, best if multitasking driver is the first one EEEEEEEEEEEK not zero!
;	.word	0, 0, 0			; irrelevant register values
tsi_end:
; end of stack frame for easier size computation

	.as:

; *********************************************
; *** RELEASE, release ALL memory for a PID *** perhaps to be deprecated???
; *********************************************
;		INPUT
; Y		= PID, 0 means myself
;		USES ma_pt and whatever takes FREE (will call it)
; this is NOT intended to be called by apps, kernel & multitasking driver only, thus do not care about architecture
; but make certain that FREE calls are 24-bit enabled!
; * 8-bit savvy, I think *
	.asc	"<RELEASE>"
release:
; switch DBR as it accesses a lot of kernel data!
	PHB					; eeeeeeeeek
	PHK					; bank 0 into stack
	PLB					; set DBR! do not forget another PLB upon end!
; proceed
; ** not sure if I really need to save this value... **
; supposedly this will be called upon task death!
;	LDX run_arch		; "current" (?) architecture
;	PHX					; save it!
	STZ run_arch		; clear this to make it 24-bit enabled
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
;	PLX					; take a byte from stack
;	STX run_arch		; restore value, just in case
	PLB					; restore!
	_EXIT_OK			; no errors...

	.as:

; ***********************************************************
; *** SET_CURR, set internal kernel info for running task ***
; ***********************************************************
;		INPUT
; Y			= PID
; cpu_ll	= architecture (0=65816, 2=Rockwell, 4=65C02, 6=NMOS... or at least 0 for 65816)
;		OUTPUT
; Y			= preset PID (must respect it!)
; affects internal sysvars run_pid & run_arch
	.asc	"<SET_CURR>"
set_curr:
	TYA					; eeeeek, no long STY (2)
	STA @run_pid		; store PID into kernel variables (5)
	LDA cpu_ll			; get architecture from multitasking driver (3)
	STA @run_arch		; and store it for kernel use (5)
	_EXIT_OK

; *******************************
; *** end of kernel functions ***
; *******************************
