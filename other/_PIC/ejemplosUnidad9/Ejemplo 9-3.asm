;						CURSO: "Microcontroladores PIC: Nivel I"
;									SEPTIEMBRE 2014
;							Autor: Mikel Etxebarria Isuskiza
;						Ingeniería de Microsistemas Programados S.L.
;							wwww.microcontroladores.com	
;
;								
;Ejemplo 9-3: El TMR0 en el modo contador de eventos externos
;
;Sobre el display 7 segmentos de las unidades, conectado a la puerta B se visualizará el número de pulsos 
;aplicados por RA4/T0CKI al TMR0, Cuando lleguen 6 pulsos se provoca una interrupción 
;cuyo tratamiento activa todos los segmentos del display durante 1 seg. y luego se apagan. 
;Para repetir el proceso se debe accionar el pulsador de RESET
	
		List	p=16F886		;Tipo de procesador
		include	"P16F886.INC"	;Definiciones de registros internos
		#define Fosc 4000000	;Velocidad de trabajo

;Ajusta los valores de las palabras de configuración durante el ensamblado.Los bits no empleados
;adquieren el valor por defecto.Estos y otros valores se pueden modificar según las necesidades

		__config	_CONFIG1, _LVP_OFF&_PWRTE_ON&_WDT_OFF&_EC_OSC&_FCMEN_OFF&_BOR_OFF	;Palabra 1 de configuración
		__config	_CONFIG2, _WRT_OFF&_BOR40V									;Palabra 2 de configuración
                    
Contador		equ	0x20				;Variable del contador
MSE_Delay_V		equ	0x73				;Variables (3) empleadas por las macros de temporización
		
				org	0x00				;Vector de RESET
				goto	Inicio
				org	0x04
				goto	Interrupcion	;Vector de interrupción
				org	0x05

		include	"MSE_Delay.inc"			;Incluir rutinas de temporización
	

;**********************************************************************************
;Tabla: Esta rutina convierte el código binario presente en los 4 bits de menos peso
;del reg. W en su equivalente a 7 segmentos. Para ello el valor de W se suma al valor actual
;del PC. Se obtiene un desplazamiento que apunta al elemento deseado de la tabla.El código 7 
;segmentos retorna también en el reg. W.

Tabla:			addwf	PCL,F		;Desplazamiento sobre la tabla
				retlw	b'11000000'	;Dígito 0
				retlw	b'11111001'	;Dígito 1
				retlw	b'10100100'	;Dígito 2
				retlw	b'10110000'	;Dígito 3
				retlw	b'10011001'	;Dígito 4
				retlw	b'10010010'	;Dígito 5
				retlw	b'10000010'	;Dígito 6
				retlw	b'11111000'	;Dígito 7
				retlw	b'10000000'	;Dígito 8
				retlw	b'10011000'	;Dígito 9
				retlw	b'10001000'	;Dígito A
				retlw	b'10000011'	;Dígito B
				retlw	b'11000110'	;Dígito C
				retlw	b'10100001'	;Dígito D
				retlw	b'10000110'	;Dígito E
				retlw	b'10001110'	;Dígito F

;Programa de tratamiento de la interrupción provocada cuando TMR0 ha contado 6 eventos externos

Interrupcion	bcf		INTCON,T0IF	;Repone el flag del TMR0
				bcf		INTCON,T0IE	;Dsactiva interrupción del TMR0
				clrf	PORTB		;Activa todos los segmentos del display
				Delay	1000 Milis	;Temporiza 1 segundo
				movlw	b'11111111'
				movwf	PORTB		;Desactiva los segmentos del display
				sleep				;Sistema detenido

;Programa principal
Inicio			movlw	b'11111111'
				movwf	PORTB		;Apaga los segmentos
				bsf		STATUS,RP0
				bsf		STATUS,RP1	;Selecciona banco 3
				clrf	ANSEL		;Puerta A digital
				clrf	ANSELH		;Puerta B digital
				bcf		STATUS,RP1	;Selecciona banco 1
				clrf	TRISB		;RB7:RB0 se configuran como salida
				movlw	b'00111111'		
				movwf	TRISA		;Puerta A se configura como entrada		
				movlw	b'00111000'	;TMR0 modo contador sensible al flanco descendente de RA4/T0CKI
				movwf	OPTION_REG	;Preescaler de 1 para el TMR0 en el modo contador
				bcf		STATUS,RP0	;Selecciona banco 0			                                                                         
		
				movlw	~.6
				movwf	TMR0		;Repone el TMR0 con nº de pulsos externos a contar
				movlw	b'10100000'
				movwf	INTCON		;Activa interrupción del TMR0

Loop			comf	TMR0,W		;lee el valor actual del TMR0
				andlw	b'00001111'
				call	Tabla		;Convierte a 7 segmentos
				movwf	PORTB		;Lo visualiza sobre el display
				goto	Loop

				end					;Fin del programa fuente

