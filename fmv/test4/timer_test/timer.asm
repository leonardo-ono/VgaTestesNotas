	bits 16
	org 100h
	
start:
	mov ah, 0eh
	mov al, 41h
	int 10h
	call install_timer_handler
	
	mov ah, 0
	int 16h
	
	call restore_timer_handler
	
	mov ax, 4c00h
	int 21h

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
	mov ax, cs
	mov [es:4 * 8 + 2], ax
	sti
	ret
	
restore_timer_handler:
	cli
	mov ax, 0
	mov es, ax
	mov ax, [int8h_old_offset]
	mov [es:4 * 8], ax
	mov ax, [int8h_old_seg]
	mov [es:4 * 8 + 2], ax
	sti
	ret

int8h_handler:
	push ax
	mov ah, 0eh
	mov al, 41h
	int 10h
	mov al, 20h
	out 20h, al
	pop ax
	iret
	
int8h_old_offset dw 0
int8h_old_seg dw 0

