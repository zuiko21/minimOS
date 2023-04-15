; free space header for minimOS filesystem
; also as Durango-X SD-card ROM images
; header ID
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
	.word	0				; filesize (lower 16 bits)
	.word	1				; 64K free space needs third byte; if less than 16M, [255]=NUL may be third magic number
