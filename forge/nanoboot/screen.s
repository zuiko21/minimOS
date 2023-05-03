; screen header for minimOS filesystem
; also as Durango-X SD-card ROM images
; use -DNAME=filename
; optionally -DHIRES

; header ID
#ifdef	HIRES
#define		TYPE	'R'
#else
#define		TYPE	'S'
#endif

#ifndef	NAME
#define		NAME	screen.sv
#endif

#echo	NAME screen image header for Durango TYPE (and -X)
img_start:
	.byt	0				; [0]=NUL, first magic number
	.asc	'd', TYPE		; image header for Durango-X devCart SD
	.asc	"****"			; reserved
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"NAME"
	.word	0				; non-existent comment

; advance to end of header
; commits or version make no sense here, thus all the way to timestamp
	.dsb	img_start + $F8 - *, $FF

	.word	0
	.word	0				; so far, midnight Jan 1, 1980

; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	$2200			; Durango screens area always 8K... plus two pages of leading sector!
	.word	0				; if less than 16M, [255]=NUL may be third magic number

; one-page filling so the screenshot is sector-aligned
	.dsb	256, $FF
