; filesystem fopen routine for minimOS 0.5a1, seems *OBSOLETE* since 2015
; (c) 2015-2021 Carlos J. Santisteban
; last modified 20150306-1422

; *** fopen alternative code ***
; first of all, assing device number (if available)
	LDX #0			; reset index
fo_getdev:
		LDA fs_devs, X	; get table entry
			BEQ fo_avail	; found an empty one
		INX				; go for next
		CPX #MAX_FILES	; until the end of list
		BNE fo_getdev
	_ERR(FULL)		; all available files are in use
fo_bad:
	_ERR(INVALID)	; wrong argument
fo_avail:
	TYA				; *** don't know what to assign, mode flag for a start ***
	BEQ fo_bad		; wrong mode, won't assign anything
	STA fs_devs, X
	TXA				; the returned value depends on this
	CLC
	ADC #64			; assume first file-dev is 64
	STA fs_ret		; save in context
; get PID-specific pointers (from the original version)
	LDA #<fs_masks			; get LSB from masks *pack* (2)
	STA fs_mask				; store pointer (3)
	LDA #>fs_masks			; get base MSB (2)
	CLC						; prepare for adding (put SBC #0 too if PIDs are from 1) (2 (+2))
	ADC mm_pid				; select appropriate bank from PID (4)
	STA fs_mask+1			; store corrected pointer (3)
; let's have a look to the filename...
	LDY #0
