;							LCD4bitsPIC16.inc
;						Autor: Mikel Etxebarria
;			(c) Ingeniería de Microsistemas Programados S.L.
;						www.microcontroladores.com
;								Bilbao 2010
;
;Este conjunto de rutinas diseñadas para PIC16 que permiten realizar las tareas 
;básicas de control del módulo de visualización LCD, mediante un interface de 4 bits. 
;Este fichero se debe incluir en los futuros programas fuente mediante la directiva INCLUDE
;
;Las rutinas están adaptadas a las velocidades más lentas de algunos módulos LCD, en las cuales 
;el tiempo de activación (Tc) entre una señal ENABLE y la siguiente es de unos 4 uS. La 
;velocidad de trabajo se supone de 4MHz. 

;UP_LCD: 		Configuración PIC para el LCD.
;
;LCD_INI: 		Rutina de visualización según Wintek. El LCD queda activado, borrado
;				y en la 1ª posición del cursor
;
;LCD_DATO: 		Escritura de datos en DDRAM o CGRAM. Envía el dato presente en el W
;
;LCD_REG: 		Escritura de comandos en el LCD. Envía el comando presente en el W
;

;Se supone un interface de 4 bits. RB0-RB3 es la puerta de datos. RA1-RA3 son las señales de control. 
;Estas conexiones se pueden modificar según se necesite

#define ENABLE       	bsf PORTA,1     ;Activa señal E (RA1)
#define DISABLE      	bcf PORTA,1     ;Desactiva señal E (RA1)
#define LEER         	bsf PORTA,2     ;Pone LCD en Modo RD (RA2)
#define ESCRIBIR     	bcf PORTA,2     ;Pone LCD en Modo WR (RA2)
#define LCD_COMANDO  	bcf PORTA,3     ;Desactiva RS (modo comando)(RA3)
#define LCD_DATOS   	bsf PORTA,3   	;Activa RS (modo dato)(RA3)
#define LCD_C_PORT		PORTA			;Puerta de control del LCD (RA1-RA3)
#define	LCD_C_TRIS		TRISA			;Control de la puerta de control del LCD
#define LCD_PORT		PORTB			;Puerta de datos del LCD (RB0-RB3)
#define LCD_TRIS		TRISB			;Control de la puerta de datos del LCD

;Variables empleadas por las rutinas de control del LCD		
						CBLOCK	Lcd_var	;Inicio de las variables. Será la primera						
							Lcd_Temp_1	;direccón libre disponible
							Lcd_Temp_2
							Lcd_Temp_3
						ENDC											

;*************************************************************************
;UP_LCD: Configuración PIC para el LCD.
;
UP_LCD          LCD_COMANDO             ;RS=0
                DISABLE                 ;E=0
                ESCRIBIR				;R/W=0
				bsf		STATUS,RP0		;Banco 1
				movf	LCD_C_TRIS,W
				andlw	b'11110001'
				movwf	LCD_C_TRIS		;Puerta de control del LCD como salida
				movf	LCD_TRIS,W
				andlw	0xF0
				movwf   LCD_TRIS        ;Puerta de datos del LCD como salidas
				bcf		STATUS,RP0		;Banco 0
				return

;**************************************************************************
;LCD_BUSY: Lectura del Flag Busy y de la dirección. No retorna hasta que busy sea "0"
;
LCD_BUSY	clrwdt
			bsf		STATUS,RP0		;Banco 1
           	movf	LCD_TRIS,W
			andlw	0xf0
			iorlw	0x0f
			movwf	LCD_TRIS        ;Puerta de interface como entradas
			bcf		STATUS,RP0		;Banco 0
            LCD_COMANDO				;Modo dato
			LEER                    ;Pone el LCD en Modo RD
LCD_BUSY_1	nop
			ENABLE                  ;Activa el LCD
           	swapf	LCD_PORT,W
			andlw	b'11110000'
			movwf	Lcd_Temp_3		;Lee y salva los 4 bits de mas peso
			DISABLE
			nop
			ENABLE					;Activa el LCD
			nop
			movf	LCD_PORT,W
			andlw	b'00001111'
			iorwf	Lcd_Temp_3,F	;Lee y salva los 4 bits de menos peso
			nop
			DISABLE
			btfsc	Lcd_Temp_3,7	;Busy activado ??
			goto	LCD_BUSY_1		;Si, volver a leer
			ESCRIBIR				;Modo escritura
			bsf		STATUS,RP0		;Banco 1
          	movf	LCD_TRIS,W
			andlw	0xf0	
			movwf   LCD_TRIS        ;Puerta de interface como salida
			bcf		STATUS,RP0		;Banco 0
			return
		
;**************************************************************************
;LCD_E: Pulso de Enable. En algunos LCD's esta señal debe estar a "0" un tiempo mínimo 
;antes de volver a ponerse a "1". Se puede variar el valor de temporización en función
;del tipo de LCD.
;
LCD_E           ENABLE              ;Activa E
				nop
				nop
				DISABLE             ;Desactiva E
				nop
				nop
				return

;**************************************************************************
;LCD_DATO: Escritura de datos en DDRAM o CGRAM. Envía el dato presente en el W
;
LCD_DATO		movwf	Lcd_Temp_2	;Salva el dato a visualizar
				call	LCD_BUSY	;Espera que el LCD esté libre
				movlw	0xf0
				andwf	LCD_PORT,F
				swapf	Lcd_Temp_2,W
				andlw	0x0F
				iorwf	LCD_PORT,F	;Salida de los 4 bits de mas peso
				ESCRIBIR			;Modo escritura
				LCD_DATOS			;Modo datos
				call	LCD_E		;Genera pulso de Enable
				movlw	0xf0
				andwf	LCD_PORT,F
				movf 	Lcd_Temp_2,W
				andlw	0x0f
				iorwf	LCD_PORT,F	;Salida de los 4 bits de menos peso
				call	LCD_E		;Genera pulso de Enable
				return
                
;**************************************************************************
;LCD_REG: Escritura de comandos en el LCD. Envía el comando presente en el W

LCD_REG         movwf	Lcd_Temp_2	;Salva el dato a visualizar
				call	LCD_BUSY	;Espera que el LCD esté libre
				movlw	0xf0
				andwf	LCD_PORT,F
				swapf	Lcd_Temp_2,W
				andlw	0x0f
				iorwf	LCD_PORT,F	;Salida de los 4 bits de mas peso
				ESCRIBIR			;Modo escritura
				LCD_COMANDO			;Modo comandos
				call	LCD_E		;Genera pulso de Enable
				movlw	0xf0
				andwf	LCD_PORT,F
				movf	Lcd_Temp_2,W	
				andlw	0x0f
				iorwf	LCD_PORT,F	;Salida de los 4 bits de menos peso
				call	LCD_E		;Genera pulso de Enable
				return

;***************************************************************************
;LCD_INI: Rutina de visualización según Wintek. El LCD queda activado, borrado
;y en la 1ª posición del cursor

LCD_INI			movlw	.75
				movwf	Lcd_Temp_1
				call	LCD_DELAY	;Temporización de unos 15mS tras el Power-On
				DISABLE
				ESCRIBIR
				LCD_COMANDO			;Modo comando y escritura
				movlw	0xf0
				andwf	LCD_PORT,F
				movlw	0x03
				iorwf	LCD_PORT,F	;Comando FUNCTION SET sin chequeo de busy
				call	LCD_E		;Genera pulso de Enable
				movlw	.25
				movwf	Lcd_Temp_1
				call	LCD_DELAY	;Temporiza unos 5mS
				movlw	0xf0
				andwf	LCD_PORT,F
				movlw	0x03		
				iorwf	LCD_PORT,F	;Comando FUNCTION SET sin chequeo de busy
				call	LCD_E		;Genera pulso de Enable
				movlw	.5
				movwf	Lcd_Temp_1
				call	LCD_DELAY	;Temporiza unos 1 ms
				movlw	0xf0
				andwf	LCD_PORT,F
				movlw	0x02
				iorwf	LCD_PORT,F	;Comando FUNCTION SET a 4 bits sin chequeo de busy
				call	LCD_E		;Genera pulso de Enable
				movlw	b'00101000'	
				call	LCD_REG		;Comando FUNCTION SET con chequeo de busy
				movlw	b'00001000'
				call	LCD_REG		;Display Off
				movlw	b'00000001'
				call	LCD_REG		;Comando HOME
				movlw	b'00001100'
				call	LCD_REG		;Comando Diaplay ON
				return	

;*****************************************************************************
;LCD_DELAY: Rutina de temporización de unos 200 uS a 4MHz que se repite tantas veces
;como indica la variable Lcd_Temp_1. Se emplean las variables Lcd_Temp_1
;y LCD_Temp_2 en lugar del TMR0. Este queda libre para las aplicaciones del usuario

LCD_DELAY:		movlw	.50
				movwf	Lcd_Temp_2
LCD_DELAY_1:	clrwdt
				decfsz	Lcd_Temp_2,F
				goto	LCD_DELAY_1
				decfsz	Lcd_Temp_1,F	;Bucle de 4uS que se repite 50 veces (200us)
				goto	LCD_DELAY		;El bucle de 200uS se repite Lcd_Temp_1 veces
				return
            
