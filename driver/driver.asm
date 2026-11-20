registerDriver:
	push eax ; Store driver ptr

	mov edi, 0x180000
	mov ecx, 0x10000
	xor eax, eax

	repne scasd
	jnz registerDriver_error

	pop eax
	mov dword[edi-4], eax

	not cx
	add cx, 0x8000
	mov dx, cx

	clc
	ret

registerDriver_error:
	stc
	ret
