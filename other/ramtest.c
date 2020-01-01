/* ********************************************************
 * ** Verificación de memoria en minimOS 0.4 (sobre SDd) **
 * ********** última modificación: 20171212-0952 **********
 * ********* (c) 2017-2020 Carlos J. Santisteban  *********
 * ******************************************************** */

/* ***** declaración de constantes ***** */
/* offset en página cero usado como puntero indirecto */
#define	Z_USED		2

/* código de error cuando la función acaba exitosamente */
#define	EXIT_OK		0

/* código de error si hay algún fallo en la RAM (haría PANIC en la práctica, valor irrelevante) */
#define	RAM_FAIL	1

/* ***** globales para memoria y registros 6502 ***** */
unsigned char	a, x, y;		/* registros del 6502 */
unsigned char	ram[16384];		/* 16 kiB RAM emulados */

/* *********************************************************************************
 * ***** función para verificar la RAM, devuelve constante con código de error *****
 * ********************************************************************************* */
int	mem_test(void) {
	int		ptr;				/* en realidad se encuentra en ram[Z_USED] (16 bits) */

	ram[Z_USED]		= 0x55;		/* verificar antes la ubicación del puntero */
	ram[Z_USED+1]	= 0xAA;
	a = ram[Z_USED];			/* valor escrito en el LSB */
	if (a != 0x55)	{			/* si no es el esperado, abortar */
		return RAM_FAIL;
	}
	a = a ^ ram[Z_USED+1];		/* XOR de ambos bytes debe salir todo unos */
	a++;						/* sumando uno, pasa a ser todo ceros */
	if (a) {					/* ¡de lo contrario, imposible seguir! */
		return RAM_FAIL;
	}
	y = 4:						/* offset adecuado para el hardware E/S */
	ptr = 0;					/* iniciar puntero */
	a = 0x55;					/* valor inicial a escribir */
	do {
		ram[ptr+y] = a;			/* almacena el valor */
		if (a != ram[ptr+y]) {	/* si es diferente... */
			break;				/* ...puede que estemos fuera de la RAM */
		}
		a = a ^ 0xFF;			/* invertir los bits */
		if (a >= 0x80) {		/* ¿es ahora negativo? */
			continue;			/* en tal caso, repetir una vez más */
		}
		ptr = ptr + 256;		/* siguiente página */
	} while (ptr < 16384);		/* límite absoluto de RAM */
	x = ptr / 256;				/* número de página actual */
	do {
		ptr = ptr - 256;		/* página previa */
		a = ptr / 256			/* obtener número de página y almacenarlo */
		ram[ptr+y] = a;
	} while (a);				/* hasta llegar a la página cero */
	x--;						/* X apunta a la última página */
	ptr = ptr%256 | x*256		/* corrige MSB del puntero asignándole X */
	a = ram[ptr+y];				/* leer el byte almacenado en esa página, es el número más alto de página */
	himem = ++a;
	x = 0xFF;					/* nuevos valores iniciales para probar la página cero */
	a = 0;
	do {
		ram[x--] = a--;			/* ir escribiendo una cuenta descendente (0, 255, 254...) empezando por arriba */
	} while (a);				/* A es 0 cuando se haya hecho toda la página cero */
	x = ram[0xFF];				/* lee el byte escrito en el último byte de la página */
	if (x) {					/* si no es cero, hay mirroring, sólo 128 bytes de RAM */
		himem = 0;
	}
	a = x--;					/* A contendrá el número de bytes, X apuntará al último byte */
	do {
		if (a-- != ram[x--]) {	/* si algún valor escrito no coincide con el esperado, hay un problema */
			return RAM_FAIL;
		}
	} while (a);				/* comprobar hasta agotar todos los bytes */

	return EXIT_OK;				/* si llegó aquí, todo CORRECTO */
}

