; minimOS 0.6rc3 System Variables
; (c) 2012-2018 Carlos J. Santisteban
; last modified 20180305-0941
.bss

; **** I/O management ****
; ** pointer tables for drivers, new order suggested for alternative version **
#ifndef	LOWRAM
drv_opt		.dsb	MX_DRVRS*2	; full page of output driver pointers, new direct scheme 160406 ; ***these best NOT at $xx00***
drv_ipt		.dsb	MX_DRVRS*2	; full page of input driver pointers, new direct scheme 160406
; ***** new direct array for sparse indexes *****
dr_ind		.dsb	128			; index for sparse array ***this is best aligned at $xx80 for optimum performance***
; mutable or not, keep track of driver header pointers!
drv_ads		.dsb	MX_DRVRS*2	; address of headers from actually assigned IDs, new 171011, now sparse
#else
; ****** this will change
drv_num		.byt	0			; number of installed drivers
id_list		.dsb	MX_DRVRS	; space for reasonable number of drivers
; ideally will be non-sparse direct arrays from ROM, non-mutable devices lr0-lr7 (128-135)
;drv_en		.dsb	8			; array of enabled drivers, perhaps going in a slower, memory-saving bitwise format???
#endif

; ** I/O flags and locks **
; mandatory order!!!
#ifndef	LOWRAM
cio_lock	.dsb	MX_DRVRS*2	; PID-reserved MUTEX for CIN & COUT, per-phys-driver & interleaved with CIN binary mode flag for event management 170220
cin_mode	= cio_lock + 1		; interleaved
#else
cin_mode	.dsb	1			; only this for low ram systems
#endif

; **** interrupt queues **** new format 20170518
queue_mx	.word	0			; array with max offset for both Periodic[1] & Async[0] queues
drv_poll	.dsb	MX_QUEUE	; space for periodic task pointers
drv_freq	.dsb	MX_QUEUE	; array of periodic task frequencies (word?)
drv_asyn	.dsb	MX_QUEUE	; space for async task pointers
drv_a_en	.dsb	MX_QUEUE	; interleaved array of async interrupt task flags
drv_p_en	= drv_a_en + 1		; ditto for periodic tasks (interleaved)
drv_cnt		.dsb	MX_QUEUE	; current P-task counters eeeeeeeeeeeeeeeeeeeeek

; *** single-task sigterm handler separate again! ***
; multitasking should provide appropriate space!
#ifdef	C816
mm_sterm	.dsb	3			; including bank address just after the pointer
#else
mm_sterm	.dsb	2			; 16-bit pointer
#endif
; no longer mm_term et al here!

; **** new memory management table 150209, revamped 161106 ****
#ifndef		LOWRAM
#ifdef		C816
ram_pos		.dsb	MAX_LIST*2	; location of blocks, new var 20161103
ram_stat	.dsb	MAX_LIST*2	; status of each block, interleaved with PID for 65816!
ram_pid		= ram_stat + 1		; interleaved array!
#else
ram_pos		.dsb	MAX_LIST	; location of blocks, new var 20161103
ram_stat	.dsb	MAX_LIST	; status of each block, non interleaved
ram_pid		.dsb	MAX_LIST	; non-interleaved PID array
#endif
#endif

; *************************************************
; ** these are the older variables, up to 150126 **
; *************************************************
; IRQs per second no longer here, now in firmware if suitable
ticks		.dsb	4	; jiffy IRQ count (4 bytes) newest format 170822
sd_flag		.byt	0	; default task upon no remaining braids! 160408
#ifndef	LOWRAM
dflt_in		.byt	0	; GLOBAL default devices, EXCEPT for LOWRAM systems
dfltout		.byt	0
; no way for multitasking in LOWRAM systems
run_pid		.byt	0	; current PID running for easy kernel access, will be set by new SET_CURR
#else
dflt_in		= std_in	; in LOWRAM systems, both global and local standard devices are the same!
dfltout		= stdout
#endif

; ********************************
; *** some 65816 specific vars ***
; ********************************
#ifdef	C816
run_arch	.byt	0	; current braid CPU type, 0=65816, 2=Rockwell, 4=65C02, 6=NMOS
; or maybe any other format (EOR #'V'), just make sure native 65816 is 0!
#endif

; ** driver-specific system variables come after this one, in main source **
