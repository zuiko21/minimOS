; *** echo server test for CONIO ***
; (c) 2022 Carlos J. Santisteban
; last modified 20221213-1750
; **********************************

	* = $F000

; try to assemble from here with
; xa echo.s -I ../../OS/firmware -l labels 
; may add -DKBBYPAD for optional keyboad-by-pad
; add -DKBDMAT for generic matrix keyboard support (instead of PASK)

;#define	KBBYPAD
#define		KBDMAT

; *****************************************************
; *** firmware & hardware definitions for Durango-X ***
; *****************************************************
fw_irq		= $0200			; ### usual minimOS interrupt vectors ###
fw_nmi		= $0202
;ticks		= $0206			; jiffy counter EEEEK
; make room for keyboard driver ($020A-$020F)
; CONIO specific variables
fw_cbin		= $0210			; integrated picoVDU/Durango-X specifics
fw_fnt		= fw_cbin+1		; (new, pointer to relocatable 2KB font file)
fw_mask		= fw_fnt+2		; (for inverse/emphasis mode)
fw_chalf	= fw_mask+1		; (remaining pages to write)
fw_sind		= fw_chalf+1
fw_ccol		= fw_sind+3		; (no longer SPARSE array of two-pixel combos, will store ink & paper)
fw_ctmp		= fw_ccol+4
fw_cbyt		= fw_ctmp		; (temporary glyph storage) other tmp
fw_ccnt		= fw_cbyt		; (bytes per raster counter, no longer X) actually the same tmp
fw_ciop		= fw_ccnt+1		; cursor position
fw_vbot		= fw_ciop+2		; page start of screen at current hardware setting (updated upon FF)
fw_vtop		= fw_vbot+1		; first non-VRAM page (new)
fw_io9		= fw_vtop+1		; received keypress
fw_scur		= fw_io9+1		; NEW, cursor control
fw_knes		= fw_scur+1		; NEW, NES-pad alternative keyboard
GAMEPAD_MASK1	= fw_knes+1	; EEEEEEEEK
; CONIO zeropage usage ($E4-$E7)
cio_pt		= $E6
cio_src		= $E4

; *** Durango-X hardware definitions ****
-IO8attr	= $DF80		; video mode register
-IO8blk		= $DF88		; video blanking signals
-IO9di		= $DF9A		; data input (PASK standard)
-IO9nes0	= $DF9C		; NES controller for alternative keyboard emulation & latch
-IO9nes1	= $DF9D		; NES controller clock port
-IOAie		= $DFA0		; canonical interrupt enable address (d0)
-IOBeep		= $DFB0		; canonical buzzer address (d0)


; *****************************
; *** include firmware here ***
; *****************************
; POST
reset:
	SEI						; usual 6502 stuff
	CLD
	LDX #$FF
	TXS
	STX IOAie				; ### enable Durango-X hardware interrupt ###
	STX fw_scur				; as bit 7 is on, activates cursor
	LDA #$38				; start in colour mode
	STA IO8attr
	LDX #3					; max jiffy counter index
jf_res:
;		STZ ticks, X		; reset all jiffy counter bytes
		STZ kb_asc, X		; init all keyboard variables too, up to kb_scan (4 bytes)
		DEX
		BPL jf_res
	LDX #>std_irq
	LDY #<std_irq
	STY fw_irq				; set standard interrupt vectors
	STX fw_irq+1
	LDX #>std_nmi			; danger if commented!
	LDY #<std_nmi
	STY fw_nmi
	STX fw_nmi+1
#ifdef	KBBYPAD
	LDA #'@'				; initial character for key-by-pad
	STA fw_knes
; init gamepad
	STA IO9nes0				; latch pad status
	LDX #8					; number of bits to read
nes_init:
		STA IO9nes1			; send clock pulse
		DEX
		BNE nes_init		; all bits read @ IO9nes0
	LDA IO9nes0				; get bits
	STA GAMEPAD_MASK1		; * MUST have a standard address, and MUST be initialised! *
#endif
; * check keyboard *
	LDX #0					; default is PASK
	LDA #32					; column 6
	STA IO9m5x8				; select it
	LDA IO9m5x8				; and read rows
	CMP #$2C				; is it a 5x8 matrix? EEEEEK
	BNE not_5x8
		LDX #2				; set as default keyboard
not_5x8:
	STX kb_type				; set selected type
; * init CONIO *
	STZ fw_cbin				; EEEEEEK
	STZ fw_mask
	STZ fw_io9
; select base colours from detected keyboard
	LDA #$87				; yellow on blue intial colours (matrix)
	LDX kb_type				; check type
	BNE not_pask			; matrix detected, keep beautiful colours...
		LSR					; ...or go orange-on-dark-green for PASK
not_pask:
	STA fw_ccol+1			; will reconstruct colours from this upon FF
	LDY #12					; FF = clear screen
	JSR conio
	CLI						; EEEEEEEEEEEEEEEEEEEEEEEEK

; echo server follows
echo:
		LDY #0				; input mode
		JSR conio
			BCS echo		; wait for a key
		JSR conio			; print it!
		LDA IO8attr
		EOR #64				; toggle inverse every key
		STA IO8attr
		BRA echo			; forever

; **************************
; *** interrupt handlers ***
; **************************
irq:
	JMP (fw_irq)			; standard minimOS vector
std_irq:					; IRQ support for EhBASIC, from min_mon.asm
	PHA
	PHX
	PHY						; needed for 5x8 matrix support
; *** interrupt support for matrix keyboard ***
	JSR kbd_isr
	TSX
	LDA $104, X				; get pushed PSR (note stack frame)
	AND #$10				; check BRK bit
	BEQ not_brk
; *** BRK happened *** will keep the LED flashing, as no debugger is installed
brk_panic:
std_nmi:					; NMI will just panic
				INX
				BNE brk_panic
			INY
			BNE brk_panic	; 0.2s delay
		INC					; cycle LED
		STA IOAie
		BRA brk_panic
not_brk:
	PLY						; for 5x8 matrix support
	PLX
	PLA
	RTI
nmi:
	JMP (fw_nmi)			; standard minimOS vector

; *** multi-keyboard support ***
kbd_isr:
	LDX kb_type
	JMP (kbd_drv, X)		; CMOS only
; drivers pointer list
kbd_drv:
	.word	drv_pask
	.word	drv_5x8
; generic PASK driver
drv_pask:
	LDA IO9pask				; PASK peripheral address
	STA kb_asc				; store for software
	RTS

; BIOS
#include "../../OS/macros.h"
; EMPTY definition from abi.h
#define	EMPTY	6
#define	SAFE
-conio:
#include "../../OS/firmware/modules/conio-durango-fast.s"

; keyboard driver
#ifdef	KBDMAT
#include "../../OS/firmware/modules/durango-5x8key.s"
#endif

echo_end:					; for size computation

; *** padding, signatures and hardware vectors ***

	.dsb	$FFD6-*, $FF
	.asc	"DmOS"			; minimOS-compliant Durango-X cartridge signature
	.dsb	$FFDE-*, $FF
	.word	$FFFF			; Fletcher-16 checksum placeholder

	.dsb	$FFFA-*, $FF	; *** may place PANIC routine here ***

	.word	nmi				; standard 6502 hardware vectors
	.word	reset
	.word	irq

