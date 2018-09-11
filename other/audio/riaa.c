#include <stdio.h>
#include <math.h>
/* use gcc -lm to compile with math!!! */

/********************/
/* GLOBAL constants */
/********************/

double pp= 2*3.14159265;	// pi times two for convenience

/*********************/
/* complex functions */
/*********************/

double mulr(double a, double b, double c, double d) {
	return a*c - b*d;
}

double muli(double a, double b, double c, double d) {
	return a*d + b*c;
}

double divr(double a, double b, double c, double d) {
	return (a*c+b*d)/(c*c+d*d);
}

double divi(double a, double b, double c, double d) {
	return (b*c-a*d)/(c*c+d*d);
}

double polar(double a, double b) {
	return sqrt(a*a+b*b);
}

/************************/
/* convenient functions */
/************************/

double db(double g) {
	return 20*log10(g);
}

double para(double r1, double r2) {
	return r1*r2/(r1+r2);
}

/**********************/
/* filters and stages */
/**********************/

double stage(double f, double cb, double rba, double rbd, double cl, double rla, double rld) {
	double t, zcl, zcb, re, im, re2, im2, re3, im3;

	t= 1/(pp*f);
/* capacitor reactance */
	zcb= t/cb;		// bias (emitter) capacitor
	if (cl>0) {
		zcl= t/cl;		// load (collector) capacitor
/* load (collector) impedance for EQ stages */
		re= mulr(rla, zcl, rld, 0);
		im= muli(rla, zcl, rld, 0);
		re2= divr(re, im, rla+rld, zcl);
		im2= divi(re, im, rla+rld, zcl);
	} else {
/* for non-EQ stages */
		re2= rld;		// single resistor
		im2= 0;
	}
/* bias (emitter) impedance */
	re= mulr(rba, zcb, rbd, 0);
	im= muli(rba, zcb, rbd, 0);
	re3= divr(re, im, rba+rbd, zcb);
	im3= divi(re, im, rba+rbd, zcb);
/* compute stage gain by COMPLEX division */
	re= divr(re2, im2, re3, im3);
	im= divi(re2, im2, re3, im3);

	return polar(re, im);
}

double lowpass(double f, double c, double r) {
	double re, im, zc;

	zc= 1/(pp*f*c);
	re= divr(0, zc, r, zc);
	im= divi(0, zc, r, zc);

	return polar(re, im);
}

double hipass(double f, double c, double r) {
	double re, im, zc;

	zc= 1/(pp*f*c);
	re= divr(r, 0, r, zc);
	im= divi(r, 0, r, zc);

	return polar(re, im);
}

/****************/
/* main program */
/****************/

int main(void) {
/* constants */
	double hz[11]= {0.1, 1, 4, 13, 20, 50, 500, 1000, 2120, 6300, 20000};	// test frequencies
	int freqs= 11;				// same as above array!!!

/********************/
/* component values */
/********************/
/* stage two, bias 2k2/270+47uF, load 8k2/8k2/470+690nF */
	double rla= 470, rld= 4100, rba= 270, rbd= 2200;	// resistor values
	double fl= 680e-9, fb= 100e-6;				// capacitor values
/* other stages */
	double s1c= 22e-6, s1a= 1200, s1d= 10000, s1l= 10000;	// first stage values, bias 10k/1k2+22uF, load 10k
	double s3c= 47e-6, s3a= 390, s3d= 1200, s3l= 1800;	// third stage values, bias 1k2/390+100uF, load 1k8
	double lpr= 27000, lpc= 2.7e-9;		// final low-pass filter values (68k/82k, 1n/1n)
/* input/output coupling */
	double cin= 180e-9, zin= para(150e3, 330e3);		// effect of 150n input capacitor (was 68n)
	double cout= 470e-9, zout= 47e3;	// effect of 470n output capacitor
/* variables */
	int fr;					// loop counter
	double gain;				// temporary result

/* --------------- */

/* prepare display */
	printf("(output-Z: %f)\n\n", zout);
	printf("Hz\t\tGain\t\tdB\n");
	printf("==\t\t====\t\t==\n");

/* compute gain for each frequency */
	for (fr= 0; fr<freqs; fr++) {

/*** circuit configuration ***/
/* apply input coupling effect */
		gain= hipass(hz[fr], cin, zin);

/* apply non-EQ first stage with subsonic filter */
		gain*= stage(hz[fr], s1c, s1a, s1d, 0, 0, s1l);	// missing AC load

/* apply middle EQ stage */
		gain*= stage(hz[fr], fb, rba, rbd, fl, rla, rld);

/* apply non-EQ third stage with subsonic filter */
		gain*= stage(hz[fr], s3c, s3a, s3d, 0, 0, s3l); // missing AC load

/* RIAA low-pass filter */
		gain*= lowpass(hz[fr], lpc, lpr);		// apply passive low-pass

/* apply output coupling effect */
		gain*= hipass(hz[fr], cout, zout);

/*** print results! ***/
		printf("%f\t%f\t%f\n", hz[fr], gain, db(gain)-40.1288);
	}

	return 0;
}
