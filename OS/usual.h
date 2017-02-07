; usual header includes for minimOS
; last modified 20170207-0858
; (c) 2012-2017 Carlos J. Santisteban

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
#include "sysvars.h"
; driver-specific system variables, located here 20170207
dr_vars:
#include "drivers/config/DRIVER_PACK.h"
; points to the beginning of free SRAM
-user_sram:
#ifndef	ROM
; extra labels for standalone assembly
.text
*				= ROM_BASE
-remote_boot	= *
-kernel			= *
#endif
#endif
