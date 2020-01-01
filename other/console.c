/* (c) 2020 Carlos J. Santisteban */
#include <stdio.h>

int main(void)
{
	char c;
	while(-1)
	{
		c=getchar();
		printf("Código de %c: %d\n", c, c);
	}
	return 0;
}

