; firmware module for minimOS·65
; (c) 2021 Carlos J. Santisteban
; last modified 20211230-0020

; *** init CONIO in durango, as interrupts are already set up ***
; *** firmware variables to be reset upon FF ***
; fw_ccol.p (SPARSE array of two-pixel combos, will store STD_INK & STD_PPR)
;  * now reduced to simple 00.01.10.11 array
; fw_ciop.w (upper scan of cursor position)
; fw_fnt.w (new, pointer to relocatable 2KB font file)
; fw_mask (for inverse/emphasis mode)
; fw_cbin (binary or multibyte mode)

; NMOS (with macros) and 65816 savvy

; *** default colours *** globally defined
#define		STD_PPR		0
#define		STD_INK		15

.(
; set default colours
	LDA #STD_PPR*17			; twice the colour code
	STA fw_ccol
	AND #$F0				; keep STD_PPR in high nibble
	ORA #STD_INK			; STD_PPR-STD_INK
	STA fw_ccol+1
	LDA #STD_INK*17			; all STD_INK
	STA fw_ccol+3
	AND #$F0
	ORA #STD_PPR			; STD_INK-STD_PPR
	STA fw_ccol+2
; set default font
	LDY #<cio_fnt			; get exported address
	LDX #>cio_fnt
	STY fw_fnt				; set firmware font address
	STX fw_fnt+1
; set other variables
	_STZA fw_cbin			; allow normal mode at startup
	_STZA fw_mask			; non-inverted
; compute actual video address for cursor
	LDA IO8attr				; get video flags
	AND #%00110000			; filter screen-block bits
	ASL						; times two, 8 kiB blocks
	TAX						; save base for later
#ifdef	SAFE
; *** should check whether 0 -> 8 kiB RAM systems must use bottom half!
	BNE dx_p8k
		LDA #%00010000		; base address is 4K
dx_p8k:
#endif
	STA fw_vbot				; this one before!
	ORA #%00000100			; skip the 1K banner in screen!
	STA fw_ciop+1			; set cursor position
	TXA						; now for the end address, C known clear
	ADC #$20				; from hardware address, valid in all cases
	STA fw_vtop
	_STZA fw_ciop			; always page-aligned
.)
