#define	PASO	32
#define	TILE	8
#define	CERCA	TILE/2
#define	MOVER	0
#define	MOVED	1
#define	MOVEL	2
#define	MOVEU	3

// valor a cambiar cada coordenada según dirección
int dx[4] = {1, 0, -1, 0};
int dy[4] = {0, 1, 0, -1};

int	px, py;	// coordenadas pacman
int pd;		// dirección pacman
int pm;		// dirección DESEADA pacman
int gx, gy;	// coordenadas fantasma
int gd;		// dirección actual fantasma
int dd;		// dirección DESEADA fantasma

		// movimiento comecocos y posible cambio de dirección según teclas
		if (px%PASO || py%PASO) {
			// mover comecocos según dirección actual
			px += dx[pd];
			py += dy[pd];
		}
		else {
			// ver teclas y, si es factible, cambiar dirección
			// pm=10...3 como futuro pd***
			if (mapa[px/PASO+dx[pm]][py/PASO+dy[pm]] == 0) {	// casilla libre
				pd = pm;	// se acepta el movimiento
			}
			// ver si puede seguir moviéndose, de lo contrario se queda en el sitio
			if (mapa[px/PASO+dx[pd]][py/PASO+dy[pd]] == 0) {
				px += dx[pd];
				py += dy[pd];
			}
		}
		// hacer algo parecido con el fantasma, aunque el sprite es igual en todas direcciones
		if (!(gx%PASO || gy%PASO)) {
			// decidir movimiento aleatorio y, si es factible, cambiar dirección
			dd = rand()%4;	// aleatorio 0...3, válidos como direcciones
			while (mapa[gx/PASO+dx[dd]][gy/PASO+dy[dd]]) {
				dd++;		// si la dirección sugerida está ocupada, probar otra
				dd %= 4;	// sólo valores válidos
			}
			gd = dd;	// esta dirección es siempre válida
		}
		gx += dx[gd];	// en todo caso, mover fantasma
		gy += dy[gd];
		// control de colisiones
		if (((gx+CERCA)/TILE == (px+CERCA)/TILE) && ((gy+CERCA)/TILE == (py+CERCA)/TILE)) {	// suficientemente cerca
			// palmatoria...
		} 
