/* opcode list reader for minimOS crasm package
 * (c) 2020 Carlos J. Santisteban
 * last modified 20200225-0915
 * */

#include <stdio.h>

int main(void) {
	FILE*			f;
	unsigned char	c;
	int				i=0;
	
	f=fopen("a.o65","rb");
	if (f==NULL) {
		printf("*** Could not open opcode list ***\n");
	}
	else {
		printf("$0: ");
		while(!feof(f)) {
			c=getc(f);
			if (c!='{') {
				printf("%c", c&127);
			}
			else {
				c=getc(f);
				printf(" >>> %d", c&127);
			}
			if (c&128) {
				printf("\n$%x: ",++i);
			}
		}
		printf(" *** END ***\n");
		fclose(f);
	}
	return 0;
}
