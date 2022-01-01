/* 3x5 font viewer
 * for Pacman score
 * (c) 2021-2022 Carlos J. Santisteban
 * last modified 20210304-1322
 * */
 
 #include <stdio.h>
 
 int main(void) {
	FILE	*f;
	int		i, j, k, n;
	unsigned char	c;
	unsigned char	m[5][10][16];
	
	f=fopen("a.o65", "rb");
	if (f==NULL)	return -1;
	
	for (i=0; i<5; i++)					/* scanline */
		for (j=0; j<10; j++)			/* decade */
			for (k=0; k<16; k++)		/* unit+padding */
				m[i][j][k]=fgetc(f);

	fclose(f);

	for (j=0; j<10; j++) {
		for (k=0; k<10; k++) {
			for (i=0; i<5; i++) {
				c = m[i][j][k];
				for (n=128; n>0; n>>=1) {
					if (c&n)	printf("#");
					else		printf(" ");
				}
				printf("\n");
			}
			printf("----\n");
		}
	}
	
	return 0;
}
