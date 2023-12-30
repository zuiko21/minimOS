/*
 * 4-bit PCB dither and bankswitching	*
 * (c) 2023 Carlos J. Santisteban		*
 * last modified 20231230-1756			*
 * */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define	SAMPLES	30720
#define	EFFECT	1.0

typedef	u_int8_t	byte;

void	init(void);						// preload quantisation array
float	db(float n);					// convert dB into factor, for convenience
byte	nr(byte sample, float effect);	// compression effect = 0 (none) ... 1 (maximum)
byte	dither(byte sample);			// returns 0...15 as PSG *attenuation* values

byte	q[16];							// global quantisation array

int main(void) {
	char	name[12] = {"audio0.4bit\0"};
	FILE*	f;
	FILE*	s;
	int		i, c=0;
	byte	b[SAMPLES], first, second;

	init();

	f=fopen("dither.wav", "rb");		// open original unsigned 8-bit PCM
	if (f==NULL)	return -1;
	else			printf("open OK\n");
	fseek(f, 44, SEEK_SET);				// skip WAV header
	printf("Compression effect: %1.2f\n", EFFECT);

	while(!feof(f)) {
		if (fread(b, SAMPLES, 1, f) != 1)	return -1;	// fill buffer until the end
		else								printf("fread OK, ");
		for (i=0; i<SAMPLES; i+=2) {
			first  = dither(nr(b[i],  EFFECT));			// compute high nybble
			second = dither(nr(b[i+1],EFFECT));			// compute low nybble
//printf("%x%x",first,second);
			b[i>>1] = (first<<4) | second;				// combine into single byte
		}
		name[5]='0'+ c++;
		s = fopen(name, "wb");			// create output file
		if (s==NULL)	printf("*** ERROR opening bank %d ***\n", c-1);
		if (fwrite(b, SAMPLES>>1, 1, s) != 1)	printf("*** ERROR writing bank %d ***\n", c-1);
		fclose(s);						// this output file is finished!
		printf("%s OK\n",name);
	}
	fclose(f);

	return	0;
}

void	init(void) {
	byte	i;

	q[0] = 0;
	for (i=1; i<16; i++)	q[i] = i*17;
//		q[i] = 255 * db(-2.0*(15-i));	// preload thresholds for PSG's attenuation values
}

float	db(float n) {
	return	pow(10,n/20);				// turn dB into factor
}

byte	nr(byte sample, float effect) {
	float	s, t, c;
	byte	e;

	s = (sample-128)/127.0;				// convert into normalised float
	if (s < -1)		s = -1;				// beware of underflow!
	t = (s<0) ? -sqrt(-s) : sqrt(s);	// square root with original sign EEEEEK
	c = effect*t + (1.0-effect)*s;		// adjust effect (0..1)
	e = 128+c*127;						// back into unsigned integer

	return	e;
}

byte	dither(byte sample) {
	byte	r, i = 0;

//printf("%d ",sample);
	while (sample > q[i])	i++;			// find such i that q[i] <= sample < q[i+1]
//printf("%x",i);
	if (sample == q[i])		return 15-i;	// spot-on value
	r = rand() % (q[i+1]-q[i]);				// assume i<15 because of above!

	return	(r >= sample) ? 15-i : 14-i;	// round accordingly
//	return	(r >= sample) ? i : i+1;	// round accordingly
}
