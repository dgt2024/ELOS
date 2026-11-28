__echo_main:
	; this code has a "C translation"
	mov dh, 0
	int 0x43 ; pollMessage();

	mov dh, 5
	int 0x42 ; getMessage();

	cmp bl, 0
	jne __echo_main ; if(msgType != 0)

	mov ax, cx
	mov dh, 8
	int 0x42 ; requestShare(msgData);

__echo_wait:
	mov dh, 0
	int 0x43 ; pollMessage();

	mov dh, 5
	int 0x42 ; getMessage();

	cmp bl, 2
	jne __echo_wait

	mov eax, "OUT "
	mov dh, 2
	int 0x42

	mov ax, dx
	mov edi, 0x40002009
	mov ecx, 5
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