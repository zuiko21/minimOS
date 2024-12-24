; TriPSG PCM bankswitching player (16K banks)
; (c) 2024 Carlos J. Santisteban
; last modified 20241224-1037

; will use all but last page (accessed at $8000-$BFFF thus NOT affected by I/O)
; player code repeated at every bank

.(
; *** speed definitions ***
; set delay constants for TURBO and non-TURBO machines, see table below
; now set for 12 kHz, EXACT at 3.5 MHz and very close for v1
#define	FAST_D	49
#define	SLOW_D	16

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
speed	= $FB				; new, delay constant for TURBO
ptr		= $FC				; standard sysptr (memory cursor)
bank	= $FE				; standard systmp (current bank)
ticks	= bank				; temporary use at startup
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
; new, check speed
	STX IOAint				; turn off LED and enable interrupts (still $FF)
	LDX #0
	LDY #0
	STZ ticks				; reset counters
	CLI						; interrupts are on!
first:
		LDA ticks			; check interrupt counter
		BEQ first			; until first interrupt happens
time:
			INX
			BNE time		; suitable 1279t delay
		INY					; count cycle eeek
		CMP ticks			; another change?
		BEQ time			; if so, we know the interrupt period (1287y)
	SEI						; no more interrupts!
	LDA #SLOW_D				; by default, non-TURBO delay value
	CPY #10					; TURBO threshold
	BCC slow
		LDA #FAST_D			; value for faster machines
slow:
	STA speed				; update delay constant
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
; ** ** additional delay set here for a certain sample rate ** **
				LDA speed	; get computed constant (3)
d_loop:
					DEC				; 2n
					BNE d_loop		; 3n, total = 5n+2 including LDA zp above
; fine tune adjustments (optional)
; ex. 12 kHz @ v2 needs 251t
;		setting FAST_D as 50 gives 252t or 11945 Hz (-0.4%)
;		set to 49 (247t) plus two NOPs is EXACT
; 12 kHz @ v2 non-TURBO needs 105t
;		setting SLOW_D as 21 gives 107t or 11824 Hz (-1.46%)
;		set to 20 (102t) plus LDA zp is EXACT
; alternative optimisation for 12 kHz @ v1 needs 87t
;		setting SLOW_D as 17 is EXACT
;			with two NOPs as desired for FAST, use 16 and will be 12094 Hz (+0.8%)
;		but non-TURBO v2 will do 13780 Hz (+14.8%)
;		and the rare o.c. v1, 15748 Hz (+31.2%)
				NOP: NOP	; v2-optimised
; ** ** end of delay block ** **
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
	INC ticks				; for speed check
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
