*=$C000

begin:
    ; Set video mode
    LDA #$3F
    STA $df80

    ; Store at $10 video memory pointer
    LDA #$60
    STA $11
    LDA #$00
    STA $10 ; Current video memory position

    ; Store at $12 current color
    LDA #$11
    STA $12

loop3:
    ; Init memory position
    LDA #$60
    STA $11

loop2:
    ; Load color into accumulator
    LDA $12

    ; Iterate over less significative memory address
    LDY #$00
loop:
    STA ($10), Y
    INY
    BNE loop

    ; Iterate over more significative memory address
    LDA $11 ; Increment memory pointer Hi address using accumulator
    CLC
    ADC #$1
    STA $11
    CMP #$80; Compare with end memory position
    BNE loop2

    LDA $12
    CLC
    ADC #$11
    CMP #$10
    BNE store
    LDA #$00

store:
    STA $12


    LDX #$20
wait_vsync_end:
    BIT $DF88
    BVS wait_vsync_end
wait_vsync_begin:
    BIT $DF88
    BVC wait_vsync_begin   
    DEX
    BNE wait_vsync_end

    JMP loop3

    .dsb    $fffa-*, $ff    ; filling

* = $fffa
    .word begin
    .word begin
    .word begin
