; fast bit blt copy screen to screen - 4 planes at once
;
; note: it can only copy from same plane source to same plane destination, i.e,
;       you can copy and paste to x position only every 4 pixels.
;        
; references:
; https://www.phatcode.net/res/224/files/html/ch48/48-01.html
; https://www.phatcode.net/res/224/files/html/ch48/48-04.html

		%define MISC_OUTPUT  03c2h
		%define CRTC_INDEX   03d4h
		%define CRTC_DATA    03d5h
		%define INPUT_STATUS 03dah
		%define AC_WRITE     03c0h
		%define AC_READ      03c1h		
		%define MEMORY_MODE    04h
		%define UNDERLINE_LOC  14h
		%define MODE_CONTROL   17h
		%define HIGH_ADDRESS   0ch
		%define LOW_ADDRESS    0dh
		%define LINE_OFFSET    13h
		%define PEL_PANNING    13h

		%define GC_INDEX     03ceh ;Graphics Controller Index register port
		%define SC_INDEX     03c4h ;Sequence Controller Index register port
		%define SC_DATA      03c5h
		%define GC_DATA      03cfh ;Graphics Controller Index register port

		%define MAP_MASK       02h ;index in SC of Map Mask register
		%define BIT_MASK       08h ;index in GC of Bit Mask register
		
		%define CRTC_LINECOMPARE 24		
		%define CRTC_OVERFLOW     7
		%define CRTC_MAXSCANLINE  9

		bits 16
		org 100h
		
start:
		mov al, 13h
		call set_video_mode
		call set_video_mode_y
		call set_virtual_640
		
		; clear flag direction
		cld
		
		; destination VRAM
		mov ax, 0a000h
		mov es, ax

	; --- start main loop ---
	
	
		; draw ship
		mov si, brick
		mov bx, 0
		mov dx, 0
		call draw_image
		
	.next_frame:
		
		mov word [brick_y], 17
		
	.next_brick:
		mov si, 16
		mov bx, [brick_x]
		dec bx
		mov dx, [brick_y]
		call bitblt

		mov si, 16
		mov bx, [brick_x]
		add bx, 31
		mov dx, [brick_y]
		call bitblt

		mov si, 16
		mov bx, [brick_x]
		add bx, 63
		mov dx, [brick_y]
		call bitblt
		
		mov si, 0
		mov bx, [brick_x]
		mov dx, [brick_y]
		call bitblt
		
		mov si, 0
		mov bx, [brick_x]
		add bx, 32
		mov dx, [brick_y]
		call bitblt

		mov si, 0
		mov bx, [brick_x]
		add bx, 64
		mov dx, [brick_y]
		call bitblt
		
		add word [brick_y], 17
		cmp word [brick_y], 17 * 11
		jb .next_brick


		add word [brick_x], 4
		; inc word [brick_y]
	
		call wait_retrace

	
		mov ah, 1
		int 16h
		jnz .exit
		; cmp al, 27
		; jz .exit
		
		jmp .next_frame
		
	.exit:
		mov ah, 0
		mov al, 3
		int 10h
		
		mov ax, 4c00h
		int 21h
		
; AL = video mode		
set_video_mode:
		mov ah, 0
		int 10h
		ret
		
; reference: http://www.brackeen.com/vga/source/bc31/modes.c.html		
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

; bl  = 1 2 4 8
; plane 0 1 2 3
change_write_plane:
		push bx
		push dx
		push ax
		mov dx, SC_INDEX
		mov al, MAP_MASK
		mov ah, bl			
		out dx, ax ; note: you can pass data to ah register and send out dx, al
		;mov dx, SC_DATA
		;mov al, bl
		;out dx, al
		pop ax
		pop dx
		pop bx
		ret
		
set_virtual_640:
		mov dx, CRTC_INDEX
		mov al, LINE_OFFSET
		out dx, al
		mov dx, CRTC_DATA
		mov al, 640 / 8
		out dx, al
		ret

wait_retrace:
		push dx
		push ax
		mov dx, 3dah
	.l1:
		in al,dx
		test al, 08h
		jz .l1
	.l2:
		in al,dx
		test al, 08h
		jnz .l2
		pop ax
		pop dx
		ret

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
		call change_write_plane
		
		pop bx
		pop cx

		mov ax, dx
		shl ax, 7
		
		shl dx, 5
		add ax, dx
		
		shr bx, 2
		add ax, bx
		
		mov bx, ax
		
		mov [bx], cl
		
		pop ds
		ret
		

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
		mov cl, [si] ; pixel color
		call set_pixel
		
		inc word [img_i]
		
		inc word [img_x]
		mov bx, [di - 4] ; image width
		cmp  [img_x], bx
		jb .next_pixel
		
		mov word [img_x], 0
		inc word [img_y]
		mov dx, [di - 2] ; image height
		cmp [img_y], dx
		jb .next_pixel
		
		ret 

; copy screen to screen - 4 planes at once
; https://www.phatcode.net/res/224/files/html/ch48/48-04.html
; si = source video address
; bx = x
; dx = y
bitblt:
		push ds
		
		; calculate di (linear destination address)
		mov ax, dx
		shl ax, 7
		shl dx, 5
		add ax, dx
		shr bx, 2
		add ax, bx
		mov di, ax
		
		mov dx, SC_INDEX
		mov al, MAP_MASK
		mov ah, 0fh ; select all 4 planes			
		out dx, ax
		
		mov dx, GC_INDEX          ;set the bit mask to select all bits
        mov ax, 00000h + BIT_MASK ; from the latches and none from
        out dx, ax                ; the CPU, so that we can write the
                                  ; latch contents directly to memory
								  ; note: you can also write mov dx, GC_INDEX
								  ;                          mov al, BIT_MASK
								  ;							 out dx, al
								  ; 						 mov dx, GC_DATA
								  ;                          mov al, 0
								  ;							 out dx, al
								  
		mov ax, 0a000h
		mov ds, ax
		
		mov bl, 0 ; line counter
		
		; mov si, 0
		; mov di, 50 * 160 + 40
	.next_line:	
		;mov al, [es:si]
		;mov byte [ds:di], 15
		mov cx, 4
		rep movsb
		
		add si, 160 - 4
		add di, 160 - 4
		inc bl
		cmp bl, 16
		jb .next_line
		
		pop ds
		ret
		
; image file
img_start_x dw 0
img_start_y dw 0
img_x dw 0
img_y dw 0
img_i dw 0

brick_x dw 32
brick_y dw 32

; size: (16, 16)
brick_width dw 16
brick_height dw 16
brick:
	incbin "brick.bmp", 54 + 1024 ; skip header and palette information