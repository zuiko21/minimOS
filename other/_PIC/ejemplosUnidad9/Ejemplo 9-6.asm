;						CURSO: "Microcontroladores PIC: Nivel I"
;									SEPTIEMBRE 2014
;							Autor: Mikel Etxebarria Isuskiza
;						Ingeniería de Microsistemas Programados S.L.
;							wwww.microcontroladores.com	
;
;								
;Ejemplo 9-6: El TMR1 como contador con control de disparo externo
;
;Ejemplo similar al anterior. Mediante el generador de onda cuadrada del laboratorio 
;se aplican pulsos por la línea RC0/T1CKI. La pantalla LCD visualizará, en binario, el 
;contenido del TMR1:
;
;En esta ocasión se emplea el control de disparo del Timer 1 propio del los dispositivos
;PIC16F88X. Esta función consiste en controlar el Timer 1 mediante una señal externa de
;disparo que activa o desactiva el contaje. Efectivamente la señal RB5/AN13/T1G actúa
;como señal de disparo (/T1G) y se conecta con la entrada E0. Cuando ésta está a nivel "0"
;la cuenta se detiene. Cuando está a "1" la cuenta se reanuda desde donde se quedó

		List	p=16F886			;Tipo de procesador
		include	"P16F886.INC"		;Definiciones de registros internos

;Ajusta los valores de las palabras de configuración durante el ensamblado.Los bits no empleados
;adquieren el valor por defecto.Estos y otros valores se pueden modificar según las necesidades

		__config	_CONFIG1, _LVP_OFF&_PWRTE_ON&_WDT_OFF&_EC_OSC&_FCMEN_OFF&_BOR_OFF	;Palabra 1 de configuración
		__config	_CONFIG2, _WRT_OFF&_BOR40V									;Palabra 2 de configuración

Temporal_1	equ	0x20		;Variable temporal
Temporal_2	equ	0x21		;variable temporal
Lcd_var		equ	0x70		;Inicio de variables de las rutinas LCD

			org	0x00				;Vector de RESET	
			goto	Inicio
			org	0x05

			include	"LCD4bitsPIC16.inc"	;Incluir rutinas de manejo del LCD

;Visualiza: Esta rutina coge el octeto presente en la variable Temporal_1, lo convierte
;a 8 caracteres ASCII (0 o 1) y los visualiza sobre el LCD

Visualiza:		movlw	.8
				movwf	Temporal_2		;Nº de caracteres a visualizar
Visual_loop		rlf		Temporal_1,F
				btfsc	STATUS,C		;Testea el bit a visualizar
				goto	Bit_1			;Está a 1
				movlw	'0'
				goto	Visu_1
Bit_1			movlw	'1'
Visu_1			call	LCD_DATO		;Visualiza el "0" o el "1" sobre el LCD
				decfsz	Temporal_2,F	;Siguiente bit/carácter
				goto	Visual_loop
				return
		
;Programa principal
Inicio	      	bsf		STATUS,RP0
				bsf		STATUS,RP1		;Banco 3
				clrf	ANSEL			;Puerta A digital
				clrf	ANSELH			;Puerta B digital
				bcf		STATUS,RP1		;Banco 1
				movlw	b'11111111'	
				movwf	TRISB			;RB5 entrada
				movwf	TRISC			;Puerta C como entrada
				bcf		STATUS,RP0		;Selecciona banco 0

;El TMR1 actúa como contador externo asíncrono y con un preescaler de 1:1
				clrf	TMR1L
				clrf	TMR1H			;Puesta a 0 del TMR1

;Activa el TMR1 en modo contador. Habilita la función de disparo cuando la entrada RB5/AN13//T1G = "1"
				movlw	b'11000011'
				movwf	T1CON			;Configura TMR1

;Inicio de la pantalla LCD
				call	UP_LCD			;Configura puerto para el LCD
				call	LCD_INI			;Inicia el LCD
				movlw	b'00001100'
				call	LCD_REG			;LCD On, cursor y blink Off
	
Loop			movlw	0x80
				call	LCD_REG			;Cursor home
				movf	TMR1H,W
				movwf	Temporal_1		;Lee byte alto del TMR1
				call	Visualiza		;Visualiza en binario
				movf	TMR1L,W
				movwf	Temporal_1		;Lee byte bajo del TMR1
				call	Visualiza		;Visualiza en binario

				goto	Loop			;Bucle infinito		

				end						;Fin del programa fuente
