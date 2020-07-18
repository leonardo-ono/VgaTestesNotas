
		%define MISC_OUTPUT  03c2h
		%define GC_INDEX     03ceh
		%define GC_DATA      03cfh
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

		%define MAP_MASK       02h ;index in SC of Map Mask register
		%define BIT_MASK       08h ;index in GC of Bit Mask register
		
		%define CRTC_LINECOMPARE 24		
		%define CRTC_OVERFLOW     7
		%define CRTC_MAXSCANLINE  9
		
		%define AC_INDEX	    03c0h ; Attribute controller index register
		%define AC_MODE_CONTROL	  10h ; Index of Mode COntrol register in AC
		
		; http://www.scs.stanford.edu/17wi-cs140/pintos/specs/freevga/vga/graphreg.htm		
		%define READ_MAP_SELECT 04h ;index in GC
		
		%define KEY_LEFT  'K'
		%define KEY_RIGHT 'M'
		%define KEY_UP    'H'
		%define KEY_DOWN  'P'
		%define KEY_Z     ','
		%define KEY_X     '-'
		%define KEY_ESC    1

		
		bits 16
		cpu 8086
		org 100h
		
start:
		mov al, 13h
		call set_video_mode
		call set_video_mode_y
		call set_virtual_328
		call install_key_handler

		; clear flag direction
		cld
		
		; destination VRAM
		mov ax, 0a000h
		mov es, ax
		
		mov si, sprites ; si = image address
		mov bx, 0 ; bx = start x		
		mov dx, 180 ; dx = start y		
		call draw_image	
		
		mov si, terrain ; si = image address
		mov bx, 0 ; bx = start x		
		mov dx, 121 ; dx = start y		
		call draw_image	
	
	.next_frame:
		call wait_retrace

		; draw ship
		mov si, 82 * 180 + 4 * 6 ; si = source video address
		mov bx, [ship_x] ; bx = x
		mov dx, [ship_y] ; dx = y
		call bitblt
		mov si, 82 * 180 + 4 * 7 ; si = source video address
		mov bx, [ship_x] ; bx = x
		add bx, 16
		mov dx, [ship_y] ; dx = y
		call bitblt

		; draw cannon
		;call get_cannon_animation_index
		call get_cannon_animation_index_2
		mov ah, 0
		;mov ax, 2 ; animation index
		shl ax, 1
		shl ax, 1
		mov si, 82 * 180 ; si = source video address
		add si, ax
		mov bx, [cannon_x] ; bx = x
		mov dx, [cannon_y] ; dx = y
		call bitblt
	
		;mov ah, 0
		;int 16h
		
		call check_keys
		
		jmp .next_frame
		
	.exit:
		call uninstall_key_handler

		mov al, 3h
		call set_video_mode

		mov ax, 4c00h
		int 21h		

check_keys:		
		mov bl, KEY_ESC
		call is_key_pressed
		cmp al, 0
		ja start.exit

	.check_up:
		mov bl, KEY_UP
		call is_key_pressed
		cmp al, 0
		jz .check_down
	.up_pressed:
		sub word [ship_y], 1

	.check_down:
		mov bl, KEY_DOWN
		call is_key_pressed
		cmp al, 0
		jz .check_left
	.down_pressed:
		add word [ship_y], 1
	
	.check_left:
		mov bl, KEY_LEFT
		call is_key_pressed
		cmp al, 0
		jz .check_right
	.left_pressed:
		sub word [ship_x], 1
		
	.check_right:
		mov bl, KEY_RIGHT
		call is_key_pressed
		cmp al, 0
		jz .check_key_end
	.right_pressed:
		add word [ship_x], 1

	.check_key_end:
		ret
		
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
		ret

; bl  = 0 1 2 3 (plane)
change_read_plane:
		push bx
		push dx
		push ax
		mov dx, GC_INDEX
		mov al, READ_MAP_SELECT
		out dx, al
		mov dx, GC_DATA
		mov al, bl
        out dx, ax 
		pop ax
		pop dx
		pop bx
		ret

		
; root42 - https://github.com/root42/letscode-breakout/blob/master/vga.c		
; http://www.petesqbsite.com/sections/tutorials/tutorials/3scroll.htm
; this register holds the number of bytes (not pixels) difference between the start address of each row
set_virtual_328:
		mov dx, CRTC_INDEX
		mov al, LINE_OFFSET
		out dx, al
		mov dx, CRTC_DATA
		mov al, 328 / 8
		out dx, al
		ret


; bx = x
; dx = y
; cl = color
set_pixel:
		push ds
		mov ax, 0a000h
		mov ds, ax
		
		push dx
		push ax
		mov dx, GC_INDEX          ;set the bit mask to select all bits
        mov ax, 0ff00h + BIT_MASK ; from the latches and none from
        out dx, ax                ; the CPU, so that we can write the
		pop ax
		pop dx
		
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
		
		push cx
		
		mov cl, 6
		shl ax, cl ; 64
		
		add ax, dx ; 1
		add ax, dx ; 1
		
		mov cl, 4
		shl dx, cl
		add ax, dx ; 16
		
		mov cl, 2
		shr bx, cl
		add ax, bx
		
		pop cx
		
		mov bx, ax
		
		mov [bx], cl
		
		pop ds
		ret

; bx = x
; dx = y
; cl = color			
get_pixel:
		push ds
		mov ax, 0a000h
		mov ds, ax

		push cx
		push bx
		
		mov cl, bl
		and cl, 3
		;mov ch, 1
		;shl ch, cl ; ch plane 
		
		mov bl, cl
		call change_read_plane
		
		pop bx
		pop cx


		mov ax, dx
		
		push cx
		
		mov cl, 6
		shl ax, cl ; 64
		
		add ax, dx ; 1
		add ax, dx ; 1
		
		mov cl, 4
		shl dx, cl
		add ax, dx ; 16
		
		mov cl, 2
		shr bx, cl
		add ax, bx
		
		pop cx
		
		mov bx, ax
		
		mov cl, [bx]

		pop ds
		ret
		
; bx = x
; dx = y
; cl = color			
get_pixel_2:
		push ds
		mov ax, 0a000h
		mov ds, ax

		push cx
		push bx
		
		mov cl, bl
		and cl, 3
		;mov ch, 1
		;shl ch, cl ; ch plane 
		
		; mov bl, cl
		mov bl, 2 ; <- fixed to get always plane 0 for this test
		call change_read_plane
		
		pop bx
		pop cx


		mov ax, dx
		
		push cx
		
		mov cl, 6
		shl ax, cl ; 64
		
		add ax, dx ; 1
		add ax, dx ; 1
		
		mov cl, 4
		shl dx, cl
		add ax, dx ; 16
		
		mov cl, 2
		shr bx, cl
		add ax, bx
		
		pop cx
		
		mov bx, ax
		
		mov cl, [bx]

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
		push ax
		push bx
		push cx
		push dx
		push di
		push si
		push ds
		
		; calculate di (linear destination address)
		mov ax, dx
		mov cl, 6
		shl ax, cl
		
		add ax, dx
		add ax, dx
		
		mov cl, 4
		shl dx, cl
		add ax, dx
		
		mov cl, 2
		shr bx, cl
		
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
		
		add si, 82 - 4
		add di, 82 - 4
		inc bl
		cmp bl, 16
		jb .next_line
		
		pop ds
		pop si
		pop di
		pop dx
		pop cx
		pop bx
		pop ax
		ret


; copy screen to screen - 4 planes at once
; https://www.phatcode.net/res/224/files/html/ch48/48-04.html
; si = source video address
; bp = height (in pixels)
; cx = width (4 pixels) / 2 = 8 pixels
; di = destination
bitblt2:
		push ax
		push bx
		push cx
		push dx
		push di
		push si
		push ds
		
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
		
		
		mov bx, 0 ; line counter
		
	.next_line:	
		push cx ; cx = width (4 pixels)
		;mov cx, 2
		
		rep movsb
		pop cx
		
		add si, 82
		sub si, cx
		add di, 82
		sub di, cx
		
		inc bx
		
		;cmp bl, 8
		cmp bx, bp
		
		jb .next_line
		
		pop ds
		pop si
		pop di
		pop dx
		pop cx
		pop bx
		pop ax
		ret

; al = cannon animation index
get_cannon_animation_index:
		; cannonAnimationIndex[24 - (cannonRow - mouseRow)][64 - (cannonCol - mouseCol)];
		
		mov ax, [ship_x]
		mov cl, 3
		shr ax, cl
		mov [.ship_col], ax

		mov ax, [ship_y]
		mov cl, 3
		shr ax, cl
		mov [.ship_row], ax

		mov ax, [cannon_x]
		mov cl, 3
		shr ax, cl
		mov [.cannon_col], ax

		mov ax, [cannon_y]
		mov cl, 3
		shr ax, cl
		mov [.cannon_row], ax
		
		; table col
		mov ax, 64
		sub ax, [.cannon_col]
		add ax, [.ship_col]
		mov [.table_col], ax
		
		; table row
		mov ax, 24
		sub ax, [.cannon_row]
		add ax, [.ship_row]
		mov [.table_row], ax
		
		; location = 128 * .table_row + .table_col
		mov bx, [.table_row]
		mov cl, 7
		shl bx, cl
		add bx, [.table_col]
		add bx, cannon_animation_table
		
		mov al, [bx] ; al = animation index
		
		ret
		
	.cannon_row dw 0
	.cannon_col dw 0
	.ship_row dw 0
	.ship_col dw 0
	.table_row dw 0
	.table_col dw 0


; al = cannon animation index
get_cannon_animation_index_2:
		; cannonAnimationIndex[24 - (cannonRow - shipRow)][64 - (cannonCol - shipCol)];
		
		; table col
		mov ax, 64 * 8
		sub ax, [cannon_x]
		add ax, [ship_x]
		mov cl, 3
		shr ax, cl
		
		; table row
		mov bx, 24 * 8
		sub bx, [cannon_y]
		add bx, [ship_y]
		and bx, 0fff8h
		mov cl, 4 ; shr bx, 3 -> shl bx, 7 = shl bx, 4
		shl bx, cl
		
		; location = 128 * .table_row + .table_col
		add bx, ax
		add bx, cannon_animation_table
		
		mov al, [bx] ; al = animation index
		ret
	
	
; --- keyboard ---


	install_key_handler:
			cli
			push es
			mov ax, 0
			mov es, ax
			mov ax, [es:4 * 9 + 2]
			mov [ds:int9_original_segment], ax
			mov ax, [es:4 * 9]
			mov [ds:int9_original_offset], ax
			mov ax, cs
			mov word [es:4 * 9 + 2], ax
			mov word [es:4 * 9], key_handler
			pop es
			sti
			ret

	uninstall_key_handler:
			push es
			mov ax, 0
			mov es, ax
			cli
			mov ax, [int9_original_offset]
			mov [es:4 * 9], ax
			mov ax, [int9_original_segment]
			mov [es:4 * 9 + 2], ax
			sti
			pop es
			ret

	; bl = code
	; al = 1 = true / 0 = false
	is_key_pressed:
			mov bh, 0
			mov al, [key_pressed + bx]
			mov ah, 0
			ret
			
	key_handler:
			push es
			push ax
			push bx
			
			mov ax, cs
			mov es, ax
			
			in al, 60h
			mov bh, al
			
			in    al, 061h       
			mov   bl, al
			or    al, 080h
			out   061h, al     
			mov   al, bl
			out   061h, al 
			
			mov al, bh
			cmp al, 0e0h
			jz .ignore
			mov ah, 0
			mov bx, ax
			and bl, 01111111b
			and al, 10000000b
			;cmp al, 10000000b
			jnz .key_released
		.key_pressed:
			mov byte [es:key_pressed + bx], 1
			jmp .ignore
		.key_released:
			mov byte [es:key_pressed + bx], 0
		.ignore:
			mov al, 20h
			out 20h, al
			pop bx
			pop ax
			pop es		
			iret                          

	
	
; --- data ---

int9_original_offset	dw 0
int9_original_segment	dw 0

key_pressed		times 256 db 0
	
ship_x dw 160
ship_y dw 50

cannon_x dw 127
cannon_y dw 153
		
; image file
img_start_x dw 0
img_start_y dw 0
img_x dw 0
img_y dw 0
img_i dw 0

sprites_width dw 128
sprites_height dw 16
sprites:
		incbin "sprites.bmp", 54 + 1024 ; skip header and palette information		

terrain_width dw 328
terrain_height dw 57
terrain:
		incbin "terrain.bmp", 54 + 1024 ; skip header and palette information		


cannon_animation_table:
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,2,2,2,3,3,3,3,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,2,2,3,3,3,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,2,2,3,3,3,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,2,3,3,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,2,3,3,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,3,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
