; minimOS generic Kernel
; v0.5a8
; (c) 2012-2016 Carlos J. Santisteban
; last modified 20151014-1843
; revised 20160115 for commit with new filenames

; avoid standalone definitions
#define		KERNEL	_KERNEL

; uncomment in case of separate, downloadable jump & boot files
; should assume standalone assembly!!! (will get drivers anyway)
;#define		DOWNLOAD	_DOWNLOAD

; in case of standalone assembly
#ifndef		ROM
#include "options.h"	; machine specific
#include "macros.h"
#include "abi.h"		; ** new filename **
.zero
#include "zeropage.h"
.bss
#include "firmware/firmware.h"	; machine specific
#ifdef		DOWNLOAD
* = $0400				; safe address for patchable 2 kiB systems, change if required
#else
#include "sysvars.h"
#include "drivers.h"
user_sram = *
#include "drivers.s"	; don't assemble actual code, just labels
* = ROM_BASE			; just a placeholder, no standardised address
#endif
.text
#endif

; **************************************************
; *** kernel begins here, much like a warm reset ***
; **************************************************

#ifndef		FINAL
	_BRA warm				; in case somebody JMPs to kernel
	.asc	"<warm>"		; *** just for easier debugging ***
#endif

warm:
-kernel:			; defined also into ROM file, just in case is needed by firmware
	SEI				; shouldn't use macro, really
#ifdef	NMOS
	CLD				; not needed for CMOS
#endif

; install kernel jump table if not previously loaded, NOT for 128-byte systems
#ifndef	LOWRAM
#ifndef		DOWNLOAD
	LDA #<k_vec		; get table LSB (2+3)
	STA zpar
	LDA #>k_vec		; get table MSB (2+3)
	STA zpar+1
	_ADMIN(INSTALL)	; copy jump table (14...)
#endif
#endif

; install ISR code (as defined in "isr/irq.s" below)
	LDA #<k_isr		; get address LSB (2)
	STA zpar		; no need to know about actual vector location (3)
	LDA #>k_isr		; get address MSB (2+3)
	STA zpar+1
	_ADMIN(SET_ISR)	; install routine (14...)

; install optional NMI code (as defined in "isr/nmi.s" below)
	LDA #<k_nmi		; get address LSB (2)
	STA zpar		; no need to know about actual vector location (3)
	LDA #>k_nmi		; get address MSB (2+3)
	STA zpar+1
	_ADMIN(SET_NMI)	; install routine (14...)

; *****************************
; *** memory initialisation ***
; *****************************
; should be revised ASAP

#ifndef		LOWRAM
#ifndef		FINAL
	_BRA memo_label			; skip the markup!
	.asc	"<memo>"		; *** just for easier debugging ***
memo_label:
#endif

	LDA #' '			; unassigned space (2)
	LDX #MAX_LIST		; depending on RAM size, corrected 20150326 (2)
mreset:
		STA ram_stat, X		; set entry as unassigned, essential (4)
		DEX					; previous byte (2)
		BNE mreset			; leaves first entry alone (3/2, is this OK?)
	LDA #<user_sram		; get first entry LSB (2)
	STA ram_tab			; create entry (4)
	LDA #>user_sram		; same for MSB (2+4)
	STA ram_tab+1
	LDA #'F'			; set free entry (2+4)
	STA ram_stat
	LDA #0				; compute free RAM (2+2)
	SEC
	SBC #<user_sram		; substract LSB (2+4)
	STA ram_siz
	LDA himem			; get ram size MSB (4)
	SBC #>user_sram		; substract MSB (2)
	STA ram_siz+1		; entry is OK (4)
#endif

; ******************************************************
; intialise drivers from their jump tables! new 20150206
; optimised code with self-generated ID list 20150220
; new code disabling failed drivers 20150318
; ******************************************************
; systems with enough ram should create direct table!!!!!!!!!!!

#ifndef		FINAL
	_BRA dinit_label		; skip the markup!
	.asc	"<dinit>"		; *** just for easier debugging ***
dinit_label:
#endif

; set some labels, much neater this way
da_ptr	= locpt2		; pointer for indirect addressing, new CIN/COUT compatible 20150619
drv_aix = local3		; address index for, not necessarily PROPOSED, driver list, new 20150318, shifted 20150619

; driver full install is new 20150208
	_STZA dpoll_mx		; reset indexes, sorry for NMOS (4x4)
	_STZA dreq_mx
	_STZA dsec_mx
#ifdef LOWRAM
	_STZA drv_num		; single index of, not necessarily SUCCESSFULLY, installed drivers, updated 20150318
#else
	LDX #0				; reset index of direct table (2)
	TXA					; value to be stored (2)
dr_clear:
		STA drivers_pt+1, X		; clear MSB, since no driver is allowed in zeropage (4)
		INX						; next pointer (2+2)
		INX
		BNE dr_clear			; finish page (3/2)
#endif
	_STZA drv_aix
; first get the pointer to each driver table
dr_loop:
; get address index
		LDX drv_aix			; get address index (4)
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
			BPL dr_abort		; reject logical devices (2/3)

#ifndef	LOWRAM
; new faster driver list 20151014
		ASL					; use retrieved ID as index (2+2)
		TAY
		LDA drivers_pt+1, Y		; check whether in use (5?)
			BNE dr_abort			; already in use, don't register! (2/3)
		LDA da_ptr				; get driver table LSB (3)
		STA drivers_pt, Y		; store in table (5?)
		LDA da_ptr+1			; same for MSB (3+5?)
		STA drivers_pt+1, Y
#else
#ifdef	SAFE
; ** let's check whether the ID is in already in use **
		LDX #0			; reset index (2)
		BEQ dr_limit	; check whether has something to check, no need for BRA (3)
dr_scan:
			CMP drivers_id, X	; compare with list entry (4)
				BEQ dr_abort		; already in use, don't register! (2/3)
			INX					; go for next (2)
dr_limit:	CPX drv_num			; all done? (4)
			BNE dr_scan			; go for next (3/2)
; ** end of check **
#else
		LDX drv_num			; retrieve single offset (4) *** already set because of the previous check, if done
#endif
		STA drivers_id, X	; store in list, now in RAM (4)
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
		INC drv_num		; update SINGLE index (6)
#endif
; in order to keep drivers_ad in ROM, can't just forget unsuccessfully registered drivers...
; in case drivers_ad is *created* in RAM, dr_abort could just be here
		INC drv_aix		; update ADDRESS index, even if unsuccessful (5)
		JMP dr_loop		; go for next (3)
dr_abort:
#ifdef	LOWRAM
		LDX drv_num			; get failed driver index (4)
		LDA #DEV_NULL		; make it unreachable, any positive value (logic device) will do (2)
		STA drivers_id, X	; delete older value (4)
#else
		LDY #D_ID			; offset for ID (2)
		LDA (da_ptr), Y		; get ID code (5)
			BPL dr_next			; nothing to delete (2/3)
		ASL					; use retrieved ID as index (2+2)
		TAX
		_STZA drivers_pt+1, X	; discard it (4)
#endif
		_BRA dr_next			; go for next (3)

dr_icall:
	LDY #D_INIT+1		; get MSB first (2)
dr_call:				; *** generic driver call, pointer set at locpt2, Y holds table offset+1 *** new 20150610
#ifndef	NMOS
	LDA (da_ptr), Y		; destination pointer (5)
	TAX					; store temporarily (2) new '816 compatible code 20151014
	DEY					; go for LSB (2)
	LDA (da_ptr), Y		; repeat procedure (5)
	BNE dr_nowrap		; won't mess with MSB (3/2)
		DEX					; will carry (2) or 
dr_nowrap:
	_DEC				; RTS will go one less (2)
	PHX					; push MSB -- no NMOS macro!!!!! (3)
	PHA					; push LSB (3)
#else
	DEY					; get LSB first
	LDA (da_ptr), Y
	TAX					; store temporarily in X
	INY					; go for MSB in A
	LDA (da_ptr), Y
	CPX #0				; check whether wraps or not
	BNE dr_nowrap
		_DEC
dr_nowrap:
	DEX					; RTS will go one less
	PHA					; push address
	_PHX
#endif
	RTS					; the actual COMPATIBLE jump (6)

dr_ok:					; all drivers init'd
#ifdef	LOWRAM
	LDX drv_num			; retrieve single index (4)
	_STZA drivers_id, X	; terminate list, and we're done! (4)
#endif

; **********************************
; ********* startup code ***********
; **********************************

#ifndef		FINAL
	_BRA start_label		; skip the markup!
	.asc	"<start>"		; *** just for easier debugging ***
start_label:
#endif

; reset several remaining flags
	_STZA cin_mode	; reset binary mode flag, new 20150618

; *** set default SIGTERM handler for single-task systems, new 20150514 ***
#ifndef		MULTITASK
	LDA #<k38_kill	; get default routine address LSB
	STA stt_handler	; store in new system variable
	LDA #>k38_kill	; same for MSB
	STA stt_handler+1
#endif

; **********************************
; original startup code, revise ASAP ****************************
; **********************************

; *** set default I/O device *** REVISE ASAP
	LDA #DEV_LED	; LED-keypad, new constant 20150324
	STA default_out	; should check some devices
	STA default_in

; *** interrupt setup no longer here, firmware did it! *** 20150605
	_CLI			; enable interrupts

; say hello! *** revise ASAP
	LDA #<hello		; LSB of the string
	STA z10
	LDA #>hello		; MSB
	STA z10+1
	LDY #0			; default device, let the kernel get it!
	_KERNEL(STRING)	; print the message

; ******************************
; **** launch monitor/shell ****
; ******************************

#ifndef		FINAL
	_BRA shell				; skip the markup!
	.asc	"<shell>"		; *** just for easier debugging ***
#endif

; so far, shell is a post-POST task only!
shell:
#include "shell.s"
	BRK				; just in case...

hello:
	.asc "HOLA", 13, 0	; startup text

; *** generic kernel routines, now in separate file 20150924 *** new filenames
#ifndef		LOWRAM
#include "api.s"
#else
#include "api_lowram.s"
#endif

; *** new, sorted out code 20150124 ***
; *** interrupt service routine ***

#ifndef		FINAL
	.asc	"<isr>"		; *** just for easier debugging ***
#endif

k_isr:
#include "isr/irq.s"

; *** non-maskable interrupt handler ***
; must begin with 'UNj*'

#ifndef		FINAL
	.asc	"<nmi>"		; *** just for easier debugging ***
#endif

k_nmi:
#include "isr/nmi.s"

