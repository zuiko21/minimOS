#include <SDL2/SDL.h>

#ifndef VDU_HPP
#define VDU_HPP

using namespace std;

class Vdu {
    private:
        bool quit;
        //Screen dimension constants
        int SCREEN_WIDTH;
        int SCREEN_HEIGHT;
        //The window we'll be rendering to
        SDL_Window *sdl_window;
        //The window renderer
        SDL_Renderer* sdl_renderer;
        // Display mode
        SDL_DisplayMode sdl_display_mode;
        //Game Controllers 
        SDL_Joystick *sdl_gamepads[2];
        void init(void);
        void close(void);
        void sync_render(void);
        void render(void);
        void process_input_internal(SDL_Event *e);
    protected:
    public:
        Vdu(void);
        ~Vdu(void);
        void run(void); 
        
};


#endif
