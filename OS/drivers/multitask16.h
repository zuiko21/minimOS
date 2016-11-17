; static variables for 65816 software multitasking module for minimOS·16
; v0.5.1a3
; (c) 2016 Carlos J. Santisteban
; last modified 20161117-1351

mm_pid		.byt	0				; current PID
mm_flags	.dsb	MAX_BRAIDS		; status list, might be integrated with mm_treq???
;mm_treq	.dsb	MAX_BRAIDS		; table of SIGTERM requests, new 20150611 *** integrated on mm_flags 161117
; no longer using mm_sfsiz & mm_stack, as per new TS_INFO output format!
; no longer defining mm_term, now integrated on sysvars.h

; *** hardware multitasking will not use these ***
#ifndef	AUTOBANK
; 65816-specific context areas, must be page-aligned!
; .align does not seem to work!
mm_context	.dsb	256 * MAX_BRAIDS	; direct-page areas
mm_stacks	.dsb	256 * MAX_BRAIDS	; stack areas, 816-exclusive
#endif
