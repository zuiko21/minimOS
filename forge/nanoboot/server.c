/* nanoBoot server for Raspberry Pi!   *
 * (c) 2020-2021 Carlos J. Santisteban *
 * last modified 20210112-1758         */

#include <stdio.h>
#include <stdlib.h>
#include <wiringPi.h>
/* *** needs -lwiringPi option *** */

/* pin definitions, 36-38-40 at header, BCM 16-20-21 */
/* STB pin isn't currently used, just a placeholder for SS22 */
#define	CB1		27
#define	CB2		28
#define	STB		29

/* prototypes */
void cabe(int x);	/* send header byte in a slow way */
void dato(int x);	/* send data byte at full speed! */
void useg(int x);	/* delay for specified microseconds */

/* *** main code *** */
int main(void) {
	FILE*	f;
	int		i, c, fin, ini;
	char	nombre[80];

/* GPIO setup */
	wiringPiSetup();
	digitalWrite(CB1, 1);	/* clock initially disabled */
	pinMode(CB1, OUTPUT);
	pinMode(CB2, OUTPUT);
	pinMode(STB, OUTPUT);	/* not actually used */
/* open source file */
	printf("File: ");
	scanf("%s", nombre);
	if ((f = fopen(nombre, "rb")) == NULL) {
		printf("*** NO SUCH FILE ***\n");
		return -1;
	}
/* compute header parameters */
	fseek(f, 0, SEEK_END);
	fin = ftell(f);
	printf("It's %d bytes long ($%04X)\n\n", fin, fin);
	printf("Address (HEX): ");
	scanf("%x", &ini);
	fin += ini;				/* nanoBoot mandatory format */
/* send header */
	cabe(0x4B);
	cabe(fin>>8);
	cabe(fin&255);
	cabe(ini>>8);
	cabe(ini&255);
/* send binary */
	rewind(f);
	printf("*** GO!!! ***\n");
	for (i=ini; i<fin; i++) {
		if ((i&255) == 0) {
			delay(2);		/* page crossing may need some time */
			printf("$%02X...\n", i>>8);
		}
		c = fgetc(f);
		dato(c);
	}
	printf("\nEnded at $%04X\n", fin);
	fclose(f);
	
	return 0;
}

/* *** function definitions *** */
void cabe(int x) {			/* just like dato() but with longer bit delay, whole header takes ~85 ms */
	int bit, i = 8;
	
	while(i>0) {
		bit = x & 1;
		digitalWrite(CB2, bit);
		digitalWrite(CB1, 0);
		delay(2);			/* way too long, just in case */
		digitalWrite(CB1, 1);
/* in case the NMI is not edge-triggered as in the 6502, you should put the delay here */
		x >>= 1;
		i--;
	}
	delay(1);				/* shouldn't be needed, but won't harm anyway */
}

void dato(int x) {			/* send a byte at 'top' speed */
	int bit, i = 8;
	
	while(i>0) {
		bit = x & 1;
		digitalWrite(CB2, bit);
		digitalWrite(CB1, 0);
		useg(75);			/* *** 75 µs or so (at 1 MHz) *** */
		digitalWrite(CB1, 1);
/* in case the NMI is not edge-triggered as in the 6502, you should put the delay here */
		x >>= 1;
		i--;
	}
	useg(200);				/* *** perhaps 200 µs or so *** */
}

void useg(int x){
	int i, t;
	
	for (t=0; t<x; t++){
		for (i=0; i<200; i++);	/* *** 200 iterations = 1 µs on RPi400 *** */
	}
}
