/* *** directivas del compilador y otras definiciones *** */
#include <tonc.h>
#include <string.h>
#include "background.gfx.h"
#include "sprites.gfx.h"
#include <stdlib.h>

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
// código especial (no cambia dirección)
#define	SIGUE	5

/* *** declaración de tipos de datos y estructuras *** */
struct sprite_s {
	int			x;
	int			y;		// posición en píxeles
	int			dir;	// 0=dcha, 1=abajo, 2=izq, 3=arriba
	OBJ_ATTR*	obp;	// añadir puntero al array de objetos
};

// ...del tutorial
// Definir estructura para guardar los datos del juego
struct game_s {
    // Buffer con los metadatos de los sprites
    OBJ_ATTR obj_buffer[128];
    // Tamano del buffer de metadatos de sprites
    int obj_buffer_size;
    // Contador de frames
    u32 frame;
    /* LOGICA DE JUEGO instanciada en cada sprite */
};

/* *** variables y datos globales *** */
// ...del tutorial
// Instanciar en memoria la estructura con los datos del juego
struct game_s game;

// ...del propio juego
struct sprite_s pac, gh[FANTS];	// un pacman y dos fantasmas

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
};

// valor a cambiar cada coordenada según dirección
const int dx[DIRS] = {1, 0, -1,  0};
const int dy[DIRS] = {0, 1,  0, -1};
// factores para determinar casilla adyacente del mapa (son de 4x4 mientras que los sprites son de 8x8)
const int fx[DIRS] = {2, 0, -1,  0};
const int fy[DIRS] = {0, 2,  0, -1};
// la otra casilla que hay que comprobar... lo mismo pero cambiando los 0 por 1
const int ax[DIRS] = {2, 1, -1,  1};
const int ay[DIRS] = {1, 2,  1, -1};

/* *** funciones *** */
/* determinar si el movimiento previsto en esas coordenadas cae en casilla ocupada (0) o libre (1) */
int posible(int x, int y, int dir) {
	int resul;

	resul  =	mapa[x/PASO+fx[dir]][y/PASO+fy[dir]];	// caso general, +2/-1
	resul &=	mapa[x/PASO+ax[dir]][y/PASO+ay[dir]];	// la otra casilla

	return resul;
}

/* leer teclas de dirección, devuelve el valor 0...3 */
int direccion(void) {
	key_poll();
	if (key_is_down(KEY_RIGHT))		return MOVER;		// key_hit() responde muy mal
	if (key_is_down(KEY_DOWN))		return MOVED;
	if (key_is_down(KEY_LEFT))		return MOVEL;
	if (key_is_down(KEY_UP))		return MOVEU;

	return	SIGUE;
}

/* movimiento comecocos */
void mover_come() {
// pac.x, pac.y		coordenadas pacman (añadir [56,16] al mostrar, para que coincida con mapa)
// pac.dir			dirección pacman
	int pm;			// dirección DESEADA pacman

	if ((pac.x%PASO) || (pac.y%PASO)) {
		// fuera de intersecciones, mover comecocos según dirección actual
		// *** PROBLEMA: el comecocos no reacciona hasta el cambio de tile, pero en la arcade puede cambiar de sentido SIEMPRE ***
		pac.x += dx[pac.dir];
		pac.y += dy[pac.dir];
	}
	else {
		// ver teclas y, si es factible, cambiar dirección
		pm = direccion();
		if (pm == SIGUE)	pm = pac.dir;
		if (posible(pac.x, pac.y, pm)) {	// casilla libre
			pac.dir = pm;	// se acepta el movimiento
			// *** debería seleccionar sprite y ajustar 'espejado' *** tal vez según pac.dir, al mostrarlo
		}
		// ver si puede seguir moviéndose, de lo contrario se queda en el sitio
		// *** quizá sacar este if del anterior, dejando sólo el else (como el de los fantasmas) ***
		// *** ...dejando la llamada a direccion() fuera, claro ***
		// *** y sólo el cambio de sentido sería aceptable fuera de la frontera de tiles ***
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
			lim = DIRS+1;		// inicialmente 4 ¿o 5?
			// decidir movimiento aleatorio y, si es factible, cambiar dirección
			dd = rand()%DIRS;	// aleatorio 0...3, válidos como direcciones
			while (((!posible(gh[i].x, gh[i].y, dd)) || (dd == opu)) && --lim) {	// no es posible girar 180º
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
			return 1;		// palmatoria, ni me molesto en mover el otro fantasma
		} 
	}

	return	0;				// si llega aquí, no se ha detectado colisión
}

/* Inicializar posiciones de los sprites */
void partida(void) {
	pac.x = 54;			// centrado, para un sprite de 8x8 EEEEEEEK
	pac.y = 92; 
	pac.dir = MOVEL;	// como en la arcade, el pacman comienza mirando a la izquierda
	
	for (int i=0; i<FANTS; i++) {
		gh[i].x = 64 - (i%2)*20;				// el primero (par) más a la derecha, el otro (impar) más a la izquierda
		gh[i].y = 44;							// pasillo sobre la 'casa'
		gh[i].dir = MOVER+(MOVEL-MOVER)*(i%2);	// el primero (par) mira a la derecha, el otro (impar) a la izquierda
    }
}

void palmatoria(void) {
	int i;				// retardos varios

	for (i=0;i<60;i++) {	// un segundo
		VBlankIntrWait();
	}
// ¿deshabilito fantasmas? al menos pongo encima el pacman
	obj_set_attr(pac.obp, ATTR0_SQUARE, ATTR1_SIZE_32x32,  ATTR2_PALBANK(0)|ATTR2_PRIO(-1)|0);	// encima de todo fantasma ¿admite negativos?
// animación muerte pacman
	for (int j=0;j<5;j++) {	// 5 fotogramas
		// *** mostrar frame correspondiente {row2}
		obj_set_pos(pac.obp, pac.x+56, pac.y+16);	// se supone que ya está, pero bueno
		pac.obp->attr2 = ATTR2_BUILD((j+10)*16, 0, 0); 		// fotograma deseado en tercera fila
		pac.obp->attr1 &= (~ATTR1_HFLIP & ~ATTR1_VFLIP);	// apago las inversiones en todo caso		
		oam_copy(oam_mem, game.obj_buffer, game.obj_buffer_size);	// EEEEEEK
		for (i=0;i<12;i++) {	// tasa de 5 fotogramas/segundo
			VBlankIntrWait();
		}
	}
	for (i=0;i<60;i++) {	// un segundo
		VBlankIntrWait();
	}
// ¿habilito fantasmas de nuevo? o al menos recupero prioridad original
	obj_set_attr(pac.obp, ATTR0_SQUARE, ATTR1_SIZE_32x32,  ATTR2_PALBANK(0)|ATTR2_PRIO(FANTS)|0);
}

// ...del tutorial
// Inicializar datos juego
void init_game() {
	// Inicializar buffer sprites
	oam_init(game.obj_buffer, 128);
	// Inicializar contador tamano buffer sprites
    game.obj_buffer_size=0;
    // Inicializar contador de frames
    game.frame=0;

	partida();		// inicializar datos de los sprites
}

// Cargar fondo
void load_background() {
    memcpy(pal_bg_mem, background_gfxPal, background_gfxPalLen);
    memcpy(&tile_mem[0][0], background_gfxTiles, background_gfxTilesLen);
    memcpy(&se_mem[16][0], background_gfxMap, background_gfxMapLen);
    REG_BG0CNT = BG_CBB(0) | BG_SBB(16) | BG_4BPP | BG_REG_64x32 | BG_PRIO(1);
    REG_BG0HOFS = 0;
    REG_BG0VOFS = 0;
}

// Cargar sprites
void load_sprites() {
    memcpy(pal_obj_mem, sprites_gfxPal, sprites_gfxPalLen);
	memcpy(&tile_mem[4][0], sprites_gfxTiles, sprites_gfxTilesLen);
	// .obp habrá que asignarle algún &game.obj_buffer[ ...
	// *** *** NI IDEA DE LO QUE ESTOY HACIENDO *** ***
	pac.obp = &game.obj_buffer[game.obj_buffer_size++];	// espero que ése esté bien
	obj_set_attr(pac.obp, ATTR0_SQUARE, ATTR1_SIZE_32x32,  ATTR2_PALBANK(0)|ATTR2_PRIO(FANTS)|0);	// ¿PRIO(2) = pacman debajo?
	for (int i=0; i<FANTS; i++) {
		gh[i].obp = &game.obj_buffer[game.obj_buffer_size++];	// ** NI IDEA **
		obj_set_attr(gh[i].obp, ATTR0_SQUARE, ATTR1_SIZE_32x32,  ATTR2_PALBANK(0)|ATTR2_PRIO(FANTS-i-1)|0);	// distinta prioridad
	}
}

/* a la hora de mostrar los sprites:
 * hflip: ...attr1 |= (dir==MOVEL)?ATTR1_HFLIP:0;
 * vflip: ...attr1 |= (dir==MOVEU)?ATTR1_VFLIP:0;
 * selección sprite PacMan: (dir & MOVED)?{row1}:{row0}	// detecta dirección vert/horiz EEEEEK
 * */

// Actualizar y mostar sprites en pantalla ***
void update_sprites() {
	obj_set_pos(pac.obp, pac.x+56-(pac.dir==MOVEL?24:0), pac.y+16-(pac.dir==MOVEU?24:0));			// EEEEEEEEEK
	pac.obp->attr2 = ATTR2_BUILD((game.frame%5+((pac.dir & MOVED)?5:0))*16, 0, 0); // ** NI IDEA ** EEEEK
	pac.obp->attr1 &= (~ATTR1_HFLIP & ~ATTR1_VFLIP);	// apago las inversiones un momento
	pac.obp->attr1 |= (pac.dir==MOVEL)?ATTR1_HFLIP:0;	// a la izquierda, inversión horizontal... pero corrigiendo coordenadas
	pac.obp->attr1 |= (pac.dir==MOVEU)?ATTR1_VFLIP:0;	// hacia arriba, inversión vertical
	// ¿...y los fantasmas?
	for (int i=0; i<FANTS; i++) {
		obj_set_pos(gh[i].obp, gh[i].x+56, gh[i].y+16);	// EEEEEEEEEK
		gh[i].obp->attr2 = ATTR2_BUILD((game.frame%5+(15+i%2*5))*16, 0, 0); // debería funcionar... EEEEK
		// ¿necesitaré ajustar algo en ATTR1? Nunca se invierte
	}
    // Copiar buffer to sprites memory
    oam_copy(oam_mem, game.obj_buffer, game.obj_buffer_size);	// ¿habrá que cambiar algo?
}

// Actualizar datos juego
void update_game() {
	mover_come();		// mueve el pacman, cambiando de dirección si procede
	if (mover_fant()) {	// mueve los fantasmas, comprobando si devuelve posible colisión
		palmatoria();	// animación muerte pacman y ¿vuelta a empezar?
		partida();
	}
}

// Inicializar sistema grafico
void init_display() {
	REG_DISPCNT = DCNT_MODE0 | DCNT_BG0 | DCNT_OBJ | DCNT_OBJ_1D;
}

// Metodo main. Inicio del programa
int main()
{
	// Inicializar interrupciones
	irq_init(NULL);
	// Activar interrupción VBlank
    irq_add(II_VBLANK, NULL);
    
    // Inicializar datos    
	init_game();
	
	// Cargar fondo	
	load_background();
	// Cargar sprites
	load_sprites();
    // Inicializar video
    init_display();
	// un segundo de retardo antes de empezar
	for (int i=0;i<60;i++) {
		VBlankIntrWait();
	}

	// Bucle infinito. No tenemos sistema operativo al que volver
	while(1)
	{
		// Sincronizar con VBlank mediante interrupcion.
		// Esto se hace para evitar modificar la memoria a mitad de un refresco de pantalla.
		// *** si va muy rápido, poner 3 seguidos, por ejemplo
        VBlankIntrWait();
        VBlankIntrWait();
        // Actualizar contador de frames
		game.frame++;
        // Leer botones ya lo hace la función direccion()
//		key_poll();
        // Actualizar datos juego
		update_game();
        // Actualizar sprites
        update_sprites();
	}

	// Nunca llegaremos a este punto. Sólo por cumplir con estandar c
	return 0;
}
