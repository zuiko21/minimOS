; firmware module for minimOS
; Durango-X ROMcheck interface
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20211227-0037

.(
	LDX #>ROM_BASE			; begin of test
#ifndef	DOWNLOAD
	LDY #0					; test usually until the end of map, or...
#else
	LDY #$60				; ...VRAM start
#endif
	LDA #>IO_BASE			; page to be skipped (if in ROM)
	STX st_pg
	STY af_pg
	STA skipg
	JSR chk_sum				; direct firmware call, of course
	BCC f16ok				; ROM checked out OK...
		LDA #1				; or turn LED off once, cyclically
		JMP lock			; low-level panic routine
f16ok:
.)
