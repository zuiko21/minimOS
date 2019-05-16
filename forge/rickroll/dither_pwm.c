/*
 * converts 8bit WAV into dithered *
 * PWM for VIA's shift register    *
 *
 * (c) 2019 Carlos J. Santisteban  *
 * last modified 20190516-1239     *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* global variables */
	FILE	*f, *s;
	unsigned char	pwm[9]={0, 32, 64, 96, 128, 160, 192, 224, 255}; /* still linear, but should be logarithmic */

/* functions */
unsigned char	dither(unsigned char x) {
	unsigned char	r, y, z;
	int				i=0;
	
	while (x>pwm[i+1] && i<7)	i++;		/* scan threshold */
	if (x==pwm[i])				r=x;		/* exact value */
	else {		/* dither intermediate value */
		y = pwm[i+1]-pwm[i];				/* range */
		z = x-pwm[i];						/* position of current sample */
		if (rand()%y > z)		r=pwm[i];	/* closer to lower threshold... */
		else					r=pwm[i+1];	/* ...or closer to ceiling */	
	}

	return	r;
}

/* *** main code *** */
int main(void) {
	char			name[100];
	unsigned char	c;
	int				i, j, k, x;

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
			fseek(f, 44, SEEK_SET);	/* skip WAV header */
			while (!feof(f)) {
				c=fgetc(f);
				fputc(dither(c),s);
			}
/* clean up */
			fclose(f);
			fclose(s);
			printf("Success!\n");
		}
	}

	return 0;
}
