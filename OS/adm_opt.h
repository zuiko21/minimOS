; minimOS 0.6rc2 FAST Firmware calls
; (c) 2018 Carlos J. Santisteban
; last modified 20180403-0959


#define	{	(
#define	}	)
#ifdef	API_OPT
#define		_ADMIN{GESTALT}		JSR gestalt
#define		_ADMIN{SET_ISR}		JSR set_isr
#define		_ADMIN{SET_NMI}		JSR set_nmi
#define		_ADMIN{SET_DBG}		JSR set_dbg
#define		_ADMIN{JIFFY}		JSR jiffy
#define		_ADMIN{IRQ_SRC}		JSR irq_src
#define		_ADMIN{POWEROFF}	JSR poweroff
#define		_ADMIN{FREQ_GEN}	JSR freq_gen
#ifndef	LOWRAM
#define		_ADMIN{INSTALL}		JSR install
#define		_ADMIN{PATCH}		JSR patch
#endif
#endif
