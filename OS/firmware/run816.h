; firmware variables for minimOS on run65816 BBC simulator
; v0.9.6b3
; (c) 2017-2018 Carlos J. Santisteban
; last modified 20180120-2135

-sysram:
; lowram option for testing purposes only
#ifndef	LOWRAM
fw_table	.dsb	LAST_API, $0	; more efficient usage 171114, NOT available in 128-byte systems
#endif
; *** standard FW vars package ***
#include "firmware/template16.h"
; kernel sysvars to follow
