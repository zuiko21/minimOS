;						CURSO: "Microcontroladores PIC: Nivel I"
;									SEPTIEMBRE 2014
;							Autor: Mikel Etxebarria Isuskiza
;						Ingeniería de Microsistemas Programados S.L.
;							wwww.microcontroladores.com	
;
;								
;Ejemplo 9-2: La interrupción del TMR0.
;
;Se trata de comprobar la interrupción provocada por el TMR0. El programa
;lee el estado de los interruptores conectados a RA0 y RA1 para reflejarlo en
;los leds conectados a RB0 y RB1 respectivamente. Al mismo tiempo el TMR0
;genera una interrupción cada 0.01 seg. (10 mS) que se repetirá 50 veces con objeto 
;de hacer intermitencia de 500 mS sobre el led conectado a RB3.

	
		List	p=16F886		;Tipo de procesador
		include	"P16F886.INC"	;Definiciones de registros internos

;Ajusta los valores de las palabras de configuración durante el ensamblado.Los bits no empleados
;adquieren el valor por defecto.Estos y otros valores se pueden modificar según las necesidades

		__config	_CONFIG1, _LVP_OFF&_PWRTE_ON&_WDT_OFF&_EC_OSC&_FCMEN_OFF&_BOR_OFF	;Palabra 1 de configuración
		__config	_CONFIG2, _WRT_OFF&_BOR40V									;Palabra 2 de configuración

Contador		equ	0x020			;Variable para la temporización
              
				org	0x00			;Vector de RESET
				goto	Inicio
				org	0x04			;Vector de interrupción
				goto	Interrupcion
				org	0x05

Interrupcion   	bcf		INTCON,T0IF	;Repone flag del TMR0
				decfsz 	Contador,F	;Decrementa el contador. Ha habido 50 interrupciones ??
           		goto 	Seguir		;No, no han pasado los 500 mS
Con_si_0   		movlw 	.50			;Si, han pasado los 500 mS
           		movwf 	Contador   	;Repone el contador nuevamente para contar otras 50 interrupciones
           		movlw	b'00001000'
				xorwf	PORTB,F		;RB3 cambia de estado
Seguir    		movlw 	~.39
           		movwf 	TMR0      	;Repone el TMR0 con 39
           		retfie				;Retorno de interrupción

Inicio			clrf 	PORTB		;Borra los latch de salida
				bsf		STATUS,RP0
				bsf		STATUS,RP1	;Selecciona banco 3
				clrf	ANSEL		;Puerta A digital
				clrf	ANSELH		;Puerta B digital
				bcf		STATUS,RP1	;Selecciona banco 1
				clrf	TRISB		;RB7:RB0 se configuran como salida
				movlw	b'00111111'		
				movwf	TRISA		;RA5:RA0 se configuran como entrada
				movlw	b'00000111'
				movwf	OPTION_REG	;Preescaler de 256 para el TMR0		
				bcf		STATUS,RP0	;Selecciona banco 0			                                                                         

;El TMR0 se carga con 39. Con un preescaler de 256 y a una frecuencia de 4MHz se obtiene una interrupción
;cada 10mS. Se habilita la interrupción del TMR0.

				movlw	~.39
				movwf	TMR0		;Carga el TMR0 con 39
				movlw	.50
				movwf	Contador	;Nº de veces a repetir la interrupción
				movlw	b'10100000'
				movwf	INTCON		;Activa la interrupción del TMR0

;Este es el cuerpo principal del programa. Consiste en leer constantemente el estado de RA0 y RA1 para visualizar
;sobre RB0 y RB1 sin que cambie el estado actual de RB7

Loop			btfsc 	PORTA,0     ;Testea el estado de RA0
           		goto 	RA0_ES_1
           		bcf 	PORTB,0		;Desactiva RB0
           		goto 	TEST_RB1
RA0_ES_1   		bsf 	PORTB,0		;Activa RB0
TEST_RB1   		btfsc 	PORTA,1     ;Testea el estado de RA1
           		goto 	RA1_ES_1
           		bcf 	PORTB,1		;Desactiva RB1
           		goto 	Loop
RA1_ES_1  	 	bsf 	PORTB,1		;Activa RB1
				goto 	Loop

				end					;Fin del programa fuente
