

save_sprite:
		; si = source video address
		; bp = height (in pixels)
		; cx = width (4 pixels) / 2 = 8 pixels
		; di = destination
		mov ax, 82
		mov bx, [ship_y]
		mul bx
		mov bx, [ship_x]
		shr bx, 1
		shr bx, 1
		add ax, bx
		;mov si, 82 * 100 + 2
		mov si, ax
		mov [ship_restore_location], si
		mov bp, 16
		mov cx, 4
		mov di, 0
		call bitblt
		ret
		
restore_sprite:
		; restore previous background
		mov si, 0 ; si = source video address
		mov bp, 16 ; bp = height (in pixels)
		mov cx, 4 ; cx = width (4 pixels) / 2 = 8 pixels
		mov di, [ship_restore_location] ; di = destination
		call bitblt
		ret
		
draw_sprite:
		mov si, sprites_location ; si = source video address
		mov bp, 16 ; bp = height (in pixels)
		mov cx, 4 ; cx = width (4 pixels) / 2 = 8 pixels
		mov di, [ship_restore_location] ; di = destination
		call bitblt
		ret
		
; -------------------
; page 0

; dx = sprite pointer
save_sprite_2:
		mov si, dx

		;and dx, 3
		add word [si], 3 ;.x + 4

		mov ax, 82
		mov bx, [si + 2] ; .y
		mul bx
		mov bx, [si] ; .x
		shr bx, 1
		shr bx, 1
		add ax, bx
		mov [si + 6], ax ; .restore_location
		mov bp, 16 ; bp = height (in pixels)
		mov cx, 4 ; cx = width (4 pixels) / 2 = 8 pixels
		mov di, [si + 4] ; di = destination / .backup_location
		mov si, ax
		call bitblt
		ret

; dx = sprite pointer
restore_sprite_2:
		mov si, dx
		; restore previous background
		mov bp, 16 ; bp = height (in pixels)
		mov cx, 4 ; cx = width (4 pixels) / 2 = 8 pixels
		mov di, [si + 6] ; di = destination / .restore_location
		mov si, [si + 4] ; si = source video address / .backup_location
		call bitblt
		ret
		
; dx = sprite pointer
draw_sprite_2:
		mov si, dx
		mov bp, 16 ; bp = height (in pixels)
		mov cx, 4 ; cx = width (4 pixels) / 2 = 8 pixels
		mov di, [si + 6] ; di = destination / .restore_location
		mov si, [si + 8] ; si = source video address / .sprite_location
		call bitblt
		ret		
		

; -------------------
; page 1

; dx = sprite pointer
save_sprite_3:
		mov si, dx

		; and dx, 3
		add word [si], 3 ;.x + 4

		mov ax, 82
		mov bx, [si + 2] ; .y
		mul bx
		mov bx, [si] ; .x
		shr bx, 1
		shr bx, 1
		add ax, bx
		add ax, 82 * 200 ; page 1
		mov [si + 12], ax ; .restore_location
		mov bp, 16 ; bp = height (in pixels)
		mov cx, 4 ; cx = width (4 pixels) / 2 = 8 pixels
		mov di, [si + 10] ; di = destination / .backup_location
		mov si, ax
		call bitblt
		ret

; dx = sprite pointer
restore_sprite_3:
		mov si, dx
		; restore previous background
		mov bp, 16 ; bp = height (in pixels)
		mov cx, 4 ; cx = width (4 pixels) / 2 = 8 pixels
		mov di, [si + 12] ; di = destination / .restore_location
		mov si, [si + 10] ; si = source video address / .backup_location
		call bitblt
		ret
		
; dx = sprite pointer
draw_sprite_3:
		mov si, dx
		mov bp, 16 ; bp = height (in pixels)
		mov cx, 4 ; cx = width (4 pixels) / 2 = 8 pixels
		mov di, [si + 12] ; di = destination / .restore_location
		mov si, [si + 8] ; si = source video address / .sprite_location
		call bitblt
		ret		
		
; ---------------------

start_sprites_0:
		mov dx, spr_0
		call save_sprite_2
		mov dx, spr_1
		call save_sprite_2
		mov dx, spr_2
		call save_sprite_2
		mov dx, spr_3
		call save_sprite_2
		mov dx, spr_4
		call save_sprite_2
		mov dx, spr_5
		call save_sprite_2
		mov dx, spr_6
		call save_sprite_2
		mov dx, spr_7
		call save_sprite_2
		mov dx, spr_8
		call save_sprite_2
		mov dx, spr_9
		call save_sprite_2
		mov dx, spr_10
		call save_sprite_2
		ret
		
start_sprites_1:
		mov dx, spr_0
		call save_sprite_3
		mov dx, spr_1
		call save_sprite_3
		mov dx, spr_2
		call save_sprite_3
		mov dx, spr_3
		call save_sprite_3
		mov dx, spr_4
		call save_sprite_3
		mov dx, spr_5
		call save_sprite_3
		mov dx, spr_6
		call save_sprite_3
		mov dx, spr_7
		call save_sprite_3
		mov dx, spr_8
		call save_sprite_3
		mov dx, spr_9
		call save_sprite_3
		mov dx, spr_10
		call save_sprite_3
		
		;call save_sprite
		ret
		
; page 0
draw_sprites_0:
		mov dx, spr_0
		call restore_sprite_2
		mov dx, spr_1
		call restore_sprite_2
		mov dx, spr_2
		call restore_sprite_2
		mov dx, spr_3
		call restore_sprite_2
		mov dx, spr_4
		call restore_sprite_2
		mov dx, spr_5
		call restore_sprite_2
		mov dx, spr_6
		call restore_sprite_2
		mov dx, spr_7
		call restore_sprite_2
		mov dx, spr_8
		call restore_sprite_2
		mov dx, spr_9
		call restore_sprite_2
		mov dx, spr_10
		call restore_sprite_2
		
		;call restore_sprite
		
		mov dx, spr_0
		call save_sprite_2
		mov dx, spr_1
		call save_sprite_2
		mov dx, spr_2
		call save_sprite_2
		mov dx, spr_3
		call save_sprite_2
		mov dx, spr_4
		call save_sprite_2
		mov dx, spr_5
		call save_sprite_2
		mov dx, spr_6
		call save_sprite_2
		mov dx, spr_7
		call save_sprite_2
		mov dx, spr_8
		call save_sprite_2
		mov dx, spr_9
		call save_sprite_2
		mov dx, spr_10
		call save_sprite_2
		
		;call save_sprite

		mov dx, spr_0
		call draw_sprite_2
		mov dx, spr_1
		call draw_sprite_2
		mov dx, spr_2
		call draw_sprite_2
		mov dx, spr_3
		call draw_sprite_2
		mov dx, spr_4
		call draw_sprite_2
		mov dx, spr_5
		call draw_sprite_2
		mov dx, spr_6
		call draw_sprite_2
		mov dx, spr_7
		call draw_sprite_2
		mov dx, spr_8
		call draw_sprite_2
		mov dx, spr_9
		call draw_sprite_2
		mov dx, spr_10
		call draw_sprite_2
		
		;call draw_sprite
		ret

; page 1		
draw_sprites_1:
		mov dx, spr_0
		call restore_sprite_3
		mov dx, spr_1
		call restore_sprite_3
		mov dx, spr_2
		call restore_sprite_3
		mov dx, spr_3
		call restore_sprite_3
		mov dx, spr_4
		call restore_sprite_3
		mov dx, spr_5
		call restore_sprite_3
		mov dx, spr_6
		call restore_sprite_3
		mov dx, spr_7
		call restore_sprite_3
		mov dx, spr_8
		call restore_sprite_3
		mov dx, spr_9
		call restore_sprite_3
		mov dx, spr_10
		call restore_sprite_3
		
		;call restore_sprite
		
		mov dx, spr_0
		call save_sprite_3
		mov dx, spr_1
		call save_sprite_3
		mov dx, spr_2
		call save_sprite_3
		mov dx, spr_3
		call save_sprite_3
		mov dx, spr_4
		call save_sprite_3
		mov dx, spr_5
		call save_sprite_3
		mov dx, spr_6
		call save_sprite_3
		mov dx, spr_7
		call save_sprite_3
		mov dx, spr_8
		call save_sprite_3
		mov dx, spr_9
		call save_sprite_3
		mov dx, spr_10
		call save_sprite_3
		
		;call save_sprite

		mov dx, spr_0
		call draw_sprite_3
		mov dx, spr_1
		call draw_sprite_3
		mov dx, spr_2
		call draw_sprite_3
		mov dx, spr_3
		call draw_sprite_3
		mov dx, spr_4
		call draw_sprite_3
		mov dx, spr_5
		call draw_sprite_3
		mov dx, spr_6
		call draw_sprite_3
		mov dx, spr_7
		call draw_sprite_3
		mov dx, spr_8
		call draw_sprite_3
		mov dx, spr_9
		call draw_sprite_3
		mov dx, spr_10
		call draw_sprite_3
		
		;call draw_sprite
		ret		