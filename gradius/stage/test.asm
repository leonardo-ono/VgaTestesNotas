; references:
;
; Osystem - https://www.youtube.com/watch?v=9vdsRD3oI3c&t=14s
; https://github.com/mills32/Little-Game-Engine-for-VGA
;
; https://github.com/root42/letscode-breakout/blob/master/vga.c
; root42 - https://www.youtube.com/watch?v=IFueAukNyxk
; http://www.scs.stanford.edu/10wi-cs140/pintos/specs/freevga/vga/vgafx.htm

		%define MISC_OUTPUT  03c2h
		%define GC_INDEX     03ceh
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
		;call install_key_handler
		
		; clear flag direction
		cld
		
		; destination VRAM
		mov ax, 0a000h
		mov es, ax
		
		call fill_screen
		
		;mov bx, 319 ; bx = x
		;mov dx, 1 ; dx = y
		;mov cl, 15 ; cl = color
		;call set_pixel
		;mov ah, 0
		;int 16h
		
		
		mov si, st1tiles
		mov bx, 0
		mov dx, 0
		call draw_image

		;mov si, 82 * 8 ; si = source video address
		;mov bx, 0 ; bx = x
		;mov dx, 100 ; dx = y
		;call bitblt

		mov di, 0 ; di = x
		mov ax, 60 ; ax = y
		call move_to
		
		
		mov word [restore_stage.tiles_vram_location], st1tiles_vram_location
		mov word [restore_stage.start_draw_vram_location], 82 * 60
		mov word [restore_stage.start_map_location], stage_1_map_start
		mov word [restore_stage.stage_start_col], 0
		mov word [restore_stage.x], 201
		mov word [restore_stage.y], 122
		mov word [restore_stage.width], 16
		mov word [restore_stage.height], 16
		call restore_stage
		
		mov ah, 0
		int 16h

		
		mov ax, 0
	.next_initial_column:
		push ax
		mov si, stage_1_map_start ; si = stage_1_map_start location -> map_data
		mov bx, ax ; bx = column number (0~499)
		shl ax, 1
		mov di, 82 * 60 + 0; di = page_start_address + (scroll_x / 4)
		add di, ax
		call draw_next_stage_column_2
		pop ax
		inc ax
		cmp ax, 41
		jb .next_initial_column
		
		mov si, stage_1_map_start ; si = stage_1_map_start location -> map_data
		mov bx, 1 ; bx = column number (0~499)
		mov di, 82 * 60 + 2; di = page_start_address + (scroll_x / 4)
		call draw_next_stage_column_2

		;mov si, 82 * 8 ; si = source video address
		;mov bp, 16 ; bp = height (in pixels)
		;mov cx, 2 ; cx = width (4 pixels) / 2 = 8 pixels
		;mov di, 82 * 100 ; di = destination
		;call bitblt2

		mov ah, 0
		int 16h
		jmp .exit
		
		mov cx, 41
	.draw_next_initial_column:
		push cx
		call draw_next_stage_column
		pop cx
		loop .draw_next_initial_column
		

		mov word [brick_x], 160
		mov word [brick_y], 100
		mov word [scroll_x], 0
			
	.next_column:	
		mov ax, 20 ; bp ; bp y scroll
		mov di, [scroll_x] ; bp x scroll
		call move_to
		call wait_retrace
		call wait_retrace
		call wait_retrace
		call wait_retrace
		call wait_retrace
		call wait_retrace
		call wait_retrace
		call wait_retrace
		add word [scroll_x], 4

		mov ah, 1
		int 16h
		jnz .exit
		;cmp al, 27
		;jz .exit

		mov ax, 20 ; bp ; bp y scroll
		mov di, [scroll_x] ; bp x scroll
		call move_to
		call wait_retrace
		call wait_retrace
		call wait_retrace
		call wait_retrace
		call wait_retrace
		call wait_retrace
		call wait_retrace
		call wait_retrace
		add word [scroll_x], 4
		
		call draw_next_stage_column

		mov ah, 1
		int 16h
		jnz .exit
		;cmp al, 27
		;jz .exit
		

		;mov si, 2
		;mov bx, [brick_x]
		;add bx, [scroll_x]
		;mov dx, [brick_y]
		;call bitblt

		
		jmp .next_column
		
		;mov si, img
		;mov bx, 320
		;mov dx, 0
		;call draw_image
		
		;mov si, img
		;mov bx, 0
		;mov dx, 200
		;call draw_image

		;mov si, img
		;mov bx, 320
		;mov dx, 200
		;call draw_image

		
		;mov ah, 0
		;int 16h
		;jmp .exit
		
		;call fill_screen

		;mov di, 170
		;call split_screen

		; draw brick
		;mov si, brick
		;mov bx, 0
		;mov dx, 0
		;call draw_image

		
		mov ax, 0
		mov bp, 0

		mov word [brick_x], 160
		mov word [brick_y], 100
		mov word [scroll_x], 0
	
	; --- main loop ---
		
	.next_y:
	
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
	
		mov bp, [scroll_x]
		;mov cl, 2
		;shr bp, cl;
	
		;call wait_retrace
		;call wait_retrace
		;call wait_retrace
		
		
		mov ax, 20 ; bp ; bp y scroll
		mov di, bp ; bp x scroll
		call move_to
	
		call wait_retrace
		
		
		mov si, 0
		mov bx, [brick_x]
		add bx, bp
		mov dx, [brick_y]
		call bitblt

		mov si, 0
		mov bx, [brick_x]
		add bx, 32
		add bx, bp
		mov dx, [brick_y]
		sub dx, 32
		call bitblt
; ---
		mov si, 0
		mov bx, [brick_x]
		add bx, bp
		sub bx, 20
		mov dx, [brick_y]
		add dx, 70
		call bitblt

		mov si, 0
		mov bx, [brick_x]
		add bx, bp
		add bx, 12
		mov dx, [brick_y]
		sub dx, 40
		call bitblt
;---

		mov si, 0
		mov bx, [brick_x]
		add bx, bp
		sub bx, 50
		mov dx, [brick_y]
		add dx, 15
		call bitblt

		mov si, 0
		mov bx, [brick_x]
		add bx, bp
		sub bx, 18
		mov dx, [brick_y]
		sub dx, 17
		call bitblt
;---

		mov si, 0
		mov bx, [brick_x]
		add bx, bp
		add bx, 30
		mov dx, [brick_y]
		call bitblt

		mov si, 0
		mov bx, [brick_x]
		add bx, 32
		add bx, bp
		add bx, 30
		mov dx, [brick_y]
		sub dx, 64
		call bitblt
;---
		mov si, 0
		mov bx, [brick_x]
		add bx, bp
		sub bx, 10
		mov dx, [brick_y]
		sub dx, 30
		call bitblt

		mov si, 0
		mov bx, [brick_x]
		add bx, bp
		add bx, 60
		mov dx, [brick_y]
		add dx, 60
		call bitblt

		mov si, 0
		mov bx, [brick_x]
		add bx, 100
		add bx, bp
		mov dx, [brick_y]
		add dx, 10
		call bitblt
		
		

		
		; wait for keypress
		;mov ah, 0
		;int 16h
		;jnz .exit
		;cmp al, 27
		;jz .exit
		mov bl, KEY_ESC
		call is_key_pressed
		cmp al, 0
		ja .exit

	.check_up:
		mov bl, KEY_UP
		call is_key_pressed
		cmp al, 0
		jz .check_down
	.up_pressed:
		sub word [brick_y], 1

	.check_down:
		mov bl, KEY_DOWN
		call is_key_pressed
		cmp al, 0
		jz .check_left
	.down_pressed:
		add word [brick_y], 1
	
	.check_left:
		mov bl, KEY_LEFT
		call is_key_pressed
		cmp al, 0
		jz .check_right
	.left_pressed:
		sub word [brick_x], 1
		
	.check_right:
		mov bl, KEY_RIGHT
		call is_key_pressed
		cmp al, 0
		jz .check_key_end
	.right_pressed:
		add word [brick_x], 1

	.check_key_end:
		;mov [scroll_prev], bp
		inc word [scroll_fino_x]
		cmp word [scroll_fino_x], 12
		jb .next_y
		
		;add bp, 4
		add word [scroll_x], 4
		mov word [scroll_fino_x], 0
		;cmp bp, 320
		;jb .next_y
		;mov bp, 0
		
		jmp .next_y
		
	.exit:
		;call uninstall_key_handler
		mov al, 3h
		call set_video_mode

		mov ax, 4c00h
		int 21h

		
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

fill_screen:
		push es
		mov ax, 0a000h
		mov es, ax
		mov bl, 1
	.next_plane:
		call change_write_plane
		
		mov di, 0
		mov cx, 64000
		mov al, 0 ; color
		rep stosb
		
		shl bl, 1
		cmp bl, 16
		jz .end
		
		jmp .next_plane
	.end:
		pop es
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
		
; http://www.petesqbsite.com/sections/tutorials/tutorials/3scroll.htm		
; http://archive.gamedev.net/archive/reference/articles/article358.html
; di = x
; ax = y
move_to:
		;o := y*size+x; size=82 p/ virtual screen=328
		; y scrolling is ok, but horizontally it can scroll 4 pixel at a time
		
		mov cx, 82
		xor dx, dx
		mul cx
		mov bx, di
		mov cl, 2
		shr bx, cl
		add ax, bx

		mov    bx, ax ; 10 * 80 * 2 + 0
		mov    ah, bh
		mov    al, HIGH_ADDRESS

		mov    dx, CRTC_INDEX
		out    dx, ax

		mov    ah, bl
		mov    al, LOW_ADDRESS
		mov    dx, CRTC_INDEX
		out    dx, ax		
		
; ret ; <--		
		
		; 4 pixels fix for panning
		
		cli ; <- is this necessary ?
		
		mov dx, INPUT_STATUS
		in al, dx
		
		mov dx, AC_WRITE
		in al, DX
		mov bl, al
		
		mov dx, AC_WRITE
		mov al, PEL_PANNING
		out dx, al
		
		mov dx, AC_WRITE
		mov ax, di ; scroll x
		shl ax, 1
		out dx, al
		
		mov dx, AC_WRITE
		mov al, bl
		out dx, al
		
		sti ; <- is this necessary ?
		
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
		
; https://github.com/mills32/Little-Game-Engine-for-VGA/blob/master/SRC/lt_gfx.c		
; https://github.com/sparky4/16/blob/master/src/lib/16_vl.c
; void VL_SetSplitScreen (int linenum)
; {
; 	VL_WaitVBL (1);
; 	linenum=linenum*2-1;
; 	outportb (CRTC_INDEX,CRTC_LINECOMPARE);
; 	outportb (CRTC_INDEX+1,linenum % 256);
; 	outportb (CRTC_INDEX,CRTC_OVERFLOW);
; 	outportb (CRTC_INDEX+1, 1+16*(linenum/256));
; 	outportb (CRTC_INDEX,CRTC_MAXSCANLINE);
; 	outportb (CRTC_INDEX+1,inportb(CRTC_INDEX+1) & (255-64));
; }

; di = linenum
split_screen:
		shl di, 1
		dec di
		
		mov dx, CRTC_INDEX
		mov al, CRTC_LINECOMPARE
		out dx, al
		
		mov dx, CRTC_DATA
		mov ax, di
		out dx, al
	
		mov dx, CRTC_INDEX
		mov al, CRTC_OVERFLOW
		out dx, al
		
		mov dx, CRTC_DATA
		mov ax, di
		mov cl, 8
		shr ax, cl
		mov cl, 4
		shl ax, cl
		inc ax
		out dx, al

		mov dx, CRTC_INDEX
		mov al, CRTC_MAXSCANLINE
		out dx, al
		
		mov dx, CRTC_DATA
		in al, dx
		
		and al, (255-64)
		
		mov dx, CRTC_DATA
		out dx, al
	
		; Turn on split screen pal pen suppression, so the split screen
		; won't be subject to pel panning as is the non split screen portion.

		mov  dx, INPUT_STATUS
		in   al, dx                  	; Reset the AC Index/Data toggle to index state
		mov  al, AC_MODE_CONTROL + 20h 	; Bit 5 set to prevent screen blanking
		mov  dx, AC_INDEX				; Point AC to Index/Data register
		out  dx, al
		inc  dx							; Point to AC Data reg (for reads only)
		in   al, dx						; Get the current AC Mode Control reg
		or   al, 20h						; Enable split scrn Pel panning suppress.
		dec  dx							; Point to AC Index/Data reg (for writes only)
		out  dx, al		
	
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
		mov cx, 2
		rep movsb
		
		add si, 82 - 2
		add di, 82 - 2
		inc bl
		cmp bl, 8
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


		
; note: color 0 = desenha no restore cor preta, 
;                 mas nesta funcao ignora para economizar processamento
; TODO draw_column(start_column, column_number)
draw_next_stage_column:
		mov byte [stage_column_y], 0 ; clear
		add word [stage_column_x], 8

	.next_data:
		mov si, [stage_column_index]
		mov al, [si]
		
		cmp al, 0
		jnz .draw
		
	.draw_empty:
		inc si
		mov [stage_column_index], si

		inc byte [stage_column_y]
		cmp byte [stage_column_y], 20
		ja .end
		
		jmp .next_data
		
	.draw:
		inc si
		mov [stage_column_index], si

		mov ah, 0
		shl ax, 1
		mov bx, ax
		mov si, [tileIdToOffset + bx] 
		;mov si, ax ; si = source video address
		
		mov bx, [stage_column_x] ; bx = x
		mov dh, 0
		mov dl, [stage_column_y] ; dx = y
		mov cl, 3
		shl dx, cl
		add dx, 48
		call bitblt
		
		inc byte [stage_column_y]
		cmp byte [stage_column_y], 20
		ja .end
		
		jmp .next_data
		
	.end:
		; stage_1_map
		add word [stage_column_index], 11
		
		
		ret
		

	
; note: color 0 = desenha no restore cor preta, 
;                 mas nesta funcao ignora para economizar processamento
; TODO ? = tiles_vram_location
; si = stage_1_map_start location -> map_data
; bx = column number (0~499)
; di = page_start_address + (scroll_x / 4)
draw_next_stage_column_2:
		mov byte [stage_column_y], 0 ; clear
		; add word [stage_column_x], 8

		mov cl, 5
		shl bx, cl
		add si, bx
		
	.next_data:
		; mov si, [stage_column_index]
		mov al, [si]
		
		cmp al, 0
		jnz .draw
		
	.draw_empty:
		inc si
		; mov [stage_column_index], si

		add di, 82 * 8

		inc byte [stage_column_y]
		cmp byte [stage_column_y], 20
		ja .end
		
		jmp .next_data
		
	.draw:
		inc si
		; mov [stage_column_index], si
		push si
		
		mov ah, 0
		shl ax, 1
		mov bx, ax
		mov si, [tileIdToOffset + bx] 
		;mov si, ax ; si = source video address
		
		;mov bx, [stage_column_x] ; bx = x
		;mov dh, 0
		;mov dl, [stage_column_y] ; dx = y
		;mov cl, 3
		;shl dx, cl
		;add dx, 48
		;call bitblt
		
		add si, st1tiles_vram_location
		; mov si, ax ; si = source video address
		mov bp, 8 ; bp = height (in pixels)
		mov cx, 2 ; cx = width (4 pixels) / 2 = 8 pixels
		;mov di, destination ; di = destination
		call bitblt2
		
		pop si ; restore stage_column_index
		
		add di, 82 * 8
		
		inc byte [stage_column_y]
		cmp byte [stage_column_y], 20
		ja .end
		
		jmp .next_data
		
	.end:
		; stage_1_map
		
		
		ret
		
		
; restore_stage.tiles_vram_location
; restore_stage.start_draw_vram_location
; restore_stage.start_map_location
; restore_stage.stage_start_col 
; restore_stage.x
; restore_stage.y
; restore_stage.width
; restore_stage.height
restore_stage:
		; .stage_col_1 = .stage_start_col + (.x / 8)
		mov ax, [.stage_start_col];
		mov bx, [.x]
		mov cl, 3
		shr bx, cl
		add ax, bx
		add [.stage_col_1], ax
		
		; .stage_col_2 = .stage_start_col + ((.x + .width - 1) / 8)
		mov ax, [.stage_start_col];
		mov bx, [.x]
		add bx, [.width]
		dec bx ; width - 1
		mov cl, 3
		shr bx, cl
		add ax, bx
		add [.stage_col_2], ax

		; .stage_row_1 = .y / 8
		mov ax, [.y]
		mov cl, 3
		shr ax, cl
		add [.stage_row_1], ax

		; .stage_row_2 = .y / 8
		mov ax, [.y]
		add ax, [.height]
		dec ax
		mov cl, 3
		shr ax, cl
		add [.stage_row_2], ax
		
		; loop
		mov ax, [.stage_col_1]
		mov [.stage_col], ax
		mov ax, [.stage_row_1]
		mov [.stage_row], ax
		
		mov ax, [.x] ; fix .x for 8 bytes align
		mov cl, 3
		shr ax, cl
		shl ax, cl
		mov [.x], ax

		and word [.y], 0fffch ; fix .y for 8 bytes align
		
		mov [.current_x], ax
		mov ax, [.y]
		mov [.current_y], ax
		
	.next_tile:
	
		; .map_location = .start_map_location + (.stage_col * 32) + .stage_row
		mov ax, [.stage_col]
		mov cl, 5
		shl ax, cl
		add ax, [.start_map_location]
		add ax, [.stage_row]
		mov [.map_location], ax
		
		; .draw_location = .start_draw_vram_location + (.y * 82) + (.x / 4)
		mov ax, [.current_y]
		mov bl, 82
		mul bl
		add ax, [.start_draw_vram_location]
		mov bx, [.current_x]
		mov cl, 2
		shr bx, cl
		add ax, bx
		mov [.draw_location], ax
		
		; convert tileId to map_location offset
		mov bx, [.map_location]
		mov bl, [bx] ; bl = tileId
		mov bh, 0
		shl bx, 1
		mov si, [tileIdToOffset + bx] ; si = tileset vram address offset
		add si, [.tiles_vram_location]
		
		; mov si, st1tiles_vram_location + 82 * 16 ; si = source video address
		mov bp, 8 ; bp = height (in pixels)
		mov cx, 2 ; cx = width (4 pixels) / 2 = 8 pixels
		;mov di, 82 * 100 ; di = destination
		mov di, [.draw_location]
		call bitblt2

		add word [.current_x], 8

		inc word [.stage_col]
		mov ax, [.stage_col]
		cmp ax, word [.stage_col_2]
		jbe .next_tile

		mov ax, [.x]
		mov [.current_x], ax

		mov ax, [.stage_col_1]
		mov [.stage_col], ax

		add word [.current_y], 8

		inc word [.stage_row]
		mov ax, [.stage_row]
		cmp ax, word [.stage_row_2]
		jbe .next_tile

		ret
		
	; --- parameters
	.tiles_vram_location dw 0
	.start_draw_vram_location dw 0
	.start_map_location dw 0
	.stage_start_col dw 0
	.x dw 0
	.y dw 0
	.width dw 0
	.height dw 0
	; --- local variables
	.stage_col_1 dw 0
	.stage_row_1 dw 0
	.stage_col_2 dw 0
	.stage_row_2 dw 0
	.stage_col dw 0
	.stage_row dw 0
	.map_location dw 0
	.draw_location dw 0
	.current_x dw 0
	.current_y dw 0
	
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
			cmp al, 10000000b
			jz .key_released
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

scroll_x dw 0		
scroll_fino_x dw 0		

scroll_prev dw 0 

; image file
img_start_x dw 0
img_start_y dw 0
img_x dw 0
img_y dw 0
img_i dw 0

%include "img.asm"

; %include "st1map.asm"
%include "stage1.asm"

st1tiles_vram_location equ 0
st1tiles_width dw 328
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



; --- stage ---
stage_column_index dw stage_1_map_start ; - stage_1_map
stage_column_y db 0
stage_column_x dw 0