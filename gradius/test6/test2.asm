	bits 16
	cpu 8086
	org 100h
	
start:
		mov al, 13h
		call set_video_mode
		call set_video_mode_y
		call set_virtual_328
		
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
		;mov si, [sprites_location]
		;add si, 6 * 4 ; si = source video address
		
		mov cx, 8 ; cx = width (4 pixels) / 2 = 8 pixels 
		mov bp, 16 ; bp = height (in pixels)
		mov di, [scroll_x_0] ; di = destination
		shr di, 1
		shr di, 1
		add di, 82 * 100 + 41
		call bitblt
		

		add word [scroll_x_0], 1
				
		mov ax, 0 ; bp ; bp y scroll
		mov di, [scroll_x_0] ; bp x scroll
		call move_to

		call wait_retrace
		;call wait_retrace
		;call wait_retrace
		
		mov ah, 1
		int 16h
		jnz .exit
		;cmp al, 27
		;jz .exit

		test word [scroll_x_0], 7
		jnz .page_1

		mov bp, stage_column_index_0 ; dx = stage_column_index address
		mov cx, [scroll_x_0]
		shr cx, 1
		shr cx, 1
		call draw_next_stage_column
		
	.page_1:
		; --- page 1 ---

		add word [scroll_x_1], 1
		
		; draw ship sprite
		mov si, [scroll_x_1]
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
		
		;mov si, [sprites_location]
		;add si, 6 * 4 ; si = source video address
		;add si, 82 * 16
		
		mov cx, 8 ; cx = width (4 pixels) / 2 = 8 pixels 
		mov bp, 16 ; bp = height (in pixels)
		mov di, [scroll_x_1] ; di = destination
		shr di, 1
		shr di, 1
		add di, 82 * (169 + 100) + 41
		call bitblt
		
		mov ax, 169 ; bp ; bp y scroll
		mov di, [scroll_x_1] ; bp x scroll
		inc di
		call move_to

		call wait_retrace
		;call wait_retrace
		;call wait_retrace
		
		mov ah, 1
		int 16h
		jnz .exit
		;cmp al, 27
		;jz .exit

		test word [scroll_x_1], 7
		jnz .next

		mov bp, stage_column_index_1 ; dx = stage_column_index address
		mov cx, [scroll_x_1]
		shr cx, 1
		shr cx, 1
		add cx, 82 * 169
		call draw_next_stage_column
	
		jmp .next

	.exit:
		mov al, 3h
		call set_video_mode

		mov ax, 4c00h
		int 21h

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

	