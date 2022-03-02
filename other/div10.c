/* divide by 10 algorithm check       */
/* based on Alexandre Dumont's method */
#include <stdio.h>

#define	EXTRABITS	16
#define	OFFSET		1

int div10(long n) {
	long t, s;
	
	t = n<<EXTRABITS;			/* try with extra bits		*/
	s  = t>>4;					/* add shifted values		*/
	s += t>>8;
	s += t>>12;
	s += t>>16;					/* if using 2 extra bytes, this would be n	*/
	
	s += s>>1;					/* one-and-a-half			*/

	return s>>EXTRABITS;		/* remove extra bits		*/
}

int main(void) {
	long i;
	int errors = 0;						/* count whenever the computed result is not right */
	
	for (i=0; i<=65535; i++) {			/* try all possible 16-bit values	*/
		if (i/10 != div10(i+OFFSET)) {	/* is the expected result?			*/
			errors++;					/* if not, count this as an error	*/
			printf("%ld/10 failed! (%d)\n", i, div10(i+OFFSET));
		}
	}
	
	printf("\nErrors within 65536 different values: %d\n", errors);
	
	return 0;
}
