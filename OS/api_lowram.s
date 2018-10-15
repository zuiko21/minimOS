; minimOS generic Kernel API for LOWRAM systems
; v0.6rc14
; (c) 2012-2018 Carlos J. Santisteban
; last modified 20181015-1102

; jump table, if not in separate 'jump' file
; *** order MUST match abi.h ***
-fw_table:				; 128-byte systems' firmware get unpatchable table from here, new 20150318
k_vec:
; FAST API option needs no jump table!
#ifndef	FAST_API
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
; other generic functions
	.word	uptime		; approximate uptime in ticks
; * no longer set_fg! *
	.word	shutdown	; proper shutdown procedure
	.word	loadlink	; get addr. once in RAM/ROM
; simplified task management
	.word	b_fork		; get available PID ***returns 0
	.word	b_exec		; launch new process ***simpler
	.word	b_signal	; send UNIX-like signal to a braid ***SIGTERM & SIGKILL only
	.word	b_flags		; get execution flags of a task ***eeeeeeeeeek***RENAMED
	.word	set_hndl	; set SIGTERM handler
	.word	b_yield		; give away CPU time for I/O-bound process ***does nothing
	.word	b_fore		; set foreground task ***new
	.word	b_event		; send signal to foreground task ***new
	.word	get_pid		; get PID of current braid ***returns 0
; new driver functionalities TBD
	.word	dr_info		; get header, is this possible?
	.word	aq_mng		; manage asynchronous task queue
	.word	pq_mng		; manage periodic task queue
; reduced driver implementation
	.word	dr_inst		; install driver
	.word	dr_shut		; shutdown driver
; *** unimplemented functions ***
#ifdef	SAFE
	.word	malloc		; reserve memory
	.word	free		; release memory
	.word	memlock		; reserve some address
	.word	release		; release ALL memory for a PID
	.word	ts_info		; get taskswitching info
	.word	set_curr	; set internal kernel info for running task
#endif
#endif
; *** dummy function, non implemented ***
unimplemented:			; placeholder here, not currently used
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
aq_mng:
pq_mng:
bl_cnfg:
bl_stat:
	_ERR(UNAVAIL)	; go away!

; *** diverse data ***
cio_mask:
	.byt	%00000001	; lr0, #128 = d0
	.byt	%00000010	; lr1, #129 = d1
	.byt	%00000100	; lr2, #130 = d2
	.byt	%00001000	; lr3, #131 = d3
	.byt	%00010000	; lr4, #132 = d4
	.byt	%00100000	; lr5, #133 = d5
	.byt	%01000000	; lr6, #134 = d6
	.byt	%10000000	; lr7, #135 = d7


; ********************************
; *** COUT, output a character ***
; ********************************
;		INPUT
; Y		= dev
; io_c	= char
;		OUTPUT
; C = I/O error
;		USES BLOUT

cout:
	LDA #io_c			; will point to parameter
	STA bl_ptr			; set pointer
	_STZA bl_ptr+1
	LDA #1				; single byte
	STA bl_siz			; set counter
	_STZA bl_siz+1
; ...and fall into BLOUT

; ***************************
; *** BLOUT, block output ***
; ***************************
;		INPUT
; Y		= dev
; bl_ptr	= pointer to block
; bl_siz	= block size
;		OUTPUT
; bl_siz	= remaining bytes
; C = I/O error
;		USES cio_of, da_ptr, iol_dev, plus whatever the driver takes

blout:
#ifdef	SAFE
	LDA bl_siz			; check size
	ORA bl_siz+1
	BNE blo_do			; not empty
		_EXIT_OK			; or nothing to do
blo_do:
#endif
	LDA #D_BOUT			; output pointer location
	STA cio_of			; store for further indexing
; in case of optimised direct jump, suppress the above and use this instead
;	STZA cio_of		; store for further indexing, only difference from blin, no longer stores D_BOUT (3)
	TYA					; check device ID (2)
	BNE co_port			; not default (3/2)
		LDY stdout			; default output device (3)
		BNE co_port			; eeeeeeeeeek
			LDY #DEVICE			; *** somewhat ugly hack ***
co_port:
	BMI cio_phys		; not a logic device (3/2)
; no need to check for windows or filesystem
; investigate rest of logical devices
		CPY #DEV_NULL		; lastly, ignore output
			BNE cio_nfound		; final error otherwise
		_STZA bl_siz		; null transfers always complete
		_STZA bl_siz+1		; null transfers always complete
		_EXIT_OK			; "/dev/null" is always OK
cio_phys:
; let us scan for the requested device, for sure Y>127, shoud be Y<136 too
	STY iol_dev			; need to save this
#ifdef	SAFE
	JSR dr_id2m			; check valid ID for mask
#endif
	LDA cio_mask-128, Y	; pattern for this device, faster this way
	AND drv_en			; compare against enabled mask
	BNE cio_dev			; device is not disabled
cio_nfound:
		_ERR(N_FOUND)		; unknown device, needed before cio_dev in case of optimized loop
cio_dev:				; old label location
;	LDY cio_of			; want input or output?
; this is suspicious...
;	LDA iol_dev			; retrieve (valid) ID, no longer in X
;	ASL					; two times (2)
;	TAX					; index for address table!
;	BNE cio_in			; not zero is input
; no support yext for optimised direct jumps...
;		JMPX(drv_opt)		; optimised direct jump, new for 0.6
;cio_in:
;	JMPX(drv_ipt)
; awful loop in the meanwhile
	LDX #0
cio_idsc:
		LDA drvrs_ad+1, X	; same for MSB
			BEQ cio_nfound2		; *never in ZP
		STA da_ptr+1
		LDA drvrs_ad, X		; take table LSB (4)
		STA da_ptr			; store pointer (3)
		LDY #D_ID
		LDA (da_ptr), Y		; *get ID of that
		CMP iol_dev			; *desired?
			BEQ cio_idok		; *yeah
		INX					; *no, go next
		INX					; *eeeeeeeeeeeeeek
		BNE cio_idsc
		BEQ cio_nfound		; ? did not found the end of the driver list, should not happen...
cio_idok:
	LDY cio_of			; want input or output?
	JMP dr_call			; re-use routine (3...)

cio_nfound2
lda#'~';list at drvrs_ad ended unexpectedly
jsr$c0c2
jmp cio_nfound
; *****************************
; *** CIN,  get a character ***
; *****************************
;		INPUT
; Y = dev
;		OUTPUT
; io_c	= char
; C		= not available
;		USES BLIN

cin:
	LDA #io_c			; will point to parameter
	STA bl_ptr			; set pointer
	_STZA bl_ptr+1
	LDA #1				; single byte
	STA bl_siz			; set counter
	_STZA bl_siz+1
	JSR blin			; proceed...
		BCS ci_exit			; ...or return error
; ** EVENT management **
	LDA io_c			; get received character
;	CMP #' '			; printable?
;	BCC ci_manage		; if not, might be an event
;ci_exitOK:
	CLC					; otherwise, no error --- eeeeeeeek!
ci_exit:
	RTS					; above comparison would set carry
; ** event management no longer here **

; *************************
; *** BLIN, block input ***
; *************************
;		INPUT
; Y		= dev
; bl_ptr	= buffer address
; bl_siz	= maximum transfer size
;		OUTPUT
; bl_siz	= remaining bytes
; C		= nothing available
;		USES iol_dev, and whatever the driver takes

blin:
#ifdef	SAFE
	LDA bl_siz		; how many?
	ORA bl_siz+1
	BEQ bli_ok		; empty perhaps? eeeeeek
		_EXIT_OK		; nothing to do
bli_ok:
#endif
	LDA #D_BLIN			; only difference from bout
	STA cio_of			; store for further addition, or just check as not zero
	TYA					; for indexed comparisons
	BNE ci_port			; specified
		LDY std_in			; default input device
		BNE ci_port			; eeeeeeeeeek
			LDY #DEVICE			; *** somewhat ugly hack ***
ci_port:
	BPL ci_nph			; logic device
		JMP cio_phys		; check physical devices, will no longer check events here
ci_nph:
; only logical devs, no need to check for windows or filesystem
	CPY #DEV_RND		; getting a random number?
		BEQ ci_rnd			; compute it!
	CPY #DEV_NULL		; lastly, ignore input
	BEQ ci_null
		JMP cio_nfound		; final error otherwise
; must behave like /dev/zero!
ci_null:
	LDX bl_ptr+1		; pointer might change
	LDA #0			; filling value
	TAY			; reset index
ci_nll:
		STA (bl_ptr), Y		; store a zero in buffer
		INY			; next
		BNE ci_ny		; no wrap
			INC bl_ptr+1		; increment MSB
ci_ny:
		DEC bl_siz		; one less
			BNE ci_nll
ci_nlw:
		CMP bl_siz+1		; check pages remaining
			BEQ ci_compl		; all done!
		DEC bl_siz+1		; or continue
		_BRA ci_nll
ci_compl:
	STX bl_ptr+1		; restore original pointer!
	_EXIT_OK			; "/dev/null" is always OK

ci_rnd:
; *** generate random number (TO DO) ***
	LDY #0
	LDX bl_ptr+1
cirn_l:
		LDA ticks			; simple placeholder
		STA (bl_ptr), Y			; eeeeeeek
		INY
		BNE cirn_nx
			INC bl_ptr+1
cirn_nx:
		DEC bl_siz
			BNE cirn_l
		LDA bl_siz+1
			BEQ ci_compl
		DEC bl_siz+1
		_BRA cirn_l


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
; *** GET_PID, get current PID ********
; *** B_FORK, reserve available PID ***
; *************************************
;		OUTPUT
; Y = PID (0 means singletask system)
ow_no_window:

get_pid:
b_fork:
	LDY #0				; no multitasking or standard device
; ********************************************************
; *** B_YIELD, yield CPU time to next braid **************
; ********************************************************
; *** CLOSE_W,  close window *****************************
; *** FREE_W, release window, will be closed by kernel ***
; ********************************************************
;		INPUT
; Y = dev

b_yield:
close_w:
free_w:
	_EXIT_OK


; ***********************************
; *** B_FORE, set foreground task ***
; ***********************************
;		INPUT
; Y		= PID of task, must be 0 as this will not multitask

b_fore:
#ifdef	SAFE
	TYA					; check PID
	BEQ bf_ok			; must be zero
		_ERR(INVALID)		; complain otherwise
bf_ok:
#endif
	_EXIT_OK


; ************************************************
; *** B_EVENT, send signal to appropriate task ***
; ************************************************
;		INPUT
; Y		= transferred char
; affects b_sig as may call B_SIGNAL

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
	BNE bn_none			; this is the last recognised event
		LDA #SIGSTOP
be_sig:
	STA b_sig			; set signal
#ifdef	SAFE
	LDY #0				; get foreground task, cannot multitask anyway!
#endif
	JMP b_signal		; exexute and return
be_none:
	_ERR(INVALID)		; usually a discarded event, may be just ignored


; **************************************
; *** UPTIME, get approximate uptime ***
; **************************************
;		OUTPUT
; up_ticks	= 32b ticks, new format
; up_sec	= 24b approximate uptime in seconds for compatibility
; takes 13b / 62t

uptime:
	LDX #3				; max offset (2)
	_CRITIC				; do not change while copying (5)
up_loop:
		LDA ticks, X		; get system variable byte (4)
		STA up_ticks, X		; and store them in output parameter (4)
		DEX					; back one byte (2)
		BPL up_loop			; (3/2)
	_NO_CRIT			; (4)
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

b_signal:
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


; ***********************************************
; *** B_FLAGS, get execution flags of a braid ***
; ***********************************************
;		INPUT
; Y = addressed braid
;		OUTPUT
; Y = flags ***TBD
; C = invalid PID

b_flags:
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

set_hndl:
#ifdef	SAFE
	TYA					; check PID
		BNE sig_pid			; only 0 accepted
#endif
	LDY ex_pt			; get pointer
	LDA ex_pt+1			; get pointer MSB
	_CRITIC
	STY mm_sterm		; store in single variable (from unused table)
	STA mm_sterm+1
	_NO_CRIT
	_EXIT_OK


; **************************************************************
; *** LOADLINK, get address once in RAM/ROM (in development) ***
; **************************************************************
;		INPUT
; str_pt	= pointer to filename path (will be altered!)
;		OUTPUT
; ex_pt		= pointer to executable code
;		USES rh_scan

loadlink:
; *** look for that filename in ROM headers ***
#ifndef	NOHEAD
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
;	LDX fw_cpu			; *** UGLY HACK, this is a FIRMWARE variable ***
	_ADMIN(GESTALT)			; get sys info, proper way
	LDX cpu_ll			; installed CPU
	CPX #'R'			; is it a Rockwell/WDC CPU?
		BEQ ll_rock			; from R down is OK
	CPX #'B'			; generic 65C02?
		BEQ ll_cmos			; from B down is OK
; does it make any sense to support the 816 on such limited systems??
;	CPX #'V'			; 65816 is supported but no better than a generic 65C02
;		BEQ ll_cmos
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
#else
	_ERR(UNAVAIL)		; no headers to scan
#endif


; *********************************
; *** STRING, prints a C-string ***
; *********************************
;		INPUT
; Y			= dev
; str_pt	= pointer to string (might be altered!)
;		OUTPUT
; C = device error
;		USES iol_dev and whatever BOUT takes

string:
	STY iol_dev			; save Y device
	LDA str_pt			; get LSB of pointer...
	STA bl_ptr			; ...as new parameter EEEEEEEEEEEEEEEK
	LDY #0				; reset new index
	STY bl_siz+1		; reset counter
	LDX str_pt+1		; get older MSB in case it changes
	STX bl_ptr+1		; ...and as new parameter eeeeeek
str_loop:
		LDA (str_pt), Y		; get character, new approach
			BEQ str_end			; NUL = end-of-string
		INY					; eeeeeeeek!
		BNE str_loop		; no wrap
			INC str_pt+1		; next page, unfortunately
			INC bl_siz+1
		BNE str_loop		; no need for BRA
str_end:
	STX str_pt+1		; restore pointer
	STY bl_siz			; complete counter
	LDY iol_dev			; retrieve device
	JMP blout			; standard block out... and return


; ******************************
; *** READLN, buffered input *** new 20161223
; ******************************
;		INPUT
; Y			= dev
; str_pt	= buffer address
; ln_siz	= max offset (byte)
;		USES rl_dev, rl_cur and whatever CIN takes

readln:
	STY rl_dev			; preset device ID!
	_STZY rl_cur		; reset variable
rl_l:
		JSR b_yield			; always useful!
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
		BEQ sd_fw			; don't shutdown system then!
	CPY #PW_HARD		; some interrupt invoked?
		BCS sd_fw			; just pass to FW
	CPY #PW_CLEAN		; from end of main task
		BEQ sd_2nd			; continue with second stage
	STY sd_flag			; store mode for later, first must do proper system shutdown, note long addressing
; ask THE braid to terminate
	LDY #0				; PID=0 means ALL braids
	LDA #SIGTERM		; will be asked to terminate
	STA b_sig			; store signal type
	JMP b_signal		; ask braids to terminate, needs to return to task until the end
; ** the real stuff starts here **
sd_2nd:
; now let's disable all drivers
	SEI					; disable interrupts
; call each driver's shutdown routine thru DR_SHUT
	LDY #135			; last valid device driver ID (lr7)
sd_loop:
		_PHY				; save just in case
		_KERNEL(DR_SHUT)	; turn this off
		_PLY				; retrieve
		DEY					; next device
		BMI sd_loop			; until done!
; ** system cleanly shut, time to let the firmware turn-off or reboot **
sd_done:
	LDX sd_flag			; retrieve mode as index!
	_JMPX(sd_tab-2)		; do as appropriate *** note offset as sd_stat will not be called from here

; firmware interface
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
; *** no needed for suspend as will be called directly, check offset above
	.word	sd_warm		; warm boot direct by kernel
	.word	sd_cold		; cold boot via firmware
	.word	sd_off		; poweroff system


; *******************************
; *** DR_INST, install driver ***
; *******************************
;		INPUT
; da_ptr	= pointer to the proposed driver header
;		OUTPUT
; Y		= assigned ID (fixed as this is NOT mutable, 128...135, lr0-lr7)
; C		= could not install driver (ID in use or invalid, queue full, init failed)

dr_inst:
; get some info from header
; as D_ID is zero, simply indirect will do without variable (not much used anyway)
#ifdef	SAFE
	LDY #D_MEM
	LDA (da_ptr), Y
	INY
	ORA (da_ptr), Y
		BNE dr_derr
	_LDAY(da_ptr)		; get ID as not stored above
	BMI dr_phys			; only physical devices (3/2)
dr_derr:
		JMP dr_iabort		; reject logical devices (3)
dr_phys:
#endif

; *** 3) before registering, check whether the driver COULD be successfully installed ***
; that means 1.the ID must not be in use eeeeeek
; 2.there must be room enough on the interrupt queues for its tasks, if provided
; and 3.the D_INIT routine succeeded as usual
; otherwise, skip the installing procedure altogether for that driver

; 3.1 is best done last...

; 3.2) check room in queues, if needed
; first get and store requested features
	LDY #D_AUTH			; let us get the provided features
	LDA (da_ptr), Y
	STA dr_aut			; a commonly used value
; check space in queues
; *** this should really use some other method, like trying to find empty entries in queues! ***
; *** might be interesting for the full featured API too ***
	_STZA dq_off		; reset free entry counters
	_STZA dq_off+1
	LDX #MX_QUEUE		; max index in queues
dr_chk:
		LDA drv_p_en, X		; get status for an entry of this queue
; zero could be a halted task at ID=128!!! Perhaps safer to make 127 the IQ_FREE value, as ID 255 might be reserved...
		CMP #IQ_FREE		; is this entry free?
		BNE dr_pfree		; no, try next
			INC dq_off			; yes, there is room in P-queue (or +1)
dr_pfree:
		LDA drv_a_en, X		; get status for an entry of this queue
; zero could be a halted task at ID=128!!! Perhaps safer to make 127 the IQ_FREE value, as ID 255 might be reserved...
		CMP #IQ_FREE		; is this entry free?
		BNE dr_afree		; no, try next
			INC dq_off+1			; yes, there is room in P-queue (or +0)
dr_afree:
		DEX					; continue scanning
		BPL dr_chk			; *** will work as long as queues are less than 128 bytes long ***
	BIT dr_aut			; check uppermost bits
	BPL dr_npoll		; b7=0 means no polling
		LDA dq_off			; free poll counter (as above)
			BEQ dr_fabort		; no room!
dr_npoll:
	BVC dr_nreq			; b6=0 means no async
		LDA dq_off+1		; free async counter (as above)
			BEQ dr_fabort		; no room!
dr_nreq:
; 3.3) if arrived here, there is room for interrupt tasks, but check init code
	JSR dr_icall		; call routine (6+...)
		BCS dr_fabort		; no way, forget about this
; 4) LOWRAM kernel has no I/O pointers in RAM...
; finally add ID to list
	_LDAY(da_ptr)		; retrieve ID eeeeeek
	TAY					; eeeeeeeeeeeek
; first convert ID into bit mask for new drv_en
#ifdef	SAFE
	JSR dr_id2m			; check ID for mask
#endif
	LDA cio_mask-128, Y	; pattern for this device, faster this way
; arrives here with ID mask in A
#ifdef	SAFE
; 3.1) check whether this ID was not in use ***
	TAX					; save mask!
	AND drv_en			; was that in use?
		BNE dr_babort		; already in use, do not register! eeeeeeeeeeeek (2/3)
	TXA					; otherwise, retrieve ID and continue
#endif
; if arrived here, succeeded, thus enable ID in bit-list
	ORA drv_en			; add bit to current
	STA drv_en			; update register

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
; must look for a free entry, and store its index in dq_off!
			LDY #MX_QUEUE-2		; last valid index
dr_iqscan:
				LDA dte_ptr, Y		; check into current queue
				CMP #IQ_FREE		; is that free?
					BEQ dr_qfree		; yes, save index
				DEY					; no, move to another entry
				DEY
				BPL dr_iqscan		; will work with queues smaller than 128 bytes
; should not arrive here...
dr_qfree:
			STY dq_off			; store index of free entry
; * code for copying a pointer from header into a table *
; no longer dr_itask routine!
; read pointer from header
			LDY #1				; preset offset
			LDA (pfa_ptr), Y	; get MSB from header
			PHA					; stack it!
			_LDAY(pfa_ptr)		; non-indexed indirect, get LSB in A
; write pointer into queue
			LDY dq_off			; get index of free entry!
			STA (dq_ptr), Y		; store into reserved place!
			INY					; go for MSB
			PLA					; was stacked!
			STA (dq_ptr), Y
; save for frequency queue, flags must be enabled for this task!
			_LDAY(da_ptr)		; use ID as flags, simplifies search and bit 7 hi (as per physical device) means enabled by default
			LDY dq_off			; get index of free entry!
			STA (dte_ptr), Y	; set default flags
; let us see if we are doing periodic task, in case frequency must be set also
			TXA					; doing periodic?
				BEQ dr_done			; if zero, is doing async queue, thus skip frequencies (in fact, already ended)
			JSR dr_nextq		; advance to next queue (frequencies)
; install into queue but cannot use routine as now 8-bit values!
			_LDAY(pfa_ptr)		; read pointer from header
			LDY dq_off			; get index of free entry!
			STA (dq_ptr), Y		; write freq into queue
; *** must copy here original frequency into drv_cnt, now single-byte ***
			STA drv_cnt, Y		; freq already in A, store unmodified
			_BRA dr_doreq		; nothing to skip, go for async queue

; **********************
; *** error handling ***
; **********************
dr_fabort:
	LDX #FULL
	BNE dr_abort

; end of the loop
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
; *** 6) continue initing drivers ***
	_LDAY(da_ptr)			; must return (fixed) ID as per API
	_EXIT_OK				; if arrived here, did not fail

; **********************
; *** error handling *** continued
; **********************
dr_babort:
	LDX #BUSY			; as further routines affect Y, but not X
	BNE dr_abort

; *****************************************
; *** some driver installation routines ***
; *****************************************
dr_icall:
	LDY #D_INIT			; original pointer offset (2)
; *** generic driver call, pointer set at da_ptr, Y holds table offset *** new 20150610, revised 20160412
; takes 10 bytes, 29 clocks
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
; da_ptr pointing to header, Y has the offset in table, returns pointer in sysptr
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

; * check whether ID in Y is in range lr0...lr7 *
dr_id2m:
; this routine will not be called unless in SAFE mode, thus extensive check becomes mandatory here
	TYA					; original device
	AND #%11111000		; check out fixed bits
	CMP #%10000000		; within range lr0-lr7?
	BEQ dr_idok			; yes, create mask
		PLA					; discard return address for this routine!
		PLA
		JMP dr_iabort		; abort with INVALID ID error
dr_idok:
; now Y is 128...135
	RTS

; **********************
; *** error handling *** continued
; **********************
dr_iabort:
	LDX #INVALID
	BNE dr_abort
dr_uabort:
	LDX #UNAVAIL

; *** if arrived here, driver initialisation failed in any way ***
; invalidate ID on list
dr_abort:
	_LDAY(da_ptr)		; get failed ID
; convert ID into mask for removing
	TAY					; where the ID is expected
	JSR dr_id2m			; convert to mask
	LDA cio_mask-128, Y	; pattern for this device, faster this way
	EOR #$FF			; invert mask
	AND drv_en			; remove failed device from current mask
	STA drv_en
; LOWRAM systems no longer keep count of installed drivers!
	TXA					; previous error code...
	TAY					; ...will be reported
	SEC					; will not use macro as error code is precomputed
	RTS

;DEBUG show A in binary
dbgbin:
phx
phy
pha
lda#'%'
jsr$c0c2
pla
pha
ldy#8
dloop:
rol
tax
lda#'0'
bcc dno
inc
dno:
jsr$c0c2
txa
dey
bne dloop
lda#10
jsr$c0c2
pla
ply
plx
rts

dbgen:
pha
lda drv_en
jsr dbgbin
pla
rts

;DEBUG show A in pseudohex
debug_hex:
pha
pha
lda#'$'
jsr$c0c2
pla
pha
lsr
lsr
lsr
lsr
clc
adc#48
jsr$c0c2
pla
and#15
clc
adc#48
jsr$c0c2
pla
rts
; *******************************
; *** DR_SHUT, disable driver *** reduced LOWRAM version
; *******************************
;		INPUT
; Y			= target ID (128...135, lr0-lr7)
;		OUTPUT
; da_ptr	= pointer to header from removed driver (if available, C otherwise)

dr_shut:
	TYA					; get ID
	ASL					; convert to index
	TAX
; convert ID (already in Y) to mask
#ifdef	SAFE
	JSR dr_id2m			; check valid ID for mask
#endif
	LDA cio_mask-128, Y	; pattern for this device, faster this way
	EOR #$FF			; negative mask
	AND drv_en			; remove device from bitmask
	STA drv_en
; now get this FIXED driver header address
	LDY drv_ads, X		; get full header pointer
	LDA drv_ads+1, X
	STY da_ptr			; report from removed, will serve as ZP pointer too
	STA da_ptr+1
; needs to disable interrupt tasks!
; *** perhaps using AQ_MNG and PQ_MNG???
; finally, execute proper shutdown
	_CRITIC
	LDY #D_BYE			; offset to shutdown routine
	JSR dr_call			; execute shutdown procedure *** interrupts off ***
	_NO_CRIT
	_EXIT_OK			; all done


; *******************************************
; *** DR_INFO, get default device drivers ***
; *******************************************
;		INPUT
; Y			= requested device ID
;		OUTPUT
; def_io	= std_in.L and stdout.H devices, if Y=0!

dr_info:
	TYA					; asking for defaults
	BNE di_ndef			; no, proceed as usual
		LDX std_in			; otherwise get BOTH devices
		LDA stdout
		STX def_io			; ...and store them as exit parameter
		STA def_io+1
		_EXIT_OK
di_ndef:
	_ERR(UNAVAIL)		; is there a way to get header address without sparse indexes?


; *******************************
; *** end of kernel functions ***
; *******************************

