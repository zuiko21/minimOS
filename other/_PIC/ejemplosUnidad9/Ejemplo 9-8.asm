;						CURSO: "Microcontroladores PIC: Nivel I"
;									SEPTIEMBRE 2014
;							Autor: Mikel Etxebarria Isuskiza
;						Ingeniería de Microsistemas Programados S.L.
;							wwww.microcontroladores.com	
;
;								
;Ejemplo 9-8: Frecuencímetro
;
;Mediante el generador de onda cuadrada del laboratorio, se aplican pulsos por la 
;línea RC0/T1CKI. 
;
;El TMR1 cuenta los pulsos durante un intervalo de 1s. El resultado de la cuenta representa
;el número de pulsos por segundo (Frecuencia en Hz).
;
;Dicha frecuencia se visualiza por la pantalla LCD

		List	p=16F886			;Tipo de procesador
		include	"P16F886.INC"		;Definiciones de registros internos

;Ajusta los valores de las palabras de configuración durante el ensamblado.Los bits no empleados
;adquieren el valor por defecto.Estos y otros valores se pueden modificar según las necesidades

		__config	_CONFIG1, _LVP_OFF&_PWRTE_ON&_WDT_OFF&_EC_OSC&_FCMEN_OFF&_BOR_OFF	;Palabra 1 de configuración
		__config	_CONFIG2, _WRT_OFF&_BOR40V									;Palabra 2 de configuración

		cblock	0x20			;Inicio de variables de la aplicación
			Byte_L				;Parte baja del byte a convertir
			Byte_H				;Parte alta del byte a convertir
			BCD_2				;Byte 2 de conversión a BCD
			BCD_1				;Byte 1 de conversión a BCD
			BCD_0				;Byte 0 de conversión a BCD
			Contador			;Variable de contaje
			Temporal			;Variable temporal
			Delay				;Variable para la temporización
		endc

Lcd_var		equ	0x70			;Inicio de variables de las rutinas LCD	
	
			org	0x00				;Vector de RESET	
			goto	Inicio
			org	0x04				;Vector de interrupción
			goto	Inter
			org	0x05

			include	"LCD4bitsPIC16.inc"	;Incluye rutinas de manejo del LCD

;Visualizar: Visualiza sobre la pantalla LCD los cinco dígitos situados en las variables
;BCD_0, BC_1 y BCD_2
Visualizar	movlw	0x80
			call	LCD_REG			;Posiciona el cursor
			movlw	3
			movwf	Contador		;Inicia contador de bytes a convertir
			movlw	BCD_0
			movwf	FSR				;Inicia puntero índice
Visual_loop	swapf	INDF,W
			andlw	0x0f
			iorlw	0x30			;Convierte a ASCII el nible de más peso
			call	LCD_DATO		;Lo visualiza
			movf	INDF,W
			andlw	0x0f
			iorlw	0x30			;Convierte a ASCII el nible de menos peso
			call	LCD_DATO		;Lo visualiza
			decf	FSR,F			;Siguiente byte
			decfsz	Contador,F
			goto	Visual_loop
			return

;16Bits_BCD: Esta rutina convierte un número binario de 16 bits situado en Cont_H y
;Cont_L y lo convierte en 5 dígitos BCD que se depositan en las variables BCD_0, BCD_1
;y BCD_2, siendo esta última la de menos peso.
;Está presentada en la nota de aplicación AN544 de MICROCHIP y adaptada por MSE
Bits16_BCD	bcf		STATUS,C
			clrf	Contador	
			bsf		Contador,4		;Carga el contador con 16		
			clrf	BCD_0
			clrf	BCD_1
			clrf	BCD_2			;Puesta a 0 inicial

Loop_16		rlf		Byte_L,F
			rlf		Byte_H,F
			rlf		BCD_2,F
			rlf		BCD_1,F
			rlf		BCD_0,F			;Desplaza a izda. (multiplica por 2)
			decfsz	Contador,F
			goto	Ajuste
			return

Ajuste		movlw	BCD_2
			movwf	FSR				;Inicia el índice
			call	Ajuste_BCD		;Ajusta el primer byte
			incf	FSR,F
			call	Ajuste_BCD		;Ajusta el segundo byte
			incf	FSR,F
			call	Ajuste_BCD
			goto	Loop_16

Ajuste_BCD	movf	INDF,W		
			addlw	0x03
			movwf	Temporal	
			btfsc	Temporal,3		;Mayor de 7 el nibble de menos peso ??
			movwf	INDF			;Si, lo acumula
			movf	INDF,W		
			addlw	0x30
			movwf	Temporal
			btfsc	Temporal,7		;Mayor de 7 el nibble de menos peso ??
			movwf	INDF			;Si, lo acumula
			return

;Programa de tratamiento de la interrupción que se provoca cuando el TMR0 temporice 10mS.
;Trabajando a 4MHz el TMR0 evoluciona cada 1uS. Con un preescaler de 256, hay que cargar
;el valor 39 para provocar una interrupción cada 10 mS. Esta se repite 100 veces para obtener una
;temporización total de 1 seg.

Inter		decfsz	Delay,F			;Ha pasado 1000mS (1") ??
			goto	No_1000_mS		;No
Si_1000_mS	bcf		T1CON,0			;TMR1 en Off, cuenta de pulsos externos detenida
			bcf		STATUS,C
			movf	TMR1L,W
			movwf	Byte_L			;Salva parte baja del contador
			movf	TMR1H,W
			movwf	Byte_H			;Salva parta alta del contador
			call	Bits16_BCD		;Convierte a BCD el resultado de la cuenta
			call	Visualizar		;Visualiza el resultado en el LCD
			movlw	~.39
			movwf	TMR0			;Repone el TMR0 para temporizar 10 ms
			movlw	.100
			movwf	Delay			;Repone variable para temporizar otro segundo
			bcf		INTCON,2		;Repone flag del TMR0
			clrf	TMR1L
			clrf	TMR1H			;Borra el TMR1
			bsf		T1CON,0			;TMR1 en On, se inicia la nueva cuenta de pulsos externos
			retfie

No_1000_mS	movlw	~.39
			movwf	TMR0			;Repone para temporizar otros 10mS
			bcf		INTCON,2		;Repone el flag del TMR0
			retfie

;Programa principal
Inicio	   	clrf 	PORTB			;Borra los latch de salida
			clrf	PORTA			;Borra los latch de salida
			bsf		STATUS,RP0
			bsf		STATUS,RP1		;Banco 3
			clrf	ANSEL			;Puerta A digital
			clrf	ANSELH			;Puerta B digital
			bcf		STATUS,RP1		;Banco 1
			clrf	TRISB			;Puerta B se configura como salida
			clrf	TRISA			;Puerta A se configura como salida
			movlw	b'11000111'
			movwf	OPTION_REG		;Preescaler de 256 asociado al TMR0
			movwf	TRISC			;RC0/T1CKI entrada
			bcf		STATUS,RP0		;Selecciona banco 0

;Inicio de la pantalla LCD
			call	UP_LCD			;Configura puerto para el LCD
			call	LCD_INI			;Inicia el LCD
			movlw	b'00001100'
			call	LCD_REG			;LCD On, cursor y blink Off

;El TMR1 actúa como contador externo asíncrono y con un preescaler de 1:1
			movlw	b'00000010'	
			movwf	T1CON			;TMR1 Off
			clrf	TMR1L
			clrf	TMR1H			;Puesta a 0 del TMR1

;El TMR0 interrumpe cada 10mS que se repetirá 100 veces para conseguir 1 segundo.
			movlw	.100
			movwf	Delay			;Prepara temporización total de 1000mS (1")
			movlw	~.39
			movwf	TMR0			;TMR0 comienza a temporizar 10 ms
			bsf		T1CON,0			;TMR1 en On, comienza la cuenta de pulsos externos
			movlw	b'10100000'
			movwf	INTCON			;Habilita interrupción del TMR0

;Bucle principal del programa
Loop		nop
			goto	Loop			;Bucle infinito		

			end						;Fin del programa fuente
