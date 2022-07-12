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
	TAX		; use as colour index

    ; Store at $12 current color
;   LDA #$11
;   STA $12

loop3:
    ; Init memory position
    LDA #$60
    STA $11


loop2:
    ; Load color into accumulator
;    LDA $12
	LDA table, X

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

;    LDA $12
;    CLC
;    ADC #$11
;    CMP #$10
;    BNE store
;    LDA #$00

;store:
;    STA $12
	INX			; next colour
	CPX #$10	; out of 16
	BNE next
		LDX #0
next:

    LDY #3
wait_vsync_end:
    BIT $DF88
    BVS wait_vsync_end
wait_vsync_begin:
    BIT $DF88
    BVC wait_vsync_begin   
    DEY
    BNE wait_vsync_end

    JMP loop3

table:
; simple index order for greyscale
;	.byt	$00, $88, $44, $CC, $22, $AA, $66, $EE, $11, $99, $55, $DD, $33, $BB, $77, $FF
;	%luma	0,   11,  20,  31,  30,  41,  50,  61,  39,  50,  59,  70,  69,  80,  89,  100%      

; optimized index order for strictly injective function
	.byt	$00, $88, $44, $22, $CC, $11, $AA, $66, $99, $55, $EE, $33, $DD, $BB, $77, $FF
;	%luma	0,   11,  20,  30,  31,  39,  41,  50*, 50*, 59,  61,  69,  70,  80,  89,  100%

    .dsb    $fffa-*, $ff    ; filling

* = $fffa
    .word begin
    .word begin
    .word begin
