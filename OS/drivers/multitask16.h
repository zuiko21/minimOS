; static variables for 65816 software multitasking module for minimOS·16
; v0.5a1
; (c) 2016 Carlos J. Santisteban
; last modified 20161003-0839

mm_pid		.byt	0				; current PID
mm_flags	.dsb	MAX_BRAIDS		; status list, might be integrated with mm_treq???
mm_treq		.dsb	MAX_BRAIDS		; table of SIGTERM requests, new 20150611
; *** revise these ***
mm_sfsiz	.byt	3				; space used by the stackframe below, new 20150521
mm_stack	.dsb	3				; special context info for stack frame, could be larger, new 20150507

; no longer defining mm_term, now integrated on sysvars.h

; 65816-specific context areas, must be page-aligned!
			.align	256
mm_context	.dsb	256 * MAX_BRAIDS	; direct-page areas
mm_stacks	.dsb	256 * MAX_BRAIDS	; stack areas, 816-exclusive
