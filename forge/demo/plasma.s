; plasma effect for Durango-X
; based on code from Commodore 64 & 6510 retro-programming
; https://www.youtube.com/watch?v=w93AncybKaY
; (c) 2024 Carlos J. Santisteban
; last modified 20240707-1513

; **************************
; *** memory definitions ***
; **************************
; zeropage
	ptr		= $FC			; indirect pointer
; standard RAM
	fw_irq	= $0200
	fw_nmi	= $0202
; Durango·X hardware
	screen3	= $6000
	IO8mode	= $DF80
	IO8lf	= $DF88			; EEEEEEEK
	IOAen	= $DFA0
	IOBeep	= $DFB0

	* = $800				; suitable for Pocket format
; *********************************
; *** pocket header (essential) ***
; *********************************
start:
; header ID
	.byt	0				; [0]=NUL, first magic number
	.asc	"pX"			; pocket format Durango-X executable
	.word	start			; load address
	.word	exec			; execute address
	.byt	13				; [7]=NEWLINE, second magic number
; filename
	.asc	"Plasma effect"	; C-string with filename @ [8], max 220 chars
	.byt	0, 0			; second terminator for optional comment, just in case

; advance to end of header
	.dsb	start + $E6 - *, $FF

; NEW library commit (user field 2)
	.asc	"$$$$$$$$"
; NEW main commit (user field 1)
	.asc	"$$$$$$$$"
; NEW coded version number
	.word	$1001			; 1.0a1		%vvvvrrrrsshhbbbb, where revision = %hhrrrr, ss = %00 (alpha), %01 (beta), %10 (RC), %11 (final)
; date & time in MS-DOS format at byte 248 ($F8)
	.word	$7A00			; time, 15.16		0111 1-010 000-0 0000
	.word	$58E7			; date, 2024/7/7	0101 100-0 111-0 0111
; filesize in top 32 bits (@ $FC) now including header ** must be EVEN number of pages because of 512-byte sectors
	.word	end-start		; filesize including header
	.word	0				; 64K space does not use upper 16 bits, [255]=NUL may be third magic number

; ******************
; *** init code ***
; ******************
exec:
	SEI						; usual 6502 stuff
	CLD
	LDX #$FF
	TXS
; Durango·X specific stuff
	LDA #$38				; flag init and interrupt disable
	STA IO8mode				; set colour mode
	STX IOAen				; enable hardware interrupt (LED turns off)
; black everywhere
	LDX #>screen3
	LDY #<screen3			; screen address
	STY ptr
	TYA						; actually 0
cl_page:
		STX ptr+1			; update page
clear:
			STA (ptr), Y	; clear this byte
			INY				; next in page
			BNE clear
		INX					; next page
		BPL cl_page			; until the end of screen

lock:
	BRA lock				; *** TESTING

end:

/*

 START
; first step is to create a table with sine + cosine values 
; The addition is performed on a proportionate basis
; the table is changed on every frame

        LDX #64 ; 25 rows (+40 additional values)
loop      
        LDA sin,X
        
addpart
        ADC cos,X ; Y can be used as index 
                 ; insofar as it's decremented
        STA sinecosine,x ; new table
        DEX
        BPL loop
                   ; values in sine + cos table are changed
        INC loop+1 ; after each frame
        DEC addpart+1

; the first 40 succesive values represent a value
; for each of the 40 columns
; The 25 following successive values represent the 25 rows 
; Once the sine + cos table with the 65 values is created
; The code adds and combines them giving 1,000 different values
; values 0-39 in the table : column
; values 40-64 in the table : row
; the routine deals each column, line by line 

        LDX #39      
PLOT
        LDA sinecosine,x
        ;LSR
        STA $10 ; address $10 in memory will be used 
                ; to store the value used
                ; for each column
; row/line 0
        ADC sinecosine+40 ; value for row/line 0
        TAY
        LDA charcode,y ; load the charcode from a table
        STA $0400,x     ; read and indexed with Y
                        ; and store it in the screen memory
        LDA colorcode,y ; same thing about color memory        
        STA $d800,x     ; operation is repeated every 
                        ; 25 screen rows/lines
        
; row/line 1
        LDA $10
        ADC sinecosine+41
        TAY
        LDA charcode,y  ; load the charcode from a table
                        ; read and indexed with Y
        STA $0400+40,x  ; and store it in the screen memory
        LDA colorcode,y ; same thing about color memory         
        STA $d800+40,x


; row/line 2
        LDA $10
        ADC sinecosine+42
        TAY           
        LDA charcode,y
        STA $0400+80,x                
        LDA colorcode,y         
        STA $d800+80,x

        
; row/line 3
        LDA $10
        ADC sinecosine+43
        TAY
        LDA charcode,y
        STA $0400+120,x
        LDA colorcode,y         
        STA $d800+120,x

; row/line 4
        LDA $10
        ADC sinecosine+44
        TAY
        LDA charcode,y
        STA $0400+160,x
        LDA colorcode,y         
        STA $d800+160,x
     
; row/line 5
        LDA $10
        ADC sinecosine+45
        TAY
        LDA charcode,y
        STA $0400+200,x
        LDA colorcode,y         
        STA $d800+200,x

; row/line 6
        LDA $10
        ADC sinecosine+46
        TAY
        LDA charcode,y
        STA $0400+240,x
        LDA colorcode,y         
        STA $d800+240,x

; row/line 7
        LDA $10 
        ADC sinecosine+47
        TAY
        LDA charcode,y
        STA $0400+280,x
        LDA colorcode,y         
        STA $d800+280,x

; row/line 8
        LDA $10 
        ADC sinecosine+48
        TAY
        LDA charcode,y
        STA $0400+320,x
        LDA colorcode,y         
        STA $d800+320,x

;row/line 9
        LDA $10 
        ADC sinecosine+49
        TAY
        LDA charcode,y
        STA $0400+360,x
        LDA colorcode,y         
        STA $d800+360,x

;row/line 10
        LDA $10 
        ADC sinecosine+50
        TAY
        LDA charcode,y
        STA $0400+400,x
        LDA colorcode,y         
        STA $d800+400,x

;row/line 11
        LDA $10 
        ADC sinecosine+51
        TAY
        LDA charcode,y
        STA $0400+440,x
        LDA colorcode,y         
        STA $d800+440,x

;row/line 12
        LDA $10 
        ADC sinecosine+52
        TAY
        LDA charcode,y
        STA $0400+480,x
        LDA colorcode,y         
        STA $d800+480,x

;row/line 13
        LDA $10 
        ADC sinecosine+53
        TAY
        LDA charcode,y
        STA $0400+520,x
        LDA colorcode,y         
        STA $d800+520,x

;row/line 14
        LDA $10 
        ADC sinecosine+54
        TAY
        LDA charcode,y
        STA $0400+560,x
        LDA colorcode,y         
        STA $d800+560,x

;row/line 15
        LDA $10 
        ADC sinecosine+55
        TAY
        LDA charcode,y
        STA $0400+600,x
        LDA colorcode,y         
        STA $d800+600,x

;row/line 16
        LDA $10 
        ADC sinecosine+56
        TAY
        LDA charcode,y
        STA $0400+640,x
        LDA colorcode,y         
        STA $d800+640,x

;row/line 17
        LDA $10 
        ADC sinecosine+57
        TAY
        LDA charcode,y
        STA $0400+680,x
        LDA colorcode,y         
        STA $d800+680,x

;row/line 18
        LDA $10 
        ADC sinecosine+58
        TAY
        LDA charcode,y
        STA $0400+720,x
        LDA colorcode,y         
        STA $d800+720,x

;row/line 19
        LDA $10 
        ADC sinecosine+59
        TAY
        LDA charcode,y
        STA $0400+760,x
        LDA colorcode,y         
        STA $d800+760,x

;row/line 20
        LDA $10 
        ADC sinecosine+60
        TAY
        LDA charcode,y
        STA $0400+800,x
        LDA colorcode,y         
        STA $d800+800,x

;row/line 21
        LDA $10 
        ADC sinecosine+61
        TAY
        LDA charcode,y
        STA $0400+840,x
        LDA colorcode,y         
        STA $d800+840,x

;row/line 22
        LDA $10 
        ADC sinecosine+62
        TAY
        LDA charcode,y
        STA $0400+880,x
        LDA colorcode,y         
        STA $d800+880,x

;row/line 23
        LDA $10 
        ADC sinecosine+63
        TAY
        LDA charcode,y
        STA $0400+920,x
        LDA colorcode,y         
        STA $d800+920,x

;row/line 24
        LDA $10 
        ADC sinecosine+64
        TAY
        LDA charcode,y
        STA $0400+960,x
        LDA colorcode,y         
        STA $d800+960,x             
        DEX
        BMI loop_exit
        JMP PLOT

loop_exit

        LDY #50
@exit
        DEX
        BNE @exit
@exit2
        DEY
        BNE @exit

       JMP START

ALIGN   ; here the code is aligned
        ; so that the LB adress is at $00
charcode
        DCB 16,195 ; 
        DCB 16,196 ; number of bytes used will determine
        DCB 16,197 ; the thickness of the layers pattern
        DCB 16,198 ;         

        DCB 16,195
        DCB 16,196
        DCB 16,197
        DCB 16,198
        
        DCB 16,195
        DCB 16,196
        DCB 16,197
        DCB 16,198        
                 
        DCB 16,195
        DCB 16,196
        DCB 16,197
        DCB 16,198

ALIGN   ; here the code is aligned
        ; so that the LB adress is at $00
colorcode
        DCB 16,00
        DCB 16,11
        DCB 16,12
        DCB 16,15

        DCB 16,00
        DCB 16,11
        DCB 16,12
        DCB 16,15

        DCB 16,00
        DCB 16,11
        DCB 16,12
        DCB 16,15

        DCB 16,00
        DCB 16,11
        DCB 16,12
        DCB 16,15
*/
