; static variables for minimOS drivers
; empty file for testing purposes!
; (c) 2016-2018 Carlos J. Santisteban
; last modified 20180404-1346

; optional multitasking
#ifdef	MULTITASK
#ifdef	C816
#include	"../multitask16.h"
#else
#include	"../multitask.h"
#endif
#endif

/* forget about this...
; optional filesystem
#ifdef	FILESYSTEM
#include "../filesystem.h"
#endif
*/
