; Infinite Horizontal Scroll in VGA mode 13
; tested on DOSBox with 245 CPU cycles (!)

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
		
		cld
		; destination VRAM
		mov ax, 0a000h
		mov es, ax
		

		mov bx, 336
		call set_virtual_width

;		mov di, 0
;		mov cx, 20
;	.draw_next_col:
;		pusha
;		call draw_bricks
;		popa
;		add di, 16
;		loop .draw_next_col

		
		mov word [offset_x], 0
	.offset:
		
		
		mov di, [offset_x] ; scroll x
		mov ax, -2
		call move_to
	
		call wait_vsync

		mov ah, 1
		int 16h
		jnz .exit
		cmp al, 27
		jz .exit
			
		; column
		mov ax, [offset_x]
		and ax, 0fh
		cmp ax, 0
		jnz .column_ok
	.update_column:
	
		;inc word [column_count]
		;cmp word [column_count], 22
		;jnz .column_count_ok
		;inc word [offset_y]
		;mov word [column_count], 0
		add word [offset_y], 336 * 16
		
	.column_count_ok:
		mov di, [offset_x]
		; add di, [offset_y]
		add di, 320
		
		;mov di, 336 * 16 + 32
		call draw_bricks
		
	.column_ok:
	
	.continue:

		add word [offset_x], 1
		
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
offset_y dw 0

column_count dw 20

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
		;o := y*size+x; size=84 p/ virtual screen=336x?
		; y scrolling is ok, but horizontally it can scroll 4 pixel at a time
		
		cli
		
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
		
		; fix smooth horizontal scroll
		
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
		
		sti
		
		ret			

; di = start address
draw_bricks:
		mov si, 0
	.next_brick:
		call draw_brick
		add di, 336 * 16
		inc si
		cmp si, 12
		jb .next_brick
		ret
		
; di = destination address
draw_brick:
		push di
		push si
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
		pop si
		pop di
		ret
		
; di = destination address
draw_mario:
		push di
		mov al, 0 ; line counter
		mov si, mario
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
		
		pop di
		ret

; di = destination address
draw_black:
		push di
		mov al, 0 ; line counter
		mov si, black
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
		
		pop di
		ret
		
draw_marios:
		mov di, [offset_x] ; = destination address
		add di, 336 * 20 + 50
		call draw_black
		call draw_mario
		
		ret
		
		mov di, [offset_x] ; = destination address
		add di, 336 * 50 + 30
		call draw_black
		call draw_mario
		mov di, [offset_x] ; = destination address
		add di, 336 * 70 + 20
		call draw_black
		call draw_mario
		mov di, [offset_x] ; = destination address
		add di, 336 * 100 + 40
		call draw_black
		call draw_mario
		mov di, [offset_x] ; = destination address
		add di, 336 * 150 + 100
		call draw_black
		call draw_mario
		mov di, [offset_x] ; = destination address
		add di, 336 * 20 + 70
		call draw_black
		call draw_mario
		mov di, [offset_x] ; = destination address
		add di, 336 * 30 + 40
		call draw_black
		call draw_mario
		mov di, [offset_x] ; = destination address
		add di, 336 * 40 + 10
		call draw_black
		call draw_mario
		mov di, [offset_x] ; = destination address
		add di, 336 * 90 + 80
		call draw_black
		call draw_mario
		mov di, [offset_x] ; = destination address
		add di, 336 * 170 + 120
		call draw_black
		call draw_mario
		
		ret
		
brick:
		incbin "brick.bmp", 54 + 1024 ; skip header and palette information

black:
		incbin "black.bmp", 54 + 1024 ; skip header and palette information

mario:
		incbin "mario.bmp", 54 + 1024 ; skip header and palette information

