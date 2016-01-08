;						CURSO: "Microcontroladores PIC: Nivel I"
;									SEPTIEMBRE 2014
;							Autor: Mikel Etxebarria Isuskiza
;						Ingeniería de Microsistemas Programados S.L.
;							wwww.microcontroladores.com	
;
;								
;Ejemplo 9-1: Temporizador simple con el TMR0.
;
;Se trata de comprobar el funcionamiento básico del Timer 0. Cuando se detecta un flanco
;descendente en RA0 (conectada con un pulsador), se activa la salida RB0 durante un tiempo
;y luego se desconecta. El TMR0 realiza una temporización de 50mS que se repite tantas veces
;como se indique en la constante "Valor". Así pues la temporización total será de 50mS*Valor.
;
;Suponiendo una frecuencia de trabajo de 4MHz, 4Tosc=1uS. Trabajando con un prescaler de 256,
;al TMR0 hay que cargarlo con 195 para temporizar 50mS (Temporización=1uS*195*256)

	
		List	p=16F886		;Tipo de procesador
		include	"P16F886.INC"	;Definiciones de registros internos

;Ajusta los valores de las palabras de configuración durante el ensamblado.Los bits no empleados
;adquieren el valor por defecto.Estos y otros valores se pueden modificar según las necesidades

		__config	_CONFIG1, _LVP_OFF&_PWRTE_ON&_WDT_OFF&_EC_OSC&_FCMEN_OFF&_BOR_OFF	;Palabra 1 de configuración
		__config	_CONFIG2, _WRT_OFF&_BOR40V									;Palabra 2 de configuración

Valor			equ	.20				;Constante para temporizar 1 seg (50mS*20)

Temp			equ	0x020			;Variable para la temporización
              
				org	0x00			;Vector de RESET
				goto	Inicio
				org	0x05

;*********************************************************************************************
;Delay: El Timer 0 realiza un retardo de 50mS que se repite tantas veces como se indica en la 
;constante valor

Delay			movlw	Valor
				movwf	Temp		;Nº de veces a temporizar 50 mS 
Delay_1			movlw	~.195  
				movwf	TMR0		;Inicia el Timer 0 con 195 (195*256=49.9mS)
				bcf		INTCON,T0IF	;Repone flag del TMR0
Delay_2			btfss	INTCON,T0IF	;Fin de los 50mS ??
				goto	Delay_2		;No, el TMR0 no ha terminado
				decfsz 	Temp,F		;Si. Decrementa el contador. Fin de temporización ??
           		goto 	Delay_1		;No, el TMR0 temporiza otros 50 mS
				return				;Si, final de la temporización

;Programa principal
Inicio			clrf 	PORTB		;Borra los latch de salida
				bsf		STATUS,RP0
				bsf		STATUS,RP1	;Selecciona banco 3
				clrf	ANSEL		;Puerta A digital
				clrf	ANSELH		;Puerta B digital
				bcf		STATUS,RP1	;Selecciona banco 1
				movlw	b'11111110'
				movwf	TRISB		;RB0 se configura como salida
				movlw	b'00111111'		
				movwf	TRISA		;RA5:RA0 se configuran como entrada
				movlw	b'00000111'	
				movwf	OPTION_REG	;TMR0 con reloj interno y preescaler de 256		
				bcf		STATUS,RP0	;Selecciona banco 0			                                                                         

;Este es el cuerpo principal del programa. Espera a que en RA0 se detecte un flanco descendente

Loop			btfsc 	PORTA,0     ;RA0=0 ??
           		goto 	Loop		;No, esperar
				bsf		PORTB,0		;Si activar RB0
				call	Delay		;Temporizar
				bcf		PORTB,0		;Desactivar RB0
				goto	Loop		;Repetir el proceso

				end					;Fin del programa fuente
