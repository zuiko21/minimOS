; minimOS 0.5a6 System Variables
; (c) 2012-2015 Carlos J. Santisteban
; last modified 20151014-1757

.bss

-sysvars:

; pointer tables for drivers, new order suggested for alternative version
#ifdef	LOWRAM
drv_num		.byt	0	; number of installed drivers
drivers_id	.dsb	MAX_QUEUE	; space for reasonable number of drivers
#else
drivers_pt	.dsb	256			; full page of driver pointers, new 151014
#endif

dpoll_mx	.byt	0	; bytes used for drivers with polling routines, might make things faster
drv_poll	.dsb	MAX_QUEUE	; space for periodic routines
dreq_mx		.byt	0	; bytes used for drivers with async routines
drv_async	.dsb	MAX_QUEUE	; space for async routines
dsec_mx		.byt	0	; bytes used for drivers with 1-sec routines
drv_sec		.dsb	MAX_QUEUE	; space for 1-sec routines

cin_mode	.byt	0	; CIN binary mode flag for event management, new 20150618

; for single-task systems, simple SIGTERM handler, otherwise on driver's memory, new 20150514
#ifndef		MULTITASK
stt_handler	.dsb	2	; TERM routine address
#endif

; new memory management table 150209
#ifndef		LOWRAM
ram_tab		.dsb	MAX_LIST	; space for blocks
ram_siz		.dsb	MAX_LIST	; size of blocks
ram_stat	.dsb	MAX_LIST/2	; status of each block
#endif

; these are the older variables, up to 150126
irq_freq	.word	200	; IRQs per second
ticks		.dsb	5	; (irq_freq)-interrupts, then approximate uptime in seconds (3 bytes)
default_out	.byt	0	; global default devices
default_in	.byt	0
old_t1		.word	0	; keep old T1 latch value for FG, revised 150208

;driver-specific system variables come after this one, in main source
