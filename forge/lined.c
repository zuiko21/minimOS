/* line editor for minimOS!
 * v0.5a6
 * (c) 2016-2022 Carlos J. Santisteban
 * last modified 20160511-1421 */

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
// cannot use ^S for down, use ^R instead EEEEEEK
#define	down	0x12
// ^W is up
#define	up		0x17
#define	backspace	0x8
#define	escape	0x1b

#define	FALSE	0
#define	TRUE	-1

#define	buffer	512
#define	start	1024
#define bufsize	80

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

void prev() {					// *** point to previous line
	if (start<ptr) {				// not at the beginning
		ptr--;							// end of last line
		a = ram[ptr];
		while (a!='\n' && a!='\0' && start<ptr) {	// seek for newline or start
			ptr--;							// backwards
			a = ram[ptr];					// eeeeek!
		}
		cur--;							// one less line
	} else {
		printf("\n{START}");			// no way to go back
	}
}

void next() {					// *** point to next line
	if (ptr<top) {					// not at end already
		ptr++;							// start of this line
		a = ram[ptr];
		while (a!='\n' && a!='\0' && ptr<top) {	// seek for newline or end
			ptr++;							// forth
			a = ram[ptr];					// eeeeek!
		}
		cur++;							// one more line
	} else {
		printf ("\n{END}");				// cannot advance
	}
}

void pop() {					// *** copy line into buffer
	x=1;							// leading CR is not to be copied
	a=ram[ptr+1];					// first character
	while (a!='\0' && a!='\n') {	// until newline or end
		ram[buffer-1+x]=a;				// copy character into buffer, notice offset
		x++;
		a=ram[ptr+x];					// next character
	}
	ram[buffer-1+x] = '\0';			// terminate buffer
}

void push() {					// *** copy buffer @ptr, and increase pointer
	x=0;							// reset index
	a=ram[buffer];					// first character
	while (a != '\0') {				// until buffer is terminated
		ptr++;							// should increase too!
		ram[ptr]=a;						// copy from buffer
		x++;
		a=ram[buffer+x];				// next character
	}
	ram[++ptr] = '\n';				// place trailing CR
}

void prompt() {					// *** show cur> and buffer contents
	x=0;							// reset index
	printf("\n%04x>", cur);			// ask for current line
	a = ram[buffer];				// first char in buffer
	while (a!='\0') {				// until terminated
		if (a!='\t') {
			putchar(a);						// print it
		} else {
			putchar('~');					// tab replacement
		}
		x++;
		a = ram[buffer+x];				// next char
	}
	y = x;							// eeeeeek
}

void move_dn(int s, int d) {
	int		delta=s-d;	// eeeeeeek

	while(s <= top) {
		ram[d] = ram[s];
		d++;
		s++;
	}
	
	top -= delta;
}

void move_up(int s, int d) {

	int		delta = d-s;
	int		tmptr;
	
	tmptr = top;
	top += delta;
	d = top;
	
	while(tmptr >= s) {
		ram[d] = ram[tmptr];
		d--;
		tmptr--;
	}
}

byte buflen() {					// *** return buffer length
	x=0;							// reset counter

	while(ram[buffer+x]!='\0') {	// until terminated
		x++;							// there is one more
	}

	return x;						// result
}

void indent() {					// *** copy leading whitespace into buffer
	x=1;							// points at first character on current line
	a = ram[ptr+1];					// get first char
	while (a==' ' || a=='\t') {		// while there is whitespace
		ram[buffer-1+x]=a;				// put it on buffer, note offset
		x++;
		a = ram[ptr+x];					// next character, do not mess with ptr!
	}
	ram[buffer-1+x]='\0';				// temporary buffer termination
}

void show() {					// *** print cur: and line @ptr, advance ptr!
	if (top<=ptr) {					// already at end?
		printf("\n{end}");				// complain
	} else {
		ptr++;							// first char in line
		a = ram[ptr];					// check char
		printf("\n%04x:", cur);			// non-editing prompt
		while (a!='\n' && a!='\0') {	// until the end of this line
			putchar(a);						// print it
			ptr++;
			a = ram[ptr];					// next char
		}
		cur++;							// would edit next line
	}
}

void all() {					// *** show all contents ***
	printf("\n\nCONTENTS:\n");
	for (zz=start; zz<top; zz++)	printf("%c", ram[zz]);
	printf("\n-----");
}	
	
int ask() {						// *** ask for a line number to jump at
	int i;

	printf("\nLine: ");
	scanf("%d",&i);

	return i;
}

byte valid(byte k) {			// *** check whether it is printable or not
	if ((k=='\t') || (' '<=k))		// eeeeek
		return TRUE;
	else
		return FALSE;
}

void load() {					// *** check current 'file' and go to its end

// ********preload some content*********
	int i=0;
	byte texto[80]={"\0"};	// couple of sample lines
	
	while(ram[start+i]=texto[i]) {
		printf("%c", texto[i]);
		i++;
	}
// *********continue as usual*********/

	ptr = start;				// initial values for debugging
	cur = 1;					// at least one line unless empty
	
	while (ram[ptr]!='\0') {	// until the end
		if (ram[ptr]=='\n')		cur++;	// found a newline
		ptr++;
	}
	if (ptr==start) {			// no content!
		cur = 0;					// empty doc
	}
	top = ptr;					// position of TRAILING terminator
	printf("{%d bytes, %d lines}\n", ptr-start, cur);
}

int main(void)
{
	load();						// get 'file' and count lines and bytes
	ram[start-1] = 0;			// needs leading terminator!!!! Might go into load()

	edit=FALSE;					// standard mode
	if (start<ptr) {			// not empty?
		prev();						// get last line
		indent();					// get whitespace into buffer
		show();						// print it!
		cur--;						// eeeeek
	} else {
		ram[buffer]='\0';		// eeeeek
	}
	prompt();					// ask for next line
	do {
		key = getch();				// read key

		switch(key) {				// compare values...
		case 0x14: 					//***DEBUG ^T shows all*** will become a regular command
			all();						// show all
			prompt();
			break;
		case ctl_e:					//***edit previous***
			if (ptr==start) {				// insert at top
				printf("\n{start}");		// complain
				ram[buffer] = 0;			// empty buffer
			} else {
				if (!edit) {				// was not already editing?
					prev();						// go back until CR or begin
					edit=TRUE;					// mode: edit existing
				}
				pop();						// copy line into buffer
			}
			prompt();					//print cur> and buffer contents
			break;
		case ctl_x:					//***delete previous***
			if (cur==0) {				// no previous line to delete
				printf("\n{start}");		// complain
				ram[buffer]='\0';
			} else {
				optr=ptr;					// remember from where
				prev();						// beginning of previous line to be deleted
				move_dn(optr+1,ptr+1);		// move down
				prev();						// let us see what we have above
				if (start<ptr) {			// not the first one
//					cur++;
					indent();					// get leading whitespace on buffer
					show();						// return, or just next???
				}
			}
			prompt();					// ready to insert another
			break;
		case cr:					//***insert or accept current***
			ram[buffer+y] = '\0';		// eeeeeeeek
			if (!edit) {				//*insert new line*
				src=ptr+1;					// current is kept
				dest=src+buflen()+1		;	// room for buffer
				move_up(src,dest);
				cur++;						// eeeeeeek
			} else {					//*replace old*
				edit=FALSE;
				optr=ptr;					//save current pos
				next();						//set ptr to next line (advance current size)
				delta=buflen()+1-(ptr-optr);	//new vs old length
				if (delta>0) {				//now is longer
					move_up(optr,optr+delta);	//get extra room
				} else if (delta<0) { 		//now is shorter
					move_dn(ptr,ptr+delta);	//shrink! eeeek!
				}							//don't move if same length
				ptr=optr;					//retrieve
			}
			push();						//copy buffer @ptr plus trailing CR
			// common block
			prev();						// have a look at last line!
			indent();					//copy leading whitespace into buffer and terminate it
			next();						// just after recent line, no need to show?
			prompt();					//show cur> and buffer (indent)
			break;
		case up:					//***show previous***
			if (ptr<=start) {			// empty???
				printf("\n{start}");		// cannot go back!
				ram[buffer]='\0';			// clear buffer
				cur = 0;					// just in case...
			} else {
				prev();						// skip pointed buffer...
				prev();						// ...and previous line to show!
				//this should be common
				indent();					// get leading whitespace
				show();						// print cur: and line @ptr, advance ptr! otherwise next()
			}
			prompt();					// show new cur> and buffer (indent)
			break;
		case down:					//***show next if not at end***
			//common as above
			indent();					//get leading whitespace
			show();						//print cur: and line @ptr, advance ptr! otherwise next()
			prompt();					//show new cur> and buffer (indent)
			break;
		//************ should do start & END keys ******************
		case ctl_g:					//***goto line***
			dest = ask();					// prompt for line number
			ptr = start;					// eeeeeeek!
			cur = 0;
			for(zz=0;zz<dest;zz++) {
				next();						// advance one line
				if (!ram[ptr])	break;		//abort at end
			}
			key=0;							// why???
			if (ptr==start) {				// at start, no whitespace to take
				ram[buffer]='\0';
			} else {
				indent();					// get leading whitespace
				show();						// print cur: and line @ptr
			}
			prompt();					// show new cur> and buffer (indent)
			break;
		case escape:
			ram[buffer]='\0';				// clear buffer
			prompt();					// will reset y
			break;
		case backspace:
			if (0<y) {				// something in buffer
				y--;					// delete char in buffer
				printf("\b \b");		// also on screen
			}
			break;
		default:					// manage regular typing
			if (valid(key) && y<bufsize) {			//***put keystroke in buffer
				if (key=='\t') {				// tabs made printable
					putchar('~');					// desired substitution
				} else {
					putchar(key);					// print typed
				}
				ram[buffer+y]=key;				// store in buffer
				y++;
			}
		}
	} while(-1);				// loop forever

	return 0;
}
