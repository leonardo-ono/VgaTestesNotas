; "Bad Apple" FMV with PC-Speaker Music
;
; Written by Leonardo Ono (ono.leo80@gmail.com)
; June 24, 2020
;
; Target Machine: PC-XT 4.7Mhz
; Target OS: DOS
; Assembler: nasm 2.14
; Linker: tlink (Turbo Link v2.0)
; To assemble and link, use: build.bat
;
; References:
; youtube video: https://www.youtube.com/watch?v=FtutLA63Cp8
; online youtube downloader: https://en.savefrom.net/17/
; video to jpg: https://www.onlineconverter.com/video-to-jpg
; 
; Resource:
; Touhou-BadApple!!.mid - https://freemidi.org/request-detail-153

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
			
			call far install_timer_handler
			call far start_fast_clock
			
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
			; synchronize music with video
			mov bx, [music_next_frame]
			shr bx, 1
			cmp [music_index], bx
			jb .next_frame
		
		; music from     0~15498 -> 14.0 notes/frame
		;            15499~end   -> 13.5 notes/frame
			cmp word [music_index], 15498
			ja .v15
			add word [music_next_frame], 11100b
			jmp .vok
		.v15:
			add word [music_next_frame], 11011b
		.vok:
		
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
			call far stop_fast_clock
			call far restore_timer_handler
		
			mov al, 3
			call far set_video_mode
			call far note_off
			mov ax, 4c00h
			int 21h

segment timer
	
	; count = 1193180 / sampling_rate
	; sampling_rate = 140 cycles per second
	; count = 1193180 / 140 = 214a (in hex) 
	start_fast_clock:
			cli
			mov al, 36h
			out 43h, al
			mov al, 04ah ; low 
			out 40h, al
			mov al, 021h ; high
			out 40h, al
			sti
			retf

	stop_fast_clock:
			cli
			mov al, 36h
			out 43h, al
			mov al, 0h ; low 
			out 40h, al
			mov al, 0h ; high
			out 40h, al
			sti
			retf
			
	install_timer_handler:
			cli
			mov ax, 0
			mov es, ax
			mov ax, [es:4 * 8]
			mov [int8h_old_offset], ax
			mov ax, [es:4 * 8 + 2]
			mov [int8h_old_seg], ax
			; new int 8h interruption handler
			mov word [es:4 * 8], int8h_handler
			mov word [es:4 * 8 + 2], timer
			sti
			retf
		
	restore_timer_handler:
			cli
			mov ax, 0
			mov es, ax
			mov ax, [int8h_old_offset]
			mov [es:4 * 8], ax
			mov ax, [int8h_old_seg]
			mov [es:4 * 8 + 2], ax
			sti
			retf

	int8h_handler:
			pusha
			push ds
			
			; needs to set ds because		
			; this int 8 can be called when
			; ds is set to another value			
			mov ax, data
			mov ds, ax
			
			call far play_next_note
			mov al, 20h
			out 20h, al
			
			pop ds
			popa
			iret
	
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

	; convert color index 1 to white
	fix_palette:
			mov dx, 3c8h
			mov al, 1 ; color index 
			out dx, al
			mov dx, 3c9h
			mov al, 0ffh
			out dx, al ;red
			out dx, al ; green
			out dx, al ; blue
			retf
				
	draw_frame:
			push ds
			
			mov si, [current_frame_offset]
			mov ax, [current_frame_seg]
			mov ds, ax
			
			; es already 0a000h
			mov di, 0
			
			mov bx, 0 ; black or white ?
			
		.next:
			mov ch, 0
			mov cl, [si] ; current_frame_seg:current_frame_offset
		
		.check_special_command:
			cmp cl, 0 ; end of animation
			je .end_of_animation
			cmp cl, 1 ; repeated pair (a, b)
			je .repeated_pair
			cmp cl, 2 ; double value (low, high)
			je .double_value
			cmp cl, 3 ; end of frame
			je .end_of_frame
			cmp cl, 4 ; end of segment
			je .end_of_segment
			
			sub cl, 4
			jmp .size_ok
			
		.end_of_animation:
			mov ax, data
			mov ds, ax
			mov byte [end_of_animation], 1
			jmp .ret 
		
		.end_of_segment:
			mov cx, [si + 1] ; next animation segment
			mov ax, data
			mov ds, ax
			mov [current_frame_seg], cx
			mov word [current_frame_offset], 0
			mov ds, cx
			xor si, si
			jmp .next
			
		.repeated_pair:
			mov ch, 0
			mov cl, [si + 1] ; repeat count
			
		.next_pair:
			push cx

			mov ch, 0
			mov cl, [si + 2] ; a
			sub cl, 4
			mov ax, bx
			and ax, 1
			rep stosb
			inc bx

			mov ch, 0
			mov cl, [si + 3] ; b
			sub cl, 4
			mov ax, bx
			and ax, 1
			rep stosb
			inc bx
			
			pop cx
			loop .next_pair
			
			add si, 4
			jmp .next
			
		.double_value:
			mov cx, [si + 1] ; double size
			add si, 2
			jmp .size_ok
		
		.end_of_frame:
			inc si
			mov ax, data
			mov ds, ax
			mov [current_frame_offset], si
			jmp .ret
			
		.size_ok:	
			mov ax, bx
			and ax, 1
			rep stosb
			inc bx
			inc si
			
			jmp .next
			
		.ret:
			pop ds
			retf

segment music

	play_next_note:
			mov si, [music_index]
			cmp si, [ba_music_size]
			ja .note_off
			
			mov bh, 0
			mov bl, [ba_music + si]

			cmp bl, 255 ; ignore
			jz .ignore
			cmp bl, 254 ; note off
			jz .note_off
			
		.play_midi_note:
			shl bx, 1
			mov ax, [midi_note_to_freq_table + bx];
			call note_on
			jmp .ignore
			
		.note_off:
			call far note_off

		.ignore:
			inc si
			mov [music_index], si

		.end:
			retf
			
	; ax = 1193180 / frequency		
	note_on:
			; change frequency
			mov dx, ax
			mov al, 0b6h
			out 43h, al
			mov ax, dx
			out 42h, al
			mov al, ah
			out 42h, al

			; start the sound
			in al, 61h
			or al, 3h
			out 61h, al
			ret
			
	; stop the sound
	note_off:
			in al, 61h
			and al, 0fch
			out 61h, al			
			retf
			

; --- animation data ---
%include "anim.asm"
			
segment data
	current_frame_seg dw animation_data_0
	current_frame_offset dw 0
	end_of_animation db 0
	
	; --- timer ---
	int8h_old_offset dw 0
	int8h_old_seg dw 0

	; --- music ---
	music_next_frame dw 11100b ; fixed point math 1 bit decimal precision
	music_index dw 0 
	midi_note_to_freq_table:
			db 014h, 03ah, 015h, 01ah, 0e2h, 0fbh, 060h, 0dfh, 079h, 0c4h, 013h, 0abh, 01bh, 093h, 07bh, 07ch
			db 020h, 067h, 0f8h, 052h, 0f2h, 03fh, 0fdh, 02dh, 00ah, 01dh, 00ah, 00dh, 0f1h, 0fdh, 0b0h, 0efh
			db 03ch, 0e2h, 089h, 0d5h, 08dh, 0c9h, 03dh, 0beh, 090h, 0b3h, 07ch, 0a9h, 0f9h, 09fh, 0feh, 096h
			db 085h, 08eh, 085h, 086h, 0f8h, 07eh, 0d8h, 077h, 01eh, 071h, 0c4h, 06ah, 0c6h, 064h, 01eh, 05fh
			db 0c8h, 059h, 0beh, 054h, 0fch, 04fh, 07fh, 04bh, 042h, 047h, 042h, 043h, 07ch, 03fh, 0ech, 03bh
			db 08fh, 038h, 062h, 035h, 063h, 032h, 08fh, 02fh, 0e4h, 02ch, 05fh, 02ah, 0feh, 027h, 0bfh, 025h
			db 0a1h, 023h, 0a1h, 021h, 0beh, 01fh, 0f6h, 01dh, 047h, 01ch, 0b1h, 01ah, 031h, 019h, 0c7h, 017h
			db 072h, 016h, 02fh, 015h, 0ffh, 013h, 0dfh, 012h, 0d0h, 011h, 0d0h, 010h, 0dfh, 00fh, 0fbh, 00eh
			db 023h, 00eh, 058h, 00dh, 098h, 00ch, 0e3h, 00bh, 039h, 00bh, 097h, 00ah, 0ffh, 009h, 06fh, 009h
			db 0e8h, 008h, 068h, 008h, 0efh, 007h, 07dh, 007h, 011h, 007h, 0ach, 006h, 04ch, 006h, 0f1h, 005h
			db 09ch, 005h, 04bh, 005h, 0ffh, 004h, 0b7h, 004h, 074h, 004h, 034h, 004h, 0f7h, 003h, 0beh, 003h
			db 088h, 003h, 056h, 003h, 026h, 003h, 0f8h, 002h, 0ceh, 002h, 0a5h, 002h, 07fh, 002h, 05bh, 002h
			db 03ah, 002h, 01ah, 002h, 0fbh, 001h, 0dfh, 001h, 0c4h, 001h, 0abh, 001h, 093h, 001h, 07ch, 001h
			db 067h, 001h, 052h, 001h, 03fh, 001h, 02dh, 001h, 01dh, 001h, 00dh, 001h, 0fdh, 000h, 0efh, 000h
			db 0e2h, 000h, 0d5h, 000h, 0c9h, 000h, 0beh, 000h, 0b3h, 000h, 0a9h, 000h, 09fh, 000h, 096h, 000h
			db 08eh, 000h, 086h, 000h, 07eh, 000h, 077h, 000h, 071h, 000h, 06ah, 000h, 064h, 000h, 05fh, 000h
	
	%include "music.dat"
		
segment stack stack
		resb 256

		

