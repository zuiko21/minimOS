; *** convert raster in A into a 16bit raster ***
; *** for Tampico's optional colour mode ***
; (c) 2020-2022 Carlos J. Santisteban
; last modified 20201023-2003

; first approach, outside ZP takes 20b, 305t (using ZP goes down to 16b, 273t)
	LDX #8				; set bit counter (2)
loop:
		ASL					; get MSB first (2)
		PHP					; keep Carry for next iteration! (3)
		ROL temp			; insert once into word (6+6)
		ROL temp+1
		PLP					; retrieve original Carry to repeat bit! (4)
		ROL temp			; insert twice into word (6+6)
		ROL temp+1
		DEX					; next bit (2)
		BNE loop			; until whole byte is done (3)

; another approach uses temporarily memory for the source, rotating into A
; this takes 24b, 283t (7.2% faster) outside ZP
; ZP use will take just 19b, 255t (6.6% faster)
	STA temp+1			; not the MSB yet, but temporary source (4)
	LDX #8				; set bit counter (2)
loop:
		ASL temp+1			; get MSB first (6)
		PHP					; keep Carry for next iteration! (3)
		ROL temp			; insert once into word (6+2)
		ROL
		PLP					; retrieve original Carry to repeat bit! (4)
		ROL temp			; insert twice into word (6+2)
		ROL
		DEX					; next bit (2)
		BNE loop			; until whole byte is done (3)
	STA temp+1			; complete word in memory (4)
