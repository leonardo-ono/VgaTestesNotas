		bits 16
		org 100h
	
start:
		mov ah, 0
		mov al, 13h
		int 10h

		; set ES to access video memory
		mov ax, 0a000h
		mov es, ax
	
		mov ax, 160
		mov bx, 100
		mov cl, 1 ; cl = color 		
		call set_pixel
		
		jmp .next_frame
		
	.next_circle:
	
		mov si, [angle]
		call get_cos
		mov bx, ax
		mov bx, 80
		imul bx
		sar ax, 7
		mov [screen_x], ax

		mov si, [angle]
		call get_sin
		mov bx, ax
		mov ax, 80
		imul bx
		sar ax, 7
		mov [screen_y], ax
		
		mov ax, [screen_x]
		add ax, 160
		mov bx, [screen_y]
		add bx, 100
		mov cl, 15 ; cl = color 		
		call set_pixel

		;inc word [angle]
		;cmp word [angle], 256
		;jb .next_circle

		mov ah, 0
		int 16h
		
		mov ax, 4c00h
		int 21h
		


	.next_frame:
		call wait_retrace	
		
	.next_pixel:	
		call calculate_texture_coordinates
		
		mov ax, [texture_x] ; ax = x
		mov bx, [texture_y] ; bx = y
		call get_texture_pixel ; out: cl = color
		
		mov ax, [screen_x] ; ax = x
		mov bx, [screen_y] ; bx = y
		;mov ax, [texture_x] ; ax = x
		;mov bx, [texture_y] ; bx = y
		;mov cl, 1 ; cl = color 		
		call set_pixel
		
		inc word [screen_x]
		cmp word [screen_x], 320
		jb .next_pixel
		
		mov word [screen_x], 0

		inc word [screen_y]
		cmp word [screen_y], 200
		jb .next_pixel
		
		
		mov ah, 1
		int 16h
		jnz .exit
		
		inc word [angle]
		mov word [screen_x], 0
		mov word [screen_y], 0
		
		jmp .next_frame
		
	.exit:
		mov ax, 4c00h
		int 21h
	
calculate_texture_coordinates:
		; calculate screen_x -> texture_x
		
		mov si, [angle]
		call get_cos
		mov bx, ax
		mov ax, [screen_x] ; screen x
		imul bx ; dx:ax
		sar ax, 7
		mov [tmp_a], ax

		mov si, [angle]
		call get_sin
		mov bx, ax
		mov ax, [screen_y] ; screen y
		imul bx ; dx:ax
		sar ax, 7
		mov [tmp_b], ax
		
		mov ax, [tmp_a]
		sub ax, [tmp_b]
		mov [texture_x], al

		; calculate screen_y -> texture_y
		mov si, [angle]
		call get_sin
		mov bx, ax
		mov ax, [screen_x] ; screen y
		imul bx ; dx:ax
		sar ax, 7
		mov [tmp_a], ax

		mov si, [angle]
		call get_cos
		mov bx, ax
		mov ax, [screen_y] ; screen x
		imul bx ; dx:ax
		sar ax, 7
		mov [tmp_b], ax

		mov ax, [tmp_a]
		add ax, [tmp_b]
		mov [texture_y], al
		
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
		;mov ah, 0
		mov al, [bx + si]
		cbw
		ret

;  in: si = angle 0-255
; out: ax = sin
get_cos:
		mov bx, sin_table
		sub si, 64
		and si, 0ffh
		;mov ah, 0
		mov al, [bx + si]
		cbw
		ret

load_texture:
		; destination VRAM
		mov ax, 0a000h
		mov es, ax
		mov di, 0
		; source (DS already ok)
		mov si, texture
		; image size in bytes
		mov cx, 64000
		cld ; clear flag direction (increment next address)
		rep movsb
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
		
		
angle dw 0

screen_x dw 0
screen_y dw 0

tmp_a dw 0
tmp_b dw 0

texture_x db 0
texture_y db 0

	
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
