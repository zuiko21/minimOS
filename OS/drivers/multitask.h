; static variables for software multitasking module for minimOS
; v0.5a5
; (c) 2015-2016 Carlos J. Santisteban
; last modified 20160406-0908

mm_qcnt		.byt	0				; quantums to wait for
mm_pid		.byt	0				; current PID
mm_flags	.dsb	MAX_BRAIDS		; status list, might be integrated with mm_treq???
mm_treq		.dsb	MAX_BRAIDS		; table of SIGTERM requests, new 20150611
mm_sfsiz	.byt	3				; space used by the stackframe below, new 20150521
mm_stack	.dsb	3				; special context info for stack frame, could be larger, new 20150507
; no longer defining mm_term, now integrated on sysvars.h

; only software multitask will enable this
#ifndef		AUTOBANK
mm_context	.dsb	256 * MAX_BRAIDS	; context copy area, not needed with hardware-assisted multitasking
#endif

