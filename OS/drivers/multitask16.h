; static variables for 65816 software multitasking module for minimOS·16
; v0.5.1a4
; (c) 2016-2018 Carlos J. Santisteban
; last modified 20180205-0935

mm_pid		.byt	0				; current PID
mm_flags	.dsb	MAX_BRAIDS		; status list, might be integrated with mm_treq???
; no longer using mm_sfsiz & mm_stack, as per new TS_INFO output format!
; but again gets mm_term here, together with specific mm_bank
mm_term		.dsb	MAX_BRAIDS*2	; perhaps thru 24-bit misaligned pointers!
mm_stbank	.dsb	MAX_BRAIDS


; *** hardware multitasking will not use these ***
#ifndef	AUTOBANK
; 65816-specific context areas, must be page-aligned!
	.dsb	$100*((* & $FF) <> 0) - (* & $FF), $FF	; page alignment!!! eeeeek
mm_context	.dsb	256 * MAX_BRAIDS	; direct-page areas
mm_stacks	.dsb	256 * MAX_BRAIDS	; stack areas, 816-exclusive
#endif
