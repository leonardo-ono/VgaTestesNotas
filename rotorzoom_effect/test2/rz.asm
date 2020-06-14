; Assembly 8086 RotoZoom Effect
;
; Written by Leonardo (ono.leo@gmail.com)
; June 14, 2020
;
; Target Machine: Pentium II 300 (at least ?)
; Target OS: DOS
; Assembler: nasm 2.14
; To assemble: nasm rz.asm -o rz.com -f bin
;
; References:
; https://www.youtube.com/watch?v=NXca7V9ODGg
; http://www.hugi.scene.org/online/coding/hugi%2012%20-%20corzoom.htm		
; https://www.flipcode.com/archives/The_Art_of_Demomaking-Issue_10_Roto-Zooming.shtml
; https://seancode.com/demofx/

		bits 16
		org 100h
	
start:
		mov ah, 0
		mov al, 13h
		int 10h
		
		; convert screen to 320x100
		mov bl, 3 ; bl = max scanline
		call set_max_scanline

		; set ES to access video memory
		mov ax, 0a000h
		mov es, ax
	
	.next_frame:
		call wait_retrace	
		
	.next_pixel:	
		call calculate_screen_to_texture_coordinates
		
		mov ax, [texture_x] ; ax = x
		mov bx, [texture_y] ; bx = y
		call get_texture_pixel ; out: cl = color
		
		mov ax, [screen_x] ; ax = x
		mov bx, [screen_y] ; bx = y
		;mov cl, 1 ; cl = color 		
		call set_pixel
		
		inc word [screen_x]
		cmp word [screen_x], 320
		jb .next_pixel
		
		;mov ax, [frame]
		;and ax, 1
		mov word [screen_x], 0

		add word [screen_y], 1
		cmp word [screen_y], 100
		jb .next_pixel
		
		; exit if keypress
		mov ah, 1
		int 16h
		jnz .exit
		
		inc word [angle]
		mov word [screen_x], 0
		mov word [screen_y], 0
		
		inc word [frame]
		jmp .next_frame
		
	.exit:
		mov ah, 0
		mov al, 3h
		int 10h

		mov ax, 4c00h
		int 21h
	
calculate_screen_to_texture_coordinates:

		mov si, [angle]
		;shl si, 1
		call get_cos
		mov [tmp_cos], ax
		mov si, [angle]
		shl si, 1
		call get_sin
		mov [tmp_sin], ax
		
		;mov bx, 08fh
		;shr ax, 2
		;add bx, ax
		add ax, 128 + 64
		mov word [scale], ax ; 110000000b

		; calculate screen_x -> texture_x

		mov si, [angle]
		;shr si, 1
		call get_cos
		mov bx, ax
		mov ax, [screen_x] ; screen x
		sub ax, 160
		add ax, [tmp_sin]
		imul bx ; dx:ax
		sar ax, 7
		call scale_ax
		mov [tmp_a], ax

		mov si, [angle]
		;shr si, 1
		call get_sin
		mov bx, ax
		mov ax, [screen_y] ; screen y
		shl ax, 1
		sub ax, 100
		sub ax, [tmp_cos]
		imul bx ; dx:ax
		sar ax, 7
		call scale_ax
		mov [tmp_b], ax
		
		mov ax, [tmp_a]
		sub ax, [tmp_b]
		mov [texture_x], al

		; calculate screen_y -> texture_y
		mov si, [angle]
		;shr si, 1
		call get_sin
		mov bx, ax
		mov ax, [screen_x] ; screen y
		sub ax, 160
		add ax, [tmp_sin]
		imul bx ; dx:ax
		sar ax, 7
		call scale_ax
		mov [tmp_a], ax

		mov si, [angle]
		;shr si, 1
		call get_cos
		mov bx, ax
		mov ax, [screen_y] ; screen x
		shl ax, 1
		sub ax, 100
		sub ax, [tmp_cos]
		imul bx ; dx:ax
		sar ax, 7
		call scale_ax
		mov [tmp_b], ax

		mov ax, [tmp_a]
		add ax, [tmp_b]
		mov [texture_y], al
		
		ret

; ax 
scale_ax:
		push bx
		mov bx, [scale]
		imul bx
		sar ax, 7
		pop bx
		ret

; in:  ax = x
;      bx = y
; out: cl = color 		
get_texture_pixel:
		and ax, 127
		and bx, 127
		shl bx, 7
		add bx, ax
		mov cl, [bx + texture]
		ret
		
; set white pixel
; ax = x
; bx = y
; cl = color 		
set_pixel:
		mov dx, bx
		shl dx, 8
		shl bx, 6
		add bx, dx
		add bx, ax
		mov byte [es:bx], cl ; cl = color
		ret
		
;  in: si = angle 0-255
; out: ax = sin
get_sin:
		mov bx, sin_table
		and si, 0ffh
		mov al, [bx + si]
		cbw
		ret

;  in: si = angle 0-255
; out: ax = sin
get_cos:
		mov bx, sin_table
		sub si, 64
		and si, 0ffh
		mov al, [bx + si]
		cbw
		ret
		
; bl = max scanline
set_max_scanline:
		mov dx, 03d4h ; CRTC_INDEX
		mov al, 9h ; CRTC_MAXSCANLINE
		out dx, al
		
		mov dx, 03d5h; CRTC_DATA
		mov al, bl
		out dx, al
		ret
			
wait_retrace:
		mov dx, 3dah
	.l1:
		in al,dx
		test al, 08h
		jz .l1
		
	.l2:
		in al,dx
		test al, 08h
		jnz .l2
		ret

; --- data ---

frame dw 0
		
angle dw 0

scale dw 20h

screen_x dw 0
screen_y dw 0

tmp_a dw 0
tmp_b dw 0

texture_x db 0
texture_y db 0

tmp_cos dw 0
tmp_sin dw 0
	
; pre-calculated 256 bytes lookup sin table
sin_table:
		db 0, 3, 6, 9, 12, 15, 18, 21, 24, 28, 31, 34, 37, 40, 43, 46, 48, 51, 54, 
		db 57, 60, 63, 65, 68, 71, 73, 76, 78, 81, 83, 85, 88, 90, 92, 94, 96, 98, 
		db 100, 102, 104, 106, 108, 109, 111, 112, 114, 115, 117, 118, 119, 120, 
		db 121, 122, 123, 124, 124, 125, 126, 126, 127, 127, 127, 127, 127, 127, 
		db 127, 127, 127, 127, 127, 126, 126, 125, 124, 124, 123, 122, 121, 120, 
		db 119, 118, 117, 115, 114, 112, 111, 109, 108, 106, 104, 102, 100, 98, 
		db 96, 94, 92, 90, 88, 85, 83, 81, 78, 76, 73, 71, 68, 65, 63, 60, 57, 54, 
		db 51, 48, 46, 43, 40, 37, 34, 31, 28, 24, 21, 18, 15, 12, 9, 6, 3, 0, -3, 
		db -6, -9, -12, -15, -18, -21, -24, -28, -31, -34, -37, -40, -43, -46, -48, 
		db -51, -54, -57, -60, -63, -65, -68, -71, -73, -76, -78, -81, -83, -85, 
		db -88, -90, -92, -94, -96, -98, -100, -102, -104, -106, -108, -109, -111, 
		db -112, -114, -115, -117, -118, -119, -120, -121, -122, -123, -124, -124, 
		db -125, -126, -126, -127, -127, -127, -127, -127, -128, -127, -127, -127, 
		db -127, -127, -126, -126, -125, -124, -124, -123, -122, -121, -120, -119, 
		db -118, -117, -115, -114, -112, -111, -109, -108, -106, -104, -102, -100, 
		db -98, -96, -94, -92, -90, -88, -85, -83, -81, -78, -76, -73, -71, -68, 
		db -65, -63, -60, -57, -54, -51, -48, -46, -43, -40, -37, -34, -31, -28, 
		db -24, -21, -18, -15, -12, -9, -6, -3    

texture:
		incbin "tex.bmp", 54 + 1024 ; skip header and palette information
