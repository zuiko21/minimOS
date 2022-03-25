; firmware module for minimOS
; Durango-X interrupt & beeper shutoff
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20220326-0032

.(
	LDA #$38				; colour mode, non-inverted, screen 3, will disable hard interrupts and beeper
	STA IO8attr				; set video mode...
	STA IOAie				; ...and disable interrupts 
; might add a brief memory addressing test in order to tell if all video modes are supported!
; MA8-14 are always fine (in case of enough RAM) no matter the video option
; MA0-7 will fail if current mode is NOT supported -- try the usual $55/AA on these
#ifdef	SAFE
	LDA #%01010101			; initial pattern
	STA $1335				; contents indicate offset, page seems always OK
	ASL						; shift one bit, alternating most
	STA $13CA				; second test position
	CMP $13CA				; should be fine
		BNE ns_mode
	LSR						; back to initial pattern, save some bytes
	CMP $1335				; compare to initial storage
	BEQ mode_ok
ns_mode:
		LDA #$B0			; if colour does not work, hires should
		STA IO8attr
mode_ok:
#endif
.)
