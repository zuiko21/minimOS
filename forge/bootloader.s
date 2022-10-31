; 16K bootloader for Durango-X
; (c) 2022 Carlos J. Santisteban
; last modified 20221031-2359

; some constants (blue background, yellow ink, green progress)
#define	BGCOL	$88
#define	FGCOL	$77
#define	PRCOL	$55

; reasonable start address
		*	= $FF80

; *** hardware definitions ***
-IO8attr	= $DF80
-IO8blk		= $DF88

; *** pointers and variables ***
-fw_irq		= $0200
-fw_nmi		= $0202
ptr			= $02
rom_pg		= ptr+1
count		= ptr

boot:
; usual init, but do not enable hardware interrupts
	SEI
;	CLD						; not needed as no ADC/SBC here
	LDA #$38				; try colour mode, screen 3
	STA IO8attr
	LDX #>switch			; start of switching routine
	LDY #<switch
	STY fw_nmi				; set vectored NMI
	STX fw_nmi
; clear screen
	LDX #$60				; screen start
	LDY #0					; LSB and index reset
	LDA #BGCOL				; blue background
	STY ptr
page:
		STX ptr+1			; update MSB
clear:
			STA (ptr), Y	; set screen byte
			INY
			BNE clear		; complete page
		INX					; next page
		BPL page
; draw two lines
	LDY #1					; max offset (4 pixels wide)
	LDA #FGCOL				; yellow colour!
line:
		STA $6802, Y		; draw two lines, total height 5 pixels
		STA $6902, Y
		DEY
		BPL line
; init data
	STX ptr+1				; actually $80, start of first ROM block!
; *** main loop ***
sync:
			BIT IO8blk
			BVS sync			; if in blanking, wait for the end of it
wait:
			BIT IO8blk
			BVC wait			; wait for end of frame
; draw counter line
		LDA count
		LSR						; counter divided by 4
		LSR
		TAX						; use as index
		LDA #PRCOL				; green progress bar
		STA $7000, X			; place pixels
; draw square (2x1) on selected position @ ptr+1
		LDA rom_pg				; $80 or $C0
		CLC
		ROL						; make it 2 or 3
		ROL
		ROL
		TAX
		LDA #FGCOL				; yellow is selected
		STA $6880, X			; 2 lines below upper line
		TXA
		EOR #1					; swap 2-3
		TAX
		LDA #BGCOL				; blue is unselected
		STA $6880, X
; go for next until timeout
		INC count
		BNE sync
; *** timeout, jump to selected ROM ***
	JMP (ptr)

switch:
; *** NMI service for ROM selection ***
	PHA
	PHX
	PHY
delay:						; avoid button bounce
			INX
			BNE delay
		INY
		BNE delay
	LDA rom_pg
	EOR #$40				; switch selected ROM
	STA rom_pg
	PLY
	PLX
	PLA
	RTI

; *** standard IRQ handler ***
irq_handler:
	JMP (fw_irq)

; *** standard NMI handler ***
nmi_handler:
	JMP (fw_nmi)

; *** fill and vectors ***
	.dsb	$FFFA - *, $FF

	.word	nmi_handler
	.word	boot
	.word	irq_handler
