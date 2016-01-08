;						CURSO: "Microcontroladores PIC: Nivel I"
;									SEPTIEMBRE 2014
;							Autor: Mikel Etxebarria Isuskiza
;						Ingeniería de Microsistemas Programados S.L.
;							wwww.microcontroladores.com	
;
;								
;Ejemplo 8-4: La memoria EEPROM de datos.La máquina "SU TURNO"
;
;Se trata de emular el funcionamiento de las máquinas tipo "SU TURNO" habituales en múltiples
;comercios. Sobre el display se visualizará el número del turno actual. Este se icrementa a
;cada pulso aplicado por RA0. En la memoria EEPROM del PIC16F886 se almacena el último número
;visualizado, de forma que, ante un fallo de alimentación (p.e.), se reanude la cuenta en el
;último número.
;
;Cuando el sistema se emplea por 1ª vez, trás ensamblarlo, el contador en la EEPROM vale 0x00.

		List	p=16F886		;Tipo de procesador
		include	"P16F886.INC"	;Definiciones de registros internos
		#define Fosc 4000000	;Velocidad de trabajo

;Ajusta los valores de las palabras de configuración durante el ensamblado.Los bits no empleados
;adquieren el valor por defecto.Estos y otros valores se pueden modificar según las necesidades

		__config	_CONFIG1, _LVP_OFF&_PWRTE_ON&_WDT_OFF&_EC_OSC&_FCMEN_OFF&_BOR_OFF	;Palabra 1 de configuración
		__config	_CONFIG2, _WRT_OFF&_BOR40V									;Palabra 2 de configuración
		
				org	0x2100  
				de	0x01				;Esta directiva graba el valor 0x01 en la 1ª posición de
										;la EEPROM trás el ensamblado. 

Visu_Temp  		equ	0x20				;Variable temporal para visualización
Contador		equ	0x21				;Variable del contador
Contador_L		equ	0x22				;Nible de menos peso de contador
Contador_H		equ	0x23				;Nible de más peso del contador
MSE_Delay_V		equ	0x73				;Variables (3) empleadas por las macros de temporización

				org	0x00	
				goto	Inicio
				org	0x05

		include	"MSE_Delay.inc"			;Incluir rutinas de temporización

;****************************************************************************************
;EE_Write: Graba un byte en la EEPROM de datos. La dirección será la contenida en EEADR y
;el dato se le supone previamente metido en EEDAT

EE_Write      	bsf    	STATUS,RP0
				bsf		STATUS,RP1		;Selecciona banco 3
				bcf		EECON1,EEPGD	;Acceso a EEPROM de datos
				bsf    	EECON1,WREN		;Permiso de escritura
               	movlw  	b'01010101'
               	movwf  	EECON2
               	movlw  	b'10101010'
               	movwf  	EECON2			;Secuencia establecida por Microchip
               	bsf    	EECON1,WR		;Orden de escritura
Wait           	btfsc  	EECON1,WR		;Testear flag de fin de escritura
               	goto   	Wait
				bcf    	EECON1,WREN		;Desconecta permiso de escritura             
				bcf    	PIR2,EEIF		;Reponer flag de fin de escritura
               	bcf    	STATUS,RP0
               	bcf		STATUS,RP1		;Selecciona banco 0
				return

;**************************************************************************************
;EE_Read: Leer un byte de la EEPROM. Se supone al registro EEADR cargado con la direc-
;ción a leer. En EEDAT aparecerá el dato leído.

EE_Read        	bsf     STATUS,RP0	
				bsf		STATUS,RP1		;Selección de banco 3
               	bcf		EECON1,EEPGD	;Selecciona EEPROM de datos
				bsf    	EECON1,RD		;Orden de lectura
               	bcf    	STATUS,RP0	
				bcf		STATUS,RP0		;Selección de banco 0
                return

;**********************************************************************************
;Tabla: Esta rutina convierte el código binario presente en los 4 bits de menos peso
;del reg. W en su equivalente a 7 segmentos. Para ello el valor de W se suma al valor actual
;del PC. Se obtiene un desplazamiento que apunta al elemento deseado de la tabla.El código 7 
;segmentos retorna también en el reg. W.

Tabla:			addwf	PCL,F			;Desplazamiento sobre la tabla
				retlw	b'11000000'		;Dígito 0
				retlw	b'11111001'		;Dígito 1
				retlw	b'10100100'		;Dígito 2
				retlw	b'10110000'		;Dígito 3
				retlw	b'10011001'		;Dígito 4
				retlw	b'10010010'		;Dígito 5
				retlw	b'10000010'		;Dígito 6
				retlw	b'11111000'		;Dígito 7
				retlw	b'10000000'		;Dígito 8
				retlw	b'10011000'		;Dígito 9
				retlw	b'10001000'		;Dígito A
				retlw	b'10000011'		;Dígito B
				retlw	b'11000110'		;Dígito C
				retlw	b'10100001'		;Dígito D
				retlw	b'10000110'		;Dígito E
				retlw	b'10001110'		;Dígito F

;***********************************************************************************************
;Visu_Disp: Esta rutina realiza un barrido sobre los dos displays para visualizar sobre ellos
;el contenido de W. El display de las unidades se controla mediante RA2 y el de las decenas
;mediante RA3. Nominalmente cada display permanece activado 1mS, mostrando su correspondiente valor.

Visu_Disp		movwf	Visu_Temp		;Salva el valor a visualizar
				andlw	b'00001111'
				call	Tabla			;Convierte a 7 segmentos el valor de las unidades
				movwf	PORTB			;Salida a los segmentos
				bsf		PORTA,2			;Activa el display de las unidades
				Delay	1 Milis			;Temporiza 1mS 																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																							Delay	500 Milis	;Temporiza 1 mS (variando este valor se varía el efecto visual
				bcf		PORTA,2			;Desactiva display de la unidades
				movlw	b'11111111'
				movwf	PORTB			;Apaga los segmentos
				swapf	Visu_Temp,W	
				andlw	b'00001111'
				call	Tabla			;Convierte a 7 segmentos el valor de las decenas
				movwf	PORTB			;Salida a los segmentos
				bsf		PORTA,3			;Activa display de las decenas
				Delay	1 Milis			;Temporiza 1 mS
				bcf		PORTA,3			;Desactiva display de las decenas
				movlw	b'11111111'
				movwf	PORTB			;Apaga los segmentos
				return

;Programa principal
Inicio	       	clrf	PORTA			;Borra los latch de salida
				movlw	b'11111111'
				movwf	PORTB			;Apaga los segmentos
				bsf		STATUS,RP0
				bsf		STATUS,RP1		;Selecciona banco 3
				clrf	ANSEL			;Puerta A digital
				clrf	ANSELH			;Puerta B digital
				bcf		STATUS,RP1		;Selecciona banco 1
				clrf	TRISB			;RB7:RB0 se configuran como salida
				movlw	b'11110011'		
				movwf	TRISA			;RA2 y RA3 se configuran como salida
				bcf		STATUS,RP0		;Selecciona banco 0				                                                                         					
				bsf		STATUS,RP1		;Selecciona banco 2

;Lee el primer byte de la memoria EEPROM que contiene el turno actual. Este sera 01 si se emplea por
;vez primera tras el ensamblado, o bien si el contador desborda y pasa de 99 a 00 y a 01

				clrf	EEADR			;Selecciona dirección 00 de EEPROM				
				call	EE_Read			;Lee byte de la EEPROM
				bsf		STATUS,RP1		;Banco 2
				movf	EEDAT,W			;Lee el valor actual del turno
				bcf		STATUS,RP1		;Banco 0
				movwf	Contador		
				andlw	b'00001111'
				movwf	Contador_L
				swapf	Contador,W
				andlw	b'00001111'
				movwf	Contador_H		;Iniciar contador con el valor actual del turno

Loop			movf	Contador,W
				call	Visu_Disp		;Visualiza el contador sobre el display		
				btfsc	PORTA,0			;RA0 está a "0" ??
				goto	Loop			;No, esperar
				Delay	5 Milis			;Eliminar rebotes

Wait_1			movf	Contador,W
				call	Visu_Disp		;Visualiza el contador sobre el display	
				btfss	PORTA,0			;RA0 está a "1" ??
				goto	Wait_1			;No, esperar
				Delay	5 Milis			;Eliminar rebotes. Ha habido un pulso

;Incremento en decimal del contador. Incrementa el nible de más peso hasta llegar a 9 por
;cada vez que el nible de menos peso pase de 9 a 0. Evoluciona por tanto desde 00 a 99

				incf	Contador_L,F	;Incrementa nible de menos peso del contador
				movlw	.10
				subwf	Contador_L,W
				btfss	STATUS,Z		;Es  mayor de 9 ??
				goto	Ajuste			;No.Fusionar ambos nibles
				clrf	Contador_L		;Si, puesta a 0 del nible de menos 
				incf	Contador_H,F	;Incrementa nible de más peso del contador
				movlw	.10
				subwf	Contador_H,W
				btfss	STATUS,Z		;Es mayor de 9 ??
				goto	Ajuste			;No.Fusionar ambos nibles		
				clrf	Contador_H		;Si, puesta a 0 del nible de más peso

;Fusiona ambos nibles para formar la variable contador que varía de 00 a 99
Ajuste			movf	Contador_L,W
				andlw	b'00001111'
				movwf	Contador		;Ajusta la parte de menos peso
				swapf	Contador_H,W
				andlw	b'11110000'		;Ajusta la parte de más peso
				iorwf	Contador,F		;Fusión de ambas partes
				movf	Contador,W

;El valor final del contador se almacena como nº Su Turno enla EEPROM
				bsf		STATUS,RP1		;Banco 2
				movwf	EEDAT			;Valor del contador a grabar en la EEPROM
				clrf	EEADR			;Dirección 0x00 de la EEPROM
				call	EE_Write		;Graba el nuevo valor del contador en la EEPROM
				goto	Loop

				end						;Fin del programa fuente

