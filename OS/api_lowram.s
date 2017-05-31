; minimOS generic Kernel API for LOWRAM systems
; v0.6a7
; (c) 2012-2017 Carlos J. Santisteban
; last modified 20170531-1153

; *** dummy function, non implemented ***
unimplemented:		; placeholder here, not currently used
; *** MALLOC, reserve memory ***
; *** MEMLOCK, reserve some address ***
; *** FREE, release memory ***
; *** RELEASE, release ALL memory for a PID ***
; *** TS_INFO, get taskswitching info for multitasking driver ***
; *** SET_CURR, set internal kernel info for running task ***
; not for 128-byte systems
malloc:
memlock:
free:
release:
ts_info:
set_curr:

; *** FUTURE IMPLEMENTATION ***
aqmanage:
pqmanage:

	_ERR(UNAVAIL)	; go away!

; ********************************
; *** COUT, output a character ***
; ********************************
;		INPUT
; Y		= dev
; io_c	= char
;		OUTPUT
; C = I/O error
;		USES da_ptr, iol_dev, plus whatever the driver takes

cio_of = da_ptr			; parameter switching between CIN and COUT
; da_ptr globally defined, cio_of not needed upon calling dr_call!

cout:
	LDA #D_COUT			; only difference from cin (2)
	STA cio_of			; store for further indexing (3)
	TYA					; for indexed comparisons (2)
	BNE co_port			; not default (3/2)
		LDA stdout			; default output device (3)
		BNE co_port			; eeeeeeeeeek
			LDA #DEVICE			; *** somewhat ugly hack ***
co_port:
	BMI cio_phys		; not a logic device (3/2)
; no need to check for windows or filesystem
; investigate rest of logical devices
		CMP #DEV_NULL		; lastly, ignore output
			BNE cio_nfound		; final error otherwise
		_EXIT_OK			; "/dev/null" is always OK
cio_phys:
	LDX drv_num			; number of drivers (3)
		BEQ cio_nfound		; no drivers at all! (2/3)
cio_loop:
		CMP drivers_id-1, X	; get ID from list, notice trick (4)
			BEQ cio_dev			; device found! (2/3)
		DEX					; go back one (2)
		BNE cio_loop		; repeat until end, will reach not_found otherwise (3/2)
cio_nfound:
	_ERR(N_FOUND)		; unknown device, needed before cio_dev in case of optimized loop
cio_dev:
	DEX					; needed because of backwards optimized loop (2)
	TXA					; get index in list (2)
	ASL					; two times (2)
	TAX					; index for address table!
; unified version is 15 bytes, 20 + 29 clocks
	LDY cio_of			; get offset (3)
	LDA drivers_ad, X	; take table LSB (4)
	STA da_ptr			; store pointer (3)
	LDA drivers_ad+1, X	; same for LSB (4+3)
	STA da_ptr+1		; cannot use neater way but no longer needs cio_of!
	JMP dr_call			; re-use routine (3...)

; *****************************
; *** CIN,  get a character ***
; *****************************
;		INPUT
; Y = dev
;		OUTPUT
; io_c	= char
; C		= not available
;		USES iol_dev, and whatever the driver takes
; cin_mode is a kernel variable

cin:
	LDA #D_CIN			; only difference from cout
	STA cio_of			; store for further addition
	TYA					; for indexed comparisons
	BNE ci_port			; specified
		LDA std_in			; default input device
		BNE ci_port			; eeeeeeeeeek
			LDA #DEVICE			; *** somewhat ugly hack ***
ci_port:
	BPL ci_nph			; logic device
		JSR cio_phys		; check physical devices... but come back for events! new 20150617
			BCS ci_exit			; some error, send it back
; ** EVENT management **
; this might be revised, or supressed altogether!
		LDA io_c			; get received character
		CMP #' '			; printable?
			BCC ci_manage		; if not, might be an event
ci_exitOK:
		CLC					; otherwise, no error --- eeeeeeeek!
ci_exit:
		RTS					; above comparison would set carry
; ** continue event management **
ci_manage:
; check for binary mode
	LDY cin_mode		; get flag, new sysvar 20150617
	BEQ ci_event		; should process possible event
		_STZY cin_mode		; back to normal mode
		_BRA ci_exit		; and return whatever was received
ci_event:
	CMP #16				; is it DLE?
	BNE ci_notdle		; otherwise check next
		STA cin_mode		; set binary mode! SAFER!
		BNE ci_abort		; and supress received character, no need for BRA
ci_notdle:
	CMP #3				; is it ^C? (TERM)
	BNE ci_exitOK		; otherwise there's no more to check -- only signal for single-task systems!
		LDA #SIGTERM
		STA b_sig			; set signal as parameter
#ifdef	SAFE
		LDY #0				; sent to all, this is the only one (skimming a couple of bytes!)
#endif
		JSR signal			; send signal FASTER
ci_abort:
		_ERR(EMPTY)			; no character was received

ci_nph:
; only logical devs, no need to check for windows or filesystem
	CMP #DEV_RND		; getting a random number?
		BEQ ci_rnd			; compute it!
	CMP #DEV_NULL		; lastly, ignore input
		BNE cio_nfound		; final error otherwise
	_EXIT_OK			; "/dev/null" is always OK

ci_rnd:
; *** generate random number (TO DO) ***
	LDA ticks			; simple placeholder
	STA io_c			; eeeeeeek
	_EXIT_OK


; **************************************
; *** OPEN_W, get I/O port or window ***
; **************************************
;		INPUT
; w_rect	= 16b size VV.HH
; w_rect+2	= 16b pos VV.HH
; str_pt	= 24b pointer to title string, NONE yet used
;		OUTPUT
; Y = dev
; C = not supported/not available

open_w:
	LDA w_rect			; asking for some size?
	ORA w_rect+1
	BEQ ow_no_window	; wouldn't do it
		_ERR(NO_RSRC)

; *************************************
; ***** GET_PID, get current PID ******
; *** B_FORK, reserve available PID ***
; *************************************
;		OUTPUT
; Y = PID (0 means singletask system)
; *********************************************
; *** B_YIELD, Yield CPU time to next braid ***
; *********************************************
; (no interface needed)
; ********************************************************
; *** CLOSE_W,  close window *****************************
; *** FREE_W, release window, will be closed by kernel ***
; ********************************************************
;		INPUT
; Y = dev

ow_no_window:
get_pid:
b_fork:
	LDY #0				; no multitasking, system reserved PID
yield:
close_w:
free_w:
	_EXIT_OK


; **************************************
; *** UPTIME, get approximate uptime ***
; **************************************
;		OUTPUT
; up_ticks	= 16b ticks, new standard format 20161006
; up_sec	= 32b uptime in seconds
; new version is 22b / 113t

uptime:
	LDX #7				; end of destination offset (2)
	LDY #5				; end of source pointer (2)
	_ENTER_CS			; do not change while copying (5)
up_loop:
		LDA ticks, Y		; get system variable byte (4)
		STA up_ticks, X		; and store them in output parameter (4)
		DEX					; back one byte (2)
		CPX #3				; already did seconds? (2)
		BNE up_nosec		; do not skip to ticks... (3/2)
			LDX #1				; ...until seconds are done (2)
up_nosec:
		DEY					; go for next (2)
		BPL up_loop			; (3/2)
	_EXIT_CS			; (4)
	_EXIT_OK


; *****************************************
; *** B_EXEC, launch new loaded process ***
; *****************************************
;		INPUT
; Y			= PID (0 for singletask only)
; ex_pt		= execution pointer
; def_io	= 16b default std_in (LSB) & stdout (MSB)
;
; API still subject to change... (rendez-vous mode TBD)

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
; *** SIGKILL standard handler ***
sig_kill:
; systems without memory management have nothing to free...
	LDA sd_flag			; some pending action?
	BEQ rst_shell		; if not, just restart the shell
		LDY #PW_CLEAN		; or go into second phase...
		JSR shutdown		; ...of shutdown procedure (could use JMP)
; if none of the above, a single task system can only restart the shell!
rst_shell:
	LDX #SPTR			; init stack again (in case SIGKILL was called)
	TXS
	JMP sh_exec			; back to kernel shell!

ex_jmp:
; set default SIGTERM handler! eeeeeeeeeeeeeeeeeeeeek
	LDA #>sig_kill		; get MSB
	LDY #<sig_kill		; and LSB
	STY mm_sterm		; set variable
	STA mm_sterm+1
; this is how a task should replace the shell
	LDA #ZP_AVAIL		; eeeeeeeeeeek
	STA z_used			; otherwise SAFE will not work
; and set default devices!!! eeeeeeeeeeeeeeeeeeeeeeek
; in case of LOWRAM, this will alter default global devices, is that OK?
	LDA def_io			; standard input
	STA std_in			; set at GLOBAL
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

signal:
#ifdef	SAFE
	TYA					; check correct PID, really needed?
		BNE sig_pid			; strange error?
#endif
	LDY b_sig			; get the signal
	CPY #SIGTERM		; clean shutdown?
	BNE sig_suic
		LDA #>sig_exit		; set standard return address
		PHA
		LDA #<sig_exit		; same for LSB
		PHA
		PHP					; as required by RTI
		JMP (mm_sterm)		; execute handler, will return to sig_exit
sig_suic:
	CPY #SIGKILL		; suicide?
		BEQ sig_kill
sig_pid:
	_ERR(INVALID)		; unrecognised signal


; ************************************************
; *** B_STATUS, get execution flags of a braid ***
; ************************************************
;		INPUT
; Y = addressed braid
;		OUTPUT
; Y = flags ***TBD
; C = invalid PID

status:
#ifdef	SAFE
	TYA					; check PID
		BNE sig_pid			; only 0 accepted
#endif
	LDY #BR_RUN			; single-task systems are always running
sig_exit:
	_EXIT_OK


; **************************************************************
; *** SET_HNDL, set SIGTERM handler, default is like SIGKILL ***
; **************************************************************
;		INPUT
; Y		= PID (0 means to myself)
; ex_pt = SIGTERM handler routine (ending in RTI!)
;		OUTPUT
; C = bad PID

set_handler:
#ifdef	SAFE
	TYA					; check PID
		BNE sig_pid			; only 0 accepted
#endif
	LDY ex_pt			; get pointer
	LDA ex_pt+1			; get pointer MSB
	STY mm_sterm		; store in single variable (from unused table)
	STA mm_sterm+1
	_EXIT_OK


; ***************************************************************
; *** LOAD_LINK, get address once in RAM/ROM (in development) ***
; ***************************************************************
;		INPUT
; str_pt	= pointer to filename path (will be altered!)
;		OUTPUT
; ex_pt		= pointer to executable code
;		USES rh_scan

load_link:
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
; original LOADLINK code
	LDY #1				; offset for filetype
	LDA (rh_scan), Y	; check filetype
	CMP #'m'			; must be minimOS app!
		BNE ll_wrap		; error otherwise
	INY					; next byte is CPU type
	LDA (rh_scan), Y	; get it
; check compability of supplied code against present CPU
	LDX fw_cpu			; *** UGLY HACK, this is a FIRMWARE variable ***
	CPX #'R'			; is it a Rockwell/WDC CPU?
		BEQ ll_rock			; from R down is OK
	CPX #'B'			; generic 65C02?
		BEQ ll_cmos			; from B down is OK
	CPX #'V'			; 65816 is supported but no better than a generic 65C02
		BEQ ll_cmos
	CPX #'N'			; old NMOS?
	BEQ ll_nmos			; only NMOS code will do
		_PANIC("{CPU?}")	; *** should NEVER arrive here, unless firmware variables are corrupt! ***
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
	LDA rh_scan			; get pointer LSB
	LDY rh_scan+1		; and MSB
	INY					; start from next page
	STA ex_pt			; save execution pointer
	STY ex_pt+1
	_EXIT_OK
ll_wrap:
	_ERR(INVALID)		; something was wrong


; *********************************
; *** STRING, prints a C-string ***
; *********************************
;		INPUT
; Y			= dev
; str_pt	= 24b pointer to string (might be altered!) 24-bit ready!
;		OUTPUT
; C = device error
;		USES iol_dev and whatever COUT takes

string:
	STY iol_dev			; save Y
	LDY #0				; reset new index
	LDA str_pt+1		; get older MSB in case it changes
	PHA					; save it somewhere!
str_loop:
		LDA (str_pt), Y		; get character, new approach
			BEQ str_end			; NUL = end-of-string
		STA io_c			; store output character for COUT
		_PHY				; save current index
		LDY iol_dev			; retrieve device number
		_KERNEL(COUT)		; call routine
#ifdef	SAFE
		BCC str_nerr		; extra check
			PLA					; cleanup stack
			_BRA str_exit		; return error code (and restore pointer)
str_nerr:
#endif
		_PLY				; retrieve index
		INY					; eeeeeeeek!
		BNE str_loop		; repeat, will later check for termination
	INC str_pt+1		; next page, unfortunately
	BNE str_loop		; no need for BRA
str_end:
	CLC					; no errors
str_exit:
	PLA					; get MSB back
	STA str_pt+1		; restore it
	RTS					; return error code


; ******************************
; *** READLN, buffered input *** new 20161223
; ******************************
;		INPUT
; Y			= dev
; str_pt	= buffer address
; ln_siz	= max offset (byte)
;		USES rl_dev, rl_cur and whatever CIN takes

readLN:
	STY rl_dev			; preset device ID!
	_STZY rl_cur		; reset variable
rl_l:
		JSR yield			; always useful!
		LDY rl_dev			; use device
		JSR cin				; get one character
		BCC rl_rcv			; got something
			CPY #EMPTY			; otherwise is just waiting?
		BEQ rl_l			; continue then
			LDA #0
			_STAX(str_pt)		; if any other error, terminate string
			RTS					; and return whatever error
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
			_BRA rl_echo		; and resume operation
rl_nbs:
		CPY ln_siz			; overflow? EEEEEEEEEEK
			BCS rl_l			; ignore if so
		STA (str_pt), Y		; store into buffer
		INC	rl_cur			; update index
rl_echo:
		LDY rl_dev			; retrieve device
		JSR cout			; echo received character
		_BRA rl_l			; and continue
rl_cr:
	LDA #CR				; newline
	LDY rl_dev			; retrieve device
	JSR cout			; print newline (ignoring errors)
	LDY rl_cur			; retrieve cursor!!!!!
	LDA #0				; no STZ indirect indexed
	STA (str_pt), Y		; terminate string
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
; *******TO BE REVISED*********
set_fg:
	LDA zpar
	ORA zpar+1
		BEQ fg_dis		; if zero, disable output
	LDA VIA+ACR		; get current configuration
		BMI fg_busy	; already in use
	LDX VIA+T1LL	; get older T1 latch values
	STX old_t1		; save them
	LDX VIA+T1LH
	STX old_t1+1
; *** TO_DO - should compare old and new values in order to adjust quantum size accordingly ***
	LDX zpar			; get new division factor
	STX VIA+T1LL	; store it
	LDX zpar+1
	STX VIA+T1LH
	STX VIA+T1CH	; get it running!
	ORA #$C0		; enable free-run PB7 output
	STA VIA+ACR		; update config
fg_none:
	_EXIT_OK		; finish anyway
fg_dis:
	LDA VIA+ACR		; get current configuration
		BPL fg_none	; it wasn't playing!
	AND #$7F		; disable PB7 only
	STA VIA+ACR		; update config
	LDA old_t1		; older T1L_L
	STA VIA+T1LL	; restore old value
	LDA old_t1+1
	STA VIA+T1LH	; it's supposed to be running already
; *** TO_DO - restore standard quantum ***
		_BRA fg_none
fg_busy:
	_ERR(BUSY)		; couldn't set


; ***********************************************************
; *** SHUTDOWN, proper shutdown, with or without poweroff ***
; ***********************************************************
;		INPUT
; Y = subfunction code
;		OUTPUT
; C = not implemented?
;		USES b_sig (calls B_SIGNAL)
; sd_flag is a kernel variable

shutdown:
	CPY #PW_STAT		; is it going to suspend?
		BEQ sd_stat			; don't shutdown system then!
	CPY #PW_CLEAN		; from end of main task
		BEQ sd_2nd			; continue with second stage
	STY sd_flag			; store mode for later, first must do proper system shutdown, note long addressing
; ask THE braid to terminate
	LDY #0				; PID=0 means ALL braids
	LDA #SIGTERM		; will be asked to terminate
	STA b_sig			; store signal type
	JMP signal			; ask braids to terminate, needs to return to task until the end
; ** the real stuff starts here **
sd_2nd:
; now let's disable all drivers
	SEI					; disable interrupts
; call each driver's shutdown routine
	LDA drv_num			; get number of installed drivers
	ASL					; twice the value as a pointer
	TAX					; use as index
; first get the pointer to each driver table
sd_loop:
; get address index
		DEX					; go back one address
		DEX
		LDA drivers_ad+1, X	; get address MSB (4)
		BEQ sd_done			; not in zeropage
		STA da_ptr+1		; store pointer (3)
		LDA drivers_ad, X	; same for LSB (4+3)
		STA da_ptr
		_PHX				; save index for later
		LDY #D_BYE			; offset for shutdown routine --- eeeeeek!
		JSR dr_call			; call routine from generic code!
		_PLX				; retrieve index
		BNE sd_loop			; repeat until zero
; ** system cleanly shut, time to let the firmware turn-off or reboot **
sd_done:
	LDX sd_flag			; retrieve mode as index!
	_JMPX(sd_tab-2)		; do as appropriate *** note offset as sd_stat will not be called from here

; firmware interface
sd_stat:
	LDY #PW_STAT		; suspend
sd_fw:
	_ADMIN(POWEROFF)	; except for suspend, shouldn't return...
	RTS					; for suspend or not implemented
sd_off:
	LDY #PW_OFF			; poweroff
	BNE sd_fw			; no need for BRA
sd_cold:
	LDY #PW_COLD		; cold boot
	BNE sd_fw			; will reboot, shared code, no need for BRA
sd_warm:
	JMP warm			; firmware no longer should take pointer, generic kernel knows anyway

sd_tab:
;	.word	sd_stat		; suspend *** no needed as will be called directly, check offset above
	.word	sd_warm		; warm boot direct by kernel
	.word	sd_cold		; cold boot via firmware
	.word	sd_off		; poweroff system

; *******************************
; *** end of kernel functions ***
; *******************************

; jump table, if not in separate 'jump' file
; *** order MUST match abi.h ***
-fw_table:				; 128-byte systems' firmware get unpatchable table from here, new 20150318
k_vec:
; basic I/O
	.word	cout		; output a character
	.word	cin			; get a character
	.word	string		; prints a C-string
	.word	readLN		; buffered input
; simple windowing system (placeholders)
	.word	open_w		; get I/O port or window
	.word	close_w		; close window
	.word	free_w		; will be closed by kernel
; other generic functions
	.word	uptime		; approximate uptime in ticks
	.word	set_fg		; enable frequency generator (VIA T1@PB7)
	.word	shutdown	; proper shutdown procedure
	.word	load_link	; get addr. once in RAM/ROM
; simplified task management
	.word	b_fork		; get available PID ***returns 0
	.word	b_exec		; launch new process ***simpler
	.word	signal		; send UNIX-like signal to a braid ***SIGTERM & SIGKILL only
	.word	status		; get execution flags of a task ***eeeeeeeeeek
	.word	get_pid		; get PID of current braid ***returns 0
	.word	set_handler	; set SIGTERM handler
	.word	yield		; give away CPU time for I/O-bound process ***does nothing
; new functionalities TBD
	.word	aqmanage	; manage asynchronous task queue
	.word	pqmanage	; manage periodic task queue
; *** unimplemented functions ***
#ifdef	SAFE
	.word	malloc		; reserve memory
	.word	memlock		; reserve some address
	.word	free		; release memory
	.word	release		; release ALL memory for a PID
	.word	ts_info		; get taskswitching info
	.word	set_curr	; set internal kernel info for running task
#endif
