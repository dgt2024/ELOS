__echo_main:
	mov eax, "OUT "
	mov dh, 2
	int 0x42

	mov ax, dx

	push ax

	mov edi, __echo_msg
	mov ecx, __echo_msg_end - __echo_msg
	mov dh, 1
	mov bl, 6
	int 0x42

	pop ax

	mov edi, 0x40000089
	mov ecx, 0xffffffff
	mov dh, 1
	mov bl, 6
	int 0x42
	
	mov eax, 0
	mov dh, 3
	int 0x43

__echo_msg:
	db 10
__echo_msg_end: