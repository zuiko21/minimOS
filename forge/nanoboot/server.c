/* nanoBoot server for Raspberry Pi! *
 * (c) 2020 Carlos J. Santisteban    *
 * last modified 20201227-1719       */

#include <stdio.h>
#include <stdlib.h>
//#include <wiringPi.h>

/* prototipos */
void dato(int x);

/* *** programa principal *** */
int main(void) {
	FILE*	f;
	int		i, c, fin, ini;
	char	nombre[80];

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
		// poner bit y pulsar reloj
		printf("%d", bit);//placeholder
		x >>= 1;
		i--;
	}
//	delay(1);
	printf(" ");//placeholder
}
