/* nanoPython POC
 * (c) 2023 Carlos J. Santisteban
 * */

#include <stdio.h>

char buffer[80];
int vars[26];
int a, x, y;
int cursor, lvalue, result, old, oper, temptr, prnflag, errflag, assign;
int exitf			= 0;
int cmd_id			= 0;
char tokens[256]	= {	'p','r','i','n','t',' ',0,
						'q','u','i','t','(',')',0,
						'=',0,
						'+',0,
						'-',0,
						'*',0,
						'/',0,
							-1};

int get_token(void);
int parse(void);
void evaluate(void);
void execute(int c);
int isletter(int c);
void error(void);

int main(void) {

	printf("nanoPython POC for 65C02\n\n");
	do {					// repl:
		printf(">>> ");		// JSR prompt
		gets(buffer);		// buff:
//		cursor = 0;			// parse:
		if (parse())	error();
//		get_token();
	} while (!exitf);
	printf("\nThanks for using nanoPython\n");

	return 0;
}

int parse(void) {
		printf("\nParsing %s\n",buffer);// ******debug*********
	cursor = 0;
	oper = 0;
	prnflag = 0;
	errflag = 0;
	lvalue = 0;
	assign = 0;
	while (buffer[cursor] && !errflag) {
		a = get_token();
		if (a<0)	evaluate();
		else		execute(a);
	}
	if (!errflag && prnflag)	printf("OUTPUT: %d\n", result);
	if (!errflag && assign)		vars[lvalue-1] = result;

	return errflag;
}

int get_token(void) {
		printf("{GT}");
	temptr	= 0;
	cmd_id	= 0;

	do {					// tk_loop:
		x = cursor;
		y = 0;
		do {				// tk_char:
			a = tokens[y+temptr];//printf("%c",a);
			if (!a)					break;
			if (a != buffer[x])		break;
			x++;
			y++;
		} while (-1);		// BNE tk_char
//next_tk:
		if (!a) {
			return cmd_id;
		} else {
			do {
				y++;
				a = tokens[y+temptr];//printf(">%c",a);
			} while (a);		// BNE next_tk
			cmd_id++;//printf("*");
			y++;
			temptr += y;
		}
	} while(tokens[temptr] >= 0);	// BPL tk_loop

	return -1;
}

void evaluate(void) {
		printf("{EV}");
	x = cursor;
	a = buffer[x];
	printf("[%c]",a);
	if (a) {
		a = isletter(a);
		if (a) {
			printf("!");
			y = a;
			a = vars[y-1];
			if (x)			result = a;
			else			lvalue = y;
		} else {
			result = 0;
			do {
				a = buffer[x];
				printf("[%c]",a);
				if (a<'0' || a>'9')	break;	// BCC/BCS pending
				a -= '0';
				result *= 10;
				a += result;
				result = a;
				x++;
			} while (x);
			x--;
		}
		x++;
		cursor = x;
		x = oper;
		switch(x) {
			case 1:
				result = old + result;
				printf(".suma.");
				oper = 0;
				break;
			case 2:
				result = old - result;
				printf(".resta.");
				oper = 0;
				break;
			case 3:
				result = old * result;
				printf(".mul.");
				oper = 0;
				break;
			case 4:
				result = old / result;
				printf(".div.");
				oper = 0;
				break;
		}
	}
}

void execute(int c) {
		printf("{XC}");
	if (oper)	error();	// prevents evaluating negative values
	cursor = ++x;
	switch(c) {				// JMP (exec, X)
		case 0:				// do_print:
			printf(" TOKEN = print\n");
			prnflag = 1;
			break;
		case 1:				// exit:
			printf(" TOKEN = quit()\n");
			exitf = 1;
			break;
		case 2:				// assign:
			printf(" TOKEN = '='\n");
			if (!lvalue)	error();
			else			assign = 1;
			break;
		case 3:				// opadd:
			printf(" TOKEN = +\n");
			oper = 1;
			break;
		case 4:				// opsub:
			printf(" TOKEN = -\n");
//			if (oper)	error();
			oper = 2;
			break;
		case 5:				// opmul:
			printf(" TOKEN = *\n");
			oper = 3;
			break;
		case 6:				// opdiv:
			printf(" TOKEN = /\n");
			oper = 4;
			break;
	}
	old = result;
}

void error(void) {
	printf("\nWTF?\n\n");
// may set some flags preventing further parsing
}

int isletter(int c) {
	c |= 32;
	if (c >= 'a' && c <= 'z')	return c-'a'+1;
	return 0;
}
