; static variables for minimOS drivers
; (c) 2015-2017 Carlos J. Santisteban
; last modified 20171220-1305

; optional multitasking
#ifdef	MULTITASK
#include "drivers/multitask.h"
#endif

; optional filesystem
#ifdef	FILESYSTEM
#include "drivers/filesystem.h"
#endif

; ordinary driver variables, in no particular order
#include "drivers/drv_led.h"
;#include "drivers/drv_ss22.h"
;#include "drivers/drv_ascii_lcd.h"
