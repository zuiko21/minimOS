/* Durango Imager - CLI version
 * (C)2023 Carlos J. Santisteban
 * last modified 20231127-1352
 * */

/* Libraries */
#include	<stdio.h>
#include	<stdlib.h>

/* Constants */
// Max number of files into volume
#define		MAXFILES	100
#define		OPT_OPEN	1
#define		OPT_LIST	2
#define		OPT_ADD		3
#define		OPT_EXTR	4
#define		OPT_DEL		5
#define		OPT_GEN		6
#define		OPT_EXIT	9
#define		OPT_NONE	0

/* Custom types */
typedef	u_int8_t		byte;
typedef	u_int16_t		word;

/* Global variables */
byte*	ptr_h[MAXFILES];	// pointer to dynamically stored header (and file)
int		used;				// actual number of files

/* Function prototypes */
void	init(void);			// Init stuff
void	bye(void);			// Clean up
int		menu(void);			// Show menu and choose action
void	open(void);			// Open volume
void	list(void);			// List volume contents
void	add(void);			// Add file to volume
void	extract(void);		// Extract file from volume
void	delete(void);		// Delete file from volume
void	generate(void);		// Generate volume

/* ** main code ** */
int main (void) {
	int		opt =	OPT_NONE;

	init();					// Init things
// Do actual stuff
	while (opt != OPT_EXIT) {
		opt =	menu();		// choose task
		switch(opt) {
			case OPT_OPEN:	// Open volume
				open();
				break;
			case OPT_LIST:	// List volume contents
				list();
				break;
			case OPT_ADD:	// Add file to volume
				add();
				break;
			case OPT_EXTR:	// Extract file from volume
				extract();
				break;
			case OPT_DEL:	// Delete file from volume
				delete();
				break;
			case OPT_GEN:	// Generate volume
				generate();
				break;
			case OPT_EXIT:
				printf("Exit...\n");
				break;		// just EXIT
			default:
				printf("\n * * * ERROR! * * *\n\n");
		}
	}
	bye();					// Clean up

	return	0;
}

/* ** Function definitions ** */
void init(void) {			// Init stuff
	int		i;

	used =	0;				// empty array, nothing stored in heap
	for (i=0;i<MAXFILES;i++) {
		ptr_h[i] =	NULL;	// reset all empty pointers
	} 
}

void bye(void) {			// Release heap memory * * * VERY IMPORTANT * * *
	int		i =	0;

	while(ptr_h[i]!=NULL) {
		free(ptr_h[i++]);	// release this block
	}
}

int		menu(void) {		// Show menu and choose action
	int		opt;

	printf("\n1.Open volume\n");
	printf("2.List volume contents\n");
	printf("3.Add file to volume\n");
	printf("4.Extract file from volume\n");
	printf("5.Delete file from volume\n");
	printf("6.Generate volume\n");
	printf("==========================\n");
	printf("9.EXIT\n\n");
	printf("Choose option: ");
	scanf("%d", &opt);

	return	opt;
}

void	open(void){			// Open volume
}

void	list(void){			// List volume contents
}

void	add(void){			// Add file to volume
}

void	extract(void){		// Extract file from volume
}

void	delete(void){		// Delete file from volume
}

void	generate(void){		// Generate volume
}
