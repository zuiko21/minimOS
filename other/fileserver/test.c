/* (c) 2015-2020 Carlos J. Santisteban */
#include <stdio.h>
#include <string.h>

int main(void)
{
	char c[80]="!login:pass\0";
	char l[80];
	char* p;

	printf("cadena=%s\n",c+2);
	p = strchr(c,':');
	printf("tras buscar : %s\n",p);
	strncpy(l,c+1,p-c-1);
	l[p-c-1]='\0';
	printf("login=%s\n",l);

	return 0;
}

