
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
		call wait_retrace ; <-- pel panning in pcem only works properly with this
		
		;o := y*size+x; size=82 p/ virtual screen width = 328
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
		call wait_retrace_2 ; <-- pel panning in pcem only works properly with this
		
		; 4 pixels fix for panning
		
		;cli ; <- is this necessary ?
		
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
		and ax, 3
		shl ax, 1
		out dx, al
		
		mov dx, AC_WRITE
		mov al, bl
		out dx, al
		
		;sti ; <- is this necessary ?

		
		ret	
		
wait_retrace_3:
		push dx
		push ax
		
		mov dx, 3dah
		
	.l2:
		in al,dx
		test al, 08h
		jnz .l2
		
		pop ax
		pop dx
		ret
		
wait_retrace_2:
		push dx
		push ax
		
		mov dx, 3dah
		
	.l1:
		in al,dx
		test al, 08h
		jz .l1
		
		pop ax
		pop dx
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

; July 3, 2020
; si = image address
; di = destination 
drawImage:
		mov bp, 0
		mov bl, 1
		
	.next_plane:
		push si
		push di
		
		call change_write_plane

		mov ax, [si - 2]
		mov cl, 82 ; [st1tiles_width] / 4
		mul cl
		mov cx, ax
		
		;mov cx, (36 * 82)
	.next_pixel:
		mov al, [si + bp]
		mov [es:di], al
		inc di
		add si, 4
		loop .next_pixel
		
		pop di
		pop si
		inc bp

		shl bl, 1
		cmp bl, 16
		jnz .next_plane

	.end:
		ret

bitblt_start:
		mov dx, SC_INDEX
		mov al, MAP_MASK
		mov ah, 0fh ; select all 4 planes			
		out dx, ax
		ret
		
; copy screen to screen - 4 planes at once
; https://www.phatcode.net/res/224/files/html/ch48/48-04.html
; si = source video address
; bp = height (in pixels)
; cx = width (4 pixels) / 2 = 8 pixels
; di = destination
bitblt:
		push ax
		push bx
		push cx
		push dx
		push di
		push si
		push ds
		
		;mov dx, SC_INDEX
		;mov al, MAP_MASK
		;mov ah, 0fh ; select all 4 planes			
		;out dx, ax
		
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

; draw column test
;		mov si, [tiles_location] ; si = source video address
;		add si, 2
;		mov di, [scroll_x]
;		shr di, 1
;		shr di, 1
;		add di, 80
;		call bitblt
;		mov cx, 24
;	.next_row:
;		add di, 82 * 8
;		call bitblt
;		loop .next_row

; cx = destination address
; bp = stage_column_index address
draw_next_stage_column:
		mov byte [stage_column_y], 0 ; clear

	.next_data:
		mov bx, bp
		mov si, [bx]
		mov al, [si]
		
		cmp al, 0
		jnz .draw
		
	.repeat_empty:
		inc si
		mov al, [si] ; al = empty block size
		inc si
		mov bx, bp
		mov [bx], si
		add [stage_column_y], al
		cmp byte [stage_column_y], 20
		ja .end
		jmp .next_data
		
	.draw:
		inc si
		mov bx, bp ; stage_column_index_0
		mov [bx], si

		mov ah, 0
		shl ax, 1
		mov bx, ax
		mov si, [tileIdToOffset + bx]
		add si, [tiles_location]		

		mov di, cx ; [scroll_x_0] ; -> di is parameter
		;shr di, 1
		;shr di, 1
		
		mov ax, 82 * 8
		mov bh, 0
		mov bl, [stage_column_y]
		mul bx
		add di, ax	

		add di, 80
		
		;mov si, [tiles_location] ; si = source video address
		;add si, 2
		
		push cx 
		push bp
		mov cx, 2 
		mov bp, 8
		call bitblt
		pop bp
		pop cx
		
		inc byte [stage_column_y]
		cmp byte [stage_column_y], 20
		ja .end
		
		jmp .next_data
		
	.end:
		; stage_1_map
		
		ret
		