; nanoLink demo loader
; devCart version!
; (c) 2023 Carlos J. Santisteban
; last modified 20230130-2353

; *** definitions ***
ptr		= $F8
link_en	= $FF				; set to 8 if enabled, 0 if disabled
l_boot	= $6100				; boot enable flag ($4B bootable, $4E data)
link_pt	= $6103				; start address copy
link_st	= $6105				; link status, $4B/4C header received, $FF receiving data, $00 idle
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
	TXS						; usual 6502 stuff, SP setting is important
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
	JSR enable				; activate header reception
	CLI						; eeeeeeeek
; *** main loop ***
loop:
		LDA link_en			; is the link enabled? if so, it's either waiting or loading
		BEQ link_disabled
			LDA l_boot;link_st
			BMI loading		; status $FF while enabled means loading, otherwise is waiting
				CMP #$4B	; got a bootable header?
				BEQ do_load
					CMP #$4E			; non-bootable will load too
					BNE not_done		; otherwise is garbage
do_load:
				CMP l_boot	; check against corruption
			BNE not_done
; valid header is received, proceed with load at specified address
				LDX #4		; will copy 4 bytes ($101-$104)
l_loop:
					LDA l_boot, X		; original header data
					STA linktop-1, X	; copy into NMI space (note offset)
					DEX
					BNE l_loop
ldx#$ff;				DEX			; was 0, now $FF
				STX l_boot;link_st	; status $FF, active load
				LDY linktop+1			; check final page as marker
				LDA #$B8				; light pink just at left pixel
				STA $7F00, Y			; display dot on bottom row
				TXA			; status in A like above
loading:
; check if status is really $FF
			CMP #$FF		; really loading, not garbage header?
			BNE not_done
; actually loading, update progress bar
				LDX sysptr+1			; check MSB
				LDA #$55				; light green
				STA $7F00, X			; place elongated dot on bottom row
; should check whether transfer has ended
				LDA link_en
				BNE not_done
link_disabled:
lda l_boot;link_st
bpl not_done
					LDA sysptr
					CMP linktop
				BNE not_done
					LDA sysptr+1
					CMP linktop+1
				BNE not_done
; transfer completed successfully, execute or notify
					LDA l_boot			; check flag
					CMP #$4B			; bootable?
					BNE no_boot
; if executable is not a ROM image, just execute it
						LDA linktop
						ORA linktop+1	; zero if last byte was at $FFFF
						BEQ switch
							JMP (link_pt)		; start address copy
switch:
; if bootable ROM image, make it switch to RAM
						SEI
						LDA #%01100000	; ROM disabled, protected mode
						JMP $FFDE		; standard switchpoint
; * if executed, no longer will run from this *
no_boot:
; beep and flash to indicate data loaded
					LDA #64				; inverse mode
					TSB IO8attr			; set inverse bit
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
					TRB IO8attr			; clear inverse bit
					JSR enable			; ready for another one
not_done:
; either a load ended, or is in progress, or was aborted, or never started due to corrupt header
				LDA link_en				; is it disabled?
				BNE not_disabled
					STZ l_boot;link_st			; prevent from corrupt headers
					JSR display			; if so, keep showing time
not_disabled:
; may check if the user desires to disable the load by pressing SPACE
				LDA #1					; select column 1
				STA IO9kbd
				BIT IO9kbd				; SPACE = d7, ENTER = d6
				BPL no_space
					STZ link_en			; SPACE pressed, disable nanoLink
					STZ l_boot;link_st
					LDA #$22			; red
					JSR bottom
;					BRA no_enter		; calling bottom won't affect V flag
no_space:
; ...or if load status is to be reenabled by pressing ENTER
				BVC no_enter
					JSR enable		; ENTER pressed, enable nanoLink
					LDA #$88		; blue
					JSR bottom
no_enter:
		JMP loop

; *** support routines ***
bottom:
; set bottom row in color stated in A
	LDX #0
bot_loop:
		STA $7F00, X
		INX
		BNE bot_loop
	LDY #$F8
	TXA
bot_clear:
		STA $7E00, Y		; nicer if the remainings of numbers are deleted
		INY
		BNE bot_clear
	RTS

enable:
; activate link for next header
	LDX #>l_boot
	STX sysptr+1
	STZ sysptr				; set stack page for header!
	LDA #<link_st+1			; address $106 must be unreachable!
	STA linktop
	STX linktop+1			; set loading limit EEEEEEEEEK
	STZ l_boot;link_st				; extra header init (0 = idle)
	LDA #8
	STA link_en				; link enabled
	RTS

display:
; show timer in hex
	LDA ticks+2
	PHA
	LSR
	LSR
	LSR
	LSR
	LDX #$7E
	LDY #$F8				; position of first digit
	JSR figure
	PLA
	AND #15
	LDX #$7E
	LDY #$FA
	JSR figure
	LDA ticks+1
	PHA
	LSR
	LSR
	LSR
	LSR
	LDX #$7E
	LDY #$FC
	JSR figure
	PLA
	AND #15
	LDX #$7E
	LDY #$FE
;	JSR figure
figure:
; display number in A at address XY
	STX ptr+1
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
	.byt	$77,$07,$77,$77,$77,$77,$77,$77,$77,$77,$77,$70,$00,$07,$77,$77	; row 1, now on black background
	.byt	$77,$27,$27,$27,$77,$72,$72,$27,$77,$77,$27,$72,$22,$27,$72,$72	; row 2, yellow on red background
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
