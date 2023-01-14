; nanoLink demo game
; (c) 2023 Carlos J. Santisteban
; last modified 20230114-1905

; *** memory allocation ***
posbuf		= $F0			; received coordinates (YYYYXXXX), 1-based
mypos		= $F4			; ditto for local player
oldpos		= $F5			; previous challenger position
pad_mask	= $F8			; single pad stuff
pad_value	= $F9
old_pad		= $FA			; avoid continuous
demo_ptr	= $EA

; *** hardware definitions ***
IO8attr		= $DF80
IO8blnk		= $DF88
IO9kbd		= $DF9B
IO9pad1		= $DF9C
IO9pad2		= $DF9D
IO9nes_lat	= IO9pad1
IO9nes_clk	= IO9pad2
IOAie		= $DFA0

; ************
; *** code ***
; ************

	* = $C000				; for 16K EPROM
	.dsb	$FE00-*, $FF
;	*	= $FE00				; 512b should be enough!

; *** external stuff ***
; nanoLink send routine
send:
#include "send.s"

; nanoLink alternative interrupt handlers
nmi:						; non-vectored for performance
#include "nmi.s"

reset:
	STZ sys_sp				; disable nanoLink for a moment!

	SEI						; continue with usual 6502 stuff
	CLD
	LDX #$FF
	TXS

	STX IOAie				; Durango-X specifics, turn ERROR LED off
	LDA #$38
	STA IO8attr				; colour mode, screen 3, RGB
	STZ pad_mask
	JSR readpad
	LDA pad_value			; eeeeeek
	STA pad_mask			; returns with mask in A -- NOPE!
	STZ pad_value
; clear screen ASAP
	LDX #$60				; screen 3 MSB
	LDY #0					; screen 3 LSB, must be zero
	TYA						; black as standard
	STY demo_ptr
cl_pg:
		STX demo_ptr+1
cl_byt:
			STA (demo_ptr), Y	; clear screen byte
			INY
			BNE cl_byt
		INX					; next page
		BPL cl_pg			; screen 3 ends at the last positive page
; init some game data
	LDY #$88				; around the centre of the screen
	STY mypos
	JSR draw_me				; standard appearance
	STZ oldpos				; will keep display disabled until connection
; init interrupt stuff
	LDY #<isr
	LDX #>isr
	STY fw_irq
	STX fw_irq+1			; as defined in nmi.s
	CLI						; good to go!
; init nanoLink
	LDY #<posbuf
	LDX #>posbuf			; actually zero
	STY sysptr
	STX sysptr+1			; set nanoLink buffer pointer, this one could be STZ if in ZP
	STZ posbuf				; clear by default = not received
	LDA #8					; 8 bits per byte, starting value
	STA sys_sp				; start connection!

; *** main loop ***
loop:
; check pad action and redraw player if moved
		LDA pad_value		; AtBeULDR
		CMP old_pad			; some changes?
			BEQ no_move
		STA old_pad			; if so, take note
		BIT #1				; check Right
		BEQ not_right
			LDA mypos
			AND #15			; check X
			CMP #15			; must be below this
			BCS cant_right
				JSR clear_me	; clear previous
				INC mypos	; X++
				JSR draw_me	; and show new
cant_right:
			LDA pad_value	; reload
not_right:
		BIT #4				; check Left
		BEQ not_left
			LDA mypos
			AND #15			; check X
			CMP #2			; must be this or higher
			BCC cant_right
				JSR clear_me	; clear previous
				DEC mypos	; X--
				JSR draw_me	; and show new
cant_left:
			LDA pad_value	; reload
not_left:
		BIT #2				; check Down
		BEQ not_down
			LDA mypos		; Y is times 16!
			CMP #240		; must be below this
			BCS cant_down
				JSR clear_me	; clear previous
				LDA mypos
				CLC
				ADC #16		; Y++
				STA mypos
				JSR draw_me	; and show new
cant_down:
			LDA pad_value	; reload
not_down:
		BIT #8				; check Up
		BEQ not_up
			LDA mypos		; Y is times 16!
			CMP #32			; must be this or higher
			BCC cant_up
				JSR clear_me	; clear previous
				LDA mypos
				SEC
				SBC #16		; Y--
				STA mypos
				JSR draw_me	; and show new
cant_up:
;			LDA pad_value	; reload
not_up:
no_move:
; check challenger and redraw if moved (or appeared)
		LDA posbuf
		CMP oldpos
		BEQ no_chal			; eeeeeeeeeek
			LDA #<posbuf
			STA sysptr		; restore receive pointer
			LDY oldpos		; clear old position
			BEQ appear		; just arrived, do not clear
				LDX #0		; in black
				JSR draw
appear:
			LDY posbuf
			STY oldpos		; update position
			LDX #$22		; in red
			JSR draw
no_chal:
		JMP loop

; ***********************
; *** useful routines ***
; ***********************
readpad:
	STA IO9nes_lat			; latch values
	LDA #8
rp_loop:
		STA IO9nes_clk		; send clock pulse
		DEC
		BNE rp_loop
	LDA IO9pad1
	EOR pad_mask
	STA pad_value			; store corrected value
; pad emulation by keyboard (QAOP -> AtBeULDR)
	LDA #1					; most keys are on column 1
	STA IO9kbd
	LDA IO9kbd				; get this column
; Q=up (col 1 row 2) sets d3
	BIT #%00000010			; up?
	BEQ not_q
		LDA #%00001000		; set d3
		BRA addbit
not_q:
; A=down (col 1 row 3) sets d1
	BIT #%00000100			; down?
	BEQ not_a
		LDA #%00000010		; set d1
		BRA addbit
not_a:
; P=right (col 1 row 5) sets d0
	BIT #%00010000			; right?
	BEQ not_p
		LDA #%00000001		; set d0
		BRA addbit
not_p:
; O=left (col 2 row 5) sets d2
	LDA #2					; select column 2
	STA IO9kbd
	LDA IO9kbd
	BIT #%00010000			; left?
	BEQ not_o
		LDA #%00000100		; set d2
;		BRA addbit
addbit:
	TSB pad_value			; set emulated bits
not_o:
	RTS

; delete previous position
clear_me:
	LDX #0					; black as background
	LDY mypos				; current position
	JMP draw

; draw green dot at current position
draw_me:
	LDX #$55				; green
	LDY mypos				; current position
;	JMP draw

; draw some big dot of colour X at referred position Y
draw:
	TYA
	AND #$F0				; keep Y
	LSR
	LSR
	LSR						; 2 pages per row
	SEC
	SBC #2					; 0-based
	ORA #$61				; screen 3 start, OK for demo
	STA demo_ptr+1
	LDA #$83				; adequate raster offset
	STA demo_ptr
	DEY						; 0-based
	TYA
	AND #$0F				; keep X
	ASL
	ASL						; 4 bytes per column
	TAY
	TXA						; retrieve colour (II format)
	STA (demo_ptr), Y		; upper left
	INY
	STA (demo_ptr), Y		; upper right
	LDX #$C3				; offset of second raster
	STX demo_ptr			; eeeeeek
	STA (demo_ptr), Y		; lower right
	DEY
	STA (demo_ptr), Y		; lower left
	RTS


; **************************
; *** interrupt handlers ***
; **************************
irq:
	JMP (fw_irq)			; standard minimOS

; standard interrupt service routine
isr:
	PHA
	JSR readpad
; should send coordinates via nanoLink
	PHX						; send uses A & X
	LDA mypos
	JSR byte_send
	PLX
	PLA
	RTI
code_end:

; *******************************
; *** ROM padding and vectors ***
; *******************************

	.dsb	$FFD6-*, $FF
	.asc	"DmOS"			; minimOS-compliant signature

	.dsb	$FFFA-*, $FF

	.word	nmi
	.word	reset
	.word	irq
