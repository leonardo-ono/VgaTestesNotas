; Playing Super Mario Bros music on the PC speaker Test
; Assembly 8086 - Written by Leonardo Ono (ono.leo@gmail.com)
; 12/06/2018
; Target OS: DOS 
; Executable extension: *.COM
; use: nasm mario.asm -o mario.com -f bin

			bits 16
			org 100h

section .text

	start: ; entry point
	
			call start_fast_clock
			call play_music
			call stop_fast_clock
			call note_off
			; return to DOS
			mov ah, 4ch
			int 21h

	play_music:
			mov si, 0
		.next_note:
			mov bh, 0
			mov bl, [mario_music + si]

			; print note char in the screen
			mov ah, 0eh
			mov al, bl
			int 10h

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
			call note_off
		.ignore:
		
		.delay:
			call get_current_time
			cmp eax, [last_time]
			jbe .delay
			mov [last_time], eax
		
			inc si
			cmp si, [mario_music_size]
			
			mov ah, 1
			int 16h
			jnz .end
			
			jb .next_note
		.end:
			ret
			
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
			ret
			
	; count = 1193180 / sampling_rate
	; sampling_rate = 25 cycles per second
	; count = 1193180 / 25 = ba6f (in hex) 
	start_fast_clock:
			cli
			mov al, 36h
			out 43h, al
			mov al, 012h ; low 
			out 40h, al
			mov al, 01fh ; high
			out 40h, al
			sti
			ret

	stop_fast_clock:
			cli
			mov al, 36h
			out 43h, al
			mov al, 0h ; low 
			out 40h, al
			mov al, 0h ; high
			out 40h, al
			sti
			ret
			
	; eax = get current time
	get_current_time:
			push es
			mov ax, 0
			mov es, ax
			mov eax, [es:46ch]
			pop es
			ret
	
section .data

	last_time dd 0

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


		; --- music data ---
		%include "music.dat"
