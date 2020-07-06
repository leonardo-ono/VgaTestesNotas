
		
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

int9_original_offset	dw 0
int9_original_segment	dw 0

key_pressed		times 256 db 0
