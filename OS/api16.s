; minimOS·16 generic Kernel API!
; v0.5.1a8, should match kernel16.s
; (c) 2016 Carlos J. Santisteban
; last modified 20161109-1103

; no way for standalone assembly...

; *** dummy function, non implemented ***
unimplemented:			; placeholder here, not currently used
	.as: .xs: SEP #$30	; *** standard register size ***
	_ERR(UNAVAIL)		; go away!


; *** COUT, output a character ***
; Y <- dev, io_c <- char

cout:
	.as: .xs: SEP #$30	; *** standard register size ***
	TYA					; for indexed comparisons (2)
	BNE co_port			; not default (3/2)
		LDA stdout			; new per-process standard device ### apply this to ·65
		BNE co_port			; already a valid device
			LDA default_out		; otherwise get system global (4)
co_port:
	BMI co_phys			; not a logic device (3/2)
		CMP #64				; first file-dev??? ***
			BCC co_win			; below that, should be window manager
; ** optional filesystem access **
#ifdef	FILESYSTEM
		CMP #64+MAX_FILES	; still within file-devs?
			BCS co_log			; that value or over, not a file
; *** manage here output to open file ***
		_ERR(NO_RSRC)		; not yet implemented ***placeholder***
#endif
; ** end of filesystem access **
co_log:
; investigate rest of logical devices
		CMP #DEV_NULL		; lastly, ignore output
			BNE cio_nfound		; final error otherwise
		_EXIT_OK			; "/dev/null" is always OK
co_win:
; *** virtual windows manager TO DO ***
	_ERR(NO_RSRC)		; not yet implemented
co_phys:
; ** new direct indexing **
	ASL					; convert to index (2+2)
	TAX
	JSR (drv_opt, X)	; direct CALL!!! driver should end in RTS as usual via the new DR_ macros
; ** important routine ending in order to preserve C status after thr RTI **
cio_callend:
	PLA					; extract previous status!
	BCC cio_notc		; no need to clear carry
		ORA #1				; otherwise set it
cio_notc:
	PHA					; replace stored flags
	RTI					; end of call procedure
cio_nfound:
	_ERR(N_FOUND)		; unknown device


; *** CIN, get a character ***
; Y <- dev, io_c -> char, C = not available

cin:
	.as: .xs: SEP #$30	; *** standard register size ***
	TYA					; for indexed comparisons
	BNE ci_port			; specified
		LDA std_in			; new per-process standard device ### apply this to ·65
		BNE ci_port			; already a valid device
			LDA default_in		; otherwise get system global
ci_port:
	BPL ci_nph			; logic device
; ** new direct indexing **
		ASL					; convert to index (2+2)
		TAX
		JSR (drv_ipt, X)	; direct CALL!!!
			BCS cio_callend		; if some error, send it back
; ** EVENT management **
; this might be revised, or supressed altogether!
		LDA io_c			; get received character
		CMP #' '			; printable?
			BCC ci_manage		; if not, might be an event
		_EXIT_OK			; generic macro, older trick NLA

; ** continue event management ** REVISE
ci_manage:
; check for binary mode
	LDY cin_mode		; get flag
	BEQ ci_event		; should process possible event
		STZ cin_mode		; back to normal mode
		_EXIT_OK			; and return whatever was received
ci_event:
	CMP #16				; is it DLE?
	BNE ci_notdle		; otherwise check next
		INC cin_mode		; set binary mode!
		BNE ci_abort		; and supress received character, no need for BRA
ci_notdle:
	CMP #3				; is it ^C? (TERM)
	BNE ci_noterm		; otherwise check next
		LDA #SIGTERM
		BNE ci_signal		; send signal, no need for BRA?
ci_noterm:
	CMP #4				; is it ^D? (KILL) somewhat dangerous...
	BNE ci_nokill		; otherwise check next
		LDA #SIGKILL
		BNE ci_signal		; send signal, no need for BRA?
ci_nokill:
	CMP #26				; is it ^Z? (STOP)
	BEQ ci_stop			; last signal to be sent
		_EXIT_OK			; otherwise all done
ci_stop:
	LDA #SIGSTOP		; last signal to be sent
ci_signal:
	STA b_sig			; set signal as parameter
	_KERNEL(GET_PID)	; as this will be a self-sent signal!
	_KERNEL(B_SIGNAL)	; send signal to PID in Y
ci_abort:
	_ERR(EMPTY)			; no character was received

ci_nph:
	CMP #64				; first file-dev??? ***
		BCC ci_win			; below that, should be window manager
; ** optional filesystem access **
#ifdef	FILESYSTEM
	CMP #64+MAX_FILES	; still within file-devs?
		BCS ci_log			; that or over, not a file
; *** manage here input from open file ***
	_ERR(NO_RSRC)		; not yet implemented ***placeholder***
#endif
; ** end of filesystem access **

ci_log:
	CMP #DEV_RND		; getting a random number?
		BEQ ci_rnd			; compute it!
	CMP #DEV_NULL		; lastly, ignore input
		BNE cio_nfound		; final error otherwise
	_EXIT_OK			; "/dev/null" is always OK

ci_rnd:
; *** generate random number (TO DO) ***
	LDY ticks			; simple placeholder
	_EXIT_OK

ci_win:
; *** virtual window manager TO DO ***
	_ERR(NO_RSRC)		; not yet implemented


; *** MALLOC, reserve memory *** revamped 20161103
; ma_rs <- size, ma_pt -> addr, C = not enough memory
; ma_align <- mask for MSB (0=page or not aligned, 1=512b, $FF=bank aligned) new 161105 TO DO
; ma_rs = 0 means reserve as much memory as available!!!
; ram_stat & ram_pid are interleaved (=ram_stat+1) in minimOS-16, but separate otherwise!
; * this works on 24-bit addressing! *
; uses ma_l as diverse temporary vars, as defined below

ma_siz	= ma_l
ma_ix	= ma_l+2

malloc:
	.al: REP #$20		; *** 16-bit memory ***
	.xs: SEP #$10		; *** 8-bit indexes ***
	LDX #0				; reset index
	STX ma_align+1		; **clear MSB in cass of a 16-bit BIT!**
	LDY ma_rs			; check individual bytes, just in case
	BEQ ma_nxpg			; no extra page needed
		INC ma_rs+1			; otherwise increase number of pages
		STX ma_rs				; ...and just in case, clear asked bytes!
ma_nxpg:
; default 816 API functions run on interrupts masked, thus no need for CS
	LDA ma_rs+1			; get number of asked pages
	BNE ma_scan			; work on specific size
; otherwise check for biggest available block -- new ram_stat word format 161105
		STZ ma_siz		; ...and found value eeeeeeeeek
ma_biggest:
			LDY ram_stat, X		; get status of block (4)
;			CPY #FREE_RAM		; not needed if FREE_RAM is zero! (2)
			BNE ma_nxbig		; go for next as this one was not free (3/2)
				JSR ma_alsiz		; **compute size according to alignment mask**
				CMP ma_siz			; compare against current maximum (4)
				BCC ma_nxbig		; this was not bigger (3/2)
					STA ma_siz			; otherwise keep track of it... (4)
					STX ma_ix			; ...and its index! (3)
ma_nxbig:
			INX					; advance index (2+2)
			INX
			LDY ram_stat, X		; peek next status (4)
			CPY #END_RAM		; check whether at end (2)
			BNE ma_biggest		; or continue (3/2)
; is there at least one available block?
		LDA ma_siz			; should not be zero
		BNE ma_fill			; there is at least one block to allocate
			_ERR(FULL)		; otherwise no free memory!
; report allocated size
ma_fill:
		STA ma_rs+1			; store allocated size! already computed
		LDX ma_ix			; retrieve index
		BRA ma_updt			; nothing to scan, just update status and return address
ma_scan:
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
	_ERR(FULL)			; no room for it!
ma_found:
	JSR ma_alsiz		; **compute size according to alignment mask**
#ifdef	SAFE
	BMI ma_nobad		; no corruption was seen (3/2) **instead of BCS**
		LDA #user_sram	; otherwise take beginning of user RAM...
		LDX #USED_RAM	; ...that will become locked (maybe another value)
		STA ram_pos		; create values
		STX ram_stat		; **should it clear the PID field too???**
		LDA #SRAM		; physical top of RAM...
		LDX #END_RAM		; ...as non-plus-ultra
		STA ram_pos+2		; create second set of values
		STX ram_stat+2
		_ERR(CORRUPT)	; report but do not turn system down
ma_nobad:
#endif
	CMP ma_rs+1			; compare (5)
		BCC ma_cont			; smaller, thus continue searching (2/3)
; here we go!
; **first of all create empty block for alignment, if needed**
	PHA					; save current size
	LDA ram_pos, X		; check current address
	AND ma_align		; any misaligned bits set?
	BEQ ma_aok			; already aligned, nothing needed
		JSR ma_adv			; advance and let repeated first entry!
		INX					; let the algnment blank and go for next
		INX
		LDA ram_pos, X		; get repeated address
		ORA ma_align		; set disturbing bits...
		INC					; ...and reset them after increasing the rest
		STA ram_pos, X		; update pointer
ma_aok:
	PLA					; retrieve size
; make room for new entry... if not exactly the same size
	CMP ma_rs			; compare this block with requested size
	BEQ ma_updt			; was same size, will not generate new entry
		JSR ma_adv			; make room otherwise
ma_updt:
	STZ ma_pt			; clear pointer LSB... plus extra byte
	LDA ram_pos, X		; get address of block to be assigned
	STA ma_pt+1			; note this is address of PAGE
	LDA #USED_RAM		; now is reserved
	STA ram_stat, X		; update table entry, will destroy PID temporarily but no STY abs,X!!!
; ** new 20161106, store PID of caller **
	PHX					; will need this index
	_KERNEL(GET_PID)	; who asked for this?
	PLX					; retrieve index
	.as: SEP #$30		; *** back to 8-bit because interleaved array! ***
	TYA					; get into A as no STY abs,X!!!
	STA ram_pid, X		; store PID, interleaved array will apply some offset
; theoretically we are done, end of CS
	_EXIT_OK

	.al					; as routines will be called in 16-bit memory!!!

; routine for aligned-block size computation
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
; *** non-aligned version ***
;	LDA ram_pos+2, X	; get end position (5)
;	SEC
;	SBC ram_pos, X		; subtract current for size! (2+5)
; *** end of non-aligned version ***

; routine for making room for an entry
ma_adv:
	STX ma_ix			; store current index
ma_2end:
		INX					; previous was free, thus check next
		INX
		CPX #MAX_LIST-1		; just in case, check offset!!!
		BCC ma_notend		; could expand
			PLA					; discard return address (still in 16-bit mode)
			JMP ma_nobank		; notice error
ma_notend:
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
; create at the beginning of the moved block a FREE entry!
	LDA ram_pos+2, X	; newly assigned slice will begin here
	CLC
	ADC ma_rs+1			; add number of assigned pages
	STA ram_pos+2, X	; update value
	LDA #FREE_RAM		; let us mark it as free, PID is irrelevant!
	STA ram_stat+2, X	; next to the assigned one, no STY abs,X!!!
	RTS


; *** FREE, release memory *** revamped 20161104 & 05
; ma_pt <- addr
; C -> no such used block!

free:
	.al: REP #$20		; *** 16-bit memory ***
	.xs: SEP #$10		; *** 8-bit indexes ***
	LDX #0				; reset index
	LDA ma_pt			; get comparison term
fr_loop:
		CMP ram_pos, X		; is what we are looking for?
			BEQ fr_found		; go free it!
		LDY ram_stat, X		; otherwise check status
		INX					; advance index
		INX
		CPY #END_RAM		; no more in list?
		BNE fr_loop			; continue until end
; this could be one end of CS
fr_no:
	_ERR(N_FOUND)		; no such block!
fr_found:
#ifdef	SAFE
	LDY ram_stat, X		; only used blocks can be freed!
	CPY #USED_RAM		; was it in use?
		BNE fr_no			; if not, cannot free it!
#endif
	LDA #FREE_RAM		; most likely zero, could I use STZ in 16-bit mode??? irrelevant PID
	STA ram_stat, X		; no STY abs,Y... this block is now free, but...
; really should join possible adjacent free blocks
	LDY ram_stat+2, X	; check status of following entry
;	CPY #FREE_RAM		; was it free? could be supressed if value is zero
	BNE fr_ok			; was not free, thus nothing to optimize
; loop for obliterating the following empty entry
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
; we are done
fr_ok:
	_EXIT_OK


; *** OPEN_W, get I/O port or window ***
; Y -> dev, w_rect <- size+pos*64K, str_pt <- pointer to window title!

open_w:
	.al: REP #$20		; *** 16-bit memory size ***
	.xs: SEP #$10		; *** 8-bit register, just in case ***
	LDA w_rect			; asking for some size? includes BOTH bytes
	BEQ ow_no_window	; wouldn't do it
		_ERR(NO_RSRC)
ow_no_window:
	LDY #DEVICE			; constant default device, REVISE
;	EXIT_OK on subsequent system calls!

; *** CLOSE_W, close window ***
; *** FREE_W, release window, will be closed by kernel ***
; Y <- dev
close_w:				; doesn't do much
free_w:					; doesn't do much, either
	_EXIT_OK


; *** UPTIME, get approximate uptime ***
; up_ticks -> ticks, new standard format 20161006
; up_sec -> 32-bit uptime in seconds

uptime:
	.al: REP #$20		; *** optimum 16-bit memory ***
; default 816 API functions run on interrupts masked, thus no need for CS
		LDA ticks		; get system variable word (5)
		STA up_ticks	; and store them in output parameter (4)
		LDA ticks+2		; get system variable uptime (5)
		STA up_sec		; and store it in output parameter (4)
		LDA ticks+4		; another word, as per new format (5)
		STA up_sec+2	; store that (4)
; end of CS
	_EXIT_OK


; *** LOAD_LINK, get address once in RAM/ROM (kludge!) *** TO_DO
; ex_pt -> addr, str_pt <- *path, cpu_ll -> architecture
; *** only 64K RAM supported so far ***

load_link:
; *** assume *path points to header, code begins +256 *** STILL A KLUDGE
	.as: .xs: SEP #$30	; *** standard register size ***
	LDY #1				; offset for filetype
	LDA (str_pt), Y		; check filetype
	CMP #'m'			; must be minimOS app!
		BNE ll_wrap			; error otherwise
	INY					; next byte is CPU type then
	LDA (str_pt), Y		; get it
	CMP #'R'			; Rockwell is the only unsupported type!
		BEQ ll_wrap
	STA cpu_ll			; set CPU type
	LDA str_pt			; get pointer LSB
	LDY str_pt+1		; and MSB, not worth on 16-bit mode because of page increment
	INY					; start from next page
	STA ex_pt			; save execution pointer
	STY ex_pt+1
	STZ ex_pt+2			; invalidate bank... this far, this is important for 6502 code with new B_EXEC approach
	_EXIT_OK
ll_wrap:
	_ERR(INVALID)		; something was wrong


; *** SU_POKE, write to protected addresses ***
; might be deprecated, not sure if of any use in other architectures
; Y <- value, zpar <- addr
; destroys A (and maybe Y on NMOS)

su_poke:
	.as: .xs: SEP #$30	; *** standard register size ***
	TYA					; transfer value
	STA (zpar)			; store value
	_EXIT_OK


; *** SU_PEEK, read from protected addresses ***
; might be deprecated, not sure if of any use in other architectures
; Y -> value, zpar <- addr
; destroys A

su_peek:
	.as: .xs: SEP #$30	; *** standard register size ***
	LDA (zpar)			; store value
	TAY					; transfer value
	_EXIT_OK


; *** STRING, prints a C-string *** optimized loop 20161004, should port to ·65
; Y <- dev, str_pt <- *string (.w in current version)
; uses str_dev
; calls cout, but now directly at driver code ***

string:
; ** actual code from COUT here, might save space using a common routine, but adds a bit of overhead
	.as: .xs: SEP #$30	; *** standard register size ***
	TYA					; for indexed comparisons (2)
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
		_ERR(NO_RSRC)		; not yet implemented ***placeholder***
#endif
; ** end of filesystem access **
str_log:
; investigate rest of logical devices
		CMP #DEV_NULL		; lastly, ignore output
			BNE str_nfound		; final error otherwise
str_exit:
		_EXIT_OK			; "/dev/null" is always OK
str_win:
; *** virtual windows manager TO DO ***
	_ERR(NO_RSRC)		; not yet implemented
str_nfound:
	_ERR(N_FOUND)		; unknown device
str_phys:
; ** new direct indexing, revamped 20160407 **
	ASL					; convert to index (2+2)
	STA str_dev			; store for indexed call! (3)
	LDY #0				; eeeeeeeek! (2)
; ** the actual printing loop **
str_loop:
		PHY					; save just in case COUT destroys it (3)
		LDA (str_pt), Y		; get character from string, new approach (5)
			BEQ str_exit		; exit when terminated! (2/3)
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
	PLA					; discard saved Y while keeping error code eeeeeeeeeek^2
	JMP cio_callend		; otherwise return code eeeeeeeeeek^2


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


; *** SET_FG, enable/disable frequency generator (Phi2/n) on VIA ***
; ** should use some firmware interface, just in case it doesn't affect jiffy-IRQ! **
; should also be Phi2-rate independent... input as Hz, or 100uS steps?
; zpar.W <- dividing factor (times two?), C -> busy
; destroys A, X...

; *******TO BE REVISED*********
set_fg:
	LDA zpar
	ORA zpar+1
		BEQ fg_dis			; if zero, disable output
	LDA VIA+ACR			; get current configuration
		BMI fg_busy			; already in use
	LDX VIA+T1LL		; get older T1 latch values
	STX old_t1			; save them
	LDX VIA+T1LH
	STX old_t1+1
; *** TO_DO - should compare old and new values in order to adjust quantum size accordingly ***
	LDX zpar			; get new division factor
	STX VIA+T1LL		; store it
	LDX zpar+1
	STX VIA+T1LH
	STX VIA+T1CH		; get it running!
	ORA #$C0			; enable free-run PB7 output
	STA VIA+ACR			; update config
fg_none:
	_EXIT_OK			; finish anyway
fg_dis:
	LDA VIA+ACR			; get current configuration
		BPL fg_none			; it wasn't playing!
	AND #$7F			; disable PB7 only
	STA VIA+ACR			; update config
	LDA old_t1			; older T1L_L
	STA VIA+T1LL		; restore old value
	LDA old_t1+1
	STA VIA+T1LH		; it's supposed to be running already
; *** TO_DO - restore standard quantum ***
		BRA fg_none
fg_busy:
	_ERR(BUSY)			; couldn't set


; *** GO_SHELL, launch default shell *** REVISE
; no interface needed
go_shell:
	JMP shell			; simply... *** SHOULD initialise SP and other things anyway ***


; *** SHUTDOWN, proper shutdown, with or without poweroff ***
; Y <- subfunction code
; C -> couldn't poweroff or reboot (?)

shutdown:
	.as: .xs: SEP #$30	; *** standard register size ***
	CPY #PW_CLEAN		; from scheduler only!
		BEQ sd_2nd			; continue with second stage
	CPY #PW_STAT		; is it going to suspend?
		BEQ sd_stat			; don't shutdown system then!
	STY sd_flag			; store mode for later, first must do proper system shutdown
; ask all braids to terminate
	LDY #0				; PID=0 means ALL braids
	LDA #SIGTERM		; will be asked to terminate
	STA b_sig			; store signal type
	_KERNEL(B_SIGNAL)	; ask braids to terminate
	PLP					; original mask is buried in stack
	CLI					; make sure all will keep running!
	PHP					; restore for subsequent RTI
	_EXIT_OK			; actually RTI for 816

; firmware interface
sd_off:
	LDY #PW_OFF			; poweroff
sd_fw:
	_ADMIN(POWEROFF)	; except for suspend, shouldn't return...
	JMP cio_callend			; just in case was not implemented!
sd_stat:
	LDY #PW_STAT		; suspend
	BNE sd_fw			; no need for BRA
sd_cold:
	LDY #PW_COLD		; cold boot
	BNE sd_fw			; will reboot, shared code, no need for BRA
sd_warm:
	SEP #9				; disable interrupts and set carry...
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
	.al: REP #$20		; *** 16-bit memory ***
; first get the pointer to each driver table
sd_loop:
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

sd_tab:					; check order in abi.h!
	.word	sd_stat		; suspend
	.word	sd_warm		; warm boot direct by kernel
	.word	sd_cold		; cold boot via firmware
	.word	sd_off		; poweroff system


; *** B_FORK, reserve available PID ***
; Y -> PID

b_fork:
	.as: .xs: SEP #$30	; *** standard register size ***
	LDX #MM_FORK		; subfunction code
	BRA yld_call		; go for the driver


; *** B_EXEC, launch new loaded process ***
; API still subject to change... (default I/O, rendez-vous mode TBD)
; Y <- PID, ex_pt <- addr (was z2L), cpu_ll <- architecture, def_io <- std_in & stdout
b_exec:
	.as: .xs: SEP #$30	; *** standard register size ***
	LDX #MM_EXEC		; subfunction code
	BRA yld_call		; go for the driver


; *** B_SIGNAL, send UNIX-like signal to a braid ***
; b_sig <- signal to be sent , Y <- addressed braid
; don't know of possible errors

signal:
	.as: .xs: SEP #$30	; *** standard register size ***
	LDX #MM_SIGNAL		; subfunction code
	BRA yld_call		; go for the driver


; *** B_STATUS, get execution flags of a braid ***
; Y <- addressed braid
; Y -> flags, TBD
; don't know of possible errors, maybe just a bad PID

status:
	.as: .xs: SEP #$30	; *** standard register size ***
	LDX #MM_STATUS		; subfunction code
	BRA yld_call		; go for the driver


; *** GET_PID, get current braid PID ***
; Y -> PID, TBD

get_pid:
	.as: .xs: SEP #$30	; *** standard register size ***
	LDX #MM_PID		; subfunction code
	BRA yld_call	; go for the driver


; *** SET_HNDL, set SIGTERM handler, default is like SIGKILL ***
; Y <- PID, ex_pt <- SIGTERM handler routine (ending in RTI)
; ** so far only bank 0 routines supported **
; uses locals[0] too
; bad PID is probably the only feasible error

set_handler:
	.as: .xs: SEP #$30	; *** standard register size ***
	LDX #MM_HANDL		; subfunction code
	BRA yld_call		; go for the driver


; *** B_YIELD, Yield CPU time to next braid *** REVISE
; supposedly no interface needed, don't think I need to tell if ignored

yield:
	.as: .xs: SEP #$30	; *** standard register size ***
	LDX #MM_YIELD		; subfunction code
; * unified calling procedure, get subfunction code in X * new faster interface 20161102
yld_call:
; new code is 6 bytes, 10 clocks! old code was 8 bytes, 13 clocks
	PEA cio_callend-1	; push correct return address!
	JMP (drv_opt)		; as will be the first one in list, best to use non-indexed indirect

; *** TS_INFO, get taskswitching info for multitasking driver *** new API 20161019
; Y -> number of bytes, ex_pt -> pointer to the proposed stack frame
ts_info:
#ifdef	MULTITASK
	.xs: SEP #$10			; *** standard index size ***
	.al: REP #$20			; *** 16-bit memory ***
	LDA #tsi_str			; pointer to proposed stack frame
	STA ex_pt				; store output word
	LDY #tsi_end-tsi_str	; number of bytes
	_EXIT_OK
#else
	.xs: REP #$10			; *** standard index size for error handling ***
	_ERR(UNAVAIL)			; non-supporting kernel!
#endif

tsi_str:
; pre-created reversed stack frame for firing tasks up, regardless of multitasking driver implementation
	.word	isr_sched_ret-1	; corrected reentry address **standard label**
	.byt	0				; stored X value, best if multitasking driver is the first one
	.word	0, 0, 0			; irrelevant Y, X, A values
tsi_end:
; end of stack frame for easier size computation

; *** end of kernel functions ***


; jump table, if not in separate 'jump' file
#ifndef		DOWNLOAD
k_vec:
	.word	cout		; output a character
	.word	cin			; get a character
	.word	malloc		; reserve memory (kludge!)
	.word	free		; release memory (kludgest!)
	.word	open_w		; get I/O port or window
	.word	close_w		; close window
	.word	free_w		; will be closed by kernel
	.word	uptime		; approximate uptime in ticks (new)
	.word	b_fork		; get available PID
	.word	b_exec		; launch new process
	.word	load_link	; get addr. once in RAM/ROM
	.word	su_poke		; write protected addresses
	.word	su_peek		; read protected addresses
	.word	string		; prints a C-string
	.word	su_sei		; disable interrupts, aka dis_int
	.word	su_cli		; enable interrupts (not needed for 65xx) aka en_int
	.word	set_fg		; enable frequency generator (VIA T1@PB7)
	.word	go_shell	; launch default shell, INSERTED 20150604
	.word	shutdown	; proper shutdown procedure, new 20150409, renumbered 20150604
	.word	signal		; send UNIX-like signal to a braid, new 20150415, renumbered 20150604
	.word	get_pid		; get PID of current braid, new 20150415, renumbered 20150604
	.word	set_handler	; set SIGTERM handler, new 20150417, renumbered 20150604
	.word	yield		; give away CPU time for I/O-bound process, new 20150415, renumbered 20150604
	.word	ts_info		; get taskswitching info, new 20150507-08, renumbered 20150604

#else
#include "drivers.s"	; this package will be included with downloadable kernels
.data
#include "sysvars.h"	; donwloadable systems have all vars AND drivers after the kernel itself
#include "drivers.h"
user_sram = *			; the rest of SRAM
#endif
