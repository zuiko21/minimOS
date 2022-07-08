; Tiles position (0x8000 - 0x9fff)
*=$8000
#include "boat_tiles.s"
; First map 0xa000
#include "boat_maps.s"

begin:

; Set video mode
; [HiRes Invert S1 S0    RGB LED NC NC]
LDA #$3F
STA $df80

; $10 $11 current video memory pointer
LDA #$60
STA $11
LDA #$00
STA $10

; $12, $13 tile to draw (initial position in mem)
LDA #$80
STA $13
LDA #$00
STA $12

; $14, $15 tilemap to draw
LDA #$a0
STA $15
LDA #$00
STA $14

; Draw map 1
JSR draw_map

main_loop:

; Second map
LDA #$40
STA $11
LDA #$00
STA $10
LDA #$a1
STA $15
LDA #$00
STA $14
JSR draw_map
; Change screen
wait_vsync1:
BIT $DF88
BVC wait_vsync1
LDA #$2F
STA $df80

; Third map
LDA #$60
STA $11
LDA #$00
STA $10
LDA #$a2
STA $15
LDA #$00
STA $14
JSR draw_map
; Change screen
wait_vsync2:
BIT $DF88
BVC wait_vsync2
LDA #$3F
STA $df80

JMP main_loop


end: JMP end




; $14, $15 tilemap to draw
draw_map:
; $07 tiles rows counter
;LDA #$a0
LDA #$10
STA $07
draw_map_loop1:
; First tiles row
; tile 0
JSR convert_tile_index_to_mem
JSR draw_back_tile
; tile 1
INC $14
JSR convert_tile_index_to_mem
JSR draw_back_tile
; tile 2
INC $14
JSR convert_tile_index_to_mem
JSR draw_back_tile
; tile 3
INC $14
JSR convert_tile_index_to_mem
JSR draw_back_tile
; tile 4
INC $14
JSR convert_tile_index_to_mem
JSR draw_back_tile
; tile 5
INC $14
JSR convert_tile_index_to_mem
JSR draw_back_tile
; tile 6
INC $14
JSR convert_tile_index_to_mem
JSR draw_back_tile
; tile 7
INC $14
JSR convert_tile_index_to_mem
JSR draw_back_tile
; tile 8
INC $14
JSR convert_tile_index_to_mem
JSR draw_back_tile
; tile 9
INC $14
JSR convert_tile_index_to_mem
JSR draw_back_tile
; tile 10
INC $14
JSR convert_tile_index_to_mem
JSR draw_back_tile
; tile 11
INC $14
JSR convert_tile_index_to_mem
JSR draw_back_tile
; tile 12
INC $14
JSR convert_tile_index_to_mem
JSR draw_back_tile
; tile 13
INC $14
JSR convert_tile_index_to_mem
JSR draw_back_tile
; tile 14
INC $14
JSR convert_tile_index_to_mem
JSR draw_back_tile
; tile 15
INC $14
JSR convert_tile_index_to_mem
JSR draw_back_tile
INC $14

; Change row
LDA #$00
STA $10
INC $11
INC $11
DEC $07
BEQ draw_map_end
JMP draw_map_loop1
draw_map_end:
RTS
;------------------------------------------------------


; Input $14 $15 Tilemap position
; output $12, $13 tile to draw (initial position in mem
; $08 internal, backup of current tile index
convert_tile_index_to_mem:
; Load tile index in X
LDY #$00
LDA ($14), Y
;$08 backup of current tile index ($14)
STA $08
; Calculate tile memory position by multiplying (shifting) tile number * 0x20
ASL
ASL
ASL
ASL
ASL
; Store tile memory position in $12
STA $12

; Calculate more significative tile memory position ($13)
;$07 backup of current tile index ($13)
;LDA $13
;STA $07
LDA $08
CLC
LSR
CLC
LSR
CLC
LSR
CLC
ADC #$80
STA $13
RTS
; --------------------------------------------------------







;$12, $13 -> tile number, tile bank
;$10,$11 -> screen position
;$09 backup of $10 original value
draw_back_tile:
; Save screen position as backup in $09
LDA $10
STA $09
; First row
LDY #$00
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
; Change row
LDA $10; Increment using acumulator less significative screen pos ($10)
CLC
ADC #$40; Each row is 0x40 (64) bytes 
STA $10
LDA $12; Increment first tile byte position ($12), so it points to next byte
CLC
ADC #$04; Increment by 4 (already drawn 8 pixels)
STA $12
LDY #$00; Initialize pixel counter to 0
; Second row
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
; Change row
LDA $10
CLC
ADC #$40
STA $10
LDA $12
CLC
ADC #$04
STA $12
LDY #$00
; Third row
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
; Change row
LDA $10
CLC
ADC #$40
STA $10
LDA $12
CLC
ADC #$04
STA $12
LDY #$00
; Fourth row
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
; Change row and block
LDA $10
CLC
ADC #$40
STA $10
INC $11; Each 4 rows, high significative byte should be increased
LDA $12
CLC
ADC #$04
STA $12
LDY #$00
; Fith row
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
; Change row
LDA $10
CLC
ADC #$40
STA $10
LDA $12
CLC
ADC #$04
STA $12
LDY #$00
; Sixth row
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
; Change row
LDA $10
CLC
ADC #$40
STA $10
LDA $12
CLC
ADC #$04
STA $12
LDY #$00
; Seventh row
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
; Change row
LDA $10
CLC
ADC #$40
STA $10
LDA $12
CLC
ADC #$04
STA $12
LDY #$00
; Eight row
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y
INY
LDA ($12), Y
STA ($10), Y

; Finalize tile drawing
LDA $12; Go to next tile by incrementing $12 by 0x04 (already drawn 8 pixels)
CLC
ADC #$04
DEC $11; Restore $11 to original value, so next tile is at same row
LDA $09; Restore $10 using backup and add 0x04 to set at next screen position 
CLC
ADC #$04
STA $10
RTS
;--------------------------------------------------------



; Fill unused ROM
.dsb $fffa-*, $00

; Set initial PC
* = $fffa
    .word begin
    .word begin
    .word begin
