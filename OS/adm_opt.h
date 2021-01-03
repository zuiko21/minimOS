; minimOS 0.6rc5 FAST Firmware calls
; (c) 2018-2021 Carlos J. Santisteban
; last modified 20180411-0829


#ifdef	FAST_FW
#define		_ADMIN(a)	_FWFAST_ ## a

#define		_FWFAST_GESTALT		JSR gestalt
#define		_FWFAST_SET_ISR		JSR set_isr
#define		_FWFAST_SET_NMI		JSR set_nmi
#define		_FWFAST_SET_DBG		JSR set_dbg
#define		_FWFAST_JIFFY		JSR jiffy
#define		_FWFAST_IRQ_SRC		JSR irq_src
#define		_FWFAST_POWEROFF	JSR poweroff
#define		_FWFAST_FREQ_GEN	JSR freq_gen

#ifndef	LOWRAM
#define		_FWFAST_INSTALL		JSR install
#define		_FWFAST_PATCH		JSR patch
#endif
#endif
