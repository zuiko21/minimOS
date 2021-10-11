; DMA video player with PWM audio for Durango-X!
; (c) 2021 Carlos J. Santisteban
; last modified 20211011-1907

; *** required variables ***

	.zero

	* = 3					; minimOS-savvy ZP address

zlimit	.dsb	3, 0		; number of frames (every byte +1 mod 256 for easier DEC)
zdelay	.byt	0			; spare byte

	.text

; *** hardware definitions ***
	IOBeep	= $DFB0			; previously $Bxxx, only D0 checked
	IO8sync	= $DF88			; D6=VBLANK
	PWMdata	= $7F00			; last 256 bytes is where the audio track is!
	SDswap	= $5F00			; DMA signal port (placeholder)
	
; *** player code ***

	* = $400				; downloadable version

	SEI						; standard init
	CLD
	LDX #$FF
	TXS

; must locate file in card *** TBD

; must set zlimit's 3 bytes as 24-bit number of frames to be played *** NO WAY TO CHECK?

; wait for VBLANK
skip:
	BIT IO8sync				; are we already on VBLANK?
	BVS skip				; let's wait for next field, just in case
sync:
	BIT IOsync				; waiting for the next VBLANK
	BVC sync
; and then send a signal to the DMA board! *** TBD
	STA SDswap				; signal to DMA board! (placeholder)

; if every frame carries just 237 samples every 129t, jitter is just +3t!
; plus +1t microjitter every sample, D7 is 17/16 times the standard value
; total jitter per frame 4t or 2.6 µs
; actual sampling rate would be ~11906 Hz (recorded at ~11850.2)
; fv is actually 50.23547880690738 Hz or ~0.471% faster
; final values are one bit every 16t (17 for D7, actually)
; every 237 samples wait 3t, may signal DMA board too

	LDY #0					; reset pointer to fixed buffer
loop:
	STY zdelay				; timing adjustment (3+2)
	NOP
fast:
	LDA PWMdata, Y			; get chunk of data (4 before counting, deduct from end anyway)
	STA IOBeep				; loaded D0 is out, order is actually irrelevant (4, 12 to go)
	NOP						; (5x2)
	NOP
	NOP
	NOP
	NOP
	LSR						; checking D1 now (2, we're on time)
	STA IOBeep				; output on time (4, 12 to go)
	NOP						; (5x2)
	NOP
	NOP
	NOP
	NOP
	LSR						; checking D2 now (2)
	STA IOBeep				; output on time (4, 12 to go)
	NOP						; (5x2)
	NOP
	NOP
	NOP
	NOP
	LSR						; checking D3 now (2)
	STA IOBeep				; output on time (4, 12 to go)
	NOP						; (5x2)
	NOP
	NOP
	NOP
	NOP
	LSR						; checking D4 now (2)
	STA IOBeep				; output on time (4, 12 to go)
	NOP						; (5x2)
	NOP
	NOP
	NOP
	NOP
	LSR						; checking D5 now (2)
	STA IOBeep				; output on time (4, 12 to go)
	NOP						; (5x2)
	NOP
	NOP
	NOP
	NOP
	LSR						; checking D6 now (2)
	STA IOBeep				; output on time (4, 11* to go)
	STY zdelay				; I was missing one cycle, thus D6 is 15t, D7 will be 18 and the rest 16, for a total of 129 (3, 8 to go)
	NOP						; special timing adjustment for -1 microjitter (2x2, 4 to go)
	NOP
	INY						; *** get ready for next byte! (2, 2 to go which is the LSR)
	LSR						; checking D7 now (2)
	STA IOBeep				; output on time (4, but 14 to go as this has +2 microjitter too)
	CPY #237				; are we done with this field? (2, 12 to go)
	BNE loop				; if not, get another byte! (3, 9 to go... which will load A anyway)
		STY SDswap			; otherwise tell DMA card to load next frame (2+4 but must add 3, thus 9 to go anyway)
		LDY #0				; Y will not wrap! eeeeeek (2, 7 to go and not yet loaded!)
	BEQ fast				; (3 with 4 to go which is the direct load)
; should check for end of file somehow

; done
	STY IOBeep				; turn beeper off, just in case (Y known to be zero)
lock:
	BEQ lock				; no need for BRA

