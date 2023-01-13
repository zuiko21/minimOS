; nanoLink NMI handler for transparent reception
; (c) 2023 Carlos J. Santisteban
; last modified 20230113-0955

; *****************************************
; *** NMI handler for nanoLink receiver ***
; input
;	sys_sp	= 8 to enable, 0 to disable
;	sysptr	= pointer to receive buffer
; *****************************************
.(
nmi:
	STZ IOAie				; disable hardware interrupt ASAP (4 after NMI acknowledge)
	PHA						; save reg (3, total 7+ACK)
	LDA sys_sp				; check current state (optional, usually 5t)
		BEQ disabled		; do not disturb operation if disabled
	ASL systmp				; make room into received value (5, 12+ACK)
	LDA fw_irq+1
	PHA
	LDA fw_irq
	PHA						; save previous IRQ vector (14, 26+ACK)
	LDA #<rcv_irq
	STA fw_irq
	LDA #>rcv_irq
	STA fw_irq+1			; point to specific nanoLink IRQ handler (12, 38+ACK)
	CLI						; enable interrupt... (2, 40+ACK)
; if bit is 1, t is added -- MUST return with interrupts disabled in stacked P!
;	SEI						; ...and disable it! (no longer needed)
	PLA
	STA fw_irq
	PLA 
	STA fw_irq+1			; restore interrupt vector (16)
	LDA #1					; odd value to enable interrupts
	DEC sys_sp				; one bit less to go
	BNE no_byte				; not yet complete
		LDA systmp			; get read value
		STA (sysptr)		; and store into buffer, CMOS only
		LDA #8				; reset value for bit counter (after subtracting one)
		INC sysptr			; advance into buffer
		BNE no_wrap
			INC sysptr+1	; page crossing
no_wrap:
		STA sys_sp			; eeeeek
		DEC					; correction needed to allow 0 as disable function
no_byte:
	STA IOAie				; odd value reenables interrupt
disabled:
	PLA
	RTI

; *************************************************
; *** IRQ handler for nanoLink *** total 20t+7t ACK
; *************************************************
rcv_irq:
	INC systmp				; LSB was 0, won't affect anything else (5)
	PLA						; get saved PSR, A was meaningless (4)
	ORA #$04				; disable saved interrupts (2)
	PHA						; restack corrected PSR (3)
	RTI						; (6)
.)
