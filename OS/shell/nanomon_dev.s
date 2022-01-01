; nanomon16 scratch file
; (c) 2019-2022 Carlos J. Santisteban

; *** original code is 12b *** GRAND TOTAL 30 bytes
	LDA 8, S			; stacked Y
	STA z_y
	LDA 10, S			; stacked X
	STA z_x
	LDA 12, S			; stacked A
	STA z_acc
; minimal status with new offsets *** original code is 14b *** +7 for TSX et al
	LDA 15, S			; get stacked PC
	STA z_addr			; update current pointer
	.as: .xs: SEP #$30	; *** make sure all in 8-bit ***
	LDA 17, S			; bank address too
	STA z_addr+2
	LDA 14, S			; get stacked PSR
	STA z_psr			; update value
; should keep stacked Data Bank register *** original code is 4b ***
	LDA 7, S			; stacked B
	STA z_b
#else
	PHD					; eeeeeeeeeeeeeeeeeeeek *** initial 4b *** GRAND TOTAL 20 bytes
	JSR njs_regs		; keep current state, but that PSR is not valid
; could save some bytes by switching to 16-bit... *** original code is 16b ***
	LDA 1, S			; get stacked PSR
	STA z_psr			; update value
	LDA 2, S			; get stacked PC
	STA z_addr			; update current pointer
	LDA 3, S
	STA z_addr+1
	LDA 4, S
	STA z_addr+2
; *** alternative for the above, in 16-bit mode ***
/*
7	B
8	Y
9	·
10	X
11	·
12	A
13	·
14	P
15	PC.L
16	PC.H
17	PC.Bank
*/
