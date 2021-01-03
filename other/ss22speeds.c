/* compute VIA T2CL value for
 * SS22 speed adjustment
 * (c) 2015-2021 Carlos J. Santisteban
 * last modified 20150219-1032 */

#include <tgmath.h>
#include <stdio.h>

int compute_speed(float my, float his)
{
	float x;
	if (my <= his)	// same speed or slower me
	{
		x=0;		// full speed for me
	}
	else
	{
		x=ceil(2*my/his-2);
	}
	return (int)x;
}

int main(void)
{
	float speed;
	float bps;
	int i, j;			// loop counters
	int t2;				// value for VIA's T2CL
	
	printf("MHz? ");
	scanf(" %f", &speed);
	for (i=0; i<32; i++)
	{
		printf("%3d: ", 8*i);
		for (j=0; j<8; j++)
		{
			t2 = j+8*i;	// value in T2 counter
			bps = speed * 1000000 / (2*(t2+2));
			printf("%6.0f|", bps);
		}
		printf("\n");
	}
	
	printf("SC: %d\n", compute_speed(speed*16.0, 16.0));	// 16 -> compared against 1 MHz
	
	return 0;
}
