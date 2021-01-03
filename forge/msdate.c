/* (c) 2020-2021 Carlos J. Santisteban */
#include <stdio.h>

int main(void)
{
	int y, m, d, h, min;
	unsigned int date, time;

	printf("Año: ");
	scanf(" %d", &y);
	printf("Mes: ");
	scanf(" %d", &m);
	printf("Día: ");
	scanf(" %d", &d);
	printf("Hora: ");
	scanf(" %d", &h);
	printf("Minuto: ");
	scanf(" %d", &min);

	date = (y-1980)<<9 | m<<5 | d;
	time = h<<11 | min<<5;
	
	printf("DATE: $%04x, TIME: $%04x\n", date, time);
	
	return 0;
}
