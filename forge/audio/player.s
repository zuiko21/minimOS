; 4-bit PCM audio player for PSG and bankswitching cartridge! (16K banks)
; (c) 2023 Carlos J. Santisteban
; last modified 20231230-1807

; *** definitions ***
IO_PSG	= $DFDB				; PSG
IOBank	= $DFFC				; Bankswitching register
pb_buf	= $8000				; play back from mirrored ROM, no I/O page between $8000-$BFFF!
end_buf	= $BC00

; *** zeropage usage ***
sample	= $FE				; indirect pointer to audio sample
temp	= $FD				; temporary usage for delays
nxt_bnk	= 1					; increment this between banks!

; * BANK 0 *
; *** audio data ***
* = $C000

	.bin	0, 0, "audio0.4bit"			; 15 KiB 4-bit PCM audio chunk!

#include "bankplay.s"

; * BANK 1 *
; *** audio data ***
* = $C000

	.bin	0, 0, "audio1.4bit"			; 15 KiB 4-bit PCM audio chunk!

#include "bankplay.s"

; * BANK 2 *
; *** audio data ***
* = $C000

	.bin	0, 0, "audio2.4bit"			; 15 KiB 4-bit PCM audio chunk!

#include "bankplay.s"

; * BANK 3 *
; *** audio data ***
* = $C000

	.bin	0, 0, "audio3.4bit"			; 15 KiB 4-bit PCM audio chunk!

#include "bankplay.s"

; * BANK 4 *
; *** audio data ***
* = $C000

	.bin	0, 0, "audio4.4bit"			; 15 KiB 4-bit PCM audio chunk!

#include "bankplay.s"

; * BANK 5 *
; *** audio data ***
* = $C000

	.bin	0, 0, "audio5.4bit"			; 15 KiB 4-bit PCM audio chunk!

#include "bankplay.s"

; * BANK 6 *
; *** audio data ***
* = $C000

	.bin	0, 0, "audio6.4bit"			; 15 KiB 4-bit PCM audio chunk!

#include "bankplay.s"
; * BANK 7 *
; *** audio data ***
* = $C000

	.bin	0, 0, "audio7.4bit"			; 15 KiB 4-bit PCM audio chunk!

#include "bankplay.s"
