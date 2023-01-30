/* nanoLink sender for Raspberry Pi *
 * (c) 2023 Carlos J. Santisteban   *
 * last modified 20230130-2248      *
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

void send(int x);

int main(int argc, char *argv[]) {
	int		boot	= 1;			/* executable by default */
	int		start	= 0;			/* base address */
	int		i, index, length, end;
	FILE	*f;

	printf("*** nanoLink sender (OC) ***\n");
	printf("pin 34=GND, 36=CLK, 38=DAT\n\n");
/* check command syntax */
	if (argc<2) {
		printf("\nUSAGE: ./%s file [address] [-]\n", argv[0]);
		printf("address in decimal or hex (Intel '0x' syntax)\n");
		printf("-: do NOT execute upon reception\n");
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
		if ((start==0) && (argc>3))
			start=(int)atof(argv[3]);	/* try with third parameter */
		index = 2;					/* try locating -n parameter */
		if ((argv[index][0]!='-') && (argc>3))
			index=3;				/* may be the third parameter (as usual) */
		if (argv[index][0]=='-')
			boot=0;					/* non-executable */
	}
	if (start==0) {
		printf("(ROM image) ");fflush(stdout);
		start=65536-length;			/* if omitted, assume it's a ROM image */
	}
	printf("Start address: $%04X", start);
	if (!boot)	printf(" (non executable)");
	printf("\n");
	end = start+length;
/* GPIO setup */
	wiringPiSetupGpio();	/* using BCM numbering! */
	digitalWrite(CB1, 0);	/* clock initially disabled, note OC */
	pinMode(CB1, OUTPUT);
	pinMode(CB2, OUTPUT);
	pinMode(STB, OUTPUT);	/* not actually used */
/* send header */
	printf("Sending header...\n");
	send(boot?0x4B:0x4E);	/* magic number $4B for bootable, $4E for data */
	send(end   & 255);
	send(end   >>  8);		/* end address, now little-endian */
	send(start & 255);
	send(start >>  8);		/* start address, now little-endian */
	send(boot?0x4B:0x4E);	/* magic number $4B for bootable, $4E for data */
	delayMicroseconds(5000);			/* wait at least 5 ms */
/* send actual file */
	rewind(f);
	printf("Sending code! ");
	fflush(stdout);
	wiringPiSetupSys();
	for (i=start; i<end; i++) {
		send(fgetc(f));
		if ((i & 255) == 255) {
			delayMicroseconds(2000);	/* page crossing may need some time */
			printf("$%02X, ", i>>8);
			fflush(stdout);
		}
	}
	printf("\b\b complete pages!\nEnded at $%04X (%f kiB/s)\n", i, length/1.024/millis());
	fclose(f);

	return 0;
}

void send(int x) {
	int bit, i = 128;

	while(i>0) {
		bit = x & i;
		digitalWrite(CB1, 1);		/* trigger NMI */
		delayMicroseconds(10);		/* wait for NMI acknoledge before sending IRQ */
		digitalWrite(CB2, bit);		/* note OC */
		delayMicroseconds(27);//22		/* keep data line until IRQ is enabled */
		digitalWrite(CB1, 0);
		digitalWrite(CB2, 0);		/* let data line float high, note OC */
		delayMicroseconds(bit?44:28);//41:26);	/* ones take longer to transmit */
		i >>= 1;
	}
	delayMicroseconds(30);
}
