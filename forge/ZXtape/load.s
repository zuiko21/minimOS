; minimOS ZX tape interface loader!
; v0.1a3
; (c) 2016 Carlos J. Santisteban
; last modified 20160807-1613

; ***** Load block of bytes at (data_pt), size stored at data_size *****
; ****   ONLY if enabled by setting 'flag' to look for data ($FF) ****
; ****   otherwise will wait for the discarded block to end without loading ****
; ****   because it will keep looking for a header ($00) ****
; ***** If detected, 17 byte header gets loaded at (data_pt) *****
; ****   because flag is set to look for a header ($00) ****

; *** needed data ***
; ddrx = VIA DDRx
; px6in = VIA IORx, easy detection via BIT instruction (V) though not used!
; speedcode = stores CPU speed in fixed point format ($10 = 1 MHz)
 mask = %01000000  ; preset for bit 6 but change otherwise
 
; *** zeropage ***
; pointer (word)
; length (word) is best on ZP
; last will actually hold the relevant bit read from the port
; sys_sp is safe to use when interrupts are disabled

; *** REFERENCE: pulse lengths ***
; guide tone = 619/619 uS (cycle 1.238 mS) 
; sync = 191/210 uS
; zero = 244/244 uS (cycle 488 uS)
; one = 489/489 uS (cycle 978 uS)

; *** ADVICE ***
; wait about 102 uS before entering timing loop
; compare against 686 uS ???
; other looks for 314 uS? (one vs zero?)
; 'ld edge 1' takes 133 uS + 17 for each failed pass
;   and will return with NO Carry if no edge found within 4 mS
;     otherwise wait for a second and continue if TWO edges within time frame (ld edge 2)
;   now accept only guide, timing $9C, but edges must be within 857 uS (B=$C6)
;     needs at least 256 pairs
;   for sync, timing is $C9 waiting for a single short edge (ld edge 1)
;     keep waiting against $D4, call 'ld edge 1' again for the other edge
;   reading bits use timing $B0 ($B2 for flag?)
; * two pulses in less than 713 uS means 0, otherwise 1, timeout after 1575 uS *

zx_load:

; disable interrupts!!!
	_ENTER_CS	; actually PHP and SEI
	
; initialise input port
	LDA ddrx	; previous data direction register on VIA
	AND #%10111111	; make sure bit 6 is input
	STA ddrx	; set direction, port is ready
	LDA px6in	; get whole byte
	AND #mask	; filter bit 6 or whatever
	STA last	; set initial value as only transitions will matter

; *** get a couple of edges, much like the original ***

ld_edge2:

	JSR ld_edge1	; get first edge
	BCS ld_edge1	; if successful, go for the second one
		RTS		; otherwise return with C clear and Z set, timeout 

; *** get timed edge, named much like the original ***
; Y = preloaded with max time, will go down to zero upon timeout
; returns with C if edge found, otherwise Z means timeout
; both C and Z clear means BREAK was pressed (not yet implemented)

ld_edge1:

; previous delay, 115 uS @ 1 MHz, 112.2 uS @ 14 Mhz
; remove NOP for 83 uS @ 1 MHz, 80 uS @ 14 MHz
; extra NOP does 147 uS @ 1 MHz, 144.2 uS @ 14 MHz

	LDX speedcode	; (4) adjust for CPU speed
ld_delay:
		NOP		; (2*) lose some time
		DEX		; (2*) count depending on CPU speed
		BNE ld_delay	; (3*) wait before entering sampling loop
		
; now wait for an edge
; new algorithm, somewhat faster
;   Y:  1 MHz 14 Mc (uS)
; -----+-----+-----
;    1   271   257
;    2   535   514
;    3   799   770

;   Y:    -   1 NOP 2NOPs (total delay @ 1 MHz)
; -----+-----+-----+-----
;    1   354   386   418
;    2   618   650   682
;    3   882   914   946

edge_loop:
	LDX speedcode	; (4*) reload correction factor
bit_loop:
		LDA px6in	; (4**) get whole byte
		AND #mask	; (2**) filter bit 6 or whatever
		CMP last	; (3**) compare against previous value
		BNE changed	; (2**) if did not change, keep waiting and counting
; increase count and check for timeouts
			DEX		; (2**) CPU speed dependent counter
		BNE bit_loop	; (3**) continue checking
			DEY		; (2*) 'absolute' timing counter
		BNE edge_loop	; (3*) wait for edge or timeout
; no edge found within expected timeframe
		CLC		; (2+6) no edge found, and Z means timeout
; *** if available, BREAK key should return with CLC and _NOT_ Z
		RTS
changed:
; edge was found
	STA last	; (3) update with new value
	SEC		; (2+6) found edge within timeframe
	RTS

