/* ==========================================================================
    <UCONIO.H> = Unix Console Input Output
	-A port/customizing of the CONIO D.O.S library (Console
	 Input/Output) to UNIX.
	 Also, i added some extra functions.

    File Version: UConio-1.0.9-PR
    Date: Tue Oct 24 22:00:34 ART 2000
    
    Author: Pablo J. Vidal <pablo@pablovidal.org>    
    URL: http://www.pablovidal.org
    
    BUG REPORTS TO: <uconio-bugs@pablovidal.org>
    
    Current Working Functions:
	* u_clrscr()      -  Clear the Screen
	* u_gotoxy()      -  Move the cursor to anywhere on the screen
    [E] * u_beep()        -  Play a single or more beeps on the PC Speaker
	* u_textcolor()   -  Change the Text foreground and background colour
    [E] * u_textattr()    -  Change the Text attributes
	* u_wherex()      -  Gets current 'x' position
	* u_wherey()      -  Gets current 'y' position
	* u_getch()       -  Gets a single character from the stdin
	* u_getche()      -  Gets and echo a single char from stdin to stdout
	* u_normvideo()   -  Reset the Video attribs to Default
	* u_clreol()      -  Clear the current line
	* u_puttext()     -  Create a BOX with characters inside
    [E] * u_vputc()       -  Put a determinated quantity of characters on the
	                     screen    
    [E] * u_vputs()       -  Put a string on the screen
    [E] * u_vgets()       -  Get a string from the keyboard
    [E] * u_vgetc()       -  Get a single character from any stream

    (NOTE: the [E] icon placed before the function name means the
	   contiguous function is an Extra function isnt in conio.h)
	
    ToDo:
	 Write a new Tutorial
 ============================================================================ */

/* The Includes */
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <termios.h>
#include <stdarg.h>
#include <sys/ioctl.h>

/* Checks for multiple include of this library */
#ifndef __UCONIO_IN_USE__
#define __UCONIO_IN_USE__


/* ********************************************************************* 
   ** HERE BEGINS THE STRUCTS AND CONFIG MACROS                       **
   ********************************************************************* */

/* Text Attributes Preprocessor Definitions */
#define NORMAL 0        /* The Definition for NORMAL mode */
#define BOLD 1          /* The Definition for BOLD mode */
#define BLINK 2         /* The Definition for BLINK mode */

/* The Text Colour Preprocessor Definitions */
#define BLACK 0         /* The Definition for BLACK colour */
#define RED 1           /* The Definition for RED colour */
#define GREEN 2         /* The Definition for GREEN colour */
#define BROWN 3         /* The Definition for the BROWN colour */
#define BLUE 4          /* The Definition for the BLUE colour */
#define MAGENTA 5       /* The Definition for the MAGENTA colour */
#define CYAN 6          /* The Definition for the CYAN colour */
#define WHITE 7         /* The Definition for the WHITE colour */
#define DEFAULT 8       /* The Definition for the DEFAULT colour */

/* Video Properties Preprocessor Definitions */
#define X_MIN 0 	/* The 'X' minimum valour-position */
#define X_MAX 79	/* The 'X' maximum valour-position */
#define Y_MIN 0 	/* The 'Y' maximum valour-position */
#define Y_MAX 24	/* The 'Y' maximum valour-position */

/* Video Attributes Global Variable */
int Attribute=0;

/* Video Properties Structure */
struct Properties
    {
	short int x; /* Here goes the current 'x' position of the cursor */
	short int y; /* Here goes the current 'y' position of the cursor */
	int fg;      /* Here goes the current text foreground color */
	int bg;      /* Here goes the current text backgrount color */
	int attr;    /* Here goes the text attributes */
    };

/* Video Default Properties */
enum Defaults 
    {
	 def_x=X_MIN, /* The Default 'x' position for the cursor (Minimal) */
	 def_y=Y_MIN, /* The Default 'y' position for the cursor (Minimal) */
	   def_fg=49,    /* Text Foreground default color */
        	def_bg=49,    /* Text Backgrount default color */
    };


/* ********************************************************************* 
   ** HERE BEGINS THE FUNCTIONS DECLARATION                           **
   ********************************************************************* */
   
void u_clrscr(void);
void u_gotoxy(short x, short y);
void u_beep(register int times);
void u_textcolor(short int bg, short int fg);
void u_textattr(register int attri);
short int u_wherex(void);
short int u_wherey(void);
int u_getch(void);
int u_getche(void);
void u_clreol(void);
void u_normvideo(void);
int u_puttext(int left, int top, int right, int bottom, char *string);
void u_vputc(char *format, ...);
void u_vputs(char *string);
void u_vgets(char *string);
int u_vgetc(FILE *source);

#endif
