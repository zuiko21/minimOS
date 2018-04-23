/* simple expression evaluator
 * intended for symbolic miniMoDA
 * (c) 2018 Carlos J. Santisteban
 * last modified 20180423-1356
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
int value;		//final result will be here
int stack[STKSIZ];	//stack contents
int sp=0;		//stack pointer

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

void getnum(void) {	// evaluate number into value
	while(tx[pt]>='0' && tx[pt]<='9' && tx[pt]!='\0') {	// keep getting numbers
#ifdef	DEBUG
printf("CIPH! ");
#endif
#ifdef	DEBUG
if(num==FALSE)	printf("Reset...");
#endif
		if(num==FALSE)	value=0;
#ifdef	DEBUG
printf("(was %d) ",value);
#endif
		value *= 10;
		value += (int)(tx[pt]-'0');
#ifdef	DEBUG
printf("(now %d)\n",value);
#endif
				num = TRUE;
		pt++;
	}
}

/* main code */
int main(void) {
	int pt=0;	//reset cursor
	int num=FALSE;	//a number was just evaluated
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
#ifdef	DEBUG
printf("WS-NUM (value=%d)\n",value);
#endif
					op=pop();	//look for pending ops
					if (op==-1)	break;	//empty stack
					if (op<65536) {
						push(op);	//was a number, push it back
					} else {
#ifdef	DEBUG
printf("pending OP...");
#endif

					   num=FALSE;
					   switch (op>>16) {	//do as stated
//binary ops pop previous value and operate with last
						case '+':
							value = pop() + value;
#ifdef	DEBUG
printf("...+ (now %d)\n",value);
#endif
							break;
						case '-':
							value = pop() - value;
#ifdef	DEBUG
printf("...- (now %d)\n",value);
#endif
							break;
						case '*':
							value = pop() * value;
#ifdef	DEBUG
printf("...* (now %d)\n",value);
#endif
							break;
						case '/':
							value = pop() / value;
#ifdef	DEBUG
printf(".../ (now %d)\n",value);
#endif
							break;
//unary ops just operate on last value
						case '<':
							value %= 256;
#ifdef	DEBUG
printf("...< (now %d)\n",value);
#endif
							break;
						case '>':
							value >>= 8;
#ifdef	DEBUG
printf("...> (now %d)\n",value);
#endif
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
#ifdef	DEBUG
printf("CIPH! ");
#endif
#ifdef	DEBUG
if(num==FALSE)	printf("Reset...");
#endif
				if(num==FALSE)	value=0;
#ifdef	DEBUG
printf("(was %d) ",value);
#endif
				value *= 10;
				value += (int)(tx[pt]-'0');
#ifdef	DEBUG
printf("(now %d)\n",value);
#endif
				num = TRUE;
				break;
			case '+':
			case '-':
			case '*':
			case '/':
			case '&':
			case '|':
//it is a binary operator, push previous value and then pending op
#ifdef	DEBUG
printf("Operator (%d)%c\n",value,tx[pt]);
#endif
				num=FALSE;
				push(value);
				push(tx[pt]<<16);	//shift makes code unreachable
				break;
			case '<':
			case '>':
//it is an unary operator, just push pending op
#ifdef	DEBUG
printf("Operator %c\n",tx[pt]);
#endif
				num=FALSE;
				push(tx[pt]<<16);	//shift makes code unreachable
				break;
		}
		pt++;
	} while(tx[pt-1]!='\0');
	printf("\n\nResult: %d\n",value);

	return 0;
}
