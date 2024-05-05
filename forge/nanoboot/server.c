/* nanoBoot server for Raspberry Pi!   *
 * (c) 2020-2024 Carlos J. Santisteban *
 * last modified 20240505-1358         */

#include <stdio.h>
#include <stdlib.h>
#include <wiringPi.h>
/* *** needs -lwiringPi option *** */

/* pin definitions, 36-38-40 at header, BCM 16-20-21 */
/* CB1 is clock, CB2 data, can use pin 34 as GND */
/* THIS VERSION NEEDS OPEN COLLECTOR (INVERTING) DRIVERS */
/* STB pin isn't currently used, just a placeholder for SS22 */
#define	CB1		16
#define	CB2		20
#define	STB		21

/* type definitions */
typedef	u_int8_t	byte;
typedef u_int16_t	word;

/* prototypes */
void cabe(byte x);	/* send header byte in a slow way */
void dato(byte x);	/* send data byte at full speed! */
void useg(int x);	/* delay for specified microseconds */

/* *** main code *** */
int main(void) {
	FILE*	f;
	word	ini, exe, hi, hx;
	byte	c, bb, tipo;
	int		fin, i;
	char	nombre[80];
	byte	buffer[256];

	printf("*** nanoBoot server (OC) ***\n\n");
	printf("pin 34=GND, 36=CLK, 38=DAT\n\n");
/* GPIO setup */
	wiringPiSetupGpio();	/* using BCM numbering! */
	digitalWrite(CB1, 0);	/* clock initially disabled, note OC */
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
	printf("It's %d bytes long ($%04X) ", fin, fin);
/* check file header as well */
	rewind(f);
	fread(buffer, 256, 1, f);
	if (!buffer[0] && !buffer[255] && (buffer[7]==13)) {	/* valid header */
		printf("and has valid header!\n");
		bb = 0;							/* NOT a binary blob */
		hi = *(word*)(&buffer[3]);		/* load address stored into file header */
		hx = *(word*)(&buffer[5]);		/* execution address stored into file header */
		if (buffer[2]=='X') {
			if (buffer[1]=='d') {
				tipo = 0x4C;			/* ROM image */
				printf("ROM image starting at %04X", 0x10000-fin);
			}
			if (buffer[1]=='p') {
				tipo = 0x4E;			/* Pocket executable */
				printf("Pocket executable: Load at %04X, Execute at %04X", hi, hx);
			}
		} else {
			tipo = 0x4D;				/* unrecognised header */
			printf("(Generic, non-executable type)");
		}
	} else		bb = 1;					/* binary blob might be executed from start */
/* determine type */
	printf("\n\nNon-executable Load Address in HEX (0=default): ");
	scanf("%x", &ini);
	if (!ini) {
		if (bb) {
			printf("Execution Address in HEX (0=default): ");
			scanf("%x", &exe);
			if (exe)	tipo = 0x4B;		/* binary code blob (legacy) */
			else {
				printf("*** Execution address is needed! ***\n");
				fclose(f);
				return -1;
			}
		}
	} else {
		if (tipo != 0x4D)	printf("\n(will be sent as raw data, no longer executable)");
		tipo = 0x4D;		/* generic data */
	}
	if (ini && exe) {
		printf("*** Set either Load OR Execution address ***\n");
		fclose(f);
		return -1;
	}
	switch(tipo) {
		case 0x4B:
			ini = exe;		/* blobs start at load address */
			break;
		case 0x4C:
			ini = 0x10000-fin;			/* load address depends on ROM length */
			break;
		case 0x4E:
			ini = hi;		/* Pocket loads at pointer inside file header */
			break;
	}
	fin += ini;				/* nanoBoot mandatory format */
/* send header */
	cabe(tipo);
	cabe((fin>>8)&255);		/* ROM images 'end' at $0000 */
	cabe(fin&255);
	cabe(ini>>8);
	cabe(ini&255);
/* send binary */
	rewind(f);
	printf("\n*** GO!!! ***\n");
	for (i=ini; i<fin; i++) {
		if ((i&255) == 0) {
			delay(2);		/* page crossing may need some time */
			printf("$%02X...\n", i>>8);
		}
		c = fgetc(f);
		if (i>>8 != 0xDF)	dato(c);
	}
	printf("\nEnded at $%04X\n", fin);
	fclose(f);

	return 0;
}

/* *** function definitions *** */
/* for old nanoBoot ROM, invert bit (bit^1) */
void cabe(byte x) {			/* just like dato() but with longer bit delay, whole header takes ~85 ms */
	byte bit, i = 8;

	while(i>0) {
		bit = x & 1;
		digitalWrite(CB2, bit);		/* send bit for OC *** ^1 is NO LONGER needed *** */
		digitalWrite(CB1, 1);
		useg(15);			/* eeeeeek */
		digitalWrite(CB1, 0);
		delay(2);			/* way too long, just in case, note OC */
/* delay is best here in any case */
		x >>= 1;
		i--;
	}
	delay(1);				/* shouldn't be needed, but won't harm anyway */
}

void dato(byte x) {			/* send a byte at 'top' speed */
	byte bit, i = 8;

	while(i>0) {
		bit = x & 1;
		digitalWrite(CB2, bit);		/* note OC *** ^1 is NO LONGER needed *** */
		digitalWrite(CB1, 1);
		useg(15);			/* eeeeeeek */
		digitalWrite(CB1, 0);
		useg(65);			/* *** cranked up to 55 µs or so (at 1 MHz) is pretty unreliable *** */
/* delay is best here in any case */
		x >>= 1;
		i--;
	}
	digitalWrite(CB2, 0);	/* let data line float high, note OC */
	useg(125);				/* *** perhaps 200 µs or so *** */
}

void useg(int x){
	int i, t;

	for (t=0; t<x; t++){
		for (i=0; i<200; i++);	/* *** 200 iterations = 1 µs on RPi400 *** */
	}
}
