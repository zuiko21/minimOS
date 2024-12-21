; 8-bit PCM audio player for PCM Tri-PSG card (with 16K banks)
; (c) 2024 Carlos J. Santisteban
; last modified 20241222-0003

; * BANK 0 *
* = $C000					; mirrored bank start
	.bin	0, 0, "xaa"		; 15.75 kiB 8-bit PCM
#include	"pcm-player.s"	; player code on each bank

; * BANK 1 *
* = $C000					; mirrored bank start
	.bin	0, 0, "xab"		; 15.75 kiB 8-bit PCM
#include	"pcm-player.s"

; * BANK 2 *
* = $C000					; mirrored bank start
	.bin	0, 0, "xac"		; 15.75 kiB 8-bit PCM
#include	"pcm-player.s"

; * BANK 3 *
* = $C000					; mirrored bank start
	.bin	0, 0, "xad"		; 15.75 kiB 8-bit PCM
#include	"pcm-player.s"

; * BANK 4 *
* = $C000					; mirrored bank start
	.bin	0, 0, "xae"		; 15.75 kiB 8-bit PCM
#include	"pcm-player.s"

; * BANK 5 *
* = $C000					; mirrored bank start
	.bin	0, 0, "xaf"		; 15.75 kiB 8-bit PCM
#include	"pcm-player.s"

; * BANK 6 *
* = $C000					; mirrored bank start
	.bin	0, 0, "xag"		; 15.75 kiB 8-bit PCM
#include	"pcm-player.s"

; * BANK 7 *
* = $C000					; mirrored bank start
	.bin	0, 0, "xah"		; 15.75 kiB 8-bit PCM
	.dsb	$FF00-*, 128	; filling as the last chunk will be shorter
#include	"pcm-player.s"

