; online youtube downloader: https://en.savefrom.net/17/
; video to jpg: https://www.onlineconverter.com/video-to-jpg
		
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
		org 100h
		
start:
		mov al, 13h
		call set_video_mode
		call set_video_mode_y
		call fix_palette
		; convert screen resolution to 320x100
		mov bl, 3 ; bl = max scanline
		call set_max_scanline
		
		mov ax, 0a000h
		mov es, ax

		mov ah, 0
		int 16h
		
	.next_frame:
		call wait_vsync
		call wait_vsync
		call wait_vsync
		call wait_vsync
		call wait_vsync
		call wait_vsync
		call wait_vsync
		call wait_vsync
		;call wait_vsync
		
		call draw_frame
		
		mov ah, 1
		int 16h
		jnz .exit
		;cmp al, 27
		;jz .exit
		
		jmp .next_frame
		
	.exit:
		mov al, 3
		call set_video_mode
		
		mov ax, 4c00h
		int 21h


; al = video mode		
set_video_mode:
		mov ah, 0
		int 10h
		ret
		
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
		
; bl = max scanline
set_max_scanline:
		mov dx, CRTC_INDEX
		mov al, CRTC_MAXSCANLINE
		out dx, al
		
		mov dx, CRTC_DATA
		mov al, bl
		out dx, al
		ret		
		
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
		ret
	
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
		ret

fix_palette:
		mov dx, 3c8h
		mov al, 1 ; color index 
		out dx, al
;		mov cx, 256 ; palette size
;	.next_color:
		mov dx, 3c9h
		mov al, 0ffh
		out dx, al ;red
		out dx, al ; green
		out dx, al ; blue
;		loop .next_color
		ret
			
; http://faydoc.tripod.com/cpu/stosb.htm			
draw_frame:
		push ds

		mov si, [current_frame]
		
		cmp si, data_frame_end
		jae .ret
		
		; es already ok
		mov ax, 0a000h
		mov es, ax
		mov di, 0
		
		cld ; clear direction flag
		mov bx, 0
	.next:
	
		mov cx, [si]
		
		cmp cx, 0
		jz .end
		
		mov ax, bx
		and ax, 1
		rep stosb
		
		inc bx
		add si, 2
		
		jmp .next
		
	.end:
		add si, 2
		mov [current_frame], si
	.ret:
		pop ds
		ret

current_frame dw data_frame

data_frame:
		%include "anim.asm"
	data_frame_end:
