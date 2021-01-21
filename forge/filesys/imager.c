/* minimOS disk imager v0.2       *
 * (c) 2021 Carlos J. Santisteban *
 * last modified 20210121-1426    *
 */

#include <stdio.h>
#include <stdlib.h>

/* type definitions */
struct	imagen {
	char*	byte;
	long	size;
};

typedef	int				ERR;
typedef	struct imagen*	PIM;

/* function prototypes */
int		menu(void);
PIM		create(long tama);
PIM		open(char *nom);
ERR		dir(PIM fs);
ERR		close(PIM fs, char* nom);
ERR		insert(PIM fs, char* nom);
ERR		delete(PIM fs, char* nom);
ERR		extract(PIM fs, char* nom);

/* global variables */
	FILE*	im;
	char*	rd = NULL;
	long	siz = 0, kb;

/* main loop */
int main(void) {
	int		opc, err;
	char	nom[80];
	struct imagen	rd;

	printf("\nminimOS disk image manager v0.1");
	printf("\n===============================\n");
	do {
		opc=menu();
		switch(opc) {
			case 1:			/* create image in RAM */
				if (rd != NULL) {
					printf("*** Error: one image is open ***\n");
				} else {
					printf("How many kiB? ");
					scanf("%ld", &kb);
					rd = create(kb<<10);	/* multiply by 1024 */
					if (rd == NULL) {
						printf("*** Error: not enough memory ***\n");
					}
				}
				break;
			case 2:			/* open image from disk */
				if (rd != NULL) {
					printf("*** Error: one image is open ***\n");
				} else {
					printf("Image file: ");
					scanf("%s", nom);
					rd = open(nom);
					if (rd == (struct imagen *)-1) {
						printf("*** Error: no such file ***\n");
						rd = NULL;
					} else if (rd == NULL) {
						printf("*** Error: not enough memory ***\n");
					}
					if (rd != NULL) {
						printf("Loaded %ld bytes\n", rd->size);
					}
				}
				break;
			case 3:			/* display image contents */
				if (dir(rd))	printf("*** Error: no image in use ***\n");
				break;
			case 4:			/* save image to file */
				if (rd != NULL) {
					printf("Save to image file: ");
					scanf("%s", nom);
					err = close(rd, nom);
					if (rd == (struct imagen *)-2) {
						printf("*** Error: couldn't save image ***\n");
					} else {
						free(rd);
						rd = NULL;
					}
				} else {
					printf("*** Error: no image to save ***\n");
				}
				break;
			case 5:			/* insert file into image */
				printf("File to insert: ");
				scanf("%s", nom);
				insert(rd, nom);
				break;
			case 6:			/* delete file from image */
				printf("Delete from image, which file? ");
				scanf("%s", nom);
				delete(rd, nom);
				break;
			case 7:			/* extract file from image */
				printf("Extract from image, which file? ");
				scanf("%s", nom);
				extract(rd, nom);
		}
	} while (opc != 0);

	return 0;
}

/* function definitions */
int menu(void) {
	int x=-1;
	
	printf("\n1.Create image\n");
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

PIM	create(long tama) {
	PIM	ptr;

	ptr->byte = (char*)malloc(tama);	/* allocate RAM */
	if (ptr->byte == NULL)				return NULL;
	ptr->size = tama;

	return	ptr;
}

PIM	open(char *nom) {
	PIM	ptr;
	FILE*			im;
	long			tama;

	im = fopen(nom, "rb");
	if (im == NULL) {
		return (struct imagen *)-1;		/* ** no file ** */
	}
	fseek(im, 0, SEEK_END);				/* check file length */
	tama = ftell(im);
	rewind(im);
	ptr = create(tama);					/* allocate RAM */
	if (ptr == NULL) {
		fclose(im);
		return ptr;						/* ** not enough memory ** */
	}
	fread(ptr->byte, sizeof(char), tama, im);	/* load whole file into RAMdisk */
	fclose(im);

	return ptr;
}

ERR				dir(PIM fs) {
	return 0;
}

ERR				close(PIM fs, char* nom) {
	return 0;
}

ERR				insert(PIM fs, char* nom) {
	return 0;
}

ERR				delete(PIM fs, char* nom) {
	return 0;
}

ERR				extract(PIM fs, char* nom) {
	return 0;
}
