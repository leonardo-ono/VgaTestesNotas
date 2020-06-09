; Assembly 8086 Palette Animation in VGA Unchained Graphic Mode-Y
;
; Written by Leonardo Ono (ono.leo80@gmail.com)
; June 9, 2020
;
; Target Machine: PC-XT 4.7MHz
; Target OS: DOS
; Assembler: nasm 2.14
; Linker: tlink (Turbo Link v2.0)
; To assemble and link, use: build.bat
;
; references:
; http://elearning.algonquincollege.com/coursemat/pincka/dat2343/lectures.f03/33-COM-and-EXE.htm
; http://www.osdever.net/FreeVGA/vga/colorreg.htm
; Sonic 3D's Impossibly Compressed Logo FMV - How's it done? - https://www.youtube.com/watch?v=c-aQvP7CUAI
;
; resources:
; https://www.thisiscolossal.com/2018/12/new-gifs-by-etienne-jacob/

			%define MISC_OUTPUT       03c2h
			%define GC_INDEX          03ceh
			%define SC_INDEX          03c4h
			%define SC_DATA           03c5h
			%define CRTC_INDEX        03d4h
			%define CRTC_DATA         03d5h
			%define INPUT_STATUS      03dah
			%define AC_WRITE          03c0h
			%define AC_READ           03c1h		
			%define MAP_MASK            02h
			%define MEMORY_MODE         04h
			%define UNDERLINE_LOC       14h
			%define MODE_CONTROL        17h
			%define HIGH_ADDRESS        0ch
			%define LOW_ADDRESS         0dh
			%define LINE_OFFSET         13h
			%define PEL_PANNING         13h
			%define CRTC_LINECOMPARE    18h		
			%define CRTC_OVERFLOW        7h
			%define CRTC_MAXSCANLINE     9h
			%define AC_MODE_CONTROL	    10h

			bits 16

segment code

	..start:
			mov ax, data
			mov ds, ax

			mov al, 13h
			call far set_video_mode
			call far set_video_mode_y
			call far reset_palette
			call load_all_planes
			
		.next_frame:
			call far wait_vsync
			call far wait_vsync
			call far wait_vsync
			
			call far next_animation_frame
			
			; exit if keypress
			mov ah, 1
			int 16h
			jnz .exit
			
			jmp .next_frame
			
		.exit:	
			; return to text mode
			mov al, 3
			call far set_video_mode
			
			; exit to DOS
			mov ax, 4c00h
			int 21h

	load_all_planes:
			mov bl, 1 ; bl = plane 1 2 4 8
			mov dx, screen_data_plane_0 ; dx = source segment
			mov si, 0 ; si = source address
			call far load_plane
			
			mov bl, 2 ; bl = plane 1 2 4 8
			mov dx, screen_data_plane_1 ; dx = source segment
			mov si, 0 ; si = source address
			call far load_plane
			
			mov bl, 4 ; bl = plane 1 2 4 8
			mov dx, screen_data_plane_2 ; dx = source segment
			mov si, 0 ; si = source address
			call far load_plane
			
			mov bl, 8 ; bl = plane 1 2 4 8
			mov dx, screen_data_plane_3 ; dx = source segment
			mov si, 0 ; si = source address
			call far load_plane
			
			ret
			
segment video

	; al = video mode		
	set_video_mode:
			mov ah, 0
			int 10h
			retf
			
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
			call far change_write_plane
			
			retf
			
	; bl  = 1 2 4 8
	; plane 0 1 2 3
	change_write_plane:
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
			retf
		
	wait_vsync:
			push ax
			push dx
			mov dx, INPUT_STATUS
		.l1:
			in al, dx
			test al, 08h
			jz .l1
		.l2:
			in al, dx
			test al, 08h
			jnz .l2
			pop dx
			pop ax
			retf	
			
	; di = x
	; ax = y			
	move_to:
			pusha
			;o := y*size+x; size=80 p/ virtual screen width 320 pixels 
			mov cx, 80
			xor dx, dx
			mul cx
			mov bx, di
			shr bx, 2
			add ax, bx
			mov    bx, ax
			mov    ah, bh
			mov    al, HIGH_ADDRESS
			mov    dx, CRTC_INDEX
			out    dx, ax
			mov    ah, bl
			mov    al, LOW_ADDRESS
			mov    dx, CRTC_INDEX
			out    dx, ax		
			popa
			retf
			
	reset_palette:
			mov dx, 3c8h
			mov al, 0 ; color index 
			out dx, al
			mov cx, 256 ; palette size
		.next_color:
			mov dx, 3c9h
			mov al, 0
			out dx, al ;red
			out dx, al ; green
			out dx, al ; blue
			loop .next_color
			retf
			
	; bl = plane 1 2 4 8
	; dx = source segment
	; si = source address
	load_plane:
			push ds
			
			; source
			mov ds, dx

			call far change_write_plane

			; destination VRAM
			mov ax, 0a000h
			mov es, ax
			mov di, 0
			
			; source ds:si
			
			; image size in bytes
			mov cx, 64000
			; clear flag direction (increment next address)
			cld
			rep movsb
			
			pop ds
			retf
			
	next_animation_frame:
			mov ax, palette_animation_data
			mov es, ax
			
			mov si, [frame] ; current frame address
			push si

			mov ah, 0
			mov al, [es:si] 
			and ax, 1
			shl ax, 7
			
			mov dx, 3c8h
			; al = color index even-0 odd-128
			out dx, al
			
			mov cx, 128 ; palette size
		.next_color:

			mov dx, 3c9h
			mov al, [es:si + 1]
			out dx, al ;red
			mov dx, 3c9h
			mov al, [es:si + 2]
			out dx, al ; green
			mov dx, 3c9h
			mov al, [es:si + 3]
			out dx, al ; blue
			add si, 4
			loop .next_color
			
			mov [frame], si
			
			cmp si, palette_frames_end
			jb .frame_ok
			
			mov word [frame], 0
			
		.frame_ok:
			; flip screen to the correct page
			pop si
			mov di, 0 ; di = x
			mov bl, [es:si] ; page number
			mov ax, 200
			mul bl ; ax = y			
			call far move_to

			retf


segment data
		frame dw 0
	
segment screen_data_plane_0 align=16
		incbin "data/plane_0.dat"
	
segment screen_data_plane_1 align=16
		incbin "data/plane_1.dat"

segment screen_data_plane_2 align=16
		incbin "data/plane_2.dat"

segment screen_data_plane_3 align=16
		incbin "data/plane_3.dat"

segment palette_animation_data
		%include "data/pal_0.asm"
		%include "data/pal_1.asm"
		%include "data/pal_2.asm"
		%include "data/pal_3.asm"
	palette_frames_end:
	
segment stack stack
		resb 256
