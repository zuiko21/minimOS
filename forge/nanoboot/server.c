/* nanoBoot server for Raspberry Pi! *
 * (c) 2020 Carlos J. Santisteban    *
 * last modified 20201227-1820       */

#include <stdio.h>
#include <stdlib.h>
#include <wiringPi.h>

/* definición de pines, 36-38-40 en el conector, BCM 16-20-21 */
#define	CB1		27
#define	CB2		28
#define	STB		29

/* prototipos */
void dato(int x);

/* *** programa principal *** */
int main(void) {
	FILE*	f;
	int		i, c, fin, ini;
	char	nombre[80];

/* preparar GPIO */
	wiringPiSetup();
	digitalWrite(CB1, 1);
	pinMode(CB1, OUTPUT);
	pinMode(CB2, OUTPUT);
	pinMode(STB, OUTPUT);
/* abrir archivo original */
	printf("Archivo: ");
	scanf("%s", nombre);
	if ((f = fopen(nombre, "rb")) == NULL) {
		printf("*** NO EXISTE EL ARCHIVO ***\n");
		return -1;
	}
/* preparar parámetros de cabecera */
	printf("Dirección (en decimal): ");
	scanf("%d", &ini);
	fseek(f, 0, SEEK_END);
	fin = ini + ftell(f);
	printf("Son %d bytes...\n\n", fin-ini);
/* generar cabecera */
	dato(0x4B);
	dato(fin>>8);
	dato(fin&255);
	dato(ini>>8);
	dato(ini&255);
/* enviar archivo binario */
	rewind(f);
	printf("¡¡¡TOMA!!! ¡Todo pa´dentro, maricón!\n");
	for (i=ini; i<fin; i++) {
		if (i&255 == 0)		delay(1);
		c = fgetc(f);
		dato(c);
	}
	printf("Acaba en %d\n", fin);
	fclose(f);
	
	return 0;
}

/* *** definición de funciones *** */
void dato(int x) {
	int bit, i = 8;
	
	while(i>0) {
		bit = x & 1;
		digitalWrite(CB2, bit);
		digitalWrite(CB1, 0);
		digitalWrite(CB1, 1);
//		printf("%d", bit);//placeholder
		x >>= 1;
		i--;
	}
	delay(1);
//	printf(" ");//placeholder
}
