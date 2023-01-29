; nanoLink demo loader
; devCart version!
; (c) 2023 Carlos J. Santisteban
; last modified 20230128-2353

; *** definitions ***
ptr		= $FC
link_en	= $FF				; set to 8 if enabled, 0 if disabled
l_boot	= $100				; boot enable flag ($4B bootable, $4E data)
link_pt	= $103				; start address copy
link_st	= $105				; link status, $4B/4C header received, $FF receiving data, $00 idle
ticks	= $206
IO8attr	= $DF80
IO9kbd	= $DF9B
IOAen	= $DFA0
IOBeep	= $DFB0
IOCart	= $DFC0

#define	NANOLINK
; specific nanoLink limit *** new ***
linktop	= $FA				; address of receiving limit (non-inclusive)
; standard minimOS interrupt-reserved variables
sysptr	= $FC				; download buffer pointer
systmp	= $FE				; temporary bit shifting
sys_sp	= $FF				; bit counter, set to 8 to enable, set to zero to disable
; standard minimOS firmware interrupt vectors
fw_irq	= $0200
fw_nmi	= $0202

	* = $C000				; devcart takes no more than 16K ROM

reset:
	SEI
	CLD
	LDX #$FF
	TSX						; usual 6502 stuff, SP setting is important
	STX IOAen				; enable hard interrupts, turn error LED off
	LDA #$38				; colour mode, RGB, screen 3
	STA IO8attr
; init interrupt vectors
	LDX #>rcv_nmi
	LDY #<rcv_nmi
	STY fw_nmi
	STX fw_nmi+1
	LDX #>std_isr
	LDY #<std_isr
	STY fw_irq
	STX fw_irq+1
; clear the screen
	LDX #$60				; screen start
	LDY #0
	STY ptr
	STY link_st				; extra header init (0 = idle)
	STY IOCart				; just in case
	TYA
p_loop:
		STX ptr+1			; update MSB
b_loop:
			STA (ptr), Y
			INY
			BNE b_loop
		INX
		BPL p_loop
; set everything for header reception
	LDA #$88				; blue as enabled
	JSR bottom				; display bottom row
	LDA #1
	STA ptr+1
	STZ ptr					; set stack page for header!
	LDA #8
	STA link_en				; link enabled
; *** main loop ***
loop:
; check for received header
		LDA link_st
		CMP #$4B
			BEQ prepare		; valid header detected
		CMP #$4E
			BNE not_head	; no header
prepare:
			LDX #4			; will copy 4 bytes ($101-$104)
l_loop:
				LDA l_boot, X			; original header data
				STA linktop-1, X		; copy into NMI space (note offset)
				DEX
				BNE l_loop
			DEX
			STX link_st		; status $FF, active load
			TXA
not_head:
; update loading progress indicator
;		LDA link_st
		CMP #$FF			; load in progress?
		BNE not_load
			LDX ptr+1		; check MSB
			LDA #$55		; light green
			STA $7F00, X	; place elongated dot on bottom row
not_load:
		LDA link_en			; disabled state?
		BNE not_disabled
			JSR display		; show time progression
			LDA #1			; select column 1
			STA IO9kbd
			BIT IO9kbd		; SPACE = d7, ENTER = d6
			BVC not_disabled
				LDA #8
				STZ link_en		; ENTER pressed, enable nanoLink
				LDA #$88		; blue
				JSR bottom
not_disabled:
; check if load ended
		LDA link_en
		BNE not_ended
			LDA ptr
			CMP linktop
				BNE not_ended
			LDA ptr+1
			CMP linktop+1
			BNE not_ended
; execute loaded code or simply notify user
				LDA l_boot	; check flag
				CMP #$4B	; bootable?
				BNE no_boot
; if executable is not a ROM image, just execute it
					LDA linktop
					ORA linktop+1		; zero if last byte was at $FFFF
					BEQ switch
						JMP (link_pt)	; start address copy
switch:
; if bootable ROM image, make it switch to RAM
					SEI
					LDA #%01100000		; ROM disabled, protected mode
					JMP $FFDE			; standard switchpoint
no_boot:
; beep and flash to indicate data loaded
				LDA #64		; inverse mode
				TSB IO8attr	; set inverse bit
				LDX #0
				SEI
cycle:
					LDY #153 
beep:
						DEY
						BNE beep
					INX
					STX IOBeep
					BNE cycle
				CLI
				TRB IO8attr	; clear inverse bit
				STZ link_st	; ready for another one
not_ended:
		LDA #1				; select column 1
		STA IO9kbd
		BIT IO9kbd			; SPACE = d7, ENTER = d6
		BPL no_space
			STZ link_en		; SPACE pressed, disable nanoLink
			LDA #$22		; red
			JSR bottom
no_space:
		JMP loop

; *** support routines ***
bottom:
; set bottom row in color stated in A
	LDX #0
bot_loop:
		STA $7F00, X
		INX
		BNE bot_loop
	RTS

display:
; show timer in hex
	LDX #$7E
	LDY #$B8				; position of first digit
;	STY ptr
	STX ptr+1				; pointer complete, use only during disabled state
	LDA ticks+2
	PHA
	LSR
	LSR
	LSR
	LSR
	JSR figure
	PLA
	AND #15
	LDY #$BA
	JSR figure
	LDA ticks+1
	PHA
	LSR
	LSR
	LSR
	LSR
	LDY #$BC
	JSR figure
	PLA
	AND #15
	LDY #$BE
;	JSR figure
figure:
; display number in A at offset Y
	STY ptr
	TAX
	LDA numbers, X
	STA (ptr)
	LDA numbers+16, X
	LDY #$40
	STA (ptr), Y
	LDA numbers+32, X
	LDY #$80
	STA (ptr), Y
	LDA numbers+48, X
	LDY #$C0
	STA (ptr), Y
	LDA numbers+64, X
	INC ptr+1				; page crossing!
	STA (ptr)
	RTS

; *** tables *** hex numbers, yellow on red
numbers:
;			0	1	2	3	4	5	6	7	8	9	A	B	C	D	E	F
	.byt	$77,$27,$77,$77,$77,$77,$77,$77,$77,$77,$77,$72,$22,$27,$77,$77	; row 1
	.byt	$77,$27,$27,$27,$77,$72,$72,$27,$77,$77,$27,$72,$22,$27,$72,$72	; row 2
	.byt	$77,$27,$77,$77,$77,$77,$77,$27,$22,$77,$77,$77,$77,$77,$77,$77	; row 3
	.byt	$77,$27,$72,$27,$27,$27,$77,$27,$77,$27,$77,$77,$72,$77,$72,$72	; row 4
	.byt	$77,$27,$77,$77,$27,$77,$77,$27,$77,$77,$77,$77,$77,$77,$77,$72	; row 5

; *** interrupt handlers ***
irq:
	JMP (fw_irq)
nmi:
	JMP (fw_nmi)
; *** standard ISR ***
std_isr:
	INC ticks
	BNE isr_end
		INC ticks+1
	BNE isr_end
		INC ticks+2
isr_end:
	RTI
; *** nanoLink package ***
#include "nmi.s"

loader_end:

; *** ROM filling ***

	.dsb	$FFD6-*, $FF
	.asc	"DmOS"			; standard signature

	.dsb	$FFDE-*, $FF
	STA IOCart				; switch ROMs @ $FFDE
	JMP ($FFFC)				; warm reset, should be in image at $FFE1

	.dsb	$FFFA-*, $FF	; standard vectors
	.word	nmi
	.word	reset
	.word	irq
