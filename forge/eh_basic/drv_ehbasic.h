;*** EhBASIC static variables ***
; implemented as a pseudo-driver for minimOS
; (c) 2015-2022 Carlos J. Santisteban
; last modified 20220322-2258

eh_var:

LAB_WARM	= eh_var-1	; BASIC warm start entry point *** only the next two bytes are used, thus no need for this byte itself
Wrmjpl 		= LAB_WARM+1; BASIC warm start vector jump low byte
Wrmjph 		= LAB_WARM+2; BASIC warm start vector jump high byte

Usrjmp		= Wrmjph+1	; USR function JMP address *** no longer $0A, should it hold a JMP opcode?
Usrjpl		= Usrjmp+1	; USR function JMP vector low byte
Usrjph		= Usrjmp+2	; USR function JMP vector high byte

;Nullct		= Usrjph+1	; nulls output after each line *** no longer $0D
;TPos		= Nullct+1	; BASIC terminal position byte *** $0E
;TWidth		= TPos+1	; BASIC terminal width byte *** $0F
;Iclim		= TWidth+1	; input column limit *** $10
;Itempl		= Iclim		; temporary integer low byte *** $11 *** MUST BE IN ZP
;Itemph		= Itempl+1	; temporary integer high byte *** ZP!

;nums_1		= Iclim	;	; number to bin/hex string convert MSB
;nums_2		= nums_1+1	; number to bin/hex string convert
;nums_3		= nums_1+2	; number to bin/hex string convert LSB

;Srchc		= nums_3+1	; search character *** $5B
;Temp3		= Srchc		; temp byte used in number routines
;Scnquo		= Srchc+1	; scan-between-quotes flag *** $5C
;Asrch		= Scnquo	; alt search character

;XOAw_l		= Srchc		; eXclusive OR, OR and AND word low byte
;XOAw_h		= Scnquo	; eXclusive OR, OR and AND word high byte

;Ibptr		= Scnquo+1	; input buffer pointer *** $5D
;Dimcnt		= Ibptr		; # of dimensions
;Tindx		= Ibptr		; token index

;Defdim		= Ibptr+1	; default DIM flag *** $5E
;Dtypef		= Defdim+1	; data type flag, $FF=string, $00=numeric *** $5F
;Oquote		= Dtypef+1	; open quote flag (b7) (Flag: DATA scan; LIST quote; memory) *** $60
;Gclctd		= Oquote	; garbage collected flag
;Sufnxf		= Oquote+1	; subscript/FNX flag, 1xxx xxx = FN(0xxx xxx) *** $61
;Imode		= Sufnxf+1	; input mode flag, $00=INPUT, $80=READ *** $62

;Cflag		= Imode+1	; comparison evaluation flag *** $63

;TabSiz		= Cflag+1	; TAB step size (was input flag) *** $64

;next_s		= TabSiz+1	; next descriptor stack address *** $65

; *** watch this, might point somewhere in zeropage ***
						; these two bytes form a word pointer to the item
						; currently on top of the descriptor stack
;last_sl		= next_s+1	; last descriptor stack address low byte *** $66
;last_sh		= last_sl+1	; last descriptor stack address high byte (always $00) *** $67

;des_sk		= last_sh	; descriptor stack start address (temp strings) *** $68 *** MUST BE IN ZP

;			= $70		; End of descriptor stack *** $70
