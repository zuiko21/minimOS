unsigned char	a, x, y;
unsigned char	ram[16384];

err_code	mem_test(void) {
	int		ptr;				/* actually stored at ram[Z_USED] */

	ram[Z_USED]		= 0x55;		/* try pointer address first */
	ram[Z_USED+1]	= 0xAA;
	a = ram[Z_USED];			/* get first value */
	if (a != 0x55)	{			/* if not as expected, abort */
		return RAM_FAIL;
	}
	a = a ^ ram[Z_USED+1];		/* XOR between both values should be all ones */
	a++;						/* plus one, must be all zeroes */
	if (a) {					/* otherwise, it's bad! */
		return RAM_FAIL;
	}
	y = 4:						/* safe offset for I/O hardware */
	ptr = 0;					/* reset pointer */
	a = 0x55;					/* initial value */
	do {
		ram[ptr+y] = a;			/* store it */
		if (a != ram[ptr+y]) {	/* if different... */
			break;				/* ...most likely outside decoded RAM */
		}
		a = a ^ 0xFF;			/* invert bits */
		if (a >= 0x80) {		/* negative? */
			continue;			/* if so, try once more */
		}
		ptr = ptr + 256;		/* next page */
	} while (ptr < 16384);		/* absolute RAM limit */
	x = ptr / 256;				/* get current page number */
	do {
		ptr = ptr - 256;		/* previous page */
		a = ptr / 256			/* get page number... */
		ram[ptr+y] = a;			/* ...and store it */
		x--;
