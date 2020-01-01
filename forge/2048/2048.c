/* 2048 tile game 1.0, 20140504-1600 */
/* (c) 2014-2020 Carlos J. Santisteban */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

void inicializar(void);				// tablero inicial
void generar(void);					// pone un dos (o un 4) en una casilla aleatoria libre
void mostrar(void);					// exhibe el tablero completo en pantalla
void espacios(int n, char s);		// muestra espacios hasta rellenar a cuatro
int gravedad(char d);				// determina desplazamientos
void mueve(int x, int y, char d);	// desplaza fichas solapando una
int posible(void);					// determina se se puede seguir jugando

int mat[4][4];	// la matriz global del juego
int puntos;		// tanteo (global)
int nx, ny;		// coordenadas de la nueva ficha, versión mejorada

int main(void)
{
	char grav;				// almacenará entrada del usuario

	srand(time(NULL));		// baraja los aleatorios
	inicializar();			// genera primer tablero
	do						// bucle principal
	{
		printf("WADX? ");	// solicita dirección
		scanf(" %c", &grav);
		if (gravedad(grav))		// desplaza fichas
			generar();			// añade ficha si se ha movido algo
		mostrar();			// actualiza tablero
	}
	while (posible());		// hasta que no pueda más
	printf("\n*** Has fracasado miserablemente como una rata de cloaca ***\n\n");

	return 0;
}

void inicializar(void)		// tablero inicial
{
	int i, j;				// bucles genéricos

	puntos = 0;				// inicia puntuación
	for (i=0; i<4; i++)
		for (j=0; j<4; j++)
			mat[i][j] = 0;	// cero es casilla vacía
			
	generar();				// colocación aleatoria primera jugada
	generar();
	
	mostrar();				// presenta primer tablero
}

void generar(void)			// pone un dos en una casilla aleatoria libre
{
	do
	{
		nx = rand() % 4;
		ny = rand() % 4;
	}
	while (mat[ny][nx]);	// espera casilla vacía, pero PUEDE COLGARSE SI NO CABE
	if (rand()%8)		mat[ny][nx] = 2;		// pone un dos
	else				mat[ny][nx] = 4;		// o un cuatro con 1/8 de probabilidad
}

void mostrar(void)			// exhibe el tablero completo en pantalla
{
	int i, j;				// bucles genéricos

	printf("+------+------+------+------+\n");
	for (i=0; i<4; i++)
	{
		printf("| ");
		for (j=0; j<4; j++)
		if (nx!=j || ny!=i)
			espacios(mat[i][j], ' ');	// muestra número ecualizando espacios
		else
			espacios(mat[i][j], '*');	// muestra nueva ficha ecualizando
		printf("\n+------+------+------+------+\n");
	}
	printf("\nPuntos: %d\n", puntos);	// muestra tanteo
}

void espacios(int n, char s)		// muestra espacios hasta rellenar a 4
{
	if (n<1000)		printf(" ");	// imprime espacios que faltan
	if (n<100)		printf(" ");
	if (n<10)		printf(" ");
	if (n)			printf("%d%c| ", n, s);			// imprime el número al final
	else			printf("  | ");					// casilla vacía
}

int gravedad(char d)		// desplaza fichas
{
	int x, y;		// columna y fila para bucles
	int z = 0;		// contador desplazamientos
	int n;			// fichas desaparecidas
	
	switch(d)		// según dirección escogida
	{
		case 'w':	// arriba
		case 'W':
			for (x=0; x<4; x++)			// para cada columna...
			{
				y=0;					// fila inicial
				n=0;					// fichas desaparecidas
				while (y+n < 4)			// avanza hasta haber procesado 4 fichas
				{
					while (mat[y][x] == 0 && n<4)	// casilla vacía
					{
						mueve(x, y, d);				// hacer sitio
						n++;						// una menos
					}
					if (y>0)			// ante la primera no puede haber igual
					{
						if (mat[y][x] == mat[y-1][x])	// iguales juntas
						{
							mat[y-1][x] *= 2;			// almacena doble valor
							puntos += mat[y-1][x];		// añade al tanteo
							mueve(x, y, d);				// y elimina la repetida
							n++;						// otra menos
						}
					}
					y++;				// siguiente fila
				}
				z += n;					// contabiliza desplazamientos
			}
			break;
		case 'a':	// izquierda
		case 'A':
			for (y=0; y<4; y++)			// para cada fila...
			{
				x=0;					// columna inicial
				n=0;					// fichas desaparecidas
				while (x+n < 4)			// avanza hasta haber procesado 4 fichas
				{
					while (mat[y][x] == 0 && n<4)		// casilla vacía
					{
						mueve(x, y, d);				// hacer sitio
						n++;						// una menos
					}
					if (x>0)			// ante la primera no puede haber igual
					{
						if (mat[y][x] == mat[y][x-1])	// iguales juntas
						{
							mat[y][x-1] *= 2;			// almacena doble valor
							puntos += mat[y][x-1];		// añade al tanteo
							mueve(x, y, d);				// y elimina la repetida
							n++;						// otra menos
						}
					}
					x++;				// siguiente fila
				}
				z += n;					// contabiliza desplazamientos
			}
			break;
		case 'd':	// derecha
		case 'D':
			for (y=0; y<4; y++)			// para cada fila...
			{
				x=3;					// columna inicial
				n=0;					// fichas desaparecidas
				while (x-n >= 0)		// retrocede hasta haber procesado 4 fichas
				{
					while (mat[y][x] == 0 && n<4)	// casilla vacía
					{
						mueve(x, y, d);				// hacer sitio
						n++;						// una menos
					}
					if (x<3)			// tras la última no puede haber igual
					{
						if (mat[y][x] == mat[y][x+1])	// iguales juntas
						{
							mat[y][x+1] *= 2;			// almacena doble valor
							puntos += mat[y][x+1];		// añade al tanteo
							mueve(x, y, d);				// y elimina la repetida
							n++;						// otra menos
						}
					}
					x--;				// siguiente fila
				}
				z += n;					// contabiliza desplazamientos
			}

			break;
		case 'x':	// abajo (revisar)
		case 'X':
			for (x=0; x<4; x++)			// para cada columna...
			{
				y=3;					// fila inicial
				n=0;					// fichas desaparecidas
				while (y-n >= 0)		// retrocede hasta haber procesado 4 fichas
				{
					while (mat[y][x] == 0 && n<4)	// casilla vacía
					{
						mueve(x, y, d);				// hacer sitio
						n++;						// una menos
					}
					if (y<3)			// tras la última no puede haber igual
					{
						if (mat[y][x] == mat[y+1][x])	// iguales juntas
						{
							mat[y+1][x] *= 2;			// almacena doble valor
							puntos += mat[y+1][x];		// añade al tanteo							
							mueve(x, y, d);				// y elimina la repetida
							n++;						// otra menos
						}
					}
					y--;				// fila anterior
				}
				z += n;					// contabiliza desplazamientos
			}
			break;
		default:	// tecla errónea
			printf("***Dirección equivocada***\n");
	}
	if (!z)		printf("\nNo se puede mover en esa dirección\n");
	
	return z;
}

void mueve(int x, int y, char d)	// desplaza fichas solapando una
{
	int i;			// bucle genérico

	switch(d)
	{
		case 'w':	// arriba
		case 'W':
			for (i=y+1; i<4; i++)			// ficha origen
				mat[i-1][x] = mat[i][x];	// machaca destino
			mat[3][x] = 0;					// limpia el hueco resultante
			break;
		case 'a':	// izquierda
		case 'A':
			for (i=x+1; i<4; i++)			// ficha origen
				mat[y][i-1] = mat[y][i];	// machaca destino
			mat[y][3] = 0;					// limpia el hueco resultante
			break;
		case 'd':	// derecha
		case 'D':
			for (i=x-1; i>=0; i--)			// ficha origen
				mat[y][i+1] = mat[y][i];	// machaca destino
			mat[y][0] = 0;					// limpia el hueco resultante
			break;
		case 'x':	// abajo
		case 'X':
			for (i=y-1; i>=0; i--)			// ficha origen
				mat[i+1][x] = mat[i][x];	// machaca destino
			mat[0][x] = 0;					// limpia el hueco resultante
			break;	// no estrictamente necesario
	}
}

int posible(void)			// determina se se puede seguir jugando
{
	int n=0;	// contador de vacías o iguales
	int i, j;	// bucles genéricos
	
	for (i=0; i<4; i++)					// explora por filas
	{
		if (mat[i][0] == 0)		n++;	// si al menos la primera columna está vacía
		for (j=1; j<4; j++)				// columnas (excepto primera)
		{
			if (mat[i][j] == mat[i][j-1])		n++;	// en caso de vecinas iguales
			if (mat[i][j] == 0)					n++;	// en caso de casilla vacía
			if (mat[j][i] == mat[j-1][i])		n++;	// busca vecinas iguales, por columnas
		}
	}
	
	return n;	// cero si no se puede seguir
}
