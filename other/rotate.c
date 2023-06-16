/* in-situ matrix rotation
 * as requested by Maxim Deryabin
 * (c) 2023 Carlos J. Santisteban
 * */

#include <stdio.h>

 int matrix[20][20];
 int size;				// actual number of elements used
 
 void display(int m[][20], int siz);	// display matrix contents
 void input(int m[][20], int size);		// input matrix elements
 void rotate(int m[][20], int size);	// rotate matrix
 
 int main(void) {
	printf("How many elements? ");
	scanf(" %d", &size);

	input(matrix, size);
	display(matrix, size);

	printf("\n\nHOLD MY BEER...!\n\n");

	rotate(matrix, size);
	display(matrix, size);

	return 0;
}

void display(int m[][20], int n) {
	int i, j;
	for (i=0; i<n; i++) {
		for (j=0; j<n; j++) {
			printf("|");
			if (m[j][i] < 10)	printf(" ");
			printf("%d", m[j][i]);
		}
		printf("|\n");
	}
}

void input(int m[][20], int n) {
	int i, j;
	for (i=0; i<n; i++) {
		for (j=0; j<n; j++) {
			printf("Element (%d,%d)? ", j, i);
			scanf(" %d", &(m[j][i]));
		}
	}
	
}

void rotate(int m[][20], int n) {
	int i, t, buf, old;
	
	for (i=0; i<(n/2); i++) {
		for (t=0; t<(n-2*i-1); t++) {
			buf = m[i+t][i];
			old = m[n-1-i][i+t];
			m[n-1-i][i+t]=buf;
			buf=old;

			old = m[n-1-i-t][n-1-i];
			m[n-1-i-t][n-1-i]=buf;
			buf=old;

			old = m[i][n-1-i-t];
			m[i][n-1-i-t]=buf;
			buf=old;

			m[i+t][i]=buf;
		}
	}

}

