; static variables for minimOS drivers
; (c) 2015-2021 Carlos J. Santisteban
; last modified 20180404-1337

; optional multitasking
#ifdef	MULTITASK
#include "../multitask.h"
#endif

; optional filesystem
#ifdef	FILESYSTEM
#include "../filesystem.h"
#endif

; ordinary driver variables
#include "../drv_led.h"
#include "../drv_ss22.h"
;#include "../drv_ascii_lcd.h"
#include "../drv_acia.h"
;#include "../drv_lcd.h"
