;						CURSO: "Microcontroladores PIC: Nivel I"
;									SEPTIEMBRE 2014
;							Autor: Mikel Etxebarria Isuskiza
;						Ingeniería de Microsistemas Programados S.L.
;							wwww.microcontroladores.com	
;
;								
;Ejemplo 9-9: Interrupción periódica con el TMR2
;
;El TMR2 provoca una interrupción cada 10 mS. Transcurridas 100 interrupciones, el tiempo total
;transcurrido es de 1 segundo.
;
;El segundero se visualiza sobre el display 7 segmentos conectado a la puerta B. 
;RA2 y RA3 controlan los displays de unidades y decenas respectivamente

		List	p=16F886		;Tipo de procesador
		include	"P16F886.INC"	;Definiciones de registros internos
		#define Fosc 4000000	;Velocidad de trabajo

;Ajusta los valores de las palabras de configuración durante el ensamblado.Los bits no empleados
;adquieren el valor por defecto.Estos y otros valores se pueden modificar según las necesidades

		__config	_CONFIG1, _LVP_OFF&_PWRTE_ON&_WDT_OFF&_EC_OSC&_FCMEN_OFF&_BOR_OFF	;Palabra 1 de configuración
		__config	_CONFIG2, _WRT_OFF&_BOR40V									;Palabra 2 de configuración

		cblock 0x20
			Contador			;Variable de temporización
			Segundero_L	
			Segundero_H		
			Segundero			;Variables del contador de segundos
			Visu_Temp			;Variable temporal para visualización
		endc

MSE_Delay_V		equ	0x70		;Variables (3) empleadas por las macros de temporización

				org	0x00		;Vector de RESET	
				goto	Inicio
				org	0x04		;Vector de interrupción
				goto	Inter
				org	0x05

		include	"MSE_Delay.inc"			;Incluir rutinas de temporización

;**********************************************************************************
;Tabla: Esta rutina convierte el código binario presente en los 4 bits de menos peso
;del reg. W en su equivalente a 7 segmentos. Para ello el valor de W se suma al valor actual
;del PC. Se obtiene un desplazamiento que apunta al elemento deseado de la tabla.El código 7 
;segmentos retorna también en el reg. W.

Tabla:		addwf	PCL,F		;Desplazamiento sobre la tabla
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

;***********************************************************************************************
;Visu_Disp: Esta rutina realiza un barrido sobre los dos displays para visualizar sobre ellos
;el contenido de W. El display de las unidades se controla mediante RA2 y el de las decenas
;mediante RA3. Nominalmente cada display permanece activado 1mS, mostrando su correspondiente valor.

Visu_Disp	movwf	Visu_Temp	;Salva el valor a visualizar
			andlw	b'00001111'
			call	Tabla		;Convierte a 7 segmentos el valor de las unidades
			movwf	PORTB		;Salida a los segmentos
			bsf		PORTA,2		;Activa el display de las unidades
			Delay	1 Milis		;Temporiza 1mS 																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																							Delay	500 Milis	;Temporiza 1 mS (variando este valor se varía el efecto visual
			bcf		PORTA,2		;Desactiva display de la unidades
			movlw	b'11111111'
			movwf	PORTB		;Apaga los segmentos
			swapf	Visu_Temp,W	
			andlw	b'00001111'
			call	Tabla		;Convierte a 7 segmentos el valor de las decenas
			movwf	PORTB		;Salida a los segmentos
			bsf		PORTA,3		;Activa display de las decenas
			Delay	1 Milis		;Temporiza 1 mS
			bcf		PORTA,3		;Desactiva display de las decenas
			movlw	b'11111111'
			movwf	PORTB		;Apaga los segmentos
			return

;Programa de tratamiento de la interrupción que provoca el TMR2 cada 10mS. Incrementa en
;decimal la variable contadora de segundos
Inter		decfsz	Contador,F	;Ha pasado un segundo ??
			goto	No_es_1_seg	;No

;Incremento en decimal del segundero
			incf	Segundero_L,F	;Incrementa nible de menos peso del contador
			movlw	.10
			subwf	Segundero_L,W
			btfss	STATUS,Z		;Es  mayor de 9 ??
			goto	Ajuste			;No.Fusionar ambos nibles
			clrf	Segundero_L		;Si, puesta a 0 del nible de menos 
			incf	Segundero_H,F	;Incrementa nible de más peso del contador
			movlw	.10
			subwf	Segundero_H,W
			btfss	STATUS,Z		;Es mayor de 9 ??
			goto	Ajuste			;No.Fusionar ambos nibles		
			clrf	Segundero_H		;Si, puesta a 0 del nible de más peso
Ajuste		movf	Segundero_L,W
			andlw	b'00001111'
			movwf	Segundero	;Ajusta la parte de menos peso
			swapf	Segundero_H,W
			andlw	b'11110000'	;Ajusta la parte de más peso
			iorwf	Segundero,F	;Fusión de ambas partes			

			movlw	.100
			movwf	Contador	;Reinicia el contador de interrupciones

No_es_1_seg	bcf	PIR1,TMR2IF		;Repone el flag del TMR2
			retfie

;Programa principal
Inicio	   	clrf	PORTA		;Borra los latch de salida
			movlw	b'11111111'
			movwf	PORTB		;Apaga los segmentos
			bsf		STATUS,RP0
			bsf		STATUS,RP1	;Selecciona banco 3
			clrf	ANSEL		;Puerta A digital
			clrf	ANSELH		;Puerta B digital
			bcf		STATUS,RP1	;Selecciona banco 1
			movlw	b'11110011'		
			movwf	TRISA		;RA2 y RA3 se configuran como salida
			clrf	TRISB		;RB7:RB0 se configuran como salida
			movlw	.39
			movwf	PR2			;Carga registro de periodos con 39
			bsf		PIE1,TMR2IE	;Habilita interrupción del TMR2
			bcf		STATUS,RP0	;Selecciona banco 0	

;El TMR2 emplea un preescaler y un postcaler de 1:16 (total 1:256). Trabajando a una
;frecuencia de 4MHZ el TMR2 evoluciona cada 16uS (preescaler 1:16). La cuenta avanza hasta
;alcanzar el valor del registro de periodos (39), con lo que el tiempo transcurrido es de
;624 uS. Este lapsus se repite 16 veces (postcaler 1:16) antes de provocar la interrupción
;(al de 9984 uS).

			movlw	b'01111111'
			movwf	T2CON		;TMR2 On, preescaler/postcaler = 1:16
			clrf	TMR2		;Inicia el TMR2
			movlw	.100
			movwf	Contador	;Inicia variable de delay
			movlw	b'11000000'
			movwf	INTCON		;Habilita interrupciones

			clrf	Segundero
			clrf	Segundero_L
			clrf	Segundero_H	;Pone a 0 inicialmente el segundero
		
Loop		movf	Segundero,W
			call	Visu_Disp	;Visualiza e valor actual de segundero
			goto	Loop		;Bucle infinito		

			end					;Fin del programa fuente
