/* (c) 2020 Carlos J. Santisteban */
#include <stdlib.h>
#include <time.h>
#include <stdio.h>

char ascpix(int x); //obtiene un carácter según la densidad del 'pixel'
unsigned int word(char x[], int pos); //lee el valor de 2 bytes en el vector
unsigned long dword(char x[], int pos); // lee el valor de 4 bytes en el vector

int main(void)
{
	FILE* arch;
	int i, j, ii, jj, dx, dy, bd, k, blk;
	unsigned int cosa;
	float media, mix;
	unsigned char buf;
	unsigned long l, of, x, y;
	char cad[55];
	unsigned char paleta[256];
	unsigned char* bmap; // puntero a un vector 'dinámico', propiedad del S.O.
	
    printf("Nombre de archivo: ");
    scanf("%s", cad);	
	if ((arch = fopen(cad,"rb")) == NULL)  // intenta abrir
	{
		printf("*** NO HAY FILETE ***");
        printf("\nentrar 0>");
        scanf("%d", &x);
		return -1;
	}
//	fgets(cad, 55, arch);  // Lee cabecera. PELIGRO: ¿Y si pilla un CR?
    fread(cad,55,sizeof(unsigned char),arch);     // lee cabecera

	if ((cad[0] != 'B') || (cad[1] != 'M')) // identifica cabecera válida
	{
		printf("*** No es BMP ***");
        printf("\nentrar 0>");
        scanf("%d", &x);
		return -1;
	}
	l = dword(cad, 2);    // longitud archivo
	printf("TamaÃ±o: %ld\n", l);
	of = dword(cad, 10);     // posición datos imagen
	printf("Offset: %ld\n", of);
	x = dword(cad, 14);     // tipo de archivo
	switch(x)
	{
		case 40:
			printf("GÃ¼in V3...");
			break;
		case 108:
			printf("GÃ¼in 98 etc???");
			break;
		case 124:
			printf("GÃ¼inequinpÃ©???");
			break;
		default:
			printf("O es OS/2, o estÃ¡ puteao");
            printf("\nentrar 0>");
            scanf("%d", &x);
			return -1;
	}
	mix = 0;
	fseek(arch, 14+x, SEEK_SET);       // se va al inicio de la paleta
	printf("@ %ld\n",ftell(arch));
	for(i=0; i<256; i++)          // calcula tonos de gris de la paleta (!)
	{
		media=0.11*(float)fgetc(arch)+0.59*(float)fgetc(arch)+0.3*(float)fgetc(arch);
		fgetc(arch);  // desperdicia un byte para cuadrar a 32 bits / entrada                                                              
		paleta[i]=(char)media;
		mix += media;         // estadística...
	}
	printf("Paleta cargada (media = %f)\n", mix/256);  // valor medio de luminosidad...
	x = dword(cad, 18);    // anchura
	y = dword(cad, 22);    // altura
	bd = word(cad, 28);    // profundidad de bits
	printf("[%ld x %ld, %d bits]", x, y, bd);
	if (bd>8)
	{
             printf("*** No puedo leer BMPs sin paleta ***");
             printf("\nentrar 0>");
             scanf("%d", &x);
             return -1;
    }
	l = dword(cad, 34);    // tamaño datos imagen
	printf(" %ld bytes\n", l);
	if (word(cad, 30))     // verifica compresión
	{
		printf("*** EstÃ¡ comprimÃ­a ***");
        printf("\nentrar 0>");
        scanf("%d", &x);
		return -1;
	}
	
	printf("Positivo (Mac) = 1, Negativo (DOS) = 0. Valor? ");
	scanf("%d", &i);
	
	k = 1-2*i;
	blk = 255*i;
	bmap = new unsigned char[l+1];   // reserva memoria dinámica para la imagen
//	bmap = (unsigned char*)malloc((l+1)*sizeof(unsigned char));
	
	fseek(arch, of, SEEK_SET);  // se coloca al inicio de los datos
//	fgets((char *)bmap, l+1, arch);   // PELIGRO: aborta al encontrar CR
    fread(bmap,l,sizeof(unsigned char),arch);     // lee todo el archivo
	printf("Filete en RAM\n");
	
	
	if (x%4)	x = (x/4+1)*4;        // rectifica anchura para que sea divisible por 4 (por exceso)
	dx = x/80+1;  // anchura del bloque
	dy = 2*dx;  // altura del bloque
    y = y/dy*dy;                      // redondea altura

	for(i=0; i<y; i+=dy)   // bucle líneas
	{
		for(j=0; j<x; j+=dx)  // bucle columnas
		{
			cosa = 0;         // luminosidad acumulada
			for(ii=i; ii<i+dy; ii++)   //líneas dentro del bloque
			{
				for(jj=j; jj<j+dx; jj++)        // columnas dentro del bloque
				{
					buf = paleta[bmap[x*(y-ii-1) + jj]];   // lee pixel, viendo paleta
					cosa += buf;
				}
			}
			printf("%c", ascpix(blk+k*(cosa/(dx*dy)))); // muestra carácter según la oscuridad del bloque
		}
		printf("\n");
	}
	
	fclose(arch);    // cierra archivo
	delete [] bmap;  // libera memoria dinámica
//	free(bmap);

   printf("\nOK, entrar 0>");
   scanf("%d", &x);
	
	return 0;
}

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
	
