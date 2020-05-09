/*
 * M/L for minimOS simulator
 * (c) 2015-2020 Carlos J. Santisteban
 * last modified 20151009-0901
 */

#include <stdio.h>

/*
 * type definitions
 */
typedef	unsigned char	byt;

/*
 * global variables
 */
// memory array
byt		ram[49152];					// 48 kiB
byt		a, x, y, s, p;				// 65c02 registers

// zp pointers
byt*	endsp	= &ram[2];			// *** used_z for mOS works as data stack pointer
byt*	a_reg	= &ram[3];
byt*	x_reg	= &ram[4];
byt*	y_reg	= &ram[5];
byt*	p_reg	= &ram[6];
byt*	s_reg	= &ram[7];
byt*	io_dev	= &ram[8];			// *** mOS only
byt*	com_dev	= &ram[8];			// *** for load/save
byt*	curs	= &ram[9];			// current buffer pointer, really needed?
byt*	mode	= &ram[10];			// choose between hex (0) and ASCII ($FF) mode
byt*	temp	= &ram[11];			// hex-to-bin conversion
byt*	count	= &ram[12];			// number of lines (minus 1) to dump, or bytes to load/save
byt*	ptr		= &ram[14];			// converted values and addresses *** needs to be in zeropage ***
byt*	last_f	= &ram[16];			// last fetch address *** should be in zeropage, may be merged with others
byt*	last_p	= &ram[18];			// last store address *** should be in zeropage, may be merged with others
byt*	last_d	= &ram[20];			// last dump address *** should be in zeropage, may be merged with others
byt*	inbuff	= &ram[22];			// 40-byte buffer for keyboard input
byt*	stack	= &ram[62];			// internal stack

/*
 * function prototypes
 */
byt mos_init(void);

/*
 * main function
 */
int main(void){
	*endsp = 225;					// full minimOS standard value
//	printf("%c\n", *endsp);
	
/*
 * Code starts here
 */
	*a_reg = a;		// store registers
	*x_reg = x;
	*y_reg = y;
	*p_reg = p;		// done via PHP:PLA:STA
	*s_reg = s;		// done via TSX:STX
	
	if (mos_init())		return 0;	// initialize specific stuff, abort in case of any problems
	x = inbuff-com_dev+1;			// bytes to be cleared
	
	return 0;
}

/*
 * function definitions
 */

byt mos_init(void){
	a = *endsp;		// really gets number of available ZP bytes
	if (a<67) {		// below minimum?
		printf("\n***FATAL ERROR: not enough zeropage space***\n");
		return 1;	// abort
	}
// set SIGTERM handler...
// open device window...
	*io_dev = 232;	// default device placeholder
	
	return 0;		// all OK
}
