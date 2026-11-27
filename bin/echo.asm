__echo_main:
	mov dh, 0
	int 0x43

	mov dh, 5
	int 0x42

	cmp bl, 0
	jne __echo_main

	mov word[__echo_write], cx
	shr ecx, 16
	mov byte[__echo_write+2], cl

	mov eax, "OUT "
	mov dh, 2
	int 0x42

	mov ax, dx
	mov edi, __echo_msg
	mov ecx, __echo_msg_end - __echo_msg
	mov dh, 1
	mov bl, 6
	int 0x42
	
	mov dh, 3
	int 0x43
__echo_msg:
	db 10, "u did echo "
__echo_write:
	db 0, 0, 0, 10
__echo_msg_end: