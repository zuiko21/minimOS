; (c) 2020-2022 Carlos J. Santisteban
.o1f00
; repeat 10 times .c $2000
LDA #0A
STA $02
JSR $2000
DEC $02
BNE $1F04
RTS
; standard benchmark routine
.o2000
_2000: LDA #$00      ; A9 00 (2)
_2002: TAX           ; AA (2)
_2003: TAY           ; A8 (2)
; inner loop
_2004: JSR $2010     ; 20 10 20
; above call takes ***6+21
_2007: INY           ; C8 (***2)
_2008: BNE $2004     ; D0 FA (***3 -1**)
; inner loop is 8191 clocks
_200A: INX           ; E8 (**2)
_200B: BNE $2004     ; D0 F7 (**3 -1*)
; middle loop is 2098175 clocks
_200D: INC           ; 1A (*2)
_200E: BNE $2004     ; D0 F4 (*3 -1)
; external loop is 537134079 clocks
; delay routine... (21)
_2010: JSR $2013     ; 20 13 20 (6+6)
_2013: JMP $2016     ; 4C 16 20 (3)
_2016: RTS           ; 60 (6)
;takes 2.4s @i5 (~224 MHz)

