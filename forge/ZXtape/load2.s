; minimOS ZX tape interface loader - alternate version
; v0.1b2
; (c) 2016-2020 Carlos J. Santisteban
; last modified 20160923-0942

; ***** REFERENCE: pulse lengths *****
; guide tone = 619/619 uS (cycle 1.238 mS)
; sync = 191/210 uS
; zero = 244/244 uS (cycle 488 uS)
; one = 489/489 uS (cycle 978 uS)

; ***** ORIGINAL TIMING *****
; pulse wait ~14000t, ~4 mS ($00)
; leader timeout/threshold ($9C/C6) 1.686 mS / 978 uS
; sync ($C9/D4) 927 / 742 uS
; bits ($B0/CB) 1349 / 893 uS

; *** needed data and pointers ***
	ddrx		= VIA1+DDRB	; VIA DDRx
	px6in	= VIA1+IORB	; VIA IORx, easy detection via BIT instruction (V) though not used
	speedcode	= $0210	; PLACEHOLDER stores CPU speed in fixed point format ($10 = 1 MHz)

	mask = %01000000  ; preset for bit 6 but change otherwise

; *** variable definitions ***
	sc_tt	= local1	; 12-byte computed timing table storage
	loc_tt	= sysptr	; 3-byte temporary storage (includes systmp) for fixed point timings
	loc_sc	= sys_sp	; temporary storage for speed code
	counter	= sysptr	; just one byte waiting for the guide tone, loc_tt released
	last		= systmp	; previous value on input port

; *** interface *** TBD
	data_pt		= ma_pt	; address where the data or header will be loaded
	data_size	= ma_rs	; size of data block, set to 17 when looking for a header!
	flag			= b_sig	; set to $00 when looking for a header, $FF otherwise

; ***** REAL STUFF BEGINS HERE *****

zx_load:

; disable interrupts!!!
	_ENTER_CS	; actually PHP and SEI
; best do that first for sys_sp, systmp & sysptr availability

; first of all, recompute timing constants for current speedcode - revamped
	LDX #12	; table size as index
; prepare for one value
preload:
		LDA speedcode	; (4*6) get original value
		STA loc_sc	; (3*6) store temporarily as will be shifted
		LDA timing-2, X	; (4*6) get original value FRACTION (notice offset)
		STA loc_tt	; (3*6) store in zeropage
		LDA timing-1, X	; (4*6) get original INTEGER
		STA loc_tt+1	; (3*6) continue storage
		LDA #0	; (2*6) NMOS savvy
		STA loc_tt+2	; (3*6) clear MSB
		STA sc_tt-1, X	; (10*6) and also result variables
		STA sc_tt-2, X
; 218 clocks up here
mult:
			LSR loc_sc	; (5*6*n) get lowest bit from speedcode
			BCC mul_z	; (2.5*6*n) nothing to add this time
mul_add:
				CLC		; (2*6*hn) prepare addition
				LDA loc_tt+1	; (3*6*hn) current factor LSB
				ADC sc_tt-2, X	; (4*6*hn) add to last value
				STA sc_tt-2, X	; (5*6*hn) update eeeeeeek
				LDA loc_tt+2	; (3*6*hn) continue adding MSB
				ADC sc_tt-1, X	; (4*6*hn) propagate carry
				STA sc_tt-1, X	; (5*6*hn) complete addition
mul_z:
			LDA loc_sc	; (3*6*n) look for remaining bits
				BEQ mul_done	; (2*6*n) no more bits!
			ASL loc_tt	; (5*6*n) double the current value
			ROL loc_tt+1	; (5*6*n) propagating to LSB
			ROL loc_tt+2	; (5*6*n) and MSB!
			BCC mult	; (3*6*n) go for next bit
; go for next value, last block takes 183*n fixed clocks plus 156*hn
; for n=8 and h=0.5 that is 2088
; for n=8 and h=1/8 (8 MHz) is 1620
; for n=5 and h=0.2 (1 Mhz) is 1071
mul_done:
		DEX		; (4*6)continue variable roundup
		DEX
		BNE preload	; (3*6)
; add finally 41 clocks
; sc_tt now holds the 16-bit timing constants adapted for the speedcode
; "worst" case 2347 clocks (n=8, half the bits set, at least 9.1875 MHz)
; will take 1330 clocks @ 1 MHz and 1879 @ 8 MHz

; initialise input port
	LDA ddrx	; previous data direction register on VIA
	AND #255-mask	; make sure bit 6 (or whatever) is input
	STA ddrx	; set direction, port is ready
	LDA px6in	; get whole byte
	AND #mask	; filter bit 6 or whatever
	STA last	; set initial value as only transitions will matter

; *** first wait for the guide tone and sync ***
	LDY #0	; longest timeout...
	LDX speedcode	; ...with this MSB
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
		LDY sc_tt+2	; guide tone timing constant
		LDX sc_tt+3	; MSB
		JSR ld_edge2	; wait for two edges up to 1.685 mS
			BCC ld_brk	; ...hopefully successful
; compare X/Y with threshold @sc_tt[0-1]
		CPX sc_tt+1	; check MSB first
			BCC wait	; was not the proper frequency
			BNE lead_cs	; otherwise well within limits
		CPY sc_tt	; check LSB if close
			BCC wait	; was not the proper frequency
lead_cs:
		INC counter	; needs 256 of these
	BNE leader

; time to fetch the sync pulse
sync:
		LDY sc_tt+6	; timing constant for sync
		LDX sc_tt+7	; MSB
		JSR ld_edge1	; try to get first half
			BCC ld_brk	; no luck
; adequate threshold @sc_tt[4-5]
		CPX sc_tt+5	; check MSB first
			BCC sync	; keep trying
			BNE syn_cs	; well within limits
		CPY sc_tt+4	; check LSB if close
			BCC sync	; keep trying
syn_cs:
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
		_EXIT_OK	; this is CLC RTS *** valid for driver function, FINISH otherwise
		
error:
	_EXIT_CS	; PLP, actually
	_ERR(CORRUPT)	; otherwise a loading error happened *** for drivers, ABORT otherwise
	
; ****** all finished ******

; ***** DATA TABLES *****
; timing constants in fixed point, threshold first, then timeout ***revise values
timing:
	.word	$03A0	; leader
	.word	$0640	; leader timeout 
	.word	$0370	; sync
	.word	$02C0	; sync timeout
	.word	$0500	; bits threshold
	.word	$0350	; bits timeout
	
; ***** USEFUL ROUTINES *****
; *** get a byte in A from the data stream ***
; return with C set means OK, clear means error!

ld_8bits:

	LDA #1	; marker pattern
	LDY sc_tt+10	; timing value eeeeeek
	LDX sc_tt+11	; MSB
ld_bits:
		PHA		; eeeeeeek
		JSR ld_edge2	; get whole bit
		PLA		; eeeeeeek
		BCS bitOK	; something was received
			RTS		; timeout otherwise
bitOK:
; one/zero threshold @sc_tt[8-9]
		CPX sc_tt+9	; check MSB first
			BCC bit_in	; will insert zero
			BNE bit_set	; otherwise one
		CPY sc_tt+8	; check MSB if close
			BCC bit_in	; will do zero
bit_set: 
		SEC		; usually needed
; is C correctly set? (clear if zero, set if one) NOT!!!
; will insert bits inverted and then invert the whole byte
bit_in:
		ROL		; rotate bits and push marker
		LDY sc_tt+10	; 1.5 mS timeout for next bit
		LDX sc_tt+11	; MSB eeeek
		BCC ld_bits	; continue while bits remain (no marker yet)
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

; previous delay (118 uS @ 1 MHz, 112.4 @ 14 MHz)

	LDA speedcode	; (4) adjust for CPU speed
	SEC		; (2)
ld_delay:
		NOP		; (2*) lose some time
		SBC #1		; (2*) count depending on CPU speed
		BNE ld_delay	; (3*) wait before entering sampling loop
		
; now wait for an edge
; Y decreases every 16 clocks, X every 4102 clocks

edge_loop:
		LDA px6in	; (4**) get whole byte
		AND #mask	; (2**) filter bit 6 or whatever
		CMP last	; (3**) compare against previous value
		BNE changed	; (2**) if did not change, keep waiting and counting
; increase count and check for timeouts
			DEY		; (2**) timing constant LSB
		BNE edge_loop	; (3**) continue checking
			DEX		; (2*) timing constant MSB
			CMP #$FF	; (2*) check eventual expiration
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

