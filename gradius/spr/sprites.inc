; si = location. For instance: mov si, [scroll_x_0] or mov si, [scroll_x_1]
; bx = number of line (or page flipping location) 0 or 169		
draw_ship_sprites_test_1:
	mov di, si
	; mov si, [scroll_x_1]
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
	; mov di, [scroll_x_1] ; di = destination
	add di, [ship_x]
	shr di, 1
	shr di, 1

	; add di, 82 * (169 + 100) + 41

	; mov ax, 169
	mov ax, bx
	
	add ax, [ship_y]
	mov bx, 82
	mul bx
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

	pop di
	;push di
	add di, 82 * 16 + 32
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
	;add di, 82 * 16 + 56
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

	ret