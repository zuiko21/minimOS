/*
Copyright 2009-2010 Ed.Spittles@gmail.com

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

http://www.gnu.org/licenses/gpl-2.0.html
*/

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <curses.h>
#include "cpu.h"

#define MEMSIZE (1024 * 1024)
byte addressSpace[MEMSIZE];
static byte bank[0x10][0x4000];

static char *program= 0;

byte BlockingRead( void )
{
    return (byte)( getchar() );
}   

byte NonBlockingRead( void )
{
    return 0x00;
}   

void Emit( byte b )
{
    putchar( (int)b );
    fflush( stdout );
}   

void EMUL_handleWDM(byte opcode, word32 timestamp)
{
  fprintf( stderr, "WDM executing at time %d\n", timestamp );
  // we could use WDM as an emulator escape for tracing, stack dump, stdio
  CPU_debug();
}

void EMUL_hardwareUpdate(word32 timestamp)
{
  // fprintf( stderr, "EMUL_hardwareUpdate firing an IRQ at time %d\n", timestamp );
  // fprintf( stderr, "!" );
  CPU_addIRQ( 1 );
}

#define op_RTS (0x60)
#define op_RTI (0x40)
#define op_WDM (0x42)

byte oswrch(word32 address, word32 timestamp)
{
  Emit( A.B.L );
  return op_RTS;
}

byte osword(word32 address, word32 timestamp)
{
  byte *params= &addressSpace[0] + X.B.L + (Y.B.L << 8);

  switch( A.B.L )
    {
    case 0x00: /* input line */
      /* On entry: XY+0,1=>string area,
       *	   XY+2=maximum line length,
       *	   XY+3=minimum acceptable ASCII value,
       *	   XY+4=maximum acceptable ASCII value.
       * On exit:  Y is the line length (excluding CR),
       *	   C is set if Escape terminated input.
       */
      {
	word32  offset= params[0] + (params[1] << 8);
	byte   *buffer= &addressSpace[0] + offset;
	byte    length= params[2], minVal= params[3], maxVal= params[4], b= 0;

	if (!fgets((char *)buffer, length, stdin))
	  {
	    fprintf( stderr, "osword 0x00 failed to read a line\n" );
	    putchar('\n');
	  }
	for (b= 0;  b < length;  ++b)
	  if ((buffer[b] < minVal) || (buffer[b] > maxVal) || ('\n' == buffer[b]))
	    break;

	buffer[b]= 13;
	Y.B.L= b;
	P &= 0xFE;
	break;
      }

    default:
      {
	fprintf( stderr, "bad osword: A:%01x X:%01x Y:%01x\n", A.B.L, X.B.L, Y.B.L );
	// might as well see if it works without trapping
        return MEM_readMem( address, timestamp, 0 );
      }
    }

  return op_RTS;
}

byte osbyte(word32 address, word32 timestamp)
{

  switch ( A.B.L )
    {
    case 0x7A:  /* perform keyboard scan */
      X.B.L= 0x00;
      break;

    case 0x7E:  /* acknowledge detection of escape condition */
      break;

    case 0x83:	/* read top of OS ram address (OSHWM) */
      Y.B.L= 0x0E;
      X.B.L= 0x00;
      break;

    case 0x84:	/* read bottom of display ram address */
      Y.B.L= 0x80;
      X.B.L= 0x00;
      break;

    case 0xDA:  /* read/write number of items in vdu queue (stored at 0x026A) */
      // just run the opcode we fetched
      return MEM_readMem( address, timestamp, 0 );
      break;

    default:
      fprintf( stderr, "bad osbyte: A:%01x X:%01x Y:%01x\n", A.B.L, X.B.L, Y.B.L );
      break;
    }

  return op_RTS;
}

byte MEM_readMem(word32 address, word32 timestamp, word32 flags)
{
  // maybe we should emulate address folding
  address = address % MEMSIZE;

  if( address >= MEMSIZE ) {
    // if only we had a trace buffer
    fprintf( stderr, "disaster: read outside memory bounds at time %d\n", timestamp );
    CPU_debug();

    /* simple stack trace - should probably be an option to CPU_debug */
    int i = S.W & 0xFFF0;
    int j;
    for( j = 0; j < 64; j++ )
    {
        if( ( j & 15 ) == 0 ) fprintf( stderr, "\n%04X - ", i );
        if( i == S.W ) fprintf( stderr, "*%02X", MEM_readMem(i,timestamp,0) );
        else           fprintf( stderr, " %02X", MEM_readMem(i,timestamp,0) );
        i+=1;
    }
    fprintf( stderr, "\n" );
    abort();
  }

    // example: simple emulation of i/o
    // if( address > 0x3FFFFF )    return 0x00;
    // if( address > 0x2FFFFF )    return NonBlockingRead();
    // if( address > 0x1FFFFF )    return BlockingRead();
    // if( address > 0x0FFFFF )    return 0x00; /* unused at the moment */

    // BBC model B i/o emulation
/*    if( address >= 0x00FE40 && address <= 0x00FE4F )    return 0x00;
    if( address >= 0x00FC00 && address <= 0x00FEFF )    return 0xFF;

  // model hardware redirection of 816-mode vectors into bank 1
  if( ((flags & EMUL_PIN_VP) != 0) && (E == 0) ){
    address |= 0x010000;
  }*/

  if( (flags & EMUL_PIN_SYNC) == 0 ){
    // not an opcode fetch so no further processing
//    return addressSpace[address];
  }

  // The remainder handles opcode fetches
  //   - to turn tracing on and off
  //   - for OS emulation
  //   - for patching any routines which are hard to emulate

  // enable tracing on some condition:
  // when we're deep enough into emulation
  //  if( timestamp < 10 ) {
  // when we start user code
  if( address == 0x002000 ) {
    //      CPU_setTrace( 1 );
  }
  // disable tracing on some condition:
  // when time has passed
  //  if( timestamp > 1000 ) {
  // when we visit or return to BASIC code, or get to the BASIC prompt
  if( address == 0x008af6 ) {
//      CPU_setTrace( 0 );
  }
  // note any RTI instructions
  // if ( addressSpace[address] == op_RTI ){
  //   fprintf( stderr, "^" );
  // }

/*  if( address == 0x00F055 ) { // unexpected interrupt during startup indirects to ECONET
    return op_RTS;
  }

  // sysmon/sbc3
  if( address == 0x00F241 ||
      address == 0x00F286 ||
      address == 0x00F2f9 
      ) {  // SPI handler - polls endlessly
    return op_RTS;
  }
  // sysmon / sbc3
  if( address == 0x00EEC4 ) { // putc aka oswrch
    return oswrch( address, timestamp );
  }
  if( address == 0x00f2bd ) { // getc
    A.B.L = getchar();
    return op_RTS;
  }*/
  // ehbasic
  if( address == 0x00c0c2 ) { // putc aka oswrch
    return oswrch( address, timestamp );
  }
  if( address == 0x00c0bf ) { // getc
    A.B.L = getchar();
    return op_RTS;
  }

  // bbc os
 /* if( address == 0x00FFEE || address == 0x00E0A4 ) { // oswrch and nvwrch
    return oswrch( address, timestamp );
  }
  if( address == 0x00FFF1 ) {
    return osword( address, timestamp );
  }
  if( address == 0x00FFF4 ) {
    return osbyte( address, timestamp );
  }
  if( address >= 0x00FF00 && address <= 0x00FFFF &&
      address < 0x00FFE3 && address > 0x00FFEC ) {  // allowing osasci, osnewl, oswrcr
    fprintf( stderr, "Possible attempted BBC OS call at 0x%06x\n", address );
  }*/

    return addressSpace[address];

}

void MEM_writeMem(word32 address, byte b, word32 timestamp)
{
  address = address % MEMSIZE;

/*    if( address == 0x00FE09 ) { Emit(b); return; } // BBC ACIA data register
    if( address >= 0x00FE30 && address <= 0x00FE33 ) {  // BBC ROM select register
      memcpy(addressSpace + 0x8000, bank[b & 0x0F], 0x4000);
    }
    if( address > 0x1FFFFF )    return; /* unused at the moment */
    if( address > 0x0FFFFF ) {  Emit(b); return; }

    addressSpace[address] = b;
}

void LoadROMs( void )
{
    union { int I; struct { char B0, B1, B2, B3; } B; } loadAddress;
    FILE *fh;

    fprintf( stderr, "Reading ROM.PRG\n" );
    fh = fopen( "ROM.PRG", "rb" );
    if( fh != NULL )
    {
        fread( &(loadAddress.B.B0), 1, 1, fh );
        fread( &(loadAddress.B.B1), 1, 1, fh );
        loadAddress.I &= 0xFFFF;

        while( !feof( fh ) )
        {   
            fread( &addressSpace[ loadAddress.I ], 1, 1, fh );
            // printf( ".M %04lX %02lX\n", loadAddress.I, addressSpace[ loadAddress.I ] );
            loadAddress.I = (loadAddress.I+1) & 0xFFFF;
        }   

        fclose( fh );
    }
}

/* some routines borrowed with modifications from run6502 */

void fail(const char *fmt, ...)
{
  va_list ap;
  fflush(stdout);
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
  fprintf(stderr, "\n");
  exit(1);
}

void pfail(const char *msg)
{
  fflush(stdout);
  perror(msg);
  exit(1);
}

static unsigned long htol(char *hex)
{
  char *end;
  unsigned long l= strtol(hex, &end, 16);
  if (*end) fail("bad hex number: %s", hex);
  return l;
}

static int loadInterpreter( word32 start, const char *path )
{
  FILE   *file= 0;
  int     count= 0;
  byte   *memory= addressSpace + start;
  size_t  max= 0x10000 - start;
  int     c= 0;

  if ((!(file= fopen(path, "rb"))) || ('#' != fgetc(file)) || ('!' != fgetc(file)))
    return 0;
  while ((c= fgetc(file)) >= ' ')
    ;
  while ((count= fread(memory, 1, max, file)) > 0)
    {
      memory += count;
      max -= count;
    }
  fclose(file);
  return 1;
}

static int load(word32 address, const char *path)
{
  FILE  *file= 0;
  int    count= 0;
  size_t max= 0x10000 - address;
  if (!(file= fopen(path, "rb")))
    return 0;
  fprintf(stderr, "loading ROM file %s\n", path);
  while ((count= fread(addressSpace + address, 1, max, file)) > 0)
    {
      address += count;
      max -= count;
    }
  fclose(file);
  return 1;
}

static void usage(int status)
{
    FILE *stream= status ? stderr : stdout;
    fprintf(stream, "usage: %s [option ...] -B [image ...]\n", program);
    fprintf(stream, "  -B                -- (mandatory) minimal Acorn 'BBC Model B' compatibility\n");
    fprintf(stream, "  -h                -- help (print this message)\n");
    fprintf(stream, "  -l addr file      -- load file at addr\n");
    fprintf(stream, "  image             -- '-l 8000 image' in available ROM slot\n");
    fprintf(stream, "\n");
    fprintf(stream, "'last' can be an address (non-inclusive) or '+size' (in bytes)\n");
    exit(status);
}

static int doLoad(int argc, char **argv)    /* -l addr file */
{
  if (argc < 3) usage(1);
  if (!load(htol(argv[1]), argv[2])) pfail(argv[2]);
  return 2;
}

static int doHelp(int argc, char **argv)
{
  usage(0);
  return 0;
}

static int doBtraps(int argc, char **argv)
{
  unsigned addr;
  
  /* anything already loaded at 0x8000 appears in bank 0 */

  // fprintf(stderr, "copying 0x8000 area into bank 0\n");
  memcpy(bank[0x00], addressSpace + 0x8000, 0x4000);

  return 0;
} 


int main( int argc, char **argv )
{
  // it seems that the E_UPDATE and UpdatePeriod mechanisms are deprecated
  // in favour of the CPUEvent mechanism. I don't care: I just want regular IRQs
  // so I uncommented the E_UPDATE handling code in dispatch.c and built with
  //   make CCOPTS='-DDEBUG -DOLDCYCLES'

    int bTraps= 0;

    program= argv[0];

    if ((2 == argc) && ('-' != *argv[1]))
      {
	if ((!loadInterpreter( 0, argv[1] )) && (!load( 0, argv[1] )))
	  pfail(argv[1]);
	doBtraps( 0, 0 );
      }
    else
      while (++argv, --argc > 0)
      {
        int n= 0;
        if      (!strcmp(*argv, "-B"))  bTraps= 1;
        else if (!strcmp(*argv, "-h"))  n= doHelp(argc, argv);
        else if (!strcmp(*argv, "-l"))  n= doLoad(argc, argv);
        else if ('-' == **argv)         usage(1);
        else
          {
            /* doBtraps() left 0x8000+0x4000 in bank 0, so load */
            /* additional images starting at 15 and work down */
            static int bankSel= 0x0F;
            if (!bTraps)                   usage(1);
            if (bankSel < 0)               fail("too many images");
            if (!load(0x8000, argv[0]))    pfail(argv[0]);
	    // fprintf(stderr, "copying 0x8000 area into bank %d\n", bankSel);
            memcpy(bank[bankSel--],
                   0x8000 + addressSpace,
                   0x4000);
            n= 0; // was buggedly 1 in run6502
          }
        argc -= n;
        argv += n;
      }

    if (!bTraps)  // for now, we only handle BBC emulation
      usage(1);

    doBtraps( 0,0 );

    CPUEvent_initialize();
    CPU_setUpdatePeriod( 10000 );

    int cbreak(void);
    fprintf( stderr, "WARP FACTOR 5\n" );
    CPU_reset();
    // CPU_setTrace( 1 );
    CPU_run();
    int nocbreak(void);

    return 0;
}
