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

double db(double g) {
	return 20*log10(g);
}

/**********************/
/* filters and stages */
/**********************/

double stage(double f, double cb, double rba, double rbd, double cl, double rla, double rld) {
	double t, zcl, zcb, re, im, re2, im2, zl, zb;

	t= 1/(pp*f);
/* capacitor reactance */
	zcl= t/cl;		// load (collector) capacitor
	zcb= t/cb;		// bias (emitter) capacitor
/* load (collector) impedance */
	re= mulr(rla, zcl, rld, 0);
	im= muli(rla, zcl, rld, 0);
	re2= divr(re, im, rla+rld, zcl);
	im2= divi(re, im, rla+rld, zcl);
	zl= polar(re2, im2);
/* bias (emitter) impedance */
	re= mulr(rba, zcb, rbd, 0);
	im= muli(rba, zcb, rbd, 0);
	re2= divr(re, im, rba+rbd, zcb);
	im2= divi(re, im, rba+rbd, zcb);
	zb= polar(re2, im2);

/* compute stage gain just by polar modules? */
	return zl/zb;
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
	int freqs= 11;			// same as above array!!!
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
	printf("Hz\t\tGain\t\tdB\n");
	printf("==\t\t====\t\t==\n");

/* compute gain for each frequency */
	for (fr= 0; fr<freqs; fr++) {
		t= 1/(pp*hz[fr]);	// for convenience

/* apply input coupling effect, currently includes IEC amend */
		gain= hipass(hz[fr], zin, cin);

/* apply middle EQ stage */
		gain*= stage(hz[fr], fb, rba, rbd, fl, rla, rld);

/* apply other stages gain */
// must add subsonic filter! simple way*******

		gain*= s1l/s1a;
		gain*= hipass(hz[fr], s1c, s1a);	// apply passive hi-pass

		gain*= s3l/s3a;
		gain*= hipass(hz[fr], s3c, s3a);	// apply passive hi-pass
		// two by-ten stages

/* RIAA low-pass filter */
		gain*= lowpass(hz[fr], lpc, lpr);		// apply passive low-pass

/* apply output coupling effect */
		gain*= hipass(hz[fr], zout, cout);

/* print results! */
		printf("%f\t%f\t%f\n", hz[fr], gain, db(gain));
	}

	return 0;
}
