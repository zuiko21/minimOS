/* minimOS disk imager v0.2       *
 * (c) 2021 Carlos J. Santisteban *
 * last modified 20210121-2024    *
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
ERR		create(PIM ptr, long tama, char *nom);
ERR		open(PIM ptr, char *nom);
ERR		dir(PIM ptr);
ERR		close(PIM ptr, char* nom);
ERR		insert(PIM ptr, char* nom);
ERR		delete(PIM ptr, char* nom);
ERR		extract(PIM ptr, char* nom);

/* main loop */
int main(void) {
	int				opc, err;
	long			kb;
	char			nom[80];
	struct imagen	rd;

	rd.byte = NULL;			/* object intialisation */
	rd.size = 0;			/* just in case */

	printf("\nminimOS disk image manager v0.2");
	printf("\n===============================\n");
	do {
		opc=menu();
		switch(opc) {
			case 1:			/* create image in RAM */
				if (rd.byte != NULL) {
					printf("*** Error: one image is open ***\n");
				} else {
					printf("How many kiB? ");
					scanf("%ld", &kb);	/* will be multiplied by 1024 */
					printf("Volume name: ");
					scanf("%s", nom);
					if (create(&rd, kb<<10, nom)) {
						printf("*** Error: not enough memory ***\n");
					}
				}
				break;
			case 2:			/* open image from disk */
				if (rd.byte != NULL) {
					printf("*** Error: one image is open ***\n");
				} else {
					printf("Image file: ");
					scanf("%s", nom);
					err = open(&rd, nom);
					if (err == -1) {
						printf("*** Error: no such file ***\n");
					} else if (err == -2) {
						printf("*** Error: not enough memory ***\n");
					} else {
						printf("Loaded %ld bytes\n", rd.size);
						printf("Volume name: %s\n", &(rd.byte[8]));
					}
				}
				break;
			case 3:			/* display image contents */
				if (dir(&rd))	printf("*** Error: no image in use ***\n");
				break;
			case 4:			/* save image to file */
				if (rd.byte != NULL) {
					printf("Save to image file: ");
					scanf("%s", nom);
					err = close(&rd, nom);
					if (err == -3) {
						printf("*** Error: couldn't save image ***\n");
					} else {
						free(rd.byte);
						rd.byte = NULL;
						rd.size = 0;
					}
				} else {
					printf("*** Error: no image to save ***\n");
				}
				break;
			case 5:			/* insert file into image */
				printf("File to insert: ");
				scanf("%s", nom);
				err = insert(&rd, nom);
				break;
			case 6:			/* delete file from image */
				printf("Delete from image, which file? ");
				scanf("%s", nom);
				err = delete(&rd, nom);
				break;
			case 7:			/* extract file from image */
				printf("Extract from image, which file? ");
				scanf("%s", nom);
				err = extract(&rd, nom);
		}
	} while (opc != 0);

	return 0;
}

/* function definitions */
int menu(void) {
	int x = -1;
	
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

ERR	create(PIM ptr, long tama, char *nom) {

	ptr->byte = (char*)malloc(tama);	/* allocate RAM */
	if (ptr->byte == NULL)	return -2;	/* ** not enough memory ** */
	ptr->size = tama;

	return	0;
}

ERR	open(PIM ptr, char *nom) {
	FILE*	im;
	long	tama;
	ERR		err;
	char	vol[80];

	im = fopen(nom, "rb");
	if (im == NULL) {
		return -1;					/* ** no file ** */
	}
	fseek(im, 0, SEEK_END);			/* check file length */
	tama = ftell(im);
	fseek(im, 8, SEEK_SET);			/* check volume name */
	fgets(vol, 80, im);
	rewind(im);
	err = create(ptr, tama, vol);	/* allocate RAM */
	if (err) {
		fclose(im);
		return err;					/* ** not enough memory ** */
	}
	fread(ptr->byte, sizeof(char), tama, im);	/* load whole file into RAMdisk */
	fclose(im);

	return 0;
}

ERR	dir(PIM ptr) {
	return 0;
}

ERR	close(PIM ptr, char* nom) {
	FILE*	im=NULL;
	char	chk[80];

	im = fopen(nom, "r");
	fclose(im);
	if (im != NULL) {			/* file exists */
		printf("-- File exists. Overwrite? (y/n): ");
		scanf("%s", chk);
		if ((chk[0]|32) != 'y') {
			return -3;			/* ** not overwriting ** */
		}
	}
	im = fopen(nom, "wb");
	if (im == NULL)		return -3;	/* ** couldn't write ** */
	fwrite(ptr->byte, sizeof(char), ptr->size, im);	/* save whole file into RAMdisk */
	fclose(im);

	return 0;
}

ERR	insert(PIM ptr, char* nom) {
	return 0;
}

ERR	delete(PIM ptr, char* nom) {
	return 0;
}

ERR	extract(PIM ptr, char* nom) {
	return 0;
}
