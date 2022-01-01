/* nanoBoot server for Raspberry Pi!   *
 * TEST version for debugging          *
 * (c) 2020-2022 Carlos J. Santisteban *
 * last modified 20210219-0931         */

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

/* prototypes */
void cabe(int x);	/* send header byte in a slow way */
void dato(int x);	/* send data byte at full speed! */
void useg(int x);	/* delay for specified microseconds */

/* *** main code *** */
int main(void) {
	int		ini;

	printf("*** nanoBoot TEST server (OC) ***\n\n");
	printf("pin 34=GND, 36=CLK, 38=DAT\n\n");
/* GPIO setup */
	wiringPiSetupGpio();	/* using BCM numbering! */
	digitalWrite(CB1, 0);	/* clock initially disabled, note OC */
	pinMode(CB1, OUTPUT);
	pinMode(CB2, OUTPUT);
	pinMode(STB, OUTPUT);	/* not actually used */
	while (-1) {
/* compute transfer 'parameters' */
		printf("Byte to send ($1xx=header): ");
		scanf("%x", &ini);
/* send THAT byte */
		if (ini&256)	cabe(ini&255);
		else			dato(ini&255);
		digitalWrite(CB2, 0);	/* let data line float high, note OC */
	}

	return 0;
}

/* *** function definitions *** */
void cabe(int x) {			/* just like dato() but with longer bit delay, whole header takes ~85 ms */
	int bit, i = 8;

	while(i>0) {
		bit = x & 1;
		digitalWrite(CB2, bit);		/* send bit for OC, NO longer INVERTED */
		digitalWrite(CB1, 1);
		useg(5);
		digitalWrite(CB1, 0);
		delay(2);			/* way too long, just in case, note OC */
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
		digitalWrite(CB2, bit);		/* note OC */
		digitalWrite(CB1, 1);
		useg(5);
		digitalWrite(CB1, 0);
		useg(50);			/* *** 75 µs or so (at 1 MHz), may need more with IOB beep *** */
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
