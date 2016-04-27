; minimOS generic Kernel
; v0.5b5
; (c) 2012-2016 Carlos J. Santisteban
; last modified 20160427-1441

; avoid standalone definitions
#define		KERNEL	_KERNEL

; uncomment in case of separate, downloadable jump & boot files
; should assume standalone assembly!!! (will get drivers anyway)
;#define		DOWNLOAD	_DOWNLOAD

; in case of standalone assembly
#ifndef		ROM
#include "options.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
.bss
#include "firmware/ARCH.h"
#ifdef		DOWNLOAD
* = $0400				; safe address for patchable 2 kiB systems, change if required
#else
#include "sysvars.h"
#include "drivers/config/DRIVER_PACK.h"
user_sram = *
#include "drivers/config/DRIVER_PACK.s"	; don't assemble actual code, just labels
* = ROM_BASE			; just a placeholder, no standardised address
#endif
.text
#endif

; **************************************************
; *** kernel begins here, much like a warm reset ***
; **************************************************

warm:
; assume interrupts off, binary mode and 65C816 in emulation mode!
; install kernel jump table if not previously loaded, NOT for 128-byte systems
#ifndef	LOWRAM
; ++++++
#ifndef		DOWNLOAD
	LDY #<k_vec		; get table address, nicer way (2+2)
	LDA #>k_vec
	STY ex_pt		; store parameter (3+3)
	STA ex_pt+1
	_ADMIN(INSTALL)	; copy jump table (14...)
#endif
; ++++++
#endif

; install ISR code (as defined in "isr/irq.s" below)
	LDY #<k_isr		; get address, nicer way (2+2)
	LDA #>k_isr
	STY ex_pt		; no need to know about actual vector location (3)
	STA ex_pt+1
	_ADMIN(SET_ISR)	; install routine (14...)

; Kernel no longer supplies default NMI, but could install it otherwise

	_STZA sd_flag	; this is important to be clear (PW_STAT) ASAP

; *****************************
; *** memory initialisation ***
; *****************************
; should be revised ASAP

#ifndef		LOWRAM
; ++++++
	LDA #UNAS_RAM		; unassigned space (2) should be defined somewhere (2)
	LDX #MAX_LIST		; depending on RAM size, corrected 20150326 (2)
mreset:
		STA ram_stat, X		; set entry as unassigned, essential (4)
		DEX					; previous byte (2)
		BNE mreset			; leaves first entry alone (3/2, is this OK?)
; please note Jalapa special RAM addressing!
	LDA #<user_sram		; get first entry LSB (2)
	STA ram_tab			; create entry (4)
	LDA #>user_sram		; same for MSB (2+4)
	STA ram_tab+1
;	LDA #FREE_RAM		; no longer needed if free is zero
	_STZA ram_stat		; set free entry (4)
	LDA #0				; compute free RAM (2+2)
	SEC
	SBC #<user_sram		; substract LSB (2+4)
	STA ram_siz
	LDA himem			; get ram size MSB (4)
	SBC #>user_sram		; substract MSB (2)
	STA ram_siz+1		; entry is OK (4)
; ++++++
#endif

; ******************************************************
; intialise drivers from their jump tables
; ******************************************************
; THINK about making API entries for this!

; set some labels, much neater this way
; globally defined da_ptr is a pointer for indirect addressing, new CIN/COUT compatible 20150619, revised 20160413
tm_ptr	= sysptr		; temporary pointer for double-indirect addressing!
;drv_aix = systmp		; address index for, not necessarily PROPOSED, driver list, new 20150318, shifted 20150619

; driver full install is new 20150208
	LDX #0				; reset driver index (2)
	STX dpoll_mx		; reset all indexes, NMOS-savvy (4+4+4)
	STX dreq_mx
	STX dsec_mx
;	STX drv_aix

#ifdef LOWRAM
; ------ low-RAM systems have no direct tables to reset ------
	STX drv_num			; single index of, not necessarily SUCCESSFULLY, detected drivers, updated 20150318 (4)
; ------
#else
; ++++++ new direct I/O tables for much faster access 20160406 ++++++
dr_clear:
		LDA #<dr_error			; make unused entries point to a standard error routine, new 20160406 (2)
		STA drv_opt, X			; set LSB for output (4)
		STA drv_ipt, X			; and for input (4)
		INX						; go for MSB (2)
		LDA #>dr_error			; pretty much the same, not worth a loop (2)
		STA drv_opt, X			; set MSB for output (4)
		STA drv_ipt, X			; and for input (4)
		INX						; next entry (2)
		BNE dr_clear			; finish page (3/2)
; ++++++
#endif

; first get the pointer to each driver table
dr_loop:
;		LDX drv_aix
		_PHX				; keep current value, just in case (3)
		LDA drivers_ad+1, X	; get address MSB (4)
		BNE dr_inst			; not in zeropage, in case is too far for BEQ dr_ok (3/2)
			JMP dr_ok			; all done otherwise (0/4)
dr_inst:
		STA da_ptr+1		; store pointer (3)
		LDA drivers_ad, X	; same for LSB (4+3)
		STA da_ptr
; create entry on IDs table ** new 20150219
		LDY #D_ID			; offset for ID (2)
		LDA (da_ptr), Y		; get ID code (5)
#ifdef	SAFE
		BMI dr_phys			; only physical devices (3/2)
			JMP dr_abort		; reject logical devices (3)
dr_phys:
#endif

#ifndef	LOWRAM
; ++++++ new faster driver list 20151014, revamped 20160406 ++++++
		ASL					; use retrieved ID as index (2+2)
		TAY
		LDA drv_opt, Y		; check whether in use (4)
		EOR drv_ipt, Y		; only the same if not installed! eeeeek
		BEQ dr_lsb			; LSB was OK (3/2)
			JMP dr_abort		; already in use (3)
dr_lsb:
		LDA drv_opt, Y	; check MSB too (4+2)
		EOR drv_ipt, Y		; only the same if not installed! eeeeek
		BEQ dr_msb			; all OK then (3/2) 
			JMP dr_abort		; already in use (3)
dr_msb:
		_PHY				; save index! (3)
		LDY #D_COUT			; offset for output routine (2)
		JSR dr_gind			; get indirect address
		_PLY				; restore index (4)
		LDA tm_ptr			; get driver table LSB (3)
		STA drv_opt, Y		; store in table (4)
		LDA tm_ptr+1		; same for MSB (3+4)
		STA drv_opt+1, Y
		_PHY				; save index! (3)
		LDY #D_CIN			; same for input routine (2)
		JSR dr_gind			; get indirect address
		_PLY				; restore index (4)
		LDA tm_ptr			; get driver table LSB (3)
		STA drv_ipt, Y		; store in table (4)
		LDA tm_ptr+1		; same for MSB (3+4)
		STA drv_ipt+1, Y
; ++++++
#else
; ------ IDs table filling for low-RAM systems ------
#ifdef	SAFE
; check whether the ID is in already in use
; might use a reversed loop, doing at the end LDX drv_num anyway?
; *** may fail if no drivers installed! *** think about doing it in reverse!
;		LDY #0			; reset index (2)
;		BEQ dr_limit	; check whether has something to check, no need for BRA (3)
dr_scan:
;			CMP drivers_id, Y	; compare with list entry (4)
;				BEQ dr_abort		; already in use, don't register! (2/3)
;			INY					; go for next (2)
;dr_limit:	CPY drv_num			; all done? (4)
;			BNE dr_scan			; go for next (3/2) */
#endif
		LDX drv_num			; retrieve single offset (4)
		STA drivers_id, X	; store in list, now in RAM (4)
; ------
#endif

; register interrupt routines (as usual)
		LDY #D_AUTH			; offset for feature code (2)
		LDA (da_ptr), Y		; get auth code (5)
		AND #A_POLL			; check whether D_POLL routine is avaliable (2)
			BEQ dr_nopoll		; no D_POLL installed (2/3)
		LDY #D_POLL			; get offset for periodic vector (2)
		LDX dpoll_mx		; get destination index (4)
		CPX #MAX_QUEUE		; compare against limit (2)
			BCS dr_abort		; error registering driver! (2/3) eek
dr_ploop:
			LDA (da_ptr), Y		; get one byte (5)
			STA drv_poll, X		; store in RAM (4)
			INY					; increase indexes (2+2)
			INX
			CPY #D_POLL+2		; both bytes done? (2)
			BCC dr_ploop		; if not, go for MSB (3/2) eek
		STX dpoll_mx		; save updated index (4)
		LDY #D_AUTH			; offset for feature code (2)
dr_nopoll:
		LDA (da_ptr), Y		; get auth code (5)
		AND #A_REQ			; check D_REQ presence (2)
			BEQ dr_noreq		; no D_REQ installed (2/3)
		LDY #D_REQ			; get offset for async vector (2)
		LDX dreq_mx			; get destination index (4)
		CPX #MAX_QUEUE		; compare against limit (2)
			BCS dr_abort		; error registering driver! (2/3) eek
dr_aloop:
			LDA (da_ptr), Y		; get its LSB (5)
			STA drv_async, X	; store in RAM (4)
			INY					; increase indexes (2+2)
			INX
			CPY #D_REQ+2		; both bytes done? (2)
			BCC dr_aloop		; if not, go for MSB (3/2) eek
		STX dreq_mx			; save updated index  (4)
		LDY #D_AUTH			; offset for feature code (2)
dr_noreq:
		LDA (da_ptr), Y		; get auth code (5)
		AND #A_SEC			; check D_SEC (2)
			BEQ dr_nosec		; no D_SEC installed (2/3)
		LDY #D_SEC			; get offset for 1-sec vector (2)
		LDX dsec_mx			; get destination index (4)
		CPX #MAX_QUEUE		; compare against limit (2)
			BCS dr_abort		; error registering driver! (2/3) eek
dr_sloop:
			LDA (da_ptr), Y		; get its LSB (5)
			STA drv_sec, X		; store in RAM (4)
			INY					; increase indexes (2+2)
			INX
			CPY #D_SEC+2		; both bytes done? (2)
			BCC dr_sloop		; if not, go for MSB (3/2) eek
		STX dsec_mx			; save updated index (4)
dr_nosec: 
; continue initing drivers
		JSR dr_icall	; call routine (6+...)
			BCS dr_abort	; failed initialisation, new 20150320
dr_next:
#ifdef	LOWRAM
; ------ low-RAM systems keep count of installed drivers ------
		INC drv_num		; update SINGLE index (6)
; ------
#endif
; in order to keep drivers_ad in ROM, can't just forget unsuccessfully registered drivers...
; in case drivers_ad is *created* in RAM, dr_abort could just be here, is this OK with new separate pointer tables?
;		INC drv_aix
		_PLX			; retrieve saved index (4)
		INX				; update ADDRESS index, even if unsuccessful (2)
		INX				; eeeeeeeek! pointer arithmetic! (2)
		JMP dr_loop		; go for next (3)
dr_abort:
#ifdef	LOWRAM
; ------ low-RAM systems keep count of installed drivers ------
		LDY drv_num			; get failed driver index (4)
		LDA #DEV_NULL		; make it unreachable, any positive value (logic device) will do (2)
		STA drivers_id, Y	; delete older value (4)
; ------
#else
; ++++++
		LDY #D_ID			; offset for ID (2)
		LDA (da_ptr), Y		; get ID code (5)
			BPL dr_next			; nothing to delete (2/3)
		ASL					; use retrieved ID as index (2+2)
		TAY
		LDA #<dr_error			; make deleted entries point to a standard error routine, new 20160406 (2)
		STA drv_opt, Y			; set LSB for output (4)
		STA drv_ipt, Y			; and for input (4)
		LDA #>dr_error			; pretty much the same, not worth a loop (2)
		STA drv_opt+1, Y		; set MSB for output (4)
		STA drv_ipt+1, Y		; and for input (4)
; ++++++
#endif
		_BRA dr_next			; go for next (3)

; get indirect address from driver pointer table, 13 bytes, 33 clocks
dr_gind:
	LDA (da_ptr), Y		; get address LSB (5)
	STA tm_ptr			; store temporarily (3)
	INY					; same for MSB (2)
	LDA (da_ptr), Y		; get MSB (5)
	STA tm_ptr+1		; store temporarily (3)
	RTS					; come back!!! (6)

dr_error:
	_ERR(N_FOUND)		; standard exit for non-existing drivers!

dr_icall:
	LDY #D_INIT			; original pointer (2)
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

dr_ok:					; all drivers inited
	PLA					; discard stored X, no hassle for NMOS
#ifdef	LOWRAM
; ------ terminate ID list ------
	LDX drv_num			; retrieve single index (4)
	_STZA drivers_id, X	; terminate list, and we're done! (4)
; ------
#endif

; **********************************
; ********* startup code ***********
; **********************************

; reset several remaining flags
	_STZA cin_mode	; reset binary mode flag, new 20150618

; *** set default SIGTERM handler for single-task systems, new 20150514 ***
; could be done always, will not harm anyway
#ifndef		MULTITASK
	LDY #<sig_kill	; get default routine address LSB
	LDA #>sig_kill	; same for MSB
	STY mm_term		; store in new system variable
	STA mm_term+1
#endif

; **********************************
; startup code, revise ASAP
; **********************************

; *** set default I/O device ***
	LDA #DEVICE		; as defined in options.h
	STA default_out	; should check some devices
	STA default_in

; *** interrupt setup no longer here, firmware did it! *** 20150605
	CLI				; enable interrupts

; ******************************
; **** launch monitor/shell ****
; ******************************

; until a proper B_EXEC is done, at least set available zeropage space!
	LDA #ZP_AVAIL		; available bytes
	STA z_used			; set environment variable
	JSR shell			; should be done this way, until a proper EXEC is made!
; ****revise this, should do PROPER shutdown and keep waiting for the firmware to power OFF
#ifndef		MULTITASK
	LDY #PW_OFF			; after execution, shut down system (al least)
	_ADMIN(POWEROFF)	; via firmware, will not return
#else
	BRK					; just in case...
	.asc	"{EXIT}", 0	; if managed
#endif

; place here the shell code, must end in RTS
shell:
#include "shell/SHELL"

; *** generic kernel routines, now in separate file 20150924 *** new filenames
#ifndef		LOWRAM
#include "api.s"
#else
#include "api_lowram.s"
#endif

; *** new, sorted out code 20150124 ***
; *** interrupt service routine ***

k_isr:
#include "isr/irq.s"

; default NMI-ISR is on firmware!
