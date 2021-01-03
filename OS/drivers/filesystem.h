; filesystem pseudo-driver static variables for minimOS
; v0.5a1, seems OBSOLETE since 2015
; (c) 2015-2021 Carlos J. Santisteban
; last modified 20150309-1101

fs_devs		.dsb	_MAX_FILES		; virtual devices for open files
fs_masks	.dsb	_MAX_BRAIDS*256	; ???
fs_tab		.dsb	_MAX_VOLS*16	; mounted volumes
