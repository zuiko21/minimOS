/* minimOS disk imager v0.1       *
 * (c) 2021 Carlos J. Santisteban *
 * last modified 20210120-0029    *
 */

#include <stdio.h>
#include <stdlib.h>

/* function prototypes */
int		menu(void);
void	create(void);
void	open(void);
void	dir(void);
void	close(void);
void	insert(void);
void	delete(void);
void	extract(void);

/* main loop */
int main(void) {
	FILE*	im, ext;
	char	nom[80];
	int		opc;
	
	printf("minimOS disk image manager v0.1\n");
	printf("===============================\n\n");
	do {
		opc=menu();
	} while (opc != 0);
	
	return 0;
}

/* function definitions */
int menu(void) {
	int x=-1;
	
	printf("1.Create image\n");
	printf("2.Open image\n");
	printf("3.Show image contents\n");
	printf("4.Close image\n");
	printf("5.Insert file\n");
	printf("6.Delete file\n");
	printf("7.Extract file\n");
	printf("\n0.EXIT\n\n");
	while ((x<0)||(x>7)) {
		printf(">");
		scanf("%d",&x);
	}
	
	return x;
}

void	create(void){
	
}

void	open(void) {
	
}

void	close(void) {
	
}

void	insert(void) {
	
}

void	delete(void) {
	
}

void	extract(void) {
	
}
