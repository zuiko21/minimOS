#include <SDL2/SDL.h>
#include <cmath>
#include <iostream>
#include "perdita_exception.hpp"
#include "vdu.hpp"

using namespace std;


Vdu::Vdu() {
}

Vdu::~Vdu() {  
}

void Vdu::setMemory(unsigned char *memory) {
  this->memory=memory;
}

void Vdu::init() {
    quit=false;
    
    //Initialize SDL
    if( SDL_Init( SDL_INIT_VIDEO | SDL_INIT_JOYSTICK ) < 0 )
    {
	  string error = "SDL could not be initialized! SDL Error: " + string(SDL_GetError());
      throw PerditaException(error);
    }
  
    //Set texture filtering to linear
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");
  
    //Check for joysticks 
    for(int i=0; i<SDL_NumJoysticks(); i++)
    {
      //Load joystick 
      sdl_gamepads[i] = SDL_JoystickOpen(i); 
      if(sdl_gamepads[i] == NULL ) 
      {
		 string error =  "Unable to open game controller #" + to_string(i) + "! SDL Error: " + string(SDL_GetError());
	     throw PerditaException(error);
      }
    }
      
    // Get display mode
    if (SDL_GetDesktopDisplayMode(0, &sdl_display_mode) != 0) {
      string error = "SDL_GetDesktopDisplayMode faile! SDL Error: " + string(SDL_GetError());
      throw PerditaException(error);
    }
    SCREEN_WIDTH=128*4;
    SCREEN_HEIGHT=SCREEN_WIDTH;
    
    //Create window
    sdl_window = SDL_CreateWindow("Durango", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_OPENGL);
    if( sdl_window == NULL )
    {
	  string error = "Window could not be created! SDL Error: " + string(SDL_GetError());
	  throw PerditaException(error);
    }
  
    //Create renderer for window
    this->sdl_renderer = SDL_CreateRenderer( sdl_window, -1, SDL_RENDERER_ACCELERATED );
    if( this->sdl_renderer == NULL )
    {
	  string error = "Renderer could not be created! SDL Error: " + string(SDL_GetError());
	  throw PerditaException(error);
    }
}

void Vdu::close() {
    
    //Destroy renderer  
    if(this->sdl_renderer!=NULL)
    {
      SDL_DestroyRenderer( this->sdl_renderer );
      this->sdl_renderer=NULL;
    }
  
    if(sdl_window != NULL)
    {
      // Destroy window
      SDL_DestroyWindow( this->sdl_window );
      this->sdl_window=NULL;
    }
  
    // Close gamepads
    for(int i=0; i<SDL_NumJoysticks(); i++)
    {
      SDL_JoystickClose(this->sdl_gamepads[i]);
      this->sdl_gamepads[i]=NULL;
    }
  
    // Close SDL
    SDL_Quit();
}

void Vdu::run()
{
    //Event handler
    SDL_Event e;
  
    // Init quit flag
    quit=0;
  
    // Init SDL
    init();
      
    // Main game loop
    while(!quit)
    {
      //Handle events on queue
      while( SDL_PollEvent( &e ) != 0 )
      {
        process_input_internal(&e);
      }
    
      // Update & Render
      sync_render();
    }
  
    // Close SDL
    close();
}

void Vdu::sync_render()
{
    unsigned int start, end, render_time; 
  
    start = SDL_GetTicks();
  
    // Render screen
    render();  
  
    end = SDL_GetTicks();
    render_time = end - start;
  
    // 60 fps -> 16ms
    // 30 fps -> 32ms
    // 50 fps -> 20ms
    // 60 fps -> 17ms
    // 100 fps -> 10ms
    if(render_time < 17)
    {
      //remaining = 1;
      SDL_Delay(17 - render_time);
    }
    else
    {
      printf("Render time: %ud !!!!\n", render_time);
    }  
}

void Vdu::render() {
    //Clear screen
    SDL_SetRenderDrawColor( sdl_renderer, 0x00, 0x00, 0x00, 0xFF );
    SDL_RenderClear( sdl_renderer );
  
    // Actual rendering
    durango_render();
  
    //Update screen
    SDL_RenderPresent(sdl_renderer);
}

void Vdu::durango_render() {
    unsigned long i;
    //Render red filled quad
    //SDL_Rect fillRect = { 10, 10, 10, 10 };
    //SDL_SetRenderDrawColor( sdl_renderer, 0xFF, 0x00, 0x00, 0xFF );        
    //SDL_RenderFillRect( sdl_renderer, &fillRect );
    
    /*for(i=0x0; i<0x10000; i++) {
      durango_render_mem(i);
    }*/
    durango_render_mem(0x6000);
}

void Vdu::durango_render_mem(unsigned long addr) {
  // video mode [HiRes Invert S1 S0    RGB LED NC NC]
  
  // Read video mode (HiRes or Colour)
  unsigned char videoMode = (this->memory[0xdf80] & 0x80)>>7;
  
  unsigned int screenAddress = ((this->memory[0xdf80] & 0x30)>>4)*0x2000;
  unsigned int screenAddressEnd = screenAddress + 0x2000;
 
  if(addr >= screenAddress && addr < screenAddressEnd) {   
    if(videoMode == 0) {
      drawColorPixel(addr);
    }
    else if(videoMode == 1) {
      drawHiResPixel(addr);
    }
  }
}


void Vdu::setColor(unsigned char index) {
  if(index!=0)
    
  switch(index) {
    case 0x00: SDL_SetRenderDrawColor( sdl_renderer, 0x00, 0x00, 0x00, 0xff ); break; // 0
    case 0x01: SDL_SetRenderDrawColor( sdl_renderer, 0x00, 0xaa, 0x00, 0xff ); break; // 1
    case 0x02: SDL_SetRenderDrawColor( sdl_renderer, 0xff, 0x00, 0x00, 0xff ); break; // 2
    case 0x03: SDL_SetRenderDrawColor( sdl_renderer, 0xff, 0xaa, 0x00, 0xff ); break; // 3
    case 0x04: SDL_SetRenderDrawColor( sdl_renderer, 0x00, 0x55, 0x00, 0xff ); break; // 4
    case 0x05: SDL_SetRenderDrawColor( sdl_renderer, 0x00, 0xff, 0x00, 0xff ); break; // 5
    case 0x06: SDL_SetRenderDrawColor( sdl_renderer, 0xff, 0x55, 0x00, 0xff ); break; // 6
    case 0x07: SDL_SetRenderDrawColor( sdl_renderer, 0xff, 0xff, 0x00, 0xff ); break; // 7
    case 0x08: SDL_SetRenderDrawColor( sdl_renderer, 0x00, 0x00, 0xff, 0xff ); break; // 8
    case 0x09: SDL_SetRenderDrawColor( sdl_renderer, 0x00, 0xaa, 0xff, 0xff ); break; // 9
    case 0x0a: SDL_SetRenderDrawColor( sdl_renderer, 0xff, 0x00, 0xff, 0xff ); break; // 10
    case 0x0b: SDL_SetRenderDrawColor( sdl_renderer, 0xff, 0xaa, 0xff, 0xff ); break; // 11
    case 0x0c: SDL_SetRenderDrawColor( sdl_renderer, 0x00, 0x55, 0xff, 0xff ); break; // 12
    case 0x0d: SDL_SetRenderDrawColor( sdl_renderer, 0x00, 0xff, 0xff, 0xff ); break; // 13
    case 0x0e: SDL_SetRenderDrawColor( sdl_renderer, 0xff, 0x55, 0xff, 0xff ); break; // 14
    case 0x0f: SDL_SetRenderDrawColor( sdl_renderer, 0xff, 0xff, 0xff, 0xff ); break; // 15
  }
}

void Vdu::drawColorPixel(unsigned long addr) {
  int pixelSize=SCREEN_WIDTH/128;
  // Calculate screen address
  unsigned long  screenAddress = ((this->memory[0xdf80] & 0x30)>>4)*0x2000;
  // Calculate screen y coord
  int y = floor((addr - screenAddress) * 2 / 128);
  // Calculate screen x coord
  int x = ((addr - screenAddress) *2) % 128;
  // Draw Left Pixel
  setColor((this->memory[addr] & 0xf0)>>4);
  SDL_Rect fillRect = { x * pixelSize, y * pixelSize, pixelSize, pixelSize };
  SDL_RenderFillRect( sdl_renderer, &fillRect );
  
  
  // Draw Right Pixel      
  setColor(this->memory[addr] & 0x0f);
  fillRect = { (x+1) * pixelSize, y * pixelSize, pixelSize, pixelSize };
  SDL_RenderFillRect( sdl_renderer, &fillRect );
}

void Vdu::drawHiResPixel(unsigned long addr) {
}

void Vdu::process_input_internal(SDL_Event *e)
{
    //User requests quit
    if(e->type == SDL_QUIT 
      // User press ESC or q
      || (e->type == SDL_KEYDOWN && (e->key.keysym.sym=='q' || e->key.keysym.sym == 27))
    )
    {
      quit = 1;
    }
    else {
        //process_input(e);
    }
}

