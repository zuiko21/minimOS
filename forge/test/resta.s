; testing perdita subtraction

	* = $1000

	SEI
	CLD
	STZ $DFA0
	STZ $DF94		; set VSP hex mode
	CLC
	PHP
	PLA
	STA $DF93		; should show C clear (Even)
	SEC
	PHP
	PLA
	STA $DF93		; should show C set (odd)
	LDA #9
	SBC #5
	PHP
	STA $DF93		; result is 4
	PLY
	STY $DF93		; C should be set (odd)
	LDA #5
	SBC #9
	PHP
	STA $DF93		; result is -4?
	PLY
	STY $DF93		; C should be clear (even)
	LDY #1
	STY $DFA0		; turn off ERROR LED
lock:
	BRA lock
