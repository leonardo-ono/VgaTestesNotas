; easy way to load bitmap images
; without worrying about palette

		%define INPUT_STATUS 03dah

		bits 16
		org 100h
		
start:
		; set video to vga graphic 320x200 256 colors mode
		mov ah, 0
		mov al, 13h
		int 10h
		
		call load_img
		
		mov ah, 0
		int 16h
		
	.next_frame:
		call wait_vsync
		call wait_vsync
		call wait_vsync
		call wait_vsync
		call wait_vsync
		
		call change_palette
		
		mov ax, [frame] 
		add ax, [palette_frame_size]
		add ax, [palette_frame_size]
		add ax, [palette_frame_size]
		mov [frame], ax
		
		cmp ax, palette_last_frame - palette_frames
		jbe .frame_ok
		
		mov word [frame], 0
		
	.frame_ok:	
		mov ah, 1
		int 16h
		jnz .exit
		;cmp al, 27
		;jz .exit
		
		jmp .next_frame
	
	.exit:
		mov ah, 0
		mov al, 3
		int 10h
		
		mov ax, 4c00h
		int 21h

load_img:
		; destination VRAM
		mov ax, 0a000h
		mov es, ax
		mov di, 0
		; source (DS already ok)
		mov si, img
		; image size in bytes
		mov cx, 64000
		; clear flag direction (increment next address)
		cld
		rep movsb
		ret
			
; frame
change_palette:
		mov dx, 3c8h
		mov al, 0 ; color index
		out dx, al
		
		mov cx, [palette_frame_size]
		
		mov si, palette_frames
		add si, [frame]
		
	.next_color:
		mov dx, 3c9h
		mov al, [si]
		out dx, al ;red
		mov dx, 3c9h
		mov al, [si + 1]
		out dx, al ; green
		mov dx, 3c9h
		mov al, [si + 2]
		out dx, al ; blue
		
		add si, 3
		
		loop .next_color
		
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

frame dw 0

img:
		; http://www.brackeen.com/vga/bitmaps.html
		incbin "anim.dat", 0 ; 54 + 1024 ; skip header and palette information

		%include "pal_frames.asm"
