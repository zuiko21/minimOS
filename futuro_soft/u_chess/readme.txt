By gracious permission of Peter Jennings, the original author and copyright 
holder of "MicroChess", I present my modified version for my 65C02 SBC. 

This program and its associated documentation are provided for your personal 
use only and appear here exclusively by permission of the copyright holder. 
Please contact the copyright holder before re-distributing, re-publishing 
or disseminating this copyrighted work. Microchess is not GPL or in the 
public domain. Please respect the author's copyright. 

Downloading this program indicates your acceptance of all license terms. 
This particular version is freeware as long as the copyright messages are left 
intact.


Microchess was developed in 1976, originally for the KIM-1. Later versions 
included 1.5, ported to the Commodore PET and Commodore Chessmate; and 2.0, 
for the Apple II and the Tandy Color Computer series.  I am including a 
scanned copy of the original source code (See file uchess.pdf) for those 
who wish to study the program's logic and strategy.   


To play, load the program using the new "U" command from the SBC's monitor.
"U" performs an xmodem/crc upload from your PC to the SBC's RAM.  The file 
will load into address's starting at $1000 and is just under 1.5k.

To run it, type "1000G<Enter>" from the monitor.  Note, the board was designed
to be viewed using a white text on dark background.  Therefore, the empty squares
that are white will have ** in them, while the black squares are filled with 
spaces.  Hopefully, this won't confuse everyone.  If it does, then feel free to
alter the code just before POUT25 to reverse the characters.

Commands are:
C - clear and restart the game (when entered, CCCCCC will appear)
E - toggle sides (when entered, EEEEEE will appear) 
P - tell the computer to "Play Chess".  By default, the computer will play white.
    To play black, after clearing the game, press E to switch sides, enter your 
    move (as described below), and then press P.  
<Enter> - give the computer YOUR move
Q - Quit the Game (JMP's to address $E800 (the SBC monitor entry point)

You must clear (i.e. reset) the game when you play it for the first time 
in a session.  The game is not cleared automatically for you when you start 
the program. 

The computer will display its move in ax yy zz format, where 
'a' is the player (0 if computer, 1 if yours)
'x' is the chess piece (memory locations of your pieces and the computer's 
    pieces in parentheses): 

    0: King            (you, 0060; computer, 0050)
    1: Queen           (you, 0061; computer, 0051)
    2: King's Rook     (you, 0062; computer, 0052)
    3: Queen's Rook     :
    4: King's Bishop    :
    5: Queen's Bishop   :
    6: King's Knight    :
    7: Queen's Knight   :
    8: K R Pawn         :
    9: Q R Pawn         :
    A: K N Pawn         :
    B: Q N Pawn         :
    C: K B Pawn         :
    D: Q B Pawn         :
    E: Q Pawn           :
    F: K Pawn          (you, 006F; computer, 005F)

'yy' and 'zz' are the from and to square respectively. Each ranges from 
    00 to 77, with 00 being the computer's queen rook, and 77 being your 
    king rook.  

For example, the move 0F 13 33 means King's Pawn from King's Pawn 2 to King's 
Pawn 4 (white).  The computer may take some time to compute its move and will 
print dots (.) as it thinks.  

To enter your move, enter FROM and TO locations (piece is not needed). 
The computer verifies your piece by showing what is on that FROM square; 
if it is one of your men, it will start with a 1. (An FF shows no piece 
there.) For example, should you key 63 43 and the screen reads 1F 63 43, 
that means KIM thinks your King's Pawn is there and that you're advancing 
it two spaces. When ready, press <Enter> to enter the move, and then 'P' 
to tell the computer to play.  The legality of your moves is never verified, 
and you may make multiple moves on a single turn -- as long as you press 
<Enter> after each one -- before pressing 'P' (in fact, as you'll see 
below, for special moves you will have to). You may move the computer's 
men at any time as well. The computer also does not warn you if you are 
in check, and its strategy expects that you will move out of check when 
you are placed in it. 

Castling is accomplished by moving the king, then rook, then pressing 'P'. 
If the computer signals a castle by moving its king two spaces over, you 
will need to also move its rook for it. 

While you of course can capture en passant by making the appropriate 
lateral capture and moving forward, the computer does not know how and 
will not construct its strategy with it in mind. 

Queening pawns must be done manually by altering the game board image 
from the SBC monitor. Stop the game with 'Q', remove the queened pawn by 
entering CC in its location (see table above) and set your Queen at 0061 
to this queened pawn. After adjustment, type '1000G<Enter>' to resume 
the game.  As only one Queen can be on the board at once, if you still have 
a Queen you must select some other captured piece and then move that as if 
it were a queen. The computer will also not autopromote its queened pawns, 
so you'll have to do that as well. 

The computer will resign if it ends up in checkmate or stalemate; the display 
will read 'ff ff ff'.  You are, of course, expected to show the same courtesy 
when you are checkmated, and restart the game. 

There are a few points of adjustment for skill level. By default, 08 at $11F5
 and FB at $10DE indicates normal mode with an average time per move of ~100s. 
If you are an impatient or poor player, try 00/FB for ~10 seconds "Blitz", 
or 00/FF for ~3 seconds "Super-Blitz".  Of course, the computer's ability 
to analyse moves will be progressively impaired. 

Openings can be loaded into locations $1541-$155C which Microchess will 
attempt to play from, as long as you do.  By default, the game will try 
to play the Giuoco Piano opening. 

Have fun! 

Daryl Rictor
65c02@softcom.net
