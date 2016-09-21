; minimOS·16 generic Kernel API!
; v0.5b1, should match kernel16.s
; this is essentialy minimOS·65 0.5b4...
; (c) 2016 Carlos J. Santisteban
; last modified 20160921-1406

; no way for standalone assembly...

; *** dummy function, non implemented ***
unimplemented:		; placeholder here, not currently used
	.as: .xs: SEP $30	; *** standard register size ***
	_ERR16(UNAVAIL)	; go away!


; *** COUT, output a character ***
; Y <- dev, io_c <- char
; *** TO DO revise local default device *** 

cout:
	.as: .xs: SEP $30	; *** standard register size ***
	TYA				; for indexed comparisons (2)
	BNE co_port		; not default (3/2)
		LDA default_out	; default output device (4)
co_port:
	BMI co_phys		; not a logic device (3/2)
		CMP #64			; first file-dev??? ***
			BCC co_win		; below that, should be window manager
; ** optional filesystem access **
#ifdef	FILESYSTEM
		CMP #64+MAX_FILES	; still within file-devs?
			BCS co_log		; that value or over, not a file
; *** manage here output to open file ***
		_ERR16(NO_RSRC)	; not yet implemented ***placeholder***
#endif
; ** end of filesystem access **
co_log:
; investigate rest of logical devices
		CMP #DEV_NULL	; lastly, ignore output
			BNE cio_nfound	; final error otherwise
		_OK_16		; "/dev/null" is always OK
co_win:
; *** virtual windows manager TO DO ***
	_ERR16(NO_RSRC)	; not yet implemented
co_phys:
; ** new direct indexing **
	ASL					; convert to index (2+2)
	TAX
	_JMPX(drv_opt)		; direct jump!!! **** needs 16-bit driver ending on RTI... or redefined standard macros!

cio_nfound:
	_ERR16(N_FOUND)	; unknown device


; *** CIN, get a character *** revamped 20150209
; Y <- dev, io_c -> char, C = not available

cin:
	.as: .xs: SEP $30	; *** standard register size ***
	TYA				; for indexed comparisons
	BNE ci_port		; specified
		LDA default_in	; default input device
ci_port:
	BPL ci_nph		; logic device
		JSR ci_phys		; check physical devices... but come back for events! new 20150617
			BCS ci_exit		; some error, send it back
; ** EVENT management **
; this might be revised, or supressed altogether!
		LDA io_c		; get received character
		CMP #' '		; printable?
			BCC ci_manage	; if not, might be an event
ci_exitOK:
		_OK_16			; generic macro, older trick NLA
ci_exit:
		RTS				; cannot use macro because may need to keep Carry
ci_phys:
; ** new direct indexing **
	ASL					; convert to index (2+2)
	TAX
	_JMPX(drv_ipt)		; direct jump!!!

; ** continue event management ** REVISE
ci_manage:
; check for binary mode
	LDY cin_mode	; get flag, new sysvar 20150617
	BEQ ci_event	; should process possible event
		_STZY cin_mode	; back to normal mode
		_BRA ci_exit	; and return whatever was received
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
	BNE ci_exitOK	; otherwise there's no more to check
		LDA #SIGSTOP	; last signal to be sent
ci_signal:
		STA b_sig			; set signal as parameter
		_KERN16(GET_PID)	; as this will be a self-sent signal!
		_KERN16(B_SIGNAL)	; send signal to PID in Y
ci_abort:
		_ERR16(EMPTY)		; no character was received

ci_nph:
	CMP #64			; first file-dev??? ***
		BCC ci_win		; below that, should be window manager
; ** optional filesystem access **
#ifdef	FILESYSTEM
	CMP #64+MAX_FILES	; still within file-devs?
		BCS ci_log		; that or over, not a file
; *** manage here input from open file ***
	_ERR16(NO_RSRC)	; not yet implemented ***placeholder***
#endif
; ** end of filesystem access **

ci_log:
	CMP #DEV_RND	; getting a random number?
		BEQ ci_rnd		; compute it!
	CMP #DEV_NULL	; lastly, ignore input
		BNE cio_nfound	; final error otherwise
	_OK_16		; "/dev/null" is always OK

ci_rnd:
; *** generate random number (TO DO) ***
	LDY ticks		; simple placeholder
	_OK_16

ci_win:
; *** virtual window manager TO DO ***
	_ERR16(NO_RSRC)	; not yet implemented


; *** MALLOC, reserve memory *** revamped 20150209
; ma_rs <- size, ma_pt -> addr, C = not enough memory (16-bit so far, but put zeroes on high-size!)
; ** ONLY for systems over 128-byte RAM **
; uses ma_l

malloc:
;	LDA ma_rs+2		; asking over 64K?
;	ORA ma_rs+3
;		BNE ma_nobank	; most likely never available for 65C02
	.as: .xs: SEP $30	; *** standard register size ***
	LDY #0			; reset index
	_ENTER_CS		; this is dangerous! enter critical section, new 160119
ma_scan:
		LDA ram_stat, Y		; get state of current entry (4)
;		CMP #FREE_RAM		; looking for a free one (2) not needed if free is zero
			BEQ ma_found		; got one (2/3)
ma_cont:
		INY					; increase index (2)
		CPY #MAX_LIST/2		; until the end (2+3)
		BNE ma_scan
	_EXIT_CS		; were off by 15*n, up to 240 clocks instead of 304
ma_nobank:
	_ERR16(FULL)		; no room for it!
ma_found:
	TYA						; compute other index
	ASL						; two times
	TAX						; now indexing in words
	LDA ram_siz+1, X		; get size MSB (4)
	CMP ma_rs+1				; compare (3)
		BCC ma_cont				; smaller, thus continue searching (2/3)
	LDA ram_siz, X			; check LSB, just in case (4)
	CMP ma_rs				; compare (3)
		BCC ma_cont				; smaller, thus continue searching (2/3)
; here we go
	LDA ram_siz, X			; get current free block size LSB (4)
	STA ma_l				; store it for later (3)
	LDA ram_siz+1, X		; same for MSB (4+3)
	STA ma_l+1
	LDA ma_rs				; get size LSB (3)
	STA ram_siz, X			; reduce entry (4)
	LDA ma_rs+1				; same for MSB (3+4)
	STA ram_siz+1, X
	LDA #USED_RAM			; mark block as used (2) define elsewhere
	STA ram_stat, Y			; indexed by byte (4)
	LDA ma_l
	ORA ma_l+1				; some space remaining? (3+3)
	BEQ ma_ok				; nothing more to do (2/3)
; ** make room for sub-entry, highly recommended **
		STX ma_l+2				; store limit
		LDY #MAX_LIST-2			; first origin (2)
ma_opt:
			LDA ram_tab, Y		; get origin
			STA ram_tab+2, Y	; put destination, sure???
			LDA ram_siz, Y		; same for ram_siz
			STA ram_siz+2, Y
			DEY					; next
			CPY ma_l+2
			BCS ma_opt
		CLC
		LSR ma_l+2			; do same for ram_stat
		LDY #(MAX_LIST/2)-1
ma_stat:
			LDA ram_stat, Y
			STA ram_stat+1, Y	; check too
			DEY					; next
			CPY ma_l+2
			BCS ma_stat			; EEEK, was BPL, hope it is OK
; now create new free entry
		LDA ram_tab, X		; get current address
		CLC
		ADC ma_rs			; add size LSB
		STA ram_tab+2, X	; set new entry, best not touching X!
		LDA ram_tab+1, X	; same for MSB
		ADC ma_rs+1
		STA ram_tab+3, X
		LDA ma_l			; get size LSB
		SEC
		SBC ma_rs			; substract size
		STA ram_siz+2, X	; store in new entry, same as before
		LDA ma_l+1			; same for MSB
		SBC ma_rs+1
		STA ram_siz+3, X
		LDY ma_l+2			; Y is no longer valid, thus restore from stored X/2
		LDA #FREE_RAM		; needed even if free is zero
		STA ram_stat+1, Y	; set new entry as free, unfortunately no STZ abs,Y
; ** optimization finished **
ma_ok:
	LDA ram_tab, X			; get address' LSB (4)
	STA ma_pt				; store output (3)
	LDA ram_tab+1, X		; same for MSB (4+3)
	STA ma_pt+1
	_EXIT_CS				; end of critical section, new 160119
	_OK_16				; we're done


; *** FREE, release memory *** revamped 20150209
; ma_pt <- addr
; ** ONLY for systems over 128-byte RAM

free:
	.as: .xs: SEP $30	; *** standard register size ***
	LDX #0			; reset indexes
	_ENTER_CS		; supposedly dangerous
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
	_EXIT_CS
	_ERR16(N_FOUND)			; no block to be freed!
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
		_STZA ram_siz+2, X	; clear size of it, so the KLUDGE might work
		_STZA ram_siz+3, X
		_STZA ram_tab+2, X	; same with address, so the KLUDGE might work
		_STZA ram_tab+3, X
; ** already optimized **
fr_ok:
	_EXIT_CS
	_OK_16


; *** OPEN_W, get I/O port or window *** interface revised 20150208
; Y -> dev, w_rect <- size+pos*64K, str_pt <- pointer to window title!

open_w:
	.as: .xs: SEP $30	; *** standard register size ***
	LDA w_rect			; asking for some size?
	ORA w_rect+1
	BEQ ow_no_window	; wouldn't do it
		_ERR16(NO_RSRC)
ow_no_window:
	LDY #DEVICE			; constant default device, REVISE
;	EXIT_OK on subsequent system calls!

; *** CLOSE_W, close window ***
; *** FREE_W, release window, will be closed by kernel ***
; Y <- dev
close_w:				; doesn't do much
free_w:					; doesn't do much, either
	_OK_16


; *** UPTIME, get approximate uptime *** revised 20150208, corrected 20150318
; up_ticks -> fr-ticks
; up_sec -> 24-bit uptime in seconds

uptime:
	.as: .xs: SEP $30	; *** standard register size ***
	LDX #1			; first go for remaining ticks (2 bytes) (2)
	_ENTER_CS		; don't change while copying
up_loop:
		LDA ticks, X		; get system variable byte (not uptime, corrected 20150125) (4)
		STA up_ticks, X		; and store them in output parameter (3)
		DEX					; go for next (2+3/2)
		BPL up_loop
	LDX #2			; now for the uptime in seconds (3 bytes) (2)
up_upt:
		LDA ticks+2, X		; get system variable uptime, new 20150318 (4)
		STA up_sec, X		; and store it in output parameter (3) corrected 150610
		DEX					; go for next (2+3/2)
		BPL up_upt
	_EXIT_CS		; disabled for 62 clocks, not 53...
	_OK_16


; *** B_FORK, get available PID *** properly interfaced 20150417
; Y -> PID

b_fork:
	.as: .xs: SEP $30	; *** standard register size ***
#ifdef	MULTITASK
; ** might be replaced with LDY pid on optimized builds **
	LDA #MM_FORK	; subfunction code
	STA io_c		; as fake parameter
	LDY #TASK_DEV	; multitasking as device driver!
	_KERN16(COUT)	; call pseudo-driver
	RTS				; return whatever error code
#else
	LDY #0			; no multitasking, system reserved PID
	_OK_16
#endif

; *** B_EXEC, launch new loaded process *** properly interfaced 20150417 with changed API!
; API still subject to change... (default I/O, rendez-vous mode TBD)
; Y <- PID, ex_pt <- addr (was z2L)
; uses str_dev for temporary braid storage, driver will pick it up!

b_exec:
	.as: .xs: SEP $30	; *** standard register size ***
#ifdef	MULTITASK
; ** might be repaced with driver code on optimized builds **
	LDA #MM_EXEC	; subfunction code
	STY str_dev		; COUT shouldn't touch it
	STA io_c		; as fake parameter
	LDY #TASK_DEV	; multitasking as device driver!
	_KERN16(COUT)	; call pseudo-driver
	RTS				; return previous error
#else
; non-multitasking version
	CPY #0			; should be system reserved PID
	BEQ exec_st		; OK for single-task system
		_ERR16(NO_RSRC)	; no way without multitasking
exec_st:
	LDA ex_pt+1		; get address MSB first
	PHA				; put it on stack
	LDA ex_pt		; same for LSB
	PHA
	PHP				; ready for RTI
	RTI				; actual jump, won't return here
#endif


; *** LOAD_LINK, get address once in RAM/ROM (kludge!) *** TO_DO TO_DO TO_DO *******************
; ex_pt -> addr, str_pt <- *path

load_link:
; *** assume path points to filename in header, code begins +248 *** KLUDGE
	.as: .xs: SEP $30	; *** standard register size ***
	CLC				; ready to add
	LDA str_pt		; get LSB
	ADC #248		; offset to actual code!
	STA ex_pt		; store address LSB
	LDA str_pt+1	; get MSB so far
	ADC #0			; propagate carry!
	STA ex_pt+1		; store address MSB
	LDA #0			; NMOS only
	STA ex_pt+2		; STZ, invalidate bank...
	STA ex_pt+3		; ...just in case
	BCS ll_wrap		; really unexpected error
		_OK_16
ll_wrap:
	_ERR16(INVALID)	; something was wrong


; *** SU_POKE, write to protected addresses *** revised 20150208
; might be deprecated, not sure if of any use in other architectures
; Y <- value, zpar <- addr
; destroys A (and maybe Y on NMOS)

su_poke:
	.as: .xs: SEP $30	; *** standard register size ***
	TYA				; transfer value
	_STAY(zpar)		; store value, macro for NMOS
	_OK_16


; *** SU_PEEK, read from protected addresses *** revised 20150208
; might be deprecated, not sure if of any use in other architectures
; Y -> value, zpar <- addr
; destroys A

su_peek:
	.as: .xs: SEP $30	; *** standard register size ***
	_LDAY(zpar)		; store value, macro for NMOS
	TAY				; transfer value
	_OK_16


; *** STRING, prints a C-string *** revised 20150208, revamped 20151015, complete rewrite 20160120
; Y <- dev, str_pt <- *string (.w in current version)
; uses str_dev
; calls cout, but now directly at driver code *** great revision, scans ONCE for device driver

string:
; ** actual code from COUT here, might save space using a common routine, but adds a bit of overhead
	.as: .xs: SEP $30	; *** standard register size ***
	TYA				; for indexed comparisons (2)
	BNE str_port	; not default (3/2)
		LDA default_out	; default output device (4)
str_port:
	BMI str_phys	; not a logic device (3/2)
		CMP #64			; first file-dev??? ***
			BCC str_win		; below that, should be window manager
; ** optional filesystem access **
#ifdef	FILESYSTEM
		CMP #64+MAX_FILES	; still within file-devs?
			BCS str_log		; that value or over, not a file
; *** manage here output to open file ***
		_ERR16(NO_RSRC)	; not yet implemented ***placeholder***
#endif
; ** end of filesystem access **
str_log:
; investigate rest of logical devices
		CMP #DEV_NULL	; lastly, ignore output
			BNE str_nfound	; final error otherwise
str_exit:
		_OK_16		; "/dev/null" is always OK
str_win:
; *** virtual windows manager TO DO ***
	_ERR16(NO_RSRC)	; not yet implemented
str_nfound:
	_ERR16(N_FOUND)	; unknown device
str_phys:
; ** new direct indexing, revamped 20160407 **
	ASL					; convert to index (2+2)
	STA str_dev			; store for indexed call! (3)
	LDY #0				; eeeeeeeek! (2)
; ** the actual printing loop **
str_loop:
		_PHY				; save just in case COUT destroys it (3)
		LDA (str_pt), Y		; get character from string, new approach (5)
		BNE str_cont		; not terminated! (3/2)
			PLA					; otherwise discard saved Y (4)
			_OK_16			; and go away!
str_cont:
		STA io_c			; store output character for COUT (3)
		JSR str_call		; indirect subroutine call (6...)
		_PLY				; restore index (4)
		INY					; eeeeeeeeeeeek (2)
		BNE str_loop		; still within same page
	INC str_pt+1		; otherwise increase, parameter has changed!
	_BRA str_loop		; continue, will check for termination later (3)
str_call:
	LDX str_dev			; get driver pointer position (3)
	JMP (drv_opt, X)	; go at stored pointer (...6)


; *** SU_SEI, disable interrupts *** revised 20150209
; C -> not authorized (?)
; probably not needed on 65xx, _CS macros are much more interesting anyway
su_sei:
	SEI				; disable interrupts
	_OK_16		; no error so far


; *** SU_CLI, enable interrupts *** revised 20150209
; probably not needed on 65xx, _CS macros are much more interesting anyway

su_cli:				; not needed for 65xx, even with protection hardware
	CLI				; enable interrupts
	_OK_16		; no error


; *** SET_FG, enable/disable frequency generator (Phi2/n) on VIA *** revised 20150208...
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
	_OK_16		; finish anyway
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
	_ERR16(BUSY)		; couldn't set


; *** GO_SHELL, launch default shell *** new 20150604
; no interface needed
go_shell:
	JMP shell		; simply... *** SHOULD initialise SP and other things anyway ***


; *** SHUTDOWN, proper shutdown, with or without poweroff ***
; Y <- subfunction code new ABI 20150603, 20160408
; C -> couldn't poweroff or reboot (?)

shutdown:
	CPY #PW_CLEAN		; from scheduler only!
		BEQ sd_2nd			; continue with second stage
	CPY #PW_STAT		; is it going to suspend?
		BEQ sd_stat			; don't shutdown system then!
	STY sd_flag			; store mode for later, first must do proper system shutdown
; ask all braids to termmm_siginate
	LDY #0				; PID=0 means ALL braids
	LDA #SIGTERM		; will be asked to terminate
	STA b_sig			; store signal type
	_KERN16(B_SIGNAL)	; ask braids to terminate
	CLI					; make sure all will keep running!
	_OK_16

; firmware interface
sd_off:
	LDY #PW_OFF			; poweroff
sd_fw:
	_ADMIN(POWEROFF)	; except for suspend, shouldn't return...
	RTS					; just in case was not implemented!
sd_stat:
	LDY #PW_STAT		; suspend
	BNE sd_fw			; no need for BRA
sd_cold:
	LDY #PW_COLD		; cold boot
	BNE sd_fw			; will reboot, shared code, no need for BRA
sd_warm:
	SEI					; maybe a better place to do it
	CLD
	JMP warm			; firmware no longer should take pointer, generic kernel knows anyway

; the scheduler will wait for NO braids active
; now let's disable all drivers
sd_2nd:
	LDA sd_flag		; check what was pending
	BNE sd_shut		; something to do
		BRK				; otherwise an error!
		.asc	"{sched}", 0	; panic code
sd_shut:
	_SEI			; disable interrupts
#ifdef	SAFE
	_STZA dpoll_mx	; disable interrupt queues, just in case
	_STZA dreq_mx
	_STZA dsec_mx
#endif
; call each driver's shutdown routine *** new system 20151015
	LDX #0			; reset index
; first get the pointer to each driver table
sd_loop:
; get address index
		LDA drivers_ad, X	; get address from original list
		STA sysptr			; store temporarily
		LDA drivers_ad+1, X	; same for MSB
			BEQ sd_done			; no more drivers to shutdown!
		STA sysptr+1
; check here whether the driver was successfully installed, get ID as index for drv_opt/ipt
		LDY #D_ID			; point to ID of driver
		LDA (sysptr), Y		; get ID
		ASL					; convert to index
			BCC sd_next			; invalid device ID!
		TAY					; use as index
		LDA drv_opt, Y		; check LSB
		EOR drv_ipt, Y		; only the same if not installed...
		BNE sd_msb			; but check MSB too!
			INY					; point to MSB
			LDA drv_opt, Y		; check MSB
			EOR drv_ipt, Y		; only the same if not installed!
			BEQ sd_next			; nothing to shutoff
sd_msb:
		LDY #D_BYE+1		; shutdown MSB offset
		PHX					; save index for later
		JSR dr_call			; call routine from generic code!!!
		PLX					; retrieve index
sd_next:
		INX					; advance to next entry (2+2)
		INX
		BNE sd_loop			; repeat
; system cleanly shut, time to let the firmware turn-off or reboot
sd_done:
	LDX sd_flag			; retrieve mode as index!
	_JMPX(sd_tab)		; do as appropriate

sd_tab:					; check order in abi.h!
	.word	sd_stat		; suspend
	.word	sd_warm		; warm boot direct by kernel
	.word	sd_cold		; cold boot via firmware
	.word	sd_off		; shutdown system

; ***************************************************** REVAMP *************************************************+

; *** B_SIGNAL, send UNIX-like signal to a braid ***
; b_sig <- signal to be sent , Y <- addressed braid
; uses locals[0] too
; don't know of possible errors********

signal:
#ifdef	MULTITASK
	LDA #MM_SIGNAL	; subfunction code
	STY mm_sig		; COUT shouldn't touch it anyway
	_BRA yld_call	; go for the driver
; ** if the driver fails, it will NEVER reach this point!!!! **
#ifdef	SAFE
sig_st:				; *** single-task interface, in case MM driver failed *** (repeated from below)
	TYA				; check correct PID, really needed?
		BNE sig_pid		; strange error?
	LDY b_sig		; get the signal
	CPY #SIGTERM	; clean shutoff
		BEQ sig_term
	CPY #SIGKILL	; suicide, makes any sense?
		BEQ sig_kill
sig_pid:			; placeholder...
	_ERR16(INVALID)	; unrecognised signal
sig_term:
	JSR sig_call	; call routine, RTS will get back here
sig_kill:
	_OK_16		; *** don't know what to do here ***
sig_call:
	JMP (mm_term)	; jump to single-word vector, actually taken from an unused table!
#endif
#else
; *** single task interface (copied above) ***
	TYA				; check correct PID, really needed?
		BNE sig_pid		; strange error?
	LDY b_sig		; get the signal
	CPY #SIGTERM	; clean shutoff
		BEQ sig_term
	CPY #SIGKILL	; suicide, makes any sense?
		BEQ sig_kill
sig_pid:			; placeholder...
	_ERR16(INVALID)	; unrecognised signal
sig_term:
	JSR sig_call	; call routine, RTS will get back here
sig_kill:
	_OK_16		; *** don't know what to do here ***
sig_call:
	JMP (mm_term)	; jump to single-word vector, don't forget to init it somewhere!
#endif

; *** B_STATUS, get execution flags of a braid ***
; Y <- addressed braid
; Y -> flags, TBD
; uses locals[0] too
; don't know of possible errors

status:
#ifdef	MULTITASK
	LDA #MM_STATUS	; subfunction code
	;**************
	STY locals		; COUT shouldn't touch it anyway
	_BRA yld_call	; go for the driver
; ** if the driver fails, it will NEVER reach this point!!!! **
#ifdef	SAFE
stat_st:				; *** single-task interface, in case MM driver failed *** copied from below
	LDY #BR_RUN		; single-task systems are always running, or should I make an error instead?
	_OK_16
#endif
#else	
; *** single-task interface, copied above ***
	LDY #BR_RUN		; single-task systems are always running, or should I make an error instead?
	_OK_16
#endif

; *** GET_PID, get current braid PID ***
; Y -> PID, TBD
; uses locals[0] too ***revise
; don't know of possible errors

get_pid:
#ifdef	MULTITASK
	LDA #MM_PID		; subfunction code
	_BRA yld_call	; go for the driver
; ** if the driver fails, it will NEVER reach this point!!!! **
#ifdef	SAFE
pid_st:				; *** single-task interface, in case MM driver failed *** copied from below
	LDY #0			; system-reserved PID for single-task execution
	_OK_16
#endif
#else
; *** single-task interface, copied above ***
	LDY #0			; system-reserved PID for single-task execution
	_OK_16
#endif

; *** SET_HNDL, set SIGTERM handler, default is like SIGKILL ***
; Y <- PID, zpar2.W <- SIGTERM handler routine (ending in RTS)
; uses locals[0] too
; bad PID is probably the only feasible error

set_handler:
#ifdef	MULTITASK
	LDA #MM_HANDL	; subfunction code
	_BRA yld_call	; go for the driver
; ** if the driver fails, it will NEVER reach this point!!!! **
#ifdef	SAFE
hndl_st:				; *** single-task interface, in case MM driver failed *** copied from below
	LDA zpar2		; get LSB
	STA mm_term		; store in single variable (from unused table)
	LDA zpar2+1		; same for MSB
	STA mm_term+1
	_OK_16
#endif
#else
; *** single-task interface, copied above ***
	LDA zpar2		; get LSB
	STA mm_term	; store in single variable
	LDA zpar2+1		; same for MSB
	STA mm_term+1
	_OK_16
#endif

; *** B_YIELD, Yield CPU time to next braid ***
; supposedly no interface needed, don't think I need to tell if ignored
; destroys like COUT and _TASK_DEV

yield:
#ifndef	MULTITASK
	_OK_16		; no one to give CPU time away!
#else
#ifndef	AUTOBANK
	_OK_16		; if no multitasking assisting hardware is present, just ignore and stay
#else
	LDA #MM_YIELD	; subfunction code
#endif
yld_call:			; unified calling procedure
	STA zpar		; subfunction as fake character
	LDY #TASK_DEV	; multitasking driver ID
	_KERN16(COUT)	; call driver
#ifdef	SAFE
		BCS yld_failed	; in case multitasking driver was included but failed to register...
#endif
	RTS				; all done, keeping any errors from driver

#ifdef	SAFE
yld_failed:			; *** emergency single-task management ***
	LDX zpar		; get subfunction code
	CPX #MM_PRIOR	; first invalid code (this far)
		BPL yld_err		; generic error
	_JMPX(yld_table-4)	; go to appropriate label! note offset, since B_FORK and B_EXEC are already processed

yld_st:
		_OK_16		; in case isn't defined elsewhere
yld_err:
		_ERR16(INVALID)	; some generic error...

; addresses of single-task routines, new procedure 20150610
yld_table:
;	0 = B_FORK, 2 = B_EXEC
	.word	yld_st	; does nothing, actually
	.word	sig_st	; single-task SIGNAL
	.word	stat_st	; single-task STATUS
	.word	pid_st	; single-task PID
	.word	hndl_st	; single-task HANDL
#endif
#endif

; *** TS_INFO, get taskswitching info for multitasking driver *** revamped 20150521
; Y -> number of bytes, zpar... -> bytes of the proposed _reversed_ stack frame (originally 3)
; REVISE REVISE
ts_info:
	LDA #0					; what will X hold? could be 0 as long as the multitasaking driver is the first one!
	STA zpar+2				; store output value
	LDA #>(isr_sched_ret-1)	; get return address MSB
	STA zpar+1				; store it
	LDA #<(isr_sched_ret-1)	; same for LSB
	STA zpar
	LDY #3					; number of bytes
	_OK_16

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
