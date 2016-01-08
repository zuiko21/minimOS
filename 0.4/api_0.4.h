; minimOS 0.4b3 API
; (c) 2012-2013 Carlos J. Santisteban
; last modified 2013.05.04

; NEW 2012.12.26, driver code offsets, three more in 20130110
; new, all constants begin with underscore 20130218
; should numeric constants be all caps with no underscore (reserved for macros)?
; new, offsets in HEX! 20130219
#define _d_init		$0
#define _d_poll		$2
#define _d_req		$4
#define _d_in		$6
#define _d_out		$8
#define _d_1sec		$A
#define _d_bli		$C
#define _d_blo		$E
; new offsets 20130218
#define _d_bye		$10
#define _d_auth		$12
#define _d_num		$13

; kernel function codes for system call
#define	_cout		0
#define	_cin		2
#define	_malloc		4
#define	_free		6
#define	_open_w		8
#define	_close_w	10
#define	_free_w		12
#define	_hid_push	14
#define	_b_fork		16
#define	_b_exec		18
#define	_load_link	20
#define	_su_poke	22
#define	_su_peek	24
#define	_string		26
; new functions 20130206
#define	_dis_int	28
#define	_en_int		30
#define _set_fg		32

; error codes
#define	_OK		0
; not needed on 65xx, CLC instead
#define	_unavail	1
; unavailable on this version
#define	_timeout	2
; try later
#define	_full		3
; not enough memory, try less
#define	_not_found	4
; try another
#define	_no_rsrc	5
; no windows, try a different way
#define	_empty		6
; put some and retry
#define _invalid	7
; invalid argument, NEW@121216, rest was 121205
; new 20130206
#define _busy		8
; can't use it now, free it or wait

; misc constants -- DEPRECATED
#define	_cr		13
#define	_lf		10
#define	_ff		12
#define	_bs		8
#define	_bel		7

; these are temporary, thus no underscore yet
; to be determined... from _d_num?
#define led_dev		240
#define lcd_dev		210
#define acia_dev	236
#define ss22_dev	250

; more temporary IDs 130504

; ascii-kbd(+lcd) = 241
; acia 2651 = 237
; VIA PA parallel port = 243
; (d)uart-16c550-1 = 232 hehehe
; duart-16c552-0 (or 2) = 224
; rtc 146818 (pseudo-driver?) = 208
; duart 2681-1 = 235 (or 227)
; duart 2681-2 = 227 (or 235)
