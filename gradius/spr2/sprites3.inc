; system memory -> display memory
; draw 4 pages separately

; ah = select plane 1 2 4 8
;                   0 1 2 3
; si = spr_page_0
; di = vram destination
draw_spr_page:
		cld ; clear flag direction
		
		mov dx, SC_INDEX
		mov al, MAP_MASK
		; mov ah, 01h ; select all 4 planes			
		out dx, ax

		mov dx, GC_INDEX          ;set the bit mask to select all bits
        ; mov ax, 7e00h + BIT_MASK ; from the latches and none from
        mov ax, 0ff00h + BIT_MASK ; from the latches and none from
        out dx, ax                ; the CPU, so that we can write the

		; mov di, 82 * 50 + 40 ; start drawing location
		
		; mov si, spr_page_0
		
		mov bh, 0
		mov bl, [si]
		inc si

		cmp bx, 1 ; check if start with transparency or opaque pixels
		jz .opaque
		
	.transparent: ; bx = 0
		mov ah, 0
		mov al, [si]
		inc si
		add di, ax
		mov bx, 1 
		jmp .next
		
	.opaque: ; bx = 1
		mov ch, 0
		mov cl, [si]
		inc si
		rep movsb
		mov bx, 0
	
	.next:
		mov al, [si]
		cmp al, 0
		jz .end
		cmp bx, 0
		jz .transparent
		jmp .opaque
		
	.end:
		ret

; di = vram location
draw_sprite_4_page:
		push di 
		
		mov ah, 1 ; ah = select plane 1 2 4 8 / 0 1 2 3
		mov si, spr_page_0 ; si = spr_page_0
		;mov di, 82 * 50 + 40 ; vram destination
		call draw_spr_page

		pop di
		push di

		mov ah, 2 ; ah = select plane 1 2 4 8 / 0 1 2 3
		mov si, spr_page_1 ; si = spr_page_0
		;mov di, 82 * 50 + 40 ; vram destination
		call draw_spr_page

		pop di
		push di

		mov ah, 4 ; ah = select plane 1 2 4 8 / 0 1 2 3
		mov si, spr_page_2 ; si = spr_page_0
		;mov di, 82 * 50 + 40 ; vram destination
		call draw_spr_page

		pop di

		mov ah, 8 ; ah = select plane 1 2 4 8 / 0 1 2 3
		mov si, spr_page_3 ; si = spr_page_0
		;mov di, 82 * 50 + 40 ; vram destination
		call draw_spr_page
		
		ret		

; si = sprite data
; di = vram location
; ax = 0~3 -> x%4
; cl = plane 0~3
draw_sprite_4_page_2:
		push cx
		
		mov bh, 0
		mov bl, cl
		shl bx, 1
		shl bx, 1
		
		mov cl, 4
		shl ax, cl
		
		add bx, ax
		add bx, sprite_page_table
		add di, [bx] ; p + 1
		add si, [bx + 2] ; spr_data + offset
		mov si, [si]
		
		pop cx
		mov ah, 1
		shl ah, cl ; ah = select plane 1 2 4 8 / 0 1 2 3
		; mov si, spr_data + 8 ; si = spr_page_0
		; mov di, 0 ; vram destination
		call draw_spr_page
		
		ret		

; di = [spr_0.restore_location] ; di = vram location
draw_sprite_complete:
		push di
		
		mov si, spr_data ; si = sprite data
		;mov di, [spr_0.restore_location] ; di = vram location
		mov ax, [spr_0.x] ; ax = 0~3 -> x%4
		and ax, 3
		mov cl, 0 ; bx = plane 0~3
		call draw_sprite_4_page_2

		pop di
		push di

		mov si, spr_data ; si = sprite data
		;mov di, [spr_0.restore_location] ; di = vram location
		mov ax, [spr_0.x] ; ax = 0~3 -> x%4
		and ax, 3
		mov cl, 1 ; bx = plane 0~3
		call draw_sprite_4_page_2

		pop di
		push di

		mov si, spr_data ; si = sprite data
		;mov di, [spr_0.restore_location] ; di = vram location
		mov ax, [spr_0.x] ; ax = 0~3 -> x%4
		and ax, 3
		mov cl, 2 ; bx = plane 0~3
		call draw_sprite_4_page_2
		
		pop di
		
		mov si, spr_data ; si = sprite data
		;mov di, [spr_0.restore_location] ; di = vram location
		mov ax, [spr_0.x] ; ax = 0~3 -> x%4
		and ax, 3
		mov cl, 3 ; bx = plane 0~3
		call draw_sprite_4_page_2
		
		ret

spr_data:
		   dw spr_page_0, spr_page_1, spr_page_2, spr_page_3
spr_page_0 db 0,84,1,77,81,1,15,80,2,77,77,80,3,77,77,0,79,3,77,77,77,79,3,77,0,77,79,3,0,42,15,79,3,77,42,15,79,3,77,0,15,79,3,15,77,77,79,3,15,15,77,79,3,77,77,77,80,1,77,243,0
spr_page_1 db 0,84,1,77,80,2,77,77,80,2,77,15,80,2,15,77,80,2,15,0,80,3,77,77,77,79,3,77,0,77,79,3,0,0,77,79,3,77,77,77,79,3,77,77,77,79,3,15,77,77,79,2,15,77,0
spr_page_2 db 0,83,1,77,81,2,77,77,80,2,15,77,80,2,15,0,80,2,77,77,80,2,77,15,79,3,0,0,77,79,4,77,0,77,77,78,4,77,77,0,77,79,2,77,77,80,2,77,77,80,2,15,77,80,1,77,244,0
spr_page_3 db 0,83,1,77,81,1,77,81,2,15,77,80,2,77,0,80,2,77,77,80,2,0,15,79,3,0,42,15,79,3,77,42,77,79,3,15,0,77,79,3,77,77,0,79,3,77,15,0,80,2,15,0,80,1,77,244,0

; case = x % 4
sprite_page_table:
;          d  s
; plane    --0-  --1-  --2-  --3-
		dw 0, 0, 0, 2, 0, 4, 0, 6 ; case 0 
		dw 1, 6, 0, 0, 0, 2, 0, 4 ; case 1 
		dw 1, 4, 1, 6, 0, 0, 0, 2 ; case 2 
		dw 1, 2, 1, 4, 1, 6, 0, 0 ; case 3 
	