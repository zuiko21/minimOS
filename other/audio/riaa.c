#include <stdio.h>
#include <math.h>
/* use gcc -lm to compile with math!!! */

/********************/
/* custom functions */
/********************/

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

double db(double g) {
	return 20*log10(g);
}

/****************/
/* main program */
/****************/

int main(void) {
/* constants */
	double hz[11]= {0.1, 1, 4, 13, 20, 50, 500, 1000, 2120, 6300, 20000};	// test frequencies
	int freqs= 11;			// same as above array!!!
	double pp= 2*3.14159265;	// pi times two for convenience
/* stage two */
	double rla= 470, rld= 4100, rba= 270, rbd= 2200;	// resistor values
	double fl= 690e-9, fb= 47e-6;				// capacitor values
/* other stages */
	double s1c= 10e-6, s1a= 1200, s1d= 10000, s1l= 10000;	// first stage values
	double s3c= 47e-6, s3a= 270, s3d= 1200, s3l= 1800;	// third stage values
	double lpr= 37500, lpc= 2e-9;		// final low-pass filter values
/* input/output coupling */
	double cin= 220e-9, zin= 116e3;		// effect of 68n input capacitor
	double cout= 470e-9, zout= 47e3;	// effect of 470n output capacitor
/* variables */
	int fr;					// loop counter
	double cl, cb, zb, zl, gain, t;		// temporary results
	double re, im, re2, im2, lpf, hpf;

/* --------------- */

/* prepare display */
	printf("(output-Z: %f)\n\n", zout);
	printf("Hz\t\tZLoad\t\tZBias\t\tGain\t\tdB\n");
	printf("==\t\t=====\t\t=====\t\t====\t\t==\n");

/* compute gain for each frequency */
	for (fr= 0; fr<freqs; fr++) {
		t= 1/(pp*hz[fr]);	// for convenience
/* capacitor reactance */
		cl= t/fl;		// load (collector) capacitor
		cb= t/fb;		// bias (emitter) capacitor
/* load (collector) impedance */
		re= mulr(rla, cl, rld, 0);
		im= muli(rla, cl, rld, 0);
		re2= divr(re, im, rla+rld, cl);
		im2= divi(re, im, rla+rld, cl);
		zl= polar(re2, im2);
/* bias (emitter) impedance */
		re= mulr(rba, cb, rbd, 0);
		im= muli(rba, cb, rbd, 0);
		re2= divr(re, im, rba+rbd, cb);
		im2= divi(re, im, rba+rbd, cb);
		zb= polar(re2, im2);
/* compute stage gain just by polar modules? */
		gain= zl/zb;

/* apply input coupling effect, currently includes IEC amend */
		cb= t/cin;
		re= divr(zin, 0, zin, cb);
		im= divi(zin, 0, zin, cb);
		hpf= polar(re, im);
		gain*= hpf;		// apply hi-pass

/* apply other stages gain */
// must add subsonic filter! simple way*******
		gain*= s1l/s1a;
		cb= t/s1c;
		re= divr(s1a, 0, s1a, cb);
		im= divi(s1a, 0, s1a, cb);
		hpf= polar(re, im);
		gain*= hpf;		// apply passive hi-pass

		gain*= s3l/s3a;
		cb= t/s3c;
		re= divr(s3a, 0, s3a, cb);
		im= divi(s3a, 0, s3a, cb);
		hpf= polar(re, im);
		gain*= hpf;		// apply passive hi-pass
		// two by-ten stages
/* RIAA low-pass filter */
		cl= t/lpc;
		re= divr(0, cl, lpr, cl);
		im= divi(0, cl, lpr, cl);
		lpf= polar(re, im);
		gain*= lpf;		// apply passive low-pass

/* apply output coupling effect */
		cb= t/cout;
		re= divr(zout, 0, zout, cb);
		im= divi(zout, 0, zout, cb);
		hpf= polar(re, im);
		gain*= hpf;		// apply passive hi-pass

/* print results! */
		printf("%f\t%f\t%f\t%f\t%f\n", hz[fr], zl, zb, gain, db(gain));
	}

	return 0;
}
