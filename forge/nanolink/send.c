/* nanoLink sender for Raspberry Pi *
 * (c) 2023 Carlos J. Santisteban   *
 * last modified 20230128-2041      *
 */

#include <stdio.h>
#include <stdlib.h>
#include <wiringPi.h>
/* *** needs -lwiringPi option *** */

/* pin definitions, 36-38-40 at header, BCM 16-20-21         */
/* CB1 is clock, CB2 data, can use pin 34 as GND             */
/* THIS VERSION NEEDS OPEN COLLECTOR (INVERTING) DRIVERS     */
/* STB pin isn't currently used, just a placeholder for SS22 */
#define	CB1		16
#define	CB2		20
#define	STB		21

int main(int argc, char *argv[]) {
	int		boot	= 1;			/* executable by default */
	int		start	= 0;			/* base address */
	int		length, end;
	FILE	*f;

	printf("*** nanoLink sender (OC) ***\n");
	printf("pin 34=GND, 36=CLK, 38=DAT\n\n");
/* check command syntax */
	if (argc<2) {
		printf("\nUSAGE: ./%s file [address] [-n]\n", argv[0]);
		printf("address in decimal or hex (Intel '0x' syntax)\n");
		printf("-n: do NOT execute upon reception\n");
		return -1;
	}
/* open source file */
	if ((f = fopen(argv[1], "rb")) == NULL) {
		printf("*** NO SUCH FILE ***\n");
		return -2;
	}
/* compute header parameters */
	fseek(f, 0, SEEK_END);
	length = ftell(f);
	printf("%s is %d bytes long ($%04X)\n\n", argv[1], length, length);
/* set parameters */
	if (argc>2) {
		start=(int)atof(argv[2]);		/* atoi() won't accept Hex addresses! */
		if (!start && argc>3)
			start=(int)atof(argv[3]);	/* try with third parameter */
		index = 2;					/* try locating -n parameter */
		if (argv[index][0]]!='-' && argc>=3)
			index=3;				/* may be the third parameter (as usual) */
		if (argv[index][0]]=='-' && argv[index][1]|32 =='n')
			boot=0;					/* non-executable */
	}
	if (start==0)
		start=65536-length;			/* if omitted, assume it's a ROM image */
	printf("Start address: $%04X\n", (int)start);
	end = start+length;
/* GPIO setup */
	wiringPiSetupGpio();	/* using BCM numbering! */
	digitalWrite(CB1, 0);	/* clock initially disabled, note OC */
	pinMode(CB1, OUTPUT);
	pinMode(CB2, OUTPUT);
	pinMode(STB, OUTPUT);	/* not actually used */
/* send header */
	printf("Sending header...\n");
	if (boot)	send(0x4B);	/* magic number $4B for bootable, $4E for data */
	else		send(0x4E);
	send(end & 255);
	send(end >>  8);		/* end address, now little-endian */
	send(start & 255);
	send(start >>  8);		/* start address, now little-endian */
	sleep(5);				/* wait at least 5 ms */
/* send actual file */
	rewind(f);
	for (i=start; i<end; i++) {
		if ((i & 255) == 0) {
			sleep(2);		/* page crossing may need some time */
			printf("$%02X, ", i>>8);
		}
		c = fgetc(f);
		send(c);
	}
	printf("\b\b!\nEnded at $%04X\n", end);
	fclose(f);

	return 0;
}




/* old code for reference only

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

*/
