/*
	keyboard.h
*/

#define LEFT	'K'
#define RIGHT	'M'
#define UP	'H'
#define DOWN	'P'
#define Z	','
#define X	'-'
#define ESC     1

extern void far install_key_handler();
extern void far uninstall_key_handler();
extern int far is_key_pressed(int code);
