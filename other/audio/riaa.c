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
	int freqs= 18;		// same as size of arrays below!!!
	double hz[18]= {0.1, 1, 4, 12, 20, 31, 49, 79, 150, 270, 480,
			1000, 1100, 2100, 3800, 7600, 12000, 21000};	// test frequencies
/* if using ...20, 31, 49, 79, 150, 270, 480, 1k, 1k1, 2k1, 3k8, 7k6, 12k, 21k,
	these are the IEC values for convenience */
	double iec[18]= {0,0,0,0, 16.35, 17.09, 16.45, 14.4, 10.28, 6.23, 2.92,
			0, -0.23, -2.73, -6.17, -11.39, -15.17, -19.95};

/********************/
/* component values */
/********************/
/* stage one, bias 8k2/150+100uF, load 10k/1k1+270nF */
	double rla=para(2200,2200), rld=10e3, fl=270e-9;
	double rba=150, rbd=8200, fb=100e-6;
/* stage two and low pass filter */
	double s3c=100e-6, s3a=150, s3d=560, s3l=1500;
	double lpr=para(68e3,68e3), lpc=2.2e-9;
/* input/output coupling */
	double cin= 220e-9, zin= para(150e3, 330e3);		// effect of 220n input capacitor (was 68n)
	double cout= 470e-9, zout= 47e3;	// effect of 470n output capacitor
/* variables */
	int fr;					// loop counter
	double gain, eq;			// temporary results

/* --------------- */

/* prepare display */
	printf("(output-Z: %f)\n\n", zout);
	printf("Hz\t\tGain\t\tdB\t\t(IEC err)\n");
	printf("==\t\t====\t\t==\t\t=========\n");

/* compute gain for each frequency */
	for (fr= 0; fr<freqs; fr++) {

/*** circuit configuration ***/
/* apply input coupling effect */
		gain= hipass(hz[fr], cin, zin);

/* apply first EQ stage */
		gain*= stage(hz[fr], fb, rba, rbd, fl, rla, rld);

/* apply non-EQ second stage with subsonic filter */
		gain*= stage(hz[fr], s3c, s3a, s3d, 0, 0, s3l); // missing AC load

/* RIAA low-pass filter */
		gain*= lowpass(hz[fr], lpc, lpr);		// apply passive low-pass

/* apply output coupling effect */
		gain*= hipass(hz[fr], cout, zout);

		eq= db(gain)-38.8345;				// EQ dB for convenience
/*** print results! ***/
		printf("%f\t%f\t%f\t%f\n", hz[fr], gain, eq, eq-iec[fr]);
	}

	return 0;
}
