/* minimOS disk imager v0.1       *
 * (c) 2021 Carlos J. Santisteban *
 * last modified 20210120-1711    *
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

/* global variables */
	FILE*			im;
	unsigned char*	rd = NULL;
	long			siz = 0;

/* main loop */
int main(void) {
	int		opc;

	printf("minimOS disk image manager v0.1\n");
	printf("===============================\n\n");
	do {
		opc=menu();
		switch(opc) {
			case 1:
				create();
				break;
			case 2:
				open();
				break;
			case 3:
				dir();
				break;
			case 4:
				close();
				break;
			case 5:
				insert();
				break;
			case 6:
				delete();
				break;
			case 7:
				extract();
		}
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
	char	nom[80];

	if (rd != NULL) {
		printf("*** Error: one image is open ***\n");
		return;
	}
	printf("Image file: ");		/* ask for a file */
	scanf("%s", nom);
	im = fopen(nom, "rb");
	if (im == NULL) {
		printf("*** Error: no such file ***\n");
		return;
	}
	fseek(im, 0, SEEK_END);		/* check file length */
	siz = ftell(im);
	rewind(im);
	rd = (unsigned char*)malloc(siz);	/* reserve RAM */
	if (rd == NULL) {
		printf("*** Error: not enough memory ***\n");
		fclose(im);
		return;
	}
	fread(rd, 1, siz, im);		/* load whole file into RAMdisk */
	printf("Loaded %ld bytes\n\n", siz);
	fclose(im);
}

void	dir(void) {
	
}
void	close(void) {
	
}

void	insert(void) {
	
}

void	delete(void) {
	
}

void	extract(void) {
	
}
