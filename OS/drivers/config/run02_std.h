; static variables for minimOS drivers
; v0.9b3
; (c) 2017-2019 Carlos J. Santisteban
; last modified 20190215-0955

; ***** none needed for the simple drv_run02.s driver! *****
; ...unless trying the multitasking option!

#ifdef	MULTITASK
#include	"../multitask.h"
#endif
