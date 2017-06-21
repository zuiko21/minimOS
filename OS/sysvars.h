; minimOS 0.6a4 System Variables
; (c) 2012-2017 Carlos J. Santisteban
; last modified 20170621-1343
.bss

; **** I/O management ****
; ** pointer tables for drivers, new order suggested for alternative version **
#ifndef	LOWRAM
drv_opt		.dsb	256			; full page of output driver pointers, new direct scheme 160406
drv_ipt		.dsb	256			; full page of input driver pointers, new direct scheme 160406
#else
drv_num		.byt	0			; number of installed drivers
drivers_id	.dsb	MAX_DRIVERS	; space for reasonable number of drivers
#endif

; ** I/O flags and locks **
; mandatory order!!!
#ifndef	LOWRAM
cio_lock	.dsb	256			; PID-reserved MUTEX for CIN & COUT, per-phys-driver & interleaved with CIN binary mode flag for event management 170220
cin_mode	= cio_lock + 1		; interleaved
#else
cin_mode	.dsb	1			; only this for low ram systems
#endif

; **** interrupt queues **** new format 20170518
queues_mx	.word	0			; array with max offset for both Periodic[1] & Async[0] queues
drv_poll	.dsb	MAX_QUEUE	; space for periodic task pointers
drv_freq	.dsb	MAX_QUEUE	; array of periodic task frequencies (word?)
drv_async	.dsb	MAX_QUEUE	; space for async task pointers
drv_a_en	.dsb	MAX_QUEUE	; interleaved array of async interrupt task flags
drv_p_en	= drv_a_en + 1		; ditto for periodic tasks (interleaved)
drv_count	.dsb	MAX_QUEUE	; current P-task counters eeeeeeeeeeeeeeeeeeeeek

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
irq_freq	.word	200	; IRQs per second (originally set from options.h)
ticks		.dsb	6	; second fraction in jiffy IRQs, then approximate uptime in seconds (2+4 bytes) new format 161006
sd_flag		.byt	0	; default task upon no remaining braids! 160408
#ifndef	LOWRAM
default_in	.byt	0	; GLOBAL default devices, EXCEPT for LOWRAM systems
default_out	.byt	0
; no way for multitasking in LOWRAM systems
run_pid		.byt	0	; current PID running for easy kernel access, will be set by new SET_CURR
#else
default_in	= std_in	; in LOWRAM systems, both global and local standard devices are the same!
default_out	= stdout
#endif
old_t1		.word	0	; *** keep old T1 latch value for FG, revised 150208 *** might be revised or moved to firmware vars!

; ********************************
; *** some 65816 specific vars ***
; ********************************
#ifdef	C816
run_arch	.byt	0	; current braid CPU type, 0=65816, 2=Rockwell, 4=65C02, 6=NMOS
; or maybe any other format (EOR #'V'), just make sure native 65816 is 0!
#endif

; ** driver-specific system variables come after this one, in main source **
