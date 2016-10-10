; usual header includes for minimOS
; last modified 20161010-1220
; (c) 2012-2016 Carlos J. Santisteban

#ifndef	HEADERS
#define	HEADERS	_HEADERS
#include "options.h"
#include "macros.h"
#include "abi.h"
.zero
#include "zeropage.h"
.bss
#include "firmware/ARCH.h"
#include "sysvars.h"
.text
-user_sram		= $0600
*				= ROM_BASE
-remote_boot	= *
-kernel			= *
#endif
