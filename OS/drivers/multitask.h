; static variables for software multitasking module for minimOS
; v0.5a4
; (c) 2015 Carlos J. Santisteban
; last modified 20150611-1250

mm_qcnt		.byt	0				; quantums to wait for
mm_pid		.byt	0				; current PID
mm_flags	.dsb	MAX_BRAIDS		; status list
mm_term		.dsb	2 * MAX_BRAIDS	; table of TERM handlers, new 20150325
mm_treq		.dsb	MAX_BRAIDS		; table of SIGTERM requests, new 20150611
mm_sfsiz	.byt	3				; space used by the stackframe below, new 20150521
mm_stack	.dsb	3				; special context info for stack frame, could be larger, new 20150507

#ifndef		AUTOBANK
mm_context	.dsb	256 * MAX_BRAIDS	; context copy area, not needed with hardware-assisted multitasking
#endif

