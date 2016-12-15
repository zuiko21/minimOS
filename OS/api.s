; minimOS generic Kernel API
; v0.5.1a12, must match kernel.s
; (c) 2012-2016 Carlos J. Santisteban
; last modified 20161215-0958

; no way for standalone assembly...

; *** dummy function, non implemented ***
unimplemented:			; placeholder here, not currently used
	_ERR(UNAVAIL)		; go away!


; *** COUT, output a character ***
; Y <- dev, io_c <- char
; LOWRAM version uses da_ptr!!!

cout:
; new MUTEX for COUT 161121, *per-driver based 161124 **added overhead
#ifdef	MULTITASK
	STY iol_dev			; **keep device temporarily, worth doing here (3)
	_ENTER_CS			; needed for a MUTEX (5)
co_loop:
	LDA cio_lock, Y		; *check whether THAT device in use (4)
	BEQ co_lckd			; resume operation if free (3)
; otherwise yield CPU time and repeat
		JSR yield			; give way... scheduler would switch on interrupts as needed *** direct internal API call!
		LDY iol_dev			; restore previous status, *new style (3)
		_BRA co_loop		; try again! (3)
co_lckd:
	JSR get_pid			; **standard internal call, 816 prefers indexed JSR
	TYA					; **current PID in A (2)
	LDY iol_dev			; **restore device number (3)
	STA cio_lock, Y		; *reserve this (4)
	_EXIT_CS			; proceed normally (4)
#endif
; continue with mutually exclusive COUT
	TYA					; for indexed comparisons (2)
	BNE co_port			; not default (3/2)
		LDA stdout			; new per-process standard device
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
; ** new direct indexing, converted to subroutine because of MUTEX 20161121 **
	ASL					; convert to index (2+2)
	TAX
; clear mutex ONLY if multitasking is in use!
#ifdef	MULTITASK
	JSR co_call			; indirect indexed CALL...
	LDX iol_dev			; **need to clear new lock! (3)
	_STZA cio_lock, X	; ...because I have to clear MUTEX! *new indexed form (4)
	RTS					; respect error code anyway

co_call:
#endif
	_JMPX(drv_opt)		; direct jump!!!


; *** CIN, get a character *** revamped 20150209
; Y <- dev, io_c -> char, C = not available

cin:
; new MUTEX for CIN 161121, *per-driver based 161124 **added overhead
#ifdef	MULTITASK
	STY iol_dev			; **keep device temporarily, worth doing here (3)
	_ENTER_CS			; needed for a MUTEX (5)
ci_loop:
	LDA cio_lock, Y		; *check whether THAT device in use (4)
	BEQ ci_lckd			; resume operation if free (3)
; otherwise yield CPU time and repeat
; but first check whether it was me (waiting on binary mode)
		JSR get_pid			; *standard internal call, 816 prefers indexed JSR
		TYA					; **current PID in A
		LDY iol_dev			; **retrieve device as index
		CMP cio_lock, Y		; *was it me who locked? (4)
			BEQ ci_lckdd		; *if so, resume execution (3)
; if the above, could first check whether the device is in binary mode, otherwise repeat loop!
; continue with regular mutex
		JSR yield			; give way... scheduler would switch on interrupts as needed *** direct internal API call!
		LDY iol_dev			; *restore previous status (3)
		_BRA ci_loop		; try again! (3)
ci_lckd:
	JSR get_pid			; **standard internal call, 816 prefers indexed JSR
	TYA					; **current PID in A (2)
	LDY iol_dev			; **restore device number (3)
	STA cio_lock, Y		; *reserve this (4)
ci_lckdd:
	_EXIT_CS			; proceed normally (4)
#endif
; continue with mutually exclusive CIN
	TYA					; for indexed comparisons
	BNE ci_port			; specified
		LDA std_in			; new per-process standard device
		BNE ci_port			; already a valid device
			LDA default_in		; otherwise get system global
ci_port:
	BPL ci_nph			; logic device
		JSR ci_phys			; check physical devices... but come back for events! new 20150617
		BCC ci_chkev		; no error, have a look at events ***could reduce overhead a bit with BCS!
ci_exit:
#ifdef	MULTITASK
			LDX iol_dev			; **use device as index! (3)
			_STZA cio_lock, X	; *otherwise clear mutex!!! (4)
#endif
			RTS					; return whatever error!

; some common I/O calls
cio_nfound:
	_ERR(N_FOUND)		; unknown device

; ** EVENT management **
; this might be revised, or supressed altogether!
ci_chkev:
#ifdef	MULTITASK
		LDX iol_dev			; **use device as index! worth doing here (3)
#endif
		LDA io_c			; get received character
		CMP #' '			; printable?
			BCS ci_exitOK		; if so, will not be an event, exit with NO error
; otherwise might be an event ** REVISE
; check for binary mode first
#ifdef	MULTITASK
		LDY cin_mode, X		; *get flag, new sysvar 20150617
#else
		LDY cin_mode		; singletask systems
#endif
		BEQ ci_event		; not binary, should process possible event ***might reduce overhead with BNE
#ifdef	MULTITASK
			_STZA cin_mode, X	; *back to normal mode
#else
			_STZA cin_mode		; normal mode for singletask systems!
#endif
ci_exitOK:
#ifdef	MULTITASK
			_STZA cio_lock, X	; *clear mutex!!! (4)
#endif
			_EXIT_OK			; all done without error!
ci_event:
		CMP #16				; is it DLE?
		BNE ci_notdle		; otherwise check next
#ifdef	MULTITASK
			STA cin_mode, X		; *set binary mode! safer and faster!
#else
			STA cin_mode		; single task systems do not set X!!!
#endif
			_ERR(EMPTY)			; and supress received character, ***but will stay locked!
ci_notdle:
		CMP #3				; is it ^C? (TERM)
		BNE ci_noterm		; otherwise check next
			LDA #SIGTERM
			BNE ci_signal		; send signal, no need for BRA?
ci_noterm:
		CMP #4				; is it ^D? (KILL) ***somewhat dangerous...
		BNE ci_nokill		; otherwise check next
			LDA #SIGKILL
			BNE ci_signal		; send signal, no need for BRA?
ci_nokill:
		CMP #26				; is it ^Z? (STOP)
		BNE ci_exitOK		; otherwise there's no more to check
			LDA #SIGSTOP		; last signal to be sent
ci_signal:
			STA b_sig			; set signal as parameter
			JSR get_pid			; as this will be a self-sent signal! ***internal call
			JSR signal			; send signal to PID in Y ***internal call
			LDX iol_dev			; **as internal calls will destroy X
ci_abort:
#ifdef	MULTITASK
		_STZA cio_lock, X	; *clear mutex!
#endif
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
	LDY ticks		; simple placeholder
	_EXIT_OK

ci_win:
; *** virtual window manager TO DO ***
	_ERR(NO_RSRC)	; not yet implemented

ci_phys:
; ** new direct indexing **
	ASL					; convert to index (2+2)
	TAX
	_JMPX(drv_ipt)		; direct jump!!!

; *** MALLOC, reserve memory *** fully revamped 20161107
; ma_rs <- size, ma_pt -> addr, C = not enough memory
; ma_align <- mask for MSB (0=page or not aligned, 1=512b, $FF=bank aligned) new 161105 TO DO
; ma_rs = 0 means reserve as much memory as available!!!
; this works on 16-bit addressing, thus single byte positions and non-interleaved status & PID arrays!
; uses ma_l as diverse temporary vars, as defined below *** might redefine in separate locals

ma_siz	= ma_l
ma_ix	= ma_l+1

malloc:
	LDX #0				; reset index
	LDY ma_rs			; check individual bytes, just in case
	BEQ ma_nxpg			; no extra page needed
		INC ma_rs+1			; otherwise increase number of pages
		STX ma_rs			; ...and just in case, clear asked bytes!
ma_nxpg:
	_ENTER_CS			; this is dangerous! enter critical section, new 160119
	LDA ma_rs+1			; get number of asked pages
	BNE ma_scan			; work on specific size
; otherwise check for biggest available block
		STX ma_siz			; clear found value eeeeeeeeek
ma_biggest:
			LDY ram_stat, X		; get status of block (4)
;			CPY #FREE_RAM		; not needed if FREE_RAM is zero! (2)
			BNE ma_nxbig		; go for next as this one was not free (3/2)
				JSR ma_alsiz		; **compute size according to alignment mask**
				CMP ma_siz			; compare against current maximum (3)
				BCC ma_nxbig		; this was not bigger (3/2)
					STA ma_siz			; otherwise keep track of it... (3)
					STX ma_ix			; ...and its index! (3)
ma_nxbig:
			INX					; advance index (2)
			LDY ram_stat, X		; peek next status (4)
			CPY #END_RAM		; check whether at end (2)
			BNE ma_biggest		; or continue (3/2)
; is there at least one available block?
		LDA ma_siz			; should not be zero
		BNE ma_fill			; there is at least one block to allocate
			_ERR(FULL)			; otherwise no free memory!
; report allocated size
ma_fill:
		STA ma_rs+1			; store allocated size! already computed
		LDX ma_ix			; retrieve index
		_BRA ma_updt		; nothing to scan, just update status and return address
ma_scan:
		LDY ram_stat, X		; get state of current entry (4)
;		CMP #FREE_RAM		; looking for a free one (2) not needed if free is zero
			BEQ ma_found		; got one (2/3)
		CPY #END_RAM		; got already to the end? (2)
			BEQ ma_nobank		; could not found anything suitable (2/3)
ma_cont:
		INX					; increase index (2)
		CPX #MAX_LIST		; until the end (2+3)
		BNE ma_scan
ma_nobank:
	_EXIT_CS			; non-critical when aborting!
	_ERR(FULL)			; no room for it!
ma_found:
#ifdef	SAFE
	LDA ram_pos+1, X	; check next block position
	SEC
	SBC ram_pos, X		; and subtract current pointer
	BCS ma_nobad		; this one should be lower!
		LDA #>user_sram		; otherwise take beginning of user RAM...
		LDY #USED_RAM		; ...that will become locked (maybe another value)
		STA ram_pos			; create values
		STY ram_stat		; **should it clear the PID field too???**
		LDA #SRAM			; physical top of RAM...
		LDY #END_RAM		; ...as non-plus-ultra
		STA ram_pos+1		; create second set of values
		STY ram_stat+1
		_ERR(CORRUPT)		; report but do not turn system down!
ma_nobad:
#endif
	JSR ma_alsiz		; **compute size according to alignment mask**
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
		LDA ram_pos, X		; get repeated address
		ORA ma_align		; set disturbing bits...
		_INC				; ...and reset them after increasing the rest
		STA ram_pos, X		; update pointer
ma_aok:
	PLA					; retrieve size
; make room for new entry... if not exactly the same size
	CMP ma_rs			; compare this block with requested size
	BEQ ma_updt			; was same size, will not generate new entry
		JSR ma_adv			; make room otherwise
ma_updt:
	_STZA ma_pt			; clear pointer LSB
	LDA ram_pos, X		; get address of block to be assigned
	STA ma_pt+1			; note this is address of PAGE
	LDA #USED_RAM		; now is reserved
	STA ram_stat, X		; update table entry
; ** new 20161106, store PID of caller **
	_PHX				; will need this index
	JSR get_pid			; who asked for this?
	_PLX				; retrieve index
	TYA					; unfortunately no STY abs,X
	STA ram_pid, X		; store PID
; theoretically we are done, end of CS
	_EXIT_CS			; end of critical section, new 160119
	_EXIT_OK			; we're done

; routine for aligned-block size computation
ma_alsiz:
	LDA ram_pos, X		; get bottom address (4)
	BIT ma_align		; check for set bits from mask (4)
	BEQ ma_fit			; none was set, thus already aligned (3/2)
		ORA ma_align		; set masked bits... (3)
		_INC				; ...and increase address for alignment (2)
ma_fit:			ORA (str_pt), Y		; is this possible?

	EOR #$FF			; invert bits as will be subtracted to next entry (2)
	SEC					; needs one more for twos-complement (2)
	ADC ram_pos+1, X	; compute size from top ptr MINUS bottom one (5)
	RTS
; *** non-aligned version ***
;	LDA ram_pos+1, X	; get end position (4)
;	SEC
;	SBC ram_pos, X		; subtract current for size! (2+4)
; *** end of non-aligned version ***

; routine for making room for an entry
ma_adv:
	STX ma_ix			; store current index
ma_2end:
		INX					; previous was free, thus check next
		CPX #MAX_LIST-1		; just in case, check offset!!!
		BCC ma_notend		; could expand
			PLA					; discard return address
			PLA
			JMP ma_nobank		; notice error
ma_notend:
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
; create at the beginning of the moved block a FREE entry!
	LDA ram_pos+1, X	; newly assigned slice will begin here
	CLC
	ADC ma_rs+1			; add number of assigned pages
	STA ram_pos+1, X	; update value
	LDA #FREE_RAM		; let us mark it as free
	STA ram_stat+1, X	; next to the assigned one
	RTS


; *** FREE, release memory *** revamped 20150209
; ma_pt <- addr
; C -> no such used block!

free:
	LDX #0				; reset index
	LDA ma_pt			; get comparison term
	_ENTER_CS			; supposedly dangerous
fr_loop:
		CMP ram_pos, X		; is what we are looking for?
			BEQ fr_found		; go free it!
		LDY ram_stat, X		; otherwise check status
		INX					; advance index
		CPY #END_RAM		; no more in list?
		BNE fr_loop			; continue until end
; was not found, thus exit CS and abort
fr_no:
	_EXIT_CS
	_ERR(N_FOUND)		; no block to be freed!
fr_found:
#ifdef	SAFE
	LDY ram_stat, X		; only used blocks can be freed!
	CPY #USED_RAM		; was it in use?
		BNE fr_no			; if not, cannot free it!
#endif
	LDA #FREE_RAM		; most likely zero, might use STZ instead
	STA ram_stat, X		; this block is now free, but...
; really should join possible adjacent free blocks
	LDY ram_stat+1, X	; check status of following entry
;	CPY #FREE_RAM		; was it free? could be supressed if value is zero
	BNE fr_ok			; was not free, thus nothing to optimize
; loop for obliterating the following empty entry
fr_join:
		INX					; go for next entry
		LDA ram_pos+1, X	; get following address
		STA ram_pos, X		; store one entry below
		LDA ram_stat+1, X	; check status of following!
		STA ram_stat, X		; store one entry below
		LDA ram_pid+1, X	; copy PID of following, but keep status in Y!
		STA ram_pid, X		; 			ORA (str_pt), Y		; is this possible?
no longer interleaved
		CPY #END_RAM		; end of list?
		BNE fr_join			; repeat until done
; ** already optimized **
fr_ok:
	_EXIT_CS
	_EXIT_OK


; *** OPEN_W, get I/O port or window *** interface revised 20150208
; Y -> dev, w_rect <- size+pos*64K, str_pt <- pointer to window title!

open_w:
	LDA w_rect			; asking for some size?
	ORA w_rect+1
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


; *** UPTIME, get approximate uptime *** revised 20150208, corrected 20150318
; up_ticks -> ticks, new format 20161006
; up_sec -> 32-bit uptime in seconds

uptime:
	LDX #1			; first go for elapsed ticks (2 bytes) (2)
	_ENTER_CS		; don't change while copying
up_loop:
		LDA ticks, X		; get system variable byte (not uptime, corrected 20150125) (4)
		STA up_ticks, X		; and store them in output parameter (3)
		DEX					; go for next (2+3/2)
		BPL up_loop
	LDX #3			; now for the uptime in seconds (now 4 bytes) (2)
up_upt:
		LDA ticks+2, X		; get system variable uptime, new 20150318 (4)
		STA up_sec, X		; and store it in output parameter (3) corrected 150610
		DEX					; go for next (2+3/2)
		BPL up_upt
	_EXIT_CS
	_EXIT_OK


; *** LOAD_LINK, get address once in RAM/ROM (kludge!) *** TO_DO
; ex_pt -> addr, str_pt <- *path
; somewhat improved version, scans ROM headers looking for the _filename_ pointed by str_pt
; *** modifies str_pt parameter ***
; no folders accepted!!!
; will use rh_scan (local3)

load_link:
; *** first look for that filename in ROM headers ***
; first of all, correct parameter pointer as will be aligned with header!
	LDA str_pt			; get LSB
	SEC
	SBC #8				; subtract name position in header!
	STA str_pt			; modified value
	BCS ll_reset		; nothing else to do if no borrow
		DEC str_pt			; otherwise will point to previous page
ll_reset:
; get initial address! beacuse of the above, no longer adds filename offset!
	LDA #<ROM_BASE		; begin of ROM contents LSB
;	CLC
;	ADC #8				; add filename offset!!!
	STA	rh_scan			; set local pointer
	LDA #>ROM_BASE		; same for MSB
;	ADC #0				; propagate carry, although probably not needed!
	STA rh_scan+1		; corrected pointer set
ll_geth:
; ** check whether we are on a valid header!!! **
		LDY #0				; first of all should be a NUL
		LDA (rh_scan), Y	; get first byte in header
			BNE ll_nfound		; link was lost, no more to scan
		LDY #7				; after type and size, a CR is expected
		LDA (rh_scan), Y	; get eigth byte in header!
		CMP #13				; was it a CR?
			BNE ll_nfound		; if not, go away
; look for the name
		LDY #8				; reset scanning index (now at name position)
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
		LDY #253			; relative offset to number of pages to skip
		LDA (rh_scan), Y	; get number of pages to skip
		SEC					; ...plus header itself! eeeeeeek
		ADC rh_scan+1		; add to previous value
		STA rh_scan+1		; update pointer
		BCC ll_geth			; inspect new header (if no overflow! 16-bit addressing)
ll_nfound:
	_ERR(N_FOUND)		; all was scanned and the query was not found
ll_found:
; this was the original load_link code prior to 20161202, will be executed after the header was found!
; *** assume *path points to header, code begins +256 *** STILL A KLUDGE
; instead of the above, use a (re-corrected) rh_scan instead (based on zero)
	LDY #1			; offset for filetype
	LDA (rh_scan), Y	; check filetype
	CMP #'m'		; must be minimOS app!
		BNE ll_wrap		; error otherwise
	INY				; next byte is CPU type
	LDA (rh_scan), Y	; get it

; ** generic CPU-type comparison code, this is 46 bytes long
; loop for checking out CPU type, assume Y=2!!!
;ll_ccpu:
;		CMP ll_cpulst, Y	; is one of the listed CPUs?
;			BEQ ll_dcpu			; detected type
;		DEY					; otherwise try next
;		BPL ll_ccpu			; until zero (included)
;	BMI ll_wrap		; not suitable for this architecture!
;ll_dcpu:
;	LDX #3			; will scan physical CPU type
;	LDA fw_cpu		; *** UGLY HACK, this is a FIRMWARE variable ***
;ll_scpu:
;		CMP ll_cpulst, X	; is one of the listed CPUs?
;			BEQ ll_phcpu		; physical CPU detected
;		DEY					; otherwise try next
;		BPL ll_scpu			; until end
;	BRK				; *** should never arrive here unless firmware vars corruption ***
;	.asc	"{CPU}", 0
;ll_phcpu:
;	CPX #3			; is it a 65816?
;	BNE ll_6502		; not!
;		CPY #2			; if so, is it trying to execute Rockwell extensions?
;			BEQ ll_wrap		; no way!
;			BNE ll_valid	; otherwise, no problem
;ll_6502:			; *** (40 bytes this far)
;	STX ex_pt		; temporary storage of _physical_ CPU-type, or STY???
;	CPY ex_pt		; compare against _code_ CPU-type, or CPX????
;		BCC ll_wrap		; this was incompatible

; ** alternative code (minus CPU-type table, this is 35 bytes only
	LDX fw_cpu		; *** UGLY HACK, this is a FIRMWARE variable ***
	CPX #'R'		; is it a Rockwell/WDC CPU?
		BEQ ll_rock		; from R down is OK
	CPX #'B'		; generic 65C02?
		BEQ ll_cmos		; from B down is OK
	CPX #'V'		; 65816 is supported but no better than a generic 65C02
		BEQ ll_cmos
	CPX #'N'		; old NMOS?
		BEQ ll_nmos			; only NMOS code will do
		_PANIC("{CPU?}")	; *** should NEVER arrive here, unless firmware variables are corrupt! ***
ll_rock:
	CMP #'R'		; code has Rockwell extensions?
		BEQ ll_valid
ll_cmos:
	CMP #'B'		; generic 65C02 code?
		BEQ ll_valid
ll_nmos:
	CMP #'N'		; every supported CPU can run NMOS code
		BNE ll_wrap		; otherwise is code for another architecture!
; present CPU is able to execute supplied code
ll_valid:
	LDA rh_scan		; get pointer LSB
	LDY rh_scan+1	; and MSB
	INY				; start from next page
	STA ex_pt		; save execution pointer
	STY ex_pt+1
	_EXIT_OK
ll_wrap:
	_ERR(INVALID)	; something was wrong

; CPU type list for easier detection *** NO LONGER USED
;ll_cpulst:
;	.asc	"NBRV"	; NMOS, generic CMOS, Rockwell CMOS, then 65816 (for physical CPU only)


; *** SU_POKE, write to protected addresses *** revised 20150208
; might be deprecated, not sure if of any use in other architectures
; Y <- value, zpar <- addr
; destroys A (and maybe Y on NMOS)

su_poke:
	TYA				; transfer value
	_STAY(zpar)		; store value, macro for NMOS
	_EXIT_OK


; *** SU_PEEK, read from protected addresses *** revised 20150208
; might be deprecated, not sure if of any use in other architectures
; Y -> value, zpar <- addr
; destroys A

su_peek:
	_LDAY(zpar)		; store value, macro for NMOS
	TAY				; transfer value
	_EXIT_OK


; *** STRING, prints a C-string *** revised 20150208, revamped 20151015, complete rewrite 20160120
; Y <- dev, str_pt <- *string (.w in current version)
; uses str_dev AND iol_dev
; calls cout, but now directly at driver code *** great revision, scans ONCE for device driver
; included mutex 20161201 eeeeeeeeeeeeeek

string:
; ** actual code from COUT here, might save space using a common routine, but adds a bit of overhead
; new MUTEX 161201, *per-driver **added overhead
#ifdef	MULTITASK
	STY iol_dev			; **keep device temporarily, worth doing here (3)
	_ENTER_CS			; needed for a MUTEX (5)
str_wait:
	LDA cio_lock, Y		; *check whether THAT device in use (4)
	BEQ str_lckd		; resume operation if free (3)
; otherwise yield CPU time and repeat
		JSR yield			; give way... scheduler would switch on interrupts as needed *** direct internal API call!
		LDY iol_dev			; restore previous status, *new style (3)
		_BRA str_wait		; try again! (3)
str_lckd:
	JSR get_pid			; **standard internal call, 816 prefers indexed JSR
	TYA					; **current PID in A (2)
	LDY iol_dev			; **restore device number (3)
	STA cio_lock, Y		; *reserve this (4)
	_EXIT_CS			; proceed normally (4)
#endif
; continue with mutually exclusive COUT
	TYA				; for indexed comparisons (2)
	BNE str_port	; not default (3/2)
		LDA stdout		; new per-process standard device
		BNE str_port	; already a valid device
			LDA default_out	; otherwise get system global (4)
str_port:
	BMI str_phys	; not a logic device (3/2)
		CMP #64			; first file-dev??? ***
			BCC str_win		; below that, should be window manager
; ** optional filesystem access **
#ifdef	FILESYSTEM
		CMP #64+MAX_FILES	; still within file-devs?
			BCS str_log		; that value or over, not a file
; *** manage here output to open file ***
		_ERR(NO_RSRC)	; not yet implemented ***placeholder***
#endif
; ** end of filesystem access **
str_log:
; investigate rest of logical devices
		CMP #DEV_NULL	; lastly, ignore output
			BNE str_nfound	; final error otherwise
str_exit:
#ifdef	MULTITASK
		LDX iol_dev			; retrieve driver index
		_STZA cio_lock, X	; clear mutex
#endif
		_EXIT_OK		; "/dev/null" is always OK
str_win:
; *** virtual windows manager TO DO ***
	LDY #NO_RSRC		; not yet implemented
	SEC					; eeek
	_BRA str_abort		; notify error code AND unlock device!
str_nfound:
	LDY #N_FOUND		; unknown device
	SEC					; eeeek
	_BRA str_abort		; notify error code AND unlock device!
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
			_EXIT_OK			; and go away!
str_cont:
		STA io_c			; store output character for COUT (3)
		JSR str_call		; indirect subroutine call (6...)
		_PLY				; restore index (4)
		INY					; eeeeeeeeeeeek (2)
			BCS str_err			; error from driver, but keeping Y eeeeeek
		BNE str_loop		; still within same page
	INC str_pt+1		; otherwise increase, parameter has changed! will it have to restore parameter?
	_BRA str_loop		; continue, will check for termination later (3)
str_call:
	LDX str_dev			; get driver pointer position (3)
	_JMPX(drv_opt)		; go at stored pointer (...6)
str_err:
	PLA					; discard saved Y while keeping error code
str_abort:
#ifdef	MULTITASK
	LDX iol_dev			; retrieve driver index
	_STZA cio_lock, X	; clear mutex
#endif
	RTS					; return whatever error code

; *** SU_SEI, disable interrupts *** revised 20150209
; C -> not authorized (?)
; probably not needed on 65xx, _CS macros are much more interesting anyway
su_sei:
	SEI				; disable interrupts
	_EXIT_OK		; no error so far


; *** SU_CLI, enable interrupts *** revised 20150209
; probably not needed on 65xx, _CS macros are much more interesting anyway

su_cli:				; not needed for 65xx, even with protection hardware
	CLI				; enable interrupts
	_EXIT_OK		; no error


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
; ask all braids to terminate
	LDY #0				; PID=0 means ALL braids
	LDA #SIGTERM		; will be asked to terminate
	STA b_sig			; store signal type
	JSR signal			; ask braids to terminate
	CLI					; make sure all will keep running!
	_EXIT_OK

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
		_PANIC("{sched}")	; otherwise an error!
sd_shut:
	SEI				; disable interrupts
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
		LDY #D_BYE			; shutdown LSB offset eeeeeeek
		_PHX				; save index for later
		JSR dr_call			; call routine from generic code!!!
		_PLX				; retrieve index
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


; *** B_FORK, get available PID *** properly interfaced 20150417
; Y -> PID

b_fork:
; ** might be replaced with LDY pid on optimized builds **
	LDX #MM_FORK	; subfunction code
	_BRA sig_call	; go for the driver

; *** B_EXEC, launch new loaded process *** properly interfaced 20150417 with changed API!
; API still subject to change... (default I/O, rendez-vous mode TBD)
; Y <- PID, ex_pt <- addr, def_io <- std_in & stdout
; *** should need some flag to indicate XIP or not! stack frame is different

b_exec:
; ** might be repaced with driver code on optimized builds **
	LDX #MM_EXEC	; subfunction code
	_BRA sig_call	; go for the driver


; *** B_SIGNAL, send UNIX-like signal to a braid ***
; b_sig <- signal to be sent , Y <- addressed braid

signal:
	LDX #MM_SIGNAL	; subfunction code
	_BRA sig_call	; go for the driver

; *** B_STATUS, get execution flags of a braid ***
; Y <- addressed braid
; Y -> flags, TBD
; don't know of possible errors, maybe just a bad PID

status:
	LDX #MM_STATUS	; subfunction code
	_BRA sig_call	; go for the driver

; *** GET_PID, get current braid PID ***
; Y -> PID, TBD
; *****think about making this the direct call as is the fastest one!

get_pid:
	LDX #MM_PID		; subfunction code
; * unified calling procedure, get subfunction code in X * new faster interface 20161102
sig_call:			; NEW unified calling procedure
	JMP (drv_opt)	; just enter into preinstalled driver, will exit with appropriate error code!

; *** SET_HNDL, set SIGTERM handler, default is like SIGKILL ***
; Y <- PID, ex_pt <- SIGTERM handler routine (ending in RTI!!!)
; bad PID is probably the only feasible error

set_handler:
	LDX #MM_HANDL	; subfunction code
	_BRA sig_call	; go for the driver

; *** B_YIELD, Yield CPU time to next braid ***
; supposedly no interface needed, don't think I need to tell if ignored

yield:
	LDX #MM_YIELD	; subfunction code
	_BRA sig_call	; go for the driver


; *** TS_INFO, get taskswitching info for multitasking driver *** new API 20161019
; Y -> number of bytes, ex_pt -> pointer to the proposed stack frame
ts_info:
#ifdef	MULTITASK
	LDX #<tsi_str			; pointer to proposed stack frame
	LDA #>tsi_str			; including MSB
	STX ex_pt				; store LSB
	STA ex_pt+1				; and MSB
	LDY #tsi_end-tsi_str	; number of bytes
	_EXIT_OK
#else
	_ERR(UNAVAIL)			; non-supporting kernel!
#endif

tsi_str:
; pre-created reversed stack frame for firing tasks up, regardless of multitasking driver implementation
	.word	isr_sched_ret-1	; corrected reentry address **standard label** REVISE REVISE************++
	.byt	0				; stored X value, best if multitasking driver is the first one
	.byt	0, 0, 0			; irrelevant Y, X, A values
tsi_end:
; end of stack frame for easier size computation

; *** RELEASE, release ALL memory for a PID, new 20161115
; Y <- PID

release:
	TYA					; as no CPY abs,X
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
			LDA ram_pos+1, X	; MSB too
			STY ma_pt			; will be used by FREE
			STA ma_pt+1
			JSR free			; release it!
			_PLX				; retrieve status
			PLA
			BCC rls_next		; keep index IF current entry was deleted!
rls_oth:
		INX					; advance to next block
rls_next:
		LDY ram_stat, X		; look status only
		CPY #END_RAM		; are we done?
		BNE rls_loop		; continue if not yet
	_EXIT_OK			; no errors...

; *******************************
; *** end of kernel functions ***
; *******************************

; **************************************************
; *** jump table, if not in separate 'jump' file ***
; **************************************************
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
	.word	release		; release ALL memory for a PID, new 20161115

#else
#include "drivers.s"	; this package will be included with downloadable kernels
.data
#include "sysvars.h"	; downloadable systems have all vars AND drivers after the kernel itself
#include "drivers.h"
user_sram = *			; the rest of SRAM
#endif
