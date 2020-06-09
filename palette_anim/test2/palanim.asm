; references:
; http://elearning.algonquincollege.com/coursemat/pincka/dat2343/lectures.f03/33-COM-and-EXE.htm

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
			call load_all_pages
			
		.next_frame:
		
			call far wait_vsync
			call far wait_vsync
			call far wait_vsync
			
			call far next_animation_frame
			
			; wait for keypress
			mov ah, 1
			int 16h
			jnz .exit
			;cmp al, 27
			;jz .exit
			
			jmp .next_frame
			
		.exit:	
			; return to text mode
			mov al, 3
			call far set_video_mode
			
			; exit to DOS
			mov ax, 4c00h
			int 21h
			
	load_all_pages:
			; page 0
			mov ax, screen_data_page_0
			mov es, ax      ; es = image segment
			mov si, 0       ; si = image address
			mov bx, 0       ; bx = start x		
			mov dx, 200 * 0 ; dx = start y		
			call far draw_image
			; page 1
			mov ax, screen_data_page_1
			mov es, ax      ; es = image segment
			mov si, 0       ; si = image address
			mov bx, 0       ; bx = start x		
			mov dx, 200 * 1 ; dx = start y		
			call far draw_image
			; page 2
			mov ax, screen_data_page_2
			mov es, ax      ; es = image segment
			mov si, 0       ; si = image address
			mov bx, 0       ; bx = start x		
			mov dx, 200 * 2 ; dx = start y		
			call far draw_image
			; page 3
			mov ax, screen_data_page_3
			mov es, ax      ; es = image segment
			mov si, 0       ; si = image address
			mov bx, 0       ; bx = start x		
			mov dx, 200 * 3 ; dx = start y		
			call far draw_image
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
			; mov al, 0 ; color index even-0 odd-128
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
			call far change_write_plane
			
			pop bx
			pop cx

			mov ax, dx
			shl ax, 6
			
			shl dx, 4
			add ax, dx
			
			shr bx, 2
			add ax, bx
			
			mov bx, ax
			
			mov [bx], cl
			
			pop ds
			
			retf

	; es = image segment
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
			mov cl, [es:si] ; pixel color
			call far set_pixel
			
			inc word [img_i]
			
			inc word [img_x]
			mov bx, 320 ; image width
			cmp  [img_x], bx
			jb .next_pixel
			
			mov word [img_x], 0
			inc word [img_y]
			mov dx, 200 ; image height
			cmp [img_y], dx
			jb .next_pixel
			
			retf


segment data
	letter             db 'A'
	frame              dw 0
	
	; draw image
	img_start_x dw 0
	img_start_y dw 0
	img_x dw 0
	img_y dw 0
	img_i dw 0
		
segment screen_data_page_0 align=16
	incbin "data/page_0.dat"
	
segment screen_data_page_1 align=16
	incbin "data/page_1.dat"

segment screen_data_page_2 align=16
	incbin "data/page_2.dat"

segment screen_data_page_3 align=16
	incbin "data/page_3.dat"

segment palette_animation_data
	%include "data/pal_0.asm"
	%include "data/pal_1.asm"
	%include "data/pal_2.asm"
	%include "data/pal_3.asm"
	palette_frames_end:
	
segment stack stack
	resb 256
