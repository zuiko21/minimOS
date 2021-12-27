; firmware module for minimOS
; Durango-X interrupt & beeper shutoff
; (c) 2021 Carlos J. Santisteban
; last modified 20211226-1540

	LDA #$38				; colour mode, non-inverted, screen 3, will disable ahrd interrupts and beeper
	STA IO8attr				; set video mode...
	STA IOAie				; ...and disable interrupts 
; might add a brief memory addressing test in order to tell if all video modes are supported!
