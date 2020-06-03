; Infinite Horizontal Scroll in VGA mode 13
; test

		%define CRTC_INDEX   03d4h
		%define CRTC_DATA    03d5h
		%define INPUT_STATUS 03dah
		%define LINE_OFFSET    13h
		%define HIGH_ADDRESS   0ch
		%define LOW_ADDRESS    0dh
		
		bits 16
		org 100h
		
start:
		; set video to vga graphic 320x200 256 colors mode
		mov ah, 0
		mov al, 13h
		int 10h
		
		cld
		; destination VRAM
		mov ax, 0a000h
		mov es, ax
		

		mov bx, 336
		call set_virtual_width
		
		call load_img

		
		mov word [offset_x], 0
	.offset:
		

		
		mov di, [offset_x]
		mov ax, 0
		call move_to
	
		call wait_vsync
	
		mov ah, 0
		int 16h
		jnz .exit
		cmp al, 27
		jz .exit
		
		; ---------------- update column -----------
		; check need to update column
		mov ax, [offset_x]
		and al, 0fh
		cmp al, 0
		jnz .continue
		
	.update_next_column:
		mov bx, [column_x]
		mov dx, [column_y]
		call draw_bricks
		
		inc word [columns_count]
		cmp word [columns_count], 21
		jnz .column_y_ok
	.update_column_y:
		inc word [column_y]
		cmp word [columns_count], 0
		
	.column_y_ok:
		add word [column_x], 16
		cmp word [column_x], 336
		jnz .continue
		mov word [column_x], 0
		; ---------------- end update column -----------
		
	.continue:
		
		add word [offset_x], 4
		
		jmp .offset
		
	.exit:
		; set text mode
		mov ah, 0
		mov al, 3
		int 10h
		
		; return to DOS
		mov ax, 4c00h
		int 21h
		
offset_x dw 0
column_x dw 320
column_y dw 0
columns_count dw 20

; bx = width
set_virtual_width:
		mov dx, CRTC_INDEX
		mov al, LINE_OFFSET
		out dx, al
		mov dx, CRTC_DATA
		shr bx, 3 ; width / 8
		mov al, bl
		out dx, al
		ret
		
wait_vsync:
		pusha
		mov dx, INPUT_STATUS
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
		
; di = x
; ax = y
move_to:
		;o := y*size+x; size=160 p/ virtual screen=640x400
		; y scrolling is ok, but horizontally it can scroll 4 pixel at a time
		
		mov cx, 84
		xor dx, dx
		mul cx
		mov bx, di
		shr bx, 2
		add ax, bx

		mov bx, ax ; 10 * 80 * 2 + 0
		mov ah, bh
		mov al, HIGH_ADDRESS

		mov dx, CRTC_INDEX
		out dx, ax

		mov ah, bl
		mov al, LOW_ADDRESS
		mov dx, CRTC_INDEX
		out dx, ax		
		
ret ; <--		

load_img:
		mov di, 0
		; source (DS already ok)
		mov si, img
		; image size in bytes
		mov cx, 64000
		; clear flag direction (increment next address)
		cld
		rep movsb
		ret
		
; bx = x
; dx = y
draw_bricks:
		mov si, 0
	.next_brick:
		push si
		push dx
		call draw_brick
		pop dx
		pop si
		add dx, 16
		inc si
		cmp si, 10
		jb .next_brick
		ret
		
; bx = x
; dx = y
draw_brick:
		mov di, dx
		shl di, 8
		mov ax, dx
		shl ax, 6
		shl dx, 4
		add di, ax
		add di, dx
		add di, bx ; destination
		
		mov al, 0 ; line counter
		mov si, brick
	.next_line:
		; source (DS already ok)
		; image size in bytes
		mov cx, 8
		; clear flag direction (increment next address)
		rep movsw
		
		add di, 336 - 16
		inc al
		cmp al, 16
		jb .next_line
		
		ret
		
brick:
		incbin "brick.bmp", 54 + 1024 ; skip header and palette information
		
img:
		incbin "img.bmp", 54 + 1024 ; skip header and palette information

