; minimOS 0.4b1 API
; (c) 2012-2013 Carlos J. Santisteban
; last modified 2013.02.08

; NEW 2012.12.26, driver code offsets, three more in 20130110
#define d_init		0
#define d_poll		2
#define d_req		4
#define d_in		6
#define d_out		8
#define d_1sec		10
#define d_bli		12
#define d_blo		14

; kernel function codes for macro _KERNEL()
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
#define	_OK		0	; not on 65xx, CLC instead
#define	_unavail	1	; unavailable on this version
#define	_timeout	2	; try later
#define	_full		3	; not enough memory, try less
#define	_not_found	4	; try another
#define	_no_rsrc	5	; no windows, try a different way
#define	_empty		6	; put some and retry
#define _invalid	7	; invalid argument, NEW@121216, rest was 121205
; new 20130206
#define _busy		8	; can't use it now, free it or wait

; misc constants
#define	_cr		13	; carriage return
#define	_lf		10	; line feed
#define	_ff		12	; form feed
#define	_bs		8	; backspace
#define	_bel		7	; acoustic alert

#define led_dev		0	; to be determined
#define lcd_dev		160
#define acia_dev	136
#define ss22_dev	222
