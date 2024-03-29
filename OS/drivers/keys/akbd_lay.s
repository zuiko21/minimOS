; ********************************
; *** scancode to ASCII tables *** for 64-key ASCII keyboard
; ********************************
; (c) 2012-2022 Carlos J. Santisteban
; last modified 20200315-2051

; cols 0...14, and inside rows 0...3
; note standard labels!

; *****************************************************
; *** standard keys, with either caps lock or shift ***
; *****************************************************
; unshifted
ak_traw:
	.byt	$20, $3C, $09, $BA,  $7A, $61, $71, $31,  $78, $73, $77, $32	;  <·º zaq1 xsw2
	.byt	$63, $64, $65, $33,  $76, $66, $72, $34,  $62, $67, $74, $35	; cde3 vfr4 bgt5
	.byt	$6E, $68, $79, $36,  $6D, $6A, $75, $37,  $2C, $6B, $69, $38	; nhy6 mju7 ,ki8
	.byt	$2E, $6C, $6F, $39,  $2D, $F1, $70, $30,  $0 , $B4, $60, $27	; .lo9 -ñp0 ·'`'
	.byt	$0 , $E7, $2B, $A1,  $0A, $0B, $0D, $08,  $0C, $0 , $7F, $1B	; ·ç+¡ ···· ····

; caps lock
ak_tu:
	.byt	$20, $3C, $09, $BA,  $5A, $41, $51, $31,  $58, $53, $57, $32	;  <·º ZAQ1 XSW2
	.byt	$43, $44, $45, $33,  $56, $46, $52, $34,  $42, $47, $54, $35	; CDE3 VFR4 BGT5
	.byt	$4E, $48, $59, $36,  $4D, $4A, $55, $37,  $2C, $4B, $49, $38	; NHY6 MJU7 ,KI8
	.byt	$2E, $4C, $4F, $39,  $2D, $D1, $50, $30,  $0 , $B4, $60, $27	; .LO9 -ÑP0 ·'`'
	.byt	$0 , $C7, $2B, $A1,  $0A, $0B, $0D, $08,  $0C, $0 , $7F, $1B	; ·Ç+¡ ···· ····

; shift (with or without caps lock)
ak_ts:
ak_tsu:
	.byt	$0 , $3E, $0 , $AA,  $5A, $41, $51, $21,  $58, $53, $57, $22	; ·>·ª ZAQ! XSW"
	.byt	$43, $44, $45, $B7,  $56, $46, $52, $24,  $42, $47, $54, $25	; CDE· VFR$ BGT%
	.byt	$4E, $48, $59, $26,  $4D, $4A, $55, $2F,  $3B, $4B, $49, $28	; NHY& MJU/ ;KI(
	.byt	$3A, $4C, $4F, $29,  $5F, $D1, $50, $3D,  $0 , $A8, $5E, $3F	; :LO) _ÑP= ·¨^?
	.byt	$0 , $C7, $2A, $BF,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 	; ·Ç*¿ ···· ····

; ***************************
; *** keys with alternate ***
; ***************************
; alt only
ak_ta:
	.byt	$A0, $96, $0 , $5C,  $FE, $E1, $D8, $7C,  $D7, $A7, $B8, $40	; □≤·\ þáØ| ×§ω@
	.byt	$E7, $F0, $E9, $23,  $91, $0 , $95, $A4,  $DF, $E3, $97, $BA	; çđé# ✓·σ€ ßãτº
	.byt	$F1, $E6, $FD, $AC,  $B5, $0 , $FA, $A6,  $0 , $F5, $ED, $7B	; ñæý¬ µ·ú¦ ·õí{
	.byt	$0 , $E5, $F3, $7D,  $AF, $7E, $B6, $7E,  $0 , $7B, $5B, $0 	; ·åó} ¯~¶~ ·{[·
	.byt	$0 , $7D, $5D, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 	; ·}]· ···· ····

; caps lock & alt (note some caps are not the same as shifted)
ak_tua:
	.byt	$A0, $96, $0 , $5C,  $DE, $C1, $D8, $7C,  $D7, $A7, $9A, $40	; □≤·\ ÞÁØ| ×§Ω@
	.byt	$C7, $D0, $C9, $23,  $91, $0 , $95, $A4,  $DF, $C3, $97, $BA	; ÇĐÉ# ✓·σ€ ßÃτº
	.byt	$D1, $C6, $DD, $AC,  $B5, $0 , $DA, $A6,  $0 , $D5, $CD, $7B	; ÑÆÝ¬ µ·Ú¦ ·ÕÍ{
	.byt	$0 , $C5, $D3, $7D,  $AF, $7E, $B6, $7E,  $0 , $7B, $5B, $0 	; ·ÅÓ} ¯~¶~ ·{[·
	.byt	$0 , $7D, $5D, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 	; ·}]· ···· ····

; shift & alt (with or without caps lock)
ak_tsa:
ak_tsua:
	.byt	$0 , $9C, $0 , $5C,  $DE, $C1, $D8, $A1,  $0 , $9F, $9A, $40	; ·∞·\ ÞÁØ¡ ·∩Ω@
	.byt	$C7, $D0, $C9, $BC,  $0 , $0 , $B0, $A3,  $0 , $C2, $A8, $AA	; ÇĐÉ• ··°£ ·Â¨ª
	.byt	$D1, $CA, $DD, $AC,  $B5, $0 , $DA, $5C,  $0 , $D4, $CD, $AB	; ÑÊÝ¬ µ·Ú\ ·ÔÍ«
	.byt	$0 , $DB, $D3, $BB,  $AF, $9D, $B6, $9D,  $0 , $AB, $5B, $0 	; ·ÛÓ» ¯≈¶≈ ·«[·
	.byt	$0 , $BB, $5D, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 	; ·»]· ···· ····

; ***********************************************
; *** control keys, with every other modifier ***
; ***********************************************
; control (needs shift separated, but caps lock has no effect!)
ak_tc:
ak_tuc:
	.byt	$80, $0 , $0 , $F7,  $1A, $01, $11, $2B,  $18, $13, $17, $27	;  ··÷ ···+ ···'
	.byt	$03, $04, $05, $2E,  $16, $06, $12, $2C,  $02, $07, $14, $3A	; ···. ···, ···:
	.byt	$0E, $08, $19, $3B,  $0D, $0A, $15, $2D,  $0 , $0B, $09, $2C	; ···; ···- ···<
	.byt	$0 , $0C, $0F, $3E,  $2D, $BE, $10, $5F,  $0 , $0 , $0 , $0 	; ···> -ŋ·_ ····
	.byt	$0 , $A9, $0 , $2A,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 	; ·©·* ···· ····

; shift & control (with or without caps lock)
ak_tsc:
ak_tsuc:
	.byt	$0 , $0 , $0 , $0 ,  $1A, $01, $11, $1B,  $18, $13, $17, $1C	; ···· ···· ····
	.byt	$03, $04, $05, $1D,  $16, $06, $12, $1E,  $02, $07, $14, $1F	; ···· ···· ····
	.byt	$0E, $08, $19, $5E,  $0D, $0A, $15, $3F,  $0 , $0B, $09, $5B	; ···^ ···? ···[
	.byt	$0 , $0C, $0F, $5D,  $3F, $0 , $10, $7F,  $0 , $0 , $0 , $1C	; .··] ?··· ····
	.byt	$0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 	; ···· ···· ····

; *** control & alternate ***
; alt & control (separating both caps & shift)
ak_tac:
	.byt	$00, $96, $0 , $F7,  $99, $E4, $0 , $2A,  $90, $94, $0 , $A2	; ·≤·÷ ϴä·* αΣ·¢
	.byt	$A9, $9B, $EB, $B1,  $B9, $0 , $AE, $A5,  $0 , $E0, $92, $F7	; ©δë± Δ·®¥ ·àΓ÷
	.byt	$BE, $E8, $FF, $60,  $9E, $EC, $FC, $BF,  $A5, $F2, $EF, $96	; ŋèÿ` ∈ìü¿ ¥òï≤
	.byt	$0 , $F9, $F6, $98,  $BF, $BE, $93, $AD,  $0 , $96, $9C, $A2	; .ùö≥ ¿ŋπ≠ ·≤∞¢
	.byt	$0 , $0 , $2A, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 	; ··*· ···· ····

; alt & control & caps lock
ak_tuac:
	.byt	$00, $96, $0 , $F7,  $99, $C4, $0 , $2A,  $90, $94, $0 , $A2	; ·≤·÷ ϴÄ·* αΣ·¢
	.byt	$A9, $9B, $CB, $B1,  $B9, $0 , $AE, $A5,  $0 , $C0, $92, $F7	; ©δË± Δ·®¥ ·ÀΓ÷
	.byt	$BE, $C8, $FF, $60,  $9E, $CC, $DC, $BF,  $A5, $D2, $CF, $96	; ŋÈÿ` ∈ÌÜ¿ ¥ÒÏ≤
	.byt	$0 , $D9, $D6, $98,  $BF, $BE, $93, $AD,  $0 , $96, $9C, $A2	; .ÙÖ≥ ¿ŋπ≠ ·≤∞¢
	.byt	$0 , $0 , $2A, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 	; ··*· ···· ····

; alt & control & shift (with or without caps)
ak_tsac:
ak_tsuac:
	.byt	$0 , $9C, $0 , $0 ,  $0 , $C4, $0 , $0 ,  $0 , $0 , $0 , $B2	; ·∞·· ·Ä·· ···²
	.byt	$0 , $0 , $CB, $B3,  $0 , $0 , $0 , $0 ,  $0 , $C0, $0 , $0 	; ··Ë³ ···· ·À··
	.byt	$0 , $C8, $0 , $0 ,  $0 , $CC, $DC, $0 ,  $0 , $D2, $CF, $9C	; ·È·· ·ÌÜ· ·ÒÏ∞
	.byt	$0 , $D9, $D6, $0 ,  $0 , $0 , $0 , $AF,  $0 , $9C, $9C, $B2	; .ÙÖ· ···¯ ·∞∞²
	.byt	$0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 	; ···· ···· ····

#ifdef	DEADKEY
; *************************************************
; ** tables for deadkey(s), just one for Spanish **
; *************************************************
; acute unshifted
ak_acu:
	.byt	$B4, $0 , $0 , $0 ,  $0 , $E1, $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $E9, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $FD, $0 ,  $0 , $0 , $FA, $0 ,  $0 , $0 , $ED, $0
	.byt	$0 , $0 , $F3, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0

; acute with shift and/or caps lock
ak_acs:
	.byt	$B4, $0 , $0 , $0 ,  $0 , $C1, $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $C9, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $DD, $0 ,  $0 , $0 , $DA, $0 ,  $0 , $0 , $CD, $0
	.byt	$0 , $0 , $D3, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0

; diaeresis unshifted
ak_umu:
	.byt	$A8, $0 , $0 , $0 ,  $0 , $E4, $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $EB, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $FF, $0 ,  $0 , $0 , $FC, $0 ,  $0 , $0 , $EF, $0
	.byt	$0 , $0 , $F6, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0

; diaeresis with shift and/or caps lock
ak_ums:
	.byt	$A8, $0 , $0 , $0 ,  $0 , $C4, $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $CB, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $FF, $0 ,  $0 , $0 , $DC, $0 ,  $0 , $0 , $CF, $0
	.byt	$0 , $0 , $D6, $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
	.byt	$0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0 ,  $0 , $0 , $0 , $0
#endif
