; minimOS BRK handler
; v0.5a1
; (c) Carlos J. Santisteban
; based on 0.4rc
; last modified 20150210-0952

; *** do something to tell the debugger it's from BRK, not NMI...
	LDA #<brk_txt		; string address load
	STA sysptr			; new label 20150124
	LDA #>brk_txt
	STA sysptr+1
;	JMP debug			; debug somehow...
brk_txt:
	.asc "BRK ", 0		; splash text string
