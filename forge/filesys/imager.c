/* minimOS disk imager v0.3            *
 * (c) 2021-2022 Carlos J. Santisteban *
 * last modified 20210129-1428         *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* type definitions */
struct	imagen {
	char*	byte;
	long	size;
	char	dirty;
};

struct cabecera {
	char	tipo[2];
	char	extra[4];
	char	nombre[240];
	char	coment[240];
	int		year;
	int		mes;
	int		dia;
	int		hora;
	int		minuto;
	int		segundo;
	long	sgte;
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
ERR		discard(PIM ptr);
ERR		r_sector(char *sec, struct cabecera* c);
ERR		w_sector(char *sec, struct cabecera* c);

/* main loop */
int main(void) {
	int				opc, err;
	long			kb;
	char			nom[80];
	struct imagen	rd;
	
	struct cabecera c;
	
	printf("%ld\n",sizeof(c));

	rd.byte = NULL;			/* object intialisation */
	rd.size = 0;			/* just in case */
	rd.dirty = 0;			/* nothing to save yet */

	printf("\nminimOS disk image manager v0.2");
	printf("\n===============================\n");
	do {
		opc=menu();
		switch(opc) {
			case 1:					/* create image in RAM */
				discard(&rd);		/* check current image */
				printf("How many kiB? ");
				scanf("%ld", &kb);	/* will be multiplied by 1024 */
				printf("Volume name: ");
				scanf("%s", nom);
				if (create(&rd, kb<<10, nom)) {
					printf("*** Error: not enough memory ***\n");
				}
				break;
			case 2:					/* open image from disk */
				discard(&rd);		/* check current image */
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
				break;
			case 0:			/* exit, but check for unsaved image */
				if (rd.dirty)	opc=discard(&rd);
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
	int				i = 0;
	struct cabecera	c;

	ptr->byte = (char*)malloc(tama);	/* allocate RAM */
	if (ptr->byte == NULL)	return -2;	/* ** not enough memory ** */
	ptr->size = tama;
	ptr->dirty = 1;
/* create minimOS header */
	memcpy(c.tipo, "aV", 2);
	memcpy(c.extra, "****", 4);			/* does this include volume size? */
	strcpy(c.nombre, nom);
	c.coment[0]='\0';
/* to do the rest of the header */
/* create header as start sector */
	w_sector(ptr->byte, &c);

	return	0;
}

ERR	open(PIM ptr, char *nom) {
	FILE*	im;
	long	tama;
	ERR		err;
//	char	vol[80];

	im = fopen(nom, "rb");
	if (im == NULL) {
		return -1;					/* ** no file ** */
	}
	fseek(im, 0, SEEK_END);			/* check file length */
	tama = ftell(im);
/*	fseek(im, 8, SEEK_SET);			/* check volume name */
/*	fgets(vol, 80, im);				/* no need as will be overwritten */
	rewind(im);
	err = create(ptr, tama, "\0");	/* allocate RAM */
	if (err) {
		fclose(im);
		return err;					/* ** not enough memory ** */
	}
	fread(ptr->byte, sizeof(char), tama, im);	/* load whole file into RAMdisk */
	fclose(im);
	ptr->dirty = 1;

	return 0;
}

ERR	dir(PIM ptr) {
	printf("Volume: %s\n", &(ptr->byte[8]));

	return 0;
}

ERR	close(PIM ptr, char* nom) {
	FILE*	im;
	char	chk[80];

	im = fopen(nom, "rb");
	fclose(im);
/* check whether this file already exists */
	if (im != NULL) {
		printf("-- File exists. Overwrite? (y/n): ");
		scanf("%s", chk);
		if ((chk[0]|32) != 'y') {
			return -3;
		}
	}
/* ** return -3 means no overwriting, same code if cannot open file for write ** */
/* proceed to write */
	im = fopen(nom, "wb");
	if (im == NULL)		return -3;			/* ** couldn't write ** */
	fwrite(ptr->byte, 1, ptr->size, im);	/* save whole file into RAMdisk */
	fclose(im);
	ptr->dirty = 0;

	return 0;
}

ERR	insert(PIM ptr, char* nom) {
	if (ptr->byte == NULL)	return -5;
	ptr->dirty = 1;

	return 0;
}

ERR	delete(PIM ptr, char* nom) {
	if (ptr->byte == NULL)	return -6;
	ptr->dirty = 1;
	return 0;
}

ERR	extract(PIM ptr, char* nom) {
	if (ptr->byte == NULL)	return -6;
	return 0;
}

ERR	discard(PIM ptr) {
	char	chk[80];

	if (ptr->byte != NULL) {
		printf("-- Image in use. Discard? (y/n): ");
		scanf("%s", chk);
		if ((chk[0]|32) == 'y') {
			free(ptr->byte);
			ptr->byte = NULL;
			ptr->dirty = 0;
			return 0;		/* ** image was discarded ** */
		}
	}

	return -4;				/* ** NOT discarded, operation aborted ** */
}

ERR		w_sector(char *sec, struct cabecera* c) {
	int 			i=0, j=0;
	unsigned int	hora, fecha;

	sec[0] = 0;								/* minimOS header ID */
	sec[7] = 13;
	memcpy(&(sec[1]), c->tipo, 2);			/* type and value signature */
	memcpy(&(sec[3]), c->extra, 4);
	while(c->nombre[i++]!='\0');			/* i is name length, incl. term */
	while(c->coment[j++]!='\0');			/* j is comment length, incl. term */
	if (i+j>240) 	c->coment[239-i]='\0';	/* truncate comment if filename is too long */
	strcpy(&(sec[8]), c->nombre);
	strcpy(&(sec[8+i]), c->coment);
	hora = c->hora << 11;					/* compose timestamp */
	hora |= c->minuto << 5;
	hora |= c->segundo >> 1;
	fecha = (c->year-1980) << 9;			/* compose datestamp */
	fecha |= c->mes << 5;
	fecha |= c->dia;
	memcpy(&(sec[248]), &hora, 2);			/* transfer modified time */
	memcpy(&(sec[250]), &fecha, 2);

	return 0;
}

ERR		r_sector(char *sec, struct cabecera* c) {
	int				i=0;
	unsigned int	hora, fecha;

	if ((sec[0]!=0) || (sec[7]!=13))	return -7;	/* bad header */
	strcpy(c->nombre, &(sec[8]));
	while(c->nombre[i++]!='\0');			/* i is name length, incl. term */
	strcpy(c->coment, &(sec[8+i]));
	memcpy(&hora, &(sec[248]), 2);			/* extract modified time */
	memcpy(&fecha, &(sec[250]), 2);
	c->hora = hora >> 11;					/* decompose timestamp */
	c->minuto = (hora >> 5) & 0b111111;
	c->segundo = (hora & 0b11111) << 1;
	c->year = fecha >> 9;					/* decompose datestamp */
	c->mes = (fecha >> 5) & 0b1111;
	c->dia = fecha & 0b11111;

	return 0;
}
