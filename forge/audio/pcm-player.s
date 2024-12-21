; TriPSG PCM bankswitching player (16K banks)
; (c) 2024 Carlos J. Santisteban
; last modified 20241222-0004

; will use all but last page (accessed at $8000-$BFFF thus NOT affected by I/O)
; player code repeated at every bank

.(
; *** hardware definitions ***
; standard Durango hardware
screen	= $6000
IO8mode	= $DF80
IO9kbd	= $DF9B
IOAint	= $DFA0
; Tri-PSG+PCM (or Durango PLUS) ports
IOPSG_L	= $DFD3
IOPSG_R	= $DFD7
IO_PSG	= $DFDB				; PSG addresses (just to be inited)
IOPCM	= $DFDF				; DAC output
IObank	= $DFFF				; bankswitching cartridge

; *** memory usage ***
ptr		= $FC				; standard sysptr (memory cursor)
bank	= $FE				; standard systmp (current bank)
data	= $8000				; mirrored ROM start
end		= $BF00				; first byte of code, not data

; *******************
; *** player init ***
; *******************
	*	= $FF00				; player code at last page
reset:
	SEI
	CLD
	LDX #$FF
	TXS						; standard 6502 init
; Durango init
;	STX IOAint				; turn off LED
	LDA #$38				; colour mode
	STA IO8mode
	LDA #$80				; centered zero value
	STA IOPCM
; PSG init ASAP!
	LDA #255				; mute channel 4
psg_init:
		STA IO_PSG
		STA IOPSG_L
		STA IOPSG_R			; send value to all PSGs
		ROL screen			; extra delay
		SEC
		SBC #32				; next channel
		JSR delay
		BMI psg_init		; until all 4 channels done (every 37t)
; clear screen
	LDX #>screen			; screen page
	LDY #0					; must be zero!
	LDA #0					; or whatever background colour
	STY ptr					; no need for STZ
cl_page:
		STX ptr+1			; update page
clear:
			STA (ptr), Y	; clear byte
			INY				; next
			BNE clear
		INX					; next page
		BPL cl_page			; until RAM ends
; minimal interface on screen
	LDA #$22				; both red for STOP (NMI)
	STA screen
	STA screen+$41
	LDA #$20				; left pixel only (down)
	STA screen+$40
	LDA #2					; right pixel only (up)
	STA screen+1
	LDA #$55				; both green for PLAY (SPACE)
	STA data-1
	STA data-$C1
	LDA #$50				; left pixel on second raster
	STA data-$41
	LDA #5					; right pixel on third raster
	STA data-$81
; rewind player!
	LDX #>data				; ROM start address (could use one more, allowing room for header!)
	LDY #<data
	STX ptr+1				; update page pointer (LSB will be done later)
	STZ bank				; always bank 0 after reset
; wait for SPACE to play
pause:
	LDA #1					; first column
	STA IO9kbd
	STA IOAint				; make sure LED is off (not playing)
wait:
		LDA IO9kbd			; get row
		BPL wait			; until row 8 is set (d7)
	STZ IOAint				; turn LED on as it's playing
	STZ IO9kbd				; deselect column for power saving
; *** main playing loop ***
; select appropriate delay for playback rate (baseline is 41t)
;	Fs (Hz)	1.536 MHz	1.75 MHz	2 MHz (o.c.)	3.5 MHz (v2)	128K PB time
;	8000		151			178			209				397				16.1 s
;	12000		 87			105			126				251				10.8 s
;	16000		 55			 68			 84				178				 8.1 s
;	22050		 29			 38			 50				118				 5.9 s
;	31250		  8			 15			 23				 71				 4.1 s
;	44100		-			-			  4				 38				 2.9 s
;	48000		-			-			 ~0				 32				 2.7 s
loop3:
		STZ ptr				; 3
		LDA ptr				; 3
		LDA ptr				; 3 (9)
loop2:
			JSR delay		; 6+6
			LDA ptr			; 3
			LDA ptr			; 3 (18)
loop1:
; additional delay set here for a certain sample rate (ex. 178, 16kHz @ v2T)
;				JSR delay	; for 12kHz @ v2T
;				LDA screen	; +4 = 175 (remove for 12kHz)
;				LDA ptr		; +3 = 178 (remove for 12kHz)
;				LDA #10		; 10x17+1=171 (#14 for 12kHz @ v2T)
; another example, 87t for 12 kHz @ v1
				JSR delay	; for 12kHz @ v1
				LDA ptr
				LDA ptr		; additional 18t + 4*17 +1 = 87t
				LDA #4		; one less because of rounding!
d_loop:
					JSR delay		; 12n
					DEC				; 2n
					BNE d_loop		; 3n, total = 17n+1
; get samples and play them
				LDA (ptr), Y		; 5
				STA IOPCM	; 4
				INY			; 2
				BNE loop3	; 3/2 (14)
			INX				; 2
			STX ptr+1		; 3
			CPX #>end		; 2
			BNE loop2		; 3/2 (23)
		INC bank			; 5
		LDA bank			; 3
		STA IObank			; 4
		LDX #>data			; 2
		STX ptr+1			; 2
		BRA loop1			; 3 (max.41)
; *** delay routine ***
delay:
	RTS						; 6 plus 6 of calling overhead

; *** interrupt handler (spurious) ***
irq:
	RTI

; ************************
; *** standard ROM end ***
; ************************
	.dsb	$FFD6-*, $FF	; filling
	.asc	"DmOS"			; usual ROM signature

	.dsb	$FFE1-*, $FF	; Durango devCart is *not* supported, but anyway
	JMP ($FFFC)

	.dsb	$FFFA-*, $FF	; fill until 6502 hard vectors
	.word	pause			; NMI will pause, SPACE will resume/start play
	.word	reset			; RESET will rewind and stop as well
	.word	irq
.)
