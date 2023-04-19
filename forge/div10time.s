; Table-based bin-to-decimal conversion
; intended for easier time/date display!
; (c) 2023 Carlos J. Santisteban

dtdec_l:				; units
	.asc	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'	; 0...19
	.asc	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'	; 20...39
	.asc	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'	; 40...59
;	.asc	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'	; 60...79
;	.asc	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'	; 80...99 may be interesting for year (after adding 80 and discarding hundreds)


dtdec_h:				; decades
	.asc	' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1'	; 0...19, note no leading zero
	.asc	'2', '2', '2', '2', '2', '2', '2', '2', '2', '2', '3', '3', '3', '3', '3', '3', '3', '3', '3', '3'	; 20...39
	.asc	'4', '4', '4', '4', '4', '4', '4', '4', '4', '4', '5', '5', '5', '5', '5', '5', '5', '5', '5', '5'	; 40...59
;	.asc	'6', '6', '6', '6', '6', '6', '6', '6', '6', '6', '7', '7', '7', '7', '7', '7', '7', '7', '7', '7'	; 60...79
;	.asc	'4', '4', '4', '4', '4', '4', '4', '4', '4', '4', '5', '5', '5', '5', '5', '5', '5', '5', '5', '5'	; 90...99 may be interesting for year (after adding 80 and discarding hundreds)

; example code for display minutes from FAT-like storage
; % hhhhhmmm mmmsssss
;	LDA ftime+1			; MSB holds 3 upper bits for minutes
;	AND #%00000111		; discard hour bits
;	STA index			; store as final
;	LDA ftime			; LSB holds 3 lower bits for minutes
;	LDX #3				; 3 bits to be shifted
;sloop:
;		ASL
;		ROL index		; getting value into index
;		DEX
;		BNE sloop
;	LDX index			; final value 0...59
;	LDY dtdec_h, X		; get decade number
; optionally detect ' ' and change to '0' if leading zeroes are desired
;	JSR conio
;	LDX index			; reload number
;	LDY dtdec_l, X		; now get units
;	JSR conio			; and print them, trailing zeroes always available

; with extended tables, 2-digit years may be shown this way
;	LDA fdate+1			; year in upper 7 bits
;	LSR					; A = year-1980
;	CLC
;	ADC #80
;	CMP #100			; 21st century?
;	BCC c20
;		SBC #100		; C was set
;c20:
;	STA index			; final value
;	TAX
; similar code for minutes follow...
