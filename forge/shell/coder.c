/* (c) 2020-2021 Carlos J. Santisteban */
#include <stdio.h>

int main(void)
{
	int i;

	FILE* f;

	f=fopen("test.bin","wb");
	fputc(0,f);
	for (i=1;i<256;i++)
	{
		fputc(i,f);
		fputc(i,f);
		fputc(i,f);
	}
	fclose(f);
	
	return 0;
}
