; nanoBoot ISR for 6502, v0.3a1
; (c) 2018-2020 Carlos J. Santisteban
; last modified 20201226-1235

nb_irq:
; *** this modifies A (and stored P), thus PHA is needed on NMI for proper operation ***
; since this has to set I flag anyway, clear stored C as received bit value
	PLA				; saved status... (4)
	ORA #%00000100	; ...now with I set... (2)
	AND #%11111110	; ...and C clear (2)
	PHA				; restore all (A changed) (3)
	RTI				; (6) whole routine takes only 17 clocks
