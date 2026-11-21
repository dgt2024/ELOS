runDevice:
	movzx eax, ax
	mov edx, eax

	cmp byte[0x100000+eax*8], 0
	je runDevice_error

	mov ax, word[0x100002+eax*8]

	call runDriver
	jc runDevice_error

	clc
	ret

runDevice_error:
	stc
	ret

createDevice:
	push eax ; save type

	movzx edi, al
	shl edi, 9
	add edi, 0x1e0000 ; device type dev_type

	xor ax, ax
	mov ecx, 0x100

	repne scasw
	jnz createDevice_error

	not cl
	inc cl
	mov dl, cl ; save ID for later

	mov esi, 0x100000
	xor ax, ax
	mov ecx, 0x10000

createDevice_loop:
	cmp byte[esi], 0
	je createDevice_found

	add esi, 8
	loop createDevice_loop
createDevice_found:
	not cx
	inc cx

	pop eax

	mov byte[esi], dl
	mov byte[esi+1], al
	mov dx, word[0x80000ffc] ; DDHNDL of current driver
	; Only drivers can create devices unless
	; its a ring 1 device and you have driver loaded

	mov word[esi+2], dx
	mov dword[esi+4], ebx

	mov dx, cx
	
	clc
	ret

createDevice_error:
	stc
	ret
