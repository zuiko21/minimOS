/* nanoLink sender for Raspberry Pi *
 * (c) 2023 Carlos J. Santisteban   *
 * last modified 20230128-2254      *
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
	printf("Start address: $%04X", start);
	if (!boot)	printf(" (non executable)");
	print("\n");
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
	send(end   & 255);
	send(end   >>  8);		/* end address, now little-endian */
	send(start & 255);
	send(start >>  8);		/* start address, now little-endian */
	usleep(5000);			/* wait at least 5 ms */
/* send actual file */
	rewind(f);
	printf("Sending code! ");
	for (i=start; i<end; i++) {
		send(fgetc(f));
		if ((i & 255) == 255) {
			usleep(2000);	/* page crossing may need some time */
			printf("$%02X, ", i>>8);
		}
	}
	printf("\b\b!\nEnded at $%04X!\n", i);
	fclose(f);

	return 0;
}

void send(int x) {
	int bit, i = 128;

	while(i>0) {
		bit = x & i;
		digitalWrite(CB1, 1);
		usleep(12);					/* must trigger NMI, then wait for IRQ to be disconnected before sending data */
		digitalWrite(CB2, bit);		/* note OC */
		usleep(40);
		digitalWrite(CB1, 0);
		digitalWrite(CB2, 0);		/* let data line float high, note OC */
		usleep(28);
		i >>= 1;
	}
	usleep(32);
}
