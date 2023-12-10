#include <stdio.h>
#include <stdlib.h>

#define	SAMPLES	30720
int main(void) {
	char		name[12] = {"audio0.4bit\0"};
	FILE*		f;
	FILE*		s;
	int			i, c=0;
	u_int8_t	b[SAMPLES];

	f=fopen("dither.wav", "rb");
	if (f==NULL)	return -1;
	else			printf("open OK\n");
	fseek(f, 44, SEEK_SET);

	while(!feof(f)) {
		if (fread(b, SAMPLES, 1, f) != 1)		return -1;
		else								printf("fread OK, ");
		for (i=0; i<SAMPLES; i+=2) {
			b[i>>1] = (b[i] & 0xF0) | (b[i+1]>>4);
		}
		name[5]='0'+ c++;
		s = fopen(name, "wb");
		if (s==NULL)	printf("*** ERROR opening bank %d ***\n", c-1);
		if (fwrite(b, SAMPLES>>1, 1, s) != 1)	printf("*** ERROR writing bank %d ***\n", c-1);
		fclose(s);
		printf("%s OK\n",name);
	}
	fclose(f);
	return 0;
}
