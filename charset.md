# minimOS Character Set

Focused on limited resource platforms, the standard **character set** for minimOS
had to satisfy the following:

- **Single-byte** sequences (for easier/faster parsing).
- Reasonably adhesion to actual standards for convenient **compatibility**.
- Support for **Spanish** characters... plus some other *personal interests* of mine.

Another consideration was trying to match the text-LCD modules charset as much as
possible.

Currently, it is *loosely* based on **ISO 8859-1**. It does however include the
**Euro** sign from 8859-15.

On the other hand, as *C1 control codes* were not defined on that standard, those
were replaced with the following characters from other architectures:

- 128-143 ($80-$8F) are the **Sinclair ZX Spectrum *semi-graphic*** characters.
- 144-159 ($90-$9F) come from $E0-$EF of **code page 437** (*selected Greek for Maths*)
but with four substitutions for equal or similar characters (vgr. using *Beta*
instead of *Eszett*). These alterations are filled with some other characters from
CP437 in the range $F0-$FF which were deemed interesting, like the *check mark*
(actually derived from the *radical sign*), approximation and non-strict
inequalities.
 
Up to 190 ($BE) there are some differences from ISO 8859-1. Beyond that, they are just
the same -- and also like *Windows-1252*, for that matter.

The aforementioned differences include:

- *Non-Breaking space* (160, $A0) is replaced by a hollow square/rectangle. Where
needed, its functionality may be provided by code 128/$80 Spectrum graphic (which
shows up as a blank space anyway).
- *Soft hyphen* (173, $AD) is replaced by the (seldom found on single-byte encodings!)
**slashed equal**.
- *Cedilla* (184, $B8) is not needed as Iberian & Gallic keyboards have the
*C-cedilla* key available, thus is replaced by **lowercase omega**. *This encoding
is already used on some HD44780-based LCD text displays*. 
- *Superscript 1* (185, $B9), unlike the superscript 2 & 3, makes little sense to me,
thus replaced by **uppercase delta**.
- *Fractions* (188-190, $BC-$BE) were to be replaced by *French ligatures and uppercase
Y with diaeresis* but, albeit current, they are rarely used. The latter is replaced
by the **eng** character (required by Wolof language) while the first one will get
the **bullet** character. Note that the *lowercase **oe** ligature* is kept from
ISO 8859-15 as, like the Y with diaeresis, may be an acceptable substitute for the
(rare) appearances of their uppercase counterparts.

## non-ASCII character table

mOS|$x0|$x1|$x2|$x3|$x4|$x5|$x6|$x7|$x8|$x9|$xA|$xB|$xC|$xD|$xE|$xF
---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---
**$8x**| |&#9629;|&#9624;|&#9600;|&#9623;|&#9616;|&#9626;|&#9628;|&#9622;|&#9630;|&#9612;|&#9627;|&#9604;|&#9631;|&#9625;|&#9608;
**$9x**|&#945;|&#10003;|&#915;|&#960;|&#931;|&#963;|&#8804;|&#964;|&#8805;|&#1012;|&#937;|&#948;|&#8734;|&#8776;|&#8712;|&#8745;
**$Ax**|&#9633;|¡|&#162;|£|€|&#165;|&#166;|&#167;|&#168;|&#169;|&#170;|&#171;|&#172;|&#8800;|&#174;|&#175;
**$Bx**|°|&#177;|&#178;|&#179;|&#180;|&#181;|&#182;|&#183;|&#969;|&#916;|&#186;|&#187;|&#8226;|&#339;|&#331;|¿
**$Cx**|À|Á|Â|Ã|Ä|Å|Æ|Ç|È|É|Ê|Ë|Ì|Í|Î|Ï
**$Dx**|Đ|Ñ|Ò|Ó|Ô|Õ|Ö|×|Ø|Ù|Ú|Û|Ü|Ý|&#222;|&#223;
**$Ex**|à|á|â|ã|ä|å|æ|ç|è|é|ê|ë|ì|í|î|ï
**$Fx**|đ|ñ|ò|ó|ô|õ|ö|÷|ø|ù|ú|û|ü|ý|&#254;|&#255;

## Control characters

^ key|Dec|Hex|ASCII|mOS|glyph|notes
-----|---|---|-----|---|-----|-----
|0|$00|`NUL`|**`NULL`**||(1)
A|1|$01|`SOH`|**`HOME`**|&#8689;|reset cursor without clearing screen
B|2|$02|`STX`|**`LEFT`**|&#8678;|move cursor to the left (no backspace)
C|3|$03|`ETX`|**`TERM`**||send TERM signal
D|4|$04|`EOT`|**`ENDT`**|&#8690;|end of text
E|5|$05|`ENQ`|**`ENDL`**|&#8608;|move cursor to end of line
F|6|$06|`ACK`|**`RGHT`**|&#8680;|move cursor to the right (no space)
G|7|$07|`BEL`|**`BELL`**||acoustic or visual alert
H|8|$08|`BS`|**`BKSP`**|&#8602;|backspace, clear previous character
I|9|$09|`HT`|**`HTAB`**|&#8677;|advance to next tab, printing spaces
J|10|$0A|`LF`|**`DOWN`**|&#8681;|cursor down (no CR)
K|11|$0B|`VT`|**`UPCU`**|&#8679;|cursor up one line
L|12|$0C|`FF`|**`FRMF`**||clear screen (2)
M|13|$0D|`CR`|**`NWLN`**||newline, ZX Spectrum-like
N|14|$0E|`SO`|**`EMON`**||emphasis on
O|15|$0F|`SI`|**`EMOF`**||emphasis off
P|16|$10|`DLE`|**`DLE`**||do not interpret next control char (3) 
Q|17|$11|`DC1`|**`XON`**|&#8658;|cursor on (when available)
R|18|$12|`DC2`|**`INK`**||set foreground colour (3)(4)
S|19|$13|`DC3`|**`XOFF`**|&#8656;|cursor off
T|20|$14|`DC4`|**`PAPR`**||set background colour (3)(4)
U|21|$15|`NAK`|**`CRTN`**|&#8606;|carriage return (without line feed)
V|22|$16|`SYN`|**`PGDN`**|&#8609;|page down
W|23|$17|`ETB`|**``**||
X|24|$18|`CAN`|*`BKTB`**|&#8676;|backwards tabulation
Y|22|$19|`EM`|**`PGUP`**|&#8607;|page up
Z|26|$1A|`SUB`|**``**||
|27|$1B|`ESC`|**`ESC`**|&#11017;|escape
|28|$1C|`FS`|**``**||
|29|$1D|`GS`|**``**||
|30|$1E|`RS`|**``**||
|31|$1F|`US`|**``**||

### Notes:

1.If sent to `CONIO`, will issue an input.
2.If sent to `CONIO`, reset the standard device.
3.Takes a second character to complete
4.Currently only low nibble used as `GRgB` or `G2 R2 G1 B2`. *High nibble may be used
(when supported) as `R1 G0 R0 B1`*.

*last modified 20190323-1152*
