; minimOS 0.6rc2 FAST API calls
; (c) 2018 Carlos J. Santisteban
; last modified 20180403-0959

#ifdef	API_OPT
#define		_KERNEL(COUT)		JSR cout
#define		_KERNEL(CIN)		JSR cin
#define		_KERNEL(STRING)		JSR string
#define		_KERNEL(READLN)		JSR readln
#define		_KERNEL(BLOUT)		JSR blout
#define		_KERNEL(BLIN)		JSR blin
#define		_KERNEL(BL_CNFG)	JSR bl_cnfg
#define		_KERNEL(BL_STAT)	JSR bl_stat
#define		_KERNEL(OPEN_W)		JSR open_w
#define		_KERNEL(CLOSE_W)	JSR close_w
#define		_KERNEL(FREE_W)		JSR free_w
#define		_KERNEL(UPTIME)		JSR uptime
#define		_KERNEL(SHUTDOWN)	JSR shutdown
#define		_KERNEL(LOADLINK)	JSR loadlink
#define		_KERNEL(B_FORK)		JSR b_fork
#define		_KERNEL(B_EXEC)		JSR b_exec
#define		_KERNEL(B_SIGNAL)	JSR b_signal
#define		_KERNEL(B_FLAGS)	JSR b_flags
#define		_KERNEL(SET_HNDL)	JSR set_hndl
#define		_KERNEL(B_YIELD)	JSR b_yield
#define		_KERNEL(GET_PID)	JSR get_pid
#define		_KERNEL(DR_INFO)	JSR dr_info
#define		_KERNEL(AQ_MNG)		JSR aq_mng
#define		_KERNEL(PQ_MNG)		JSR pq_mng
#define		_KERNEL(DR_INST)	JSR dr_inst
#define		_KERNEL(DR_SHUT)	JSR dr_shut
#ifndef	LOWRAM
#define		_KERNEL(MALLOC)		JSR malloc
#define		_KERNEL(FREE)		JSR free
#define		_KERNEL(MEMLOCK)	JSR memlock
#define		_KERNEL(RELEASE)	JSR release
#define		_KERNEL(TS_INFO)	JSR ts_info
#define		_KERNEL(SET_CURR)	JSR set_curr
#endif
#endif
