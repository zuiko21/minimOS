; (c) 2020 Carlos J. Santisteban
#include <stdio.h>

void binario(char v)
{
	unsigned char n;
	for (n=128; n>=1; n>>=1)
	{
		if (v & n)  printf("1");
		else        printf("0");
	}
}

void ror(char *v, int *c)
{
	int t;
	
	t = *v & 1;
	(*v) >>= 1;
	if (*c)	*v |= 128;
	else    *v &= 127;
	*c = t;
}

void espera(void)
{
    char a;
    char z_low, z_high;
    int total=0;
    
    a = 195;
    z_low = z_high = a;
    do {
        do ++total; while (--z_low);
    } while (--z_high);
    printf("[%d]", total);
}

int main(void)
{
	char x, a;
	int c, salida=50;
	char last_c, cont_pb, cont_pa;
	
	x = 0;
	last_c = x;	//hace falta?
	cont_pb = x;
	cont_pa = x;
    do {
        binario(cont_pb);	//muestra PB en binario
        printf("-");
        binario(cont_pa);
        printf("\n");
        a = last_c;
        if (!a)     c = 1;
        else        c = 0;
        ror(&cont_pb, &c);
        ror(&cont_pa, &c);
        if (!c)     {a=0; last_c=a;}
        else        last_c--;
        espera();
    } while (--salida);
    
	return 0;
}
