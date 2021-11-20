// píxeles por unidad de mapa
#define	PASO	4
// anchura del sprite en unidades de mapa (actualmente 8 pixels)
#define	ANCHO	2
// umbral de redondeo para detectar colisiones
#define	CERCA	PASO/2
// número de fantasmas, aunque muy determinado
#define FANTS	2
// numero de direcciones disponibles, por evitar constantes
#define DIRS	4
// códigos de dirección
#define	MOVER	0
#define	MOVED	1
#define	MOVEL	2
#define	MOVEU	3

char mapa[29][32] = {	// laberinto original, celdas de 4x4 píxeles, 0=ocupada, 1=libre, inicializar por columnas!!!
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,0,0,0,0,1,1,1,1,1,0,1,1,1,1,1,0},
	{0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,1,0,0,0,0,1,1,1,1,1,0,1,1,1,1,1,0},
	{0,1,1,0,0,1,1,0,1,1,0,0,0,0,1,1,0,0,0,0,1,1,0,1,1,1,1,1,0,1,1,0},
	{0,1,1,0,0,1,1,0,1,1,0,0,0,0,1,1,0,0,0,0,1,1,0,1,1,1,1,1,0,1,1,0},
	
// valor a cambiar cada coordenada según dirección
int dx[DIRS] = {1, 0, -1, 0};
int dy[DIRS] = {0, 1, 0, -1};
// factores para determinar casilla adyacente del mapa (son de 4x4 mientras que los sprites son de 8x8)
int fx[DIRS] = {2, 0, -1, 0};
int fy[DIRS] = {0, 2, 0, -1};

int	px, py;	// coordenadas pacman (añadir [56,16] al mostrar, para que coincida con mapa)
int pd;		// dirección pacman
int pm;		// dirección DESEADA pacman
int gx[FANTS], gy[FANTS];	// coordenadas fantasmaS
int gd[FANTS];				// dirección actual fantasmaS
int dd;		// dirección DESEADA fantasma (temporal)

		// movimiento comecocos y posible cambio de dirección según teclas
		if (px%PASO || py%PASO) {
			// fuera de intersecciones, mover comecocos según dirección actual
			px += dx[pd];
			py += dy[pd];
		}
		else {
			// ver teclas y, si es factible, cambiar dirección
			// en el mapa hay que mirar x+2/y+2 o bien x-1/y-1 :-(
			// *** pm=0...3 como futuro pd ***
			if (mapa[px/PASO+fx[pm]][py/PASO+fy[pm]]) {	// casilla libre
				pd = pm;	// se acepta el movimiento
			}
			// ver si puede seguir moviéndose, de lo contrario se queda en el sitio
			if (mapa[px/PASO+fx[pd]][py/PASO+fy[pd]]) {
				px += dx[pd];
				py += dy[pd];
			}
		}
		// hacer algo parecido con LOS fantasmaS, aunque el sprite es igual en todas direcciones
		for (int i=0; i<FANTS; i++) {
			if (!(gx[i]%PASO || gy[i]%PASO)) {
				// decidir movimiento aleatorio y, si es factible, cambiar dirección
				dd = rand()%DIRS;	// aleatorio 0...3, válidos como direcciones
				while (!(mapa[gx[i]/PASO+fx[dd]][gy[i]/PASO+fy[dd]]) || ((dd+DIRS/2)%DIRS == gd[i])) {
					dd++;		// si la dirección sugerida está ocupada (o es la opuesta a la actual), probar otra
					dd %= DIRS;	// sólo índices válidos
				}
				gd[i] = dd;	// esta dirección es siempre válida
			}
			gx[i] += dx[gd[i]];	// en todo caso, mover fantasma
			gy[i] += dy[gd[i]];
			// control de colisiones
			if (((gx[i]+CERCA)/PASO == (px+CERCA)/PASO) && ((gy[i]+CERCA)/PASO == (py+CERCA)/PASO)) {	// suficientemente cerca
				// palmatoria...
			} 
		}
