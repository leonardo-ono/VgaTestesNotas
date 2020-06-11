; "Bad Apple" FMV for PC-XT (No Sound)
;
; Written by Leonardo Ono (ono.leo80@gmail.com)
; June 10, 2020
;
; Target Machine: PC-XT 4.7MHz
; Target OS: DOS
; Assembler: nasm 2.14
; Linker: tlink (Turbo Link v2.0)
; To assemble and link, use: build.bat
;
; References:
; youtube video: https://www.youtube.com/watch?v=FtutLA63Cp8
; online youtube downloader: https://en.savefrom.net/17/
; video to jpg: https://www.onlineconverter.com/video-to-jpg
			
			%define MISC_OUTPUT       03c2h
			%define GC_INDEX          03ceh
			%define SC_INDEX          03c4h
			%define SC_DATA           03c5h
			%define CRTC_INDEX        03d4h
			%define CRTC_DATA         03d5h
			%define INPUT_STATUS      03dah
			%define AC_WRITE          03c0h
			%define AC_READ           03c1h		
			%define MAP_MASK            02h
			%define MEMORY_MODE         04h
			%define UNDERLINE_LOC       14h
			%define MODE_CONTROL        17h
			%define HIGH_ADDRESS        0ch
			%define LOW_ADDRESS         0dh
			%define LINE_OFFSET         13h
			%define PEL_PANNING         13h
			%define CRTC_LINECOMPARE    18h		
			%define CRTC_OVERFLOW        7h
			%define CRTC_MAXSCANLINE     9h
			%define AC_MODE_CONTROL	    10h
				
			bits 16
			
segment code			
			
	..start:
			; set ds and es registers
			mov ax, data
			mov ds, ax
			
			mov ax, 0a000h
			mov es, ax

			cld ; clear direction flag

			mov al, 13h
			call far set_video_mode
			call far set_video_mode_y
			call far fix_palette
			
			; convert screen resolution to 320x100
			mov bl, 3 ; bl = max scanline
			call far set_max_scanline

			;mov ah, 0
			;int 16h
			
		.next_frame:
			call far wait_vsync
			call far wait_vsync
			call far wait_vsync
			call far wait_vsync
			call far wait_vsync
			call far wait_vsync
			call far wait_vsync
			
			call far draw_frame
			
			; end of animation
			cmp byte [end_of_animation], 1
			jz .exit
			
			mov ah, 1
			int 16h
			jnz .exit
			;cmp al, 27
			;jz .exit
			
			jmp .next_frame
			
		.exit:
			mov al, 3
			call far set_video_mode
			
			mov ax, 4c00h
			int 21h

segment video

	; al = video mode		
	set_video_mode:
			mov ah, 0
			int 10h
			retf
			
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
			call far change_write_plane
			
			retf
			
	; bl = max scanline
	set_max_scanline:
			mov dx, CRTC_INDEX
			mov al, CRTC_MAXSCANLINE
			out dx, al
			
			mov dx, CRTC_DATA
			mov al, bl
			out dx, al
			retf	
			
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
			retf
		
	wait_vsync:
			push ax
			push dx
			mov dx, INPUT_STATUS
		.l1:
			in al, dx
			test al, 08h
			jz .l1
		.l2:
			in al, dx
			test al, 08h
			jnz .l2
			pop dx
			pop ax
			retf

	fix_palette:
			mov dx, 3c8h
			mov al, 1 ; color index 
			out dx, al
	;		mov cx, 256 ; palette size
	;	.next_color:
			mov dx, 3c9h
			mov al, 0ffh
			out dx, al ;red
			out dx, al ; green
			out dx, al ; blue
	;		loop .next_color
			retf
				
	draw_frame:
			push ds
			
			mov si, [current_frame_offset]
			mov ax, [current_frame_seg]
			mov ds, ax
			
			; es already 0a000h
			mov di, 0
			
			mov bx, 0
		.next:
		
			mov ch, 0
			mov cl, [si] ; current_frame_seg:current_frame_offset
		
		.check_special_command:
			cmp cl, 0 ; 0 = special command
			ja .size_ok
		
		.check_end_of_frame:
			inc si
			mov cx, [si]
			cmp cx, 0 ; 0 (word) = end of frame
			jz .end_of_frame
			; if cx > 0 -> cx = size (word)
			inc si
			
		.size_ok:	
			mov ax, bx
			and ax, 1
			rep stosb
			
			inc bx
			inc si
			
			jmp .next
			
		.end_of_frame:
			add si, 2
			
		.check_end_of_segment:
			mov cx, [si] ; current_frame_seg:current_frame_offset
			cmp cx, 0 ; 0 (word) = end of segment
			jnz .segment_ok
			
		.end_of_segment:
			mov cx, [si + 2] ; next animation segment
			mov ax, data
			mov ds, ax
			mov [current_frame_seg], cx
			mov word [current_frame_offset], 0
		
		.check_end_of_animation:		
			cmp cx, 0
			jnz .ret
		
		.end_of_animation:			
			; mov byte [end_of_animation], 1
			
			jmp .ret 
			
		.segment_ok:
			mov ax, data
			mov ds, ax
			mov [current_frame_offset], si
			
		.ret:
			pop ds
			retf

; --- animation data ---
%include "anim.asm"
			
segment data

	current_frame_seg dw animation_data_0
	current_frame_offset dw 0
	
	end_of_animation db 0
	
segment stack stack
		resb 256

		

