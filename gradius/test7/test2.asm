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

		mov si, st1tiles ; si = image address
		mov di, [tiles_location] ; di = destination 
		call drawImage
		
		mov si, sprites ; si = image address
		mov di, [sprites_location] ; di = destination 
		call drawImage

		call bitblt_start

		mov bp, stage_column_index_0 ; dx = stage_column_index address
		mov cx, [scroll_x_0]
		call draw_next_stage_column

		mov bp, stage_column_index_1 ; dx = stage_column_index address
		mov cx, 82 * 169 ; [scroll_x_1]
		call draw_next_stage_column

		;mov ah, 0
		;int 16h

	.next:
		; --- page 0 ---
	
		; draw ship sprite
		
		mov si, [scroll_x_0]
		add si, [ship_x]
		and si, 3
		shl si, 1
		shl si, 1
		shl si, 1
		shl si, 1
		mov ax, 82
		mul si
		mov si, ax
		add si, [sprites_location]
		add si, 6 * 4
		add si, word [ship_animation]
		;mov si, [sprites_location]
		;add si, 6 * 4 ; si = source video address
		
		mov cx, 8 ; cx = width (4 pixels) / 2 = 8 pixels 
		mov bp, 16 ; bp = height (in pixels)
		mov di, [scroll_x_0] ; di = destination
		add di, [ship_x]
		shr di, 1
		shr di, 1

		; add di, 82 * (0 + 100) + 41
		
		mov ax, 0
		add ax, [ship_y]
		mov bl, 82
		mul bl
		add di, ax
		
		call bitblt
		
		push di
		add di, 82 * 16
		call bitblt
		add di, 82 * 16
		call bitblt
		add di, 82 * 16
		call bitblt
		add di, 82 * 16
		call bitblt
		add di, 82 * 16
		call bitblt
		
		pop di
		push di
		add di, 82 * 16 + 8
		call bitblt
		add di, 82 * 16
		call bitblt
		add di, 82 * 16
		call bitblt
		add di, 82 * 16
		call bitblt
		add di, 82 * 16
		call bitblt

		pop di
		;push di
		add di, 82 * 16 + 16
		call bitblt
		add di, 82 * 16
		call bitblt
		add di, 82 * 16
		call bitblt
		add di, 82 * 16
		call bitblt
		add di, 82 * 16
		call bitblt

		;pop di
		;push di
		;add di, 82 * 16 + 24
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		
		;pop di
		;push di
		;add di, 82 * 16 + 32
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		;add di, 82 * 16
		;call bitblt

		;pop di
		;add di, 82 * 16 + 40
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		;add di, 82 * 16
		;call bitblt

		add word [scroll_x_0], 1
				
		mov ax, 0 ; bp ; bp y scroll
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
		jnz .check_keys_0

		mov bp, stage_column_index_0 ; dx = stage_column_index address
		mov cx, [scroll_x_0]
		shr cx, 1
		shr cx, 1
		call draw_next_stage_column

					.check_keys_0:

						mov bl, KEY_ESC
						call is_key_pressed
						cmp al, 0
						ja .exit
						
						mov word [ship_animation], 0
						
					.check_up_0:
						mov bl, KEY_UP
						call is_key_pressed
						cmp al, 0
						jz .check_down_0
					.up_pressed_0:
						sub word [ship_y], 2
						mov word [ship_animation], 16
						
					.check_down_0:
						mov bl, KEY_DOWN
						call is_key_pressed
						cmp al, 0
						jz .check_left_0
					.down_pressed_0:
						add word [ship_y], 2
						mov word [ship_animation], 8
					
					.check_left_0:
						mov bl, KEY_LEFT
						call is_key_pressed
						cmp al, 0
						jz .check_right_0
					.left_pressed_0:
						sub word [ship_x], 2
						
					.check_right_0:
						mov bl, KEY_RIGHT
						call is_key_pressed
						cmp al, 0
						jz .check_key_end_0
					.right_pressed_0:
						add word [ship_x], 2

					.check_key_end_0:
		
	.page_1:


		; --- page 1 ---
		

		add word [scroll_x_1], 1
		
		; draw ship sprite
		mov si, [scroll_x_1]
		add si, [ship_x]
		and si, 3
		shl si, 1
		shl si, 1
		shl si, 1
		shl si, 1
		mov ax, 82
		mul si
		mov si, ax
		add si, [sprites_location]
		add si, 6 * 4
		add si, word [ship_animation]
		
		;mov si, [sprites_location]
		;add si, 6 * 4 ; si = source video address
		;add si, 82 * 16
		
		mov cx, 8 ; cx = width (4 pixels) / 2 = 8 pixels 
		mov bp, 16 ; bp = height (in pixels)
		mov di, [scroll_x_1] ; di = destination
		add di, [ship_x]
		shr di, 1
		shr di, 1

		; add di, 82 * (169 + 100) + 41

		mov ax, 169
		add ax, [ship_y]
		mov bl, 82
		mul bl
		add di, ax
		
		call bitblt
		
		push di
		add di, 82 * 16
		call bitblt
		add di, 82 * 16
		call bitblt
		add di, 82 * 16
		call bitblt
		add di, 82 * 16
		call bitblt
		add di, 82 * 16
		call bitblt
		
		pop di
		push di
		add di, 82 * 16 + 8
		call bitblt
		add di, 82 * 16
		call bitblt
		add di, 82 * 16
		call bitblt
		add di, 82 * 16
		call bitblt
		add di, 82 * 16
		call bitblt

		pop di
		;push di
		add di, 82 * 16 + 16
		call bitblt
		add di, 82 * 16
		call bitblt
		add di, 82 * 16
		call bitblt
		add di, 82 * 16
		call bitblt
		add di, 82 * 16
		call bitblt

		;pop di
		;push di
		;add di, 82 * 16 + 24
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		
		;pop di
		;push di
		;add di, 82 * 16 + 32
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		;add di, 82 * 16
		;call bitblt

		;pop di
		;add di, 82 * 16 + 40
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		;add di, 82 * 16
		;call bitblt
		
		
		mov ax, 169 ; bp ; bp y scroll
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
		jnz .check_keys_1

		mov bp, stage_column_index_1 ; dx = stage_column_index address
		mov cx, [scroll_x_1]
		shr cx, 1
		shr cx, 1
		add cx, 82 * 169
		call draw_next_stage_column
	
		jmp .check_keys_1

						.check_keys_1:

							mov bl, KEY_ESC
							call is_key_pressed
							cmp al, 0
							ja .exit

							mov word [ship_animation], 0

						.check_up_1:
							mov bl, KEY_UP
							call is_key_pressed
							cmp al, 0
							jz .check_down_1
						.up_pressed_1:
							sub word [ship_y], 2
							mov word [ship_animation], 16

						.check_down_1:
							mov bl, KEY_DOWN
							call is_key_pressed
							cmp al, 0
							jz .check_left_1
						.down_pressed_1:
							add word [ship_y], 2
							mov word [ship_animation], 8
						
						.check_left_1:
							mov bl, KEY_LEFT
							call is_key_pressed
							cmp al, 0
							jz .check_right_1
						.left_pressed_1:
							sub word [ship_x], 2
							
						.check_right_1:
							mov bl, KEY_RIGHT
							call is_key_pressed
							cmp al, 0
							jz .check_key_end_1
						.right_pressed_1:
							add word [ship_x], 2

						.check_key_end_1:
	
		jmp .next

	.exit:
		call uninstall_key_handler
		
		mov al, 3h
		call set_video_mode

		mov ax, 4c00h
		int 21h

	%include "keyboard.inc"
	%include "graphics.inc"

	%include "st1map.asm"
	
scroll_x_0 dw 0
scroll_x_1 dw 0



; --- stage ---
stage_column_index_0 dw stage_1_map_start ; - stage_1_map
stage_column_index_1 dw stage_1_map_start ; - stage_1_map

stage_column_y db 0
stage_column_x dw 0

tiles_location dw 82 * 400
; st1tiles_width dw 328 / all images must be 328 width
st1tiles_height dw 40
st1tiles:
		incbin "st1tiles.bmp", 54 + 1024 ; skip header and palette information		

ship_x dw 0
ship_y dw 0
ship_animation dw 0

; size: (16, 16)
brick_x dw 0
brick_y dw 0

brick_width dw 28
brick_height dw 24
brick:
		incbin "brick.bmp", 54 + 1024 ; skip header and palette information		

; --- sprites ---
sprites_location dw 82 * 440
sprites_height dw 64
sprites:
		incbin "level1b.bmp", 54 + 1024 ; skip header and palette information		
	