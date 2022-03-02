/* divide by 10 algorithm check       */
/* based on Alexandre Dumont's method */
#include <stdio.h>

#define	EXTRABITS	8

int div10(unsigned int n) {
	long t, s=0;
	
	t = n<<EXTRABITS;			/* try with one extra byte	*/
	s += t>>4;					/* add shifted values		*/
	s += t>>8;					/* this one is actually n	*/
	s += t>>12;
	s += t>>16;
	
	s += s>>1;					/* one-and-a-half			*/
	
	return (int) s>>EXTRABITS;	/* remove extra byte		*/
}
	
int main(void) {
	unsigned int i;
	long errors = 0;			/* count whenever the computed result is not right */
	
	for (i=0; i<=65535; i++) {	/* try all possible 16-bit values	*/
		if (i/10 != div10(i)) {	/* is the expected result?			*/
			errors++;			/* if not, count this as an error	*/
		}
	}
	
	printf("Errors within 65536 different values: %d\n", errors);
	
	return 0;
}
