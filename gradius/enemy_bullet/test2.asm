; cannon pointing to ship 16x16 lookup table

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
	
		; update bullet position
		cmp byte [bullet_active], 0
		jz .end_current_frame
		
		mov al, [bullet_vx]
		cbw ; ax = signed 16 bits
		add [bullet_x], ax

		mov al, [bullet_vy]
		cbw ; ax = signed 16 bits
		add [bullet_y], ax
		
		; deactive bullet if y < 0
		cmp word [bullet_y], 0
		jg .bullet_keep_active
		
	.bullet_deactive:
		mov byte [bullet_active], 0
	
	.bullet_keep_active:
	
	.draw_bullet:	
	
		; draw enemy bullet
		mov bx, [bullet_x] ; bx = x
		mov cl, 6
		sar bx, cl
		
		; select correct bullet frame according to position (x % 4)
		mov ax, bx
		and ax, 3
		mov cl, 2
		shl ax, cl
		mov si, 82 * 180 + 4 * 8 ; si = source video address
		add si, ax 
		
		mov dx, [bullet_y] ; dx = y
		mov cl, 6
		sar dx, cl
		call bitblt
	
		;mov ah, 0
		;int 16h
	
	.end_current_frame:
	
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
		jz .check_z
	.right_pressed:
		add word [ship_x], 1

	.check_z:
		mov bl, KEY_Z
		call is_key_pressed
		cmp al, 0
		jz .check_key_end
	.z_pressed:
		call get_bullet_direction_vector ; al=dx / ah=dy
		mov [bullet_vx], al
		mov [bullet_vy], ah
		mov word [bullet_x], 127 << 6
		mov word [bullet_y], 153 << 6
		mov byte [bullet_active], 1

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
		mov ax, 32 * 16
		sub ax, [cannon_x]
		add ax, [ship_x]
		mov cl, 4
		shr ax, cl
		
		; table row
		mov bx, 12 * 16
		sub bx, [cannon_y]
		add bx, [ship_y]
		and bx, 0fff0h
		mov cl, 2 ; shr bx, 4 -> shl bx, 6 = shl bx, 2
		shl bx, cl
		
		; location = 64 * .table_row + .table_col
		add bx, ax
		add bx, cannon_animation_table
		
		mov al, [bx] ; al = animation index
		ret
	

; bullet direction vector
; al = dx
; ah = dy
get_bullet_direction_vector:
		; bulletDirectionVector[24 - (cannonRow - shipRow)][64 - (cannonCol - shipCol)];
		
		; table col
		mov ax, 32 * 16
		sub ax, [cannon_x]
		add ax, [ship_x]
		add ax, 12 ; center ship x
		mov cl, 4
		shr ax, cl
		
		; table row
		mov bx, 12 * 16
		sub bx, [cannon_y]
		add bx, [ship_y]
		add bx, 8 ; center ship y
		and bx, 0fff0h
		mov cl, 2 ; shr bx, 4 -> shl bx, 6 = shl bx, 2
		shl bx, cl
		
		; location = 64 * .table_row + .table_col
		add bx, ax
		
		push bx
		
		add bx, enemy_bullet_directions_dx
		mov al, [bx] ; al = dx
		
		pop bx

		add bx, enemy_bullet_directions_dy
		mov ah, [bx] ; ah = dy
		
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

bullet_active db 0
bullet_vx db 219
bullet_vy db 204
bullet_x dw 127 << 6
bullet_y dw 153 << 6

		
; image file
img_start_x dw 0
img_start_y dw 0
img_x dw 0
img_y dw 0
img_i dw 0

sprites_width dw 192
sprites_height dw 16
sprites:
		incbin "sprites.bmp", 54 + 1024 ; skip header and palette information		

terrain_width dw 328
terrain_height dw 57
terrain:
		incbin "terrain.bmp", 54 + 1024 ; skip header and palette information		


cannon_animation_table:
   db 0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,2,2,2,3,3,3,3,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,2,2,3,3,3,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,2,2,3,3,3,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,2,3,3,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,2,3,3,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,3,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5

enemy_bullet_directions_dx:
   db 197,197,197,197,198,198,198,199,199,200,200,201,202,202,203,204,205,207,208,209,211,213,216,218,221,224,228,232,236,241,246,251,0,5,10,15,20,24,28,32,35,38,40,43,45,47,48,49,51,52,53,54,54,55,56,56,57,57,58,58,58,59,59,59
   db 196,196,196,197,197,197,198,198,198,199,199,200,200,201,202,203,204,205,206,208,209,211,213,216,219,222,226,230,235,240,245,251,0,5,11,16,21,26,30,34,37,40,43,45,47,48,50,51,52,53,54,55,56,56,57,57,58,58,58,59,59,59,60,60
   db 195,196,196,196,196,196,197,197,197,198,198,199,199,200,201,201,202,203,204,206,207,209,211,214,217,220,224,228,233,238,244,250,0,6,12,18,23,28,32,36,39,42,45,47,49,50,52,53,54,55,55,56,57,57,58,58,59,59,59,60,60,60,60,60
   db 195,195,195,195,196,196,196,196,197,197,197,198,198,199,199,200,201,202,203,204,205,207,209,211,214,217,221,225,231,236,243,249,0,7,13,20,25,31,35,39,42,45,47,49,51,52,53,54,55,56,57,57,58,58,59,59,59,60,60,60,60,61,61,61
   db 194,195,195,195,195,195,195,196,196,196,196,197,197,198,198,199,199,200,201,202,203,205,207,209,211,214,218,223,228,234,241,249,0,7,15,22,28,33,38,42,45,47,49,51,53,54,55,56,57,57,58,58,59,59,60,60,60,60,61,61,61,61,61,61
   db 194,194,194,194,194,195,195,195,195,195,196,196,196,196,197,197,198,199,199,200,201,203,204,206,208,211,215,219,225,231,239,247,0,9,17,25,31,37,41,45,48,50,52,53,55,56,57,57,58,59,59,60,60,60,60,61,61,61,61,61,62,62,62,62
   db 194,194,194,194,194,194,194,194,194,195,195,195,195,195,196,196,197,197,198,198,199,200,202,203,205,208,211,216,221,228,236,246,0,10,20,28,35,40,45,48,51,53,54,56,57,58,58,59,59,60,60,61,61,61,61,61,62,62,62,62,62,62,62,62
   db 193,193,193,193,193,194,194,194,194,194,194,194,194,195,195,195,195,196,196,197,197,198,199,201,202,204,207,211,217,224,233,244,0,12,23,32,39,45,49,52,54,55,57,58,59,59,60,60,61,61,61,61,62,62,62,62,62,62,62,62,63,63,63,63
   db 193,193,193,193,193,193,193,193,193,193,194,194,194,194,194,194,194,195,195,195,196,196,197,198,199,201,203,207,211,218,228,241,0,15,28,38,45,49,53,55,57,58,59,60,60,61,61,61,62,62,62,62,62,62,62,63,63,63,63,63,63,63,63,63
   db 193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,194,194,194,194,194,195,195,196,197,198,199,202,205,211,221,236,0,20,35,45,51,54,57,58,59,60,61,61,62,62,62,62,62,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63
   db 193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,194,194,194,194,195,196,197,199,203,211,228,0,28,45,53,57,59,60,61,62,62,62,62,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63
   db 193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,194,194,196,199,211,0,45,57,60,62,62,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63
   db 193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,193,0,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63

enemy_bullet_directions_dy:
   db 234,233,233,232,231,231,230,229,228,227,226,225,224,222,221,220,218,217,215,213,211,209,207,205,203,201,199,197,196,194,193,193,192,193,193,194,196,197,199,201,203,205,207,209,211,213,215,217,218,220,221,222,224,225,226,227,228,229,230,231,231,232,233,233
   db 236,235,234,234,233,232,232,231,230,229,228,227,226,224,223,222,220,219,217,215,213,211,209,207,205,203,200,198,196,195,194,193,192,193,194,195,196,198,200,203,205,207,209,211,213,215,217,219,220,222,223,224,226,227,228,229,230,231,232,232,233,234,234,235
   db 237,237,236,236,235,234,234,233,232,231,230,229,228,227,225,224,223,221,219,217,216,213,211,209,207,204,202,199,197,195,194,193,192,193,194,195,197,199,202,204,207,209,211,213,216,217,219,221,223,224,225,227,228,229,230,231,232,233,234,234,235,236,236,237
   db 239,239,238,238,237,236,236,235,234,233,232,231,230,229,228,227,225,224,222,220,218,216,214,211,209,206,203,201,198,196,194,193,192,193,194,196,198,201,203,206,209,211,214,216,218,220,222,224,225,227,228,229,230,231,232,233,234,235,236,236,237,238,238,239
   db 241,241,240,239,239,238,238,237,236,235,235,234,233,232,231,229,228,226,225,223,221,219,217,214,211,208,205,202,199,197,194,193,192,193,194,197,199,202,205,208,211,214,217,219,221,223,225,226,228,229,231,232,233,234,235,235,236,237,238,238,239,239,240,241
   db 243,242,242,241,241,240,240,239,239,238,237,236,235,234,233,232,231,229,228,226,224,222,220,217,214,211,208,204,201,198,195,193,192,193,195,198,201,204,208,211,214,217,220,222,224,226,228,229,231,232,233,234,235,236,237,238,239,239,240,240,241,241,242,242
   db 245,244,244,244,243,243,242,242,241,240,240,239,238,237,236,235,234,233,231,230,228,226,224,221,218,215,211,207,203,199,196,193,192,193,196,199,203,207,211,215,218,221,224,226,228,230,231,233,234,235,236,237,238,239,240,240,241,242,242,243,243,244,244,244
   db 247,246,246,246,245,245,244,244,243,243,242,242,241,240,239,238,237,236,235,234,232,230,228,225,223,219,216,211,207,202,197,194,192,194,197,202,207,211,216,219,223,225,228,230,232,234,235,236,237,238,239,240,241,242,242,243,243,244,244,245,245,246,246,246
   db 249,248,248,248,247,247,247,246,246,246,245,245,244,243,243,242,241,240,239,238,236,235,233,231,228,225,221,217,211,205,199,194,192,194,199,205,211,217,221,225,228,231,233,235,236,238,239,240,241,242,243,243,244,245,245,246,246,246,247,247,247,248,248,248
   db 251,250,250,250,250,249,249,249,249,248,248,247,247,247,246,245,245,244,243,242,241,240,238,236,234,231,228,224,218,211,203,196,192,196,203,211,218,224,228,231,234,236,238,240,241,242,243,244,245,245,246,247,247,247,248,248,249,249,249,249,250,250,250,250
   db 253,252,252,252,252,252,252,251,251,251,251,250,250,250,249,249,249,248,247,247,246,245,244,243,241,239,236,233,228,221,211,199,192,199,211,221,228,233,236,239,241,243,244,245,246,247,247,248,249,249,249,250,250,250,251,251,251,251,252,252,252,252,252,252
   db 254,254,254,254,254,254,254,254,254,254,254,253,253,253,253,253,253,252,252,252,251,251,250,249,249,247,246,244,241,236,228,211,192,211,228,236,241,244,246,247,249,249,250,251,251,252,252,252,253,253,253,253,253,253,254,254,254,254,254,254,254,254,254,254
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,192,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
