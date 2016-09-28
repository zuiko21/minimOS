; 0.5 dummy driver for minimOS
; as originally supplied with minimOS 0.4b4LK4
; new ABI 20150323
; (c) Carlos J. Santisteban
; last modified 20150928-1047

; *** dummy device driver ***
	.byt	0				; +D_ID, reserved for alignment (device number!)
	.byt	0				; +D_AUTH, feature authorization code (new), dummy driver does nothing
	.word	void_routine	; +D_INIT, device reset
	.word	void_routine	; +D_POLL, device poll, called periodically
	.word	void_routine	; +D_REQ, asynchronous interrupt request by device (should verify source)
	.word	void_routine	; +D_CIN, device input, get character from device or buffer
	.word	void_routine	; +D_COUT, device output, buffered or not
	.word	void_routine	; +D_SEC, one second periodic interrupt
	.word	void_routine	; +D_SIN, device input, block transfer
	.word	void_routine	; +D_SOUT, device output, block transfer
	.word	void_routine	; +D_BYE, shutdown procedure
	.word	void_info		; +D_INFO, new info string
	.byt	0				; +D_MEM, reserved relocatable bytes

void_info:
	.asc	"DUMMY", 0

void_routine:
	_DR_OK					; essentially RTS, new interface
