; firmware variables for minimOS on run65816 BBC simulator
; 8-bit kernels!
; v0.9.6b4
; (c) 2017-2018 Carlos J. Santisteban
; last modified 20180124-1302

-sysram:
; no way to set experimental LOWRAM option
; *** standard FW vars from template ***
#include "firmware/template.s"
; kernel sysvars to follow
