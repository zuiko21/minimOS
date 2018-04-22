/* simple expression evaluator
 * intended for symbolic miniMoDA
 * (c) 2018 Carlos J. Santisteban
 * last modified 20180422-1635
 */

#include <stdio.h>

/* constants */
#define	EXPSIZ	80
#define	STKSIZ	8
#define	TRUE	-1
#define	FALSE	0

/* globals */
char tx[EXPSIZ];	//input buffer
int value;		//final result will be here
int stack[STKSIZ];	//stack contents
int sp=0;		//stack pointer

/* supporting functions */
int push(int x) {	//returns true if OK, false if overflow
	if (sp<STKSIZ) {
		stack[sp++]=x;
		return TRUE;
	} else {
		return FALSE;	//stack overflow
	}
}

int pop(void) {		//returns (unsigned) value or -1 if empty
	if (sp>0) {
		return stack[--sp];
	} else {
		return -1;	//stack was empty
	}
}
/* main code */
int main(void) {
	int pt=0;	//reset cursor
	int num=0;	//a number was just evaluated
	int op;

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
				if (num) {
					op=pop();	//look for pending ops
					if (op==-1)	break;	//empty stack
					if (op<65536) {
						push(op);	//was a number, push it back
					} else {
					   num=FALSE;
					   switch (op>>16) {	//do as stated
//binary ops pop previous value and operate with last
						case '+':
							value = pop() + value;
							break;
						case '-':
							value = pop() - value;
							break;
						case '*':
							value = pop() * value;
							break;
						case '/':
							value = pop() / value;
							break;
//unary ops just operate on last value
						case '<':
							value %= 256;
							break;
						case '>':
							value >>= 8;
							break;
					   }
					}
				}
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
				if(!num)	value=0;
				value *= 10;
				value += tx[pt]-'0';
				num = TRUE;
				break;
			case '+':
			case '-':
			case '*':
			case '/':
			case '&':
			case '|':
//it is a binary operator, push previous value and then pending op
				push(value);
				push(tx[pt]<<16);	//shift makes code unreachable
				break;
			case '<':
			case '>':
//it is an unary operator, just push pending op
				push(tx[pt]<<16);	//shift makes code unreachable
				break;
		}
		pt++;
	} while(tx[pt-1]!='\0');
	printf("Result: %d\n",value);

	return 0;
}
