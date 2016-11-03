; minimOS·16 generic Kernel API!
; v0.5.1a6, should match kernel16.s
; (c) 2016 Carlos J. Santisteban
; last modified 20161103-1325

; no way for standalone assembly...

; *** dummy function, non implemented ***
unimplemented:		; placeholder here, not currently used
	.as: .xs: SEP #$30	; *** standard register size ***
	_ERR(UNAVAIL)	; go away!


; *** COUT, output a character ***
; Y <- dev, io_c <- char

cout:
	.as: .xs: SEP #$30	; *** standard register size ***
	TYA				; for indexed comparisons (2)
	BNE co_port		; not default (3/2)
		LDA stdout		; new per-process standard device ### apply this to ·65
		BNE co_port		; already a valid device
			LDA default_out	; otherwise get system global (4)
co_port:
	BMI co_phys		; not a logic device (3/2)
		CMP #64			; first file-dev??? ***
			BCC co_win		; below that, should be window manager
; ** optional filesystem access **
#ifdef	FILESYSTEM
		CMP #64+MAX_FILES	; still within file-devs?
			BCS co_log		; that value or over, not a file
; *** manage here output to open file ***
		_ERR(NO_RSRC)	; not yet implemented ***placeholder***
#endif
; ** end of filesystem access **
co_log:
; investigate rest of logical devices
		CMP #DEV_NULL	; lastly, ignore output
			BNE cio_nfound	; final error otherwise
		_EXIT_OK		; "/dev/null" is always OK
co_win:
; *** virtual windows manager TO DO ***
	_ERR(NO_RSRC)	; not yet implemented
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
	TYA				; for indexed comparisons
	BNE ci_port		; specified
		LDA std_in		; new per-process standard device ### apply this to ·65
		BNE ci_port		; already a valid device
			LDA default_in	; otherwise get system global
ci_port:
	BPL ci_nph		; logic device
; ** new direct indexing **
		ASL					; convert to index (2+2)
		TAX
		JSR (drv_ipt, X)	; direct CALL!!!
			BCS cio_callend		; if some error, send it back
; ** EVENT management **
; this might be revised, or supressed altogether!
		LDA io_c		; get received character
		CMP #' '		; printable?
			BCC ci_manage	; if not, might be an event
		_EXIT_OK			; generic macro, older trick NLA

; ** continue event management ** REVISE
ci_manage:
; check for binary mode
	LDY cin_mode	; get flag
	BEQ ci_event	; should process possible event
		STZ cin_mode	; back to normal mode
		_EXIT_OK		; and return whatever was received
ci_event:
	CMP #16			; is it DLE?
	BNE ci_notdle	; otherwise check next
		INC cin_mode	; set binary mode!
		BNE ci_abort	; and supress received character, no need for BRA
ci_notdle:
	CMP #3			; is it ^C? (TERM)
	BNE ci_noterm	; otherwise check next
		LDA #SIGTERM
		BNE ci_signal	; send signal, no need for BRA?
ci_noterm:
	CMP #4			; is it ^D? (KILL) somewhat dangerous...
	BNE ci_nokill	; otherwise check next
		LDA #SIGKILL
		BNE ci_signal	; send signal, no need for BRA?
ci_nokill:
	CMP #26			; is it ^Z? (STOP)
	BEQ ci_stop		; last signal to be sent
		_EXIT_OK		; otherwise all done
ci_stop:
	LDA #SIGSTOP	; last signal to be sent
ci_signal:
	STA b_sig			; set signal as parameter
	_KERNEL(GET_PID)	; as this will be a self-sent signal!
	_KERNEL(B_SIGNAL)	; send signal to PID in Y
ci_abort:
	_ERR(EMPTY)			; no character was received

ci_nph:
	CMP #64			; first file-dev??? ***
		BCC ci_win		; below that, should be window manager
; ** optional filesystem access **
#ifdef	FILESYSTEM
	CMP #64+MAX_FILES	; still within file-devs?
		BCS ci_log		; that or over, not a file
; *** manage here input from open file ***
	_ERR(NO_RSRC)	; not yet implemented ***placeholder***
#endif
; ** end of filesystem access **

ci_log:
	CMP #DEV_RND	; getting a random number?
		BEQ ci_rnd		; compute it!
	CMP #DEV_NULL	; lastly, ignore input
		BNE cio_nfound	; final error otherwise
	_EXIT_OK		; "/dev/null" is always OK

ci_rnd:
; *** generate random number (TO DO) ***
	LDY ticks		; simple placeholder
	_EXIT_OK

ci_win:
; *** virtual window manager TO DO ***
	_ERR(NO_RSRC)	; not yet implemented


; *** MALLOC, reserve memory *** IN THE MAKING
; ma_rs <- size, ma_pt -> addr, C = not enough memory
; ma_rs = 0 means reserve as much memory as available!!!
; * this works on 24-bit addressing! *
; uses ma_l

malloc:
	.al: REP #$20		; *** 16-bit memory ***
	.xs: SEP #$10		; *** 8-bit indexes ***
	LDX ma_rs			; check individual bytes, just in case
	BEQ ma_nxpg			; no extra page needed
		INC	ma_rs+1			; otherwise increase number of pages
;		LDX #0				; ...and just in case, clear asked bytes!
;		STX ma_rs			; best not to change again register size
ma_nxpg:
	LDA ma_rs+1			; get number of asked pages
; default 816 API functions run on interrupts masked, thus no need for CS
	BNE ma_sized		; work on specific size
		; *** otherwise check available space *** TO DO *** TO DO *** TO DO ***
ma_sized:
	LDY #0				; reset list index
ma_scan:
		LDX ram_stat, Y		; get state of current entry (4)
;		CMP #FREE_RAM		; looking for a free one (2) not needed if free is zero
			BEQ ma_found		; got one (2/3)
		CPX #END_RAM		; got already to the end? (2)
			BEQ ma_nobank		; could not found anything suitable (2/3)
ma_cont:
		INY					; increase index (2)
		CPY #MAX_LIST/2		; until the end (2+3)
		BNE ma_scan
; one end of CS
ma_nobank:
	_ERR(FULL)		; no room for it!
ma_found:
	TYA						; compute other index (2)
	ASL						; two times (2)
	TAX						; now indexing in words, MSB is lost anyway (2)
	LDA ram_pos+2, X		; get position of NEXT block (5)
	SEC
	SBC ram_pos, X			; subtract current (FREE) block position, now A holds size in pages (2+5)
#ifdef	SAFE
	BCS ma_nobad			; no corruption was seen (3/2)
		_PANIC("{RAMlist}")		; otherwise something went VERY wrong!
ma_nobad:
#endif
	CMP ma_rs+1				; compare (5)
		BCC ma_cont				; smaller, thus continue searching (2/3)
; here we go!
; first make room for new entry... if not exactly the same size
	BEQ ma_updt				; was same size, will not generate new entry
; make room for new entry
		STX ma_l				; store index
		TXA						; to half index...
		LSR
		TAY
		STY ma_l+1				; store halved version too
ma_2end:
			INY						; previous was free, thus check next
			LDX ram_stat, Y			; check status of block
			CPX #END_RAM			; scan for the end-of-memory marker
			BNE ma_2end				; hopefully will end sometime!
		STY ma_l+2				; this will help too
		TYA						; back to full index...
		ASL
		TAX
ma_room:
			LDA ram_pos, X			; get one block address
			STA ram_pos+2, X		; one position forward
			DEX						; down one entry
			DEX
			CPX ma_l				; position of updated entry
			BNE ma_room				; continue until done
		LDY ma_l+2				; now let us do the status array
ma_stats:
			LDX ram_stat, Y			; get one block status
			STX ram_stat+1, Y		; advance it
			DEY						; go backwards
			CPY ma_l+1				; until the end
			BNE ma_stats
		LDX ma_l				; get back full index!
; create at the beginning of the moved block a FREE entry!
		LDA ram_pos+2, X		; newly assigned slice will begin here
		CLC
		ADC ma_rs+1				; add number of assigned pages
		STA ram_pos+2, X		; update value
		LDX #FREE_RAM			; let us mark it as free
		STX ram_stat+1, Y		; next to the assigned one
ma_updt:
	LDA ram_pos, X			; get address of block to be assigned
	STA ma_pt+1				; note this is address of PAGE
	LDY #0					; set byte address to zero, just in case
	STY ma_pt
	TXA						; back to half index, consider making sparse array
	LSR						; halve it
	TAY						; just like the other one
	LDX #USED_RAM			; now is reserved
	STX ram_stat, Y			; update table entry
; theoretically we are done, end of CS
	_EXIT_OK


; *** FREE, release memory *** revamp along MALLOC
; ma_pt <- addr

free:
	.as: .xs: SEP #$30	; *** standard register size ***
	LDX #0			; reset indexes
; default 816 API functions run on interrupts masked, thus no need for CS
; might go 16-bit memory...
fr_loop:
		LDA ram_tab, X		; get entry LSB
		CMP ma_pt			; compare
			BNE fr_next			; try other
		LDA ram_tab+1, X	; same for MSB
		CMP ma_pt+1
			BEQ fr_found		; stop searching, much easier this way
fr_next:
		INX
		INX
		CPX #MAX_LIST		; until the end
		BCC fr_loop
; end of CS
	_ERR(N_FOUND)			; no block to be freed!
fr_found:
	TXA				; get two-byte index
	CLC
	LSR				; convert to byte index
	TAY				; could be saved but no way with optimization...
	LDA #FREE_RAM	; free block
	STA ram_stat, Y	; unfortunately no STZ abs,Y
; ** optimize list, highly recommended **
fr_opt:
		LDA ram_stat+1, Y	; get status of contiguous entry
;		CMP #FREE_RAM		; was it free? no need if free is zero
			BNE fr_ok			; was not free, so nothing to optimize
		LDA ram_siz, X		; get actual size LSB
		CLC
		ADC ram_siz+2, X	; add following size
		LDA ram_siz+1, X	; same with MSB
		ADC ram_siz+3, X
		LDA #UNAS_RAM		; create unassigned entry
		STA ram_stat+1, Y	; **KLUDGE** just set entry as unassigned, instead of obliterating it
		STZ ram_siz+2, X	; clear size of it, so the KLUDGE might work
		STZ ram_siz+3, X
		STZ ram_tab+2, X	; same with address, so the KLUDGE might work
		STZ ram_tab+3, X
; ** already optimized **
fr_ok:
; end of CS, if still there
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
	SEI				; disable interrupts
	_EXIT_OK		; no error so far


; *** SU_CLI, enable interrupts ***
; probably not needed on 65xx, _CS macros are much more interesting anyway

su_cli:				; not needed for 65xx, even with protection hardware
	CLI				; enable interrupts
	_EXIT_OK		; no error


; *** SET_FG, enable/disable frequency generator (Phi2/n) on VIA ***
; ** should use some firmware interface, just in case it doesn't affect jiffy-IRQ! **
; should also be Phi2-rate independent... input as Hz, or 100uS steps?
; zpar.W <- dividing factor (times two?), C -> busy
; destroys A, X...

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
		BRA fg_none
fg_busy:
	_ERR(BUSY)		; couldn't set


; *** GO_SHELL, launch default shell *** REVISE
; no interface needed
go_shell:
	JMP shell		; simply... *** SHOULD initialise SP and other things anyway ***


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
	.xs: SEP #$10			; *** standard index size ***
	.al: REP #$20			; *** 16-bit memory ***
#ifdef	MULTITASK
	LDA #tsi_str			; pointer to proposed stack frame
	STA ex_pt				; store output word
	LDY #tsi_end-tsi_str	; number of bytes
	_EXIT_OK
#else
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

; *** pseudo-driver for non-multitasking systems! ***
st_taskdev:
	JMP (st_tdlist, X)	; call appropriate code, will return to original caller

; pointer list for single-task management routines
st_tdlist:
	.word	st_fork		; reserve a free braid (will go BR_STOP for a moment)
	.word	st_exec		; get code at some address running into a paused braid (will go BR_RUN)
	.word	st_yield	; switch to next braid, likely to be ignored if lacking hardware-assisted multitasking
	.word	st_signal	; send some signal to a braid
	.word	st_status	; get execution flags for a braid
	.word	st_getpid	; get current PID
	.word	st_hndl		; set SIGTERM handler
	.word	st_prior	; priorize braid, jump to it at once, really needed?

; ** single-task management routines **

; B_FORK for non-multitasking systems
; GET_PID for non-multitasking systems
st_fork:
st_getpid:
	LDY #0				; no multitasking, system reserved PID anytime
; B_YIELD for non-multitasking systems
st_yield:
	_DR_OK				; YIELD has no other task to give CPU time to!

; B_EXEC for non-multitasking systems
st_exec:
st_prior:
#ifdef	SAFE
	TYA					; should be system reserved PID, best way
	BEQ exec_st			; OK for single-task system
		_DR_ERR(NO_RSRC)	; no way without multitasking
exec_st:
#endif
; this should now work for both 02 and 816 apps
	LDA cpu_ll			; check architecture
	CMP #'V'			; check whether native 816 code (ending in RTL)
; new approach, reusing 816 code!
	BNE exec_02			; skip return address for 8-bit code
; ** alternative to self-generated code for long indirect call **
		PHK					; push program bank address, actually zero (3)
		PEA exec_ret-1		; push corrected return address (now long thanks to above instruction) (5)
exec_02:
	JMP [ex_pt]			; forthcoming RTL will get back just here, but 6502 RTS will go back to caller COUT
exec_ret:
	RTS					; keep possible error code (6)

; SET_HNDL for single-task systems
st_hndl:
	.al: REP #$20		; *** 16-bit memory size ***
	LDA ex_pt			; get pointer *** only bank zero addresses supported this far
	STA mm_term			; store in single variable (from unused table)
	_DR_OK

; B_STATUS for single-task systems
st_status:
	LDY #BR_RUN			; single-task systems are always running, or should I make an error instead?
	_DR_OK

; B_SIGNAL for single-task systems
st_signal:
#ifdef	SAFE
	TYA					; check correct PID, really needed?
		BNE sig_pid			; strange error?
#endif
	LDY b_sig			; get the signal
	CPY #SIGTERM		; clean shutdown
		BEQ sig_term
	CPY #SIGKILL		; suicide, makes any sense?
		BEQ sig_kill
sig_pid:
	_DR_ERR(INVALID)	; unrecognised signal
sig_term:
	PHK					; needed for new interface as will end in RTI!
	PEA sig_kill		; correct return address
	PHP					; eeeeeeeeeeeek
	LDA mm_stbnk		; single task handler might be anywhere
	PHA					; push bank address eeeeeeeeeeeek
	LDA mm_term+1		; get handler MSB
	PHA					; into stack
	LDA mm_term			; same for LSB
	PHA
	PHP					; as required
	RTI					; actual JUMP, RTS will get as indicated
sig_kill:				; *** I do not know what to do in this case *** might release windows etc
	_DR_OK				; generic exit, but check label above


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

