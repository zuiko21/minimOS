; free space header for minimOS filesystem
; also as Durango-X SD-card ROM images
; header ID
#ifndef	SIZE
#define		SIZE	$10000
#endif

#echo	SIZE free space header
free_start:
	.byt	0				; [0]=NUL, first magic number
	.asc	"dL"			; FREE space for Durango-X devCart SD
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.word	0				; non-existent filename, just the two terminators

; advance to end of header
; commits, version or timestamp make no sense here, thus all the way to filesize
	.dsb	free_start + $FC - *, $FF

; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.byt	0				; filesize (lower 8 bits always 0)
	.word	 SIZE / 256		; 64K free space needs third byte
	.byt	0				; if less than 16M, [255]=NUL may be third magic number

; now comes actual space
	.dsb	SIZE -256, $FF	; 64K minus 256 bytes
