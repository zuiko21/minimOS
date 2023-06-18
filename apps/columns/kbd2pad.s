; *** keyboard to pad table for Durango-X ***

;	col1 > Sp Cr Sh P  0  A  Q  1	> f2· s1· · L1· ·
;	col2 > Al L  Z  O  9  S  W  2	> f2R2s1· · D1U1·
;	col3 > M  K  X  I  8  D  E  3	> s2D2f1U2· R1· ·
;	col4 > N  J  C  U  7  F  R  4	> s2L2f1· · · · ·
;	col5 never used (BHVY6GT5)
; with a nice trick these can be index of a 64-byte table per player
; d7d6d5d4d3d2d1d0 > 0 0 d7 d6 d5 d4 C  d2 (C = d1 on column 2) via LSR, LSR, BCC*, ORA#2, *
; generic tables (may be interlaced, as only 4 columns are used) should look like...
;				player 1			player 2
;	col 1	>	· · t · · L		>	A · · · · ·
;	col 2	>	· · e · U D		>	B R · · · ·
;	col 3	>	· · B · · R		>	e D · U · ·
;	col 4	>	· · A · · ·		>	t L · · · ·
; whereas the entries are in the usual AtBeULDR format

#ifndef	PAD_BUTTONS
#define	PAD_BUTTONS
#define	PAD_FIRE	%10000000
#define	PAD_STRT	%01000000
#define	PAD_B		%00100000
#define	PAD_SEL		%00010000
#define	PAD_UP		%00001000
#define	PAD_LEFT	%00000100
#define	PAD_DOWN	%00000010
#define	PAD_RGHT	%00000001
#endif

kbd2pad0:
	.byt	0, 0, 0, 0							; no keys!
	.byt	PAD_LEFT, PAD_DOWN, PAD_RGHT, 0		; [1]
	.byt	0, PAD_UP, 0 ,0						; [2]
	.byt	PAD_LEFT, PAD_DOWN|PAD_UP, PAD_RGHT, 0				; [3] =1+2
	.byt	0, 0, 0, 0							; [4] no keys for this player
	.byt	PAD_LEFT, PAD_DOWN, PAD_RGHT, 0		; [5] =1
	.byt	0, PAD_UP, 0 ,0						; [6] =2
	.byt	PAD_LEFT, PAD_DOWN|PAD_UP, PAD_RGHT, 0				; [7] =3
	.byt	PAD_STRT, PAD_SEL, PAD_B, PAD_FIRE					; [8] has many controls
	.byt	PAD_STRT|PAD_LEFT, PAD_SEL|PAD_DOWN, PAD_B|PAD_RGHT, PAD_FIRE		; [9] combines a lot!
	.byt	PAD_STRT, PAD_SEL|PAD_UP, PAD_B, PAD_FIRE			; [10] adds PAD_UP
	.byt	PAD_STRT|PAD_LEFT, PAD_SEL, PAD_B|PAD_RGHT, PAD_FIRE				; [11] combines a lot, but UP+DOWN makes no sense
	.byt	PAD_STRT, PAD_SEL, PAD_B, PAD_FIRE					; [12] =8
	.byt	PAD_STRT|PAD_LEFT, PAD_SEL|PAD_DOWN, PAD_B|PAD_RGHT, PAD_FIRE		; [13] =9
	.byt	PAD_STRT, PAD_SEL|PAD_UP, PAD_B, PAD_FIRE			; [14] =10
	.byt	PAD_STRT|PAD_LEFT, PAD_SEL, PAD_B|PAD_RGHT, PAD_FIRE				; [15] =11
; these 16x4 combos get repeated four times, as the two uppermost bits are unused for player 1
	.byt	0, 0, 0, 0							; [16-31] =0-15
	.byt	PAD_LEFT, PAD_DOWN, PAD_RGHT, 0	
	.byt	0, PAD_UP, 0 ,0
	.byt	PAD_LEFT, PAD_DOWN|PAD_UP, PAD_RGHT, 0
	.byt	0, 0, 0, 0
	.byt	PAD_LEFT, PAD_DOWN, PAD_RGHT, 0
	.byt	0, PAD_UP, 0 ,0
	.byt	PAD_LEFT, PAD_DOWN|PAD_UP, PAD_RGHT, 0
	.byt	PAD_STRT, PAD_SEL, PAD_B, PAD_FIRE
	.byt	PAD_STRT|PAD_LEFT, PAD_SEL|PAD_DOWN, PAD_B|PAD_RGHT, PAD_FIRE
	.byt	PAD_STRT, PAD_SEL|PAD_UP, PAD_B, PAD_FIRE
	.byt	PAD_STRT|PAD_LEFT, PAD_SEL, PAD_B|PAD_RGHT, PAD_FIRE
	.byt	PAD_STRT, PAD_SEL, PAD_B, PAD_FIRE
	.byt	PAD_STRT|PAD_LEFT, PAD_SEL|PAD_DOWN, PAD_B|PAD_RGHT, PAD_FIRE
	.byt	PAD_STRT, PAD_SEL|PAD_UP, PAD_B, PAD_FIRE
	.byt	PAD_STRT|PAD_LEFT, PAD_SEL, PAD_B|PAD_RGHT, PAD_FIRE

	.byt	0, 0, 0, 0							; [32-47] =0-15
	.byt	PAD_LEFT, PAD_DOWN, PAD_RGHT, 0	
	.byt	0, PAD_UP, 0 ,0
	.byt	PAD_LEFT, PAD_DOWN|PAD_UP, PAD_RGHT, 0
	.byt	0, 0, 0, 0
	.byt	PAD_LEFT, PAD_DOWN, PAD_RGHT, 0
	.byt	0, PAD_UP, 0 ,0
	.byt	PAD_LEFT, PAD_DOWN|PAD_UP, PAD_RGHT, 0
	.byt	PAD_STRT, PAD_SEL, PAD_B, PAD_FIRE
	.byt	PAD_STRT|PAD_LEFT, PAD_SEL|PAD_DOWN, PAD_B|PAD_RGHT, PAD_FIRE
	.byt	PAD_STRT, PAD_SEL|PAD_UP, PAD_B, PAD_FIRE
	.byt	PAD_STRT|PAD_LEFT, PAD_SEL, PAD_B|PAD_RGHT, PAD_FIRE
	.byt	PAD_STRT, PAD_SEL, PAD_B, PAD_FIRE
	.byt	PAD_STRT|PAD_LEFT, PAD_SEL|PAD_DOWN, PAD_B|PAD_RGHT, PAD_FIRE
	.byt	PAD_STRT, PAD_SEL|PAD_UP, PAD_B, PAD_FIRE
	.byt	PAD_STRT|PAD_LEFT, PAD_SEL, PAD_B|PAD_RGHT, PAD_FIRE

	.byt	0, 0, 0, 0							; [48-63] =0-15
	.byt	PAD_LEFT, PAD_DOWN, PAD_RGHT, 0	
	.byt	0, PAD_UP, 0 ,0
	.byt	PAD_LEFT, PAD_DOWN|PAD_UP, PAD_RGHT, 0
	.byt	0, 0, 0, 0
	.byt	PAD_LEFT, PAD_DOWN, PAD_RGHT, 0
	.byt	0, PAD_UP, 0 ,0
	.byt	PAD_LEFT, PAD_DOWN|PAD_UP, PAD_RGHT, 0
	.byt	PAD_STRT, PAD_SEL, PAD_B, PAD_FIRE
	.byt	PAD_STRT|PAD_LEFT, PAD_SEL|PAD_DOWN, PAD_B|PAD_RGHT, PAD_FIRE
	.byt	PAD_STRT, PAD_SEL|PAD_UP, PAD_B, PAD_FIRE
	.byt	PAD_STRT|PAD_LEFT, PAD_SEL, PAD_B|PAD_RGHT, PAD_FIRE
	.byt	PAD_STRT, PAD_SEL, PAD_B, PAD_FIRE
	.byt	PAD_STRT|PAD_LEFT, PAD_SEL|PAD_DOWN, PAD_B|PAD_RGHT, PAD_FIRE
	.byt	PAD_STRT, PAD_SEL|PAD_UP, PAD_B, PAD_FIRE
	.byt	PAD_STRT|PAD_LEFT, PAD_SEL, PAD_B|PAD_RGHT, PAD_FIRE

kbd2pad1:
; as player 2 has the two lowest bits unused, every subtable is repeated four times
	.byt	0, 0, 0, 0							; [0] no keys for this player
	.byt	0, 0, 0, 0
	.byt	0, 0, 0, 0
	.byt	0, 0, 0, 0
	.byt	0, 0, PAD_UP, 0						; [1] is UP only
	.byt	0, 0, PAD_UP, 0
	.byt	0, 0, PAD_UP, 0
	.byt	0, 0, PAD_UP, 0
	.byt	0, 0, 0, 0							; [2] adds nothing
	.byt	0, 0, 0, 0
	.byt	0, 0, 0, 0
	.byt	0, 0, 0, 0
	.byt	0, 0, PAD_UP, 0						; [3] =1
	.byt	0, 0, PAD_UP, 0
	.byt	0, 0, PAD_UP, 0
	.byt	0, 0, PAD_UP, 0
	.byt	0, PAD_RGHT, PAD_DOWN, PAD_LEFT		; [4] has most movements
	.byt	0, PAD_RGHT, PAD_DOWN, PAD_LEFT
	.byt	0, PAD_RGHT, PAD_DOWN, PAD_LEFT
	.byt	0, PAD_RGHT, PAD_DOWN, PAD_LEFT
	.byt	0, PAD_RGHT, 0, PAD_LEFT			; [5] UP+DOWN makes no sense
	.byt	0, PAD_RGHT, 0, PAD_LEFT
	.byt	0, PAD_RGHT, 0, PAD_LEFT
	.byt	0, PAD_RGHT, 0, PAD_LEFT
	.byt	0, PAD_RGHT, PAD_DOWN, PAD_LEFT		; [6] =4
	.byt	0, PAD_RGHT, PAD_DOWN, PAD_LEFT
	.byt	0, PAD_RGHT, PAD_DOWN, PAD_LEFT
	.byt	0, PAD_RGHT, PAD_DOWN, PAD_LEFT
	.byt	0, PAD_RGHT, 0, PAD_LEFT			; [7] =5
	.byt	0, PAD_RGHT, 0, PAD_LEFT
	.byt	0, PAD_RGHT, 0, PAD_LEFT
	.byt	0, PAD_RGHT, 0, PAD_LEFT
	.byt	PAD_FIRE, PAD_B, PAD_SEL, PAD_STRT	; [8] all but D-pad
	.byt	PAD_FIRE, PAD_B, PAD_SEL, PAD_STRT
	.byt	PAD_FIRE, PAD_B, PAD_SEL, PAD_STRT
	.byt	PAD_FIRE, PAD_B, PAD_SEL, PAD_STRT
	.byt	PAD_FIRE, PAD_B, PAD_SEL|PAD_UP, PAD_STRT			; [9] adds UP
	.byt	PAD_FIRE, PAD_B, PAD_SEL|PAD_UP, PAD_STRT
	.byt	PAD_FIRE, PAD_B, PAD_SEL|PAD_UP, PAD_STRT
	.byt	PAD_FIRE, PAD_B, PAD_SEL|PAD_UP, PAD_STRT
	.byt	PAD_FIRE, PAD_B, PAD_SEL, PAD_STRT	; [10] =8
	.byt	PAD_FIRE, PAD_B, PAD_SEL, PAD_STRT
	.byt	PAD_FIRE, PAD_B, PAD_SEL, PAD_STRT
	.byt	PAD_FIRE, PAD_B, PAD_SEL, PAD_STRT
	.byt	PAD_FIRE, PAD_B, PAD_SEL|PAD_UP, PAD_STRT			; [11] =9
	.byt	PAD_FIRE, PAD_B, PAD_SEL|PAD_UP, PAD_STRT
	.byt	PAD_FIRE, PAD_B, PAD_SEL|PAD_UP, PAD_STRT
	.byt	PAD_FIRE, PAD_B, PAD_SEL|PAD_UP, PAD_STRT
	.byt	PAD_FIRE, PAD_B|PAD_RGHT, PAD_SEL|PAD_DOWN, PAD_STRT|PAD_LEFT		; [12] combines a lot!
	.byt	PAD_FIRE, PAD_B|PAD_RGHT, PAD_SEL|PAD_DOWN, PAD_STRT|PAD_LEFT
	.byt	PAD_FIRE, PAD_B|PAD_RGHT, PAD_SEL|PAD_DOWN, PAD_STRT|PAD_LEFT
	.byt	PAD_FIRE, PAD_B|PAD_RGHT, PAD_SEL|PAD_DOWN, PAD_STRT|PAD_LEFT
	.byt	PAD_FIRE, PAD_B|PAD_RGHT, PAD_SEL, PAD_STRT|PAD_LEFT				; [13] UP+DOWN makes no sense
	.byt	PAD_FIRE, PAD_B|PAD_RGHT, PAD_SEL, PAD_STRT|PAD_LEFT
	.byt	PAD_FIRE, PAD_B|PAD_RGHT, PAD_SEL, PAD_STRT|PAD_LEFT
	.byt	PAD_FIRE, PAD_B|PAD_RGHT, PAD_SEL, PAD_STRT|PAD_LEFT
	.byt	PAD_FIRE, PAD_B|PAD_RGHT, PAD_SEL|PAD_DOWN, PAD_STRT|PAD_LEFT		; [14] =12
	.byt	PAD_FIRE, PAD_B|PAD_RGHT, PAD_SEL|PAD_DOWN, PAD_STRT|PAD_LEFT
	.byt	PAD_FIRE, PAD_B|PAD_RGHT, PAD_SEL|PAD_DOWN, PAD_STRT|PAD_LEFT
	.byt	PAD_FIRE, PAD_B|PAD_RGHT, PAD_SEL|PAD_DOWN, PAD_STRT|PAD_LEFT
	.byt	PAD_FIRE, PAD_B|PAD_RGHT, PAD_SEL, PAD_STRT|PAD_LEFT				; [15] =13
	.byt	PAD_FIRE, PAD_B|PAD_RGHT, PAD_SEL, PAD_STRT|PAD_LEFT
	.byt	PAD_FIRE, PAD_B|PAD_RGHT, PAD_SEL, PAD_STRT|PAD_LEFT
	.byt	PAD_FIRE, PAD_B|PAD_RGHT, PAD_SEL, PAD_STRT|PAD_LEFT
