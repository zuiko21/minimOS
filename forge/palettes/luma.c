/* (C) 2019-2020 Carlos J. Santisteban */
#include <stdio.h>

int main(void) {
	float y;
	int r,g,b;

	printf("R:");
	scanf("%d",&r);
	printf("G:");
	scanf("%d",&g);
	printf("B:");
	scanf("%d",&b);

	y=r*0.3+g*0.59+b*0.11;
	printf("Y = %d\n",(int)y);

	return 0;
}

