/*
 * converts 8bit WAV into dithered      *
 * PWM for VIA's shift register         *
 *
 * (c) 2019-2021 Carlos J. Santisteban  *
 * last modified 20211007-1320          *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* global variables */
	FILE	*f, *s;
	unsigned char	thr[9]={0, 70, 104, 120, 128, 136, 152, 186, 255}; 				/* sort-of-logarithmic threshold scale */
	unsigned char	pwm[9]={0, 0x10, 0x24, 0x52, 0x55, 0xAD, 0xDB, 0xEF, 0xFF};		/* PWM patterns */

/* functions */
unsigned char	dither(unsigned char x) {
	unsigned char	r, y, z, i=0;

	while (x>thr[i+1] && i<7)	i++;		/* scan threshold */
	if (x==thr[i])				r=x;		/* exact value */
	else {		/* dither intermediate value */
		y = thr[i+1]-thr[i];				/* range */
		z = x-thr[i];						/* position of current sample */
		if (rand()%y > z)		r=i;		/* closer to lower threshold... */
		else					r=i+1;		/* ...or closer to ceiling */	
	}

	return	pwm[r];							/* return direct PWM pattern */
}

/* *** main code *** */
int main(void) {
	char			name[100];
	unsigned char	c;
	int				i;

	srand(time(NULL));		/* randomize numbers */

	/* test code
	for(i=0;i<256;i+=32) {
		x=dither(i);
		printf("%d,",x);
	}
	printf("%d\n",dither(255));
	/* end of test code */

/* select input file */
	printf("WAV File? ");
	fgets(name, 100, stdin);
/* why should I put the terminator on the read string? */
	i=0;
	while (name[i]!='\n' && name[i]!='\0')	{i++;}
	name[i]=0;			/* filename is ready */
	printf("Opening %s file...\n", name);
	f=fopen(name, "r");
	if (f==NULL) {		/* error handling */
		printf("Could not open audio file!\n");
	} else {
/* open output file */
		strcat(name,".pwm");
		s=fopen(name,"w");
		if (s==NULL) {	/* error handling */
			printf("Cannot output dithered file!\n");
		} else {
/* proceed! */
//			fseek(f, 44, SEEK_SET);	/* skip WAV header */
			while (!feof(f)) {
				c=fgetc(f);
//				printf("%2X>", c);
				c=dither(c);
//				printf("%2X ", c);
				if(!feof(f)) {		/* make certain there is no extra byte at the end! */
					fputc(c,s);
				}
			}

/* clean up */
			fclose(f);
			fclose(s);
			printf("Success!\n");
		}
	}

	return 0;
}
