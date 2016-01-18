; NetBoot module for minimOS firmware
; v0.5a1
; (c) 2015-2016 Carlos J. Santisteban
; last modified 20150309-1108
; revised 20160115 for commit with new filenames

#define		NETBOOT		_NETBOOT

; in case of standalone assembly 'xa firmware/modules/netboot.s'
#ifndef		FIRMWARE
#include "options.h"
#include "macros.h"
#include "abi.h"		; new filename
.zero
#include "zeropage.h"
.bss
#include "firmware/firmware.h"
sysvars = *				; free RAM from here
.text
#endif

nb_ptr = uz				; pointer in zeropage (typically $3)
nb_buf = nb_ptr+2		; 20-byte buffer in zeropage ($5)
nb_conv = nb_buf+20		; space for converted hex strings ($19)
nb_free = nb_conv+5		; space for firmware drivers ($1E)

netboot:
; initialise included driver
	JSR fwn_init
; establish link (intended for SS-22)
	LDA #$55			; link establishing code
	JSR nb_out			; send character thru simplified driver
	LDA #SPEED_CODE		; inform server about my speed
	JSR nb_out			; send character thru simplified driver
	JSR nb_in			; read character
	CMP #$22			; is it $22?
	BEQ nb_valid		; link acknowledged!
		JMP nb_end			; not a valid server
nb_valid:
	JSR nb_in			; read server's speed code
; serial link ignores speed code anyway...
; log in to the server
	LDX #>nb_log		; login string MSB
	LDY #<nb_log		; login string LSB
	JSR nb_sout			; send login ID string
	JSR nb_ack			; wait for acknowledge
; ask for jump table first
	LDX #>nb_ljump		; Ljump string MSB
	LDY #<nb_ljump		; Ljump string LSB
	JSR nb_sout			; send login ID string
	LDX #>nb_buf		; buffer MSB (or STZ)
	LDY #<nb_buf		; buffer LSB
	JSR nb_sin			; get size (and pos) hex string
	LDA nb_buf			; get first char in buffer
	CMP #'$'			; is it 16-bit size?
	BEQ nb_16t			; supported size
		JMP nb_end			; 32-bit not supported yet
nb_16t:
	LDX #1				; point to first hex char
	JSR nb_h2b			; convert to binary (16-bit)
	LDA nb_conv			; get size LSB
	BEQ nb_nlo1			; proper size
		JMP nb_logout		; not the proper size!
nb_nlo1:
	LDA nb_conv+1		; get size MSB
	CMP #1				; is it one page?
	BEQ nb_nlo2			; yes
		JMP nb_logout		; not!
nb_nlo2:
; get things ready to load ~/jump
	LDA #'A'			; send acknowledge
	JSR nb_out
	LDY #0				; reset offset
nb_jloop:
		JSR fwn_cin			; get binary byte
		BCC nb_good
			JMP nb_bad			; abort if error
nb_good:
		STA fw_table, Y		; copy into table
		INY
		BNE nb_jloop		; one page
; now try to get boot code
; *** check alternative code ***
	LDX #>nb_lboot		; Lboot string MSB (2)
	LDY #<nb_lboot		; Lboot string LSB (2)
	JSR nb_sout			; send login ID string (6...)
	LDX #>nb_buf		; buffer MSB (2)
	LDY #<nb_buf		; buffer LSB (2)
	JSR nb_sin			; get size (and pos) hex string (6...)
	LDA nb_buf			; get first char in buffer (3)
	CMP #'$'			; is it 16-bit size? (2)
		BEQ nb_16s			; supported size (3/2)
	CMP #'@'			; has start address? (0/2)
		BEQ nb_16a			; supported size (0/3/2)
		JMP nb_end			; 32-bit not supported yet (3)
nb_16s:
	LDA #<sysvars		; free RAM start LSB (2)
	STA nb_ptr			; store in pointer (3)
	LDA #>sysvars		; same for MSB (2+3)
	STA nb_ptr+1
	LDX #1				; set index from start (2)
	_BRA nb_size		; get size and go for it (3)
nb_16a:
	LDX #1				; point to first hex char (address) (2)
	JSR nb_h2b			; convert to binary (16-bit) (6...)
	LDA nb_conv			; get address LSB (3)
	STA nb_ptr			; store pointer (3)
	LDA nb_conv+1		; same for MSB (3+3)
	STA nb_ptr+1
	LDX #5				; point to hex size (2)
nb_size:
	JSR nb_h2b			; convert size into nb_conv (6...)
; *** end of alternative code ***
; get things ready to load ~/boot
; ...
	LDA #'A'		; send acknowledge
	JSR nb_out
nb_bloop:
; *********modified loop....

; *** useful routines ***
; convert 4-hex into 16-bit binary, X is index for nb_buf, writes on nb_conv
nb_h2b:
	LDY #1			; reset output index to MSB
nb_byte:
		JSR nb_nib			; get this nibble
		ASL					; shift four times
		ASL
		ASL
		ASL
		STA (nb_conv), Y	; write converted hi-nibble
		JSR nb_nib			; get other nibble
		AND #$0F			; mask out irrelevant bits (will substract 48 anyway)
		ORA (nb_conv), Y	; add to hi nibble
		STA (nb_conv), Y	; update final byte
		DEY					; now for new byte (LSB)
		BPL nb_byte
	RTS
nb_nib:
; convert hex char into nibble
	LDA nb_buf, X	; get char
	CMP #'A'		; is it a letter?
	BMI nb_numb		; if not, just modulo-16
		ORA #32			; lowercaps, numbers untouched
		SEC				; prepare for substraction
		SBC #'a'-'0'	; convert to value
nb_numb:
	INX				; go for next char
	RTS

; output a C-string (X=MSB, Y=LSB), Carry set in case of any problem
nb_sout:
	STY nb_ptr		; store LSB
	STX nb_ptr+1	; store MSB
	LDY #0			; reset offset
nb_oloop:
		LDA (nb_ptr), Y		; get char
		BEQ nb_oterm		; nothing else
		JSR fwn_cout			; send character
			BCS nb_bad		; error
		INY					; next char
		BCC nb_oloop		; no need for macro, NMOS savvy
nb_oterm:
	LDA #0			; terminate output
	JSR fwn_cout
		BCS nb_bad		; in case of error
	RTS

; get a string terminated with NULL, CR _or_ LF (X=MSB, Y=LSB), Carry set in case of any problem
nb_sin:
	STY nb_ptr		; store LSB
	STX nb_ptr+1		; store MSB
	LDY #0			; reset offset
	JSR nb_b_in		; get first byte without blanks
nb_iloop:
		STA (nb_ptr), Y
		INY					; next char
		JSR fwn_cin			; get it
			BCS nb_bad			; error
			BEQ nb_iterm			; done if null
		CMP #13				; CR?
			BEQ nb_iterm			; done
		CMP #10				; LF?
			BEQ nb_iterm			; done
		BNE nb_iloop		; no need for macro, NMOS savvy
nb_iterm:
	LDA #0
	STA (nb_ptr), Y		; terminate string***
	CLC				; no error, just in case
	RTS

; ignore extra blanks and get char after that, used anyway???
nb_b_in:
		JSR fwn_cin		; get char
			BCS nb_bad2		; error
			BEQ nb_b_in		; ignore if null
		CMP #13			; CR?
			BEQ nb_b_in		; ignore
		CMP #10			; LF?
			BEQ nb_b_in		; ignore
	RTS					; exit with char in A

; *** interface for driver functions ***
nb_out:
	JSR fwn_cout		; send character thru simplified driver
		BCC nb_bad		; nobody out there...
	RTS				; back to business
nb_bad2:
	PLA				; dismiss another return address, used anyway???
	PLA
nb_bad:
	PLA				; dismiss return address
	PLA
	BCC nb_in
		JMP nb_end		; abort because of timeout, no need for BRA
nb_in:
	JSR fwn_cin			; receive character
		BCS nb_bad		; error
	RTS
nb_ack:
	JSR fwn_cin		; get reply from server
		BCS nb_bad		; nobody there
	CMP #'A'		; acknowledged
		BNE nb_bad		; exit otherwise
	RTS

; *** command strings ***
nb_log:
	.asc	"!", _MACHINE_ID, 0		; short name for login
;*************************
nb_ljump:
	.asc	"Ljump", 0		; for loading jump table
nb_lboot:
	.asc	"Lboot", 0		; for loading boot code

; *** simplified driver for netbooting (or into firmware?) ***
#include "firmware/modules/fd_6551.s"	; ACIA
;#include "firmware/modules/fd_ss22.s"	; SS-22 link
; *** this is a dummy driver for netbooting, please remove if supplying a real one ***
;fwn_init:
;fwn_cin:
;fwn_cout:
;	RTS				; dummy driver!

nb_logout:		; ??????
; go away and proceed with preinstalled kernel
nb_end:


