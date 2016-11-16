; static variables for software multitasking module for minimOS
; v0.5a6
; (c) 2015-2016 Carlos J. Santisteban
; last modified 20161116-1020

mm_pid		.byt	0				; current PID
mm_flags	.dsb	MAX_BRAIDS		; status list, might be integrated with mm_treq???
mm_treq		.dsb	MAX_BRAIDS		; table of SIGTERM requests, new 20150611
; no longer using mm_sfsiz & mm_stack, as per new TS_INFO output format!
mm_qcnt		.byt	0				; quantums to wait for (6502 specific)
; no longer defining mm_term, now integrated on sysvars.h

; only software multitask will enable this
#ifndef		AUTOBANK
; were 65816-specific context areas, do not need to be page-aligned!
mm_context	.dsb	256 * MAX_BRAIDS	; context copy area, not needed with hardware-assisted multitasking
mm_stacks	.dsb	256 * MAX_BRAIDS	; stack areas, new on 6502 20161116
#endif

