/* solution seeker for Fletcher-16 checksum *
 * (c) 2021 Carlos J. Santisteban           *
 * last modified 20210907-1515              */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(void) {
	int rom[16384];
	int sum, check, i, j, target;
	
	srand(time(NULL));
	
	target=0;
	for (i=0; i<16384; i++) {
		rom[i]=rand() & 255;	/* fill with random bytes */
		target += rom[i];		/* preliminary sum */
	}
	
	target -= rom[0x3FDE];		/* subtract reserved values */
	target -= rom[0x3FDF];
	target &= 255;
	target = 256-target;
	
	rom[0x3FDE]=rom[0x3FDF]=0;	/* clear them as well */

	check=sum=0;				/* precheck values */
/*	for(i=0;i<16384;i++) {
		sum += rom[i];
		sum &= 255;
		check += sum;
		check &= 255;
	}
	printf("ORIGINAL: %d, %d ($%02x%02x)\n", sum, check, check, sum);
*/	printf("TARGET: %d\n", target);

	check = 256;
	j=0;
	while (j<256 && check!=0) {
		rom[0x3FDE]=j;			/* preload candidates */
		rom[0x3FDF]=(target-j) & 255;	/* as defined from preliminary sum */
		check=sum=0;
		for(i=0;i<16384;i++) {
			sum += rom[i];
			sum &= 255;
			check += sum;
			check &= 255;
		}
		//if(check==0)
			printf("%d.%d: SUM=%d, CHECK=%d\n", j, rom[0x3FDF], sum, check);
		j++;
	}
	if (check)		printf("\n*** No way! ***\n");
	
	return 0;
}
