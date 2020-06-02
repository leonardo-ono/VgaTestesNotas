; Bad Sync TV Effect
; tested on DOSBox with 245 CPU cycles (!)
; Disclaimer: use this code at your own risk, i am not responsible 
;             for any damage caused by the use of this content.

		%define CRTC_INDEX   03d4h
		%define CRTC_DATA    03d5h
		%define INPUT_STATUS 03dah
		%define LINE_OFFSET    13h
		
		bits 16
		org 100h
		
start:
		; set video to vga graphic 320x200 256 colors mode
		mov ah, 0
		mov al, 13h
		int 10h
		
		call load_img

		; start bad sync tv effect
		
		mov word [offset_x], 0xff
	.offset:
		mov bx, [offset_x]
		call set_virtual_width
		
		mov ah, 1
		int 16h
		jnz .pause
		
		call wait_vsync		
		call wait_vsync		
		call wait_vsync		
		
		xor word [offset_x], 10101010b
		add word [offset_x], 197
		
		jmp .offset
	.pause:
		mov ah, 0
		int 16h
		cmp al, 27 ; ESC to exit
		jz .exit

		mov bx, 320
		call set_virtual_width

		mov ah, 0
		int 16h
		
		cmp al, 27
		jz .exit
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
		
img:
		incbin "img.bmp", 54 + 1024 ; skip header and palette information
