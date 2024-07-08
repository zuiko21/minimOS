/* nanoBoot server for Raspberry Pi!   *
 * (c) 2020-2024 Carlos J. Santisteban *
 * last modified 20240708-2359         */

/* gcc server.c -lwiringPi -o nanoBootServer */

#include <stdio.h>
#include <stdlib.h>
#include <wiringPi.h>
#include <unistd.h>

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
int main(int argc, char *argv[]) {
	FILE*	f;
	word	ini, exe, hi, hx;
	byte	c, bb, tipo;
	int		fin, i, arg;
	float	speed	= 1.0;	/* NEW speed factor */
	char*	nombre;			/* now as argument */
	byte	buffer[256];
	char*	a_str	= NULL;	/* parameter parsing */
	char*	x_str	= NULL;
	char*	s_str	= NULL;
	int		index, arg_index;

/* parse arguments *** TBD *** */
	while ((arg = getopt(argc, argv, "a:x:s:")) != -1) {
		switch (arg) {
			case 'a':
				a_str = optarg;
				break;
			case 'x':
				x_str = optarg;
				break;
			case 's':
				s_str = optarg;
				break;
			case '?':
				printf("Unknown option '-%c'\n", optopt);
				printf("Usage: %s file [-a load_address] [-x execution_address] [-s speed]\n", argv[0]);
				return -1;
			default:
				abort();
		}
	}
	arg_index = 0;
	index = optind;
	while (index < argc) {
		switch (arg_index++) {
			case 0:
				nombre = argv[index++];
				break;
		}
	}
	if (!arg_index) {
		printf("Filename is mandatory\n");
		return -2;
	}
printf("before...\n");
//*	if (a_str != NULL && (strlen(a_str) != 6 || a_str[0]!='0' || a_str[1]!='x')) {
	if (a_str != NULL)
		if (a_str[0]!='0' || a_str[1]!='x') {
			printf("Load address format: 0x0000\n");
			return -3;
		}
printf("...and after\n");
	if (x_str != NULL)
		if (x_str[0]!='0' || x_str[1]!='x') {
			printf("Execution address format: 0x0000\n");
			return -3;
		}
	if (s_str != NULL) {
		speed = strtof(s_str, NULL);
		if (!speed) {
			printf("Speed must be a float in MHz\n");
			return -3;
		}
	}

/* data transmission */
	printf("*** nanoBoot server (OC) ***\n\n");
	printf("pin 34=GND, 36=CLK, 38=DAT\n\n");
/* GPIO setup */
	wiringPiSetupGpio();	/* using BCM numbering! */
	digitalWrite(CB1, 0);	/* clock initially disabled, note OC */
	pinMode(CB1, OUTPUT);
	pinMode(CB2, OUTPUT);
	pinMode(STB, OUTPUT);	/* not actually used */
/* open source file */
	if ((f = fopen(nombre, "rb")) == NULL) {
		printf("*** NO SUCH FILE ***\n");
		return -4;
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
	ini = (word)strtol(a_str, NULL, 0);	/* get load address, or default */
	if (!ini) {
		if (bb) {
			exe = (word)strtol(x_str, NULL, 0);		/* get execution address from argument */
			if (exe)	tipo = 0x4B;		/* binary code blob (legacy) */
			else {
				printf("*** Execution address is needed! ***\n");
				fclose(f);
				return -5;
			}
		}
	} else {
		if (tipo != 0x4D)	printf("\n(will be sent as raw data, no longer executable)");
		tipo = 0x4D;		/* generic data */
	}
	if (ini && exe) {
		printf("*** Set either Load OR Execution address ***\n");
		fclose(f);
		return -6;
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
