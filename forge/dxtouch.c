/* Durango touch utility - CLI version
 * sets file timestamp into header!
 * (C)2023 Carlos J. Santisteban
 * last modified 20231201-1920
 * */

/* Libraries */
#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>
/* optional libraries for timestamp fetching */
#include	<sys/stat.h>
#include	<unistd.h>
#include	<time.h>
/* ***************************************** */

/* Constants */
// bytes per header/page
#define		HD_BYTES	256
// Header offsets
#define		H_MAGIC1	0
#define		H_SIGNATURE	1
#define		H_LOAD		3
#define		H_EXECUTE	5
#define		H_MAGIC2	7
#define		H_NAME		8
#define		H_LIB		230
#define		H_COMMIT	238
#define		H_VERSION	246
#define		H_TIME		248
#define		H_DATE		250
#define		H_SIZE		252
#define		H_MAGIC3	255

/* Custom types */
typedef	u_int8_t		byte;
typedef	u_int16_t		word;
typedef u_int32_t		dword;

struct	header {
	char	signature[2];	// [1-2]
	word	ld_addr;		// [3-4]
	word	ex_addr;		// [5-6]
	char	name[221];		// [8-]
	char	comment[221];	// name and comment together cannot be over 220 chars (plus both terminators)
	char	lib[8];			// [230-237]
	char	commit[8];		// [238-245]
	byte	version;		// [246-247]
	byte	revision;
	char	phase;			// (a)lpha-(b)eta-(R)elease candidate-(f)inal
	byte	build;
	byte	hour;			// [248-249]
	byte	minute;
	byte	second;
	byte	year;			// [250-251]
	byte	month;
	byte	day;
	dword	size;			// [252-254] bytes including this 256-byte header
};

/* Function prototypes */

/* ** main code ** */
int main (int argc, char* argv[]) {
	byte			buffer[HD_BYTES];
	struct header	h;
	FILE*			file;
/* variables for timestamp fetching */
	struct tm*		stamp;
	struct stat		attrib;
/* ******************************** */

	if ((file = fopen(argv[1], "r+b")) == NULL) {
		printf("\n\tFile NOT found\n\n");
		return	-1;
	}
	if (fread(buffer, HD_BYTES, 1, file) != 1) {// get header into buffer
		printf("\n\t*** No header ***\n\n");	// not even space for a header
		fclose(file);
		return	-1;
	}
	if ((buffer[H_MAGIC1]!=0) || (buffer[H_MAGIC2]!=13) || (buffer[H_MAGIC1]!=0)) {
		printf("\n\t*** No valid header, probably NOT a Durango file ***\n");	// EEEEEEEEK
		fclose(file);
		return	-1;
	}
/* timestamp fetching (don't know if it's portable) */
	stat(argv[1], &attrib);
	stamp = localtime(&(attrib.st_mtime));
	h.year			= stamp->tm_year - 80;		// wtf?
	h.month			= stamp->tm_mon + 1;		// WTF?
	h.day			= stamp->tm_mday;
	h.hour			= stamp->tm_hour;
	h.minute		= stamp->tm_min;
	h.second		= stamp->tm_sec;					// is this OK?
/* ************************************************ */
	printf("%d/%d/%d, %02d:%02d\n", h.year+1980, h.month, h.day, h.hour, h.minute);
	buffer[H_TIME]	=	((h.minute << 5) & 0xFF) | (h.second >> 1);
	buffer[H_TIME+1]=	(h.hour << 3) | (h.minute >> 3);		// coded time
	buffer[H_DATE]	=	((h.month << 5) & 0xFF) | h.day;
	buffer[H_DATE+1]=	(h.year << 1) | (h.month >> 3);			// coded date
	rewind(file);						// back to start, as will modify header
	if (fwrite(buffer, HD_BYTES, 1, file) != 1) {
		printf("\n*** FAIL ***\n\n");
	}
	fclose(file);						// done

	return	0;
}
