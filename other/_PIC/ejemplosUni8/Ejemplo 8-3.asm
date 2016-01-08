;						CURSO: "Microcontroladores PIC: Nivel I"
;									SEPTIEMBRE 2014
;							Autor: Mikel Etxebarria Isuskiza
;						Ingeniería de Microsistemas Programados S.L.
;							wwww.microcontroladores.com	
;
;								
;Ejemplo 8-3: Control del teclado mediante interrupción por cambio de estado.
;
;Haciendo uso de las rutinas incluidas en los ficheros Teclado.inc y LCD4bitsPIC16.inc, se trata 
;de leer el teclado y, visualizar sobre el módulo LCD  la tecla pulsada.
;
;El ejemplo pretende mostrar la interrupción por cambio de estado en cualquiera de las líneas 
;RB4-RB7 del PIC El sistema se mantiene en el modo SLEEP de bajo consumo y sólo reacciona cuando
;tiene lugar la pulsación de cualquier tecla.

		List	p=16F886			;Tipo de procesador
		include	"P16F886.INC"		;Definiciones de registros internos

;Ajusta los valores de las palabras de configuración durante el ensamblado.Los bits no empleados
;adquieren el valor por defecto.Estos y otros valores se pueden modificar según las necesidades

		__config	_CONFIG1, _LVP_OFF&_PWRTE_ON&_WDT_OFF&_EC_OSC&_FCMEN_OFF&_BOR_OFF	;Palabra 1 de configuración
		__config	_CONFIG2, _WRT_OFF&_BOR40V									;Palabra 2 de configuración
                 
Temporal_1	equ	0x20		;Variable temporal
Temporal_2	equ	0x21		;Variable temporal
Temporal_3	equ	0x22		;Variable temporal
Lcd_var		equ	0x70		;Variables (3) empleadas por las rutinas de manejo del LCD
Key_var		equ 0x73		;Inicio de las 6 variables empleadas por las rutinas de manejo del teclado
	
				org	0x00		;Vector de RESET	
				goto	Inicio
				org	0x04
				goto	Interrupcion	;Vector de interrupción
				org	0x05
				
Tabla_Mensajes:	movwf	PCL				;Desplazamiento sobre la tabla

Mens_0			equ	$					;Mens_0 apunta al primer carácter
				dt	"Has pulsado : ",0x00

			include	"TECLADO.INC"		;Incluir rutinas de manejo del teclado
			include	"LCD4bitsPIC16.inc"	;Incluir rutinas de manejo del LCD

;*************************************************************************************
;Mensaje: Esta rutina envía a la pantalla LCD el mensaje cuyo inicio está  indicado en
;el acumulador. El fin de un mensaje se determina mediante el código 0x00

Mensaje			movwf  	Temporal_1     	;Salva posición de la tabla
Mensaje_1  		movf   	Temporal_1,W   	;Recupera posición de la tabla
           		call   	Tabla_Mensajes 	;Busca caracter de salida
           		movwf  	Temporal_2     	;Guarda el caracter
            	movf   	Temporal_2,F
            	btfss  	STATUS,Z       	;Mira si es el último
            	goto   	Mensaje_2
            	return
Mensaje_2   	call    LCD_DATO       	;Visualiza en el LCD
            	incf    Temporal_1,F   	;Siguiente caracter
            	goto    Mensaje_1

;Programa de tratamiento de la interrupción por cambio de estado							

Interrupcion	call	Key_Scan		;Explora el teclado
				movf	Tecla,W
				movwf	Temporal_3		;Salva la tecla temporalmente

Inter_1			call	Key_Scan		;Explora el teclado
				movlw	0x80
				subwf	Tecla,W
				btfss	STATUS,Z		;Se ha liberado la tecla pulsada ?
				goto	Inter_1			;No, esperar que se libere

				call	UP_LCD			;Configura Puertas A y B como salidas para manejo del LCD		
				movlw	0x8f
				call	LCD_REG			;Posiciona el cursor del LCD
				movf	Temporal_3,W	;Recupera la tecla que se pulsó
				sublw	.9
				btfss	STATUS,C       	;Es mayor que 9 (A, B,C,D,E,F)?
				goto	Mayor_que_9		;Si
				movf	Temporal_3,W	;No
				addlw	0x30           	;Ajuste ASCII de los caracteres del 0 al 9
				call	LCD_DATO		;Visualizar sobre el LCD
				goto	Inter_Fin												
Mayor_que_9		movf	Temporal_3,W
				addlw	0x37			;Ajuste ASCII de los caracteres de la A a la F
				call	LCD_DATO       	;Visualiza sobre el LCD

Inter_Fin		clrf	PORTA
				clrf	PORTB
				bsf		STATUS,RP0		;Selecciona banco 1
				movlw	b'11110000'
				movwf	TRISB			;RB0-RB3 salidas, RB4-RB7 entradas
				bcf		STATUS,RP0		;Selecciona banco 0	
				movf	PORTB,W			;Lee estado actual de reposo de las entradas
				bcf		INTCON,RBIF		;Reponer el flag de interrupción
				retfie

;Programa principal
Inicio:			bsf		STATUS,RP0
				bsf		STATUS,RP1		;Banco 3
				clrf	ANSEL			;Puerta A digital
				clrf	ANSELH			;Puerta B digital
				bcf		STATUS,RP1		;Banco 1
				movlw	b'11110000'
				movwf	WPUB			;Activa cargas pull-up para RB7:RB4
				bcf		OPTION_REG,NOT_RBPU	;Habita cargas pull-Up
				movlw	b'11110000'		
				movwf	IOCB			;Habilita interrupción por cambio de estado para RB7:RB4
				bcf		STATUS,RP0		;Banco 0
		
				call	UP_LCD			;Configura puertos para LCD
				call	LCD_INI			;Secuencia de inicio del LCD
				movlw	b'00001100'
				call	LCD_REG			;LCD en ON
				movlw	b'00000001'
				call	LCD_REG			;Borra LCD y HOME

;Salida del mensaje "Tecla pulsada:"
				
				movlw	Mens_0
				call	Mensaje			;Visualiza el mensaje		
				clrf	PORTA
				clrf	PORTB
				bsf		STATUS,RP0		;Selecciona banco 1
				movlw	b'11110000'
				movwf	TRISB			;RB0-RB3 salidas, RB4-RB7 entradas
				bcf		STATUS,RP0		;Selecciona banco 0
				movf	PORTB,W			;Lee estado actual de reposo de las entradas
				bcf		INTCON,RBIF		;Reponer el flag de interrupción
				bsf		INTCON,RBIE		;Activa máscara de interrupción RBIE
				bsf		INTCON,GIE		;Activa interrupciones

;Bucle principal

Loop:			sleep
				nop
				goto	Loop	

				end						;Fin del programa fuente
