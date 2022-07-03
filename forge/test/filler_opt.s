*=$FF00

begin:
; Set video mode
    LDA #$3F
    STA $df80

; Store at $10 video memory pointer
; MSB will be set on the loop
    LDY #$00	; reset LSB & index
    STY $10 ; Current video memory position

    LDA #$11	; *** current colour
	LDX #$60	; MSB of initial video address
loop3:
; Init memory position
    STX $11

loop2:
    ; Iterate over less significative memory address
loop:
    STA ($10), Y	; *** MAIN LOOP, takes 256*11-1 clocks, done 32 times is ~90 kt or ~59 ms (about 3 fields)
    INY
    BNE loop
; *** remaining code adds little overhead as will be executed 0.4% of the time
; Iterate over more significative memory address
    INC $11 ; Increment memory pointer Hi address
    BPL loop2	; Compare with end memory position (could use 'loop' label as well)

    CLC
    ADC #$11	; *** next colour
    BCC loop3
    LDA #$00

    BCS loop3	; *** could use BRA (CMOS) or even BEQ (as A was reset)

    .dsb    $fffa-*, $ff    ; filling

* = $fffa
    .word begin
    .word begin
    .word begin
