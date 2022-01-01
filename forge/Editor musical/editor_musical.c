//
//  main.c
//  EditorMusical
//
//  Created by Carlos Javier Santisteban Salinas on 13/05/13.
//  Copyright (c) 2013-2022 Carlos Javier Santisteban Salinas. All rights reserved.
//

#include <stdio.h>

#include <unistd.h>
#include <termios.h>
#include <string.h>

// maximum ram size
#define limite  300

// function headers
void    ejecutar(int m);
int     tecla(void);

void    intro(void);
void    editar(void);
void    tempo_afi(void);
void    play(void);
void    borrar(void);
void    salir(void);

// globals
int     salida;
int     menu;
int     tempo;
int     tama;
int     ram[limite];

// strings
char    m1[] = {"Introducir: INTR\0"};
char    m2[] = {"Editar: EDIT\0"};
char    m3[] = {"Tempo: TEMP\0"};
char    m4[] = {"Tocar: PLAY\0"};
char    m5[] = {"Borrar: BORR\0"};
char    m6[] = {"Salir: SALE\0"};

char    t1[] = {"d=30\0"};
char    t2[] = {"d=35\0"};
char    t3[] = {"d=40\0"};
char    t4[] = {"d=50\0"};
char    t5[] = {"d=60\0"};
char    t6[] = {"d=70\0"};
char    t7[] = {"d=80\0"};
char    t8[] = {"d=90\0"};
char    t9[] = {"d=100\0"};
char    t10[] = {"d=120\0"};
char    t11[] = {"d=140\0"};
char    t12[] = {"d=160\0"};
char    t13[] = {"d=180\0"};
char    t14[] = {"d=200\0"};
char    t15[] = {"d=240\0"};
char    t16[] = {"d=300\0"};


// main loop

int main(int argc, const char * argv[])
{
    char*   menu_opt[] = {m1, m2, m3, m4, m5, m6};
    int     c;
    
    struct termios oldt, newt;

    menu = 0;   // default = first menu option
    tempo = 6;  // default = 80
    tama = 0;   // score size
    salida = 0; // don't exit yet

    // ••••• stuff for making getchar() behave as expected! •••••
    tcgetattr( STDIN_FILENO, &oldt);
    memcpy((void *)&newt, (void *)&oldt, sizeof(struct termios));
    newt.c_lflag &= ~(ICANON);  // Reset ICANON so enter after char is not needed
    newt.c_lflag &= ~(ECHO);    // Turn echo off
    tcsetattr( STDIN_FILENO, TCSANOW, &newt);
    // •••••
    
    // OPEN_W, get I/O device port
    // z_used = *, set used zero-page space
    
    printf("Editor musical 1.0\n");
    printf("<cr> = OK, <esc> = NO; (+/–)\n");
    while (!salida)  // loop forever
    {
         printf("%s\n", menu_opt[menu]);
        while(EOF == (c = getchar()));
        if (c == '\n')  ejecutar(menu);
        if (c == 27 || c == '+' || c == 'u')    // should be UP instead of 'u'
        {
            menu++;
            if (menu > 5)      menu = 0;
        }
        if (c == 'j' || c == '-')   // should be DOWN instead of 'j'
        {
            menu--;
            if (menu < 0)       menu = 5;
        }
        
    }
    
    // ••••• revert to the standard way •••••
    tcsetattr( STDIN_FILENO, TCSANOW, &oldt);

    return 0;
}

// function definitions
void    ejecutar(int m)
{
    switch (m) {
        case 0:
            intro();
            break;
        case 1:
            editar();
            break;
        case 2:
            tempo_afi();
            break;
        case 3:
            play();
            break;
        case 4:
            borrar();
            break;
        case 5:
            salir();
            break;
            
        default:
            printf("\n•••ERROR: Opción desconocida•••\n");
            break;
    }
    menu++;
    printf("<cr> = OK, <esc> = NO; (+/–)\n");
}

int     tecla(void)
{
    int     c;
    
    c = getchar() | 32;         // all low case, numbers remain the same
    if (c > 64)     c = c-49;   // A...G equals 0...6
    
    return c;
}

void    intro(void)
{
    int     pos, nota, alter, oct, dur;
    int     c;
    
    pos = 0;
    c = 0;
    while (c != '?')
    {
        printf("\nNota %d: ", pos+1);
        do
            c = tecla();
        while ((c>='0' && c<='5') || c=='?');   // wait for a note, rest or exit
        if (c>='0')
        {
            nota = c-'0';       // get note pitch 0...6
            printf("%c", c+17); // prints A...G
        }
        else    break;          // otherwise, exit
        do
            c = tecla();
        while ((c>='4' && c<='9') || c=='.' || c=='?');   // wait for alteration, octave or exit
        if (c == '?')   break;  // aborted procedure
        else            switch
        
        
    }
        

}

void    editar(void)
{
    // edit score
}

void    tempo_afi(void)
{
    char*   t_tx[] = {t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16};
    int     c;

    printf("(+/-)\n");
    do {
        printf("Negra %s\n", t_tx[tempo]);
        c = getchar();
        if (c == '+')   // OR up
        {
            tempo++;
            if (tempo > 15)     tempo = 15;
        }
        if (c == '-')   // OR down
        {
            tempo--;
            if (tempo < 0)     tempo = 0;
        }
    } while (c != '?' && c != 27 && c != '\n');
    if (c == '\n')
    {
        // set intonation
    }
}

void    play(void)
{
    // play score
}

void    borrar(void)
{
    int     c;
    printf("¿BORRAR? Sí: +\n");
    c = getchar();
    if (c=='+')
    {
        printf("¡Borrada!\n");
        tama = 0;
    }
}

void    salir(void)
{
    int     c;
    printf("¿SALIR? Sí: -\n");
    c = getchar();
    if (c == '-')
    {
        printf("\n••• Fin del programa •••\n");
        salida = -1;
    }
}
