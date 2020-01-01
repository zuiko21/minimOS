; minimOS ZX tape interface loader!
; v0.1b2
; (c) 2016-2020 Carlos J. Santisteban
; last modified 20160923-0944

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
; counter is best on zp
; length (word) and checksum are best on ZP
; last will actually hold the relevant bit read from the port
; sys_sp is safe to use when interrupts are disabled, ditto for sys_ptr

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
;     keep waiting against $D4 (742 uS) calling 'ld edge 1' again for the other edge
;   reading bits use timing $B0 ($B2 for flag?)
; * two pulses in less than ***893 uS ($CB) means 0, otherwise 1, timeout after 1349 uS *

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

; *** first wait for the guide tone and sync ***
	LDY #0	; longest timeout
	STY counter	; will be used later as guide tone pulse counter
ld_brk:
		;BEQ wait	; in case BREAK was not pressed, not yet implemented
		;	_EXIT_CS	; PLP actually
		;	_ERR(ABORT)	; signal NEW error in ABI***

wait:
		JSR ld_edge1	; look for any pulse
		BCC ld_brk	; until found or aborted
		
; now wait for a second and see if the pulsing signal remains
	LDX speedcode	; machine specific
	TXA		; save for later as will be reused!
wp_loop:
		LDY #49	; (2) adjusted for nearly 1 second, whole loop should take ~62500 clocks!
wp_loop2:
				DEX		;(2**) will loop 256 iterations most of the time
				BNE wp_loop2	; (3**) 1279 per Y, but 79 @ 1 MHz once in Y loop!
			DEY		; (2*) auxiliary counter
			BNE wp_loop2	; (3*)
		TAX		; (2) retrieve value!
		DEX		; (2) CPU speed dependent
		BNE wp_loop	; (3) until the end of delay
	JSR ld_edge2	; continue only if two edges are found
		BCC ld_brk	; will check at last whether BREAK was pressed (if implemented)
		
; now accept only a guide tone
leader:
		LDY #6	; guide tone timing constant
		JSR ld_edge2	; wait for two edges up to 1.685 mS, actually 1.738
			BCC ld_brk	; ...hopefully successful
		CPY #3	; guide tone threshold, actually 946 uS vs. 857!
			BCC wait	; was not the proper frequency
		INC counter	; needs 256 of these
	BNE leader

; time to fetch the sync pulse
sync:
		LDY #3	; timing constant for 927 uS (actually 946)
		JSR ld_edge1	; try to get first half
			BCC ld_brk	; no luck
		CPY #2	; adequate threshold (742 uS, actually 682) is this OK?
			BCC sync	; keep trying
		JSR ld_edge1	; must get the other half
	BCC error	; not found!

; *** now load the flag and, if matches with supplied, proceed to load ***
	LDA #0	; NMOS savvy
	STA checksum	; reset it now as will be included in total computation
	JSR ld_8bits	; get the first byte
		BCC error		; something went wrong
	CMP flag	; what were you looking for? (0=header or $FF=data)
	BEQ ld_loop	; matched flag, proceed with load
		_EXIT_CS	; PLP actually
		_ERR(N_FOUND)	; otherwise is a discarded block *** for drivers, ABORT otherwise

; *** get byte, store it and decrease counter ***
ld_loop:
	JSR ld_8bits	; get byte in A
		BCC error	; something went wrong
; store byte in memory, checksum is not counted
	LDY #0	; NMOS savvy!
	STA (data_pt), Y	; store byte ***** change for CMP if verifying
	INC data_pt	; point to next byte
	BNE nw1	; check MSB in case
		INC data_pt+1
nw1:
	DEC data_size	; one byte less to go
	BNE ld_loop	; check MSB just in case
		LDX data_size+1
	BEQ loaded	; if zero too, all done!
		DEC data_size+1	; otherwise decrease MSB...
		JMP ld_loop	; ...and get another
loaded:
; finally load checksum and the stored one should turn zero
	JSR ld_8bits	; get checksum byte in A (and modify stored)
		BCC error	; something went wrong
	LDA checksum	; check stored
	BNE error	; zero means OK
		_EXIT_CS	; PLP actually
		_EXIT_OK	; this is CLC RTS ** for drivers, FINISH otherwise
		
error:
	_EXIT_CS	; PLP, actually
	_ERR(CORRUPT)	; otherwise a loading error happened *** for drivers, ABORT otherwise
	
; ****** all finished ******

; ***** USEFUL ROUTINES *****
; *** get a byte in A from the data stream ***
; return with C set means OK, clear means error!

ld_8bits:

	LDA #1	; marker pattern
	LDY #5	; timing value eeeeeek
ld_bits:
		PHA		; eeeeeeek
		JSR ld_edge2	; get whole bit
		PLA		; eeeeeeek
		BCS bitOK	; something was received
			RTS		; timeout otherwise
bitOK:
		CPY #3	; one/zero threshold, OK?
; is C correctly set? (clear if zero, set if one) NOT!!!
; will insert bits inverted and then invert the whole byte
		ROL		; rotate bits and push marker
		LDY #5	; 1.5 mS timeout for next bit
		BCC ld_bits	; continue while bits remain
; byte is done... but inverted!
	EOR #$FF	; invert byte eek
; byte is in A, add to checksum
	PHA		; keep it!!
	EOR checksum	; add to current
	STA checksum	; and update stored value
	PLA		; retrieve value!
	RTS

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
		NOP		; (2*) lose some time, see comments
		NOP
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
;    3   882   914   946 (154+264 per Y), 1210, 1474, 1738, 2002...

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

