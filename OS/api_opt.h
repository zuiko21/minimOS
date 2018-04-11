; minimOS 0.6rc6 FAST API calls
; (c) 2018 Carlos J. Santisteban
; last modified 20180411-0829

#ifdef	FAST_API
#define		_KERNEL(a)	_KFAST_ ## a

#define		_KFAST_COUT		JSR cout
#define		_KFAST_CIN		JSR cin
#define		_KFAST_STRING	JSR string
#define		_KFAST_READLN	JSR readln
#define		_KFAST_BLOUT	JSR blout
#define		_KFAST_BLIN		JSR blin
#define		_KFAST_BL_CNFG	JSR bl_cnfg
#define		_KFAST_BL_STAT	JSR bl_stat
#define		_KFAST_OPEN_W	JSR open_w
#define		_KFAST_CLOSE_W	JSR close_w
#define		_KFAST_FREE_W	JSR free_w
#define		_KFAST_UPTIME	JSR uptime
#define		_KFAST_SHUTDOWN	JSR shutdown
#define		_KFAST_LOADLINK	JSR loadlink
#define		_KFAST_B_FORK	JSR b_fork
#define		_KFAST_B_EXEC	JSR b_exec
#define		_KFAST_B_SIGNAL	JSR b_signal
#define		_KFAST_B_FLAGS	JSR b_flags
#define		_KFAST_SET_HNDL	JSR set_hndl
#define		_KFAST_B_YIELD	JSR b_yield
#define		_KFAST_GET_PID	JSR get_pid
#define		_KFAST_DR_INFO	JSR dr_info
#define		_KFAST_AQ_MNG	JSR aq_mng
#define		_KFAST_PQ_MNG	JSR pq_mng
#define		_KFAST_DR_INST	JSR dr_inst
#define		_KFAST_DR_SHUT	JSR dr_shut
#ifndef	LOWRAM
#define		_KFAST_MALLOC	JSR malloc
#define		_KFAST_FREE		JSR free
#define		_KFAST_MEMLOCK	JSR memlock
#define		_KFAST_RELEASE	JSR release
#define		_KFAST_TS_INFO	JSR ts_info
#define		_KFAST_SET_CURR	JSR set_curr
	API_SIZE	=	64
#else
	API_SIZE	=	52
#endif
#endif
