/* Perdita 65C02 Durango-X emulator!
 * (c)2007-2023 Carlos J. Santisteban, Emilio López Berenguer
 * last modified 20230415-1700
 * */

/* Gamepad buttons constants */
#define BUTTON_A			0x80
#define BUTTON_START		0x40
#define BUTTON_B			0x20
#define BUTTON_SELECT		0x10
#define BUTTON_UP			0x08
#define BUTTON_LEFT			0x04
#define BUTTON_DOWN			0x02
#define BUTTON_RIGHT		0x01
/* PSV Constants */
#define	PSV_DISABLE			0
#define PSV_FOPEN			0x11
#define PSV_FREAD			0x12
#define PSV_FWRITE			0x13
#define PSV_FCLOSE			0x1F
#define PSV_HEX				0xF0
#define PSV_ASCII			0xF1
#define PSV_BINARY			0xF2
#define PSV_DECIMAL			0xF3
#define PSV_INT 			0xF4
#define PSV_HEX16			0xF5
#define PSV_STOPWATCH_START	0xFB
#define PSV_STOPWATCH_STOP	0xFC
#define PSV_DUMP			0xFD
#define PSV_STACK			0xFE
#define PSV_STAT			0xFF


/* Binary conversion */
#define BYTE_TO_BINARY_PATTERN "[%c%c%c%c%c%c%c%c]"
#define BYTE_TO_BINARY(byte)  \
  (byte & 0x80 ? '1' : '0'), \
  (byte & 0x40 ? '1' : '0'), \
  (byte & 0x20 ? '1' : '0'), \
  (byte & 0x10 ? '1' : '0'), \
  (byte & 0x08 ? '1' : '0'), \
  (byte & 0x04 ? '1' : '0'), \
  (byte & 0x02 ? '1' : '0'), \
  (byte & 0x01 ? '1' : '0') 


#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <unistd.h>
// SDL Install: apt-get install libsdl2-dev. Build with -lSDL2 flag
#include <SDL2/SDL.h>
// arguments parser
#include <unistd.h>

/* type definitions */
	typedef uint8_t byte;
	typedef uint16_t word;

/* global variables */
	byte mem[65536];			// unified memory map
	byte gamepads[2];		 	// 2 gamepad hardware status
	byte gamepads_latch[2];	 	// 2 gamepad register latch
	int emulate_gamepads = 0;	// Allow gamepad emulation
	int emulate_minstrel = 1;	// Emulate Minstrel keyboard
	int gp1_emulated = 0; 		// Use keyboard as gamepad 1 (new layout WASD, Shift=start, Z=select, X='B', C=fire)
	int gp2_emulated = 0; 		// Use keyboard as gamepad 2 (new layout IJKL, N=start, M=select, Alt='B', Space=fire)
	int gp_shift_counter = 0;	// gamepad shift counter

	byte a, x, y, s, p;			// 8-bit registers
	word pc;					// program counter

	word screen = 0;			// Durango screen switcher, xSSxxxxx xxxxxxxx
	int scr_dirty = 0;			// screen update flag
	int	err_led = 0;
	int dec;					// decimal flag for speed penalties (CMOS only)
	int run = 3;				// allow execution, 0 = stop, 1 = pause, 2 = single step, 3 = run
	int ver = 0;				// verbosity mode, 0 = none, 1 = warnings, 2 = interrupts, 3 = jumps, 4 = events, 5 = all
	int fast = 0;				// speed flag
	int graf = 1;				// enable SDL2 graphic display
	int safe = 0;				// enable safe mode (stops on warnings and BRK)
	int nmi_flag = 0;			// interrupt control
	int irq_flag = 0;
	int typing = 0;				// auto-typing flag
	int type_delay;				// received keystroke timing
	FILE *typed;				// keystroke file
	long cont = 0;				// total elapsed cycles
	long stopwatch = 0;			// cycles stopwatch
    int dump_on_exit = 0;       // Generate dump after emulation

/* global vdu variables */
	// Screen width in pixels
	int VDU_SCREEN_WIDTH;
	// Screen height in pixels
	int VDU_SCREEN_HEIGHT;
	// Pixel size, both colout and HIRES modes
	int pixel_size, hpixel_size;
	//The window we'll be rendering to
	SDL_Window *sdl_window;
	//The window renderer
	SDL_Renderer* sdl_renderer;
	// Display mode
	SDL_DisplayMode sdl_display_mode;
	// Game gamepads
	SDL_Joystick *sdl_gamepads[2];
	// Minstrel keyboard
	byte minstrel_keyboard[5];
	// Do not close GUI after program end
	int keep_open = 0;
/* global sound variables */
	int sample_nr = 0;
	SDL_AudioSpec want;

//	Uint8	aud_buff[192];	// room for 4 ms of 48 kHz 8-bit mono audio
	Uint8	aud_buff[30576];// room for ~20 ms (one field) of 8-bit mono audio at CPU rate!
	int		old_t = 0;		// time of last sample creation
	int		old_v = 0;		// last sample value

	byte keys[8][256];		// keyboard map

/* Global PSV Variables */
	// PSV filename
	char psv_filename[100];
	int psv_index = 0;
	FILE* psv_file;

/* ******************* */
/* function prototypes */
/* ******************* */
/* emulator control */
	void load(const char name[], word adr);		// load firmware
	int ROMload(const char name[]);			// load ROM at the end, calling load()
    void displayInfoRom(const char name[]); // Display ROM header information
	void usage(char name[]);// help with command line options
	void stat(void);		// display processor status
	void stack_stat(void);	// display stack status
	void dump(word dir);	// display 16 bytes of memory
    void full_dump(void);    // Dump full memory space and registers to file
	void run_emulation(int ready);	// Run emulator
	int  exec(void);		// execute one opcode, returning number of cycles
	void illegal(byte s, byte op);				// if in safe mode, abort on illegal opcodes
	void process_keyboard(SDL_Event*);
	void emulate_gamepad1(SDL_Event *e);
	void emulate_gamepad2(SDL_Event *e);
	void emulation_minstrel(SDL_Event *e);

/* memory management */
	byte peek(word dir);			// read memory or I/O
	void poke(word dir, byte v);	// write memory or I/O
	void push(byte b)		{ poke(0x100 + s--, b); }		// standard stack ops
	byte pop(void)			{ return peek(++s + 0x100); }
	void randomize(void);

/* interrupt support */
	void intack(void);		// save status for interrupt acknowledge
	void reset(void);		// RESET & hardware interrupts
	void nmi(void);
	void irq(void);

/* opcode support */
	void bits_nz(byte b);	// set N&Z flags

	void asl(byte *d);		// shift left
	void lsr(byte *d);		// shift right
	void rol(byte *d);		// rotate left
	void ror(byte *d);		// rotate right

	void adc(byte d);		// add to A with carry
	void sbc(byte d);		// subtract from A with borrow, 6502-style
	void cmp(byte reg, byte d);		// compare, based on subtraction result

/* addressing modes */
	word am_a(void);		// absolute
	word am_ax(int*);		// absolute indexed X, possible penalty
	word am_ay(int*);		// absolute indexed Y, possible penalty
	byte am_zx(void)		{ return (peek(pc++) + x) & 255; }	// ZeroPage indexed X
	byte am_zy(void)		{ return (peek(pc++) + y) & 255; }	// ZeroPage indexed Y (rare)
	word am_ix(void);		// pre-indexed indirect X (rare)
	word am_iy(int*);		// indirect post-indexed Y, possible penalty
	word am_iz(void);		// indirect (CMOS only)
	word am_ai(void)		{ word j=am_a(); return peek(j)  |(peek(j+1)  <<8); }	// absolute indirect, not broken
	word am_aix(void)		{ word j=am_a(); return peek(j+x)|(peek(j+x+1)<<8); }	// absolute pre-indexed indirect (CMOS only)
	void rel(int*);			// relative branches, possible penalty

/* keymap */
	void redefine(void);

/* *********************** */
/* vdu function prototypes */
/* *********************** */

	int  init_vdu();		// Initialize vdu display window
	void close_vdu();		// Close vdu display window
	void vdu_draw_full();	// Draw full screen
	void vdu_read_keyboard();	// Read keyboard
/* vdu internal functions */
	void vdu_set_color_pixel(byte);
	void vdu_set_hires_pixel(byte);
	void vdu_draw_color_pixel(word);
	void vdu_draw_hires_pixel(word);
	void draw_circle(SDL_Renderer*, int32_t, int32_t, int32_t);
/* audio functions */
	void audio_callback(void *user_data, Uint8 *raw_buffer, int bytes);
	void sample_audio(int time, int value);

/* ************************************************* */
/* ******************* main loop ******************* */
/* ************************************************* */
int main(int argc, char *argv[])
{
	int index;
	int arg_index;
	int c, do_rand=1;
	char *filename;
	char *rom_addr=NULL;
	int rom_addr_int;

	redefine();		// finish keyboard layout definitions

	if(argc==1) {
		usage(argv[0]);
		return 1;
	}

	opterr = 0;

	while ((c = getopt (argc, argv, "a:fvlksphrgmd")) != -1)
	switch (c) {
		case 'a':
			rom_addr = optarg;
			break;
		case 'f':
			fast = 1;
			break;
		case 'k':
			keep_open = 1;
			break;
		case 'v':
			ver++;			// not that I like this, but...
			break;
		case 'l':
			err_led = 1;
			break;
		case 's':
			safe = 1;
			break;
		case 'p':
			run = 2;
			break;
		case 'h':
			graf = 0;
			break;
		case 'r':
			do_rand = 0;
			break;
		case 'g':
			emulate_gamepads = 1;
			break;
		case 'm':
			emulate_minstrel = 0;
			break;
        case 'd':
            dump_on_exit = 1;
            break;
		case '?':
			fprintf (stderr, "Unknown option\n");
			usage(argv[0]);
			return 1;
		default:
			abort ();
	}

	for (arg_index = 0, index = optind; index < argc; index++, arg_index++) {
		switch(arg_index) {
			case 0: filename = argv[index]; break;
		}
	}

	if(arg_index == 0) {
		printf("Filename is mandatory\n");
		return 1;
	}
	
	if(rom_addr != NULL && (strlen(rom_addr) != 6 || rom_addr[0]!='0' || rom_addr[1]!='x')) {
		printf("ROM address format: 0x0000\n");
		return 1;
	}

	if (do_rand)		randomize();		// randomize memory contents

	if(rom_addr == NULL) {
		run_emulation(ROMload(filename)==1);
	}
	else {
		rom_addr_int = (int)strtol(rom_addr, NULL, 0);
		load(filename, rom_addr_int);
/* set some standard vectors and base ROM contents */
		mem[0xFFF4] = 0x6C;					// JMP ($0200) as recommended for IRQ
		mem[0xFFF5] = 0x00;
		mem[0xFFF6] = 0x02;
		mem[0xFFF7] = 0x6C;					// JMP ($0202) as recommended for NMI
		mem[0xFFF8] = 0x02;
		mem[0xFFF9] = 0x02;
		mem[0xFFFA] = 0xF7;					// standard NMI vector points to recommended indirect jump
		mem[0xFFFB] = 0xFF;
		mem[0xFFFC] = rom_addr_int & 0xFF;	// set RESET vector pointing to loaded code
		mem[0xFFFD] = rom_addr_int >> 8;
		mem[0xFFFE] = 0xF4;					// standard IRQ vector points to recommended indirect jump
		mem[0xFFFF] = 0xFF;
                run_emulation(0);
	}

	return 0;
}

void usage(char name[]) {
	printf("usage: %s [-a rom_address] [-v] rom_file\n", name);	// in case user renames the executable
	printf("-a: load ROM at supplied address, example 0x8000\n");
	printf("-f fast mode\n");
	printf("-s safe mode (will stop on warnings and BRK)\n");
	printf("-p start in STEP mode\n");
	printf("-l enable error LED(s)\n");
	printf("-k keep GUI open after program end\n");
	printf("-h headless -- no graphics!\n");
	printf("-v verbose (warnings/interrupts/jumps/events/all)\n");
	printf("-r do NOT randomize memory at startup\n");
	printf("-g emulate controllers\n");
	printf("-m do NOT emulate Minstrel-type keyboard\n");
    printf("-d Generate dump after emulation\n");
}

void run_emulation (int ready) {
	int cyc=0, it=0;		// instruction and interrupt cycle counter
	int ht=0;				// horizontal counter
	int line=0;				// line count for vertical retrace flag
	int stroke;				// received keystroke
	clock_t next;			// delay counter
	clock_t sleep_time;		// delay time
	clock_t min_sleep;		// for peek performance evaluation
	clock_t render_start;	// for SDL/GPU performance evaluation
	clock_t render_time;
	clock_t max_render;
	long frames = 0;		// total elapsed frames (for performance evaluation)
	long ticks = 0;			// total added microseconds of DELAY
	long us_render = 0;		// total microseconds of rendering
	long skip = 0;			// total skipped frames

	printf("[F1=STOP, F2=NMI, F3=IRQ, F4=RESET, F5=PAUSE, F6=DUMP, F7=STEP, F8=CONT, F9=LOAD]\n");
	if (graf)	init_vdu();
	if(!ready) {
                reset();				// ready to start!
        }

	next=clock()+19906;		// set delay counter, assumes CLOCKS_PER_SEC is 1000000!
	min_sleep = 19906;		// EEEEEEK
	max_render = 0;

	while (run) {
/* execute current opcode */
		cyc = exec();		// count elapsed clock cycles for this instruction
		cont += cyc;		// add last instruction cycle count
		sample_nr += cyc;	// advance audio sample cursor (at CPU rate!)
		it += cyc;			// advance interrupt counter
		ht += cyc;			// both get slightly out-of-sync during interrupts, but...
/* check horizontal counter for HSYNC flag and count lines for VSYNC */
		if (ht >= 98) {
			ht -= 98;
			line++;
			if (line >= 312) {
				line = 0;						// 312-line field limit
				sample_nr -= 30576;				// refresh audio sample
				sample_audio(sample_nr, old_v);
				frames++;
				render_start = clock();
				if (graf && scr_dirty)	vdu_draw_full();	// seems worth updating screen every VSYNC
				render_time = clock()-render_start;
				us_render += render_time;					// compute rendering time
				if (render_time > max_render)	max_render = render_time;
/* make a suitable delay for speed accuracy */
				if (!fast) {
					sleep_time=next-clock();
					ticks += sleep_time;		// for performance measurement
					if (sleep_time < min_sleep)		min_sleep = sleep_time;		// worse performance so far
					if(sleep_time>0) {
						usleep(sleep_time);		// should be accurate enough
					} else {
						skip++;
						if (!ver) {
							printf("!");		// not enough CPU power!
						}
					}
					next=clock()+19906;			// set next frame time (more like 19932)
				}
			}
			mem[0xDF88] &= 0b10111111;			// replace bit 6 (VSYNC)...
			mem[0xDF88] |= (line&256)>>2;		// ...by bit 8 of line number (>=256)
		}
		mem[0xDF88] &= 0b01111111;		// replace bit 7 (HSYNC)...
		mem[0xDF88] |= (ht&64)<<1;		// ...by bit 6 of bye counter (>=64)
/* check hardware interrupt counter */
		if (it >= 6144)		// 250 Hz interrupt @ 1.536 MHz
		{
			it -= 6144;		// restore for next
/* get keypresses from SDL here, as this get executed every 4 ms */
			vdu_read_keyboard();	// ***is it possible to read keys without initing graphics?
/* may check for emulated keystrokes here */
			if (typing) {
				if (--type_delay == 0) {
					stroke = fgetc(typed);
					if (stroke == EOF) {
						typing = 0;
						printf(" OK!\n");
						fclose(typed);
						mem[0xDF9A] = 0;
					} else {
						type_delay = 25;		// just in case it scrolls
						if (stroke == 10) {
							stroke = 13;		// standard minimOS NEWLINE
							type_delay = 50;	// extra safe value for parsers
						}
						mem[0xDF9A] = stroke;
					}
				} else mem[0xDF9A] = 0;			// simulate PASK key up
			}
/* generate periodic interrupt */ 
			if (mem[0xDFA0] & 1) {
				irq();							// if hardware interrupts are enabled, send signal to CPU
			}
			fflush(stdout);						// update terminal screen
		}
/* generate asynchronous interrupts */ 
		if (irq_flag) {		// 'spurious' cartridge interrupt emulation!
			irq_flag = 0;
 			irq();
 		}
		if (nmi_flag) {
			nmi_flag = 0;
			nmi();			// NMI gets executed always
		}
/* check pause and step execution */
		if (run == 2)	run = 1;		// back to PAUSE after single-step execution
		if (run == 1) {
			if (graf && scr_dirty)		vdu_draw_full();	// get latest screen contents
			stat();						// display status at every pause
			while (run == 1) {			// wait until resume or step...
				usleep(20000);
				vdu_read_keyboard();	// ...but keep checking those keys for changes in 'run'
			}
		}
	}

	if (graf)	vdu_draw_full();		// last screen update
	printf(" *** CPU halted after %ld clock cycles ***\n", cont);
	stat();								// display final status

/* performance statistics */
	if (!frames)	frames = 1;			// whatever
	printf("\nSkipped frames: %ld (%f%%)\n", skip, skip*100.0/frames);
	printf("Average CPU time use: %f%%\n", 100-(ticks/200.0/frames));
	printf("Peak CPU time use: %f%%\n", 100-(min_sleep/200.0));
	printf("Average Rendering time: %ld µs (%f%%)\n", us_render/frames, us_render/frames/200.0);
	printf("Peak Rendering time: %ld µs (%f%%)\n", max_render, max_render/200.0);
	if(keep_open) {
		printf("\nPress ENTER key to exit\n");
		getchar();
	}
    
    if(dump_on_exit) {
        full_dump();
    }

	if (graf)	close_vdu();
}

/* **************************** */
/* support functions definition */
/* **************************** */

/* display CPU status */
void stat(void)	{ 
	int i;
	byte psr = p;			// local copy of status
	const char flag[8]="NV.bDIZC";	// flag names

	printf("<PC=$%04X, A=$%02X, X=$%02X, Y=$%02X, S=$%02X, CLK=%ld>\n<PSR: ", pc-1, a, x, y, s, cont);
	for (i=0; i<8; i++) {
		if (psr&128)	printf("%c", flag[i]);
		else			printf("·");
		psr<<=1;			// next flag
	}
	printf("> [%04X]=%02X\n",pc-1, mem[pc-1]);
}

/* Display STACK status */
void stack_stat(void) {
	// Copy stack pointer
	byte i=s;

	// If stack is not empty
	if(i!=0xff) {
		// Iterate stack
		do {
			i++;
			printf("|%02X| \n", mem[0x0100+i]);
		} while (i<0xff);
	}
	printf("|==|\n\n");
}

/* display 16 bytes of memory */
void dump(word dir) {
	int i;

	printf("$%04X: ", dir);
	for (i=0; i<16; i++)		printf("%02X ", mem[dir+i]);
	printf ("[");
	for (i=0; i<16; i++)
		if ((mem[dir+i]>31)&&(mem[dir+i]<127))	printf("%c", mem[dir+i]);
		else 									printf("·");
	printf ("]\n");
}

void full_dump() {
	FILE *f;

	f = fopen("dump.bin", "wb");
	if (f != NULL) {
		// Write memory
		fwrite(mem, sizeof(byte), 65536, f); 
		// Write registers
		fputc(a, f);
		fputc(x, f);
		fputc(y, f);
		fputc(s, f);
		fputc(p, f);
		// Write PC
		fwrite(&pc, sizeof(word), 1, f);
		// Close file
		fclose(f);
		printf("dump.bin generated\n");
	}
	else {
		printf("*** Could not write dump ***\n");
		run = 0;
	}
}

void load_dump(const char name[]) {
	FILE *f;

	f = fopen(name, "rb");
	if (f != NULL) {
		// Read memory
		fread(mem, sizeof(byte), 65536, f); 
		// Read registers
		a = fgetc(f);
		x = fgetc(f);
		y = fgetc(f);
		s = fgetc(f);
		p = fgetc(f);
		// Read PC
		fread(&pc, sizeof(word), 1, f);
		// Close file
		fclose(f);
		printf("%s loaded\n",name);
	}
	else {
		printf("*** No available dump ***\n");
		run = 0;
	}
}

/* load firmware, arbitrary position */
void load(const char name[], word adr) {
	FILE *f;
	int c, b = 0;

	f = fopen(name, "rb");
	if (f != NULL) {
		do {
			c = fgetc(f);
			mem[adr+(b++)] = c;	// load one byte
		} while( c != EOF);

		fclose(f);
		printf("%s: %d bytes loaded at $%04X\n", name, --b, adr);
	}
	else {
		printf("*** Could not load image ***\n");
		run = 0;
	}
}

/* load ROM at the end of memory map */
int ROMload(const char name[]) {
	FILE *f;
	word pos = 0;
	long siz;

	f = fopen(name, "rb");
	if (f != NULL) {
		fseek(f, 0, SEEK_END);	// go to end of file
		siz = ftell(f);			// get size
		fclose(f);				// done for now, load() will reopen
		// If dump file
		if(siz == 65543) {
			printf("Loading memory dump file\n");
			load_dump(name);	// Load dump
			return 1;
		}
		// If rom bigger than 32K
		else if (siz > 32768) {
			printf("*** ROM too large! ***\n");
			run = 0;
			return -1;
		} else {
			pos -= siz;
            displayInfoRom(name);
			printf("Loading %s... (%ld K ROM image)\n", name, siz>>10);
			load(name, pos);	// get actual ROM image
			return 0;
		}
	}
	else {
		printf("*** Could not load ROM ***\n");
		run = 0;
		return -1;
	}
}

/* Read ROM header and display information */
void displayInfoRom(const char name[]) {
	FILE *f;
    byte header[256];
	int c, b = 0;
    char *title;
    char * description;

	f = fopen(name, "rb");
	if (f != NULL) {
		do {
			c = fgetc(f);
			header[b++] = c;	// load one byte
		} while( b <= 255);

		fclose(f);
        
        if(header[0]==0x0 && header[1]==0x64 && header[2]==0x58) {
            printf("DURANGO STANDARD ROM\n");
        
            title = (char*) header+0x0008;
            description = (char*) title+strlen(title)+1;
        
            printf("Title: %s\n", title);
            printf("Description: %s\n", description);
        }
	}
	else {
		printf("*** Error reading image ***\n");
		run = 0;
	}
}

/* *** memory management *** */
/* read from memory or I/O */
byte peek(word dir) {
	byte d = 0;					// supposed floating databus value?

	if (dir>=0xDF80 && dir<=0xDFFF) {	// *** I/O ***
		if (dir<=0xDF87) {				// video mode (high nibble readable)
			d = mem[0xDF80] | 0x0F;		// assume RGB mode and $FF floating value
		} else if (dir<=0xDF8F) {		// sync flags
			d = mem[0xDF88];
		} else if (dir==0xDF93) {		// Read from VSP
			if (mem[0xDF94]==PSV_FREAD) {
				if (!feof(psv_file)) {
					d = fgetc(psv_file);				// get char from input file
					if (ver)	printf("(%d)", d);		// DEBUG transmitted char
				} else {
					d = 0;				// NULL means EOF
					printf(" Done reading file\n");
					fclose(psv_file);	// eeeeek
					psv_file = NULL;
					mem[0xDF94] = PSV_DISABLE;			// no further actions
				}
			}							// cannot read anything if disabled, default d=0 means EOF anyway
			mem[0xDF93] = d;			// cache value
		} else if (dir==0xDF9B && emulate_minstrel) {	// Minstrel keyboard port EEEEEK
			switch(mem[0xDF9B]) {
				case 1: return minstrel_keyboard[0];
				case 2: return minstrel_keyboard[1];
				case 4: return minstrel_keyboard[2];
				case 8: return minstrel_keyboard[3];
				case 16: return minstrel_keyboard[4];
				case 32: return 0x2C;
			}
									// no separate if-else is needed because of the default d value
									// ...and $DF9B could be used by another device
		} else if (dir<=0xDF9F) {	// expansion port
			d = mem[dir];			// *** is this OK?
		} else if (dir<=0xDFBF) {	// interrupt control and beeper are NOT readable and WILL be corrupted otherwise
			if (ver)	printf("\n*** Reading from Write-only ports at $%04X ***\n", pc);
			if (safe)	run = 0;
		} else {					// cartridge I/O
			d = mem[dir];			// *** is this OK?
		}
	} else {
		d = mem[dir];				// default memory read, either RAM or ROM
	}

	return d;
}

/* write to memory or I/O */
void poke(word dir, byte v) {
	word psv_int;
    int psv_value;
    if (dir<=0x7FFF) {			// 32 KiB static RAM
		mem[dir] = v;
		if ((dir & 0x6000) == screen) {			// VRAM area
			scr_dirty = 1;		// screen access detected, thus window must be updated!
		}
	} else if (dir>=0xDF80 && dir<=0xDFFF) {	// *** I/O ***
		if (dir<=0xDF87) {		// video mode?
			mem[0xDF80] = v;	// canonical address
			screen = (v & 0b00110000) << 9;		// screen switching
			scr_dirty = 1;		// note window should be updated when changing modes!
		} else if (dir<=0xDF8F) {				// sync flags not writable!
			if (ver)	printf("\n*** Writing to Read-only ports at $%04X ***\n", pc);
			if (safe)	run = 0;
		} else if (dir==0xDF93) { // virtual serial port at $df93
			// Cache value
			mem[dir]=v;
			// If hex mode enabled
			if(mem[0xDF94]==PSV_HEX) {
				// Print hex value
				printf("[%02X]", mem[dir]);	
			}
			// If ascii mode enabled
			else if(mem[0xDF94]==PSV_ASCII) {
				// Print ascii
				printf("%c", mem[dir]);
			}
			// If binary mode enabled
			else if(mem[0xDF94]==PSV_BINARY) {
				// Print binary
				printf(BYTE_TO_BINARY_PATTERN, BYTE_TO_BINARY(mem[dir]));
			}
			// If decimal mode enabled
			else if(mem[0xDF94]==PSV_DECIMAL) {
				// Print decimal
				printf("[%u]", mem[dir]);
			}
            // If int mode enabled
			else if(mem[0xDF94]==PSV_INT) {
				// Save value
                psv_filename[psv_index++] = mem[dir];
                // Display value
                if(psv_index==2) {
                    // Print decimal
                    psv_int=psv_filename[0] | psv_filename[1]<<8;
                    if(psv_int<=0x7FFF) {
                        psv_value=psv_int;
                    }
                    else {
                        psv_value=psv_int-65536;
                    }
                    printf("[%d]", psv_value);	
                    psv_index=0;
                }
			}
            // If int mode enabled
			else if(mem[0xDF94]==PSV_HEX16) {
				// Save value
                psv_filename[psv_index++] = mem[dir];
                // Display value
                if(psv_index==2) {
                    // Print hex
                    printf("[%02X%02X]", psv_filename[0], psv_filename[1]);	
                    psv_index=0;
                }
			}
			// If file open mode enabled
			else if(mem[0xDF94]==PSV_FOPEN) {
				// Filter filename
				if(mem[dir] >= ' ') {
				// Save filename
					psv_filename[psv_index++] = mem[dir];
				} else {
					psv_filename[psv_index++] = '_';
				}
			}
			// If file write mode enabled
			else if(mem[0xDF94]==PSV_FWRITE) {
				// write to file
				fputc(mem[dir], psv_file);
			}
			// flush stdout
			fflush(stdout);
		} else if (dir==0xDF94) { // virtual serial port config at $df94
			// If stat print mode
			if(v==PSV_STAT) {
				// Print stat
				stat();
			}
			// If stack print mode
			else if(v==PSV_STACK) {
				stack_stat();
			}
			// If memory dump mode
			else if(v==PSV_DUMP) {
				full_dump();
			}
			// If stop stopwatch
			else if(v==PSV_STOPWATCH_STOP) {
				printf("t=%ld cycles\n", cont-stopwatch);
			}
			// If start stopwatch
			else if(v==PSV_STOPWATCH_START) {
				stopwatch = cont;
			}
			// Cache value
			else {
				mem[dir]=v;
			}
			// PSV file open
			if(v==PSV_FOPEN) {
				psv_index = 0;
				if (psv_file != NULL) {
					fclose(psv_file);	// there was something open
					psv_file = NULL;
					printf("WARNING: there was another open file\n");
				}
//				psv_filename[psv_index++]='p';
//				psv_filename[psv_index++]='s';
//				psv_filename[psv_index++]='v';
//				psv_filename[psv_index++]='_';
			}
			// PSV file write
			if(v==PSV_FWRITE) {
				psv_filename[psv_index] = '\0';
				// actual file opening
				if(psv_file == NULL) {
					psv_file =fopen(psv_filename,"wb");
					if (psv_file == NULL) {	// we want a brand new file
						printf("[%d] ERROR: can't write to file %s\n", psv_index, psv_filename);
						mem[0xDF94] = 0;								// disable VSP
					} else {
						printf("Opening file %s for writing...\n", psv_filename);
					}
				} else {
					printf("ERROR: file already open\n");
					mem[0xDF94] = 0;									// disable VSP
				}
			}
			// PSV file read
			if(v==PSV_FREAD) {
				psv_filename[psv_index] = '\0';		// I believe this is needed
				if(psv_file == NULL) {
					psv_file =fopen(psv_filename,"rb");
					if (psv_file == NULL) {	// we want a brand new file
						printf("[%d] ERROR: can't open file %s\n", psv_index, psv_filename);
						mem[0xDF94] = 0;			// disable VSP
					} else {
						printf("Opening file %s for reading...\n", psv_filename);
					}
				} else {
					printf("ERROR: file already open\n");
					mem[0xDF94] = 0;									// disable VSP
				}
//				mem[0xDF93]=fgetc(psv_file);		// not done at config time, wait for actual read!
			}
			// PSV file close
			if(v==PSV_FCLOSE && psv_file!=NULL) {
				// close file
				if(fclose(psv_file)!=0) {
					printf("WARNING: Error closing file %s\n", psv_filename);
				} else {
					printf(" Done with file!\n");
				}
				psv_file = NULL;
			}
			// flush stdout
			fflush(stdout);
		} else if (dir==0xDF9C) { // gamepad 1 at $df9c
			if (ver>2)	printf("Latch gamepads\n");
			gamepads_latch[0] = gamepads[0];
			gamepads_latch[1] = gamepads[1];
			gp_shift_counter = 0;
		} else if (dir==0xDF9D) { // gamepads 2 at $df9d 
			if (ver>2)	printf("Shift gamepads\n");
			if(++gp_shift_counter == 8) {
				mem[0xDF9C]=~gamepads_latch[0];
				mem[0xDF9D]=~gamepads_latch[1];
			}
			else {
				mem[0xDF9C]=0;
				mem[0xDF9D]=0;
			}
		} else if (dir<=0xDF9F) {	// expansion port?
			mem[dir] = v;			// *** is this OK?
		} else if (dir<=0xDFAF) {	// interrupt control?
			mem[0xDFA0] = v;		// canonical address, only D0 matters
			scr_dirty = 1;			// note window might be updated when changing the state of the LED!
		} else if (dir<=0xDFBF) {	// beeper?
			mem[0xDFB0] = v;		// canonical address, only D0 matters
			sample_audio(sample_nr, (v&1)?255:0);	// generate audio sample
		} else {
			mem[dir] = v;		// otherwise is cartridge I/O *** anything else?
		}
	} else {					// any other address is ROM, thus no much sense writing there?
		if (ver)	printf("\n*** Writing to ROM at $%04X ***\n", pc);
		if (safe)	run=0;
	}
}

/* *** interrupt support *** */
/* acknowledge interrupt and save status */
void intack(void) {
	push(pc >> 8);							// stack standard status
	push(pc & 255);
	push(p);

	p |= 0b00000100;						// set interrupt mask
	p &= 0b11110111;						// and clear Decimal mode (CMOS only)
	dec = 0;

	cont += 7;								// interrupt acknowledge time
}

/* reset CPU, like !RES signal */
void reset(void) {
	pc = peek(0xFFFC) | peek(0xFFFD)<<8;	// RESET vector

	if (ver > 1)	printf(" RESET: PC=>%04X\n", pc);

	p &= 0b11110111;						// CLD on 65C02
	p |= 0b00110100;						// these always 1, includes SEI
	dec = 0;								// per CLD above
	mem[0xDFA0] = 0;						// interrupt gets disabled on RESET!
	mem[0xDFB0] = 0;						// ...and so does BUZZER
	gamepads[0] = 0;						// Reset gamepad 1 register
	gamepads[1] = 0;						// Reset gamepad 2 register

	cont = 0;								// reset global cycle counter?
}

/* emulate !NMI signal */
void nmi(void) {
	intack();								// acknowledge and save

	pc = peek(0xFFFA) | peek(0xFFFB)<<8;	// NMI vector
	if (ver > 1)	printf(" NMI: PC=>%04X\n", pc);
}

/* emulate !IRQ signal */
void irq(void) {
	if (!(p & 4)) {								// if not masked...
		p &= 0b11101111;						// clear B, as this is IRQ!
		intack();								// acknowledge and save
		p |= 0b00010000;						// retrieve current status

		pc = peek(0xFFFE) | peek(0xFFFF)<<8;	// IRQ/BRK vector
		if (ver > 1)	printf(" IRQ: PC=>%04X\n", pc);
	}
}

/* *** addressing modes *** */
/* absolute */
word am_a(void) {
	word pt = peek(pc) | (peek(pc+1) <<8);
	pc += 2;

	return pt;
}

/* absolute indexed X */
word am_ax(int *bound) {
	word ba = am_a();		// pick base address and skip operand
	word pt = ba + x;		// add offset
	*bound = ((pt & 0xFF00)==(ba & 0xFF00))?0:1;	// check page crossing

	return pt;
}

/* absolute indexed Y */
word am_ay(int *bound) {
	word ba = am_a();		// pick base address and skip operand
	word pt = ba + y;		// add offset
	*bound = ((pt & 0xFF00)==(ba & 0xFF00))?0:1;	// check page crossing

	return pt;
}

/* indirect */
word am_iz(void) {
	word pt = peek(peek(pc)) | (peek((peek(pc)+1)&255)<<8);	// EEEEEEEK
	pc++;

	return pt;
}

/* indirect post-indexed */
word am_iy(int *bound) {
	word ba = am_iz();		// pick base address and skip operand
	word pt = ba + y;		// add offset
	*bound = ((pt & 0xFF00)==(ba & 0xFF00))?0:1;	// check page crossing

	return pt;
}

/* pre-indexed indirect */
word am_ix(void) {
	word pt = (peek((peek(pc)+x)&255)|(peek((peek(pc)+x+1)&255)<<8));	// EEEEEEK
	pc++;

	return pt;
}

/* relative branch */
void rel(int *bound) {
	byte off = peek(pc++);	// read offset and skip operand
	word old = pc;

	pc += off;
	pc -= (off & 128)?256:0;						// check negative displacement

	*bound = ((old & 0xFF00)==(pc & 0xFF00))?0:1;	// check page crossing
}

/* *** opcode assistants *** */
/* compute usual N & Z flags from value */
void bits_nz(byte b) {
	p &= 0b01111101;		// pre-clear N & Z
	p |= (b & 128);			// set N as bit 7
	p |= (b==0)?2:0;		// set Z accordingly
}

/* ASL, shift left */
void asl(byte *d) {
	p &= 0b11111110;		// clear C
	p |= ((*d) & 128) >> 7;	// will take previous bit 7
	(*d) <<= 1;				// EEEEEEEEK
	bits_nz(*d);
}

/* LSR, shift right */
void lsr(byte *d) {
	p &= 0b11111110;		// clear C
	p |= (*d) & 1;			// will take previous bit 0
	(*d) >>= 1;				// eeeek
	bits_nz(*d);
}

/* ROL, rotate left */
void rol(byte *d) {
	byte tmp = (p & 1);		// keep previous C

	p &= 0b11111110;		// clear C
	p |= ((*d) & 128) >> 7;	// will take previous bit 7
	(*d) <<= 1;				// eeeeeek
	(*d) |= tmp;			// rotate C
	bits_nz(*d);
}

/* ROR, rotate right */
void ror(byte *d) {
	byte tmp = (p & 1)<<7;	// keep previous C (shifted)

	p &= 0b11111110;		// clear C
	p |= (*d) & 1;			// will take previous bit 0
	(*d) >>= 1;				// eeeek
	(*d) |= tmp;			// rotate C
	bits_nz(*d);
}

/* ADC, add with carry */
void adc(byte d) {
	byte old = a;
	word big = a;

	big += d;				// basic add... but check for Decimal mode!
	big += (p & 1);			// add with Carry (A was computer just after this)

	if (p & 0b00001000) {						// Decimal mode!
		if ((big & 0x0F) > 9) {					// LSN overflow? was 'a' instead of 'big'
			big += 6;								// get into next decade
		}
		if ((big & 0xF0) > 0x90) {				// MSN overflow?
			big += 0x60;							// correct it
		}
	}
	a = big & 255;			// placed here trying to correct Carry in BCD mode

	if (big & 256)			p |= 0b00000001;	// set Carry if needed
	else					p &= 0b11111110;
	if ((a&128)^(old&128))	p |= 0b01000000;	// set oVerflow if needed
	else					p &= 0b10111111;
	bits_nz(a);									// set N & Z as usual
}

/* SBC, subtract with borrow */ //EEEEEEEEEEEEEEEEK
void sbc(byte d) {
	byte old = a;
	word big = a;

	big += ~d;				// basic subtract, 6502-style... but check for Decimal mode!
	big += (p & 1);			// add with Carry
	
	if (p & 0b00001000) {						// Decimal mode!
		if ((big & 0x0F) > 9) {					// LSN overflow?
			big -= 6;								// get into next decade *** check
		}
		if ((big & 0xF0) > 0x90) {				// MSN overflow?
			big -= 0x60;							// correct it
		}
	}
	a = big & 255;			// same as ADC

	if (big & 256)			p &= 0b11111110;	// set Carry if needed EEEEEEEEEEEEK, is this OK?
	else					p |= 0b00000001;
	if ((a&128)^(old&128))	p |= 0b01000000;	// set oVerflow if needed
	else					p &= 0b10111111;
	bits_nz(a);									// set N & Z as usual
}

/* CMP/CPX/CPY compare register to memory */
void cmp(byte reg, byte d) {
	word big = reg;

	big -= d;				// apparent subtract, always binary

	if (big & 256)			p &= 0b11111110;	// set Carry if needed (note inversion)
	else					p |= 0b00000001;
	bits_nz(reg - d);							// set N & Z as usual
}

/* execute a single opcode, returning cycle count */
int exec(void) {
	int per = 2;			// base cycle count
	int page = 0;			// page boundary flag, for speed penalties
	byte opcode, temp;
	word adr;

	opcode = peek(pc++);	// get opcode and point to next one (or operand)

	switch(opcode) {
/* *** ADC: Add Memory to Accumulator with Carry *** */
		case 0x69:
			adc(peek(pc++));
			if (ver > 3) printf("[ADC#]");
			per += dec;
			break;
		case 0x6D:
			adc(peek(am_a()));
			if (ver > 3) printf("[ADCa]");
			per = 4 + dec;
			break;
		case 0x65:
			adc(peek(peek(pc++)));
			if (ver > 3) printf("[ADCz]");
			per = 3 + dec;
			break;
		case 0x61:
			adc(peek(am_ix()));
			if (ver > 3) printf("[ADC(x)]");
			per = 6 + dec;
			break;
		case 0x71:
			adc(peek(am_iy(&page)));
			if (ver > 3) printf("[ADC(y)]");
			per = 5 + dec + page;
			break;
		case 0x75:
			adc(peek(am_zx()));
			if (ver > 3) printf("[ADCzx]");
			per = 4 + dec;
			break;
		case 0x7D:
			adc(peek(am_ax(&page)));
			if (ver > 3) printf("[ADCx]");
			per = 4 + dec + page;
			break;
		case 0x79:
			adc(peek(am_ay(&page)));
			if (ver > 3) printf("[ADCy]");
			per = 4 + dec + page;
			break;
		case 0x72:			// CMOS only
			adc(peek(am_iz()));
			if (ver > 3) printf("[ADC(z)]");
			per = 5 + dec;
			break;
/* *** AND: "And" Memory with Accumulator *** */
		case 0x29:
			a &= peek(pc++);
			bits_nz(a);
			if (ver > 3) printf("[AND#]");
			break;
		case 0x2D:
			a &= peek(am_a());
			bits_nz(a);
			if (ver > 3) printf("[ANDa]");
			per = 4;
			break;
		case 0x25:
			a &= peek(peek(pc++));
			bits_nz(a);
			if (ver > 3) printf("[ANDz]");
			per = 3;
			break;
		case 0x21:
			a &= peek(am_ix());
			bits_nz(a);
			if (ver > 3) printf("[AND(x)]");
			per = 6;
			break;
		case 0x31:
			a &= peek(am_iy(&page));
			bits_nz(a);
			if (ver > 3) printf("[AND(y)]");
			per = 5 + page;
			break;
		case 0x35:
			a &= peek(am_zx());
			bits_nz(a);
			if (ver > 3) printf("[ANDzx]");
			per = 4;
			break;
		case 0x3D:
			a &= peek(am_ax(&page));
			bits_nz(a);
			if (ver > 3) printf("[ANDx]");
			per = 4 + page;
			break;
		case 0x39:
			a &= peek(am_ay(&page));
			bits_nz(a);
			if (ver > 3) printf("[ANDy]");
			per = 4 + page;
			break;
		case 0x32:			// CMOS only
			a &= peek(am_iz());
			bits_nz(a);
			if (ver > 3) printf("[AND(z)]");
			per = 5;
			break;
/* *** ASL: Shift Left one Bit (Memory or Accumulator) *** */
		case 0x0E:
			adr = am_a();
			temp = peek(adr);
			asl(&temp);
			poke(adr, temp);
			if (ver > 3) printf("[ASLa]");
			per = 6;
			break;
		case 0x06:
			temp = peek(peek(pc));
			asl(&temp);
			poke(peek(pc++), temp);
			if (ver > 3) printf("[ASLz]");
			per = 5;
			break;
		case 0x0A:
			asl(&a);
			if (ver > 3) printf("[ASL]");
			break;
		case 0x16:
			adr = am_zx();
			temp = peek(adr);
			asl(&temp);
			poke(adr, temp);
			if (ver > 3) printf("[ASLzx]");
			per = 6;
			break;
		case 0x1E:
			adr = am_ax(&page);
			temp = peek(adr);
			asl(&temp);
			poke(adr, temp);
			if (ver > 3) printf("[ASLx]");
			per = 6 + page;	// 7 on NMOS
			break;
/* *** Bxx: Branch on flag condition *** */
		case 0x90:
			if(!(p & 0b00000001)) {
				rel(&page);
				per = 3 + page;
				if (ver > 2) printf("[BCC]");
			} else pc++;	// must skip offset if not done EEEEEK
			break;
		case 0xB0:
			if(p & 0b00000001) {
				rel(&page);
				per = 3 + page;
				if (ver > 2) printf("[BCS]");
			} else pc++;	// must skip offset if not done EEEEEK
			break;
		case 0xF0:
			if(p & 0b00000010) {
				rel(&page);
				per = 3 + page;
				if (ver > 2) printf("[BEQ]");
			} else pc++;	// must skip offset if not done EEEEEK
			break;
/* *** BIT: Test Bits in Memory with Accumulator *** */
		case 0x2C:
			temp = peek(am_a());
			p &= 0b00111101;			// pre-clear N, V & Z
			p |= (temp & 0b11000000);	// copy bits 7 & 6 as N & Z
			p |= (a & temp)?0:2;		// set Z accordingly
			if (ver > 3) printf("[BITa]");
			per = 4;
			break;
		case 0x24:
			temp = peek(peek(pc++));
			p &= 0b00111101;			// pre-clear N, V & Z
			p |= (temp & 0b11000000);	// copy bits 7 & 6 as N & Z
			p |= (a & temp)?0:2;		// set Z accordingly
			if (ver > 3) printf("[BITz]");
			per = 3;
			break;
		case 0x89:			// CMOS only
			temp = peek(pc++);
			p &= 0b11111101;			// pre-clear Z only, is this OK?
			p |= (a & temp)?0:2;		// set Z accordingly
			if (ver > 3) printf("[BIT#]");
			break;
		case 0x3C:			// CMOS only
			temp = peek(am_ax(&page));
			p &= 0b00111101;			// pre-clear N, V & Z
			p |= (temp & 0b11000000);	// copy bits 7 & 6 as N & Z
			p |= (a & temp)?0:2;		// set Z accordingly
			if (ver > 3) printf("[BITx]");
			per = 4 + page;
			break;
		case 0x34:			// CMOS only
			temp = peek(am_zx());
			p &= 0b00111101;			// pre-clear N, V & Z
			p |= (temp & 0b11000000);	// copy bits 7 & 6 as N & Z
			p |= (a & temp)?0:2;		// set Z accordingly
			if (ver > 3) printf("[BITzx]");
			per = 4;
			break;
/* *** Bxx: Branch on flag condition *** */
		case 0x30:
			if(p & 0b10000000) {
				rel(&page);
				per = 3 + page;
			} else pc++;	// must skip offset if not done EEEEEK
			if (ver > 2) printf("[BMI]");
			break;
		case 0xD0:
			if(!(p & 0b00000010)) {
				rel(&page);
				per = 3 + page;
			} else pc++;	// must skip offset if not done EEEEEK
			if (ver > 2) printf("[BNE]");
			break;
		case 0x10:
			if(!(p & 0b10000000)) {
				rel(&page);
				per = 3 + page;
			} else pc++;	// must skip offset if not done EEEEEK
			if (ver > 2) printf("[BPL]");
			break;
		case 0x80:			// CMOS only
			rel(&page);
			per = 3 + page;
			if (ver > 2) printf("[BRA]");
			break;
/* *** BRK: force break *** */
		case 0x00:
			pc++;
			if (ver > 1) printf("[BRK]");
			if (safe)	run = 0;
			else {
				p |= 0b00010000;		// set B, just in case
				intack();
				p &= 0b11101111;		// clear B, just in case
				pc = peek(0xFFFE) | peek(0xFFFF)<<8;	// IRQ/BRK vector
				if (ver > 1) printf("\b PC=>%04X]", pc);
			}
			break;
/* *** Bxx: Branch on flag condition *** */
		case 0x50:
			if(!(p & 0b01000000)) {
				rel(&page);
				per = 3 + page;
			} else pc++;	// must skip offset if not done EEEEEK
			if (ver > 2) printf("[BVC]");
			break;
		case 0x70:
			if(p & 0b01000000) {
				rel(&page);
				per = 3 + page;
			} else pc++;	// must skip offset if not done EEEEEK
			if (ver > 2) printf("[BVS]");
			break;
/* *** CLx: Clear flags *** */
		case 0x18:
			p &= 0b11111110;
			if (ver > 3) printf("[CLC]");
			break;
		case 0xD8:
			p &= 0b11110111;
			dec = 0;
			if (ver > 3) printf("[CLD]");
			break;
		case 0x58:
			p &= 0b11111011;
			if (ver > 3) printf("[CLI]");
			break;
		case 0xB8:
			p &= 0b10111111;
			if (ver > 3) printf("[CLV]");
			break;
/* *** CMP: Compare Memory And Accumulator *** */
		case 0xC9:
			cmp(a, peek(pc++));
			if (ver > 3) printf("[CMP#]");
			break;
		case 0xCD:
			cmp(a, peek(am_a()));
			if (ver > 3) printf("[CMPa]");
			per = 4;
			break;
		case 0xC5:
			cmp(a, peek(peek(pc++)));
			if (ver > 3) printf("[CMPz]");
			per = 3;
			break;
		case 0xC1:
			cmp(a, peek(am_ix()));
			if (ver > 3) printf("[CMP(x)]");
			per = 6;
			break;
		case 0xD1:
			cmp(a, peek(am_iy(&page)));
			if (ver > 3) printf("[CMP(y)]");
			per = 5 + page;
			break;
		case 0xD5:
			cmp(a, peek(am_zx()));
			if (ver > 3) printf("[CMPzx]");
			per = 4;
			break;
		case 0xDD:
			cmp(a, peek(am_ax(&page)));
			if (ver > 3) printf("[CMPx]");
			per = 4 + page;
			break;
		case 0xD9:
			cmp(a, peek(am_ay(&page)));
			if (ver > 3) printf("[CMPy]");
			per = 4 + page;
			break;
		case 0xD2:			// CMOS only
			cmp(a, peek(am_iz()));
			if (ver > 3) printf("[CMP(z)]");
			per = 5;
			break;
/* *** CPX: Compare Memory And Index X *** */
		case 0xE0:
			cmp(x, peek(pc++));
			if (ver > 3) printf("[CPX#]");
			break;
		case 0xEC:
			cmp(x, peek(am_a()));
			if (ver > 3) printf("[CPXa]");
			per = 4;
			break;
		case 0xE4:
			cmp(x, peek(peek(pc++)));
			if (ver > 3) printf("[CPXz]");
			per = 3;
			break;
/* *** CPY: Compare Memory And Index Y *** */
		case 0xC0:
			cmp(y, peek(pc++));
			if (ver > 3) printf("[CPY#]");
			break;
		case 0xCC:
			cmp(y, peek(am_a()));
			if (ver > 3) printf("[CPYa]");
			per = 4;
			break;
		case 0xC4:
			cmp(y, peek(peek(pc++)));
			if (ver > 3) printf("[CPYz]");
			per = 3;
			break;
/* *** DEC: Decrement Memory (or Accumulator) by One *** */
		case 0xCE:
			adr = am_a();	// EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEK
			temp = peek(adr);
			temp--;
			poke(adr, temp);
			bits_nz(temp);
			if (ver > 3) printf("[DECa]");
			per = 6;
			break;
		case 0xC6:
			temp = peek(peek(pc));
			temp--;
			poke(peek(pc++), temp);
			bits_nz(temp);
			if (ver > 3) printf("[DECz]");
			per = 5;
			break;
		case 0xD6:
			adr = am_zx();	// EEEEEEEEEEK
			temp = peek(adr);
			temp--;
			poke(adr, temp);
			bits_nz(temp);
			if (ver > 3) printf("[DECzx]");
			per = 6;
			break;
		case 0xDE:
			adr = am_ax(&page);	// EEEEEEEEK
			temp = peek(adr);
			temp--;
			poke(adr, temp);
			bits_nz(temp);
			if (ver > 3) printf("[DECx]");
			per = 7;		// 6+page for WDC?
			break;
		case 0x3A:			// CMOS only (OK)
			a--;
			bits_nz(a);
			if (ver > 3) printf("[DEC]");
			break;
/* *** DEX: Decrement Index X by One *** */
		case 0xCA:
			x--;
			bits_nz(x);
			if (ver > 3) printf("[DEX]");
			break;
/* *** DEY: Decrement Index Y by One *** */
		case 0x88:
			y--;
			bits_nz(y);
			if (ver > 3) printf("[DEY]");
			break;
/* *** EOR: "Exclusive Or" Memory with Accumulator *** */
		case 0x49:
			a ^= peek(pc++);
			bits_nz(a);
			if (ver > 3) printf("[EOR#]");
			break;
		case 0x4D:
			a ^= peek(am_a());
			bits_nz(a);
			if (ver > 3) printf("[EORa]");
			per = 4;
			break;
		case 0x45:
			a ^= peek(peek(pc++));
			bits_nz(a);
			if (ver > 3) printf("[EORz]");
			per = 3;
			break;
		case 0x41:
			a ^= peek(am_ix());
			bits_nz(a);
			if (ver > 3) printf("[EOR(x)]");
			per = 6;
			break;
		case 0x51:
			a ^= peek(am_iy(&page));
			bits_nz(a);
			if (ver > 3) printf("[EOR(y)]");
			per = 5 + page;
			break;
		case 0x55:
			a ^= peek(am_zx());
			bits_nz(a);
			if (ver > 3) printf("[EORzx]");
			per = 4;
			break;
		case 0x5D:
			a ^= peek(am_ax(&page));
			bits_nz(a);
			if (ver > 3) printf("[EORx]");
			per = 4 + page;
			break;
		case 0x59:
			a ^= peek(am_ay(&page));
			bits_nz(a);
			if (ver > 3) printf("[EORy]");
			per = 4 + page;
			break;
		case 0x52:			// CMOS only
			a ^= peek(am_iz());
			bits_nz(a);
			if (ver > 3) printf("[EOR(z)]");
			per = 5;
			break;
/* *** INC: Increment Memory (or Accumulator) by One *** */
		case 0xEE:
			adr = am_a();	// EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEK
			temp = peek(adr);
			temp++;
			poke(adr, temp);
			bits_nz(temp);
			if (ver > 3) printf("[INCa]");
			per = 6;
			break;
		case 0xE6:
			temp = peek(peek(pc));
			temp++;
			poke(peek(pc++), temp);
			bits_nz(temp);
			if (ver > 3) printf("[INCz]");
			per = 5;
			break;
		case 0xF6:
			adr = am_zx();	// EEEEEEEEEEK
			temp = peek(adr);
			temp++;
			poke(adr, temp);
			bits_nz(temp);
			if (ver > 3) printf("[INCzx]");
			per = 6;
			break;
		case 0xFE:
			adr = am_ax(&page);	// EEEEEEEEEEK
			temp = peek(adr);
			temp++;
			poke(adr, temp);
			bits_nz(temp);
			if (ver > 3) printf("[INCx]");
			per = 7;		// 6+page for WDC?
			break;
		case 0x1A:			// CMOS only
			a++;
			bits_nz(a);
			if (ver > 3) printf("[INC]");
			break;
/* *** INX: Increment Index X by One *** */
		case 0xE8:
			x++;
			bits_nz(x);
			if (ver > 3) printf("[INX]");
			break;
/* *** INY: Increment Index Y by One *** */
		case 0xC8:
			y++;
			bits_nz(y);
			if (ver > 3) printf("[INY]");
			break;
/* *** JMP: Jump to New Location *** */
		case 0x4C:
			pc = am_a();
			if (ver > 2)	printf("[JMP]");
			per = 3;
			break;
		case 0x6C:
			pc = am_ai();
			if (ver > 2)	printf("[JMP()]");
			per = 6;		// 5 for NMOS!
			break;
		case 0x7C:			// CMOS only
			pc = am_aix();
			if (ver > 2)	printf("[JMP(x)]");
			per = 6;
			break;
/* *** JSR: Jump to New Location Saving Return Address *** */
		case 0x20:
			push((pc+1)>>8);		// stack one byte before return address, right at MSB
			push((pc+1)&255);
			pc = am_a();			// get operand
			if (ver > 2)	printf("[JSR]");
			per = 6;
			break;
/* *** LDA: Load Accumulator with Memory *** */
		case 0xA9:
			a = peek(pc++);
			bits_nz(a);
			if (ver > 3) printf("[LDA#]");
			break;
		case 0xAD:
			a = peek(am_a());
			bits_nz(a);
			if (ver > 3) printf("[LDAa]");
			per = 4;
			break;
		case 0xA5:
			a = peek(peek(pc++));
			bits_nz(a);
			if (ver > 3) printf("[LDAz]");
			per = 3;
			break;
		case 0xA1:
			a = peek(am_ix());
			bits_nz(a);
			if (ver > 3) printf("[LDA(x)]");
			per = 6;
			break;
		case 0xB1:
			a = peek(am_iy(&page));
			bits_nz(a);
			if (ver > 3) printf("[LDA(y)]");
			per = 5 + page;
			break;
		case 0xB5:
			a = peek(am_zx());
			bits_nz(a);
			if (ver > 3) printf("[LDAzx]");
			per = 4;
			break;
		case 0xBD:
			a = peek(am_ax(&page));
			bits_nz(a);
			if (ver > 3) printf("[LDAx]");
			per = 4 + page;
			break;
		case 0xB9:
			a = peek(am_ay(&page));
			bits_nz(a);
			if (ver > 3) printf("[LDAy]");
			per = 4 + page;
			break;
		case 0xB2:			// CMOS only
			a = peek(am_iz());
			bits_nz(a);
			if (ver > 3) printf("[LDA(z)]");
			per = 5;
			break;
/* *** LDX: Load Index X with Memory *** */
		case 0xA2:
			x = peek(pc++);
			bits_nz(x);
			if (ver > 3) printf("[LDX#]");
			break;
		case 0xAE:
			x = peek(am_a());
			bits_nz(x);
			if (ver > 3) printf("[LDXa]");
			per = 4;
			break;
		case 0xA6:
			x = peek(peek(pc++));
			bits_nz(x);
			if (ver > 3) printf("[LDXz]");
			per = 3;
			break;
		case 0xB6:
			x = peek(am_zy());
			bits_nz(x);
			if (ver > 3) printf("[LDXzy]");
			per = 4;
			break;
		case 0xBE:
			x = peek(am_ay(&page));
			bits_nz(x);
			if (ver > 3) printf("[LDXy]");
			per = 4 + page;
			break;
/* *** LDY: Load Index Y with Memory *** */
		case 0xA0:
			y = peek(pc++);
			bits_nz(y);
			if (ver > 3) printf("[LDY#]");
			break;
		case 0xAC:
			y = peek(am_a());
			bits_nz(y);
			if (ver > 3) printf("[LDYa]");
			per = 4;
			break;
		case 0xA4:
			y = peek(peek(pc++));
			bits_nz(y);
			if (ver > 3) printf("[LDYz]");
			per = 3;
			break;
		case 0xB4:
			y = peek(am_zx());
			bits_nz(y);
			if (ver > 3) printf("[LDYzx]");
			per = 4;
			break;
		case 0xBC:
			y = peek(am_ax(&page));
			bits_nz(y);
			if (ver > 3) printf("[LDYx]");
			per = 4 + page;
			break;
/* *** LSR: Shift One Bit Right (Memory or Accumulator) *** */
		case 0x4E:
			adr=am_a();
			temp = peek(adr);
			lsr(&temp);
			poke(adr, temp);
			if (ver > 3) printf("[LSRa]");
			per = 6;
			break;
		case 0x46:
			temp = peek(peek(pc));
			lsr(&temp);
			poke(peek(pc++), temp);
			if (ver > 3) printf("[LSRz]");
			per = 5;
			break;
		case 0x4A:
			lsr(&a);
			if (ver > 3) printf("[LSR]");
			break;
		case 0x56:
			adr = am_zx();
			temp = peek(adr);
			lsr(&temp);
			poke(adr, temp);
			if (ver > 3) printf("[LSRzx]");
			per = 6;
			break;
		case 0x5E:
			adr = am_ax(&page);
			temp = peek(adr);
			lsr(&temp);
			poke(adr, temp);
			if (ver > 3) printf("[LSRx]");
			per = 6 + page;	// 7 for NMOS
			break;
/* *** NOP: No Operation *** */
		case 0xEA:
			if (ver > 3) printf("[NOP]");
			break;
/* *** ORA: "Or" Memory with Accumulator *** */
		case 0x09:
			a |= peek(pc++);
			bits_nz(a);
			if (ver > 3) printf("[ORA#]");
			break;
		case 0x0D:
			a |= peek(am_a());
			bits_nz(a);
			if (ver > 3) printf("[ORAa]");
			per = 4;
			break;
		case 0x05:
			a |= peek(peek(pc++));
			bits_nz(a);
			if (ver > 3) printf("[ORAz]");
			per = 3;
			break;
		case 0x01:
			a |= peek(am_ix());
			bits_nz(a);
			if (ver > 3) printf("[ORA(x)]");
			per = 6;
			break;
		case 0x11:
			a |= peek(am_iy(&page));
			bits_nz(a);
			if (ver > 3) printf("[ORA(y)]");
			per = 5 + page;
			break;
		case 0x15:
			a |= peek(am_zx());
			bits_nz(a);
			if (ver > 3) printf("[ORAzx]");
			per = 4;
			break;
		case 0x1D:
			a |= peek(am_ax(&page));
			bits_nz(a);
			if (ver > 3) printf("[ORAx]");
			per = 4 + page;
			break;
		case 0x19:
			a |= peek(am_ay(&page));
			bits_nz(a);
			if (ver > 3) printf("[ORAy]");
			per = 4 + page;
			break;
		case 0x12:			// CMOS only
			a |= peek(am_iz());
			bits_nz(a);
			if (ver > 3) printf("[ORA(z)]");
			per = 5;
			break;
/* *** PHA: Push Accumulator on Stack *** */
		case 0x48:
			push(a);
			if (ver > 3) printf("[PHA]");
			per = 3;
			break;
/* *** PHP: Push Processor Status on Stack *** */
		case 0x08:
			push(p);
			if (ver > 3) printf("[PHP]");
			per = 3;
			break;
/* *** PHX: Push Index X on Stack *** */
		case 0xDA:			// CMOS only
			push(x);
			if (ver > 3) printf("[PHX]");
			per = 3;
			break;
/* *** PHY: Push Index Y on Stack *** */
		case 0x5A:			// CMOS only
			push(y);
			if (ver > 3) printf("[PHY]");
			per = 3;
			break;
/* *** PLA: Pull Accumulator from Stack *** */
		case 0x68:
			a = pop();
			if (ver > 3) printf("[PLA]");
			bits_nz(a);
			per = 4;
			break;
/* *** PLP: Pull Processor Status from Stack *** */
		case 0x28:
			p = pop();
			if (p & 0b00001000)	dec = 1;	// check for decimal flag
			else				dec = 0;
			if (ver > 3) printf("[PLP]");
			per = 4;
			break;
/* *** PLX: Pull Index X from Stack *** */
		case 0xFA:			// CMOS only
			x = pop();
			if (ver > 3) printf("[PLX]");
			per = 4;
			break;
/* *** PLX: Pull Index X from Stack *** */
		case 0x7A:			// CMOS only
			y = pop();
			if (ver > 3) printf("[PLY]");
			per = 4;
			break;
/* *** ROL: Rotate One Bit Left (Memory or Accumulator) *** */
		case 0x2E:
			adr = am_a();
			temp = peek(adr);
			rol(&temp);
			poke(adr, temp);
			if (ver > 3) printf("[ROLa]");
			per = 6;
			break;
		case 0x26:
			temp = peek(peek(pc));
			rol(&temp);
			poke(peek(pc++), temp);
			if (ver > 3) printf("[ROLz]");
			per = 5;
			break;
		case 0x36:
			adr = am_zx();
			temp = peek(adr);
			rol(&temp);
			poke(adr, temp);
			if (ver > 3) printf("[ROLzx]");
			per = 6;
			break;
		case 0x3E:
			adr = am_ax(&page);
			temp = peek(adr);
			rol(&temp);
			poke(adr, temp);
			if (ver > 3) printf("[ROLx]");
			per = 6 + page;	// 7 for NMOS
			break;
		case 0x2A:
			rol(&a);
			if (ver > 3) printf("[ROL]");
			break;
/* *** ROR: Rotate One Bit Right (Memory or Accumulator) *** */
		case 0x6E:
			adr = am_a();
			temp = peek(adr);
			ror(&temp);
			poke(adr, temp);
			if (ver > 3) printf("[RORa]");
			per = 6;
			break;
		case 0x66:
			temp = peek(peek(pc));
			ror(&temp);
			poke(peek(pc++), temp);
			if (ver > 3) printf("[RORz]");
			per = 5;
			break;
		case 0x6A:
			ror(&a);
			if (ver > 3) printf("[ROR]");
			break;
		case 0x76:
			adr = am_zx();
			temp = peek(adr);
			ror(&temp);
			poke(adr, temp);
			if (ver > 3) printf("[RORzx]");
			per = 6;
			break;
		case 0x7E:
			adr = am_ax(&page);
			temp = peek(adr);
			ror(&temp);
			poke(adr, temp);
			if (ver > 3) printf("[RORx]");
			per = 6 + page;	// 7 for NMOS
			break;
/* *** RTI: Return from Interrupt *** */
		case 0x40:
			p = pop();					// retrieve status
			p |= 0b00010000;			// forget possible B flag
			pc = pop();					// extract LSB...
			pc |= (pop() << 8);			// ...and MSB, address is correct
			if (ver > 2)	printf("[RTI]");
			per = 6;
			break;
/* *** RTS: Return from Subroutine *** */
		case 0x60:
			pc = pop();					// extract LSB...
			pc |= (pop() << 8);			// ...and MSB, but is one byte off
			pc++;						// return instruction address
			if (ver > 2)	printf("[RTS]");
			per = 6;
			break;
/* *** SBC: Subtract Memory from Accumulator with Borrow *** */
		case 0xE9:
			sbc(peek(pc++));
			if (ver > 3) printf("[SBC#]");
			per += dec;
			break;
		case 0xED:
			sbc(peek(am_a()));
			if (ver > 3) printf("[SBCa]");
			per = 4 + dec;
			break;
		case 0xE5:
			sbc(peek(peek(pc++)));
			if (ver > 3) printf("[SBCz]");
			per = 3 + dec;
			break;
		case 0xE1:
			sbc(peek(am_ix()));
			if (ver > 3) printf("[SBC(x)]");
			per = 6 + dec;
			break;
		case 0xF1:
			sbc(peek(am_iy(&page)));
			if (ver > 3) printf("[SBC(y)]");
			per = 5 + dec + page;
			break;
		case 0xF5:
			sbc(peek(am_zx()));
			if (ver > 3) printf("[SBCzx]");
			per = 4 + dec;
			break;
		case 0xFD:
			sbc(peek(am_ax(&page)));
			if (ver > 3) printf("[SBCx]");
			per = 4 + dec + page;
			break;
		case 0xF9:
			sbc(peek(am_ay(&page)));
			if (ver > 3) printf("[SBCy]");
			per = 4 + dec + page;
			break;
		case 0xF2:			// CMOS only
			sbc(peek(am_iz()));
			if (ver > 3) printf("[SBC(z)]");
			per = 5 + dec;
			break;
// *** SEx: Set Flags *** */
		case 0x38:
			p |= 0b00000001;
			if (ver > 3) printf("[SEC]");
			break;
		case 0xF8:
			p |= 0b00001000;
			dec = 1;
			if (ver > 3) printf("[SED]");
			break;
		case 0x78:
			p |= 0b00000100;
			if (ver > 3) printf("[SEI]");
			break;
/* *** STA: Store Accumulator in Memory *** */
		case 0x8D:
			poke(am_a(), a);
			if (ver > 3) printf("[STAa]");
			per = 4;
			break;
		case 0x85:
			poke(peek(pc++), a);
			if (ver > 3) printf("[STAz]");
			per = 3;
			break;
		case 0x81:
			poke(am_ix(), a);
			if (ver > 3) printf("[STA(x)]");
			per = 6;
			break;
		case 0x91:
			poke(am_iy(&page), a);
			if (ver > 3) printf("[STA(y)]");
			per = 6;		// ...and not 5, as expected
			break;
		case 0x95:
			poke(am_zx(), a);
			if (ver > 3) printf("[STAzx]");
			per = 4;
			break;
		case 0x9D:
			poke(am_ax(&page), a);
			if (ver > 3) printf("[STAx]");
			per = 5;		// ...and not 4, as expected
			break;
		case 0x99:
			poke(am_ay(&page), a);
			if (ver > 3) printf("[STAy]");
			per = 5;		// ...and not 4, as expected
			break;
		case 0x92:			// CMOS only
			poke(am_iz(), a);
			if (ver > 3) printf("[STA(z)]");
			per = 5;
			break;
/* *** STX: Store Index X in Memory *** */
		case 0x8E:
			poke(am_a(), x);
			if (ver > 3) printf("[STXa]");
			per = 4;
			break;
		case 0x86:
			poke(peek(pc++), x);
			if (ver > 3) printf("[STXz]");
			per = 3;
			break;
		case 0x96:
			poke(am_zy(), x);
			if (ver > 3) printf("[STXzy]");
			per = 4;
			break;
/* *** STY: Store Index Y in Memory *** */
		case 0x8C:
			poke(am_a(), y);
			if (ver > 3) printf("[STYa]");
			per = 4;
			break;
		case 0x84:
			poke(peek(pc++), y);
			if (ver > 3) printf("[STYz]");
			per = 3;
			break;
		case 0x94:
			poke(am_zx(), y);
			if (ver > 3) printf("[STYzx]");
			per = 4;
			break;
// *** STZ: Store Zero in Memory, CMOS only ***
		case 0x9C:
			poke(am_a(), 0);
			if (ver > 3) printf("[STZa]");
			per = 4;
			break;
		case 0x64:
			poke(peek(pc++), 0);
			if (ver > 3) printf("[STZz]");
			per = 3;
			break;
		case 0x74:
			poke(am_zx(), 0);
			if (ver > 3) printf("[STZzx]");
			per = 4;
			break;
		case 0x9E:
			poke(am_ax(&page), 0);
			if (ver > 3) printf("[STZx]");
			per = 5;		// ...and not 4, as expected
			break;
/* *** TAX: Transfer Accumulator to Index X *** */
		case 0xAA:
			x = a;
			bits_nz(x);
			if (ver > 3) printf("[TAX]");
			break;
/* *** TAY: Transfer Accumulator to Index Y *** */
		case 0xA8:
			y = a;
			bits_nz(y);
			if (ver > 3) printf("[TAY]");
			break;
/* *** TRB: Test and Reset Bits, CMOS only *** */
		case 0x1C:
			adr = am_a();
			temp = peek(adr);
			if (temp & a)		p &= 0b11111101;	// set Z accordingly
			else 				p |= 0b00000010;
			poke(adr, temp & ~a);
			if (ver > 3) printf("[TRBa]");
			per = 6;
			break;
		case 0x14:
			adr = peek(pc++);
			temp = peek(adr);
			if (temp & a)		p &= 0b11111101;	// set Z accordingly
			else 				p |= 0b00000010;
			poke(adr, temp & ~a);
			if (ver > 3) printf("[TRBz]");
			per = 5;
			break;
/* *** TSB: Test and Set Bits, CMOS only *** */
		case 0x0C:
			adr = am_a();
			temp = peek(adr);
			if (temp & a)		p &= 0b11111101;	// set Z accordingly
			else 				p |= 0b00000010;
			poke(adr, temp | a);
			if (ver > 3) printf("[TSBa]");
			per = 6;
			break;
		case 0x04:
			adr = peek(pc++);
			temp = peek(adr);
			if (temp & a)		p &= 0b11111101;	// set Z accordingly
			else 				p |= 0b00000010;
			poke(adr, temp | a);
			if (ver > 3) printf("[TSBz]");
			per = 5;
			break;
/* *** TSX: Transfer Stack Pointer to Index X *** */
		case 0xBA:
			x = s;
			bits_nz(x);
			if (ver > 3) printf("[TSX]");
			break;
/* *** TXA: Transfer Index X to Accumulator *** */
		case 0x8A:
			a = x;
			bits_nz(a);
			if (ver > 3) printf("[TXA]");
			break;
/* *** TXS: Transfer Index X to Stack Pointer *** */
		case 0x9A:
			s = x;
			bits_nz(s);
			if (ver > 3) printf("[TXS]");
			break;
/* *** TYA: Transfer Index Y to Accumulator *** */
		case 0x98:
			a = y;
			bits_nz(a);
			if (ver > 3) printf("[TYA]");
			break;
/* *** *** special control 'opcodes' *** *** */
/* *** Emulator Breakpoint  (WAI on WDC) *** */
		case 0xCB:
//			if (ver)	printf(" Status @ $%x04:", pc-1);	// must allow warnings to display status request
//			stat();
			run = 1;		// pause execution
			break;
/* *** Graceful Halt (STP on WDC) *** */
		case 0xDB:
			printf(" ...HALT!");
			run = per = 0;	// definitively stop execution
			break;
/* *** *** unused (illegal?) opcodes *** *** */
/* *** remaining opcodes (illegal on NMOS) executed as pseudoNOPs, according to 65C02 byte and cycle usage *** */
		case 0x03:
		case 0x13:
		case 0x23:
		case 0x33:
		case 0x43:
		case 0x53:
		case 0x63:
		case 0x73:
		case 0x83:
		case 0x93:
		case 0xA3:
		case 0xB3:
		case 0xC3:
		case 0xD3:
		case 0xE3:
		case 0xF3:
		case 0x0B:
		case 0x1B:
		case 0x2B:
		case 0x3B:
		case 0x4B:
		case 0x5B:
		case 0x6B:
		case 0x7B:
		case 0x8B:
		case 0x9B:
		case 0xAB:
		case 0xBB:
		case 0xEB:
		case 0xFB:	// minus WDC opcodes, used for emulator control
		case 0x07:
		case 0x17:
		case 0x27:
		case 0x37:
		case 0x47:
		case 0x57:
		case 0x67:
		case 0x77:
		case 0x87:
		case 0x97:
		case 0xA7:
		case 0xB7:
		case 0xC7:
		case 0xD7:
		case 0xE7:
		case 0xF7:	// Rockwell RMB/SMB opcodes
		case 0x0F:
		case 0x1F:
		case 0x2F:
		case 0x3F:
		case 0x4F:
		case 0x5F:
		case 0x6F:
		case 0x7F:
		case 0x8F:
		case 0x9F:
		case 0xAF:
		case 0xBF:
		case 0xCF:
		case 0xDF:
		case 0xEF:
		case 0xFF:	// Rockwell BBR/BBS opcodes
			per = 1;		// ultra-fast 1 byte NOPs!
			if (ver)	printf("[NOP!]");
			if (safe)	illegal(1, opcode);
			break;
		case 0x02:
		case 0x22:
		case 0x42:
		case 0x62:
		case 0x82:
		case 0xC2:
		case 0xE2:
			pc++;			// 2-byte, 2-cycle NOPs
			if (ver)	printf("[NOP#]");
			if (safe)	illegal(2, opcode);
			break;
		case 0x44:
			pc++;
			per++;			// only case of 2-byte, 3-cycle NOP
			if (ver)	printf("[NOPz]");
			if (safe)	illegal(2, opcode);
			break;
		case 0x54:
		case 0xD4:
		case 0xF4:
			pc++;
			per = 4;		// only cases of 2-byte, 4-cycle NOP
			if (ver)	printf("[NOPzx]");
			if (safe)	illegal(2, opcode);
			break;
		case 0xDC:
		case 0xFC:
			pc += 2;
			per = 4;		// only cases of 3-byte, 4-cycle NOP
			if (ver)	printf("[NOPa]");
			if (safe)	illegal(3, opcode);
			break;
		case 0x5C:
			pc += 2;
			per = 8;		// extremely slow 8-cycle NOP
			if (ver)	printf("[NOP?]");
			if (safe)	illegal(3, opcode);
			break;			// not needed as it's the last one, but just in case
	}

	return per;
}

/* *** *** *** halt CPU on illegal opcodes *** *** *** */
void illegal(byte s, byte op) {
	printf("\n*** ($%04X) Illegal opcode $%02X ***\n", pc-s, op);
	run = 0;
}

/* *** randomize memory contents *** */
void randomize(void) {
	int i;

	srand(time(NULL));
	for (i=0; i<32768; i++)		mem[i]=rand() & 255;	// RAM contents
	mem[0xDF80] = rand() & 255;							// random video mode at powerup
}

/* *** *** VDU SECTION *** *** */

/* Initialize vdu display window */
int init_vdu() {
	//Initialize SDL
	if( SDL_Init( SDL_INIT_VIDEO | SDL_INIT_JOYSTICK | SDL_INIT_AUDIO ) < 0 )
	{
		printf("SDL could not be initialized! SDL Error: %s\n", SDL_GetError());
		return -1;
	}

	//Set texture filtering to linear
	SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");

	//Check for joysticks
	for(int i=0; i<2 && i<SDL_NumJoysticks(); i++)
	{
		//Load joystick
		sdl_gamepads[i] = SDL_JoystickOpen(i);
		if(sdl_gamepads[i] == NULL)
		{
		 printf("Unable to open game gamepad #%d! SDL Error: %s\n", i, SDL_GetError());
		 return -2;
		}
	}
	if(emulate_gamepads && SDL_NumJoysticks()==0) {
		gp1_emulated = 1;
		gp2_emulated = 1;
	}
	else if(emulate_gamepads && SDL_NumJoysticks()==1) {
		gp1_emulated = 0;
		gp2_emulated = 1;
	}

	// Get display mode
	if (SDL_GetDesktopDisplayMode(0, &sdl_display_mode) != 0) {
		printf("SDL_GetDesktopDisplayMode faile! SDL Error: %s\n", SDL_GetError());
		return -3;
	}

	pixel_size=4;
	hpixel_size=2;
	VDU_SCREEN_WIDTH=128*pixel_size;
	VDU_SCREEN_HEIGHT=VDU_SCREEN_WIDTH;

	//Create window
	sdl_window = SDL_CreateWindow("Durango-X", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, VDU_SCREEN_WIDTH, VDU_SCREEN_HEIGHT, SDL_WINDOW_OPENGL);
	if( sdl_window == NULL )
	{
		printf("Window could not be created! SDL Error: %s\n", SDL_GetError());
		return -4;
	}

	//Create renderer for window
	sdl_renderer = SDL_CreateRenderer( sdl_window, -1, SDL_RENDERER_ACCELERATED );
	if(sdl_renderer == NULL)
	{
		printf("Renderer could not be created! SDL Error: %s\n", SDL_GetError());
		return -5;
	}

    //Clear screen
	SDL_SetRenderDrawColor(sdl_renderer, 0x00, 0x00, 0x00, 0xFF);
	SDL_RenderClear(sdl_renderer);
	SDL_RenderPresent(sdl_renderer);

	// Initialize sound
	want.freq = 48000; // number of samples per second
	want.format = AUDIO_U8; // sample type (trying UNsigned 8 bit)
	want.channels = 1; // only one channel
	want.samples = 956; // buffer-size, does it need to be power of two? now every frame
	want.callback = audio_callback; // function SDL calls periodically to refill the buffer
	want.userdata = &(want.silence);

    SDL_AudioSpec have;
	if(SDL_OpenAudio(&want, &have) != 0)
	{
		printf("Failed to open SDL audio! SDL Error: %s\n", SDL_GetError());
		return -6;
	}
	if(want.format != have.format)
	{
		printf("Failed to setup SDL audio! SDL Error: %s\n", SDL_GetError());
if (have.format == AUDIO_U8) printf("**** era U8 *****");
		return -7;
	}

	// Start audio playback
	SDL_PauseAudio(0);
    
    return 0;
}

/* Close vdu display window */
void close_vdu() {
	// Stop audio
	SDL_PauseAudio(1);

	// Close audio module
	SDL_CloseAudio();

	// Close gamepads
	for(int i=0; i<2 && i<SDL_NumJoysticks(); i++)
	{
		SDL_JoystickClose(sdl_gamepads[i]);
		sdl_gamepads[i]=NULL;
	}

	//Destroy renderer
	if(sdl_renderer!=NULL)
	{
		SDL_DestroyRenderer(sdl_renderer);
		sdl_renderer=NULL;
	}

	if(sdl_window != NULL)
	{
		// Destroy window
		SDL_DestroyWindow(sdl_window);
		sdl_window=NULL;
	}

	
	// Close SDL
	SDL_Quit();
}

/* Set current color in SDL from palette */
void vdu_set_color_pixel(byte c) {
	// Color components
	byte red=0, green=0, blue=0;

	// Process invert flag
	if(mem[0xdf80] & 0x40) {
		c ^= 0x0F;		// just invert the index
	}

	// Durango palette
	switch(c) {
		case 0x00: red = 0x00; green = 0x00; blue = 0x00; break; // 0
		case 0x01: red = 0x00; green = 0xaa; blue = 0x00; break; // 1
		case 0x02: red = 0xff; green = 0x00; blue = 0x00; break; // 2
		case 0x03: red = 0xff; green = 0xaa; blue = 0x00; break; // 3
		case 0x04: red = 0x00; green = 0x55; blue = 0x00; break; // 4
		case 0x05: red = 0x00; green = 0xff; blue = 0x00; break; // 5
		case 0x06: red = 0xff; green = 0x55; blue = 0x00; break; // 6
		case 0x07: red = 0xff; green = 0xff; blue = 0x00; break; // 7
		case 0x08: red = 0x00; green = 0x00; blue = 0xff; break; // 8
		case 0x09: red = 0x00; green = 0xaa; blue = 0xff; break; // 9
		case 0x0a: red = 0xff; green = 0x00; blue = 0xff; break; // 10
		case 0x0b: red = 0xff; green = 0xaa; blue = 0xff; break; // 11
		case 0x0c: red = 0x00; green = 0x55; blue = 0xff; break; // 12
		case 0x0d: red = 0x00; green = 0xff; blue = 0xff; break; // 13
		case 0x0e: red = 0xff; green = 0x55; blue = 0xff; break; // 14
		case 0x0f: red = 0xff; green = 0xff; blue = 0xff; break; // 15
	}

	// Process RGB flag
	if(!(mem[0xdf80] & 0x08)) {
		red   = ((c&1)?0x88:0) | ((c&2)?0x44:0) | ((c&4)?0x22:0) | ((c&8)?0x11:0);
		green = red;
		blue  = green;	// that, or a switch like above for some sort of gamma correction, note bits are in reverse order!
	}

	SDL_SetRenderDrawColor(sdl_renderer, red, green, blue, 0xff);
}

/* Set current color in SDL HiRes mode */
void vdu_set_hires_pixel(byte color_index) {
	byte color = color_index ? 0xFF : 0x00;

	// Process invert flag
	if(mem[0xdf80] & 0x40) {
		color = ~color;
	}

	SDL_SetRenderDrawColor(sdl_renderer, color, color, color, 0xff);
}

/* Draw color pixel in supplied address */
void vdu_draw_color_pixel(word addr) {
	SDL_Rect fill_rect;
	// Calculate screen address
	word screen_address = (mem[0xdf80] & 0x30) << 9;

	// Calculate screen y coord
	int y = floor((addr - screen_address) >> 6);
	// Calculate screen x coord
	int x = ((addr - screen_address) << 1) & 127;

	// Draw Left Pixel
	vdu_set_color_pixel((mem[addr] & 0xf0) >> 4);
	fill_rect.x = x << 2;				// * pixel_size;
	fill_rect.y = y << 2;				// * pixel_size;
	fill_rect.w = pixel_size;
	fill_rect.h = pixel_size;
	SDL_RenderFillRect(sdl_renderer, &fill_rect);
	// Draw Right Pixel
	vdu_set_color_pixel(mem[addr] & 0x0f);
	fill_rect.x += pixel_size;
	SDL_RenderFillRect(sdl_renderer, &fill_rect);
}

void vdu_draw_hires_pixel(word addr) {
	SDL_Rect fill_rect;
	int i;
	// Calculate screen address
	word screen_address = (mem[0xdf80] & 0x30) << 9;
	// Calculate screen y coord
	int y = floor((addr - screen_address) >> 5);
	// Calculate screen x coord
	int x = ((addr - screen_address) << 3) & 255;
	byte b = mem[addr];

	fill_rect.x = (x << 1) -2;			// * hpixel_size;
	fill_rect.y = y << 1;				// * hpixel_size;
	fill_rect.w = hpixel_size;
	fill_rect.h = hpixel_size;
	for(i=0; i<8; i++) {
		vdu_set_hires_pixel(b & 0x80);		// set function doesn't tell any non-zero value
		b <<= 1;
		fill_rect.x += hpixel_size;
		SDL_RenderFillRect(sdl_renderer, &fill_rect);
	}
}

/* Render Durango screen. */
void vdu_draw_full() {
	word i;
	byte hires_flag = mem[0xdf80] & 0x80;
	word screen_address = (mem[0xdf80] & 0x30) << 9;
	word screen_address_end = screen_address + 0x2000;

	//Clear screen
    SDL_SetRenderDrawColor(sdl_renderer, 0x00, 0x00, 0x00, 0xFF);
    SDL_RenderClear(sdl_renderer);

	// Color
	if(!hires_flag) {
		for(i=screen_address; i<screen_address_end; i++) {
			vdu_draw_color_pixel(i);
		}
	}
	// HiRes
	else {
		for(i=screen_address; i<screen_address_end; i++) {
			vdu_draw_hires_pixel(i);
		}
	}

	// Display something resembling the error LED at upper right corner, if lit
	if (err_led && !(mem[0xdfa0] & 1)) {	// check interrupt status
		// black surrounding
		SDL_SetRenderDrawColor(sdl_renderer, 0, 0, 0, 0xff);
		draw_circle(sdl_renderer, 490, 490, 10);
		// Set color to red
		SDL_SetRenderDrawColor(sdl_renderer, 0xff, 0x00, 0x00, 0xff);
		// Draw red led
		draw_circle(sdl_renderer, 490, 490, 8);
	}

	// A similar code may be used for other LEDs
	if (err_led && (mem[0xdf80] & 4)) {		// check free bit from '174
		// black surrounding
		SDL_SetRenderDrawColor(sdl_renderer, 0, 0, 0, 0xff);
		draw_circle(sdl_renderer, 460, 490, 10);
		// Set color to white
		SDL_SetRenderDrawColor(sdl_renderer, 0xff, 0xff, 0xff, 0xff);
		// Draw white led
		draw_circle(sdl_renderer, 460, 490, 8);
	}

	//Update screen
	SDL_RenderPresent(sdl_renderer);
	
	scr_dirty = 0;			// window has been updated
}

/* *** *** Process keyboard / mouse events *** *** */
/* *** redefine keymap *** */
void redefine(void) {
	int i, j;
/* some awkward sequences */
	byte n_a[10]	= {0x7e, 0x7c, 0x40, 0x23, 0xa4, 0xba, 0xac, 0xa6, 0x7b, 0x7d};	// number keys with ALT
	byte n_as[10]	= {0x9d, 0xa1,    0, 0xbc, 0xa3, 0xaa, 0xb4, 0x5c, 0xab, 0xbb}; // number keys with SHIFT+ALT
	byte n_ac[10]	= {0xad, 0x2a, 0xa2, 0xb1, 0xa5, 0xf7, 0x60, 0xbf, 0x96, 0x98}; // number keys with CTRL+ALT
	byte nl_c[5]	= {0x5f, 0x2b, 0x27, 0x2e, 0x2c};	// lower half number keys with CTRL
	byte n_cs[10]	= {0x7f, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x5e, 0x3f, 0x5b, 0x5d};	// number keys with CTRL+SHIFT
	byte curs[8]	= {0x02, 0x0b, 0x0a, 0x06, 0x19, 0x16, 0x01, 0x05};				// ASCII for left, up, down, right, pgup, pgnd, home, end
/* diacritics and indices */
	byte acute[5]	= {0xe1, 0xe9, 0xed, 0xf3, 0xfa};	// lowercase acute accents (sub $20 for uppercase, 1 for grave; add 1 for circumflex, 2 for umlaut*) except ä ($e4) and ö ($f6, both acute+3)
	byte tilde[5]	= {0xe3, 0xe6,    0, 0xf5, 0xe5};	// lowercase ã, ae, -, õ, å (sub $20 for uppercase)
	byte vowel[5]	= {'a', 'e', 'i', 'o', 'u'};		// position of lowercase circumflex, acute and umlaut vowels
	byte middle[5]	= {'g', 'h', 'j', 'k', 'l'};		// position of uppercase circumflex, grave and some with tilde

	for (i=0; i<8; i++)
		for (j=0;j<256;j++)
			keys[i][j]=0;		// clear entries by default

/* * some dedicated keys * */
	for (i=0; i<8; i++) {		// set some common keys to (almost) all shifted combos
		keys[i][0x08]	=0x08;	// backspace
		if (i<4)
			keys[i][0x09]=0x09;	// tab, except all ALTs (SWTC, 0 or $1A?)
		else
			keys[i][0x09]=0x00;	// tab, except all ALTs (SWTC, 0 or $1A?)***TBD
		keys[i][0x0d]	=0x0d;	// newline
		keys[i][0x1b]	=0x1b;	// escape
		switch(i) {
			case 2:
				keys[2][0x20]	=0x80;	// CTRL-SPACE
				break;
			case 4:
				keys[4][0x20]	=0xA0;	// ALT-SPACE
				break;
			case 6:
				keys[6][0x20]	=0;		// ALT+CTRL-SPACE
				break;
			default:
				keys[i][0x20]	=0x20;	// space bar, except CTRL ($80), ALT ($A0) and CTRL+ALT (0)
		}
		keys[i][0x7f]	=0x7f;	// delete
		if (i&1) {				// some SHIFTed combos, not affected by ALT/CTRL
			keys[i][',']=';';
			keys[i]['.']=':';
			keys[i]['-']='_';	// no dashes here, just hyphen/underscore
			keys[i][0x27]='?';	// apostrophe key
			keys[i][0xa1]=0xbf;	// reverse question
		} else {
			keys[i][',']=',';
			keys[i]['.']='.';
			keys[i]['-']='-';	// no dashes here, just hyphen/underscore
			keys[i][0x27]=0x27;	// apostrophe
			keys[i][0xa1]=0xa1;	// reverse exclamation
		}
		for (j=0; j<8; j++) {
			keys[i][curs[j]] = curs[j];			// set cursor keys for every modifier
		}
		if (i&2) {								// if CTRL is pressed...
			keys[i][curs[6]]	=0x15;			// ...both home and end...
			keys[i][curs[7]]	=0x04;			// ...refer to whole document
		}
	}
/* set top left key manually */
	keys[0][0xba]	=0xba;		// ord m.
	keys[1][0xba]	=0xaa;		// ord f.
	keys[4][0xba]	=0x5c;		// backslash
	keys[5][0xba]	=0xb0;		// degree (Mac)

/* * number keys * */
	for (i='0'; i<='9'; i++) {
		keys[0][i]		=i;				// unshifted numbers
		keys[1][i]		=i-0x10;		// shift all except 3 ($B7), 7 ($2F) and 0 ($3D)
		if (i>'4')
			keys[2][i]	=i+5;			// ctrl over 5 OK except 7 ($2D) and 8 ($3C)
		else
			keys[2][i]	=nl_c[i-'0'];	// first half of numbers + CTRL
		keys[3][i]	=n_cs[i-'0'];		// numbers with CTRL-SHIFT
		keys[4][i]	=n_a[i-'0'];		// alt
		keys[5][i]	=n_as[i-'0'];		// alt+shift
		keys[6][i]	=n_ac[i-'0'];		// alt+ctrl
		if ((i>'1')&&(i<'4'))
			keys[7][i]	=i+0x80;		//only these two ctrl-alt-shift number keys make sense
	}
/* manually assigned number keys */
	keys[1]['0']		=0x3d;	// equals
	keys[1]['3']		=0xb7;	// interpunct (shift-3)
	keys[1]['7']		=0x2f;	// slash
	keys[2]['7']		=0x2d;	// minus (ctrl-7)
	keys[2]['8']		=0x3c;	// less than
	keys[7]['0']		=0xaf;	// macron
	keys[7]['8']		=0x9c;	// infinity

/* * letter keys * */
	for (i='a'; i<='z'; i++) {
		keys[0][i]	=i;			// standard unshifted letter
		keys[1][i]	=i-0x20;	// uppercase letters
		keys[2][i]	=i-0x60;	// control codes
	}							// other combos must be computed differently
/* diacritics */
	for (i=0; i<5; i++) {		// check vowels
		keys[4][vowel[i]]	=acute[i];		// ALT vowel = acute
		keys[5][vowel[i]]	=acute[i]-0x20;	// ALT+SHIFT vowel = upper acute
		keys[4][middle[i]]	=tilde[i];		// ALT middle = tildes etc
		if (i!=2)
			keys[3][middle[i]]	=tilde[i]-0x20;	// CTRL+SHIFT middle = upper tildes etc
		else
			keys[3][middle[i]]	=0x8b;		// semigraphic alternative
		keys[6][middle[i]]	=acute[i]-1;	// ALT+CTRL middle = grave
		keys[7][middle[i]]	=acute[i]-0x21;	// ALT+CTRL+SHIFT middle = upper grave
		keys[3][vowel[i]]	=acute[i]+1;	// CTRL+SHIFT vowel = circum
		keys[5][middle[i]]	=acute[i]-0x1f;	// ALT+SHIFT middle = upper circum
		if ((i!=0) && (i!=3)) {
			keys[6][vowel[i]]	=acute[i]+2;	// ALT+CTRL vowel = umlaut
			keys[7][vowel[i]]	=acute[i]-0x1e;	// ALT+CTRL+SHIFT vowel = upper umlaut
		} else {
			keys[6][vowel[i]]	=acute[i]+3;	// special cases for ä and ö, b/c tilde
			keys[7][vowel[i]]	=acute[i]-0x1d;
		}
	}
// ÿ and some others TBD...

/* misc Spanish ISO layout characters, usually disabled with CTRL */
	keys[0]['+']	=0x2b;	// plus
	keys[1]['+']	=0x2a;	// star
	keys[4]['+']	=0x5d;	// close bracket
	keys[5]['+']	=0xb1;	// plus-minus
	keys[0]['`']	=0x60;	// grave accent
	keys[1]['`']	=0x5e;	// caret
	keys[4]['`']	=0x5b;	// open bracket

	keys[0][0xb4]	=0xb4;	// acute accent
	keys[1][0xb4]	=0xa8;	// diaeresis 
	keys[4][0xb4]	=0x7b;	// open braces 
	keys[5][0xb4]	=0xab;	// open guillemet
	keys[0][0xf1]	=0xf1;	// ñ
	keys[1][0xf1]	=0xd1;	// Ñ 
	keys[4][0xf1]	=0x7e;	// tilde

	keys[0][0xe7]	=0xe7;	// ç
	keys[1][0xe7]	=0xc7;	// Ç
	keys[4][0xe7]	=0x7d;	// close braces
	keys[5][0xe7]	=0xbb;	// close guillemet
	keys[0][0x3c]	=0x3c;	// <
	keys[1][0x3c]	=0x3e;	// >
	keys[4][0x3c]	=0x96;	// less or equal
	keys[5][0x3c]	=0x98;	// more or equal
}

void process_keyboard(SDL_Event *e) {
	int asc, shift;
	/*
	 * Type:
	 * SDL_KEYDOWN
	 * SDL_KEYUP
	 * SDL_JOYAXISMOTION
	 * SDL_JOYBUTTONDOWN
	 * SDL_JOYBUTTONUP
	 * SDL_MOUSEMOTION
	 * SDL_MOUSEBUTTONDOWN
	 * SDL_MOUSEBUTTONUP
	 * SDL_MOUSEWHEEL
	 * 
	 * Code:
	 * https://wiki.libsdl.org/SDL_Keycode
	 * 
	 * Modifiers:
	 * KMOD_NONE -> no modifier is applicable
	 * KMOD_LSHIFT -> the left Shift key is down
	 * KMOD_RSHIFT -> the right Shift key is down
	 * KMOD_LCTRL -> the left Ctrl (Control) key is down
	 * KMOD_RCTRL -> the right Ctrl (Control) key is down
	 * KMOD_LALT -> the left Alt key is down
	 * KMOD_RALT -> the right Alt key is down
	 * KMOD_CTRL -> any control key is down
	 * KMOD_SHIFT-> any shift key is down
	 * KMOD_ALT -> any alt key is down
	 * KMOD_CAPS -> caps key is down
	 */
	if(e->type == SDL_KEYDOWN) {
		if (ver)		printf("key: %c ($%x)\n", e->key.keysym.sym, e->key.keysym.scancode);
		
		shift = 0;			// default unshifted state
		if(SDL_GetModState() & KMOD_SHIFT) {			// SHIFT
			shift |= 1;		// d0 = SHIFT
		}
		if(SDL_GetModState() & KMOD_CTRL) {				// CONTROL
			shift |= 2;		// d1 = CONTROL
		}
		if(SDL_GetModState() & KMOD_ALT) {				// ALT
			shift |= 4;		// d2 = ALTERNATE
		}
		if (SDL_GetModState() & KMOD_CAPS)
		{
			printf("KMOD_CAPS is pressed\n");	// no CAPS LOCK support yet!
		}
		switch(e->key.keysym.scancode) {
			case 0x2f:				// grave accent
				asc = 0x60;
				break;
			case 0x34:				// acute accent
				asc = 0xb4;
				break;
			case 0x50:				// cursor left
				asc = 0x02;
				break;
			case 0x52:				// cursor up
				asc = 0x0b;
				break;
			case 0x51:				// cursor down
				asc = 0x0a;
				break;
			case 0x4f:				// cursor right
				asc = 0x06;
				break;
			case 0x4b:				// page up
				asc = 0x19;
				break;
			case 0x4e:				// page down
				asc = 0x16;
				break;
			case 0x4a:				// home
				asc = 0x01;
				break;
			case 0x4d:				// end
				asc = 0x05;
				break;
			case 0x62:				// numpad 0
				shift = 0;			// any numpad key will disable all modificators
				asc = '0';
				break;
			case 0x59:				// numpad 1-9
			case 0x5a:
			case 0x5b:
			case 0x5c:
			case 0x5d:
			case 0x5e:
			case 0x5f:
			case 0x60:
			case 0x61:
				shift = 0;
				asc = e->key.keysym.scancode - 0x28;
				break;
			case 0x58:				// numpad ENTER
				shift = 0;
				asc = 0x0d;
				break;
			case 0x63:				// numpad DECIMAL POINT
				shift = 0;
				asc = '.';			// desired value for EhBASIC
				break;
			case 0x57:				// numpad +
				shift = 0;
				asc = '+';
				break;
			case 0x56:				// numpad -
				shift = 0;
				asc = '-';
				break;
			case 0x55:				// numpad *
				shift = 1;			// actually SHIFT and '+'
				asc = '+';
				break;
			case 0x54:				// numpad /
				shift = 1;			// actually SHIFT and 7
				asc = '7';
				break;
			default:
				asc = e->key.keysym.sym;
		}
		if (asc<256) {
			asc = keys[shift][asc];	// read from keyboard table
			mem[0xDF9A] = asc;		// will temporarily store ASCII at 0xDF9A, as per PASK standard :-)
		}
	}
	// detect key release for PASK compatibility
	else if(e->type == SDL_KEYUP) {
		if (ver)	printf("·");
		mem[0xDF9A] = 0;
	}
	// gamepad button down
	else if(e->type == SDL_JOYBUTTONDOWN) {
		if (ver) printf("gamepad: %d button: %d\n",e->jbutton.which, e->jbutton.button);
		switch( e->jbutton.button) {
        	case 0: gamepads[e->jbutton.which] |= BUTTON_A; break;
        	case 1: gamepads[e->jbutton.which] |= BUTTON_B; break;
        	case 2: gamepads[e->jbutton.which] |= BUTTON_A; break;
        	case 3: gamepads[e->jbutton.which] |= BUTTON_B; break;
			case 8: gamepads[e->jbutton.which] |= BUTTON_SELECT; break;
        	case 9: gamepads[e->jbutton.which] |= BUTTON_START; break;
        }
		if (ver > 2) printf("gamepads[0] = $%x\n", gamepads[0]);
		if (ver > 2) printf("gamepads[0] = $%x\n", gamepads[1]);
	}
	// gamepad button up
	else if(e->type == SDL_JOYBUTTONUP) {
		switch( e->jbutton.button) {
        	case 0: gamepads[e->jbutton.which] &= ~BUTTON_A; break;
        	case 1: gamepads[e->jbutton.which] &= ~BUTTON_B; break;
			case 2: gamepads[e->jbutton.which] &= ~BUTTON_A; break;
        	case 3: gamepads[e->jbutton.which] &= ~BUTTON_B; break;
        	case 8: gamepads[e->jbutton.which] &= ~BUTTON_SELECT; break;
        	case 9: gamepads[e->jbutton.which] &= ~BUTTON_START; break;
        }
		if (ver > 2) printf("gamepads[0] = $%x\n", gamepads[0]);
		if (ver > 2) printf("gamepads[0] = $%x\n", gamepads[1]);
	}
	else if( e->type == SDL_JOYAXISMOTION) {
		if (ver) printf("gamepad: %d, axis: %d, value: %d\n", e->jaxis.which, e->jaxis.axis, e->jaxis.value);
		// Left
		if(e->jaxis.axis==0 && e->jaxis.value<0) {
			gamepads[e->jaxis.which] |= BUTTON_LEFT;
			gamepads[e->jaxis.which] &= ~BUTTON_RIGHT;
		}
		// Right
		else if(e->jaxis.axis==0 && e->jaxis.value>0) {
			gamepads[e->jaxis.which] &= ~BUTTON_LEFT;
			gamepads[e->jaxis.which] |= BUTTON_RIGHT;
		}
		// None
		else if(e->jaxis.axis==0 && e->jaxis.value==0) {
			gamepads[e->jaxis.which] &= ~BUTTON_LEFT;
			gamepads[e->jaxis.which] &= ~BUTTON_RIGHT;
		}
		// Up
		if(e->jaxis.axis==1 && e->jaxis.value<0) {
			gamepads[e->jaxis.which] |= BUTTON_UP;
			gamepads[e->jaxis.which] &= ~BUTTON_DOWN;
		}
		// Down
		else if(e->jaxis.axis==1 && e->jaxis.value>0) {
			gamepads[e->jaxis.which] &= ~BUTTON_UP;
			gamepads[e->jaxis.which] |= BUTTON_DOWN;
		}
		// None
		else if(e->jaxis.axis==1 && e->jaxis.value==0) {
			gamepads[e->jaxis.which] &= ~BUTTON_UP;
			gamepads[e->jaxis.which] &= ~BUTTON_DOWN;
		}
		if (ver > 2) printf("gamepads[0] = $%x\n", gamepads[0]);
		if (ver > 2) printf("gamepads[1] = $%x\n", gamepads[1]);
	}
}

/* Emulate first gamepad. */
void emulate_gamepad1(SDL_Event *e) {
	// Left key down p1 at o, now A
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'a') {
		// Left down
		gamepads[0] |= BUTTON_LEFT;		
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'a') {
		// Left up
		gamepads[0] &= ~BUTTON_LEFT;		
	}
	// Right key down p1 at p, now D
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'd') {
		// Right down
		gamepads[0] |= BUTTON_RIGHT;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'd') {
		// Right up
		gamepads[0] &= ~BUTTON_RIGHT;
	}
	// Up key p1 at q, now W
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'w') {
		// Up down
		gamepads[0] |= BUTTON_UP;		
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'w') {
		// Up up
		gamepads[0] &= ~BUTTON_UP;
	}
	// Down key p1 at a, now S
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 's') {
		// Down down
		gamepads[0] |= BUTTON_DOWN;		
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 's') {
		// Down up
		gamepads[0] &= ~BUTTON_DOWN;
	}
	// A key down p1 at space, now C
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'c') {
		// A down
		gamepads[0] |= BUTTON_A;		
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'c') {
		// A up
		gamepads[0] &= ~BUTTON_A;
	}
	// B key p1 at c, now X
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'x') {
		// B down
		gamepads[0] |= BUTTON_B;		
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'x') {
		// B up
		gamepads[0] &= ~BUTTON_B;
	}
	// START key p1 at space, now left shift
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == SDLK_LSHIFT) {
		// START down
		gamepads[0] |= BUTTON_START;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == SDLK_LSHIFT) {
		// START up
		gamepads[0] &= ~BUTTON_START;
	}
	// SELECT key p1 at x, now Z
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'z') {
		// SELECT down
		gamepads[0] |= BUTTON_SELECT;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'z') {
		// SELECT up
		gamepads[0] &= ~BUTTON_SELECT;
	}
}

/* Emulate second gamepad. */
void emulate_gamepad2(SDL_Event *e) {
	// Left key down p2 at u, now J
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'j') {
		// Left down
		gamepads[1] |= BUTTON_LEFT;		
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'j') {
		// Left up
		gamepads[1] &= ~BUTTON_LEFT;		
	}
	// Right key down p2 at i, now L
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'l') {
		// Right down
		gamepads[1] |= BUTTON_RIGHT;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'l') {
		// Right up
		gamepads[1] &= ~BUTTON_RIGHT;
	}
	// Up key p2 at w, now I
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'i') {
		// Up down
		gamepads[1] |= BUTTON_UP;		
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'i') {
		// Up up
		gamepads[1] &= ~BUTTON_UP;
	}
	// Down key p2 at s, now K
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'k') {
		// Down down
		gamepads[1] |= BUTTON_DOWN;		
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'k') {
		// Down up
		gamepads[1] &= ~BUTTON_DOWN;
	}
	// A key down p2 at e, now SPACE
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == ' ') {
		// A down
		gamepads[1] |= BUTTON_A;		
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == ' ') {
		// A up
		gamepads[1] &= ~BUTTON_A;
	}
	// B key p2 at d, now ALT-GR
	if(e->type == SDL_KEYDOWN && e->key.keysym.scancode == SDL_SCANCODE_RALT) {
		// B down
		gamepads[1] |= BUTTON_B;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.scancode == SDL_SCANCODE_RALT) {
		// B up
		gamepads[1] &= ~BUTTON_B;
	}
	// START key p2 at r, now N
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'n') {
		// START down
		gamepads[1] |= BUTTON_START;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'n') {
		// START up
		gamepads[1] &= ~BUTTON_START;
	}
	// SELECT key p2 at f, now M
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'm') {
		// SELECT down
		gamepads[1] |= BUTTON_SELECT;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'm') {
		// SELECT up
		gamepads[1] &= ~BUTTON_SELECT;
	}
}

void emulation_minstrel(SDL_Event *e) {
	// COL 1 DOWN
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == ' ') {
		minstrel_keyboard[0] |= 128;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 13) {
		minstrel_keyboard[0] |= 64;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == SDLK_LSHIFT) {	// LEFT SHIFT
		minstrel_keyboard[0] |= 32;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'p') {
		minstrel_keyboard[0] |= 16;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == '0') {
		minstrel_keyboard[0] |= 8;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'a') {
		minstrel_keyboard[0] |= 4;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'q') {
		minstrel_keyboard[0] |= 2;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == '1') {
		minstrel_keyboard[0] |= 1;
	}
	// COL 1 UP
	if(e->type == SDL_KEYUP && e->key.keysym.sym == ' ') {
		minstrel_keyboard[0] &= ~128;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 13) {
		minstrel_keyboard[0] &= ~64;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == SDLK_LSHIFT) {	// LEFT SHIFT
		minstrel_keyboard[0] &= ~32;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'p') {
		minstrel_keyboard[0] &= ~16;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == '0') {
		minstrel_keyboard[0] &= ~8;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'a') {
		minstrel_keyboard[0] &= ~4;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'q') {
		minstrel_keyboard[0] &= ~2;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == '1') {
		minstrel_keyboard[0] &= ~1;
	}
	// COL 2 DOWN
	if(e->type == SDL_KEYDOWN && e->key.keysym.scancode == SDL_SCANCODE_RALT) {	// ALT (GR) SDLK_RALT
		minstrel_keyboard[1] |= 128;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'l') {
		minstrel_keyboard[1] |= 64;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'z') {
		minstrel_keyboard[1] |= 32;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'o') {
		minstrel_keyboard[1] |= 16;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == '9') {
		minstrel_keyboard[1] |= 8;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 's') {
		minstrel_keyboard[1] |= 4;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'w') {
		minstrel_keyboard[1] |= 2;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == '2') {
		minstrel_keyboard[1] |= 1;
	}
	// COL 2 UP
	if(e->type == SDL_KEYUP && e->key.keysym.scancode == SDL_SCANCODE_RALT) {	// ALT (GR)
		minstrel_keyboard[1] &= ~128;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'l') {
		minstrel_keyboard[1] &= ~64;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'z') {
		minstrel_keyboard[1] &= ~32;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'o') {
		minstrel_keyboard[1] &= ~16;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == '9') {
		minstrel_keyboard[1] &= ~8;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 's') {
		minstrel_keyboard[1] &= ~4;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'w') {
		minstrel_keyboard[1] &= 24;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == '2') {
		minstrel_keyboard[1] &= ~1;
	}
	// COL 3 DOWN
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'm') {
		minstrel_keyboard[2] |= 128;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'k') {
		minstrel_keyboard[2] |= 64;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'x') {
		minstrel_keyboard[2] |= 32;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'i') {
		minstrel_keyboard[2] |= 16;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == '8') {
		minstrel_keyboard[2] |= 8;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'd') {
		minstrel_keyboard[2] |= 4;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'e') {
		minstrel_keyboard[2] |= 2;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == '3') {
		minstrel_keyboard[2] |= 1;
	}
	// COL 3 UP
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'm') {
		minstrel_keyboard[2] &= ~128;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'k') {
		minstrel_keyboard[2] &= ~64;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'x') {
		minstrel_keyboard[2] &= ~32;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'i') {
		minstrel_keyboard[2] &= ~16;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == '8') {
		minstrel_keyboard[2] &= ~8;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'd') {
		minstrel_keyboard[2] &= ~4;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'e') {
		minstrel_keyboard[2] &= ~2;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == '3') {
		minstrel_keyboard[2] &= ~1;
	}
	// COL 4 DOWN
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'n') {
		minstrel_keyboard[3] |= 128;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'j') {
		minstrel_keyboard[3] |= 64;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'c') {
		minstrel_keyboard[3] |= 32;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'u') {
		minstrel_keyboard[3] |= 16;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == '7') {
		minstrel_keyboard[3] |= 8;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'f') {
		minstrel_keyboard[3] |= 4;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'r') {
		minstrel_keyboard[3] |= 2;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == '4') {
		minstrel_keyboard[3] |= 1;
	}
	// COL 4 UP
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'n') {
		minstrel_keyboard[3] &= ~128;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'j') {
		minstrel_keyboard[3] &= ~64;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'c') {
		minstrel_keyboard[3] &= ~32;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'u') {
		minstrel_keyboard[3] &= ~16;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == '7') {
		minstrel_keyboard[3] &= ~8;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'f') {
		minstrel_keyboard[3] &= ~4;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'r') {
		minstrel_keyboard[3] &= ~2;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == '4') {
		minstrel_keyboard[3] &= ~1;
	}
	// COL 5 DOWN
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'b') {
		minstrel_keyboard[4] |= 128;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'h') {
		minstrel_keyboard[4] |= 64;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'v') {
		minstrel_keyboard[4] |= 32;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'y') {
		minstrel_keyboard[4] |= 16;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == '6') {
		minstrel_keyboard[4] |= 8;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 'g') {
		minstrel_keyboard[4] |= 4;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == 't') {
		minstrel_keyboard[4] |= 2;
	}
	if(e->type == SDL_KEYDOWN && e->key.keysym.sym == '5') {
		minstrel_keyboard[4] |= 1;
	}
	// COL 5 UP
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'b') {
		minstrel_keyboard[4] &= ~128;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'h') {
		minstrel_keyboard[4] &= ~64;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'v') {
		minstrel_keyboard[4] &= ~32;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'y') {
		minstrel_keyboard[4] &= ~16;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == '6') {
		minstrel_keyboard[4] &= ~8;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 'g') {
		minstrel_keyboard[4] &= ~4;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == 't') {
		minstrel_keyboard[4] &= ~2;
	}
	if(e->type == SDL_KEYUP && e->key.keysym.sym == '5') {
		minstrel_keyboard[4] &= ~1;
	}
}

/* Process GUI events in VDU window */
void vdu_read_keyboard() {
	//Event handler
    SDL_Event e;
    
	//Handle events on queue
	while( SDL_PollEvent( &e ) != 0 )
	{
		// Vdu window is closed
		if(e.type == SDL_QUIT)
		{
			run = 0;
		}
		// Press F1 = STOP
		else if(e.type == SDL_KEYDOWN && e.key.keysym.sym==SDLK_F1) {
			run = 0;		// definitively stop execution
		}
		// Press F2 = NMI
		else if(e.type == SDL_KEYDOWN && e.key.keysym.sym==SDLK_F2) {
			nmi_flag = 1;	// simulate NMI signal
		}
		// Press F3 = IRQ?
		else if(e.type == SDL_KEYDOWN && e.key.keysym.sym==SDLK_F3) {
			irq_flag = 1;	// simulate (spurious) IRQ
		}
		// Press F4 = RESET
		else if(e.type == SDL_KEYDOWN && e.key.keysym.sym==SDLK_F4) {
			reset();
		}
		// Press F5 = PAUSE
		else if(e.type == SDL_KEYDOWN && e.key.keysym.sym==SDLK_F5) {
			run = 1;		// pause execution and display status
		}
		// Press F6 = DUMP memory to file
		else if(e.type == SDL_KEYDOWN && e.key.keysym.sym==SDLK_F6) {
			full_dump();
		}
		// Press F7 = STEP
		else if(e.type == SDL_KEYDOWN && e.key.keysym.sym==SDLK_F7) {
			run = 2;		// will execute a single opcode, then back to PAUSE mode
		}
		// Press F8 = RESUME
		else if(e.type == SDL_KEYDOWN && e.key.keysym.sym==SDLK_F8) {
			run = 3;		// resume normal execution
		}
		// Press F9 = LOAD DUMP
		else if(e.type == SDL_KEYDOWN && e.key.keysym.sym==SDLK_F9) {
			load_dump("dump.bin");	// load saved status...
			run = 3;		// ...and resume execution
			scr_dirty = 1;	// but update screen! EEEEEK
		}
		// Press F10 = KEYSTROKES
		else if(e.type == SDL_KEYDOWN && e.key.keysym.sym==SDLK_F10) {
			typed=fopen("keystrokes.txt","r");
			if (typed==NULL) {
				printf("\n*** No keystrokes file! ***\n");
			} else {
				printf("Sending keystrokes...");
				type_delay = 1;
				typing = 1;	// start typing from file
			}
		}
		// Press F11
		else if(e.type == SDL_KEYDOWN && e.key.keysym.sym==SDLK_F11) {
		}
		// Press F12
		else if(e.type == SDL_KEYDOWN && e.key.keysym.sym==SDLK_F12) {
			run = 0;
		}
		// Event forwarded to Durango
		else {
			// Emulate gamepads
			if(emulate_gamepads) {
				if(gp1_emulated) {
					emulate_gamepad1(&e);
				}
				if(gp2_emulated) {
					emulate_gamepad2(&e);
				}
			}
			// Emulate minstrel keyboard
			if(emulate_minstrel) {
				emulation_minstrel(&e);
			}
			// Full PASK keyboard is always emulated!
			process_keyboard(&e);
		}
	}
}

/* Aux procedure to draw circles using SDL */
void draw_circle(SDL_Renderer * renderer, int32_t x, int32_t y, int32_t radius) {
   for (int w = 0; w < radius * 2; w++)
    {
        for (int h = 0; h < radius * 2; h++)
        {
            int dx = radius - w; // horizontal offset
            int dy = radius - h; // vertical offset
            if ((dx*dx + dy*dy) <= (radius * radius))
            {
                SDL_RenderDrawPoint(sdl_renderer, x + dx, y + dy);
            }
        }
    }
}

/* SDL audio call back function */
void audio_callback(void *user_data, Uint8 *raw_buffer, int bytes) {
	// Fill buffer with new audio to play
	for(int i=0; i<bytes; i++) {
		raw_buffer[i] = aud_buff[i<<5];
	}
}

/* custom audio function */
void sample_audio(int time, int value) {
	if (time <= old_t) {			// EEEEEEEEEEK, not '<'
		time = 30576;
	}
	while (old_t != time) {
		aud_buff[old_t++] = old_v;
	}
	old_v = value;
	old_t %= 30576;
}
