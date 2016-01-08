; minimOS 0.4a2 API
; (c) 2012 Carlos J. Santisteban
; last modified 2012.12.05

; kernel function codes for macro _KERNEL()
#define	_cout		0
#define	_cin		2
#define	_malloc	4
#define	_free		6
#define	_open_w	8
#define	_close_w	10
#define	_free_w	12
#define	_hid_push	14
#define	_b_fork	16
#define	_b_exec	18
#define	_load_link	20
#define	_su_poke	22
#define	_su_peek	24
#define	_string	26

; error codes
#define	_OK		0	; not on 65xx, CLC instead
#define	_unavail	1	; unavailable on this version
#define	_timeout	2	; try later
#define	_full		3	; not enough memory, try less
#define	_not_found	4	; try another
#define	_no_rsrc	5	; no windows, try a different way
#define	_empty		6	; put some and retry

; misc constants
#define	_cr		13	; carriage return
#define	_lf		10	; line feed
#define	_ff		12	; form feed
#define	_bs		8	; backspace
#define	_bel		7	; acoustic alert