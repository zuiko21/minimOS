/* (c) 2020 Carlos J. Santisteban */
#include <stdio.h>

int main(void) {
/* input data */
	int n = 4096;	//dividend
	int d = 10;	//divisor

/* initialise */
	int q = 0;	//init quotient
	int r = 0;	//init remainder
	int i=32768;	//highest bit of 16-bit amounts

	while (0 < i) {	//will keep shifting right
		r <<= 1;	//shift left remainder
		if (n & i) {	//this bit set on N?
			r |= 1;		//set LSB of R, then
		}
		if (d <= r) {	//reminder too large?
			r -= d;		//subtract divisor
			q |= i;		//set this bit on quotient
		}
		i >>= 1;	//shift right for next bit
	}

/* show results */
	printf("Q=%d, R=%d\n", q, r);

	return 0;
}

