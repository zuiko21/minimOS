; software serial port emulator for minimOS!
; v0.6b3, will assemble on NMOS but wrong timing! Use 65C02 *always*
; (c) 2016-2019 Carlos J. Santisteban
; last modified 20180404-1322

; VIA bit functions
; Tx	= PA0 (any 0...5, set masks accordingly)
; Rx	= PA7 (or PA6 for easy checking)
; /CTS	= PA6 (or PA7 for easy checking) *temporarily disabled
; /RTS	= PA1 (or any 0...5) *temporarily disabled

; new VIA-connected device ID is $23, will go into PB

; initially designed for 9600,n,1 on 1 MHz systems (Chihuahua)
; 104.167 clocks/bit!!!
; would be EXACTLY 192 cycles at 1.8432 MHz
; would be EXACTLY 240 cycles at 2.304 MHz
;
; ***********************
; *** minimOS headers ***
; ***********************
#include "../usual.h"

; *** begins with sub-function addresses table ***
	.byt	232		; physical driver number D_ID (TBD)
	.byt	A_BOUT|A_BLIN	; basic I/O driver, non-interrupt-driven
	.word	srs_rcvN	; read N bytes from 'serial'
	.word	srs_sendN	; output N bytes to 'serial'
	.word	srs_init	; initialise 'device', called by POST only
	.word	srs_exit	; no periodic interrupt
	.word	0		; frequency makes no sense
	.word	srs_nreq	; D_ASYN does nothing
	.word	srs_nreq	; no config
	.word	srs_nreq	; no status
	.word	srs_exit	; shutdown procedure, leave VIA as it was...
	.word	srs_info	; points to descriptor string
	.word	0			; reserved, D_MEM

; *** driver description ***
srs_info:
	.asc	"Serial-port emulation v0.6b1", 0

; *** some definitions ***
zsr_vote	= sys_sp	; single local variable, could be elsewhere in zeropage

IN_MASK		= %01111111	; PA6-7 as input *PA6 disabled
OUT_MASK	= %00000001	; PA0-1 as output *PA1 disabled
TX_MASK		= %00000001	; mask for Tx (PA0)
RTS_MASK	= %00000000	; mask for /RTS (PA1) *disabled
INIT_MASK	= TX_MASK + RTS_MASK	; set Tx (idle) and negate RTS (disable reception)

; ***************************************************************
; *** this header will enable classic character routines within block procedures ***
; ***************************************************************
srs_rcvN:
	LDA bl_ptr+1		; get pointer MSB
	PHA					; in case gets modified...
	LDY #0				; reset index
srsr_l:
		_PHY				; keep this
		JSR srs_rcv			; *** get one byte ***
			BCS blck_err		; any error ends transfer!
		_PLY				; restore index
		LDA io_c			; received byte...
		STA (bl_ptr), Y		; ...goes into buffer
		INY					; go for next
		BNE srsr_nw			; still within page
			INC bl_ptr+1			; ...or increment MSB
srsr_nw:
		DEC bl_siz			; one less to go
			BNE srsr_l			; no wrap, continue
		LDA bl_siz+1			; check MSB otherwise EEEEEK
			BEQ blck_end		; no more!
		DEC bl_siz+1		; ...or one page less
		_BRA srsr_l
blck_err:
	PLA					; was Y, but must respect error code!
blck_end:
	PLA					; gets pointer MSB back...
	STA bl_ptr+1		; ...and restores it
	RTS					; respect whatever error code

srs_sendN:
	LDA bl_ptr+1		; get pointer MSB
	PHA					; in case gets modified...
	LDY #0				; reset index
srss_l:
		LDA (bl_ptr), Y		; buffer contents...
		STA io_c			; ...will be sent
		_PHY				; keep this
		JSR srs_send		; *** send one byte ***
			BCS blck_err		; any error ends transfer!
		_PLY				; restore index
		INY					; go for next
		BNE srss_nw			; still within page
			INC bl_ptr+1			; ...or increment MSB
srss_nw:
		DEC bl_siz			; one less to go
			BNE srss_l			; no wrap, continue
		LDA bl_siz+1			; check MSB otherwise
			BEQ blck_end		; no more!
		DEC bl_siz+1		; ...or one page less
		_BRA srss_l


; ************************
; *** initialise stuff ***
; ************************
srs_init:
	LDA VIA1+IORA		; previous data
	ORA #INIT_MASK		; set Tx (idle) and negate RTS (disable reception)
	STA VIA1+IORA		; set initial status
	LDA VIA1+DDRA		; get I/O config
	AND #IN_MASK		; PA6-7 as input *PA7 only
	ORA #OUT_MASK		; PA0-1 as output *PA0 only
	STA VIA1+DDRA		; set config
	_DR_OK				; succeeded

; *****************************
; *** send one byte in io_c ***
; *****************************
srs_send:
	_CRITIC				; disable interrupts
/*
	LDX #30				; timeout counter ~1.5 mS *not used
; wait until receiver is available
srss_wait:
		BIT VIA1+IORA		; check input bits (4)
			BVC srss_cts		; exit loop if clear to send (2/3)
		JSR srs_41us		; half bit wait (41 incl JSR/RTS)
		DEX					; keep waiting (2)
		BNE srss_wait		; until timeout (3/2)
	_NO_CRIT			; restore interrupts if needed
	_DR_ERR(TIMEOUT)	; could not send in a timely fashion
srss_cts:
*/
; ready to go, prepare some values
	LDX #9				; bits per byte incl. stop
	SEC					; this will be the stop bit!
; now put the start bit
	LDA #TX_MASK		; mask for Tx, will be used anywhere (2)
	_TRB(VIA1+IORA)		; REset it! EEEEEEK (6)
	PHA: PLA			; 7 extra clocks delay!
	JSR srs_83us		; delay (83)
; still on until next bit is read
srss_bit:
		ROR io_c			; put bit to send in C (5)
		BCC srss_nzero		; was one (3/2)
			_TRB(VIA1+IORA)		; otherwise put 0 (0/6) one clock early from start, but was 0 anyway
			_BRA srss_sent		; this is done (0/3)
srss_nzero:
		_TSB(VIA1+IORA)		; it is a one (6/0) accurate from start
		NOP					; this should equalise paths! (2/0)
srss_sent:
		JSR srs_83us		; delay (83)
		DEX					; next bit (2)
		BNE srss_bit		; until done (3/2)
	_NO_CRIT			; restore interrupts if needed
	_DR_OK				; succeeded

; ************************
; *** receive one byte ***
; ************************
srs_rcv:
	_CRITIC				; disable interrupts
	LDA #RTS_MASK		; mask for RTS *not yet used
	_TRB(VIA1+IORA)		; enable reception!
	LDX #136			; timeout counter ~1.5 mS *** not for 1.8432 MHz ***
;	LDX #251			; *** timeout constant for 1.8432 MHz systems ***
; *will use a much longer timeout...
		LDY #0		; inner loop
; wait until data is available
srsr_wait:
		BIT VIA1+IORA		; check input bits (4)
			BPL srsr_start		; exit loop upon start bit reception (2/3)
		DEY		; *inner loop
		BNE srsr_wait		; until timeout (3/2)
		DEX					; keep waiting (2)
		BNE srsr_wait		; until timeout (3/2)
	_NO_CRIT			; restore previous interrupt state
; nreq for unexpected interrupt tasks! meaningless error, instead of NEXT_ISR
srs_nreq:
	_DR_ERR(EMPTY)		; could not receive anything within time frame
srsr_start:
; wait for the start bit to finish ** a bit of a kludge
	JSR srs_fullbit		; full-bit wait (104)
; let us read one byte
	LDX #8				; bits per byte (2)
	_STZA io_c			; clear received value (3)
srsr_bit:
		_STZA zsr_vote		; clear sample counter (3)
		LDY #3				; samples per bit (2) *** make it 5 at 1.8432 MHz ***
		NOP					; fix sampling timing (2) *** NOT for 1.8432 MHz ***
;		LDA zsr_vote		; *** put this for 1.8432 MHz (3) ***
srsr_sample:
			BIT VIA1+IORA		; check Rx (4)
			BPL srsr_zero		; was clear (3/2)
				INC zsr_vote		; otherwise vote for 1 (0/5)
				_BRA srsr_took		; just took this (0/3)
srsr_zero:
			DEC zsr_vote		; vote for 0 (5/0)
			NOP					; equalise paths (2/0)
srsr_took:
			PHA: PLA			; slight delay (7)
;			PHA					; *** add this for 1.8432 MHz (7) ***
;			PLA					; *** avoiding commented colon!!!!! ***
			DEY					; next sample (2)
			BNE srsr_sample		; vote again (3/2)
; now three samples took 79 uS! (see NOP above) (or 164 clocks @ 1.8432)
; let us decide what the bit is according to votes
		BIT zsr_vote		; check sign (3)
		BPL srsr_one		; was set (3/2)
			CLC					; otherwise clear bit (0/2)
			_BRA srsr_carry		; insert it (0/3)
srsr_one:
		SEC					; set bit (2/0)
		NOP					; equal lengths (2/0)
srsr_carry:
		ROR io_c			; insert into result (5)
		DEX					; go for next bit (2)
		BNE srsr_bit		; until complete (3/2)
; vote computed & bit set in 20 clocks (minus last one)
; should wait a bit for the stop bit!
	JSR srs_41us		; wait half a bit
	BIT VIA1+IORA		; check Rx line
	BMI srsr_stop		; looks like a stop bit
		LDA #RTS_MASK		; otherwise something went wrong
		_TSB(VIA1+IORA)		; disable reception!
		_NO_CRIT			; restore interrupts first eeeeeeeeeek
		_DR_ERR(CORRUPT)	; notify error
; disable receiver and finish
srsr_stop:
	JSR srs_41us		; wait a bit more (really needed?)
	LDA #RTS_MASK		; mask for /RTS *not used
	_TSB(VIA1+IORA)		; disable reception!
	_NO_CRIT			; no longer in a hurry
	_DR_OK

; ****************************************
; *** delay routines for 1 MHz systems ***
; ***** note changes for 1.8432 MHz! *****
; ****************************************

; * delay for a bit (83us incl JSR/RTS, or 171) *
srs_83us:
;	LDY sys_sp			; for timing (3) *** 1.8432 only ***
	LDY #14				; delay constant (2) *** 31 for 1.8432 ***
srs83_loop:
		DEY					; update countdown (2)
		BNE srs83_loop		; until done (3/2)
srs_exit:
	RTS					; done (6)

; * half-bit delay (41us incl JSR/RTS, or 85) *
srs_41us:
;	LDY $0100			; extra delay (4) *** 1.8432 only ***
	LDY #5				; delay constant (2) *** 13 for 1.8432 ***
	_BRA srs83_loop		; continue with accurate timing (3+)

; * full-bit delay (104uS or 192) *
srs_fullbit:
	LDY zsr_vote		; correcting delay (3)
;	LDY zsr_vote		; extra delay (3) *** 1.8432 only ***
	LDY #17				; for a 104uS delay (2) *** 34 for 1.8432 ***
	_BRA srs83_loop		; continue delay (93 or 178)
