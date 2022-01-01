// (c) 2021-2022 Carlos J. Santisteban
// píxeles por unidad de mapa
#define	PASO	4
// anchura del sprite en unidades de mapa (actualmente 8 pixels) *** NO USADO?
#define	ANCHO	2
// umbral de redondeo para detectar colisiones
#define	CERCA	PASO/2
// número de fantasmas, aunque muy determinado
#define FANTS	2
// numero de direcciones disponibles, por evitar constantes
#define DIRS	4
// códigos de dirección (mejor que no sea un enum)
#define	MOVER	0
#define	MOVED	1
#define	MOVEL	2
#define	MOVEU	3

struct sprite {
	int		x, y;	// posición en píxeles
	int		dir;	// 0=dcha, 1=abajo, 2=izq, 3=arriba
	// añadir puntero al array de objetos (?)
}

struct sprite pac, gh[FANTS];	// un pacman y dos fantasmas

// laberinto original, celdas de 4x4 píxeles, 0=ocupada, 1=libre, inicializar por columnas!!!
const unsigned short mapa[29][32] = {
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},	// x=0
	{0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,0,0,0,0,1,1,1,1,1,0,1,1,1,1,1,0},	// 1
	{0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,0,0,0,0,1,1,1,1,1,0,1,1,1,1,1,0},	// 2 = 1
	{0,1,1,0,0,1,1,0,1,1,0,0,0,0,1,1,0,0,0,0,1,1,0,1,1,1,1,1,0,1,1,0},	// 3
	{0,1,1,0,0,1,1,0,1,1,0,0,0,0,1,1,0,0,0,0,1,1,0,1,1,1,1,1,0,1,1,0},	// 4 = 3
	{0,1,1,0,0,1,1,0,1,1,0,0,0,0,1,1,0,0,0,0,1,1,0,0,0,0,1,1,0,1,1,0},	// 5
	{0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,0},	// 6
	{0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,0},	// 7 = 6
	{0,1,1,0,0,1,1,0,0,0,0,0,0,0,1,1,0,0,0,0,1,1,0,1,1,0,0,0,0,1,1,0},	// 8
	{0,1,1,0,0,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,0,1,1,0},	// 9
	{0,1,1,0,0,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,0,1,1,0},	// 10 = 9
	{0,1,1,0,0,1,1,0,1,1,0,1,1,0,0,0,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0},	// 11
	{0,1,1,1,1,1,1,0,1,1,1,1,1,0,0,0,0,1,1,0,1,1,1,1,1,0,1,1,1,1,1,0},	// 12
	{0,1,1,1,1,1,1,0,1,1,1,1,1,0,0,0,0,1,1,0,1,1,1,1,1,0,1,1,1,1,1,0},	// 13 = 12
	{0,0,0,0,0,1,1,0,0,0,0,1,1,0,0,0,0,1,1,0,0,0,0,1,1,0,0,0,0,1,1,0},	// 14 (centro)
	{0,1,1,1,1,1,1,0,1,1,1,1,1,0,0,0,0,1,1,0,1,1,1,1,1,0,1,1,1,1,1,0},	// 15 = 13 = 12
	{0,1,1,1,1,1,1,0,1,1,1,1,1,0,0,0,0,1,1,0,1,1,1,1,1,0,1,1,1,1,1,0},	// 16 = 12
	{0,1,1,0,0,1,1,0,1,1,0,1,1,0,0,0,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0},	// 17 = 11
	{0,1,1,0,0,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,0,1,1,0},	// 18 = 10 = 9
	{0,1,1,0,0,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,0,1,1,0},	// 19 = 9
	{0,1,1,0,0,1,1,0,0,0,0,0,0,0,1,1,0,0,0,0,1,1,0,1,1,0,0,0,0,1,1,0},	// 20 = 8
	{0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,0},	// 21 = 7 = 6
	{0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,0},	// 22 = 6
	{0,1,1,0,0,1,1,0,1,1,0,0,0,0,1,1,0,0,0,0,1,1,0,0,0,0,1,1,0,1,1,0},	// 23 = 5
	{0,1,1,0,0,1,1,0,1,1,0,0,0,0,1,1,0,0,0,0,1,1,0,1,1,1,1,1,0,1,1,0},	// 24 = 4 = 3
	{0,1,1,0,0,1,1,0,1,1,0,0,0,0,1,1,0,0,0,0,1,1,0,1,1,1,1,1,0,1,1,0},	// 25 = 3
	{0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,0,0,0,0,1,1,1,1,1,0,1,1,1,1,1,0},	// 26 = 2 = 1
	{0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,0,0,0,0,1,1,1,1,1,0,1,1,1,1,1,0},	// 27 = 1
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}	// 28 = 0
}

// valor a cambiar cada coordenada según dirección
const int dx[DIRS] = {1, 0, -1,  0};
const int dy[DIRS] = {0, 1,  0, -1};
// factores para determinar casilla adyacente del mapa (son de 4x4 mientras que los sprites son de 8x8)
const int fx[DIRS] = {2, 0, -1,  0};
const int fy[DIRS] = {0, 2,  0, -1};
// la otra casilla que hay que comprobar... lo mismo pero cambiando los 0 por 1
const int ax[DIRS] = {2, 1, -1,  1};
const int ay[DIRS] = {1, 2,  1, -1};


/* determinar si el movimiento previsto en esas coordenadas cae en casilla ocupada (0) o libre (1) */
int posible(int x, int y, int dir) {
	int resul;

	resul = mapa[x/PASO+fx[dir]][y/PASO+fy[dir]];	// caso general, +2/-1
	resul &= mapa[x/PASO+ax[dir]][y/PASO+ay[dir]];	// la otra casilla

	return resul;
}

/* leer teclas de dirección, devuelve el valor 0...3 */
int direccion(void) {
	key_poll();
	if (key_hit(KEY_RIGHT))		return MOVER;		// ¿...o debería usar key_is_down()?
	if (key_hit(KEY_DOWN))		return MOVED;
	if (key_hit(KEY_LEFT))		return MOVEL;
	if (key_hit(KEY_UP))		return MOVEU;
}

/* movimiento comecocos */
void mover_come() {
// pac.x, pac.y		coordenadas pacman (añadir [56,16] al mostrar, para que coincida con mapa)
// pac.dir			dirección pacman
	int pm;			// dirección DESEADA pacman

	if (pac.x%PASO || pac.y%PASO) {
		// fuera de intersecciones, mover comecocos según dirección actual
		// *** PROBLEMA: el comecocos no reacciona hasta el cambio de tile, pero en la arcade puede cambiar de sentido SIEMPRE ***
		pac.x += dx[pac.dir];
		pac.y += dy[pac.dir];
	}
	else {
		// ver teclas y, si es factible, cambiar dirección
		pm = direccion();
		if (posible(pac.x, pac.y, pm)) {	// casilla libre
			pac.dir = pm;	// se acepta el movimiento
			// *** debería seleccionar sprite y ajustar 'espejado' *** tal vez según pac.dir, al mostrarlo
		}
		// ver si puede seguir moviéndose, de lo contrario se queda en el sitio
		// *** quizá sacar este if del anterior, dejando sólo el else (como el de los fantasmas) ***
		if (posible(pac.x, pac.y, pac.dir)) {
			pac.x += dx[pac.dir];
			pac.y += dy[pac.dir];
		}
	}
}

/* movimiento fantasmas, devuelve 1  si detecta colisión */
int mover_fant() {
// gh[].x, gh[].y	coordenadas fantasmaS (añadir [56,16] al mostrar)
// gh[].dir;		dirección actual fantasmaS
	int dd;			// dirección DESEADA fantasma
	int opu;		// dirección OPUESTA a la actual, normalmente no se usa, pero...
	int lim;		// por seguridad, no puede explorar más de cuatro direcciones...

	// en este caso, el sprite es igual en todas direcciones
	for (int i=0; i<FANTS; i++) {
		if (!(gh[i].x%PASO || gh[i].y%PASO)) {
			opu = (gh[i].dir+DIRS/2)%DIRS;		// necesita saber la dirección opuesta a la actual, por si tiene que evitarla
			lim = DIRS;		// inicialmente 4
			// decidir movimiento aleatorio y, si es factible, cambiar dirección
			dd = rand()%DIRS;	// aleatorio 0...3, válidos como direcciones
			while (((!posible(gh[i].x, gh[i].y, dd)) || (dd == opu)) && lim--) {	// no es posible girar 180º
				dd++;		// si la dirección sugerida está ocupada (o es la opuesta a la actual), probar otra
				dd %= DIRS;	// sólo índices válidos
			}
			// PROBLEMA: si entra en un callejón sin salida, no puede invertir
			if (!lim) {
				dd = opu;	// forzamos la inversión sólo en este caso
			}
			gh[i].dir = dd;	// esta dirección es siempre válida
		}
		gh[i].x += dx[gh[i].dir];	// en todo caso, mover fantasma
		gh[i].y += dy[gh[i].dir];
		// control de colisiones, ver si ese fantasma está lo bastante cerca del comecocos
		if (((gh[i].x+CERCA)/PASO == (pac.x+CERCA)/PASO) && ((gh[i].y+CERCA)/PASO == (pac.y+CERCA)/PASO)) {
			return 1;		// palmatoria...
		} 
	}
}

/* a la hora de mostrar los sprites:
 * hflip: ...attr1 |= (dir==MOVEL)?ATTR1_HFLIP:0;
 * vflip: ...attr1 |= (dir==MOVEU)?ATTR1_VFLIP:0;
 * selección sprite PacMan: (dir & MOVED)?{row0}:{row1}	// detecta dirección horiz/vert
 * */
