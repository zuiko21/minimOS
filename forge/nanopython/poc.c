/* nanoPython POC
 * (c) 2023 Carlos J. Santisteban
 * */

#include <stdio.h>

char buffer[80];
int vars[26];
int cursor, lvalue, result, old, oper;
int exitf			= 0;
char tokens[256]	= {	'p','r','i','n','t',' ',0,
						'q','u','i','t','(',')',0,
						'=',0,
						'+',0,
						'-',0,
						'*',0,
						'/',0,
							-1};

void get_token(void);
int isletter(int c);
void error(void);

int main(void) {

	printf("nanoPython POC for 65C02\n\n");
	do {					// repl:
		printf(">>> ");		// JSR prompt
		gets(buffer);		// buff:
		printf("\nParsing %s\n",buffer);// ******debug*********
		cursor = 0;			// parse:
		get_token();
	} while (!exitf);
	printf("\nThanks for using nanoPython\n");

	return 0;
}

void get_token() {
	int a, x, y;
	int cmd_id	= 0;
	int temptr	= 0;

	do {					// tk_loop:
		x = cursor;
		y = 0;
		do {				// tk_char:
			a = tokens[y+temptr];//printf("%c",a);
			if (!a)					goto found;
			if (a != buffer[x])		goto next_tk;
			x++;
			y++;
		} while (-1);		// BNE tk_char
next_tk:
		do {
			y++;
			a = tokens[y+temptr];//printf(">%c",a);
		} while (a);		// BNE next_tk
		cmd_id++;//printf("*");
		y++;
		temptr += y;
	} while(tokens[temptr] >= 0);	// BPL tk_loop
eval:
	a = buffer[x];
	printf("[%c]",a);
	if (!a)		goto eol;
	a = isletter(a);
	if (a) {				// BEQ evalnum
		y = a;
		a = vars[y-1];
		goto operand;
	} else {				// evalnum:
		do {
			a = buffer[x];
			printf("[%c]",a);
			if (a<'0' || a>'9')	break;	// BCC/BCS pending
			a -= '0';
			result *= 10;
			a += result;
operand:
			result = a;
			x++;
		} while (x);		// BNE evalnum
		x++;				// pending:INX
		cursor = x;
		a = result;
		x = oper;
		if (x) {
			a = old;
//			do_op();
			oper = 0;
			x = cursor;
		}					// noop:
		old = a;
		result = 0;
	}
eol:
	return;
found:
	cursor = ++x;
	switch(cmd_id) {		// JMP (exec, X)
		case 0:				// do_print:
			printf(" TOKEN = print\n");
			break;
		case 1:				// exit:
			printf(" TOKEN = quit()\n");
			exitf = 1;
			break;
		case 2:				// assign:
			printf(" TOKEN = '='\n");
			x = cursor-2;
			a = buffer[x];
			a = isletter(a);
			if (!a)		error();
			else		lvalue = a;
			break;
		case 3:				// opadd:
			printf(" TOKEN = +\n");
			break;
		case 4:				// opsub:
			printf(" TOKEN = -\n");
			break;
		case 5:				// opmul:
			printf(" TOKEN = *\n");
			break;
		case 6:				// opdiv:
			printf(" TOKEN = /\n");
			break;
	}
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
