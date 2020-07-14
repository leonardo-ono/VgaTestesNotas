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

		; draw sprites
		mov si, sprites ; si = image address
		mov di, sprites_location ; di = destination 
		call drawImage

		; draw tiles
		mov si, st1tiles ; si = image address
		mov di, 82 * 0 ; di = destination 
		call drawImage
		mov si, st1tiles ; si = image address
		mov di, 82 * 50 ; di = destination 
		call drawImage
		mov si, st1tiles ; si = image address
		mov di, 82 * 100 ; di = destination 
		call drawImage
		mov si, st1tiles ; si = image address
		mov di, 82 * 150 ; di = destination 
		call drawImage

		; draw tiles
		mov si, st1tiles ; si = image address
		mov di, 82 * 200 ; di = destination 
		call drawImage
		mov si, st1tiles ; si = image address
		mov di, 82 * 250 ; di = destination 
		call drawImage
		mov si, st1tiles ; si = image address
		mov di, 82 * 300 ; di = destination 
		call drawImage
		mov si, st1tiles ; si = image address
		mov di, 82 * 350 ; di = destination 
		call drawImage
		
		call start_sprites_0
		call start_sprites_1

		mov di, 0 ; di = x
		mov ax, 200 ; 200 ; ax = y
		call move_to
		
	.next_frame:
					; plane 0 1 2 3
		mov bl, 1	; bl  = 1 2 4 8
		call change_write_plane
					; plane 0 1 2 3
		mov bl, 2	; bl  = 1 2 4 8
		call change_write_plane
					; plane 0 1 2 3
		mov bl, 4	; bl  = 1 2 4 8
		call change_write_plane
					; plane 0 1 2 3
		mov bl, 8	; bl  = 1 2 4 8
		call change_write_plane
		
		call draw_sprites_0


		mov di, [scroll_x_0] ; di = x
		mov ax, 0 ; ax = y
		call move_to

		;mov di, [scroll_x_0] ; di = x
		;mov ax, 0 ; ax = y
		;call move_to

		inc word [scroll_x_0]

		call check_keys

					; plane 0 1 2 3
		mov bl, 1	; bl  = 1 2 4 8
		call change_write_plane
					; plane 0 1 2 3
		mov bl, 2	; bl  = 1 2 4 8
		call change_write_plane
					; plane 0 1 2 3
		mov bl, 4	; bl  = 1 2 4 8
		call change_write_plane
					; plane 0 1 2 3
		mov bl, 8	; bl  = 1 2 4 8
		call change_write_plane
		
		call draw_sprites_1
		
		
		mov di, [scroll_x_0] ; di = x
		mov ax, 200 ; ax = y
		call move_to

		;mov di, [scroll_x_0] ; di = x
		;mov ax, 200 ; ax = y
		;call move_to
		
		inc word [scroll_x_0]

		call check_keys
		;mov ah, 0
		;int 16h

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

		mov word [ship_animation], 0

	.check_up_1:
		mov bl, KEY_UP
		call is_key_pressed
		cmp al, 0
		jz .check_down_1
	.up_pressed_1:
		mov ax, [spr_0.y]
		mov [ship_previous_y], ax
		sub word [spr_0.y], 2
		mov word [ship_animation], 16

	.check_down_1:
		mov bl, KEY_DOWN
		call is_key_pressed
		cmp al, 0
		jz .check_left_1
	.down_pressed_1:
		mov ax, [spr_0.y]
		mov [ship_previous_y], ax
		add word [spr_0.y], 2
		mov word [ship_animation], 8
	
	.check_left_1:
		mov bl, KEY_LEFT
		call is_key_pressed
		cmp al, 0
		jz .check_right_1
	.left_pressed_1:
		mov ax, [spr_0.x]
		mov [ship_previous_x], ax
		sub word [spr_0.x], 3
		
	.check_right_1:
		mov bl, KEY_RIGHT
		call is_key_pressed
		cmp al, 0
		jz .check_key_end_1
	.right_pressed_1:
		mov ax, [spr_0.x]
		mov [ship_previous_x], ax
		add word [spr_0.x], 2

	.check_key_end_1:

		;add word [spr_0.x], 1

		ret
		
		
	%include "keyboard.inc"
	%include "graphics.inc"
	%include "sprites.inc"
	%include "sprites2.inc"

	%include "st1map.asm"
	
scroll_x_0 dw 0 ; must have only one for both page 0 and page 1
; scroll_x_1 dw 0

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
st1tiles_height dw 50 ; 176
st1tiles:
		; incbin "st1tiles.bmp", 54 + 1024 ; skip header and palette information		
		incbin "bg.bmp", 54 + 1024 ; skip header and palette information		

ship_previous_x dw 0
ship_previous_y dw 0
ship_x dw 160
ship_y dw 100
ship_animation dw 0
ship_background_location dw 82 * (600 + 31)
ship_restore_location dw 0

spr_0:
	.x dw 20 ; 0
	.y dw 104 ; 2
	.backup_location dw 4 ; 4
	.restore_location dw 0 ; 6
	.sprite_location dw (sprites_location + 0) ; 8
	.backup_location_1 dw 82 * 200 + 4 ; 10
	.restore_location_1 dw 0 ; 12

spr_1:
	.x dw 40 ; 0
	.y dw 116 ; 2
	.backup_location dw 8 ; 4
	.restore_location dw 0 ; 6
	.sprite_location dw (sprites_location + 4) ; 8
	.backup_location_1 dw 82 * 200 + 8 ; 10
	.restore_location_1 dw 0 ; 12

spr_2:
	.x dw 60 ; 0
	.y dw 148 ; 2
	.backup_location dw 12 ; 4
	.restore_location dw 0 ; 6
	.sprite_location dw (sprites_location + 8) ; 8
	.backup_location_1 dw 82 * 200 + 12 ; 10
	.restore_location_1 dw 0 ; 12

spr_3:
	.x dw 80 ; 0
	.y dw 98 ; 2
	.backup_location dw 16 ; 4
	.restore_location dw 0 ; 6
	.sprite_location dw (sprites_location + 12) ; 8
	.backup_location_1 dw 82 * 200 + 16 ; 10
	.restore_location_1 dw 0 ; 12

spr_4:
	.x dw 280 ; 0
	.y dw 79 ; 2
	.backup_location dw 20 ; 4
	.restore_location dw 0 ; 6
	.sprite_location dw (sprites_location + 12) ; 8
	.backup_location_1 dw 82 * 200 + 20 ; 10
	.restore_location_1 dw 0 ; 12

spr_5:
	.x dw 100 ; 0
	.y dw 128 ; 2
	.backup_location dw 24 ; 4
	.restore_location dw 0 ; 6
	.sprite_location dw (sprites_location + 12) ; 8
	.backup_location_1 dw 82 * 200 + 24 ; 10
	.restore_location_1 dw 0 ; 12

spr_6:
	.x dw 120 ; 0
	.y dw 47 ; 2
	.backup_location dw 28 ; 4
	.restore_location dw 0 ; 6
	.sprite_location dw (sprites_location + 12) ; 8
	.backup_location_1 dw 82 * 200 + 28 ; 10
	.restore_location_1 dw 0 ; 12

spr_7:
	.x dw 140 ; 0
	.y dw 170 ; 2
	.backup_location dw 32 ; 4
	.restore_location dw 0 ; 6
	.sprite_location dw (sprites_location + 12) ; 8
	.backup_location_1 dw 82 * 200 + 32 ; 10
	.restore_location_1 dw 0 ; 12

spr_8:
	.x dw 160 ; 0
	.y dw 150 ; 2
	.backup_location dw 36 ; 4
	.restore_location dw 0 ; 6
	.sprite_location dw (sprites_location + 12) ; 8
	.backup_location_1 dw 82 * 200 + 36 ; 10
	.restore_location_1 dw 0 ; 12

spr_9:
	.x dw 180 ; 0
	.y dw 120 ; 2
	.backup_location dw 40 ; 4
	.restore_location dw 0 ; 6
	.sprite_location dw (sprites_location + 12) ; 8
	.backup_location_1 dw 82 * 200 + 40 ; 10
	.restore_location_1 dw 0 ; 12

spr_10:
	.x dw 200 ; 0
	.y dw 60 ; 2
	.backup_location dw 44 ; 4
	.restore_location dw 0 ; 6
	.sprite_location dw (sprites_location + 12) ; 8
	.backup_location_1 dw 82 * 200 + 44 ; 10
	.restore_location_1 dw 0 ; 12
	
; size: (16, 16)
brick_x dw 0
brick_y dw 0

brick_width dw 28
brick_height dw 24
brick:
		incbin "brick.bmp", 54 + 1024 ; skip header and palette information		

; --- sprites ---
sprites_location equ 82 * (600)
sprites_height dw 64
sprites:
		incbin "level1b.bmp", 54 + 1024 ; skip header and palette information		
	
; --- HUD ---
hud_location dw 82 * (0)
hud_height dw 30
hud_image:
		incbin "hud.bmp", 54 + 1024 ; skip header and palette information		
