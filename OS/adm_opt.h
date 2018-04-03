; minimOS 0.6rc2 FAST Firmware calls
; (c) 2018 Carlos J. Santisteban
; last modified 20180403-1108


#ifdef	API_OPT
#define		_ADMIN(#0)	JSR gestalt
#define		_ADMIN(#2)	JSR set_isr
#define		_ADMIN(#4)	JSR set_nmi
#define		_ADMIN(#6)	JSR set_dbg
#define		_ADMIN(#8)	JSR jiffy
#define		_ADMIN(#10)	JSR irq_src
#define		_ADMIN(#12)	JSR poweroff
#define		_ADMIN(#14)	JSR freq_gen
#ifndef	LOWRAM
#define		_ADMIN(#16)	JSR install
#define		_ADMIN(#18)	JSR patch
#endif
#endif
