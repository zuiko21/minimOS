; firmware variables for minimOS on run65816 BBC simulator
; 8-bit kernels!
; v0.9.6b3
; (c) 2017-2018 Carlos J. Santisteban
; last modified 20180120-2138

-sysram:
; lowram option for testing only
#ifndef	LOWRAM
fw_table	.dsb	LAST_API, $0	; more efficient usage 171114, NOT available in 128-byte systems
#endif
; *** standard FW vars from template ***
#include "firmware/template.s"
; kernel sysvars to follow
