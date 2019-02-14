; static variables for 65816 software multitasking module for minimOS·16
; v0.6a3
; (c) 2016-2019 Carlos J. Santisteban
; last modified 20190214-1227

mm_pid		.byt	0				; current PID
mm_fg		.byt	0				; *** new foreground task
; no longer using mm_sfsiz & mm_stack, as per new TS_INFO output format!
; but again gets mm_term here, together with specific mm_bank
mm_term		.dsb	MAX_BRAIDS*2	; not worth 24-bit misaligned pointers
; new interleaved flags and SIGTERM banks, MUST use EVEN PIDs!!!
mm_flags	.dsb	MAX_BRAIDS		; status list, integrated with mm_treq but NO LONGER interleaved with mm_stbank
mm_stbank	.dsb	MAX_BRAIDS		; NOT worth interleaving, even PIDs only!

; *** hardware multitasking will not use these ***
#ifndef	AUTOBANK
; 65816-specific context areas, must be page-aligned!
	.dsb	$100*((* & $FF) <> 0) - (* & $FF), $FF	; page alignment!!! eeeeek
mm_context	.dsb	512*MAX_BRAIDS	; direct-page AND stack areas
mm_stacks	= mm_context + 256		; interleaved stack areas, 816-exclusive
#endif
