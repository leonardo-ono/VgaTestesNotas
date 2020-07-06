; keyboard handler
; designed for large memory model
; written by Leonardo Ono 

	bits 16

	global _install_key_handler
	global _uninstall_key_handler
	global _is_key_pressed

segment _TEXT public class=CODE

	_install_key_handler:
			push es
			cli
			mov ax, 0
			mov es, ax
			mov ax, [es:4 * 9 + 2]
			mov [ds:int9_original_segment], ax
			mov ax, [es:4 * 9]
			mov [ds:int9_original_offset], ax
			mov ax, cs
			mov word [es:4 * 9 + 2], ax
			mov word [es:4 * 9], key_handler
			sti
			pop es
			retf

	_uninstall_key_handler:
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
			retf

	; int far is_key_pressed(int code)
	_is_key_pressed:
			push bp
			mov bp, sp
			mov bx, [bp + 6]
			mov al, [key_pressed + bx]
			mov ah, 0
			pop bp
			retf
			
	key_handler:
			push es
			push ax
			push bx
			mov ax, _DATA
			mov es, ax
			in al, 60h
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

section _DATA public class=DATA
	int9_original_offset	dw 0
	int9_original_segment	dw 0

	key_pressed		times 256 db 0


