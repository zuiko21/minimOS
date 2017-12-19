; static variables for software multitasking module for minimOS
; v0.5.1a4 *** bumped ***
; (c) 2015-2017 Carlos J. Santisteban
; last modified 20171219-1106

#define	MX_BRAID	4

mm_pid		.byt	0				; current PID
mm_flags	.dsb	MX_BRAID		; status list, might be integrated with mm_treq???
;mm_treq	.dsb	MX_BRAID		; table of SIGTERM requests, new 20150611 *** integrated on mm_flags 161117
; no longer using mm_sfsiz & mm_stack, as per new TS_INFO output format!
mm_qcnt		.byt	0				; quantums to wait for (6502 specific)
; no longer defining mm_term, now integrated on sysvars.h

; only software multitask will enable this
#ifndef		AUTOBANK
; were 65816-specific context areas, do not need to be page-aligned!
mm_context	.dsb	256 * MX_BRAID	; context copy area, not needed with hardware-assisted multitasking
mm_stacks	.dsb	256 * MX_BRAID	; stack areas, new on 6502 20161116
#endif

