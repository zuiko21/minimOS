; nanoLink NMI handler for transparent reception
; (c) 2023 Carlos J. Santisteban
; last modified 20230112-1403

.(
nmi:
	STZ IOAie				; disable hardware interrupt ASAP (4 after NMI acknowledge)
	PHA						; save reg (3, total 7+ACK)
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
; if bit is 1, 18t is added
	SEI						; ...and disable it! Did it fire? (2... +IRQ)
	PLA
	STA fw_irq
	PLA 
	STA fw_irq+1			; restore interrupt vector (16)
	LDA #1					; value to enable interrupts
	DEC sys_sp				; one bit less to go
	BPL no_byte				; not yet complete
		LDA systmp			; get read value
		STA (sysptr)		; and store into buffer, CMOS only
		LDA #7				; reset value for bit counter
		INC sysptr			; advance into buffer
		BNE no_byte
			INC sysptr+1	; page crossing
no_byte:
	STA IOAie				; odd value reenables interrupt
	PLA
	RTI

; *** IRQ handler for nanoLink ***
rcv_irq:
	INC systmp				; LSB was 0, won't affect anything else (5+6)
	RTI
.)
