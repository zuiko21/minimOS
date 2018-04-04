; minimOS 0.6rc3 FAST Firmware calls
; (c) 2018 Carlos J. Santisteban
; last modified 20180404-0855


#ifdef	API_OPT
#define		_ADMIN(a)	_FWFAST_ ## a

#define		_FWFAST_0	JSR gestalt
#define		_FWFAST_2	JSR set_isr
#define		_FWFAST_4	JSR set_nmi
#define		_FWFAST_6	JSR set_dbg
#define		_FWFAST_8	JSR jiffy
#define		_FWFAST_10	JSR irq_src
#define		_FWFAST_12	JSR poweroff
#define		_FWFAST_14	JSR freq_gen

#ifndef	LOWRAM
#define		_FWFAST_16	JSR install
#define		_FWFAST_18	JSR patch
#endif
#endif
