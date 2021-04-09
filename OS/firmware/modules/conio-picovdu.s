; firmware module for minimOS
; pico-VDU basic 16x16 firmware console 0.9.6a1
; suitable for Durango (not Durango-SV) computer
; also for prototype with IOSCREEN option
; (c) 2021 Carlos J. Santisteban
; last modified 20210409-0951

; ****************************************
; CONIO, simple console driver in firmware
; ****************************************
; template with temporary IO9 input support (no handshake!)
;	INPUT
; Y <-	char to be printed (1...255)
;		0	= ask for one character (non-locking)
;		12	= clear screen AND initialise device
;	OUTPUT
; C ->	no available char (if Y was 0)
; NMOS and 65816 savvy

#define	IOSCREEN	_IOSCREEN

pvdu	= $7800				; base address
#ifdef	IOSCREEN
IO8lh	= $8000				; I/O Screen addresses (for prototype)
IO8ll	= $8001
IO8wr	= $8003
#endif
IO9di	= $9FF0				; data input (TBD)

.(
	TYA						; check mode (and put into A, just in case)
	BEQ cn_in				; Y=0 means input mode
		LDX fw_cbin			; check whether in binary mode
		BEQ cio_ctl			; if not, check control codes
			DEC fw_cbin		; otherwise, clear binary mode and print directly (STZ is safer!)
			BEQ cp_do
cio_ctl:
		CMP #FORMFEED		; reset device?
		BNE cn_nff			; no, just print it
; clear screen here
			LDY #<pvdu		; initial address
			LDX #>pvdu		; valid MSB for IOSCREEN, black-on-white mode (%01111xxx) instead of inverse for Pacman (%00001xxx)
			STY cio_pt		; set ZP pointer
			STX cio_pt+1
			STY fw_ciop		; worth resetting global pointer (cursor) here (conio.h?)
			STX fw_ciop+1
;			LDY #0			; no need to reset index
			TYA				; clear accumulator
cls_p:
#ifdef	IOSCREEN
				STX IO8lh	; set page on I/O device
#endif
cls_l:
#ifndef IOSCREEN
					STA (cio_pt), Y	; clear screen byte
#else
					STY IO8ll
					STA IO8wr
#endif
					INY
					BNE cls_l	; continue within page
#ifndef	IOSCREEN
				INC cio_pt+1
#else
				INX
#endif
				BPL cls_p		; same as cls_l if not using IOSCREEN
			_DR_OK
; continue evaluating control codes
cn_nff:
		CMP #BS				; backspace?
		BNE cn_nbs
; back one char
; coordinates are stored 01111yyy y000xxxx
; y will remain constant, xxxx may go down to zero
; if xxxx is zero, do nothing... but better clear first char in line
; will never cross page!
; with no cursor, best to clear current char after backing
			LDA fw_ciop		; get LSB (yrrrxxxx)
			AND #$F			; check xxxx
			BEQ bs_clr		; already at line start
				DEC fw_ciop	; back one character (cannot be xxxx=0 as already checked for that)
bs_clr:
			LDA fw_ciop		; get current address (perhaps after backing)
			LDX fw_ciop+1
			STA cio_pt		; set pointer
			STX cio_pt+1
#ifdef	IOSCREEN
			STX IO8lh		; preset I/O address
			STA IO8ll
#endif
			LDY #0			; reset offset
bs_loop:
				LDA #0		; clear value
#ifndef	IOSCREEN
				STA (cio_pt), Y
#else
				STA IO8wr
#endif
				TYA			; advance offset to next raster
				CLC
				ADC #16
				TAY
#ifdef	IOSCREEN
				CLC			; I/O LSB is offset + base LSB
				ADC cio_pt	; works because no page will cross between rasters!
				STA IO8ll
				TYA			; recheck Y for N flag
#endif
				BPL bs_loop	; offset always below 128 (8x16)
			_DR_OK
cn_nbs:
		CMP #CR				; new line?
		BNE cn_ncr
			LDA fw_ciop		; current position (LSB)
cn_cr:
			AND #$80		; the actual CR eeeeeeeek
			CLC
			ADC #$80		; then LF
			STA fw_ciop
			BCC cn_cre		; check carry
				INC fw_ciop+1
				BPL cn_cre
; this far, no scrolling, just wrap
					LDA #>pvdu
					STA fw_ciop+1
cn_cre:
			_DR_OK
cn_ncr:
		CMP #DLE			; check for DLE
		BNE cn_ndle
			LDA #1			; set binary mode
			STA fw_cbin
cn_ndle:
; anything else?
; PRINT HERE
		CMP #32				; check whether printable
		BCC cn_end			; skip if < 32 (we are NOT in binary mode)
cp_do:						; otherwise it is printable, or had received DLE
			ASL				; times eight
			ROL cio_src+1	; M=???????7, A=6543210·
			ASL
			ROL cio_src+1	; M=??????76, M=543210··
			ASL
			ROL cio_src+1	; M=?????765, A=43210···
			CLC
			ADC #<font		; add font base
			STA cio_src
			LDA cio_src+1	; A=?????765
			AND #7			; A=·····765
			ADC #>font
			STA cio_src+1	; pointer to glyph is ready
			LDA fw_ciop		; get current address
			LDX fw_ciop+1
			STA cio_pt		; set pointer
			STX cio_pt+1
#ifdef	IOSCREEN
			STX IO8lh		; preset I/O address
			STA IO8ll
#endif
			LDY #0			; reset offset
cp_loop:
				_LDAX(cio_src)	; glyph pattern
#ifndef	IOSCREEN
				STA (cio_pt), Y
#else
				STA IO8wr
#endif
				INC cio_src	; advance raster in font data, single byte
				BNE cp_nras
					INC cio_src
cp_nras:
				TYA			; advance offset to next raster
				CLC
				ADC #16
				TAY
#ifdef	IOSCREEN
				CLC			; I/O LSB is offset + base LSB
				ADC cio_pt
				STA IO8ll
				TYA			; recheck Y for N flag
#endif
				BPL cp_loop	; offset always below 128 (8x16)
; advance screen pointer before exit
			INC fw_ciop
			LDA fw_ciop
			BIT #%01110000	; check possible linewrap (CMOS, may use AND plus LDA afterwards)
				BNE cn_cr	; code shared with CR
cn_end:
		_DR_OK				; make sure C is clear
cn_in:
; TBD ***
	BCS cn_empty			; nothing here, keep trying
		BCC cn_end			; send received otherwise
cn_empty:
	_DR_ERR(EMPTY)			; set C instead eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeek
font:
#include "../../drivers/fonts/8x8.s"
.)
