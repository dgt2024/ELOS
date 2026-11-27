__hwrld_main:
	mov eax, "OUT "
	mov dh, 2
	int 0x37

	mov ax, dx
	mov edi, __hwrld_msg
	mov ecx, __hwrld_msg_end - __hwrld_msg
	mov dh, 1
	mov bl, 6
	int 0x37
	ret

__hwrld_msg:
	db 10, "Hello, World!", 10
__hwrld_msg_end: