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

		bits 16
		org 100h
		
start:
		; set video to vga graphic 320x200 256 colors mode
		mov ah, 0
		mov al, 13h
		int 10h

		mov di, 256 ; di = width
		call set_virtual_screen_width

		; destination VRAM
		mov ax, 0a000h
		mov es, ax
		; clear flag direction (increment next address)
		cld
		
		call wait_retrace
		; clear screen
		mov di, 0
		mov al, 15
		mov cx, 65535
		rep stosb

		call wait_retrace
		call load_img

		
	.next_y:
		mov di, [offset_y]
		mov ax, [offset_y]
		call move_to
		
		mov ah, 0
		int 16h
		cmp al, 27
		jz .exit
		
		add word [offset_y], 16
		jmp .next_y
		
	.exit:
		mov ah, 0
		mov al, 3
		int 10h
		
		mov ax, 4c00h
		int 21h
		
offset_y dw 0

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
		
; di = width
set_virtual_screen_width:
		mov dx, CRTC_INDEX
		mov al, LINE_OFFSET
		out dx, al
		mov dx, CRTC_DATA
		shr di, 3 ; width / 8
		mov ax, di
		out dx, al
		ret
		
; http://www.petesqbsite.com/sections/tutorials/tutorials/3scroll.htm		
; http://archive.gamedev.net/archive/reference/articles/article358.html
; di = x
; ax = y
move_to:
		;o := y*size+x; size=64 p/ virtual screen=256x?
		; y scrolling is ok, but horizontally it can scroll 4 pixel at a time
		
		mov cx, 64
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
		
		ret ; <--		


load_img:
		mov di, 0
		; source (DS already ok)
		mov si, img
		; image size in bytes
		mov cx, img_end - img
		rep movsb

		ret


img:
		; http://www.brackeen.com/vga/bitmaps.html
		incbin "img.bmp", 54 + 1024 ; skip header and palette information
img_end: