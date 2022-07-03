*=$FF00

begin:
    ; Set video mode
    LDA #$3F
    STA $df80

    ; Store at $10 video memory pointer
    LDA #$60	; *** this is done at loop3, thus not needed here
    STA $11
    LDA #$00	; *** may use Y instead, so it will be reset as well
    STA $10 ; Current video memory position

    ; Store at $12 current color
    LDA #$11
    STA $12		; *** no actual need as modified code won't affect A

loop3:
    ; Init memory position
    LDA #$60	; *** if using X instead, will keep A intact, and LDX could be before loop3 as will not change, but not really worth
    STA $11

loop2:
    ; Load color into accumulator
    LDA $12		; *** no need if using X above

    ; Iterate over less significative memory address
    LDY #$00	; *** the loop below exits when zero, no need for this as long as it's reset when setting the pointer
loop:
    STA ($10), Y	; *** MAIN LOOP, takes 256*11-1 clocks, done 32 times is ~90 kt or ~59 ms (about 3 fields)
    INY
    BNE loop
; *** remaining code adds little overhead as will be executed 0.4% of the time
    ; Iterate over more significative memory address
    LDA $11 ; Increment memory pointer Hi address using accumulator *** can be simplified, see below
    CLC
    ADC #$1
    STA $11
    CMP #$80; Compare with end memory position
    BNE loop2	; *** BPL is best, CMP is not needed and neither is A, as INC $11 will suffice!

    LDA $12		; *** not needed if using modifications
    CLC
    ADC #$11
    CMP #$10	; *** when it wraps, Carry is set, thus remove CMP and use BCC instead
    BNE store	; *** alternatively, branch to loop3
    LDA #$00

store:
    STA $12		; *** not really needed

    JMP loop3	; *** could use BRA (CMOS) or even BCS/BEQ (as A was reset)

    .dsb    $fffa-*, $ff    ; filling

* = $fffa
    .word begin
    .word begin
    .word begin
