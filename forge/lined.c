/* line editor for minimOS!
 * v0.5a2
 * (c)2016 Carlos J. Santisteban
 * last modified 20160505-1438 */

/* See more info at http://hughm.cs.ukzn.ac.za/~murrellh/os/notes/ncurses.html */

#include <stdio.h>

#include <stdlib.h>
#include <unistd.h>
#include <termios.h>
#include <string.h>

#define	ctl_g	'\a'
#define	ctl_e	0x5
#define	ctl_x	0x18
#define	cr		'\n'
// cannot use ^S for down, use ^R instead
#define	down	0x14
#define	up		0x17
#define	FALSE	0
#define	TRUE	-1

#define	buffer	512
#define	start	1024

typedef unsigned char byte;
 
byte getch(void) //Dynamic String Input function from Daniweb.com
{ 
    int ch;
    struct termios oldt;
    struct termios newt;
    tcgetattr(STDIN_FILENO, &oldt); /*store old settings */
    newt = oldt; /* copy old settings to new settings */
    newt.c_lflag &= ~(ICANON | ECHO); /* make one change to old settings in new settings */
    tcsetattr(STDIN_FILENO, TCSANOW, &newt); /*apply the new settings immediatly */
    ch = getchar(); /* standard getchar call */
    tcsetattr(STDIN_FILENO, TCSANOW, &oldt); /*reapply the old settings */
    return (byte)ch; /*return received char */
}

byte	ram[65536];
byte	a, x, y;
byte	key, edit;
int		cur, ptr, optr, src, dest, delta, top, zz;

void prev() {
	if (ram[ptr]!='\0') {	// needs leading terminator!!!
		ptr--;					// end of last line
		a = ram[ptr];
		while (a!='\n' && a!='\0') {	// seek for newline or start
			ptr--;							// backwards
		}
		cur--;					// one less line
	} else {
		printf ("{START}\n");	// cannot get back
	}
}

void next() {
	if (ram[ptr]!='\0') {	// not at end already
		ptr++;					// start of this line
		a = ram[ptr];
		while (a!='\n' && a!='\0' && ptr>0) {	// seek for newline or end
			ptr++;									// forth
		}
		cur++;				// one more line
	} else {
		printf ("{END}\n");	// cannot advance
	}
}

void pop() {		// *** copy line into buffer
	x=1;					// leading CR is not to be copied
	a=ram[ptr+x];			// first character
	while (a!='\0' && a!='\n') {	// until newline or end
		ram[buffer-1+x]=a;				// copy character into buffer, notice offset
		x++;
		a=ram[ptr+x];					// next character
	}
	ram[buffer-1+x] = '\0';	// terminate buffer
}

void push() {		// *** copy buffer @ptr
	x=1;					// respect leading CR
	while ((a=ram[buffer-1+x]) != '\0') {	// until buffer is terminated
		ram[ptr+x]=a;							// copy from buffer
		x++;									// next
	}
	ram[ptr+x] = '\n';						// place trailing CR
}

void prompt() {		// *** show cur> and buffer contents
	x=0;
	printf("%04x>", cur);	// ask for current line
	a = ram[buffer+x];		// first char in buffer
	while (a!='\0') {		// until terminated
		putchar(a);				// print it
		x++;
		a = ram[buffer+x];		// next char
	}
}

void move_dn(int s, int d) {
	printf("MOVE_DN %d -> %d\n", s, d);
//************************
	while(s<top) {
		ram[d] = ram[s];
		d++;
		s++;
	}
	
	top = d;
}

void move_up(int s, int d) {
	printf("MOVE_UP %d -> %d\n", s, d);
//***************************
	int		delta = d-s;
	int		tmptr;
	
	tmptr = top;
	top += delta;
	d = top;
	
	while(tmptr>s) {
		ram[d]=ram[tmptr];
		d--;
		tmptr--;
	}

}

byte buflen() {
	x=0;				// reset counter

	while(ram[buffer+x]!='\0') {	// until terminated
		x++;							// there is one more
	}

	return x;			// result
}

void indent() {
	x=1;							// points at first character on current line
	if (a = ram[ptr+x] != '\0') {	// not the end?
		while (a==' ' || a=='\t') {	// while there is whitespace
			ram[buffer-1+x]=a;			// put it on buffer
			x++;
			a = ram[ptr+x];				// next character, do not mess with ptr!
		}
	}
	ram[buffer-1+x]='\0';			// temporary buffer termination
}

void show() {			// *** print cur: and line @ptr, advance ptr! otherwise next()
	a = ram[++ptr];			// check char on next position
	if (!a) {				// already at end?
		printf("{end}\n");		// nothing to do
	} else {
		printf("%04x:", cur);			// non-editing prompt
		while (a!='\n' && a!='\0') {	// until the end of this line
			putchar(a);						// print it
			ptr++;
			a = ram[ptr];					// next char
		}
		cur++;							// would edit next line
		printf("\n");					// line ended
	}
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

void load() {

// preload some content
	int i=0;
	byte texto[10]={"123\n456\0"};	// couple of sample lines
	
	while(ram[start+i]=texto[i]) {
		printf("%c", texto[i]);
		i++;
	}
// continue as usual

	ptr = start;
	cur = 1;
	
	while (ram[ptr]!='\0') {
		if (ram[ptr]=='\n')		cur++;
		ptr++;
	}
	if (ptr==start) {		// no content!
		cur = 0;			// empty doc
	}
	top = ptr;
	printf("{%d bytes, %d lines}\n", ptr-start, cur);
}

int main(void)
{

	load();						// get 'file' and count lines and bytes
	ram[start-1] = 0;			// needs leading terminator!!!!

	edit=FALSE;					// standard mode
	prev();						// get last line
	if (ram[ptr]) {				// not empty?
		indent();					// get whitespace into buffer
		show();						// print it!
	}
	prompt();					// ask for next line
	do {
		key = getch();				//read key

		if (key==0x14) {			//***DEBUG ^T shows all***
			printf("\nCONTENTS:\n");
			for (zz=start; zz<top; zz++)	printf("%c", ram[zz]);
			printf("\n-----\n");
		} else
		
		if (key==ctl_e) {			//***edit previous***
//		printf("Ctl-E ");
			if (cur==0) {				// insert at top
				printf("{start}\n");		// complain
				ram[buffer] = 0;			// empty buffer
			} else {
				edit=TRUE;					// mode: edit existing
				prev();						// go back until CR or begin
				pop();						// copy line into buffer
			}
			prompt();					//print cur> and buffer contents
		} else
		
		if (key==ctl_x) {			//***delete previous***
//		printf("Ctl-X ");
			if (cur==0) {				// no previous line to delete
				printf("{start}\n");		// complain
			} else {
				src=ptr;					// start of current line
				prev();						// back to previous
				move_dn(src,ptr);			// displace...
			}
		} else
		
		if (key==cr) {				//***insert or accept current***
			y=0;
			if (!edit) {				//*insert new line*
				src=ptr+1;					//current is kept
				dest=ptr+buflen()		;	//room for buffer
				move_up(src,dest);
			} else {					//*replace old*
				edit=FALSE;
				optr=ptr;					//save current pos
				next();						//set ptr to next line (advance current size)
//***
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
			prompt();					//show cur> and buffer (indent)
		} else
		
		if (key==up) {		//***show previous***
//		printf("Ctl-W ");
			prev();						// skip pointed buffer...
			prev();						// ...and previous line to show!
			//this should be common
			indent();					// get leading whitespace
			show();						// print cur: and line @ptr, advance ptr! otherwise next()
			prompt();					// show new cur> and buffer (indent)
		} else
		
		if (key==down) {	//***show next if not at end***
//		printf("Ctl-S ");
			//common as above
			indent();					//get leading whitespace
			show();						//print cur: and line @ptr, advance ptr! otherwise next()
			prompt();					//show new cur> and buffer (indent)
		} else
		//should do start & end keys
		//what to do on ESC? common block?
		if (key==ctl_g) {			//***goto line***
//		printf("Ctl-G ");
			dest = ask();					// prompt for line number
			ptr = start;					// eeeeeeek!
			cur = 0;
			for(zz=0;zz<dest;zz++) {
//				optr=ptr;					//keep old pos
				next();						// advance one line
//***cannot mess with cur!!!!!
				if (!ram[ptr])	break;		//abort at end
			}
//			ptr=optr;					//back once, should decr. cur???
			//common as above
			indent();					// get leading whitespace
			show();						// print cur: and line @ptr, advance ptr! otherwise next()
			prompt();					// show new cur> and buffer (indent)
		} else
		
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
