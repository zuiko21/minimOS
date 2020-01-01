; static variables for software multitasking module for minimOS
; v0.6a4
; (c) 2015-2020 Carlos J. Santisteban
; last modified 20190215-1010

#define	MX_BRAID	4

mm_pid		.byt	0				; current PID
mm_fg		.byt	0				; *** new foreground task
mm_flags	.dsb	MX_BRAID		; status list, now integrated with mm_treq
mm_term		.dsb	MX_BRAID*2		; space for TERM pointers, no longer integrated in sysvars!
; no longer using mm_sfsiz & mm_stack, as per new TS_INFO output format!
; mm_qcnt no longer needed as per new driver format

; only software multitask will enable this
#ifndef		AUTOBANK
; were 65816-specific context areas, do not need to be page-aligned!
mm_context	.dsb	256 * MX_BRAID	; context copy area, not needed with hardware-assisted multitasking
mm_stacks	.dsb	256 * MX_BRAID	; stack areas, new on 6502 20161116
#endif

