// pseudo malloc, last modified 20150209-1428
// (c) 2015-2022 Carlos J. Santisteban
#include <stdio.h>

	unsigned int	ram_tab[8];		// like sysvars.h
	unsigned int	ram_siz[8];
	unsigned char	ram_stat[8];

void view(void)
{
	int x;
	
	for(x=0;x<8;x++)
	{
		printf("%d: ", x);
		if (ram_stat[x] != ' ')
		{
			printf("%d (%d) ", ram_tab[x], ram_siz[x]);
		}
		switch(ram_stat[x])
		{
			case 'F':
				printf("LIBRE");
				break;
			case 'U':
				printf("usado");
				break;
			case ' ':
				printf("--- sin asignar ---");
				break;
			default:
				printf("***DESCONOCIDO***");
		}
		printf("\n");
	}
}

unsigned int	_malloc(unsigned int size)
{
	unsigned int	dir = 0;
	int a,x,y;
	int local;

	printf("[Asignando %d bytes... ", size);
	x=0;
	while (((ram_stat[x]!='F')||(ram_siz[x]<size))&&(x<8))
	{
		x++;
	}
	if (x>=8)
	{
		printf("***NO CABE***]\n");
		return -1;		// memory full
	}
	local=ram_siz[x];
	ram_siz[x]=size;
	ram_stat[x]='U';
	if (local)
	{
		//insert x+1 > x+2
		if (ram_stat[7] != ' ')
		{
			printf("---mal asunto---]\n");
			return -1;	// bad things
		}
		for (y=6; y>x; y--)
		{
			ram_siz[y+1] = ram_siz[y];
			ram_tab[y+1] = ram_tab[y];
			ram_stat[y+1] = ram_stat[y];
		}
		// create new free
		ram_tab[x+1]=ram_tab[x]+size;
		ram_siz[x+1]=local-size;
		ram_stat[x+1]='F';
	}
	dir=ram_tab[x];
	printf("OK en %d]\n", dir);
	
	return dir;		// if OK
}

int	_free(unsigned int pos)
{
	int x,y,a;
	
	printf("[Liberando bloque en %d... ", pos);
	x=0;
	while ((ram_tab[x] != pos)&&(x<8))
	{
		x++;
	}
	if (x>=8)
	{
		printf("NO EXISTE, pero bueno\n]");
		return -1;
	}
	ram_stat[x] = 'F';
	// compactar si posible
	while(ram_stat[x+1]=='F')
	{
		printf("!");
		ram_siz[x] += ram_siz[x+1];
		// esto se hace chapuceramente instead
		for(y=x+1;y<7;y++)
		{
			ram_siz[y] = ram_siz[y+1];
			ram_tab[y] = ram_tab[y+1];
			ram_stat[y] = ram_stat[y+1];
		}
		ram_stat[7]=' '; // en la chapuza, x+1
	}
	printf("OK]\n");
	
	return 0;
}

int main(void)
{
	int x;
	
	for(x=1;x<8;x++)
	{
		ram_stat[x]=' ';
	}
	
		ram_stat[0] = 'F';			// init free
		ram_tab[0] = 0x400;			// start of ram
		ram_siz[0] = 0x3C00;		// end of ram $4000

view();
_malloc(500);
_malloc(1000);
_malloc(20000);
_malloc(9537);
view();
_free(1524);
view();
_malloc(4000);
view();
_free(1024);
view();
// do some

	return 0;
}
