/* (c) 2018-2021 Carlos J. Santisteban */
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
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
	return r1*r2/(r1+r2);			// two resistor in parallel (or capacitors in series)
}

/* simulte tolerances with random factors */
double alea(void) {
	return 0.5;//rand()*1.0/RAND_MAX;	// return 0.5 to disable randomness
}

double	c2(void) {
	return 0.9+0.1*(alea()+alea());		// 2 parallel 10% capacitors
}

double	c1(void) {
	return 0.9+0.2*alea();			// single 10% capacitor
}

double	r2(void) {
	return 0.95+0.05*(alea()+alea());	// 2 parallel 5% resistors
}

double	r1(void) {
	return 0.95+0.1*alea();			// single 5% resistor
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

/* low-pass filter with optional Neumann high frquency rollover */
double lowpass(double f, double c, double r, double ch) {
	double re, im, zc, zi, zr;

	if (ch>0) {
		zi= 1/(pp*f*ch);
		re= mulr(r, 0, 0, zi);
		im= muli(r, 0, 0, zi);
		zr= divr(re, im, r, zi);
		zi= divi(re, im, r, zi);
	} else {
		zr= r;
		zi= 0;
	}
	zc= 1/(pp*f*c);
	re= divr(0, zc, zr, zc+zi);
	im= divi(0, zc, zr, zc+zi);

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
	int freqs= 21;		// same as size of arrays below!!!
	double hz[21]= {0.1, 1, 4, 12, 20, 31, 49, 79, 150, 270, 480,
			1000, 1100, 2100, 3800, 7600, 12000, 21000, 31600, 50000, 100000};	// test frequencies
/* if using ...20, 31, 49, 79, 150, 270, 480, 1k, 1k1, 2k1, 3k8, 7k6, 12k, 21k,
	these are the IEC values for convenience */
	double iec[21]= {0,0,0,0, 16.35, 17.09, 16.45, 14.4, 10.28, 6.23, 2.92,
			0, -0.23, -2.73, -6.17, -11.39, -15.17, -19.95, 0,0,0};

	srand(time(NULL));			// prepare random numbers!
/********************/
/* component values */
/********************/
/* stage one, bias 8k2/150+100uF, load 10k/1k1+270nF */
	double rla=para(2200,2200)*r2(), rld=10e3*r1(), fl=270e-9*c2();
	double rba=150*r1(), rbd=8200*r1(), fb=100e-6*c1();
/* stage two and low pass filter */
	double s3c=100e-6*c1(), s3a=150*r1(), s3d=560*r1(), s3l=1500*r1();
	double lpr=para(68e3,68e3)*r2(), lpc=2.2e-9*c2();
/* optional Neumann rollover on lowpass filter */
	double nc= 0;//68e-12;			// 94pF for lpr=34k (50 kHz)
/* input/output coupling */
	double cin= 220e-9*c1(), zin= para(150e3, 330e3)*r2();		// effect of 220n input capacitor (was 68n)
	double cout= 470e-9, zout= 47e3;	// effect of 470n output capacitor
/* variables */
	int fr;					// loop counter
	double gain, eq;			// temporary results

/* --------------- */

/* prepare display */
	printf("(output-Z: %f)\n%d\n", zout, RAND_MAX);
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
		gain*= lowpass(hz[fr], lpc, lpr, nc);		// apply passive low-pass

/* apply output coupling effect */
		gain*= hipass(hz[fr], cout, zout);

		eq= db(gain)-38.8344;				// EQ dB for convenience
/*** print results! ***/
		printf("%f\t%f\t%f", hz[fr], gain, eq);
		if (iec[fr]!=0) {
			printf("\t%f", eq-iec[fr]);
		}
		printf("\n");
	}

	return 0;
}
