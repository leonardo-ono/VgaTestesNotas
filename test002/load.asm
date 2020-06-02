; easy way to load bitmap images
; without worrying about palette

		bits 16
		org 100h
		
start:
		; set video to vga graphic 320x200 256 colors mode
		mov ah, 0
		mov al, 13h
		int 10h
		
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
		
		mov ax, 4c00h
		int 21h
		
img:
		; http://www.brackeen.com/vga/bitmaps.html
		incbin "img.bmp", 54 + 1024 ; skip header and palette information
