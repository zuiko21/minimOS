; minimOS 0.6rc4 FAST API calls
; (c) 2018 Carlos J. Santisteban
; last modified 20180404-0856

#ifdef	API_OPT
#define		_KERNEL(a)	_KFAST_ ## a

#define		_KFAST_0	JSR cout
#define		_KFAST_2	JSR cin
#define		_KFAST_4	JSR string
#define		_KFAST_6	JSR readln
#define		_KFAST_8	JSR blout
#define		_KFAST_10	JSR blin
#define		_KFAST_12	JSR bl_cnfg
#define		_KFAST_14	JSR bl_stat
#define		_KFAST_16	JSR open_w
#define		_KFAST_18	JSR close_w
#define		_KFAST_20	JSR free_w
#define		_KFAST_22	JSR uptime
#define		_KFAST_24	JSR shutdown
#define		_KFAST_26	JSR loadlink
#define		_KFAST_28	JSR b_fork
#define		_KFAST_30	JSR b_exec
#define		_KFAST_32	JSR b_signal
#define		_KFAST_34	JSR b_flags
#define		_KFAST_36	JSR set_hndl
#define		_KFAST_38	JSR b_yield
#define		_KFAST_40	JSR get_pid
#define		_KFAST_42	JSR dr_info
#define		_KFAST_44	JSR aq_mng
#define		_KFAST_46	JSR pq_mng
#define		_KFAST_48	JSR dr_inst
#define		_KFAST_50	JSR dr_shut
#ifndef	LOWRAM
#define		_KFAST_52	JSR malloc
#define		_KFAST_54	JSR free
#define		_KFAST_56	JSR memlock
#define		_KFAST_58	JSR release
#define		_KFAST_60	JSR ts_info
#define		_KFAST_62	JSR set_curr
	API_SIZE	=	64
#else
	API_SIZE	=	52
#endif
#endif
