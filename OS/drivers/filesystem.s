; filesystem pseudo-driver module for minimOS
; v0.5a1
; (c) 2015-2016 Carlos J. Santisteban
; last modified 20150323-1104
; revised 20160928

; *** put here standalone includes ***
#ifndef		DRIVERS
#include "options.h"
#include "macros.h"
#include "abi.h"		; new filename
.zero
#include "zeropage.h"
.bss
#include "firmware/firmware.h"
#include "sysvars.h"
; specific header for this driver
#include "drivers/filesystem.h"
.text
#endif

; *** begins with sub-function addresses table ***
	.byt	FILESYSTEM	; D_ID, new format 20150323, TBD
	.byt	A_COUT		; no interrupts, output only, no block transfers, non-relocatable (NEW)
	.word	fsc_init	; initialize data structures
	.word	fsc_none	; nothing periodic to do
	.word	fsc_none	; no interrupts to set
	.word	fsc_none	; no input
	.word	fsc_go		; the command interface
	.word	fsc_none	; no need for 1-second interrupt
	.word	fsc_none	; no block input
	.word	fsc_none	; no block output
	.word	fsc_bye		; shutdown procedure, TBD
	.word	fsc_info	; NEW info string
	.byt	0			; reserved for D_MEM

; *** info string ***
fsc_info:
	.asc	"FileSystem module v0.5a1", 0

; calling interface
fsc_go:
	LDX zpar			; get subcommand
	_JMPX(fsc_table)	; jump to proper routine

fsc_table:
	.word	fsc_open
	.word	fsc_seek
	.word	fsc_tell
	.word	fsc_close
	.word	fsc_flush
; more to come**************

fsc_init:
; *** initialise here fstab and other variables from filesystem.h ***

fsc_bye:
; *** unmount all volumes et al, or will the hardware drivers do it? ***

; ***** the filesystem functions themselves *****
; *** fopen ***
fsc_open:
; get PID-specific pointers
	LDA #<fs_masks			; get LSB from masks *pack* (2)
	STA fs_mask				; store pointer (3)
	LDA #>fs_masks			; get base MSB (2)
	CLC						; prepare for adding (put SBC #0 too if PIDs are from 1) (2 (+2))
	ADC mm_pid				; select appropriate bank from PID (4)
	STA fs_mask+1			; store corrected pointer (3)
; investigate filename, either absolute or relative
	LDY #0					; get first byte (2)
	LDA (fs_filename), Y	; from parameter (5)
	CMP #'/'				; absolute path? (2)
	BNE fo_rel				; don't set volume (2/3)
		INY						; skip root bar (2)
		JSR fo_setvol			; set current volume... temporarily (6...)
		INY						; skip trailing bar (2)
		BNE fo_gbar			; continue scanning path, no need for BRA (3)
fo_rel:
	CMP #'~'				; volume root? (2)
	BEQ fo_file				; reset working directory (2/3)
fo_gbar:
		JSR fo_scanb			; look for the last bar (store it in fs_noff) (6...)
		LDY #1					; reset index (2)
		BCC fo_tmpth			; bar found, make mask from path (2/3)
fo_gwd:
			LDA (fs_wd), Y			; get char from pwd (5)
				BEQ fo_file				; done (trailing bar is expected) (2/3)
			STA (fs_mask), Y		; store into mask (5+2)
			INY
			_BRA fo_gwd				; next char (3)
fo_tmpth:
			LDA (fs_filename), Y	; get char from path (5)
			STA (fs_mask), Y		; store into mask (5+2+2)
			TYA
			INY
			CMP fs_noff				; until last bar (included) (3+3/2)
			BNE fo_tmpth
fo_file:
	LDA #0					; no indirect STZ (2)
	STA (fs_mask), Y		; terminate temporary mask (5)
; now look for the file, currently hardwired to ROMdisk format!
	STY fs_noff				; store position of first character in name (3)
; **init more ROMdisk things
fo_scanf:
; search for the file in data structure
		JSR fo_entry			; get next entry (6...)
			BCS fo_err				; no more entries (2/3)
		LDY fs_noff				; offset for desired filename (3)
		LDA #8					; offset for filename TBD (2)
		STA fs_ncur				; position into stored filename (3)
fo_ncmp:
			LDA (fs_filename), Y	; get filename char (5)
				BEQ fs_found			; search ended (2/3)
			STA fs_tmp				; store temporarily (3)
			TYA						; save this offset (2+2)
			TAX
			LDY fs_ncur				; get the other offset (3)
			LDA (fs_bufptr), Y		; compare with stored filename (5+3)
			CMP fs_tmp
				BNE fo_scanf			; not the same (2/3)
			INC fs_ncur				; advance to next char (5)
			TXA						; restore other offset (2+2)
			TAY
			INY						; advance it too (2)
			BNE fo_ncmp			; keep comparing, best not use BRA (3/2)
fo_err:
	_DR_ERR(N_FOUND)			; file not found
fo_found:
; time to assign a device number to this file...**********************best to assign device first, then locate file within its own data structures???
	LDX #0					; reset index
fo_getdev:
		
	INC fs_bufptr+1			; access to data area ***hardwired to ROMdisks
	

; routine for locating the last bar on pathname (where the proper filename starts)
fo_scanb:
	_PHY					; save this reg
	LDY #$FF				; minus one for safety
fosb_loop:
		INY						; next char
		LDA (fs_filename), Y	; get char in filename
		BNE fosb_loop			; until terminator
fosb_back:
		DEY						; go back one
		CPY #$FF				; check limit, BMI won't allow 255-char pathnames
			BEQ fosb_nf				; no bar was found
		LDA (fs_filename), Y	; get char
		CMP #'/'				; is it bar?
		BNE fosb_back			; backoff otherwise
	STY fs_noff				; store result
	CLC						; found bar
	RTS
fosb_nf:
	SEC						; carry means no bar was found
	RTS

; *** fseek ***
fsc_seek:

; *** ftell ***
fsc_tell:

; *** fclose ***
fsc_close:

; *** fflush ***
fsc_flush:

fsc_none:
	RTS			; just a dummy placeholder

; *** optional filesystem calls, now implemented as macros! ***
; all of them using all registers, locals[4] and calling COUT

; _FILESYS(FOPEN)
; Y<- mode, zpar3.w <- pointer to path, Y -> device number, C -> error

; _FILESYS(FSEEK)
; ** interface TBD **
; Y <- file stream

; _FILESYS(FTELL)
; ** interface TBD **
; Y <- file stream

; _FILESYS(FCLOSE)
; Y <- file stream

; _FILESYS(FFLUSH)
; Y <- file stream
