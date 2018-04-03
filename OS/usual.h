; usual header includes for minimOS
; last modified 20180403-1043
; (c) 2012-2018 Carlos J. Santisteban

#ifndef	HEADERS
; avoid further redefinitions
#define	HEADERS	_HEADERS
; usual support files
#include "options.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
.bss
* = SYSRAM				; as defined in options.h
; firmware and system variables
#include "firmware/ARCH.h"
#ifndef	DOWNLOAD
sysvars:
#include "sysvars.h"
; driver-specific system variables, located here 20170207
dr_vars:
#include "drivers/config/DRIVER_PACK.h";******TESTING
#endif
; points to the beginning of free SRAM
-user_ram:
.text
#ifndef	ROM
; placeholder for standalone assembly
*		= ROM_BASE
-kernel	= *
#endif
#endif
