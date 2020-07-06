	bits 16
	cpu 8086
	org 100h

		%define KEY_LEFT  'K'
		%define KEY_RIGHT 'M'
		%define KEY_UP    'H'
		%define KEY_DOWN  'P'
		%define KEY_Z     ','
		%define KEY_X     '-'
		%define KEY_ESC    1
	
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
		
		call fill_screen

		mov di, 168 ; di = linenum
		call split_screen

		; draw HUD
		mov si, hud_image ; si = image address
		mov di, 0 ; di = destination 
		call drawImage

		mov si, st1tiles ; si = image address
		mov di, [tiles_location] ; di = destination 
		call drawImage
		
		mov si, sprites ; si = image address
		mov di, [sprites_location] ; di = destination 
		call drawImage

		call bitblt_start

		mov bp, stage_column_index_0 ; dx = stage_column_index address
		mov cx, page_location_0 ; [scroll_x_0]
		mov dx, 80
		call draw_next_stage_column

		mov bp, stage_column_index_1 ; dx = stage_column_index address
		mov cx, page_location_1 ; 82 * 169 ; [scroll_x_1]
		mov dx, 80
		call draw_next_stage_column

		;mov ah, 0
		;int 16h

	.next:
		; --- page 0 ---
	

		; restore previous ship region
		; TODO
		
		; save new position
		; TODO
			
		; draw ship sprites test
		mov bx, page_line_0
		mov si, [scroll_x_0] ; si = location
		call draw_ship_sprites_test_1
		

		add word [scroll_x_0], 1
				
		mov ax, page_line_0 ; bp ; bp y scroll
		mov di, [scroll_x_0] ; bp x scroll
		call move_to

		;call wait_retrace
		;call wait_retrace
		;call wait_retrace
		
		mov ah, 1
		int 16h
		jnz .exit
		;cmp al, 27
		;jz .exit

		test word [scroll_x_0], 7
		jnz .continue_0

		mov bp, stage_column_index_0 ; dx = stage_column_index address
		mov cx, [scroll_x_0]
		shr cx, 1
		shr cx, 1
		mov dx, 80
		add cx, page_location_0 ; 82 * 30
		call draw_next_stage_column

	.continue_0:
		call check_keys
		
	.page_1:


		; --- page 1 ---
		

		add word [scroll_x_1], 1

		; restore previous ship region
		; TODO
		
		; save new position
		; TODO
		
		mov bp, 16 ; bp = height (in pixels)
		mov cx, 6 ; cx = width (4 pixels) / 2 = 8 pixels
		mov di, [ship_background_location] ; di = destination
		call bitblt
		
		; draw ship sprite
		mov bx, page_line_1 ; 169
		mov si, [scroll_x_1]
		call draw_ship_sprites_test_1
		
		
		mov ax, page_line_1 ; 169 ; bp ; bp y scroll
		mov di, [scroll_x_1] ; bp x scroll
		inc di
		call move_to

		;call wait_retrace
		;call wait_retrace
		;call wait_retrace
		
		mov ah, 1
		int 16h
		jnz .exit
		;cmp al, 27
		;jz .exit

		test word [scroll_x_1], 7
		jnz .continue_1

		mov bp, stage_column_index_1 ; dx = stage_column_index address
		mov cx, [scroll_x_1]
		shr cx, 1
		shr cx, 1
		add cx, page_location_1 ; 82 * 169
		mov dx, 80
		call draw_next_stage_column
	
	.continue_1:
		call check_keys
	
		jmp .next

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

		mov word [ship_animation], 0

	.check_up_1:
		mov bl, KEY_UP
		call is_key_pressed
		cmp al, 0
		jz .check_down_1
	.up_pressed_1:
		mov ax, [ship_y]
		mov [ship_previous_y], ax
		sub word [ship_y], 2
		mov word [ship_animation], 16

	.check_down_1:
		mov bl, KEY_DOWN
		call is_key_pressed
		cmp al, 0
		jz .check_left_1
	.down_pressed_1:
		mov ax, [ship_y]
		mov [ship_previous_y], ax
		add word [ship_y], 2
		mov word [ship_animation], 8
	
	.check_left_1:
		mov bl, KEY_LEFT
		call is_key_pressed
		cmp al, 0
		jz .check_right_1
	.left_pressed_1:
		mov ax, [ship_x]
		mov [ship_previous_x], ax
		sub word [ship_x], 2
		
	.check_right_1:
		mov bl, KEY_RIGHT
		call is_key_pressed
		cmp al, 0
		jz .check_key_end_1
	.right_pressed_1:
		mov ax, [ship_x]
		mov [ship_previous_x], ax
		add word [ship_x], 2

	.check_key_end_1:
		ret
		
		
	%include "keyboard.inc"
	%include "graphics.inc"
	%include "sprites.inc"

	%include "st1map.asm"
	
scroll_x_0 dw 0
scroll_x_1 dw 0

; --- page flipping ---
page_line_0 equ (31)
page_location_0 equ 82 * (31)

page_line_1 equ (169 + 31)
page_location_1 equ 82 * (169 + 31)

; --- stage ---
stage_column_index_0 dw stage_1_map_start ; - stage_1_map
stage_column_index_1 dw stage_1_map_start ; - stage_1_map

stage_column_y db 0
stage_column_x dw 0

tiles_location dw 82 * (400 + 31)
; st1tiles_width dw 328 / all images must be 328 width
st1tiles_height dw 40
st1tiles:
		incbin "st1tiles.bmp", 54 + 1024 ; skip header and palette information		

ship_previous_x dw 0
ship_previous_y dw 0
ship_x dw 0
ship_y dw 0
ship_animation dw 0
ship_background_location dw 82 * (600 + 31)

; size: (16, 16)
brick_x dw 0
brick_y dw 0

brick_width dw 28
brick_height dw 24
brick:
		incbin "brick.bmp", 54 + 1024 ; skip header and palette information		

; --- sprites ---
sprites_location dw 82 * (440 + 31)
sprites_height dw 64
sprites:
		incbin "level1b.bmp", 54 + 1024 ; skip header and palette information		
	
; --- HUD ---
hud_location dw 82 * (0)
hud_height dw 30
hud_image:
		incbin "hud.bmp", 54 + 1024 ; skip header and palette information		
