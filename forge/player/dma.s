; DMA video player with PWM/PCM audio for Durango-X!
; (c) 2021-2022 Carlos J. Santisteban
; last modified 20211022-1724

; *** new multiformat version ***
; supported formats are combinations of 50/25 fps, hires/colour and PWM/PCM sound
; the latter needs support from the DMA board, a '174 may provide decent 6-bit output
; mono/colour (including greyscale) is just a matter of setting video flags before playback
; 25fps mode swaps VRAM every TWO frames, thus uses the last TWO pages for soundtrack
; because of the non-standard frame rate, sound is 237/474 bytes per frame, page-aligned for each frame
; PCM sound is free from bit shifting, allowing a crude two-times oversampling digital filter

; *** proposed header format ***
; typical minimOS stuff, starts as $00, $61, $4D which includes 'aM' as generic movie file signature
; flags at offset 3 are HI11Cxxx to be set directly into $DF80...
; ...where H=hires mode (256x248/240), I=inverse, C=colour enable (instead of grey, unused in hires)
; flags at offset 4 are FArrrrrr and indicate frame rate and audio format...
; ...where F means 25fps (instead of 50) and A indicates 8-bit PCM (instead of PWM)
; all bits 'x' are irrelevant, and bits 'r' are reserved for future format options
; *** *** consider using HI11CFAx instead and then 3-byte mod255 frame count *** ***
; at offset 5 there is $xx, $xx, $0D, then a NULL-terminated filename
; after that, some NULL-terminated comment (could be empty as long as the second terminator is there) 
; offset $F8 may have timestamp in MS-DOS format
; offset $FC is 32-bit filesize, thus actual maximum play time is 512ki-frames or 5.8h (at 25fps)
; *** might encode somewhere the number of frames in mod255 format for easier timer setting! ***

; *** required variables ***

	.zero

	* = 3					; minimOS-savvy ZP address

zlimit	.word	0			; 256*number of frames (every byte +1 mod 256 for easier DEC)
zdelay	.byt	0			; spare byte
zptr	.word	0			; pointer for indirect-indexed addressing
zfmt	.byt	0			; format flags

	.text

; *** hardware definitions ***
	IOBeep	= $DFB0			; previously $Bxxx, only D0 checked
	IO8sync	= $DF88			; D6=VBLANK
	PWMdata	= $7F00			; last 256 bytes is where the audio track is! valid for PCM too
	PCMdata	= $7E00			; new extra audio track for 25 fps playback, valid for PWM too 
	SDswap	= $5F00			; DMA signal port (placeholder)

; *** player code ***

	* = $400				; downloadable version

	SEI						; standard init
	CLD
	LDX #$FF
	TXS

; must locate file in card *** TBD

next:						; placeholder
; assume zptr pointing to SD-card buffer
; check for a valid header
	LDY #0					; might use absolute indexed instead?
	LDA (zptr), Y
	BNE next				; not valid
	INY
	LDA (zptr), Y			; check first signature byte
	CMP #'a'				; generic file
	BNE next
	INY
	LDA (zptr), Y			; check second
	CMP #'M'				; movie file
	BNE next
	LDY #7					; advance to end of initial header
	LDA (zptr), Y			; check magic
	CMP #NEWLINE
	BNE next
; might check filename by advancing Y

; must set video flags from offset 3 in header *** STUB
	LDY #3
	LDA (zptr), Y			; get video flags
	STA IO8attr				; set hardware accordingly
; check flags at offset 4 for frame rate and audio format *** STUB
	INY
	LDA (zptr), Y			; get framerate and format
	STA zfmt				; store as more things needed before!

; must set X and zlimit's 2 bytes as 24-bit number of frames to be played
; note that all values are +1 mod 256 *except* X which is +1 mod 255! (won't stay at zero)

; get back to begin of file (header is actually 'visible' in first frame)

; wait for VBLANK
skip:
	BIT IO8sync				; are we already on VBLANK?
	BVS skip				; let's wait for next field, just in case
sync:
	BIT IO8sync				; waiting for the next VBLANK
	BVC sync
; and then send a signal to the DMA board! *** TBD
	STA SDswap				; signal to DMA board! (placeholder)


; ready to go, jump to appropriate player code
	BIT zfmt				; retrieve format
	BMI fps50				; easy initial check
		BVC pwm25
; if arrived here, it's 25fps PCM
			;JMP pcm25p
pwm25:
; jump to 25fps PWM
		;JMP pwm25p
fps50:
		BVC pwm50p
; if arrived here, it's 50fps PCM
			;JMP pcm50p
; otherwise is the 'original' 50fps PWM

; ************************************
; *** playback code for 50 fps PWM ***
; ************************************
pwm50p:
; if every frame carries just 237 samples every 129t, jitter is just +3t!
; plus +1t microjitter every sample, D7 is 17/16 times the standard value
; total jitter per frame 4t or 2.6 µs
; actual sampling rate would be ~11906 Hz (recorded at ~11850.2)
; fv is actually 50.23547880690738 Hz or ~0.471% faster
; final values are one bit every ~16t
; every 237 samples wait 3t, may signal DMA board too
; in order to allow end-of-file detection, this timing is used
; 15-15-16-18-15-16-16-18 = 129t
; anyway, some delay (~5 µs) will happen every ~22 minutes, with a maximum playing time of ~92 h of exactly 127.5 GiB (!)

	LDY #0					; reset pointer to fixed buffer
loop:
	STY zdelay				; timing adjustment (3+2)
	NOP
fast:
	LDA PWMdata, Y			; get chunk of data (4 before counting, deduct from end anyway)
; d0 has 15t until next bit
	STA IOBeep				; loaded D0 is out, order is actually irrelevant (4, 11* to go)
	STY zdelay				; (3+3x2, 2 to go just before LSR)
	NOP
	NOP
	NOP
	LSR						; checking D1 now (2, we're on time)
; d1 has 15t too
	STA IOBeep				; output on time (4, 11* to go)
	STY zdelay				; (3+3x2, 2 to go just before LSR)
	NOP
	NOP
	NOP
	LSR						; checking D2 now (2)
; d2 has 16t (counts new frame in X)
	STA IOBeep				; output on time (4, 12 to go)
	CPY #0					; just changed page? (2, 10 to go)
	BEQ field				; must modify counter(s) (3, 7 to go)
	BNE d3					; otherwise adjust delay and continue (2+3, 5 to go)
field:
		DEX					; count this new frame (2, 5 to go)
d3:
	STY zdelay				; (3, 2 to go in any case)
	LSR						; checking D3 now (2)
; d3 has 18t, sometimes much more (if X = 0, 255 frames has passed, increment RAM counter)
	STA IOBeep				; output on time (4, 14* to go)
	CPX #0					; 255 frames done? (2, 12 to go)
	BNE dd3					; no, just continue but equalising delays (3, 9 to go including 3t for return)
		DEC zlimit			; change counter LSB (2+5 if here, 5 to go)
		BNE d4				; won't wrap LSB, thus jump to LSR in time (3, 2 to go as expected) 
; *** will arrive here every ~22 minutes, will delay audio a bit for the MSB update and check ***
			DEC zlimit+1	; update MSB (2+5, we're past 5)
			BEQ end			; if down to zero, film is over (if not, 2 for past 7t or ~4,6 µs every 22 minutes)
; *** worst case for a full-length file would be ~1.2 ms delay, not terrible ***
d4:
	LSR						; checking D4 now (2)
; d4 has 15t (will wrap X if 0, so won't trigger RAM counters again)
	STA IOBeep				; output on time (4, 11 to go)
	CPX #0					; 255 frames done? (2, 9 to go)
	BEQ page				; yes (3, 6 to go) or no (2, 7 to go)
	BNE d5					; (3, 4 to go)
page:
		DEX					; won't repeat check, thus MOD 255 (2 if done, 4 to go)
d5:
	NOP						; (2 to arrive at LSR with 2 to go)
	LSR						; checking D5 now (2)
; d5 takes the standard 16t
	STA IOBeep				; output on time (4, 12 to go)
	NOP						; (5x2)
	NOP
	NOP
	NOP
	NOP
	LSR						; checking D6 now (2)
; d6 is standard 16t too (will INY)
	STA IOBeep				; output on time (4, 11* to go)
	STY zdelay				; I was missing one cycle, thus D6 is 15t, D7 will be 18 and the rest 16, for a total of 129 (3, 8 to go)
	NOP						; special timing adjustment for -1 microjitter (2x2, 4 to go)
	NOP
	INY						; *** get ready for next byte! (2, 2 to go which is the LSR)
	LSR						; checking D7 now (2)
; lastly, d7 is 18t (checks Y wrap and signals frame change)
	STA IOBeep				; output on time (4, but 14 to go as this has +2 microjitter too)
	CPY #237				; are we done with this field? (2, 12 to go)
	BNE loop				; if not, get another byte! (3, 9 to go... which will load A anyway)
		STY SDswap			; otherwise tell DMA card to load next frame (2+4 but must add 3, thus 9 to go anyway)
		LDY #0				; Y will not wrap! eeeeeek (2, 7 to go and not yet loaded!)
	BEQ fast				; repeat always (3 with 4 to go which is the direct load)

; *** special delay routine *** 7t
dd3:
	NOP
	NOP
	JMP d4					; return to main loop (2+2+3, 2 remaining to go for the LSR)

; *** *** done *** ***
end:
	STY IOBeep				; turn beeper off, just in case (Y known to be zero)
lock:
	BEQ lock				; no need for BRA

; ***
