; bootloader test
; *** must be signed above $C000 but BELOW $FF80 ***
#define	MULTIBOOT

; first ROM
*	= $8000

.(
#include "../../apps/pacman/intro.s"
.)
	.dsb	$C000-*, $FF	; filling until next bank

.(
#include "durango-test.s"
.)
	.dsb	$FF80-*, $FF	; filling until boot ROM

#include "../bootloader.s"
