; power-off firmware module for minimOS
; v0.5.1a1
; (c)2015-2016 Carlos J. Santisteban
; generic placeholder
; last modified 20161010-1007

; *** things to do for poweroff, maybe suspend-then-reboot ***
; for systems without supporting hardware, just abort execution
	_PANIC("{OFF}")		; stop execution! just in case is handled
