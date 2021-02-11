; 4x8 font definition for minimOS picoVDU
; (c) 2021 Carlos J. Santisteban
; last modified 20210211-1103

; for space saving, even glyps are stored as MSN, and odd glyphs as LSN

; ASCII $00 - NULL / centre filled square
; ASCII $01 - HOML / double arrow left
	.byt	%11110000
	.byt	%10010000
	.byt	%11010101
	.byt	%11011010
	.byt	%11011111
	.byt	%11011010
	.byt	%10010101
	.byt	%11110000

; ASCII $02 - LEFT / left arrow
; ASCII $03 - TERM / ball switch
	.byt	%00000000
	.byt	%00100100
	.byt	%01111110
	.byt	%01111110
	.byt	%11111110
	.byt	%01111010
	.byt	%01110100
	.byt	%00100000

; ASCII $04 - ENDT / arrow to SE corner
; ASCII $05 - ENDL / double arrow right
	.byt	%00010000
	.byt	%10010000
	.byt	%10011010
	.byt	%01010101
	.byt	%01011111
	.byt	%00110101
	.byt	%00111010
	.byt	%11110000

; ASCII $06 - RIGHT / right arrow
; ASCII $07 - BELL / bell
	.byt	%00000000
	.byt	%01000100
	.byt	%11100110
	.byt	%11100110
	.byt	%11110110
	.byt	%11101111
	.byt	%11100010
	.byt	%01000001


; ASCII $08 - BKSP / left sign with x
; ASCII $09 - HTAB / right arrow to bar
	.byt	%00000000
	.byt	%00010001
	.byt	%00110101
	.byt	%01010011
	.byt	%10011111
	.byt	%01010011
	.byt	%00110101
	.byt	%00010001

; ASCII $0A - DOWN / down arrow
; ASCII $0B - UPCU / up arrow
	.byt	%00000000
	.byt	%01100100
	.byt	%01100110
	.byt	%01101111
	.byt	%11110110
	.byt	%01100110
	.byt	%01000110
	.byt	%00000000

; ASCII $0C - FORM / sheet
; ASCII $0D - NEWL / curved arrow
	.byt	%00000000
	.byt	%11000001
	.byt	%11000001
	.byt	%10110001
	.byt	%10010101
	.byt	%10011111
	.byt	%10010100
	.byt	%11110000

; ASCII $0E - EMON / imply
; ASCII $0F - EMOF / reverse imply
	.byt	%00000000
	.byt	%10000001
	.byt	%01000010
	.byt	%11100111
	.byt	%00011000
	.byt	%11100111
	.byt	%01000010
	.byt	%10000001

; ASCII $10 - DLE / heart
; ASCII $11 - XON / star
	.byt	%00000000
	.byt	%10100100
	.byt	%11100100
	.byt	%11101110
	.byt	%11100100
	.byt	%01000100
	.byt	%01001010
	.byt	%00000000

; ASCII $12 - INK / pencil
; ASCII $13 - XOFF / diamond suit
	.byt	%10100000
	.byt	%10100100
	.byt	%10100100
	.byt	%10101110
	.byt	%11101110
	.byt	%10100100
	.byt	%01000100
	.byt	%00000000

; ASCII $14 - PAPC / club suit
; ASCII $15 - HOME / arrow to NW corner
	.byt	%00001111
	.byt	%01001100
	.byt	%01001100
	.byt	%10101010
	.byt	%10101010
	.byt	%01001001
	.byt	%01001001
	.byt	%11101000

; ASCII $16 - PGDN / double arrow down
; ASCII $17 - ATYX / spades suit
	.byt	%00000000
	.byt	%01000100
	.byt	%01000100
	.byt	%10101110
	.byt	%01001010
	.byt	%01000100
	.byt	%10100100
	.byt	%01001110

; ASCII $18 - BKTB / left arrow to bar
; ASCII $19 - PGUP / double arrow up
	.byt	%00000000
	.byt	%10000100
	.byt	%10101010
	.byt	%11000100
	.byt	%11110100
	.byt	%11001010
	.byt	%10100100
	.byt	%10000100

; ASCII $1A - STOP / no entry
; ASCII $1B - ESC / NW arrow
	.byt	%01100000
	.byt	%11111111
	.byt	%11111110
	.byt	%10011110
	.byt	%10011111
	.byt	%11111011
	.byt	%11111011
	.byt	%01100000

; ASCII $1C - ramp up
; ASCII $1D - ramp down
	.byt	%00011000
	.byt	%00011000
	.byt	%00111100
	.byt	%00111100
	.byt	%01111110
	.byt	%01111110
	.byt	%11111111
	.byt	%11111111

; ASCII $1E - light pattern
; ASCII $1F - mid pattern
	.byt	%00000101
	.byt	%00101010
	.byt	%00000101
	.byt	%10001010
	.byt	%00000101
	.byt	%00101010
	.byt	%00000101
	.byt	%10001010

; ASCII $20 - SPACE
; ASCII $21 - !
	.byt	%00000000
	.byt	%00000100
	.byt	%00000100
	.byt	%00000100
	.byt	%00000100
	.byt	%00000000
	.byt	%00000100
	.byt	%00000000

; ASCII $22 - "
; ASCII $23 - # (pound or hash sign)
	.byt	%00000000
	.byt	%10101010
	.byt	%10101110
	.byt	%00001010
	.byt	%00001010
	.byt	%00001110
	.byt	%00001010
	.byt	%00000000

; ASCII $24 - $
; ASCII $25 - %
	.byt	%00001100
	.byt	%01001101
	.byt	%11100001
	.byt	%10000010
	.byt	%11100100
	.byt	%00101000
	.byt	%11101011
	.byt	%01000011

; ASCII $26 - &
; ASCII $27 - ' (different from ZX)
	.byt	%00000000
	.byt	%01100100
	.byt	%10000100
	.byt	%10100000
	.byt	%01110000
	.byt	%10100000
	.byt	%10010000
	.byt	%01100000

; ASCII $28 - (
; ASCII $29 - )
	.byt	%00000000
	.byt	%00100100
	.byt	%01000010
	.byt	%01000010
	.byt	%01000010
	.byt	%01000010
	.byt	%00100100
	.byt	%00000000

; ASCII $2A - *
; ASCII $2B - +
	.byt	%00000000
	.byt	%00000000
	.byt	%10100100
	.byt	%01000100
	.byt	%11101110
	.byt	%01000100
	.byt	%10100100
	.byt	%00000000

; ASCII $2C - ,
; ASCII $2D - -
	.byt	%00000000
	.byt	%00000000
	.byt	%00000000
	.byt	%00000000
	.byt	%00001110
	.byt	%01000000
	.byt	%01000000
	.byt	%10000000

; ASCII $2E - .
; ASCII $2F - /
	.byt	%00000000
	.byt	%00000001
	.byt	%00000010
	.byt	%00000010
	.byt	%00000100
	.byt	%01100100
	.byt	%01101000
	.byt	%00000000

; ASCII $30 - 0
; ASCII $31 - 1
	.byt	%00000000
	.byt	%11100100
	.byt	%10101100
	.byt	%10100100
	.byt	%10100100
	.byt	%10100100
	.byt	%11101110
	.byt	%00000000

; ASCII $32 - 2
; ASCII $33 - 3
	.byt	%00000000
	.byt	%01001110
	.byt	%10100010
	.byt	%00100100
	.byt	%01000010
	.byt	%10000010
	.byt	%11101100
	.byt	%00000000

; ASCII $34 - 4
; ASCII $35 - 5
	.byt	%00000000
	.byt	%10101110
	.byt	%10101000
	.byt	%10101100
	.byt	%11100010
	.byt	%00100010
	.byt	%00101100
	.byt	%00000000

; ASCII $36 - 6
; ASCII $37 - 7
	.byt	%00000000
	.byt	%01101110
	.byt	%10000010
	.byt	%11000100
	.byt	%10100100
	.byt	%10101000
	.byt	%01001000
	.byt	%00000000

; ASCII $38 - 8
; ASCII $39 - 9
	.byt	%00000000
	.byt	%01000100
	.byt	%10101010
	.byt	%01001010
	.byt	%10100110
	.byt	%10100010
	.byt	%01000100
	.byt	%00000000

; ASCII $3A - :
; ASCII $3B - ;
	.byt	%00000000
	.byt	%00000000
	.byt	%00000100
	.byt	%01000000
	.byt	%00000000
	.byt	%00000100
	.byt	%01000100
	.byt	%00001000

; ASCII $3C - <
; ASCII $3D - =
	.byt	%00000000
	.byt	%00000000
	.byt	%00100000
	.byt	%01001110
	.byt	%10000000
	.byt	%01001110
	.byt	%00100000
	.byt	%00000000

; ASCII $3E - >
; ASCII $3F - ?
	.byt	%00000000
	.byt	%00000100
	.byt	%10001010
	.byt	%01000010
	.byt	%00100100
	.byt	%01000100
	.byt	%10000000
	.byt	%00000100

; ASCII $40 - @
; ASCII $41 - A
	.byt	%00000000
	.byt	%01100100
	.byt	%10011010
	.byt	%10111010
	.byt	%10111110
	.byt	%10001010
	.byt	%10011010
	.byt	%01100000

; ASCII $42 - B
; ASCII $43 - C
	.byt	%00000000
	.byt	%11000110
	.byt	%10101000
	.byt	%11001000
	.byt	%10101000
	.byt	%10101000
	.byt	%11000110
	.byt	%00000000

; ASCII $44 - D
; ASCII $45 - E
	.byt	%00000000
	.byt	%11001110
	.byt	%10101000
	.byt	%10101110
	.byt	%10101000
	.byt	%10101000
	.byt	%11001110
	.byt	%00000000

; ASCII $46 - F
; ASCII $47 - G
	.byt	%00000000
	.byt	%11100100
	.byt	%10001010
	.byt	%11101000
	.byt	%10001110
	.byt	%10001010
	.byt	%10000110
	.byt	%00000000

; ASCII $48 - H
; ASCII $49 - I
	.byt	%00000000
	.byt	%10101110
	.byt	%10100100
	.byt	%11100100
	.byt	%10100100
	.byt	%10100100
	.byt	%10101110
	.byt	%00000000

; ASCII $4A - J
; ASCII $4B - K
	.byt	%00000000
	.byt	%00101001
	.byt	%00101010
	.byt	%00101100
	.byt	%10101100
	.byt	%10101010
	.byt	%01001001
	.byt	%00000000

; ASCII $4C - L
; ASCII $4D - M
	.byt	%00000000
	.byt	%10001010
	.byt	%10001110
	.byt	%10001110
	.byt	%10001010
	.byt	%10001010
	.byt	%11101010
	.byt	%00000000

; ASCII $4E - N
; ASCII $4F - O
	.byt	%00000000
	.byt	%10010100
	.byt	%11011010
	.byt	%11011010
	.byt	%10111010
	.byt	%10111010
	.byt	%10010100
	.byt	%00000000

; ASCII $50 - P
; ASCII $51 - Q
	.byt	%00000000
	.byt	%11000100
	.byt	%10101010
	.byt	%10101010
	.byt	%11001110
	.byt	%10001010
	.byt	%10000101
	.byt	%00000000

; ASCII $52 - R
; ASCII $53 - S
	.byt	%00000000
	.byt	%11000110
	.byt	%10101000
	.byt	%10100100
	.byt	%11000010
	.byt	%10100010
	.byt	%10101100
	.byt	%00000000

; ASCII $54 - T
; ASCII $55 - U
	.byt	%00000000
	.byt	%11101010
	.byt	%01001010
	.byt	%01001010
	.byt	%01001010
	.byt	%01001010
	.byt	%01000100
	.byt	%00000000

; ASCII $56 - V
; ASCII $57 - W
	.byt	%00000000
	.byt	%10101010
	.byt	%10101010
	.byt	%10101010
	.byt	%10101110
	.byt	%01001110
	.byt	%01001010
	.byt	%00000000

; ASCII $58 - X
; ASCII $59 - Y
	.byt	%00000000
	.byt	%10101010
	.byt	%10101010
	.byt	%01000100
	.byt	%01000100
	.byt	%10100100
	.byt	%10100100
	.byt	%00000000

; ASCII $5A - Z
; ASCII $5B - [
	.byt	%00000000
	.byt	%11100110
	.byt	%00100100
	.byt	%01000100
	.byt	%01000100
	.byt	%10000100
	.byt	%11100110
	.byt	%00000000

; ASCII $5C - \ (backslash)
; ASCII $5D - ]
	.byt	%00000000
	.byt	%10000110
	.byt	%01000010
	.byt	%01000010
	.byt	%00100010
	.byt	%00100010
	.byt	%00010110
	.byt	%00000000

; ASCII $5E - ^
; ASCII $5F - _
	.byt	%00000000
	.byt	%01000000
	.byt	%10100000
	.byt	%00000000
	.byt	%00000000
	.byt	%00000000
	.byt	%00000000
	.byt	%00001111

; ASCII $60 - `
; ASCII $61 - a
	.byt	%00000000
	.byt	%01000000
	.byt	%00100100
	.byt	%00000010
	.byt	%00000110
	.byt	%00001010
	.byt	%00000100
	.byt	%00000000

; ASCII $62 - b
; ASCII $63 - c
	.byt	%00000000
	.byt	%10000000
	.byt	%10000110
	.byt	%11001000
	.byt	%10101000
	.byt	%10101000
	.byt	%11000110
	.byt	%00000000

; ASCII $64 - d
; ASCII $65 - e
	.byt	%00000000
	.byt	%00100000
	.byt	%00100100
	.byt	%01101010
	.byt	%10101110
	.byt	%10101000
	.byt	%01100110
	.byt	%00000000

; ASCII $66 - f
; ASCII $67 - g
	.byt	%00000000
	.byt	%01100000
	.byt	%10000110
	.byt	%11001010
	.byt	%10001010
	.byt	%10000110
	.byt	%10000010
	.byt	%00000100

; ASCII $68 - h
; ASCII $69 - i
	.byt	%00000000
	.byt	%10000100
	.byt	%10000000
	.byt	%11001100
	.byt	%10100100
	.byt	%10100100
	.byt	%10101110
	.byt	%00000000

; ASCII $6A - j
; ASCII $6B - k
	.byt	%00000000
	.byt	%00101000
	.byt	%00001000
	.byt	%00101010
	.byt	%00101100
	.byt	%00101100
	.byt	%10101010
	.byt	%01000000

; ASCII $6C - l
; ASCII $6D - m
	.byt	%00000000
	.byt	%10000000
	.byt	%10001100
	.byt	%10001110
	.byt	%10001110
	.byt	%10001010
	.byt	%01101010
	.byt	%00000000

; ASCII $6E - n
; ASCII $6F - o
	.byt	%00000000
	.byt	%00000000
	.byt	%11000100
	.byt	%10101010
	.byt	%10101010
	.byt	%10101010
	.byt	%10100100
	.byt	%00000000

; ASCII $70 - p
; ASCII $71 - q
	.byt	%00000000
	.byt	%00000000
	.byt	%11000110
	.byt	%10101010
	.byt	%10101010
	.byt	%11000110
	.byt	%10000010
	.byt	%10000011

; ASCII $72 - r
; ASCII $73 - s
	.byt	%00000000
	.byt	%00000000
	.byt	%01100110
	.byt	%10001000
	.byt	%10000100
	.byt	%10000010
	.byt	%10001100
	.byt	%00000000

; ASCII $74 - t
; ASCII $75 - u
	.byt	%00000000
	.byt	%01000000
	.byt	%11101010
	.byt	%01001010
	.byt	%01001010
	.byt	%01001010
	.byt	%00100100
	.byt	%00000000

; ASCII $76 - v
; ASCII $77 - w
	.byt	%00000000
	.byt	%00000000
	.byt	%10101010
	.byt	%10101010
	.byt	%10101110
	.byt	%01001110
	.byt	%01000100
	.byt	%00000000

; ASCII $78 - x
; ASCII $79 - y
	.byt	%00000000
	.byt	%00000000
	.byt	%10101010
	.byt	%10101010
	.byt	%01001010
	.byt	%10100110
	.byt	%10100010
	.byt	%00000100

; ASCII $7A - z
; ASCII $7B - {
	.byt	%00000000
	.byt	%00000110
	.byt	%11100100
	.byt	%00101000
	.byt	%01000100
	.byt	%10000100
	.byt	%11100110
	.byt	%00000000

; ASCII $7C - |
; ASCII $7D - }
	.byt	%01000000
	.byt	%01001100
	.byt	%01000100
	.byt	%01000010
	.byt	%01000100
	.byt	%01000100
	.byt	%01001100
	.byt	%01000000

; ASCII $7E - ~
; ASCII $7F - DEL
	.byt	%00001111
	.byt	%01011001
	.byt	%10101001
	.byt	%00001111
	.byt	%00001111
	.byt	%00001001
	.byt	%00001001
	.byt	%00001111

; ASCII $80 - block space
; ASCII $81 - continue with ZX Spectrum blocks
	.byt	%00000011
	.byt	%00000011
	.byt	%00000011
	.byt	%00000011
	.byt	%00000000
	.byt	%00000000
	.byt	%00000000
	.byt	%00000000

; ASCII $82
; ASCII $83
	.byt	%11001111
	.byt	%11001111
	.byt	%11001111
	.byt	%11001111
	.byt	%00000000
	.byt	%00000000
	.byt	%00000000
	.byt	%00000000

; ASCII $84
; ASCII $85
	.byt	%00000011
	.byt	%00000011
	.byt	%00000011
	.byt	%00000011
	.byt	%00110011
	.byt	%00110011
	.byt	%00110011
	.byt	%00110011

; ASCII $86
; ASCII $87
	.byt	%11001111
	.byt	%11001111
	.byt	%11001111
	.byt	%11001111
	.byt	%00110011
	.byt	%00110011
	.byt	%00110011
	.byt	%00110011

; ASCII $88
; ASCII $89
	.byt	%00000011
	.byt	%00000011
	.byt	%00000011
	.byt	%00000011
	.byt	%11001100
	.byt	%11001100
	.byt	%11001100
	.byt	%11001100

; ASCII $8A
; ASCII $8B
	.byt	%11001111
	.byt	%11001111
	.byt	%11001111
	.byt	%11001111
	.byt	%11001100
	.byt	%11001100
	.byt	%11001100
	.byt	%11001100

; ASCII $8C
; ASCII $8D
	.byt	%00000011
	.byt	%00000011
	.byt	%00000011
	.byt	%00000011
	.byt	%11111111
	.byt	%11111111
	.byt	%11111111
	.byt	%11111111

; ASCII $8E
; ASCII $8F - whole square, last of ZX glyphs
	.byt	%11001111
	.byt	%11001111
	.byt	%11001111
	.byt	%11001111
	.byt	%11111111
	.byt	%11111111
	.byt	%11111111
	.byt	%11111111

; ASCII $90 - alpha
; ASCII $91 - check

	.byt	%00000000
	.byt	%00000000
	.byt	%01010001
	.byt	%10100001
	.byt	%10100010
	.byt	%01011010
	.byt	%00000100
	.byt	%00000000

; ASCII $92 - gamma
; ASCII $93 - pi
	.byt	%00000000
	.byt	%11100000
	.byt	%10000000
	.byt	%10001111
	.byt	%10000101
	.byt	%10000101
	.byt	%10000101
	.byt	%00000000

; ASCII $94 - upper sigma
; ASCII $95 - rho
	.byt	%11100000
	.byt	%10000000
	.byt	%01000000
	.byt	%00100111
	.byt	%01001010
	.byt	%10001010
	.byt	%11100100
	.byt	%00000000

; ASCII $96 - less or equal
; ASCII $97 - tau
	.byt	%00000000
	.byt	%00100000
	.byt	%01000010
	.byt	%01001110
	.byt	%10001100
	.byt	%11100100
	.byt	%00000010
	.byt	%11100000

; ASCII $98 - more or equal
; ASCII $99 - theta
	.byt	%00000000
	.byt	%10000100
	.byt	%01001010
	.byt	%01001010
	.byt	%00101110
	.byt	%11101010
	.byt	%00001010
	.byt	%11100100

; ASCII $9A - upper omega
; ASCII $9B - lower delta
	.byt	%00000000
	.byt	%01100100
	.byt	%10011000
	.byt	%10010100
	.byt	%10011010
	.byt	%01101010
	.byt	%11110100
	.byt	%00000000

; ASCII $9C - infinity
; ASCII $9D - approximate
	.byt	%00000000
	.byt	%00000000
	.byt	%10010101
	.byt	%10011010
	.byt	%11110000
	.byt	%10010101
	.byt	%10011010
	.byt	%00000000

; ASCII $9E - belongs
; ASCII $9F - arc
	.byt	%00000000
	.byt	%00100000
	.byt	%01000100
	.byt	%10001010
	.byt	%11101010
	.byt	%10001010
	.byt	%01000000
	.byt	%00100000

; ASCII $A0 - hollow square
; ASCII $A1 - ¡
	.byt	%11110000
	.byt	%10010010
	.byt	%10010000
	.byt	%10010010
	.byt	%10010010
	.byt	%10010010
	.byt	%10010010
	.byt	%11110000

; ASCII $A2 - cent
; ASCII $A3 - pound
	.byt	%00000000
	.byt	%01000100
	.byt	%01101010
	.byt	%10001000
	.byt	%10001110
	.byt	%01101000
	.byt	%01001110
	.byt	%00000000

; ASCII $A4 - €
; ASCII $A5 - yen
	.byt	%00000000
	.byt	%01101010
	.byt	%10000100
	.byt	%11101110
	.byt	%10000100
	.byt	%11101110
	.byt	%10000100
	.byt	%01100000

; ASCII $A6 - broken pipe
; ASCII $A7 - section
	.byt	%00000000
	.byt	%00100010
	.byt	%00100100
	.byt	%00100100
	.byt	%00001010
	.byt	%00100100
	.byt	%00100100
	.byt	%00101000

; ASCII $A8 - umlaut
; ASCII $A9 - copyright
	.byt	%00000110
	.byt	%10101001
	.byt	%00000110
	.byt	%00001000
	.byt	%00001000
	.byt	%00000110
	.byt	%00001001
	.byt	%00000110

; ASCII $AA - ª
; ASCII $AB - left chevron
	.byt	%01000000
	.byt	%00100101
	.byt	%11100101
	.byt	%11101010
	.byt	%00001010
	.byt	%11101010
	.byt	%00000101
	.byt	%00000101

; ASCII $AC - not
; ASCII $AD - not equal
	.byt	%00000000
	.byt	%00000000
	.byt	%00000010
	.byt	%11111111
	.byt	%00010000
	.byt	%00011111
	.byt	%00000100
	.byt	%00000000

; ASCII $AE - registered
; ASCII $AF - macron
	.byt	%01101111
	.byt	%10010000
	.byt	%11000000
	.byt	%10100000
	.byt	%11000000
	.byt	%10100000
	.byt	%10010000
	.byt	%01100000

; ASCII $B0 - degrees
; ASCII $B1 - plus minus
	.byt	%01000000
	.byt	%10100000
	.byt	%01000100
	.byt	%00001110
	.byt	%00000100
	.byt	%00000000
	.byt	%00001110
	.byt	%00000000

; ASCII $B2 - power of 2
; ASCII $B3 - power of three
	.byt	%11101110
	.byt	%00100010
	.byt	%11101110
	.byt	%10000010
	.byt	%11101110
	.byt	%00000000
	.byt	%00000000
	.byt	%00000000

; ASCII $B4 - acute
; ASCII $B5 - mju
	.byt	%00100000
	.byt	%01000000
	.byt	%00001010
	.byt	%00001010
	.byt	%00001101
	.byt	%00001000
	.byt	%00001000
	.byt	%00000000

; ASCII $B6 - paragraph
; ASCII $B7 - interpunct
	.byt	%00000000
	.byt	%01010000
	.byt	%11010000
	.byt	%11010000
	.byt	%01010100
	.byt	%01010000
	.byt	%01010000
	.byt	%00000000

; ASCII $B8 - lowercase omega
; ASCII $B9 - delta
	.byt	%00000000
	.byt	%00000000
	.byt	%00000000
	.byt	%01000100
	.byt	%10000010
	.byt	%10010010
	.byt	%01101100
	.byt	%00000000

	.byt	%00000000
	.byt	%00000000
	.byt	%00010000
	.byt	%00101000
	.byt	%01000100
	.byt	%11111110
	.byt	%00000000
	.byt	%00000000

; ASCII $BA - º
; ASCII $BB - right chevron
	.byt	%01110000
	.byt	%01110000
	.byt	%00000000
	.byt	%01110000
	.byt	%00000000
	.byt	%00000000
	.byt	%00000000
	.byt	%00000000

	.byt	%00000000
	.byt	%00000000
	.byt	%01001000
	.byt	%00100100
	.byt	%00010010
	.byt	%00100100
	.byt	%01001000
	.byt	%00000000

; ASCII $BC - bullet
; ASCII $BD - oe ligature
	.byt	%00000000
	.byt	%00111100
	.byt	%01111110
	.byt	%01111110
	.byt	%01111110
	.byt	%01111110
	.byt	%00111100
	.byt	%00000000

	.byt	%00000000
	.byt	%00000000
	.byt	%01101100
	.byt	%10010010
	.byt	%10011100
	.byt	%10010000
	.byt	%01101110
	.byt	%00000000

; ASCII $BE - eng
; ASCII $BF - ¿
	.byt	%00000000
	.byt	%00000000
	.byt	%01111000
	.byt	%01000100
	.byt	%01000100
	.byt	%01000100
	.byt	%00000100
	.byt	%00001000

	.byt	%00000000
	.byt	%00010000
	.byt	%00000000
	.byt	%00010000
	.byt	%00100000
	.byt	%01000010
	.byt	%00111100
	.byt	%00000000

; ASCII $C0 - À
; ASCII $C1 - Á
	.byt	%00010000
	.byt	%00001000
	.byt	%00111100
	.byt	%01000010
	.byt	%01111110
	.byt	%01000010
	.byt	%01000010
	.byt	%00000000

	.byt	%00001000
	.byt	%00010000
	.byt	%00111100
	.byt	%01000010
	.byt	%01111110
	.byt	%01000010
	.byt	%01000010
	.byt	%00000000

; ASCII $C2 - Â
; ASCII $C3 - A tilde
	.byt	%00011000
	.byt	%00100100
	.byt	%00000000
	.byt	%00111100
	.byt	%01000010
	.byt	%01111110
	.byt	%01000010
	.byt	%00000000

	.byt	%00010100
	.byt	%00101000
	.byt	%00000000
	.byt	%00111100
	.byt	%01000010
	.byt	%01111110
	.byt	%01000010
	.byt	%00000000

; ASCII $C4 - Ä
; ASCII $C5 - A with circle
	.byt	%00100100
	.byt	%00000000
	.byt	%00111100
	.byt	%01000010
	.byt	%01111110
	.byt	%01000010
	.byt	%01000010
	.byt	%00000000

	.byt	%00011000
	.byt	%00100100
	.byt	%00011000
	.byt	%00111100
	.byt	%01000010
	.byt	%01111110
	.byt	%01000010
	.byt	%00000000

; ASCII $C6 - Æ
; ASCII $C7 - Ç
	.byt	%00000000
	.byt	%01111110
	.byt	%10010000
	.byt	%11111100
	.byt	%10010000
	.byt	%10010000
	.byt	%10011110
	.byt	%00000000

	.byt	%00000000
	.byt	%00111100
	.byt	%01000010
	.byt	%01000000
	.byt	%01000010
	.byt	%00111100
	.byt	%00001000
	.byt	%00010000

; ASCII $C8 - È
; ASCII $C9 - É
	.byt	%00010000
	.byt	%00001000
	.byt	%01111110
	.byt	%01000000
	.byt	%01111100
	.byt	%01000000
	.byt	%01111110
	.byt	%00000000

	.byt	%00001000
	.byt	%00010000
	.byt	%01111110
	.byt	%01000000
	.byt	%01111100
	.byt	%01000000
	.byt	%01111110
	.byt	%00000000

; ASCII $CA - Ê
; ASCII $CB -Ë
	.byt	%00011000
	.byt	%00100100
	.byt	%00000000
	.byt	%01111110
	.byt	%01000000
	.byt	%01111100
	.byt	%01000000
	.byt	%01111110

	.byt	%00100100
	.byt	%00000000
	.byt	%01111110
	.byt	%01000000
	.byt	%01111100
	.byt	%01000000
	.byt	%01111110
	.byt	%00000000

; ASCII $CC - Ì
; ASCII $CD - Í
	.byt	%00010000
	.byt	%00001000
	.byt	%00111110
	.byt	%00001000
	.byt	%00001000
	.byt	%00001000
	.byt	%00111110
	.byt	%00000000

	.byt	%00000100
	.byt	%00001000
	.byt	%00111110
	.byt	%00001000
	.byt	%00001000
	.byt	%00001000
	.byt	%00111110
	.byt	%00000000

; ASCII $CE - Î
; ASCII $CF - Ï
	.byt	%00001000
	.byt	%00010100
	.byt	%00000000
	.byt	%00111110
	.byt	%00001000
	.byt	%00001000
	.byt	%00001000
	.byt	%00111110

	.byt	%00010100
	.byt	%00000000
	.byt	%00111110
	.byt	%00001000
	.byt	%00001000
	.byt	%00001000
	.byt	%00111110
	.byt	%00000000

; ASCII $D0 - ETH
; ASCII $D1 - Ñ
	.byt	%00000000
	.byt	%01111000
	.byt	%01000100
	.byt	%11100010
	.byt	%01000010
	.byt	%01000100
	.byt	%01111000
	.byt	%00000000

	.byt	%00010100
	.byt	%00101000
	.byt	%01000010
	.byt	%01100010
	.byt	%01010010
	.byt	%01001010
	.byt	%01000110
	.byt	%01000010

; ASCII $D2 - Ò
; ASCII $D3 - Ó
	.byt	%00010000
	.byt	%00001000
	.byt	%00111100
	.byt	%01000010
	.byt	%01000010
	.byt	%01000010
	.byt	%00111100
	.byt	%00000000

	.byt	%00001000
	.byt	%00010000
	.byt	%00111100
	.byt	%01000010
	.byt	%01000010
	.byt	%01000010
	.byt	%00111100
	.byt	%00000000

; ASCII $D4 - Ô
; ASCII $D5 - O tilde
	.byt	%00011000
	.byt	%00100100
	.byt	%00000000
	.byt	%00111100
	.byt	%01000010
	.byt	%01000010
	.byt	%01000010
	.byt	%00111100

	.byt	%00010100
	.byt	%00101000
	.byt	%00000000
	.byt	%00111100
	.byt	%01000010
	.byt	%01000010
	.byt	%01000010
	.byt	%00111100

; ASCII $D6 - Ö
; ASCII $D7 - product
	.byt	%00100100
	.byt	%00000000
	.byt	%00111100
	.byt	%01000010
	.byt	%01000010
	.byt	%01000010
	.byt	%00111100
	.byt	%00000000

	.byt	%00000000
	.byt	%00000000
	.byt	%00000000
	.byt	%00101000
	.byt	%00010000
	.byt	%00101000
	.byt	%00000000
	.byt	%00000000

; ASCII $D8 - empty set
; ASCII $D9 - Ù
	.byt	%00000001
	.byt	%00111110
	.byt	%01000110
	.byt	%01001010
	.byt	%01010010
	.byt	%01100010
	.byt	%01111100
	.byt	%10000000

	.byt	%00010000
	.byt	%01001010
	.byt	%01000010
	.byt	%01000010
	.byt	%01000010
	.byt	%01000010
	.byt	%00111100
	.byt	%00000000

; ASCII $DA - Ú
; ASCII $DB - Û
	.byt	%00001000
	.byt	%01010010
	.byt	%01000010
	.byt	%01000010
	.byt	%01000010
	.byt	%01000010
	.byt	%00111100
	.byt	%00000000

	.byt	%00011000
	.byt	%00100100
	.byt	%00000000
	.byt	%01000010
	.byt	%01000010
	.byt	%01000010
	.byt	%01000010
	.byt	%00111100

; ASCII $DC - Ü
; ASCII $DD - Ý
	.byt	%01000010
	.byt	%00000000
	.byt	%01000010
	.byt	%01000010
	.byt	%01000010
	.byt	%01000010
	.byt	%00111100
	.byt	%00000000

	.byt	%00001000
	.byt	%10010010
	.byt	%01000100
	.byt	%00101000
	.byt	%00010000
	.byt	%00010000
	.byt	%00010000
	.byt	%00000000

; ASCII $DE - upper thorn
; ASCII $DF - esszett
	.byt	%00000000
	.byt	%01000000
	.byt	%01000000
	.byt	%01111100
	.byt	%01000010
	.byt	%01111100
	.byt	%01000000
	.byt	%01000000

	.byt	%00000000
	.byt	%00110000
	.byt	%01001000
	.byt	%01010000
	.byt	%01001000
	.byt	%01001000
	.byt	%01010000
	.byt	%00000000

; ASCII $E0 - à
; ASCII $E1 - á
	.byt	%00010000
	.byt	%00001000
	.byt	%00111000
	.byt	%00000100
	.byt	%00111100
	.byt	%01000100
	.byt	%00111100
	.byt	%00000000

	.byt	%00001000
	.byt	%00010000
	.byt	%00111000
	.byt	%00000100
	.byt	%00111100
	.byt	%01000100
	.byt	%00111100
	.byt	%00000000

; ASCII $E2 - â
; ASCII $E3 - a tilde
	.byt	%00010000
	.byt	%00101000
	.byt	%00000000
	.byt	%00111000
	.byt	%00000100
	.byt	%00111100
	.byt	%01000100
	.byt	%00111100

	.byt	%00010100
	.byt	%00101000
	.byt	%00000000
	.byt	%00111000
	.byt	%00000100
	.byt	%00111100
	.byt	%01000100
	.byt	%00111100

; ASCII $E4 - ä
; ASCII $E5 - a with circle
	.byt	%00101000
	.byt	%00000000
	.byt	%00111000
	.byt	%00000100
	.byt	%00111100
	.byt	%01000100
	.byt	%00111100
	.byt	%00000000

	.byt	%00010000
	.byt	%00101000
	.byt	%00010000
	.byt	%00111000
	.byt	%00000100
	.byt	%00111100
	.byt	%01000100
	.byt	%00111100

; ASCII $E6 - æ
; ASCII $E7 - ç
	.byt	%00000000
	.byt	%00000000
	.byt	%01101100
	.byt	%00010010
	.byt	%01111100
	.byt	%10010000
	.byt	%01111110
	.byt	%00000000

	.byt	%00000000
	.byt	%00011100
	.byt	%00100000
	.byt	%00100000
	.byt	%00100000
	.byt	%00011100
	.byt	%00001000
	.byt	%00010000

; ASCII $E8 - è
; ASCII $E9 - é
	.byt	%00010000
	.byt	%00001000
	.byt	%00111000
	.byt	%01000100
	.byt	%01111000
	.byt	%01000000
	.byt	%00111100
	.byt	%00000000

	.byt	%00001000
	.byt	%00010000
	.byt	%00111000
	.byt	%01000100
	.byt	%01111000
	.byt	%01000000
	.byt	%00111100
	.byt	%00000000

; ASCII $EA - ê
; ASCII $EB - ë
	.byt	%00010000
	.byt	%00101000
	.byt	%00000000
	.byt	%00111000
	.byt	%01000100
	.byt	%01111000
	.byt	%01000000
	.byt	%00111100

	.byt	%00101000
	.byt	%00000000
	.byt	%00111000
	.byt	%01000100
	.byt	%01111000
	.byt	%01000000
	.byt	%00111100
	.byt	%00000000

; ASCII $EC - ì
; ASCII $ED - í
	.byt	%00100000
	.byt	%00010000
	.byt	%00000000
	.byt	%00110000
	.byt	%00010000
	.byt	%00010000
	.byt	%00111000
	.byt	%00000000

	.byt	%00001000
	.byt	%00010000
	.byt	%00000000
	.byt	%00110000
	.byt	%00010000
	.byt	%00010000
	.byt	%00111000
	.byt	%00000000

; ASCII $EE - î
; ASCII $EF - ï
	.byt	%00010000
	.byt	%00101000
	.byt	%00000000
	.byt	%00110000
	.byt	%00010000
	.byt	%00010000
	.byt	%00111000
	.byt	%00000000

	.byt	%00000000
	.byt	%00101000
	.byt	%00000000
	.byt	%00110000
	.byt	%00010000
	.byt	%00010000
	.byt	%00111000
	.byt	%00000000

; ASCII $F0 - eth
; ASCII $F1 - ñ
	.byt	%00000000
	.byt	%00000100
	.byt	%00001110
	.byt	%00000100
	.byt	%00111100
	.byt	%01000100
	.byt	%00111100
	.byt	%00000000

	.byt	%00111000
	.byt	%00000000
	.byt	%01111000
	.byt	%01000100
	.byt	%01000100
	.byt	%01000100
	.byt	%01000100
	.byt	%00000000

; ASCII $F2 - ò
; ASCII $F3 - ó
	.byt	%00010000
	.byt	%00001000
	.byt	%00111000
	.byt	%01000100
	.byt	%01000100
	.byt	%01000100
	.byt	%00111000
	.byt	%00000000

	.byt	%00001000
	.byt	%00010000
	.byt	%00111000
	.byt	%01000100
	.byt	%01000100
	.byt	%01000100
	.byt	%00111000
	.byt	%00000000

; ASCII $F4 - ô
; ASCII $F5 - o tilde
	.byt	%00010000
	.byt	%00101000
	.byt	%00000000
	.byt	%00111000
	.byt	%01000100
	.byt	%01000100
	.byt	%01000100
	.byt	%00111000

	.byt	%00010100
	.byt	%00101000
	.byt	%00000000
	.byt	%00111000
	.byt	%01000100
	.byt	%01000100
	.byt	%01000100
	.byt	%00111000

; ASCII $F6 - ö
; ASCII $F7 - division
	.byt	%00101000
	.byt	%00000000
	.byt	%00111000
	.byt	%01000100
	.byt	%01000100
	.byt	%01000100
	.byt	%00111000
	.byt	%00000000

	.byt	%00000000
	.byt	%00000000
	.byt	%00010000
	.byt	%00000000
	.byt	%01111100
	.byt	%00000000
	.byt	%00010000
	.byt	%00000000

; ASCII $F8 - o with bar
; ASCII $F9 - ù
	.byt	%00000000
	.byt	%00000010
	.byt	%00111100
	.byt	%01001100
	.byt	%01010100
	.byt	%01100100
	.byt	%01111000
	.byt	%10000000

	.byt	%00100000
	.byt	%00010000
	.byt	%01000100
	.byt	%01000100
	.byt	%01000100
	.byt	%01000100
	.byt	%00111000
	.byt	%00000000

; ASCII $FA - ú
; ASCII $FB - û
	.byt	%00001000
	.byt	%00010000
	.byt	%01000100
	.byt	%01000100
	.byt	%01000100
	.byt	%01000100
	.byt	%00111000
	.byt	%00000000

	.byt	%00010000
	.byt	%00101000
	.byt	%00000000
	.byt	%01000100
	.byt	%01000100
	.byt	%01000100
	.byt	%01000100
	.byt	%00111000

; ASCII $FC - ü
; ASCII $FD - ý
	.byt	%00101000
	.byt	%00000000
	.byt	%01000100
	.byt	%01000100
	.byt	%01000100
	.byt	%01000100
	.byt	%00111000
	.byt	%00000000

	.byt	%00001000
	.byt	%00010000
	.byt	%01000100
	.byt	%01000100
	.byt	%01000100
	.byt	%00111100
	.byt	%00000100
	.byt	%00111000

; ASCII $FE - lower thorn
; ASCII $FF - ÿ
	.byt	%00000000
	.byt	%00100000
	.byt	%00111000
	.byt	%00100100
	.byt	%00100100
	.byt	%00111000
	.byt	%00100000
	.byt	%00000000

	.byt	%00101000
	.byt	%00000000
	.byt	%01000100
	.byt	%01000100
	.byt	%01000100
	.byt	%00111100
	.byt	%00000100
	.byt	%00111000
