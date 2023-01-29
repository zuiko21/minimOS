/* IO9 keyboard emulation              *
 * (c) 2021-2022 Carlos J. Santisteban *
 * last modified 20220421-1820         */

#include <stdio.h>
#include <stdlib.h>
#include <wiringPi.h>
/* *** needs -lwiringPi option *** */

#define	UNBUFF	_UNBUFF
#ifdef	UNBUFF
#include <curses.h>
/* *** needs -lncurses option *** */
#endif

/* length of emulated keypress */
#define DELAYMS	25

/* pin definitions, rightmost top row at header is BCM 10-9-11-[GND]-[SD]-5-6-13-19-26-[GND] */
/* alternative BCM pinout:  17-27-22-[3V3]-[MOSI]-[MISO]-[CLK]-[GND]-[SD]-5-6-13-19-26-[GND] */
/* say, D7-D5 & D4-D0 */
/* may use the GND from nanoLink (pin 34 at bottom row) */
#define	D0		26
#define	D1		19
#define	D2		13
#define	D3		6
#define	D4		5

/* might change these to 17-27-22, as they may be used with SPI */
#define	D5		11
#define	D6		9
#define	D7		10	/**/

/* SPI-savvy higher bits *
#define	D5		22
#define	D6		27
#define	D7		17 /**/

/* optional strobe pin is 40 at header, BCM21, rightmost bottom row */
#define	STB		21

/* Global variables */
int	ctl=255, alt=0;

/* prototypes */
void salida(int x);
void modi(void);

/* *** main code *** */
int main(void) {
	int c, last=0;

#ifdef	UNBUFF
    initscr();
#endif
	printf("*** PASK emulator ***\n\n");
	printf("pin 19=D7, 21=D6, 23=D5, 29=D4, 31=D3, 33=D2, 35=D1, 37=D0\n\n");
//	printf("pin 11=D7, 13=D6, 15=D5, 29=D4, 31=D3, 33=D2, 35=D1, 37=D0\n\n");
#ifdef	UNBUFF
	refresh();
#endif

/* GPIO setup */
	wiringPiSetupGpio();	/* using BCM numbering! */
	digitalWrite(D0, 0);	/* output initially zeroed */
	digitalWrite(D1, 0);
	digitalWrite(D2, 0);
	digitalWrite(D3, 0);
	digitalWrite(D4, 0);
	digitalWrite(D5, 0);
	digitalWrite(D6, 0);
	digitalWrite(D7, 0);
	digitalWrite(STB,1);	/* STROBE is active-low, will go into CA1 */
	pinMode(D0, OUTPUT);	/* set output port */
	pinMode(D1, OUTPUT);
	pinMode(D2, OUTPUT);
	pinMode(D3, OUTPUT);
	pinMode(D4, OUTPUT);
	pinMode(D5, OUTPUT);
	pinMode(D6, OUTPUT);
	pinMode(D7, OUTPUT);
	pinMode(STB,OUTPUT);
/* main loop */
	while(1) {
#ifdef	UNBUFF
		c = getch();
#else
		c = getchar();
#endif
		if (c==10)	c=13;	/* minimOS CR */
		if (c==1) {
//			modi();			/* ^A sets modifiers */
			c=0;
		}
		if ((c==27) && (last==27))	break;
		if (c) {
			salida(c&ctl|alt);
			printf("(%d)", c&ctl|alt);
#ifdef	UNBUFF
			refresh();
#endif
			ctl=255; alt=0;		/* reset modifiers */
			last=c;
		}
	}
	endwin();

	return 0;
}

/* *** function definitions *** */
void salida(int x) {
	digitalWrite(D0, x&1);		/* fast enough? */
	digitalWrite(D1, x&2);
	digitalWrite(D2, x&4);
	digitalWrite(D3, x&8);
	digitalWrite(D4, x&16);
	digitalWrite(D5, x&32);
	digitalWrite(D6, x&64);
	digitalWrite(D7, x&128);
	digitalWrite(STB,0);		/* assert STROBE pulse */
	delay(DELAYMS);				/* 5 ms wait should be enough */
	digitalWrite(STB,1);		/* negate STROBE pulse */
	digitalWrite(D0, 0);		/* reset port to allow repeated keys without handshake */
	digitalWrite(D1, 0);
	digitalWrite(D2, 0);
	digitalWrite(D3, 0);
	digitalWrite(D4, 0);
	digitalWrite(D5, 0);
	digitalWrite(D6, 0);
	digitalWrite(D7, 0);
	delay(DELAYMS);				/* let a non-handshake, interrupt-driven input allow repeated keys */
}

void modi() {
	int n=0;

//	while (getchar()=='\n');			/* will this supress the buffering? */
	printf("\n\n[MODIFIERS] 1=CTL, 2=ALT, 3=both: ");
	while (!n)	n=getchar();
	if (n=='1')		ctl=159; alt=0;		/* control key */
	if (n=='2')		ctl=255; alt=128;	/* alt key */
	if (n=='3')		ctl=159; alt=128;	/* both keys */
	printf("%c\n\n", n);
}

