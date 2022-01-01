/* (c) 2020-2022 Carlos J. Santisteban */
#include <stdlib.h>
#include <time.h>
#include <stdio.h>

unsigned long dword(char x[], int pos)
{
	unsigned long res = 0;
	unsigned char c;
	int i;
	
	for(i=pos+3; i>=pos; i--)
	{
		c = x[i];
		res *= 256;
		res += c;
	}
	
	return res;
}

unsigned int word(char x[], int pos)
{
	unsigned int res;
	unsigned char cl, ch;
	
	cl = x[pos];
	ch = x[pos+1];
	res = cl + 256*ch;
	
	return res;
}	

char ascpix(int x)
{
	if (x<32) return ' ';
	if (x<64) return '.';
	if (x<96) return '-';
	if (x<128) return '+';
	if (x<160) return '*';
	if (x<192) return '&';
	if (x<224) return '%';
	return '#';
}

int main(void)
{
	FILE* arch;
	int i, j, ii, jj, dx, dy, bd;
	unsigned int cosa;
	float media, mix;
	unsigned char buf;
	unsigned long l, of, x, y;
	char cad[55];
	unsigned char paleta[256];
	unsigned char* bmap;
	
	srand(time(NULL));
	
	if ((arch = fopen("ld.bmp","rb")) == NULL)
	{
		printf("*** NO HAY FILETE ***");
		return -1;
	}
	fgets(cad, 55, arch);
	if ((cad[0] != 'B') || (cad[1] != 'M'))
	{
		printf("*** No es BMP ***");
		return 0;
	}
	l = dword(cad, 2);
	printf("Tamaño: %ld\n", l);
	of = dword(cad, 10);
	printf("Offset: %ld\n", of);
	x = dword(cad, 14);
	switch(x)
	{
		case 40:
			printf("Güin V3...");
			break;
		case 108:
			printf("Güin 98 etc???");
			break;
		case 124:
			printf("Güinequinpé???");
			break;
		default:
			printf("O es OS/2, o está puteao");
			return -1;
	}
	mix = 0;
	fseek(arch, 14+x, SEEK_SET);
	printf("@ %ld\n",ftell(arch));
	for(i=0; i<256; i++);
	{
		media=0.11*(float)fgetc(arch)+0.59*(float)fgetc(arch)+0.3*(float)fgetc(arch);
		fgetc(arch);
		paleta[i]=(char)media;
		mix += media;
	}
	printf("Paleta cargada (media = %f)\n", mix/256);
	x = dword(cad, 18);
	y = dword(cad, 22);
	bd = word(cad, 28);
	printf("[%ld x %ld, %d bits]", x, y, bd);
	l = dword(cad, 34);
	printf(" %ld bytes\n", l);
	if (word(cad, 30))
	{
		printf("*** Está comprimía ***");
		return -1;
	}
	
//	bmap = new unsigned char[l+1];
	bmap = (unsigned char*)malloc((l+1)*sizeof(unsigned char));
	
	fseek(arch, of, SEEK_SET);
	fgets((char *)bmap, l+1, arch);
	printf("Filete en RAM\n");
	if (x%4)	x = (x/4+1)*4;
	
	dx = 4;
	dy = 8;
	
	for(i=0; i<y; i+=dy)
	{
		media = 0;
		for(j=0; j<x; j+=dx)
		{
			cosa = 0;
			for(ii=i; ii<i+dy; ii++)
			{
				for(jj=j; jj<j+dx; jj++)
				{
					//printf("(%d-%d)",jj,ii);
					buf = bmap[x*(y-ii-1) + jj];
					cosa += buf;
				}
			}
			printf("%c", ascpix(255-(cosa/(dx*dy))));
			//media += cosa/8;
		}
		//printf("Media línea %d = %f\n", i, media/x);
		printf("\n");
	}
	
	fclose(arch);
//	delete [] bmap;
	free(bmap);
	
	return 0;
}

	
