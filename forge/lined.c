/* line editor for minimOS!
 * v0.5a1
 * (c)2016 Carlos J. Santisteban
 * last modified 20160503-1505 */

#include <stdio.h>

#define	ctl_g	'\a'
#define	ctl_e	0x5
#define	ctl_x	0x18
#define	cr		'\n'
#define	down	0x13
#define	up		0x17
#define	FALSE	0
#define	TRUE	-1


typedef unsigned char byte;

byte	ram[65536];
byte	a, x, y;
byte	key, edit;
int	cur, ptr, optr, src, dest, delta, top;
int	buffer=512;

void prev() {
//	printf("(PREV)\n");

	if (ram[ptr]!='\0') {    // needs leading terminator at ptr=0
		ptr--;
		a = ram[ptr];
		while (a!='\n' && a!='\0' && ptr>0) {
			ptr--;
		}
	} else {
                printf ("{start}\n");
        }
}

void pop() {		//copy line into buffer
//	printf("(POP)\n");
	x=1;

	a=ram[ptr+x];
	while (a!='\0' && a!='\n') {
		ram[buffer-1+x]=a;
		x++;
		a=ram[ptr+x];
	}
	ram[buffer-1+x] = '\0';
}

void prompt() {
//	printf("(PROMPT)\n");
	x=0;

	printf("%04x>", cur);
	a = ram[buffer+x];
	while (a!='\0') {
		putchar(a);
		x++;
		a = ram[buffer+x];
	}
}

void move_dn(int s, int d) {
	printf("MOVE_DN %d -> %d\n", s, d);

}

void move_up(int s, int d) {
	printf("MOVE_UP %d -> %d\n", s, d);

}

byte buflen() {
//	printf("(BUFLEN)\n");
	x=0;

	while(ram[buffer+x]!='\0') {
		x++;
	}

	return x;
}

void push() {		//copy buffer @ptr
//	printf("(PUSH)\n");
	x=1;

	while ((a=ram[buffer-1+x]) != '\0') {
		ram[ptr+x]=a;
		x++;
	}
	ram[ptr+x] = '\n';
}

void indent() {
//	printf("(INDENT)\n");
	x=0;

	if (ram[ptr] != '\0') {		// not the end? *****revise
		ptr++;
		a = ram[ptr];
		while (a==' ' || a=='\t') {
			ram[buffer+x]=a;
			x++;
			ptr++;
			a = ram[ptr];
		}
	}
	ram[buffer+x]='\0';
}

void next() {
//	printf("(NEXT)\n");

	if (ram[ptr]!='\0') {
		ptr++;
		a = ram[ptr];
		while (a!='\n' && a!='\0' && ptr>0) {
			ptr++;
		}
	} else {
                printf ("{END}\n");
        }
}

void show() {			//print cur: and line @ptr, advance ptr! otherwise next()
//	printf("(SHOW)\n");

	printf("%04x:", cur);
	a = ram[ptr];
	while (a!='\n' && a!='\0') {
		putchar(a);
		ptr++;
		a = ram[ptr];
	}
	printf("\n");
}

int ask() {
	int i;

	printf("Line: ");
	scanf("%d", &i);

	return i;
}

byte valid(byte k) {
	printf("(VALID %c)\n", k);
	if (k=='\t' || ('a'<=k && k<='z') || ('A'<=k && k<='Z') || ('0'<=k && k<='9'))
		return TRUE;
	else
		return FALSE;
}

int main(void)
{
	cur = 0;
//	top = 1024;
	ptr = 1024;
	ram[ptr]='\0';
	ram[buffer]='\0';

	edit=FALSE;
	pop();
	prompt();
	do {
		key = getchar_unlocked();			//read key
		if (key==ctl_e) {			//***edit previous***
			if (cur>0)		cur--;
			edit=TRUE;					//mode: edit existing
			prev();						//go back until CR or begin
			pop();						//copy line into buffer
			prompt();					//print cur> and buffer contents
		}
		if (key==ctl_x) {			//***delete previous***
			if (cur>0) {				//none if empty
				src=ptr;					//start of current line
				prev();						//back to previous
				move_dn(src,ptr);			//displace
				cur--;
			}
		}
		if (key==cr) {				//***insert or accept current***
			y=0;
			if (!edit) {				//*insert new line*
				src=ptr;					//current is kept
				dest=ptr+buflen()		;	//room for buffer
				move_up(src,dest);
			} else {					//*replace old*
				edit=FALSE;
				optr=ptr;					//save current pos
				next();						//set ptr to next line (advance current size)
				delta=optr+buflen()-ptr;	//new vs old length
				if (delta>0) {				//now is longer
					move_up(optr,optr+delta);	//get extra room
				} else if (delta<0) { 		//now is shorter
					move_dn(optr+delta,optr);	//shrink
				}							//don't move if same length
				ptr=optr;					//retrieve
			}
			push();						//copy buffer @ptr
			indent();					//copy leading whitespace into buffer and terminate it
			next();						//point to next
			cur++;
			prompt();					//show cur> and buffer (indent)
		}
		if (key==up && cur>1) {		//***show previous***
			cur-=2;
			prev();
			//this should be common
			indent();					//get leading whitespace
			show();						//print cur: and line @ptr, advance ptr! otherwise next()
			cur++;
			prompt();					//show new cur> and buffer (indent)
		}
		if (key==down && ram[ptr]) {	//***show next if not at end***
			//common as above
			indent();					//get leading whitespace
			show();						//print cur: and line @ptr, advance ptr! otherwise next()
			cur++;
			prompt();					//show new cur> and buffer (indent)
		}
		//should do start & end keys
		//what to do on ESC? common block?
		if (key==ctl_g) {			//***goto line***
			dest=ask();					//prompt for line number
			ptr=0;						//eeeeeeek!
			for(cur=0;cur<dest;cur++) {
				optr=ptr;					//keep old pos
				next();						//advance one line
				if (!ram[ptr])	break;		//abort at end
			}
			ptr=optr;					//back once, should decr. cur???
			//common as above
		}
		if (valid(key)) {			//***including tabs shown raw***
			//edit like READLN in raw
			//don't manage CR/ESC
			putchar(key);
			ram[buffer+y]=key;
			y++;
		}
	} while(-1);				// loop forever

	return 0;
}
