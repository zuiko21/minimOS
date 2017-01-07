; usual header includes for minimOS
; last modified 20170107-1844
; (c) 2012-2017 Carlos J. Santisteban

#ifndef	HEADERS
#define	HEADERS	_HEADERS
#include "options.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
.bss
* = SYSRAM		; as defined in options.h
#include "firmware/ARCH.h"
#include "sysvars.h"
#ifndef	ROM
.text
-user_sram		= $0600
*				= ROM_BASE
-remote_boot	= *
-kernel			= *
#endif
#endif
