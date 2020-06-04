; references:
;
; Osystem - https://www.youtube.com/watch?v=9vdsRD3oI3c&t=14s
; https://github.com/mills32/Little-Game-Engine-for-VGA
;
; https://github.com/root42/letscode-breakout/blob/master/vga.c
; root42 - https://www.youtube.com/watch?v=IFueAukNyxk
; http://www.scs.stanford.edu/10wi-cs140/pintos/specs/freevga/vga/vgafx.htm

		%define MISC_OUTPUT  03c2h
		%define GC_INDEX     03ceh
		%define SC_INDEX     03c4h
		%define SC_DATA      03c5h
		%define CRTC_INDEX   03d4h
		%define CRTC_DATA    03d5h
		%define INPUT_STATUS 03dah
		%define AC_WRITE     03c0h
		%define AC_READ      03c1h		
		%define MAP_MASK       02h
		%define MEMORY_MODE    04h
		%define UNDERLINE_LOC  14h
		%define MODE_CONTROL   17h
		%define HIGH_ADDRESS   0ch
		%define LOW_ADDRESS    0dh
		%define LINE_OFFSET    13h
		%define PEL_PANNING    13h
		
		%define CRTC_LINECOMPARE 24		
		%define CRTC_OVERFLOW     7
		%define CRTC_MAXSCANLINE  9
		
		%define AC_INDEX	    03c0h ; Attribute controller index register
		%define AC_MODE_CONTROL	  10h ; Index of Mode COntrol register in AC
		
		bits 16
		org 100h
		
start:
		mov al, 13h
		call set_video_mode
		call set_video_mode_y
		call set_virtual_640
		
		mov si, img
		mov bx, 0
		mov dx, 0
		call draw_image

		mov si, img
		mov bx, 320
		mov dx, 0
		call draw_image
		
		mov si, img
		mov bx, 0
		mov dx, 200
		call draw_image

		mov si, img
		mov bx, 320
		mov dx, 200
		call draw_image

		
		;mov ah, 0
		;int 16h
		;jmp .exit
		
		;call fill_screen

		mov di, 170
		call split_screen

		
		mov ax, 0
		mov bp, 0
	.next_y:

	

		;mov si, black
		;mov bx, [scroll_prev]
		;add bx, 30
		;mov dx, 50
		;call draw_image
		;mov si, black
		;mov bx, [scroll_prev]
		;add bx, 40
		;mov dx, 70
		;call draw_image
		
		mov si, ship
		mov bx, bp
		add bx, 30
		mov dx, 50
		call draw_image
		mov si, ship
		mov bx, bp
		add bx, 40
		mov dx, 70
		call draw_image
		
		mov ax, 20 ; bp ; bp y scroll
		mov di, bp ; bp x scroll
		call move_to

		call wait_retrace
		; call wait_retrace
		;call wait_retrace
		;call wait_retrace

		
		; wait for keypress
		mov ah, 1
		int 16h
		; cmp al, 27
		jnz .exit
		
		mov [scroll_prev], bp
		
		add bp, 1
		cmp bp, 320
		jb .next_y
		mov bp, 0
		jmp .next_y
		
	.exit:
		mov al, 3h
		call set_video_mode

		mov ax, 4c00h
		int 21h

; si = image address
; bx = start x		
; dx = start y		
draw_image:		
		mov [img_start_x], bx
		mov [img_start_y], dx
		mov word [img_x], 0
		mov word [img_y], 0
		mov word [img_i], 0
		mov di, si
	.next_pixel:
		mov bx, [img_x] ; x
		mov dx, [img_y] ; y
		add bx, [img_start_x] ; x
		add dx, [img_start_y] ; y
		
		mov si, di
		add si, [img_i]
		mov cl, [si] ; pixel color
		call set_pixel
		
		inc word [img_i]
		
		inc word [img_x]
		mov bx, [di - 4] ; image width
		cmp  [img_x], bx
		jb .next_pixel
		
		mov word [img_x], 0
		inc word [img_y]
		mov dx, [di - 2] ; image height
		cmp [img_y], dx
		jb .next_pixel
		
		ret 

; bx = x
; dx = y
; cl = color
set_pixel:
		push ds
		mov ax, 0a000h
		mov ds, ax
		
		push cx
		push bx
		
		mov cl, bl
		and cl, 3
		mov ch, 1
		shl ch, cl
		
		mov bl, ch
		call change_write_plane
		
		pop bx
		pop cx

		mov ax, dx
		shl ax, 7
		
		shl dx, 5
		add ax, dx
		
		shr bx, 2
		add ax, bx
		
		mov bx, ax
		
		mov [bx], cl
		
		pop ds
		ret
		
; AL = video mode		
set_video_mode:
		mov ah, 0
		int 10h
		ret
		
; reference: http://www.brackeen.com/vga/source/bc31/modes.c.html		
set_video_mode_y:
		; turn off chain-4 mode 
		mov dx, SC_INDEX
		mov al, MEMORY_MODE
		out dx, al

		mov dx, SC_DATA
		mov al, 06h
		out dx, al

		; set map mask to all 4 planes for screen clearing 
		mov dx, SC_INDEX
		mov al, MAP_MASK
		out dx, al

		mov dx, SC_DATA
		mov al, 0ffh
		out dx, al

		; turn off long mode 
		mov dx, CRTC_INDEX
		mov al, UNDERLINE_LOC
		out dx, al

		mov dx, CRTC_DATA
		mov al, 0
		out dx, al

		; turn on byte mode 
		mov dx, CRTC_INDEX
		mov al, MODE_CONTROL
		out dx, al

		mov dx, CRTC_DATA
		mov al, 0e3h
		out dx, al

		mov dx, MISC_OUTPUT
		mov al, 0e3h
		out dx, al
		
		; clear all video memory
		mov bl, 0ffh
		call change_write_plane
		
		ret

fill_screen:
		push es
		mov ax, 0a000h
		mov es, ax
		mov dl, 1 ; color
		mov bl, 1
	.next_plane:
		call change_write_plane
		
		mov di, 0
		mov cx, 16000
		mov al, dl
		rep stosb
		inc dl

		mov di, 16000
		mov cx, 16000
		mov al, dl
		rep stosb
		inc dl

		mov di, 32000
		mov cx, 16000
		mov al, dl
		rep stosb
		inc dl

		mov di, 48000
		mov cx, 16000
		mov al, dl
		rep stosb
		inc dl
		
		shl bl, 1
		cmp bl, 16
		jz .end
		
		jmp .next_plane
	.end:
		pop es
		ret
		
	
; bl  = 1 2 4 8
; plane 0 1 2 3
change_write_plane:
		push bx
		push dx
		push ax
		mov dx, SC_INDEX
		mov al, MAP_MASK
		out dx, al
		mov dx, SC_DATA
		mov al, bl
		out dx, al
		pop ax
		pop dx
		pop bx
		ret

		
; root42 - https://github.com/root42/letscode-breakout/blob/master/vga.c		
; http://www.petesqbsite.com/sections/tutorials/tutorials/3scroll.htm
; this register holds the number of bytes (not pixels) difference between the start address of each row
set_virtual_640:
		mov dx, CRTC_INDEX
		mov al, LINE_OFFSET
		out dx, al
		mov dx, CRTC_DATA
		mov al, 640 / 8
		out dx, al
		ret
		
; http://www.petesqbsite.com/sections/tutorials/tutorials/3scroll.htm		
; http://archive.gamedev.net/archive/reference/articles/article358.html
; di = x
; ax = y
move_to:
		;o := y*size+x; size=160 p/ virtual screen=640x400
		; y scrolling is ok, but horizontally it can scroll 4 pixel at a time
		
		mov cx, 160
		xor dx, dx
		mul cx
		mov bx, di
		shr bx, 2
		add ax, bx

		mov    bx, ax ; 10 * 80 * 2 + 0
		mov    ah, bh
		mov    al, HIGH_ADDRESS

		mov    dx, CRTC_INDEX
		out    dx, ax

		mov    ah, bl
		mov    al, LOW_ADDRESS
		mov    dx, CRTC_INDEX
		out    dx, ax		
		
; ret ; <--		
		
		; 4 pixels fix for panning
		
		cli ; <- is this necessary ?
		
		mov dx, INPUT_STATUS
		in al, dx
		
		mov dx, AC_WRITE
		in al, DX
		mov bl, al
		
		mov dx, AC_WRITE
		mov al, PEL_PANNING
		out dx, al
		
		mov dx, AC_WRITE
		mov ax, di ; scroll x
		shl ax, 1
		out dx, al
		
		mov dx, AC_WRITE
		mov al, bl
		out dx, al
		
		sti ; <- is this necessary ?
		
		ret	
		
wait_retrace:
		pusha
		mov dx, 3dah
	.l1:
		in al,dx
		test al, 08h
		jz .l1
		
	.l2:
		in al,dx
		test al, 08h
		jnz .l2
		popa
		ret
		
; https://github.com/mills32/Little-Game-Engine-for-VGA/blob/master/SRC/lt_gfx.c		
; https://github.com/sparky4/16/blob/master/src/lib/16_vl.c
; void VL_SetSplitScreen (int linenum)
; {
; 	VL_WaitVBL (1);
; 	linenum=linenum*2-1;
; 	outportb (CRTC_INDEX,CRTC_LINECOMPARE);
; 	outportb (CRTC_INDEX+1,linenum % 256);
; 	outportb (CRTC_INDEX,CRTC_OVERFLOW);
; 	outportb (CRTC_INDEX+1, 1+16*(linenum/256));
; 	outportb (CRTC_INDEX,CRTC_MAXSCANLINE);
; 	outportb (CRTC_INDEX+1,inportb(CRTC_INDEX+1) & (255-64));
; }

; di = linenum
split_screen:
		shl di, 1
		dec di
		
		mov dx, CRTC_INDEX
		mov al, CRTC_LINECOMPARE
		out dx, al
		
		mov dx, CRTC_DATA
		mov ax, di
		out dx, al
	
		mov dx, CRTC_INDEX
		mov al, CRTC_OVERFLOW
		out dx, al
		
		mov dx, CRTC_DATA
		mov ax, di
		shr ax, 8
		shl ax, 4
		inc ax
		out dx, al

		mov dx, CRTC_INDEX
		mov al, CRTC_MAXSCANLINE
		out dx, al
		
		mov dx, CRTC_DATA
		in al, dx
		
		and al, (255-64)
		
		mov dx, CRTC_DATA
		out dx, al
	
		; Turn on split screen pal pen suppression, so the split screen
		; won't be subject to pel panning as is the non split screen portion.

		mov  dx, INPUT_STATUS
		in   al, dx                  	; Reset the AC Index/Data toggle to index state
		mov  al, AC_MODE_CONTROL + 20h 	; Bit 5 set to prevent screen blanking
		mov  dx, AC_INDEX				; Point AC to Index/Data register
		out  dx, al
		inc  dx							; Point to AC Data reg (for reads only)
		in   al, dx						; Get the current AC Mode Control reg
		or   al, 20h						; Enable split scrn Pel panning suppress.
		dec  dx							; Point to AC Index/Data reg (for writes only)
		out  dx, al		
	
		ret
		
		scroll_prev dw 0 
		
		; image file
		img_start_x dw 0
		img_start_y dw 0
		img_x dw 0
		img_y dw 0
		img_i dw 0
		%include "img.asm"

