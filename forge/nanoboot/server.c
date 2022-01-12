/* nanoBoot server for Raspberry Pi!   *
 * (c) 2020-2022 Carlos J. Santisteban *
 * last modified 20220112-1255         */

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

/* Global variables */
int		periodo;	/* needed iterations for 1 uS delay, nominally 200 on RPi 400 */

/* prototypes */
void cabe(int x);	/* send header byte in a slow way */
void dato(int x);	/* send data byte at full speed! */
void useg(int x);	/* delay for specified microseconds (at 1 MHz) or t-states*/
void err(void);		/* show usage in case of parameter error */

/* *** main code *** */
/* NEW usage is server (file) (address) [[mode]speed] */
/* where mode is + (safe, default) or - (fast NMI)    */
/* address in dec or hex (0x style, not $)            */
/* speed in MHz, default 1 MHz, safe NMI mode         */
int main(int argc, char *argv[]) {
	FILE*	f;
	int		i, c, fin, ini;
	char	nombre[80];
	float	vel = 1.0;		/* NEW speed in MHz, keep these default values */
	int		seg = 1;		/* NEW, set to 0 if not in SAFE mode (minimal NMI handler latency) */
	int		dats;			/* space between bits, nominally 65t with fast NMI */
	int		cabs;			/* space between header bits, nominally ~2000t */

/* check command syntax */
	if (argc<3) {
		printf("\nUSAGE: %s file address [[-]speed]\n", argv[0]);
		printf("address in decimal or hex (Intel '0x' syntax)\n");
		printf("default speed in MHz is 1, safe NMI handler (<215t/bit)\n");
		printf("NEGATIVE speed for FAST NMI handler (<65t/bit total)\n\n");
		return -1;
	}
	printf("*** nanoBoot server (OC) ***\n");
	printf("pin 34=GND, 36=CLK, 38=DAT\n\n");
/* set new speed parameters (non interactive), otherwise take 1 MHz slow NMI */
	if (argc>=4) {			/* enough parameters detected */
		vel=atof(argv[3]);	/* claimed speed, plus or minus */
		if (vel<0) {
			seg=0;			/* FAST mode set */
			vel=-vel;		/* absolute value of speed */
		}
	}
/* set delays accordingly */
	if (vel<200)
			periodo=200/vel;/* 200 iterations = 1uS @ RPi400 */
	else 	periodo=1;		/* maximum speed, we don't want it rounded to zero! */
	dats=65+seg*150;		/* nominally 12.5 or 4.3 kb/s @ 1 MHz */
	printf("%f MHz", vel);
	if (!seg)	prinf(", fast NMI handler");
	printf("\nNominal rate: %d b/s\n\n", vel*1000000/(dats+15));
/* GPIO setup */
	wiringPiSetupGpio();	/* using BCM numbering! */
	digitalWrite(CB1, 0);	/* clock initially disabled, note OC */
	pinMode(CB1, OUTPUT);
	pinMode(CB2, OUTPUT);
	pinMode(STB, OUTPUT);	/* not actually used */
/* get filename in batch mode */
	printf("File: %s\n", argv[1]);
/* open source file */
	if ((f = fopen(argv[1], "rb")) == NULL) {
		printf("*** NO SUCH FILE ***\n");
		return -2;
	}
/* compute header parameters */
	fseek(f, 0, SEEK_END);
	fin = ftell(f);
	printf("It's %d bytes long ($%04X)\n\n", fin, fin);
/* check start address */
	ini=atof(argv[2]);		/* atoi() won't accept Hex addresses! */
	fin += ini;				/* nanoBoot mandatory format */
/* send header */
	cabe(0x4B);
	cabe(fin>>8);
	cabe(fin&255);
	cabe(ini>>8);
	cabe(ini&255);
/* send binary after pressing Return */
	rewind(f);
	printf("Hit <CR> to start transfer...\n)";
	while (getchar()!='\n');
	printf("*** GO!!! ***\n");
	for (i=ini; i<fin; i++) {
		if ((i&255) == 0) {
			useg(2000);		/* page crossing may need some time */
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
/* for old nanoBoot ROM, invert bit (bit^1) */
void cabe(int x) {			/* just like dato() but with longer bit delay, whole header takes ~85 ms */
	int bit, i = 8;

	while(i>0) {
		bit = x & 1;
		digitalWrite(CB2, bit);		/* send bit for OC, NO longer INVERTED */
		digitalWrite(CB1, 1);
		useg(15);			/* eeeeeek */
		digitalWrite(CB1, 0);
		useg(1985);			/* way too long, just in case, note OC */
/* delay is best here in any case */
		x >>= 1;
		i--;
	}
	useg(1000);				/* shouldn't be needed, but won't harm anyway */
}

void dato(int x) {			/* send a byte at 'top' speed */
	int bit, i = 8;

	while(i>0) {
		bit = x & 1;
		digitalWrite(CB2, bit);		/* note OC */
		digitalWrite(CB1, 1);
		useg(15);			/* eeeeeeek */
		digitalWrite(CB1, 0);
		useg(dats);			/* *** cranked up to 55 µs or so (at 1 MHz) is pretty unreliable *** */
/* delay is best here in any case */
		x >>= 1;
		i--;
	}
	digitalWrite(CB2, 0);	/* let data line float high, note OC */
	useg(125);				/* *** perhaps 200 µs or so *** */
}

/* this actually waits for a number of t-states */
void useg(int x){
	int i, t;

	for (t=0; t<x; t++){
		for (i=0; i<periodo; i++);	/* *** 200 iterations = 1 µs on RPi400 *** */
	}
}
