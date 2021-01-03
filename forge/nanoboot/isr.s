; nanoBoot ISR for 6502, v0.3a2
; (c) 2018-2021 Carlos J. Santisteban
; last modified 20201227-0149

nb_irq:
; *** this modifies A (and stored P), thus PHA is needed on NMI for proper operation ***
; since this has to set I flag anyway, clear stored C as received bit value
	PLA				; saved status... (4)
	ORA #%00000101	; ...now with I set *AND* C set (2)
	PHA				; restore all (A changed) (3)
	RTI				; (6) whole routine takes only 15 clocks
