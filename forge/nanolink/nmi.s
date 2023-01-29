; nanoLink NMI handler for transparent reception
; (c) 2023 Carlos J. Santisteban
; last modified 20230129-0151

; *****************************************
; *** NMI handler for nanoLink receiver ***
; input
;	sys_sp	= 8 to enable, 0 to disable
;	sysptr	= pointer to receive buffer
; *****************************************

; timing info
; x/y	values for sending 0/1
; +		add NMI acknowldge (7 clocks + end of previous instruction)
; *		did end byte, no page crossing
; **	page crossing after ending byte
; ***	same LSB as limit, did not cross page
; ****	same LSB as limit with page crossing

#ifndef	NANOLINK
#define	NANOLINK
; specific nanoLink limit *** new ***
linktop	= $FA				; address of receiving limit (non-inclusive)
; standard minimOS interrupt-reserved variables
sysptr	= $FC				; download buffer pointer
systmp	= $FE				; temporary bit shifting
sys_sp	= $FF				; bit counter, set to 8 to enable, set to zero to disable
; standard minimOS firmware interrupt vector, may set in ZP for performance
fw_irq	= $0200
#endif
; hardware definitions
-IOAie	= $DFA0				; Durango-X interrupt enable

rcv_nmi:
.(
	PHA						; save reg (3, total 7+)
	LDA sys_sp				; check current state (optional, usually 5t, total 12+)
		BEQ disabled		; do not disturb operation if disabled
	STZ IOAie				; disable hardware interrupt ASAP (4+ACK)
	LDA fw_irq+1
	PHA
	LDA fw_irq
	PHA						; save previous IRQ vector (14, 26+)
	LDA #<rcv_irq
	STA fw_irq
	LDA #>rcv_irq
	STA fw_irq+1			; point to specific nanoLink IRQ handler (12, 38+)(* * may save 4t if fw_irq on ZP * *)
	CLC						; ready to receive carry if bit=1 (2, 40+)
	CLI						; enable interrupt... (2, 42+)
; *** IRQ is executed if bit is 1, takes 22t (15t + ACK) ***
; MUST return with interrupts disabled in stacked P!
	SEI						; ...and disable it, in case no IRQ was called! (2, 44+ if 0, 66+ if 1)
	ROL systmp				; EEEEEEK, MSb first like SS-22 (5)
	PLA
	STA fw_irq
	PLA 
	STA fw_irq+1			; restore interrupt vector (16, 60+ if 0, 82+ if 1)
	LDA #1					; odd value to enable interrupts (2, 62+ if 0, 84+ if 1)
	DEC sys_sp				; one bit less to go (5, 67+ if 0, 89+ if 1)
	BNE no_byte				; not yet complete (usually 3, 70+ if 0, 92+ if 1) (*or 2, 69+ if 0, 91+ if 1)
		LDA systmp			; get read value (*3, 72+ if 0, 94+ if 1)
		STA (sysptr)		; and store into buffer, CMOS only (*6, 78+ if 0, 100+ if 1)
		INC sysptr			; advance into buffer (*5, 83+ if 0, 105+ if 1)
		BNE no_wrap			; (*typically 3, 86+ if 0, 108+ if 1) (**or 2, 85+ if 0, 107+ if 1)
; ** ** ** in case check is done only every page crossing, insert code around here ** ** **
			INC sysptr+1	; page crossing (**5, 90+ if 0, 112+ if 1)
no_wrap:
; ** ** ** transfer limit seems best suited here ** ** **
		LDA sysptr
		CMP linktop			; time to finish reception? (3+3, *92/114+, **96/118+) 
		BNE nextbyte		; not yet (3, *95/117+, **99/121+)(***or 2, 94/116+, ****98/120+)
			LDA sysptr+1	; check MSB too
			SEC
			SBC linktop+1	; will be zero at the end (3+2+3=8, ***102/124+, ****106/128+) 
			BEQ nl_end		; and will disable further reception (usually 2, ***105/127+, ****109/131+)
nextbyte:
		LDA #8				; reset value for bit counter (2, *97/119+, **101/123+, ***107/129+, ****111/133+)
nl_end:
		STA sys_sp			; eeeeek (3, *100/122+, **104/126+, ***110/132+, ****114/136+)
		DEC					; correction needed to allow 0 as disable function (2, *102/124+, **106/128+, ***112/134+, ****116/138+)
no_byte:
	STA IOAie				; odd value reenables interrupt (4, 74/96+, *106/128+, **110/132+, ***116/138+, ****120/142+)
disabled:
	PLA						; (4+6, 84/106+ single bit, 116/138+ last bit, 120/142+ page cross, 126/148+ check limit, 130/152+ limit while crossing)
	RTI

; *************************************************
; *** IRQ handler for nanoLink *** total 15t+7t ACK
; *************************************************
rcv_irq:
	PLA						; get saved PSR, A was meaningless (4)
	ORA #%00000101			; set Carry *AND* disable saved interrupts (2)
	PHA						; restack corrected PSR (3)
	RTI						; (6)
.)
