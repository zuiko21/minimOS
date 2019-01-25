; minimOS generic Kernel API
; v0.6rc24, must match kernel.s
; (c) 2012-2019 Carlos J. Santisteban
; last modified 20190125-1114
; no way for standalone assembly...

; **************************************************
; *** jump table, if not in separate 'jump' file ***
; **************************************************
#ifndef		DOWNLOAD
k_vec:
; FAST API option needs no jump table!
#ifndef	FAST_API
; basic I/O
	.word	cout		; output a character
	.word	cin			; get a character
	.word	string		; prints a C-string
	.word	readln		; buffered input
; block-oriented I/O
	.word	blout		; block output
	.word	blin		; block input
	.word	bl_cnfg		; I/O config, new
	.word	bl_stat		; I/O query, new
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
	.word	dr_info		; driver header ***new
	.word	aq_mng		; manage asynchronous task queue
	.word	pq_mng		; manage periodic task queue
; only for systems with enough RAM
; drivers...
	.word	dr_inst		; install driver
	.word	dr_shut		; shutdown driver
; memory...
	.word	malloc		; reserve memory
	.word	free		; release memory
	.word	memlock		; reserve some address
	.word	release		; release ALL memory for a PID
; multitasking...
	.word	ts_info		; get taskswitching info
	.word	set_curr	; set internal kernel info for running task
#endif
#endif

; ***************************************
; *** dummy function, non implemented ***
; ***************************************

; *** FUTURE IMPLEMENTATION *** reserve some addresses
memlock:
aq_mng:
pq_mng:
bl_cnfg:
bl_stat:

unimplemented:			; placeholder here
	_ERR(UNAVAIL)		; go away!


; ****************************
; *** CIN, get a character *** no longer manage events!
; ****************************
;		INPUT
; Y = dev
;		OUTPUT
; io_c	= char
; C		= not available
;		USES whatever BLIN takes
	.asc	"<CIN>"
cin:
	LDA #io_c			; will point to old parameter
	STA bl_ptr			; set pointer
	_STZA bl_ptr+1
	LDA #1				; transfer a single byte
	STA bl_siz			; set size
	_STZA bl_siz+1
	_KERNEL(BLIN)		; get small block...
		RTS					; ...or keep error code from BLIN
; *** events no longer managed here ***


; ********************************
; *** COUT, output a character ***
; ********************************
;		INPUT
; Y		= dev
; io_c	= char
;		OUTPUT
; C = I/O error
;		USES whatever BLOUT takes
	.asc	"<COUT>"
cout:
	LDA #io_c			; will point to old parameter
	STA bl_ptr			; set pointer
	_STZA bl_ptr+1
	LDA #1				; transfer a single byte
	STA bl_siz			; set size
	_STZA bl_siz+1
; ...and fall into BLOUT

; ***************************
; *** BLOUT, block output ***
; ***************************
;		INPUT
; Y		= dev
; bl_pt		= pointer to block
; bl_siz	= number of bytes (16b)

;		OUTPUT
; bl_siz	= remaining bytes
; C		= I/O error
;		USES iol_dev plus whatever the driver takes
; cio_lock is a kernel structure
	BRA blout
	.asc	"<BLOUT>"
blout:
	TYA					; basic ID check (2)
	BNE co_port			; not default (3/2)
		LDY stdout			; new per-process standard device
		BNE co_port			; already a valid device
			LDY dfltout			; otherwise get system global (4)
co_port:
	BMI co_phys			; not a logic device (3/2)
		CPY #64				; first file-dev??? ***
			BCC co_win			; below that, should be window manager
; ** optional filesystem access **
#ifdef	FILESYSTEM
		CPY #64+MX_FILES	; still within file-devs?
			BCS co_log			; that value or over, not a file
; *** manage here output to open file ***
#endif
; ** end of filesystem access **
co_win:
; *** virtual windows manager TO DO ***
		_ERR(NO_RSRC)		; not yet implemented ***placeholder***
co_log:
; investigate rest of logical devices
		CPY #DEV_NULL		; lastly, ignore output
		BNE cio_nfound		; final error otherwise
			_STZA bl_siz		; transfer fullfilled eeeeeek
			_STZA bl_siz+1
			_EXIT_OK			; "/dev/null" is always OK
; *** common I/O call ***
cio_nfound:
	_ERR(N_FOUND)		; unknown device

; * stuff begins here *
co_phys:
; arrived here with dev # in Y eeeeeek
; new per-phys-device MUTEX for COUT, no matter if singletask!
; new indirect-sparse array system!
	LDX dr_ind-128, Y	; get proper index for that physical ID (4)
; a dummy first entry in pointer arrays make checking for available devices unnecessary!
; newly computed index is stored as usual
	STX iol_dev			; keep device-index temporarily, worth doing here (3)
	_CRITIC				; needed for a MUTEX (5)
co_loop:
		LDA cio_lock, X		; check whether THAT device is in use (4)
			BEQ co_lckd			; resume operation if free (3)
; otherwise yield CPU time and repeat
		_KERNEL(B_YIELD)	; otherwise yield CPU time and repeat *** could be patched!
		LDX iol_dev			; retrieve index!
		_BRA co_loop		; try again! (3)
co_lckd:
	LDA run_pid			; get ours in A, faster!
	STA cio_lock, X		; reserve this (4)
	_NO_CRIT
; continue with mutually exclusive COUT
	JSR co_call			; direct CALL!!! driver should end in RTS as usual via the new DR_ macros

; *** common I/O call ***
cio_unlock:
	LDX iol_dev			; get offest, need to clear new lock! (3)
	_STZA cio_lock, X	; ...because I have to clear MUTEX! (4)
	RTS					; exit with whatever error code

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
; cio_lock & cin_mode are kernel structures
	.asc	"<BLIN>"
blin:
	TYA					; update flags from Y contents
	BNE ci_port			; specified
		LDY std_in			; new per-process standard device
		BNE ci_port			; already a valid device
			LDY dflt_in			; otherwise get system global
ci_port:
	BPL ci_nph			; logic device
; new MUTEX for CIN, physical devs only! ID arrives in Y!
; new indirect-sparse array system!
	LDX dr_ind-128, Y	; get proper index for that physical ID (4)
; a dummy first entry in pointer arrays make checking for available devices unnecessary!
; newly computed index is stored as usual
	STX iol_dev			; keep sparse-physdev temporarily, worth doing here (3)
; * this has to be done atomic! *
	_CRITIC
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
		LDX iol_dev			; restore previous status (3)
		_BRA ci_loop		; try again! (3)
ci_lckd:
	LDA run_pid			; who is me?
	STA cio_lock, X		; reserve this (4)
ci_lckdd:
	_NO_CRIT
; * end of atomic operation *
	JSR ci_call			; direct CALL!!!
	_BRA cio_unlock		; clear MUTEX and return whatever error!

; ** EVENT management no longer here **

; logical devices management, * placeholder
ci_nph:
	CPY #64				; within window devices?
		BCC ci_win			; below that, should be window manager
; ** optional filesystem access **
#ifdef	FILESYSTEM
	CPY #64+MX_FILES	; still within file-devs?
		BCS ci_log			; that or over, not a file
; *** manage here input from open file ***
#endif
; *** virtual window manager TO DO ***
ci_win:
	_ERR(NO_RSRC)		; not yet implemented ***placeholder***

; *** manage logical devices ***
ci_log:
	CPY #DEV_RND		; getting a random number?
		BEQ ci_rnd			; compute it!
	CPY #DEV_NULL		; lastly, ignore input...
		BEQ ci_ok			; but work like "/dev/zero"
	JMP cio_nfound		; final error otherwise

; these loops could be unified somehow...
ci_rnd:
; *** generate random number (TO DO) ***
	LDY #0				; reset index
	LDX bl_ptr+1		; keep MSB just in case***
cirn_loop:
		LDA ticks			; simple placeholder******* eeeeeeek
		STA (bl_ptr), Y		; store in buffer
		INY					; go for next
		BNE cirn_nw			; no wrap...
			INC bl_ptr+1		; ...or next page*****
cirn_nw:
		DEC bl_siz			; one less to go
		BNE cirn_loop		; no boundary crossing...
			DEC bl_siz+1		; ...or propagate...
			LDA bl_siz+1		; ...and check value...
			CMP #$FF			; ...whether wrapped...
		BNE cirn_loop		; ...until the end
	STX bl_ptr+1		; restore pointer***
ci_ok:
	_EXIT_OK

ci_null:
; reading from DEV_NULL works like /dev/zero, must fill buffer with zeroes!
		LDX bl_siz			; LSB as offset
			BEQ ci_nlw			; empty perhaps?
		LDA #0				; fill buffer with this
		TAY					; reset ascending offset
ci_nll:
			STA (bl_ptr), Y		; put a zero into buffer
			INY					; try one more
			BNE ci_ny			; no wrap yet
				INC bl_ptr+1		; or increment MSB*** but save it!!
ci_ny:
			DEC bl_siz			; one less to go
			BNE ci_nll
ci_nlw:
		LDX bl_siz+1		; check MSB
			BEQ ci_nle			; all done!
		DEC bl_siz+1		; or continue
		_BRA ci_nll
ci_nle:
; placeholder exit, must restore altered pointer
	_EXIT_OK

; *** for 02 systems without indexed CALL ***
co_call:
	_JMPX(drv_opt)		; direct jump to output routine

ci_call:
	_JMPX(drv_ipt)		; direct jump to input routine


; ******************************
; *** MALLOC, reserve memory ***
; ******************************
;		INPUT
; ma_rs		= size (0 means reserve as much memory as available)
; ma_align	= page mask (0=page/not aligned, 1=512b, $FF=bank aligned)
;		OUTPUT
; ma_pt	= pointer to reserved block
; ma_rs	= actual size (esp. if ma_rs was 0, but check LSB too)
; C		= not enough memory/corruption detected
;		USES ma_ix.b
; ram_stat & ram_pid (= ram_stat+1) are interleaved in minimOS-16
	.asc	"<MALLOC>"
malloc:
	LDX #0				; reset index
	LDY ma_rs			; check individual bytes, just in case
	BEQ ma_nxpg			; no extra page needed
		INC ma_rs+1			; otherwise increase number of pages
		STX ma_rs			; ...and just in case, clear asked bytes!
ma_nxpg:
	_CRITIC				; this is dangerous! enter critical section, new 160119
	LDA ma_rs+1			; get number of asked pages
	BNE ma_scan			; work on specific size
; otherwise check for biggest available block
ma_biggest:
#ifdef	SAFE
			CPX #MAX_LIST		; already past?
				BEQ ma_corrupt		; something was wrong!!!
; *** self-healing feature for full memory assignment! ***
			LDA ram_pos+1, X	; get end position (4)
			SEC
			SBC ram_pos, X		; subtract current for size! (2+4)
				BCC ma_corrupt		; corruption detected!
#endif
			LDY ram_stat, X		; get status of block (4)
;			CPY #FREE_RAM		; not needed if FREE_RAM is zero! (2)
			BNE ma_nxbig		; go for next as this one was not free (3/2)
				JSR ma_alsiz		; **compute size according to alignment mask**
				CMP ma_rs+1			; compare against current maximum (3)
				BCC ma_nxbig		; this was not bigger (3/2)
					STA ma_rs+1			; otherwise keep track of it... (3)
					STX ma_ix			; ...and its index! (3)
ma_nxbig:
			INX					; advance index (2)
			LDY ram_stat, X		; peek next status (4)
			CPY #END_RAM		; check whether at end (2)
			BNE ma_biggest		; or continue (3/2)
; is there at least one available block?
		LDA ma_rs+1			; should not be zero
		BNE ma_fill			; there is at least one block to allocate
			_NO_CRIT			; eeeeeeek! we are going
			_ERR(FULL)			; otherwise no free memory!
; report allocated size
ma_fill:
		LDX ma_ix			; retrieve index
		_BRA ma_falgn		; nothing to scan, only if aligned eeeeeek
ma_scan:
; *** this is the place for the self-healing feature! ***
#ifdef	SAFE
		CPX #MAX_LIST		; already past?
			BEQ ma_corrupt		; something was wrong!!!
; check UNALIGNED size for self-healing feature! worth a routine?
		LDA ram_pos+1, X	; get end position (4)
		SEC
		SBC ram_pos, X		; subtract current for size! (2+4)
		BCS ma_nobad		; no corruption was seen (3/2) **instead of BPL** eeeeeek
ma_corrupt:
			LDX #>user_ram		; otherwise take beginning of user RAM...
			LDY #<user_ram		; LSB misaligned?
			BEQ ma_zlsb			; nothing to align
				INX					; otherwise start at next page
ma_zlsb:
			LDY #LOCK_RAM		; ...that will become locked (new value)
			STX ram_pos			; create values
			STY ram_stat		; **should it clear the PID field too???**
			LDA #SRAM			; physical top of RAM...
			LDY #END_RAM		; ...as non-plus-ultra
			STA ram_pos+1		; create second set of values
			STY ram_stat+1
			_NO_CRIT			; eeeeeeeeeek
			_ERR(CORRUPT)		; report but do not turn system down
ma_nobad:
#endif
		LDY ram_stat, X		; get state of current entry (4)
;		CMP #FREE_RAM		; looking for a free one (2) not needed if free is zero
			BEQ ma_found		; got one (2/3)
		CPY #END_RAM		; got already to the end? (2)
			BEQ ma_nobank		; could not found anything suitable (2/3)
ma_cont:
		INX					; increase index (2)
;		CPX #MAX_LIST		; until the end (2)
		BNE ma_scan			; will not be zero anyway (3)
ma_nobank:
	_NO_CRIT			; non-critical when aborting!
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
		_INC				; ...and reset them after increasing the rest
		PHA					; need to keep the new aligned pointer!
		JSR ma_adv			; create room for assigned block (BEFORE advancing eeeeeeeek)
		INX					; skip the alignment blank
		PLA					; retrieve aligned address
		STA ram_pos, X		; update pointer on assigned block
ma_aok:
	PLA					; retrieve size
; make room for new entry... if not exactly the same size
	CMP ma_rs+1			; compare this block with requested size eeeeeeeek
	BEQ ma_updt			; was same size, will not generate new entry
; **should I correct stack balance for safe mode?
		JSR ma_adv			; make room otherwise, and set the following one as free padding
; create after the assigned block a FREE entry!
		LDA ram_pos, X		; newly assigned slice will begin there eeeeeeeeeek
		CLC
		ADC ma_rs+1			; add number of assigned pages
		STA ram_pos+1, X	; update value
		LDA #FREE_RAM		; let us mark it as free, PID is irrelevant!
		STA ram_stat+1, X	; next to the assigned one, no STY abs,X!!!
ma_updt:
	_STZA ma_pt			; clear pointer LSB
	LDA ram_pos, X		; get address of block to be assigned
	STA ma_pt+1			; note this is address of PAGE
	LDA #USED_RAM		; now is reserved
	STA ram_stat, X		; update table entry
; ** new 20161106, store PID of caller **
	LDA run_pid			; who asked for this? FASTER
	STA ram_pid, X		; store PID
; theoretically we are done, end of CS
	_NO_CRIT			; end of critical section, new 160119
	_EXIT_OK			; we're done

; **** routine for aligned-block size computation ****
; returns found size in A, sets C if OK, error otherwise (C clear!)
ma_alsiz:
	LDA ram_pos, X		; get bottom address (4)
	BIT ma_align		; check for set bits from mask (4)
	BEQ ma_fit			; none was set, thus already aligned (3/2)
		ORA ma_align		; set masked bits... (3)
		_INC				; ...and increase address for alignment (2)
ma_fit:
	EOR #$FF			; invert bits as will be subtracted to next entry (2)
	SEC					; needs one more for twos-complement (2)
	ADC ram_pos+1, X	; compute size from top ptr MINUS bottom one (5)
	RTS

; **** routine for making room for an entry ****
ma_adv:
	STX ma_ix			; store current index
ma_2end:
		INX					; previous was free, thus check next
#ifdef	SAFE
		CPX #MAX_LIST-1		; just in case, check offset!!! (needs -1?)
		BCC ma_notend		; could expand
			PLA					; discard return address
			PLA
			_BRA ma_nobank		; notice error
ma_notend:
#endif
		LDY ram_stat, X		; check status of block
		CPY #END_RAM		; scan for the end-of-memory marker
		BNE ma_2end			; hope will eventually finish!
ma_room:
		LDA ram_pos, X		; get block address
		STA ram_pos+1, X	; one position forward
		LDA ram_stat, X		; get block status
		STA ram_stat+1, X	; advance it
		LDA ram_pid, X		; same for PID, non-interleaved!
		STA ram_pid+1, X	; advance it
		DEX					; down one entry
		CPX ma_ix			; position of updated entry
		BNE ma_room			; continue until done
; no longer creates at the beginning of the moved block a FREE entry!
	RTS


; ****************************
; *** FREE, release memory ***
; ****************************
;		INPUT
; ma_pt = addr
;		OUTPUT
; C = no such used block
;
; ram_pos & ram_stat are kernel structures
	.asc	"<FREE>"
free:
#ifdef	SAFE
	LDY ma_pt			; LSB currently not implemented
		BNE fr_nos			; could not find
#endif
	LDX #0				; reset index
	LDA ma_pt+1			; get comparison PAGE eeeeeeeeek
	_CRITIC				; supposedly dangerous
fr_loop:
		CMP ram_pos, X		; is what we are looking for?
			BEQ fr_found		; go free it!
		INX					; advance index
		LDY ram_stat, X		; anyway check status
		CPY #END_RAM		; no more in list?
		BNE fr_loop			; continue until end
; was not found, thus exit CS and abort
fr_no:
	_NO_CRIT
fr_nos:
	_ERR(N_FOUND)		; no block to be freed!
fr_found:
	LDY ram_stat, X		; only used blocks can be freed!
	CPY #USED_RAM		; was it in use?
		BNE fr_no			; if not, cannot free it!
	LDA #FREE_RAM		; most likely zero, might use STZ instead
	STA ram_stat, X		; this block is now free, but...
; really should join possible adjacent free blocks
	LDY ram_stat+1, X	; check status of following entry
;	CPY #FREE_RAM		; was it free? could be supressed if value is zero
	BNE fr_notafter		; was not free, thus nothing to optimise forward
		JSR fr_join			; integrate following free block
	BEQ fr_ok			; if the first block, cannot look back eeeeeeeeeek
fr_notafter:
	TXA					; check whether it was the first block
		BEQ fr_ok			; do not even try to look back eeeeeeeeeeek
	DEX					; let us have a look to the previous block
	LDY ram_stat, X		; is this one free?
;	CPY #FREE_RAM		; could be supressed if value is zero
	BNE fr_ok			; nothing to optimise backwards
		JSR fr_join			; otherwise integrate it too
; ** already optimized **
fr_ok:
	_NO_CRIT
	_EXIT_OK

; routine for obliterating the following empty entry
fr_join:
		LDA ram_pos+2, X	; get following address
		STA ram_pos+1, X	; store one entry below
		LDA ram_pid+2, X	; copy PID of following, but keep status for last!
		STA ram_pid+1, X	; no longer interleaved
		LDA ram_stat+2, X	; check status of following!
		STA ram_stat+1, X	; store one entry below
		CMP #END_RAM		; end of list?
		BNE fr_join			; repeat until done
	RTS


; **************************************
; *** OPEN_W, get I/O port or window ***
; **************************************
;		INPUT
; w_rect	= size VV.HH
; w_rect+2	= pos VV.HH
; str_pt	= pointer to title string
;		OUTPUT
; Y = dev
; C = not supported/not available
	.asc	"<OPEN_W>"
open_w:
	LDA w_rect			; asking for some size?
	ORA w_rect+1
	BEQ ow_no_window	; would not do it
		_ERR(NO_RSRC)
ow_no_window:
; ******************************************
; *** B_FORK, get available PID ************
; *** GET_FG, get current foreground PID ***
; ******************************************
;		OUTPUT
; Y		= PID, 0 means not available or singletask
	BRA get_fg
	.asc	"<B_FORK,GET_FG>"
get_fg:
b_fork:
	LDY #0				; constant default device or standard single task
; ***** EXIT_OK on subsequent system calls!!! *****

; ********************************************************
; *** CLOSE_W,  close window *****************************
; *** FREE_W, release window, will be closed by kernel ***
; *** FLOAT_W, put window in foreground ******************
; *** B_YIELD, yield CPU time to next braid **************
; ********************************************************
;		INPUT
; Y = dev (unless it is B_YIELD)
	BRA close_w
	.asc	"<CLOSE_W,FREE_W,FLOAT_W,B_YIELD>"
close_w:				; does not do much
free_w:					; does not do much, either
float_w:				; placeholder
b_yield:
	_EXIT_OK


; **************************************
; *** UPTIME, get approximate uptime ***
; **************************************
;		OUTPUT
; up_sec	= approximate 24-bit uptime in secs for API compatibility
; up_ticks	= 32-bit uptime in ticks, new format 20170822
	.asc	"<UPTIME>"
uptime:
	LDX #3				; max offset, count backwards (2)
	_CRITIC				; don't change while copying (5)
up_loop:
		LDA ticks, X		; get system variable byte (4)
		STA up_ticks, X		; and store them in output parameter (3)
		DEX					; go for next (2+3/2)
		BPL up_loop
	_NO_CRIT			; done (4)
	_EXIT_OK


; *****************************************
; *** B_EXEC, launch new loaded process ***
; *****************************************
;		INPUT
; Y			= PID, 0 means execute within this braid (destructive)
; ex_pt		= address of code to be executed (can be a mere subroutine)
; def_io	= std_in & stdout
;
; API still subject to change... (register values, rendez-vous mode TBD)
	.asc	"<B_EXEC>"
b_exec:
; non-multitasking version
#ifdef	SAFE
	TYA					; should be system reserved PID, best way
	BEQ ex_st			; OK for single-task system
		_ERR(NO_RSRC)		; no way without multitasking
ex_st:
#endif
	LDX #SPTR			; init stack
	TXS
	JSR ex_jmp			; call supplied address

; ***** SIGKILL handler, either from B_SIGNAL or at task completion *****
sig_kill:
; *** TO DO *** this should save Y & P.C (carry) somewhere for status report! ***
; first, free up all memory from previous task
;	LDY #0				; standard PID
;	KERNEL(RELEASE)	; free all memory eeeeeeeek
; *** non-XIP code should release its own block! ***
; cannot just pull from stack as SIGKILL may be executed at any time
;	LDY $FF+SPTR		; get stacked pointer of block...
;	LDA $100+SPTR		; ...MSB too...
;	STY ma_pt			; ...to be freed
;	STA ma_pt+1
;	KERNEL(FREE)		; free it or fail quietly
; *** end of non-XIP code, will not harm anyway ***
; then, check for any shutdown command
	LDA sd_flag			; some pending action?
	BEQ rst_shell		; if not, just restart the shell
		LDY #PW_CLEAN		; or go into second phase...
		JSR shutdown		; ...of shutdown procedure (could use JMP)*** what of patched???
; if none of the above, a single task system can only restart the shell!
rst_shell:
	LDX #SPTR			; init stack again (in case SIGKILL was called)
	TXS
	JMP sh_exec			; back to kernel shell!
ex_jmp:
; *** non-XIP code must push the block address at the very bottom of stack ***
;	LDA ex_pt+1			; get MSB...
;	PHA					; ...into stack
;	LDA ex_pt			; same for LSB, this way is NMOS savvy
;	PHA
; *** end of non-XIP code, will not harm anyway ***
; set default SIGTERM handler! eeeeeeeeeeeeeeeeeeeeek
	LDA #>sig_kill		; get MSB
	LDY #<sig_kill		; and LSB
	STY mm_sterm		; set variable
	STA mm_sterm+1
; this is how a task should replace the shell
	LDA #ZP_AVAIL		; eeeeeeeeeeek *** must be computed!
; NMOS systems (or apps!) get 2 bytes less
; C-64 gets four bytes less
; LOWRAM has reduced space, no matter the CPU or arch
	STA z_used			; otherwise SAFE will not work
; and set default devices!!! eeeeeeeeeeeeeeeeeeeeeeek
	LDA def_io			; standard input
	STA std_in			; set as default
	LDA def_io+1		; same for output
	STA stdout
; *** soon will preset registers according to new API ***
; at last, launch code
	CLI					; time to do it!
	JMP (ex_pt)			; DUH...


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
		BNE sig_pid			; just 0 for singletasking
#endif
	LDY b_sig			; get the signal
	CPY #SIGTERM		; clean shutdown?
	BNE sig_suic
; TERM handlers no longer end in RTI!!!
		JSR sig_term		; will call... and return here
sig_exit:
		_EXIT_OK			; standard exit, resume execution after calling handler
sig_term:
		JMP (mm_sterm)		; execute handler, will return to sig_exit
sig_suic:
	CPY #SIGKILL		; suicide?
		BEQ sig_kill
sig_pid:
	_ERR(INVALID)		; unrecognised signal


; ***********************************************
; *** B_FLAGS, get execution flags of a braid ***
; ***********************************************
;		INPUT
; Y			= addressed braid
;		OUTPUT
; Y			= flags ***TBD
; cpu_ll	= running architecture***
; C			= invalid PID
	.asc	"<B_FLAGS>"
b_flags:
#ifdef	SAFE
	TYA					; check PID
		BNE sig_pid			; only 0 accepted
#endif
	LDY #BR_RUN			; single-task systems are always running
;	STY cpu_ll			; report running architecture, which one?
	_EXIT_OK


; **************************************************************
; *** SET_HNDL, set SIGTERM handler, default is like SIGKILL ***
; **************************************************************
;		INPUT
; Y		= PID (0 means to myself)
; ex_pt = SIGTERM handler routine (ending in RTS!!!!)
;		OUTPUT
; C		= bad PID
	.asc	"<SET_HNDL>"
set_hndl:
#ifdef	SAFE
	TYA					; check PID
		BNE sig_pid			; only 0 accepted
#endif
	LDY ex_pt			; get pointer
	LDA ex_pt+1			; get pointer MSB
	STY mm_sterm		; store in single variable
	STA mm_sterm+1
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
; Y		= PID of task, 0 if myself (or single-task)
; *** if Y=$FF, switch to another available task *** new
	.asc	"<B_FORE>"
b_fore:
#ifdef	SAFE
	CPY #$FF			; asking for another?
	BEQ bf_ok			; will stay anyway as singletask!
		TYA					; check PID
		BNE sig_pid			; must be zero, complain otherwise
bf_ok:
#endif
	_EXIT_OK

; ***********************************************************
; *** B_EVENT, send signal to appropriate foreground task ***
; ***********************************************************
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
; str_pt = points to filename path (will be altered!)
;		OUTPUT
; ex_pt		= pointer to executable code
;		USES rh_scan
	.asc	"<LOADLINK>"
loadlink:
; this will ONLY work if NOHEAD option is NOT enabled!
#ifndef	NOHEAD
; *** look for that filename in ROM headers ***
; first of all, correct parameter pointer as will be aligned with header!
	LDA str_pt			; get LSB
	SEC
	SBC #8				; subtract name position in header! beware of 816 non-wrapping!
	STA str_pt			; modified value
	BCS ll_reset		; nothing else to do if no borrow
		DEC str_pt+1		; otherwise will point to previous PAGE eeeeeeek
ll_reset:
; get initial address! beacuse of the above, no longer adds filename offset!
	LDA #<ROM_BASE		; begin of ROM contents LSB, most likely zero
	STA	rh_scan			; set local pointer
	LDA #>ROM_BASE		; same for MSB
	STA rh_scan+1		; internal pointer set
ll_geth:
; ** check whether we are on a valid header!!! **
		_LDAY(rh_scan)		; first of all should be a NUL
			BNE ll_nfound		; link was lost, no more to scan
		LDY #7				; after type and size, a CR is expected
		LDA (rh_scan), Y	; get eigth byte in header!
		CMP #CR				; was it a CR?
			BNE ll_nfound		; if not, go away
; look for the name
		INY					; reset scanning index (now at name position, was @7)
ll_nloop:
			LDA (rh_scan), Y	; get character in found name
			CMP (str_pt), Y		; compare with what we are looking for
				BNE ll_nthis		; difference found
			ORA (str_pt), Y		; otherwise check whether at EOL
				BEQ ll_found		; all were zero, both ended names are the same!
			INY					; otherwise continue search
			BNE ll_nloop		; will not do forever, no need for BRA
ll_nthis:
; not this one, correct local pointer for the next header
		LDY #253			; relative offset to number of pages
		LDA (rh_scan), Y	; get it now
		TAX					; save for a while
		DEY					; relative offset to FILE SIZE eeeeek
		LDA (rh_scan), Y	; check whether crosses boundary
		BEQ ll_bound		; if it does not, do not advance page
			INX					; otherwise goes into next page
ll_bound:
		TXA					; retrieve number of pages to skip...
		SEC					; ...plus header itself! eeeeeeek
		ADC rh_scan+1		; add to previous value
		STA rh_scan+1		; update pointer
		BCC ll_geth			; inspect new header (if no overflow! 16-bit addressing)
ll_nfound:
	_ERR(N_FOUND)		; all was scanned and the query was not found
ll_found:
; this was the original loadlink code prior to 20161202, will be executed after the header was found!
	LDY #1				; offset for filetype
	LDA (rh_scan), Y	; check filetype
	CMP #'m'			; must be minimOS app!
		BNE ll_wrap			; error otherwise
	INY					; next byte is CPU type
	LDA (rh_scan), Y	; get it
; this is done instead of LDX fw_cpu
;	ADMIN(GESTALT)		; get full system info
;	LDY cpu_ll			; installed CPU *** should return it in Y!
	LDY fw_cpu			; ********************* HACK AGAIN. MUST REVISE GESTALT INTERFACE ************************
	CPY #'R'			; is it a Rockwell/WDC CPU?
		BEQ ll_rock			; from R down is OK
	CPY #'B'			; generic 65C02?
		BEQ ll_cmos			; from B down is OK
	CPY #'V'			; 65816 is supported but no better than a generic 65C02
		BEQ ll_cmos
; if none of the above, must be plain old NMOS... unless FW variables are corrupt!
#ifdef	SAFE
	CPY #'N'			; old NMOS?
		BEQ ll_nmos			; only NMOS code will do
		_PANIC("{CPU?}")	; *** should NEVER arrive here, unless firmware variables are corrupt! ***
#endif
ll_rock:
	CMP #'R'			; code has Rockwell extensions?
		BEQ ll_valid
ll_cmos:
	CMP #'B'			; generic 65C02 code?
		BEQ ll_valid
ll_nmos:
	CMP #'N'			; every supported CPU can run NMOS code
		BNE ll_wrap			; otherwise is code for another architecture!
; present CPU is able to execute supplied code
ll_valid:
	LDY rh_scan+1		; and MSB
	INY					; start from next page
	_STZA ex_pt			; *** assume all headers are page-aligned ***
	STY ex_pt+1			; save rest of execution pointer
	_EXIT_OK
ll_wrap:
	_ERR(INVALID)		; something was wrong
#else
	_ERR(UNAVAIL)		; no headers to scan
#endif

; *********************************
; *** STRING, prints a C-string ***
; *********************************
;		INPUT
; Y			= dev
; str_pt	= pointer to string
;		OUTPUT
; C = device error
;		USES BLOUT...
	.asc	"<STRING>"
string:
; not very efficient... measure string and call BOUT
	_PHY				; must keep device eeeeeeek
	LDA str_pt			; get LSB of pointer...
	STA bl_ptr			; ...as new parameter
	LDX str_pt+1		; MSB of pointer might be changed
	LDY #0				; eeeeeeeek! (2)
	STY bl_siz+1		; reset MSB of measured size
str_loop:
		LDA (str_pt), Y		; get character from string, new approach (5)
			BEQ str_term		; terminated! (3/2)
		INY					; eeeeeeeeeeeek (2)
		BNE str_loop		; still within same page
			INC str_pt+1		; otherwise increase, parameter has changed! MUST be restored later
			INC bl_siz+1		; one more page
		BNE str_loop		; continue, no need for BRA (3)
str_term:
	STX str_pt+1		; restore pointer, needed for new API/ABI
	STX bl_ptr+1		; ...and new parameter eeeeeek
	STY bl_siz			; record size LSB
	_PLY				; restore device
	_KERNEL(BLOUT)		; call usual (could be patched)
	RTS					; return whatever error code


; ******************************
; *** READLN, buffered input *** new 20161223
; ******************************
;		INPUT
; Y		= dev
; str_pt	= buffer address
; ln_siz	= max offset (byte)
;		USES rl_dev, rl_cur
	.asc	"<READLN>"
readln:
	STY rl_dev			; preset device ID!
	_STZY rl_cur		; reset variable
rl_l:
; always useful to yield CPU time, but could be patched...
		_KERNEL(B_YIELD)
		LDY rl_dev			; use device
		_KERNEL(CIN)		; get one character
		BCC rl_rcv			; got something
			CPY #EMPTY			; otherwise is just waiting?
		BEQ rl_l			; continue then
			_PHY				; otherwise, save error code...
			LDA #0
			LDY rl_cur			; current position (new)
			STA (str_pt), Y		; if any other error, terminate string... without clearing?
			_PLY				; retrieve error code
			RTS					; and return whatever error
rl_rcv:
		LDA io_c			; get received
		LDY rl_cur			; retrieve index
		CMP #CR				; hit CR?
			BEQ rl_cr			; all done then
		CMP #BS				; is it backspace?
		BNE rl_nbs			; delete then
			TYA					; otherwise check index
				BEQ rl_l			; ignore if already zero
			DEC rl_cur			; otherwise reduce index
			_BRA rl_echo		; and resume operation
rl_nbs:
		CPY ln_siz			; overflow? EEEEEEEEEEK
			BEQ rl_l			; ignore if so (was BCS)
		STA (str_pt), Y		; store into buffer
		INC	rl_cur			; update index
rl_echo:
		LDY rl_dev			; retrieve device
		_KERNEL(COUT)		; echo received character
		_BRA rl_l			; and continue
rl_cr:
; a CR is already stored at io_c
	LDY rl_dev			; retrieve device
	_KERNEL(COUT)		; print newline (ignoring errors)
	LDY rl_cur			; retrieve cursor!!!!!
	LDA #0				; no STZ indirect indexed
	STA (str_pt), Y		; terminate string
	_EXIT_OK			; and all done!


; ***********************************************************
; *** SHUTDOWN, proper shutdown, with or without poweroff ***
; ***********************************************************
;		INPUT
; Y		= subfunction code new ABI 20150603, 20160408
;		OUTPUT
; C		= couldn't poweroff or reboot (?)
;		USES b_sig (calls B_SIGNAL)
; sd_flag is a kernel variable
	.asc	"<SHUTDOWN>"
shutdown:
	CPY #PW_CLEAN		; from scheduler only!
		BEQ sd_2nd			; continue with second stage
	CPY #PW_STAT		; is it going to suspend?
		BEQ sd_fw			; do not shutdown system then!
; new, interrupt invoking
	CPY #PW_NMI		; interrupt simulation?
		BCS sd_fw			; do not shutdown, just pass to FW
	STY sd_flag			; store mode for later, first must do proper system shutdown
; ask all braids to terminate
	LDY #0				; PID=0 means ALL braids
	LDA #SIGTERM		; will be asked to terminate
	STA b_sig			; store signal type
	_KERNEL(B_SIGNAL)	; ask braids to terminate *** no longer direct call as could be patched!
	CLI					; make sure all will keep running!
	_EXIT_OK

; firmware interface
sd_fw:
	_ADMIN(POWEROFF)	; except for suspend, shouldn't return...
	RTS					; just in case was not implemented!
sd_off:
	LDY #PW_OFF			; poweroff
	BNE sd_fw			; no need for BRA
sd_cold:
	LDY #PW_COLD		; cold boot
	BNE sd_fw			; will reboot, shared code, no need for BRA

; the scheduler will wait for NO braids active
; now let's disable all drivers
sd_2nd:
	LDA sd_flag			; check what was pending
	BNE sd_shut			; something to do
		_PANIC("{sched}")	; otherwise an error!
sd_shut:
	SEI					; disable interrupts
; call each driver's shutdown routine thru DR_SHUT (12b, was 25b)
	LDY #128			; first valid device driver ID
sd_loop:
		LDA dr_ind-128, Y	; check whether this ID is in use
		BEQ sdl_skip		; no! skip this ID
			_PHY				; save just in case
			_KERNEL(DR_SHUT)	; turn this off
			_PLY				; retrieve
sdl_skip:
		INY					; next device
		BNE sd_loop			; until done!
; system cleanly shut, time to let the firmware turn-off or reboot
sd_done:
	LDX sd_flag			; retrieve mode as index!
	_JMPX(sd_tab-2)		; do as appropriate *** note offset as STAT will not be called from here

sd_tab:					; check order in abi.h
; *** no needed for suspend as will be called directly, check offset above ***
	.word	warm		; warm boot direct by kernel
	.word	sd_cold		; cold boot via firmware
	.word	sd_off		; shutdown system

; *******************************
; *** DR_INST, install driver ***
; *******************************
;		INPUT
; da_ptr	= pointer to the proposed driver header
;		OUTPUT
; Y		= actually assigned ID (if mutable)
; C		= could not install driver (ID in use or invalid, queue full, init failed)
	.asc	"<DR_INST>"
dr_inst:
; get some info from header
; dynamic drivers are currently NOT supported
#ifdef	SAFE
	LDY #D_MEM
	LDA (da_ptr), Y
	INY
	ORA (da_ptr), Y
		BNE dr_derr
#endif
; as D_ID is zero, simply indirect will do without variable (not much used anyway)
; ...but will be stored anyway for mutable option
	_LDAY(da_ptr)		; retrieve ID
#ifdef	SAFE
	BMI dr_phys			; only physical devices (3/2)
; separate function issues INVALID error
dr_derr:
		JMP dr_iabort		; reject logical devices (3)
dr_phys:
#endif

; *** before registering, check whether the driver COULD be successfully installed ***
; that means 1.the ID must not be in use eeeeeek
; 2.there must be room enough on the interrupt queues for its tasks, if provided
; 2b.in case of DYNAMIC drivers, requested memory must be succesfully allocated
; but in case of D_INIT failure, FREE must be called!
; and 3.the D_INIT routine succeeded as usual
; otherwise, skip the installing procedure altogether for that driver

; 1) first check whether this ID was not in use ***
; ****** will store ID as might change within device type if busy (already in A) ******
; ++++++ new faster driver list 20151014, revamped 20160406 ++++++
	TAX					; was Y, also in A (2)
; sparse array ready
	LDY dr_ind-128, X	; check original ID
	BEQ dr_empty		; if free, go for it (3)
#ifdef	MUTABLE
; new 171013, mutable IDs have a pointer array for easier checking
		AND #%11111000		; no, filter 8 devs each kind
		TAX
		LDY #8				; 8 devs per kind
dr_nxid:
			LDA dr_ind-128, X	; check that other ID
				BEQ dr_empty		; yes, already OK (3)
			INX					; no, try next (2)
			DEY					; one less to go (2)
			BNE dr_nxid			; until no more available (3)
; otherwise, no room for it! new ID in X
#endif
dr_busy:
; separate function issues BUSY error
		JMP dr_babort		; already in use (3)
dr_empty:
	STX dr_id			; this is the mutable new ID

; 2) check room in queues, if needed
; first get and store requested features
	LDY #D_AUTH			; let us get the provided features
	LDA (da_ptr), Y
	STA dr_aut			; a commonly used value
; check space in queues
	LDX #1				; max queue-size index
dr_chk:
		ASL					; extract MSB (will be A_POLL first, then A_REQ)
		BCC dr_ntsk			; skip verification if task not enabled
			LDY queue_mx, X		; get current tasks in queue
			CPY #MX_QUEUE		; room for another?
			BCC dr_ntsk			; yeah!
dr_nabort:
; separate function issues FULL error
				JMP dr_fabort		; or did not checked OK
dr_ntsk:
		DEX					; let us check next feature
		BNE dr_chk

; 3) if arrived here, there is room for interrupt tasks, but check init code
	JSR dr_icall		; call routine (6+...)
	BCC dr_succ			; success
; separate function issues UNAVAIL error
		JMP dr_uabort		; no way, forget about this
dr_succ:

; all checked OK, do actual driver installation!
; *** now adapted for new sparse arrays! ***
; time to look for an empty entry on sparse array
	LDX #2				; will not assing index 0 (2)
dr_ios:
		LDA drv_ads+1, X	; check MSB of entry, now on mandatory array (4)
			BEQ dr_sarr			; found a free entry (2/3)
		INX					; go for next (2+2)
		INX
		CPX #2*MX_DRVRS+2	; otherwise, is there room for more? (2) note offset
		BNE dr_ios			; yes, no need for BRA (3)
	JMP dr_fabort		; no, complain (3)
dr_sarr:
; sequential index is computed, store it into direct array
	LDY dr_id			; get direct, mutable ID eeeeeeeeeeeeeeek (3)
	TXA					; get spare entry index (2)
	STA dr_ind-128, Y	; store sparse index for that ID, alas, no STX abs,Y (4)
; proper index already in X and A

; 4) Set I/O pointers
; no longer checks I/O availability as drv_ads array is mandatory!
; thus not worth a loop, I think...
	LDY #D_BLIN			; input routine (2)
	JSR dr_gind			; get indirect address
	LDA pfa_ptr			; get driver table LSB (3)
	STA drv_ipt, X		; store in table, leaving dummy entry (4)
	LDA pfa_ptr+1		; same for MSB (3+4)
	STA drv_ipt+1, X
	LDY #D_BOUT			; offset for output routine (2)
	JSR dr_gind			; get indirect address
	LDA pfa_ptr			; get driver table LSB (3)
	STA drv_opt, X		; store in table, leaving dummy entry (4)
	LDA pfa_ptr+1		; same for MSB (3+4)
	STA drv_opt+1, X

; *** 5) register interrupt routines *** new, much cleaner approach
; time to get a pointer to the-block-of-pointers (source)
	LDY #D_POLL			; should be the FIRST of the three words (D_POLL, D_FREQ, D_ASYN)
	JSR dr_gind			; get the pointer into pfa_ptr)
; also a temporary pointer to the particular queue
	LDA #<drv_poll		; must be the first one!
	STA dq_ptr			; store temporarily
	LDA #>drv_poll		; MSB too
	STA dq_ptr+1
; new functionality 170519, pointer to (interleaved) task enabling queues
	LDA #<drv_p_en		; this is the second one, will be decremented for async
	STA dte_ptr			; yet another temporary pointer...
	LDA #>drv_p_en		; same for MSB
	STA dte_ptr+1
; all set now, now easier to use a loop
	LDX #1				; index for periodic queue (2)
; *** suspicious code ***
dr_iqloop:
		ASL dr_aut			; extract MSB (will be A_POLL first, then A_REQ)
		BCC dr_noten		; skip installation if task not enabled
; prepare another entry into queue
			LDY queue_mx, X		; get index of free entry!
			STY dq_off			; worth saving on a local variable
			INC queue_mx, X		; add another task in queue
			INC queue_mx, X		; pointer takes two bytes
; install entry into queue
			JSR dr_itask		; install into queue
; save for frequency queue, flags must be enabled for this task!
			LDA dr_id			; use ID as flags, simplifies search and bit 7 hi (as per physical device) means enabled by default eeeeeeek
; ****** might replace above by LDAY if inmutable IDs ******
			LDY dq_off			; get index of free entry!
			STA (dte_ptr), Y	; set default flags
; let us see if we are doing periodic task, in case frequency must be set also
			TXA					; doing periodic?
				BEQ dr_done			; if zero, is doing async queue, thus skip frequencies (in fact, already ended)
			JSR dr_nextq		; advance to next queue (frequencies)
			JSR dr_itask		; same for frequency queue
; *** must copy here original frequency (PLUS 256) into drv_cnt ***
			LDA (dq_ptr), Y		; get MSB
			_INC				; plus 1
			STA drv_cnt, Y		; store copy...
			STA (dq_ptr), Y		; ...and correct original value
			DEY					; go for LSB
			LDA (dq_ptr), Y		; get original...
			STA drv_cnt, Y		; ...and store unmodified
			_BRA dr_doreq		; nothing to skip, go for async queue
dr_noten:
		JSR dr_nextq		; if periodic was not enabled, this will skip frequencies queue
dr_doreq:
; as this will get into async, switch enabling queue
		LDA dte_ptr			; check previous LSB
		BNE dr_neqnw		; will wrap upon decrement?
			DEC dte_ptr+1		; if so, precorrect MSB
dr_neqnw:
		DEC dte_ptr			; one before as it is interleaved
; continue into async queue
		JSR dr_nextq		; go for next queue
		DEX					; now 0, index for async queue (2)
		BPL dr_iqloop		; eeeeek
; *** end of suspicious code ***
dr_done:
	LDY dr_id			; must return actual ID, as might be mutable!
; sparse indexes always!
	LDX dr_ind-128, Y	; now it is a proper index for sparse array! (4)
; ******I think it had to be shifted left...
	LDA da_ptr			; get header pointer (3)
	STA drv_ads, X		; store LSB, leaving dummy entry (4)
	LDA da_ptr+1		; same for MSB (3)
	STA drv_ads+1, X	; store MSB in proper entry (4)
; function will exit successfully here
	_EXIT_OK

; *****************************************
; *** some driver installation routines ***
; *****************************************
dr_icall:
	LDY #D_INIT			; original pointer offset (2)
; *** generic driver call, pointer set at da_ptr, Y holds table offset *** new 20150610, revised 20160412
; takes 10 bytes, 29 clocks *** THIS MUST GET A SEPARATE API ENTRY ***
dr_call:
	INY					; get MSB first (2)
	LDA (da_ptr), Y		; destination pointer MSB (5)
	PHA					; push it (3)
	DEY					; go for LSB (2)
	LDA (da_ptr), Y		; repeat procedure (5)
	PHA					; push LSB (3)
	PHP					; 816 is expected to be in emulation mode anyway (3)
	RTI					; actual jump (6)

; * get indirect address from driver pointer table, 13 bytes, 33 clocks *
; da_ptr pointing to header, Y has the offset in table, returns pointer in sysptr *** THIS MUST GET A SEPARATE API ENTRY ***
dr_gind:
	LDA (da_ptr), Y		; get address LSB (5)
	STA pfa_ptr			; store temporarily (3)
	INY					; same for MSB (2)
	LDA (da_ptr), Y		; get MSB (5)
	STA pfa_ptr+1		; store temporarily (3)
	RTS					; come back!!! (6)

; * routine for advancing to next queue *
; both pointers in dq_ptr (whole queue) and pfa_ptr (pointer in header)
dr_nextq:
	LDA dq_ptr			; get original queue pointer
	CLC
	ADC #MX_QUEUE		; go to next queue
	STA dq_ptr
	BCC dnq_nw			; no carry...
		INC dq_ptr+1		; ...or update MSB
dnq_nw:
	LDA pfa_ptr			; increment the origin pointer!
	CLC
	ADC #2				; next pointer in header
	STA pfa_ptr			; eeeeeeeeeeek
	BCC dnq_snw			; no carry...
		INC pfa_ptr+1		; ...or update MSB
dnq_snw:
	RTS

; * routine for copying a pointer from header into a table *
; X is 0 for async, 1 for periodic, pfa_ptr, dq_off & dq_ptr set as usual
dr_itask:
; read pointer from header
	LDY #1				; preset offset
	LDA (pfa_ptr), Y		; get MSB from header
	PHA					; stack it!
	_LDAY(pfa_ptr)		; non-indexed indirect, get LSB in A
; write pointer into queue
	LDY dq_off			; get index of free entry!
	STA (dq_ptr), Y		; store into reserved place!
	INY					; go for MSB
	PLA					; was stacked!
	STA (dq_ptr), Y
	RTS

; **********************
; *** error handling ***
; **********************
dr_iabort:
	LDY #INVALID
	BNE dr_abort			; could use BNE instead of BRA
dr_fabort:
	LDY #FULL
	BNE dr_abort
dr_babort:
	LDY #BUSY
	BNE dr_abort
dr_uabort:
	LDY #INVALID
dr_abort:
; standard error exit, no macro here
	SEC
	RTS


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
	LDA dr_ind-128, Y	; is that being used?
	BNE ds_used			; yes, proceed to remove
		_ERR(N_FOUND)		; no, nothing to remove
ds_used:
	ASL					; EEEEEEEEEEEEEEEK
	TAX
	LDA #0				; no STZ abs, Y...
	STA dr_ind-128, Y	; this is no more, any problem here?
	LDY drv_ads, X		; get full header pointer (leave dummy entry)
	LDA drv_ads+1, X
; does it need to clear that entry?
	STY da_ptr			; report from removed, will serve as ZP pointer too
	STA da_ptr+1
; make sure this entry is reported as free for future use
	_STZA drv_ads+1, X	; clear at least MSB of this entry as now mandatory (first entry is dummy)
; needs to disable interrupt tasks!
; *** perhaps using AQ_MNG and PQ_MNG???
	STY dr_id			; ID needs to be compared
	LDX #MX_QUEUE-1		; maximum index
ds_qseek:
		LDA drv_a_en, X		; get entry from whatever queue
		ORA #%10000000		; enabled or not
		CMP dr_id			; targeted ID?
		BNE ds_qnxt			; no, try next
			_STZA drv_a_en, X	; yes, clear entry
ds_qnxt:
		DEX					; another
		BPL ds_qseek		; ***works below 128 bytes
; finally, execute proper shutdown
	_CRITIC
	LDY #D_BYE			; offset to shutdown routine
	JSR dr_call			; execute shutdown procedure *** interrupts off ***
	_NO_CRIT
	_EXIT_OK			; all done


; *********************************************
; *** DR_INFO, get pointer to driver header ***
; *********************************************
;		INPUT
; Y			= requested device ID
;		OUTPUT
; ex_pt		= pointer to driver header, for any suitable Y
; def_io	= std_in@L and stdout@H devices, if Y=0!
	.asc	"<DR_INFO>"
dr_info:
	TYA					; asking for defaults
	BNE di_ndef			; no, proceed as usual
; try to resolve default global devices
		LDX std_in			; get std_in here (LSB) (/3)
		BNE di_sinz			; non-standard input (/3/2)
			LDX dflt_in			; otherwise, get system global! (//4)
di_sinz:
		LDA stdout
		BNE di_sonz			; non-standard output (/3/2)
			LDA dfltout			; otherwise get system global (//4)
di_sonz:
		STX def_io			; ...and store them as exit parameter
		STA def_io+1
		_EXIT_OK
di_ndef:
; as drv_ads is now mandatory, no need for MUTABLE option
	LDX dr_ind-128, Y	; get sparse index, is this entry free? (4)
	BEQ di_none			; yes, signal error (3)
		LDA drv_ads, X		; otherwise get MSB (note min X=1)...
		LDY drv_ads-1, X	; ...and LSB
		STY ex_pt			; store pointer as exit parameter
		STA ex_pt+1
		_EXIT_OK
di_none:
	_ERR(N_FOUND)		; no such ID


; ***************************************************************
; *** TS_INFO, get taskswitching info for multitasking driver ***
; ***************************************************************
;		OUTPUT
; Y			= number of bytes
; ex_pt		= pointer to the proposed stack frame
	.asc	"<TS_INFO>"
ts_info:
	LDX #<tsi_str		; pointer to proposed stack frame
	LDA #>tsi_str		; including MSB
	STX ex_pt			; store LSB
	STA ex_pt+1			; and MSB
	LDY #tsi_end-tsi_str; number of bytes
	_EXIT_OK

tsi_str:
; pre-created reversed stack frame for firing tasks up, regardless of multitasking driver implementation
	.word	isr_schd-1	; corrected reentry address, NEW standard label from ISR
	.byt	1			; stored X value, best if multitasking driver is the first one EEEEEEEEEEEK not zero!
;	.byt	0, 0, 0		; irrelevant Y, X, A values?
tsi_end:
; end of stack frame for easier size computation


; *********************************************************
; *** RELEASE, release ALL memory for a PID, new 20161115
; *********************************************************
;		INPUT
; Y		= PID, 0 means myself
;		USES ma_pt and whatever takes FREE (will call it)
	.asc	"<RELEASE>"
release:
	TYA					; as no CPY abs,X
	BNE rls_pid			; was it a valid PID?
		LDA run_pid			; otherwise, get mine
rls_pid:
	LDX #0				; reset index
rls_loop:
		LDY ram_stat, X		; will check stat of this block
		CPY #USED_RAM
			BNE rls_oth			; it is not in use
		CMP ram_pid, X		; check whether mine!
		BNE rls_oth			; it is not mine
			PHA					; otherwise save status
			_PHX
			LDY ram_pos, X		; get pointer to targeted block
			STY ma_pt			; will be used by FREE
			_STZA ma_pt+1
			_KERNEL(FREE)		; release it!
			_PLX				; retrieve status
			PLA
			BCC rls_next		; keep index IF current entry was deleted!
rls_oth:
		INX					; advance to next block
#ifdef	SAFE
		CPX #MAX_LIST		; all scanned?
		BNE rls_next		; no, keep looking
			_ERR(CORRUPT)		; something was really wrong...
#endif
rls_next:
		LDY ram_stat, X		; look status only
		CPY #END_RAM		; are we done?
		BNE rls_loop		; continue if not yet
	_EXIT_OK			; no errors...


; ***********************************************************
; *** SET_CURR, set internal kernel info for running task ***
; ***********************************************************
;		INPUT
; Y			= PID
; affects internal sysvar run_pid
; run_arch not supported in 8-bit mode
	.asc	"<SET_CURR>"
set_curr:
; does not check for valid PID... hopefully the multitasking driver (the only one expected to call this) does
	STY run_pid			; store PID into kernel variables (4)
	_EXIT_OK

; *******************************
; *** end of kernel functions ***
; *******************************
