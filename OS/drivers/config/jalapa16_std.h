; static variables for minimOS·16 drivers
; (c) 2015-2016 Carlos J. Santisteban
; last modified 20161017-1322

; optional multitasking
#ifdef	MULTITASK
#include "drivers/multitask16.h"
#endif

; optional filesystem
#ifdef	FILESYSTEM
#include "drivers/filesystem.h"
#endif

; ordinary driver variables
#include "drivers/drv_led.h"
#include "drivers/drv_ss22.h"
;#include "drivers/drv_ascii_lcd.h"
#include "drivers/drv_acia.h"
;#include "drivers/drv_lcd.h"
