; static variables for minimOS drivers
; empty file for testing purposes!
; (c) 2016 Carlos J. Santisteban
; last modified 20161219-1223

; optional multitasking
#ifdef	MULTITASK
#ifdef	C816
#include	"drivers/multitask16.h"
#else
#include	"drivers/multitask.h"
#endif
#endif

/* forget about this...
; optional filesystem
#ifdef	FILESYSTEM
#include "drivers/filesystem.h"
#endif
*/
