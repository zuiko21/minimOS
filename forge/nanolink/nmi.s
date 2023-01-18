; nanoLink NMI handler for transparent reception
; (c) 2023 Carlos J. Santisteban
; last modified 20230118-1418

; *****************************************
; *** NMI handler for nanoLink receiver ***
; input
;	sys_sp	= 8 to enable, 0 to disable
;	sysptr	= pointer to receive buffer
; *****************************************

#ifndef	NANOLINK
#define	NANOLINK
; specific nanoLink limit *** new ***
linkend	= $FA				; address of LAST byte to be received
; standard minimOS interrupt-reserved variables
sysptr	= $FC				; download buffer pointer
systmp	= $FE				; temporary bit shifting
sys_sp	= $FF				; bit counter, set to 8 to enable, set to zero to disable
; standard minimOS firmware interrupt vector, may set in ZP for performance
fw_irq	= $0200
; hardware definitions
-IOAie	= $DFA0				; Durango-X interrupt enable
#endif

rcv_nmi:
.(
	STZ IOAie				; disable hardware interrupt ASAP (4+ACK)
	PHA						; save reg (3, total 7+)
	LDA sys_sp				; check current state (optional, usually 5t, total 12+)
		BEQ disabled		; do not disturb operation if disabled
	LDA fw_irq+1
	PHA
	LDA fw_irq
	PHA						; save previous IRQ vector (14, 26+)
	LDA #<rcv_irq
	STA fw_irq
	LDA #>rcv_irq
	STA fw_irq+1			; point to specific nanoLink IRQ handler (12, 38+)
	CLC						; ready to receive carry if bit=1 (2, 40+)
	CLI						; enable interrupt... (2, 42+)
; *** IRQ is executed if bit is 1, takes 22t (15t + ACK) ***
; MUST return with interrupts disabled in stacked P!
	SEI						; ...and disable it, in case no IRQ was called! (2, 44+ if 0, 66+ if 1)
	PLA
	STA fw_irq
	PLA 
	STA fw_irq+1			; restore interrupt vector (16, 60+ if 0, 82+ if 1)
	LDA #1					; odd value to enable interrupts (2, 62+ if 0, 84+ if 1) **** check
	DEC sys_sp				; one bit less to go (5, 67+ if 0, 89+ if 1)
	BNE no_byte				; not yet complete (usually 3, 70+ if 0, 92+ if 1) (*or 2, 69+ if 0, 91+ if 1)
		LDA systmp			; get read value (*3, 72+ if 0, 94+ if 1)
		STA (sysptr)		; and store into buffer, CMOS only (*5, 77+ if 0, 99+ if 1)
; original version, checking against last address (typically adds 9 or 18) *** MAY MOVE AFTER INCREMENT ***
		LDA sysptr
		CMP linkend			; time to finish reception?
		BNE nextbyte		; not yet
			LDA sysptr+1	; check MSB too
			SEC
			SBC linkend+1	; will be zero at the end
			BEQ nl_end		; and will disable further reception
nextbyte:
		LDA #8				; reset value for bit counter (*2, 79++ if 0, 101++ if 1)
		INC sysptr			; advance into buffer (*5, 84++ if 0, 106++ if 1)
		BNE no_wrap			; (*typically 3, 87++ if 0, 109++ if 1) (**or 2, 86++ if 0, 108++ if 1)
; ** ** ** in case check is done only every page crossing, insert code around here ** ** **
			INC sysptr+1	; page crossing (**5, 91++ if 0, 113++ if 1)
no_wrap:
; ** ** ** transfer limit seems best suited here ** ** ** CONTINUE TIMING more or less here
nl_end:
		STA sys_sp			; eeeeek (*3, 90++ if 0, 112++ if 1) (**97+ if 0, 124+ if 1), timing OK?
		DEC					; correction needed to allow 0 as disable function (*2, 95+ if 0, 122+ if 1) (**99+ if 0, 126+ if 1)
no_byte:
	STA IOAie				; odd value reenables interrupt (4, 77+ if 0, 104+ if 1) (*99+ if 0, 126+ if 1) (**103+ if 0, 130+ if 1)
disabled:
	PLA						; (4+6, 87+ if 0, 114+ if 1) (*109+ if 0, 136+ if 1) (**113+ if 0, 140+ if 1)
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
