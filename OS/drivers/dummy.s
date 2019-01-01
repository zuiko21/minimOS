; 0.6 dummy driver for minimOS
; new 0.6 ABI 20170830
; (c) 2013-2019 Carlos J. Santisteban
; last modified 20170830-1723

; *** dummy device driver ***
	.byt	255		; +D_ID, reserved for alignment (device number!)
	.byt	0		; +D_AUTH, feature authorization code (new), dummy driver does nothing
	.word	empty_routine	; +D_BLIN, block input (new) will work like /dev/null instead of /dev/zero
	.word	empty_routine	; +D_BOUT, block output (new)
	.word	void_routine	; +D_INIT, initialisation procedure
	.word	void_routine	; +D_POLL, periodic interrupt request
	.word	0		; +D_FREQ, execution frequency for the above (in jiffys)
	.word	next_routine	; +D_ASYN, asynchronous interrupt request by device (should verify source)
	.word	err_routine	; +D_CNFG, device configuration TBD
	.word	err_routine	; +D_STAT, device status TBD
	.word	void_routine	; +D_BYE, shutdown procedure
	.word	void_info	; +D_INFO, info C-string
	.word	0		; +D_MEM, reserved relocatable bytes

void_info:
	.asc	"DUMMY", 0

empty_routine:
	_STZA bl_siz		; clear remainjng size!
	_STZA bl_siz+1
void_routine:
	_DR_OK			; essentially RTS, new interface

err_routine:
	_DR_ERR(UNAVAIL)	; feature not available

next_routine:
	_NXT_ISR		; cannot handle any interrupt, try another
