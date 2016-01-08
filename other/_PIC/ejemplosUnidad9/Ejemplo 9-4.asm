;						CURSO: "Microcontroladores PIC: Nivel I"
;									SEPTIEMBRE 2014
;							Autor: Mikel Etxebarria Isuskiza
;						Ingeniería de Microsistemas Programados S.L.
;							wwww.microcontroladores.com	
;
;								
;Ejemplo 9-4: Temporizador e interrupción con el Timer 1
;
;Se desea realizar un contador binario visualizado sobre la Puerta B, que se vaya incremen-
;tando a razón de una unidad cada 0.1 segundos. Para ello contamos con la ayuda de la
;interrupción provocada por el TMR1
		
		List	p=16F886			;Tipo de procesador
		include	"P16F886.INC"		;Definiciones de registros intern+os

;Ajusta los valores de las palabras de configuración durante el ensamblado.Los bits no empleados
;adquieren el valor por defecto.Estos y otros valores se pueden modificar según las necesidades

		__config	_CONFIG1, _LVP_OFF&_PWRTE_ON&_WDT_OFF&_EC_OSC&_FCMEN_OFF&_BOR_OFF	;Palabra 1 de configuración
		__config	_CONFIG2, _WRT_OFF&_BOR40V									;Palabra 2 de configuración

			org	0x00				;Vector de RESET	
			goto	Inicio
			org	0x04
			goto	Inter			;Vector de interrupción

;Programa de tratamiento de interrupción

Inter		movlw	low ~.12500
			movwf	TMR1L			;Carga la parte de menos peso de 12500 en TMR1L
			movlw	high ~.12500
			movwf	TMR1H			;Carga la parte de más peso. Repone el TMR1 con el valor 12500.
			bcf		PIR1,TMR1IF		;Repone el flag del TMR1
			incf	PORTB,F			;Incrementa el contador de la Puerta B
			retfie

;Programa principal
Inicio		clrf 	PORTB			;Borra los latch de salida. El contador parte de 0
			bsf		STATUS,RP0
			bsf		STATUS,RP1		;Banco 3
			clrf	ANSEL			;Puerta A digital
			clrf	ANSELH			;Puerta B digital
			bcf		STATUS,RP1		;Banco 1
			clrf	TRISB			;Puerta B se configura como salida
			bsf		PIE1,TMR1IE		;habilita interrupción del TMR1
			bcf		STATUS,RP0		;Selecciona banco 0

;El TMR1 trabaja con oscilador interno y un preescaler de 1:8. Si se trabaja a una frecuencia
;de 4 MHz, el TMR1 deberá ser cargado con 12500 para que provoque interrupción al de 0.1s
;(12500 * 8 * 1 =100000uS=0.1")

			movlw	low ~.12500
			movwf	TMR1L
			movlw	high ~.12500
			movwf	TMR1H			;Carga el TMR1 con el valor 12500.
			movlw	b'00110001'		;Selecciona reloj interno y preescaler de 8
			movwf	T1CON			;Habilita el TMR1
			movlw	b'11000000'
			movwf	INTCON			;Habilitación global de interrupciones

Loop		nop
			goto	Loop			;Bucle infinito		

			end						;Fin del programa fuente
