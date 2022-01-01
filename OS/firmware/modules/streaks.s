; debug module
; streaks on Durango-X screen
; (c) 2021-2022 Carlos J. Santisteban

.(
streaks:
	LDA $DF80				; continuously invert screen
	EOR #$40
	STA $DF80
	LDX #5					; timing value, 4 is completely standstill
sloop:
		INX
		BNE sloop
	BEQ streaks
.)
