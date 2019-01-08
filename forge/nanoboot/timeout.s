; nanoboot timeout mods
; (c) 2019 Carlos J. Santisteban

	LDX #4				; initial value
	STX timeout			; fill 16b timeout counter
	STX timeout+1
; ...
nb_grc:
#ifdef	TIMEBOOT
		DEC timeout			; one less to go (5)
		BNE nb_cont			; if still within time, continue waiting after 8 extra cycles (3/2)
			DEC timeout+1		; update MSB too otherwise (5)
			BNE nb_cont			; not yet expired, continue after 15 extra cycles (3/2)
				PLA					; discard return address otherwise... (4+4)
				PLA
				BNE nb_exit			; ...and proceed with standard boot!
nb_cont:
#endif
		BIT nb_flag			; received something? (3)
		BPL nb_grc			; (3/2)
	LDA nb_rcv			; check received (3)
	STX nb_rcv			; preset value (3)
	STX nb_flag			; clear bit 7 (3)
	RTS

; if X=1, then it timeouts after 14 cycles
; if X=2, after 14(1/2)+ 21(0/1)+ 14(255/1)+ 14(254/1)+ ... + 14(1/1)+ 14(0/0) =3619 ~3591
; t~((256*14)+7)*(x-1) cycles
; if x=3, t~7182... x=0 gives around 0.92 secs @ 1 MHz!
