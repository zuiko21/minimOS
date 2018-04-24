/* simple expression evaluator
 * intended for symbolic miniMoDA
 * (c) 2018 Carlos J. Santisteban
 * last modified 20180424-1100
 */
#define	DEBUG	1

#include <stdio.h>

/* constants */
#define	EXPSIZ	80
#define	STKSIZ	8
#define	TRUE	-1
#define	FALSE	0

/* globals */
char tx[EXPSIZ];	//input buffer
int value;			//final result will be here
int stack[STKSIZ];	//stack contents
int sp=0;			//stack pointer
int pt=0;	//reset cursor

/* supporting functions */
int push(int x) {	//returns true if OK, false if overflow
#ifdef	DEBUG
printf("push %d\n",x);
#endif
	if (sp<STKSIZ) {
		stack[sp++]=x;
		return TRUE;
	} else {
		return FALSE;	//stack overflow
	}
}

int pop(void) {		//returns (unsigned) value or -1 if empty
#ifdef	DEBUG
printf("pop @ %d: %d\n",sp,stack[sp-1]);
#endif
	if (sp>0) {
		return stack[--sp];
	} else {
		return -1;	//stack was empty
	}
}

void operation(void) {
	int op = pop();

	if (op==-1) {
#ifdef	DEBUG
printf("No previous value\n");
#endif
		return;		//stack was empty, nothing to do here
	}

	switch (op>>16) {		//convert special code into operator ASCII, numbers will render 0 anyway
// binary operators
		case '+':	//add
			value += pop();
			break;
		case '-':	//subtract
			value = pop()-value;
			break;
		case '*':	//multiply
			value *= pop();
			break;
		case '/':	//divide
			value = pop()/value;
			break;
		case '&':	//bitwise and
			value &= pop();
			break;
		case '|':	//bitwise or
			value |= pop();
			break;
		case '^':	//bitwise xor
			value ^= pop();
			break;
// unary operators
		case '<':	//LSB
			value %= 256;
			break;
		case '>':	//MSB
			value >>=8;
			break;
		default:
#ifdef	DEBUG
printf("OP???\n");
#endif
			push(op);	//non recognised operation, leave stack untouched
	}
#ifdef	DEBUG
printf("Value=%d\n",value);
#endif

}

void getnum(void) {	// evaluate number into value
	value=0;
	while(tx[pt]>='0' && tx[pt]<='9' && tx[pt]!='\0') {	// keep getting numbers
#ifdef	DEBUG
printf("CIPH! ");
#endif
		value *= 10;
		value += (int)(tx[pt]-'0');
#ifdef	DEBUG
printf("(now %d)\n",value);
#endif
		pt++;
	}
}

void operator(void) {
	switch (tx[pt]) {
// binary operators
		case '+':	//add
		case '-':	//subtract
		case '*':	//multiply
		case '/':	//divide
		case '&':	//bitwise and
		case '|':	//bitwise or
		case '^':	//bitwise xor
#ifdef	DEBUG
printf("Binary %c ",tx[pt]);
#endif
			push(value);
			push(tx[pt]<<16);	//special code for operator, cannot be a valid value
			break;
// unary operators
		case '<':	//LSB
		case '>':	//MSB
#ifdef	DEBUG
printf("Unary %c ",tx[pt]);
#endif
			push(tx[pt]<<16);	//no previous value to push
			break;
	}
}

/* main code */
int main(void) {

/* read input */
	fgets(tx, EXPSIZ, stdin);
/* reset stuff */
	value=0;
/* look for values */
	do {
		switch (tx[pt]) {
			case ' ':
			case '\t':
			case '\n':
			case '\0':
//whitespace, do nothing... just check whether a number was done
				operation();	//in case we had postoperand
				break;
			case '0':
			case '1':
			case '2':
			case '3':
			case '4':
			case '5':
			case '6':
			case '7':
			case '8':
			case '9':
//number, evaluate it
				getnum();
				pt--;
				operation();	//check whether there was a pending operation
				break;
			case '+':
			case '-':
			case '*':
			case '/':
			case '&':
			case '|':
			case '^':
			case '<':
			case '>':
//some kind of operator
				operator();	//perhaps needs to push preoperand
				break;
		}
		pt++;
	} while(tx[pt-1]!='\0');
	printf("\n\nResult: %d\nSP: %d\n",value,sp);

	return 0;
}
